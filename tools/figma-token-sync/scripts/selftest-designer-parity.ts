// Self-test for src/designer-parity.ts — the pure half: variant-name
// normalisation, the per-variant multiset diff, the fingerprint, and the
// log formatter. No Figma runtime; runs under plain Node via
// `npm run selftest`. Exits non-zero on any assertion failure.
//
// The reading half (walking a set's nodes into leaf descriptors) needs a
// canvas and is exercised by a real Generate — the `⇄` line it prints is the
// evidence. What can be wrong WITHOUT a canvas is here: a diff that misses a
// difference, a fingerprint that moves when nothing changed, a formatter that
// hides the one line that mattered.

import {
  diffLeaves,
  isRedesignFrameName,
  isReplaceablePrior,
  isPriorSnapshotName,
  fingerprintOfLeaves,
  formatFreshnessLine,
  formatNoDesignerCopy,
  formatParityDiff,
  formatParitySummary,
  freshnessOf,
  noDesignerCopyReport,
  normalizeVariantName,
  pickDesignerFrame,
  priorSnapshotName,
  redesignSnapshotName,
  snapshotName,
  serialiseParityEnvelope,
  variantKeyOf,
  formatRenameLines,
  parityReport,
  renameCopyVariants,
  variantRenamesFor,
  type ParityRename,
  type ParitySetReport,
  type VariantLeaves,
} from '../src/designer-parity';
import { VARIANT_RENAMES, type VariantRename } from '../src/renames';
import { ownStrokeInsets, readSurfaceMaterial, type SurfaceHostLike } from '../src/surface-layers';
import { layoutInsetChecks } from './selftest-layout-inset-projection';

declare const process: { exit(code: number): never };

let failures = 0;

function check(label: string, fn: () => void): void {
  try {
    fn();
    console.log(`  ok  ${label}`);
  } catch (e) {
    failures++;
    console.error(`FAIL  ${label}\n      ${String(e)}`);
  }
}

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

function assertEq<T>(actual: T, expected: T, what: string): void {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a !== b) throw new Error(`${what}: expected ${b}, got ${a}`);
}

const kBox = 'box 240x40 r8 fill:color/surface stroke:color/outline-variant w1';
const kText = 'text "Select an option" 16 Regular lh120% ls-0.16 color/placeholder';
const kIcon = 'icon chevron-down 20 color/placeholder';
const kRing = 'box 248x48 r12 fill:none stroke:color/focus-ring w2';
const kRingPrimary = 'box 248x48 r12 fill:none stroke:color/primary w2';
const kCaret = 'box 2x22 r2 fill:color/primary stroke:none w0';

console.log('selftest: designer-parity');

check('variant names compare with their axes sorted (T-16 order vs canvas order)', () => {
  assertEq(
    normalizeVariantName('Size=sm, Selected=false, State=enabled'),
    normalizeVariantName('Size=sm, State=enabled, Selected=false'),
    'same pose, different axis order',
  );
  assert(
    normalizeVariantName('Size=sm, State=enabled') !== normalizeVariantName('Size=md, State=enabled'),
    'different values must not collapse',
  );
  assertEq(normalizeVariantName('  Icon  '), 'Icon', 'a single component keeps its name');
  assertEq(
    normalizeVariantName('Variant=a , Size = md'),
    'Size=md, Variant=a',
    'whitespace around = and , is not a difference',
  );
});

check('identical leaves → no difference, every variant compared', () => {
  const a: VariantLeaves = { 'Size=md, State=enabled': [kBox, kIcon, kText].sort() };
  const b: VariantLeaves = { 'Size=md, State=enabled': [kText, kBox, kIcon].sort() };
  const d = diffLeaves(a, b);
  assertEq(d.compared, 1, 'compared');
  assertEq(d.differing, [], 'differing');
  assertEq(d.lines, [], 'lines');
});

check('a value that differs shows up on both sides of the same variant', () => {
  const designer: VariantLeaves = { 'Size=md, State=focus': [kBox, kText, kRing].sort() };
  const generated: VariantLeaves = {
    'Size=md, State=focus': [kBox, kText, kRingPrimary, kCaret].sort(),
  };
  const d = diffLeaves(designer, generated);
  assertEq(d.differing, ['Size=md, State=focus'], 'the focus pose differs');
  assertEq(d.lines[0].designer, [kRing], 'designer-only: the focus-ring coloured ring');
  assertEq(
    d.lines[0].generated,
    [kCaret, kRingPrimary].sort(),
    'generated-only: the primary ring and the caret',
  );
});

check('the diff is a multiset — a duplicated leaf counts', () => {
  const designer: VariantLeaves = { v: [kBox] };
  const generated: VariantLeaves = { v: [kBox, kBox] };
  const d = diffLeaves(designer, generated);
  assertEq(d.lines[0].generated, [kBox], 'the second box is a difference');
  assertEq(d.lines[0].designer, [], 'nothing missing on the designer side');
});

check('variants present on one side only are reported, not compared', () => {
  const designer: VariantLeaves = { a: [kBox], b: [kBox] };
  const generated: VariantLeaves = { a: [kBox], c: [kBox] };
  const d = diffLeaves(designer, generated);
  assertEq(d.compared, 1, 'only `a` is on both sides');
  assertEq(d.onlyDesigner, ['b'], 'b is designer-only');
  assertEq(d.onlyGenerated, ['c'], 'c is generated-only');
  assertEq(d.differing, [], 'a is equal');
});

check('the fingerprint ignores order and moves on any value', () => {
  const a: VariantLeaves = { v1: [kBox, kText].sort(), v2: [kIcon] };
  const b: VariantLeaves = { v2: [kIcon], v1: [kText, kBox].sort() };
  assertEq(fingerprintOfLeaves(a), fingerprintOfLeaves(b), 'key/leaf order is not a change');
  const c: VariantLeaves = { v1: [kBox, kText.replace('120%', '160%')].sort(), v2: [kIcon] };
  assert(fingerprintOfLeaves(a) !== fingerprintOfLeaves(c), 'a line-height change moves it');
  const dropped: VariantLeaves = { v1: [kBox, kText].sort() };
  assert(fingerprintOfLeaves(a) !== fingerprintOfLeaves(dropped), 'a missing variant moves it');
});

check('the formatter folds the same difference across variants into one entry', () => {
  const designer: VariantLeaves = {};
  const generated: VariantLeaves = {};
  for (const size of ['sm', 'md', 'lg']) {
    designer[`Size=${size}, State=focus`] = [kBox, kRing].sort();
    generated[`Size=${size}, State=focus`] = [kBox, kRingPrimary].sort();
  }
  const lines = formatParityDiff('Select', diffLeaves(designer, generated));
  assert(lines[0].includes('3 / 3 변형'), `header counts differing variants: ${lines[0]}`);
  const where = lines.find((l) => l.includes('외 2 변형'));
  assert(where != null, `three variants fold into one entry: ${lines.join(' | ')}`);
  assertEq(
    lines.filter((l) => l.includes('리디자인:')).length,
    1,
    'the designer value is printed once, not three times',
  );
  assert(lines.some((l) => l.includes(kRing)), 'the designer ring line is present');
  assert(lines.some((l) => l.includes(kRingPrimary)), 'the generated ring line is present');
});

check('the formatter says so when nothing differs', () => {
  const lines = formatParityDiff('Toggle', diffLeaves({ a: [kBox] }, { a: [kBox] }));
  assertEq(lines.length, 1, 'one line');
  assert(lines[0].includes('차이 없음'), lines[0]);
  assert(lines[0].includes('(1 변형)'), lines[0]);
});

check('the formatter caps its output and says it did', () => {
  const designer: VariantLeaves = {};
  const generated: VariantLeaves = {};
  for (let i = 0; i < 20; i++) {
    designer[`v${i}`] = [`box ${i}x1 r0 fill:a stroke:none w0`];
    generated[`v${i}`] = [`box ${i}x2 r0 fill:a stroke:none w0`];
  }
  const lines = formatParityDiff('Many', diffLeaves(designer, generated), 6);
  assert(lines.some((l) => l.includes('잘림')), `a truncation line exists: ${lines.join(' | ')}`);
  assert(lines.length <= 6 + 2, `stays near the cap (${lines.length} lines)`);
});

check('an instance member is keyed by its axes, not its name', () => {
  // 같은 파일 안에서 세트를 복사·붙여 넣으면 멤버가 전부 INSTANCE 가 되고
  // 그 이름은 세트 이름이다 — 이름으로 키를 잡으면 전 변형이 한 칸에 겹친다.
  const a = variantKeyOf('Select', { Size: 'md', State: 'enabled' });
  const b = variantKeyOf('Select', { State: 'enabled', Size: 'md' });
  assertEq(a, b, 'axis order does not matter');
  assertEq(a, 'Size=md, State=enabled', 'the key is the axes');
  assert(
    variantKeyOf('Select', { Size: 'sm', State: 'enabled' }) !== a,
    'two instances with different axes must not collapse',
  );
  assertEq(
    variantKeyOf('Variant=error, Size=md', null),
    'Size=md, Variant=error',
    'a component member falls back to its name',
  );
  assertEq(variantKeyOf('Icon', {}), 'Icon', 'an empty axis map falls back to the name');
});

check('the reference is the redesign — a hand copy, or a preserved hand edit', () => {
  // 지문 없이 뜬 백업은 어제의 생성본이다. 그것과 대조하면 "코드가 얼마나
  // 바뀌었나" 가 나오지 리디자인과의 차이가 아니다 — 실제로 사본이 없는
  // 세트에서 대조가 그것을 집어 "192/192 다름" 을 냈다. 반대로 손 편집을
  // 보존한 스냅샷은 디자이너가 실제로 그린 것이라 기준이 **되어야** 한다.
  const manual = { name: 'Select (리디자인)', stamp: '' };
  const priorOld = {
    name: 'Select (이전 · 2026-09-09 10:00)',
    stamp: '2026-09-09T01:00:00.000Z',
    reason: 'prior',
  };
  const priorNew = {
    name: 'Select (이전 · 2026-09-10 18:00)',
    stamp: '2026-09-10T09:00:00.000Z',
    reason: 'prior',
  };
  const handOld = {
    name: 'Select (리디자인 · 2026-09-09 11:00)',
    stamp: '2026-09-09T02:00:00.000Z',
    reason: 'hand-edit',
  };
  const handNew = {
    name: 'Select (리디자인 · 2026-09-10 19:00)',
    stamp: '2026-09-10T10:00:00.000Z',
    reason: 'hand-edit',
  };
  // 이유를 알 수 없는 옛 스냅샷 — 손 편집이었는지 백업이었는지 모른다.
  const unknown = { name: 'Select (디자이너 · 2026-09-08 09:00)', stamp: '2026-09-08T00:00:00.000Z' };

  assertEq(pickDesignerFrame([priorOld, manual, priorNew]), 1, 'the unstamped hand copy is chosen');
  assertEq(pickDesignerFrame([priorOld, priorNew]), -1, 'backups only → nothing to compare against');
  assertEq(pickDesignerFrame([unknown]), -1, 'an unknown-reason snapshot is not a reference');
  assertEq(pickDesignerFrame([unknown, manual]), 1, 'the hand copy wins over an unknown one');
  assertEq(pickDesignerFrame([]), -1, 'no candidate → -1');

  // 손 편집 보존본은 기준이다 — 이것이 세트를 직접 고치는 흐름의 전부다.
  assertEq(pickDesignerFrame([priorNew, handOld]), 1, 'a preserved hand edit IS a reference');
  assertEq(pickDesignerFrame([handOld, handNew]), 1, 'two preserved edits → the newer stamp');
  assertEq(pickDesignerFrame([handNew, handOld]), 0, 'and that does not depend on array order');
  // 사람이 둔 사본이 있으면 그것이 이긴다 — 보존본은 플러그인이 뜬 것이고,
  // 사본은 디자이너가 "이것이 기준" 이라고 직접 둔 것이다.
  assertEq(pickDesignerFrame([handNew, manual]), 1, 'the hand copy outranks a preserved edit');

  const a = { name: 'Select (리디자인 A)', stamp: '' };
  const b = { name: 'Select (리디자인 B)', stamp: '' };
  assertEq(pickDesignerFrame([a, b, priorNew]), 1, 'two hand copies → the later name');
  assertEq(pickDesignerFrame([b, a, priorNew]), 0, 'and that does not depend on array order');
});

check('a component-set original prefers a same-kind copy over a comparison frame', () => {
  // `X(리디자인) / 비교` 프레임은 이름 정렬에서 세트 사본보다 뒤다.
  const set = { name: 'MultipleChoice(리디자인)', stamp: '', isComponent: true };
  const frame = { name: 'MultipleChoice(리디자인) / 비교', stamp: '', isComponent: false };
  // (a) 세트가 기준이 된다. 종류를 가리지 않으면 프레임이 이긴다(회귀 확인용).
  assertEq(pickDesignerFrame([set, frame], true), 0, 'the set beats the later-named comparison frame');
  assertEq(pickDesignerFrame([frame, set], true), 1, 'and that does not depend on array order');
  assertEq(pickDesignerFrame([set, frame], false), 1, 'without the preference the later name wins');
  // (b) 세트 없이 프레임만 — 기존 동작(프레임이 후보, 이후 대조가 안내).
  assertEq(pickDesignerFrame([frame], true), 0, 'frame only → still the candidate');
  // (c) 세트 둘 — 이름 정렬의 마지막.
  const s1 = { name: 'Slider(리디자인 A)', stamp: '', isComponent: true };
  const s2 = { name: 'Slider(리디자인 B)', stamp: '', isComponent: true };
  assertEq(pickDesignerFrame([s1, s2, frame], true), 1, 'two sets → the later name, frame ignored');
});

check('the redesign frame is recognised with or without the space, new name or old', () => {
  // 손으로 붙여 넣은 사본은 붙여 적는다 — 실제로 넷 다 붙여 적었고, 공백
  // 하나 때문에 대조가 침묵했다. 옛 표기도 받는다: 표기를 바꿨다고 캔버스에
  // 이미 있는 사본이 조용히 후보에서 빠지면 어제까지 되던 대조가 멈춘다.
  for (const n of [
    'Checkbox(리디자인)',
    'Checkbox (리디자인)',
    'Checkbox(리디자인 2차)',
    'Checkbox (리디자인 · 2026-09-10 13:35)',
    'Checkbox(디자이너)',
    'Checkbox (디자이너)',
  ]) {
    assert(isRedesignFrameName(n, 'Checkbox'), `should match: ${n}`);
  }
  // 세트 이름은 정확히 일치해야 한다 — 접두가 같은 다른 세트를 끌어오지 않는다.
  assert(!isRedesignFrameName('CheckboxGroup(리디자인)', 'Checkbox'), 'prefix is not enough');
  assert(!isRedesignFrameName('Checkbox', 'Checkbox'), 'the set itself is not its own reference');
  assert(!isRedesignFrameName('Checkbox (이전)', 'Checkbox'), 'another parenthetical is not it');
  assert(!isRedesignFrameName('Toggle(리디자인)', 'Checkbox'), 'another set is not it');
});

check('the two snapshot kinds get two names and two roles', () => {
  // 한 이름으로 두 이유를 덮으면 디자이너가 백업을 자기 사본과 같은 종류로
  // 읽는다(실제로 그랬다). 이름을 만드는 함수와 알아보는 함수를 같이 검사해,
  // 한쪽만 바뀌어 두 종류가 다시 섞이는 일이 없게 한다.
  const at = new Date(2026, 8, 10, 13, 35);

  const prior = priorSnapshotName('Checkbox', at);
  assertEq(prior, 'Checkbox (이전 · 2026-09-10 13:35)', 'the backup name');
  assertEq(snapshotName('Checkbox', 'prior', at), prior, 'kind dispatches to the same name');
  assert(isPriorSnapshotName(prior, 'Checkbox'), 'the plugin recognises its own backup');
  assert(!isRedesignFrameName(prior, 'Checkbox'), 'a backup is NOT a redesign frame');
  assert(!prior.includes('리디자인'), 'the word 리디자인 does not appear in a backup name');

  const hand = redesignSnapshotName('Checkbox', at);
  assertEq(hand, 'Checkbox (리디자인 · 2026-09-10 13:35)', 'the preserved-edit name');
  assertEq(snapshotName('Checkbox', 'hand-edit', at), hand, 'kind dispatches to the same name');
  assert(isRedesignFrameName(hand, 'Checkbox'), 'a preserved hand edit IS a redesign frame');
  assert(!isPriorSnapshotName(hand, 'Checkbox'), 'and it is not a backup');
  assert(hand !== prior, 'the two kinds never collide on a name');

  assert(isPriorSnapshotName('Checkbox(이전 · 2026-09-10 13:35)', 'Checkbox'), 'space is optional');
  assert(!isPriorSnapshotName('Checkbox(리디자인)', 'Checkbox'), 'a hand copy is not a backup');
  assert(!isPriorSnapshotName('CheckboxGroup (이전 · x)', 'Checkbox'), 'prefix is not enough');
  assert(!isPriorSnapshotName('Checkbox (이전)', 'Checkbox'), 'the dot-separated stamp is required');
});

check('only a backup is ever auto-deleted — a preserved hand edit never is', () => {
  // 이 모듈은 손 편집이 흔적 없이 사라지는 것을 막으려고 있다. 정리 규칙이
  // 손 편집 보존본을 지우면 그 사고를 이 모듈이 저지른다 — 그래서 지워도
  // 되는 것은 백업뿐이고, 이유를 모르는 것도 남긴다(손 편집이었을 수 있다).
  const node = (name: string, stamp = '', reason = '') => ({
    name,
    getPluginData: (k: string) =>
      k === 'coui-designer-snapshot' ? stamp : k === 'coui-snapshot-reason' ? reason : '',
  });

  assert(
    isReplaceablePrior(node('Checkbox (이전 · 2026-09-10 13:35)', 's', 'prior'), 'Checkbox'),
    'a backup is replaceable',
  );
  assert(
    isReplaceablePrior(node('Checkbox (이전 · 2026-09-10 13:35)'), 'Checkbox'),
    'a backup is replaceable by name even without plugin data',
  );
  assert(
    !isReplaceablePrior(node('Checkbox (리디자인 · 2026-09-10 13:35)', 's', 'hand-edit'), 'Checkbox'),
    'a PRESERVED HAND EDIT is never auto-deleted',
  );
  assert(
    !isReplaceablePrior(node('Checkbox(리디자인)'), 'Checkbox'),
    "a designer's own hand copy is never auto-deleted",
  );
  assert(
    !isReplaceablePrior(node('Checkbox (디자이너 · 2026-09-08 09:00)', 's'), 'Checkbox'),
    'an unknown-reason snapshot is left alone — it may have been a hand edit',
  );
  assert(
    !isReplaceablePrior(node('CheckboxGroup (이전 · x)', 's', 'prior'), 'Checkbox'),
    "another set's backup is not this set's",
  );
});

check('the no-copy line names the set and the frame name to add', () => {
  assertEq(
    formatNoDesignerCopy('Checkbox'),
    '⇄ Checkbox: 리디자인 사본 없음 — 세트를 직접 고쳐 반영하거나, 같은 페이지에 "Checkbox(리디자인)" 을 두면 대조한다',
    'the line',
  );
  const r = noDesignerCopyReport('Checkbox', '❖ Checkbox');
  assertEq(r.designerFrame, null, 'no frame');
  assertEq(r.freshness.hint, 'n/a', 'no freshness without a copy');
  assertEq([r.compared, r.differing.length, r.lines.length], [0, 0, 0], 'nothing compared');
  assertEq(r.page, '❖ Checkbox', 'the page is carried');
});

check('freshness — a raw-paste copy is called out, a bound one is not', () => {
  assertEq(freshnessOf(90, 0).hint, 'raw-paste', '0 bound of 90 → raw-paste');
  assertEq(freshnessOf(90, 1).hint, 'bound', 'any bound → bound');
  assertEq(freshnessOf(0, 0).hint, 'n/a', 'no text → n/a');
  assertEq(
    formatFreshnessLine(freshnessOf(90, 0)),
    '  ⚠ 사본이 로우 텍스트(변수 바인딩 0/90) — 자간·크기 축의 차이는 붙여넣기에서 잃은 값일 수 있다',
    'the warning line',
  );
  assertEq(formatFreshnessLine(freshnessOf(90, 12)), null, 'a bound copy gets no warning');
  assertEq(formatFreshnessLine(freshnessOf(0, 0)), null, 'no text gets no warning');
});

function report(
  name: string,
  designerFrame: string | null,
  diff: Partial<Pick<ParitySetReport, 'differing' | 'onlyDesigner' | 'onlyGenerated' | 'skipped'>> = {},
): ParitySetReport {
  return {
    name,
    page: `❖ ${name}`,
    designerFrame,
    freshness: freshnessOf(designerFrame ? 10 : 0, designerFrame ? 10 : 0),
    compared: designerFrame ? 10 : 0,
    differing: diff.differing ?? [],
    onlyDesigner: diff.onlyDesigner ?? [],
    onlyGenerated: diff.onlyGenerated ?? [],
    lines: (diff.differing ?? []).map((v) => ({ variant: v, designer: [kRing], generated: [] })),
    ...(diff.skipped != null ? { skipped: diff.skipped } : {}),
  };
}

check('the summary counts compared / clean / differing / missing in one line', () => {
  const sets = [
    report('Checkbox', 'Checkbox(리디자인)'),
    report('Toggle', 'Toggle(리디자인)', { differing: ['Size=md'] }),
    report('Radio', 'Radio(리디자인)', { onlyDesigner: ['Size=xl'] }),
    report('Chip', null),
    report('Badge', null),
  ];
  assertEq(
    formatParitySummary(sets),
    '⇄ 요약: 대조 3 세트 · 차이 0 → 1 세트 · 차이 있음 2 세트 · 사본 없음 2 세트',
    'the summary',
  );
  // a variant that exists on one side only is a difference, not a clean set
  assertEq(
    formatParitySummary([report('Radio', 'Radio(리디자인)', { onlyGenerated: ['x'] })]),
    '⇄ 요약: 대조 1 세트 · 차이 0 → 0 세트 · 차이 있음 1 세트 · 사본 없음 0 세트',
    'onlyGenerated counts as differing',
  );
  // a mirrored copy is neither compared nor missing — appended only when present
  assertEq(
    formatParitySummary([report('Select', 'Select(리디자인)', { skipped: 'mirrors' })]),
    '⇄ 요약: 대조 0 세트 · 차이 0 → 0 세트 · 차이 있음 0 세트 · 사본 없음 0 세트 · 건너뜀 1 세트',
    'skipped is a separate bucket',
  );
});

check('the JSON envelope carries every set and every line, uncapped', () => {
  const designer: VariantLeaves = {};
  const generated: VariantLeaves = {};
  for (let i = 0; i < 30; i++) {
    designer[`v${i}`] = [`box ${i}x1 r0 fill:a stroke:none w0`];
    generated[`v${i}`] = [`box ${i}x2 r0 fill:a stroke:none w0`];
  }
  const diff = diffLeaves(designer, generated);
  const logLines = formatParityDiff('Many', diff);
  assert(logLines.some((l) => l.includes('잘림')), 'the log is capped');
  const set: ParitySetReport = {
    name: 'Many',
    page: '❖ Many',
    designerFrame: 'Many(리디자인)',
    freshness: freshnessOf(30, 0),
    compared: diff.compared,
    differing: diff.differing,
    onlyDesigner: diff.onlyDesigner,
    onlyGenerated: diff.onlyGenerated,
    lines: diff.lines,
  };
  const json = serialiseParityEnvelope([set, noDesignerCopyReport('Chip', '❖ Chip')], {
    capturedAt: '2026-09-10T04:35:00.000Z',
    fileKey: 'abc123',
    sourceHash: 'deadbeef',
  });
  const parsed = JSON.parse(json) as {
    kind: string;
    schema: number;
    capturedAt: string;
    fileKey: string | null;
    sourceHash: string;
    sets: ParitySetReport[];
  };
  assertEq(parsed.kind, 'coui-designer-parity', 'kind');
  assertEq(parsed.schema, 1, 'schema');
  assertEq(parsed.capturedAt, '2026-09-10T04:35:00.000Z', 'capturedAt');
  assertEq(parsed.fileKey, 'abc123', 'fileKey');
  assertEq(parsed.sourceHash, 'deadbeef', 'sourceHash');
  assertEq(parsed.sets.length, 2, 'both sets, including the one without a copy');
  assertEq(parsed.sets[0].lines.length, 30, 'every differing variant is in the file');
  assertEq(parsed.sets[0].differing.length, 30, 'differing is uncapped too');
  const v7 = parsed.sets[0].lines.find((l) => l.variant === 'v7');
  assertEq(v7?.designer, ['box 7x1 r0 fill:a stroke:none w0'], 'leaf descriptors are carried verbatim');
  assertEq(v7?.generated, ['box 7x2 r0 fill:a stroke:none w0'], 'both sides');
  assertEq(parsed.sets[0].freshness, { textNodes: 30, boundTextNodes: 0, hint: 'raw-paste' }, 'freshness');
  assertEq(parsed.sets[1].designerFrame, null, 'the missing copy is null, not absent');
  assertEq(
    Object.keys(parsed.sets[1]).sort(),
    ['compared', 'designerFrame', 'differing', 'freshness', 'lines', 'name', 'onlyDesigner', 'onlyGenerated', 'page'],
    'the set shape (no `skipped` key when not skipped)',
  );
  assertEq(
    serialiseParityEnvelope([], { capturedAt: 'x', fileKey: null, sourceHash: 'dev' }).includes('"fileKey": null'),
    true,
    'an unknown fileKey is null, not omitted',
  );
});

// ─── 개명표 — 사본의 옛 이름을 새 이름으로 읽는다 ─────────────────────────
//
// Generate 는 원본 세트의 멤버만 개명한다. 개명 전에 복제한 `(리디자인)` 사본은
// 옛 이름을 그대로 들고 있어, 이름으로만 짝을 지으면 바뀐 변형이 전부 양쪽
// "에만" 으로 갈라지고 값은 하나도 대조되지 않는다. 아래는 그 짝을 표로 맺는
// 순수 규칙이고, 그 뒤가 실제 `parityReport` 를 가짜 캔버스로 돌린 것이다.

const kOld = 'Variant=a, Enabled=false';
const kOldKey = normalizeVariantName(kOld); // 'Enabled=false, Variant=a'
const kNew = 'Variant=a, State=disabled';
const kNewKey = normalizeVariantName(kNew); // 'State=disabled, Variant=a'

check('renames — an old copy name is read as the name the table moved it to', () => {
  const designer: VariantLeaves = { [kOldKey]: [kBox] };
  const generated: VariantLeaves = { [kNewKey]: [kBox] };
  const r = renameCopyVariants(designer, generated, [{ from: kOld, to: kNew }]);
  assertEq(Object.keys(r.leaves), [kNewKey], 'the copy is keyed by the new name');
  assertEq(r.renamed, [{ from: kOldKey, to: kNewKey }], 'the pair is recorded old → new');
  assertEq(r.conflicts, [], 'no conflict');
  const d = diffLeaves(r.leaves, generated);
  assertEq([d.compared, d.onlyDesigner.length, d.onlyGenerated.length], [1, 0, 0], 'paired and compared');
});

check('renames — the table is matched with axes sorted, whatever order the copy spells', () => {
  // 표는 캔버스가 적은 순서 그대로, 사본은 다른 순서일 수 있다 — 키는 둘 다 정규화.
  const designer: VariantLeaves = { [variantKeyOf('Enabled=false, Variant=a')]: [kBox] };
  const generated: VariantLeaves = { [kNewKey]: [kBox] };
  const r = renameCopyVariants(designer, generated, [{ from: 'Variant=a, Enabled=false', to: kNew }]);
  assertEq(r.renamed.length, 1, 'the reordered copy name still matches the row');
});

check('renames — a name the generated set already has is never moved', () => {
  // 새 이름을 쓴 사본은 지금처럼 바로 짝지어진다. 표의 `from` 이 우연히 생성본의
  // 이름이어도 생성본에 그대로 있는 이름이 이긴다.
  const designer: VariantLeaves = { [kNewKey]: [kBox] };
  const generated: VariantLeaves = { [kNewKey]: [kBox], other: [kBox] };
  const r = renameCopyVariants(designer, generated, [{ from: kNew, to: 'other' }]);
  assertEq(r.renamed, [], 'nothing moved');
  assert(r.leaves === designer, 'the input object comes back untouched');
});

check('renames — an empty table, or a reorder-only row, changes nothing', () => {
  const designer: VariantLeaves = { a: [kBox], b: [kText] };
  const generated: VariantLeaves = { a: [kBox], c: [kText] };
  const empty = renameCopyVariants(designer, generated, []);
  assert(empty.leaves === designer, 'no table → the same object');
  assertEq([empty.renamed, empty.conflicts], [[], []], 'no pairs');
  const reorder = renameCopyVariants(designer, generated, [
    { from: 'Size=md, Open=true', to: 'Open=true, Size=md' },
  ]);
  assert(reorder.leaves === designer, 'a row that only reorders axes is the same key');
});

check('renames — a chain is followed to the first name the generated set has', () => {
  // 표는 세대를 거칠 수 있다 — 옛 세대 → 중간 → 지금.
  const table: ParityRename[] = [
    { from: 'A=1', to: 'B=1' },
    { from: 'B=1', to: 'C=1' },
  ];
  const toEnd = renameCopyVariants({ 'A=1': [kBox] }, { 'C=1': [kBox] }, table);
  assertEq(toEnd.renamed, [{ from: 'A=1', to: 'C=1' }], 'two hops land on the produced name');
  const stopEarly = renameCopyVariants({ 'A=1': [kBox] }, { 'B=1': [kBox], 'C=1': [kBox] }, table);
  assertEq(stopEarly.renamed, [{ from: 'A=1', to: 'B=1' }], 'it stops at the first produced name');
});

check('renames — a target the generated set does not have is not invented', () => {
  const r = renameCopyVariants({ 'A=1': [kBox] }, { 'Z=1': [kBox] }, [{ from: 'A=1', to: 'B=1' }]);
  assertEq(r.renamed, [], 'unreachable → not moved');
  assertEq(Object.keys(r.leaves), ['A=1'], 'it stays designer-only under its old name');
  const loop = renameCopyVariants({ 'A=1': [kBox] }, { 'Z=1': [kBox] }, [
    { from: 'A=1', to: 'B=1' },
    { from: 'B=1', to: 'A=1' },
  ]);
  assertEq(loop.renamed, [], 'a cycle ends without a pair (and without hanging)');
});

check('renames — a target the copy already holds is a conflict, not an overwrite', () => {
  // 사본에 옛 이름과 새 이름이 함께 있으면 직접 짝이 이기고, 옛 것은 옛 이름 그대로.
  const designer: VariantLeaves = { [kOldKey]: [kText], [kNewKey]: [kBox] };
  const generated: VariantLeaves = { [kNewKey]: [kBox] };
  const r = renameCopyVariants(designer, generated, [{ from: kOld, to: kNew }]);
  assertEq(r.renamed, [], 'nothing moved');
  assertEq(r.conflicts, [{ from: kOldKey, to: kNewKey }], 'the blocked pair is recorded');
  assertEq(r.leaves[kNewKey], [kBox], "the direct pair keeps its own leaves — the old one's are not merged in");
  assertEq(r.leaves[kOldKey], [kText], 'the old one stays under its old name');
});

check('renames — two old names for one target: the first in key order wins', () => {
  // 세대가 둘인 표(`Variant=standard` 와 `Variant=standard, Disabled=false` → 같은 멤버).
  const r = renameCopyVariants({ 'A=1': [kBox], 'A=2': [kText] }, { 'B=1': [kBox] }, [
    { from: 'A=2', to: 'B=1' },
    { from: 'A=1', to: 'B=1' },
  ]);
  assertEq(r.renamed, [{ from: 'A=1', to: 'B=1' }], 'A=1 sorts first');
  assertEq(r.conflicts, [{ from: 'A=2', to: 'B=1' }], 'A=2 is the conflict');
});

check('renames — the log lines list pairs, fold the rest, and are empty without pairs', () => {
  assertEq(formatRenameLines([], []), [], 'nothing → no lines (a set without renames logs as before)');
  const pairs = ['a', 'b', 'c', 'd', 'e'].map((x) => ({ from: `Old=${x}`, to: `New=${x}` }));
  const lines = formatRenameLines(pairs, [{ from: 'Old=z', to: 'New=a' }]);
  assertEq(lines[0], '  ↻ 개명표로 짝지음 5 변형 — 사본의 옛 이름을 지금 이름으로 읽었다', 'the header');
  assertEq(lines.slice(1, 4), ['      Old=a → New=a', '      Old=b → New=b', '      Old=c → New=c'], 'three pairs');
  assertEq(lines[4], '      … 외 2 변형', 'the rest folded');
  assert(lines[5].startsWith('  ⚠ 개명 목적지를'), `the conflict line is a warning: ${lines[5]}`);
  assertEq(lines[6], '      Old=z → New=a', 'the conflict pair');
});

check('renames — the table rows are picked by the set name', () => {
  const table = [
    { component: 'Toggle', from: 'x', to: 'y', reason: '' },
    { component: 'ToggleGroup', from: 'p', to: 'q', reason: '' },
  ] satisfies VariantRename[];
  assertEq(variantRenamesFor('Toggle', table), [{ from: 'x', to: 'y' }], 'exact name only');
  assertEq(variantRenamesFor('Nope', table), [], 'no rows → empty');
  assert(variantRenamesFor('RadioGroup').length > 0, 'the default is the real VARIANT_RENAMES');
});

check('renames — the summary counts sets paired through the table, only when there are some', () => {
  const plain = report('Toggle', 'Toggle(리디자인)');
  const viaTable: ParitySetReport = { ...report('Radio', 'Radio(리디자인)'), renamed: [{ from: 'a', to: 'b' }] };
  assertEq(
    formatParitySummary([plain, viaTable]),
    '⇄ 요약: 대조 2 세트 · 차이 0 → 2 세트 · 차이 있음 0 세트 · 사본 없음 0 세트 · 개명표로 짝지음 1 세트',
    'the suffix appears',
  );
  assertEq(
    formatParitySummary([plain]),
    '⇄ 요약: 대조 1 세트 · 차이 0 → 1 세트 · 차이 있음 0 세트 · 사본 없음 0 세트',
    'and is absent otherwise',
  );
});

// ─── 가짜 캔버스로 `parityReport` 를 끝까지 돌린다 ───────────────────────
//
// 위 규칙이 맞아도 `parityReport` 가 그것을 부르지 않으면 소용없다 — 그래서 실제
// 함수에 페이지 · 세트 · 사본을 흉내 낸 노드를 넣는다. 멤버마다 박스 하나를
// 칠하므로 잎 서술자는 `box 40x24 r8 fill:<색> …` 한 줄이다.

interface FakeNode {
  type: string;
  name: string;
  visible: boolean;
  width: number;
  height: number;
  opacity: number;
  layoutMode: 'NONE';
  cornerRadius: number;
  strokeWeight: number;
  fills: unknown[];
  strokes: unknown[];
  children: FakeNode[];
  getPluginData(key: string): string;
}

function fakeNode(type: string, name: string, fill: string | null, children: FakeNode[] = []): FakeNode {
  return {
    type,
    name,
    visible: true,
    width: 40,
    height: 24,
    opacity: 1,
    layoutMode: 'NONE',
    cornerRadius: 8,
    strokeWeight: 1,
    fills:
      fill == null
        ? []
        : [{ type: 'SOLID', visible: true, opacity: 1, color: { r: 0, g: 0, b: 0 }, boundVariables: { color: { id: fill } } }],
    strokes: [],
    children,
    getPluginData: () => '',
  };
}

/** 생성본 세트와 디자이너가 ⌘D 로 둔 사본(같은 페이지 최상위, `<세트>(리디자인)`). */
function fakePage(setName: string, generated: [string, string][], copy: [string, string][]): {
  set: ComponentSetNode;
  page: PageNode;
} {
  const set = fakeNode('COMPONENT_SET', setName, null, generated.map(([n, f]) => fakeNode('COMPONENT', n, f)));
  const copyNode = fakeNode('COMPONENT_SET', `${setName}(리디자인)`, null, copy.map(([n, f]) => fakeNode('COMPONENT', n, f)));
  const page = { type: 'PAGE', name: `❖ ${setName}`, children: [set, copyNode] };
  return { set: set as unknown as ComponentSetNode, page: page as unknown as PageNode };
}

function installFakeFigma(): void {
  (globalThis as unknown as { figma: unknown }).figma = {
    mixed: Symbol('figma.mixed'),
    variables: { getVariableByIdAsync: async (id: string) => ({ name: id }) },
  };
}

async function checkAsync(label: string, fn: () => Promise<void>): Promise<void> {
  try {
    await fn();
    console.log(`  ok  ${label}`);
  } catch (e) {
    failures++;
    console.error(`FAIL  ${label}\n      ${String(e)}`);
  }
}

/** 실제 개명표의 RadioGroup 4축 세대 — `Enabled` 불린이 `State` 사다리로 접힌 행. */
function radioGroupBooleanGeneration(): VariantRename[] {
  return VARIANT_RENAMES.filter(
    (r) => r.component === 'RadioGroup' && r.from.startsWith('Variant=defaultVariant, ') && r.from.includes('Enabled='),
  );
}

async function renameParityChecks(): Promise<void> {
  installFakeFigma();

  await checkAsync('parityReport — a copy with OLD names pairs with the renamed set (the real table)', async () => {
    const rows = radioGroupBooleanGeneration();
    assertEq(rows.length, 24, 'the RadioGroup boolean generation has 24 rows (6 sizes × 2 × 2)');
    // 생성본은 새 이름(개명 뒤), 사본은 개명 전에 복제한 옛 이름. 리디자인은 한 포즈의
    // 색을 바꿨고, 생성본에는 옛 이름이 없는 새 포즈(hover)가 하나 더 있다.
    const changedOld = 'Variant=defaultVariant, Size=md, Enabled=true, Selected=true';
    const fillOf = (to: string) => (to.includes('State=disabled') ? 'color/disabled' : 'color/primary');
    const generated: [string, string][] = rows.map((r) => [r.to, fillOf(r.to)]);
    generated.push(['Variant=defaultVariant, Size=md, State=hover, Selected=false', 'color/primary']);
    const copy: [string, string][] = rows.map((r) => [r.from, r.from === changedOld ? 'color/tertiary' : fillOf(r.to)]);
    const { set, page } = fakePage('RadioGroup', generated, copy);

    const { lines, report: rep } = await parityReport(set, page);
    console.log(lines.map((l) => `        │ ${l}`).join('\n'));
    assertEq(rep.compared, 24, 'all 24 old-named copy members were compared');
    assertEq(rep.renamed?.length, 24, 'and every one of them paired through the table');
    assertEq(rep.onlyDesigner, [], 'nothing left designer-only');
    assertEq(rep.onlyGenerated, ['Selected=false, Size=md, State=hover, Variant=defaultVariant'], 'the new pose is generated-only');
    assertEq(rep.differing, ['Selected=true, Size=md, State=enabled, Variant=defaultVariant'], 'the one recoloured pose differs, under its NEW name');
    assertEq(
      rep.renamed?.find((p) => p.to === 'Selected=true, Size=md, State=enabled, Variant=defaultVariant')?.from,
      normalizeVariantName(changedOld),
      'the report says which old name it came from',
    );
    assertEq(rep.lines[0].designer, ['box 40x24 r8 fill:color/tertiary stroke:none w0'], 'the redesign value is on the line');
    assert(lines.some((l) => l === '  ↻ 개명표로 짝지음 24 변형 — 사본의 옛 이름을 지금 이름으로 읽었다'), 'the log says so');
    assertEq(rep.renameConflicts, undefined, 'no conflicts key without conflicts');

    // 같은 캔버스를 표 없이 — 이것이 개명표를 읽기 전의 대조다.
    const blind = (await parityReport(set, page, undefined, [])).report;
    assertEq([blind.compared, blind.onlyDesigner.length, blind.onlyGenerated.length], [0, 24, 25], 'without the table nothing pairs');
    assertEq(blind.renamed, undefined, 'and nothing is reported as renamed');
  });

  await checkAsync('parityReport — a copy that already uses the NEW names pairs directly', async () => {
    const rows = radioGroupBooleanGeneration();
    const generated: [string, string][] = rows.map((r) => [r.to, 'color/primary']);
    const { set, page } = fakePage('RadioGroup', generated, generated);
    const { lines, report: rep } = await parityReport(set, page);
    assertEq([rep.compared, rep.differing.length], [24, 0], 'all compared, no difference');
    assertEq(rep.renamed, undefined, 'no pair went through the table');
    assert(!lines.some((l) => l.includes('개명표')), 'no rename line in the log');
  });

  await checkAsync('parityReport — a set with no rows in the table is exactly as before', async () => {
    const name = 'ParityHarnessUnrelated';
    assertEq(variantRenamesFor(name), [], `${name} has no VARIANT_RENAMES rows`);
    const generated: [string, string][] = [['Size=sm', 'color/primary'], ['Size=lg', 'color/primary']];
    const copy: [string, string][] = [['Size=sm', 'color/secondary'], ['Size=md', 'color/primary']];
    const { set, page } = fakePage(name, generated, copy);
    const withTable = await parityReport(set, page);
    const withoutTable = await parityReport(set, page, undefined, []);
    assertEq(withTable, withoutTable, 'the real table and no table give the same lines and report');

    // 개명표 이전의 파이프라인을 손으로 재현해 같은지 본다 — 이름으로만 짝짓기.
    const d: VariantLeaves = {
      'Size=sm': ['box 40x24 r8 fill:color/secondary stroke:none w0'],
      'Size=md': ['box 40x24 r8 fill:color/primary stroke:none w0'],
    };
    const g: VariantLeaves = {
      'Size=sm': ['box 40x24 r8 fill:color/primary stroke:none w0'],
      'Size=lg': ['box 40x24 r8 fill:color/primary stroke:none w0'],
    };
    const diff = diffLeaves(d, g);
    const expected = formatParityDiff(name, diff);
    expected[0] = `${expected[0]} — 기준 "${name}(리디자인)"`;
    assertEq(withTable.lines, expected, 'the log is the name-only log');
    assertEq(
      Object.keys(withTable.report).sort(),
      ['compared', 'designerFrame', 'differing', 'freshness', 'lines', 'name', 'onlyDesigner', 'onlyGenerated', 'page'],
      'the report has no renamed / renameConflicts keys',
    );
    assertEq([withTable.report.onlyDesigner, withTable.report.onlyGenerated], [['Size=md'], ['Size=lg']], 'name-only pairing');
  });

  await checkAsync('parityReport — rows for ANOTHER set do not touch this one', async () => {
    // 이 세트의 사본이 다른 세트 행의 `from` 과 같은 이름을 들고 있어도 옮기지 않는다.
    const table: VariantRename[] = [{ component: 'SomethingElse', from: 'Size=md', to: 'Size=lg', reason: '' }];
    const { set, page } = fakePage('ParityHarnessUnrelated', [['Size=lg', 'color/primary']], [['Size=md', 'color/primary']]);
    const rep = (await parityReport(set, page, undefined, table)).report;
    assertEq([rep.onlyDesigner, rep.onlyGenerated, rep.renamed], [['Size=md'], ['Size=lg'], undefined], 'untouched');
  });

  await checkAsync('parityReport — a copy holding old AND new names reports the conflict', async () => {
    const table: VariantRename[] = [{ component: 'Harness', from: kOld, to: kNew, reason: '' }];
    const { set, page } = fakePage('Harness', [[kNew, 'color/primary']], [
      [kOld, 'color/secondary'],
      [kNew, 'color/primary'],
    ]);
    const { lines, report: rep } = await parityReport(set, page, undefined, table);
    assertEq(rep.renameConflicts, [{ from: kOldKey, to: kNewKey }], 'the conflict is in the report');
    assertEq([rep.compared, rep.differing.length, rep.onlyDesigner], [1, 0, [kOldKey]], 'the direct pair is compared');
    assert(lines.some((l) => l.startsWith('  ⚠ 개명 목적지를')), 'the log warns');
  });

  await checkAsync('parityReport — the JSON envelope carries the renamed pairs', async () => {
    const table: VariantRename[] = [{ component: 'Harness', from: kOld, to: kNew, reason: '' }];
    const { set, page } = fakePage('Harness', [[kNew, 'color/primary']], [[kOld, 'color/primary']]);
    const rep = (await parityReport(set, page, undefined, table)).report;
    const json = serialiseParityEnvelope([rep, noDesignerCopyReport('Chip', '❖ Chip')], {
      capturedAt: 'x',
      fileKey: null,
      sourceHash: 'dev',
    });
    const parsed = JSON.parse(json) as { sets: ParitySetReport[] };
    assertEq(parsed.sets[0].renamed, [{ from: kOldKey, to: kNewKey }], 'old → new is in the file');
    assertEq(parsed.sets[1].renamed, undefined, 'a set without renames has no key');
    assertEq(formatParitySummary(parsed.sets), '⇄ 요약: 대조 1 세트 · 차이 0 → 1 세트 · 차이 있음 0 세트 · 사본 없음 1 세트 · 개명표로 짝지음 1 세트', 'summary');
  });
}

// A surface's fill lives on a `material` child and its border on the node. The
// reader folds the layer into the node's own box (a designer's copy has fill and
// stroke on one node), so the one thing folding would hide — a layer that sits
// over the border — has to be read as a difference of its own. The walk over a
// canvas needs Figma; what decides each of these is pure, and is here.
{
  const layer = (x: number, y: number, width: number, height: number, extra: Record<string, unknown> = {}) => ({
    type: 'RECTANGLE',
    name: 'material',
    x,
    y,
    width,
    height,
    ...extra,
  });
  const host = (stroke: Record<string, unknown>, children: unknown[]): SurfaceHostLike =>
    ({ width: 40, height: 40, children, ...stroke }) as unknown as SurfaceHostLike;
  const bordered = { strokes: [{}], strokeAlign: 'INSIDE', strokeWeight: 1 };

  check('a stroke reaches into the box by its weight inside, half centred, none outside', () => {
    assertEq(ownStrokeInsets(bordered), { top: 1, right: 1, bottom: 1, left: 1 }, 'inside');
    assertEq(ownStrokeInsets({ ...bordered, strokeAlign: 'CENTER', strokeWeight: 2 }), { top: 1, right: 1, bottom: 1, left: 1 }, 'centred');
    assertEq(ownStrokeInsets({ ...bordered, strokeAlign: 'OUTSIDE' }), { top: 0, right: 0, bottom: 0, left: 0 }, 'outside');
    assertEq(ownStrokeInsets({ strokeWeight: 1 }), { top: 0, right: 0, bottom: 0, left: 0 }, 'no stroke paints, no reach');
    assertEq(ownStrokeInsets({ strokes: [{ visible: false }], strokeWeight: 1 }), { top: 0, right: 0, bottom: 0, left: 0 }, 'a hidden stroke has no reach');
    assertEq(
      ownStrokeInsets({ ...bordered, strokeTopWeight: 0, strokeBottomWeight: 0 }),
      { top: 0, right: 1, bottom: 0, left: 1 },
      'a side with its own weight uses it',
    );
  });

  check('a layer inset by the stroke is the surface\'s fill and covers nothing', () => {
    const read = readSurfaceMaterial(host(bordered, [layer(1, 1, 38, 38)]));
    assertEq(read, { index: 0, covers: null }, 'inset layer');
  });

  check('a layer that fills the whole box over the stroke covers the border', () => {
    const read = readSurfaceMaterial(host(bordered, [layer(0, 0, 40, 40)]));
    assert(read != null && read.covers != null, 'the cover must be reported');
    assert(String(read?.covers).includes('covers the border'), `the line names what happened: ${String(read?.covers)}`);
    // Short on one side only is still a cover.
    const side = readSurfaceMaterial(host(bordered, [layer(1, 1, 39, 38)]));
    assert(side != null && side.covers != null, 'a layer reaching the right edge covers the right border');
  });

  check('with no stroke a full-size layer covers nothing, and a stroke on the sides insets only the sides', () => {
    assertEq(readSurfaceMaterial(host({ strokes: [] }, [layer(0, 0, 40, 40)])), { index: 0, covers: null }, 'no stroke');
    const sides = { ...bordered, strokeTopWeight: 0, strokeBottomWeight: 0 };
    assertEq(readSurfaceMaterial(host(sides, [layer(1, 0, 38, 40)])), { index: 0, covers: null }, 'sides inset, top and bottom full');
    assert(readSurfaceMaterial(host(sides, [layer(0, 0, 40, 40)]))?.covers != null, 'a full-size layer covers a side stroke');
  });

  check('only the visible, marked material layer is read — not a hidden one, a glass one, or another shape', () => {
    assertEq(readSurfaceMaterial(host(bordered, [layer(1, 1, 38, 38, { visible: false })])), null, 'hidden');
    assertEq(readSurfaceMaterial(host(bordered, [layer(1, 1, 38, 38, { name: 'glass' })])), null, 'glass is not the fill');
    assertEq(readSurfaceMaterial(host(bordered, [layer(1, 1, 38, 38, { type: 'FRAME' })])), null, 'a frame called material is a designer\'s');
    assertEq(readSurfaceMaterial(host(bordered, [])), null, 'no children');
    assertEq(
      readSurfaceMaterial(host(bordered, [{ type: 'TEXT', name: 'label' }, layer(1, 1, 38, 38)]))?.index,
      1,
      'the index is the layer\'s place among the children',
    );
  });
}

void renameParityChecks().then(layoutInsetChecks).then(
  () => {
    if (failures > 0) {
      console.error(`\n${failures} check(s) failed`);
      process.exit(1);
    }
    console.log('✅ designer-parity selftest passed');
  },
  (e: unknown) => {
    console.error(`FAIL  async harness threw\n      ${String(e)}`);
    process.exit(1);
  },
);
