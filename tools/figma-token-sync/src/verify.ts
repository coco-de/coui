/// <reference types="@figma/plugin-typings" />

// Opt-in identity self-check (#3739) — NOT part of Generate Components, NOT
// run in CI. This is exactly the "정체성 멱등" self-check the mint-by-name
// design (#3737) needs proof for, decisive rather than a whitelist: it
// re-derives what the reset step forgot from a byte-level PNG diff + a
// recursive boundVariables walk, instead of asserting a fixed field list.
//
// Two checks, deliberately separate because they exercise different code
// paths and have very different costs:
//   verifyIdentityIdempotence — cheap-ish (2 real generate runs). Confirms a
//     second run with nothing changed creates/recreates/changes id or key
//     for ZERO persistent nodes (NFR-001's redefinition:
//     "created 0 / recreated 0 / skipped N / idChanged 0 / keyChanged 0").
//   verifyResetCompleteness — expensive (2 builds + 2 PNG exports PER
//     entry). Confirms a freshly-minted node and the SAME node recycled on a
//     second call are visually and structurally identical — any mismatch
//     names exactly the property resetNode() forgot to clear.

import { REGISTRY, topoSortRegistry } from './registry';
import {
  BuildResult,
  RegistryEntry,
  VarLookup,
  clearNodeIndex,
  completePendingMounts,
  flushTintLayers,
  restoreDisassembledSets,
  setReassemblyMode,
  loadFonts,
  ICON_KEYS,
  installGlyphIndex,
  clearIconModeIndex,
  clearContentIndex,
  drainInexactIconSizes,
  installNodeIndex,
  indexDocumentComponents,
  prefersDuplicateWinner,
} from './helpers';
import {
  componentPageNameOf,
  isDemotedPageOf,
  kComponentPageNamePrefix,
  sectionHeaderPageNameOf,
  withoutPageOrderPrefix,
} from './data';
import { kPageSectionOrder, sectionOfEntry } from './generate';

export interface VerifyReport {
  log: string[];
  ok: boolean;
}

export interface NodeSnapshot {
  name: string;
  type: 'COMPONENT' | 'COMPONENT_SET';
  id: string;
  key: string;
  pageName: string;
}

/**
 * A document snapshot plus the name collisions it had to resolve.
 *
 * `byName`'s winner matches `indexDocumentComponents` (`identity.ts`) —
 * generate writes to the node that index picks, so the verifier has to
 * grade that same node. Both call the same `prefersDuplicateWinner` rather
 * than each keeping its own copy of "which duplicate wins": two independent
 * copies of that rule is how the verifier once scored a node generate never
 * touched, producing a `misplaced` red that no re-run could clear.
 */
export interface DocumentSnapshot {
  byName: Map<string, NodeSnapshot>;
  /** name → every page it was found on, in document order (winner first). */
  duplicates: Map<string, string[]>;
}

// #4026 (B4) — document-wide, not legacy-page-scoped: after the
// component-per-page migration (B2) the registry's nodes live on their own
// `❖ {Name}` pages (D-27), and an idempotence claim that only looked at
// one page would be unfalsifiable for everything that moved off it.
//
// This stays document-wide even under an entry scope. Narrowing collection
// would turn "sitting on the wrong page" into "missing", inverting the very
// check `misplaced` exists to make.
export async function snapshotDocument(): Promise<DocumentSnapshot> {
  const byName = new Map<string, NodeSnapshot>();
  const duplicates = new Map<string, string[]>();
  for (const page of figma.root.children) {
    await page.loadAsync();
    for (const node of page.children) {
      if (node.type !== 'COMPONENT' && node.type !== 'COMPONENT_SET') continue;
      const won = byName.get(node.name);
      if (won) {
        const seen = duplicates.get(node.name) ?? [won.pageName];
        seen.push(page.name);
        duplicates.set(node.name, seen);
        // Same rule `indexDocumentComponents` used to pick the node generate
        // actually wrote to — a canonical `❖ {name}` page wins regardless of
        // which was reached first.
        if (prefersDuplicateWinner(node.name, won.pageName, page.name)) {
          byName.set(node.name, {
            name: node.name,
            type: node.type,
            id: node.id,
            key: node.key,
            pageName: page.name,
          });
        }
        continue;
      }
      byName.set(node.name, {
        name: node.name,
        type: node.type,
        id: node.id,
        key: node.key,
        pageName: page.name,
      });
    }
  }
  return { byName, duplicates };
}

export interface IdentityGrade {
  created: number;
  recreated: number;
  skipped: number;
  idChanged: number;
  keyChanged: number;
  misplaced: number;
  migrated: number;
  missing: string[];
  duplicateNames: string[];
  log: string[];
  ok: boolean;
}

/**
 * Score two snapshots. Pure — touches no `figma` API, so it is the seam a
 * selftest can drive without modelling the plugin runtime.
 *
 * `scope` is the registry slice run 2 was allowed to touch. Placement is the
 * only check that needs it: a scoped generate calls `placeOnPage` for
 * in-scope entries only, so asserting the whole registry's placement would
 * indict leftovers this run never went near. The id/key checks stay
 * document-wide on purpose — out-of-scope nodes must not move either, and
 * holding them to that is a stronger claim, not a weaker one.
 */
export function gradeIdentity(
  before: ReadonlyMap<string, NodeSnapshot>,
  after: ReadonlyMap<string, NodeSnapshot>,
  scope: readonly { name: string }[],
  duplicates: ReadonlyMap<string, readonly string[]> = new Map(),
): IdentityGrade {
  const log: string[] = [];
  let created = 0;
  let idChanged = 0;
  let keyChanged = 0;
  let skipped = 0;
  const missing: string[] = [];

  for (const [name, b] of before) {
    const a = after.get(name);
    if (!a) {
      missing.push(name);
      log.push(`✗ "${name}" present after run 1 but gone after run 2`);
      continue;
    }
    const idDiff = a.id !== b.id;
    const keyDiff = a.key !== b.key;
    if (idDiff) {
      idChanged++;
      log.push(`✗ "${name}" id changed between run 1 and run 2: ${b.id} → ${a.id}`);
    }
    if (keyDiff) {
      keyChanged++;
      log.push(`✗ "${name}" key changed between run 1 and run 2: ${b.key} → ${a.key}`);
    }
    if (!idDiff && !keyDiff) skipped++;
  }
  for (const name of after.keys()) {
    if (!before.has(name)) {
      created++;
      log.push(`✗ "${name}" newly created on run 2 (should already have existed after run 1)`);
    }
  }

  // "recreated" (NFR-001's third bucket) means present in both runs with a
  // changed id/key — already counted above as idChanged/keyChanged, which is
  // the more actionable signal (which field moved). Recreated == the union.
  const recreated = new Set<string>();
  for (const [name, b] of before) {
    const a = after.get(name);
    if (a && (a.id !== b.id || a.key !== b.key)) recreated.add(name);
  }

  // #4026 (B4) — placement conformance (BDD "컴포넌트당 페이지"): every
  // registry node must sit on its derived `❖ {Name}` page after run 2
  // (`componentPageNameOf` — the same single source generate places by,
  // D-27), and must not have MOVED between the two runs (a move on run 2
  // means run 1's placement pass didn't converge — re-run ≠ recovery).
  let misplaced = 0;
  let migrated = 0;
  for (const entry of scope) {
    const a = after.get(entry.name);
    if (!a) continue; // already reported as missing above
    const expectedPage = componentPageNameOf(entry.name);
    if (a.pageName !== expectedPage) {
      misplaced++;
      log.push(`✗ "${entry.name}" on page "${a.pageName}" — expected "${expectedPage}"`);
    }
    const b = before.get(entry.name);
    if (b && b.pageName !== a.pageName) {
      migrated++;
      log.push(
        `✗ "${entry.name}" moved between run 1 and run 2 ` +
          `("${b.pageName}" → "${a.pageName}") — placement did not converge on run 1`,
      );
    }
  }

  // Reported in its own bucket, not folded into `misplaced`. A duplicate name
  // is a canvas-hygiene fault, not an idempotence fault: the run is still
  // idempotent about the node it actually writes. Folding it in produced a red
  // that no re-run could clear, which trains people to ignore the red.
  const duplicateNames = [...duplicates.keys()].sort();
  for (const name of duplicateNames) {
    const pages = duplicates.get(name) ?? [];
    log.push(
      `⚠ duplicate node name "${name}" on ${pages.length} pages ` +
        `(${pages.map((p) => `"${p}"`).join(' · ')}) — graded the first; ` +
        `rename the others (the node, not the page — the index ignores page names)`,
    );
  }

  const ok =
    created === 0 && recreated.size === 0 && missing.length === 0 && misplaced === 0 && migrated === 0;

  return {
    created,
    recreated: recreated.size,
    skipped,
    idChanged,
    keyChanged,
    misplaced,
    migrated,
    missing,
    duplicateNames,
    log,
    ok,
  };
}


// ─── Part 1b — 배치·key·판정·시간 (#4026 / B4) ──────────────────────────────
//
// `gradeIdentity` 위의 네 판정. 전부 순수 함수라 `figma` 없이 셀프테스트가
// 몰 수 있고, `verifyIdentityIdempotence` 는 이들을 호출만 한다.
//
// 왜 `gradeIdentity` 안에 넣지 않았나: 저 함수는 "run1 과 run2 가 같은가" 만
// 답한다. 아래 셋은 서로 다른 질문이다 — 페이지 목록이 규약과 맞는가(배치),
// 마이그레이션이 key 를 살렸는가(NFR-F), 2회차가 정말 안 그렸는가(NFR-A).
// 한 함수에 접으면 어느 축이 빨간지 호출부가 알 수 없다.

/** 페이지 목록 판정 결과. */
export interface PageLayoutGrade {
  /** 범위 안 엔트리인데 자기 `❖ {Name}` 페이지가 없다. 강등된 것은 뺀다. */
  missingPages: string[];
  /** `❖ {Name}` 대신 **강등 페이지**(`isDemotedPageOf`)가 있다 — 디자이너의
   *  옵트아웃. 생성기가 같은 판정으로 건너뛰므로 재실행이 만들 수 없는 페이지이고,
   *  그래서 실패가 아니다. 세어서 드러내기만 한다. */
  demotedPages: string[];
  /** 생성기가 소유하는 이름이 두 번 이상 나타난다. */
  duplicatePages: string[];
  /** 컴포넌트 페이지가 0개인 섹션인데 헤더가 있다. */
  strayHeaders: string[];
  /** 컴포넌트 페이지가 있는데 헤더가 없다. */
  missingHeaders: string[];
  /** 구 `{Section} / {Name}` 잔재 — 경고만 (비어야 지워지므로). */
  oldSchemePages: string[];
  log: string[];
  ok: boolean;
}

// 구 스킴 잔재를 찾는 패턴. `generate.ts` 의 정리 패스와 **같은 네 이름**만
// 본다 — 이 정규식은 "과거 실행이 쓸 수 있었던 페이지 이름" 을 기술하며,
// 구 스킴은 이 넷으로만 쓰였다.
const kOldSchemePageName = /^(Display|Control|Form|Layout) \/ /;

/**
 * 파일의 페이지 목록이 D-26/D-27 규약과 맞는지 판정한다. 순수.
 *
 * ⚠️ **순서는 보지 않는다.** 순서를 맞추는 것은 "페이지 순서 정리" 를 켠
 * 실행뿐이고(`pageOrderMoves` scope `all`), 검증의 두 실행은 그것을 끈 채로
 * 돈다 — 검증이 파일 배치를 바꾸면 안 되기 때문이다. 그래서 "페이지 순서 ==
 * plannedPageOrder" 는 검증 실행이 만들 수 없는 상태이고, 그걸 단언하면 재실행으로
 * 지울 수 없는 빨강이 된다 — 이 파일이 duplicate 이름을 별도 버킷에 둔 것과
 * 같은 이유다. 순서 결정 자체는 `selftest-page-order` 가 이름 목록으로 본다.
 *
 * ⚠️ **페이지 수도 보지 않는다.** BDD 가 한때 요구한 `N + 1` 은 섹션 헤더 10장
 * (D-26, 의도된 것)과 파운데이션 페이지가 생긴 뒤로 성립하지 않는다.
 *
 * 대신 재실행이 실제로 고칠 수 있고 반증 가능한 넷만 본다 — 범위 안 엔트리의
 * 페이지 존재, 생성기 소유 이름의 유일성(`pageToReuse` 버그가 만든 188→198
 * 중복이 이 축이다), 섹션 헤더의 존재/부재 대칭, 그리고 구 스킴 잔재(경고).
 */
export function gradePageLayout(
  pageNames: readonly string[],
  scope: readonly { name: string; section: string | null }[],
  allEntries: readonly { name: string; section: string | null }[],
  sectionOrder: readonly string[],
): PageLayoutGrade {
  const log: string[] = [];
  // 디자이너의 `01. ` 정렬 접두는 이름을 숨기지 못한다 — `pageToReuse` 가
  // 접두에 관대한 것과 같은 규칙으로 본다.
  const bare = pageNames.map((n) => withoutPageOrderPrefix(n));
  const bareSet = new Set(bare);

  // 강등 판정은 **원래 이름**으로 한다 — `withoutPageOrderPrefix` 가 앞 공백을
  // 지우므로 `bare` 에서는 들여쓰기가 이미 사라져 있다.
  const isDemoted = (entryName: string): boolean =>
    pageNames.some((name) => isDemotedPageOf(name, entryName));
  const missingPages: string[] = [];
  const demotedPages: string[] = [];
  for (const entry of scope) {
    const want = componentPageNameOf(entry.name);
    if (bareSet.has(want)) continue;
    if (isDemoted(entry.name)) {
      demotedPages.push(entry.name);
      continue;
    }
    missingPages.push(entry.name);
    log.push(`✗ "${entry.name}" 페이지 없음 — "${want}" 가 있어야 한다`);
  }
  if (demotedPages.length > 0) {
    log.push(
      `↷ 강등 페이지 ${demotedPages.length}건 — 디자이너 옵트아웃이라 "페이지 없음" 으로 ` +
        `세지 않는다: ${demotedPages.join(', ')}`,
    );
  }

  // 헤더 판정의 근거는 **캔버스에 실제로 있는 페이지** 이지 이번 범위가
  // 아니다. 범위로 세면 한 컴포넌트만 고른 실행이 나머지 아홉 섹션의 헤더를
  // 전부 "stray" 로 신고한다 — 그 섹션들은 범위 밖 엔트리의 페이지를 갖고
  // 있을 뿐인데. 재실행으로 지울 수 없는 빨강을 만드는 그 실수를, 이 파일은
  // duplicate 이름에서 이미 한 번 했다.
  const sectionsWithPages = new Set<string>();
  const sectionsWithDemoted = new Set<string>();
  for (const entry of allEntries) {
    if (entry.section === null) continue;
    if (bareSet.has(componentPageNameOf(entry.name))) sectionsWithPages.add(entry.section);
    else if (isDemoted(entry.name)) sectionsWithDemoted.add(entry.section);
  }

  // 생성기가 소유하는 이름만 유일성을 단언한다. 디자이너의 스크래치 페이지가
  // 같은 이름을 두 번 쓰는 것은 이 판정의 대상이 아니다.
  const headerNames = new Set(sectionOrder.map((s) => sectionHeaderPageNameOf(s)));
  const owned = (name: string): boolean =>
    name.startsWith(kComponentPageNamePrefix) || headerNames.has(name);
  const seen = new Map<string, number>();
  for (const name of bare) {
    if (!owned(name)) continue;
    seen.set(name, (seen.get(name) ?? 0) + 1);
  }
  const duplicatePages: string[] = [];
  for (const [name, count] of [...seen].sort((a, b) => (a[0] < b[0] ? -1 : 1))) {
    if (count < 2) continue;
    duplicatePages.push(name);
    log.push(`✗ 페이지 "${name}" 가 ${count}번 나타난다 — 생성기가 소유하는 이름은 하나여야 한다`);
  }

  // 헤더는 컴포넌트 페이지가 있는 섹션에만 있어야 한다. 양방향 — 없어도,
  // 남아 있어도 배치가 어긋난 것이다.
  //
  // 예외 하나: 강등 페이지만 남은 섹션. 생성기는 그 섹션에 헤더를 새로 심지도
  // (`plannedPageOrder` — 컴포넌트 페이지 0개인 섹션은 계획에 없다) 지우지도
  // 않는다. 디자이너는 강등 페이지를 헤더 아래 메모로 둔다. 그래서 그 섹션의
  // 헤더는 있든 없든 재실행이 바꾸지 못하고, 어느 쪽을 빨강으로 세도 지울 수
  // 없는 빨강이 된다.
  const strayHeaders: string[] = [];
  const missingHeaders: string[] = [];
  for (const section of sectionOrder) {
    const header = sectionHeaderPageNameOf(section);
    const present = bareSet.has(header);
    const hasPages = sectionsWithPages.has(section);
    if (hasPages && !present) {
      missingHeaders.push(section);
      log.push(`✗ 섹션 "${section}" 에 컴포넌트 페이지가 있는데 헤더 "${header}" 가 없다`);
    }
    if (!hasPages && present && !sectionsWithDemoted.has(section)) {
      strayHeaders.push(section);
      log.push(`✗ 섹션 "${section}" 헤더 "${header}" 가 있는데 그 섹션 컴포넌트 페이지가 0개다`);
    }
  }

  // 구 스킴 잔재는 경고다 — 비어야 지워지고, 비지 않은 것은 의도적으로
  // 남긴다("nothing is deleted silently").
  const oldSchemePages = bare.filter((n) => kOldSchemePageName.test(n)).sort();
  for (const name of oldSchemePages) {
    log.push(`⚠ 구 스킴 페이지 "${name}" 잔존 — 비면 다음 실행이 지운다 (비지 않았으면 내용 확인)`);
  }

  const ok =
    missingPages.length === 0 &&
    duplicatePages.length === 0 &&
    strayHeaders.length === 0 &&
    missingHeaders.length === 0;

  return {
    missingPages,
    demotedPages,
    duplicatePages,
    strayHeaders,
    missingHeaders,
    oldSchemePages,
    log,
    ok,
  };
}

/** 마이그레이션 전후 key 대조 결과. */
export interface KeyPreservationGrade {
  /** 같은 이름·같은 종류인데 key 가 바뀌었다 — NFR-F 위반. */
  keyLost: { name: string; before: string; after: string }[];
  /** COMPONENT → COMPONENT_SET 승격 — BDD 의 "신규 set 노드 제외" 대상. */
  promoted: string[];
  /** 실행 전에 있었는데 사라졌다 — 경고 (RETIRED/rename 과 구별되지 않음). */
  vanished: string[];
  log: string[];
  ok: boolean;
}

/**
 * 실행 **전** 스냅샷과 실행 후 스냅샷의 key 집합을 대조한다. 순수.
 *
 * 왜 따로 있나: `gradeIdentity` 의 key 비교는 run1↔run2 다. 그건 멱등성을
 * 말할 뿐 **마이그레이션이 key 를 살렸는가**(NFR-F)에 대해서는 아무 말도
 * 하지 않는다 — 대이동은 run1 안에서 끝나므로, run1 뒤에 뜬 스냅샷 둘을
 * 아무리 비교해도 그 축은 구조적으로 보이지 않는다.
 *
 * 제외 규칙은 BDD 의 "신규 set 노드 제외" 를 그대로 옮긴 것이다 — 실행 전에
 * 없던 이름은 새 노드라 대조할 짝이 없고, loose COMPONENT 가 COMPONENT_SET
 * 으로 입양되면 세트는 그 컴포넌트를 감싸는 **다른 노드**라 key 가 바뀌는 게
 * 정상이다. 그 둘만 빼고 나머지는 전부 key 가 보존돼야 한다.
 */
export function gradeKeyPreservation(
  pristine: ReadonlyMap<string, NodeSnapshot>,
  after: ReadonlyMap<string, NodeSnapshot>,
): KeyPreservationGrade {
  const log: string[] = [];
  const keyLost: { name: string; before: string; after: string }[] = [];
  const promoted: string[] = [];
  const vanished: string[] = [];

  for (const [name, b] of pristine) {
    const a = after.get(name);
    if (!a) {
      vanished.push(name);
      continue;
    }
    if (b.type === 'COMPONENT' && a.type === 'COMPONENT_SET') {
      promoted.push(name);
      continue;
    }
    if (a.key !== b.key) {
      keyLost.push({ name, before: b.key, after: a.key });
      log.push(`✗ "${name}" key 가 마이그레이션에서 바뀌었다: ${b.key} → ${a.key}`);
    }
  }

  promoted.sort();
  vanished.sort();
  if (promoted.length > 0) {
    log.push(
      `· 입양 승격 ${promoted.length}건 — key 대조에서 제외 (${promoted.join(', ')})`,
    );
  }
  for (const name of vanished) {
    log.push(`⚠ "${name}" 가 실행 전에는 있었고 실행 후 없다 — RETIRED/rename 인지 확인`);
  }

  const ok = keyLost.length === 0;
  return { keyLost, promoted, vanished, log, ok };
}

/** `Done.` 줄에서 읽어낸 한 실행의 결산. */
export interface RunOutcome {
  built: number;
  skipped: number;
  total: number;
}

// `generate.ts` 가 쓰는 마지막 결산 줄과 **같은 문장**을 읽는다. 형식이 갈리면
// 파서가 null 을 돌려주고 호출부가 "판정 불가" 로 보고하므로, 조용히 0 으로
// 읽혀 all-skip 을 위조하는 경로가 없다.
const kDoneLine = /^Done\. (\d+) built, (\d+) skipped \(unchanged\), (\d+) total/;

/** 실행 로그에서 결산을 읽는다. 읽지 못하면 `null` — 0 이 아니다. 순수. */
export function parseRunOutcome(log: readonly string[]): RunOutcome | null {
  for (let i = log.length - 1; i >= 0; i--) {
    const m = kDoneLine.exec(log[i]);
    if (!m) continue;
    return { built: Number(m[1]), skipped: Number(m[2]), total: Number(m[3]) };
  }
  return null;
}

/** 2회차 판정 결과 — 무엇을 그렸나(NFR-A) + 얼마나 걸렸나(P-4). */
export interface SecondRunGrade {
  /** run2 가 그린 엔트리 수. 0 이어야 한다. */
  built: number | null;
  /** 시간 축을 잴 수 있었나 — run1 이 아무것도 안 그렸으면 잴 대상이 없다. */
  timingApplicable: boolean;
  /** run2Ms / run1Ms. 잴 수 없으면 null. */
  ratio: number | null;
  log: string[];
  ok: boolean;
}

/** run2 가 10% 미만이어야 한다는 P-4 문턱. */
export const kSecondRunTimeBudget = 0.1;

/**
 * 2회차가 정말 안 그렸는지, 그리고 그만큼 빨랐는지 판정한다. 순수.
 *
 * **왜 시간까지 보나**: "skipped 로 보고됨" 만 보면 안에서 다시 그리고 버리는
 * 구현도 통과한다. 시간이 그 차이를 드러내는 유일한 신호다 — 이슈 본문의
 * "왜 시간까지 재나" 가 그 말이다.
 *
 * **왜 조건부인가**: 캔버스가 이미 수렴해 run1 까지 all-skip 이면 **잴 대상이
 * 없다**. 그때 비율을 단언하면 정상 상태를 빨강으로 만든다 — 그래서 그 경우는
 * 통과시키되 "시간 축은 재지 못했다" 고 로그에 적는다. 앞의 판정(무엇을
 * 그렸나)은 그 경우에도 그대로 유효하다.
 */
export function gradeSecondRun(
  run1: RunOutcome | null,
  run2: RunOutcome | null,
  run1Ms: number,
  run2Ms: number,
): SecondRunGrade {
  const log: string[] = [];
  if (run2 === null || run1 === null) {
    log.push(
      `✗ 실행 로그의 "Done." 결산 줄을 읽지 못했다 — 2회차 판정 불가 ` +
        `(형식이 바뀌었으면 parseRunOutcome 을 같이 고쳐야 한다)`,
    );
    return { built: null, timingApplicable: false, ratio: null, log, ok: false };
  }

  let ok = true;
  if (run2.built !== 0) {
    ok = false;
    log.push(
      `✗ 2회차가 ${run2.built}개 엔트리를 다시 그렸다 — 아무 변경 없이 실행했으므로 ` +
        `전부 skipped 여야 한다 (skipped ${run2.skipped}/${run2.total})`,
    );
  }

  const timingApplicable = run1.built > 0;
  let ratio: number | null = null;
  if (!timingApplicable) {
    log.push(
      `· 시간 축 해당 없음 — 1회차도 all-skip 이라(built 0) 잴 대상이 없다. ` +
        `무엇을 그렸나는 위에서 판정했고, 그 판정은 이 경우에도 유효하다.`,
    );
  } else if (run1Ms <= 0) {
    log.push(`· 시간 축 해당 없음 — 1회차 소요가 0 으로 측정됐다`);
  } else {
    ratio = run2Ms / run1Ms;
    const pct = (ratio * 100).toFixed(1);
    const budget = (kSecondRunTimeBudget * 100).toFixed(0);
    if (ratio < kSecondRunTimeBudget) {
      log.push(`✓ 2회차 소요가 1회차의 ${pct}% — 예산 ${budget}% 미만 (P-4)`);
    } else {
      ok = false;
      log.push(
        `✗ 2회차 소요가 1회차의 ${pct}% — 예산 ${budget}% 를 넘었다. ` +
          `all-skip 으로 보고됐는데 시간이 줄지 않으면 안에서 그리고 버리는 것이다 (P-4)`,
      );
    }
  }

  return { built: run2.built, timingApplicable, ratio, log, ok };
}

// ─── Part 2 — identity idempotence across two real runs ─────────────────────

/**
 * `entryNames` narrows what run 1 and run 2 build. Without it this is the
 * whole registry twice, which on a grown canvas is hours — one component
 * (Button, 972 variants) measured 549s on its own, so the unscoped form is
 * not a thing anyone can actually run (#4026).
 */
export async function verifyIdentityIdempotence(
  generateComponents: () => Promise<string[]>,
  entryNames?: readonly string[],
): Promise<VerifyReport> {
  const wanted = entryNames && entryNames.length > 0 ? new Set(entryNames) : null;
  const scope = wanted ? REGISTRY.filter((e) => wanted.has(e.name)) : REGISTRY;

  // 실행 **전** 스냅샷. 대이동은 run1 안에서 끝나므로, run1 뒤에 뜬 스냅샷
  // 둘로는 "마이그레이션이 key 를 살렸는가"(NFR-F)가 구조적으로 보이지 않는다
  // — 그래서 이 한 장이 그 축의 유일한 근거다. 비용은 loadAsync 한 바퀴
  // (198 페이지에서 ~29s 실측)이고, 그 대가로 P-4 의 key 축이 한 세션에서
  // 답해진다.
  const pristine = await snapshotDocument();

  const run1Start = Date.now();
  const run1Log = await generateComponents(); // run 1 — may legitimately create/rebuild/migrate
  const run1Ms = Date.now() - run1Start;
  const before = await snapshotDocument();
  const run2Start = Date.now();
  const run2Log = await generateComponents(); // run 2 — nothing changed since run 1; this is what's under test
  const run2Ms = Date.now() - run2Start;
  const after = await snapshotDocument();

  const graded = gradeIdentity(before.byName, after.byName, scope, after.duplicates);
  const keys = gradeKeyPreservation(pristine.byName, after.byName);
  const secondRun = gradeSecondRun(
    parseRunOutcome(run1Log),
    parseRunOutcome(run2Log),
    run1Ms,
    run2Ms,
  );
  const layout = gradePageLayout(
    figma.root.children.map((p) => p.name),
    scope.map((e) => ({ name: e.name, section: sectionOfEntry(e) })),
    REGISTRY.map((e) => ({ name: e.name, section: sectionOfEntry(e) })),
    kPageSectionOrder,
  );
  const log = [...graded.log, ...keys.log, ...layout.log, ...secondRun.log];

  // 한 줄에 P-4 의 네 축을 전부 싣는다 — 실측하는 사람이 캡처하는 것이 이
  // 줄이고, 축 하나가 빠지면 그 축은 그 세션에서 답해지지 않는다.
  const timing =
    secondRun.ratio === null
      ? '해당없음'
      : `${(secondRun.ratio * 100).toFixed(1)}% (예산 ${(kSecondRunTimeBudget * 100).toFixed(0)}%)`;
  log.unshift(
    `created ${graded.created} / recreated ${graded.recreated} / skipped ${graded.skipped} / ` +
      `idChanged ${graded.idChanged} / keyChanged ${graded.keyChanged} / misplaced ${graded.misplaced} / ` +
      `movedOnRun2 ${graded.migrated} · keyLost ${keys.keyLost.length} (승격 ${keys.promoted.length} 제외) · ` +
      `페이지 missing ${layout.missingPages.length}/강등 ${layout.demotedPages.length}/` +
      `dup ${layout.duplicatePages.length}/` +
      `헤더 ${layout.missingHeaders.length}+${layout.strayHeaders.length} · ` +
      `run2 built ${secondRun.built ?? '판정불가'} · ` +
      `run1 ${(run1Ms / 1000).toFixed(1)}s → run2 ${(run2Ms / 1000).toFixed(1)}s = ${timing}`,
  );
  // Above the numbers, because the numbers mean different things depending on
  // it: a scoped run's timing says nothing about the whole-registry budget.
  log.unshift(
    wanted
      ? `범위: ${scope.length}/${REGISTRY.length} 엔트리 — 부분 검증 (${scope
          .map((e) => e.name)
          .join(', ')}). id/key 는 문서 전체를 봤고, 배치는 이 범위만 단언한다. ` +
          `시간은 이 범위의 것이라 전 범위 예산(P-4)에 대해서는 아무 말도 하지 않는다.`
      : `범위: 전 ${REGISTRY.length} 엔트리`,
  );
  // 축마다 한 줄. 하나로 접으면 어느 축이 빨간지 호출부가 알 수 없다.
  log.push(graded.ok ? '✓ identity idempotent' : '✗ identity NOT idempotent — 위 ✗ 참조');
  log.push(
    keys.ok
      ? `✓ key 보존 — 마이그레이션 전후 대조 (승격 ${keys.promoted.length}건 제외)`
      : `✗ key 보존 실패 ${keys.keyLost.length}건 — NFR-F 위반, 위 ✗ 참조`,
  );
  log.push(layout.ok ? '✓ 페이지 배치 규약 일치' : '✗ 페이지 배치 어긋남 — 위 ✗ 참조');
  log.push(secondRun.ok ? '✓ 2회차 all-skip (판정 + 시간)' : '✗ 2회차 판정 실패 — 위 ✗ 참조');

  const ok = graded.ok && keys.ok && layout.ok && secondRun.ok;
  return { log, ok };
}

// ─── Part 1 — reset completeness (fresh vs recycled) ─────────────────────────

function collectBoundVariableReport(root: SceneNode): string[] {
  const out: string[] = [];
  const walk = (node: SceneNode, path: string): void => {
    const withBound = node as unknown as { boundVariables?: Record<string, unknown> };
    const bound = withBound.boundVariables;
    if (bound) {
      for (const key of Object.keys(bound).sort()) {
        out.push(`${path}#${key}=${JSON.stringify((bound as Record<string, unknown>)[key])}`);
      }
    }
    const withChildren = node as unknown as { children?: readonly SceneNode[] };
    if (withChildren.children) {
      withChildren.children.forEach((child, i) => walk(child, `${path}>${i}:${child.type}:${child.name}`));
    }
  };
  walk(root, `${root.type}:${root.name}`);
  return out.sort();
}

function diffReports(before: string[], after: string[]): string[] {
  const afterSet = new Set(after);
  const beforeSet = new Set(before);
  const removed = before.filter((x) => !afterSet.has(x)).map((x) => `-${x}`);
  const added = after.filter((x) => !beforeSet.has(x)).map((x) => `+${x}`);
  return [...removed, ...added];
}

function bytesEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}

// What a reset sweep will build, and in which order.
//
// Pure and exported so the ordering itself is drivable outside Figma — the
// mistake this replaces (driving REGISTRY declaration order) was invisible to
// every other signal, because the throws it caused were reported as if they
// were the reset failures this check exists to find.
export interface ResetVerificationPlan {
  /** Entries whose fresh-vs-recycled result is actually compared. */
  targets: RegistryEntry[];
  /**
   * Entries built once, first, purely so `targets` have the children they
   * compose. Never compared. Empty for a full sweep, where every prerequisite
   * is already a target ahead of its dependents.
   */
  prerequisites: RegistryEntry[];
}

// The transitive `needs` closure of `target`, in build order.
function prerequisitesOf(
  target: RegistryEntry,
  order: readonly RegistryEntry[],
): RegistryEntry[] {
  const byName = new Map<string, RegistryEntry>();
  for (const e of order) byName.set(e.name, e);
  const needed = new Set<string>();
  const visit = (name: string): void => {
    const entry = byName.get(name);
    if (!entry) {
      // Unreachable while `topoSortRegistry` runs first — it already rejects a
      // `needs` name that is not a REGISTRY name. Restated as a throw so a
      // refactor that drops that check surfaces here instead of quietly
      // prebuilding nothing and blaming the target for the missing child.
      throw new Error(`verify: "${name}" is not a REGISTRY name.`);
    }
    for (const need of entry.needs ?? []) {
      if (needed.has(need)) continue;
      needed.add(need);
      visit(need);
    }
  };
  visit(target.name);
  // `order` is already topological, so filtering it keeps every prerequisite
  // ahead of its own dependents and dedupes a name reached by two paths.
  return order.filter((e) => needed.has(e.name));
}

export function planResetVerification(entryName?: string): ResetVerificationPlan {
  // Build order, not declaration order.
  //
  // A builder that composes a child calls `instanceOf`/`makeIcon`, and both
  // resolve the child by name on the page and throw when it is not there yet.
  // `Icon` is registered LAST on purpose (src/registry.ts), so declaration
  // order builds 32 consumers before it exists: measured over the real
  // builders, 78 of 143 entries throw — `Button` on `makeIcon('check')`,
  // `TextField` on `instanceOf('FormLabel')` — and each was logged as the
  // reset mismatch it is not. generate.ts builds `topoSortRegistry(REGISTRY)`;
  // so does this, or the check grades its own ordering instead of resetNode().
  const order = topoSortRegistry(REGISTRY);
  if (!entryName) return { targets: order, prerequisites: [] };
  const target = order.find((e) => e.name === entryName);
  if (!target) return { targets: [], prerequisites: [] };
  return { targets: [target], prerequisites: prerequisitesOf(target, order) };
}

// ⚠️ Slow — a full sweep is 143 entries × 2 builds × 2 PNG exports. Pass
// `entryName` to spot-check one entry quickly during development.
export async function verifyResetCompleteness(entryName?: string): Promise<VerifyReport> {
  const log: string[] = [];
  const { targets, prerequisites } = planResetVerification(entryName);
  if (targets.length === 0) {
    return { log: [`No registry entry named "${entryName}".`], ok: false };
  }

  // The spot-check runs the same deferred reassembly a generate does, whatever
  // an earlier run in this session fell back to.
  setReassemblyMode('deferred');
  const scratch = figma.createPage();
  scratch.name = '🧪 CoUI Verify Scratch (safe to delete)';
  await figma.setCurrentPageAsync(scratch);
  // `.children` on a PageNode needs an explicit load under manifest
  // documentAccess: "dynamic-page", and `mint`/`mountSet`/`instanceOf` all
  // read it. (`makeIcon` resolves `Icon` through `figma.currentPage` — which
  // now reaches the designer's set through the scoped index installed below,
  // not through this page.)
  await scratch.loadAsync();

  // This command builds onto an EMPTY page and its whole claim rests on that: the
  // prerequisites minted just below are what the target's children must resolve to.
  //
  // A document index left installed by an earlier command in the same session
  // breaks that. `findComponentByName` prefers the index, so a child would resolve
  // to whatever node the document already has — the target would compose something
  // this page never built, and both the identity comparison and the PNG diff would
  // be measuring a tree the reset sweep does not produce. Clearing is what puts the
  // lookups back on the page-local path this function assumes.
  clearNodeIndex();

  // …with exactly one exception, and it is not a hole in that premise.
  //
  // `Icon` is designer-owned: it lives on `❖ Icon`, its registry entry validates
  // rather than builds, and no run mints it. So "the prerequisites minted below
  // are what the children resolve to" cannot be true for it — there is nothing to
  // mint. Resolving it from the document is the accurate model, not a leak, and
  // without it every icon-bearing entry fails here on a component the sweep was
  // never supposed to produce.
  //
  // Scoped to that one name so nothing else regains a document-wide lookup.
  const documentIndex = await indexDocumentComponents();
  const iconOnly = new Map<string, SceneNode>();
  const designerIcon = documentIndex.get('Icon');
  if (designerIcon) iconOnly.set('Icon', designerIcon);
  installNodeIndex(iconOnly);

  // The glyphs the swap property points at live in a separate library file, so
  // they arrive by async import — the same prelude `generateComponents` runs,
  // for the same reason: the builders below are synchronous.
  const glyphIndex = new Map<string, ComponentNode>();
  for (const name of Object.keys(ICON_KEYS)) {
    try {
      glyphIndex.set(name, await figma.importComponentByKeyAsync(ICON_KEYS[name]));
    } catch {
      // Reported by the entry that draws it, naming the glyph — same as the
      // main run. Failing the whole command over one key would say less.
    }
  }
  installGlyphIndex(glyphIndex);
  // This command does not resolve the `Icon` collection (that is `generate.ts`'s
  // prelude), so a slot icon here is fitted the way a run with no collection
  // fits it. The run-end clear is on `generate.ts`'s success path only, so a
  // collection an earlier Generate that threw left installed would be written
  // into these builds as a stale object.
  clearIconModeIndex();
  // The content collections likewise: with no index a glyph is painted directly,
  // as it was before the slot carried its colour, and nothing is left to flush.
  clearContentIndex();
  // Same reason as the prelude in `generate.ts`: the accumulator is
  // module-level and shared across commands, so a leftover from an earlier one
  // would be reported against this command's first target.
  drainInexactIconSizes();

  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const collById = new Map<string, string>();
  for (const c of collections) collById.set(c.id, c.name);
  const vars = await figma.variables.getLocalVariablesAsync();
  const lk = new VarLookup(vars, collById);
  await loadFonts(lk);

  // A single-entry spot-check builds its target onto an EMPTY page, so every
  // child that target composes has to be minted first. Without this, 104 of
  // the 143 entries throw `not on the page yet` and only the 39 that declare
  // no `needs` were ever checkable — the failing set was exactly the set of
  // entries that declare a dependency.
  for (const dep of prerequisites) {
    try {
      await dep.build(scratch, lk);
      // Every driver of a builder owes this: a tint layer is queued during the
      // build and only gets its host's settled size here. Leaving the queue full
      // is worse than drawing one tint wrong — this page is removed below, and the
      // next `generateComponents` in the same session drains handles into it,
      // throwing inside the per-entry try and blaming an innocent entry.
      flushTintLayers();
      // Same debt for the set: its members are withheld until a driver says
      // the entry is done (`identity.ts`, deferred reassembly).
      completePendingMounts();
    } catch (err) {
      // A set the failed build left pending must not outlive the page it is
      // on — completed later over dead nodes it would fail some other entry.
      restoreDisassembledSets();
      scratch.remove();
      return {
        log: [
          `✗ ${targets[0].name}: prerequisite "${dep.name}" failed to build: ${String(err)} — ` +
            'the spot-check cannot run until its children do.',
        ],
        ok: false,
      };
    }
  }

  let failed = 0;
  for (const e of targets) {
    let fresh: BuildResult;
    let recycled: BuildResult;
    try {
      fresh = await e.build(scratch, lk);
      flushTintLayers();
      completePendingMounts();
    } catch (err) {
      restoreDisassembledSets();
      failed++;
      log.push(`✗ ${e.name}: fresh build threw: ${String(err)}`);
      continue;
    }
    const freshPng = await fresh.exportAsync({ format: 'PNG' });
    const freshVars = collectBoundVariableReport(fresh);
    const freshId = fresh.id;

    try {
      recycled = await e.build(scratch, lk); // same scratch page, same name → mint()/mountSet() recycles `fresh`
      flushTintLayers();
      completePendingMounts();
    } catch (err) {
      restoreDisassembledSets();
      failed++;
      log.push(`✗ ${e.name}: recycled build threw: ${String(err)} (fresh node from the first build is left as-is)`);
      continue;
    }

    if (recycled.id !== freshId) {
      failed++;
      log.push(`✗ ${e.name}: recycling created a NEW node (id ${freshId} → ${recycled.id}) — mint()/mountSet() lookup did not find the entry it just made`);
      continue;
    }
    // Both comparisons run and both are reported — they name different
    // forgotten properties. `failed` counts ENTRIES, though: an entry that
    // fails both used to subtract 2 from a total of 143, so the summary ratio
    // was not a count of entries and could read below the real pass count.
    let entryFailed = false;
    const recycledPng = await recycled.exportAsync({ format: 'PNG' });
    if (!bytesEqual(freshPng, recycledPng)) {
      entryFailed = true;
      log.push(`✗ ${e.name}: PNG differs between fresh and recycled — a visual property was not reset`);
    }
    const recycledVars = collectBoundVariableReport(recycled);
    const varDiff = diffReports(freshVars, recycledVars);
    if (varDiff.length > 0) {
      entryFailed = true;
      log.push(`✗ ${e.name}: boundVariables differ after recycle (missing from resetNode()): ${varDiff.join(', ')}`);
    }
    if (entryFailed) failed++;
  }
  scratch.remove();

  const ok = failed === 0;
  if (prerequisites.length > 0) {
    log.unshift(
      `prebuilt ${prerequisites.length} prerequisite(s) so "${targets[0].name}" could compose: ` +
        prerequisites.map((p) => p.name).join(', '),
    );
  }
  log.unshift(`${targets.length - failed}/${targets.length} entries: fresh === recycled`);
  log.push(ok ? '✓ reset completeness holds' : '✗ reset completeness FAILED — see ✗ lines above');
  return { log, ok };
}
