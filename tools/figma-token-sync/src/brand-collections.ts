/// <reference types="@figma/plugin-typings" />

// 옛 브랜드 컬렉션 (#6211) — 소비 파일의 화면이 브랜드마다 따로 게시되던 라이브러리
// 컬렉션(`Semantic/ Color · <브랜드>`)에 묶여 있는 상태. 소비 파일 점검이 「옛 브랜드
// 컬렉션」으로 보고하고(읽기), 「옛 브랜드 컬렉션 다시 연결」이 그 참조를 같은 이름의
// `Semantic/ Color · CoUI` 변수로 옮긴다(쓰기).
//
// ## 무엇이 문제인가
//
// 브랜드는 라이브러리의 컬렉션이 아니라 값 표다 — 소비 파일이 `Semantic/ Color · CoUI` 를
// 확장 컬렉션으로 열고 코드의 브랜드 값 표로 덮는다(`brand-table.ts`). 확장은
// `Semantic/ Color · CoUI` 변수에 묶인 노드만 덮는다. 옛 브랜드 컬렉션에 묶인 노드는 그
// 컬렉션이 마지막으로 게시된 값으로 굳어, 브랜드 값이 바뀌어도 따라오지 않는다.
//
// ## 어느 컬렉션이 옛 브랜드 컬렉션인가
//
// 원격 컬렉션 이름이 옛 번호 접두(`1-1. `)를 뺀 뒤 `Semantic/ Color · <코드 브랜드 이름>` 인
// 것. 브랜드 이름은 코드 브랜드 목록(`brands.json`)에서 읽는다 — 목록에 없는 브랜드의
// 컬렉션은 건드리지 않는다. 라이브러리 브랜드의 컬렉션(`Semantic/ Color · CoUI`)은 옮길
// 곳 자체다.
//
// ## 무엇을 무엇으로 옮기는가
//
// 참조의 범위는 「옛 사본 다시 연결」(`library-copies.ts`)과 같다 — 노드 · 로컬 스타일 ·
// 로컬 별칭, 인스턴스 안은 이 파일이 덮어쓴 필드만, 라이브러리 컴포넌트 안에서 덮어쓰지
// 않은 바인딩은 따로 세고 옮기지 않는다. 짝은 라이브러리의 `Semantic/ Color · CoUI` 에서
// 같은 이름 · 같은 타입의 변수다. 점검은 라이브러리의 변수 목록만 읽고(가져오지 않는다),
// 쓰기 명령만 `importVariableByKeyAsync` 로 그 변수를 가져와 다시 묶는다. 짝이 없는
// 이름은 옮기지 않고 보고한다.
//
// 코드 브랜드의 원시값에 직접 묶인 곳(`Primitives` 의 `color/<브랜드 id>/…`)도 같은 굳음을
// 겪지만 옮기지 않는다 — 어느 시맨틱 슬롯이어야 하는지는 사람이 정한다. 수와 위치만
// 보고한다.
//
// ## 순수 판정과 Figma 읽기를 나눈 이유
//
// `library-copies.ts` 와 같다 — 판정(`scanOldBrandCollections`)은 노드와 조회를 주입받아
// 셀프테스트의 노드 더블 위에서 돈다. 문서에 쓰는 것은 `rebindOldBrandCollections` 하나다.

import { BRANDS, type BrandTable, type BrandsDoc } from './brand-table';
import { kAuditIdsPerPage, type AuditGroup, type AuditGroupPage, type ConsumerAuditReport, type OldBrandSummary } from './consumer-audit';
import {
  applyVariableSwap,
  asCopyPages,
  collectDocumentUses,
  collectNodeUses,
  countUses,
  failureLines,
  figmaCopyDeps,
  loadedPages,
  placesOf,
  placesText,
  tallyText,
  type CopyDeps,
  type CopyPage,
  type CopyUse,
} from './library-copies';
import { canonicalCollection, withoutOrderingPrefix } from './variables';
import { mismatchedCopiesHint } from './collection-overrides';

// ─── 모양 ────────────────────────────────────────────────────────────────────

/** 라이브러리의 `Semantic/ Color · CoUI` 의 변수 하나 — 팀 라이브러리 목록에서 읽은 것. */
export interface LibraryColorVariable {
  name: string;
  key: string;
  resolvedType: string;
}

export interface CouiLibrary {
  libraryName: string;
  variables: readonly LibraryColorVariable[];
}

export type BrandScanDeps = Pick<
  CopyDeps,
  'variableOf' | 'collectionOf' | 'mainOf' | 'localVariables' | 'extensions' | 'localStyles'
> & {
  /** 켜진 라이브러리의 `Semantic/ Color · CoUI` 변수 목록. 읽기만 한다. */
  couiLibrary(): Promise<CouiLibrary | { error: string }>;
};

// ─── 판정 — 순수 ─────────────────────────────────────────────────────────────

/** 컬렉션 이름이 옛 브랜드 컬렉션이면 그 브랜드. 번호 접두는 빼고 견준다. 라이브러리
 *  브랜드의 컬렉션과 코드 브랜드 목록에 없는 브랜드의 컬렉션은 null. */
export function oldBrandOfCollection(name: string, doc: BrandsDoc = BRANDS): BrandTable | null {
  const bare = withoutOrderingPrefix(name);
  if (bare === doc.library.collection) return null;
  return doc.brands.find((b) => bare === `Semantic/ Color · ${b.displayName}`) ?? null;
}

/** 변수가 코드 브랜드의 원시값(`Primitives` 의 `color/<브랜드 id>/…`)이면 그 브랜드. */
export function brandOfPrimitive(collectionName: string, variableName: string, doc: BrandsDoc = BRANDS): BrandTable | null {
  if (canonicalCollection(collectionName) !== 'Primitives') return null;
  return doc.brands.find((b) => variableName.startsWith(`color/${b.id}/`)) ?? null;
}

/** 옛 브랜드 컬렉션의 변수 하나와 그것을 참조하는 곳. */
export interface OldBrandFinding {
  variableId: string;
  name: string;
  resolvedType: string;
  brand: string;
  /** 원격 컬렉션의 이름 그대로(번호 접두 포함). */
  collection: string;
  /** 짝 — 같은 이름 · 같은 타입의 `Semantic/ Color · CoUI` 변수의 키. 없으면 null. */
  targetKey: string | null;
  /** 짝이 없는 까닭 — `targetKey` 가 null 일 때. */
  missing: string | null;
  uses: CopyUse[];
}

/** 코드 브랜드의 원시값에 직접 묶인 변수 하나와 그것을 참조하는 곳. */
export interface BrandPrimitiveFinding {
  variableId: string;
  name: string;
  brand: string;
  uses: CopyUse[];
}

export interface OldBrandScan {
  findings: OldBrandFinding[];
  primitives: BrandPrimitiveFinding[];
  /** 라이브러리의 `Semantic/ Color · CoUI` 를 읽지 못했으면 그 까닭 — 그때는 짝을 모른다. */
  libraryError: string | null;
  libraryName: string | null;
}

/** 파일 전체의 옛 브랜드 컬렉션 참조. 아무것도 쓰지 않는다. */
export async function scanOldBrandCollections(
  pages: readonly CopyPage[],
  deps: BrandScanDeps,
  doc: BrandsDoc = BRANDS,
): Promise<OldBrandScan> {
  const nodeUses = await collectNodeUses(pages, deps);
  const docUses = await collectDocumentUses(deps);
  const byVariable = new Map<string, CopyUse[]>();
  for (const use of [...nodeUses, ...docUses.uses]) {
    const list = byVariable.get(use.variableId);
    if (list == null) byVariable.set(use.variableId, [use]);
    else list.push(use);
  }

  const findings: OldBrandFinding[] = [];
  const primitives: BrandPrimitiveFinding[] = [];
  for (const [id, uses] of byVariable) {
    const v = await deps.variableOf(id);
    if (v == null || !v.remote) continue;
    const collection = await deps.collectionOf(v.collectionId);
    if (collection == null) continue;
    const brand = oldBrandOfCollection(collection.name, doc);
    if (brand != null) {
      findings.push({
        variableId: id,
        name: v.name,
        resolvedType: v.resolvedType,
        brand: brand.displayName,
        collection: collection.name,
        targetKey: null,
        missing: null,
        uses,
      });
      continue;
    }
    const primitiveBrand = brandOfPrimitive(collection.name, v.name, doc);
    if (primitiveBrand != null) primitives.push({ variableId: id, name: v.name, brand: primitiveBrand.displayName, uses });
  }

  let libraryError: string | null = null;
  let libraryName: string | null = null;
  if (findings.length > 0) {
    const library = await deps.couiLibrary();
    if ('error' in library) {
      libraryError = library.error;
    } else {
      libraryName = library.libraryName;
      const byName = new Map<string, LibraryColorVariable>();
      for (const lv of library.variables) byName.set(lv.name, lv);
      for (const f of findings) {
        const target = byName.get(f.name);
        if (target == null) f.missing = `"${doc.library.collection}" 에 같은 이름의 변수가 없다`;
        else if (target.resolvedType !== f.resolvedType) {
          f.missing = `같은 이름의 변수가 있지만 타입이 다르다 (${f.resolvedType} → ${target.resolvedType})`;
        } else f.targetKey = target.key;
      }
    }
  }
  if (libraryError != null) for (const f of findings) f.missing = `라이브러리를 읽지 못했다 — ${libraryError}`;

  findings.sort((a, b) => a.collection.localeCompare(b.collection) || a.name.localeCompare(b.name));
  primitives.sort((a, b) => a.name.localeCompare(b.name));
  return { findings, primitives, libraryError, libraryName };
}

// ─── 목록 · 문장 ─────────────────────────────────────────────────────────────

const kOldBrandLabel = '경고 · 옛 브랜드 컬렉션';
const kPrimitiveLabel = '경고 · 브랜드 원시값에 직접';
/** 원시값에 직접 묶인 곳을 로그에 적는 상한 — 나머지는 목록에 있다. */
export const kPrimitiveSampleLines = 5;

function nodePages(uses: readonly CopyUse[]): AuditGroupPage[] {
  const pages = new Map<string, AuditGroupPage & { idSet: Set<string> }>();
  for (const u of uses) {
    if (u.kind !== 'node' || u.pageId == null) continue;
    let page = pages.get(u.pageId);
    if (page == null) {
      page = { pageId: u.pageId, pageName: u.pageName ?? '', count: 0, ids: [], idSet: new Set() };
      pages.set(u.pageId, page);
    }
    if (page.idSet.has(u.ownerId)) continue;
    page.idSet.add(u.ownerId);
    page.count += 1;
    if (page.ids.length < kAuditIdsPerPage) page.ids.push(u.ownerId);
  }
  return [...pages.values()]
    .sort((a, b) => b.count - a.count)
    .map(({ pageId, pageName, count, ids }) => ({ pageId, pageName, count, ids }));
}

function groupOf(
  category: 'old-brand' | 'brand-primitive',
  label: string,
  signature: string,
  action: string,
  uses: readonly CopyUse[],
): AuditGroup {
  const counts = countUses(uses);
  const pages = nodePages(uses);
  const where = pages.map((p) => ({ name: p.pageName, count: p.count }));
  if (counts.styles > 0) where.push({ name: '스타일', count: counts.styles });
  if (counts.aliases > 0) where.push({ name: '별칭', count: counts.aliases });
  if (counts.library > 0) where.push({ name: '라이브러리 컴포넌트 안', count: counts.library });
  return {
    category,
    label,
    warn: true,
    signature,
    action,
    role: null,
    departs: [],
    runs: placesOf(counts),
    nodes: counts.nodes,
    sample: '',
    where,
    whereRest: 0,
    pages,
  };
}

function findingAction(f: OldBrandFinding, doc: BrandsDoc): string {
  const c = countUses(f.uses);
  const notes: string[] = [];
  if (f.targetKey == null) {
    notes.push(`옮기지 않는다 — ${f.missing ?? '짝을 모른다'}. 어느 슬롯이어야 하는지 정해 손으로 다시 연결한다`);
  } else if (placesOf(c) > 0) {
    notes.push(`「옛 브랜드 컬렉션 다시 연결」로 참조 ${placesOf(c)}곳(${placesText(c)})을 ${doc.library.collection} 의 같은 이름 변수로 옮긴다`);
  } else {
    notes.push('이 파일에는 옮길 참조가 없다');
  }
  if (c.library > 0) notes.push(`라이브러리 컴포넌트 안 ${c.library}곳은 덮어쓰지 않는다 — 라이브러리 업데이트를 받는다`);
  return notes.join('. ');
}

/** 옛 브랜드 컬렉션의 변수마다, 브랜드 원시값마다 목록 한 줄. */
export function oldBrandGroups(scan: OldBrandScan, doc: BrandsDoc = BRANDS): AuditGroup[] {
  const rows: AuditGroup[] = [];
  for (const f of scan.findings) {
    const target = f.targetKey == null ? '짝 없음' : `${doc.library.collection} / ${f.name}`;
    rows.push(groupOf('old-brand', kOldBrandLabel, `${f.collection} / ${f.name} → ${target}`, findingAction(f, doc), f.uses));
  }
  for (const p of scan.primitives) {
    rows.push(
      groupOf(
        'brand-primitive',
        kPrimitiveLabel,
        `Primitives / ${p.name} (${p.brand})`,
        '옮기지 않는다 — 어느 시맨틱 슬롯이어야 하는지 정해 손으로 다시 연결한다',
        p.uses,
      ),
    );
  }
  return rows;
}

/** 원시값에 직접 묶인 곳 몇 개 — `페이지 · 노드 · 필드 · 변수`. */
export function primitiveSamples(scan: OldBrandScan, limit = kPrimitiveSampleLines): string[] {
  const out: string[] = [];
  for (const p of scan.primitives) {
    for (const u of p.uses) {
      if (out.length >= limit) return out;
      const where = u.kind === 'node' ? `${u.pageName ?? ''} · "${u.ownerName}"` : `${u.kind === 'style' ? '스타일' : '별칭'} "${u.ownerName}"`;
      out.push(`${where} · ${u.field} · ${p.name}`);
    }
  }
  return out;
}

export function oldBrandSummary(scan: OldBrandScan): OldBrandSummary {
  let places = 0;
  let unmatched = 0;
  let library = 0;
  let primitivePlaces = 0;
  const unmatchedNames: string[] = [];
  for (const f of scan.findings) {
    const c = countUses(f.uses);
    library += c.library;
    if (f.targetKey == null) {
      unmatched += placesOf(c);
      unmatchedNames.push(f.name);
    } else places += placesOf(c);
  }
  for (const p of scan.primitives) {
    const c = countUses(p.uses);
    primitivePlaces += placesOf(c) + c.library;
  }
  return {
    variables: scan.findings.length,
    places,
    unmatched,
    unmatchedNames,
    library,
    primitives: scan.primitives.length,
    primitivePlaces,
    primitiveSamples: primitiveSamples(scan),
    libraryError: scan.libraryError,
    error: null,
  };
}

/** 소비 파일 점검의 보고에 「옛 브랜드 컬렉션」을 더한다 — 줄은 목록의 맨 위(경고)에. */
export function withOldBrandCollections(
  report: ConsumerAuditReport,
  scan: OldBrandScan | { error: string },
): ConsumerAuditReport {
  if (!('findings' in scan)) {
    return {
      ...report,
      oldBrandCollections: {
        variables: 0,
        places: 0,
        unmatched: 0,
        unmatchedNames: [],
        library: 0,
        primitives: 0,
        primitivePlaces: 0,
        primitiveSamples: [],
        libraryError: null,
        error: scan.error,
      },
    };
  }
  return {
    ...report,
    oldBrandCollections: oldBrandSummary(scan),
    groups: [...oldBrandGroups(scan), ...report.groups],
  };
}

// ─── Figma 에 잇기 ───────────────────────────────────────────────────────────

function messageOf(e: unknown): string {
  return e instanceof Error ? e.message : String(e);
}

/** 켜진 라이브러리 중 `Semantic/ Color · CoUI` 를 하나 찾아 그 변수 목록을 읽는다.
 *  가져오지(import) 않는다 — 점검이 문서에 쓰지 않도록. */
async function readCouiLibrary(doc: BrandsDoc = BRANDS): Promise<CouiLibrary | { error: string }> {
  try {
    const libraries = (await figma.teamLibrary.getAvailableLibraryVariableCollectionsAsync()).filter(
      (c) => withoutOrderingPrefix(c.name) === doc.library.collection,
    );
    if (libraries.length === 0) {
      return { error: `활성화된 라이브러리에서 "${doc.library.collection}" 컬렉션을 찾지 못했다 — CoUI 라이브러리를 켠다` };
    }
    if (libraries.length > 1) {
      return {
        error:
          `"${doc.library.collection}" 컬렉션이 라이브러리 ${libraries.length}곳(` +
          `${libraries.map((l) => l.libraryName).join(', ')})에 있어 어느 것으로 옮길지 고르지 않는다`,
      };
    }
    const lib = libraries[0];
    const vars = await figma.teamLibrary.getVariablesInLibraryCollectionAsync(lib.key);
    return {
      libraryName: lib.libraryName,
      variables: vars.map((v) => ({ name: v.name, key: v.key, resolvedType: v.resolvedType })),
    };
  } catch (e) {
    return { error: messageOf(e) };
  }
}

export function figmaBrandScanDeps(): BrandScanDeps {
  return { ...figmaCopyDeps(), couiLibrary: () => readCouiLibrary() };
}

/** 소비 파일 점검이 부른다. 실패해도 글자 점검은 그대로 보고되도록 오류를 돌려준다. */
export async function auditOldBrandCollections(): Promise<OldBrandScan | { error: string }> {
  try {
    return await scanOldBrandCollections(asCopyPages(await loadedPages()), figmaBrandScanDeps());
  } catch (e) {
    return { error: messageOf(e) };
  }
}

// ─── 다시 연결 — 명령 ────────────────────────────────────────────────────────

function primitiveLines(scan: OldBrandScan): string[] {
  if (scan.primitives.length === 0) return [];
  const s = oldBrandSummary(scan);
  const lines = [
    `⚠ 브랜드 원시값에 직접 묶인 곳 ${s.primitivePlaces} (변수 ${s.primitives}개) — 옮기지 않았다. ` +
      '어느 시맨틱 슬롯이어야 하는지 정해 손으로 다시 연결한다:',
  ];
  for (const sample of s.primitiveSamples) lines.push(`  ${sample}`);
  if (s.primitivePlaces > s.primitiveSamples.length) lines.push(`  … 나머지는 소비 파일 점검의 목록에 있다`);
  return lines;
}

/**
 * 「옛 브랜드 컬렉션 다시 연결」 — 파일 전체에서 옛 브랜드 컬렉션의 변수를 참조하는 이
 * 파일의 노드 · 로컬 스타일 · 로컬 별칭을 같은 이름의 `Semantic/ Color · CoUI` 변수로
 * 옮긴다. 라이브러리 컴포넌트 안에서 덮어쓰지 않은 자리, 짝이 없는 이름, 브랜드 원시값에
 * 직접 묶인 곳은 옮기지 않고 보고한다. 끝에 파일을 다시 걸어 남은 참조를 센다.
 */
export async function rebindOldBrandCollections(doc: BrandsDoc = BRANDS): Promise<string[]> {
  const pages = await loadedPages();
  const deps = figmaBrandScanDeps();
  const before = await scanOldBrandCollections(asCopyPages(pages), deps, doc);
  const log: string[] = [
    `옛 브랜드 컬렉션 다시 연결 — 파일 전체 (페이지 ${pages.length}) → ${doc.library.collection}`,
  ];
  if (before.findings.length === 0) {
    log.push('옛 브랜드 컬렉션에 묶인 곳이 없다 — 옮길 것이 없다.');
    for (const line of primitiveLines(before)) log.push(line);
    return log;
  }
  if (before.libraryError != null) {
    log.push(`⚠ ${before.libraryError} — 아무것도 옮기지 않았다.`);
    return log;
  }

  const swap = new Map<string, Variable>();
  const imported = new Map<string, Variable | string>();
  for (const f of before.findings) {
    const c = countUses(f.uses);
    const head = `  ${f.collection} / ${f.name} — ${placesText(c) || '옮길 참조 없음'}`;
    if (f.targetKey == null) {
      log.push(head);
      log.push(`  ⚠ 옮기지 않는다 — ${f.missing ?? '짝을 모른다'}`);
      continue;
    }
    let target = imported.get(f.targetKey);
    if (target == null) {
      try {
        target = await figma.variables.importVariableByKeyAsync(f.targetKey);
      } catch (e) {
        target = messageOf(e);
      }
      imported.set(f.targetKey, target);
    }
    if (typeof target === 'string') {
      log.push(head);
      log.push(`  ⚠ ${doc.library.collection} / ${f.name} 을 가져오지 못해 건너뛴다 — ${target}`);
      continue;
    }
    log.push(head);
    swap.set(f.variableId, target);
  }

  const { tally, failures, mismatched } = await applyVariableSwap(
    pages,
    before.findings.filter((f) => swap.has(f.variableId)).flatMap((f) => f.uses),
    swap,
  );
  log.push(`✓ 다시 연결 — ${tallyText(tally)}`);
  for (const line of failureLines(failures)) log.push(line);
  if (mismatched.size > 0) log.push(`  ⚠ ${mismatchedCopiesHint([...mismatched])}`);

  // 다시 읽어 센다 — 쓴 것을 셌다고 옮겨진 것은 아니다. 조회 캐시는 새로 만든다(값이 바뀌었다).
  const after = await scanOldBrandCollections(asCopyPages(await loadedPages()), figmaBrandScanDeps(), doc);
  const s = oldBrandSummary(after);
  if (s.places === 0) {
    log.push(`✓ 다시 읽어 확인 — 옛 브랜드 컬렉션을 참조하는 이 파일의 노드 · 스타일 · 별칭 중 짝이 있는 것 0`);
  } else {
    log.push(
      `⚠ 다시 읽어 보니 옛 브랜드 컬렉션을 아직 ${s.places}곳이 참조한다 — 위 실패 줄의 자리를 손으로 다시 ` +
        '연결하고 점검을 다시 돌린다.',
    );
  }
  if (s.unmatched > 0) {
    log.push(
      `⚠ 짝이 없어 옮기지 않은 곳 ${s.unmatched} — ${s.unmatchedNames.join(', ')}. ` +
        '어느 슬롯이어야 하는지 정해 손으로 다시 연결한다.',
    );
  }
  if (s.library > 0) {
    log.push(
      `⚠ 라이브러리 컴포넌트 안 ${s.library}곳은 덮어쓰지 않았다 — 덮어쓰면 그 레이어에 라이브러리 변경이 닿지 ` +
        '않는다. Assets 에서 라이브러리 업데이트를 받은 뒤 다시 점검한다.',
    );
  }
  for (const line of primitiveLines(after)) log.push(line);
  log.push(
    '파일을 닫았다가 다시 연 뒤 토큰 탭의 「이름으로 다시 맞추기」를 돌린다 — 다시 열면 이 파일이 쓰지 않는 ' +
      '라이브러리 변수의 덮어쓰기가 정리되고, 새로 묶인 변수의 브랜드 값을 다시 채운다.',
  );
  return log;
}
