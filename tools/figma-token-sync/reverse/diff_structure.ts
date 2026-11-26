// Channel A — 무인 크론이 보는 Figma 구조/기하 드리프트.
//
// 이 differ 가 비교하는 것은 노드의 name · type · 소속 페이지 와
// x/y/width/height, 그리고 **두 캡처가 모두 schema 2 일 때** 컴포넌트 프로퍼티
// 정의와 인스턴스의 원본 참조다(매칭 키는 id). 색·토큰 바인딩·타이포·radius·shadow 는
// **볼 수 없다** — get_variable_defs 와 get_design_context 는 Figma 데스크톱 앱의
// 살아있는 선택(selection)을 요구해서 헤드리스로는 "You currently have nothing
// selected" 로 실패하기 때문이다. 그 축은 Channel B(ingest_fidelity.ts)가
// 담당한다. 여기서 "차이 없음"은 **위에 나열한 축에 대한 진술일 뿐** 이며
// 시각적 동일성을 뜻하지 않는다.
//
// 한 페이지 안에서의 부모 변경(depth 이동)은 비교하지 않는다 — 위에 래퍼 프레임
// 하나를 끼우면 그 아래 전부의 depth 가 밀려서, 한 번의 편집이 수백 행짜리
// 리포트가 된다. 늘 시끄러운 항목은 읽는 사람이 리포트 전체를 건너뛰게 만든다.
//
// 입력은 MCP get_metadata 의 원문 그대로다:
//   <raw-dir>/pages.txt              — nodeId 없이 호출한 결과(페이지 목록)
//   <raw-dir>/page-<id>.xml          — nodeId 를 주고 호출한 결과(속성만 있는 XML)
// 두 출력 모두 XML 이 아닌 산문 문장이 섞여 오므로 파서는 태그가 아닌 텍스트를
// 전부 무시한다. 다만 **태그로 보이는데 읽어낼 수 없는 것**은 무시하지 않고
// 그 자리에서 멈춘다 — 아래 parsePageXml 의 주석 참조.
//
// 매칭은 **id 기준** 이다. Figma node id 는 편집을 넘어 안정적이고 name 은
// 그렇지 않다 — 그래서 rename 이 탐지 가능한 사건이 된다. name 으로 매칭하면
// rename 이 add+remove 한 쌍으로 보여 실제 삭제와 구별되지 않는다.
//
// 입력은 둘 중 하나다:
//   --raw-dir=<dir>     MCP get_metadata 원문(pages.txt + page-<id>.xml) — 위 설명
//   --snapshot=<file>   플러그인 "구조 → .json" 이 내려준 스냅샷(이 스크립트가
//                       읽는 베이스라인과 같은 모양). 193 페이지 · 46,000 노드짜리
//                       파일은 MCP 로 걷을 수 없어(예산 · 컨텍스트) 이쪽이 정본이다.
// 두 경로의 캡처는 `capturedBy` 가 다르고 타입 어휘가 같다는 보장이 없으므로,
// 베이스라인과 다른 경로의 캡처를 비교하려 들면 멈춘다 — 전환은 --update-baseline
// 으로 한 번 한다.
//
// Usage:
//   tsx reverse/diff_structure.ts --raw-dir=reverse/.work/latest
//   tsx reverse/diff_structure.ts --snapshot=reverse/incoming/structure-<stamp>.json
//   tsx reverse/diff_structure.ts --snapshot=... --out=report.md --update-baseline

// `@types/node` 대신 로컬 ambient — scripts/*.ts 가 이미 쓰는 것과 같은 형태다.
// typeRoots 가 `@figma/plugin-typings` 로 고정돼 있어 플러그인 코드가 Node API 에
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

// 두 채널이 같아야 하는 서식·셈은 전부 여기서 온다. 같은 생각을 두 파일에 적으면
// 그 둘은 갈라지고, 그 갈라짐은 두 리포트를 나란히 놓고 봐야만 보인다.
import {
  CAPTURED_BY_PLUGIN,
  READABLE_SNAPSHOT_SCHEMAS,
  SNAPSHOT_SCHEMA,
  SNAPSHOT_SCHEMA_GEOMETRY_ONLY,
  carriesComponentProps,
  carriesMainComponent,
  ownsComponentProps,
  propDisplayName,
  serialiseSnapshot,
} from './snapshot_format';
import type { SnapshotNode, SnapshotProp } from './snapshot_format';
import {
  CHANNEL_A_BUDGET_BYTES,
  MAX_TABLE_ROWS,
  ageNote,
  brief,
  cell,
  evidenceBudget,
  fitToBudget,
  truncationNotice,
} from './report_format';

const { existsSync, readFileSync, writeFileSync, statSync } = require('node:fs') as {
  existsSync(p: string): boolean;
  readFileSync(p: string, enc: string): string;
  writeFileSync(p: string, data: string, enc: string): void;
  statSync(p: string): { mtime: { toISOString(): string } };
};
const { resolve } = require('node:path') as {
  resolve(...parts: string[]): string;
};

// ── 종료 코드 계약 ──────────────────────────────────────────────────────────
// 이 레포의 가드와 같은 규약. 1 과 2 를 절대 섞지 않는다 — 자동화는 2 를
// "파이프라인이 깨졌다", 1 을 "디자이너가 무언가 바꿨다" 로 읽는다.
const EXIT_NO_DIFF = 0;
const EXIT_DIFF = 1;
const EXIT_INFRA = 2;

// components.json 과 대조할 때 "컴포넌트 루트일 법한" 깊이의 상한.
// 캔버스(depth 0) 바로 아래 한두 겹까지만 본다 — 더 깊이 들어가면 컴포넌트의
// 내부 파트 이름이 전부 미지의 이름으로 잡혀 신호가 소음에 묻힌다.
const COMPONENT_ROOT_MAX_DEPTH = 2;

// 설정 파일의 형태 버전. 스냅샷의 형태 버전은 쓰는 쪽(플러그인)과 **같은 상수**를
// `snapshot_format.ts` 에서 가져온다 — 리터럴을 두 자리에 적으면 한쪽만 올라가고,
// 그러면 이 필드가 지키기로 한 것(디스크의 모양이 코드의 기대와 같다)을 더 이상
// 지키지 못한다.
const CONFIG_SCHEMA = 1;

// geometryEpsilonPx 의 상한. epsilon 은 좌표에 섞인 부동소수 잡음을 흡수하라고
// 있는 값이라, 디자인이 의미를 두는 최소 간격(한 스페이싱 단위)을 넘어서면
// 그건 잡음 흡수가 아니라 변화 은폐다. 실측: 10000 을 넣으면 노드가 5000px
// 이동하고 200×120 이 9999×9999 로 바뀐 캡처가 "✅ 변화 없음 · 종료 코드 0" 으로
// 나간다. 값이 빠졌을 때와 증상이 같으므로 같은 엄격함으로 막는다.
const MAX_GEOMETRY_EPSILON_PX = 8;

// populationFloorRatio 의 하한. 0 은 하한을 끄고, 0 에 가까운 값은 끈 것과
// 구별되지 않는다 — 이 하한이 막으려는 실패가 정확히 "대부분이 사라진 캡처"
// 이기 때문이다. 실측: 0 을 넣으면 200 노드가 2 노드로 붕괴한 캡처가 198 건의
// 거짓 삭제 리포트로 나간다.
const MIN_POPULATION_FLOOR_RATIO = 0.1;

const DEFAULT_RAW_DIR = 'reverse/.work/latest';
const DEFAULT_BASELINE = 'reverse/baseline.structure.json';
const DEFAULT_CONFIG = 'reverse/config.json';
const CODE_COMPONENTS = 'src/data/components.json';

// 파일 키가 정본임을 사람이 확인했다는 표시. 이 값이 아니면 걷지 않는다.
const FILE_KEY_CONFIRMED = 'confirmed';

/**
 * Figma 파일 URL 에서 파일 키가 앉는 자리.
 *
 * 키를 `[A-Za-z0-9]+` 로 좁히지 않고 경로 조각 통째(`[^/?#]+`)로 잡는다 — 좁히면
 * 키에 없는 문자가 나올 때 조각의 **앞부분만** 잡히고, 그러면 아래 대조가 실제
 * 불일치가 아닌 자기 정규식의 한계 때문에 실패한다. 여기서 알아야 하는 것은
 * "그 자리에 무엇이 적혀 있나" 뿐이다.
 */
const FIGMA_FILE_URL = /figma\.com\/(?:file|design|board|deck|slides|proto)\/([^/?#]+)/;

/** 스냅샷의 노드 한 줄. 쓰는 쪽과 같은 타입이라 필드가 갈라질 수 없다. */
type RawNode = SnapshotNode;

interface PageSnapshot {
  id: string;
  name: string;
  nodes: RawNode[];
}

interface Snapshot {
  /**
   * 이 파일의 형태 버전. **읽을 때 검증한다** — 검증하지 않는 버전 필드는 보장이
   * 아니라 장식이고, 장식은 다음 사람이 보장으로 읽는다.
   */
  schema: number;
  fileKey: string | null;
  /**
   * 이 캡처가 언제 떠졌는가. 판정에는 쓰이지 않지만 **리포트가 사람에게 말한다** —
   * 크론이 캡처 갱신에 실패하고 지난 캡처를 다시 비교하면 결과는 "변화 없음"
   * 이고, 그 문장만으로는 이번 주기의 답인지 지난달의 답인지 구별되지 않는다.
   * 바로 위 `schema` 와는 여전히 취급이 다르다: `schema` 는 파일의 모양에 대한
   * **약속**이라 어긋나면 아래 코드 전부가 틀린 가정 위에서 돌지만, 이것은
   * 약속이 아니라 기록이라 어긋나도 판정을 무너뜨리지 않는다.
   */
  capturedAt: string | null;
  capturedBy: string;
  nodeCount: number;
  pages: PageSnapshot[];
}

/** 검증을 통과한 설정. 여기 있는 값은 전부 읽히며, 읽히는 값은 전부 검증된다. */
interface Config {
  fileKey: string;
  fileKeyStatus: string;
  fileUrl: string;
  pages: string[] | null;
  geometryEpsilonPx: number;
  populationFloorRatio: number;
}

/** 페이지 목록의 한 줄. 걷지 않은 페이지도 이 모양으로 들고 다닌다. */
interface PageRef {
  id: string;
  name: string;
}

/**
 * 한 번의 캡처가 만든 것 전부 — 스냅샷과 **그 스냅샷이 무엇을 안 봤는지**.
 *
 * 걷지 않은 페이지를 여기 같이 들고 다니지 않으면 그 사실이 호출자에게 도달할
 * 길이 없고, 그러면 "안 걸었다" 와 "사라졌다" 가 리포트에서 같은 칸에 담긴다.
 */
interface Capture {
  snapshot: Snapshot;
  /** pages.txt 가 나열한 **파일 전체**의 페이지. 걷지 않은 것도 들어 있다. */
  inFile: PageRef[];
  /** `config.pages` 로 **일부러 걷지 않은** 페이지. 파일에서 사라진 것과 다르다. */
  outOfScope: PageRef[];
}

/** 노드와 **그 노드가 있던 페이지**. 리포트의 한 행은 이것 하나로 특정된다. */
interface Located {
  node: RawNode;
  pageId: string;
  pageName: string;
}

/** 두 스냅샷 사이에서 관찰된 변화. 한 노드가 여러 항목에 동시에 등장할 수 있다. */
interface Change {
  at: Located;
  before: string;
  after: string;
}

interface StructureDiff {
  added: Located[];
  removed: Located[];
  renamed: Change[];
  retyped: Change[];
  repaged: Change[];
  moved: Change[];
  resized: Change[];
  /**
   * 베이스라인에는 있는데 **이번에 걷지 않은 페이지**에 있던 노드.
   *
   * 삭제와 절대 같은 칸에 담지 않는다. 범위를 좁히면 그 밖의 노드는 전부
   * `after` 에서 사라지는데, 그것을 삭제로 세면 범위를 좁히는 행위 자체가
   * 대량 삭제 리포트를 지어낸다 — 모집단 하한이 막으려는 바로 그 거짓 신호를
   * 하한이 발동하지 않는 크기로 만들어내는 셈이다.
   */
  notCompared: Located[];
  /**
   * 한쪽에 기하 속성이 없어 delta 를 주장할 수 없었던 노드 수.
   * 페이지 루트는 제외한다 — 캔버스에는 x/y 가 애초에 없어서, 세면 이 수가
   * 페이지 수 아래로 절대 내려가지 않는다. 늘 0 이 아닌 카운터는 읽는 사람이
   * 요약 전체를 무시하게 만든다.
   */
  geometryNotComparable: number;
  /**
   * 컴포넌트 프로퍼티 정의의 변화. 기하가 그대로인 편집(세트에 BOOLEAN 하나를
   * 더한 것)은 위 어느 칸에도 나타나지 않아서, 이 칸이 없으면 그 편집은 "변화 없음"
   * 으로 나간다. `propsCompared` 가 거짓이면 이 칸들은 **세지 않은 것**이다.
   */
  propAdded: PropChange[];
  propRemoved: PropChange[];
  propRetyped: PropChange[];
  propDefaultChanged: PropChange[];
  propOptionsChanged: PropChange[];
  /** 인스턴스가 가리키는 원본 컴포넌트가 바뀐 것. */
  mainChanged: Change[];
  /**
   * 소유 노드인데 한쪽이라도 정의를 읽지 못해(`null`) 비교를 주장하지 않은 수.
   * 기하의 "비교 불가" 와 같은 이유로 세어서 말한다.
   */
  propsNotComparable: number;
  /** 인스턴스인데 한쪽이라도 원본을 해석하지 못해(`null`) 비교를 주장하지 않은 수. */
  mainNotComparable: number;
  /** 두 캡처가 모두 프로퍼티를 싣고 있어 위 칸들을 실제로 셌는가. 아니면 그 이유. */
  propsCompared: { ran: true } | { ran: false; why: string };
}

/** 프로퍼티 하나의 변화. 한 컴포넌트가 여러 행을 만들 수 있다. */
interface PropChange {
  at: Located;
  /** 비교에 쓴 이름 — `#<id>` 접미사를 접은 표시 이름. */
  prop: string;
  before: string;
  after: string;
}

function fail(what: string, why: string, doThis: string): never {
  // 이 레포 가드의 3단 실패 문구 — 무엇이 틀렸나 / 왜 위험한가 / 무엇을 하라.
  console.error(`❌ ${what}`);
  console.error(`   왜: ${why}`);
  console.error(`   무엇을: ${doThis}`);
  return process.exit(EXIT_INFRA);
}

function argValue(flag: string): string | null {
  const hit = process.argv.find((a) => a.startsWith(`${flag}=`));
  return hit === undefined ? null : hit.slice(flag.length + 1);
}

function hasFlag(flag: string): boolean {
  return process.argv.includes(flag);
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

/**
 * Figma node id(`12:47649`)를 파일명에 쓸 수 있는 형태로 바꾼다. 캡처 스크립트와
 * 이 파서가 **같은** 규칙을 써야 파일을 찾을 수 있으므로 규칙을 여기 한 곳에 둔다.
 */
function sanitiseNodeId(id: string): string {
  return id.replace(/[^A-Za-z0-9]+/g, '-');
}

/**
 * `- <id>: <name>` 형태의 줄만 페이지로 읽고 나머지는 버린다.
 * get_metadata 는 목록 앞뒤로 산문 헤더를 붙이므로 관대한 파싱이 필수다.
 */
function parsePagesTxt(text: string): { id: string; name: string }[] {
  const out: { id: string; name: string }[] = [];
  const seen = new Set<string>();
  for (const line of text.split('\n')) {
    const m = /^-\s*(\S+):\s*(.+)$/.exec(line.trim());
    if (m === null) continue;
    const id = m[1];
    const name = m[2].trim();
    // 같은 id 가 두 번 나오면 첫 번째만 — 중복은 페이지 수를 부풀려
    // 모집단 하한 판정을 무디게 만든다.
    if (seen.has(id)) continue;
    seen.add(id);
    out.push({ id, name });
  }
  return out;
}

/** 속성값의 XML 엔티티를 되돌린다. get_metadata 는 name 에 `&` 를 실어 보낸다. */
function decodeEntities(raw: string): string {
  return raw
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, '&');
}

/**
 * 속성이 있으면 유한한 수로, 없거나 수로 읽히지 않으면 `null`.
 *
 * `null` 과 `0` 을 구분하는 이유: 없는 값과 0 은 서로 다른 주장이다. 없는 값을
 * 0 으로 접으면 속성이 사라진 노드가 "원점으로 이동" 한 것처럼 보고된다.
 *
 * 빈 문자열과 공백을 먼저 걸러내는 이유도 같다 — `Number('')` 과 `Number(' ')`
 * 은 **0 이고 유한하다**. 그대로 두면 `x=""` 인 노드가 원점 이동으로,
 * `width=""` 인 노드가 0 폭으로 축소된 것으로 보고된다.
 */
function numAttr(attrs: Record<string, string>, key: string): number | null {
  const raw = attrs[key];
  if (raw === undefined) return null;
  if (raw.trim() === '') return null;
  const n = Number(raw);
  return Number.isFinite(n) ? n : null;
}

/** 한 페이지 XML 을 읽은 결과. 실패는 값으로 돌려 호출자가 맥락을 붙이게 한다. */
interface PageParse {
  nodes: RawNode[];
  /** 이 응답에서 처음 열린 태그의 이름. 태그를 하나도 못 봤으면 `null`. */
  rootTag: string | null;
  /** 그 루트를 닫는 태그를 실제로 보았는가. */
  rootClosed: boolean;
  /** 태그로 보이는데 읽어내지 못한 자리. 있으면 그 자리에서 멈춰야 한다. */
  malformed: string | null;
}

const NAME_START = /[A-Za-z_]/;
const NAME_CHAR = /[\w.:-]/;
const WS = /\s/;
// 따옴표 없는 속성값에 올 수 있는 문자. HTML 의 규칙과 같은 집합이다.
const BARE_VALUE = /[^\s"'=<>`]/;

/** 실패 메시지에 실을 짧은 발췌. 줄바꿈은 한 줄로 접는다. */
function snippet(text: string, at: number): string {
  return text.slice(at, at + 80).replace(/\s+/g, ' ').trim();
}

/**
 * 속성만 있는 XML 을 훑는다.
 *
 * 관대함과 엄격함을 **자리에 따라** 나눈다:
 *
 * - 태그가 아닌 텍스트는 전부 무시한다. get_metadata 응답 끝에는 XML 이 아닌
 *   "IMPORTANT: ..." 문장이 붙고, 그 안에 `nodeId=<id>` 같은 조각이 있어도
 *   그건 문서 구조가 아니다.
 * - 주석 안의 태그는 문서에 **존재하지 않는다**. 세면 있지도 않은 노드가
 *   "추가됨" 으로 이슈에 실린다.
 * - 반대로 **태그로 시작했는데 끝까지 읽어내지 못한 것**은 무시하지 않는다.
 *   무시하면 그 노드가 조용히 사라지고, 사라진 노드는 리포트에서 **짝 없는
 *   삭제**로 나타난다 — id 로 매칭하는 이유가 정확히 그 혼동을 없애는 것인데
 *   파서가 그것을 되살리는 셈이다. 게다가 여는 태그를 놓치면 depth 가 밀려
 *   그 아래 전부의 깊이가 어긋난다. 이상한 모양을 전부 열거할 수는 없으므로,
 *   **이해하지 못한 것은 전부 실행을 멈춘다**로 설계한다.
 */
function parsePageXml(text: string): PageParse {
  const nodes: RawNode[] = [];
  let depth = 0;
  let rootTag: string | null = null;
  let rootClosed = false;
  let i = 0;

  while (i < text.length) {
    const lt = text.indexOf('<', i);
    if (lt === -1) break;

    if (text.startsWith('<!--', lt)) {
      const end = text.indexOf('-->', lt + 4);
      if (end === -1) {
        // 닫히지 않은 주석은 응답이 중간에 잘렸다는 뜻이다.
        return { nodes, rootTag, rootClosed, malformed: snippet(text, lt) };
      }
      i = end + 3;
      continue;
    }

    let p = lt + 1;
    const isClose = text[p] === '/';
    if (isClose) p += 1;
    if (p >= text.length || !NAME_START.test(text[p])) {
      i = lt + 1;
      continue;
    }

    let nameEnd = p;
    while (nameEnd < text.length && NAME_CHAR.test(text[nameEnd])) nameEnd += 1;
    const tag = text.slice(p, nameEnd);
    p = nameEnd;

    const attrs: Record<string, string> = {};
    let selfClosing = false;
    let closed = false;

    for (;;) {
      while (p < text.length && WS.test(text[p])) p += 1;
      if (p >= text.length) break;
      if (text[p] === '>') {
        p += 1;
        closed = true;
        break;
      }
      if (text[p] === '/' && text[p + 1] === '>') {
        selfClosing = true;
        p += 2;
        closed = true;
        break;
      }
      if (!NAME_START.test(text[p])) break;

      let keyEnd = p;
      while (keyEnd < text.length && NAME_CHAR.test(text[keyEnd])) keyEnd += 1;
      const key = text.slice(p, keyEnd);
      p = keyEnd;

      while (p < text.length && WS.test(text[p])) p += 1;
      if (text[p] !== '=') {
        // 값 없는 속성. 노드를 잃는 모양이 아니므로 받아들인다.
        attrs[key] = '';
        continue;
      }
      p += 1;
      while (p < text.length && WS.test(text[p])) p += 1;

      const quote = text[p];
      if (quote === '"' || quote === "'") {
        const close = text.indexOf(quote, p + 1);
        if (close === -1) break;
        attrs[key] = decodeEntities(text.slice(p + 1, close));
        p = close + 1;
        // 닫는 따옴표 다음은 공백이거나 태그의 끝이어야 한다. 아니면 그
        // 따옴표는 값의 끝이 아니라 **값 안에 이스케이프 없이 들어간 따옴표**
        // 였다는 뜻이고(`name="Card "primary""`), 그대로 진행하면 이름이
        // 조용히 잘린 채 통과한다 — 그건 드롭보다 나쁘다.
        if (
          p < text.length &&
          !WS.test(text[p]) &&
          text[p] !== '>' &&
          !(text[p] === '/' && text[p + 1] === '>')
        ) {
          break;
        }
      } else {
        let valueEnd = p;
        while (valueEnd < text.length && BARE_VALUE.test(text[valueEnd])) {
          valueEnd += 1;
        }
        if (valueEnd === p) break;
        let raw = text.slice(p, valueEnd);
        p = valueEnd;
        // 따옴표 없는 값은 끝의 `/` 를 self-closing 슬래시와 구별할 수 없다.
        // `height=10/>` 의 `/` 는 값이 아니라 태그의 것이므로 되돌려 놓는다.
        if (raw.endsWith('/') && text[p] === '>') {
          raw = raw.slice(0, -1);
          p -= 1;
        }
        attrs[key] = decodeEntities(raw);
      }
    }

    if (!closed) {
      return { nodes, rootTag, rootClosed, malformed: snippet(text, lt) };
    }

    if (isClose) {
      // 여는 태그보다 닫는 태그가 많아도 음수로 내려가지 않게 막는다 —
      // 잘린 응답에서 depth 가 음수가 되면 이후 전부가 잘못된 깊이로 기록된다.
      if (rootTag !== null && tag === rootTag && depth === 1) rootClosed = true;
      depth = Math.max(0, depth - 1);
      i = p;
      continue;
    }

    if (rootTag === null) {
      rootTag = tag;
      // self-closing 루트는 닫는 태그가 있을 수 없다 — 그 자체로 완결이다.
      if (selfClosing) rootClosed = true;
    }

    // id 없는 태그는 노드로 세지 않는다 — id 가 매칭 키라서 그것 없이는
    // 어떤 변화도 특정 노드에 귀속시킬 수 없다.
    if (attrs.id !== undefined) {
      nodes.push({
        id: attrs.id,
        name: attrs.name ?? '',
        type: tag,
        x: numAttr(attrs, 'x'),
        y: numAttr(attrs, 'y'),
        w: numAttr(attrs, 'width'),
        h: numAttr(attrs, 'height'),
        depth,
      });
    }

    if (!selfClosing) depth += 1;
    i = p;
  }

  return { nodes, rootTag, rootClosed, malformed: null };
}

/** 실패 메시지에 "무엇이 왔는지" 를 싣는다. 이것 없이는 고칠 자리를 못 찾는다. */
function describe(v: unknown): string {
  if (v === undefined) return 'undefined';
  const s = JSON.stringify(v);
  // 함수·심볼은 stringify 가 문자열을 돌려주지 않는다. 그대로 보간하면 메시지가
  // "undefined" 가 되어 값이 빠진 경우와 구별되지 않는다.
  return typeof s === 'string' ? s : String(v);
}

/**
 * 파일 읽기 실패는 **인프라 실패**이지 디자인 변경이 아니다 — writeOut 과 같은 이유.
 *
 * `existsSync` 를 통과해도 읽기는 던진다. 그 자리가 디렉터리이거나, 권한이
 * 없거나, 확인과 읽기 사이에 사라지면 그렇다. 감싸지 않으면 그 예외가 그대로
 * 올라가 Node 를 **종료 코드 1** 로 끝내고, 자동화는 그 1 을 "디자이너가
 * 무언가 바꿨다" 로 읽어 읽히지도 않은 파일로 이슈를 만든다.
 */
function readFile(path: string, label: string): string {
  try {
    return readFileSync(path, 'utf8');
  } catch (e) {
    return fail(
      `${label} 을(를) 읽지 못함: ${path}`,
      `읽기 실패가 종료 코드 1 로 새어 나가면 자동화는 그것을 "변화 있음" 으로 읽는다 (${String(e)})`,
      '그 경로가 실제 파일이고 읽기 권한이 있는지 확인하라',
    );
  }
}

function readJson<T>(path: string, label: string): T {
  if (!existsSync(path)) {
    fail(
      `${label} 을(를) 찾을 수 없음: ${path}`,
      '비교 기준이 없으면 어떤 판정도 내릴 수 없다',
      `경로를 확인하거나 --baseline / --config 로 올바른 파일을 지정하라`,
    );
  }
  const text = readFile(path, label);
  try {
    return JSON.parse(text) as T;
  } catch (e) {
    return fail(
      `${label} 파싱 실패: ${path}`,
      `JSON 이 깨져 있으면 "변화 없음" 과 구별되지 않는다 (${String(e)})`,
      '파일 내용을 직접 열어 확인하라',
    );
  }
}

/**
 * 베이스라인을 **설정과 같은 엄격함으로** 검증한다.
 *
 * 비교의 다른 한쪽을 검증하지 않으면 깨진 베이스라인이 두 갈래로 새어 나간다.
 * 하나는 던지는 것 — `pages` 가 배열이 아니면 순회에서 예외가 나고, 잡히지 않은
 * 예외는 Node 를 **종료 코드 1** 로 끝내서 자동화가 그것을 디자이너의 드리프트로
 * 읽는다. 다른 하나는 더 나쁘다 — `nodeCount` 가 숫자가 아니면 모집단 하한이
 * `NaN` 이 되어 어떤 붕괴도 통과하고, 리포트는 그럴듯한 변경 목록을 그대로 뱉는다.
 *
 * 두 모양 다 `fileKey` 만 멀쩡하면 지금까지의 어떤 검사도 막지 못했다. 그리고
 * `fileKey` 는 파일 맨 위에 있어서, 병합 충돌을 푼 직후의 베이스라인이 정확히
 * 그 모양이 된다 — 위쪽은 살아남고 아래쪽만 뭉개진다.
 */
function readSnapshot(path: string, label: string): Snapshot {
  const raw = readJson<unknown>(path, label);

  function bad(field: string, saw: unknown, want: string): never {
    return fail(
      `${label} 의 \`${field}\` 가 올바르지 않음: ${describe(saw)} (${path})`,
      '검증되지 않은 베이스라인은 예외를 던져 종료 코드 1 로 새어 나가거나(자동화가 드리프트로 읽는다) 하한을 NaN 으로 만들어 어떤 붕괴도 통과시킨다',
      `\`${field}\` 를 고치거나, 이 캡처를 기준으로 삼는 게 맞다면 --update-baseline 으로 베이스라인을 새로 세워라. 기대하는 형태: ${want}`,
    );
  }

  function obj(v: unknown, field: string): Record<string, unknown> {
    if (typeof v !== 'object' || v === null || Array.isArray(v)) {
      bad(field, v, '객체');
    }
    return v as Record<string, unknown>;
  }

  function str(v: unknown, field: string): string {
    if (typeof v !== 'string' || v.trim() === '') bad(field, v, '비어 있지 않은 문자열');
    return v as string;
  }

  function count(v: unknown, field: string): number {
    if (typeof v !== 'number' || !Number.isInteger(v) || v < 0) {
      bad(field, v, '0 이상의 정수');
    }
    return v as number;
  }

  /** 없는 값과 0 은 다른 주장이라 `null` 을 그대로 보존한다(파서와 같은 규칙). */
  function coord(v: unknown, field: string): number | null {
    if (v === null) return null;
    if (typeof v !== 'number' || !Number.isFinite(v)) bad(field, v, '유한한 수 또는 null');
    return v as number;
  }

  /**
   * 프로퍼티 정의 목록. `null` 은 "읽지 못함" 이라 그대로 보존한다 — 빈 배열로 접으면
   * 읽지 못한 세트가 "프로퍼티를 전부 지웠다" 로 보고된다.
   */
  function propList(v: unknown, field: string): SnapshotProp[] | null {
    if (v === null) return null;
    if (!Array.isArray(v)) bad(field, v, '배열 또는 null');
    return (v as unknown[]).map((rawProp, i) => {
      const at = `${field}[${i}]`;
      const prop = obj(rawProp, at);
      const def = prop.default;
      if (typeof def !== 'string' && typeof def !== 'boolean') {
        bad(`${at}.default`, def, '문자열 또는 불리언');
      }
      const out: SnapshotProp = {
        key: str(prop.key, `${at}.key`),
        type: str(prop.type, `${at}.type`),
        default: def as string | boolean,
      };
      if (Object.prototype.hasOwnProperty.call(prop, 'options')) {
        const opts = prop.options;
        if (!Array.isArray(opts) || !opts.every((o) => typeof o === 'string')) {
          bad(`${at}.options`, opts, '문자열 배열');
        }
        out.options = [...(opts as string[])];
      }
      return out;
    });
  }

  const root = obj(raw, '(root)');

  // 순서가 메시지의 값을 정한다. 비교를 성립시키는 필드(schema · fileKey ·
  // nodeCount · pages)를 먼저 보고 출처 필드를 나중에 본다 — 뭉개진 베이스라인은
  // 대개 여러 필드가 동시에 빠지는데, 그때 첫 실패로 `capturedAt` 이 뜨면
  // 읽는 사람이 진짜 문제(예: `pages` 가 배열이 아님)를 못 보고 지나간다.
  if (typeof root.schema !== 'number' || !READABLE_SNAPSHOT_SCHEMAS.includes(root.schema)) {
    bad(
      'schema',
      root.schema,
      `${READABLE_SNAPSHOT_SCHEMAS.join(' 또는 ')} (이 코드가 읽을 수 있는 형태)`,
    );
  }
  const schema = root.schema as number;
  const withProps = carriesComponentProps(schema);
  if (root.fileKey !== null && (typeof root.fileKey !== 'string' || root.fileKey === '')) {
    bad('fileKey', root.fileKey, '비어 있지 않은 문자열 또는 null');
  }
  const nodeCount = count(root.nodeCount, 'nodeCount');

  if (!Array.isArray(root.pages)) bad('pages', root.pages, '배열');

  const pages: PageSnapshot[] = [];
  let seen = 0;
  (root.pages as unknown[]).forEach((rawPage, pi) => {
    const page = obj(rawPage, `pages[${pi}]`);
    // 페이지 자신을 먼저 본다(루트에서와 같은 이유) — 페이지 id 가 뭉개졌는데
    // 그 안 노드의 오류가 먼저 뜨면 읽는 사람이 한 겹 위의 문제를 못 본다.
    const pageId = str(page.id, `pages[${pi}].id`);
    const pageName = str(page.name, `pages[${pi}].name`);
    if (!Array.isArray(page.nodes)) bad(`pages[${pi}].nodes`, page.nodes, '배열');
    // 깊이별 조상 타입 — 노드 목록은 전위 순회라 depth-1 자리의 마지막 기록이
    // 곧 부모다. 소유 판정(세트 안의 변형은 정의를 갖지 않는다)이 부모를 봐야 한다.
    const typeAtDepth: string[] = [];
    const nodes: RawNode[] = (page.nodes as unknown[]).map((rawNode, ni) => {
      const at = `pages[${pi}].nodes[${ni}]`;
      const node = obj(rawNode, at);
      const record: RawNode = {
        // id 가 매칭 키다 — 이것이 비면 그 노드는 어떤 변화에도 귀속되지 않고,
        // name 이 비면 표를 그리는 자리에서 던진다(그 예외 역시 종료 코드 1 이다).
        id: str(node.id, `${at}.id`),
        name: typeof node.name === 'string' ? node.name : bad(`${at}.name`, node.name, '문자열'),
        type: str(node.type, `${at}.type`),
        x: coord(node.x, `${at}.x`),
        y: coord(node.y, `${at}.y`),
        w: coord(node.w, `${at}.w`),
        h: coord(node.h, `${at}.h`),
        depth: count(node.depth, `${at}.depth`),
      };
      const parentType = record.depth > 0 ? (typeAtDepth[record.depth - 1] ?? null) : null;
      typeAtDepth[record.depth] = record.type;
      typeAtDepth.length = record.depth + 1;

      // ── schema 2 의 두 키 — **있는지 여부 자체가 계약**이다 ─────────────────
      // 소유 노드에 `props` 가 없으면 그 컴포넌트의 프로퍼티 편집은 비교되지 않은 채
      // "변화 없음" 으로 나간다. 반대로 schema 1 이 그 키를 싣고 있으면 파일이 자기
      // 모양에 대해 거짓말하는 것이고, 그 값은 비교에서 조용히 버려진다. 둘 다 멈춘다.
      const owns = ownsComponentProps(record.type, parentType);
      const hasProps = Object.prototype.hasOwnProperty.call(node, 'props');
      if (!withProps || !owns) {
        if (hasProps) {
          bad(
            `${at}.props`,
            node.props,
            withProps
              ? '키 없음 — 프로퍼티는 컴포넌트 세트와 세트 밖 컴포넌트만 싣는다'
              : `키 없음 — schema ${schema} 캡처는 프로퍼티를 싣지 않는다`,
          );
        }
      } else if (!hasProps) {
        bad(`${at}.props`, undefined, '배열 또는 null (schema 2 의 소유 노드는 반드시 싣는다)');
      } else {
        record.props = propList(node.props, `${at}.props`);
      }

      const needsMain = withProps && carriesMainComponent(record.type);
      const hasMain = Object.prototype.hasOwnProperty.call(node, 'main');
      if (!needsMain) {
        if (hasMain) {
          bad(
            `${at}.main`,
            node.main,
            withProps
              ? '키 없음 — 원본 참조는 인스턴스만 싣는다'
              : `키 없음 — schema ${schema} 캡처는 원본 참조를 싣지 않는다`,
          );
        }
      } else if (!hasMain) {
        bad(`${at}.main`, undefined, '노드 id 문자열 또는 null (schema 2 의 인스턴스는 반드시 싣는다)');
      } else {
        record.main = node.main === null ? null : str(node.main, `${at}.main`);
      }
      return record;
    });
    seen += nodes.length;
    pages.push({ id: pageId, name: pageName, nodes });
  });

  if (root.capturedAt !== null && typeof root.capturedAt !== 'string') {
    bad('capturedAt', root.capturedAt, '문자열 또는 null');
  }
  str(root.capturedBy, 'capturedBy');

  // nodeCount 는 모집단 하한이 유일하게 읽는 수다. 실제 노드 수와 어긋나면
  // 그 하한이 조용히 다른 값이 된다 — 타입은 멀쩡하니 위의 어떤 검사도 안 걸린다.
  // 실측: 7 개짜리 베이스라인의 nodeCount 를 1 로 두면 하한이 0.5 로 내려앉아
  // 노드 2 개만 남은 붕괴 캡처가 통과하고 6 건의 거짓 삭제로 나간다.
  if (nodeCount !== seen) {
    bad('nodeCount', nodeCount, `pages 안 실제 노드 수(${seen})와 같은 값`);
  }

  return {
    schema,
    fileKey: root.fileKey as string | null,
    capturedAt: root.capturedAt as string | null,
    capturedBy: root.capturedBy as string,
    nodeCount,
    pages,
  };
}

/**
 * 설정을 읽고 **읽는 필드를 전부 검증한다.**
 *
 * 검증이 없으면 오타 하나가 가드를 조용히 끈다. 실측: `geometryEpsilonPx` 가
 * 빠지면 `Math.abs(delta) > undefined` 가 **항상 false** 라, 노드가 이동하고
 * 크기까지 바뀐 캡처가 "✅ 변화 없음 / 종료 코드 0" 으로 나온다.
 * `populationFloorRatio` 가 빠지면 하한이 `NaN` 이 되어 어떤 붕괴도 통과한다.
 * 둘 다 리포트는 멀쩡해 보이므로 눈으로는 잡히지 않는다.
 *
 * **값이 있다고 검증이 끝난 것도 아니다.** 두 값 모두 "있지만 가드를 끄는" 값을
 * 받을 수 있고, 그 증상은 값이 빠졌을 때와 정확히 같다 — 그래서 범위까지 본다.
 */
function readConfig(path: string): Config {
  const raw = readJson<Record<string, unknown>>(path, 'config.json');

  function badField(key: string, saw: unknown, want: string): never {
    return fail(
      `config.json 의 \`${key}\` 가 올바르지 않음: ${describe(saw)} (${path})`,
      '읽는 값이 검증되지 않으면 오타 하나가 가드를 조용히 끄고, 리포트는 그대로 초록으로 나온다',
      `\`${key}\` 값을 고쳐라. 기대하는 형태: ${want}`,
    );
  }

  // 이 파일도 버전을 달고 다닌다. 스냅샷의 `schema` 와 같은 이유로 읽는다 —
  // 검증하지 않는 버전 필드는 보장이 아니라 장식이다. 값을 나르지 않고 여기서
  // 소비하는 이유는 아래 Config 에 담아 아무도 읽지 않으면 그것이 곧 같은
  // 장식이 되기 때문이다.
  if (raw.schema !== CONFIG_SCHEMA) {
    badField('schema', raw.schema, `${CONFIG_SCHEMA} (이 코드가 읽을 수 있는 형태)`);
  }

  function str(key: string): string {
    const v = raw[key];
    if (typeof v !== 'string' || v.trim() === '') {
      badField(key, v, '비어 있지 않은 문자열');
    }
    return v as string;
  }

  function num(key: string, min: number, max: number, want: string): number {
    const v = raw[key];
    if (typeof v !== 'number' || !Number.isFinite(v) || v < min || v > max) {
      badField(key, v, want);
    }
    return v as number;
  }

  const pagesRaw = raw.pages;
  const pages =
    pagesRaw === null || pagesRaw === undefined
      ? null
      : Array.isArray(pagesRaw) && pagesRaw.every((p) => typeof p === 'string')
        ? (pagesRaw as string[])
        : badField('pages', pagesRaw, 'null 이거나 문자열 배열');

  const fileKey = str('fileKey');
  const fileUrl = str('fileUrl');

  // ── fileKey 와 fileUrl 이 **같은 파일**을 가리키는가 ──────────────────────
  //
  // 이 둘은 각자 "비어 있지 않은 문자열" 검사를 통과할 수 있으면서 서로 다른
  // 파일을 가리킬 수 있다. 그 config 는 인터록을 포함한 모든 게이트를 통과하고,
  // 그때 리포트의 **딥링크 전부가 엉뚱한 문서를 연다** — 링크는 이 리포트에서
  // 값이 가장 큰 부분이고(그것이 없으면 id 를 들고 Figma 를 뒤져야 한다), 열리는
  // 문서가 그럴듯하면 틀렸다는 것을 알아챌 방법이 없다. fileKey 인터록이 막으려는
  // "형식상 멀쩡하고 의미상 엉뚱한 파일" 과 같은 위험이 인터록이 보지 않는 필드에
  // 그대로 남아 있는 셈이다.
  const inUrl = FIGMA_FILE_URL.exec(fileUrl);
  if (inUrl === null) {
    badField(
      'fileUrl',
      fileUrl,
      'Figma 파일 URL (예: https://www.figma.com/design/<fileKey>/<이름>). ' +
        '파일 키 자리를 읽어내지 못하면 fileKey 와 대조할 수 없고, 대조하지 않은 URL 로 만든 딥링크는 검증된 적이 없다',
    );
  }
  if (inUrl[1] !== fileKey) {
    fail(
      `config.json 의 fileKey 와 fileUrl 이 서로 다른 파일을 가리킴 — fileKey ${JSON.stringify(fileKey)} vs fileUrl 안의 ${JSON.stringify(inUrl[1])} (${path})`,
      '캡처는 fileKey 의 파일에서 오고 리포트의 딥링크는 fileUrl 로 만들어진다 — 둘이 다르면 모든 행이 엉뚱한 문서를 열고, 열린 문서가 그럴듯하면 아무도 알아채지 못한다',
      '두 값 중 어느 쪽이 정본인지 확인하고 나머지를 거기에 맞춰라',
    );
  }

  return {
    fileKey,
    fileKeyStatus: str('fileKeyStatus'),
    fileUrl,
    pages,
    geometryEpsilonPx: num(
      'geometryEpsilonPx',
      0,
      MAX_GEOMETRY_EPSILON_PX,
      `0 이상 ${MAX_GEOMETRY_EPSILON_PX} 이하의 유한한 수 (픽셀). 이보다 큰 허용오차는 잡음을 흡수하는 게 아니라 실제 이동·크기 변경을 가린다`,
    ),
    populationFloorRatio: num(
      'populationFloorRatio',
      MIN_POPULATION_FLOOR_RATIO,
      1,
      `${MIN_POPULATION_FLOOR_RATIO} 이상 1 이하의 유한한 수 (베이스라인 대비 비율). 이보다 낮으면 대부분이 사라진 캡처가 통과해서 하한을 끈 것과 구별되지 않는다`,
    ),
  };
}

/**
 * 이 캡처가 디스크에 기록된 시각.
 *
 * 스냅샷 자신은 자기가 언제 떠졌는지 모른다 — MCP 응답에는 시각이 없다. 대신
 * 캡처 스크립트가 `pages.txt` 를 쓴 시각을 쓴다. 그 파일은 매 캡처의 첫 산출물이라
 * 이 실행이 **어느 시점의 캔버스**를 보고 있는지에 가장 가까운 값이다.
 *
 * 읽지 못하면 `null` 을 돌려주고 그대로 리포트에 적는다. 모르는 것을 `현재 시각`
 * 으로 채우면 오래된 캡처가 방금 뜬 것으로 렌더되는데, 그건 이 값을 두는 이유의
 * 정확한 반대다.
 */
function capturedAtOf(pagesTxt: string): string | null {
  try {
    return statSync(pagesTxt).mtime.toISOString();
  } catch {
    return null;
  }
}

function buildSnapshot(rawDir: string, config: Config): Capture {
  const pagesTxt = resolve(rawDir, 'pages.txt');
  if (!existsSync(pagesTxt)) {
    fail(
      `pages.txt 가 없음: ${pagesTxt}`,
      'MCP 캡처가 아예 실행되지 않았거나 --raw-dir 이 잘못됐다',
      'get_metadata(nodeId 없이) 출력을 pages.txt 로 저장했는지 확인하라',
    );
  }

  const all = parsePagesTxt(readFile(pagesTxt, 'pages.txt'));
  if (all.length === 0) {
    fail(
      `pages.txt 에서 페이지를 한 개도 읽지 못함: ${pagesTxt}`,
      '빈 페이지 목록은 "파일이 비었다" 가 아니라 캡처/파싱이 깨진 것에 가깝다 — 이 상태로 진행하면 전 노드가 삭제된 것으로 보고된다',
      'pages.txt 가 "- <id>: <name>" 줄을 담고 있는지 눈으로 확인하라',
    );
  }

  let pages = all;
  let outOfScope: PageRef[] = [];
  if (config.pages !== null) {
    const allow = new Set(config.pages);
    pages = all.filter((p) => allow.has(p.id));
    if (pages.length === 0) {
      fail(
        `config.pages 가 pages.txt 의 어떤 페이지와도 맞지 않음 (필터 ${config.pages.length}개 · 파일 ${all.length}개)`,
        '필터가 전부 빗나가면 노드가 하나도 안 읽히고, 그건 전 페이지 삭제와 출력이 같다',
        'config.json 의 pages 에 적힌 id 가 pages.txt 에 실제로 등장하는지 대조하라',
      );
    }

    // 필터가 **일부만** 빗나가는 경우가 전부 빗나가는 경우보다 위험하다 — 전부
    // 빗나가면 위에서 멈추지만, 오타 하나가 섞이면 그 페이지만 조용히 빠진 채
    // 리포트가 정상적으로 나오고 운영자는 자기가 적은 범위가 다 덮였다고 믿는다.
    const inFile = new Set(all.map((p) => p.id));
    const missing = config.pages.filter((id) => !inFile.has(id));
    if (missing.length > 0) {
      fail(
        `config.pages 에 적힌 페이지가 pages.txt 에 없음: ${missing.join(', ')}`,
        '맞지 않는 id 는 조용히 무시되어 커버리지를 줄인다 — 리포트는 그대로 나오므로 범위가 좁아진 것을 아무도 알아채지 못한다',
        '그 id 의 오타를 고치거나, 페이지가 실제로 삭제된 것이면 config.pages 에서 지워라',
      );
    }

    const walked = new Set(pages.map((p) => p.id));
    outOfScope = all.filter((p) => !walked.has(p.id));
  }

  const out: PageSnapshot[] = [];
  let nodeCount = 0;

  for (const page of pages) {
    const xmlPath = resolve(rawDir, `page-${sanitiseNodeId(page.id)}.xml`);
    const where = `page ${page.id} "${page.name}"`;
    if (!existsSync(xmlPath)) {
      // 페이지 파일 하나가 비면 그 페이지의 모든 노드가 "삭제됨" 으로 보고된다.
      // 그건 정확히 모집단 붕괴가 만드는 거짓 신호라 infra 실패로 처리한다.
      fail(
        `페이지 XML 이 없음: ${xmlPath} (${where})`,
        '한 페이지의 캡처가 빠지면 그 페이지 전체가 삭제된 것처럼 보고된다 — 실제 삭제와 구별할 수 없다',
        '해당 페이지에 대해 get_metadata(nodeId=<page id>) 를 다시 캡처하라',
      );
    }

    const parsed = parsePageXml(readFile(xmlPath, `페이지 XML (${where})`));

    if (parsed.malformed !== null) {
      fail(
        `페이지 XML 에서 읽어내지 못한 태그: ${xmlPath} (${where})\n   여기: ${parsed.malformed}`,
        '읽지 못한 여는 태그를 건너뛰면 그 노드가 조용히 사라져 짝 없는 삭제로 보고되고, depth 가 밀려 그 아래 전부의 깊이가 어긋난다',
        '해당 페이지를 다시 캡처하라. 응답이 정상인데도 계속 걸리면 그 모양을 파서가 다루도록 고쳐라',
      );
    }

    if (parsed.nodes.length === 0) {
      // MCP 가 "You currently have nothing selected." 같은 산문만 돌려준 경우가
      // 여기로 온다. 정상 응답이라면 캔버스 요소 자체가 id 를 달고 오므로
      // 최소 한 개는 읽힌다. 노드 0 개는 디자인에 대한 발견이 아니라 캡처
      // 실패이며, 그대로 진행하면 그 페이지 전체가 삭제로 보고된다.
      fail(
        `페이지에서 노드를 한 개도 읽지 못함: ${xmlPath} (${where})`,
        '노드 0 개는 "페이지가 비었다" 가 아니라 캡처가 구조를 못 받은 것이다 — 그대로 진행하면 그 페이지 전체가 삭제로 보고된다',
        '파일 내용이 실제 XML 인지 확인하라. MCP 오류 문장이 들어 있으면 그 페이지를 다시 캡처하라',
      );
    }

    if (!parsed.rootClosed) {
      // 토큰 한도에 걸려 응답이 중간에서 끊기면 남은 노드가 전부 "삭제됨" 으로
      // 보고된다 — 모집단 하한을 넘길 만큼만 잘리면 하한도 막지 못한다.
      // 판정은 "루트를 닫는 태그를 보았는가" 로 한다. 끝에서 depth 가 0 인지만
      // 보면 응답 끝의 산문(`nodeId=<id>`)이 여는 태그로 읽혀 멀쩡한 캡처를
      // 잘린 것으로 오판한다.
      //
      // ⚠️ **`pages.txt` 에는 이 기법을 쓸 수 없다.** 페이지 목록은 `- <id>: <name>`
      // 줄의 나열일 뿐 종결자가 없어서, 마지막 줄이 진짜 마지막인지 잘린 자리인지
      // 알려주는 것이 응답 안에 없다. 그래서 그쪽의 잘림은 여기처럼 **거부할 수
      // 없고** 세 가지로만 좁힌다: (1) 노드 모집단 하한, (2) 페이지 수 하한
      // — 노드는 대부분 남고 작은 페이지들만 사라지는 모양을 잡는다, (3) 베이스라인에
      // 있는데 목록에 없는 페이지를 리포트에 **의심으로 적기**. 셋 다 통과하는
      // 잘림(노드가 소수인 페이지 하나가 사라지는 경우)은 남아 있고, 그건 이
      // 입력으로 페이지 삭제와 구별되지 않는다 — 삭제는 정당한 드리프트라 거부하면
      // 가장 흔한 발견을 삼킨다.
      fail(
        `페이지 XML 이 중간에서 끊김: ${xmlPath} (${where})\n   <${parsed.rootTag}> 를 닫는 태그를 찾지 못했다 (읽은 노드 ${parsed.nodes.length}개)`,
        '잘린 응답은 남은 노드를 전부 "삭제됨" 으로 보고한다 — 디자이너가 지운 것과 구별되지 않고, 하한을 넘길 만큼만 잘리면 하한도 막지 못한다',
        '해당 페이지를 다시 캡처하라. 반복되면 config.pages 로 페이지를 쪼개 한 번에 받는 양을 줄여라 — 범위 밖 페이지는 삭제가 아니라 "비교 안 함" 으로 보고되고, 그 페이지가 베이스라인에 들어 있으면 --update-baseline 은 거부된다',
      );
    }

    nodeCount += parsed.nodes.length;
    out.push({ id: page.id, name: page.name, nodes: parsed.nodes });
  }

  return {
    snapshot: {
      // MCP 원문에는 프로퍼티 정의도 인스턴스의 원본도 없다 — 그 둘을 싣지 않는다고
      // 정직하게 주장해야, 비교하는 쪽이 "없어서 같았다" 가 아니라 "안 봤다" 로 말한다.
      schema: SNAPSHOT_SCHEMA_GEOMETRY_ONLY,
      fileKey: config.fileKey,
      capturedAt: capturedAtOf(pagesTxt),
      capturedBy: 'figma-mcp:get_metadata',
      nodeCount,
      pages: out,
    },
    inFile: all,
    outOfScope,
  };
}

/**
 * 플러그인이 만든 스냅샷 파일에서 Capture 를 만든다.
 *
 * 파일은 이미 스냅샷 모양이라 파싱할 것이 없다 — `readSnapshot` 의 검증을 그대로
 * 통과시키고, `config.pages` 필터만 raw-dir 경로와 같은 규칙으로 적용한다. 파일이
 * 나열한 페이지 전체가 `inFile` 이다(플러그인은 항상 전 페이지를 걷는다).
 */
function buildSnapshotFromFile(path: string, config: Config): Capture {
  const snap = readSnapshot(path, '스냅샷 파일');
  if (snap.pages.length === 0) {
    fail(
      `스냅샷 파일에 페이지가 없음: ${path}`,
      '빈 페이지 목록은 "파일이 비었다" 가 아니라 캡처가 깨진 것에 가깝다 — 이 상태로 진행하면 전 노드가 삭제된 것으로 보고된다',
      '플러그인의 "구조 → .json" 을 다시 실행해 받은 파일인지 확인하라',
    );
  }
  const all: PageRef[] = snap.pages.map((p) => ({ id: p.id, name: p.name }));

  let pages = snap.pages;
  let outOfScope: PageRef[] = [];
  if (config.pages !== null) {
    const allow = new Set(config.pages);
    pages = snap.pages.filter((p) => allow.has(p.id));
    if (pages.length === 0) {
      fail(
        `config.pages 가 스냅샷의 어떤 페이지와도 맞지 않음 (필터 ${config.pages.length}개 · 파일 ${all.length}개)`,
        '필터가 전부 빗나가면 노드가 하나도 안 읽히고, 그건 전 페이지 삭제와 출력이 같다',
        'config.json 의 pages 에 적힌 id 가 스냅샷에 실제로 등장하는지 대조하라',
      );
    }
    const inFile = new Set(all.map((p) => p.id));
    const missing = config.pages.filter((id) => !inFile.has(id));
    if (missing.length > 0) {
      fail(
        `config.pages 에 적힌 페이지가 스냅샷에 없음: ${missing.join(', ')}`,
        '맞지 않는 id 는 조용히 무시되어 커버리지를 줄인다 — 리포트는 그대로 나오므로 범위가 좁아진 것을 아무도 알아채지 못한다',
        '그 id 의 오타를 고치거나, 페이지가 실제로 삭제된 것이면 config.pages 에서 지워라',
      );
    }
    const walked = new Set(pages.map((p) => p.id));
    outOfScope = all.filter((p) => !walked.has(p.id));
  }

  return {
    snapshot: {
      schema: snap.schema,
      // 파일 키는 설정이 정본이다 — 베이스라인 대조가 설정의 키로 이뤄지고, 캡처
      // 안의 키는 아래 main 이 설정과 같은지 따로 확인한다.
      fileKey: config.fileKey,
      capturedAt: snap.capturedAt,
      capturedBy: snap.capturedBy,
      nodeCount: pages.reduce((n, p) => n + p.nodes.length, 0),
      pages,
    },
    inFile: all,
    outOfScope,
  };
}

/** 목록에서 사라진 페이지 하나와, 그 페이지가 베이스라인에서 들고 있던 노드 수. */
interface AbsentPage {
  page: PageRef;
  nodes: number;
}

/**
 * 베이스라인에는 있는데 이번 `pages.txt` 에 **아예 없는** 페이지.
 *
 * `config.pages` 로 제외한 페이지와 다르다 — 그쪽은 목록에 있으면서 걷지 않은
 * 것이라 "비교 안 함" 으로 갈리지만, 여기 걸리는 페이지는 목록 자체에 없어서
 * 그 노드가 전부 **삭제**로 세어진다. 지워진 것일 수도, 목록이 잘린 것일 수도
 * 있고 이 입력만으로는 구별되지 않는다. 그래서 판정하지 않고 세어서 리포트에 적는다.
 */
function pagesAbsentFromListing(baseline: Snapshot, inFile: PageRef[]): AbsentPage[] {
  const listed = new Set(inFile.map((p) => p.id));
  return baseline.pages
    .filter((p) => !listed.has(p.id))
    .map((p) => ({ page: { id: p.id, name: p.name }, nodes: p.nodes.length }));
}

/** id → 노드 + 그 노드가 있는 페이지. 페이지를 버리면 행이 특정되지 않는다. */
function flatten(snap: Snapshot): Map<string, Located> {
  const map = new Map<string, Located>();
  for (const page of snap.pages) {
    for (const node of page.nodes) {
      // id 중복 시 첫 번째를 유지 — 임의로 덮으면 실행마다 결과가 흔들린다.
      if (!map.has(node.id)) {
        map.set(node.id, { node, pageId: page.id, pageName: page.name });
      }
    }
  }
  return map;
}

function fmtNum(v: number | null): string {
  return v === null ? '—' : String(v);
}

function fmtPage(at: { pageId: string; pageName: string }): string {
  return `${at.pageName} (${at.pageId})`;
}

/**
 * 이 채널의 시각은 캡처가 디스크에 떠진 시각이다.
 *
 * 이 채널은 무인으로 돈다. MCP 캡처 단계가 조용히 실패하고 지난 실행의
 * `.work/latest` 가 그대로 남으면, 이 스크립트는 **같은 캡처를 다시 비교해서**
 * "변화 없음 · 종료 코드 0" 을 낸다 — 성공한 주기와 출력이 글자 그대로 같다.
 * 그래서 여기서는 오래된 것 자체가 신호이고, 그 임계는 캡처 주기와 같다.
 */
const CAPTURE_AGE = {
  label: '캡처 시각',
  stale: {
    afterDays: 1,
    warning:
      '**무인 실행은 매 주기 캡처를 새로 뜬다 — 이 캡처가 오래됐다면 ' +
      '이번 주기의 캡처 단계가 실패하고 지난 캡처가 다시 비교됐을 수 있다.**',
  },
} as const;

function diffSnapshots(
  baseline: Snapshot,
  current: Snapshot,
  epsilon: number,
  outOfScopePages: Set<string>,
): StructureDiff {
  // 베이스라인 전체를 매칭에 쓴다(범위 밖까지). 범위 밖 페이지에서 안으로 옮겨온
  // 노드가 여기 있어야 "추가" 가 아니라 "페이지 이동" 으로 읽힌다.
  const before = flatten(baseline);
  const after = flatten(current);

  const diff: StructureDiff = {
    added: [],
    removed: [],
    renamed: [],
    retyped: [],
    repaged: [],
    moved: [],
    resized: [],
    notCompared: [],
    geometryNotComparable: 0,
    propAdded: [],
    propRemoved: [],
    propRetyped: [],
    propDefaultChanged: [],
    propOptionsChanged: [],
    mainChanged: [],
    propsNotComparable: 0,
    mainNotComparable: 0,
    propsCompared: propsComparability(baseline, current),
  };

  for (const [id, at] of after) {
    if (!before.has(id)) diff.added.push(at);
  }
  for (const [id, at] of before) {
    if (after.has(id)) continue;
    // 걷지 않은 페이지에 있던 노드는 **사라진 것이 아니라 보지 않은 것**이다.
    //
    // 판정 기준이 "베이스라인에 있는데 이번에 안 읽혔다" 가 아니라 "그 페이지가
    // 파일에 있는데 config.pages 가 제외했다" 인 것이 핵심이다. 전자로 잡으면
    // pages.txt 가 잘려 페이지가 통째로 빠진 경우까지 "비교 안 함" 으로 접혀
    // 진짜 캡처 붕괴가 조용해진다. 파일에서 아예 사라진 페이지는 여전히 삭제다.
    if (outOfScopePages.has(at.pageId)) diff.notCompared.push(at);
    else diff.removed.push(at);
  }

  for (const [id, now] of after) {
    const was = before.get(id);
    if (was === undefined) continue;

    if (was.node.name !== now.node.name) {
      diff.renamed.push({ at: now, before: was.node.name, after: now.node.name });
    }

    // frame → component 승격은 이름도 기하도 그대로라, type 을 안 보면
    // 아무 변화 없음으로 나간다. 컴포넌트화는 디자인 시스템 상 큰 사건이다.
    if (was.node.type !== now.node.type) {
      diff.retyped.push({ at: now, before: was.node.type, after: now.node.type });
    }

    // 페이지를 옮긴 노드도 id 가 같아 지금까지 조용히 통과했다.
    if (was.pageId !== now.pageId) {
      diff.repaged.push({ at: now, before: fmtPage(was), after: fmtPage(now) });
    }

    // 한쪽이라도 값이 없으면 delta 를 주장하지 않는다. 대신 세어서 보고한다 —
    // 조용히 건너뛰면 "기하 변화 없음" 이 거짓으로 읽힌다.
    const posComparable =
      was.node.x !== null &&
      was.node.y !== null &&
      now.node.x !== null &&
      now.node.y !== null;
    const sizeComparable =
      was.node.w !== null &&
      was.node.h !== null &&
      now.node.w !== null &&
      now.node.h !== null;

    // 페이지 루트(캔버스)는 x/y 를 갖지 않는 것이 정상이라 세지 않는다.
    const isPageRoot = now.node.id === now.pageId;
    if (!isPageRoot && (!posComparable || !sizeComparable)) {
      diff.geometryNotComparable += 1;
    }

    if (
      posComparable &&
      (Math.abs((now.node.x as number) - (was.node.x as number)) > epsilon ||
        Math.abs((now.node.y as number) - (was.node.y as number)) > epsilon)
    ) {
      diff.moved.push({
        at: now,
        before: `(${fmtNum(was.node.x)}, ${fmtNum(was.node.y)})`,
        after: `(${fmtNum(now.node.x)}, ${fmtNum(now.node.y)})`,
      });
    }

    if (
      sizeComparable &&
      (Math.abs((now.node.w as number) - (was.node.w as number)) > epsilon ||
        Math.abs((now.node.h as number) - (was.node.h as number)) > epsilon)
    ) {
      diff.resized.push({
        at: now,
        before: `${fmtNum(was.node.w)}×${fmtNum(was.node.h)}`,
        after: `${fmtNum(now.node.w)}×${fmtNum(now.node.h)}`,
      });
    }

    if (diff.propsCompared.ran) comparePropsAndMain(was, now, before, after, diff);
  }

  return diff;
}

/**
 * 두 캡처가 **모두** 프로퍼티 정의를 싣고 있는가. 아니면 왜 아닌지.
 *
 * 한쪽이라도 schema 1 이면 이 축은 세지 않는다 — 그리고 그 사실을 리포트가 말한다.
 * 조용히 0 건으로 세면 프로퍼티만 더한 편집이 "변화 없음" 으로 나가던 원래 결함이
 * 그대로 남고, 반대로 없는 쪽을 빈 목록으로 읽으면 모든 세트의 모든 프로퍼티가
 * "추가됨" 으로 쏟아진다. 전환 기간에 멈추지도 않는다 — 기존 축은 그대로 비교한다.
 */
function propsComparability(
  baseline: Snapshot,
  current: Snapshot,
): { ran: true } | { ran: false; why: string } {
  if (!carriesComponentProps(baseline.schema)) {
    return {
      ran: false,
      why:
        `베이스라인이 schema ${baseline.schema} 캡처라 프로퍼티 정보 없음 — ` +
        `플러그인 "구조 → .json" 캡처(schema ${SNAPSHOT_SCHEMA})로 --update-baseline 해 재캡처 필요`,
    };
  }
  if (!carriesComponentProps(current.schema)) {
    return {
      ran: false,
      why:
        current.capturedBy === CAPTURED_BY_PLUGIN
          ? `이번 캡처가 schema ${current.schema} 형태라 프로퍼티 정보 없음 — 플러그인을 main 에서 다시 빌드해 재캡처 필요`
          : `이번 캡처(${current.capturedBy})는 프로퍼티 정의를 읽지 못한다 — 플러그인 "구조 → .json" 으로 재캡처 필요`,
    };
  }
  return { ran: true };
}

/**
 * 표시 이름으로 접은 프로퍼티 색인. 같은 이름이 둘이면 두 번째부터 `(2)` 를 붙인다 —
 * 하나로 덮으면 한쪽 정의가 비교에서 조용히 사라진다.
 */
function propIndex(props: SnapshotProp[]): Map<string, SnapshotProp> {
  const index = new Map<string, SnapshotProp>();
  const seen = new Map<string, number>();
  for (const prop of props) {
    const name = propDisplayName(prop.key);
    const n = (seen.get(name) ?? 0) + 1;
    seen.set(name, n);
    index.set(n === 1 ? name : `${name} (${n})`, prop);
  }
  return index;
}

function fmtPropDefault(prop: SnapshotProp): string {
  return typeof prop.default === 'string' ? JSON.stringify(prop.default) : String(prop.default);
}

function fmtPropOptions(prop: SnapshotProp): string {
  return prop.options === undefined ? '—' : `[${prop.options.join(', ')}]`;
}

/** 정의 한 줄 — 추가·삭제 행이 그 프로퍼티가 무엇이었는지 한 칸에 말한다. */
function fmtPropDef(prop: SnapshotProp): string {
  const opts = prop.options === undefined ? '' : ` · ${fmtPropOptions(prop)}`;
  return `${prop.type} · ${fmtPropDefault(prop)}${opts}`;
}

/** 원본 참조를 사람이 찾을 수 있는 모양으로 — 파일 안에 있으면 이름까지. */
function fmtMain(id: string, before: Map<string, Located>, after: Map<string, Located>): string {
  const hit = after.get(id) ?? before.get(id);
  return hit === undefined ? id : `${hit.node.name} (${id})`;
}

function comparePropsAndMain(
  was: Located,
  now: Located,
  before: Map<string, Located>,
  after: Map<string, Located>,
  diff: StructureDiff,
): void {
  // 두 쪽 모두 소유 노드일 때만 정의를 비교한다. 한쪽만 소유 노드면 그건 타입이
  // 바뀌었거나(프레임 → 컴포넌트) 세트에 넣고 뺀 것이라 이미 다른 칸이 말한다 —
  // 여기서 모든 정의를 추가/삭제로 또 세면 한 사건이 두 번 보고된다.
  if (was.node.props !== undefined && now.node.props !== undefined) {
    if (was.node.props === null || now.node.props === null) {
      diff.propsNotComparable += 1;
    } else {
      const a = propIndex(was.node.props);
      const b = propIndex(now.node.props);
      for (const [name, prop] of b) {
        const old = a.get(name);
        if (old === undefined) {
          diff.propAdded.push({ at: now, prop: name, before: '—', after: fmtPropDef(prop) });
          continue;
        }
        if (old.type !== prop.type) {
          // 타입이 바뀌면 기본값과 옵션의 의미도 바뀐다 — 그 둘을 따로 세지 않는다.
          diff.propRetyped.push({ at: now, prop: name, before: old.type, after: prop.type });
          continue;
        }
        if (fmtPropDefault(old) !== fmtPropDefault(prop)) {
          diff.propDefaultChanged.push({
            at: now,
            prop: name,
            before: fmtPropDefault(old),
            after: fmtPropDefault(prop),
          });
        }
        if (fmtPropOptions(old) !== fmtPropOptions(prop)) {
          diff.propOptionsChanged.push({
            at: now,
            prop: name,
            before: fmtPropOptions(old),
            after: fmtPropOptions(prop),
          });
        }
      }
      for (const [name, prop] of a) {
        if (!b.has(name)) {
          diff.propRemoved.push({ at: now, prop: name, before: fmtPropDef(prop), after: '—' });
        }
      }
    }
  }

  if (was.node.main !== undefined && now.node.main !== undefined) {
    if (was.node.main === null || now.node.main === null) {
      diff.mainNotComparable += 1;
    } else if (was.node.main !== now.node.main) {
      diff.mainChanged.push({
        at: now,
        before: fmtMain(was.node.main, before, after),
        after: fmtMain(now.node.main, before, after),
      });
    }
  }
}

function changeCount(diff: StructureDiff): number {
  return (
    diff.added.length +
    diff.removed.length +
    diff.renamed.length +
    diff.retyped.length +
    diff.repaged.length +
    diff.moved.length +
    diff.resized.length +
    diff.propAdded.length +
    diff.propRemoved.length +
    diff.propRetyped.length +
    diff.propDefaultChanged.length +
    diff.propOptionsChanged.length +
    diff.mainChanged.length
  );
}

/** 이름 비교용 정규화 — `Aspect Ratio Box` 와 `aspect_ratio_box` 를 같게 본다. */
function normaliseName(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '');
}

/**
 * 코드 대조가 **실제로 돌았는지**까지 들고 다닌다.
 *
 * 이름 목록만 넘기면 "대조했는데 없었다" 와 "대조 자체를 못 했다" 가 똑같이
 * 빈 배열이 되고, 리포트에서는 똑같이 **절이 없는 상태**로 나타난다. 그러면
 * 입력이 빠진 실행이 완전한 실행보다 더 깨끗해 보인다.
 */
type CodeCrossCheck =
  | { ran: true; keyCount: number; unknown: string[] }
  | { ran: false; why: string };

/**
 * 코드가 모르는 이름을 **정보성으로만** 보고한다. 휴리스틱이라 여기서의 누락도
 * 오탐도 실패가 아니다 — Figma 의 이름 규칙은 코드의 컴포넌트 키와 일치할
 * 의무가 없기 때문이다.
 */
function unknownToCode(current: Snapshot, codeKeys: Set<string>): string[] {
  const out = new Set<string>();
  for (const page of current.pages) {
    for (const node of page.nodes) {
      if (node.depth === 0 || node.depth > COMPONENT_ROOT_MAX_DEPTH) continue;
      if (node.name === '') continue;
      if (!codeKeys.has(normaliseName(node.name))) out.add(node.name);
    }
  }
  return [...out].sort();
}

function table(header: string[], rows: string[][]): string {
  const shown = rows.slice(0, MAX_TABLE_ROWS);
  const lines = [
    `| ${header.join(' | ')} |`,
    `| ${header.map(() => '---').join(' | ')} |`,
    ...shown.map((r) => `| ${r.join(' | ')} |`),
  ];
  if (rows.length > shown.length) {
    // 몇 행을 감췄는지 반드시 말한다.
    lines.push('');
    lines.push(truncationNotice(shown.length, rows.length));
  }
  return lines.join('\n');
}

/**
 * 배너에 나열하는 페이지 이름의 **개수** 상한.
 *
 * 이 목록은 파일의 페이지 수에 비례해 자란다 — 헤드에 실려 예산 밖에 있으므로,
 * 상한이 없으면 페이지가 많은 파일에서 배너 하나가 리포트의 자리를 먹는다.
 */
const MAX_LISTED_PAGES = 20;

/** 페이지를 `이름 (id)` 로 나열하되, 길면 나머지는 수로만 말한다. */
function listPages(pages: PageRef[]): string {
  const shown = pages.slice(0, MAX_LISTED_PAGES);
  const rendered = shown.map((p) => `\`${brief(p.name)} (${p.id})\``).join(' · ');
  return pages.length > shown.length
    ? `${rendered} 외 ${pages.length - shown.length}개`
    : rendered;
}

/**
 * 노드 id 를 Figma 딥링크로 만든다.
 *
 * 이 한 줄이 리포트에서 가장 값이 큰 부분이다 — 링크가 없으면 읽는 사람은
 * `12:999` 를 들고 Figma 를 열어 페이지를 뒤져야 하고, 그 마찰이 리포트를
 * 안 읽게 만든다. 링크가 있으면 모든 행이 한 번의 클릭이 된다.
 */
function nodeLink(fileUrl: string, id: string): string {
  // 딥링크의 node-id 는 `:` 대신 `-` 를 쓴다.
  return `[${cell(id)}](${fileUrl}?node-id=${id.replace(/:/g, '-')})`;
}

/**
 * 리포트를 세 덩이로 나눈다.
 *
 * - `head` — 이 리포트가 **무엇에 대한 주장인지**를 좁히는 문장들(범위 · 캡처 시각 ·
 *   확인되지 않은 파일 키 · 볼 수 없는 축 · 요약 건수 · 코드 대조 여부). 예산 밖이다.
 * - `body` — 발견의 **증거**인 표들. 예산 안에서만 실린다.
 * - `tail` — 잘렸다는 사실과 다음 행동. 예산 밖이다.
 *
 * 왜 이 순서로 나누는가: 예산이 모자랄 때 무엇을 버릴지가 곧 이 리포트가 무엇을
 * 위해 존재하는지에 대한 답이다. 증거의 일부를 잃는 것은 회복 가능하다 — 요약의
 * 건수가 남아 있고 캡처를 다시 뜰 수 있다. 반면 범위를 좁히는 문장을 잃으면
 * 남은 표가 **전부인 것처럼** 읽히고, 그 오독은 리포트 안에서 고칠 수 없다.
 */
function renderMarkdown(
  diff: StructureDiff,
  capture: Capture,
  code: CodeCrossCheck,
  config: Config,
  provisional: boolean,
  absentPages: AbsentPage[],
): string {
  const current = capture.snapshot;
  const total = changeCount(diff);
  const base = config.fileUrl.split('?')[0];
  const link = (id: string): string => nodeLink(base, id);
  const narrowed = capture.outOfScope.length > 0;

  const out: string[] = [];
  out.push('# Figma 구조 드리프트 (Channel A)');
  out.push('');
  // 범위를 좁혀 걸었다면 그 사실이 **헤드라인 안에** 있어야 한다. "페이지 1개를
  // 대조했다" 만 있으면 파일에 페이지가 하나인 것으로 읽히고, 그 오독 위에서
  // 나머지 표를 읽게 된다.
  const scanned =
    `노드 ${current.nodeCount}개, 페이지 ${current.pages.length}개를 대조했다` +
    (narrowed ? ` (파일의 페이지 ${capture.inFile.length}개 중 ${current.pages.length}개만 — config.pages 로 좁혔다)` : '');
  // 헤드라인이 **본 축만** 이름으로 말한다. 프로퍼티를 비교하지 않은 실행이
  // "프로퍼티 변화 없음" 을 주장하면, 그 축의 편집이 조용히 0 으로 나가던 결함이
  // 문장 하나로 되살아난다.
  const axes = diff.propsCompared.ran ? '구조·기하·프로퍼티' : '구조·기하';
  out.push(
    total === 0
      ? `✅ ${axes} 변화 없음 — ${scanned}.`
      : `⚠️ ${total}건의 ${axes} 변화 — ${scanned}.`,
  );
  out.push('');

  if (!diff.propsCompared.ran) {
    out.push(
      `⚠️ **컴포넌트 프로퍼티 정의와 인스턴스의 원본 참조는 비교하지 않았다** — ${brief(diff.propsCompared.why)}. ` +
        '그래서 세트에 프로퍼티만 더하거나 바꾼 편집(기하 변화 0)은 이 리포트에 나타나지 않는다. ' +
        '이 리포트의 "변화 없음"은 프로퍼티에 대한 진술이 아니다.',
    );
    out.push('');
  }

  if (narrowed) {
    out.push(
      `⚠️ **이 실행은 파일의 일부만 걸었다.** \`config.pages\` 가 아래 페이지를 범위 밖에 뒀다: ` +
        `${listPages(capture.outOfScope)}. ` +
        `**베이스라인에서 이미 그 페이지에 있던** 노드 ${diff.notCompared.length}개는 ` +
        '삭제가 아니라 "비교하지 않음" 으로 세었다. ' +
        '이 리포트의 "변화 없음"은 범위 밖 페이지에 대한 진술이 아니다.',
    );
    out.push('');

    // 위 문장이 덮지 못하는 자리를 여기서 말한다.
    //
    // "비교하지 않음" 으로 갈리는 기준은 그 노드가 **베이스라인에서** 어느 페이지에
    // 있었는가다. 걷는 페이지에 있던 노드가 걷지 않는 페이지로 **옮겨가면** 이번
    // 캡처에서 사라지고, 옮겨간 곳을 읽지 않았으므로 옮겨갔다는 증거가 이 실행에
    // 존재하지 않는다 — 그 노드는 삭제로 세어진다.
    //
    // 판정할 수 없는 것을 판정하지 않고 읽는 사람이 그 갈림길을 보게 한다. 목록에서
    // 사라진 페이지를 다루는 방식과 같다: 두 원인이 같은 입력을 만들 때 이 스크립트가
    // 할 수 있는 일은 어느 쪽인지 고르는 것이 아니라 둘 다 말하는 것이다.
    if (diff.removed.length > 0) {
      out.push(
        `⚠️ 그래서 아래 **삭제된 노드 ${diff.removed.length}개는 범위 밖 페이지로 옮겨간 것일 수 있다** — ` +
          '옮겨간 페이지를 걷지 않았으므로 이번 캡처에는 그 노드가 어디에도 없고, ' +
          '지워진 것과 구별할 방법이 이 입력에는 없다. ' +
          '지운 적이 없다면 `config.pages` 를 비우고 전체를 걸어 다시 확인하라.',
      );
      out.push('');
    }
  }

  // 목록에서 사라진 페이지는 **삭제로 세어졌다.** 그 셈이 맞는지 이 스크립트는
  // 알 수 없다 — 페이지 XML 과 달리 `pages.txt` 에는 잘림을 알려주는 종결자가
  // 없어서, 디자이너가 지운 것과 응답이 중간에서 끊긴 것이 같은 입력으로 온다.
  // 판정할 수 없는 것을 판정하지 않고, 대신 **읽는 사람이 그 갈림길을 보게** 한다.
  if (absentPages.length > 0) {
    const lostNodes = absentPages.reduce((n, a) => n + a.nodes, 0);
    out.push(
      `⚠️ **베이스라인의 페이지 ${absentPages.length}개가 이번 \`pages.txt\` 에 없다**: ` +
        `${listPages(absentPages.map((a) => a.page))}. ` +
        `그 페이지에 있던 노드 ${lostNodes}개는 아래에서 **삭제로 세었다**. ` +
        '하지만 페이지가 실제로 지워진 것과 페이지 목록이 중간에서 잘린 것은 이 입력만으로 구별되지 않는다 — ' +
        '페이지 XML 은 루트를 닫는 태그로 잘림을 판정하지만 목록에는 그런 종결자가 없다. ' +
        '지운 적이 없다면 이 리포트를 버리고 캡처를 다시 떠라.',
    );
    out.push('');
  }

  if (provisional) {
    out.push(
      `⚠️ 이 실행은 \`--allow-provisional\` 로 돌았다 — \`fileKeyStatus\` 값이 ` +
        `\`${FILE_KEY_CONFIRMED}\` 가 아니다(\`${brief(config.fileKeyStatus)}\`). ` +
        '**이 파일이 정본 라이브러리라는 확인이 없다.** 엉뚱한 파일을 기준으로 세운 ' +
        '비교는 형식상 멀쩡해 보이므로, 이 리포트를 드리프트의 근거로 쓰지 마라.',
    );
    out.push('');
  }

  out.push(
    '> 이 리포트가 비교하는 축은 **name · type · 소속 페이지 · x/y/width/height**' +
      (diff.propsCompared.ran
        ? ' 와 **컴포넌트 프로퍼티 정의(추가·삭제·타입·기본값·옵션) · 인스턴스의 원본 참조**' +
          ' 뿐이다(매칭 키는 id, 프로퍼티는 `#<id>` 접미사를 접은 표시 이름). '
        : ' 뿐이다(매칭 키는 id). ') +
      '한 페이지 안에서의 부모 변경은 비교하지 않는다. ' +
      '색 · 토큰 바인딩 · 타이포 · radius · shadow 는 헤드리스로 읽을 수 없어 ' +
      '여기에 없다 — 그 축은 Channel B(fidelity)가 답한다. ' +
      '"변화 없음"을 시각적 동일성으로 읽지 마라.',
  );
  out.push('');

  out.push(ageNote(current.capturedAt, CAPTURE_AGE));
  out.push('');

  out.push('## 요약');
  out.push('');
  out.push(
    table(
      ['변화', '건수'],
      [
        ['추가(added)', String(diff.added.length)],
        ['삭제(removed)', String(diff.removed.length)],
        ['이름 변경(renamed)', String(diff.renamed.length)],
        ['타입 변경(retyped)', String(diff.retyped.length)],
        ['페이지 이동(repaged)', String(diff.repaged.length)],
        ['이동(moved)', String(diff.moved.length)],
        ['크기 변경(resized)', String(diff.resized.length)],
        ['범위 밖 — 비교 안 함', String(diff.notCompared.length)],
        ['기하 비교 불가', String(diff.geometryNotComparable)],
        // 세지 않은 축을 0 으로 적지 않는다 — 0 은 "봤는데 없었다" 는 주장이다.
        ...(
          [
            ['프로퍼티 추가', diff.propAdded.length],
            ['프로퍼티 삭제', diff.propRemoved.length],
            ['프로퍼티 타입 변경', diff.propRetyped.length],
            ['프로퍼티 기본값 변경', diff.propDefaultChanged.length],
            ['프로퍼티 옵션 변경', diff.propOptionsChanged.length],
            ['인스턴스 원본 변경', diff.mainChanged.length],
            ['프로퍼티 비교 불가', diff.propsNotComparable],
            ['인스턴스 원본 비교 불가', diff.mainNotComparable],
          ] as [string, number][]
        ).map(([label, n]) => [label, diff.propsCompared.ran ? String(n) : '비교 안 함']),
      ],
    ),
  );
  out.push('');

  if (diff.propsNotComparable > 0 || diff.mainNotComparable > 0) {
    out.push(
      `_프로퍼티 비교 불가 ${diff.propsNotComparable}건 · 인스턴스 원본 비교 불가 ${diff.mainNotComparable}건: ` +
        '한쪽 캡처가 정의나 원본을 읽지 못해(`null`) 변화를 주장하지 않았다. 읽지 못한 것과 없는 것은 다른 주장이다._',
    );
    out.push('');
  }

  if (diff.geometryNotComparable > 0) {
    out.push(
      `_기하 비교 불가 ${diff.geometryNotComparable}건: 한쪽에 x/y/width/height 속성이 없어 ` +
        '이동·크기 변경을 주장하지 않았다. 값이 없는 것과 0 은 다른 주장이다._',
    );
    out.push('');
  }

  // 프로퍼티 표를 앞에 둔다. 예산은 앞에서부터 채워지고, 이 표들은 드물고 작으며
  // 기하 표가 대신 말해 줄 수 없는 유일한 증거다 — 기하가 그대로인 편집이기 때문이다.
  const propRows = (rows: PropChange[]): string[][] =>
    rows.map((r) => [
      link(r.at.node.id),
      cell(fmtPage(r.at)),
      cell(r.at.node.name),
      cell(r.prop),
      `${cell(r.before)} → ${cell(r.after)}`,
    ]);
  const propHeader = ['id', '페이지', '컴포넌트', '프로퍼티', 'before → after'];
  const sections: [string, string[], string[][]][] = [
    ['프로퍼티가 추가된 컴포넌트', propHeader, propRows(diff.propAdded)],
    ['프로퍼티가 삭제된 컴포넌트', propHeader, propRows(diff.propRemoved)],
    ['프로퍼티 타입이 바뀐 컴포넌트', propHeader, propRows(diff.propRetyped)],
    ['프로퍼티 기본값이 바뀐 컴포넌트', propHeader, propRows(diff.propDefaultChanged)],
    ['프로퍼티 옵션이 바뀐 컴포넌트', propHeader, propRows(diff.propOptionsChanged)],
    [
      '추가된 노드',
      ['id', '페이지', 'name', 'type', '위치·크기'],
      diff.added.map((a) => [
        link(a.node.id),
        cell(fmtPage(a)),
        cell(a.node.name),
        cell(a.node.type),
        `(${fmtNum(a.node.x)}, ${fmtNum(a.node.y)}) ${fmtNum(a.node.w)}×${fmtNum(a.node.h)}`,
      ]),
    ],
    [
      '삭제된 노드',
      ['id', '페이지', 'name', 'type', '직전 위치·크기'],
      diff.removed.map((a) => [
        link(a.node.id),
        cell(fmtPage(a)),
        cell(a.node.name),
        cell(a.node.type),
        `(${fmtNum(a.node.x)}, ${fmtNum(a.node.y)}) ${fmtNum(a.node.w)}×${fmtNum(a.node.h)}`,
      ]),
    ],
    [
      '이름이 바뀐 노드',
      ['id', '페이지', 'type', 'before → after'],
      diff.renamed.map((r) => [
        link(r.at.node.id),
        cell(fmtPage(r.at)),
        cell(r.at.node.type),
        `${cell(r.before)} → ${cell(r.after)}`,
      ]),
    ],
    [
      '타입이 바뀐 노드',
      ['id', '페이지', 'name', 'before → after'],
      diff.retyped.map((r) => [
        link(r.at.node.id),
        cell(fmtPage(r.at)),
        cell(r.at.node.name),
        `${cell(r.before)} → ${cell(r.after)}`,
      ]),
    ],
    [
      '페이지를 옮긴 노드',
      ['id', 'name', 'before → after'],
      diff.repaged.map((r) => [
        link(r.at.node.id),
        cell(r.at.node.name),
        `${cell(r.before)} → ${cell(r.after)}`,
      ]),
    ],
    [
      '이동한 노드',
      ['id', '페이지', 'name', 'before → after'],
      diff.moved.map((r) => [
        link(r.at.node.id),
        cell(fmtPage(r.at)),
        cell(r.at.node.name),
        `${r.before} → ${r.after}`,
      ]),
    ],
    [
      '크기가 바뀐 노드',
      ['id', '페이지', 'name', 'before → after'],
      diff.resized.map((r) => [
        link(r.at.node.id),
        cell(fmtPage(r.at)),
        cell(r.at.node.name),
        `${r.before} → ${r.after}`,
      ]),
    ],
    [
      '원본이 바뀐 인스턴스',
      ['id', '페이지', 'name', 'before → after'],
      diff.mainChanged.map((r) => [
        link(r.at.node.id),
        cell(fmtPage(r.at)),
        cell(r.at.node.name),
        `${cell(r.before)} → ${cell(r.after)}`,
      ]),
    ],
  ];

  // 코드 대조의 **상태**는 head 에 남는다 — 예산 밖이다. 이 사실을 stderr 로만
  // 말하면 이슈 본문에 흔적이 남지 않고, 절이 통째로 빠진 리포트는 "코드가 모르는
  // 이름이 없었다" 로 읽힌다 — 입력이 빠진 실행이 완전한 실행보다 깨끗해 보인다.
  // 예산에 밀려 표가 빠졌을 때도 같은 오독이 생기므로, 대조했는지 여부와 몇 건인지는
  // 표와 분리해 여기 둔다.
  if (!code.ran) {
    out.push(
      `⚠️ 이번 실행은 \`${CODE_COMPONENTS}\` 를 읽지 못해 코드 대조를 **하지 않았다** (${brief(code.why)}). ` +
        '이 리포트에 모르는 이름이 없는 것은 모르는 이름이 없다는 뜻이 아니라 **아무도 확인하지 않았다**는 뜻이다. ' +
        '검사되지 않은 것은 이상 없음이 아니다.',
    );
    out.push('');
  } else if (code.unknown.length === 0) {
    out.push(
      `_코드 대조: \`${CODE_COMPONENTS}\` 의 컴포넌트 키 ${code.keyCount}개와 대조했고 모르는 이름은 없었다._`,
    );
    out.push('');
  } else {
    out.push(
      `_코드 대조: \`${CODE_COMPONENTS}\` 의 컴포넌트 키 ${code.keyCount}개와 대조해 ` +
        `모르는 이름 ${code.unknown.length}개를 찾았다 — 아래 표._`,
    );
    out.push('');
  }

  // ── 여기부터가 증거다 — 예산 안에서만 실린다 ──────────────────────────────
  const body: string[] = [];
  for (const [title, header, rows] of sections) {
    if (rows.length === 0) continue;
    body.push([`## ${title} (${rows.length})`, '', table(header, rows)].join('\n'));
  }

  if (code.ran && code.unknown.length > 0) {
    body.push(
      [
        `## 코드가 모르는 이름 (${code.unknown.length}) — 휴리스틱, 정보성`,
        '',
        `아래 이름은 \`${CODE_COMPONENTS}\` 의 컴포넌트 키 ${code.keyCount}개와 매칭되지 않았다. ` +
          'Figma 의 이름 규칙은 코드 키와 일치할 의무가 없으므로 **여기 뜬 것이 곧 결함은 아니다** — ' +
          '신규 컴포넌트를 디자이너가 먼저 그렸을 때 알아채기 위한 신호일 뿐이다.',
        '',
        table(['이름'], code.unknown.map((n) => [cell(n)])),
      ].join('\n'),
    );
  }

  // 리포트가 무엇을 보라고만 하고 무엇을 하라고 말하지 않으면, 읽는 사람이
  // 매번 같은 판단 경로를 처음부터 다시 세운다.
  const tail: string[] = [];
  if (total > 0) {
    tail.push('## 이제 무엇을 하나');
    tail.push('');
    tail.push(
      '- **이 변경을 수용한다** — `npm run reverse:diff -- --snapshot=<file> --update-baseline` (MCP 캡처면 `--raw-dir=<dir>`) ' +
        '으로 베이스라인을 옮기고 커밋한다. 커밋 메시지에 무엇에 동의했는지 남긴다.',
    );
    tail.push(
      '- **회귀다** — 해당 컴포넌트 이슈를 연다. 위 표의 행을 그대로 붙이면 어느 노드인지 특정된다.',
    );
    tail.push(
      '- **Figma 가 코드보다 앞서 있다** — 디자이너가 먼저 그린 것이다. 코드로 가져오는 작업을 잡는다.',
    );
    tail.push('');
  }

  // ── 바이트 예산 ─────────────────────────────────────────────────────────
  // 행 상한(표마다 50 행)은 셀 내용이 좁을 때만 맞는 근사다. 이 리포트의 한 행에는
  // 딥링크 URL 과 레이어 이름이 들어가고, 한글은 한 글자가 3 바이트다. 실측:
  // 6 페이지 · 1,200 노드가 59,518 바이트, 표 일곱 개가 전부 찬 캡처가 67,341 바이트
  // — 후자는 이슈 본문 상한(65,536)을 혼자서 넘긴다. 그 본문이 이 발견들이 사람에게
  // 닿는 유일한 경로라, 넘기는 순간 **결함이 많을수록 아무것도 못 보게 된다**.
  //
  // head 와 tail 은 예산에서 **빼고 시작한다** — 둘은 잘리지 않기 때문이다. 그래서
  // 예산이 지배하는 것은 증거 표뿐이고, 리포트의 범위를 좁히는 문장은 언제나 남는다.
  // 그 뺄셈은 `evidenceBudget` 한 곳에서 한다: 두 채널이 같은 규율을 각자 계산하면
  // 한쪽이 무언가를 빼먹고, 빼먹은 쪽은 자기 예산 안에 있다고 믿으면서 상대의 몫을
  // 먹는다 — 실제로 Channel B 가 그렇게 됐다.
  //
  // 잘렸다는 문장도 같이 뺀다. 그것을 예산 **안에서** 쓰려 하면 예산이 바닥난 바로
  // 그때 이 문장부터 사라져 조용한 잘림이 되고, 아무 데서도 빼지 않으면 문서가
  // 예산을 넘는다 — 두 실패 다 이 예산이 막으려던 것이다. 그래서 아직 몇 개를 못
  // 실을지 모르는 시점에 **최악(전부 생략)** 기준으로 자리를 잡아둔다. 실제로는
  // 그보다 적거나 아예 안 쓰이고, 남은 자리는 문서를 줄일 뿐이다.
  //
  // 행 상한과 바이트 예산이 **다른 한도**라는 것을 문장이 직접 말한다. 둘 다
  // "잘렸다" 로만 적으면 읽는 사람이 표 아래의 행 잘림 문구를 보고 그게 전부라고 읽는다.
  const omissionNotice = (omitted: number): string =>
    `⚠️ **이 리포트는 바이트 예산에서 잘렸다** — 표 ${omitted}개를 통째로 싣지 못했다 ` +
    `(Channel A 몫 ${CHANNEL_A_BUDGET_BYTES} 바이트. 이슈 본문 상한을 Channel B 와 나눠 쓴다). ` +
    '표 안의 **행 상한과는 다른 한도**다 — 행 상한은 표마다 몇 행을 감췄는지 그 표 아래에 적고, ' +
    '이 문장은 **표 자체가 빠진 것**을 말한다. ' +
    '위 요약의 건수는 예산과 무관하게 전부 세어진 값이라, 빠진 표의 건수도 거기 들어 있다. ' +
    '전부 보려면 `--json-out` 으로 같은 실행의 스냅샷을 받아라.';

  const fitted = fitToBudget(
    body,
    evidenceBudget(
      CHANNEL_A_BUDGET_BYTES,
      out,
      tail,
      body.length > 0 ? omissionNotice(body.length) : '',
    ),
  );

  if (fitted.text !== '') {
    out.push(fitted.text);
    out.push('');
  }

  if (fitted.omittedSections > 0) {
    out.push(omissionNotice(fitted.omittedSections));
    out.push('');
  }

  for (const line of tail) out.push(line);

  return out.join('\n');
}

function main(): never {
  if (hasFlag('--help') || hasFlag('-h')) {
    console.log(
      'Usage: tsx reverse/diff_structure.ts (--raw-dir=<dir> | --snapshot=<file>) [--baseline=<path>]\n' +
        '                                    [--config=<path>] [--out=<md>]\n' +
        '                                    [--json-out=<path>] [--update-baseline]\n' +
        '                                    [--allow-provisional]\n' +
        '\n' +
        'Exit: 0 변화 없음 · 1 변화 있음 · 2 인프라 실패',
    );
    return process.exit(EXIT_NO_DIFF);
  }

  const cwd = process.cwd();
  const rawDir = resolve(cwd, argValue('--raw-dir') ?? DEFAULT_RAW_DIR);
  const baselinePath = resolve(cwd, argValue('--baseline') ?? DEFAULT_BASELINE);
  const configPath = resolve(cwd, argValue('--config') ?? DEFAULT_CONFIG);

  const config = readConfig(configPath);

  // ── 안전 인터록 ──────────────────────────────────────────────────────────
  // 파일 키가 정본이라는 것은 코드가 판정할 수 없고 사람만 판정할 수 있다.
  // 확인되지 않은 키는 엉뚱한 파일을 가리킬 수 있고, 그 파일의 구조는
  // 베이스라인과 전부 다르므로 "디자이너가 모든 것을 바꿨다" 는 거대한 거짓
  // 리포트가 나온다. 그 리포트는 틀렸다는 것조차 읽어봐야 알 수 있어서, 한 번
  // 겪은 사람은 다음 리포트도 안 읽는다. 그래서 이 판정이 파일에 기록되기
  // 전까지 걷지 않는다 — 지시문이 아니라 이 자리에서 막는다.
  const provisional = config.fileKeyStatus !== FILE_KEY_CONFIRMED;
  if (provisional && !hasFlag('--allow-provisional')) {
    fail(
      `fileKeyStatus 가 "${FILE_KEY_CONFIRMED}" 가 아님: "${config.fileKeyStatus}" (${configPath})`,
      '확인되지 않은 키는 엉뚱한 파일을 가리킬 수 있고, 그 위에 세운 베이스라인은 이후의 모든 리포트를 조용히 무의미하게 만든다',
      `디자이너가 ${config.fileKey} 가 정본 라이브러리 파일임을 확인한 뒤 fileKeyStatus 를 "${FILE_KEY_CONFIRMED}" 로 바꿔라. 부트스트랩 중이라 알면서 진행하는 것이면 --allow-provisional 을 붙여라`,
    );
  }
  if (provisional) {
    console.error(
      `⚠️  fileKeyStatus 가 "${config.fileKeyStatus}" 인데 --allow-provisional 로 진행한다 — 이 리포트는 정본 파일에 대한 주장이 아니다.`,
    );
  }

  const baseline = readSnapshot(baselinePath, 'baseline.structure.json');

  const snapshotArg = argValue('--snapshot');
  if (snapshotArg !== null && argValue('--raw-dir') !== null) {
    fail(
      '--snapshot 과 --raw-dir 을 같이 줬다',
      '두 입력은 다른 캡처 경로이고 하나의 비교는 하나의 캡처에 대한 진술이다 — 둘을 합치면 어느 쪽이 이번 주기의 답인지 알 수 없다',
      '둘 중 하나만 남겨라',
    );
  }
  const capture =
    snapshotArg !== null
      ? buildSnapshotFromFile(resolve(cwd, snapshotArg), config)
      : buildSnapshot(rawDir, config);
  const current = capture.snapshot;

  if (snapshotArg !== null) {
    // 스냅샷 파일이 든 파일 키는 설정과 같아야 한다 — 다른 파일에서 내려받은
    // 스냅샷을 정본 베이스라인과 비교하면 그 차이가 전부 디자이너의 변경으로 나간다.
    const snapKey = readSnapshot(resolve(cwd, snapshotArg), '스냅샷 파일').fileKey;
    if (snapKey !== null && snapKey !== config.fileKey) {
      fail(
        `스냅샷 파일이 다른 파일에서 왔다 — 스냅샷 ${JSON.stringify(snapKey)} vs 설정 ${JSON.stringify(config.fileKey)}`,
        '다른 파일끼리 비교하면 그 차이가 전부 디자이너의 변경으로 보고되고, 리포트만 봐서는 틀렸다는 것을 알 수 없다',
        '정본 라이브러리 파일에서 "구조 → .json" 을 다시 실행하라',
      );
    }
  }

  // 캡처 경로가 바뀌면 타입 어휘·좌표 반올림이 같다는 보장이 없다 — 그 차이가
  // 전부 retyped/moved 로 나가면 리포트가 통째로 소음이 된다. 전환은 명시적으로.
  const baselineEmptyForPath = baseline.nodeCount === 0 && baseline.pages.length === 0;
  if (
    !baselineEmptyForPath &&
    baseline.capturedBy !== current.capturedBy &&
    !hasFlag('--update-baseline')
  ) {
    fail(
      `베이스라인과 캡처의 경로가 다름 — 베이스라인 ${JSON.stringify(baseline.capturedBy)} vs 이번 캡처 ${JSON.stringify(current.capturedBy)}`,
      '다른 경로의 캡처는 타입 어휘와 반올림이 다를 수 있어, 그 차이가 전부 디자이너의 변경으로 보고된다',
      '이 캡처를 새 기준으로 삼는 것이 맞다면 --update-baseline 으로 베이스라인을 옮겨라 (그 실행의 diff 는 경로 전환 소음이므로 판정에 쓰지 않는다)',
    );
  }
  const outOfScopePages = new Set(capture.outOfScope.map((p) => p.id));

  /**
   * 부분 스코프로 베이스라인을 덮으면 범위 밖 페이지가 베이스라인에서 **사라진다**.
   * 그러면 다음 전체 실행이 그 페이지 전부를 "추가됨" 으로 보고하고, 그 리포트는
   * 형식상 멀쩡해서 틀렸다는 것을 알 방법이 없다 — 커밋된 데이터를 잃는 쪽이라
   * 되돌리기도 어렵다. 거부는 **실제로 잃을 것이 있을 때만** 한다: 베이스라인에
   * 아직 없는 페이지라면 덮어도 잃는 것이 없고, 좁힌 범위를 계속 쓰는 운영도
   * 막지 않아야 한다.
   */
  function refuseIfBaselineWouldLosePages(): void {
    const lost = baseline.pages.filter((p) => outOfScopePages.has(p.id));
    if (lost.length === 0) return;
    fail(
      `부분 스코프로는 베이스라인을 덮을 수 없음 — 범위 밖이라 이번에 걷지 않은 페이지가 베이스라인에 ${lost.length}개 있다: ${lost.map((p) => `${p.name} (${p.id})`).join(', ')}`,
      '덮으면 그 페이지가 베이스라인에서 사라지고, 다음 전체 실행이 그것들을 전부 "추가됨" 으로 보고한다 — 커밋된 기준을 잃는 쪽이라 리포트만 봐서는 알 수 없다',
      'config.pages 를 null 로 두고 전체를 걸어 갱신하거나, 그 페이지들을 정말로 범위에서 빼는 것이면 베이스라인에서 먼저 지워라',
    );
  }

  // ── 첫 실행 ──────────────────────────────────────────────────────────────
  // 베이스라인이 비어 있으면 이번 실행이 그것을 세운다. 전 노드를 "추가됨" 으로
  // 보고하면 첫 리포트가 수천 행짜리 소음이 되고, 그 소음은 다음 리포트까지
  // 불신하게 만든다.
  const baselineEmpty = baseline.nodeCount === 0 && baseline.pages.length === 0;
  if (baselineEmpty) {
    console.log(
      `ℹ️  베이스라인이 비어 있다 — 이번 실행이 베이스라인을 세운다.\n` +
        `   읽은 노드: ${current.nodeCount} (페이지 ${current.pages.length}개)\n` +
        (hasFlag('--update-baseline')
          ? `   --update-baseline 이 주어져 ${baselinePath} 에 기록한다.`
          : `   기록하려면 --update-baseline 을 붙여 다시 실행하라.`),
    );
    if (hasFlag('--update-baseline')) {
      refuseIfBaselineWouldLosePages();
      writeOut(baselinePath, serialiseSnapshot(current), '베이스라인');
    }
    return process.exit(EXIT_NO_DIFF);
  }

  // ── 같은 파일을 보고 있는가 ──────────────────────────────────────────────
  // 두 스냅샷 모두 어느 파일에서 왔는지 들고 있으면서 대조하지 않으면, 다른
  // 파일끼리의 diff 가 디자이너의 드리프트로 보고된다. 그 리포트는 형식상
  // 멀쩡해서 읽는 사람이 알아챌 방법이 없다.
  if (baseline.fileKey !== current.fileKey) {
    fail(
      `베이스라인과 설정이 서로 다른 파일을 가리킴 — 베이스라인 ${JSON.stringify(baseline.fileKey)} vs 설정 ${JSON.stringify(current.fileKey)}`,
      '다른 파일끼리 비교하면 그 차이가 전부 디자이너의 변경으로 보고되고, 리포트만 봐서는 틀렸다는 것을 알 수 없다',
      '설정의 fileKey 를 되돌리거나, 이 파일을 기준으로 삼는 게 맞다면 --update-baseline 으로 베이스라인을 새로 세워라',
    );
  }

  // ── 모집단 하한 ──────────────────────────────────────────────────────────
  // check_figma_export_fresh.sh 의 FLOOR_BYTES 와 같은 방어다. 그 가드의 논리:
  // 추출이 붕괴해 결과가 텅 비면 diff 가 작아 보여 "변화 없음" 으로 조용히
  // 통과한다. 여기서는 더 나쁘게 나타난다 — 붕괴한 캡처는 살아있는 노드
  // 전부를 "삭제됨" 으로 보고해서, 진짜 대량 삭제와 글자 그대로 구별되지
  // 않는다. 그래서 리포트를 만들기 전에 거부한다.
  //
  // 하한은 **베이스라인 × ratio 그 값** 이고, 그 값 **미만** 이면 거부한다.
  // 정확히 그 비율이면 통과다. 곱을 정수로 내림하면 하한이 문서보다 느슨해져,
  // 예컨대 ratio 0.5 에서 101 → 50 (50.5% 소실)이 통과한다.
  //
  // 하한은 **이번에 걸은 범위의 베이스라인**에 대해 잰다. 범위를 좁혔는데 파일
  // 전체를 분모로 쓰면 두 방향 다 틀린다 — 좁은 페이지만 걸을 땐 멀쩡한 캡처가
  // 붕괴로 거부되고, 넓게 걸을 땐 범위 안에서 절반이 날아가도 분모가 커서 통과한다.
  // config.pages 가 null 이면 범위가 곧 파일 전체라 이 값은 nodeCount 와 같다.
  // ── 페이지 목록 하한 ────────────────────────────────────────────────────
  // 노드 하한과 **다른 낱알**을 잰다. 한 페이지가 노드 대부분을 들고 있으면
  // 나머지 페이지가 목록에서 통째로 사라져도 노드 수는 거의 그대로라, 노드 하한이
  // 발동하지 않은 채 그 페이지들의 노드가 전부 삭제로 보고된다. `pages.txt` 는
  // 잘림을 알려주는 종결자가 없어서(위 parsePageXml 참조) 이 셈이 그 자리를 대신한다.
  //
  // 분모는 `config.pages` 와 무관한 **베이스라인의 페이지 수**다 — 범위를 좁혀도
  // pages.txt 는 파일의 페이지를 전부 나열하므로(좁히기는 그 뒤에 일어난다) 이
  // 비교는 좁힌 실행에서도 거짓 발동하지 않는다.
  const pageFloor = baseline.pages.length * config.populationFloorRatio;
  if (capture.inFile.length < pageFloor) {
    fail(
      `페이지 목록 붕괴 — pages.txt 가 나열한 페이지 ${capture.inFile.length}개, 하한 ${pageFloor}개 미만 ` +
        `(베이스라인 ${baseline.pages.length}개 × ${config.populationFloorRatio})`,
      '목록이 잘리면 빠진 페이지의 노드가 전부 "삭제됨" 으로 보고된다 — 페이지 XML 과 달리 목록에는 잘림을 알려주는 종결자가 없어 그 자리에서 알아낼 방법이 없다',
      'MCP 캡처를 다시 돌려 pages.txt 를 새로 받아라. 실제로 이만큼 지운 게 맞다면 --update-baseline 으로 베이스라인을 먼저 옮겨라',
    );
  }

  const baselineInScope = baseline.pages
    .filter((p) => !outOfScopePages.has(p.id))
    .reduce((n, p) => n + p.nodes.length, 0);
  const floor = baselineInScope * config.populationFloorRatio;
  if (current.nodeCount < floor) {
    fail(
      `모집단 붕괴 — 이번 캡처 노드 ${current.nodeCount}개, 하한 ${floor}개 미만 ` +
        `(범위 안 베이스라인 ${baselineInScope}개 × ${config.populationFloorRatio})`,
      '붕괴한 캡처는 살아있는 노드를 전부 "삭제됨" 으로 보고해서 진짜 삭제와 구별되지 않는다',
      'MCP 캡처를 다시 돌려라. 실제로 이만큼 지운 게 맞다면 --update-baseline 으로 베이스라인을 먼저 옮겨라',
    );
  }

  const diff = diffSnapshots(baseline, current, config.geometryEpsilonPx, outOfScopePages);

  // 코드 대조는 있으면 좋은 정보일 뿐이라, 파일이 없다고 실행을 막지 않는다.
  // 다만 그 사실이 **리포트 본문**까지 간다 — stderr 로만 말하면 이슈에 붙는
  // 본문에는 흔적이 남지 않아, 입력이 빠진 실행이 완전한 실행보다 깨끗해 보인다.
  let code: CodeCrossCheck;
  const codePath = resolve(cwd, CODE_COMPONENTS);
  if (!existsSync(codePath)) {
    code = { ran: false, why: `파일이 없다: ${codePath}` };
  } else {
    try {
      // 여기서만 readFile 래퍼를 쓰지 않는다 — 그 래퍼는 종료 코드 2 로 끝내는데,
      // 이 대조는 없어도 되는 정보라 읽기 실패가 실행을 막아선 안 된다. 대신
      // 실패 사실이 아래에서 리포트 본문으로 나간다.
      const parsed = JSON.parse(readFileSync(codePath, 'utf8')) as {
        components?: Record<string, unknown>;
      };
      const keys = new Set(
        Object.keys(parsed.components ?? {}).map((k) => normaliseName(k)),
      );
      code = { ran: true, keyCount: keys.size, unknown: unknownToCode(current, keys) };
    } catch (e) {
      code = { ran: false, why: `JSON 을 읽지 못했다: ${String(e)}` };
    }
  }
  if (!code.ran) console.error(`⚠️  코드 대조를 건너뛴다 — ${code.why}`);

  const markdown = renderMarkdown(
    diff,
    capture,
    code,
    config,
    provisional,
    pagesAbsentFromListing(baseline, capture.inFile),
  );

  const outPath = argValue('--out');
  if (outPath !== null) {
    const at = resolve(cwd, outPath);
    writeOut(at, `${markdown}\n`, '리포트');
    console.log(`리포트 기록: ${at}`);
  } else {
    console.log(markdown);
  }

  const jsonOut = argValue('--json-out');
  if (jsonOut !== null) {
    const at = resolve(cwd, jsonOut);
    writeOut(at, `${JSON.stringify({ snapshot: current, diff }, null, 2)}\n`, '스냅샷');
    console.log(`스냅샷 기록: ${at}`);
  }

  if (hasFlag('--update-baseline')) {
    refuseIfBaselineWouldLosePages();
    writeOut(baselinePath, serialiseSnapshot(current), '베이스라인');
    console.log(`베이스라인 갱신: ${baselinePath}`);
  }

  return process.exit(changeCount(diff) === 0 ? EXIT_NO_DIFF : EXIT_DIFF);
}

main();

// 이 파일을 모듈로 만든다 — 전역 스크립트로 남으면 위의 로컬 ambient 들이
// 같은 패턴을 쓰는 다른 파일과 한 네임스페이스에서 충돌한다.
export {};
