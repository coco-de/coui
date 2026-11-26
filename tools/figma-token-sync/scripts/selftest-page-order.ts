// Drives `compareByDocsOrder` and `docsOrderOf` against the REAL
// components.json (same no-fixture reasoning as the other selftests — the
// interesting claim is about this repo's actual catalog data, not a fixture
// that could drift from it).
//
// What this proves that a component test can't: `generateComponents()`'s
// page-placement pass used to sort each section block alphabetically
// (`a.name < b.name`). That comparator is correct Dart^H^H TypeScript and
// every existing suite is green under it — alphabetical order is still A
// total order, it's just the wrong one. A regression back to it would not
// throw, would not fail typecheck, and would not move any pixel a fidelity
// check compares. The only way to catch "sorted, but by the wrong key" is to
// assert the actual sequence against the catalog's curated order, which is
// what this file does, plus an explicit injected-regression check proving
// the assertion has teeth (alphabetical really does disagree with curated
// order for a real pair in this data).
import {
  compareByDocsOrder,
  docsOrderOf,
  isSidebarBoundaryPage,
  PageMove,
  pageOrderMoves,
  PageRef,
  pageToReuse,
  plannedPageOrder,
  resolvePlannedPages,
  sectionHeaderPageNameOf,
  withoutPageOrderPrefix,
} from '../src/data';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as {
  readFileSync(p: string, enc: 'utf8'): string;
};
// `process.cwd()`, not `__dirname` — the harness runs as a bundled `.cjs` in a
// temp path, so `__dirname` is not this file's directory. Same resolution
// `selftest-reverse-contract.ts` uses, and npm runs it from the package root.
const { join } = require('path') as { join(...parts: string[]): string };

// Mirrors `generate.ts`'s `kPageSectionOrder` — the ten sections whose
// header pages the placement pass ensures on every run.
const kPageSectionOrderForTest = [
  'Control', 'Form', 'Display', 'Layout', 'Navigation',
  'Menu', 'Overlay', 'Icon', 'Text', 'Infra',
];

let failures = 0;
function check(label: string, cond: boolean, detail?: string): void {
  if (cond) {
    console.log(`  ✓ ${label}`);
  } else {
    failures++;
    console.error(`  ✗ ${label}${detail ? ` — ${detail}` : ''}`);
  }
}

// ─── docsOrderOf reads the real catalog data ────────────────────────────────

const button = docsOrderOf('button');
const command = docsOrderOf('command');
const fab = docsOrderOf('fab');
check(
  "docsOrderOf — Control group's curated order (button, command, fab, …)",
  button !== null && command !== null && fab !== null && button < command && command < fab,
  `button=${button} command=${command} fab=${fab}`,
);

const textField = docsOrderOf('text_field');
check(
  "docsOrderOf — order is a FLAT position, not a per-group rank (Form's first item continues past Control's last)",
  textField !== null && fab !== null && textField > fab,
  `text_field=${textField} fab=${fab}`,
);

const unknown = docsOrderOf('no-such-component-xyz');
check('docsOrderOf — an uncatalogued slug is null, not fabricated', unknown === null);

// ─── compareByDocsOrder — the pure ranking function generate.ts sorts with ──

check(
  'compareByDocsOrder — orders by rank when both sides have one',
  compareByDocsOrder(0, 1, 'z', 'a') < 0 && compareByDocsOrder(1, 0, 'a', 'z') > 0,
);
check(
  'compareByDocsOrder — a ranked page always sorts before an unranked one, regardless of name',
  compareByDocsOrder(5, null, 'zzz', 'aaa') < 0 && compareByDocsOrder(null, 5, 'aaa', 'zzz') > 0,
);
check(
  'compareByDocsOrder — two unranked pages fall back to alphabetical',
  compareByDocsOrder(null, null, 'a', 'b') < 0 && compareByDocsOrder(null, null, 'b', 'a') > 0,
);

// ─── The regression this file exists to catch ───────────────────────────────
//
// Reproduces the OLD comparator (`a.name < b.name`) against the same two real
// pages and shows it disagrees with the curated order — proof that "both
// pass" isn't just this test being too weak to tell them apart, which is
// exactly the failure mode a rewritten-to-be-vacuous assertion would have.
const alphabetical = (aName: string, bName: string): number =>
  aName < bName ? -1 : aName > bName ? 1 : 0;

// Control's curated order is button/command/fab/hover/theme-controller/
// filter — Hover (3) before Filter (5). Alphabetically "Filter" < "Hover"
// ('F' < 'H'), the opposite call. Any pair where the two orderings actually
// disagree works for this proof; this is a real one in today's data rather
// than a constructed one, so the proof stays true as long as the catalog
// keeps Filter listed after Hover in Control.
const hover = docsOrderOf('hover');
const filter = docsOrderOf('filter');
const curated = compareByDocsOrder(hover, filter, 'Hover', 'Filter');
const old = alphabetical('Hover', 'Filter');
check(
  'regression proof — alphabetical order disagrees with curated order for a real pair (Hover vs Filter)',
  curated < 0 && old > 0,
  `compareByDocsOrder(Hover,Filter)=${curated} (Hover sorts first, correct) ` +
    `alphabetical(Hover,Filter)=${old} (Hover sorts AFTER Filter, wrong)`,
);

// ── Page reuse: the ordering prefix must not hide an existing page ──────
//
// The regression: `ensurePage` matched page names EXACTLY, and every section
// header on the canvas carries an ordering prefix (`01. 🎛️ CONTROL`) that
// the generated name (`🎛️ CONTROL`) does not. All ten missed, and each run
// minted a second empty header for every section — whatever the scope, since
// placement normalization is not scoped. A run that built ONE component took
// the real file from 188 pages to 198, and nothing failed.
const kCanvasHeaders = [
  '01. 🎛️ CONTROL',
  '02. 📝 FORM',
  '03. 🖥️ DISPLAY',
  '04. 📐 LAYOUT',
  '05. 🧭 NAVIGATION',
  '06. 🗂️ MENU',
  '07. 💬 OVERLAY',
  '08. ⭐ ICON',
  '09. 🔤 TEXT',
  '10. 🧱 INFRA',
];

check(
  'withoutPageOrderPrefix strips the ordering prefix and nothing else',
  withoutPageOrderPrefix('01. 🎛️ CONTROL') === '🎛️ CONTROL' &&
    withoutPageOrderPrefix('1-1. Semantic') === 'Semantic' &&
    withoutPageOrderPrefix('❖ Button') === '❖ Button',
  `got "${withoutPageOrderPrefix('01. 🎛️ CONTROL')}" / ` +
    `"${withoutPageOrderPrefix('❖ Button')}"`,
);

// The real shape of the bug: every generated section header resolves onto
// the numbered page already on the canvas instead of asking for a new one.
const unmatched = kPageSectionOrderForTest
  .map((s) => sectionHeaderPageNameOf(s))
  .filter((target) => pageToReuse(kCanvasHeaders, target) === null);
check(
  'every section header reuses its numbered page instead of minting a duplicate',
  unmatched.length === 0,
  `${unmatched.length} header(s) would be created anew: ${unmatched.join(', ')}`,
);

check(
  'the reused page is the numbered one, by name',
  pageToReuse(kCanvasHeaders, '🎛️ CONTROL') === '01. 🎛️ CONTROL',
  `got ${String(pageToReuse(kCanvasHeaders, '🎛️ CONTROL'))}`,
);

check(
  'an exact match still wins over the prefix-tolerant one',
  pageToReuse(['🎛️ CONTROL', '01. 🎛️ CONTROL'], '🎛️ CONTROL') === '🎛️ CONTROL',
  `got ${String(pageToReuse(['🎛️ CONTROL', '01. 🎛️ CONTROL'], '🎛️ CONTROL'))}`,
);

check(
  'a genuinely absent page still reports as create',
  pageToReuse(kCanvasHeaders, '❖ ValidatorHint') === null,
  `got ${String(pageToReuse(kCanvasHeaders, '❖ ValidatorHint'))}`,
);

// Regression proof — an exact-name lookup (what shipped) finds none of them.
const exactOnly = kPageSectionOrderForTest
  .map((s) => sectionHeaderPageNameOf(s))
  .filter((target) => kCanvasHeaders.includes(target));
check(
  'regression proof — the exact-name lookup that shipped matches zero headers',
  exactOnly.length === 0,
  `exact match found ${exactOnly.length}, so this proof no longer proves anything`,
);

// ─── plannedPageOrder — what the plugin's own pages should read as ──────────
//
// The plan is the same whether or not the run may move existing pages: a run
// that leaves them alone still needs it to place the pages it created.
console.log('plannedPageOrder — headers and blocks');
{
  const order = ['Control', 'Form', 'Display'];
  const pages = new Map<string, readonly string[]>([
    ['Control', ['❖ Button', '❖ Toggle']],
    ['Display', ['❖ Badge']],
  ]);
  const planned = plannedPageOrder(order, pages);
  check(
    'a header precedes each non-empty section, in section order',
    planned.join('|') ===
      [
        sectionHeaderPageNameOf('Control'),
        '❖ Button',
        '❖ Toggle',
        sectionHeaderPageNameOf('Display'),
        '❖ Badge',
      ].join('|'),
    planned.join('|'),
  );
  check(
    'an empty section gets no header — a scoped run plants none for what it never built',
    !planned.includes(sectionHeaderPageNameOf('Form')),
  );
}

// ─── 전체 새로 생성 — 세 스위치가 한 버튼에 묶여 있는가 ─────────────────────
//
// "이 파일을 코드와 처음부터 맞춰라" 는 세 가지를 동시에 뜻한다: 선택 무시(전
// 범위), 해시 무시(`force`), 페이지 정리(`reorderPages`). 셋 중 하나가 빠진
// 실행은 **성공한 것처럼 보인다** — 로그는 초록이고, 빠진 것이 무엇인지는
// 캔버스를 재봐야만 드러난다. 실제로 이 세션에서 그 형태를 겪었다: 굵기가
// 반영된 줄 알았던 세트의 절반이 옛 굵기였고, 완료 로그만으로는 알 수 없었다.
//
// UI 는 TypeScript 가 아니라 검사할 타입 표면이 없으므로 소스를 읽는다 —
// `selftest-reverse-contract.ts` 가 종료 코드 계약에 쓰는 것과 같은 수단이고,
// 같은 이유다: 이 계약이 무너지는 방식이 실행 결과에서 보이지 않는다.
console.log('전체 새로 생성 — 세 스위치');
{
  const uiPath = join(process.cwd(), 'ui.html');
  const ui = readFileSync(uiPath, 'utf8');
  const handlerAt = ui.indexOf("getElementById('generate-all')");
  check('전체 새로 생성 버튼에 핸들러가 있다', handlerAt !== -1);
  // The handler's own postMessage — bounded so the next handler's payload is
  // not read as this one's.
  const payload = ui.slice(handlerAt, handlerAt + 900);
  check('해시를 무시한다 (force: true)', /force:\s*true/.test(payload), payload.slice(0, 0));
  check('페이지를 정리한다 (reorderPages: true)', /reorderPages:\s*true/.test(payload));
  check(
    '선택을 무시한다 (entryNames: undefined — 전 범위)',
    /entryNames:\s*undefined/.test(payload),
  );

  // And the everyday button must NOT carry them — that is the whole reason
  // the two are separate buttons rather than one with checkboxes.
  const plainAt = ui.indexOf("getElementById('generate')");
  const plainPayload = ui.slice(plainAt, plainAt + 1400);
  // The everyday button hardcodes NEITHER — both come from checkboxes, so a
  // scoped force is possible (fix one component without redrawing 147) and an
  // ordinary run stays cheap.
  check(
    '일상 버튼은 해시 무시를 하드코딩하지 않는다',
    !/force:\s*true/.test(plainPayload),
  );
  check(
    '일상 버튼의 페이지 정리는 체크박스가 정한다',
    /reorderPages\s*=\s*document\.getElementById/.test(ui) &&
      !/reorderPages:\s*true/.test(plainPayload),
  );
  check(
    '일상 버튼의 해시 무시도 체크박스가 정한다 — 범위를 존중하는 force',
    /force\s*=\s*document\.getElementById\('force-rebuild'\)/.test(ui),
  );
  // Force is a remedy, not a mode. Left checked it makes every later run pay
  // for a rebuild nobody asked for, and the only symptom is slowness.
  check(
    '실행이 끝나면 해시 무시가 자동으로 해제된다',
    /getElementById\('force-rebuild'\)\.checked\s*=\s*false/.test(ui),
  );
}

// ─── The ordering decision — fixtures ───────────────────────────────────────
//
// Pages are written as names; ids are the names made unique with `#n` so the
// many dividers that share a name stay distinct, which is the whole reason
// the decision takes ids.
const refs = (names: readonly string[]): PageRef[] => {
  const seen = new Map<string, number>();
  return names.map((name) => {
    const n = (seen.get(name) ?? 0) + 1;
    seen.set(name, n);
    return { id: `${name}#${n}`, name };
  });
};
const idOf = (pages: readonly PageRef[], name: string, nth = 1): string => {
  const hits = pages.filter((p) => p.name === name);
  return hits[nth - 1]?.id ?? `<no ${name}>`;
};

/** What `generate.ts` does with a move — off the end, then into place — under
 *  both readings of a same-parent `insertChild` index, since Figma documents
 *  neither. */
function applyMoves(
  pages: readonly PageRef[],
  moves: readonly PageMove[],
  reading: 'after-removal' | 'before-removal',
  appendFirst = true,
): PageRef[] {
  const list = [...pages];
  for (const m of moves) {
    const page = list.find((p) => p.id === m.id)!;
    if (appendFirst) {
      list.splice(list.indexOf(page), 1);
      list.push(page); // appendChild
    }
    const at = list.findIndex((p) => p.id === m.anchorId) + (m.side === 'after' ? 1 : 0);
    const from = list.indexOf(page);
    if (from === at) continue;
    if (reading === 'after-removal') {
      list.splice(from, 1);
      list.splice(at, 0, page);
    } else {
      // The index names a slot in the list as it stood before removal.
      list.splice(at, 0, page);
      list.splice(list.lastIndexOf(page), 1);
    }
  }
  return list;
}

interface Shape {
  planOrder: boolean;
  headersGlued: boolean;
  othersKeptOrder: boolean;
}
function shapeAfter(before: readonly PageRef[], after: readonly PageRef[], plan: readonly string[]): Shape {
  const ids = resolvePlannedPages(after, plan);
  const owned = new Set(ids.filter((x): x is string => x !== null));
  const ownedInFile = after.filter((p) => owned.has(p.id)).map((p) => p.id);
  const planIds = ids.filter((x): x is string => x !== null);
  let headersGlued = true;
  plan.forEach((name, k) => {
    if (name.startsWith('❖ ') || ids[k] === null) return;
    const next = ids.slice(k + 1).find((x) => x !== null);
    const at = after.findIndex((p) => p.id === ids[k]);
    if (next !== undefined && after[at + 1]?.id !== next) headersGlued = false;
  });
  const others = (list: readonly PageRef[]) => list.filter((p) => !owned.has(p.id)).map((p) => p.id).join('|');
  return {
    planOrder: ownedInFile.join('|') === planIds.join('|'),
    headersGlued,
    othersKeptOrder: others(before) === others(after),
  };
}

console.log('isSidebarBoundaryPage — what ends a block');
for (const name of ['---', '--', '999. Screen', '01-1. Color 개편 시안 (2026-10-07)']) {
  check(`"${name}" is a boundary`, isSidebarBoundaryPage(name));
}
for (const name of ['     Hover', '❖ Tag', '무드 프리뷰 1차 (2026-10-08)', '📚 Component', '❖ Button']) {
  check(`"${name}" is not a boundary`, !isSidebarBoundaryPage(name));
}

console.log('resolvePlannedPages — which page each plan entry is');
{
  const pages = refs(['01. 🎛️ CONTROL', '❖ Button', '---', '❖ Button', '---', '02. 📝 FORM']);
  const ids = resolvePlannedPages(pages, ['🎛️ CONTROL', '❖ Button', '❖ Button', '📝 FORM', '❖ Ghost']);
  check('a numbered header answers to the bare plan name', ids[0] === idOf(pages, '01. 🎛️ CONTROL'));
  check(
    'two pages with one name are two different entries, in document order',
    ids[1] === idOf(pages, '❖ Button', 1) && ids[2] === idOf(pages, '❖ Button', 2),
  );
  check('a missing page is null, not a guess', ids[4] === null);
  const both = refs(['01. 🎛️ CONTROL', '🎛️ CONTROL']);
  check(
    'an exact name wins over a numbered one',
    resolvePlannedPages(both, ['🎛️ CONTROL'])[0] === idOf(both, '🎛️ CONTROL'),
  );
}

// The shape the library file was in: numbered headers dragged behind the
// previous section's last page, new pages piled at the end, a divider and a
// designer's note in between.
const kPlan = [
  '🎛️ CONTROL', '❖ Button', '❖ Filter', '❖ CommandSearch',
  '📝 FORM', '❖ TextField', '❖ Select',
  '🖥️ DISPLAY', '❖ Badge', '❖ Chip',
];
const kObserved = refs([
  'Cover', '---',
  '01. 🎛️ CONTROL', '❖ Button', '❖ Filter', '---',
  '❖ TextField', '❖ Select',
  '03. 🖥️ DISPLAY', '---', '❖ Badge', '❖ Chip', '     Swap',
  '999. Screen', '❖ Phone',
  '❖ CommandSearch', '02. 📝 FORM',
]);

console.log('pageOrderMoves — the observed file, sorted once');
{
  const decision = pageOrderMoves(kObserved, kPlan, { scope: 'all', created: new Set() });
  const after = applyMoves(kObserved, decision.moves, 'after-removal');
  const shape = shapeAfter(kObserved, after, kPlan);
  check('every plugin page ends up in plan order', shape.planOrder, after.map((p) => p.name).join(' | '));
  check('every header sits directly above its first page', shape.headersGlued, after.map((p) => p.name).join(' | '));
  check('no one else’s page changes order', shape.othersKeptOrder);
  const at = (name: string) => after.findIndex((p) => p.name === name);
  check('the page that was created at the end goes to its section', at('❖ CommandSearch') === at('❖ Filter') + 1);
  check(
    'the FORM header lands on its first page, below the divider that ends CONTROL',
    at('02. 📝 FORM') === at('❖ TextField') - 1 && after[at('02. 📝 FORM') - 1].name === '---',
  );
  check(
    'only plugin pages move',
    decision.moves.every((m) => resolvePlannedPages(kObserved, kPlan).includes(m.id)),
  );
  check(
    'both readings of insertChild give the predicted order',
    applyMoves(kObserved, decision.moves, 'before-removal').map((p) => p.id).join('|') ===
      decision.order.join('|') &&
      after.map((p) => p.id).join('|') === decision.order.join('|'),
  );
  const again = pageOrderMoves(after, kPlan, { scope: 'all', created: new Set() });
  check('a second run moves nothing', again.moves.length === 0, `${again.moves.length} move(s)`);

  // The agreement above is only true because the page goes off the end
  // first. Without that step the two readings part ways on this very file —
  // so the step, and the order generate.ts does it in, is what is under test.
  const bareA = applyMoves(kObserved, decision.moves, 'after-removal', false).map((p) => p.id).join('|');
  const bareB = applyMoves(kObserved, decision.moves, 'before-removal', false).map((p) => p.id).join('|');
  check('regression proof — without appendChild first, the two readings disagree', bareA !== bareB);
  const generate = readFileSync(join(process.cwd(), 'src', 'generate.ts'), 'utf8');
  const loop = generate.slice(generate.indexOf('for (const move of decision.moves)'));
  const appendAt = loop.indexOf('figma.root.appendChild(page)');
  const insertAt = loop.indexOf('figma.root.insertChild(at, page)');
  check(
    'generate.ts moves a page off the end before inserting it',
    appendAt !== -1 && insertAt !== -1 && appendAt < insertAt,
  );
}

// Injected regression: the loop that shipped, run on the same kind of file.
// It must reproduce the drag — otherwise the assertions above prove nothing
// about it.
console.log('regression proof — the shipped loop drags a numbered header to the end');
{
  const shippedLoop = (names: readonly string[], plan: readonly string[]): string[] => {
    const list = [...names];
    let previous: string | null = null;
    for (const name of plan) {
      const existing = list.includes(name) ? name : null;
      const page = existing ?? pageToReuse(list, name) ?? name;
      if (!list.includes(page)) list.push(page);
      if (!existing && previous) {
        list.splice(list.indexOf(page), 1);
        list.splice(list.indexOf(previous) + 1, 0, page);
      }
      previous = page;
    }
    return list;
  };
  const names = ['01. 🎛️ CONTROL', '❖ Button', '---', '02. 📝 FORM', '❖ TextField', '❖ CommandSearch'];
  const plan = ['🎛️ CONTROL', '❖ Button', '❖ CommandSearch', '📝 FORM', '❖ TextField'];
  const shipped = shippedLoop(names, plan);
  check(
    'the shipped loop puts "02. 📝 FORM" after the page created at the end',
    shipped[shipped.length - 1] === '02. 📝 FORM',
    shipped.join(' | '),
  );
  const pages = refs(names);
  const decision = pageOrderMoves(pages, plan, {
    scope: 'all',
    created: new Set([idOf(pages, '❖ CommandSearch')]),
  });
  const fixed = applyMoves(pages, decision.moves, 'after-removal').map((p) => p.name);
  check(
    'the decision keeps "02. 📝 FORM" above its first page',
    fixed.join('|') === ['01. 🎛️ CONTROL', '❖ Button', '❖ CommandSearch', '---', '02. 📝 FORM', '❖ TextField'].join('|'),
    fixed.join(' | '),
  );
  const generate = readFileSync(join(process.cwd(), 'src', 'generate.ts'), 'utf8');
  check('generate.ts orders pages through pageOrderMoves', generate.includes('pageOrderMoves('));
  check(
    'generate.ts no longer looks pages up by exact name in the ordering pass',
    !generate.includes('figma.root.children.find((p) => p.name === name)'),
  );
}

console.log('pageOrderMoves — a tidy file and the pages a run creates');
{
  const tidyNames = [
    'Cover', '01. 🎛️ CONTROL', '❖ Button', '     Hover', '---',
    '04. 📐 LAYOUT', '❖ Scaffold', '❖ BottomActionBar', '     Gap', '--',
    '999. Screen', '❖ Phone',
  ];
  const plan = ['🎛️ CONTROL', '❖ Button', '📐 LAYOUT', '❖ Scaffold', '❖ PageHeader', '❖ PanelHeader', '❖ BottomActionBar'];
  const tidy = refs(tidyNames);
  const tidyPlan = plan.filter((n) => n !== '❖ PageHeader' && n !== '❖ PanelHeader');
  const still = pageOrderMoves(tidy, tidyPlan, { scope: 'all', created: new Set() });
  check('a tidy file moves nothing', still.moves.length === 0, `${still.moves.length} move(s)`);
  check('…and keeps every plugin page', still.kept === tidyPlan.length, `kept ${still.kept}`);

  // The build pass makes pages in its own order and `createPage` appends.
  const withNew = refs([...tidyNames, '❖ PanelHeader', '❖ PageHeader']);
  const created = new Set([idOf(withNew, '❖ PanelHeader'), idOf(withNew, '❖ PageHeader')]);
  for (const scope of ['created', 'all'] as const) {
    const decision = pageOrderMoves(withNew, plan, { scope, created });
    const after = applyMoves(withNew, decision.moves, 'after-removal').map((p) => p.name);
    const at = (name: string) => after.indexOf(name);
    check(
      `${scope}: new pages land after Scaffold, in plan order`,
      at('❖ PageHeader') === at('❖ Scaffold') + 1 && at('❖ PanelHeader') === at('❖ PageHeader') + 1,
      after.join(' | '),
    );
    check(`${scope}: only the new pages move`, decision.moves.every((m) => created.has(m.id)));
  }

  // Out of order, but `created` must not touch what it did not make.
  const messy = refs(['❖ Scaffold', '04. 📐 LAYOUT', '❖ Button', '01. 🎛️ CONTROL', '❖ PageHeader']);
  const scoped = pageOrderMoves(messy, plan, { scope: 'created', created: new Set([idOf(messy, '❖ PageHeader')]) });
  check('created: an existing page out of order stays put', scoped.moves.every((m) => m.id === idOf(messy, '❖ PageHeader')));

  // A page created past someone else's title is still in sequence among the
  // plugin's pages — and is still moved, because a run never keeps its own.
  const pastTitle = refs([...tidyNames, '❖ PanelHeader']);
  const planTail = ['🎛️ CONTROL', '❖ Button', '📐 LAYOUT', '❖ Scaffold', '❖ BottomActionBar', '❖ PanelHeader'];
  const moved = pageOrderMoves(pastTitle, planTail, { scope: 'all', created: new Set([idOf(pastTitle, '❖ PanelHeader')]) });
  const afterTitle = applyMoves(pastTitle, moved.moves, 'after-removal').map((p) => p.name);
  check(
    'all: a new page under "999. Screen" moves into its own block',
    afterTitle.indexOf('❖ PanelHeader') === afterTitle.indexOf('❖ BottomActionBar') + 1,
    afterTitle.join(' | '),
  );

  // The same for a page that was already there: in sequence, but under
  // someone else's title, it is not in its block.
  const strayNames = ['01. 🎛️ CONTROL', '❖ Button', '---', '999. Screen', '❖ Phone', '❖ Toggle'];
  const stray = refs(strayNames);
  const strayMoves = pageOrderMoves(stray, ['🎛️ CONTROL', '❖ Button', '❖ Toggle'], { scope: 'all', created: new Set() });
  const strayAfter = applyMoves(stray, strayMoves.moves, 'after-removal').map((p) => p.name);
  check(
    'all: an existing page past "999. Screen" goes back to its block',
    strayAfter.join('|') === ['01. 🎛️ CONTROL', '❖ Button', '❖ Toggle', '---', '999. Screen', '❖ Phone'].join('|'),
    strayAfter.join(' | '),
  );
}

console.log('pageOrderMoves — a header whose first page is new stays where it is');
{
  const run = (names: string[], plan: string[], createdNames: string[], scope: 'all' | 'created' = 'all') => {
    const pages = refs(names);
    const created = new Set(createdNames.map((n) => idOf(pages, n)));
    const decision = pageOrderMoves(pages, plan, { scope, created });
    return { decision, after: applyMoves(pages, decision.moves, 'after-removal').map((p) => p.name) };
  };
  // The section's only page is new: the header and the note under it stay.
  const a = run(
    ['---', '04. 📐 LAYOUT', '     Gap', '--', '05. 🧭 NAVIGATION', '❖ NavigationBar', '❖ Scaffold'],
    ['📐 LAYOUT', '❖ Scaffold', '🧭 NAVIGATION', '❖ NavigationBar'],
    ['❖ Scaffold'],
  );
  check(
    'the new page goes under its header; the note and divider stay below it',
    a.after.join('|') === ['---', '04. 📐 LAYOUT', '❖ Scaffold', '     Gap', '--', '05. 🧭 NAVIGATION', '❖ NavigationBar'].join('|'),
    a.after.join(' | '),
  );
  // The last section: no kept page after it to anchor on.
  const b = run(
    ['01. 🎛️ CONTROL', '❖ Button', '---', '10. 🧱 INFRA', '     note', '❖ Portal'],
    ['🎛️ CONTROL', '❖ Button', '🧱 INFRA', '❖ Portal'],
    ['❖ Portal'],
  );
  check(
    'the last section’s header is not dragged above the divider',
    b.after.join('|') === ['01. 🎛️ CONTROL', '❖ Button', '---', '10. 🧱 INFRA', '❖ Portal', '     note'].join('|'),
    b.after.join(' | '),
  );
  // One new page is one move — not the header.
  const c = run(
    ['01. 🎛️ CONTROL', '❖ Button', '---', '03. 🖥️ DISPLAY', '---', '04. 📐 LAYOUT', '❖ Scaffold', '❖ Badge'],
    ['🎛️ CONTROL', '❖ Button', '🖥️ DISPLAY', '❖ Badge', '📐 LAYOUT', '❖ Scaffold'],
    ['❖ Badge'],
  );
  check(
    'a new first page moves; its header does not',
    c.decision.moves.length === 1 &&
      c.after.join('|') === ['01. 🎛️ CONTROL', '❖ Button', '---', '03. 🖥️ DISPLAY', '❖ Badge', '---', '04. 📐 LAYOUT', '❖ Scaffold'].join('|'),
    `${c.decision.moves.length} move(s): ${c.after.join(' | ')}`,
  );
  // Headers already there, every component new.
  const d = run(
    ['Cover', '---', '01. 🎛️ CONTROL', '---', '02. 📝 FORM', '❖ TextField', '❖ Button'],
    ['🎛️ CONTROL', '❖ Button', '📝 FORM', '❖ TextField'],
    ['❖ TextField', '❖ Button'],
  );
  check(
    'existing headers stay put and take their new pages',
    d.after.join('|') === ['Cover', '---', '01. 🎛️ CONTROL', '❖ Button', '---', '02. 📝 FORM', '❖ TextField'].join('|'),
    d.after.join(' | '),
  );

  // A new section: the run made its header too. Both scopes put the pair
  // between the blocks — not inside the block before it.
  for (const scope of ['created', 'all'] as const) {
    const e = run(
      ['01. 🎛️ CONTROL', '❖ Button', '     Hover', '---', '04. 📐 LAYOUT', '❖ Scaffold', '❖ Badge', '🖥️ DISPLAY'],
      ['🎛️ CONTROL', '❖ Button', '🖥️ DISPLAY', '❖ Badge', '📐 LAYOUT', '❖ Scaffold'],
      ['❖ Badge', '🖥️ DISPLAY'],
      scope,
    );
    check(
      `${scope}: a new section lands as a block of its own`,
      e.after.join('|') === ['01. 🎛️ CONTROL', '❖ Button', '     Hover', '---', '🖥️ DISPLAY', '❖ Badge', '04. 📐 LAYOUT', '❖ Scaffold'].join('|'),
      e.after.join(' | '),
    );
  }
  const generate = readFileSync(join(process.cwd(), 'src', 'generate.ts'), 'utf8');
  check(
    'generate.ts creates a missing header in either scope (the header loop is not behind scope === all)',
    /\n  for \(const name of plan\) \{\n    if \(name\.startsWith\(kComponentPageNamePrefix\)\) continue;\n    if \(pageToReuse\(/.test(generate),
  );
}

console.log('pageOrderMoves — two pages answer to one header');
{
  const plan = ['🎛️ CONTROL', '❖ Button', '📝 FORM', '❖ TextField'];
  let pages = refs(['01. 🎛️ CONTROL', '❖ Button', '📝 FORM', '---', '📝 FORM', '     note', '❖ TextField']);
  const movesPerRun: number[] = [];
  for (let runIndex = 0; runIndex < 4; runIndex++) {
    const decision = pageOrderMoves(pages, plan, { scope: 'all', created: new Set() });
    movesPerRun.push(decision.moves.length);
    pages = applyMoves(pages, decision.moves, 'after-removal');
  }
  check(
    'the same header is chosen every run, so the file settles',
    movesPerRun.slice(1).every((n) => n === 0),
    `moves per run: ${movesPerRun.join(', ')}`,
  );
}

console.log('pageOrderMoves — a fresh file');
{
  const plan = ['🎛️ CONTROL', '❖ Button', '❖ Toggle', '🖥️ DISPLAY', '❖ Badge', '❖ Chip'];
  // Components created in an order unrelated to the plan, headers last.
  const pages = refs(['Cover', '🎨 Palette', '❖ Chip', '❖ Toggle', '❖ Badge', '❖ Button', '🎛️ CONTROL', '🖥️ DISPLAY']);
  const created = new Set(pages.filter((p) => p.name !== 'Cover' && p.name !== '🎨 Palette').map((p) => p.id));
  const decision = pageOrderMoves(pages, plan, { scope: 'all', created });
  const after = applyMoves(pages, decision.moves, 'after-removal');
  check(
    'the blocks come out contiguous, after the pages that were there',
    after.map((p) => p.name).join('|') === ['Cover', '🎨 Palette', ...plan].join('|'),
    after.map((p) => p.name).join(' | '),
  );
  check('a second run moves nothing', pageOrderMoves(after, plan, { scope: 'all', created: new Set() }).moves.length === 0);
}

// Properties over many shapes — seeded, so a failure reproduces.
console.log('pageOrderMoves — properties over generated files');
{
  let seed = 0x5eed;
  const rand = (n: number): number => {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed % n;
  };
  const kOthers = ['---', '--', '999. Screen', '     Note', '시안 (2026-10-08)', '❖ Draft'];
  let worst = '';
  let bad = 0;
  let notOptimal = 0;
  for (let round = 0; round < 1500; round++) {
    const plan: string[] = [];
    const sections = 1 + rand(4);
    for (let s = 0; s < sections; s++) {
      plan.push(`H${s}`);
      const count = 1 + rand(5);
      for (let c = 0; c < count; c++) plan.push(`❖ S${s}P${c}`);
    }
    const names = plan.map((n) => (n.startsWith('H') && rand(2) === 0 ? `0${n.slice(1)}. ${n}` : n));
    // Now and then a stray second page that answers to a header.
    if (rand(6) === 0) names.push(`${plan[0]}`);
    for (let o = rand(9); o > 0; o--) names.push(kOthers[rand(kOthers.length)]);
    for (let i = names.length - 1; i > 0; i--) {
      const j = rand(i + 1);
      [names[i], names[j]] = [names[j], names[i]];
    }
    const pages = refs(names);
    const ownedIds = resolvePlannedPages(pages, plan);
    const created = new Set(ownedIds.filter((id): id is string => id !== null && rand(7) === 0));
    const decision = pageOrderMoves(pages, plan, { scope: 'all', created });
    const a = applyMoves(pages, decision.moves, 'after-removal');
    const b = applyMoves(pages, decision.moves, 'before-removal');
    const shape = shapeAfter(pages, a, plan);
    const rerun = pageOrderMoves(a, plan, { scope: 'all', created: new Set() });
    const ok =
      shape.planOrder &&
      shape.headersGlued &&
      shape.othersKeptOrder &&
      rerun.moves.length === 0 &&
      a.map((p) => p.id).join('|') === b.map((p) => p.id).join('|') &&
      a.map((p) => p.id).join('|') === decision.order.join('|');
    if (!ok) {
      bad++;
      if (worst === '') worst = `${JSON.stringify(names)} :: ${JSON.stringify(plan)} → ${a.map((p) => p.name).join(' | ')}`;
    }

    // Small files: nothing could have kept more pages in place.
    if (plan.length <= 12 && created.size === 0) {
      const ids = ownedIds as string[];
      const pos = ids.map((id) => pages.findIndex((p) => p.id === id));
      let sec = -1;
      const section = plan.map((n) => (n.startsWith('❖ ') ? sec : ++sec));
      const owned = new Set(ids);
      const boundary = pages.map((p) => !owned.has(p.id) && isSidebarBoundaryPage(p.name));
      const glued = (k: number) => plan[k].startsWith('❖ ') || pages[pos[k] + 1]?.id === ids[k + 1];
      let best = 0;
      for (let mask = 1; mask < 1 << plan.length; mask++) {
        const chosen = plan.map((_, k) => k).filter((k) => mask & (1 << k));
        if (!chosen.every(glued)) continue;
        let valid = true;
        for (let c = 1; c < chosen.length && valid; c++) {
          const [i, j] = [chosen[c - 1], chosen[c]];
          if (pos[i] >= pos[j]) valid = false;
          else if (section[i] === section[j] && boundary.slice(pos[i] + 1, pos[j]).some(Boolean)) valid = false;
        }
        if (valid) best = Math.max(best, chosen.length);
      }
      if (best > 0 && decision.kept !== best) notOptimal++;
    }
  }
  check('1500 generated files: plan order, glued headers, others untouched, idempotent', bad === 0, `${bad} bad — first: ${worst}`);
  check('small files keep as many pages in place as possible', notOptimal === 0, `${notOptimal} not optimal`);
}

console.log('the controls that decide how much may move');
{
  const code = readFileSync(join(process.cwd(), 'code.ts'), 'utf8');
  const verifyAt = code.indexOf('verifyIdentityIdempotence(');
  check(
    'verify does not rearrange the file — its runs pass reorderPages: false',
    verifyAt !== -1 && /reorderPages:\s*false/.test(code.slice(verifyAt, verifyAt + 400)),
  );
  const ui = readFileSync(join(process.cwd(), 'ui.html'), 'utf8');
  const hintAt = ui.indexOf('id="reorder-pages"');
  const hint = ui.slice(hintAt, hintAt + 900);
  check(
    'the "페이지 순서 정리" hint no longer describes a sort that pushes pages below',
    hintAt !== -1 && !/아래로|밀린다|다시 정렬/.test(hint),
    hint.replace(/\s+/g, ' ').slice(0, 200),
  );
}

if (failures > 0) {
  console.error(`\n${failures} failure(s).`);
  process.exit(1);
}
console.log('\nAll page-order self-tests passed.');
