/// <reference types="@figma/plugin-typings" />

// Self-test for src/overlapping-siblings.ts — the read-only "겹친 형제 보기" —
// and the `last-step` rewind warning that shipped with it (#4876).
//
// 이 검출기가 틀리는 방식은 두 방향이다:
//
//   1. **조용해진다** — 다른 세션 대역의 사본을 못 본다. 그래서 회귀를 주입한다:
//      실제로 문서에서 본 모양(같은 이름 · 다른 대역, 변형마다)을 그대로 만들어
//      잡는지 본다. 음성만 단언하면 `return []` 로 바꿔도 통과한다.
//   2. **정당한 반복을 신고한다** — 같은 세션이 만든 `item` × 4 는 겹친 형제가
//      아니다. 그걸 세면 0 이 정상값인 줄이 매번 수십으로 시작하고 곧 읽히지
//      않는다. 양성만 단언하면 이름만 같아도 세도록 바꿔도 통과한다.
//
// 그리고 배선 — 버튼 · 메시지 · 핸들러 · 비활성 목록 · Generate 꼬리 · selftest
// 체인. 무엇이 빠져도 타입체크는 통과하고 아무도 모른다.
//
// Figma 런타임 없음 — 판정은 `{id,name}` 순수 객체를 받는다. `figma.root` 를
// 만지는 `listOverlappingSiblings` 는 import 만 되고 호출되지 않는다. 그 lister 가
// 페이지 직계에서 무엇을 훑을지는 순수 `siblingSetsOfPage` 가 정하고, 여기서 가짜
// 페이지로 돈다 — 느슨한 컴포넌트(Popover 류)가 빠지는 회귀가 그 자리에서 난다.

import {
  classifySiblingSets,
  formatOverlappingSiblings,
  idBand,
  overlappingSiblingsOf,
  siblingSetsOfPage,
  type SiblingNode,
  type SiblingSceneNode,
  type SiblingSet,
} from '../src/overlapping-siblings';
import { formatLastStepRewind, parseLastStep } from '../src/last-step';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as {
  readFileSync(p: string, enc: string): string;
};
const { join } = require('path') as { join(...parts: string[]): string };

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
function codeLines(src: string): string {
  return src
    .split('\n')
    .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l))
    .join('\n');
}
function read(...parts: string[]): string {
  return readFileSync(join(process.cwd(), ...parts), 'utf8');
}

const n = (id: string, name: string): SiblingNode => ({ id, name });

// ── 1. 대역 ──────────────────────────────────────────────────────────────────

check('대역은 콜론 앞 숫자, 모양이 다르면 null', () => {
  assertEq(idBand('4206:1234'), 4206, 'plain id');
  assertEq(idBand('I6016:1;4206:2'), null, 'instance-inner id');
  assertEq(idBand('garbage'), null, 'garbage');
});

// ── 2. 판정 — 회귀 주입(양성) ────────────────────────────────────────────────

check('다른 세션 대역의 같은 이름 자식을 잡는다 (TimePicker field 두 벌)', () => {
  const found = overlappingSiblingsOf([n('6016:10', 'field'), n('4206:10', 'field'), n('6016:11', 'label')]);
  assertEq(found.map((x) => x.id), ['4206:10'], 'the older band is the overlap');
});

check('최신 대역이 여럿이어도 옛 대역만 센다', () => {
  const found = overlappingSiblingsOf([
    n('6068:1', 'text'),
    n('6068:2', 'text'),
    n('4206:1', 'text'),
    n('4206:2', 'text'),
  ]);
  assertEq(found.map((x) => x.id).sort(), ['4206:1', '4206:2'], 'both old-band copies, neither new one');
});

check('세 세션이면 최신이 아닌 두 대역이 다 잡힌다', () => {
  const found = overlappingSiblingsOf([n('7000:1', 'button'), n('6016:1', 'button'), n('4206:1', 'button')]);
  assertEq(found.map((x) => x.id).sort(), ['4206:1', '6016:1'], 'every band below the newest');
});

// ── 3. 판정 — 음성 ───────────────────────────────────────────────────────────

check('같은 대역의 정당한 반복(item × 4)은 세지 않는다', () => {
  const found = overlappingSiblingsOf([n('6016:1', 'item'), n('6016:2', 'item'), n('6016:3', 'item'), n('6016:4', 'item')]);
  assertEq(found.length, 0, 'same-session repeats');
});

check('이름이 다르면 대역이 달라도 세지 않는다', () => {
  const found = overlappingSiblingsOf([n('6016:1', 'field'), n('4206:1', 'label')]);
  assertEq(found.length, 0, 'different names');
});

check('대역을 모르는 노드는 판정에서 빠진다(세지 않는 쪽으로 틀린다)', () => {
  const found = overlappingSiblingsOf([n('6016:1', 'icon'), n('I6016:1;2:3', 'icon')]);
  assertEq(found.length, 0, 'an instance-inner id cannot be compared');
});

// ── 4. 분류와 문장 ───────────────────────────────────────────────────────────

const clean: SiblingSet = { set: 'Button', page: '❖ Button', variants: [[n('6016:1', 'label')], [n('6016:2', 'label')]] };
const menuItem: SiblingSet = {
  set: 'MenuItem',
  page: '❖ MenuItem',
  variants: [
    [n('6016:1', 'text'), n('4206:1', 'text'), n('6016:2', 'icon'), n('4206:2', 'icon')],
    [n('6016:3', 'text'), n('4206:3', 'text')],
  ],
};
const fab: SiblingSet = { set: 'Fab', page: '❖ Fab', variants: [[n('6068:1', 'button'), n('4206:9', 'button')]] };

check('세트별로 묶고 총합을 센다', () => {
  const report = classifySiblingSets([clean, menuItem, fab]);
  assertEq(report.setCount, 3, 'sets walked');
  assertEq(report.count, 4, 'overlaps total');
  assertEq(report.groups, [{ set: 'MenuItem', count: 3, variants: 2 }, { set: 'Fab', count: 1, variants: 1 }], 'groups');
});

check('문장 — 있을 때와 없을 때', () => {
  const some = formatOverlappingSiblings(classifySiblingSets([clean, menuItem, fab]));
  assert(some[0] === '겹친 형제 4 / 세트 3 — MenuItem: 3 · Fab: 1', `got ${some[0]}`);
  assert(some.length === 2 && some[1].includes('지우지') === false && some[1].includes('세기만'), 'the second line says it only counted');
  const none = formatOverlappingSiblings(classifySiblingSets([clean]));
  assertEq(none, ['겹친 형제 없음 ✅ (세트 1)'], 'nothing overlaps');
});

check('많으면 접고 몇 세트를 접었는지 적는다', () => {
  const many: SiblingSet[] = Array.from({ length: 12 }, (_, i) => ({
    set: `S${i}`,
    page: `❖ S${i}`,
    variants: [[n(`6016:${i}`, 'x'), n(`4206:${i}`, 'x')]],
  }));
  const line = formatOverlappingSiblings(classifySiblingSets(many))[0];
  assert(/… \(\+\d+ 세트\)$/.test(line), `folded tail missing: ${line}`);
});

// ── 4b. 페이지에서 훑을 단위 — 느슨한 컴포넌트 ─────────────────────────────

const sn = (type: string, id: string, name: string, children?: SiblingSceneNode[]): SiblingSceneNode => ({
  type,
  id,
  name,
  children,
});

check('느슨한 COMPONENT(Popover)는 자기 직계 자식을 한 변형으로 훑는다 — 사고의 원인 마스터', () => {
  // 실제 사고: Popover 마스터 직계에 `trigger` 가 두 세션 대역으로 두 벌 들어 있었고,
  // 그 중복이 TimePicker · Fab 안의 인스턴스로 번졌다.
  const popover = sn('COMPONENT', '6016:1', 'Popover', [
    sn('FRAME', '6016:2', 'trigger'),
    sn('FRAME', '4206:9', 'trigger'),
    sn('FRAME', '6016:3', 'panel'),
  ]);
  const timePicker = sn('COMPONENT_SET', '6016:100', 'TimePicker', [
    sn('COMPONENT', '6016:101', 'State=default', [sn('FRAME', '6016:102', 'field'), sn('FRAME', '4206:10', 'field')]),
  ]);
  const report = classifySiblingSets([
    ...siblingSetsOfPage('❖ Popover', [popover]),
    ...siblingSetsOfPage('❖ TimePicker', [timePicker]),
  ]);
  assertEq(report.setCount, 2, 'both the loose component and the set are walked');
  assertEq(
    report.groups,
    [{ set: 'Popover', count: 1, variants: 1 }, { set: 'TimePicker', count: 1, variants: 1 }],
    'the loose master must be reported, not only the set it spread into',
  );
});

check('세트의 변형은 변형마다 · 세트도 컴포넌트도 아닌 페이지 직계는 훑지 않는다', () => {
  const sets = siblingSetsOfPage('❖ X', [
    sn('COMPONENT_SET', '1:1', 'Set', [sn('COMPONENT', '1:2', 'A=1', [sn('TEXT', '1:3', 'label')]), sn('COMPONENT', '1:4', 'A=2')]),
    sn('COMPONENT', '1:5', 'Loose', [sn('TEXT', '1:6', 'label')]),
    sn('FRAME', '1:7', 'doc frame', [sn('TEXT', '1:8', 'x'), sn('TEXT', '4206:8', 'x')]),
  ]);
  assertEq(
    sets,
    [
      { set: 'Set', page: '❖ X', variants: [[{ id: '1:3', name: 'label' }], []], drawn: [null, null] },
      { set: 'Loose', page: '❖ X', variants: [[{ id: '1:6', name: 'label' }]], drawn: [null] },
    ],
    'units walked',
  );
});

// ── 4-1. 다시 그린 변형의 기록 — 유지가 섞은 대역은 겹친 형제가 아니다 ──────

const withData = (node: SiblingSceneNode, data: Record<string, string>): SiblingSceneNode => ({
  ...node,
  getPluginData: (key: string) => data[key] ?? '',
});

check('기록이 있는 변형: 대역이 갈린 같은 이름 형제도 기록 안이면 세지 않는다 (Command 의 구분선 둘)', () => {
  const kids = [{ id: '8164:230', name: 'Divider' }, { id: '8298:868', name: 'Divider' }];
  assertEq(overlappingSiblingsOf(kids).length, 1, 'by bands alone the kept one reads as a duplicate');
  assertEq(overlappingSiblingsOf(kids, new Set(['8164:230', '8298:868'])), [], 'the record clears both');
});

check('기록이 있는 변형: 기록 밖의 같은 이름 형제는 대역과 무관하게 센다', () => {
  const kids = [
    { id: '8164:230', name: 'Divider' },
    { id: '8298:868', name: 'Divider' },
    { id: '8300:1', name: 'Divider' },
  ];
  assertEq(overlappingSiblingsOf(kids, new Set(['8164:230', '8298:868'])), [{ id: '8300:1', name: 'Divider' }], 'outside the record');
});

check('기록은 이름이 겹친 묶음에만 쓰인다 — 홀로인 기록 밖 자식은 세지 않는다', () => {
  assertEq(overlappingSiblingsOf([{ id: '9:1', name: 'list' }], new Set(['1:1'])), [], 'a lone child is not a sibling');
});

check('siblingSetsOfPage 가 변형의 기록을 읽어 넘긴다', () => {
  const key = 'coui-drawn-children';
  const sets = siblingSetsOfPage('❖ Command', [
    sn('COMPONENT_SET', '1:1', 'Command', [
      withData(sn('COMPONENT', '1:2', 'A=1', [sn('INSTANCE', '8164:230', 'Divider'), sn('INSTANCE', '8298:868', 'Divider')]), {
        [key]: '8164:230,8298:868',
      }),
      sn('COMPONENT', '1:3', 'A=2', [sn('INSTANCE', '8164:231', 'Divider'), sn('INSTANCE', '8298:869', 'Divider')]),
    ]),
  ]);
  const report = classifySiblingSets(sets);
  assertEq(report.count, 1, 'only the variant without a record falls back to bands');
  assertEq(report.groups[0].variants, 1, 'one variant');
});

check('lister 가 페이지 직계를 siblingSetsOfPage 로 넘긴다(세트만 거르는 분기가 되돌아오지 않는다)', () => {
  const src = codeLines(read('src', 'overlapping-siblings.ts'));
  assert(/sets\.push\(\.\.\.siblingSetsOfPage\(page\.name, page\.children\)\);/.test(src), 'lister must delegate to siblingSetsOfPage');
  assert(!/node\.type !== 'COMPONENT_SET'\) continue/.test(src), 'a COMPONENT_SET-only filter skips loose components');
});

// ── 5. last-step 되감김 ──────────────────────────────────────────────────────

check('last-step 가 마지막 완료보다 과거면 경고한다', () => {
  const doneAt = Date.UTC(2026, 8, 13, 14, 7);
  const rewound = parseLastStep(`DropdownMenu:docs|${Date.UTC(2026, 8, 11, 16, 47)}`, doneAt + 1);
  const line = formatLastStepRewind(rewound, doneAt);
  assert(line !== null && line.includes('되감겼다') && line.includes('DropdownMenu:docs'), `got ${line}`);
  assert(line !== null && line.includes('2026-09-11 16:47Z') && line.includes('2026-09-13 14:07Z'), 'both times named');
});

check('정상 완료 직후(같은 시각) · 그 뒤의 발자국 · 기록 없음은 경고하지 않는다', () => {
  const doneAt = 1_000_000;
  assertEq(formatLastStepRewind(parseLastStep(`run:done|${doneAt}`, doneAt), doneAt), null, 'clean finish');
  assertEq(formatLastStepRewind(parseLastStep(`Button:build|${doneAt + 5}`, doneAt + 9), doneAt), null, 'a later run');
  assertEq(formatLastStepRewind(parseLastStep(`Button:build|${doneAt}`, doneAt), null), null, 'never finished');
  assertEq(formatLastStepRewind(parseLastStep('', doneAt), doneAt), null, 'never marked');
});

check('완료 시각은 run:done 마크 자신의 시각을 적는다(새 시계는 매 실행 경고를 만든다)', () => {
  const src = codeLines(read('src', 'last-step.ts'));
  assert(/const done = readLastStep\(\)\.markedAt \?\? Date\.now\(\);/.test(src), 'markLastDone must stamp the run:done mark’s own time');
});

// ── 6. 배선 ──────────────────────────────────────────────────────────────────

check('Generate 꼬리가 겹친 형제 요약을 감싸서 싣고, 자기 마커를 먼저 찍는다', () => {
  const build = codeLines(read('src', 'generate.ts'));
  assert(
    /try \{\s*overlapsAfterRun = formatOverlappingSiblings\(await listOverlappingSiblings\((?:\w+)?\)\);/.test(build),
    'the scan must be inside a try block',
  );
  assert(/\} catch \(e\) \{\s*overlapsAfterRun = \[/.test(build), 'the catch must still assign a warning line');
  assert(/for \(const line of overlapsAfterRun\) log\.push\(line\);/.test(build), 'the summary must reach the run log');
  const marker = build.indexOf("markStep('overlap-scan')");
  const call = build.indexOf('overlapsAfterRun = formatOverlappingSiblings(');
  assert(marker >= 0 && marker < call, "markStep('overlap-scan') must come before the scan");
  assert(build.indexOf("markStep('run:done')") > call, "run:done must stay the terminal marker");
  assert(build.indexOf('markLastDone();') > build.indexOf("markStep('run:done')"), 'markLastDone follows run:done');
});

check('Generate 가 시작할 때 되감김을 읽는다 — 자기 발자국을 찍기 전에', () => {
  const build = codeLines(read('src', 'generate.ts'));
  const read_ = build.indexOf('formatLastStepRewind(readLastStep(), readLastDoneAt())');
  const lock = build.indexOf('const lock = acquireRunLock(options);');
  assert(read_ >= 0 && read_ < lock, 'the rewind check must run before the lock (the first write)');
});

check('code.ts 가 overlapping-siblings 메시지를 라우팅한다', () => {
  const main = codeLines(read('code.ts'));
  assert(/msg\.type === 'overlapping-siblings'/.test(main), 'branch');
  assert(/formatOverlappingSiblings\(await listOverlappingSiblings\(\)\)/.test(main), 'call');
});

check('ui.html 의 버튼 · 핸들러 · 메시지 · 비활성 목록', () => {
  const ui = read('ui.html');
  assert(/id="overlapping-siblings"/.test(ui), 'button');
  assert(/getElementById\('overlapping-siblings'\)\.onclick/.test(ui), 'handler');
  assert(/type: 'overlapping-siblings'/.test(ui), 'message');
  assert(/'orphan-props', 'overlapping-siblings',/.test(ui), 'disabled-while-busy list');
});

check('selftest 체인에 들어 있다', () => {
  assert(read('package.json').includes('npm run selftest:overlapping-siblings'), 'chain');
});

if (failures > 0) {
  console.error(`\n${failures} failure(s)`);
  process.exit(1);
}
console.log('\nAll overlapping-siblings self-tests passed.');
