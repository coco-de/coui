// ─── Growth — does the per-unit cost climb as the set gets bigger? ─────────
//
// A span total says how long, and a 972-member set can spend 9,000 seconds two
// different ways: every member costs the same and there are simply many of
// them, or each member costs more than the one before because something scales
// with what is already there. The first is arithmetic; the second is the bug.
// A total cannot tell them apart and neither can a mean — both throw away the
// order the samples arrived in, which is the one thing the question is about.
//
// So a sampler keeps the order in the cheapest form that still answers it: the
// mean of the first hundred samples, the mean of the last hundred, and the
// worst single one. Flat first/last is a constant cost; last well above first
// is cost growing with set size. The max rides along because one pathological
// sample (a layout flush, a collection pause) hides inside a mean and can still
// be the thing worth chasing.
//
// Below 200 samples the two windows share samples, and a first/last comparison
// over shared samples reads as "no growth" whether or not there is any. The
// stats say `null` there rather than print two numbers that were never
// independent.
//
// A leaf module: `identity.ts` (the per-entry accumulators) and `generate.ts`
// (the attach pass and the report) both need it, and the selftest reads it with
// no Figma session.

export const kGrowthWindow = 100;

export interface GrowthStats {
  count: number;
  /** Mean of the first `kGrowthWindow` samples; null below `2 × kGrowthWindow`. */
  first100Ms: number | null;
  /** Mean of the last `kGrowthWindow` samples; null below `2 × kGrowthWindow`. */
  last100Ms: number | null;
  maxMs: number;
}

export class GrowthSampler {
  private count = 0;
  private firstSum = 0;
  // A ring over the most recent window — memory stays one window whatever the
  // sample count, which matters on a pass that makes thousands of calls.
  private readonly recent: number[] = [];
  private next = 0;
  private max = 0;

  add(ms: number): void {
    if (this.count < kGrowthWindow) this.firstSum += ms;
    if (this.recent.length < kGrowthWindow) {
      this.recent.push(ms);
    } else {
      this.recent[this.next] = ms;
    }
    this.next = (this.next + 1) % kGrowthWindow;
    if (ms > this.max) this.max = ms;
    this.count += 1;
  }

  stats(): GrowthStats {
    if (this.count < 2 * kGrowthWindow) {
      return { count: this.count, first100Ms: null, last100Ms: null, maxMs: this.max };
    }
    let recentSum = 0;
    for (const ms of this.recent) recentSum += ms;
    return {
      count: this.count,
      first100Ms: this.firstSum / kGrowthWindow,
      last100Ms: recentSum / kGrowthWindow,
      maxMs: this.max,
    };
  }
}

/**
 * `loop[972: first100 7812.3ms · last100 8120.0ms · max 12040ms]`.
 *
 * Milliseconds for every number, so first and last compare by eye without a
 * unit conversion in between. Bracketed per sampler because the report lines
 * these sit in already use ` · ` between their own fields.
 */
export function formatGrowth(label: string, s: GrowthStats): string {
  if (s.count === 0) return `${label}[표본 없음]`;
  const max = `max ${Math.round(s.maxMs)}ms`;
  if (s.first100Ms === null || s.last100Ms === null) {
    return (
      `${label}[${s.count}: 표본 ${2 * kGrowthWindow} 미만 — ` +
      `first${kGrowthWindow}·last${kGrowthWindow} 비교 불가 · ${max}]`
    );
  }
  return (
    `${label}[${s.count}: first${kGrowthWindow} ${s.first100Ms.toFixed(1)}ms · ` +
    `last${kGrowthWindow} ${s.last100Ms.toFixed(1)}ms · ${max}]`
  );
}
