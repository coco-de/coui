/// <reference types="@figma/plugin-typings" />

// 낡은 세트 보기 — Generate 없이, 어느 세트가 현재 코드보다 뒤졌는지 읽기
// 전용으로 센다.
//
// ## 왜 있는가
//
// 머지·빌드가 끝나도 캔버스는 그 세트를 다시 그리기 전까지 옛 코드다. 세트는
// 자기가 어느 코드로 그려졌는지를 `coui-content-hash` 로 들고 있고, 현재 코드는
// `entryContentHashOf` 가 말한다 — 둘이 다르면 그 세트는 낡은 것이다. 지금까지
// 그 사실을 알 수 있는 유일한 길은 Generate 를 돌려 `⏭ skipped` 와 `✓ built`
// 를 세는 것이었는데, 그것은 답을 얻으려고 그리는 일이다. 실제로 한 컴포넌트의
// 결정 세 건이 main 에 머지된 채 캔버스에는 없었고, 아무것도 그렇다고 말하지
// 않았다.
//
// ## 무엇을 재사용하고 무엇을 재사용하지 않는가
//
// "이 세트가 현재 코드와 같은가" 의 정의는 `content-hash.ts` 의 레시피 하나다
// (같은 키 `kHashDataKey` 를 읽고 같은 함수 `entryContentHashOf` 로 기대값을
// 만든다) — `generate.ts` 가 스탬프를 찍을 때 쓰는 것과 여기가 가져다 쓰는 것이
// 같은 모듈의 같은 함수다. 여기서 레시피를 다시 적으면 두 레시피가 되고, 어느
// 한쪽이 편집되는 순간 이 목록은 다음 Generate 가 다시 그릴 세트를 "현재" 라고
// 답한다(또는 그 반대). `content-hash.ts` 를 별도 모듈로 둔 이유도 이것이다 —
// 예전에는 `generate.ts` 가 레시피를 소유하고 여기가 그걸 다시 import 하는
// 순환이었고, 그 역방향 간선 때문에 두 파일 중 어느 쪽을 번들러가 먼저 평가하는
// 지에 결과가 갈렸다. `selftest-stale-sets` 가 그 동일성을 함수 정체성으로
// 단언한다.
//
// 캔버스 인덱스도 Generate 와 같은 `indexDocumentComponents` 다 — 읽기 전용
// 명령이 자기 순회를 따로 가지면 두 순회가 갈린다(designer-parity 가 그렇게
// 갈렸던 자리).

import { REGISTRY } from './registry';
import type { RegistryEntry } from './helpers';
import { indexDocumentComponents } from './identity';
import { entryContentHashOf, kHashDataKey } from './content-hash';
import { kSharedSourceHash } from './build-hash';
import { truncatedNames } from './summary-format';
import {
  describeBuild,
  kGenerationStampKey,
  parseGenerationStamp,
  StaleReason,
  staleReasonOf,
} from './generation-stamp';

export type StaleStatus = 'current' | 'stale' | 'absent';

export interface StaleSetRow {
  name: string;
  status: StaleStatus;
  /** Why, for a `stale` row — see `StaleReason` (#4832). */
  reason?: StaleReason;
  /** For `other-build`: which build drew it, `describeBuild` phrasing. */
  build?: string;
}

export interface StaleSetsReport {
  rows: StaleSetRow[];
  /** REGISTRY entries whose canvas set carries the current hash. */
  current: string[];
  /** On the canvas, but stamped with a different (or no) hash — the next
   *  Generate redraws these. An EMPTY stamp counts here, not as absent: the
   *  node exists, and generate clears the stamp on purpose when a docs
   *  frame failed so the entry is rebuilt (see generate.ts). */
  stale: string[];
  /** No COMPONENT / COMPONENT_SET of that name anywhere in the document —
   *  never built, retired by hand, or on a demoted page (those hold zero
   *  components). */
  absent: string[];
  /** The stale names split by reason (#4832). Absent on reports assembled
   *  by hand without reasons — `formatStaleSets` then prints the counts only. */
  reasons?: Record<StaleReason, string[]>;
  /** Distinct `describeBuild` phrases behind the `other-build` rows. */
  otherBuilds?: string[];
}

/**
 * The expected hash for one entry — exactly `content-hash.ts`'s recipe, the
 * same one `generate.ts`'s build loop stamps with. Re-exported under the name
 * the listing uses so a reader of this file sees where the definition lives,
 * and so the selftest can assert `expectedHashOf === entryContentHashOf`
 * (identity, not equal output on a sample — equal output on a sample is what
 * a drifted copy also passes until the day it does not).
 */
export const expectedHashOf: (e: RegistryEntry) => string = entryContentHashOf;

/** Pure: one node's stored stamp against the expected hash. `undefined`
 *  node → absent. Empty / different stamp → stale. */
export function classifyStamp(
  stored: string | null | undefined,
  expected: string,
  present: boolean,
): StaleStatus {
  if (!present) return 'absent';
  if (!stored) return 'stale';
  return stored === expected ? 'current' : 'stale';
}

/**
 * Pure over an injected lookup, so both callers share it: the UI button (a
 * fresh document index) and the end of Generate (the loop's LIVE index, which
 * already holds every set the run just stamped). `hashOf` is a parameter for
 * the selftest only — production callers pass nothing and get
 * `expectedHashOf`.
 */
export function classifyRegistry(
  nodeOf: (name: string) => SceneNode | undefined,
  entries: readonly RegistryEntry[] = REGISTRY,
  hashOf: (e: RegistryEntry) => string = expectedHashOf,
  myBuildHash: string = kSharedSourceHash,
): StaleSetsReport {
  const rows: StaleSetRow[] = [];
  const reasons: Record<StaleReason, string[]> = { recipe: [], 'other-build': [], unstamped: [] };
  const otherBuilds = new Set<string>();
  for (const e of entries) {
    const node = nodeOf(e.name);
    const present =
      node !== undefined && (node.type === 'COMPONENT' || node.type === 'COMPONENT_SET');
    const stored = present ? node.getPluginData(kHashDataKey) : undefined;
    const status = classifyStamp(stored, hashOf(e), present);
    const row: StaleSetRow = { name: e.name, status };
    if (status === 'stale' && present) {
      // Why it is stale decides the fix (#4832): a moved recipe is redrawn by
      // the next run; another build's stamp means two builds are alternating
      // on one file and no run will make the listing quiet until they agree.
      const stamp = parseGenerationStamp(node.getPluginData(kGenerationStampKey));
      row.reason = staleReasonOf(stored, stamp, myBuildHash);
      if (row.reason === 'other-build' && stamp !== null) {
        row.build = describeBuild(stamp);
        otherBuilds.add(row.build);
      }
      reasons[row.reason].push(e.name);
    }
    rows.push(row);
  }
  return {
    rows,
    current: rows.filter((r) => r.status === 'current').map((r) => r.name),
    stale: rows.filter((r) => r.status === 'stale').map((r) => r.name),
    absent: rows.filter((r) => r.status === 'absent').map((r) => r.name),
    reasons,
    otherBuilds: [...otherBuilds],
  };
}

/** Reads the canvas. Nothing is written — no stamp, no node, no page. */
export async function listStaleSets(): Promise<StaleSetsReport> {
  const index = await indexDocumentComponents();
  return classifyRegistry((name) => index.get(name));
}

/**
 * The log lines. Pure so the wording is testable and the UI button and the
 * Generate tail print the same sentence for the same state — two phrasings of
 * "how far behind is the canvas" would be read as two different facts.
 *
 *   낡은 세트 K / 전체 N — Select, Chip, Foo, Bar, Baz, … (+K-5)
 *   없음 M — Ghost, … (+M-5)
 * or, when nothing is stale:
 *   캔버스 = 현재 코드 ✅ (전체 N)
 *
 * The name list is capped at `kMaxNamesInSummary` — K and N themselves are
 * always the true counts over the WHOLE registry, only the spelled-out names
 * are truncated.
 */
export function formatStaleSets(report: StaleSetsReport): string[] {
  const total = report.rows.length;
  const lines: string[] = [];
  if (report.stale.length === 0) {
    lines.push(`캔버스 = 현재 코드 ✅ (전체 ${total})`);
  } else {
    lines.push(
      `낡은 세트 ${report.stale.length} / 전체 ${total} — ${truncatedNames(report.stale)}`,
    );
    // The reason line (#4832), only when the report carries reasons and there
    // is something to split. `other-build` names the builds — that is the one
    // count a redraw does not fix.
    if (report.reasons) {
      const parts: string[] = [];
      const r = report.reasons;
      if (r.recipe.length > 0) parts.push(`레시피 변경 ${r.recipe.length}`);
      if (r['other-build'].length > 0) {
        const who = report.otherBuilds && report.otherBuilds.length > 0 ? ` (${truncatedNames(report.otherBuilds)})` : '';
        parts.push(`다른 빌드 ${r['other-build'].length}${who}`);
      }
      if (r.unstamped.length > 0) parts.push(`스탬프 없음 ${r.unstamped.length}`);
      if (parts.length > 0) lines.push(`  사유 — ${parts.join(' · ')}`);
    }
  }
  if (report.absent.length > 0) {
    lines.push(`없음 ${report.absent.length} — ${truncatedNames(report.absent)}`);
  }
  return lines;
}
