/// <reference types="@figma/plugin-typings" />

// 구조 스냅샷 — Channel A 의 캡처를 MCP 대신 플러그인이 만든다.
//
// MCP `get_metadata` 경로는 이 파일에 맞지 않는다: 페이지 목록 호출이 Cover 한
// 장만 돌려주는 버그가 있고, 193 페이지 · 46,000 노드를 페이지별 호출로 걷으면
// 하루 예산(200회)과 한 실행 상한(60회)을 넘기며, 그 XML 전부가 에이전트의
// 컨텍스트를 지나야 한다. 플러그인은 파일 안에서 돈다 — 예산도 컨텍스트도 쓰지
// 않고 전 페이지를 몇 초에 읽는다.
//
// 출력은 `reverse/diff_structure.ts` 가 읽는 스냅샷 모양 그대로다(같은 schema ·
// 같은 필드). schema 2 부터 프로퍼티 소유 노드의 정의(`props`)와 인스턴스의 원본
// 참조(`main`)를 싣는다 — 기하가 그대로인 프로퍼티 편집이 대조에서 보이게 하려는
// 것이다. 좌표는 MCP XML 과 같은 의미 — 부모 기준 상대 x/y, 페이지 루트는
// `canvas` 타입에 0/0/0/0. 타입은 Figma 노드 타입을 소문자로 적는다. 두 캡처
// 경로의 타입 어휘가 완전히 같다는 보장은 없으므로 differ 는 `capturedBy` 가 다른
// 베이스라인과의 비교를 거부한다 — 그 전환은 `--update-baseline` 으로 한 번 한다.

import {
  CAPTURED_BY_PLUGIN,
  SNAPSHOT_SCHEMA,
  carriesMainComponent,
  ownsComponentProps,
  serialiseSnapshot,
  SnapshotNode,
  SnapshotPage,
  SnapshotProp,
} from '../reverse/snapshot_format';

/** 부동소수 잡음을 파일에 싣지 않는다 — 0.5px epsilon 아래의 자릿수는 정보가 아니다. */
function round2(v: number): number {
  return Math.round(v * 100) / 100;
}

/**
 * 프로퍼티를 소유하는 노드인가 — 판정 규칙은 `ownsComponentProps` 한 곳이 소유한다.
 * 읽는 쪽(`reverse/diff_structure.ts`)이 같은 규칙으로 "있어야 할 자리에 `props` 가
 * 있는가" 를 검증하므로, 여기서 규칙을 따로 적으면 둘이 갈라지는 날 스냅샷 검증이 멈춘다.
 */
function ownsProps(node: SceneNode): node is ComponentSetNode | ComponentNode {
  return ownsComponentProps(
    node.type.toLowerCase(),
    node.parent === null ? null : node.parent.type.toLowerCase(),
  );
}

/**
 * 정의를 key 로 정렬해 옮긴다. 읽지 못하면 `null` — 키를 빼면 읽는 쪽이 "프로퍼티
 * 없음" 과 구별하지 못하고, 그 둘을 같게 보면 비교하지 못한 것이 "변화 없음" 으로 나간다.
 */
function readProps(node: ComponentSetNode | ComponentNode): SnapshotProp[] | null {
  let defs: ComponentPropertyDefinitions;
  try {
    defs = node.componentPropertyDefinitions;
  } catch {
    return null;
  }
  return Object.keys(defs)
    .sort()
    .map((key) => {
      const def = defs[key];
      const prop: SnapshotProp = { key, type: def.type, default: def.defaultValue };
      if (def.type === 'VARIANT' && def.variantOptions !== undefined) {
        prop.options = [...def.variantOptions];
      } else if (def.type === 'INSTANCE_SWAP' && def.preferredValues !== undefined) {
        prop.options = def.preferredValues.map((v) => `${v.type}:${v.key}`);
      }
      return prop;
    });
}

export async function captureStructureSnapshot(): Promise<{
  content: string;
  log: string[];
  generatedAt: string;
  nodeCount: number;
  pageCount: number;
}> {
  const generatedAt = new Date().toISOString();
  const pages: SnapshotPage[] = [];
  let nodeCount = 0;
  // 순회 비용을 로그에 남긴다 — 인스턴스마다 원본을 비동기로 묻는 것이 이 캡처에서
  // 가장 비싼 부분이라, 파일이 커져 캡처가 느려지면 어느 몫인지 로그가 말해야 한다.
  const started = Date.now();
  let ownerCount = 0;
  let unreadableProps = 0;
  let instanceCount = 0;
  let unresolvedMain = 0;
  let mainMs = 0;

  for (const page of figma.root.children) {
    await page.loadAsync();
    const nodes: SnapshotNode[] = [
      { id: page.id, name: page.name, type: 'canvas', x: 0, y: 0, w: 0, h: 0, depth: 0 },
    ];
    // 명시적 스택 — 깊은 트리에서 재귀 깊이를 걱정하지 않는다. 형제 순서를
    // 유지하려고 children 을 뒤집어 넣는다(pop 이 앞에서부터 꺼내도록).
    const stack: { node: SceneNode; depth: number }[] = [];
    for (let i = page.children.length - 1; i >= 0; i--) {
      stack.push({ node: page.children[i], depth: 1 });
    }
    while (stack.length > 0) {
      const { node, depth } = stack.pop()!;
      const record: SnapshotNode = {
        id: node.id,
        name: node.name,
        type: node.type.toLowerCase(),
        x: round2(node.x),
        y: round2(node.y),
        w: round2(node.width),
        h: round2(node.height),
        depth,
      };
      if (ownsProps(node)) {
        ownerCount += 1;
        record.props = readProps(node);
        if (record.props === null) unreadableProps += 1;
      } else if (carriesMainComponent(record.type) && node.type === 'INSTANCE') {
        // 동기 `mainComponent` 는 이 플러그인의 `dynamic-page` 접근에서 읽을 수 없다.
        instanceCount += 1;
        const t0 = Date.now();
        let main: string | null = null;
        try {
          main = (await node.getMainComponentAsync())?.id ?? null;
        } catch {
          main = null;
        }
        mainMs += Date.now() - t0;
        if (main === null) unresolvedMain += 1;
        record.main = main;
      }
      nodes.push(record);
      if ('children' in node) {
        for (let i = node.children.length - 1; i >= 0; i--) {
          stack.push({ node: node.children[i], depth: depth + 1 });
        }
      }
    }
    nodeCount += nodes.length;
    pages.push({ id: page.id, name: page.name, nodes });
  }

  const content = serialiseSnapshot({
    schema: SNAPSHOT_SCHEMA,
    fileKey: typeof figma.fileKey === 'string' ? figma.fileKey : null,
    capturedAt: generatedAt,
    capturedBy: CAPTURED_BY_PLUGIN,
    nodeCount,
    pages,
  });
  return {
    content,
    generatedAt,
    nodeCount,
    pageCount: pages.length,
    log: [
      `✓ 구조 스냅샷: 페이지 ${pages.length}개 · 노드 ${nodeCount}개 (${generatedAt})`,
      `  프로퍼티 소유 노드 ${ownerCount}개` +
        (unreadableProps > 0 ? ` (정의를 읽지 못함 ${unreadableProps}개 — null 로 기록)` : ''),
      `  인스턴스 ${instanceCount}개 · 원본 조회 ${mainMs}ms` +
        (unresolvedMain > 0 ? ` (원본을 해석하지 못함 ${unresolvedMain}개 — null 로 기록)` : ''),
      `  전체 순회 ${Date.now() - started}ms`,
      '  reverse/incoming/ 에 커밋하면 diff_structure.ts --snapshot=<파일> 이 읽는다.',
    ],
  };
}
