/// <reference types="@figma/plugin-typings" />

// Consumer-file collection overrides.
//
// Figma's Extended Variable Collections are the native override mechanism:
// the consumer inherits the published collection (and therefore keeps
// receiving new variables) while storing only its changed values locally.
// Creating an unrelated local copy with the same name would not override the
// variables already bound to library component instances.
//
// 덮어쓰기는 파일에 있는 라이브러리 변수에만 걸린다. 파일을 다시 열면 이 파일이
// 쓰지 않는 라이브러리 변수가 그 덮어쓰기와 함께 정리되고, 컴포넌트를 넣어 그
// 변수가 다시 들어와도 예전 덮어쓰기는 돌아오지 않는다(2026-11-01 실측 — 확장
// 컬렉션마다 125개이던 덮어쓰기가 다시 연 뒤 45개). 그 변수는 다시 넣기 전까지
// CoUI 기본값으로 칠해진다. 그래서 「이름으로 다시 맞추기」
// (`resyncOverridesByName`)가 덮어쓰기가 빈 변수를 같은 이름의 값으로 다시 채운다.
// 무엇으로 채우는지는 확장 컬렉션이 누구의 것이냐로 갈린다:
//
//   - 코드 브랜드의 확장(`brand-table.ts` — `Semantic/ Color · CoUI → Medibooks`)은
//     코드가 정한 브랜드 값 표로 채운다(`fillBrandOverrides`). 표는 브랜드가 CoUI 와
//     다른 값만 담고, 나머지는 CoUI 를 따라간다. 브랜드를 쓰는 소비 파일의 연결은
//     CoUI 변수 그대로이고 값만 이 확장이 덮는다 — 연결을 바꾸지 않는다.
//   - 그 밖의 확장(디자이너가 직접 연 것)은 같은 이름 · 같은 타입의 로컬 변수의
//     별칭으로 채운다(`planResync`).

import {
  BRANDS,
  brandExtensionNameFor,
  brandOfExtension,
  findBrand,
  planBrandFill,
  sameColor,
  type BrandFillTarget,
  type BrandTable,
} from './brand-table';

export interface OverrideCollectionRef {
  key: string;
  name: string;
  libraryName: string;
  extended: boolean;
  extensionName?: string;
}

export function extensionNameFor(name: string): string {
  return `${name} · Overrides`;
}

export async function listOverrideCollections(): Promise<OverrideCollectionRef[]> {
  const [libraryCollections, localCollections] = await Promise.all([
    figma.teamLibrary.getAvailableLibraryVariableCollectionsAsync(),
    figma.variables.getLocalVariableCollectionsAsync(),
  ]);

  // The root collection id is only available after an extension exists. Resolve
  // it back to the published key once and use that key as the stable UI id.
  const extensionByRootKey = new Map<string, VariableCollection>();
  for (const local of localCollections) {
    if (!local.isExtension) continue;
    // `isExtension` is the runtime discriminant, but the upstream typings do
    // not currently declare VariableCollection as a discriminated union.
    const extension = local as unknown as ExtendedVariableCollection;
    const root = await figma.variables.getVariableCollectionByIdAsync(
      extension.rootVariableCollectionId,
    );
    if (root?.key) extensionByRootKey.set(root.key, local);
  }

  return libraryCollections
    .map((library) => {
      const extension = extensionByRootKey.get(library.key);
      return {
        key: library.key,
        name: library.name,
        libraryName: library.libraryName,
        extended: extension != null,
        extensionName: extension?.name,
      };
    })
    .sort((a, b) =>
      a.libraryName === b.libraryName
        ? a.name.localeCompare(b.name)
        : a.libraryName.localeCompare(b.libraryName),
    );
}

// Figma 가 플랜을 이유로 확장 생성을 거부할 때 내는 문장. 문서는 Enterprise 기능이라고
// 하지만 Organization 플랜 파일에서도 만들어졌다(#6238 실측) — 그래서 플랜을 미리 판정하지
// 않고 Figma 가 거부할 때만 알린다.
const kPlanRefused = /Cannot create extended collections outside of enterprise plan/;

/**
 * 라이브러리 컬렉션 하나의 확장 컬렉션을 만든다. Figma 가 플랜을 이유로 거부하면 같은
 * 이름의 로컬 복사본을 대신 만들지 않고 그 이유를 알린다 — 로컬 복사본은 컴포넌트가 이미
 * 가진 바인딩을 덮어쓰지 못한다.
 */
export async function extendLibraryCollection(
  collection: Pick<OverrideCollectionRef, 'key'>,
  name: string,
): Promise<ExtendedVariableCollection> {
  try {
    return (await figma.variables.extendLibraryCollectionByKeyAsync(
      collection.key,
      name,
    )) as unknown as ExtendedVariableCollection;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (kPlanRefused.test(message)) {
      throw new Error(
        'Figma 가 이 파일의 플랜에서는 확장 컬렉션을 만들 수 없다고 거부했습니다 (Enterprise 플랜 기능으로 안내됨). ' +
          '라이브러리 변수의 로컬 복사본은 컴포넌트 바인딩을 오버라이드하지 않으므로 대신 만들지 않았습니다.',
      );
    }
    throw error;
  }
}

export async function createCollectionOverrides(keys: string[]): Promise<string[]> {
  const requested = new Set(keys);
  if (requested.size === 0) throw new Error('오버라이드할 컬렉션을 1개 이상 선택하세요.');

  const available = await listOverrideCollections();
  const byKey = new Map(available.map((collection) => [collection.key, collection]));
  const unknown = [...requested].filter((key) => !byKey.has(key));
  if (unknown.length > 0) {
    throw new Error(
      `활성화된 라이브러리에서 ${unknown.length}개 컬렉션을 찾지 못했습니다. 목록을 새로고침하세요.`,
    );
  }

  const log: string[] = [];
  for (const key of requested) {
    const collection = byKey.get(key)!;
    if (collection.extended) {
      log.push(`= 이미 생성됨: ${collection.libraryName} / ${collection.name}`);
      continue;
    }
    await extendLibraryCollection(collection, extensionNameFor(collection.name));
    log.push(`+ 오버라이드 생성: ${collection.libraryName} / ${collection.name}`);
  }
  log.push(`✓ 선택 ${requested.size}개 컬렉션 처리 완료`);
  log.push('Variables 패널에서 생성된 확장 컬렉션의 필요한 값만 바꾸면 됩니다.');
  return log;
}

// ─── 덮어쓰기 실패의 원인 ────────────────────────────────────────────────────

/** 확장 컬렉션의 `setValueForMode` 가 낸 오류가 `Mismatched variable type` 인가. */
export function isMismatchedVariableType(message: string): boolean {
  return /Mismatched variable type/i.test(message);
}

/**
 * `Mismatched variable type` 의 원인과 할 일. 타입이 같은 별칭인데도 이 오류가 나는
 * 것은 이 파일이 같은 키의 라이브러리 변수를 두 번 가져와 사본이 둘이라서다 — 사본이
 * 둘인 동안은 옛 사본도 현재 사본도 덮어쓰기가 거부된다(2026-11-01 실측).
 * `library-copies.ts` 가 그 상태를 찾고 옮긴다.
 */
export function mismatchedCopiesHint(names: readonly string[]): string {
  return (
    `덮어쓰지 못한 변수 ${names.length}개(${names.join(', ')}) — Figma 가 "Mismatched variable type" 으로 ` +
    '거부했다. 타입이 같은데도 이 오류가 나면 이 파일이 같은 라이브러리 변수를 두 번 가져와 사본이 둘이라서다 ' +
    '— 사본이 둘인 동안은 옛 사본도 현재 사본도 덮어쓸 수 없다. 관리 탭의 「소비 파일 점검」이 「가져온 사본 ' +
    '중복」으로 보여 준다. 「옛 사본 다시 연결」을 누르고 파일을 닫았다가 다시 연 뒤 이 명령을 다시 돌린다.'
  );
}

// ─── 같은 이름의 로컬 토큰으로 다시 맞추기 ───────────────────────────────────

/** 확장 컬렉션의 변수 하나. */
export interface ResyncTarget {
  id: string;
  name: string;
  resolvedType: string;
  /** 어느 모드에든 덮어쓰기가 있으면 true — 그 변수는 건드리지 않는다. */
  overridden: boolean;
}

/** 이 파일의 로컬 변수(확장 컬렉션이 아닌 컬렉션의 것). */
export interface ResyncLocal {
  id: string;
  name: string;
  resolvedType: string;
  collectionId: string;
  collectionName: string;
}

export interface ResyncPlan {
  /** 별칭을 넣을 변수와 그 짝. */
  set: { variableId: string; name: string; localId: string }[];
  /** 이미 덮어쓴 변수의 수. */
  overridden: number;
  /** 이름과 타입이 같은 로컬 변수가 없는 변수. */
  noCounterpart: string[];
  /** 짝이 될 로컬 변수가 둘 이상이라 고르지 않은 변수. */
  ambiguous: { name: string; collections: string[] }[];
}

/**
 * 덮어쓰기가 없는 변수마다 짝이 될 로컬 변수. 이름과 타입이 같은 로컬 변수가 하나면
 * 그것이다. 둘 이상이면 이 확장 컬렉션의 기존 덮어쓰기가 가장 많이 가리키는 로컬
 * 컬렉션([aliasedLocalIds] 의 컬렉션)의 것을 고른다 — 브랜드마다 로컬 컬렉션을 둔
 * 파일에서는 같은 이름이 브랜드 수만큼 있고, 확장 컬렉션이 어느 브랜드인지는 이미
 * 넣은 덮어쓰기가 말한다. 그래도 하나로 좁혀지지 않으면 추측하지 않는다.
 */
export function planResync(
  targets: readonly ResyncTarget[],
  locals: readonly ResyncLocal[],
  aliasedLocalIds: readonly string[],
): ResyncPlan {
  const collectionOfLocal = new Map(locals.map((l) => [l.id, l.collectionId]));
  const votes = new Map<string, number>();
  for (const id of aliasedLocalIds) {
    const collection = collectionOfLocal.get(id);
    if (collection != null) votes.set(collection, (votes.get(collection) ?? 0) + 1);
  }
  let paired: string | null = null;
  let most = 0;
  for (const [collection, n] of votes) {
    if (n > most) {
      paired = collection;
      most = n;
    } else if (n === most) {
      paired = null; // 동률이면 어느 쪽도 아니다
    }
  }
  const plan: ResyncPlan = { set: [], overridden: 0, noCounterpart: [], ambiguous: [] };
  const seen = new Set<string>();
  for (const t of targets) {
    if (seen.has(t.id)) continue;
    seen.add(t.id);
    if (t.overridden) {
      plan.overridden += 1;
      continue;
    }
    const candidates = locals.filter((l) => l.name === t.name && l.resolvedType === t.resolvedType);
    let chosen = candidates.length === 1 ? candidates[0] : null;
    if (chosen == null && candidates.length > 1 && paired != null) {
      const inPaired = candidates.filter((l) => l.collectionId === paired);
      if (inPaired.length === 1) chosen = inPaired[0];
    }
    if (chosen != null) plan.set.push({ variableId: t.id, name: t.name, localId: chosen.id });
    else if (candidates.length === 0) plan.noCounterpart.push(t.name);
    else plan.ambiguous.push({ name: t.name, collections: candidates.map((l) => l.collectionName) });
  }
  return plan;
}

function aliasTargetOf(value: unknown): string | null {
  if (value == null || typeof value !== 'object') return null;
  const alias = value as { type?: unknown; id?: unknown };
  return alias.type === 'VARIABLE_ALIAS' && typeof alias.id === 'string' ? alias.id : null;
}

/**
 * 「같은 이름의 로컬 토큰으로 다시 맞추기」 — 이 파일의 확장 컬렉션마다, 덮어쓰기가
 * 없는 변수에 이름과 타입이 같은 로컬 변수의 별칭을 모든 확장 모드에 넣는다. 짝이 없는
 * 변수는 이름을 적는다. 라이브러리 컴포넌트를 넣은 뒤나 파일을 다시 연 뒤에 돌린다
 * (파일 머리). 넣은 뒤 컬렉션을 다시 읽어 덮어쓰기가 실제로 들어갔는지 센다.
 */
export async function resyncOverridesByName(): Promise<string[]> {
  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  // `isExtension` 이 런타임의 판별자다 — 타입 선언은 아직 합 타입이 아니다.
  const extensions = collections
    .filter((c) => c.isExtension)
    .map((c) => c as unknown as ExtendedVariableCollection);
  if (extensions.length === 0) {
    return [
      '이 파일에 확장 컬렉션이 없다 — 위 목록에서 컬렉션을 골라 「선택 컬렉션 생성」부터 한다 ' +
        '(브랜드는 브랜드 탭의 「브랜드 확장 컬렉션 만들기」).',
    ];
  }
  const ownCollections = new Map<string, string>();
  for (const c of collections) if (!c.isExtension) ownCollections.set(c.id, c.name);
  const locals: ResyncLocal[] = [];
  const localById = new Map<string, Variable>();
  for (const v of await figma.variables.getLocalVariablesAsync()) {
    const collectionName = ownCollections.get(v.variableCollectionId);
    if (v.remote || collectionName == null) continue;
    locals.push({ id: v.id, name: v.name, resolvedType: v.resolvedType, collectionId: v.variableCollectionId, collectionName });
    localById.set(v.id, v);
  }

  const log: string[] = [];
  const mismatched = new Set<string>();
  for (const ext of extensions) {
    // 코드 브랜드의 확장은 같은 이름의 로컬 변수가 아니라 코드가 정한 브랜드 값 표로 채운다.
    const brand = brandOfExtension(ext.name);
    if (brand != null) {
      const filled = await fillBrandOverrides(ext, brand);
      log.push(...filled.log);
      for (const name of filled.mismatched) mismatched.add(name);
      continue;
    }
    const overrides = ext.variableOverrides;
    const variables = new Map<string, Variable>();
    const targets: ResyncTarget[] = [];
    for (const id of ext.variableIds) {
      const v = await figma.variables.getVariableByIdAsync(id);
      if (v == null) continue;
      variables.set(id, v);
      const modes = overrides[id];
      targets.push({ id, name: v.name, resolvedType: v.resolvedType, overridden: modes != null && Object.keys(modes).length > 0 });
    }
    const aliased: string[] = [];
    for (const modes of Object.values(overrides)) {
      for (const value of Object.values(modes)) {
        const target = aliasTargetOf(value);
        if (target != null) aliased.push(target);
      }
    }
    const plan = planResync(targets, locals, aliased);

    let wrote = 0;
    const failed: string[] = [];
    for (const item of plan.set) {
      const variable = variables.get(item.variableId);
      const local = localById.get(item.localId);
      if (variable == null || local == null) continue;
      try {
        for (const mode of ext.modes) variable.setValueForMode(mode.modeId, figma.variables.createVariableAlias(local));
        wrote += 1;
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        if (isMismatchedVariableType(message)) mismatched.add(item.name);
        else failed.push(`${item.name} — ${message}`);
      }
    }

    // 다시 읽어 센다 — 던지지 않았다고 들어간 것은 아니다.
    const fresh = (await figma.variables.getVariableCollectionByIdAsync(ext.id)) as unknown as
      | ExtendedVariableCollection
      | null;
    const confirmed = plan.set.filter((item) => {
      const modes = fresh?.variableOverrides[item.variableId];
      return modes != null && ext.modes.every((m) => m.modeId in modes);
    }).length;
    const noCounterpart = [...new Set(plan.noCounterpart)];
    log.push(
      `${confirmed === wrote ? '✓' : '⚠'} ${ext.name}: 덮어쓰기 넣음 ${wrote}개 (다시 읽어 확인 ${confirmed}) · ` +
        `이미 덮어씀 ${plan.overridden} · 짝 없음 ${noCounterpart.length}`,
    );
    if (noCounterpart.length > 0) log.push(`  짝 없음 — ${noCounterpart.join(', ')}`);
    for (const a of plan.ambiguous) {
      log.push(`  ⚠ ${a.name} — 같은 이름의 로컬 변수가 둘 이상이라 고르지 않았다 (${a.collections.join(' · ')})`);
    }
    for (const f of failed) log.push(`  ⚠ 덮어쓰지 못함 — ${f}`);
  }
  if (mismatched.size > 0) log.push(`⚠ ${mismatchedCopiesHint([...mismatched])}`);
  log.push(
    `확장 컬렉션 ${extensions.length}개를 맞췄다. 라이브러리 컴포넌트를 넣은 뒤나 파일을 다시 연 뒤에 다시 ` +
      '돌린다 — 그때 다시 들어온 변수는 덮어쓰기 없이 CoUI 기본값으로 칠해진다.',
  );
  return log;
}

// ─── 코드 브랜드의 확장 컬렉션 ────────────────────────────────────────────────

export interface BrandFillResult {
  log: string[];
  /** 넣었다고 던지지 않은 (변수, 모드) 쌍의 수. */
  wrote: number;
  /** 넣은 뒤 컬렉션을 다시 읽어 값이 실제로 있는 쌍의 수. */
  confirmed: number;
  /** `Mismatched variable type` 으로 거부된 변수. */
  mismatched: string[];
}

const kMaxNamesInLog = 8;

function listNames(names: readonly string[]): string {
  const shown = names.slice(0, kMaxNamesInLog).join(', ');
  return names.length > kMaxNamesInLog ? `${shown} … (+${names.length - kMaxNamesInLog})` : shown;
}

/**
 * 확장 컬렉션 [ext] 에 코드 브랜드 [table] 의 값을 채운다 — 표의 행마다 이름이 같은
 * 확장 변수의 모드마다 색을 덮어쓴다. 이미 그 값이면 쓰지 않고, 표에 없는 덮어쓰기는
 * 세기만 하고 지우지 않는다(손으로 넣은 값일 수 있다). 이 파일에 없는 변수(그 변수를
 * 쓰는 컴포넌트가 아직 파일에 없다)는 이름을 적는다 — 파일을 다시 열면 쓰지 않는 변수의
 * 덮어쓰기가 정리되므로(파일 머리), 컴포넌트를 넣은 뒤 다시 돌리면 그때 채워진다. 넣은 뒤
 * 컬렉션을 다시 읽어 값이 실제로 들어갔는지 센다.
 */
export async function fillBrandOverrides(
  ext: ExtendedVariableCollection,
  table: BrandTable,
): Promise<BrandFillResult> {
  const root = await figma.variables.getVariableCollectionByIdAsync(ext.rootVariableCollectionId);
  if (root != null && root.name !== BRANDS.library.collection) {
    return {
      log: [
        `⚠ ${ext.name}: 이름은 ${table.displayName} 브랜드의 확장이지만 원본이 "${root.name}" 이다 ` +
          `("${BRANDS.library.collection}" 이어야 한다) — 값을 넣지 않았다.`,
      ],
      wrote: 0,
      confirmed: 0,
      mismatched: [],
    };
  }

  const variables = new Map<string, Variable>();
  const targets: BrandFillTarget[] = [];
  for (const id of ext.variableIds) {
    const v = await figma.variables.getVariableByIdAsync(id);
    if (v == null) continue;
    variables.set(id, v);
    targets.push({ id, name: v.name, resolvedType: v.resolvedType });
  }
  const plan = planBrandFill(table, targets, ext.modes, ext.variableOverrides);

  let wrote = 0;
  const failed: string[] = [];
  const mismatched = new Set<string>();
  for (const item of plan.set) {
    const variable = variables.get(item.variableId);
    if (variable == null) continue;
    try {
      variable.setValueForMode(item.modeId, item.value as RGBA);
      wrote += 1;
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      if (isMismatchedVariableType(message)) mismatched.add(item.name);
      else failed.push(`${item.name} @ ${item.modeName} — ${message}`);
    }
  }

  // 다시 읽어 센다 — 던지지 않았다고 들어간 것은 아니다.
  const fresh = (await figma.variables.getVariableCollectionByIdAsync(ext.id)) as unknown as
    | ExtendedVariableCollection
    | null;
  const confirmed = plan.set.filter((item) =>
    sameColor(fresh?.variableOverrides[item.variableId]?.[item.modeId], item.value),
  ).length;

  const log = [
    `${confirmed === wrote && failed.length === 0 && mismatched.size === 0 ? '✓' : '⚠'} ${ext.name}: ` +
      `${table.displayName} 값 넣음 ${wrote}개 (다시 읽어 확인 ${confirmed}) · 이미 맞음 ${plan.alreadyRight} · ` +
      `이 파일에 없는 변수 ${plan.absent.length}`,
  ];
  if (plan.absent.length > 0) {
    log.push(
      `  이 파일에 없는 변수 — ${listNames(plan.absent)} (그 변수를 쓰는 컴포넌트를 넣은 뒤 ` +
        '「이름으로 다시 맞추기」를 다시 돌린다)',
    );
  }
  if (plan.notColor.length > 0) {
    log.push(`  ⚠ 색이 아닌 변수라 건너뜀 — ${listNames(plan.notColor)}`);
  }
  if (plan.noMode.length > 0) {
    log.push(`  ⚠ 확장 컬렉션에 없는 모드 — ${plan.noMode.join(', ')}`);
  }
  if (plan.strayOverrides > 0) {
    log.push(`  표에 없는 덮어쓰기 ${plan.strayOverrides}개 — 손으로 넣은 값이거나 이전 표의 값이라 건드리지 않았다`);
  }
  for (const f of failed) log.push(`  ⚠ 덮어쓰지 못함 — ${f}`);
  return { log, wrote, confirmed, mismatched: [...mismatched] };
}

/**
 * 「브랜드 확장 컬렉션 만들기」 — 라이브러리의 `Semantic/ Color` 컬렉션을 이 파일의 확장
 * 컬렉션으로 열고(이미 있으면 그대로 두고) 코드 브랜드의 값을 채운다. 연결은 CoUI 변수
 * 그대로이고 값만 확장 컬렉션이 덮는다 — 컴포넌트와 화면의 색 바인딩을 바꾸지 않는다.
 */
export async function applyBrandExtension(brandName: string): Promise<string[]> {
  const brand = findBrand(brandName);
  if (brand == null) {
    throw new Error(
      `브랜드 "${brandName}" 를 찾을 수 없습니다. 코드 브랜드: ` +
        (BRANDS.brands.map((b) => b.displayName).join(', ') || '(없음)'),
    );
  }

  const libraries = (await listOverrideCollections()).filter((c) => c.name === BRANDS.library.collection);
  if (libraries.length === 0) {
    throw new Error(
      `활성화된 라이브러리에서 "${BRANDS.library.collection}" 컬렉션을 찾지 못했습니다 — ` +
        'Assets 에서 CoUI 라이브러리를 활성화하고 목록을 새로고침하세요.',
    );
  }
  if (libraries.length > 1) {
    throw new Error(
      `"${BRANDS.library.collection}" 컬렉션이 라이브러리 ${libraries.length}곳에 있어 어느 것의 브랜드인지 고르지 ` +
        `않았습니다 (${libraries.map((l) => l.libraryName).join(', ')}). 쓰지 않는 라이브러리를 비활성화하세요.`,
    );
  }
  const library = libraries[0];

  const name = brandExtensionNameFor(brand);
  const log: string[] = [`브랜드: ${brand.displayName} — ${library.libraryName} / ${library.name} 의 확장`];
  const locals = await figma.variables.getLocalVariableCollectionsAsync();
  let ext = locals.find((c) => c.isExtension && c.name === name) as unknown as
    | ExtendedVariableCollection
    | undefined;
  if (ext != null) {
    log.push(`= 이미 생성됨: ${name}`);
  } else {
    const created = await extendLibraryCollection(library, name);
    // 만든 직후의 컬렉션을 다시 읽는다 — 이 파일에 있는 변수는 거기서 읽는다.
    ext =
      ((await figma.variables.getVariableCollectionByIdAsync(created.id)) as unknown as
        | ExtendedVariableCollection
        | null) ?? created;
    log.push(`+ 확장 컬렉션 생성: ${name}`);
  }

  const filled = await fillBrandOverrides(ext, brand);
  log.push(...filled.log);
  if (filled.mismatched.length > 0) log.push(`⚠ ${mismatchedCopiesHint(filled.mismatched)}`);
  return log;
}
