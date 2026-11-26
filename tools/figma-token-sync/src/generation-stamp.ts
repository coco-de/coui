// Generation stamp (#4832) — which build, which session, drew this set last.
//
// A set carried two marks before this: the recipe hash (`coui-content-hash`)
// that decides skip-vs-rebuild, and the canvas fingerprint
// (`coui-canvas-fingerprint`) that decides "did a hand touch this since".
// Neither says WHO drew it or with WHICH build, and on 2026-09-12 that cost
// three misreadings in one run: sets another build had just redrawn read as
// "hand-edited" (37 redesign snapshots for nobody's edits), sets that build had
// stamped read as "stale" the moment this build finished (88 of 153, including
// ones this run had drawn minutes earlier), and no line of either log said
// which build the other side was running.
//
// The stamp is written next to the hash, after every successful build, and is
// read in two places: the hand-edit judgement before an overwrite and the
// stale-set listing. Pure — no `figma` — so both readers and the harness share
// one definition of what the stamp means.
//
// What it cannot do, stated: it says who drew LAST. A designer's edit made
// after another build's generation is indistinguishable from that generation
// here; #4831's run lock keeps that window as short as one run.

export const kGenerationStampKey = 'coui-generation';

export interface GenerationStamp {
  /** The run's session id — same shape as the run lock's. */
  readonly sessionId: string;
  readonly user: string;
  /** `kSharedSourceHash` of the build that drew the set. */
  readonly buildHash: string;
  /** `kBuildRef` — branch@commit, for a human reading the log. */
  readonly buildRef: string;
  readonly at: string;
}

export interface GenerationSession {
  readonly sessionId: string;
  readonly user: string;
}

const kStampFields: readonly (keyof GenerationStamp)[] = ['sessionId', 'user', 'buildHash', 'buildRef', 'at'];

export function makeGenerationStamp(
  me: GenerationSession,
  buildHash: string,
  buildRef: string,
  nowMs: number,
): GenerationStamp {
  return { sessionId: me.sessionId, user: me.user, buildHash, buildRef, at: new Date(nowMs).toISOString() };
}

/** The stamp in `raw`, or null when there is none or it does not parse. A set
 *  drawn before this stamp existed has none — that is the common case for a
 *  while, and every reader treats it as "unknown build", never as an error. */
export function parseGenerationStamp(raw: string): GenerationStamp | null {
  if (typeof raw !== 'string' || raw.trim() === '') return null;
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return null;
  }
  if (parsed === null || typeof parsed !== 'object') return null;
  const obj = parsed as Record<string, unknown>;
  for (const field of kStampFields) {
    if (typeof obj[field] !== 'string') return null;
  }
  return {
    sessionId: obj.sessionId as string,
    user: obj.user as string,
    buildHash: obj.buildHash as string,
    buildRef: obj.buildRef as string,
    at: obj.at as string,
  };
}

/** `abc123 (main@2f94b8c) by Design` — one phrase for a build, the same in
 *  every log line that names one. */
export function describeBuild(stamp: GenerationStamp): string {
  const ref = stamp.buildRef !== '' && stamp.buildRef !== 'dev' ? ` (${stamp.buildRef})` : '';
  return `${stamp.buildHash}${ref} by ${stamp.user}`;
}

/** What an overwrite is about to replace.
 *
 *  - `unfingerprinted` — no fingerprint on the set; the caller's option decides.
 *  - `unchanged` — the canvas is what the last generation left.
 *  - `hand-edit` — the canvas moved and the last generation was THIS build (or
 *    predates stamps): only a hand explains the difference. Snapshot it.
 *  - `other-build` — the canvas moved and the last generation was another
 *    build. Two builds serialise the same canvas differently (the fingerprint's
 *    fields have moved several times), and they may draw differently too, so
 *    the difference proves nothing about a hand. Not a snapshot — a line. */
export type OverwriteVerdict = 'unfingerprinted' | 'unchanged' | 'hand-edit' | 'other-build';

export function judgeOverwrite(
  storedFingerprint: string,
  currentFingerprint: string,
  stamp: GenerationStamp | null,
  myBuildHash: string,
): OverwriteVerdict {
  if (storedFingerprint === '') return 'unfingerprinted';
  if (currentFingerprint === storedFingerprint) return 'unchanged';
  if (stamp !== null && stamp.buildHash !== myBuildHash) return 'other-build';
  return 'hand-edit';
}

export function formatOtherBuildLine(pageName: string, stamp: GenerationStamp, myBuildHash: string): string {
  return (
    `↔ ${pageName}: 다른 빌드가 다시 그림 — ${describeBuild(stamp)} 가 마지막으로 그렸고 이 빌드는 ${myBuildHash} 다. ` +
    `지문은 다르지만 손 편집으로 읽지 않는다(빌드가 다르면 같은 캔버스도 다르게 서술한다). 스냅샷 없이 다시 그린다 — ` +
    `그 생성 뒤의 손 편집이 있었다면 구분하지 못한다.`
  );
}

/** Why a set is stale — the three have different fixes. `recipe`: the code
 *  moved, redraw. `other-build`: another build drew it, agree on one build.
 *  `unstamped`: never stamped or a docs frame failed, redraw. */
export type StaleReason = 'recipe' | 'other-build' | 'unstamped';

export function staleReasonOf(
  storedHash: string | null | undefined,
  stamp: GenerationStamp | null,
  myBuildHash: string,
): StaleReason {
  if (!storedHash) return 'unstamped';
  if (stamp !== null && stamp.buildHash !== myBuildHash) return 'other-build';
  return 'recipe';
}
