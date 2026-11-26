/// <reference types="@figma/plugin-typings" />

// 소비 파일 점검 — CoUI 라이브러리를 쓰는 제품 화면 파일의 글자 중, 코드로 옮길 때
// CoUI 와 갈라질 것을 읽기 전용으로 센다.
//
// ## 왜 있는가
//
// 다른 점검(드리프트 점검 · 낡은 세트 보기 · CI 가드)은 전부 라이브러리 파일과 이
// 저장소 안만 본다. 소비 파일은 아무도 보지 않는다. 그런데 앱 개발자가 옮기는 것은
// 소비 파일이다 — 텍스트 스타일이 붙은 글자는 역할 이름 하나(`labelSmall`)로 옮겨져
// CoUI 가 바뀌면 같이 따라가고, 숫자로만 적힌 글자는 옮기는 순간 굳는다. 실제로 한
// 제품 파일에서 스타일 없이 그린 글자가 수백 개였고, 그 숫자가 앱 코드에서 "CoUI
// 역할에 없는 글자 스타일" 백여 곳으로 다시 나타났다. 넘기기 **전에** 디자이너가
// 볼 자리가 없었다.
//
// ## 무엇을 재사용하고 무엇을 재사용하지 않는가
//
// "이 글자는 어느 역할인가 · 역할과 어디가 다른가" 의 판정은 빌더가 라벨에 스타일을
// 붙일지 정할 때 쓰는 그 함수다 — `text-nodes.ts` 의 `roleDeparture` 와 그 함수가
// 읽는 역할 표(`compat/v1.ts` 의 `roleMetrics` · `roleNames`). 여기서 비교를 다시
// 적으면 판정이 두 벌이 되고, 역할 표나 비교 규칙이 바뀌는 날 이 목록은 빌더가
// 스타일을 붙이는 글자를 "역할에 없다" 고 신고한다(또는 그 반대). 그래서 여기서
// 하는 일은 캔버스의 값을 그 함수가 받는 모양(`StatedTypography`)으로 옮기는 것과,
// 필드를 하나씩 넘겨 "어느 필드가 다른가" 를 모두 묻는 것뿐이다.
//
// 스타일 이름도 같다 — CoUI 스타일인지는 `text-styles.ts` 의 `textStyleNameOf` 가
// 역할마다 만드는 이름과 같은지로 판정한다. CoUI 변수인지는 exporter 가 내보내는
// 컬렉션 · 변수 이름(`Semantic/ Typography` 의 `font-size/<역할>` 등)으로 판정하고,
// 컬렉션 이름은 `variables.ts` 의 `canonicalCollection` 으로 맞춘다.
//
// ## 모드 — 스타일이 그리는 크기는 글자가 푸는 모드의 값이다
//
// CoUI 텍스트 스타일은 크기와 자간을 역할의 `Semantic/ Typography` 변수에 묶는다.
// 그래서 스타일을 붙였을 때 그려지는 크기는 그 글자가 푸는 컬렉션 모드의 값이고,
// 소비 파일은 대개 첫 모드(Mobile)로 그린다 — 거기서는 display · headline 이 코드
// 스케일(Desktop)보다 한두 단계 작다. 역할 표만 보고 견주면 Mobile 의 24 를
// Headline/Small 로 제안하고, 그 스타일은 16 으로 그린다. 그래서 글자가 푸는 모드를
// 읽고(`resolvedVariableModes`), 그 모드에서 역할이 그리는 값과 견준다
// (`roleMetricsIn` — exporter 가 변수를 만드는 그 표). 모드를 읽지 못하면 코드
// 스케일과 견주고, 모드마다 크기가 다른 역할이면 "그림이 바뀌지 않는다" 고 말하지
// 않는다.
//
// ## 본문 서체 — 어디서 읽는가
//
// 글꼴 비교에는 본문 서체 이름이 필요하다. 범위 안의 CoUI 스타일과 `font/family/*`
// 변수에서 먼저 읽고, 없으면 범위 안 CoUI 컴포넌트의 글자가 그려진 서체에서, 그래도
// 없으면 켜진 라이브러리 `Primitives` 의 서체 변수 이름에서 읽는다(읽기만 —
// 가져오지 않는다). 셋 다 없으면 글꼴은 비교하지 않고, 그때는 스타일을 붙여도
// 그림이 그대로라고 말하지 않는다 — 다른 서체의 글자에 스타일을 붙이면 서체가 바뀐다.
//
// ## 순수 판정과 Figma 읽기를 나눈 이유
//
// 판정(`classifyRun` · `buildConsumerAuditReport`)은 Figma 타입을 받지 않는다 —
// 셀프테스트에 `figma` 전역이 없고, 실제 파일에서 잰 사례를 데이터로 그대로 적어
// 각 분류를 실패시킬 수 있어야 하기 때문이다. 캔버스를 걷는 쪽(`collectRuns`)도
// 노드와 조회 함수를 주입받아 같은 이유로 노드 더블 위에서 돈다.
//
// **아무것도 바꾸지 않는다.** 항목을 눌러 노드를 선택하고 화면을 옮기는 것
// (`revealAuditNodes`)이 이 명령이 문서에 하는 일의 전부다.

import {
  isMonoRole,
  roleHasMode,
  roleMetrics,
  roleMetricsIn,
  roleNames,
  roleSizeVariesByMode,
  type RoleMetrics,
} from './compat/v1';
import { isSansFamilyVariableName } from './mono-hangul';
import { weightStyle } from './paint';
import {
  hangulRuns,
  roleDeparture,
  roleLeaf,
  textFaceOf,
  type RoleStatedField,
  type StatedTypography,
} from './text-nodes';
import { textStyleNameOf } from './text-styles';
import { canonicalCollection } from './variables';

// ─── 분류 ────────────────────────────────────────────────────────────────────

export type AuditCategory =
  | 'override'
  | 'off-role'
  | 'no-style'
  | 'local-style'
  | 'styled'
  | 'role-weight'
  | 'mono-hangul'
  | 'library'
  | 'other-library';

export interface AuditCategoryInfo {
  key: AuditCategory;
  /** 경고면 목록 위에, 통과 · 대상 아님이면 접힌 칸에 간다. */
  warn: boolean;
  label: string;
}

/** 목록의 순서이기도 하다 — 경고가 먼저, 고치기 어려운 것부터. */
export const kAuditCategories: readonly AuditCategoryInfo[] = [
  { key: 'override', warn: true, label: '경고 · 덮어쓰기' },
  { key: 'off-role', warn: true, label: '경고 · 역할에 없는 조합' },
  { key: 'no-style', warn: true, label: '경고 · 스타일 없음' },
  { key: 'local-style', warn: true, label: '경고 · 로컬 스타일' },
  { key: 'styled', warn: false, label: '통과 · CoUI 스타일' },
  { key: 'role-weight', warn: false, label: '통과 · 역할 변수 + 굵기만 다름' },
  { key: 'mono-hangul', warn: false, label: '통과 · 고정폭 글 안 한글' },
  { key: 'library', warn: false, label: '대상 아님 · CoUI 컴포넌트 안' },
  { key: 'other-library', warn: false, label: '대상 아님 · 다른 라이브러리 컴포넌트 안' },
];

/** 목록의 한 줄이 속하는 분류 — 글자 구간의 분류 아홉과, 글자가 아니라 변수를 보는
 *  「가져온 사본 중복」(`library-copies.ts`). 뒤의 것은 구간 수에 섞이지 않는다 — 세는
 *  단위(구간 · 옛 사본)가 달라서, 합치면 "경고 N" 이 무엇의 수인지 말하지 못한다. */
export type AuditGroupCategory = AuditCategory | 'library-copy' | 'old-brand' | 'brand-primitive';

function categoryInfo(key: AuditCategory): AuditCategoryInfo {
  const info = kAuditCategories.find((c) => c.key === key);
  if (info == null) throw new Error(`unknown audit category ${key}`);
  return info;
}

/** 변수가 글자에 묶이는 타이포 필드 — 판정이 읽는 것만. */
export type AuditBoundField = 'fontSize' | 'letterSpacing' | 'fontWeight' | 'lineHeight' | 'fontFamily';

/** 묶인 변수를 컬렉션 이름과 변수 이름으로. 판정은 id 가 아니라 이름을 본다 —
 *  소비 파일의 변수는 라이브러리에서 온 것이라 id 가 파일마다 다르다. */
export interface VariableRef {
  collection: string;
  name: string;
}

export type AuditLineHeight = { unit: 'AUTO' } | { unit: 'PERCENT' | 'PIXELS'; value: number };

export interface AuditLetterSpacing {
  unit: 'PERCENT' | 'PIXELS';
  value: number;
}

/** 한 구간(같은 모양으로 칠해진 글자 묶음)이 그려진 모양. */
export interface RunLook {
  family: string;
  /** 글꼴 face (`'Bold'`) — 캔버스가 그리는 굵기. */
  face: string;
  size: number;
  lineHeight: AuditLineHeight;
  letterSpacing: AuditLetterSpacing;
  textStyle: { name: string; remote: boolean } | null;
  bound: Partial<Record<AuditBoundField, VariableRef>>;
  /** 글자가 푸는 `Semantic/ Typography` 모드 이름(`Mobile`). 읽지 못했으면 null
   *  — 그때는 코드 스케일(Desktop)과 견준다. */
  mode: string | null;
}

export type RunContext =
  /** 화면에 직접 쓴 글자. */
  | { kind: 'own' }
  /** 이 파일의 로컬 컴포넌트(정의 또는 인스턴스) 안. */
  | { kind: 'local-component'; component: string }
  /** 라이브러리 컴포넌트 인스턴스 안. `overridden` 은 인스턴스에서 덮어쓴 타이포 필드. */
  | { kind: 'library'; component: string; coui: boolean; overridden: readonly string[] };

export interface TextRun {
  nodeId: string;
  pageId: string;
  pageName: string;
  /** 이 구간의 글자 — 목록의 견본. */
  text: string;
  /** 어디에 있나 — 화면(페이지 직계 프레임) 또는 컴포넌트 이름. */
  where: string;
  context: RunContext;
  /** 라이브러리 안에서 덮어쓰지 않은 글자는 읽지 않는다(null) — 라이브러리 몫이다. */
  look: RunLook | null;
  /** 같은 글 안의 고정폭 구간이 그리는 코드 역할 — 고정폭 글의 한글을 본문
   *  서체로 칠한 구간(`mono-hangul.ts`)을 알아보는 데 쓴다. 없으면 null. */
  codeRole?: string | null;
}

/** 판정에 필요한 이 문서의 사실. */
export interface AuditEnv {
  /** 본문 서체 이름. 읽지 못했으면 null — 그때는 글꼴을 비교하지 않는다. */
  sans: string | null;
  /** 고정폭 서체 이름(exporter 가 내보낸 것). */
  mono: string | null;
}

export interface RunVerdict {
  category: AuditCategory;
  /** 묶는 열쇠이자 목록에 보이는 한 줄. */
  signature: string;
  /** 무엇을 하면 되나. 통과 · 대상 아님은 빈 문자열. */
  action: string;
  /** 비교한 역할 — 스타일의 역할, 묶인 변수의 역할, 또는 가장 가까운 역할. */
  role: string | null;
  departs: RoleStatedField[];
}

const kFieldKo: Record<RoleStatedField, string> = {
  size: '크기',
  weight: '굵기',
  lineHeight: '행간',
  letterSpacing: '자간',
  family: '글꼴',
};

// 인스턴스에서 덮어쓰면 글자의 모양이 바뀌는 필드. `boundVariables` 는 빠진다 —
// 글자 내용을 문자열 변수에 묶은 것도 같은 이름으로 나와 모양과 무관하게 걸리고,
// 타이포 변수를 바꿨다면 바뀐 값이 `fontSize` · `fontName` 으로 함께 나온다.
// `styledTextSegments` 도 빠진다 — 글자만 고쳐 써도 구간이 다시 나뉘어 나온다.
const kTypographyOverrideKo: Record<string, string> = {
  fontName: '글꼴·굵기',
  fontSize: '크기',
  lineHeight: '행간',
  letterSpacing: '자간',
  textStyleId: '텍스트 스타일',
};

/** 인스턴스 덮어쓰기 목록 중 글자 모양을 바꾸는 것만. */
export function typographyOverrides(fields: readonly string[]): string[] {
  return fields.filter((f) => f in kTypographyOverrideKo);
}

// ─── 역할 판정 — roleDeparture 를 필드별로 묻는다 ────────────────────────────

const kStatedFields: readonly RoleStatedField[] = ['size', 'weight', 'lineHeight', 'letterSpacing', 'family'];

/** 한 필드만 진술한 모양. 진술하지 않은 필드는 역할을 따르므로 다를 수 없다 —
 *  `roleDeparture` 의 그 성질로 "이 필드가 다른가" 를 하나씩 묻는다. */
function onlyField(stated: StatedTypography, field: RoleStatedField): StatedTypography {
  switch (field) {
    case 'size':
      return { size: stated.size };
    case 'weight':
      return { style: stated.style };
    case 'lineHeight':
      return { lineHeightPercent: stated.lineHeightPercent, lineHeightPx: stated.lineHeightPx };
    case 'letterSpacing':
      return { letterSpacingEm: stated.letterSpacingEm };
    case 'family':
      return { family: stated.family };
  }
}

/** 캔버스가 진술한 모양. `autoLine` 은 행간이 자동이라 비교할 값이 없다는 뜻이다. */
interface CanvasStatement {
  stated: StatedTypography;
  autoLine: boolean;
}

// 캔버스의 숫자는 32비트로 저장된다(`-0.14` 가 `-0.14000000059…` 로 돌아온다).
// `roleDeparture` 의 허용오차는 같은 export 숫자끼리의 비교를 위한 것이라, 캔버스
// 값은 표시 단위에서 반올림해 넘긴다 — 행간은 0.01%, 자간은 1e-5 em.
const roundTo = (value: number, step: number): number => Math.round(value / step) * step;
const kPercentStep = 0.01;
const kEmStep = 1e-5;

function statementOf(look: RunLook, env: AuditEnv): CanvasStatement {
  const ls = look.letterSpacing;
  const em = ls.unit === 'PIXELS' ? ls.value / look.size : ls.value / 100;
  const lh = look.lineHeight;
  return {
    stated: {
      size: look.size,
      // 같은 굵기를 서체마다 다르게 적는다(`Semi Bold` · `SemiBold`) — 표기가 다른
      // 것을 굵기가 다른 것으로 읽지 않는다.
      style: textFaceOf(look.face),
      letterSpacingEm: roundTo(em, kEmStep),
      lineHeightPercent: lh.unit === 'PERCENT' ? roundTo(lh.value, kPercentStep) : undefined,
      lineHeightPx: lh.unit === 'PIXELS' ? roundTo(lh.value, kPercentStep) : undefined,
      family: familyTokenOfLook(look.family, env),
    },
    autoLine: lh.unit === 'AUTO',
  };
}

/** `'sans' | 'mono'` 은 역할 표의 어휘, 둘 다 아니면 `'other'` — 어느 역할과도
 *  다르다. 본문 서체를 모르면 null(비교하지 않음). */
function familyTokenOfLook(family: string, env: AuditEnv): string | null {
  if (env.mono != null && family === env.mono) return 'mono';
  if (env.sans == null) return null;
  return family === env.sans ? 'sans' : 'other';
}

/**
 * 역할에 맞춘 진술. 행간을 역할과 다른 단위로 적었으면 같은 크기에서의 그 역할의
 * 단위로 바꾼다 — 배수 역할에 온 픽셀 행간은 퍼센트로, 고정 줄 상자 역할(코드
 * 역할의 21px)에 온 퍼센트 행간은 픽셀로. 소비 파일에서 묻는 것은 "스타일을 붙이면
 * 그림이 바뀌는가" 이고, 13px 에 19.5px 행간은 150% 와, 12px 에 175% 는 21px 상자와
 * 같은 그림이다. 양쪽으로 바꿔야 같은 그림이 적힌 단위에 따라 다른 답을 받지 않는다.
 * (빌더는 반대로 단위가 다르면 다른 진술로 본다 — 거기서 묻는 것은 자기가 무엇을
 * 진술했느냐라서다.)
 */
function statedForRole(metrics: RoleMetrics | undefined, s: CanvasStatement, size: number): StatedTypography {
  const st = s.stated;
  if (metrics == null) return st;
  if (st.lineHeightPx != null && metrics.lineHeightPx == null && metrics.lineHeight != null) {
    return {
      ...st,
      lineHeightPx: undefined,
      lineHeightPercent: roundTo((st.lineHeightPx / size) * 100, kPercentStep),
    };
  }
  if (st.lineHeightPercent != null && metrics.lineHeightPx != null) {
    return {
      ...st,
      lineHeightPercent: undefined,
      lineHeightPx: roundTo((st.lineHeightPercent / 100) * size, kPercentStep),
    };
  }
  return st;
}

/** 역할과 다른 필드 전부, 역할 표의 필드 순서로. [mode] 는 글자가 푸는 타이포
 *  모드 — 그 모드에서 역할이 그리는 크기 · 자간과 견준다(null 이면 코드 스케일). */
function departuresFrom(role: string, s: CanvasStatement, size: number, mode: string | null): RoleStatedField[] {
  const metrics = roleMetricsIn(role, mode);
  const stated = statedForRole(metrics, s, size);
  const out = kStatedFields.filter((f) => roleDeparture(role, onlyField(stated, f), metrics) === f);
  // 자동 행간은 진술한 값이 없어 `roleDeparture` 가 볼 수 없다. 역할은 언제나
  // 줄 높이를 진술하므로(배수든 상자든) 자동은 그것과 다른 그림이다.
  const roleStatesLine = metrics != null && (metrics.lineHeight != null || metrics.lineHeightPx != null);
  if (s.autoLine && roleStatesLine && !out.includes('lineHeight')) {
    return kStatedFields.filter((f) => f === 'lineHeight' || out.includes(f));
  }
  return out;
}

function weightOfFace(face: string): number | null {
  const normalized = textFaceOf(face);
  for (let w = 100; w <= 900; w += 100) if (weightStyle(w) === normalized) return w;
  return null;
}

/**
 * 가장 가까운 역할 — 크기가 같은 역할이 먼저, 그다음 글꼴이 같은 것, 다른 필드가
 * 적은 것, 크기 차이 · 굵기 차이가 작은 것, 모드마다 크기가 같은 역할, 끝으로 역할
 * 표의 순서. 비교 자체는 전부 `departuresFrom` 이 하고, 여기는 순위만 매긴다.
 *
 * 크기와 자간은 글자가 푸는 모드에서 역할이 그리는 값과 견준다. Mobile 에서는
 * Headline/Medium 과 Title/Large 가 같은 20 처럼 두 역할이 같은 그림을 그리기도
 * 하는데, 그때는 모드마다 크기가 같은 역할을 고른다 — 숫자로 적은 글자는 모든
 * 모드에서 그 크기이고, 그것을 그대로 옮기는 역할은 그쪽이다.
 */
export function nearestRole(look: RunLook, env: AuditEnv): { role: string; departs: RoleStatedField[] } | null {
  const s = statementOf(look, env);
  const face = weightOfFace(look.face);
  const roles = roleNames();
  let best: { role: string; departs: RoleStatedField[]; key: number[] } | null = null;
  for (let index = 0; index < roles.length; index++) {
    const role = roles[index];
    const m = roleMetricsIn(role, look.mode);
    if (m == null) continue;
    const departs = departuresFrom(role, s, look.size, look.mode);
    const key = [
      departs.includes('size') ? 1 : 0,
      departs.includes('family') ? 1 : 0,
      departs.length,
      m.fontSize == null ? 0 : Math.abs(m.fontSize - look.size),
      face == null || m.fontWeight == null ? 0 : Math.abs(m.fontWeight - face),
      roleSizeVariesByMode(role) ? 1 : 0,
      index,
    ];
    if (best == null || lexLess(key, best.key)) best = { role, departs, key };
  }
  return best == null ? null : { role: best.role, departs: best.departs };
}

function lexLess(a: readonly number[], b: readonly number[]): boolean {
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return a[i] < b[i];
  return false;
}

// ─── CoUI 의 이름들 ─────────────────────────────────────────────────────────

let styleRoleIndex: Map<string, string> | null = null;

/** CoUI 텍스트 스타일 이름이면 그 역할, 아니면 null. 이름은 `textStyleNameOf` 가
 *  역할마다 만드는 것 — Import 가 스타일을 그 이름으로 만든다. */
export function couiStyleRole(name: string): string | null {
  if (styleRoleIndex == null) {
    styleRoleIndex = new Map();
    for (const role of roleNames()) {
      const styleName = textStyleNameOf(role);
      if (styleName != null) styleRoleIndex.set(styleName, role);
    }
  }
  return styleRoleIndex.get(name) ?? null;
}

const kSemanticTypography = 'Semantic/Typography';
const kPrimitives = 'Primitives';
const kSemanticTypographyPrefixes = ['font-size/', 'letter-spacing/', 'font-weight/', 'line-height/'];
const kPrimitiveTypographyPrefixes = ['font/size/', 'font/family/', 'font/weight/', 'letter-spacing/', 'line-height/'];

/** exporter 가 내보내는 타이포 변수인가 — 컬렉션과 변수 이름으로. */
export function isCouiTypographyVariable(ref: VariableRef): boolean {
  const collection = canonicalCollection(ref.collection);
  if (collection === kSemanticTypography) {
    return kSemanticTypographyPrefixes.some((p) => ref.name.startsWith(p));
  }
  if (collection === kPrimitives) {
    return kPrimitiveTypographyPrefixes.some((p) => ref.name.startsWith(p));
  }
  return false;
}

/** `Semantic/ Typography` 의 `<접두>/<역할>` 변수가 가리키는 역할. `letter-spacing/
 *  size-14` 처럼 크기 단계인 변수는 역할이 아니다. */
function roleOfVariable(ref: VariableRef | undefined, prefix: string): string | null {
  if (ref == null || canonicalCollection(ref.collection) !== kSemanticTypography) return null;
  if (!ref.name.startsWith(prefix)) return null;
  const leaf = ref.name.slice(prefix.length);
  return roleNames().find((r) => roleLeaf(r) === leaf) ?? null;
}

/** `Primitives` 의 `font/family/<이름>` 이 말하는 서체 이름. */
export function familyOfVariable(ref: VariableRef): string | null {
  if (canonicalCollection(ref.collection) !== kPrimitives) return null;
  const prefix = 'font/family/';
  return ref.name.startsWith(prefix) ? ref.name.slice(prefix.length) : null;
}

// ─── 한 구간의 판정 ─────────────────────────────────────────────────────────

const fmtNum = (n: number): string => {
  const r = Math.round(n * 100) / 100;
  return Object.is(r, -0) ? '0' : String(r);
};

/** 목록에 적는 모양 — `Pretendard Bold 12 · 행간 120% · 자간 -1%`. */
export function lookText(look: RunLook): string {
  const lh = look.lineHeight;
  const line = lh.unit === 'AUTO' ? '자동' : `${fmtNum(lh.value)}${lh.unit === 'PERCENT' ? '%' : 'px'}`;
  const ls = look.letterSpacing;
  const tracking = ls.value === 0 ? '0' : `${fmtNum(ls.value)}${ls.unit === 'PERCENT' ? '%' : 'px'}`;
  return `${look.family} ${look.face} ${fmtNum(look.size)} · 행간 ${line} · 자간 ${tracking}`;
}

function styleNameOfRole(role: string | null): string {
  return (role == null ? null : textStyleNameOf(role)) ?? '(역할 없음)';
}

function departsText(departs: readonly RoleStatedField[]): string {
  return departs.map((f) => kFieldKo[f]).join(' · ');
}

interface LookJudgement {
  role: string | null;
  departs: RoleStatedField[];
  /** 크기나 자간이 그 역할의 `Semantic/ Typography` 변수에 묶였나. */
  boundToRole: boolean;
  /** 크기가 그 역할의 변수에 묶였나 — 그러면 크기는 모든 모드에서 역할을 따른다. */
  sizeFollowsRole: boolean;
  /** 견준 모드 — 역할 표에 그 모드의 줄이 없으면(읽지 못했으면) null, 코드 스케일. */
  mode: string | null;
}

/** 크기가 역할 변수에 묶인 글자가 그려진 크기에서, 그 크기를 그리는 역할의 모드.
 *  모드를 읽지 못했을 때만 쓴다. 같은 크기를 그리는 모드가 여럿이면 그 모드들의
 *  값이 같으므로 어느 것이든 같은 답이다. */
function modeDrawnAt(role: string, size: number): string | null {
  for (const [mode, row] of Object.entries(roleMetrics(role)?.modes ?? {})) {
    if (row.fontSize === size) return mode;
  }
  return null;
}

/**
 * 스타일 없는 글자의 역할 판정. 크기나 자간이 역할 변수에 묶였으면 그 역할이 곧
 * 의도이고, 묶인 필드는 진술하지 않은 것으로 본다 — 변수의 값을 그리는 것이니
 * 역할을 따른다. 남은 필드는 글자가 푸는 모드에서 역할이 그리는 값과 견준다.
 */
function judgeLook(look: RunLook, env: AuditEnv): LookJudgement {
  const sizeRole = roleOfVariable(look.bound.fontSize, 'font-size/');
  const trackingRole = roleOfVariable(look.bound.letterSpacing, 'letter-spacing/');
  const boundRole = sizeRole ?? trackingRole;
  if (boundRole == null) {
    const near = nearestRole(look, env);
    const role = near?.role ?? null;
    return {
      role,
      departs: near?.departs ?? [],
      boundToRole: false,
      sizeFollowsRole: false,
      mode: role != null && roleHasMode(role, look.mode) ? look.mode : null,
    };
  }
  const sizeFollowsRole = sizeRole === boundRole;
  // 크기가 묶였으면 그려진 크기가 곧 그 모드의 값이다 — 모드를 읽지 못했어도
  // 그 크기를 그리는 모드로 견줄 수 있다.
  const mode = look.mode ?? (sizeFollowsRole ? modeDrawnAt(boundRole, look.size) : null);
  const s = statementOf(look, env);
  const stated: StatedTypography = { ...s.stated };
  if (sizeFollowsRole) stated.size = undefined;
  if (trackingRole === boundRole) stated.letterSpacingEm = undefined;
  return {
    role: boundRole,
    departs: departuresFrom(boundRole, { stated, autoLine: s.autoLine }, look.size, mode),
    boundToRole: true,
    sizeFollowsRole,
    mode: roleHasMode(boundRole, mode) ? mode : null,
  };
}

/** 역할 이름 옆에 붙이는 모드 — 모드마다 크기가 다른 역할만. 같은 이름이
 *  모드마다 다른 크기를 가리키므로, 목록을 읽는 사람이 어느 크기인지 알아야 한다. */
function modeTag(j: LookJudgement): string {
  if (j.role == null || !roleSizeVariesByMode(j.role)) return '';
  return j.mode != null ? ` (${j.mode})` : ' (Desktop 값)';
}

/** 그 역할의 굵기를 캔버스가 쓰는 face 이름으로 — 문장에 적는 것. */
function roleFaceOf(role: string | null): string {
  return weightStyle(role == null ? null : roleMetrics(role)?.fontWeight);
}

/**
 * 값이 역할과 같은 글자에 스타일을 붙이라고 할 때, 붙이면 그림이 그대로인지의
 * 문장. 그대로라고 말할 수 있는 것은 견준 것이 그림의 전부일 때뿐이다:
 *
 * - 글꼴을 비교하지 못했으면(본문 서체를 모름) 말하지 않는다 — 다른 서체의
 *   글자에 스타일을 붙이면 서체가 바뀐다.
 * - 모드마다 크기가 다른 역할을 숫자로 적은 글자는 견준 모드에서만 같다. 모드를
 *   읽었으면 그 모드에서는 그대로라고, 못 읽었으면 Desktop 값과 같을 뿐이라고 말한다.
 */
function attachConsequence(j: LookJudgement, styleName: string, familyChecked: boolean): string {
  const notes: string[] = [];
  const modeSensitive = j.role != null && roleSizeVariesByMode(j.role) && !j.sizeFollowsRole;
  if (modeSensitive && j.mode == null) {
    notes.push(
      'Desktop 값과 같다 — Mobile · Tablet 모드로 그려지는 글자면 붙일 때 크기가 바뀌므로 그 모드에서 맞는 역할을 고른다',
    );
  } else if (modeSensitive) {
    notes.push(`${j.mode} 에서는 값이 같아 그림이 그대로이고, 다른 모드에서는 ${styleName} 의 크기를 따른다`);
  } else if (familyChecked) {
    notes.push('값이 같아 그림은 바뀌지 않는다');
  } else {
    notes.push('크기 · 굵기 · 행간 · 자간이 같다');
  }
  if (!familyChecked) {
    notes.push('글꼴은 비교하지 못했다(본문 서체를 읽지 못했다) — 붙이면 CoUI 본문 서체로 바뀔 수 있다');
  }
  return notes.join('. ');
}

/**
 * 고정폭 글의 한글을 본문 서체로 칠한 구간인가 — `mono-hangul.ts` 가 소비 파일에서
 * 칠하는 모양. 칠한 구간은 스타일이 떨어지고(Figma 에는 구간의 서체만 덮는 길이
 * 없다) 본문 서체로 그려지지만, 크기 · 줄 상자 · 자간은 코드 역할의 것이다. 역할
 * 표로 견주면 본문 역할과 행간 · 자간이 달라 "역할에 없는 조합" 으로 나오고, 그
 * 제안을 따르면 한글만 코드 줄 격자에서 벗어난다. 그래서 같은 글에 코드 역할의
 * 고정폭 구간이 있고, 이 구간이 한글뿐이며 본문 서체이고, 글꼴 말고는 그 코드
 * 역할과 같을 때 통과로 센다.
 */
function isRepaintedMonoHangul(run: TextRun, look: RunLook, env: AuditEnv): boolean {
  if (run.codeRole == null || look.textStyle != null) return false;
  const runs = hangulRuns(run.text);
  if (runs.length !== 1 || runs[0][0] !== 0 || runs[0][1] !== run.text.length) return false;
  const s = statementOf(look, env);
  // 본문 서체로 그렸나 — 본문 서체를 모르면 고정폭이 아니기만 하면 된다.
  if (s.stated.family === 'mono' || s.stated.family === 'other') return false;
  const stated: StatedTypography = { ...s.stated, family: undefined };
  return departuresFrom(run.codeRole, { stated, autoLine: s.autoLine }, look.size, look.mode).length === 0;
}

/**
 * 한 구간의 분류. 순수 — Figma 를 읽지 않는다.
 *
 *   라이브러리 안 · CoUI 아님           → 대상 아님(다른 라이브러리)
 *   라이브러리 안 · CoUI · 덮어쓰지 않음 → 대상 아님(라이브러리 몫)
 *   라이브러리 안 · CoUI · 타이포 덮어씀 → 경고 · 덮어쓰기
 *   CoUI 라이브러리 스타일              → 통과
 *   그 밖의 스타일(로컬 · 다른 라이브러리) → 경고 · 로컬 스타일
 *   고정폭 글 안 한글을 본문 서체로 칠함  → 통과
 *   스타일 없음 · 역할과 같음            → 경고 · 스타일 없음 (스타일만 붙인다)
 *   스타일 없음 · 굵기만 다름 · 역할 변수 → 통과 (점검 요구사항의 결정 — 문서의 표 참고)
 *   스타일 없음 · 굵기만 다름 · 변수 없음 → 경고 · 스타일 없음 (붙이면 굵기가 역할의 것이 된다)
 *   스타일 없음 · 그 밖에 다름           → 경고 · 역할에 없는 조합
 */
export function classifyRun(run: TextRun, env: AuditEnv): RunVerdict {
  const ctx = run.context;
  const pass = (category: AuditCategory, signature: string, role: string | null = null): RunVerdict => ({
    category,
    signature,
    action: '',
    role,
    departs: [],
  });
  if (ctx.kind === 'library') {
    if (!ctx.coui) return pass('other-library', ctx.component);
    if (ctx.overridden.length === 0 || run.look == null) return pass('library', ctx.component);
    const j = judgeLook(run.look, env);
    const fields = ctx.overridden.map((f) => kTypographyOverrideKo[f] ?? f).join(' · ');
    return {
      category: 'override',
      signature: `${ctx.component} · ${lookText(run.look)} (덮어씀: ${fields})`,
      action: `인스턴스에서 덮어쓴 글자 모양을 되돌린다(Reset) — 이 모양이 필요하면 ${ctx.component} 리디자인 이슈로 올린다`,
      role: j.role,
      departs: j.departs,
    };
  }
  const look = run.look;
  if (look == null) throw new Error(`run ${run.nodeId}: own text must carry its look`);
  if (look.textStyle != null) {
    const role = couiStyleRole(look.textStyle.name);
    if (role != null && look.textStyle.remote) return pass('styled', look.textStyle.name, role);
    const near = nearestRole(look, env);
    const where = look.textStyle.remote ? '다른 라이브러리' : '로컬';
    return {
      category: 'local-style',
      signature: `${where} 스타일 "${look.textStyle.name}" · ${lookText(look)}`,
      action:
        `CoUI 라이브러리의 ${styleNameOfRole(near?.role ?? null)} 스타일로 바꿔 붙인다` +
        (near != null && near.departs.length > 0 ? ` (달라지는 값: ${departsText(near.departs)})` : ''),
      role: near?.role ?? null,
      departs: near?.departs ?? [],
    };
  }
  if (isRepaintedMonoHangul(run, look, env)) {
    return pass('mono-hangul', `${styleNameOfRole(run.codeRole ?? null)} 안 한글 · ${look.family}`, run.codeRole);
  }
  const j = judgeLook(look, env);
  const styleName = styleNameOfRole(j.role);
  const tag = modeTag(j);
  const familyChecked = statementOf(look, env).stated.family != null;
  if (j.departs.length === 0) {
    return {
      category: 'no-style',
      signature: `${lookText(look)} = ${styleName}${tag}`,
      action: `${styleName} 스타일을 붙인다 — ${attachConsequence(j, styleName, familyChecked)}`,
      role: j.role,
      departs: [],
    };
  }
  const roleFace = roleFaceOf(j.role);
  if (j.departs.length === 1 && j.departs[0] === 'weight') {
    // 이슈가 통과로 정한 모양: 크기 · 자간이 역할 변수에 묶이고 굵기만 다르다.
    // 변수 없이 같은 값을 적은 글자에는 그 모양을 만들라고 하지 않는다 — 캔버스
    // 규칙은 역할의 시맨틱 변수에 묶인 채 굵기를 덮은 노드를 피할 모양으로 적는다.
    if (j.boundToRole) return pass('role-weight', `${styleName} 변수 + ${look.face}`, j.role);
    return {
      category: 'no-style',
      signature: `${lookText(look)} = ${styleName}${tag} + ${look.face}`,
      action:
        `${styleName} 스타일을 붙인다 — 붙이면 굵기가 역할 굵기로 바뀐다(${look.face} → ${roleFace}). ` +
        '그 굵기가 꼭 필요하면 그 굵기의 역할을 리디자인 이슈로 묻는다',
      role: j.role,
      departs: j.departs,
    };
  }
  // 맞출 값과 굵기는 따로 적는다 — 한 문장에 이어 쓰면 맞출 값까지 남겨도 되는
  // 것으로 읽힌다.
  const toFix = j.departs.filter((f) => f !== 'weight');
  return {
    category: 'off-role',
    signature: `${lookText(look)} → ${styleName}${tag} (${departsText(j.departs)})`,
    action:
      `${styleName} 에 맞출 값: ${departsText(toFix)}.` +
      (j.departs.includes('weight') ? ` 굵기는 스타일을 붙이면 역할 굵기로 바뀐다(${look.face} → ${roleFace}).` : '') +
      ' 그 값이 꼭 필요하면 역할 추가를 리디자인 이슈로 묻는다',
    role: j.role,
    departs: j.departs,
  };
}

// ─── 묶기 ────────────────────────────────────────────────────────────────────

/** 한 항목이 한 페이지에서 선택할 노드 수의 상한. 개수는 상한과 무관하게 참값이다. */
export const kAuditIdsPerPage = 200;
const kWhereShown = 3;
const kSampleLength = 24;

export interface AuditGroupPage {
  pageId: string;
  pageName: string;
  /** 이 페이지의 구간 수. */
  count: number;
  /** 선택할 노드 — 중복 없이, `kAuditIdsPerPage` 까지. */
  ids: string[];
}

export interface AuditGroup {
  category: AuditGroupCategory;
  label: string;
  warn: boolean;
  signature: string;
  action: string;
  role: string | null;
  departs: string[];
  /** 구간 수. */
  runs: number;
  /** 노드 수(한 노드의 여러 구간은 하나로). */
  nodes: number;
  sample: string;
  where: { name: string; count: number }[];
  /** `where` 에 적지 않은 곳의 수. */
  whereRest: number;
  pages: AuditGroupPage[];
}

export interface ConsumerAuditReport {
  scope: string;
  pageCount: number;
  textNodes: number;
  runs: number;
  /** 건너뛴 이름(범위에서 찾은 것)과 그 아래의 글자 수. */
  skippedNames: string[];
  skippedTexts: number;
  /** 건너뛰라고 적었는데 범위에 그 이름의 레이어가 없었던 것 — 철자가 틀린 이름이
   *  조용해진 목록을 깨끗한 목록으로 읽히게 하지 않도록 따로 센다. */
  unmatchedSkipNames: string[];
  familyUnknown: boolean;
  counts: Record<AuditCategory, number>;
  groups: AuditGroup[];
  /** 「가져온 사본 중복」의 요약 — `library-copies.ts` 의 `withLibraryCopies` 가 채운다.
   *  없으면 그 점검을 돌리지 않은 보고다. */
  libraryCopies?: LibraryCopySummary;
  /** 「옛 브랜드 컬렉션」의 요약 — `brand-collections.ts` 의 `withOldBrandCollections` 가
   *  채운다. 없으면 그 점검을 돌리지 않은 보고다. */
  oldBrandCollections?: OldBrandSummary;
}

/** 「옛 브랜드 컬렉션」 — 범위와 상관없이 파일 전체를 본 결과. */
export interface OldBrandSummary {
  /** 이 파일이 참조하는 옛 브랜드 컬렉션의 변수 수. */
  variables: number;
  /** 그 참조 중 짝이 있어 「옛 브랜드 컬렉션 다시 연결」이 옮기는 것 — 노드 · 스타일 · 별칭. */
  places: number;
  /** 짝(같은 이름의 `Semantic/ Color · CoUI` 변수)이 없어 옮기지 않는 참조. */
  unmatched: number;
  unmatchedNames: string[];
  /** 라이브러리 컴포넌트 안에서 덮어쓰지 않은 바인딩 — 옮기지 않는다. */
  library: number;
  /** 코드 브랜드의 원시값에 직접 묶인 변수 수와 그 참조 수 — 옮기지 않는다. */
  primitives: number;
  primitivePlaces: number;
  /** 원시값에 직접 묶인 곳 몇 개 — `페이지 · 노드 · 필드 · 변수`. */
  primitiveSamples: string[];
  /** 라이브러리의 `Semantic/ Color · CoUI` 를 읽지 못했으면 그 까닭 — 짝을 모른다. */
  libraryError: string | null;
  /** 점검을 마치지 못했으면 그 까닭. */
  error: string | null;
}

/** 「가져온 사본 중복」 — 범위와 상관없이 파일 전체를 본 결과. */
export interface LibraryCopySummary {
  /** 살펴본 원격 변수(사본)의 수. */
  remoteVariables: number;
  /** 사본이 둘 이상인 라이브러리 변수(키)의 수. */
  keys: number;
  /** 옛 사본의 수 — 현재 사본을 알 수 없는 키는 그 사본 전부. */
  copies: number;
  /** 옛 사본을 참조하는 곳 중 「옛 사본 다시 연결」이 옮기는 것 — 노드 · 스타일 · 별칭. */
  places: number;
  /** 라이브러리 컴포넌트 안에서 덮어쓰지 않은 바인딩 — 옮기지 않는다. */
  library: number;
  /** 점검을 마치지 못했으면 그 까닭. */
  error: string | null;
}

export interface ReportMeta {
  scope: string;
  pageCount: number;
  textNodes: number;
  skippedNames?: readonly string[];
  skippedTexts?: number;
  unmatchedSkipNames?: readonly string[];
}

/** 같은 분류 · 같은 값은 한 줄로. 순수. */
export function buildConsumerAuditReport(
  runs: readonly TextRun[],
  env: AuditEnv,
  meta: ReportMeta,
): ConsumerAuditReport {
  const counts = Object.fromEntries(kAuditCategories.map((c) => [c.key, 0])) as Record<AuditCategory, number>;
  interface Acc {
    verdict: RunVerdict;
    runs: number;
    nodes: Set<string>;
    sample: string;
    where: Map<string, number>;
    pages: Map<string, AuditGroupPage & { idSet: Set<string> }>;
  }
  const groups = new Map<string, Acc>();
  for (const run of runs) {
    const verdict = classifyRun(run, env);
    counts[verdict.category] += 1;
    const key = `${verdict.category}\u0001${verdict.signature}`;
    let acc = groups.get(key);
    if (acc == null) {
      acc = { verdict, runs: 0, nodes: new Set(), sample: '', where: new Map(), pages: new Map() };
      groups.set(key, acc);
    }
    acc.runs += 1;
    acc.nodes.add(run.nodeId);
    const text = run.text.replace(/\s+/g, ' ').trim();
    if (acc.sample === '' && text !== '') {
      acc.sample = text.length > kSampleLength ? `${text.slice(0, kSampleLength)}…` : text;
    }
    acc.where.set(run.where, (acc.where.get(run.where) ?? 0) + 1);
    let page = acc.pages.get(run.pageId);
    if (page == null) {
      page = { pageId: run.pageId, pageName: run.pageName, count: 0, ids: [], idSet: new Set() };
      acc.pages.set(run.pageId, page);
    }
    page.count += 1;
    if (!page.idSet.has(run.nodeId) && page.ids.length < kAuditIdsPerPage) {
      page.idSet.add(run.nodeId);
      page.ids.push(run.nodeId);
    }
  }
  const order = (c: AuditGroupCategory): number => kAuditCategories.findIndex((x) => x.key === c);
  const out: AuditGroup[] = [...groups.values()].map((acc) => {
    const info = categoryInfo(acc.verdict.category);
    const where = [...acc.where.entries()]
      .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
      .map(([name, count]) => ({ name, count }));
    return {
      category: acc.verdict.category,
      label: info.label,
      warn: info.warn,
      signature: acc.verdict.signature,
      action: acc.verdict.action,
      role: acc.verdict.role,
      departs: acc.verdict.departs.map((f) => kFieldKo[f]),
      runs: acc.runs,
      nodes: acc.nodes.size,
      sample: acc.sample,
      where: where.slice(0, kWhereShown),
      whereRest: Math.max(0, where.length - kWhereShown),
      pages: [...acc.pages.values()]
        .sort((a, b) => b.count - a.count)
        .map(({ pageId, pageName, count, ids }) => ({ pageId, pageName, count, ids })),
    };
  });
  out.sort(
    (a, b) =>
      order(a.category) - order(b.category) || b.runs - a.runs || a.signature.localeCompare(b.signature),
  );
  return {
    scope: meta.scope,
    pageCount: meta.pageCount,
    textNodes: meta.textNodes,
    runs: runs.length,
    skippedNames: [...(meta.skippedNames ?? [])],
    skippedTexts: meta.skippedTexts ?? 0,
    unmatchedSkipNames: [...(meta.unmatchedSkipNames ?? [])],
    familyUnknown: env.sans == null,
    counts,
    groups: out,
  };
}

/** 로그에 적는 경고 항목의 상한 — 나머지는 목록에 있다. */
export const kAuditLogGroups = 30;

/** 「가져온 사본 중복」의 요약 줄. 사본이 없어도 한 줄 적는다 — 보지 않은 것과 없는
 *  것이 같은 침묵으로 읽히지 않게. */
function libraryCopyLines(c: LibraryCopySummary): string[] {
  if (c.error != null) return [`⚠ 가져온 사본 중복은 보지 못했다 — ${c.error}`];
  if (c.copies === 0) return [`가져온 사본 중복 없음 — 파일 전체의 원격 변수 ${c.remoteVariables}개`];
  const lines = [
    `⚠ 가져온 사본 중복 ${c.copies} — 라이브러리 변수 ${c.keys}개를 두 번 이상 가져왔다. ` +
      `옛 사본을 참조하는 곳 ${c.places} (파일 전체) — 「옛 사본 다시 연결」로 현재 사본에 옮긴다`,
  ];
  if (c.library > 0) {
    lines.push(`  라이브러리 컴포넌트 안 ${c.library}곳은 덮어쓰지 않는다 — 라이브러리 업데이트를 받는다`);
  }
  return lines;
}

/** 「옛 브랜드 컬렉션」의 요약 줄. 없어도 한 줄 적는다 — 보지 않은 것과 없는 것이 같은
 *  침묵으로 읽히지 않게. */
function oldBrandLines(c: OldBrandSummary): string[] {
  if (c.error != null) return [`⚠ 옛 브랜드 컬렉션은 보지 못했다 — ${c.error}`];
  const lines: string[] = [];
  if (c.variables === 0) {
    lines.push('옛 브랜드 컬렉션에 묶인 곳 없음 — 파일 전체');
  } else {
    lines.push(
      `⚠ 옛 브랜드 컬렉션에 묶인 곳 ${c.places + c.unmatched} (변수 ${c.variables}개, 파일 전체) — ` +
        `「옛 브랜드 컬렉션 다시 연결」로 같은 이름의 CoUI 변수에 옮긴다`,
    );
    if (c.libraryError != null) lines.push(`  짝을 모른다 — ${c.libraryError}`);
    else if (c.unmatched > 0) lines.push(`  짝이 없어 옮기지 않는 곳 ${c.unmatched} — ${c.unmatchedNames.join(', ')}`);
    if (c.library > 0) {
      lines.push(`  라이브러리 컴포넌트 안 ${c.library}곳은 덮어쓰지 않는다 — 라이브러리 업데이트를 받는다`);
    }
  }
  if (c.primitives > 0) {
    lines.push(
      `⚠ 브랜드 원시값에 직접 묶인 곳 ${c.primitivePlaces} (변수 ${c.primitives}개) — 옮기지 않는다, ` +
        '어느 시맨틱 슬롯이어야 하는지 정해 손으로 다시 연결한다',
    );
    for (const sample of c.primitiveSamples) lines.push(`  ${sample}`);
  }
  return lines;
}

/**
 * 로그 줄. 순수 — 같은 상태에 같은 문장.
 *
 *   범위: 현재 페이지 "Home" · 글 120개 (구간 124개)
 *   ⚠ 경고 9 — 덮어쓰기 1 · 역할에 없는 조합 3 · 스타일 없음 5
 *   통과 · 대상 아님 115 — CoUI 스타일 80 · …
 *     ⚠ 역할에 없는 조합 ×3 — Pretendard Bold 12 · … → Label/Small (굵기 · 행간) — "환전 찾는 중"
 */
export function formatConsumerAudit(report: ConsumerAuditReport): string[] {
  const lines: string[] = [];
  const glyphs = report.runs === report.textNodes ? '' : ` (구간 ${report.runs}개)`;
  lines.push(`범위: ${report.scope} · 글 ${report.textNodes}개${glyphs}`);
  const part = (keys: readonly AuditCategoryInfo[]): string =>
    keys
      .filter((c) => report.counts[c.key] > 0)
      .map((c) => `${c.label.replace(/^[^·]+· /, '')} ${report.counts[c.key]}`)
      .join(' · ');
  const warnCats = kAuditCategories.filter((c) => c.warn);
  const passCats = kAuditCategories.filter((c) => !c.warn);
  const warnTotal = warnCats.reduce((s, c) => s + report.counts[c.key], 0);
  const passTotal = passCats.reduce((s, c) => s + report.counts[c.key], 0);
  const copies = report.libraryCopies;
  // 글자에 경고가 없어도 가져온 사본 중복이나 옛 브랜드 컬렉션이 있으면(또는 그 점검을 마치지 못했으면)
  // 파일 전체를 두고 "경고 없음" 이라고 말하지 않는다.
  const brands = report.oldBrandCollections;
  const copyWarn =
    (copies != null && (copies.error != null || copies.copies > 0)) ||
    (brands != null && (brands.error != null || brands.variables > 0 || brands.primitives > 0));
  const clean = copyWarn ? '글자 경고 없음 ✅' : '경고 없음 ✅';
  lines.push(warnTotal === 0 ? clean : `⚠ 경고 ${warnTotal} — ${part(warnCats)}`);
  if (passTotal > 0) lines.push(`통과 · 대상 아님 ${passTotal} — ${part(passCats)}`);
  if (copies != null) for (const line of libraryCopyLines(copies)) lines.push(line);
  if (brands != null) for (const line of oldBrandLines(brands)) lines.push(line);
  if (report.skippedTexts > 0) {
    lines.push(`건너뜀 — 이름이 ${report.skippedNames.join(', ')} 인 레이어 아래 글 ${report.skippedTexts}개`);
  }
  if (report.unmatchedSkipNames.length > 0) {
    lines.push(
      `⚠ 건너뛸 이름 중 이 범위에 없는 것: ${report.unmatchedSkipNames.join(', ')} — ` +
        '레이어 이름과 글자 하나까지 같아야 건너뛴다',
    );
  }
  if (report.familyUnknown) {
    lines.push(
      '본문 서체를 읽지 못해 글꼴은 비교하지 않았다 — 범위 안에 CoUI 스타일 · font/family 변수 · ' +
        'CoUI 컴포넌트의 글자가 없고, 켜진 라이브러리의 Primitives 에도 서체 변수가 없다.',
    );
  }
  const warnGroups = report.groups.filter((g) => g.warn);
  for (const g of warnGroups.slice(0, kAuditLogGroups)) {
    const sample = g.sample === '' ? '' : ` — "${g.sample}"`;
    lines.push(`  ⚠ ${g.label.replace(/^경고 · /, '')} ×${g.runs} — ${g.signature}${sample}`);
  }
  if (warnGroups.length > kAuditLogGroups) {
    lines.push(`  … 경고 항목 ${warnGroups.length - kAuditLogGroups}줄 더 — 아래 목록에 전부 있다`);
  }
  return lines;
}

// ─── 캔버스 걷기 — 노드와 조회를 주입받는다 ─────────────────────────────────

/** 걷는 데 필요한 노드의 모양. 실제 `SceneNode` 가 이 모양을 갖고, 셀프테스트는
 *  같은 모양의 평범한 객체를 넘긴다. */
export interface AuditNode {
  readonly id: string;
  readonly name: string;
  readonly type: string;
  readonly visible?: boolean;
  readonly children?: readonly AuditNode[];
  readonly characters?: string;
  readonly overrides?: readonly { id: string; overriddenFields: readonly string[] }[];
  readonly boundVariables?: { readonly [field: string]: unknown };
  /** 컬렉션 id → 이 노드가 푸는 모드 id. */
  readonly resolvedVariableModes?: { readonly [collectionId: string]: string };
  /** 글 전체의 글꼴 — 구간마다 다르면 `figma.mixed`(심볼). */
  readonly fontName?: { readonly family: string; readonly style: string } | symbol;
  getStyledTextSegments?(fields: readonly string[]): readonly AuditSegment[];
}

export interface AuditSegment {
  characters: string;
  fontName: { family: string; style: string };
  fontSize: number;
  lineHeight: AuditLineHeight;
  letterSpacing: AuditLetterSpacing;
  textStyleId: string;
  boundVariables?: { readonly [field: string]: { id: string } | undefined };
}

export interface AuditPage {
  id: string;
  name: string;
  children: readonly AuditNode[];
}

export interface AuditStyleInfo {
  name: string;
  remote: boolean;
  family: string | null;
}

export interface AuditMainInfo {
  /** 세트의 변형이면 세트 이름, 아니면 컴포넌트 이름. */
  name: string;
  remote: boolean;
}

export interface AuditCollectionInfo {
  name: string;
  modes: readonly { modeId: string; name: string }[];
}

export interface AuditDeps {
  styleOf(id: string): Promise<AuditStyleInfo | null>;
  variableOf(id: string): Promise<VariableRef | null>;
  mainOf(instance: AuditNode): Promise<AuditMainInfo | null>;
  collectionOf(id: string): Promise<AuditCollectionInfo | null>;
  /** 켜진 라이브러리 `Primitives` 의 본문 서체 이름 — 읽기만 하는 마지막 출처.
   *  없으면 묻지 않는다. */
  librarySans?(): Promise<string | null>;
}

export interface CollectOptions {
  /** CoUI 라이브러리의 컴포넌트(세트) 이름 — 레지스트리의 이름. */
  couiComponents: ReadonlySet<string>;
  /** 이 이름의 레이어 아래는 걷지 않는다(주석 프레임 같은 것). */
  skipNames: ReadonlySet<string>;
  /** 고정폭 서체 이름. */
  mono: string | null;
}

export interface Collected {
  runs: TextRun[];
  textNodes: number;
  skippedTexts: number;
  /** 건너뛸 이름 중 범위에서 찾은 것과 찾지 못한 것. */
  skippedNames: string[];
  unmatchedSkipNames: string[];
  /** 본문 서체 — 읽지 못했으면 null. 어디서 읽는지는 파일 머리의 "본문 서체". */
  sans: string | null;
}

// 구간을 나눌 때 읽는 필드 — 판정이 보는 것 전부.
const kSegmentFields = ['fontName', 'fontSize', 'lineHeight', 'letterSpacing', 'textStyleId', 'boundVariables'];
const kBoundFields: readonly AuditBoundField[] = ['fontSize', 'letterSpacing', 'fontWeight', 'lineHeight', 'fontFamily'];

// CoUI 컴포넌트 글자의 서체로 본문 서체를 읽을 때 볼 글의 수 — 범위 안 CoUI 글자는
// 수백 개라도 같은 라이브러리의 같은 서체다. 몇 개면 족하고, 더 읽는 것은 비용이다.
const kLibraryFaceSamples = 24;

interface WalkState {
  page: AuditPage;
  /** 페이지 직계(섹션은 건너뛴) 프레임의 이름 — 화면. */
  container: string | null;
  /** 가장 안쪽 로컬 컴포넌트 — 고칠 곳. */
  localComponent: string | null;
  /** 바깥부터, 거쳐 온 라이브러리 인스턴스의 컴포넌트 이름. */
  remote: string[];
  /** 거쳐 온 인스턴스마다의 덮어쓰기 — 자손 id → 필드. */
  overrides: Map<string, readonly string[]>[];
}

function mostVoted(votes: ReadonlyMap<string, number>): string | null {
  let best: string | null = null;
  let most = 0;
  for (const [family, n] of votes) {
    if (n > most) {
      best = family;
      most = n;
    }
  }
  return best;
}

/** 보이는 글자를 걸어 구간을 모은다. 노드에 쓰는 것은 없다. */
export async function collectRuns(
  pages: readonly AuditPage[],
  deps: AuditDeps,
  opts: CollectOptions,
): Promise<Collected> {
  const runs: TextRun[] = [];
  let textNodes = 0;
  let skippedTexts = 0;
  const skipMatched = new Set<string>();
  // 본문 서체의 출처 셋 — 앞의 것이 비었을 때만 다음 것을 쓴다(파일 머리 참고).
  const sansVotes = new Map<string, number>();
  const libraryFaceVotes = new Map<string, number>();
  let libraryFaceSamples = 0;
  const vote = (votes: Map<string, number>, family: string | null): void => {
    if (family == null || family === '' || family === opts.mono) return;
    votes.set(family, (votes.get(family) ?? 0) + 1);
  };

  const countVisibleTexts = (node: AuditNode): number => {
    if (node.visible === false) return 0;
    if (node.type === 'TEXT') return (node.characters ?? '').trim() === '' ? 0 : 1;
    let n = 0;
    for (const c of node.children ?? []) n += countVisibleTexts(c);
    return n;
  };

  // 이 노드가 푸는 `Semantic/ Typography` 모드의 이름. 컬렉션 조회는 deps 가 id 마다
  // 한 번만 한다.
  const typographyModeOf = async (node: AuditNode): Promise<string | null> => {
    let modes: AuditNode['resolvedVariableModes'];
    try {
      modes = node.resolvedVariableModes;
    } catch {
      return null;
    }
    for (const [collectionId, modeId] of Object.entries(modes ?? {})) {
      const collection = await deps.collectionOf(collectionId);
      if (collection == null || canonicalCollection(collection.name) !== kSemanticTypography) continue;
      return collection.modes.find((m) => m.modeId === modeId)?.name ?? null;
    }
    return null;
  };

  const lookOf = async (seg: AuditSegment, mode: string | null): Promise<RunLook> => {
    const bound: Partial<Record<AuditBoundField, VariableRef>> = {};
    for (const field of kBoundFields) {
      const alias = seg.boundVariables?.[field];
      if (alias == null) continue;
      const ref = await deps.variableOf(alias.id);
      if (ref == null) continue;
      bound[field] = ref;
      if (field === 'fontFamily') vote(sansVotes, familyOfVariable(ref));
    }
    let textStyle: RunLook['textStyle'] = null;
    if (seg.textStyleId !== '') {
      const style = await deps.styleOf(seg.textStyleId);
      if (style != null) {
        textStyle = { name: style.name, remote: style.remote };
        const role = couiStyleRole(style.name);
        if (role != null && style.remote && !isMonoRole(role)) vote(sansVotes, style.family);
      }
    }
    return {
      family: seg.fontName.family,
      face: seg.fontName.style,
      size: seg.fontSize,
      lineHeight: seg.lineHeight,
      letterSpacing: seg.letterSpacing,
      textStyle,
      bound,
      mode,
    };
  };

  const segmentsOf = (node: AuditNode): readonly AuditSegment[] => {
    if (node.getStyledTextSegments == null) return [];
    return node.getStyledTextSegments(kSegmentFields);
  };

  // 같은 글 안에서 고정폭 구간이 그리는 코드 역할 — CoUI 코드 스타일이 붙었으면 그
  // 역할, 스타일 없이 고정폭 서체로 그렸으면 그 모양에 가장 가까운 코드 역할.
  const codeRoleOf = (looks: readonly RunLook[]): string | null => {
    for (const l of looks) {
      if (l.textStyle == null || !l.textStyle.remote) continue;
      const role = couiStyleRole(l.textStyle.name);
      if (role != null && isMonoRole(role)) return role;
    }
    if (opts.mono == null) return null;
    for (const l of looks) {
      if (l.family !== opts.mono) continue;
      const near = nearestRole(l, { sans: null, mono: opts.mono });
      if (near != null && isMonoRole(near.role)) return near.role;
    }
    return null;
  };

  // CoUI 컴포넌트 글자가 그려진 서체 — 본문 서체의 두 번째 출처. 글 전체가 한
  // 서체가 아니면 첫 고정폭 아닌 구간의 것.
  const sampleLibraryFace = (node: AuditNode): void => {
    if (libraryFaceSamples >= kLibraryFaceSamples) return;
    libraryFaceSamples += 1;
    const font = node.fontName;
    if (font != null && typeof font === 'object') {
      vote(libraryFaceVotes, font.family);
      return;
    }
    if (node.getStyledTextSegments == null) return;
    const seg = node.getStyledTextSegments(['fontName']).find((x) => x.fontName.family !== opts.mono);
    vote(libraryFaceVotes, seg?.fontName.family ?? null);
  };

  // 라이브러리 이름으로 CoUI 를 못 알아보면(이름을 바꾼 세트, 이 빌드가 모르는
  // 새 컴포넌트) 글자에게 한 번 더 묻는다: CoUI 타이포 변수에 묶였거나, CoUI 텍스트
  // 스타일이 붙었는가. 역할이 살아남은 CoUI 라벨은 스타일만 갖고 노드의 변수
  // 바인딩은 없으므로(빌더가 스타일을 붙이며 푼다) 변수만 물으면 가장 흔한 CoUI
  // 라벨을 놓친다.
  const looksCoui = async (node: AuditNode): Promise<boolean> => {
    const bv = node.boundVariables ?? {};
    for (const field of kBoundFields) {
      const raw = bv[field];
      const alias = (Array.isArray(raw) ? raw[0] : raw) as { id?: string } | undefined;
      if (alias?.id == null) continue;
      const ref = await deps.variableOf(alias.id);
      if (ref != null && isCouiTypographyVariable(ref)) return true;
    }
    if (node.getStyledTextSegments == null) return false;
    for (const seg of node.getStyledTextSegments(['textStyleId'])) {
      if (seg.textStyleId === '') continue;
      const style = await deps.styleOf(seg.textStyleId);
      if (style != null && style.remote && couiStyleRole(style.name) != null) return true;
    }
    return false;
  };

  const pushRuns = async (
    node: AuditNode,
    base: Pick<TextRun, 'nodeId' | 'pageId' | 'pageName'>,
    where: string,
    context: RunContext,
  ): Promise<void> => {
    const mode = await typographyModeOf(node);
    const segs = segmentsOf(node);
    const looks: RunLook[] = [];
    for (const seg of segs) looks.push(await lookOf(seg, mode));
    const codeRole = codeRoleOf(looks);
    segs.forEach((seg, i) => {
      runs.push({ ...base, text: seg.characters, where, context, look: looks[i], codeRole });
    });
  };

  const readText = async (node: AuditNode, w: WalkState): Promise<void> => {
    const text = node.characters ?? '';
    if (text.trim() === '') return;
    textNodes += 1;
    const base = { nodeId: node.id, pageId: w.page.id, pageName: w.page.name };
    if (w.remote.length > 0) {
      const fields = new Set<string>();
      for (const layer of w.overrides) for (const f of layer.get(node.id) ?? []) fields.add(f);
      const overridden = typographyOverrides([...fields]);
      const couiName = w.remote.find((name) => opts.couiComponents.has(name)) ?? null;
      const coui = couiName != null || (await looksCoui(node));
      const component = couiName ?? w.remote[0];
      const context: RunContext = { kind: 'library', component, coui, overridden };
      if (coui) sampleLibraryFace(node);
      if (!coui || overridden.length === 0) {
        runs.push({ ...base, text, where: component, context, look: null });
        return;
      }
      await pushRuns(node, base, component, context);
      return;
    }
    const context: RunContext =
      w.localComponent != null ? { kind: 'local-component', component: w.localComponent } : { kind: 'own' };
    await pushRuns(node, base, w.localComponent ?? w.container ?? '(페이지 직계)', context);
  };

  // `parentType` 은 노드의 `parent` 를 읽는 대신 걸어 내려오며 넘긴다 — 걷는 쪽이
  // 이미 아는 것을 노드에 다시 묻지 않는다.
  const walk = async (node: AuditNode, w: WalkState, parentType: string): Promise<void> => {
    if (node.visible === false) return;
    const name = node.name.trim();
    if (opts.skipNames.has(name)) {
      skipMatched.add(name);
      skippedTexts += countVisibleTexts(node);
      return;
    }
    if (node.type === 'TEXT') {
      await readText(node, w);
      return;
    }
    let next = w;
    if (w.container == null && node.type !== 'SECTION') next = { ...next, container: node.name };
    if (node.type === 'COMPONENT_SET') {
      next = { ...next, localComponent: node.name };
    } else if (node.type === 'COMPONENT' && parentType !== 'COMPONENT_SET') {
      next = { ...next, localComponent: node.name };
    } else if (node.type === 'INSTANCE') {
      const layer = new Map<string, readonly string[]>();
      for (const o of node.overrides ?? []) layer.set(o.id, o.overriddenFields);
      next = { ...next, overrides: [...next.overrides, layer] };
      // 라이브러리 컴포넌트 안쪽 인스턴스도 원본을 묻는다. 슬롯에 바꿔 넣은 이 파일의
      // 컴포넌트(대화상자의 내용 · 앱 바의 앞쪽 같은 자리)는 라이브러리 안에 있어도
      // 이 파일의 글자이고, 이 점검이 찾는 글자가 바로 거기에 쓰인다. 그 아래는 화면
      // 글자처럼 다시 읽는다 — 덮어쓰기 층은 그대로 둔다: 그 안의 CoUI 컴포넌트를
      // 고친 것은 바깥 인스턴스에 적힌다.
      const main = await deps.mainOf(node);
      if (main?.remote === true) next = { ...next, remote: [...next.remote, main.name] };
      else if (main != null) next = { ...next, remote: [], localComponent: main.name };
    }
    for (const child of node.children ?? []) await walk(child, next, node.type);
  };

  for (const page of pages) {
    const start: WalkState = { page, container: null, localComponent: null, remote: [], overrides: [] };
    for (const child of page.children) await walk(child, start, 'PAGE');
  }

  let sans = mostVoted(sansVotes) ?? mostVoted(libraryFaceVotes);
  if (sans == null && deps.librarySans != null) sans = await deps.librarySans();
  return {
    runs,
    textNodes,
    skippedTexts,
    skippedNames: [...opts.skipNames].filter((n) => skipMatched.has(n)),
    unmatchedSkipNames: [...opts.skipNames].filter((n) => !skipMatched.has(n)),
    sans,
  };
}

// ─── Figma 에 잇기 ───────────────────────────────────────────────────────────

/**
 * 인스턴스가 가리키는 원본의 이름 — 세트의 변형이면 세트 이름. 레지스트리는 세트
 * 이름으로 컴포넌트를 알아보므로 변형 이름(`Size=md, State=Default`)으로는 아무것도
 * 알아보지 못한다. 원격 원본의 부모를 읽지 못하면(읽기가 던진다) 변형 이름으로 둔다.
 */
export function mainComponentName(main: {
  readonly name: string;
  readonly parent?: { readonly type: string; readonly name: string } | null;
}): string {
  try {
    const parent = main.parent;
    if (parent?.type === 'COMPONENT_SET') return parent.name;
  } catch {
    // 아래로.
  }
  return main.name;
}

/** 실제 문서의 조회 — 한 페이지에 글자가 천 개쯤이라 같은 스타일 · 변수 · 컬렉션을
 *  몇 백 번 묻는다. id 마다 한 번만 묻는다. */
function figmaDeps(): AuditDeps {
  const styles = new Map<string, Promise<AuditStyleInfo | null>>();
  const variables = new Map<string, Promise<VariableRef | null>>();
  const collections = new Map<string, Promise<AuditCollectionInfo | null>>();
  const collectionOf = (id: string): Promise<AuditCollectionInfo | null> => {
    let p = collections.get(id);
    if (p == null) {
      p = figma.variables
        .getVariableCollectionByIdAsync(id)
        .then((c) =>
          c == null ? null : { name: c.name, modes: c.modes.map((m) => ({ modeId: m.modeId, name: m.name })) },
        )
        .catch(() => null);
      collections.set(id, p);
    }
    return p;
  };
  return {
    styleOf(id) {
      let p = styles.get(id);
      if (p == null) {
        p = figma
          .getStyleByIdAsync(id)
          .then((s) =>
            s != null && s.type === 'TEXT'
              ? { name: s.name, remote: s.remote, family: (s as TextStyle).fontName?.family ?? null }
              : null,
          )
          .catch(() => null);
        styles.set(id, p);
      }
      return p;
    },
    variableOf(id) {
      let p = variables.get(id);
      if (p == null) {
        p = figma.variables
          .getVariableByIdAsync(id)
          .then(async (v) =>
            v == null ? null : { collection: (await collectionOf(v.variableCollectionId))?.name ?? '', name: v.name },
          )
          .catch(() => null);
        variables.set(id, p);
      }
      return p;
    },
    async mainOf(instance) {
      const main = await (instance as unknown as InstanceNode).getMainComponentAsync().catch(() => null);
      if (main == null) return null;
      return { name: mainComponentName(main), remote: main.remote };
    },
    collectionOf,
    // 켜진 라이브러리의 `Primitives` 에서 서체 변수를 이름으로 찾는다. 변수를
    // 가져오지(import) 않는다 — 가져오기는 문서에 쓰는 일이다. 그래서 값이 아니라
    // `font/family/<이름>` 의 이름에서 읽고, 이름에 서체가 없는 `font-family/sans` 는
    // 건너뛴다. 어느 변수가 본문 서체인지는 `mono-hangul.ts` 와 같은 판정이다.
    async librarySans() {
      try {
        const libraries = await figma.teamLibrary.getAvailableLibraryVariableCollectionsAsync();
        for (const lib of libraries) {
          if (canonicalCollection(lib.name) !== kPrimitives) continue;
          const vars = await figma.teamLibrary.getVariablesInLibraryCollectionAsync(lib.key);
          for (const v of vars) {
            if (!isSansFamilyVariableName(v.name)) continue;
            const family = familyOfVariable({ collection: lib.name, name: v.name });
            if (family != null && family !== '') return family;
          }
        }
      } catch {
        // 팀 라이브러리를 읽을 수 없는 환경 — 서체를 모르는 채로 둔다.
      }
      return null;
    },
  };
}

export interface ConsumerAuditRequest {
  scope: 'page' | 'all';
  skipNames: readonly string[];
  couiComponents: Iterable<string>;
  mono: string | null;
}

/** 명령. 현재 페이지 또는 모든 페이지를 읽는다. 아무것도 쓰지 않는다. */
export async function auditConsumerFile(req: ConsumerAuditRequest): Promise<ConsumerAuditReport> {
  const pages = req.scope === 'all' ? figma.root.children.slice() : [figma.currentPage];
  const auditPages: AuditPage[] = [];
  for (const page of pages) {
    // `documentAccess: dynamic-page` 는 로드되지 않은 페이지의 children 을 거부한다.
    await page.loadAsync();
    auditPages.push({ id: page.id, name: page.name, children: page.children as unknown as AuditNode[] });
  }
  const skipNames = new Set(req.skipNames.map((n) => n.trim()).filter((n) => n !== ''));
  const collected = await collectRuns(auditPages, figmaDeps(), {
    couiComponents: new Set(req.couiComponents),
    skipNames,
    mono: req.mono,
  });
  const scope =
    req.scope === 'all' ? `모든 페이지 (${pages.length})` : `현재 페이지 "${figma.currentPage.name}"`;
  return buildConsumerAuditReport(
    collected.runs,
    { sans: collected.sans, mono: req.mono },
    {
      scope,
      pageCount: pages.length,
      textNodes: collected.textNodes,
      skippedNames: collected.skippedNames,
      skippedTexts: collected.skippedTexts,
      unmatchedSkipNames: collected.unmatchedSkipNames,
    },
  );
}

/**
 * 목록의 한 항목을 누르면 — 그 페이지로 가서 노드를 선택하고 화면을 옮긴다.
 * 선택과 화면 위치만 바뀐다. 결과는 한 줄 알림으로.
 */
export async function revealAuditNodes(pageId: string, ids: readonly string[]): Promise<string> {
  const page = await figma.getNodeByIdAsync(pageId);
  if (page == null || page.type !== 'PAGE') return '그 페이지를 찾지 못했다 — 점검을 다시 돌린다.';
  if (figma.currentPage.id !== page.id) await figma.setCurrentPageAsync(page);
  const nodes: SceneNode[] = [];
  for (const id of ids) {
    const node = await figma.getNodeByIdAsync(id);
    if (node != null && node.type !== 'PAGE' && node.type !== 'DOCUMENT') nodes.push(node as SceneNode);
  }
  if (nodes.length === 0) return '노드를 찾지 못했다 — 지웠거나 옮겼다. 점검을 다시 돌린다.';
  page.selection = nodes;
  figma.viewport.scrollAndZoomIntoView(nodes);
  const missing = ids.length - nodes.length;
  return `${nodes.length}개 선택` + (missing > 0 ? ` · ${missing}개는 찾지 못했다` : '');
}
