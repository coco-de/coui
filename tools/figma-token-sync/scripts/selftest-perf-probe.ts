// Self-test for src/perf-probe.ts — the half that needs no canvas: the median,
// the table's shape, and the rule that reads a verdict off it. The half that
// touches Figma (`runPerfProbe`) is exercised from the plugin's 관리 tab; what
// is fixed here is that whatever it measures prints in a fixed order and is
// judged by fixed thresholds, so two runs a month apart read the same way.
//
// Runs under plain Node via `npm run selftest`. Exits non-zero on any failure.

import {
  displayWidth,
  formatProbeReport,
  formatProbeTable,
  judgeHypotheses,
  kH1GrowthRatio,
  kH1InOutRatio,
  kH2Ratio,
  kProbeFloorMs,
  kProbeMetrics,
  kProbeSizes,
  median,
  type ProbeTable,
} from '../src/perf-probe';

declare const process: { exit(code: number): never };

let failures = 0;
function check(label: string, cond: boolean, detail?: string): void {
  if (cond) {
    console.log(`  ✓ ${label}`);
  } else {
    failures++;
    console.error(`  ✗ ${label}${detail ? ` — ${detail}` : ''}`);
  }
}

/** A table where every metric reads `flat` ms at every size, then overridden per metric. */
function tableOf(flat: number, overrides: Record<string, Record<number, number | null>> = {}): ProbeTable {
  return {
    sizes: kProbeSizes,
    rows: kProbeMetrics.map((metric) => {
      const msBySize: Record<number, number | null> = {};
      for (const n of kProbeSizes) {
        const over = overrides[metric];
        // `in`, not `??`: an override of `null` is a deliberately missing cell.
        msBySize[n] = over !== undefined && n in over ? over[n] : flat;
      }
      return { metric, msBySize };
    }),
  };
}

const fillsIn = kProbeMetrics[3];
const fillsOut = kProbeMetrics[4];
const refsRead = kProbeMetrics[5];
const refsBare = kProbeMetrics[6];
const visWrite = kProbeMetrics[7];
const visBare = kProbeMetrics[8];

console.log('median — the middle of the sorted samples, the mean of the two middles when even');
{
  check('empty → 0', median([]) === 0);
  check('one sample is its own median', median([7]) === 7);
  check('odd count picks the middle', median([9, 1, 5]) === 5);
  check('even count averages the two middles', median([4, 1, 3, 2]) === 2.5);
  check('order in does not matter', median([100, 1, 2, 3, 1000]) === 3);
}

console.log('table — one line per metric in declaration order, a column per size, — for a missing cell');
{
  const t = tableOf(1.5, { [fillsIn]: { 972: null }, [refsBare]: { 64: 123.456, 256: 12.34, 972: 1234.5 } });
  const lines = formatProbeTable(t);
  check('header + rule + one line per metric', lines.length === 2 + kProbeMetrics.length, String(lines.length));
  check('header names every size', kProbeSizes.every((n) => lines[0].indexOf(`n=${n}`) >= 0), lines[0]);
  for (let i = 0; i < kProbeMetrics.length; i++) {
    if (lines[2 + i].indexOf(kProbeMetrics[i]) !== 0) {
      check(`line ${i} starts with its metric`, false, lines[2 + i]);
    }
  }
  check('rows keep declaration order', lines.slice(2).every((l, i) => l.indexOf(kProbeMetrics[i]) === 0));
  const fillsLine = lines[2 + 3];
  check('a missing cell prints —', /—\s*$/.test(fillsLine), fillsLine);
  const refsLine = lines[2 + 6];
  check(
    'precision follows magnitude: 3 sig figs under 10, 1 decimal under 100, whole above',
    refsLine.indexOf('123') >= 0 && refsLine.indexOf('12.3') >= 0 && refsLine.indexOf('1235') >= 0,
    refsLine,
  );
  // Width in terminal cells, not code units — a Korean label is two cells a
  // syllable, and the numeric columns line up only if the padding knows that.
  const widths = new Set(lines.slice(2).map((l) => displayWidth(l)));
  check('every row is the same display width (monospace-aligned)', widths.size === 1, [...widths].join(','));
  check('display width counts Hangul and CJK as two cells, ASCII as one', displayWidth('fills 쓰기') === 5 + 1 + 4 && displayWidth('abc') === 3 && displayWidth('🔬') === 2);
}

console.log('verdict — H1 is a write that grows with the set and dwarfs the loose write');
{
  const h1 = tableOf(2, {
    [fillsIn]: { 64: 20, 256: 80, 972: 300 },
    [fillsOut]: { 64: 2, 256: 2, 972: 2 },
  });
  const v = judgeHypotheses(h1);
  check('H1 alone', v.verdict === 'H1', `${v.verdict} — ${v.reason}`);
  check('the reason cites the growth and the in/out ratio', v.reason.indexOf('15.0×') >= 0 && v.reason.indexOf('150.0×') >= 0, v.reason);
  // The clock floor is the denominator's floor: a pair the 1ms clock reads as
  // "1 inside, 0 outside" is 2×, not ∞, and clears nothing.
  const quantised = tableOf(0, {
    [fillsIn]: { 64: 0, 256: 0, 972: 1 },
    [fillsOut]: { 64: 0, 256: 0, 972: 0 },
  });
  check('a zero denominator reads against the floor, not as infinity', judgeHypotheses(quantised).verdict === 'neither', judgeHypotheses(quantised).reason);
  const realGap = tableOf(0.2, {
    [fillsIn]: { 64: 20, 256: 80, 972: 300 },
    [fillsOut]: { 64: 0, 256: 0, 972: 0 },
  });
  check('…while a real 300ms-against-nothing still reads as H1', judgeHypotheses(realGap).verdict === 'H1', judgeHypotheses(realGap).reason);
  // Grows, but the loose write costs the same — not H1 (the cost is the write itself).
  const growsEverywhere = tableOf(2, {
    [fillsIn]: { 64: 20, 256: 80, 972: 300 },
    [fillsOut]: { 64: 20, 256: 80, 972: 300 },
  });
  check('growth without an in/out gap is not H1', judgeHypotheses(growsEverywhere).verdict === 'neither');
  // Big inside, but flat across sizes — not proportional to the set.
  const flatBig = tableOf(2, {
    [fillsIn]: { 64: 300, 256: 300, 972: 300 },
    [fillsOut]: { 64: 2, 256: 2, 972: 2 },
  });
  check('an in/out gap that does not grow is not H1', judgeHypotheses(flatBig).verdict === 'neither');
  // Exactly at the thresholds counts.
  const edge = tableOf(2, {
    [fillsIn]: { 64: 10, 256: 20, 972: 10 * kH1GrowthRatio },
    [fillsOut]: { 64: 2, 256: 2, 972: (10 * kH1GrowthRatio) / kH1InOutRatio },
  });
  check('thresholds are inclusive', judgeHypotheses(edge).verdict === 'H1', judgeHypotheses(edge).reason);
}

console.log('verdict — H2 is a read after a write (or a write after a read) costing a multiple of the bare call');
{
  const h2refs = tableOf(2, { [refsRead]: { 972: 2 * kH2Ratio + 1 }, [refsBare]: { 972: 2 } });
  check('reference write with a read before it', judgeHypotheses(h2refs).verdict === 'H2', judgeHypotheses(h2refs).reason);
  const h2vis = tableOf(2, { [visWrite]: { 972: 50 }, [visBare]: { 972: 2 } });
  check('visible read with a write before it', judgeHypotheses(h2vis).verdict === 'H2', judgeHypotheses(h2vis).reason);
  const under = tableOf(2, { [refsRead]: { 972: 2 * kH2Ratio - 0.5 }, [refsBare]: { 972: 2 } });
  check('just under the ratio is not H2', judgeHypotheses(under).verdict === 'neither', judgeHypotheses(under).reason);
}

console.log('verdict — both, neither, and a table under the clock floor');
{
  const both = tableOf(2, {
    [fillsIn]: { 64: 20, 256: 80, 972: 300 },
    [fillsOut]: { 64: 2, 256: 2, 972: 2 },
    [refsRead]: { 972: 40 },
    [refsBare]: { 972: 2 },
  });
  check('H1+H2 when both hold', judgeHypotheses(both).verdict === 'H1+H2', judgeHypotheses(both).reason);
  check('a flat table is neither', judgeHypotheses(tableOf(2)).verdict === 'neither');
  const quiet = tableOf(kProbeFloorMs / 2);
  const q = judgeHypotheses(quiet);
  check('everything under the floor is inconclusive, and says why', q.verdict === 'inconclusive' && q.reason.indexOf('하한') >= 0, q.reason);
  const empty: ProbeTable = { sizes: kProbeSizes, rows: [] };
  check('no rows is inconclusive', judgeHypotheses(empty).verdict === 'inconclusive');
  // A missing cell in one hypothesis's inputs does not fake the other's answer.
  const holes = tableOf(2, { [fillsIn]: { 64: null, 972: 300 }, [fillsOut]: { 972: 2 }, [refsRead]: { 972: 40 }, [refsBare]: { 972: 2 } });
  check('a missing H1 input leaves H1 unjudged; H2 still reads', judgeHypotheses(holes).verdict === 'H2', judgeHypotheses(holes).reason);
}

console.log('report — heading, table, verdict; the heading names the sizes and the repeats');
{
  const t = tableOf(3);
  const lines = formatProbeReport(t, judgeHypotheses(t), 12_345);
  check('heading first, verdict last', lines[0].indexOf('🔬') === 0 && lines[lines.length - 1].indexOf('판정: ') === 0);
  check('heading names the sizes and the wall time', kProbeSizes.every((n) => lines[0].indexOf(String(n)) >= 0) && lines[0].indexOf('12.3s') >= 0, lines[0]);
  check('the table sits between the heading+legend and the verdict', lines.length === 2 + formatProbeTable(t).length + 1);
  check('the legend spells out the abbreviations', lines[1].indexOf('vp = variantProperties') >= 0, lines[1]);
}

if (failures > 0) {
  console.error(`\n${failures} perf-probe self-test(s) failed.`);
  process.exit(1);
}
console.log('\nAll perf-probe self-tests passed.');
