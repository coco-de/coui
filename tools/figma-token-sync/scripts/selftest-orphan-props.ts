/// <reference types="@figma/plugin-typings" />

// Self-test for src/orphan-props.ts — the read-only "프로퍼티 orphan 보기".
//
// 이 검출기가 틀리는 방식은 전부 같은 방향이다 — 조용해진다. 캔버스는 CI 가
// 읽지 못하므로 이 버튼이 "0" 을 말하면 그 0 을 반박할 다른 장치가 없다. 그래서
// 여기서는 "0 이 나오면 정말 0 이다" 를 Node 더블로 고정한다:
//
//   1. **심어 둔 orphan 을 잡는가** — 양성. 음성만 단언하면 `return []` 로 바꿔도 통과한다.
//   2. **참조된 것은 통과하는가** — 음성. 양성만 단언하면 전부 orphan 이라 말해도 통과한다.
//   3. **중첩 인스턴스 안까지 따라가는가** — 참조가 두 겹 아래에 있어도 찾는다.
//   4. **던지는 세트가 실행을 멈추지 않는가** — "읽을 수 없음" 줄로 따로 세고, 옆 세트는 계속 판정한다.
//   5. **배선** — 버튼 · 메시지 · 핸들러 · 비활성 목록 · selftest 체인. 다섯 중 무엇이
//      빠져도 타입체크는 통과하고 아무도 모른다.
//
// Figma 런타임 없음 — 판정 함수는 `{name, componentPropertyDefinitions, children,
// componentPropertyReferences}` 모양의 순수 객체를 받는다. `figma.root` 를 만지는
// `listOrphanProps` 는 import 만 되고 호출되지 않는다.

import {
  collectReferencedKeys,
  displayPropName,
  formatOrphanProps,
  inspectPropOwner,
  isDesignerCopyName,
  kExpectedOrphanProps,
  summarizeOrphanProps,
  type PropOwner,
  type PropRefNode,
} from '../src/orphan-props';
import { kPriorSnapshotMarker, kRedesignSnapshotMarker } from '../src/designer-parity';

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

// ── 더블 ────────────────────────────────────────────────────────────────────

function node(
  refs: Record<string, string> | null,
  children?: PropRefNode[],
): PropRefNode {
  return { componentPropertyReferences: refs, children };
}

function owner(
  name: string,
  defs: Record<string, string>,
  children: PropRefNode[],
): PropOwner {
  const definitions: Record<string, { type: string }> = {};
  for (const key of Object.keys(defs)) definitions[key] = { type: defs[key] };
  return { name, componentPropertyDefinitions: definitions, children };
}

/** Figma 가 "Component set has existing errors" 로 거부하는 세트의 더블 —
 *  정의 getter 가 던진다. */
function brokenOwner(name: string): PropOwner {
  return {
    name,
    get componentPropertyDefinitions(): Record<string, { type: string }> {
      throw new Error('in get_componentPropertyDefinitions: Component set has existing errors');
    },
    children: [],
  };
}

console.log('selftest: orphan-props');

// ── 1·2. 양성과 음성 ────────────────────────────────────────────────────────

check('심어 둔 orphan 을 잡고, 참조된 것은 통과시킨다', () => {
  const set = owner(
    'FormField',
    {
      'Label#1:0': 'TEXT',
      'Show label#2:0': 'BOOLEAN',
      'Leading#3:0': 'INSTANCE_SWAP',
      'Show helper#4:0': 'BOOLEAN', // 아무도 참조하지 않음 — orphan
    },
    [
      node(null, [
        node({ characters: 'Label#1:0', visible: 'Show label#2:0' }),
        node({ mainComponent: 'Leading#3:0' }),
      ]),
    ],
  );
  const verdict = inspectPropOwner(set);
  assertEq(
    verdict,
    { kind: 'read', owner: 'FormField', declared: 4, orphans: ['Show helper'] },
    'verdict',
  );
});

check('VARIANT 는 선언 수에도 orphan 에도 들어가지 않는다', () => {
  const set = owner('Button', { Size: 'VARIANT', State: 'VARIANT', 'Label#1:0': 'TEXT' }, [
    node(null, [node({ characters: 'Label#1:0' })]),
  ]);
  assertEq(
    inspectPropOwner(set),
    { kind: 'read', owner: 'Button', declared: 1, orphans: [] },
    'variant axes excluded',
  );
});

check('참조는 멤버 루트 자신에 걸려 있어도 센다', () => {
  // 멤버 루트의 visible 이 BOOLEAN 을 참조하는 형태 — 자손만 훑으면 놓친다.
  const set = owner('Chip', { 'Show#1:0': 'BOOLEAN' }, [node({ visible: 'Show#1:0' })]);
  assertEq(
    inspectPropOwner(set),
    { kind: 'read', owner: 'Chip', declared: 1, orphans: [] },
    'member-root ref',
  );
});

// ── 3. 중첩 인스턴스 ────────────────────────────────────────────────────────

check('중첩 인스턴스 안의 참조를 두 겹 아래까지 따라간다', () => {
  const set = owner('Card', { 'Show icon#9:0': 'BOOLEAN', 'Title#9:1': 'TEXT' }, [
    // member → INSTANCE → FRAME → (ref)
    node(null, [
      node(null, [node(null, [node({ visible: 'Show icon#9:0' })])]),
      node({ characters: 'Title#9:1' }),
    ]),
  ]);
  assertEq(
    inspectPropOwner(set),
    { kind: 'read', owner: 'Card', declared: 2, orphans: [] },
    'nested refs followed',
  );
});

check('collectReferencedKeys 는 루트 · 자손 · undefined 값을 올바르게 다룬다', () => {
  const tree: PropRefNode = {
    componentPropertyReferences: { visible: 'A#1:0', characters: undefined },
    children: [node(null), node({ mainComponent: 'B#2:0' }, [node({ characters: 'C#3:0' })])],
  };
  assertEq([...collectReferencedKeys(tree)].sort(), ['A#1:0', 'B#2:0', 'C#3:0'], 'keys');
});

// ── 4. 던지는 세트 ──────────────────────────────────────────────────────────

check('정의 접근이 던지는 세트는 "읽을 수 없음" 으로 가고 옆 세트는 계속 판정된다', () => {
  const verdicts = [
    inspectPropOwner(brokenOwner('Toast')),
    inspectPropOwner(owner('Badge', { 'Show dot#1:0': 'BOOLEAN' }, [node(null)])),
  ];
  assertEq(verdicts[0].kind, 'unreadable', 'Toast kind');
  const report = summarizeOrphanProps(verdicts);
  assertEq(report.ownerCount, 1, 'readable owners');
  assertEq(report.propertyCount, 1, 'properties');
  assertEq(report.count, 1, 'orphans');
  assertEq(report.unreadable.length, 1, 'unreadable');
  assertEq(
    formatOrphanProps(report),
    [
      `⚠ 프로퍼티 orphan 1 (기대 ${kExpectedOrphanProps}) / 컴포넌트 1 · 프로퍼티 1 — Badge: Show dot`,
      '⚠ 읽을 수 없는 컴포넌트 1 — Toast (in get_componentPropertyDefinitions: Component set has existing errors)',
    ],
    'lines',
  );
});

// ── 문장 ────────────────────────────────────────────────────────────────────

check('깨끗한 문서는 ✅ 한 줄, 사본 제외 수를 함께 말한다', () => {
  const report = summarizeOrphanProps(
    [inspectPropOwner(owner('A', { 'X#1:0': 'TEXT' }, [node({ characters: 'X#1:0' })]))],
    2,
  );
  assertEq(
    formatOrphanProps(report),
    ['프로퍼티 orphan 없음 ✅ (컴포넌트 1 · 프로퍼티 1 · 사본 2 제외)'],
    'clean line',
  );
  assert(!formatOrphanProps(report)[0].startsWith('⚠'), 'clean line must not paint the log warn');
});

check('기대값은 0 이다 — 0 이 아닌 수는 전부 ⚠ 로 시작한다', () => {
  assertEq(kExpectedOrphanProps, 0, 'expected');
  const report = summarizeOrphanProps([
    inspectPropOwner(owner('A', { 'X#1:0': 'TEXT' }, [])),
  ]);
  assert(formatOrphanProps(report)[0].startsWith('⚠'), 'non-zero must warn');
});

check('이름과 컴포넌트 두 축이 따로 접히고 개수는 참값으로 남는다', () => {
  const defs: Record<string, string> = {};
  for (let i = 0; i < 7; i++) defs[`P${i}#${i}:0`] = 'BOOLEAN';
  const busy = summarizeOrphanProps([inspectPropOwner(owner('Busy', defs, []))]);
  assertEq(busy.count, 7, 'count not folded');
  assertEq(
    formatOrphanProps(busy),
    ['⚠ 프로퍼티 orphan 7 (기대 0) / 컴포넌트 1 · 프로퍼티 7 — Busy: P0, P1, P2, P3, P4, … (+2)'],
    'name axis',
  );
  const many = summarizeOrphanProps(
    ['S0', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6'].map((n) =>
      inspectPropOwner(owner(n, { 'Q#1:0': 'TEXT' }, [])),
    ),
  );
  assertEq(
    formatOrphanProps(many),
    [
      '⚠ 프로퍼티 orphan 7 (기대 0) / 컴포넌트 7 · 프로퍼티 7 — S0: Q · S1: Q · S2: Q · S3: Q · S4: Q · … (+2 컴포넌트)',
    ],
    'owner axis',
  );
});

check('displayPropName 은 # 뒤 id 만 뗀다', () => {
  assertEq(displayPropName('Show label#12:0'), 'Show label', 'with id');
  assertEq(displayPropName('Size'), 'Size', 'variant key has no id');
});

// ── 사본 어휘는 import 만 ───────────────────────────────────────────────────

check('디자이너 사본은 사본 낱말로 걸러지고, 그 낱말은 이 파일에 적혀 있지 않다', () => {
  assert(isDesignerCopyName(`Checkbox${kRedesignSnapshotMarker}2026-09-12 10:00)`), 'redesign');
  assert(isDesignerCopyName(`Checkbox${kPriorSnapshotMarker}2026-09-12 10:00)`), 'prior');
  assert(!isDesignerCopyName('Checkbox'), 'real set');
  const code = codeLines(read('src', 'orphan-props.ts'));
  for (const word of ['리디자인', '디자이너', '이전']) {
    assert(!code.includes(`'${word}'`), `orphan-props.ts spells "${word}" — import kSnapshotNameWords`);
  }
  assert(/from '\.\/designer-parity'/.test(code), 'must import the vocabulary from designer-parity.ts');
});

check('listOrphanProps 가 사본을 걸러내고 전 페이지를 로드한다 (source text)', () => {
  const code = codeLines(read('src', 'orphan-props.ts'));
  assert(/isDesignerCopyName\(child\.name\)/.test(code), 'listOrphanProps must skip designer copies');
  assert(/await page\.loadAsync\(\)/.test(code), 'dynamic-page requires loadAsync per page');
  assert(/inspectPropOwner\(child\)/.test(code), 'listOrphanProps must judge through inspectPropOwner');
});

// ── 5. 배선 ────────────────────────────────────────────────────────────────

check('code.ts 가 orphan-props 메시지를 라우팅한다 (source text)', () => {
  const main = codeLines(read('code.ts'));
  assert(/msg\.type === 'orphan-props'/.test(main), "code.ts must branch on msg.type === 'orphan-props'");
  assert(
    /formatOrphanProps\(await listOrphanProps\(\)\)/.test(main),
    'the branch must call formatOrphanProps(await listOrphanProps())',
  );
});

check('ui.html 의 버튼 · 핸들러 · 메시지 · 비활성 목록 네 곳이 배선돼 있다', () => {
  const ui = read('ui.html');
  assert(/id="orphan-props"/.test(ui), 'ui.html must carry the orphan-props button');
  assert(/getElementById\('orphan-props'\)\.onclick/.test(ui), 'click handler');
  assert(/pluginMessage: \{ type: 'orphan-props' \}/.test(ui), "posts { type: 'orphan-props' }");
  assert(/'orphan-nodes', 'orphan-props'/.test(ui), 'busy-disable id list');
});

check('package.json 의 selftest 체인이 이 셀프테스트를 부른다', () => {
  const pkg = JSON.parse(read('package.json')) as { scripts: Record<string, string> };
  assert(
    / npm run selftest:orphan-props( |$)/.test(pkg.scripts.selftest),
    'selftest chain must include selftest:orphan-props',
  );
  assert(
    /scripts\/selftest-orphan-props\.ts/.test(pkg.scripts['selftest:orphan-props'] ?? ''),
    'selftest:orphan-props must build this file',
  );
});

if (failures > 0) {
  console.error(`\n${failures} failure(s)`);
  process.exit(1);
}
console.log('\nall ok');
