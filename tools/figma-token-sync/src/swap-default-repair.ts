/// <reference types="@figma/plugin-typings" />
// INSTANCE_SWAP 기본값이 로컬 컴포넌트의 **원격 사본**을 가리키면 로컬을 가리키게 되돌린다.
//
// ## 왜 있는가
//
// `defineProp` 은 이미 있는 INSTANCE_SWAP 의 기본값을 건드리지 않는다 — 기본값은 노드
// id 이고 id 는 문서마다 다르며, 디자이너가 의도해서 다른 곳을 가리켰을 수 있기 때문이다
// (`component-props.ts` `SwapDefault`). 그 규칙이 지켜 주는 것은 **디자이너의 선택**인데,
// 선택이 아닌 것도 같은 규칙으로 보존된다: 같은 파일의 라이브러리를 켜면 Figma 가 게시된
// 컴포넌트를 **원격 사본**으로 문서에 되가져오고, 슬롯의 기본값이 로컬 `Icon` 대신 그
// 사본으로 옮겨 앉는 일이 실제로 있었다(MenuItem 의 Leading · Trailing 이 사본 `Icon` 을
// 가리켰다, #5323). 사본은 로컬과 **같은 key** 를 갖는다 — 같은 컴포넌트의 게시본이다.
//
// 이 상태의 비용은 조용하다. 슬롯은 정상으로 그려지지만 기본값이 가리키는 노드가 로컬이
// 아니라서 로컬을 고쳐도 기본값이 따라오지 않고, 게시 창에서는 세트가 다른 컴포넌트에
// 의존하는 것으로 읽힌다.
//
// ## 판정
//
//   기본값이 가리키는 노드가 `remote` 이고, 그 key 가 이 문서의 어떤 로컬 컴포넌트의 key 와
//   **같으면** 그것은 사본이다 → 로컬 쪽 id 로 되돌린다.
//
// key 가 같지 않은 원격 노드(다른 라이브러리의 컴포넌트)는 디자이너의 선택이므로 건드리지
// 않는다. 로컬에 짝이 없는 원격 노드도 마찬가지다 — 되돌릴 곳이 없다.
//
// ## 왜 빌드 전이고 비동기인가
//
// 노드를 id 로 여는 호출은 `documentAccess: "dynamic-page"` 아래에서 비동기뿐이고 빌더는
// 동기다. 그래서 `defineProp` 안에서 판정할 수 없고, 엔트리를 그리기 **전에** 한 번 고쳐
// 둔다 — 그러면 빌더는 이미 로컬을 가리키는 기본값을 보고 `iconSwapDefault` 도 로컬 변형에서
// 아이콘을 그린다. 그린 **뒤**에 고치면 첫 결선이 사본의 모양으로 슬롯을 그린 뒤라 되돌려도
// 그림이 따라오지 않는다.

/** 이 모듈이 노드에서 읽는 것 — 셀프테스트가 순수 객체로 구동한다. */
export interface SwapTargetLike {
  readonly id: string;
  readonly name: string;
  readonly key?: string;
  readonly remote?: boolean;
  readonly parent?: { readonly type: string; readonly name: string } | null;
}

export interface SwapOwnerLike {
  readonly name: string;
  readonly componentPropertyDefinitions: Readonly<
    Record<string, { readonly type: string; readonly defaultValue?: unknown }>
  >;
  editComponentProperty?(propertyId: string, change: { defaultValue: string }): string;
}

export interface SwapDefaultRepair {
  owner: string;
  /** 속성의 표시 이름. */
  prop: string;
  from: string;
  to: string;
  /** 고쳐 썼는가 — 거부되면 false, 이유는 `why`. */
  ok: boolean;
  why?: string;
}

/**
 * `owner` 의 INSTANCE_SWAP 기본값 중 로컬 컴포넌트의 원격 사본을 가리키는 것을 로컬로 되돌린다.
 * 던지지 않는다 — 이 수리의 실패가 엔트리를 막아서는 안 된다.
 *
 * `localCounterpart(target)` 은 `target`(원격 노드)과 같은 key 의 로컬 노드 id 를 답하거나 null.
 */
export async function repairRemoteSwapDefaults(
  owner: SwapOwnerLike,
  resolveById: (id: string) => Promise<SwapTargetLike | null>,
  localCounterpart: (target: SwapTargetLike) => string | null,
): Promise<SwapDefaultRepair[]> {
  const repairs: SwapDefaultRepair[] = [];
  let defs: SwapOwnerLike['componentPropertyDefinitions'];
  try {
    defs = owner.componentPropertyDefinitions;
  } catch {
    return repairs;
  }
  for (const key of Object.keys(defs)) {
    const def = defs[key];
    if (def.type !== 'INSTANCE_SWAP') continue;
    const held = def.defaultValue;
    if (typeof held !== 'string' || held === '') continue;
    let target: SwapTargetLike | null = null;
    try {
      target = await resolveById(held);
    } catch {
      continue;
    }
    if (target === null || target.remote !== true || typeof target.key !== 'string') continue;
    const local = localCounterpart(target);
    if (local === null || local === held) continue;
    const prop = key.split('#')[0];
    if (typeof owner.editComponentProperty !== 'function') {
      repairs.push({
        owner: owner.name,
        prop: prop,
        from: held,
        to: local,
        ok: false,
        why: 'editComponentProperty 를 쓸 수 없다',
      });
      continue;
    }
    try {
      owner.editComponentProperty(key, { defaultValue: local });
      repairs.push({ owner: owner.name, prop: prop, from: held, to: local, ok: true });
    } catch (e) {
      repairs.push({
        owner: owner.name,
        prop: prop,
        from: held,
        to: local,
        ok: false,
        why: String(e),
      });
    }
  }
  return repairs;
}

/** 로그 줄. 순수. */
export function formatSwapDefaultRepairs(repairs: readonly SwapDefaultRepair[]): string[] {
  return repairs.map((r) =>
    r.ok
      ? `↻ ${r.owner}: 교체 기본값이 로컬 컴포넌트의 원격 사본을 가리켜 로컬로 되돌림 — ` +
        `${r.prop}: ${r.from} → ${r.to}`
      : `⚠ ${r.owner}: 교체 기본값이 로컬 컴포넌트의 원격 사본을 가리키지만 되돌리지 못했다 — ` +
        `${r.prop}: ${r.from} → ${r.to} (${r.why ?? ''})`,
  );
}

/**
 * 원격 노드 `target` 과 같은 key 의 로컬 노드를 찾는다. `localSet(name)` 은 이름으로 문서의
 * 로컬 컴포넌트(세트)를 답한다 — 사본은 원본과 같은 이름의 세트 안에 같은 이름의 변형으로 온다.
 */
export function localCounterpartByKey(
  target: SwapTargetLike,
  localSet: (name: string) => {
    readonly id: string;
    readonly type: string;
    readonly key?: string;
    readonly children?: readonly { readonly id: string; readonly key?: string }[];
  } | null,
): string | null {
  const parent = target.parent;
  const setName = parent != null && parent.type === 'COMPONENT_SET' ? parent.name : target.name;
  const local = localSet(setName);
  if (local === null) return null;
  if (local.type === 'COMPONENT_SET') {
    const hit = (local.children ?? []).find((c) => c.key === target.key);
    return hit ? hit.id : null;
  }
  return local.key === target.key ? local.id : null;
}
