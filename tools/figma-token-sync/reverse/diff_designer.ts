// Channel C — 디자이너 대조 JSON 을 레포에서 전수 리포트 + 분류로 렌더한다.
//
// 플러그인의 `⇄` 대조(`src/designer-parity.ts`)는 세트마다 디자이너 프레임과
// 생성본의 **보이는 잎**(박스 · 글자 · 아이콘 · 벡터 · 오토레이아웃 인셋)을
// 서술자 문자열로 뽑아 변형별 대칭차를 낸다. 그 결과는 플러그인 로그에 상한
// 14 줄로 접혀 나가고, 그 뒤엔 아무 데도 남지 않는다. 이 스크립트는 그 대조를
// **상한 없이 통째로** 담은 봉투(`designer-parity-<stamp>.json`)를 받아,
// 사람이 다음 한 걸음을 고를 수 있는 형태로 바꾼다.
//
// 로그 한 줄이 답하지 못하는 질문이 셋이다:
//
// 1. **이 차이는 어느 축인가** — 서술자 한 줄에는 크기 · 모서리 · 채움 · 보더
//    색 · 보더 두께 · 불투명도가 한꺼번에 실린다. 같은 줄이 양쪽에 다르게 있으면
//    그중 무엇이 달라진 것인지는 두 줄을 글자 단위로 겹쳐 봐야 안다. 여기서는
//    서술자를 파싱해 양쪽을 짝짓고 **달라진 필드만** 축 이름으로 낸다.
// 2. **고치면 되는 것인가, 정해야 하는 것인가** — 디자이너가 적은 값이 토큰
//    사다리 위에 있으면 Core 의 default 한 줄을 옮기면 끝이지만, 사다리에 없는
//    값(획 1.5 · 모서리 13)은 사다리를 늘리든 값을 되돌리든 **사람이 정해야**
//    한다. 그 갈림을 리포트가 미리 나눈다.
// 3. **이 사본을 그 축에서 믿어도 되는가** — 다른 파일에서 붙여 넣은 사본은
//    텍스트에 변수 바인딩이 하나도 없어 자간이 0 으로 읽힌다. 디자이너는 "자간은
//    들어가는 게 맞다" 고 확인했으므로, 그런 사본의 자간 · 크기 차이는 캔버스의
//    결정이 아니라 사본의 결함이다. 봉투의 신선도 힌트가 그것을 말하고, 리포트는
//    그 축을 **사본 의심**으로 따로 분류해 맨 위에 경고한다.
//
// 사다리는 이 파일에 적지 않는다 — `packages/coui_core` 의 원시토큰 상수에서
// 읽는다. 값을 복제하면 Core 가 사다리를 늘렸을 때 여기가 낡은 사다리로 "사다리
// 밖" 을 잘못 판정하고, 그 오판은 리포트 모양이 멀쩡해서 읽어봐야 안다.
//
// Usage:
//   tsx reverse/diff_designer.ts [--file=<json>] [--dir=reverse/incoming] [--out=<md>]
//                                [--ladder-dir=<coui_core/lib/src>]
//
// Exit: 0 차이 없음 · 1 차이 있음 · 2 인프라 실패 (Channel A/B 와 같은 계약)

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
} from './report_format';

// `@types/node` 대신 로컬 ambient — reverse/ 의 다른 스크립트와 같은 방침.
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
declare const __dirname: string;

const { existsSync, readFileSync, writeFileSync, readdirSync } = require(
  'node:fs',
) as {
  existsSync(p: string): boolean;
  readFileSync(p: string, enc: string): string;
  writeFileSync(p: string, data: string, enc: string): void;
  readdirSync(p: string): string[];
};
const { resolve, basename } = require('node:path') as {
  resolve(...parts: string[]): string;
  basename(p: string): string;
};

const EXIT_NO_DIFF = 0;
const EXIT_DIFF = 1;
const EXIT_INFRA = 2;

const DEFAULT_DIR = 'reverse/incoming';
const FILE_PREFIX = 'designer-parity-';
const ENVELOPE_KIND = 'coui-designer-parity';
const ENVELOPE_SCHEMA = 1;

/**
 * 이 리포트의 바이트 상한.
 *
 * 이 채널은 absorb 이슈(Channel A + B) 에 실리지 않고 **자기 이슈**를 갖는다 —
 * 그래서 `report_format` 의 세 예산 합산 검사에 들어가지 않는다. 상한을 Channel B
 * 와 같은 값으로 두는 이유는 성격이 같기 때문이다: 컴포넌트마다 표가 하나씩
 * 생기는 무한한 목록이라, 행 상한이 아니라 바이트로 묶어야 한다.
 */
const REPORT_BUDGET_BYTES = CHANNEL_B_BUDGET_BYTES;

/** 사다리 상수를 읽는 Dart 파일 — `packages/coui_core/lib/src` 기준 상대 경로. */
const LADDER_FILES = {
  fontSize: 'typography/font_size.dart',
  letterSpacing: 'typography/letter_spacing.dart',
  lineHeight: 'typography/line_height.dart',
  strokeWidth: 'shape/stroke_width.dart',
  radius: 'shape/radius_scale.dart',
  space: 'spacing/spacing.dart',
  size: 'size/size.dart',
} as const;

const DEFAULT_LADDER_DIR = resolve(
  __dirname,
  '..',
  '..',
  '..',
  'packages',
  'coui_core',
  'lib',
  'src',
);

// ─── 봉투 ──────────────────────────────────────────────────────────────────

type FreshnessHint = 'raw-paste' | 'bound' | 'n/a';
const FRESHNESS_HINTS: readonly FreshnessHint[] = ['raw-paste', 'bound', 'n/a'];

interface ParityLine {
  variant: string;
  designer: string[];
  generated: string[];
}

interface ParitySet {
  name: string;
  page: string;
  designerFrame: string | null;
  freshness: { textNodes: number; boundTextNodes: number; hint: FreshnessHint };
  compared: number;
  differing: string[];
  onlyDesigner: string[];
  onlyGenerated: string[];
  lines: ParityLine[];
}

interface ParityEnvelope {
  capturedAt: string;
  fileKey: string | null;
  sourceHash: string;
  sets: ParitySet[];
}

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

function writeOut(path: string, data: string, label: string): void {
  try {
    writeFileSync(path, data, 'utf8');
  } catch (e) {
    fail(
      `${label} 기록 실패: ${path}`,
      `쓰기 실패가 종료 코드 1 로 새어 나가면 자동화는 그것을 "차이 있음" 으로 읽고 존재하지 않는 파일로 이슈를 만든다 (${String(e)})`,
      '상위 디렉터리가 존재하고 쓰기 권한이 있는지 확인하라',
    );
  }
}

function isStringArray(v: unknown): v is string[] {
  return Array.isArray(v) && v.every((x) => typeof x === 'string');
}

function isCount(v: unknown): v is number {
  return typeof v === 'number' && Number.isInteger(v) && v >= 0;
}

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/**
 * 봉투를 검증한다. 느슨하게 받으면 다른 도구의 JSON 이나 절반만 적힌 봉투가
 * "차이 없음" 으로 렌더되어 종료 코드 0 을 낸다 — 이 채널의 0 은 자동화가 이슈를
 * 만들지 않는 쪽이라, 잘못 읽은 파일이 아무 흔적도 남기지 않고 지나간다.
 */
function validate(raw: unknown, path: string): ParityEnvelope {
  if (!isRecord(raw)) {
    fail(
      `봉투가 객체가 아님: ${path}`,
      '형태를 확인하지 않고 렌더하면 잘못된 파일이 깨끗한 통과로 보인다',
      '플러그인이 내려준 designer-parity JSON 이 맞는지 확인하라',
    );
  }
  if (raw.kind !== ENVELOPE_KIND) {
    fail(
      `kind 가 "${ENVELOPE_KIND}" 가 아님: ${String(raw.kind)} (${path})`,
      '다른 채널의 JSON(fidelity · structure)을 대조로 읽으면 결과가 무의미하다',
      '플러그인의 디자이너 대조가 내려준 파일을 넣어라',
    );
  }
  if (raw.schema !== ENVELOPE_SCHEMA) {
    fail(
      `schema 가 ${ENVELOPE_SCHEMA} 이 아님: ${String(raw.schema)} (${path})`,
      '스키마가 다르면 필드 의미가 달라져 조용히 잘못 읽는다',
      '플러그인을 최신 빌드로 다시 실행해 대조를 새로 받아라',
    );
  }
  const sets = raw.sets;
  if (!Array.isArray(sets)) {
    fail(
      `sets 가 배열이 아님: ${path}`,
      '세트 목록 없이는 무엇을 대조했는지 알 수 없다',
      '봉투의 sets 필드를 확인하라',
    );
  }
  const fileKey = raw.fileKey;
  if (fileKey !== null && typeof fileKey !== 'string') {
    fail(
      `fileKey 가 문자열도 null 도 아님: ${String(fileKey)} (${path})`,
      'null 은 "파일 키를 모른다" 는 뜻이다 — 다른 모양을 null 로 읽으면 어느 파일의 대조인지가 사라진다',
      '봉투의 fileKey 를 확인하라',
    );
  }

  const parsedSets: ParitySet[] = [];
  for (let i = 0; i < sets.length; i += 1) {
    const s: unknown = sets[i];
    const where = `sets[${i}] (${path})`;
    if (!isRecord(s)) {
      fail(`${where} 가 객체가 아님`, '세트 모양이 아니면 어느 세트의 차이인지 알 수 없다', '봉투를 다시 받아라');
    }
    if (typeof s.name !== 'string' || s.name.trim() === '') {
      fail(`${where} 의 name 이 없음`, '이름 없는 세트의 차이는 고칠 곳을 가리키지 못한다', '봉투를 다시 받아라');
    }
    if (typeof s.page !== 'string') {
      fail(`${where} 의 page 가 문자열이 아님`, '어느 페이지의 세트인지 알 수 없다', '봉투를 다시 받아라');
    }
    if (s.designerFrame !== null && typeof s.designerFrame !== 'string') {
      fail(
        `${where} 의 designerFrame 이 문자열도 null 도 아님`,
        'null 은 "대조 기준이 없었다" 는 뜻이다 — 다른 모양을 null 로 읽으면 대조하지 않은 세트가 차이 없음으로 보인다',
        '봉투를 다시 받아라',
      );
    }
    const fr = s.freshness;
    if (
      !isRecord(fr) ||
      !isCount(fr.textNodes) ||
      !isCount(fr.boundTextNodes) ||
      typeof fr.hint !== 'string' ||
      !(FRESHNESS_HINTS as readonly string[]).includes(fr.hint)
    ) {
      fail(
        `${where} 의 freshness 가 {textNodes, boundTextNodes, hint} 모양이 아님`,
        '신선도를 모르면 raw-paste 사본의 자간 · 크기 차이를 캔버스의 결정으로 읽게 된다 — 디자이너가 그 축은 믿지 말라고 확인한 자리다',
        '플러그인을 최신 빌드로 다시 실행해 대조를 새로 받아라',
      );
    }
    if (!isCount(s.compared)) {
      fail(`${where} 의 compared 가 셈이 아님`, '"몇 변형 중 몇 변형" 의 분모가 없다', '봉투를 다시 받아라');
    }
    const differing = s.differing;
    const onlyDesigner = s.onlyDesigner;
    const onlyGenerated = s.onlyGenerated;
    if (!isStringArray(differing) || !isStringArray(onlyDesigner) || !isStringArray(onlyGenerated)) {
      fail(
        `${where} 의 differing / onlyDesigner / onlyGenerated 중 문자열 배열이 아닌 것이 있음`,
        '모양이 틀린 목록을 걸러내면 빈 배열이 남고, 그것은 "차이 없음" 이라는 적극적 주장으로 렌더된다',
        '봉투를 다시 받아라',
      );
    }
    const lines = s.lines;
    if (
      !Array.isArray(lines) ||
      !lines.every(
        (l: unknown) =>
          isRecord(l) &&
          typeof l.variant === 'string' &&
          isStringArray(l.designer) &&
          isStringArray(l.generated),
      )
    ) {
      fail(
        `${where} 의 lines 에 {variant, designer[], generated[]} 모양이 아닌 원소가 있음`,
        '서술자를 실을 수 없는 원소는 축을 파싱할 수 없고, 걸러내면 그 변형의 차이가 조용히 사라진다',
        '봉투를 다시 받아라',
      );
    }
    parsedSets.push({
      name: s.name,
      page: s.page,
      designerFrame: s.designerFrame,
      freshness: {
        textNodes: fr.textNodes,
        boundTextNodes: fr.boundTextNodes,
        hint: fr.hint as FreshnessHint,
      },
      compared: s.compared,
      differing,
      onlyDesigner,
      onlyGenerated,
      lines: lines as ParityLine[],
    });
  }

  // `pickFile()` 이 이미 이 근거를 파일 부재에 적용했다 — 대조할 세트가 없는 것은
  // 차이가 없다는 뜻이 아니라 아무도 대조하지 않았다는 뜻이다. `sets: []` 를
  // "차이 없음" 으로 렌더하면 캡처가 통째로 깨져 세트를 하나도 못 실은 주기가
  // 초록으로 보고된다 — 침묵을 통과로 읽으면 안 된다는 원칙은 파일 수준과
  // 세트 수준에서 같이 참이다.
  if (parsedSets.length === 0) {
    fail(
      `sets 가 비어 있음: ${path}`,
      '대조할 세트가 없는 것은 차이가 없다는 뜻이 아니라 아무도 대조하지 않았다는 뜻이다',
      '플러그인이 최소 한 세트를 대조해 내려준 designer-parity JSON 인지 확인하라',
    );
  }

  return {
    // 강등은 안전한 방향이다 — `(미상)` 은 모르는 것을 모른다고 적을 뿐이다.
    capturedAt: typeof raw.capturedAt === 'string' ? raw.capturedAt : '(미상)',
    fileKey,
    sourceHash: typeof raw.sourceHash === 'string' ? raw.sourceHash : '(미상)',
    sets: parsedSets,
  };
}

// ─── 사다리 ────────────────────────────────────────────────────────────────

interface Ladder {
  fontSize: number[];
  /** em 단위 — `CoreLetterSpacing` 이 그렇게 적는다. */
  letterSpacingEm: number[];
  /** unitless 배수 — `CoreLineHeight`. */
  lineHeight: number[];
  strokeWidth: number[];
  radius: number[];
  /** `CoreSpace` ∪ `CoreSize` — 박스 크기와 인셋이 함께 서는 눈금. */
  size: number[];
  space: number[];
}

/**
 * `abstract final class <className> { … }` 의 몸통만 잘라 낸다. 찾지 못하거나
 * 닫히지 않으면 null.
 *
 * 닫는 중괄호는 깊이를 세어 찾는다 — 몸통 안의 record 타입(`({ String h100, … })`)
 * 이 중괄호를 쓰므로 첫 `}` 에서 자르면 사다리가 반만 읽힌다. 주석과 문자열 안의
 * 중괄호는 세지 않는다.
 */
function classBody(text: string, className: string): string | null {
  const head = new RegExp(`\\babstract\\s+final\\s+class\\s+${className}\\b[^{]*\\{`).exec(text);
  if (head === null) return null;
  const start = head.index + head[0].length;
  let depth = 1;
  for (let i = start; i < text.length; i++) {
    const c = text[i];
    if (c === '/' && text[i + 1] === '/') {
      const nl = text.indexOf('\n', i);
      if (nl < 0) return null;
      i = nl;
    } else if (c === '/' && text[i + 1] === '*') {
      const end = text.indexOf('*/', i + 2);
      if (end < 0) return null;
      i = end + 1;
    } else if (c === "'" || c === '"') {
      let j = i + 1;
      while (j < text.length && text[j] !== c) j += text[j] === '\\' ? 2 : 1;
      i = j;
    } else if (c === '{') {
      depth++;
    } else if (c === '}') {
      depth--;
      if (depth === 0) return text.slice(start, i);
    }
  }
  return null;
}

/**
 * `static const [double|int] name = N;` 을 전부 읽는다. Tailwind 키 record 는
 * 문자열이라 걸리지 않고, 값 상수만 남는다. `className` 을 주면 그 클래스의
 * 몸통 안에서만 읽는다 — 같은 파일에 다른 단위의 상수를 든 클래스가 함께 사는
 * 경우다.
 */
function readDartConstants(path: string, label: string, className?: string): number[] {
  let text: string;
  try {
    text = readFileSync(path, 'utf8');
  } catch (e) {
    return fail(
      `사다리를 읽지 못함: ${path}`,
      `${label} 축의 "사다리 위 / 밖" 판정은 이 상수에서 나온다 — 사다리를 잃고 진행하면 모든 값이 "사다리 밖" 으로 나가 결정 필요가 부풀거나, 반대로 판정을 건너뛰어 조용히 통과한다 (${String(e)})`,
      '이 파일이 제자리에 있는지 확인하라. 옮겼다면 --ladder-dir 로 새 자리를 주거나 이 스크립트의 경로표를 같이 옮겨라',
    );
  }
  const scope = className === undefined ? text : classBody(text, className);
  if (scope === null) {
    return fail(
      `사다리 클래스를 찾지 못함: ${String(className)} (${path})`,
      `${label} 사다리는 이 클래스 안의 상수만이다 — 같은 파일의 다른 클래스는 다른 단위의 값을 들고 있어, 파일 전체를 읽으면 사다리에 없는 값이 "사다리 위" 로 판정된다`,
      '그 클래스의 이름이나 선언 모양이 바뀌었는지 확인하고, 바뀌었다면 이 스크립트가 넘기는 클래스 이름도 같이 바꿔라',
    );
  }
  const out: number[] = [];
  const re = /static const (?:double |int )?[A-Za-z_]\w* = (-?\d+(?:\.\d+)?);/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(scope)) !== null) out.push(Number(m[1]));
  if (out.length === 0) {
    return fail(
      `사다리에서 상수를 한 개도 읽지 못함: ${path}`,
      `${label} 사다리가 비면 어떤 값도 사다리 위에 없어, 전부 "결정 필요" 로 나간다 — 파일 형식이 바뀐 것을 판정 결과로 착각하게 된다`,
      '그 Dart 파일의 상수 선언 모양이 바뀌었는지 확인하고, 바뀌었다면 이 스크립트의 읽는 자리도 같이 바꿔라',
    );
  }
  return out;
}

function loadLadder(dir: string): Ladder {
  const read = (rel: string, label: string, className?: string) =>
    readDartConstants(resolve(dir, rel), label, className);
  const space = read(LADDER_FILES.space, 'spacing');
  const size = read(LADDER_FILES.size, 'size');
  return {
    fontSize: read(LADDER_FILES.fontSize, 'text-size'),
    letterSpacingEm: read(LADDER_FILES.letterSpacing, 'letter-spacing'),
    // `line_height.dart` 는 배수 사다리 옆에 코드 역할의 고정 줄 상자
    // (`CoreLineBox`, px)를 함께 둔다. 파일 전체를 읽으면 그 px 값이 배수로 읽혀
    // 21px 상자가 2100% 라는 "사다리 위" 줄 높이가 된다 — 배수는
    // `CoreLineHeight` 안에서만 읽는다.
    lineHeight: read(LADDER_FILES.lineHeight, 'line-height', 'CoreLineHeight'),
    strokeWidth: read(LADDER_FILES.strokeWidth, 'stroke-width'),
    radius: read(LADDER_FILES.radius, 'radius'),
    size: Array.from(new Set([...size, ...space])),
    space,
  };
}

const EPSILON = 1e-6;
/** em 자간은 서술자에서 px 소수 둘째 자리로 반올림된 값을 fontSize 로 나눈 것이라 이만큼 흔들린다. */
const LETTER_SPACING_EM_EPSILON = 0.0015;

function onLadder(value: number, rungs: readonly number[], eps = EPSILON): boolean {
  return rungs.some((r) => Math.abs(r - value) <= eps);
}

// ─── 서술자 문법 ───────────────────────────────────────────────────────────
//
// 이 다섯 패턴은 `src/designer-parity.ts` 의 `collectLeaves` 가 내는 형식이다.
// 그쪽 템플릿이 바뀌면 여기 파싱이 먼저 깨져야 하므로, selftest 가 그 템플릿
// 조각을 소스에서 직접 확인한다 — 형식이 갈라진 채 파싱만 조용히 `other` 로
// 떨어지면 축이 전부 `node-missing` 으로 뭉개진다.

interface TextLeaf {
  kind: 'text';
  raw: string;
  chars: string;
  fontSize: number | null;
  face: string;
  lineHeight: string;
  letterSpacing: string;
  color: string;
}
interface IconLeaf {
  kind: 'icon';
  raw: string;
  glyph: string;
  size: string;
  color: string;
}
interface VecLeaf {
  kind: 'vec';
  raw: string;
  w: string;
  h: string;
  fill: string;
  stroke: string;
}
interface LayoutLeaf {
  kind: 'layout';
  raw: string;
  pad: string;
  gap: string;
}
interface BoxLeaf {
  kind: 'box';
  raw: string;
  w: string;
  h: string;
  radius: string;
  fill: string;
  stroke: string;
  strokeWidth: string;
  opacity: string;
}
interface OtherLeaf {
  kind: 'other';
  raw: string;
}
type Leaf = TextLeaf | IconLeaf | VecLeaf | LayoutLeaf | BoxLeaf | OtherLeaf;

const TEXT_RE = /^text "([\s\S]*)" (\S+) (.+?) lh(\S+) ls(\S+) (\S+)$/;
const ICON_RE = /^icon (\S+) (\S+) (\S+)$/;
const VEC_RE = /^vec (\S+)x(\S+) (\S+) \/ (\S+)$/;
const LAYOUT_RE = /^layout pad(\S+) gap(\S+)$/;
const BOX_RE = /^box (\S+)x(\S+) r(\S+) fill:(\S+) stroke:(\S+) w(\S+)(?: op(\S+))?$/;

function numberOrNull(s: string): number | null {
  const n = Number(s);
  return Number.isFinite(n) ? n : null;
}

function parseLeaf(raw: string): Leaf {
  let m = TEXT_RE.exec(raw);
  if (m) {
    return {
      kind: 'text',
      raw,
      chars: m[1],
      fontSize: numberOrNull(m[2]),
      face: m[3],
      lineHeight: m[4],
      letterSpacing: m[5],
      color: m[6],
    };
  }
  m = ICON_RE.exec(raw);
  if (m) return { kind: 'icon', raw, glyph: m[1], size: m[2], color: m[3] };
  m = VEC_RE.exec(raw);
  if (m) return { kind: 'vec', raw, w: m[1], h: m[2], fill: m[3], stroke: m[4] };
  m = LAYOUT_RE.exec(raw);
  if (m) return { kind: 'layout', raw, pad: m[1], gap: m[2] };
  m = BOX_RE.exec(raw);
  if (m) {
    return {
      kind: 'box',
      raw,
      w: m[1],
      h: m[2],
      radius: m[3],
      fill: m[4],
      stroke: m[5],
      strokeWidth: m[6],
      opacity: m[7] ?? '',
    };
  }
  return { kind: 'other', raw };
}

// ─── 축 ────────────────────────────────────────────────────────────────────

type Axis =
  | 'text-size'
  | 'letter-spacing'
  | 'line-height'
  | 'font-face'
  | 'text-color'
  | 'fill'
  | 'stroke-color'
  | 'stroke-width'
  | 'radius'
  | 'size'
  | 'spacing'
  | 'opacity'
  | 'node-missing';

/** 한 변형에서 한 축이 다른 사실. 값은 서술자에 적힌 그대로다. */
interface AxisDiff {
  axis: Axis;
  designer: string;
  generated: string;
  /** 사다리 판정에 쓰는 정규화 값 — 디자이너 쪽. 판정할 값이 없으면 null. */
  designerNumber: number | null;
  /** 두 번째 수가 필요한 축(size 의 높이) — 없으면 null. */
  designerNumber2: number | null;
}

function fieldDiff(
  axis: Axis,
  d: string,
  g: string,
  designerNumber: number | null = numberOrNull(d),
  designerNumber2: number | null = null,
): AxisDiff | null {
  return d === g ? null : { axis, designer: d, generated: g, designerNumber, designerNumber2 };
}

/**
 * 자간을 em 으로 — 서술자는 Figma 단위 그대로(px 또는 `%`) 적혀 있고, Core
 * 사다리(`CoreLetterSpacing`)는 em 이다. 같은 -0.01em 이 18px 에서 -0.18,
 * 12px 에서 -0.12 로 적히므로 px 그대로는 사다리와 겹칠 수 없다.
 */
function letterSpacingEm(ls: string, fontSize: number | null): number | null {
  if (ls.endsWith('%')) {
    const n = numberOrNull(ls.slice(0, -1));
    return n === null ? null : n / 100;
  }
  const px = numberOrNull(ls);
  if (px === null || fontSize === null || fontSize === 0) return null;
  return px / fontSize;
}

function lineHeightMultiple(lh: string): number | null {
  if (!lh.endsWith('%')) return null;
  const n = numberOrNull(lh.slice(0, -1));
  return n === null ? null : n / 100;
}

function pairDiffs(d: Leaf, g: Leaf): AxisDiff[] {
  const out: AxisDiff[] = [];
  const push = (x: AxisDiff | null) => {
    if (x) out.push(x);
  };
  if (d.kind === 'text' && g.kind === 'text') {
    push(fieldDiff('text-size', String(d.fontSize ?? 'mixed'), String(g.fontSize ?? 'mixed'), d.fontSize));
    push(
      fieldDiff(
        'letter-spacing',
        `ls${d.letterSpacing} @${d.fontSize ?? '?'}px`,
        `ls${g.letterSpacing} @${g.fontSize ?? '?'}px`,
        letterSpacingEm(d.letterSpacing, d.fontSize),
      ),
    );
    push(fieldDiff('line-height', d.lineHeight, g.lineHeight, lineHeightMultiple(d.lineHeight)));
    push(fieldDiff('font-face', d.face, g.face, null));
    push(fieldDiff('text-color', d.color, g.color, null));
  } else if (d.kind === 'icon' && g.kind === 'icon') {
    push(fieldDiff('size', d.size, g.size, numberOrNull(d.size), numberOrNull(d.size)));
    push(fieldDiff('fill', d.color, g.color, null));
  } else if (d.kind === 'vec' && g.kind === 'vec') {
    push(fieldDiff('size', `${d.w}x${d.h}`, `${g.w}x${g.h}`, numberOrNull(d.w), numberOrNull(d.h)));
    push(fieldDiff('fill', d.fill, g.fill, null));
    push(fieldDiff('stroke-color', d.stroke, g.stroke, null));
  } else if (d.kind === 'layout' && g.kind === 'layout') {
    push(fieldDiff('spacing', `pad${d.pad} gap${d.gap}`, `pad${g.pad} gap${g.gap}`, null));
  } else if (d.kind === 'box' && g.kind === 'box') {
    push(fieldDiff('size', `${d.w}x${d.h}`, `${g.w}x${g.h}`, numberOrNull(d.w), numberOrNull(d.h)));
    push(fieldDiff('radius', d.radius, g.radius));
    push(fieldDiff('fill', d.fill, g.fill, null));
    push(fieldDiff('stroke-color', d.stroke, g.stroke, null));
    push(fieldDiff('stroke-width', d.strokeWidth, g.strokeWidth));
    push(fieldDiff('opacity', d.opacity === '' ? '100%' : d.opacity, g.opacity === '' ? '100%' : g.opacity, null));
  }
  return out;
}

/** 짝을 지을 수 있는 잎인가 — 종류가 같고, 글자 · 글리프는 그것까지 같아야 한다. */
function pairable(d: Leaf, g: Leaf): boolean {
  if (d.kind !== g.kind) return false;
  if (d.kind === 'text' && g.kind === 'text') return d.chars === g.chars;
  if (d.kind === 'icon' && g.kind === 'icon') return d.glyph === g.glyph;
  return d.kind !== 'other';
}

/**
 * 한 변형의 디자이너-만 / 생성본-만 서술자를 짝지어 축 차이로 바꾼다.
 *
 * 짝은 **달라진 필드가 가장 적은** 상대다 — 서술자 대칭차는 "같은 박스가 한
 * 값만 다르다" 를 두 줄로 내므로, 그 두 줄을 도로 붙여야 어느 값인지가 보인다.
 * 짝이 없는 잎은 `node-missing` 이다: 한쪽에만 그려진 것은 값 차이가 아니라
 * 노드 유무의 차이라, 사다리로 판정할 것이 없다.
 */
function diffVariant(line: ParityLine): AxisDiff[] {
  const ds = line.designer.map(parseLeaf);
  const gs = line.generated.map(parseLeaf);
  const usedG = new Set<number>();
  const out: AxisDiff[] = [];
  for (const d of ds) {
    let best = -1;
    let bestScore = Number.POSITIVE_INFINITY;
    let bestDiffs: AxisDiff[] = [];
    for (let j = 0; j < gs.length; j += 1) {
      if (usedG.has(j) || !pairable(d, gs[j])) continue;
      const diffs = pairDiffs(d, gs[j]);
      if (diffs.length < bestScore) {
        best = j;
        bestScore = diffs.length;
        bestDiffs = diffs;
      }
    }
    if (best < 0) {
      out.push({ axis: 'node-missing', designer: d.raw, generated: '(없음)', designerNumber: null, designerNumber2: null });
      continue;
    }
    usedG.add(best);
    for (const x of bestDiffs) out.push(x);
  }
  for (let j = 0; j < gs.length; j += 1) {
    if (usedG.has(j)) continue;
    out.push({ axis: 'node-missing', designer: '(없음)', generated: gs[j].raw, designerNumber: null, designerNumber2: null });
  }
  return out;
}

// ─── 분류 ──────────────────────────────────────────────────────────────────

type NextStep = 'core-fix' | 'decision' | 'suspect';

const NEXT_STEP_LABEL: Record<NextStep, string> = {
  'core-fix': 'Core 값 수정',
  decision: '결정 필요 — 사다리 밖',
  suspect: '사본 의심',
};

/** raw-paste 사본에서 믿을 수 없는 축 — 텍스트에 변수 바인딩이 없어 자간이 0 으로, 크기가 로우 값으로 읽힌다. */
const RAW_PASTE_UNTRUSTED: readonly Axis[] = ['text-size', 'letter-spacing'];

/** 색 서술자가 토큰(변수 이름)만으로 이루어졌는가 — `#hex` · `mixed` · gradient 류는 사다리 밖이다. */
function isTokenColor(v: string): boolean {
  if (v === 'none') return true;
  if (v === 'mixed') return false;
  return v.split('+').every((part) => {
    const base = part.replace(/@\d+%$/, '');
    return base.includes('/') && !base.startsWith('#');
  });
}

function classify(diff: AxisDiff, ladder: Ladder, hint: FreshnessHint): NextStep {
  if (hint === 'raw-paste' && RAW_PASTE_UNTRUSTED.includes(diff.axis)) return 'suspect';
  const n = diff.designerNumber;
  switch (diff.axis) {
    case 'text-size':
      return n !== null && onLadder(n, ladder.fontSize) ? 'core-fix' : 'decision';
    case 'letter-spacing':
      return n !== null && onLadder(n, ladder.letterSpacingEm, LETTER_SPACING_EM_EPSILON)
        ? 'core-fix'
        : 'decision';
    case 'line-height':
      return n !== null && onLadder(n, ladder.lineHeight) ? 'core-fix' : 'decision';
    case 'stroke-width':
      return n !== null && onLadder(n, ladder.strokeWidth) ? 'core-fix' : 'decision';
    case 'radius':
      return n !== null && onLadder(n, ladder.radius) ? 'core-fix' : 'decision';
    case 'size': {
      const n2 = diff.designerNumber2;
      return n !== null && n2 !== null && onLadder(n, ladder.size) && onLadder(n2, ladder.size)
        ? 'core-fix'
        : 'decision';
    }
    case 'spacing': {
      const nums = diff.designer.match(/-?\d+(?:\.\d+)?/g) ?? [];
      return nums.length > 0 && nums.every((s) => onLadder(Number(s), ladder.space))
        ? 'core-fix'
        : 'decision';
    }
    case 'text-color':
    case 'fill':
    case 'stroke-color':
      return isTokenColor(diff.designer) ? 'core-fix' : 'decision';
    case 'font-face':
    case 'opacity':
    case 'node-missing':
      return 'decision';
  }
}

// ─── 접기 ──────────────────────────────────────────────────────────────────

interface FoldedRow {
  axis: Axis;
  designer: string;
  generated: string;
  next: NextStep;
  variants: string[];
}

/**
 * 같은 (축, 디자이너 값, 생성본 값) 이 여러 변형에 반복되면 한 행으로 접고 변형
 * 수를 단다 — 27 포즈의 링 색이 같은 방향으로 다르면 그것은 한 결정이지 27 개가
 * 아니다. 정렬은 변형 수 내림차순, 같으면 축 이름.
 *
 * 키의 구분자는 NUL 이다 — 서술자에는 공백도 `/` 도 `:` 도 들어가므로, 눈에 보이는
 * 문자를 구분자로 쓰면 값 안의 그 문자가 경계를 흉내내 서로 다른 두 차이가 한 행으로
 * 접힌다. 접힌 행은 접혔다는 흔적을 남기지 않아, 사라진 차이는 리포트를 읽어서는
 * 알 수 없다.
 *
 * **다만 `\u0000` 이스케이프로 적고 NUL 바이트를 소스에 직접 넣지 마라.** 파일에
 * NUL 이 한 바이트라도 있으면 `grep` 이 그 파일을 바이너리로 보고 **아무 줄도 내지
 * 않는다** — 이 레포의 가드와 리뷰는 grep 위에 서 있으므로, 그 파일만 모든 그물을
 * 조용히 빠져나간다. 실제로 이 줄 때문에 파일 전체가 `file(1)` 에 `data` 로 잡혀
 * 편집 중 grep 이 빈 결과를 냈고, 그것을 파일이 깨진 신호로 잘못 읽은 일이 있었다.
 * 런타임 키는 두 표기가 완전히 같다.
 */
function foldSet(set: ParitySet, ladder: Ladder): FoldedRow[] {
  const folded = new Map<string, FoldedRow>();
  for (const line of set.lines) {
    for (const diff of diffVariant(line)) {
      const key = `${diff.axis}\u0000${diff.designer}\u0000${diff.generated}`;
      const hit = folded.get(key);
      if (hit) {
        if (!hit.variants.includes(line.variant)) hit.variants.push(line.variant);
        continue;
      }
      folded.set(key, {
        axis: diff.axis,
        designer: diff.designer,
        generated: diff.generated,
        next: classify(diff, ladder, set.freshness.hint),
        variants: [line.variant],
      });
    }
  }
  return Array.from(folded.values()).sort(
    (a, b) => b.variants.length - a.variants.length || a.axis.localeCompare(b.axis),
  );
}

/**
 * 이 세트에 차이가 있는가 — 요약 필드(differing/onlyDesigner/onlyGenerated)만
 * 보지 않는다. 그 셋은 봉투를 낸 쪽이 낸 **주장**이고, `lines` 는 이 스크립트가
 * 직접 서술자를 파싱해 얻은 **증거**다. 둘은 서로 다른 경로로 계산되므로(플러그인의
 * 해시 비교 대 잎 수집) 어긋날 수 있다 — 요약이 "차이 없음" 이라고 말해도 `lines`
 * 안에 실제 획 · 색 · 크기 차이가 있으면 그건 있는 차이다. 요약만 믿으면 그 차이가
 * "✅ 차이 없음" 으로 렌더되고 종료 코드 0 을 내 자동화가 이슈를 만들지 않는다 —
 * 이 채널이 존재하는 이유인 바로 그 결함 종류가 조용히 사라진다.
 */
function hasDiff(set: ParitySet, ladder: Ladder): boolean {
  return (
    set.differing.length > 0 ||
    set.onlyDesigner.length > 0 ||
    set.onlyGenerated.length > 0 ||
    foldSet(set, ladder).length > 0
  );
}

// ─── 렌더 ──────────────────────────────────────────────────────────────────

function cell(s: unknown): string {
  return escapeCell(String(s ?? ''));
}

const PARITY_AGE = { label: '이 대조의 캡처 시각', stale: null } as const;

function freshnessLine(set: ParitySet): string {
  const f = set.freshness;
  switch (f.hint) {
    case 'raw-paste':
      return (
        `⚠️ **사본 신선도: raw-paste** — 텍스트 ${f.textNodes} 노드 중 변수 바인딩 ${f.boundTextNodes}. ` +
        '다른 파일에서 붙여 넣은 로우 사본이라 **자간 · 크기 축은 신뢰 불가** — 그 축의 차이는 캔버스의 결정이 아니라 사본의 결함이므로 아래 표에서 `사본 의심` 으로 분류했다.'
      );
    case 'bound':
      return `사본 신선도: bound — 텍스트 ${f.textNodes} 노드 중 변수 바인딩 ${f.boundTextNodes}. 자간 · 크기 축을 믿어도 된다.`;
    case 'n/a':
      return '사본 신선도: n/a — 판정할 텍스트가 없거나 대조 기준이 없다.';
  }
}

interface SetSection {
  head: string[];
  rows: string[];
}

function renderSet(set: ParitySet, ladder: Ladder): SetSection {
  const head: string[] = [];
  head.push(`## ${cell(set.name)} — 페이지 \`${brief(set.page)}\``);
  head.push('');
  if (set.designerFrame === null) {
    head.push('_대조 기준 없음 — 같은 페이지에 `<이름>(디자이너` 프레임이 없어 이 세트는 판정하지 않았다. 차이 없음이 아니라 정보 없음이다._');
    head.push('');
    return { head, rows: [] };
  }
  head.push(
    `기준 \`${brief(set.designerFrame)}\` · 비교 ${set.compared} 변형 · 값이 다른 변형 ${set.differing.length}` +
      (set.onlyDesigner.length > 0 ? ` · 디자이너에만 ${set.onlyDesigner.length}` : '') +
      (set.onlyGenerated.length > 0 ? ` · 생성본에만 ${set.onlyGenerated.length}` : ''),
  );
  head.push('');
  // 신선도는 표보다 **먼저** 온다 — 표를 먼저 읽고 자간 행을 캔버스의 결정으로
  // 받아들인 뒤에 경고를 만나면 이미 늦다.
  head.push(freshnessLine(set));
  head.push('');
  if (!hasDiff(set, ladder)) {
    head.push('✅ 차이 없음.');
    head.push('');
    return { head, rows: [] };
  }
  const rows: string[] = [];
  for (const r of foldSet(set, ladder)) {
    const where =
      r.variants.length === 1
        ? r.variants[0]
        : `${r.variants[0]} 외 ${r.variants.length - 1}`;
    rows.push(
      `| ${r.axis} | ${r.variants.length} (${cell(brief(where))}) | ${cell(r.designer)} | ${cell(r.generated)} | ${NEXT_STEP_LABEL[r.next]} |`,
    );
  }
  for (const v of set.onlyDesigner) {
    rows.push(`| node-missing | 1 (${cell(brief(v))}) | 변형 전체 | (없음) | ${NEXT_STEP_LABEL.decision} |`);
  }
  for (const v of set.onlyGenerated) {
    rows.push(`| node-missing | 1 (${cell(brief(v))}) | (없음) | 변형 전체 | ${NEXT_STEP_LABEL.decision} |`);
  }
  // hasDiff() 는 참인데(요약 필드가 차이를 주장했는데) lines/onlyDesigner/onlyGenerated
  // 로는 축을 하나도 못 판정했다 — 예산으로 잘린 게 아니라(그건 아래 render() 의
  // 잘림 문구가 따로 말한다) 봉투 자체에 그 변형의 잎 서술자가 없는 것이다. 표도
  // 표 머리도 없이 곧장 범례로 넘어가면 "차이 2개인데 표가 잘렸다" 와 "차이 2개인데
  // 축을 하나도 못 실었다" 가 읽는 사람에게 구별되지 않는다.
  if (rows.length === 0) {
    head.push(
      `_이 세트는 차이 ${set.differing.length} 변형이 보고됐지만 봉투에 그 변형의 잎 서술자가 없어 축을 판정하지 못했다 — 차이 없음이 아니라 증거 없음이다._`,
    );
    head.push('');
  }
  return { head, rows };
}

const TABLE_HEAD = [
  '| 축 | 변형 | 디자이너 | 생성본 | 다음 한 걸음 |',
  '| --- | --- | --- | --- | --- |',
];

function render(env: ParityEnvelope, ladder: Ladder, source: Source): string {
  const sets = env.sets;
  const withDiff = sets.filter((s) => hasDiff(s, ladder));
  const withoutFrame = sets.filter((s) => s.designerFrame === null);
  const rawPaste = sets.filter((s) => s.designerFrame !== null && s.freshness.hint === 'raw-paste');

  // ── head — 잘리지 않는다 ────────────────────────────────────────────────
  const head: string[] = [];
  head.push('# Figma 디자이너 대조 리포트 (Channel C)');
  head.push('');
  head.push(
    withDiff.length === 0
      ? `✅ 차이 없음 — 세트 ${sets.length}개 중 대조 ${sets.length - withoutFrame.length}개.`
      : `⚠️ 세트 ${sets.length}개 중 ${withDiff.length}개에서 차이 — 대조 ${sets.length - withoutFrame.length}개, 기준 없음 ${withoutFrame.length}개.`,
  );
  head.push('');
  head.push(
    '> 이 리포트는 플러그인의 `⇄` 대조 — 디자이너 프레임(`<이름>(디자이너`) 과 생성본의 보이는 잎 서술자 대칭차 — 를 ' +
      '축별로 접고, 디자이너 값이 Core 토큰 사다리 위에 있는지로 다음 한 걸음을 나눈 것이다. ' +
      '사다리는 `packages/coui_core` 의 원시토큰 상수에서 읽었다.',
  );
  head.push('');
  if (source.total > 1) {
    head.push(
      `⚠️ 드롭 디렉터리에 대조 파일이 ${source.total}개 있고 그중 파일명 사전순 마지막인 ` +
        `\`${brief(source.chosen)}\` **하나만** 읽었다 — 나머지 ${source.total - 1}개에 대해서는 아무 주장도 하지 않는다.`,
    );
    head.push('');
  }
  if (rawPaste.length > 0) {
    head.push(
      `⚠️ **raw-paste 사본 ${rawPaste.length}개**(${rawPaste.map((s) => cell(brief(s.name))).join(' · ')}) — ` +
        '텍스트에 변수 바인딩이 없는 로우 사본이라 **자간 · 크기 축은 신뢰 불가**. 그 축의 차이는 `사본 의심` 으로 분류했다. ' +
        '디자이너가 스냅샷 프레임(플러그인이 뜬 `(디자이너 · 시각)`)이 아니라 다른 파일에서 붙여 넣은 사본을 기준으로 두면 이렇게 된다.',
    );
    head.push('');
  }
  head.push(ageNote(env.capturedAt, PARITY_AGE));
  head.push('');

  // ── tail — 잘리지 않는다 ────────────────────────────────────────────────
  const tail: string[] = [];
  if (withDiff.length > 0) {
    tail.push('## 다음 한 걸음 — 분류의 뜻');
    tail.push('');
    tail.push(
      `- **${NEXT_STEP_LABEL['core-fix']}** — 디자이너 값이 토큰 사다리 위에 있다. 그 컴포넌트의 \`CoreXxxStyle\` default 를 그 눈금으로 옮기면 끝난다.`,
    );
    tail.push(
      `- **${NEXT_STEP_LABEL.decision}** — 디자이너 값이 어떤 토큰과도 맞지 않거나(획 1.5 · 모서리 13 · 로우 hex 색), 값이 아니라 노드 유무의 차이다. 사다리를 늘릴지 값을 되돌릴지 사람이 정한다.`,
    );
    tail.push(
      `- **${NEXT_STEP_LABEL.suspect}** — raw-paste 사본의 자간 · 크기. 사본이 그 축을 잃은 것이지 캔버스의 결정이 아니다 — 디자이너에게 스냅샷 기준으로 다시 대조해 달라고 한다.`,
    );
    tail.push('');
  }
  tail.push('---');
  tail.push('');
  tail.push(
    `세트 ${sets.length} · 차이 ${withDiff.length} · fileKey \`${brief(env.fileKey ?? '(없음)')}\` · ` +
      `sourceHash \`${brief(env.sourceHash)}\` · 출처 파일 \`${brief(source.chosen)}\``,
  );

  // ── 증거 — 남는 전부 ───────────────────────────────────────────────────
  //
  // 절 전체가 잘렸다는 문장은 예산 **밖에서** 쓴다 — 예산이 바닥났을 때 그 문장부터
  // 사라지면 잘린 리포트가 완전한 목록으로 읽힌다. 자리는 최악(전부 감춰졌고
  // 세트도 전부 못 실었다) 기준으로 뗀다.
  const sections = sets.map((s) => renderSet(s, ladder));
  const totalRows = sections.reduce((n, s) => n + s.rows.length, 0);
  const sectionNotice = (shown: number, dropped: number, droppedSets: number): string =>
    `_리포트가 ${REPORT_BUDGET_BYTES} 바이트에서 잘렸다 — ${shown} 행을 실었고 ${dropped} 행이 더 있다 (총 ${totalRows})._` +
    (droppedSets > 0 ? ` _그중 세트 ${droppedSets}개는 이름조차 싣지 못했다._` : '');

  const evidenceBytes = evidenceBudget(
    REPORT_BUDGET_BYTES,
    head,
    tail,
    sectionNotice(totalRows, totalRows, sets.length),
  );
  const budget = budgetOf(evidenceBytes);
  const evidence: string[] = [];
  let shownRows = 0;
  let droppedRows = 0;
  let droppedSets = 0;

  for (const sec of sections) {
    if (!spend(budget, evidence, sec.head)) {
      droppedSets += 1;
      droppedRows += sec.rows.length;
      continue;
    }
    if (sec.rows.length === 0) continue;
    if (!spend(budget, evidence, TABLE_HEAD)) {
      droppedRows += sec.rows.length;
      continue;
    }
    let emitted = 0;
    for (const row of sec.rows.slice(0, MAX_TABLE_ROWS)) {
      if (!spend(budget, evidence, [row])) break;
      emitted += 1;
    }
    shownRows += emitted;
    if (sec.rows.length > emitted) {
      spend(budget, evidence, ['', truncationNotice(emitted, sec.rows.length)]);
      droppedRows += sec.rows.length - emitted;
    }
    spend(budget, evidence, ['']);
  }

  const notice: string[] = [];
  if (droppedRows > 0) {
    notice.push(sectionNotice(shownRows, droppedRows, droppedSets));
    notice.push('');
  }
  return [...head, ...evidence, ...notice, ...tail].join('\n');
}

// ─── main ──────────────────────────────────────────────────────────────────

function pickFile(): { path: string; source: Source } {
  const cwd = process.cwd();
  const explicit = argValue('--file');
  if (explicit !== null) {
    const path = resolve(cwd, explicit);
    if (!existsSync(path)) {
      fail(
        `대조 파일이 없음: ${path}`,
        '없는 파일을 "차이 없음" 으로 읽으면 아무도 대조하지 않은 주기가 초록으로 보고된다',
        '--file 경로를 확인하라',
      );
    }
    return { path, source: { chosen: basename(path), total: 1 } };
  }
  const dir = resolve(cwd, argValue('--dir') ?? DEFAULT_DIR);
  if (!existsSync(dir)) {
    fail(
      `디렉터리가 없음: ${dir}`,
      '대조 파일을 놓을 자리가 없으면 이 채널은 아무것도 말하지 못한다',
      '경로를 확인하거나 --file / --dir 로 지정하라',
    );
  }
  let entries: string[];
  try {
    entries = readdirSync(dir);
  } catch (e) {
    return fail(
      `디렉터리를 읽지 못함: ${dir}`,
      `읽기 실패가 종료 코드 1 로 새어 나가면 자동화는 그것을 "차이 있음" 으로 읽는다 (${String(e)})`,
      '--dir 가 디렉터리를 가리키는지, 읽기 권한이 있는지 확인하라',
    );
  }
  const files = entries.filter((f) => f.startsWith(FILE_PREFIX) && f.endsWith('.json')).sort();
  if (files.length === 0) {
    fail(
      `${dir} 에 ${FILE_PREFIX}*.json 이 없음`,
      '대조 파일이 없는 것은 차이가 없다는 뜻이 아니라 아무도 대조하지 않았다는 뜻이다 — 침묵을 통과로 읽으면 안 된다',
      '플러그인 Generate 가 내려준 designer-parity JSON 을 이 디렉터리에 넣거나 --file 로 지정하라',
    );
  }
  const chosen = files[files.length - 1];
  if (files.length > 1) {
    console.error(`⚠️  대조 파일이 ${files.length}개 — 가장 마지막 파일 하나만 읽는다: ${chosen}`);
  }
  return { path: resolve(dir, chosen), source: { chosen, total: files.length } };
}

function main(): never {
  if (process.argv.includes('--help') || process.argv.includes('-h')) {
    console.log(
      'Usage: tsx reverse/diff_designer.ts [--file=<json>] [--dir=reverse/incoming] [--out=<md>] [--ladder-dir=<coui_core/lib/src>]\n' +
        '\n' +
        'Exit: 0 차이 없음 · 1 차이 있음 · 2 인프라 실패',
    );
    return process.exit(EXIT_NO_DIFF);
  }

  const { path, source } = pickFile();

  let text: string;
  try {
    text = readFileSync(path, 'utf8');
  } catch (e) {
    return fail(
      `대조 파일을 읽지 못함: ${path}`,
      `읽기 실패가 종료 코드 1 로 새어 나가면 자동화는 그것을 "차이 있음" 으로 읽는다 (${String(e)})`,
      '파일 권한을 확인하라. 같은 이름의 디렉터리가 아닌지도 확인하라',
    );
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch (e) {
    return fail(
      `JSON 파싱 실패: ${path}`,
      `깨진 파일을 조용히 건너뛰면 "차이 없음" 과 구별되지 않는다 (${String(e)})`,
      '파일을 다시 내려받아라',
    );
  }

  const env = validate(parsed, path);
  // 사다리는 봉투 검증 뒤에 읽는다 — 봉투가 틀린 실행에서 사다리 오류를 먼저
  // 보고하면 고칠 곳을 잘못 짚는다. 사다리 실패는 그 자체로 인프라 실패다.
  const ladder = loadLadder(resolve(process.cwd(), argValue('--ladder-dir') ?? DEFAULT_LADDER_DIR));
  const markdown = render(env, ladder, source);

  const outPath = argValue('--out');
  if (outPath !== null) {
    const at = resolve(process.cwd(), outPath);
    writeOut(at, `${markdown}\n`, '리포트');
    console.log(`리포트 기록: ${at}`);
  } else {
    console.log(markdown);
  }

  return process.exit(env.sets.some((s) => hasDiff(s, ladder)) ? EXIT_DIFF : EXIT_NO_DIFF);
}

main();
