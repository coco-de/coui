// Run lock (#4831) — one Generate per file at a time.
//
// Two sessions running Generate in the same Figma file see each other's
// half-way state through multiplayer. `mountSet` empties a large set down to
// its anchor for the whole build loop, so while one session rebuilds Button
// the other session's composers find a set with ONE member: everything that
// asked `restingVariantName` failed on `Variants present: <one name>`, and
// everything that asked `bestVariantName` silently took that anchor —
// primary/xs buttons on Alert · Banner · Toast · Drawer · Fab and six more
// (2026-09-12, two accounts, one file). Nothing in the file said a run was in
// progress. This record does.
//
// The record lives in `figma.root`'s plugin data, which syncs like any node
// data. This module is pure — no `figma`, no clock of its own — so the
// decision can be exercised by the harness; `generate.ts` owns the reads and
// writes.
//
// Liveness has two signals, and the lock is quiet only when BOTH are: the
// record's own `heartbeatAt` (rewritten when an entry starts and on the
// sub-progress ticks inside one, throttled) and the per-combo step mark
// `last-step.ts` already writes for every run. The mark is
// file-global rather than per-session, and that is fine here — a fresh mark
// under a foreign lock means a run is alive, and the only run that should be
// alive is the lock's holder.

export const kRunLockDataKey = 'coui-run-lock';

/** How long a held lock may show no sign of life before another session may
 *  take it over. The longest measured quiet stretch inside a run is a
 *  972-member hand-edit snapshot at about five minutes; this leaves a 2×
 *  margin. A dead session therefore blocks the file for at most this long. */
export const kRunLockTtlMs = 10 * 60_000;

export interface RunLockRecord {
  /** Distinct per session, stable across one session's runs. */
  readonly sessionId: string;
  readonly user: string;
  readonly startedAt: string;
  readonly heartbeatAt: string;
  /** `kSharedSourceHash` of the build that holds the lock — the other half
   *  of #4832's question ("which build drew this?"), answered for the run. */
  readonly buildHash: string;
  /** What the run was asked to draw — `all`, a section list, or names. */
  readonly scope: string;
}

export interface RunLockSession {
  readonly sessionId: string;
  readonly user: string;
}

export type RunLockDecision =
  | { readonly action: 'acquire' }
  | { readonly action: 'resume'; readonly held: RunLockRecord }
  | { readonly action: 'refuse'; readonly held: RunLockRecord; readonly quietMs: number }
  | { readonly action: 'takeover'; readonly stale: RunLockRecord; readonly quietMs: number };

const kRecordFields: readonly (keyof RunLockRecord)[] = [
  'sessionId',
  'user',
  'startedAt',
  'heartbeatAt',
  'buildHash',
  'scope',
];

/** The record in `raw`, or null when there is none or it does not parse as
 *  one. A malformed record is treated as absent on purpose — the alternative
 *  is a file nobody can generate into until someone clears plugin data by
 *  hand. */
export function parseRunLock(raw: string): RunLockRecord | null {
  if (typeof raw !== 'string' || raw.trim() === '') return null;
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return null;
  }
  if (parsed === null || typeof parsed !== 'object') return null;
  const obj = parsed as Record<string, unknown>;
  for (const field of kRecordFields) {
    if (typeof obj[field] !== 'string') return null;
  }
  return {
    sessionId: obj.sessionId as string,
    user: obj.user as string,
    startedAt: obj.startedAt as string,
    heartbeatAt: obj.heartbeatAt as string,
    buildHash: obj.buildHash as string,
    scope: obj.scope as string,
  };
}

function epochOf(iso: string): number | null {
  const ms = Date.parse(iso);
  return Number.isFinite(ms) ? ms : null;
}

/** How long the held lock has shown no sign of life, from its own heartbeat
 *  and the file's last step mark — whichever is later. `Infinity` when neither
 *  parses: a record that cannot prove it is alive is not alive. */
export function runLockQuietMs(held: RunLockRecord, nowMs: number, lastMarkMs: number | null): number {
  const candidates = [epochOf(held.heartbeatAt), epochOf(held.startedAt), lastMarkMs].filter(
    (v): v is number => typeof v === 'number' && Number.isFinite(v),
  );
  if (candidates.length === 0) return Infinity;
  return nowMs - Math.max(...candidates);
}

export function decideRunLock(
  raw: string,
  me: RunLockSession,
  nowMs: number,
  lastMarkMs: number | null,
  ttlMs: number = kRunLockTtlMs,
): RunLockDecision {
  const held = parseRunLock(raw);
  if (held === null) return { action: 'acquire' };
  if (held.sessionId === me.sessionId) return { action: 'resume', held };
  const quietMs = runLockQuietMs(held, nowMs, lastMarkMs);
  return quietMs < ttlMs ? { action: 'refuse', held, quietMs } : { action: 'takeover', stale: held, quietMs };
}

export function makeRunLock(me: RunLockSession, nowMs: number, buildHash: string, scope: string): RunLockRecord {
  const at = new Date(nowMs).toISOString();
  return { sessionId: me.sessionId, user: me.user, startedAt: at, heartbeatAt: at, buildHash, scope };
}

export function withHeartbeat(record: RunLockRecord, nowMs: number): RunLockRecord {
  return { ...record, heartbeatAt: new Date(nowMs).toISOString() };
}

function minutes(ms: number): string {
  if (!Number.isFinite(ms)) return '알 수 없음';
  return ms < 60_000 ? `${Math.round(ms / 1000)}초` : `${Math.round(ms / 60_000)}분`;
}

function clock(iso: string): string {
  const ms = epochOf(iso);
  if (ms === null) return iso;
  const d = new Date(ms);
  const two = (n: number): string => (n < 10 ? `0${n}` : `${n}`);
  return `${two(d.getHours())}:${two(d.getMinutes())}`;
}

export function formatRunLockRefusal(held: RunLockRecord, quietMs: number, ttlMs: number): string {
  return (
    `⛔ 다른 실행이 진행 중 — ${held.user} (세션 ${held.sessionId}) · ${clock(held.startedAt)} 시작 · ` +
    `범위 ${held.scope} · 빌드 ${held.buildHash} · 마지막 신호 ${minutes(quietMs)} 전. ` +
    `그 실행이 끝나기를 기다리세요 — 같은 파일에 두 실행이 겹치면 다시 그려지는 세트가 그동안 멤버 하나로 보이고, ` +
    `그것을 합성하는 컴포넌트가 잘못 그려진다(#4831). 신호가 ${minutes(ttlMs)} 넘게 멈추면 다음 실행이 자동으로 인수한다.`
  );
}

export function formatRunLockTakeover(stale: RunLockRecord, quietMs: number, ttlMs: number): string {
  return (
    `⚠ 만료된 실행 잠금 인수 — ${stale.user} (세션 ${stale.sessionId}) 의 실행이 ${minutes(quietMs)} 동안 ` +
    `신호가 없다(TTL ${minutes(ttlMs)}). 죽은 세션으로 보고 계속한다 — 그 실행이 아직 살아 있다면 ` +
    `그쪽 로그의 ✗ 가 이 실행을 가리킬 것이다.`
  );
}

export function formatRunLockAcquired(record: RunLockRecord, resumed: boolean): string {
  return (
    `🔒 실행 잠금 — ${record.user} · 세션 ${record.sessionId} · 빌드 ${record.buildHash} · 범위 ${record.scope} · ` +
    `${clock(record.startedAt)} 시작${resumed ? ' (같은 세션 재진입)' : ''}. 끝나면 풀린다.`
  );
}
