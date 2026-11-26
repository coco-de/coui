// 「브랜드 확장 컬렉션 만들기」의 두 번째 단계 — 화면이 그 확장을 읽게 한다.
//
// 확장 컬렉션은 그 모드를 쓰는 노드에만 칠해진다. 컴포넌트의 연결은 원래 라이브러리
// 컬렉션(`Semantic/ Color · CoUI`)의 변수 그대로라, 노드가 원래 컬렉션의 모드를 읽는
// 동안에는 확장을 만들어도 화면이 CoUI 색 그대로다(시험 소비 파일에서 실측, #6238).
// 그래서 선택한 레이어(선택이 없으면 현재 페이지)와 그 안에서 원래 컬렉션 — 또는 같은
// 원본의 다른 브랜드 확장 — 의 모드를 지정한 노드를, 같은 부모 모드(Light · Dark …)의
// 이 브랜드 확장 모드로 옮긴다. 범위의 맨 위가 모드를 지정하지 않았으면 원래 컬렉션의
// 기본 모드(첫 모드)에 해당하는 확장 모드를 준다.
//
// 노드의 변수 연결은 읽지도 쓰지도 않는다 — 바꾸는 것은 노드가 지정한 모드뿐이다.

import { brandExtensionNameFor, findBrand } from './brand-table';

type ModeCarrier = BaseNode & {
  explicitVariableModes: { [collectionId: string]: string };
  setExplicitVariableModeForCollection(collection: VariableCollection, modeId: string): void;
};

type ExtensionLike = {
  id: string;
  name: string;
  isExtension: true;
  rootVariableCollectionId: string;
  modes: Array<{ modeId: string; name: string; parentModeId?: string }>;
};

function carriesModes(node: BaseNode): node is ModeCarrier {
  return (
    typeof (node as { setExplicitVariableModeForCollection?: unknown }).setExplicitVariableModeForCollection ===
      'function' && typeof (node as { explicitVariableModes?: unknown }).explicitVariableModes === 'object'
  );
}

/**
 * [brandName] 의 확장 컬렉션 모드를 선택한 레이어(선택이 없으면 현재 페이지)에 지정한다.
 * 이미 그 확장의 모드를 지정한 노드는 건드리지 않으므로 다시 돌려도 쓰지 않는다.
 */
export async function pointScopeAtBrand(brandName: string): Promise<string[]> {
  const brand = findBrand(brandName);
  if (brand == null) return [];
  const name = brandExtensionNameFor(brand);
  const locals = (await figma.variables.getLocalVariableCollectionsAsync()) as unknown as Array<
    ExtensionLike | { id: string; name: string; isExtension?: false }
  >;
  const ext = locals.find((c): c is ExtensionLike => c.isExtension === true && c.name === name);
  if (ext == null) return [`⚠ 모드를 지정하지 않음 — 이 파일에 "${name}" 확장이 없다`];

  const rootId = ext.rootVariableCollectionId;
  // 같은 원본에서 나온 확장들 — 다른 브랜드로 칠한 화면을 이 브랜드로 옮길 때 그 모드를 읽는다.
  const siblings = locals.filter(
    (c): c is ExtensionLike => c.isExtension === true && c.rootVariableCollectionId === rootId && c.id !== ext.id,
  );
  const parentOf = new Map<string, string>();
  for (const s of siblings) for (const m of s.modes) if (m.parentModeId) parentOf.set(`${s.id}|${m.modeId}`, m.parentModeId);
  const target = new Map<string, string>();
  for (const m of ext.modes) if (m.parentModeId) target.set(m.parentModeId, m.modeId);
  const fallback = ext.modes[0]?.modeId;
  if (fallback == null) return [`⚠ 모드를 지정하지 않음 — "${name}" 에 모드가 없다`];

  const familyKeys = new Set([rootId, ...siblings.map((s) => s.id)]);
  const wornFamily = (node: ModeCarrier): string | null => {
    const worn = node.explicitVariableModes ?? {};
    for (const key of Object.keys(worn)) if (familyKeys.has(key)) return key;
    return null;
  };

  const page = figma.currentPage;
  const selection = page.selection;
  const tops: BaseNode[] = selection.length > 0 ? [...selection] : [page];
  const where = selection.length > 0 ? `선택한 레이어 ${selection.length}개` : `현재 페이지 "${page.name}"`;
  const collection = ext as unknown as VariableCollection;
  let moved = 0;
  let given = 0;
  let unmapped = 0;
  const done = new Set<string>();

  const point = (node: ModeCarrier, isTop: boolean): void => {
    if (done.has(node.id)) return;
    done.add(node.id);
    const worn = node.explicitVariableModes ?? {};
    if (worn[ext.id] != null) return;
    const key = wornFamily(node);
    let modeId: string | undefined;
    if (key == null) {
      if (!isTop) return;
      modeId = fallback;
    } else {
      const parentMode = key === rootId ? worn[key] : parentOf.get(`${key}|${worn[key]}`);
      modeId = parentMode == null ? undefined : target.get(parentMode);
    }
    if (modeId == null) {
      unmapped++;
      return;
    }
    node.setExplicitVariableModeForCollection(collection, modeId);
    if (key == null) given++;
    else moved++;
  };

  for (const top of tops) {
    if (carriesModes(top)) point(top, true);
    const descendants =
      'findAll' in top
        ? (top as ChildrenMixin).findAll((n) => carriesModes(n) && wornFamily(n) != null)
        : [];
    for (const n of descendants) if (carriesModes(n)) point(n, false);
  }

  const log = [
    `✓ 모드: ${where} → ${name} — 원래 컬렉션 · 다른 브랜드에서 옮김 ${moved}곳 · 새로 지정 ${given}곳` +
      (unmapped > 0 ? ` · 짝이 없는 모드 ${unmapped}곳은 그대로` : ''),
  ];
  if (moved + given === 0 && unmapped === 0) log.push(`= 이미 이 브랜드 모드를 쓰고 있다`);

  return log;
}
