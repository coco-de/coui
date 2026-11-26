/// <reference types="@figma/plugin-typings" />

// Self-test for src/orphan-nodes.ts — the read-only "고아 노드 보기".
//
// 세 가지가 캔버스 없이 틀릴 수 있고, 전부 같은 방향으로 거짓말한다 — 검출기가
// 조용해지거나, 디자이너의 사본을 고아라고 신고하거나:
//
//   1. **판정 어휘가 두 벌이 되는 것.** `'_Docs'` 와 사본 낱말은 각각
//      `docs-frames.ts` · `designer-parity.ts` 가 소유한다. 검출기가 그 문자열을
//      자기 파일에 다시 적으면, 표기가 하나 늘어나는 날 파리티 스냅샷이 고아로
//      신고되고 그건 "지우세요" 로 읽힌다. 여기서는 두 방향으로 막는다 —
//      검출기 소스에 그 낱말이 없다는 것과, 소유자 파일의 접두 리터럴이 남김없이
//      공유 목록에 담긴다는 것.
//   2. **배선.** 순수 로직이 옳아도 아무도 부르지 않으면 조용히 죽는다. 버튼 ·
//      메시지 경로 · Generate 꼬리 네 지점을 소스 텍스트로 고정한다 — 이 넷 중
//      무엇이 빠져도 타입체크는 통과하고 아무도 모른다.
//   3. **판정과 그것이 찍는 문장.** 양성만 단언하면 `return true` 로 바꿔도
//      통과하므로 음성을 함께 둔다.
//
// Figma 런타임 없음 — `OrphanChild` 가 `{type,name,x,y}` 순수 객체라 노드 stub 이
// 필요 없고, `figma.root` 를 만지는 `listOrphanNodes` 는 **import 하지 않는다**.

import {
  classifyPages,
  formatOrphanNodes,
  isOrphanChild,
  type OrphanChild,
  type OrphanPage,
} from '../src/orphan-nodes';
import { componentPageNameOf, kComponentPageNamePrefix } from '../src/data';
import { kDocsFrameNamePrefix, kExamplesFrameName, kHeaderFrameName, kPropertiesFrameName } from '../src/docs-frames';
import {
  kPriorSnapshotMarker,
  kRedesignSnapshotMarker,
  kSnapshotNameWords,
} from '../src/designer-parity';

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

// Code lines only — a comment is allowed to EXPLAIN the vocabulary; what must
// not exist twice is a line that spells it.
function codeLines(src: string): string {
  return src
    .split('\n')
    .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l))
    .join('\n');
}

function read(...parts: string[]): string {
  return readFileSync(join(process.cwd(), ...parts), 'utf8');
}

function child(over: Partial<OrphanChild>): OrphanChild {
  return { type: 'FRAME', name: 'icon', x: 0, y: 0, ...over };
}

console.log('selftest: orphan-nodes');

// ── 1. 어휘 단일 출처 ───────────────────────────────────────────────────────

check('docs 프레임 세 이름이 전부 kDocsFrameNamePrefix 로 시작한다', () => {
  for (const name of [kHeaderFrameName, kPropertiesFrameName, kExamplesFrameName]) {
    assert(
      name.startsWith(kDocsFrameNamePrefix),
      `"${name}" must start with kDocsFrameNamePrefix ("${kDocsFrameNamePrefix}") — ` +
        'the detector filters docs frames by that prefix alone',
    );
  }
});

check('컴포넌트 페이지 이름이 kComponentPageNamePrefix 로 만들어진다', () => {
  assert(
    componentPageNameOf('Button').startsWith(kComponentPageNamePrefix),
    'componentPageNameOf must build the name from kComponentPageNamePrefix — ' +
      'the detector filters pages by that prefix alone',
  );
});

check('두 스냅샷 마커가 각각 kSnapshotNameWords 중 하나를 담는다', () => {
  for (const marker of [kRedesignSnapshotMarker, kPriorSnapshotMarker]) {
    assert(
      kSnapshotNameWords.some((w) => marker.includes(w)),
      `snapshot marker "${marker}" contains none of kSnapshotNameWords — ` +
        'the detector would report frames carrying it as orphans',
    );
  }
});

// 표기가 하나 늘면(예: `body.startsWith('(백업')`) 여기서 fail 하고, 공유 목록
// 갱신이 강제된다. 이것이 이 셀프테스트의 유일한 "미래" 그물이다.
check('designer-parity.ts 의 사본 접두 리터럴이 남김없이 kSnapshotNameWords 에 담긴다', () => {
  const src = codeLines(read('src', 'designer-parity.ts'));
  const found: string[] = [];
  // 사본 이름은 `(` 로 시작한다 — `startsWith(' ')` / `startsWith('lucide/')`
  // 같은 무관한 접두를 끌어오지 않으려고 그 모양만 본다.
  for (const m of src.matchAll(/startsWith\('(\([^']*)'\)/g)) found.push(m[1]);
  for (const m of src.matchAll(/Marker = '([^']+)'/g)) found.push(m[1]);
  assert(found.length >= 4, `expected the snapshot prefixes to be found, got ${found.length}`);
  for (const prefix of found) {
    assert(
      kSnapshotNameWords.some((w) => prefix.includes(w)),
      `snapshot prefix "${prefix}" contains none of kSnapshotNameWords ` +
        `[${kSnapshotNameWords.join(', ')}] — add the new word there, not to orphan-nodes.ts`,
    );
  }
});

// ── 2. 두 번째 레시피 금지 ─────────────────────────────────────────────────

check('orphan-nodes.ts 는 판정 어휘를 자기 파일에 적지 않는다 (import 만)', () => {
  const src = read('src', 'orphan-nodes.ts');
  const code = codeLines(src);
  for (const word of [kDocsFrameNamePrefix, kComponentPageNamePrefix.trim(), ...kSnapshotNameWords]) {
    assert(
      !code.includes(word),
      `orphan-nodes.ts spells "${word}" in code — it must import the vocabulary ` +
        '(kComponentPageNamePrefix / kDocsFrameNamePrefix / kSnapshotNameWords), not restate it',
    );
  }
  assert(
    /from '\.\/data'/.test(code) &&
      /from '\.\/docs-frames'/.test(code) &&
      /from '\.\/designer-parity'/.test(code),
    'orphan-nodes.ts must import the vocabulary from its three owner modules',
  );
});

// 원점 조건 하나로는 부족하다는 것이 이 프로젝트의 실측이다 — 사람이 그린
// Foundation / Overview 페이지의 콘텐츠 프레임이 전부 (0,0) 에 있어, 페이지를
// 거르지 않으면 이 문서에서만 오탐 10 건이 난다. 0 이 정상값인 목록이 매번
// 10 으로 시작하면 그 줄은 곧 읽히지 않는다.
check('페이지를 먼저 거른다 — 원점 조건만으로는 사람이 그린 페이지에서 거짓말한다', () => {
  const code = codeLines(read('src', 'orphan-nodes.ts'));
  assert(
    /startsWith\(kComponentPageNamePrefix\)/.test(code),
    'listOrphanNodes must skip pages the builder does not draw',
  );
  // 그 프레임은 `isOrphanChild` 자체는 통과한다 — 걸러지는 자리가 페이지라는
  // 사실을 기록해 둔다. 이 단언이 뒤집히면 페이지 필터가 유일한 방어가 아니다.
  assert(
    isOrphanChild(child({ name: 'Foundation / 01. Color — CoUI', x: 0, y: 0 })),
    'a hand-drawn page frame at the origin does pass isOrphanChild — ' +
      'the page filter is what keeps it out of the report',
  );
});

check('orphan-nodes.ts 는 generate.ts 를 import 하지 않는다 (순환 금지)', () => {
  const code = codeLines(read('src', 'orphan-nodes.ts'));
  assert(
    !/from '\.\/generate'/.test(code),
    'generate.ts imports orphan-nodes.ts — the back-edge would be a cycle ' +
      '(content-hash.ts holds the regression that caused)',
  );
});

check('말줄임 캡은 summary-format.ts 하나이고 그 파일은 leaf 다', () => {
  const orphan = codeLines(read('src', 'orphan-nodes.ts'));
  const stale = codeLines(read('src', 'stale-sets.ts'));
  for (const [name, code] of [
    ['orphan-nodes.ts', orphan],
    ['stale-sets.ts', stale],
  ] as const) {
    assert(
      !/kMaxNamesInSummary\s*=/.test(code),
      `${name} must not declare its own kMaxNamesInSummary — import it from summary-format.ts`,
    );
    assert(
      /from '\.\/summary-format'/.test(code),
      `${name} must take the truncation cap from summary-format.ts`,
    );
  }
  const shared = codeLines(read('src', 'summary-format.ts'));
  assert(
    !/^import /m.test(shared),
    'summary-format.ts must import nothing — a leaf cannot be half of a cycle',
  );
});

// ── 3. 배선 — 순수 로직이 옳아도 아무도 안 부르면 조용히 죽는다 ─────────────

check('Generate 꼬리가 고아 요약을 실행 로그에 싣는다 (source text)', () => {
  const build = codeLines(read('src', 'generate.ts'));
  assert(
    /for \(const line of orphansAfterRun\) log\.push\(line\);/.test(build),
    'generate.ts must push the orphan tail summary onto the run log',
  );
});

// 요약은 부가 정보이지 실행의 결과가 아니다 — 제거된 노드 alias 가 throw 하면서
// 71분 실행의 `log` 전체를 가져가면 안 된다. 소스 텍스트로 단언하는 이유는 그
// 실패가 Figma 노드 없이는 재현되지 않기 때문이고, 여기서 지키는 것은 구조다:
// 호출이 `try` 안에 있고, `catch` 가 `orphansAfterRun` 에 **할당**해서 위의 `for`
// 가 여전히 돈다.
check('고아 요약은 실행 로그를 끌고 내려갈 수 없게 감싸여 있다 (source text)', () => {
  const build = codeLines(read('src', 'generate.ts'));
  assert(
    // The argument is the cache-hit page scope (#4803) — an identifier or nothing.
    /try \{\s*orphansAfterRun = formatOrphanNodes\(await listOrphanNodes\((?:\w+)?\)\);/.test(build),
    'the listOrphanNodes/formatOrphanNodes call must be inside a try block',
  );
  assert(
    /\} catch \(e\) \{\s*orphansAfterRun = \[/.test(build),
    'the catch must still assign orphansAfterRun (a warning line), not crash the run',
  );
});

// 실행 끝에 새로 생긴 전수 순회다. 마커가 없으면 여기서 죽은 실행이 "마지막
// 엔트리를 그리다 죽었다" 로 읽혀 `last-step` 의 해상도를 흐린다 — 그게 무로그
// 사망의 유일한 단서인 동안 그 손실은 받아들일 수 없다.
check('고아 스캔이 자기 last-step 마커를 먼저 찍는다 (source text)', () => {
  const build = codeLines(read('src', 'generate.ts'));
  const marker = build.indexOf("markStep('orphan-scan')");
  const call = build.indexOf('orphansAfterRun = formatOrphanNodes(');
  assert(marker >= 0, "generate.ts must markStep('orphan-scan') before the scan");
  assert(marker < call, "markStep('orphan-scan') must come BEFORE the scan, not after");
  assert(
    build.indexOf("markStep('run:done')") > call,
    "markStep('run:done') must stay the terminal marker, after the orphan scan",
  );
});

check('code.ts 가 orphan-nodes 메시지를 라우팅한다 (source text)', () => {
  const main = codeLines(read('code.ts'));
  assert(
    /msg\.type === 'orphan-nodes'/.test(main),
    "code.ts must branch on msg.type === 'orphan-nodes'",
  );
  assert(
    /formatOrphanNodes\(await listOrphanNodes\(\)\)/.test(main),
    'the branch must call formatOrphanNodes(await listOrphanNodes())',
  );
});

// ui.html 과 code.ts 의 문자열이 한 글자라도 갈리면 버튼은 눌리고 아무 일도
// 일어나지 않으며 컴파일러는 침묵한다 — 메시지 타입에 union 이 없기 때문이다.
check('ui.html 의 버튼 · 핸들러 · 메시지 · 비활성 목록 네 곳이 배선돼 있다', () => {
  const ui = read('ui.html');
  assert(/id="orphan-nodes"/.test(ui), 'ui.html must carry the orphan-nodes button');
  assert(
    /getElementById\('orphan-nodes'\)\.onclick/.test(ui),
    'ui.html must bind the orphan-nodes click handler',
  );
  assert(
    /pluginMessage: \{ type: 'orphan-nodes' \}/.test(ui),
    "the handler must post { type: 'orphan-nodes' } — the literal code.ts branches on",
  );
  assert(
    /'stale-sets', 'orphan-nodes'/.test(ui),
    'orphan-nodes must be in the busy-disable id list, or the button stays live mid-run',
  );
});

// ── 4. 순수 판정 — 양방향 ──────────────────────────────────────────────────

check('isOrphanChild: 양성 — 페이지 직계 원점의 미부착 조각', () => {
  assert(isOrphanChild(child({ type: 'FRAME', name: 'field' })), 'FRAME "field" @(0,0) is an orphan');
  assert(
    isOrphanChild(child({ type: 'INSTANCE', name: 'reset' })),
    'INSTANCE "reset" @(0,0) is an orphan',
  );
});

check('isOrphanChild: 음성 — 여섯 가지는 절대 걸리면 안 된다', () => {
  // 세트와 단일 변형 컴포넌트 — 후자는 페이지 직계에 정상적으로 산다(이 문서에
  // 47 개). `mountSet` 이 파킹하는 멤버도 COMPONENT 라 여기서 같이 걸러진다.
  assert(!isOrphanChild(child({ type: 'COMPONENT_SET', name: 'Button' })), 'COMPONENT_SET');
  assert(!isOrphanChild(child({ type: 'COMPONENT', name: 'Kbd' })), 'COMPONENT');
  // docs 프레임.
  assert(!isOrphanChild(child({ name: kHeaderFrameName })), 'docs header frame');
  // 디자이너 사본 두 표기.
  assert(
    !isOrphanChild(child({ name: 'Checkbox (리디자인 · 2026-09-12 10:00)' })),
    'redesign snapshot',
  );
  assert(!isOrphanChild(child({ name: 'Checkbox(디자이너)' })), 'legacy designer snapshot');
  // 원점이 아닌 것 — 실제 콘텐츠는 여기 산다. 두 축을 따로 단언한다.
  assert(!isOrphanChild(child({ x: 120, y: 0 })), 'x != 0');
  assert(!isOrphanChild(child({ x: 0, y: 120 })), 'y != 0');
});

check('classifyPages + formatOrphanNodes: 깨끗한 문서', () => {
  const pages: OrphanPage[] = [
    { page: 'A', children: [child({ type: 'COMPONENT_SET', name: 'Button' })] },
    { page: 'B', children: [] },
    { page: 'C', children: [child({ name: kPropertiesFrameName })] },
  ];
  const report = classifyPages(pages);
  assertEq(report.count, 0, 'orphan count');
  assertEq(report.pageCount, 3, 'page count');
  assertEq(formatOrphanNodes(report), ['고아 노드 없음 ✅ (페이지 3)'], 'clean line');
});

check('classifyPages + formatOrphanNodes: 혼합 — 정확한 한 줄', () => {
  const pages: OrphanPage[] = [
    {
      page: '❖ Label',
      children: [
        child({ type: 'FRAME', name: 'icon' }),
        child({ type: 'INSTANCE', name: 'Icon' }),
        child({ type: 'COMPONENT_SET', name: 'Label' }),
      ],
    },
    { page: '❖ Empty', children: [] },
  ];
  const report = classifyPages(pages);
  assertEq(report.count, 2, 'orphan count');
  assertEq(report.groups, [{ page: '❖ Label', names: ['icon', 'Icon'] }], 'groups');
  assertEq(
    formatOrphanNodes(report),
    ['고아 노드 2 / 페이지 2 — ❖ Label: icon, Icon'],
    'mixed line',
  );
});

// 상한 없는 join 이 이 자리의 한 줄을 레지스트리 전체로 만든 적이 한 번 있다.
// 두 축이 각각 접히고, 개수는 어느 쪽도 접히지 않는다.
check('두 축의 캡 — 이름과 페이지가 따로 접히고 개수는 참값으로 남는다', () => {
  const names = ['A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7'];
  const oneBusyPage = classifyPages([
    { page: 'P', children: names.map((name) => child({ name })) },
  ]);
  assertEq(oneBusyPage.count, 8, 'count is not folded');
  assertEq(
    formatOrphanNodes(oneBusyPage),
    ['고아 노드 8 / 페이지 1 — P: A0, A1, A2, A3, A4, … (+3)'],
    'name axis capped at 5',
  );

  const manyPages = classifyPages(
    ['P0', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'].map((page) => ({
      page,
      children: [child({ name: 'n' })],
    })),
  );
  assertEq(manyPages.count, 8, 'count is not folded');
  assertEq(manyPages.pageCount, 8, 'pageCount is not folded');
  assertEq(
    formatOrphanNodes(manyPages),
    ['고아 노드 8 / 페이지 8 — P0: n · P1: n · P2: n · P3: n · P4: n · … (+3 페이지)'],
    'page axis capped at 5, and it says its unit',
  );
});

if (failures > 0) {
  console.error(`\n${failures} failure(s)`);
  process.exit(1);
}
console.log('\nall ok');
