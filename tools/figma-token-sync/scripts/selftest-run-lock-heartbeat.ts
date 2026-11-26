/// <reference types="@figma/plugin-typings" />

// Self-test for the run-lock heartbeat inside one entry (#6077) — `generate.ts`'s
// `touchRunLock` / `entryProgressListener` against `run-lock.ts`'s `decideRunLock`,
// on a fake clock and a fake document root.
//
// The failure this guards: a lock record rewritten only when an entry STARTS shows
// another session a record as old as the entry is long. An entry that draws for
// 20 minutes is then older than the 10-minute TTL for its last 10, and a second
// session's `decideRunLock` takes the lock over while the holder is alive — both
// then draw into the same variants.
//
// What is isolated here: the other session decides with NO step mark
// (`lastMarkMs = null`), so the only liveness signal is the lock record's own
// `heartbeatAt`. In a real file the file-global step mark is a second signal; a
// test that fed it too would pass with or without the heartbeat and prove nothing
// about it. The mark's own contribution is pinned in `selftest-registry-runtime`.
//
// Every check below is run twice where it can be: against the real listener, and
// against one with the heartbeat call removed — the second must fail, or the check
// cannot tell the difference it exists to tell.

import { entryProgressListener, acquireRunLock, releaseRunLock, touchRunLock } from '../src/generate';
import { decideRunLock, kRunLockDataKey, kRunLockTtlMs, parseRunLock } from '../src/run-lock';
import type { RunLockDecision } from '../src/run-lock';

declare const process: { exit(code: number): never; cwd(): string; hrtime: { bigint(): bigint } };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as { readFileSync(p: string, enc: string): string };
const { join } = require('path') as { join(...parts: string[]): string };

let failures = 0;

function check(label: string, fn: () => void): void {
  try {
    fn();
    console.log(`  ok  ${label}`);
  } catch (e) {
    failures++;
    console.error(`FAIL  ${label}\n      ${String(e)}`);
  }
}

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

function mustThrow(what: string, fn: () => void): void {
  let threw = false;
  try {
    fn();
  } catch {
    threw = true;
  }
  if (!threw) throw new Error(`회귀 주입이 검사를 통과했다: ${what}`);
}

// ─── fake clock · fake document root ────────────────────────────────────────

const kStart = Date.UTC(2026, 10, 6, 0, 0, 0);
let now = kStart;
Date.now = () => now;

const pluginData = new Map<string, string>();
const sharedData = new Map<string, string>();
let lockWrites = 0;
let refuseLockWrites = false;
let lockWriteAttempts = 0;

(globalThis as unknown as { figma: unknown }).figma = {
  currentUser: { sessionId: 1, name: 'Holder' },
  root: {
    getPluginData: (k: string) => pluginData.get(k) ?? '',
    setPluginData: (k: string, v: string) => {
      if (k === kRunLockDataKey) {
        lockWriteAttempts++;
        if (refuseLockWrites) throw new Error('document refused the write');
        lockWrites++;
      }
      pluginData.set(k, v);
    },
    getSharedPluginData: (ns: string, k: string) => sharedData.get(`${ns}/${k}`) ?? '',
    setSharedPluginData: (ns: string, k: string, v: string) => {
      sharedData.set(`${ns}/${k}`, v);
    },
  },
};

const other = { sessionId: 's2', user: 'Other' };
const rawLock = (): string => pluginData.get(kRunLockDataKey) ?? '';

function reset(): void {
  now = kStart;
  pluginData.clear();
  sharedData.clear();
  lockWrites = 0;
  lockWriteAttempts = 0;
  refuseLockWrites = false;
  releaseRunLock();
}

type Listener = (current: number, total: number) => void;

/** The listener `generateComponentsLocked` installs around an entry's `build()`. */
const realListener = (total: number): Listener =>
  entryProgressListener({ entryName: 'Probe', index: 0, total, buildStart: now, onProgress: undefined });

/** The same listener with the heartbeat call removed — the regression to catch. */
const noHeartbeatListener: Listener = () => {};

interface EntryRun {
  /** Seconds at which the other session would have taken the lock over. */
  readonly takeoverSeconds: number[];
  readonly firstTakeoverAtMs: number | null;
  readonly refusedSamples: number;
  readonly heartbeatWrites: number;
}

/**
 * One entry drawn for `durationMs`, one sub-progress tick per `tickMs`; the other
 * session asks `decideRunLock` every second. The holder starts the entry with the
 * lock freshly written (`acquireRunLock`), which is the worst case for the old
 * behaviour — a record written at t=0 and never again.
 */
function drawEntry(durationMs: number, tickMs: number, listenerOf: (total: number) => Listener): EntryRun {
  reset();
  const acquired = acquireRunLock();
  assert(!acquired.refused, 'the holder could not acquire an empty file');
  const writesAtStart = lockWrites;
  const total = Math.max(1, Math.floor(durationMs / tickMs));
  const listener = listenerOf(total);
  const takeoverSeconds: number[] = [];
  let firstTakeoverAtMs: number | null = null;
  let refusedSamples = 0;
  let nextTick = 0;
  let tickIndex = 0;
  for (let t = 0; t <= durationMs; t += 1000) {
    now = kStart + t;
    if (t >= nextTick && tickIndex <= total) {
      listener(tickIndex, total);
      tickIndex++;
      nextTick += tickMs;
    }
    const d: RunLockDecision = decideRunLock(rawLock(), other, now, null);
    if (d.action === 'takeover') {
      takeoverSeconds.push(t / 1000);
      if (firstTakeoverAtMs === null) firstTakeoverAtMs = t;
    } else if (d.action === 'refuse') {
      refusedSamples++;
    }
  }
  return { takeoverSeconds, firstTakeoverAtMs, refusedSamples, heartbeatWrites: lockWrites - writesAtStart };
}

const kMinute = 60_000;

// ─── (a) a long entry keeps the lock alive ──────────────────────────────────

/** The property: for the whole entry the other session is refused, never given the lock. */
function assertLockHeldThroughout(run: EntryRun, durationMs: number): void {
  assert(run.takeoverSeconds.length === 0, `takeover possible from ${run.firstTakeoverAtMs! / 1000}s (${run.takeoverSeconds.length} samples)`);
  assert(run.refusedSamples === Math.floor(durationMs / 1000) + 1, `refused ${run.refusedSamples} samples, expected every one`);
}

console.log('selftest: run-lock-heartbeat');

check('(a) 25분짜리 엔트리를 그리는 동안 하트비트가 쓰이고 다른 세션의 판정은 내내 refuse 다', () => {
  const run = drawEntry(25 * kMinute, 1000, realListener);
  assertLockHeldThroughout(run, 25 * kMinute);
  // 30초 스로틀 그대로 — 25분이면 50번 안팎. 호출은 초당 한 번이어도 쓰기는 스로틀이 정한다.
  assert(run.heartbeatWrites >= 49 && run.heartbeatWrites <= 51, `heartbeat writes ${run.heartbeatWrites}, expected about 50`);
  console.log(`      쓰기 ${run.heartbeatWrites}회(호출 ${25 * 60}회, 30초 스로틀)`);
});

check('회귀 주입 — 하트비트 호출을 빼면 (a) 가 실패한다', () => {
  mustThrow('listener without the heartbeat held the lock for 25 minutes', () => {
    assertLockHeldThroughout(drawEntry(25 * kMinute, 1000, () => noHeartbeatListener), 25 * kMinute);
  });
  const run = drawEntry(25 * kMinute, 1000, () => noHeartbeatListener);
  assert(run.firstTakeoverAtMs === 10 * kMinute, `without the heartbeat the first takeover is at ${run.firstTakeoverAtMs}, expected the TTL`);
});

check('(a) 표 — 노출 시간(다른 세션이 takeover 를 판정할 수 있는 시간): 기존 모델 대 새 코드', () => {
  const rows: [string, number][] = [
    ['Button 실측 1000.6초', 1000_600],
    ['Button 부하 큰 실행 1403.0초', 1403_000],
    ['Chip 실측 530.1초', 530_100],
    ['가정 25분', 25 * kMinute],
  ];
  console.log('      D                              | 기존 계산 max(0,D−TTL) | 기존 모델(코드 실행) | 새 코드(코드 실행)');
  for (const [label, ms] of rows) {
    const formula = Math.max(0, ms - kRunLockTtlMs) / 1000;
    const oldRun = drawEntry(ms, 1000, () => noHeartbeatListener);
    const newRun = drawEntry(ms, 1000, realListener);
    const oldSec = oldRun.takeoverSeconds.length;
    console.log(
      `      ${label.padEnd(30)} | ${formula.toFixed(0).padStart(6)} 초 | ${String(oldSec).padStart(6)} 초 | ${String(newRun.takeoverSeconds.length).padStart(6)} 초`,
    );
    assert(newRun.takeoverSeconds.length === 0, `${label}: new code still exposed`);
    assert(Math.abs(oldSec - formula) <= 1, `${label}: old model ${oldSec}s disagrees with max(0, D−TTL)=${formula}s`);
  }
});

// ─── (b) a cut heartbeat is taken over after the TTL ────────────────────────

check('(b) 하트비트가 끊기면 TTL 뒤 takeover 가 가능하다 — 신호가 끊긴 진짜 죽은 세션', () => {
  reset();
  acquireRunLock();
  const listener = realListener(10_000);
  // 5분 동안 그리고, 그 뒤 홀더가 죽는다 — 어떤 신호도 더는 없다.
  let cutAt = 0;
  for (let t = 0; t <= 5 * kMinute; t += 1000) {
    now = kStart + t;
    listener(t / 1000, 10_000);
    cutAt = t;
  }
  const lastWrite = Date.parse((parseRunLock(rawLock()) as { heartbeatAt: string }).heartbeatAt);
  const sinceLastWrite = kStart + cutAt - lastWrite;
  let firstRefuseEnd = 0;
  let takeoverAt: number | null = null;
  for (let t = cutAt; t <= cutAt + 20 * kMinute; t += 1000) {
    now = kStart + t;
    const d = decideRunLock(rawLock(), other, now, null);
    if (d.action === 'refuse') firstRefuseEnd = t;
    if (d.action === 'takeover') {
      takeoverAt = t;
      break;
    }
  }
  assert(takeoverAt !== null, 'a lock whose heartbeat stopped was never taken over');
  const gap = (takeoverAt as number) - cutAt;
  console.log(
    `      하트비트 끊김 ${cutAt / 1000}s · 마지막 쓰기는 끊기기 ${sinceLastWrite / 1000}초 전 · 마지막 refuse ${firstRefuseEnd / 1000}s · takeover ${(takeoverAt as number) / 1000}s (끊긴 뒤 ${gap / 1000}초, TTL ${kRunLockTtlMs / 1000}초)`,
  );
  // 마지막 쓰기 시각 + TTL 에 takeover — 끊긴 시각 + TTL − (마지막 쓰기가 끊기기 전이었던 만큼).
  assert(gap >= kRunLockTtlMs - 30_000 && gap <= kRunLockTtlMs, `takeover ${gap / 1000}s after the cut, expected within the TTL (${kRunLockTtlMs / 1000}s)`);
  assert(firstRefuseEnd < (takeoverAt as number), 'refuse did not precede takeover');
});

// ─── 쓰기 실패 · 쓰기 비용 ──────────────────────────────────────────────────

check('쓰기를 거부하는 문서 — 호출마다 던지지 않고(엔트리를 죽이지 않는다) 스로틀 뒤에 한 번씩만 다시 시도한다', () => {
  reset();
  acquireRunLock();
  refuseLockWrites = true;
  const attemptsBefore = lockWriteAttempts;
  const listener = realListener(1000);
  // 29초 동안 초당 한 번 — 스로틀 안이라 시도 0, 던지지 않는다.
  for (let t = 1; t <= 29; t++) {
    now = kStart + t * 1000;
    listener(t, 1000);
  }
  assert(lockWriteAttempts === attemptsBefore, `attempted ${lockWriteAttempts - attemptsBefore} writes inside the throttle`);
  // 30초에 시도 한 번(거부) — 같은 30초 안에서 호출마다 다시 시도하지 않는다.
  for (let t = 30; t <= 59; t++) {
    now = kStart + t * 1000;
    listener(t, 1000);
  }
  assert(lockWriteAttempts - attemptsBefore === 1, `a refused write was retried ${lockWriteAttempts - attemptsBefore} times in one throttle window`);
});

check('쓰기 한 번의 비용(가짜 루트 — 실제 Figma 쓰기가 아니다)', () => {
  reset();
  acquireRunLock();
  const n = 20_000;
  const t0 = process.hrtime.bigint();
  for (let i = 1; i <= n; i++) {
    now = kStart + i * 31_000;
    touchRunLock(now);
  }
  const perWriteUs = Number(process.hrtime.bigint() - t0) / 1000 / n;
  assert(lockWrites >= n, `expected ${n} writes, saw ${lockWrites}`);
  console.log(`      가짜 루트에서 쓰기 ${n}회 평균 ${perWriteUs.toFixed(2)} µs(JSON.stringify + Map.set). 실제 Figma 에서는 모든 클라이언트에 전파되는 쓰기이고 이 값은 그 비용이 아니다.`);
});

// ─── 배선 — 호출이 실제 경로에 있다 ─────────────────────────────────────────

check('배선 — generateComponentsLocked 가 엔트리의 서브 진행 청취자로 entryProgressListener 를 설치하고, 그 안에 touchRunLock 이 있다', () => {
  const src = readFileSync(join(process.cwd(), 'src', 'generate.ts'), 'utf8');
  const code = src
    .split('\n')
    .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l))
    .join('\n');
  assert(/installSubProgressListener\(\s*entryProgressListener\(/.test(code), 'the build loop does not install entryProgressListener');
  const body = code.slice(code.indexOf('export function entryProgressListener'));
  const end = body.indexOf('export async function generateComponents');
  assert(/touchRunLock\(Date\.now\(\)\)/.test(body.slice(0, end)), 'entryProgressListener does not call touchRunLock');
  assert(/touchRunLock\(/.test(code.slice(code.indexOf('async function generateComponentsLocked'))), 'the entry start no longer touches the lock');
});

if (failures > 0) {
  console.error(`\nselftest: run-lock-heartbeat — ${failures} failure(s)`);
  process.exit(1);
}
console.log('selftest: run-lock-heartbeat — all ok');
