// Channel B — 디자이너가 내린 fidelity 리포트를 읽어 마크다운으로 만든다.
//
// 플러그인의 `verifyFidelity()` 는 이미 필드 단위로 expected/actual/looksLike 를
// 만들지만 그 결과가 로그로만 나가서 레포에 남지 않는다. 이 스크립트는 그
// 출력을 파일로 받아 검증하고 사람이 읽을 형태로 바꾼다.
//
// Channel A 와의 분업: A 는 무인으로 돌지만 구조·기하만 본다. 색 · 토큰 바인딩 ·
// 타이포 · radius · shadow 는 Figma 데스크톱의 살아있는 선택이 있어야 읽히므로
// **이 채널에서만** 답이 나온다. 그래서 A 가 조용하다고 B 를 건너뛸 수 없다.
//
// 이 리포트가 사람에게 닿는 경로는 자동화가 만드는 **이슈 본문 하나뿐**이다.
// 그래서 리포트의 범위를 제한하는 사실(읽지 않은 파일 · 필터 · 생성 시각 · 잘린
// 표)은 전부 본문 안에 있어야 한다. stderr 로만 말한 것은 아무에게도 닿지 않는다.
//
// Usage:
//   tsx reverse/ingest_fidelity.ts [--dir=reverse/incoming] [--out=<md>]

// 이스케이프 · 바이트 계산 · 예산 · 잘림 문구 · 인용값 상한 · 캡처 시각 진술은
// 두 채널이 **같아야 하는 것**이라 여기서 구현하지 않고 공통 모듈에서 가져온다.
// 같은 생각을 두 곳에 적으면 갈라진다 — 캡처 시각 문장이 실제로 그렇게 갈라졌다.
import {
  CHANNEL_B_BUDGET_BYTES,
  MAX_TABLE_ROWS,
  ageNote,
  brief,
  budgetOf,
  cell as escapeCell,
  evidenceBudget,
  spend,
  truncationNotice,
  truncationNoticeReserve,
  utf8Bytes,
} from './report_format';

// `@types/node` 대신 로컬 ambient — scripts/*.ts 와 같은 형태.
// typeRoots 가 `@figma/plugin-typings` 로 고정돼 플러그인 코드가 Node API 에
// 닿지 못하게 막고 있고, 전역 Node 타입 패키지를 넣으면 그 격리가 사라진다.
declare const process: {
  cwd(): string;
  argv: string[];
  exit(code: number): never;
};
declare const console: {
  log(...args: unknown[]): void;
  error(...args: unknown[]): void;
};
declare function require(id: string): unknown;
// 이 스크립트가 놓인 자리. 레지스트리는 cwd 가 아니라 **이 파일 기준**으로 찾는다 —
// cwd 로 찾으면 어디서 부르느냐에 따라 모집단 하한의 분모가 사라지고, 분모가 사라진
// 하한은 조용히 꺼진다.
declare const __dirname: string;

const { existsSync, readFileSync, writeFileSync, readdirSync } = require(
  'node:fs',
) as {
  existsSync(p: string): boolean;
  readFileSync(p: string, enc: string): string;
  writeFileSync(p: string, data: string, enc: string): void;
  readdirSync(p: string): string[];
};
const { resolve } = require('node:path') as {
  resolve(...parts: string[]): string;
};

// diff_structure.ts 와 같은 계약. 1 은 "디자이너가 무언가 바꿨다",
// 2 는 "파이프라인이 깨졌다" — 자동화가 둘을 다르게 처리한다.
const EXIT_NO_DIFF = 0;
const EXIT_DIFF = 1;
const EXIT_INFRA = 2;

// 이 채널의 예산(`CHANNEL_B_BUDGET_BYTES`)이 어떻게 나뉘는가.
//
// **행 상한만으로는 문서가 묶이지 않는다.** 불일치는 컴포넌트별로 쪼개져 렌더되므로
// 표 하나가 50 행이어도 표가 300 개면 15,000 행이 된다. 그리고 행 수 상한은 셀
// 내용이 좁을 때만 맞는 근사다 — 이 플러그인이 실제로 내보내는 가장 긴 `looksLike`
// 는 202자이고, 그 폭의 행 200개는 96,722 바이트다. 지켜야 할 성질이 바이트면
// 바이트로 센다.
//
// **몫을 상수로 적지 않는다.** 몫이 상수면 그 합이 채널 예산과 같다는 것을 아무도
// 강제하지 않고, 어느 몫에도 속하지 않는 문장(절 제목 · 귀속 배너 · 절 잘림 문구)이
// 조용히 예산 밖에 앉는다. 실측: 머리말 1,998 · 불일치 절 24,149 · 비교하지 않은
// 항목 1,513 · 꼬리말 1,454 = 29,117 바이트가 상한 28,000 을 1,117 넘겼고, 그중
// 고정 산문 몫의 추정치(2,000)는 실제 3,452 를 낮잡고 있었다. 그래서 잘리지 않는
// 산문은 **그때그때 재고**(`evidenceBudget`) 남는 전부를 증거에 준다 — 합이 구조적으로
// 채널 예산이라 어긋날 수가 없다.
//
// 산문이 예산을 통째로 먹을 수 없는 이유는 인용값이 묶여 있기 때문이다: 봉투에서
// 온 값은 전부 `brief` 를 거쳐 한 값이 `MAX_QUOTED_CHARS × 3` 바이트 안에 들어가고,
// 그런 슬롯은 다섯(출처 파일 · 필터 · 생성 시각 · buildHash · 꼬리말의 출처 파일)뿐이다.
// 채널 예산 자신이 Channel A 몫·감싸는 글 몫과 함께 이슈 본문 상한에 맞는지는
// `report_format.ts` 가 적재 시점에 확인한다 — 이 파일은 그 산술을 다시 하지 않는다.

/**
 * 비교하지 않은 항목 표가 꼬리말에서 가져갈 수 있는 최대치.
 *
 * 꼬리말은 잘리지 않으므로 이 표가 무제한이면 증거 예산을 그만큼 밀어낸다 —
 * 항목 3,000개짜리 리포트에서 불일치가 한 행도 안 실리는 쪽이 된다. 표 자신도
 * 행 상한과 이 바이트 상한 둘 다에서 잘린다.
 */
const UNCHECKED_SECTION_BYTES = 2000;

// 플러그인이 훑는 컴포넌트 레지스트리. 전체 스윕의 모집단 하한이 이것을 분모로 쓴다.
const REGISTRY_DATA = resolve(__dirname, '..', 'src', 'data', 'components.json');

// 전체 스윕이 읽었어야 할 컴포넌트 비율의 하한.
//
// **하한이 "0 보다 크다" 이면 하한이 아니다.** 145개짜리 레지스트리를 전부 훑겠다고
// 선언한 스윕이 1개만 읽고 "불일치 없음" 으로 끝나면, 그 출력은 진짜 깨끗한 스윕과
// 글자 하나 다르지 않다 — 그리고 이 채널의 0 은 자동화가 이슈를 아예 만들지 않는
// 쪽이라, 붕괴한 스윕이 **아무 흔적도 남기지 않고** 지나간다.
//
// 같은 교리를 따른다: 모집단의 절반을 잃은 실행은 결과가 아니라 사고다. 두 채널이
// 이 수를 **각자** 갖는 이유는 분모가 다르기 때문이다 — Channel A 는 베이스라인
// 노드 수를, 여기서는 레지스트리 컴포넌트 수를 센다.
//
// 그래서 이 수는 공유되지 않고 **같은 값을 우연히 갖고 있을 뿐**이다. Channel A 의
// 것은 `config.json` 이 정하고 운영자가 0.1 까지 낮출 수 있는 반면 이쪽은 코드에
// 박혀 있다 — 한쪽을 낮춘 사람이 두 채널의 엄격함이 갈라진 것을 알 방법이 없다.
// 두 수를 하나로 묶지 않는 것은 분모가 다른 하한을 한 손잡이로 돌리면 그 손잡이가
// 무엇을 느슨하게 하는지 알 수 없게 되기 때문이고, 그 대가로 갈라짐이 남는다.
const FULL_SWEEP_FLOOR_RATIO = 0.5;

const DEFAULT_DIR = 'reverse/incoming';
const ENVELOPE_KIND = 'coui-figma-fidelity';
const ENVELOPE_SCHEMA = 1;

/**
 * 불일치 한 건. 플러그인은 `component` · `field` · `expected` · `actual` ·
 * `looksLike` 를 담아 보내지만, 검증이 보장하는 것은 **객체라는 것뿐**이라
 * 필드 타입을 선언하지 않는다. 확인하지 않은 것을 타입으로 주장하면 렌더가
 * 그 주장을 믿고 방어를 뺀다.
 */
type RawMiss = Record<string, unknown>;

/**
 * `notes` 원소 하나. 미스와 같은 이유로 필드 타입을 선언하지 않는다 — 검증이
 * 보장하는 것은 컴포넌트·필드·detail 중 하나를 실을 수 있는 모양이라는 것뿐이다.
 */
type RawNote = Record<string, unknown>;

interface FidelityEnvelope {
  schema: number;
  kind: string;
  generatedAt: string;
  buildHash: string;
  entryFilter: string | null;
  /**
   * 전체 스윕이었을 때 레지스트리의 컴포넌트 수, 필터가 걸렸으면 `null`.
   *
   * 리포트에 분모로 실린다 — "컴포넌트 145개를 읽었다" 와 "145개 중 145개를 읽었다"
   * 는 읽는 사람에게 다른 문장이고, 뒤쪽만이 그 스윕이 무엇을 덮었는지 말한다.
   */
  registrySize: number | null;
  report: {
    misses: RawMiss[];
    componentsRead: number;
    checksRun: number;
    unchecked: string[];
    /** 호스트 파생 필드 — 비교 대상이 아니다. 옛 리포트에는 없다(빈 목록으로 읽는다). */
    hostDerived?: string[];
    /**
     * 진술이 없어 마크 획을 비교하지 못한 컴포넌트. `unchecked` 가 아니다 —
     * 저건 진술됐는데 이 모듈이 아직 못 읽는 자리이고, 여기는 애초에 비교할
     * 진술 자체가 없는 자리다. 옛 리포트에는 없다(빈 목록으로 읽는다).
     */
    strokeUnstated?: string[];
    /**
     * 불일치는 아니지만 읽는 사람이 알아야 하는 관찰(예: 값은 맞지만 리터럴이라
     * 역할이 바뀌어도 따라오지 않는 자간). 옛 리포트에는 없다(빈 배열로 읽는다).
     */
    notes?: RawNote[];
  };
}

/** 읽은 리포트 파일과, 같은 디렉터리에서 읽지 않고 남긴 파일의 수. */
interface Source {
  chosen: string;
  total: number;
}

function fail(what: string, why: string, doThis: string): never {
  console.error(`❌ ${what}`);
  console.error(`   왜: ${why}`);
  console.error(`   무엇을: ${doThis}`);
  return process.exit(EXIT_INFRA);
}

function argValue(flag: string): string | null {
  const hit = process.argv.find((a) => a.startsWith(`${flag}=`));
  return hit === undefined ? null : hit.slice(flag.length + 1);
}

/**
 * 파일 쓰기 실패는 **인프라 실패**이지 디자인 변경이 아니다.
 *
 * 감싸지 않으면 예외가 그대로 올라가 Node 가 종료 코드 1 로 끝나고, 자동화는
 * 그 1 을 "디자이너가 무언가 바꿨다" 로 읽어 **쓰이지도 않은 파일**을 본문으로
 * 이슈를 만들려 든다. 실패한 쓰기가 변경 신호로 둔갑하는 경로다.
 */
function writeOut(path: string, data: string, label: string): void {
  try {
    writeFileSync(path, data, 'utf8');
  } catch (e) {
    fail(
      `${label} 기록 실패: ${path}`,
      `쓰기 실패가 종료 코드 1 로 새어 나가면 자동화는 그것을 "변화 있음" 으로 읽고 존재하지 않는 파일로 이슈를 만든다 (${String(e)})`,
      '상위 디렉터리가 존재하고 쓰기 권한이 있는지 확인하라',
    );
  }
}

function isStringArray(v: unknown): v is string[] {
  return Array.isArray(v) && v.every((x) => typeof x === 'string');
}

/** 셈으로 읽어도 되는 수인지 — 음수 · 소수 · 무한대는 셈이 아니다. */
function isCount(v: unknown): v is number {
  return typeof v === 'number' && Number.isInteger(v) && v >= 0;
}

/** 렌더가 미스 한 건에서 읽는 자리. 미스가 실을 수 있는 주장은 이 다섯뿐이다. */
const MISS_KEYS = ['component', 'field', 'expected', 'actual', 'looksLike'];

/**
 * 다섯 필드를 실을 수 있는 모양인지.
 *
 * 배열과 null 은 객체로 세지 않고, **다섯 자리를 하나도 갖지 않은 객체도 세지
 * 않는다.** 거부하는 근거가 "셀이 전부 빈 행으로 렌더된다" 인데 빈 객체가 내는
 * 행이 정확히 그것이라, 객체라는 것만 보고 통과시키면 그 근거가 절반만 강제된다.
 *
 * 가르는 자리는 값이 아니라 **키**다. 다섯 자리를 갖고 값이 빈 문자열인 미스는
 * "비교했고 한쪽이 비어 있었다" 는 진짜 주장이라 그대로 통과해야 한다 — 이 검사가
 * 그것과 구별되지 않는 행을 막으려는 것이지, 그것을 막으려는 것이 아니다.
 */
function isMissShaped(v: unknown): v is RawMiss {
  if (typeof v !== 'object' || v === null || Array.isArray(v)) return false;
  const o = v as Record<string, unknown>;
  return MISS_KEYS.some((k) => k in o);
}

/** 렌더가 note 한 건에서 읽는 자리. */
const NOTE_KEYS = ['component', 'field', 'detail'];

/**
 * 세 필드를 실을 수 있는 모양인지 — `isMissShaped` 와 같은 근거(객체가 아니거나
 * 세 자리를 하나도 갖지 않으면 셀이 전부 빈 행으로 렌더돼 진짜 관찰과 구별되지
 * 않는다).
 */
function isNoteShaped(v: unknown): v is RawNote {
  if (typeof v !== 'object' || v === null || Array.isArray(v)) return false;
  const o = v as Record<string, unknown>;
  return NOTE_KEYS.some((k) => k in o);
}

/**
 * 이 스윕이 훑었어야 할 컴포넌트 수.
 *
 * 플러그인이 도는 레지스트리와 **같은 파일**에서 읽는다. 이 수를 여기 상수로
 * 적어두면 컴포넌트가 늘 때마다 조용히 낡고, 낡은 분모는 하한을 실제보다 낮게
 * 잡아 정확히 이 하한이 막으려는 붕괴를 통과시킨다.
 *
 * 읽지 못하면 하한을 건너뛰지 않고 **인프라 실패로 멈춘다.** 분모를 잃었을 때
 * 조용히 통과시키면 이 파일 하나를 지우는 것만으로 하한이 꺼지는데, 꺼진 하한은
 * 없는 하한보다 나쁘다 — 있다고 적혀 있기 때문이다.
 */
function registryComponentCount(): number {
  let text: string;
  try {
    text = readFileSync(REGISTRY_DATA, 'utf8');
  } catch (e) {
    return fail(
      `레지스트리를 읽지 못함: ${REGISTRY_DATA}`,
      `전체 스윕의 모집단 하한은 이 수를 분모로 쓴다 — 분모가 없으면 "컴포넌트 1개를 읽었다" 가 붕괴인지 아닌지 판정할 수 없다 (${String(e)})`,
      '이 파일이 제자리에 있는지 확인하라. 옮겼다면 이 스크립트의 경로도 같이 옮겨야 한다',
    );
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch (e) {
    return fail(
      `레지스트리 JSON 파싱 실패: ${REGISTRY_DATA}`,
      `모집단 하한의 분모를 읽을 수 없다 (${String(e)})`,
      '파일이 온전한지 확인하고, 생성기를 다시 돌려라',
    );
  }

  const components =
    typeof parsed === 'object' && parsed !== null
      ? (parsed as Record<string, unknown>).components
      : undefined;
  if (typeof components !== 'object' || components === null || Array.isArray(components)) {
    return fail(
      `레지스트리에서 components 를 찾지 못함: ${REGISTRY_DATA}`,
      '모집단 하한의 분모를 셀 수 없다',
      '이 파일의 스키마가 바뀌었다면 이 스크립트의 읽는 자리도 같이 바꿔야 한다',
    );
  }

  const size = Object.keys(components as Record<string, unknown>).length;
  if (size === 0) {
    return fail(
      `레지스트리가 비어 있음: ${REGISTRY_DATA}`,
      '분모가 0 이면 어떤 하한도 0 이 되어, 아무것도 읽지 않은 스윕이 통과한다',
      '생성기를 다시 돌려 컴포넌트 데이터를 채워라',
    );
  }
  return size;
}

/**
 * 봉투를 검증한다. 느슨하게 받아 넘기면 잘못된 파일이 "미스 0" 으로 렌더되어
 * 통과 신호를 준다 — 이 스크립트가 막아야 할 실패가 정확히 그것이다.
 */
function validate(raw: unknown, path: string): FidelityEnvelope {
  if (typeof raw !== 'object' || raw === null) {
    fail(
      `봉투가 객체가 아님: ${path}`,
      '형태를 확인하지 않고 렌더하면 잘못된 파일이 깨끗한 통과로 보인다',
      '플러그인에서 내려받은 fidelity JSON 이 맞는지 확인하라',
    );
  }
  const env = raw as Record<string, unknown>;

  if (env.kind !== ENVELOPE_KIND) {
    fail(
      `kind 가 "${ENVELOPE_KIND}" 가 아님: ${String(env.kind)} (${path})`,
      '다른 도구의 JSON 을 fidelity 리포트로 읽으면 결과가 무의미하다',
      '플러그인 fidelity 탭에서 내려받은 파일을 넣어라',
    );
  }
  if (env.schema !== ENVELOPE_SCHEMA) {
    fail(
      `schema 가 ${ENVELOPE_SCHEMA} 이 아님: ${String(env.schema)} (${path})`,
      '스키마가 다르면 필드 의미가 달라져 조용히 잘못 읽는다',
      '플러그인을 최신 빌드로 다시 실행해 리포트를 새로 받아라',
    );
  }

  const report = env.report;
  if (typeof report !== 'object' || report === null) {
    fail(
      `report 가 없음: ${path}`,
      '리포트 본문 없이 봉투만 있으면 검사한 것이 없다',
      '플러그인 실행이 끝까지 돌았는지 확인하라',
    );
  }
  const rep = report as Record<string, unknown>;

  // "수가 아님" 이 아니라 "셈이 아님" 을 본다. 음수 · 소수 · 무한대는 typeof 검사를
  // 통과한 뒤 아래 0 게이트까지 통과해서, 아무 근거 없는 ✅ 를 종료 코드 0 과 함께
  // 내보낸다 — 그 게이트가 막으려던 결과가 정확히 그것이다. 이 두 수는 0 에서
  // 시작해 누적되므로 셈이 아닌 값은 계수기가 깨졌다는 뜻이고, 계수기가 깨졌으면
  // 그 위에 얹힌 "미스 0" 도 근거가 없다.
  if (!isCount(rep.componentsRead) || !isCount(rep.checksRun)) {
    fail(
      `componentsRead / checksRun 이 셈이 아님: ${path}`,
      '무엇을 얼마나 검사했는지 모르면 "미스 0" 을 신뢰할 근거가 없다',
      '플러그인 리포트 생성 경로를 확인하라',
    );
  }

  // 아무것도 검사하지 않은 스윕은 깨끗한 통과로 렌더되면 안 된다.
  // 이 레포가 가드마다 모집단 하한을 두는 이유와 같다 — 0 건 검사와 0 건 결함은
  // 출력이 같고, 그 둘을 섞으면 통과 신호가 무의미해진다.
  //
  // 두 계수기를 **함께** 본다. 같은 스윕의 두 계수기라 한쪽만 막으면 다른 쪽으로
  // 같은 값 없는 초록이 그대로 나간다 — 읽은 컴포넌트가 0 이면 "미스 0" 을 떠받칠
  // 모집단이 아예 없고, 그 리포트는 "컴포넌트 0개에서 검사 N건" 이라는 앞뒤가
  // 맞지 않는 문장으로 렌더된다.
  const zeroed: string[] = [];
  if (rep.componentsRead === 0) zeroed.push('componentsRead');
  if (rep.checksRun === 0) zeroed.push('checksRun');
  if (zeroed.length > 0) {
    fail(
      `${zeroed.join(' · ')} 이 0 — 검사할 모집단이 없거나 아무 검사도 실행되지 않음: ${path}`,
      '검사 0 건과 결함 0 건은 출력이 같다 — 이걸 통과로 렌더하면 아무 근거 없는 초록이 된다',
      'entryFilter 가 아무것도 매칭하지 않았을 수 있다. 필터를 비우고 전체 스윕으로 다시 실행하라',
    );
  }

  const misses = rep.misses;
  if (!Array.isArray(misses)) {
    fail(
      `misses 가 배열이 아님: ${path}`,
      '결함 목록을 읽을 수 없으면 통과 여부를 판정할 수 없다',
      '리포트 JSON 을 직접 열어 misses 필드를 확인하라',
    );
  }

  // 배열이라는 것만 보고 원소를 안 보면, 원소 모양 검사는 렌더가 우연히 하게 된다.
  // 객체가 아닌 원소는 다섯 필드를 실을 수 없어 **셀이 전부 빈 행**으로 렌더되고,
  // 그 행은 값이 실제로 비어 있던 진짜 불일치와 글자 그대로 구별되지 않는다.
  // `unchecked` 원소를 문자열로 강제하는 것과 같은 급의 규칙이다 — 주장을 실어
  // 나르는 배열의 원소는 그 주장을 실을 수 있는 모양이어야 한다.
  if (!misses.every(isMissShaped)) {
    fail(
      `misses 에 미스 모양이 아닌 원소가 있음: ${path}`,
      `객체가 아니거나 ${MISS_KEYS.join(' · ')} 중 하나도 갖지 않은 원소는 셀이 전부 빈 행으로 렌더되어, 값이 비어 있던 진짜 불일치와 구별되지 않는다`,
      '리포트 JSON 의 report.misses 를 열어보고 플러그인을 최신 빌드로 다시 실행해 리포트를 새로 받아라',
    );
  }

  // `unchecked` 는 misses 와 같은 급이다 — 둘 다 리포트의 주장을 떠받치는 배열이라
  // 모양이 틀리면 강등하지 않고 거부한다. 문자열 아닌 원소를 걸러내면 빈 배열이
  // 남고, 빈 unchecked 는 "읽은 값이 모두 비교됐다" 는 **적극적 주장**으로 렌더된다.
  // 비교되지 않은 항목 둘이 "비교 안 된 것 없음" 이 되는 것이라, 부분 검사가 전수
  // 검사로 뒤집힌다 — 이 채널이 존재하는 이유가 정확히 그 뒤집힘을 막는 것이다.
  //
  // 경고를 달고 강등해 렌더하는 선택지는 자동화에 닿지 않아서 버렸다. 크론이 읽는
  // 것은 종료 코드뿐이고, 본문에만 있는 경고는 통과와 구별되지 않는다. 강등된 원소
  // 자체도 정보가 아니다 — 객체를 문자열로 만들면 `[object Object]` 이거나, 더
  // 나쁘게는 제대로 보고된 항목과 구별되지 않는 그럴듯한 문자열이 된다.
  // `hostDerived` 는 이 절이 생기기 전 리포트에는 없다 — 없음은 "호스트 파생
  // 필드 0개" 와 같은 뜻이라 빈 목록으로 읽는다(모양이 있는데 틀린 것만 거부).
  const hostDerived = rep.hostDerived ?? [];
  if (!isStringArray(hostDerived)) {
    fail(
      `hostDerived 가 문자열 배열이 아님: ${path}`,
      '모양이 틀린 목록을 걸러내면 빈 배열이 남고, 그것은 "호스트 파생 없음" 이라는 주장으로 렌더된다',
      '리포트 JSON 의 report.hostDerived 를 열어보고 플러그인을 최신 빌드로 다시 실행해 리포트를 새로 받아라',
    );
  }
  const unchecked = rep.unchecked;
  if (!isStringArray(unchecked)) {
    fail(
      `unchecked 가 문자열 배열이 아님: ${path}`,
      '모양이 틀린 목록을 걸러내면 빈 배열이 남고, 그것은 "비교 안 된 것 없음" 이라는 주장으로 렌더된다',
      '리포트 JSON 의 report.unchecked 를 열어보고 플러그인을 최신 빌드로 다시 실행해 리포트를 새로 받아라',
    );
  }

  // `strokeUnstated` 는 hostDerived 와 같은 급이다 — 없는 것은 "진술 없어 비교
  // 못 한 마크 획 0개" 와 같은 뜻이라 빈 목록으로 읽는다.
  const strokeUnstated = rep.strokeUnstated ?? [];
  if (!isStringArray(strokeUnstated)) {
    fail(
      `strokeUnstated 가 문자열 배열이 아님: ${path}`,
      '모양이 틀린 목록을 걸러내면 빈 배열이 남고, 그것은 "진술 없어 비교 못 한 마크 획 없음" 이라는 주장으로 렌더된다',
      '리포트 JSON 의 report.strokeUnstated 를 열어보고 플러그인을 최신 빌드로 다시 실행해 리포트를 새로 받아라',
    );
  }
  // `notes` 도 같은 급이다 — 모양이 틀린 원소를 강등하지 않고 거부한다. 강등해서
  // 빈 배열로 만들면 "알아둘 관찰 없음" 이라는 주장이 되고, 그건 misses 와 같은
  // 이유로 자동화에 닿지 않는다.
  const notes = rep.notes ?? [];
  if (!Array.isArray(notes) || !notes.every(isNoteShaped)) {
    fail(
      `notes 에 note 모양이 아닌 원소가 있음: ${path}`,
      `객체가 아니거나 ${NOTE_KEYS.join(' · ')} 중 하나도 갖지 않은 원소는 셀이 전부 빈 행으로 렌더되어, 진짜 관찰과 구별되지 않는다`,
      '리포트 JSON 의 report.notes 를 열어보고 플러그인을 최신 빌드로 다시 실행해 리포트를 새로 받아라',
    );
  }

  // entryFilter 에서 `null` 은 "전체 레지스트리를 훑었다" 는 뜻이다. 그래서 다른
  // 모양을 null 로 강등하면 부분 스윕이 전수 스윕으로 렌더된다 — 리포트 상단의
  // "필터 밖 컴포넌트에 대해서는 아무 주장도 하지 않는다" 배너가 사라지고, 그 순간
  // 리포트는 자기가 확인하지 않은 범위까지 확인했다고 말하게 된다. 값이 없는 것도
  // 거부한다: 없는 필드를 "필터 없음" 으로 읽는 것 역시 확인하지 않은 사실을
  // 유리한 쪽으로 추정하는 것이다.
  const entryFilter = env.entryFilter;
  if (entryFilter !== null && typeof entryFilter !== 'string') {
    fail(
      `entryFilter 가 문자열도 null 도 아님: ${String(entryFilter)} (${path})`,
      'null 은 전체 스윕을 뜻한다 — 다른 모양을 null 로 읽으면 부분 스윕이 전수 스윕으로 보고된다',
      '리포트 JSON 의 entryFilter 를 확인하고 플러그인을 최신 빌드로 다시 실행하라',
    );
  }

  // 전체 스윕(entryFilter === null)이 레지스트리의 얼마를 실제로 읽었는지.
  //
  // 여기까지의 게이트는 "0 이 아니다" 까지만 본다. 그런데 145개를 훑겠다고 선언한
  // 스윕이 1개를 읽고 끝나면 그것도 0 이 아니라서 통과하고, 렌더는 "✅ 불일치 없음 —
  // 컴포넌트 1개에서 검사 1건" 을 종료 코드 0 과 함께 내놓는다. 자동화는 그 0 을
  // 보고 **이슈를 만들지 않으므로**, 붕괴한 스윕은 사람 눈에 닿는 흔적을 하나도
  // 남기지 않는다 — 깨끗한 주기와 완전히 같은 모양이다.
  //
  // 필터가 걸린 스윕은 이 하한의 대상이 아니다. 좁은 것이 그 실행의 목적이라
  // 같은 잣대를 대면 정상 실행을 실패로 만든다. 봉투가 `entryFilter` 를 싣는 이유가
  // 정확히 이 구분이고, 필터가 좁힌 범위는 리포트 상단 배너가 따로 밝힌다.
  let registrySize: number | null = null;
  if (entryFilter === null) {
    registrySize = registryComponentCount();
    const floor = Math.ceil(registrySize * FULL_SWEEP_FLOOR_RATIO);
    if (rep.componentsRead < floor) {
      fail(
        `전체 스윕인데 컴포넌트를 ${rep.componentsRead}개만 읽음 — 레지스트리 ${registrySize}개 중 최소 ${floor}개는 읽어야 한다: ${path}`,
        '모집단이 무너진 스윕의 "미스 0" 은 깨끗한 스윕의 "미스 0" 과 출력이 같고, 이 채널의 0 은 자동화가 이슈를 만들지 않는 쪽이라 그대로 두면 아무 흔적도 남지 않는다',
        '플러그인이 레지스트리를 끝까지 돌았는지 확인하라. 일부만 볼 의도였다면 entryFilter 를 걸고 다시 내보내라 — 필터가 걸린 리포트는 좁은 것이 정상이라 이 하한을 적용하지 않는다',
      );
    }
  }

  // 봉투에는 `report.log` 도 실려 오지만 여기서 읽지 않으므로 들고 다니지도 않는다.
  // 읽히지 않는 필드를 타입에 남겨두면 다음 사람이 그 값이 어딘가 쓰인다고 읽는다.
  return {
    schema: ENVELOPE_SCHEMA,
    kind: ENVELOPE_KIND,
    // 이 둘의 강등은 안전한 방향이다 — `(미상)` 은 모르는 것을 모른다고 적을 뿐
    // 어떤 검사 결과도 주장하지 않는다.
    generatedAt: typeof env.generatedAt === 'string' ? env.generatedAt : '(미상)',
    buildHash: typeof env.buildHash === 'string' ? env.buildHash : '(미상)',
    entryFilter,
    registrySize,
    report: {
      misses,
      componentsRead: rep.componentsRead,
      checksRun: rep.checksRun,
      unchecked,
      hostDerived,
      strokeUnstated,
      notes,
    },
  };
}

/**
 * 셀에 실을 값은 **검증되지 않은 타입**이라(미스 필드는 `unknown`) 문자열로 만든
 * 뒤 공통 이스케이프에 넘긴다. 이스케이프 자체를 여기서 다시 적지 않는 이유:
 * 한 채널이 줄바꿈을 지우고 다른 채널이 안 지운 상태가 실제로 있었고, 그 차이는
 * 두 리포트를 나란히 놓기 전에는 보이지 않았다.
 */
function cell(s: unknown): string {
  return escapeCell(String(s ?? ''));
}

/**
 * 표를 **행 상한과 바이트 예산 둘 다**에서 잘라내고, 넘치면 몇 행을 감췄는지 말한다.
 *
 * 행만 세면 상한을 지키는지가 내용의 폭에 달리게 된다 — 폭은 다음에 누가 더 긴
 * 값을 쓰는 순간 바뀌고, 그때 이 표는 자기가 지키기로 한 것을 지키지 못하면서
 * 지켰다고 말한다. 잘림 문구가 앉을 자리는 **미리 뗀다**: 예산이 바닥난 뒤에 쓰려
 * 하면 그 문장부터 사라져 조용한 잘림이 되고, 아무 데서도 떼지 않으면 이 함수가
 * 돌려주는 문자열이 예산을 넘어 호출자가 한 절의 크기를 계산할 수 없게 된다.
 */
function table(header: string[], rows: string[][], limit: number, budgetBytes: number): string {
  const head = [
    `| ${header.join(' | ')} |`,
    `| ${header.map(() => '---').join(' | ')} |`,
  ];
  const lines = [...head];
  let left =
    budgetBytes - truncationNoticeReserve(rows.length) - utf8Bytes(head.join('\n'));
  let shown = 0;

  for (const r of rows.slice(0, limit)) {
    const line = `| ${r.join(' | ')} |`;
    const cost = utf8Bytes(line) + 1;
    if (cost > left) break;
    left -= cost;
    lines.push(line);
    shown += 1;
  }

  if (rows.length > shown) {
    lines.push('');
    lines.push(truncationNotice(shown, rows.length));
  }
  return lines.join('\n');
}

/**
 * 이 채널의 시각은 디자이너가 **한 번** 돌린 시점이고, 그 산출물은 `incoming/` 에
 * 누적된다. 새 리포트가 들어오지 않으면 같은 파일이 매 주기 다시 렌더되므로,
 * 시각을 말하지 않으면 반년 전의 ✅ 가 이번 주기의 답으로 읽힌다 — 리포트가 아예
 * 없을 때 "부재가 얼마나 오래됐는지" 를 반드시 적는 것과 같은 이유다.
 *
 * `stale` 이 없는 것은 이 채널에 주기가 없기 때문이다. Channel A 는 매 주기 캡처를
 * 새로 뜨기로 되어 있어 오래된 값 자체가 캡처 실패의 신호지만, 여기서는 디자이너가
 * 언제 돌리는지에 대한 약속이 없어 며칠을 임계로 잡아도 그 수를 떠받칠 근거가 없다.
 */
const FIDELITY_AGE = { label: '리포트 생성 시각', stale: null } as const;

function render(env: FidelityEnvelope, source: Source): string {
  const { misses, unchecked, componentsRead, checksRun } = env.report;
  const hostDerived = env.report.hostDerived ?? [];
  const strokeUnstated = env.report.strokeUnstated ?? [];
  const notes = env.report.notes ?? [];

  // 리포트를 세 덩이로 나눈다 — Channel A 와 같은 규율이다.
  //
  // - `head`  이 리포트가 **무엇에 대한 주장인지** 좁히는 문장들. 잘리지 않는다.
  // - `evidence`  발견의 **증거**인 표들. 남는 예산 안에서만 실린다.
  // - `tail`  비교하지 않은 항목 · 다음 행동 · 꼬리말. 잘리지 않는다.
  //
  // 왜 이 순서로 나누는가: 예산이 모자랄 때 무엇을 버릴지가 곧 이 리포트가 무엇을
  // 위해 존재하는지에 대한 답이다. 증거의 일부를 잃는 것은 회복 가능하다 — 머리말의
  // 건수가 남아 있고 디자이너가 다시 돌릴 수 있다. 반면 범위를 좁히는 문장을 잃으면
  // 남은 표가 **전부인 것처럼** 읽히고, 그 오독은 리포트 안에서 고칠 수 없다.
  //
  // 세 덩이를 **먼저 다 만든 뒤** 예산을 정하는 것이 이 구조의 요점이다. 증거를
  // 먼저 쓰면 잘리지 않는 산문의 크기를 추정해야 하고, 추정은 낮잡는다.

  // 전체 스윕이면 분모를 함께 적는다. "컴포넌트 145개" 는 그 스윕이 무엇을 덮었는지
  // 말하지 않지만 "145개 중 145개" 는 말한다 — 하한을 간신히 넘긴 실행도 그 사실이
  // 문장에 남아야 읽는 사람이 ✅ 의 범위를 알 수 있다.
  const read =
    env.registrySize === null
      ? `컴포넌트 ${componentsRead}개`
      : `레지스트리 ${env.registrySize}개 중 컴포넌트 ${componentsRead}개`;

  // 컴포넌트별로 묶어 보여준다 — 한 컴포넌트가 여러 필드에서 어긋나는 일이
  // 흔하고, 그때 원인은 대체로 하나다. 머리말의 귀속 배너와 예산 계산이 둘 다 이
  // 결과를 읽으므로 여기서 한 번만 만든다.
  const byComponent = new Map<string, RawMiss[]>();
  for (const m of misses) {
    const key =
      typeof m.component === 'string' && m.component.trim() !== ''
        ? m.component
        : '(미상)';
    const bucket = byComponent.get(key);
    if (bucket === undefined) byComponent.set(key, [m]);
    else bucket.push(m);
  }

  // ── head — 잘리지 않는다 ────────────────────────────────────────────────────
  const head: string[] = [];
  head.push('# Figma 시각 충실도 리포트 (Channel B)');
  head.push('');
  head.push(
    misses.length === 0
      ? `✅ 불일치 없음 — ${read}에서 검사 ${checksRun}건.`
      : `⚠️ ${misses.length}건 불일치 — ${read}에서 검사 ${checksRun}건.`,
  );
  head.push('');
  head.push(
    '> 이 리포트는 디자이너가 Figma 데스크톱에서 플러그인을 돌려 만든 것이다. ' +
      '색 · 토큰 바인딩 · 타이포 · radius · shadow 처럼 헤드리스로 읽을 수 없는 축을 ' +
      '여기서 답한다 — Channel A(구조 diff)가 조용해도 이 채널은 따로 봐야 한다.',
  );
  head.push('');

  // 범위를 좁히는 사실은 전부 여기, 본문 안에 있다. 자동화가 사람에게 건네는
  // 것은 이 문서뿐이라 stderr 로 한 말은 아무에게도 닿지 않는다.
  if (source.total > 1) {
    head.push(
      `⚠️ 드롭 디렉터리에 리포트가 ${source.total}개 있고 그중 파일명 사전순 마지막인 ` +
        `\`${brief(source.chosen)}\` **하나만** 읽었다 — 나머지 ${source.total - 1}개는 읽지 않았다. ` +
        '읽지 않은 리포트에 대해서는 아무 주장도 하지 않는다.',
    );
    head.push('');
  }

  if (env.entryFilter !== null) {
    head.push(
      `⚠️ 이 실행은 \`${brief(env.entryFilter)}\` 로 **필터링된 부분 스윕** 이다 — ` +
        '필터 밖 컴포넌트에 대해서는 아무 주장도 하지 않는다.',
    );
    head.push('');
  }

  head.push(ageNote(env.generatedAt, FIDELITY_AGE));
  head.push('');

  if (misses.length > 0) {
    head.push('## 불일치');
    head.push('');

    // 어느 컴포넌트의 것인지 적히지 않은 행은 보이기는 해도 고칠 곳을 알려주지
    // 않는다. 세어서 말하지 않으면 `(미상)` 묶음이 실재하는 컴포넌트 이름처럼 읽힌다.
    const unattributed = misses.filter(
      (m) => typeof m.component !== 'string' || m.component.trim() === '',
    ).length;
    if (unattributed > 0) {
      head.push(
        `⚠️ 이 중 ${unattributed}건은 어느 컴포넌트의 것인지 적혀 있지 않아 \`(미상)\` 으로 묶었다 — ` +
          '행은 보이지만 어디를 고쳐야 하는지는 이 리포트로 알 수 없다.',
      );
      head.push('');
    }
  }

  // ── tail — 잘리지 않는다 ────────────────────────────────────────────────────
  const tail: string[] = [];

  // 검사되지 않은 항목은 "이상 없음" 이 아니다. 이 구분을 흐리면 부분 검사가
  // 전수 검사처럼 읽힌다.
  tail.push(`## 비교하지 않은 항목 (${unchecked.length})`);
  tail.push('');
  if (unchecked.length === 0) {
    tail.push('_없음 — 읽은 값이 모두 비교됐다._');
  } else {
    tail.push('아래는 **비교되지 않았다**. 통과가 아니라 정보가 없는 상태다.');
    tail.push('');
    // 목록도 표로 낸다 — 상한과 잘림 문장을 불일치 표와 같은 것으로 쓰기 위해서다.
    tail.push(
      table(['항목'], unchecked.map((u) => [cell(u)]), MAX_TABLE_ROWS, UNCHECKED_SECTION_BYTES),
    );
  }
  tail.push('');

  // 호스트 파생 필드는 "비교하지 않은 항목" 과 다르다 — 저쪽은 검사가 아직 못 읽는
  // 자리(갭)이고, 여기는 어떤 값도 단언할 수 없는 자리(설계)다. 같은 표에 넣으면
  // 갭의 ratchet 이 설계를 세고, 그 수는 영원히 0 으로 돌아가지 못한다.
  if (hostDerived.length > 0) {
    tail.push(`## 호스트 파생 — 비교 대상 아님 (${hostDerived.length})`);
    tail.push('');
    tail.push(
      '아래 필드는 값이 호스트에서 렌더 시점에 들어온다(`@hostDerived`). 캔버스 데모는 데모 호스트의 값을 보여줄 뿐이라 단언할 것이 없다.',
    );
    tail.push('');
    tail.push(
      table(['항목'], hostDerived.map((h) => [cell(h)]), MAX_TABLE_ROWS, UNCHECKED_SECTION_BYTES),
    );
    tail.push('');
  }

  // `strokeUnstated`/`notes` 는 hostDerived 와 같은 급 — 불일치도 갭도 아니라서
  // `unchecked` ratchet 에 넣지 않는다. 넣으면 151개짜리 영구 항목이 그 ratchet 을
  // 영원히 0 에서 떼어놓는다. 대신 자기 절을 갖는다 — 그래야 152개 중 151개를
  // 비교하지 못한 실행이 "불일치 0" 으로만 읽히지 않는다.
  if (strokeUnstated.length > 0 || notes.length > 0) {
    tail.push(`## 진술 없어 비교 못 한 축 (${strokeUnstated.length + notes.length})`);
    tail.push('');
    tail.push(
      '아래는 불일치도 아니고 이 모듈이 읽지 못하는 갭도 아니다 — 세트가 애초에 ' +
        '값을 진술하지 않았거나(마크 획), 값은 오늘 맞지만 바인딩이 아니라 리터럴이라 ' +
        '역할이 바뀌어도 따라오지 않을 자리(자간)다.',
    );
    tail.push('');
    if (strokeUnstated.length > 0) {
      tail.push(
        `- 마크 획: ${componentsRead}개 중 ${strokeUnstated.length}개가 마크 두께를 ` +
          '진술하지 않아 비교 대상이 아님.',
      );
      tail.push('');
    }
    if (notes.length > 0) {
      tail.push(
        table(
          ['컴포넌트', '필드', '관찰'],
          notes.map((n) => [cell(n.component), cell(n.field), cell(n.detail)]),
          MAX_TABLE_ROWS,
          UNCHECKED_SECTION_BYTES,
        ),
      );
      tail.push('');
    }
  }

  // 리포트가 무엇을 보라고만 하고 무엇을 하라고 말하지 않으면, 읽는 사람이 매번
  // 같은 판단 경로를 처음부터 다시 세운다. Channel A 가 자기 발견에 대해 하는 것과
  // 같은 일이고, 갈래가 다를 뿐 이유는 같다.
  if (misses.length > 0) {
    tail.push('## 이제 무엇을 하나');
    tail.push('');
    tail.push(
      '- **코드가 정본이다** — 캔버스가 흘렀다. 해당 컴포넌트에서 어긋난 값을 다시 토큰에 바인딩한다. ' +
        '`expected` 가 코드가 말하는 값이다.',
    );
    tail.push(
      '- **캔버스가 정본이다** — 디자이너가 먼저 바꿨다. 그 컴포넌트의 `CoreXxxStyle` 기본값을 옮기는 작업을 잡는다. ' +
        '`actual` 이 캔버스가 말하는 값이다.',
    );
    tail.push(
      '- **둘 다 맞고 비교가 틀렸다** — 검사가 비교하면 안 되는 자리를 비교한 것이다. ' +
        '이때 고칠 곳은 캔버스도 코드도 아니라 검사이고, 그 자리는 위 "비교하지 않은 항목" 으로 옮겨져야 한다.',
    );
    tail.push('');
  }

  tail.push('---');
  tail.push('');
  tail.push(
    `읽은 컴포넌트 ${componentsRead}${env.registrySize === null ? '' : ` / ${env.registrySize}`} · ` +
      `실행한 검사 ${checksRun} · ` +
      `buildHash \`${brief(env.buildHash)}\` · 출처 파일 \`${brief(source.chosen)}\``,
  );

  // ── 증거 — 남는 전부 ───────────────────────────────────────────────────────
  //
  // 절 전체가 잘렸다는 문장은 예산 **밖에서** 쓴다. 그 한 문장만이 감춰진 행의
  // 총수를 말하므로, 예산이 바닥났을 때 그것부터 사라지면 잘린 리포트가 완전한
  // 목록으로 읽힌다. 아직 몇 행이 밀릴지 모르는 시점이라 **최악**(전부 감춰졌고
  // 컴포넌트도 전부 못 실었다) 기준으로 자리를 잡는다.
  //
  // 최악 문구가 예산 숫자로 채널 예산을 쓰는 이유: 실제 문구에 들어갈 증거 예산은
  // 이 뺄셈의 **결과**라 아직 없다. 증거 예산은 채널 예산보다 작으므로 자릿수가
  // 더 늘지 않고, 자리를 넉넉히 떼는 쪽만이 안전하다.
  const sectionNotice = (
    budgetBytes: number,
    shown: number,
    dropped: number,
    droppedComponents: number,
  ): string =>
    `_불일치 절이 ${budgetBytes} 바이트에서 잘렸다 — ${shown} 행을 실었고 ` +
    `${dropped} 행이 더 있다 (총 ${misses.length})._` +
    (droppedComponents > 0
      ? ` _그중 컴포넌트 ${droppedComponents}개는 이름조차 싣지 못했다._`
      : '');

  const evidence: string[] = [];
  const notice: string[] = [];

  if (misses.length > 0) {
    const missBytes = evidenceBudget(
      CHANNEL_B_BUDGET_BYTES,
      head,
      tail,
      sectionNotice(
        CHANNEL_B_BUDGET_BYTES,
        misses.length,
        misses.length,
        byComponent.size,
      ),
    );

    // 표 하나의 행 상한과 절 전체의 바이트 예산을 함께 건다. 행 상한만 있으면
    // 시끄러운 컴포넌트 하나가 다른 컴포넌트를 전부 밀어내고, 바이트 예산만 있으면
    // 그 하나가 예산을 다 먹는다 — 어느 쪽이든 읽는 사람은 발견의 일부만 본다.
    //
    // 컴포넌트별 잘림 문구는 예산 **안에서** 쓴다 — 그것까지 밖에 두면 컴포넌트
    // 수만큼 문장이 늘어 절 예산이 상한 노릇을 못 한다. 컴포넌트별 문구가 밀려도
    // 감춰진 것은 없다: 절 전체 문구가 그 행들을 총합에 포함해 센다.
    const budget = budgetOf(missBytes);
    let shownRows = 0;
    let droppedComponents = 0;
    let droppedRows = 0;

    for (const name of [...byComponent.keys()].sort()) {
      const rows = byComponent.get(name) as RawMiss[];
      const tableHead = [
        `### ${cell(name)} (${rows.length})`,
        '',
        '| field | expected | actual | looksLike |',
        '| --- | --- | --- | --- |',
      ];
      if (!spend(budget, evidence, tableHead)) {
        droppedComponents += 1;
        droppedRows += rows.length;
        continue;
      }

      let emitted = 0;
      for (const m of rows.slice(0, MAX_TABLE_ROWS)) {
        const line =
          `| ${cell(m.field)} | ${cell(m.expected)} | ` +
          `${cell(m.actual)} | ${cell(m.looksLike)} |`;
        if (!spend(budget, evidence, [line])) break;
        emitted += 1;
      }
      shownRows += emitted;

      if (rows.length > emitted) {
        spend(budget, evidence, ['', truncationNotice(emitted, rows.length)]);
        droppedRows += rows.length - emitted;
      }
      spend(budget, evidence, ['']);
    }

    if (droppedRows > 0) {
      notice.push(sectionNotice(missBytes, shownRows, droppedRows, droppedComponents));
      notice.push('');
    }
  }

  return [...head, ...evidence, ...notice, ...tail].join('\n');
}

function main(): never {
  if (process.argv.includes('--help') || process.argv.includes('-h')) {
    console.log(
      'Usage: tsx reverse/ingest_fidelity.ts [--dir=reverse/incoming] [--out=<md>]\n' +
        '\n' +
        'Exit: 0 불일치 없음 · 1 불일치 있음 · 2 인프라 실패',
    );
    return process.exit(EXIT_NO_DIFF);
  }

  const cwd = process.cwd();
  const dir = resolve(cwd, argValue('--dir') ?? DEFAULT_DIR);

  if (!existsSync(dir)) {
    fail(
      `디렉터리가 없음: ${dir}`,
      '리포트를 놓을 자리가 없으면 이 채널은 아무것도 말하지 못한다',
      '경로를 확인하거나 --dir 로 지정하라',
    );
  }

  // 존재한다고 디렉터리인 것은 아니다. 파일을 --dir 로 주면 여기서 ENOTDIR 이
  // 던져지는데, 감싸지 않으면 그 예외가 Node 의 종료 코드 1 로 새어 나가
  // 자동화에 "디자이너가 무언가 바꿨다" 로 읽힌다 — 오타 하나가 이슈가 된다.
  let entries: string[];
  try {
    entries = readdirSync(dir);
  } catch (e) {
    return fail(
      `디렉터리를 읽지 못함: ${dir}`,
      `읽기 실패가 종료 코드 1 로 새어 나가면 자동화는 그것을 "변화 있음" 으로 읽는다 (${String(e)})`,
      '--dir 가 파일이 아니라 디렉터리를 가리키는지, 읽기 권한이 있는지 확인하라',
    );
  }

  const files = entries
    .filter((f) => f.startsWith('fidelity-') && f.endsWith('.json'))
    .sort();

  // 침묵은 동의가 아니다 — 리포트가 없으면 "이상 없음" 이 아니라 미실행이다.
  if (files.length === 0) {
    fail(
      `${dir} 에 fidelity-*.json 이 없음`,
      '리포트가 없는 것은 결함이 없다는 뜻이 아니라 아무도 검사하지 않았다는 뜻이다 — 침묵을 통과로 읽으면 안 된다',
      'Figma 데스크톱에서 플러그인 fidelity 를 실행하고 내려받은 JSON 을 이 디렉터리에 넣어라',
    );
  }

  // 여러 개면 가장 마지막(사전순 = 파일명에 타임스탬프가 있을 때 최신)을 쓴다.
  // 그 사실은 리포트 본문에도 실린다 — 여기 stderr 는 사람이 직접 돌릴 때를 위한
  // 것이고, 자동화가 사람에게 건네는 것은 본문뿐이다.
  const chosen = files[files.length - 1];
  const path = resolve(dir, chosen);
  if (files.length > 1) {
    console.error(
      `⚠️  fidelity 리포트가 ${files.length}개 — 가장 마지막 파일 하나만 읽는다: ${chosen}`,
    );
  }

  // 읽기와 파싱을 나눈다 — 읽지 못한 것을 "JSON 이 깨졌다" 로 보고하면 고칠 곳을
  // 잘못 짚는다(권한 문제를 파일 내용 문제로 읽게 된다).
  let text: string;
  try {
    text = readFileSync(path, 'utf8');
  } catch (e) {
    return fail(
      `리포트를 읽지 못함: ${path}`,
      `읽기 실패가 종료 코드 1 로 새어 나가면 자동화는 그것을 "변화 있음" 으로 읽는다 (${String(e)})`,
      '파일 권한을 확인하라. 같은 이름의 디렉터리가 아닌지도 확인하라',
    );
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch (e) {
    return fail(
      `JSON 파싱 실패: ${path}`,
      `깨진 파일을 조용히 건너뛰면 "미스 0" 과 구별되지 않는다 (${String(e)})`,
      '파일을 다시 내려받아라',
    );
  }

  const env = validate(parsed, path);
  const markdown = render(env, { chosen, total: files.length });

  const outPath = argValue('--out');
  if (outPath !== null) {
    const at = resolve(cwd, outPath);
    writeOut(at, `${markdown}\n`, '리포트');
    console.log(`리포트 기록: ${at}`);
  } else {
    console.log(markdown);
  }

  return process.exit(env.report.misses.length > 0 ? EXIT_DIFF : EXIT_NO_DIFF);
}

main();
