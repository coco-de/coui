/// <reference types="@figma/plugin-typings" />

import { RegistryEntry } from './helpers';
import { FORM_BUILDERS } from './components/form';
import { FORM_FIELDS } from './components/form-fields';
import { FORM_CONTROLS } from './components/form-controls';
import { FORM_OPTIONS } from './components/form-options';
import { FORM_PICKERS } from './components/form-pickers';
import { ICON_BUILDERS } from './components/icon';
import { PRIMITIVES_LAYOUT } from './components/primitives-layout';
import { PRIMITIVES_CHROME } from './components/primitives-chrome';
import { PRIMITIVES_DATA } from './components/primitives-data';
import { PRIMITIVES_BEHAVIOUR } from './components/primitives-behaviour';
import { DISPLAY_BUILDERS } from './components/display';
import { DISPLAY_DATA } from './components/display-data';
import { DISPLAY_MEDIA } from './components/display-media';
import { NAVIGATION_BUILDERS } from './components/navigation';
import { SIDEBAR_BUILDERS } from './components/sidebar';
import { OVERLAY_BUILDERS } from './components/overlay';
import { LAYOUT_BUILDERS } from './components/layout';
import { FIXTURE_BUILDERS } from './components/fixtures';

import { POPUP_BUILDERS } from './components/popup';
import { PRIMITIVES_SURFACES } from './components/primitives-surfaces';
import { PRIMITIVES_COMPOSITION } from './components/primitives-composition';
import { COMMAND_BUILDERS } from './components/command';
import { COMMAND_SEARCH_BUILDERS } from './components/command-search';
import { COMMAND_ITEM_BUILDERS } from './components/command-item';
import { OVERLAY_VIEWS } from './components/overlay-views';

// #4023 (B2) — page placement no longer reads RegistryEntry.section: the
// target page is derived from schema v3's `section` fold (see
// generate.ts). The literal `section:` field on each entry below remains
// ONLY as check_figma_registry_parity.sh's extraction anchor (its grep
// keys on the `section: '…', name: '…'` shape) — do not consume it for
// behavior; removing it means updating that guard's extraction in the
// same change.

// Every component the plugin can generate. Single source of truth for both the
// generation loop and the idempotency name set.
// `Icon` is registered LAST on purpose, even though everything else depends on
// it. If it were first, `topoSortRegistry` would put it first anyway — by
// position, not by the declared edge — and the ordering mechanism would be
// decorative: break it and nothing would notice. Registered last, the only
// thing that gets `Icon` built before its 32 consumers is the `needs` edge, so
// every run exercises it, and a builder that forgets to declare `needs` fails
// immediately (`makeIcon` throws: the component isn't on the page yet).
export const REGISTRY: RegistryEntry[] = FORM_BUILDERS.concat(
  FORM_FIELDS,
  FORM_CONTROLS,
  FORM_OPTIONS,
  FORM_PICKERS,
  DISPLAY_BUILDERS,
  DISPLAY_DATA,
  DISPLAY_MEDIA,
  NAVIGATION_BUILDERS,
  SIDEBAR_BUILDERS,
  OVERLAY_BUILDERS,
  COMMAND_BUILDERS,
  COMMAND_SEARCH_BUILDERS,
  COMMAND_ITEM_BUILDERS,
  OVERLAY_VIEWS,
  LAYOUT_BUILDERS,
  // The 41 components that had no builder at all. They land after the
  // hand-built sections so the page columns keep their curated order; build
  // order is decided by `topoSortRegistry`, not by position here.
  PRIMITIVES_LAYOUT,
  POPUP_BUILDERS,
  PRIMITIVES_SURFACES,
  PRIMITIVES_CHROME,
  PRIMITIVES_COMPOSITION,
  PRIMITIVES_DATA,
  PRIMITIVES_BEHAVIOUR,
  ICON_BUILDERS,
  // Sets the builders draw for their own use (`.Slot`, the empty-slot stand-in)
  // — no CoUI component behind them, unpublished, and never a data slug.
  FIXTURE_BUILDERS,
);

/**
 * 레지스트리 배열의 이름 → 그 배열의 엔트리. 엔트리의 소스 해시는 **그 엔트리가 놓인
 * 배열의 키**로 찾는다(`entry-source.ts`) — 키의 목록은 위 `./components/*` import 의
 * 식별자와 같아야 하고(번들 단계의 `scripts/entry-source-hash.mjs` 가 같은 import 줄에서
 * 키를 읽는다), 같은지는 `selftest:entry-hash` 가 본다.
 */
export const SOURCE_GROUPS: Readonly<Record<string, readonly RegistryEntry[]>> = {
  FORM_BUILDERS,
  FORM_FIELDS,
  FORM_CONTROLS,
  FORM_OPTIONS,
  FORM_PICKERS,
  ICON_BUILDERS,
  PRIMITIVES_LAYOUT,
  POPUP_BUILDERS,
  PRIMITIVES_SURFACES,
  PRIMITIVES_CHROME,
  PRIMITIVES_COMPOSITION,
  PRIMITIVES_DATA,
  PRIMITIVES_BEHAVIOUR,
  DISPLAY_BUILDERS,
  DISPLAY_DATA,
  DISPLAY_MEDIA,
  NAVIGATION_BUILDERS,
  SIDEBAR_BUILDERS,
  OVERLAY_BUILDERS,
  COMMAND_BUILDERS,
  COMMAND_SEARCH_BUILDERS,
  COMMAND_ITEM_BUILDERS,
  OVERLAY_VIEWS,
  LAYOUT_BUILDERS,
  FIXTURE_BUILDERS,
};

// Build order that satisfies every declared `needs` edge.
//
// A builder that instantiates a child component needs that child to already
// exist on the page; section order can't express that (Form runs before
// Overlay, yet `PhoneInput` needs `Popover`). Kahn's algorithm over the
// declared edges, with ties broken by original REGISTRY position so the order
// stays deterministic — the content-hash skip and the golden self-tests both
// depend on two runs agreeing.
//
// A missing name is a hard error, not a skipped edge: `needs: ['Popver']` would
// otherwise typo its way into "no dependency" and the parent would instantiate
// nothing at run time. A cycle is also a hard error — there is no order that
// satisfies it, and picking one arbitrarily makes whichever component loses
// build against a child that isn't there yet.
export function topoSortRegistry(entries: readonly RegistryEntry[]): RegistryEntry[] {
  const byName = new Map<string, RegistryEntry>();
  for (const e of entries) byName.set(e.name, e);

  const indegree = new Map<string, number>();
  const dependents = new Map<string, string[]>();
  for (const e of entries) indegree.set(e.name, 0);
  for (const e of entries) {
    for (const need of e.needs ?? []) {
      if (!byName.has(need)) {
        throw new Error(
          `REGISTRY: '${e.name}' declares needs: '${need}', which is not a ` +
            'REGISTRY name. A name that resolves to nothing would leave the ' +
            'parent instantiating a component that was never built.',
        );
      }
      indegree.set(e.name, (indegree.get(e.name) ?? 0) + 1);
      const arr = dependents.get(need);
      if (arr) arr.push(e.name);
      else dependents.set(need, [e.name]);
    }
  }

  const position = new Map<string, number>();
  entries.forEach((e, i) => position.set(e.name, i));
  const ready = entries.filter((e) => (indegree.get(e.name) ?? 0) === 0).map((e) => e.name);
  const out: RegistryEntry[] = [];
  while (ready.length > 0) {
    // Lowest original index first — deterministic, and keeps the order as close
    // to the authored one as the edges allow.
    ready.sort((a, b) => (position.get(a) ?? 0) - (position.get(b) ?? 0));
    const name = ready.shift()!;
    out.push(byName.get(name)!);
    for (const dep of dependents.get(name) ?? []) {
      const left = (indegree.get(dep) ?? 0) - 1;
      indegree.set(dep, left);
      if (left === 0) ready.push(dep);
    }
  }

  if (out.length !== entries.length) {
    const stuck = entries.filter((e) => !out.includes(e)).map((e) => e.name);
    throw new Error(
      `REGISTRY: dependency cycle among [${stuck.join(', ')}] — no build order ` +
        'satisfies it. Break the cycle by having one side draw its own chrome ' +
        'instead of instantiating the other.',
    );
  }
  return out;
}

// ─── 스코프의 `needs` 폐포 (#4038 / C5) ─────────────────────────────────────

/**
 * 고른 엔트리 집합을 `needs` 간선을 따라 **전이적으로 닫는다**. 순수.
 *
 * ## 이 함수가 존재하는 이유
 *
 * C5 의 AC 는 "섹션별 실행의 **합집합이 전체 실행과 같은 결과**를 낸다" 고
 * 적는다. 폐포 없이는 그 문장이 **빈 문서에서 거짓**이다 — `needs` 자식이
 * 다른 섹션에 있으면 그 섹션을 먼저 돌지 않은 실행은 자식이 페이지에 없는
 * 채로 부모를 그리고, 부모는 반쯤 그려진 채 남는다. 실행 순서에 따라 결과가
 * 달라지는 것은 "같은 결과" 가 아니다.
 *
 * 스코프 필터는 정렬 **뒤에** 걸리므로 범위 안의 의존 순서는 이미 지켜진다.
 * 빠진 것은 범위 **밖으로** 나간 자식이었고, 그 자리를 이 함수가 막는다.
 *
 * ## 왜 경고가 아니라 포함인가
 *
 * 경고는 사용자에게 "다시 돌려라" 를 시키고, AC 는 보장을 요구한다. 그리고
 * 포함의 대가가 거의 없다 — 이미 최신인 자식은 per-entry 내용 해시에서
 * **skip** 되므로, 폐포는 자식이 낡았을 때만 비용을 쓴다. 정확히 필요한
 * 때만 값을 치른다.
 *
 * `needs` 이름이 REGISTRY 에 없으면 `topoSortRegistry` 가 이미 던진다 —
 * 여기서 조용히 무시하면 그 하드 에러를 우회하게 되므로 그냥 넘긴다.
 */
export function closeOverNeeds(
  selected: ReadonlySet<string>,
  entries: readonly RegistryEntry[],
): { closed: Set<string>; added: string[] } {
  const byName = new Map<string, RegistryEntry>();
  for (const e of entries) byName.set(e.name, e);

  const closed = new Set<string>();
  const added: string[] = [];
  const stack = [...selected];
  while (stack.length > 0) {
    const name = stack.pop() as string;
    if (closed.has(name)) continue;
    closed.add(name);
    if (!selected.has(name)) added.push(name);
    for (const need of byName.get(name)?.needs ?? []) {
      if (!closed.has(need)) stack.push(need);
    }
  }
  added.sort();
  return { closed, added };
}
