// 구조 스냅샷의 **파일 모양** — 쓰는 쪽(플러그인 `src/structure-snapshot.ts`)과
// 읽는 쪽(`reverse/diff_structure.ts`)이 같은 상수·같은 직렬화를 본다.
//
// 순수 모듈이다: Node API 도 figma 전역도 건드리지 않는다. 두 tsconfig 가 서로의
// 전역을 못 보게 격리돼 있어서, 양쪽에서 import 되려면 그 어느 쪽에도 기대면 안 된다.
//
// 왜 한 줄에 노드 하나인가: 46,000 노드를 `JSON.stringify(_, null, 2)` 로 쓰면
// 40만 줄이 넘고, 그 파일이 베이스라인으로 커밋된다. 노드마다 한 줄이면 diff 가
// "바뀐 노드 = 바뀐 줄" 로 읽히고 크기는 절반이다. 읽는 쪽은 그냥 JSON.parse 다.

// ── schema — 이 캡처가 **어떤 필드를 싣고 있는가**에 대한 주장 ──────────────
//
// schema 1 은 노드의 id · name · type · 기하 · depth 만 싣는다. 그 형태로는
// 컴포넌트 세트에 **프로퍼티 정의만** 더한 디자이너 편집(기하 변화 0)이 베이스라인과
// 차이 0 으로 나오고, 인스턴스가 어느 원본을 가리키는지도 보이지 않는다.
//
// schema 2 는 그 둘을 더한다 — 프로퍼티를 소유하는 노드(`props`)와 인스턴스(`main`).
// 두 키는 **있는지 여부 자체가 계약**이다: schema 2 캡처에서 소유 노드는 반드시
// `props` 를, 인스턴스는 반드시 `main` 을 갖고, 그 밖의 노드는 둘 다 갖지 않는다.
// 읽지 못한 값은 키를 빼는 대신 `null` 로 적는다 — 키가 빠진 것과 "읽어 봤는데 없었다"
// 를 같은 모양으로 쓰면, 읽는 쪽은 비교하지 못한 것을 비교해서 같았다고 보고한다.
//
// MCP `get_metadata` 캡처는 프로퍼티 정의를 읽을 수 없어 schema 1 을 주장한다.

/** 플러그인이 지금 쓰는 형태. */
export const SNAPSHOT_SCHEMA = 2;

/** 프로퍼티 · 원본 참조 없이 구조와 기하만 싣는 형태 — MCP 캡처와 이전 베이스라인. */
export const SNAPSHOT_SCHEMA_GEOMETRY_ONLY = 1;

/** 읽는 쪽이 받아들이는 형태. 전환 기간에 schema 1 베이스라인을 거부하지 않기 위해 둘 다다. */
export const READABLE_SNAPSHOT_SCHEMAS: readonly number[] = [
  SNAPSHOT_SCHEMA_GEOMETRY_ONLY,
  SNAPSHOT_SCHEMA,
];

/** 이 schema 의 캡처가 프로퍼티 정의와 인스턴스 원본 참조를 싣는가. */
export function carriesComponentProps(schema: number): boolean {
  return schema >= SNAPSHOT_SCHEMA;
}

/** 플러그인이 파일 안에서 걸어 만든 캡처. MCP 캡처(`figma-mcp:get_metadata`)와 구별한다. */
export const CAPTURED_BY_PLUGIN = 'figma-plugin:structure-snapshot';

/**
 * 컴포넌트 프로퍼티 정의 하나 — Figma `componentPropertyDefinitions` 의 한 항목.
 *
 * `key` 는 Figma 의 키 그대로다. VARIANT 가 아닌 프로퍼티는 `Show description#12:3`
 * 처럼 `#<id>` 접미사를 달고 오는데, 그 접미사는 재생성 때 바뀌므로 **비교는 접미사를
 * 접은 표시 이름으로** 한다(읽는 쪽의 몫). 여기서 접지 않는 이유: 빌더가 `defineProp`
 * 으로 채택하는 이름도, 캔버스에서 사람이 찾는 이름도 그 원문이다.
 */
export interface SnapshotProp {
  key: string;
  /** `BOOLEAN` · `TEXT` · `INSTANCE_SWAP` · `VARIANT` · `SLOT` 등 — Figma 의 어휘 그대로. */
  type: string;
  default: string | boolean;
  /**
   * VARIANT 는 `variantOptions`, INSTANCE_SWAP 은 `preferredValues` 를 `<type>:<key>`
   * 로 적은 것. 그 밖의 타입은 키가 없다.
   */
  options?: string[];
}

export interface SnapshotNode {
  id: string;
  name: string;
  type: string;
  x: number | null;
  y: number | null;
  w: number | null;
  h: number | null;
  depth: number;
  /**
   * schema 2: 프로퍼티를 소유하는 노드 — 컴포넌트 세트, 그리고 세트에 속하지 않은
   * 단독 컴포넌트 — 에만 있다. key 로 정렬한다. `null` 은 읽지 못함이다(Figma 는
   * 변형 충돌이 있는 세트에서 정의 읽기를 거부한다).
   */
  props?: SnapshotProp[] | null;
  /** schema 2: 인스턴스에만 있다. 원본 컴포넌트의 노드 id. `null` 은 원본을 해석하지 못함. */
  main?: string | null;
}

/**
 * 이 노드가 컴포넌트 프로퍼티 정의를 **소유**하는가 — 컴포넌트 세트, 그리고 세트에
 * 속하지 않은 단독 컴포넌트. 세트 안의 변형은 정의를 갖지 않는다(Figma 는 그 노드에서
 * `componentPropertyDefinitions` 를 읽으면 던진다).
 *
 * 타입은 스냅샷의 어휘(소문자)로 받는다. 쓰는 쪽은 이 판정으로 `props` 를 싣고, 읽는
 * 쪽은 같은 판정으로 "있어야 할 자리에 있는가" 를 검증한다 — 규칙이 두 곳에 적히면
 * 한쪽만 바뀌는 날 멀쩡한 스냅샷이 검증에서 멈추거나, 빠진 정의가 통과한다.
 */
export function ownsComponentProps(type: string, parentType: string | null): boolean {
  if (type === 'component_set') return true;
  return type === 'component' && parentType !== 'component_set';
}

/** schema 2 에서 `main` 을 싣는 노드 — 인스턴스. */
export function carriesMainComponent(type: string): boolean {
  return type === 'instance';
}

/**
 * 표시 이름 — 프로퍼티 키의 `#<id>` 접미사를 접는다.
 *
 * 쓰는 쪽과 읽는 쪽이 같은 규칙을 봐야 해서 여기 둔다. 접미사를 그대로 비교하면
 * 세트를 다시 그릴 때마다 모든 BOOLEAN · TEXT 프로퍼티가 "삭제 + 추가" 로 나온다.
 */
export function propDisplayName(key: string): string {
  return key.replace(/#\d+:\d+$/, '');
}

export interface SnapshotPage {
  id: string;
  name: string;
  nodes: SnapshotNode[];
}

export interface SnapshotDoc {
  schema: number;
  fileKey: string | null;
  capturedAt: string | null;
  capturedBy: string;
  nodeCount: number;
  pages: SnapshotPage[];
}

export function serialiseSnapshot(doc: SnapshotDoc): string {
  const head = JSON.stringify(
    {
      schema: doc.schema,
      fileKey: doc.fileKey,
      capturedAt: doc.capturedAt,
      capturedBy: doc.capturedBy,
      nodeCount: doc.nodeCount,
    },
    null,
    2,
  ).replace(/\n}$/, ',\n  "pages": [\n');
  const pages = doc.pages
    .map((p) => {
      const nodes = p.nodes.map((n) => `      ${JSON.stringify(n)}`).join(',\n');
      return `    {"id": ${JSON.stringify(p.id)}, "name": ${JSON.stringify(p.name)}, "nodes": [\n${nodes}\n    ]}`;
    })
    .join(',\n');
  return `${head}${pages}\n  ]\n}\n`;
}
