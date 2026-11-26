/// <reference types="@figma/plugin-typings" />

// Self-test for src/consumer-audit.ts — the read-only "소비 파일 점검".
//
// 네 가지가 캔버스 없이 틀릴 수 있다:
//
//   1. **판정이 두 벌이 되는 것.** 역할과 어디가 다른가는 빌더가 스타일을 붙일지
//      정하는 `roleDeparture` 가 답한다. 이 파일이 역할 이름이나 스타일 이름을
//      다시 적으면, 역할 표가 바뀌는 날 이 목록은 빌더가 스타일을 붙이는 글자를
//      "역할에 없다" 고 신고한다. 소스 텍스트로 막는다.
//   2. **배선.** 버튼 · 핸들러 · 메시지 · 비활성 목록 · 항목 선택 · selftest 체인.
//      문자열이 한 글자만 갈려도 버튼은 눌리고 아무 일도 없으며 컴파일러는 침묵한다.
//   3. **분류.** 2026-10-28 한 소비 파일에서 잰 사례를 데이터로 그대로 적고, 사례마다
//      한 값만 바꾼 변형을 함께 둔다 — 양성만 단언하면 판정을 `return 'styled'` 로
//      바꿔도 통과하기 때문이다.
//   4. **걷기.** 숨은 노드 · 빈 글자 · 건너뛸 이름 · 인스턴스의 덮어쓰기 · 원격
//      컴포넌트 · CoUI 슬롯에 바꿔 넣은 로컬 컴포넌트 · 섞인 구간 · 글자가 푸는 타이포
//      모드 · 본문 서체의 출처를 노드 더블로. 더블은 쓰기를 받으면 던진다 — 이 명령이
//      노드를 바꾸지 않는다는 것도 같이 단언된다.

import {
  buildConsumerAuditReport,
  classifyRun,
  collectRuns,
  couiStyleRole,
  formatConsumerAudit,
  isCouiTypographyVariable,
  kAuditCategories,
  kAuditIdsPerPage,
  mainComponentName,
  typographyOverrides,
  type AuditCollectionInfo,
  type AuditDeps,
  type AuditEnv,
  type AuditNode,
  type AuditPage,
  type AuditSegment,
  type RunContext,
  type RunLook,
  type TextRun,
  type VariableRef,
} from '../src/consumer-audit';
import { roleMetrics, roleNames, roleSizeVariesByMode } from '../src/compat/v1';
import { TYPOGRAPHY } from '../src/data';
import { textStyleNameOf } from '../src/text-styles';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as {
  readFileSync(p: string, enc: string): string;
};
const { join } = require('path') as { join(...parts: string[]): string };

let failures = 0;

function check(label: string, fn: () => void | Promise<void>): Promise<void> {
  return Promise.resolve()
    .then(fn)
    .then(
      () => console.log(`  ok  ${label}`),
      (e) => {
        failures++;
        console.error(`FAIL  ${label}\n      ${String(e)}`);
      },
    );
}

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

function assertEq<T>(actual: T, expected: T, what: string): void {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a !== b) throw new Error(`${what}: expected ${b}, got ${a}`);
}

function read(rel: string): string {
  return readFileSync(join(process.cwd(), rel), 'utf8');
}

function codeLines(src: string): string {
  return src
    .split('\n')
    .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l))
    .join('\n');
}

// ── 데이터 ────────────────────────────────────────────────────────────────

const ENV: AuditEnv = { sans: 'Pretendard', mono: 'Geist Mono' };

const TYPO = 'Semantic/ Typography';
const PRIM = 'Primitives';
const sem = (name: string): VariableRef => ({ collection: TYPO, name });
const prim = (name: string): VariableRef => ({ collection: PRIM, name });

// 실측 파일의 모든 프레임은 타이포 모드 Mobile 로 그린다 — 사례의 기본값도 그렇다.
function look(over: Partial<RunLook>): RunLook {
  return {
    family: 'Pretendard',
    face: 'Regular',
    size: 13,
    lineHeight: { unit: 'PERCENT', value: 150 },
    letterSpacing: { unit: 'PIXELS', value: -0.13 },
    textStyle: null,
    bound: {},
    mode: 'Mobile',
    ...over,
  };
}

function run(context: RunContext, l: RunLook | null, text = '글'): TextRun {
  return { nodeId: 'n', pageId: 'p', pageName: 'Page', text, where: 'Screen', context, look: l };
}

const OWN: RunContext = { kind: 'own' };

// 2026-10-28 실측 사례 — 이슈의 분류 표와 같은 번호.
const CASE = {
  // (1) "Body/Small" 라이브러리 스타일.
  styled: run(OWN, look({ textStyle: { name: 'Body/Small', remote: true } })),
  // (2) Button 라벨 — 라이브러리 인스턴스 안, 덮어쓰지 않음.
  libraryLabel: run({ kind: 'library', component: 'Button', coui: true, overridden: [] }, null, '확인'),
  // (3) "STEP 1 / 3" — Bold 12/140%/-0.12px, 역할 변수 + 굵기 변수.
  step: run(
    OWN,
    look({
      face: 'Bold',
      size: 12,
      lineHeight: { unit: 'PERCENT', value: 140 },
      letterSpacing: { unit: 'PIXELS', value: -0.12 },
      bound: {
        fontSize: sem('font-size/label-small'),
        fontWeight: sem('font-weight/title'),
        letterSpacing: sem('letter-spacing/label-small'),
      },
    }),
    'STEP 1 / 3',
  ),
  // (4) "환전 찾는 중" — 로컬 컴포넌트 안, Bold 12/120%/-1%(퍼센트 자간).
  searching: run(
    { kind: 'local-component', component: 'ListingCard · CoUI' },
    look({
      face: 'Bold',
      size: 12,
      lineHeight: { unit: 'PERCENT', value: 120 },
      letterSpacing: { unit: 'PERCENT', value: -1 },
      bound: { fontSize: sem('font-size/label-small'), fontWeight: sem('font-weight/title') },
    }),
    '환전 찾는 중',
  ),
  // (5) TextField 값 — 인스턴스에서 글꼴 · 크기를 덮어써 SemiBold 17.
  textFieldValue: run(
    {
      kind: 'library',
      component: 'TextField',
      coui: true,
      overridden: typographyOverrides(['fontName', 'fontSize', 'boundVariables']),
    },
    look({
      face: 'SemiBold',
      size: 17,
      lineHeight: { unit: 'PERCENT', value: 140 },
      letterSpacing: { unit: 'PIXELS', value: -0.17 },
    }),
    '1,000',
  ),
  // (6) Regular 13/150%/-0.13px, 스타일 · 변수 없음.
  bare: run(OWN, look({}), '부가 설명'),
  // (7) iPhone 상태 표시줄 — CoUI 가 아닌 라이브러리, 글꼴을 덮어씀.
  statusBar: run(
    { kind: 'library', component: 'Status bar', coui: false, overridden: ['fontName'] },
    look({ family: 'SF Pro', face: 'Semibold', size: 17 }),
    '9:41',
  ),
};

async function main(): Promise<void> {
  console.log('selftest: consumer-audit');

  // ── 1. 판정은 한 벌 ──────────────────────────────────────────────────────

  await check('consumer-audit.ts 는 roleDeparture · textStyleNameOf · 역할 표를 import 해서 쓴다', () => {
    const src = read('src/consumer-audit.ts');
    const code = codeLines(src);
    assert(
      /import \{[^}]*\broleDeparture\b[^}]*\} from '\.\/text-nodes'/.test(src),
      'must import roleDeparture from ./text-nodes',
    );
    assert(/roleDeparture\(role, onlyField\(/.test(code), 'must ask roleDeparture field by field');
    assert(
      /import \{ textStyleNameOf \} from '\.\/text-styles'/.test(src),
      'must import textStyleNameOf from ./text-styles',
    );
    assert(
      /import \{[^}]*\broleMetrics\b[^}]*\broleNames\b[^}]*\} from '\.\/compat\/v1'/.test(src),
      'must read roles through compat/v1 (roleMetrics · roleNames)',
    );
    assert(/canonicalCollection\(/.test(code), 'collection names must go through canonicalCollection');
  });

  await check('consumer-audit.ts 는 역할 이름 · 스타일 이름을 자기 파일에 적지 않는다', () => {
    const code = codeLines(read('src/consumer-audit.ts'));
    const roleLiteral = code.match(/'(display|headline|title|body|label|code)(Large|Medium|Small|Xs|Xl2|Xl|Sm|Md)'/);
    assert(roleLiteral == null, `role name literal in code: ${roleLiteral?.[0]}`);
    const styleLiteral = code.match(/'(Display|Headline|Title|Body|Label|Code)\/[A-Z][A-Za-z0-9]*'/);
    assert(styleLiteral == null, `style name literal in code: ${styleLiteral?.[0]}`);
    // 역할의 값과 직접 견주는 줄 — 그건 roleDeparture 의 일이다. 순위를 매기는
    // 거리(Math.abs)만 허용한다.
    assert(
      !/weightStyle\(m\.fontWeight\)|metrics\.fontSize\s*[!=]==/.test(code),
      'must not compare role metrics itself — roleDeparture does',
    );
  });

  await check('roleNames 는 components.json 의 역할 표 그대로다', () => {
    assertEq(roleNames(), Object.keys(TYPOGRAPHY), 'roleNames vs typography keys');
  });

  await check('CoUI 스타일 이름은 역할마다 하나, 역할로 되돌아간다', () => {
    for (const role of roleNames()) {
      const name = textStyleNameOf(role);
      assert(name != null, `${role} has a style name`);
      assertEq(couiStyleRole(name!), role, `style of ${role} maps back`);
    }
    assertEq(couiStyleRole('Heading 1'), null, 'non-CoUI name');
  });

  await check('CoUI 변수는 exporter 의 컬렉션 · 이름으로 알아본다', () => {
    assert(isCouiTypographyVariable(sem('font-size/label-small')), 'Semantic/ Typography font-size');
    assert(isCouiTypographyVariable({ collection: 'Semantic/Typography', name: 'font-weight/title' }), 'no-space spelling');
    assert(isCouiTypographyVariable(prim('font/size/14')), 'Primitives font/size');
    assert(isCouiTypographyVariable({ collection: '0. Primitives', name: 'font/family/Pretendard' }), 'numbered Primitives');
    assert(!isCouiTypographyVariable({ collection: 'iOS', name: 'font-size/body' }), 'other collection');
    assert(!isCouiTypographyVariable(sem('color/primary')), 'non-typography name');
  });

  // ── 2. 배선 ───────────────────────────────────────────────────────────────

  await check('code.ts 가 두 메시지를 라우팅한다', () => {
    const main = codeLines(read('code.ts'));
    assert(/msg\.type === 'consumer-audit'\)/.test(main), "code.ts must branch on 'consumer-audit'");
    assert(/auditConsumerFile\(\{/.test(main), 'the branch must call auditConsumerFile');
    assert(/type: 'consumer-audit-result'/.test(main), "the reply must be 'consumer-audit-result'");
    assert(/msg\.type === 'consumer-audit-select'\)/.test(main), "code.ts must branch on 'consumer-audit-select'");
    assert(/revealAuditNodes\(/.test(main), 'the select branch must call revealAuditNodes');
    assert(/listRegistryEntries\(\)\.map\(\(e\) => e\.name\)/.test(main), 'CoUI names come from the registry');
    // 다른 명령이 도는 중의 선택은 거절한다 — 선택은 현재 페이지를 옮긴다.
    assert(/if \(commandsInFlight > 0\)/.test(main), 'select refuses while a command is in flight');
    assert(/commandsInFlight \+= 1;/.test(main) && /finally \{\s*commandsInFlight -= 1;/.test(main), 'in-flight count');
    // 건너뛸 이름은 기억하고 로드 때 돌려준다.
    assert(/clientStorage\.setAsync\(kConsumerAuditSkipKey/.test(main), 'skip names are stored');
    assert(/msg\.type === 'consumer-audit-read-skip'\)/.test(main), 'stored skip names are read back');
    assert(/type: 'consumer-audit-skip', skipNames: names/.test(main), 'reply type for stored skip names');
    assert(/familyUnknown: report\.familyUnknown/.test(main), 'the result carries familyUnknown');
  });

  await check('ui.html 의 버튼 · 핸들러 · 메시지 · 비활성 목록 · 결과 · 선택이 배선돼 있다', () => {
    const ui = read('ui.html');
    assert(/id="consumer-audit"/.test(ui), 'button');
    assert(/id="consumer-audit-scope"/.test(ui) && /id="consumer-audit-skip"/.test(ui), 'scope + skip inputs');
    assert(/id="consumer-audit-result"/.test(ui), 'result list');
    assert(/getElementById\('consumer-audit'\)\.onclick/.test(ui), 'click handler');
    assert(/pluginMessage: \{ type: 'consumer-audit', scope, skipNames \}/.test(ui), 'posted message literal');
    assert(/'perf-probe',\s*\n\s*'consumer-audit',\s*\n\s*\]\.map/.test(ui), 'busy-disable id list');
    assert(/msg\.type === 'consumer-audit-result'/.test(ui), 'result branch');
    assert(/type: 'consumer-audit-select', pageId: page\.pageId, ids: page\.ids/.test(ui), 'row posts select');
    // 다른 명령이 도는 동안 목록은 눌리지 않는다.
    assert(/auditBox\.inert = busy;/.test(ui) && /auditBox\.classList\.toggle\('busy', busy\)/.test(ui), 'list inert while busy');
    assert(/function selectAuditPage\(page\) \{\s*if \(uiBusy\) return;/.test(ui), 'select returns early while busy');
    // 지난번 건너뛸 이름을 묻고 채운다.
    assert(/type: 'consumer-audit-read-skip'/.test(ui), 'asks for stored skip names');
    assert(/msg\.type === 'consumer-audit-skip'/.test(ui), 'fills stored skip names');
    // 관리 탭 안에 있어야 한다.
    const manage = ui.indexOf('<section data-tab="manage">');
    const button = ui.indexOf('id="consumer-audit"');
    const nextSection = ui.indexOf('</section>', manage);
    assert(manage >= 0 && button > manage && button < nextSection, 'button lives in the 관리 tab');
  });

  await check('package.json 의 selftest 체인에 들어 있다', () => {
    const pkg = JSON.parse(read('package.json')) as { scripts: Record<string, string> };
    assert(pkg.scripts['selftest:consumer-audit'] != null, 'selftest:consumer-audit script');
    assert(/npm run selftest:consumer-audit\b/.test(pkg.scripts.selftest), 'aggregate selftest runs it');
  });

  // ── 3. 분류 — 실측 사례와 한 값만 바꾼 변형 ───────────────────────────────

  await check('(1) CoUI 라이브러리 스타일 → 통과', () => {
    const v = classifyRun(CASE.styled, ENV);
    assertEq(v.category, 'styled', 'category');
    assertEq(v.signature, 'Body/Small', 'signature');
    // 변형: 같은 이름의 로컬 사본은 라이브러리를 따라가지 않는다.
    const localCopy = run(OWN, look({ textStyle: { name: 'Body/Small', remote: false } }));
    assertEq(classifyRun(localCopy, ENV).category, 'local-style', 'local copy of a CoUI name');
    // 변형: CoUI 가 아닌 라이브러리 스타일.
    const foreign = run(OWN, look({ textStyle: { name: 'Body', remote: true } }));
    const fv = classifyRun(foreign, ENV);
    assertEq(fv.category, 'local-style', 'other library style');
    assert(fv.signature.startsWith('다른 라이브러리 스타일 "Body"'), fv.signature);
    assert(fv.action.includes('Body/Small'), `suggests the nearest CoUI style: ${fv.action}`);
  });

  await check('(2) CoUI 컴포넌트 안 · 덮어쓰지 않음 → 대상 아님', () => {
    assertEq(classifyRun(CASE.libraryLabel, ENV).category, 'library', 'category');
    // 변형: 글자만 고쳐 쓴 것은 모양을 덮어쓴 것이 아니다 — 글자를 고치면 구간도
    // 다시 나뉘어 `styledTextSegments` 가 같이 나오고, 문자열 변수에 묶으면
    // `boundVariables` 가 나온다. 셋 다 모양이 아니다.
    assertEq(
      typographyOverrides(['characters', 'styledTextSegments', 'boundVariables', 'fontSize', 'textStyleId']),
      ['fontSize', 'textStyleId'],
      'typography override fields',
    );
    const textOnly = run(
      { kind: 'library', component: 'Button', coui: true, overridden: typographyOverrides(['characters', 'styledTextSegments']) },
      look({ face: 'SemiBold', size: 14 }),
    );
    assertEq(classifyRun(textOnly, ENV).category, 'library', 'characters-only override');
    // 변형: 크기를 덮어쓰면 경고.
    const sized = run(
      { kind: 'library', component: 'Button', coui: true, overridden: ['fontSize'] },
      look({ face: 'SemiBold', size: 16 }),
    );
    assertEq(classifyRun(sized, ENV).category, 'override', 'fontSize override');
  });

  await check('(3) 역할 변수 + 굵기만 다름 → 통과', () => {
    const v = classifyRun(CASE.step, ENV);
    assertEq(v.category, 'role-weight', 'category');
    assertEq(v.role, 'labelSmall', 'role');
    // 변형: 변수 없이 같은 숫자 — 역할에 연결되지 않았다.
    const unbound = run(OWN, look({ ...CASE.step.look!, bound: {} }));
    const uv = classifyRun(unbound, ENV);
    assertEq(uv.category, 'no-style', 'unbound weight-only');
    // 역할의 시맨틱 변수에 묶고 굵기를 덮으라고 하지 않는다 — 캔버스 규칙이 피할
    // 모양으로 적는 것이다. 스타일을 붙이면 굵기가 역할의 것이 된다고 말한다.
    assertEq(
      uv.action,
      'Label/Small 스타일을 붙인다 — 붙이면 굵기가 역할 굵기로 바뀐다(Bold → Medium). 그 굵기가 꼭 필요하면 그 굵기의 역할을 리디자인 이슈로 묻는다',
      'unbound weight-only action',
    );
    assert(!/font-size\/|letter-spacing\//.test(uv.action), `no variable-binding instruction: ${uv.action}`);
    // 변형: 행간까지 다르면 역할에 없는 조합.
    const lined = run(OWN, look({ ...CASE.step.look!, lineHeight: { unit: 'PERCENT', value: 120 } }));
    assertEq(classifyRun(lined, ENV).category, 'off-role', 'weight + line height');
  });

  await check('(4) 로컬 컴포넌트 안 Bold 12/120%/-1% → 역할에 없는 조합, 가장 가까운 Label/Small', () => {
    const v = classifyRun(CASE.searching, ENV);
    assertEq(v.category, 'off-role', 'category');
    assertEq(v.role, 'labelSmall', 'nearest = the bound role');
    assertEq(v.departs, ['weight', 'lineHeight'], 'departs (percent tracking -1% = the role)');
    assertEq(
      v.signature,
      'Pretendard Bold 12 · 행간 120% · 자간 -1% → Label/Small (굵기 · 행간)',
      'signature',
    );
    // 맞출 값과 굵기는 다른 문장 — 한 문장에 이으면 행간까지 남겨도 되는 것으로 읽힌다.
    assertEq(
      v.action,
      'Label/Small 에 맞출 값: 행간. 굵기는 스타일을 붙이면 역할 굵기로 바뀐다(Bold → Medium). 그 값이 꼭 필요하면 역할 추가를 리디자인 이슈로 묻는다',
      'action',
    );
    // 변형: 자간 -2% 는 역할과 다르다.
    const tracked = run(CASE.searching.context, look({ ...CASE.searching.look!, letterSpacing: { unit: 'PERCENT', value: -2 } }));
    assert(classifyRun(tracked, ENV).departs.includes('letterSpacing'), '-2% departs');
    // 변형: 행간이 역할과 같으면 굵기만 남아 통과.
    const fixed = run(CASE.searching.context, look({ ...CASE.searching.look!, lineHeight: { unit: 'PERCENT', value: 140 } }));
    assertEq(classifyRun(fixed, ENV).category, 'role-weight', 'only weight left');
  });

  await check('(5) TextField 값 덮어쓰기 → 경고', () => {
    const v = classifyRun(CASE.textFieldValue, ENV);
    assertEq(v.category, 'override', 'category');
    assert(v.signature.startsWith('TextField · Pretendard SemiBold 17'), v.signature);
    assert(v.signature.includes('덮어씀: 글꼴·굵기 · 크기'), `names the overridden fields: ${v.signature}`);
    assert(!v.signature.includes('boundVariables'), 'boundVariables alone is not a typography override');
    // 변형: 덮어쓰지 않았으면 라이브러리 몫.
    const clean = run({ kind: 'library', component: 'TextField', coui: true, overridden: [] }, CASE.textFieldValue.look);
    assertEq(classifyRun(clean, ENV).category, 'library', 'no override');
  });

  await check('(6) 역할과 같은 값 · 스타일 없음 → 스타일만 붙이면 된다', () => {
    const v = classifyRun(CASE.bare, ENV);
    assertEq(v.category, 'no-style', 'category');
    assertEq(v.role, 'bodySmall', 'role');
    assertEq(v.departs, [], 'departs');
    assertEq(v.signature, 'Pretendard Regular 13 · 행간 150% · 자간 -0.13px = Body/Small', 'signature');
    // 변형: 행간 140% 면 역할에 없는 조합, 가장 가까운 것은 여전히 Body/Small.
    const lined = run(OWN, look({ lineHeight: { unit: 'PERCENT', value: 140 } }));
    const lv = classifyRun(lined, ENV);
    assertEq([lv.category, lv.role, lv.departs], ['off-role', 'bodySmall', ['lineHeight']], 'line height 140');
    // 변형: 캔버스의 32비트 숫자와 픽셀 행간 — 같은 그림은 같은 역할이다.
    const px = run(
      OWN,
      look({ face: 'Medium', lineHeight: { unit: 'PIXELS', value: 18.200000762939453 }, letterSpacing: { unit: 'PIXELS', value: -0.12999999523162842 } }),
    );
    const pv = classifyRun(px, ENV);
    assertEq([pv.category, pv.role], ['no-style', 'labelMedium'], '18.2px on 13 = 140%');
  });

  await check('(7) CoUI 가 아닌 라이브러리 안 → 덮어써도 대상 아님', () => {
    const v = classifyRun(CASE.statusBar, ENV);
    assertEq(v.category, 'other-library', 'category');
    assertEq(v.signature, 'Status bar', 'signature');
    // 변형: 같은 덮어쓰기가 CoUI 컴포넌트였다면 경고.
    const coui = run({ ...CASE.statusBar.context, coui: true } as RunContext, CASE.statusBar.look);
    assertEq(classifyRun(coui, ENV).category, 'override', 'same override on a CoUI component');
  });

  await check('타이포 모드 — 글자가 푸는 모드에서 역할이 그리는 크기 · 자간과 견준다', () => {
    // 내보낸 표가 모드를 싣는다 — 모드마다 크기가 다른 것은 display · headline 뿐.
    assertEq(roleMetrics('headlineLarge')?.modes?.Mobile?.fontSize, 24, 'headlineLarge @ Mobile');
    assertEq(roleMetrics('displaySmall')?.modes?.Mobile?.fontSize, 28, 'displaySmall @ Mobile');
    assertEq(roleMetrics('headlineSmall')?.modes?.Mobile?.letterSpacing, -0.01, 'headlineSmall tracks the 16px step on Mobile');
    assert(roleSizeVariesByMode('headlineLarge') && !roleSizeVariesByMode('labelSmall'), 'which roles step');

    const bold24 = look({
      face: 'Bold',
      size: 24,
      lineHeight: { unit: 'PERCENT', value: 140 },
      letterSpacing: { unit: 'PIXELS', value: -0.48 },
    });
    // Mobile 에서 숫자로 적은 24 는 Headline/Large(Mobile 24) — 붙여도 그 모드에서는 그대로.
    const mobile = classifyRun(run(OWN, bold24), ENV);
    assertEq([mobile.category, mobile.role, mobile.departs], ['no-style', 'headlineLarge', []], 'literal 24 @ Mobile');
    assertEq(mobile.signature, 'Pretendard Bold 24 · 행간 140% · 자간 -0.48px = Headline/Large (Mobile)', 'signature names the mode');
    assert(mobile.action.includes('Mobile 에서는 값이 같아 그림이 그대로'), mobile.action);
    // 같은 숫자 · 모드를 못 읽음 → 코드 스케일의 24(Headline/Small), "그대로" 라고 하지 않는다.
    const unknown = classifyRun(run(OWN, { ...bold24, mode: null }), ENV);
    assertEq([unknown.category, unknown.role], ['no-style', 'headlineSmall'], 'literal 24, mode unknown');
    assert(unknown.action.includes('Desktop 값과 같다'), unknown.action);
    assert(!unknown.action.includes('그림은 바뀌지 않는다') && !unknown.action.includes('그림이 그대로'), unknown.action);
    // 실측 사례: Display/Small 을 숫자로 적은 Mobile 의 28.
    const bold28 = classifyRun(
      run(OWN, look({ ...bold24, size: 28, letterSpacing: { unit: 'PIXELS', value: -0.56 } })),
      ENV,
    );
    assertEq([bold28.category, bold28.role], ['no-style', 'displaySmall'], 'literal 28 @ Mobile');
    // Mobile 에서 두 역할이 같은 20 을 그리면(Headline/Medium · Title/Large) 굵기가 가른다 —
    // 제목은 SemiBold, 헤드라인은 Bold 라서 숫자로 적은 글자는 자기 굵기의 역할로 간다.
    // 굵기가 가르지 않을 때의 동률(모드마다 크기가 같은 역할이 이긴다)은 크기가 같고 굵기도 같은
    // 두 역할이 없어 이 표에서는 만들 수 없다 — 순위의 그 칸은 코드에 그대로 둔다.
    const semi20 = classifyRun(
      run(OWN, look({ ...bold24, face: 'SemiBold', size: 20, letterSpacing: { unit: 'PIXELS', value: -0.4 } })),
      ENV,
    );
    assertEq([semi20.category, semi20.role], ['no-style', 'titleLarge'], 'SemiBold 20 is the title role');
    assert(semi20.action.endsWith('값이 같아 그림은 바뀌지 않는다'), semi20.action);
    const bold20 = classifyRun(
      run(OWN, look({ ...bold24, size: 20, letterSpacing: { unit: 'PIXELS', value: -0.4 } })),
      ENV,
    );
    assertEq([bold20.category, bold20.role], ['no-style', 'headlineMedium'], 'Bold 20 is the headline role');

    // 크기가 역할 변수에 묶였으면 크기는 모든 모드에서 역할을 따르고, 남은 자간을 그 모드와 견준다.
    const headline = look({
      face: 'Bold',
      size: 24,
      lineHeight: { unit: 'PERCENT', value: 140 },
      letterSpacing: { unit: 'PIXELS', value: -0.48 },
      bound: { fontSize: sem('font-size/headline-large'), letterSpacing: sem('letter-spacing/headline-large') },
    });
    const bound = classifyRun(run(OWN, headline), ENV);
    assertEq([bound.category, bound.role, bound.departs], ['no-style', 'headlineLarge', []], 'bound 24 = headline-large');
    assert(bound.action.endsWith('값이 같아 그림은 바뀌지 않는다'), `size follows the role in every mode: ${bound.action}`);
    const smallBound = look({
      face: 'Bold',
      size: 16,
      lineHeight: { unit: 'PERCENT', value: 140 },
      letterSpacing: { unit: 'PIXELS', value: -0.16 },
      bound: { fontSize: sem('font-size/headline-small') },
    });
    assertEq(classifyRun(run(OWN, smallBound), ENV).departs, [], 'bound headline-small 16 + literal -0.16px @ Mobile');
    // 모드를 못 읽어도 묶인 크기가 그 모드를 말한다.
    assertEq(
      classifyRun(run(OWN, { ...smallBound, mode: null }), ENV).departs,
      [],
      'mode inferred from the bound size',
    );
    // 반대 — 자간만 묶이고 크기 16 을 숫자로 적었다: Mobile 의 headline-small 이 16 이다.
    const trackingBound = classifyRun(
      run(OWN, { ...smallBound, bound: { letterSpacing: sem('letter-spacing/headline-small') } }),
      ENV,
    );
    assertEq([trackingBound.category, trackingBound.role, trackingBound.departs], ['no-style', 'headlineSmall', []], 'bound tracking + literal 16 @ Mobile');
  });

  await check('자동 행간 · 다른 글꼴 · 고정폭', () => {
    const auto = classifyRun(run(OWN, look({ lineHeight: { unit: 'AUTO' } })), ENV);
    assertEq([auto.category, auto.role], ['off-role', 'bodySmall'], 'AUTO');
    assert(auto.departs.includes('lineHeight'), 'AUTO departs on line height');
    const sf = classifyRun(run(OWN, look({ family: 'SF Pro' })), ENV);
    assertEq([sf.category, sf.departs], ['off-role', ['family']], 'SF Pro');
    // 본문 서체를 모르면 글꼴은 비교하지 않고, 그림이 그대로라고 말하지 않는다.
    const unknown = classifyRun(run(OWN, look({ family: 'SF Pro' })), { sans: null, mono: 'Geist Mono' });
    assertEq(unknown.category, 'no-style', 'family unchecked when sans unknown');
    assert(!unknown.action.includes('그림은 바뀌지 않는다'), `no unchanged claim: ${unknown.action}`);
    assert(unknown.action.includes('글꼴은 비교하지 못했다'), unknown.action);
    const code = classifyRun(
      run(OWN, look({ family: 'Geist Mono', size: 12, lineHeight: { unit: 'PIXELS', value: 21 }, letterSpacing: { unit: 'PIXELS', value: 0 } })),
      ENV,
    );
    assertEq([code.category, code.role], ['no-style', 'codeSm'], 'Geist Mono 12 / 21px');
    // 같은 21px 상자를 퍼센트로 적어도 같은 그림이다(12 × 175% = 21).
    const pct = classifyRun(
      run(OWN, look({ family: 'Geist Mono', size: 12, lineHeight: { unit: 'PERCENT', value: 175 }, letterSpacing: { unit: 'PIXELS', value: 0 } })),
      ENV,
    );
    assertEq([pct.category, pct.role, pct.departs], ['no-style', 'codeSm', []], 'Geist Mono 12 / 175%');
  });

  await check('고정폭 글 안 한글을 본문 서체로 칠한 구간 → 통과', () => {
    // 고정폭 한글 칠하기가 남기는 모양: 스타일 없음 · 본문 서체 · 코드 역할의 크기 · 21px 상자 · 자간 0.
    const painted = look({
      size: 12,
      lineHeight: { unit: 'PIXELS', value: 21 },
      letterSpacing: { unit: 'PIXELS', value: 0 },
      bound: { fontFamily: prim('font/family/Pretendard') },
    });
    const hangul: TextRun = { ...run(OWN, painted, '토큰'), codeRole: 'codeSm' };
    const v = classifyRun(hangul, ENV);
    assertEq([v.category, v.role], ['mono-hangul', 'codeSm'], 'painted hangul');
    assertEq(v.signature, `${textStyleNameOf('codeSm')} 안 한글 · Pretendard`, 'signature');
    // 변형: 같은 글에 코드 구간이 없으면 그냥 스타일 없는 글자 — 본문 역할과 행간 · 자간이 다르다.
    assertEq(classifyRun({ ...hangul, codeRole: null }, ENV).category, 'off-role', 'no code neighbour');
    // 변형: 한글 아닌 글자가 섞였으면 칠한 구간이 아니다.
    assertEq(classifyRun({ ...hangul, text: '토큰 값' }, ENV).category, 'off-role', 'not Hangul only');
    // 변형: 줄 상자가 코드 역할과 다르면 칠한 구간이 아니다.
    const offBox = { ...hangul, look: { ...painted, lineHeight: { unit: 'PIXELS', value: 18 } as const } };
    assertEq(classifyRun(offBox, ENV).category, 'off-role', 'line box departs');
    // 변형: 다른 서체로 그렸으면 아니다.
    assertEq(classifyRun({ ...hangul, look: { ...painted, family: 'Apple SD Gothic Neo' } }, ENV).category, 'off-role', 'other face');
  });

  // ── 묶기 · 문장 ───────────────────────────────────────────────────────────

  await check('같은 분류 · 같은 값은 한 줄, 개수 · 페이지 · 순서', () => {
    const runs: TextRun[] = [
      { ...CASE.bare, nodeId: 'a', pageId: 'p1', pageName: 'Home', where: 'Home' },
      { ...CASE.bare, nodeId: 'b', pageId: 'p1', pageName: 'Home', where: 'Home' },
      { ...CASE.bare, nodeId: 'c', pageId: 'p2', pageName: 'Detail', where: 'Detail' },
      { ...CASE.searching, nodeId: 'd', pageId: 'p1', pageName: 'Home', where: 'ListingCard · CoUI' },
      { ...CASE.styled, nodeId: 'e', pageId: 'p1', pageName: 'Home' },
      { ...CASE.libraryLabel, nodeId: 'f', pageId: 'p1', pageName: 'Home', where: 'Button' },
    ];
    const report = buildConsumerAuditReport(runs, ENV, { scope: '현재 페이지 "Home"', pageCount: 1, textNodes: 6 });
    assertEq(
      report.groups.map((g) => [g.category, g.runs]),
      [['off-role', 1], ['no-style', 3], ['styled', 1], ['library', 1]],
      'groups in category order',
    );
    const bare = report.groups[1];
    assertEq(bare.pages.map((p) => [p.pageName, p.count, p.ids]), [['Home', 2, ['a', 'b']], ['Detail', 1, ['c']]], 'pages');
    assertEq(bare.where, [{ name: 'Home', count: 2 }, { name: 'Detail', count: 1 }], 'where');
    assertEq(bare.sample, '부가 설명', 'sample');
    assertEq(
      formatConsumerAudit(report).slice(0, 3),
      [
        '범위: 현재 페이지 "Home" · 글 6개',
        '⚠ 경고 4 — 역할에 없는 조합 1 · 스타일 없음 3',
        '통과 · 대상 아님 2 — CoUI 스타일 1 · CoUI 컴포넌트 안 1',
      ],
      'summary lines',
    );
  });

  await check('선택할 노드는 페이지마다 상한, 개수는 참값', () => {
    const many: TextRun[] = [];
    for (let i = 0; i < kAuditIdsPerPage + 5; i++) many.push({ ...CASE.bare, nodeId: `n${i}`, where: 'Home' });
    const report = buildConsumerAuditReport(many, ENV, { scope: 's', pageCount: 1, textNodes: many.length });
    assertEq(report.groups[0].runs, kAuditIdsPerPage + 5, 'runs not capped');
    assertEq(report.groups[0].pages[0].ids.length, kAuditIdsPerPage, 'ids capped');
  });

  await check('경고가 없으면 그렇게 말한다', () => {
    const report = buildConsumerAuditReport([CASE.styled], ENV, { scope: 's', pageCount: 1, textNodes: 1 });
    assertEq(formatConsumerAudit(report)[1], '경고 없음 ✅', 'clean line');
    assert(kAuditCategories.filter((c) => c.warn).length === 4, 'four warning categories');
  });

  // ── 4. 걷기 — 노드 더블 ───────────────────────────────────────────────────

  await check('collectRuns: 실측 사례를 담은 페이지를 걷고, 아무것도 쓰지 않는다', async () => {
    const { pages, deps, mainLookups } = fixture();
    const collected = await collectRuns(pages, deps, {
      couiComponents: COUI,
      skipNames: new Set(),
      mono: 'Geist Mono',
    });
    assertEq(collected.sans, 'Pretendard', 'text face read from the CoUI style and font/family variable');
    assert(mainLookups.includes('i-tf'), 'the consumer-placed instance is looked up');
    // 알아본 CoUI 컴포넌트 안쪽 인스턴스도 원본을 묻는다 — 슬롯에 바꿔 넣은 로컬
    // 컴포넌트는 거기서만 알아볼 수 있다.
    assert(mainLookups.includes('I3;7') && mainLookups.includes('I9;3'), 'nested instances are looked up');
    // 숨은 프레임 안 · 숨은 글자 · 빈 글자는 세지 않는다.
    assertEq(collected.textNodes, 21, 'visible, non-empty text nodes');
    const env: AuditEnv = { sans: collected.sans, mono: 'Geist Mono' };
    const byNode = new Map<string, string[]>();
    for (const r of collected.runs) {
      const list = byNode.get(r.nodeId) ?? [];
      list.push(classifyRun(r, env).category);
      byNode.set(r.nodeId, list);
    }
    const expect: Record<string, string[]> = {
      t1: ['styled'],
      'I1;1': ['library'],
      t3: ['role-weight'],
      'I2;1': ['off-role'],
      'I3;5': ['override'],
      t6: ['no-style'],
      'I4;1': ['other-library'],
      fl1: ['off-role'],
      fl2: ['off-role'],
      fl3: ['off-role'],
      chip: ['no-style'],
      mixed: ['styled', 'off-role'],
      'I6;1': ['override'],
      'I5;2;1': ['override'],
      'I7;1': ['other-library'],
      d6: ['no-style'],
      'I9;1': ['library'],
      'I9;3;1': ['off-role'],
      'I8;1': ['override'],
      code: ['styled', 'mono-hangul', 'styled'],
      h24: ['no-style'],
    };
    assertEq(Object.fromEntries([...byNode.entries()].sort()), Object.fromEntries(Object.entries(expect).sort()), 'per node');
    const where = new Map(collected.runs.map((r) => [r.nodeId, r.where]));
    assertEq(where.get('I2;1'), 'ListingCard · CoUI', 'local instance → its component');
    assertEq(where.get('chip'), 'Chip · Local', 'local component set → the set name');
    assertEq(where.get('t6'), 'Home', 'own text → its screen');
    assertEq(where.get('I6;1'), 'NewThing', 'unknown CoUI name recognised by its variables');
    assertEq(where.get('I5;2;1'), 'Button', 'override from an enclosing local instance');
    // CoUI 대화상자의 슬롯에 바꿔 넣은 로컬 컴포넌트의 글자는 이 파일의 글자로 읽는다.
    assertEq(where.get('I9;3;1'), 'OrderSummary', 'local component swapped into a CoUI slot');
    const swapped = collected.runs.find((r) => r.nodeId === 'I9;3;1');
    assertEq(swapped?.context, { kind: 'local-component', component: 'OrderSummary' }, 'swapped slot context');
    // 레지스트리에 없는 이름 · 변수 바인딩 없음 · CoUI 스타일 → CoUI 로 알아본다.
    assertEq(where.get('I8;1'), 'SegmentedControl', 'unknown CoUI name recognised by its text style');
    // 글자가 푸는 타이포 모드를 읽어 그 모드의 역할과 견준다.
    const h24 = collected.runs.find((r) => r.nodeId === 'h24');
    assertEq(h24?.look?.mode, 'Mobile', 'mode read off resolvedVariableModes');
    assertEq(classifyRun(h24!, env).role, 'headlineLarge', 'literal 24 in a Mobile frame');
    const codeRuns = collected.runs.filter((r) => r.nodeId === 'code');
    assertEq(codeRuns.map((r) => r.codeRole), ['codeSm', 'codeSm', 'codeSm'], 'code role of the node');

    const report = buildConsumerAuditReport(collected.runs, env, {
      scope: '모든 페이지 (2)',
      pageCount: 2,
      textNodes: collected.textNodes,
    });
    const flow = report.groups.find((g) => g.where.some((w) => w.name === 'FlowLabel'));
    assert(flow != null && flow.runs === 3 && flow.where[0].count === 3, 'annotation texts fold into one row');
    const bare = report.groups.find((g) => g.category === 'no-style' && g.sample === '부가 설명');
    assertEq(bare?.pages.map((p) => p.pageName), ['Home', 'Detail'], 'one row spans two pages');
  });

  await check('collectRuns: 건너뛸 이름 아래는 걷지 않고, 그 수와 못 찾은 이름을 따로 적는다', async () => {
    const { pages, deps } = fixture();
    const collected = await collectRuns(pages, deps, {
      couiComponents: COUI,
      skipNames: new Set(['FlowLabel', 'FlowLable']),
      mono: 'Geist Mono',
    });
    assertEq(collected.skippedTexts, 3, 'skipped');
    assertEq(collected.textNodes, 18, 'scanned');
    assertEq(collected.skippedNames, ['FlowLabel'], 'matched names');
    assertEq(collected.unmatchedSkipNames, ['FlowLable'], 'a misspelled name is not silent');
    assert(!collected.runs.some((r) => r.nodeId.startsWith('fl')), 'no FlowLabel runs');
    const report = buildConsumerAuditReport(collected.runs, { sans: collected.sans, mono: 'Geist Mono' }, {
      scope: 's',
      pageCount: 2,
      textNodes: collected.textNodes,
      skippedNames: collected.skippedNames,
      skippedTexts: collected.skippedTexts,
      unmatchedSkipNames: collected.unmatchedSkipNames,
    });
    const log = formatConsumerAudit(report);
    assert(log.includes('건너뜀 — 이름이 FlowLabel 인 레이어 아래 글 3개'), 'the skip is reported, not silent');
    assert(
      log.some((l) => l.startsWith('⚠ 건너뛸 이름 중 이 범위에 없는 것: FlowLable')),
      `the unmatched name is reported: ${log.join(' | ')}`,
    );
  });

  await check('collectRuns: 본문 서체 — 범위의 스타일 · 변수, 없으면 CoUI 글자의 서체, 없으면 라이브러리 변수 이름', async () => {
    const raw = (id: string): AuditNode => text(id, [{ text: '설명', family: 'SF Pro' }]);
    const button = (id: string): AuditNode =>
      instance(id, { name: 'Button', remote: true }, [
        text(`${id};1`, [{ text: '확인', face: 'SemiBold', size: 14, lineHeight: { unit: 'PERCENT', value: 140 }, letterSpacing: { unit: 'PIXELS', value: -0.14 } }]),
      ]);
    const page = (children: AuditNode[]): AuditPage[] => [{ id: 'p', name: 'P', children: [frame('f', 'Screen', children)] }];
    let libraryAsked = 0;
    const depsWith = (librarySans: string | null): AuditDeps => ({
      ...fixture().deps,
      async librarySans() {
        libraryAsked += 1;
        return librarySans;
      },
    });
    const opts = { couiComponents: COUI, skipNames: new Set<string>(), mono: 'Geist Mono' };
    // CoUI 버튼의 라벨 서체로 읽는다 — 라이브러리 변수는 묻지 않는다.
    const fromText = await collectRuns(page([raw('r1'), button('b1')]), depsWith('Inter'), opts);
    assertEq([fromText.sans, libraryAsked], ['Pretendard', 0], 'face of the CoUI label');
    const sf = classifyRun(fromText.runs.find((r) => r.nodeId === 'r1')!, { sans: fromText.sans, mono: 'Geist Mono' });
    assertEq([sf.category, sf.departs], ['off-role', ['family']], 'SF Pro is not the text face');
    // CoUI 글자도 없으면 켜진 라이브러리의 Primitives 변수 이름에서.
    const fromLibrary = await collectRuns(page([raw('r2')]), depsWith('Pretendard'), opts);
    assertEq([fromLibrary.sans, libraryAsked], ['Pretendard', 1], 'library Primitives as the last source');
    // 그래도 없으면 모른다 — 그 판정은 그림이 그대로라고 말하지 않는다(위의 사례).
    const none = await collectRuns(page([raw('r3')]), depsWith(null), opts);
    assertEq(none.sans, null, 'unknown');
  });

  await check('mainComponentName: 세트의 변형은 세트 이름, 부모를 못 읽으면 변형 이름', () => {
    assertEq(mainComponentName({ name: 'Size=md', parent: { type: 'COMPONENT_SET', name: 'Button' } }), 'Button', 'set');
    assertEq(mainComponentName({ name: 'Logo', parent: { type: 'FRAME', name: 'Assets' } }), 'Logo', 'plain component');
    const unreadable = {
      name: 'State=Default',
      get parent(): { type: string; name: string } {
        throw new Error('cannot read the parent of a remote component');
      },
    };
    assertEq(mainComponentName(unreadable), 'State=Default', 'unreadable parent');
  });

  if (failures > 0) {
    console.error(`\n${failures} failure(s)`);
    process.exit(1);
  }
  console.log('\nall ok');
}

// ── 노드 더블 ───────────────────────────────────────────────────────────────

/** 쓰기를 받으면 던지는 노드. 이 명령은 노드를 바꾸지 않는다. */
function frozen<T extends object>(target: T): T {
  return new Proxy(target, {
    set(_t, key) {
      throw new Error(`write to node.${String(key)} — the audit must not modify nodes`);
    },
    defineProperty(_t, key) {
      throw new Error(`defineProperty node.${String(key)} — the audit must not modify nodes`);
    },
    deleteProperty(_t, key) {
      throw new Error(`delete node.${String(key)} — the audit must not modify nodes`);
    },
  });
}

interface SegSpec {
  text: string;
  family?: string;
  face?: string;
  size?: number;
  lineHeight?: AuditSegment['lineHeight'];
  letterSpacing?: AuditSegment['letterSpacing'];
  style?: string;
  bound?: Record<string, string>;
}

function seg(spec: SegSpec): AuditSegment {
  return {
    characters: spec.text,
    fontName: { family: spec.family ?? 'Pretendard', style: spec.face ?? 'Regular' },
    fontSize: spec.size ?? 13,
    lineHeight: spec.lineHeight ?? { unit: 'PERCENT', value: 150 },
    letterSpacing: spec.letterSpacing ?? { unit: 'PIXELS', value: -0.13 },
    textStyleId: spec.style ?? '',
    boundVariables: Object.fromEntries(Object.entries(spec.bound ?? {}).map(([f, id]) => [f, { id }])),
  };
}

// `figma.mixed` 의 대역 — 글 전체가 한 글꼴이 아닐 때 `fontName` 이 돌려주는 심볼.
const MIXED = Symbol('mixed');

function text(
  id: string,
  segs: SegSpec[],
  extra: Partial<{ visible: boolean; nodeBound: Record<string, string>; modes: Record<string, string> }> = {},
): AuditNode {
  const characters = segs.map((s) => s.text).join('');
  const fonts = new Set(segs.map((x) => `${x.family ?? 'Pretendard'}\u0001${x.face ?? 'Regular'}`));
  const first = seg(segs[0]);
  return frozen({
    id,
    name: characters,
    type: 'TEXT',
    visible: extra.visible ?? true,
    characters,
    fontName: fonts.size === 1 ? first.fontName : MIXED,
    resolvedVariableModes: extra.modes ?? {},
    boundVariables: Object.fromEntries(Object.entries(extra.nodeBound ?? {}).map(([f, vid]) => [f, [{ id: vid }]])),
    getStyledTextSegments: () => segs.map(seg),
  });
}

function frame(id: string, name: string, children: AuditNode[], visible = true, type = 'FRAME'): AuditNode {
  return frozen({ id, name, type, visible, children });
}

const MAINS = new Map<string, { name: string; remote: boolean }>();

/** 레지스트리가 아는 CoUI 컴포넌트 이름 — 걷기 사례가 쓰는 것만. */
const COUI: ReadonlySet<string> = new Set(['Button', 'TextField', 'Dialog']);

function instance(
  id: string,
  main: { name: string; remote: boolean },
  children: AuditNode[],
  overrides: { id: string; overriddenFields: string[] }[] = [],
): AuditNode {
  MAINS.set(id, main);
  return frozen({ id, name: main.name, type: 'INSTANCE', visible: true, children, overrides });
}

function fixture(): { pages: AuditPage[]; deps: AuditDeps; mainLookups: string[] } {
  const mainLookups: string[] = [];
  const variables: Record<string, VariableRef> = {
    'v-fs-label-small': sem('font-size/label-small'),
    'v-ls-label-small': sem('letter-spacing/label-small'),
    'v-fw-title': sem('font-weight/title'),
    'v-prim-14': prim('font/size/14'),
    'v-ls-14': sem('letter-spacing/size-14'),
    'v-family': prim('font/family/Pretendard'),
  };
  const styles: Record<string, { name: string; remote: boolean; family: string | null }> = {
    's-body-small': { name: 'Body/Small', remote: true, family: 'Pretendard' },
    's-title-small': { name: 'Title/Small', remote: true, family: 'Pretendard' },
    's-label-medium': { name: 'Label/Medium', remote: true, family: 'Pretendard' },
    's-code-sm': { name: textStyleNameOf('codeSm')!, remote: true, family: 'Geist Mono' },
  };
  // 라이브러리의 타이포 컬렉션과 그 밖의 컬렉션 — 노드는 둘 다의 모드를 푼다.
  const collections: Record<string, AuditCollectionInfo> = {
    'c-typo': {
      name: 'Semantic/ Typography',
      modes: [
        { modeId: 'm-mobile', name: 'Mobile' },
        { modeId: 'm-tablet', name: 'Tablet' },
        { modeId: 'm-desktop', name: 'Desktop' },
      ],
    },
    'c-color': { name: 'Semantic/ Color · CoUI', modes: [{ modeId: 'm-light', name: 'Light' }] },
  };
  const MOBILE = { 'c-color': 'm-light', 'c-typo': 'm-mobile' };
  const bare = (t: string): SegSpec => ({ text: t });
  const buttonLabel: SegSpec = {
    text: '확인',
    face: 'SemiBold',
    size: 14,
    lineHeight: { unit: 'PERCENT', value: 140 },
    letterSpacing: { unit: 'PIXELS', value: -0.14 },
    bound: { fontSize: 'v-prim-14', letterSpacing: 'v-ls-14', fontFamily: 'v-family' },
  };
  const annotation = (id: string): AuditNode =>
    frame(`f-${id}`, 'FlowLabel', [
      text(id, [{ text: '→ 다음 화면', size: 11, lineHeight: { unit: 'AUTO' }, letterSpacing: { unit: 'PERCENT', value: 0 } }]),
    ]);

  const home: AuditPage = {
    id: 'p1',
    name: 'Home',
    children: [
      frame('f1', 'Home', [
        text('t1', [{ text: '환전하기', style: 's-body-small' }]),
        // 라벨 글자만 고쳐 쓴 Button — 모양은 라이브러리 그대로다.
        instance('i-btn', { name: 'Button', remote: true }, [text('I1;1', [buttonLabel])], [
          { id: 'I1;1', overriddenFields: ['characters', 'styledTextSegments'] },
        ]),
        text('t3', [
          {
            text: 'STEP 1 / 3',
            face: 'Bold',
            size: 12,
            lineHeight: { unit: 'PERCENT', value: 140 },
            letterSpacing: { unit: 'PIXELS', value: -0.12 },
            bound: { fontSize: 'v-fs-label-small', fontWeight: 'v-fw-title', letterSpacing: 'v-ls-label-small' },
          },
        ]),
        instance('i-card', { name: 'ListingCard · CoUI', remote: false }, [
          text('I2;1', [
            {
              text: '환전 찾는 중',
              face: 'Bold',
              size: 12,
              lineHeight: { unit: 'PERCENT', value: 120 },
              letterSpacing: { unit: 'PERCENT', value: -1 },
              bound: { fontSize: 'v-fs-label-small', fontWeight: 'v-fw-title' },
            },
          ]),
        ]),
        instance(
          'i-tf',
          { name: 'TextField', remote: true },
          [
            frame('I3;2', 'field', [
              text('I3;5', [{ text: '1,000', face: 'SemiBold', size: 17, lineHeight: { unit: 'PERCENT', value: 140 }, letterSpacing: { unit: 'PIXELS', value: -0.17 } }]),
              // 이미 알아본 CoUI 컴포넌트 안쪽 인스턴스 — 원본을 묻지 않는다.
              instance('I3;7', { name: 'Icon', remote: true }, []),
            ]),
          ],
          [{ id: 'I3;5', overriddenFields: ['fontName', 'fontSize', 'boundVariables'] }],
        ),
        text('t6', [bare('부가 설명')]),
        instance(
          'i-sb',
          { name: 'Status bar', remote: true },
          [text('I4;1', [{ text: '9:41', family: 'SF Pro', face: 'Semibold', size: 17 }])],
          [{ id: 'I4;1', overriddenFields: ['fontName'] }],
        ),
        // 이 빌드의 레지스트리에 없는 CoUI 컴포넌트 — 글자가 CoUI 변수에 묶여 알아본다.
        instance(
          'i-new',
          { name: 'NewThing', remote: true },
          [text('I6;1', [{ ...buttonLabel, size: 16 }], { nodeBound: { fontSize: 'v-prim-14' } })],
          [{ id: 'I6;1', overriddenFields: ['fontSize'] }],
        ),
        // 레지스트리에 없는 이름에 CoUI 변수도 없는 라이브러리 컴포넌트 — 다른 라이브러리.
        instance('i-plain', { name: 'Avatar Stack', remote: true }, [text('I7;1', [bare('취소')])]),
        // 로컬 인스턴스가 그 안의 CoUI 버튼 글자를 덮어쓴다.
        instance(
          'i-row',
          { name: 'Row · Local', remote: false },
          [instance('I5;2', { name: 'Button', remote: true }, [text('I5;2;1', [{ ...buttonLabel, size: 15 }])])],
          [{ id: 'I5;2;1', overriddenFields: ['fontSize'] }],
        ),
        // CoUI 대화상자 — 제목은 라이브러리 몫이고, 내용 슬롯에 이 파일의 컴포넌트를
        // 바꿔 넣었다. 그 안의 글자는 이 파일의 것이다.
        instance('i-dialog', { name: 'Dialog', remote: true }, [
          text('I9;1', [{ text: '환전 확인', face: 'Bold', size: 16, lineHeight: { unit: 'PERCENT', value: 140 }, letterSpacing: { unit: 'PIXELS', value: -0.16 } }]),
          instance('I9;3', { name: 'OrderSummary', remote: false }, [
            text('I9;3;1', [
              { text: '수수료 포함', face: 'Bold', size: 12, lineHeight: { unit: 'PERCENT', value: 120 }, letterSpacing: { unit: 'PIXELS', value: -0.12 } },
            ]),
          ]),
        ]),
        // 레지스트리에 없는 이름의 CoUI 컴포넌트 — 라벨은 CoUI 스타일만 갖고 노드의
        // 변수 바인딩은 없다(빌더가 스타일을 붙이며 푼다). 그 글꼴을 덮어썼다.
        instance(
          'i-seg',
          { name: 'SegmentedControl', remote: true },
          [text('I8;1', [{ text: '매수', face: 'SemiBold', size: 13, lineHeight: { unit: 'PERCENT', value: 140 }, letterSpacing: { unit: 'PIXELS', value: -0.13 }, style: 's-label-medium' }])],
          [{ id: 'I8;1', overriddenFields: ['fontName'] }],
        ),
        // 코드 글 — 한글 구간을 고정폭 한글 칠하기가 본문 서체로 칠했다.
        text('code', [
          { text: 'curl -H ', family: 'Geist Mono', size: 12, lineHeight: { unit: 'PIXELS', value: 21 }, letterSpacing: { unit: 'PIXELS', value: 0 }, style: 's-code-sm' },
          { text: '토큰', size: 12, lineHeight: { unit: 'PIXELS', value: 21 }, letterSpacing: { unit: 'PIXELS', value: 0 }, bound: { fontFamily: 'v-family' } },
          { text: ' x', family: 'Geist Mono', size: 12, lineHeight: { unit: 'PIXELS', value: 21 }, letterSpacing: { unit: 'PIXELS', value: 0 }, style: 's-code-sm' },
        ]),
        // Mobile 로 그리는 프레임의 숫자로 적은 24 — Headline/Large 가 Mobile 에서 그리는 크기.
        text(
          'h24',
          [{ text: '보내는 금액', face: 'Bold', size: 24, lineHeight: { unit: 'PERCENT', value: 140 }, letterSpacing: { unit: 'PIXELS', value: -0.48 } }],
          { modes: MOBILE },
        ),
        // 한 글 안에 두 모양 — 구간마다 따로 판정한다.
        text('mixed', [
          { text: '₩1,000', style: 's-title-small', face: 'Bold', size: 16, lineHeight: { unit: 'PERCENT', value: 140 }, letterSpacing: { unit: 'PIXELS', value: -0.16 } },
          { text: ' 원', size: 16, lineHeight: { unit: 'PERCENT', value: 150 }, letterSpacing: { unit: 'PIXELS', value: -0.16 } },
        ]),
        // 보이지 않는 것 · 빈 것은 세지 않는다.
        frame('f-hidden', 'hidden', [text('th', [bare('숨김')])], false),
        text('t-hidden', [bare('숨김')], { visible: false }),
        text('t-empty', [bare('   ')]),
      ]),
      annotation('fl1'),
      annotation('fl2'),
      annotation('fl3'),
      frame(
        'cs',
        'Chip · Local',
        [
          frame('c1', 'State=Default', [
            text('chip', [{ text: '칩', size: 12, letterSpacing: { unit: 'PIXELS', value: -0.12 } }]),
          ], true, 'COMPONENT'),
        ],
        true,
        'COMPONENT_SET',
      ),
    ],
  };
  const detail: AuditPage = {
    id: 'p2',
    name: 'Detail',
    children: [frame('f2', 'Detail', [text('d6', [bare('부가 설명')])])],
  };
  const deps: AuditDeps = {
    async styleOf(id) {
      return styles[id] ?? null;
    },
    async variableOf(id) {
      return variables[id] ?? null;
    },
    async mainOf(node) {
      mainLookups.push(node.id);
      return MAINS.get(node.id) ?? null;
    },
    async collectionOf(id) {
      return collections[id] ?? null;
    },
  };
  return { pages: [home, detail], deps, mainLookups };
}

void main();
