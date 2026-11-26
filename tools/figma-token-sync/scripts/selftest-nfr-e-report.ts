// #4038 (C5) — drives src/generate.ts's `formatNfrEReport`, the NFR-E
// 재계측 surface. What is testable off-sandbox is deliberately only half of
// C5: the AC's numbers have to come from a real Figma Desktop run, and a
// faked clock here would emit a report that reads like the budget was
// measured when nothing was. So this covers exactly the part that can be
// wrong WITHOUT a Figma session — which verdict a total earns (R-3's two
// thresholds), and whether the three line items the story names actually
// appear with their shares.
//
// BDD/story anchors:
//   "계측 수치가 로그로 남는다 (항목별 소요)" — loadAsync / TextNode / 144set,
//   each addressable rather than folded into one total.
//   R-3 "2배(10분) 초과 시 → 섹션 단위 분할 실행" — and the message has to
//   point at the UI that does it, since a verdict with no escape hatch just
//   restates the problem.
//
// The `⏱` / `↯` build-timing lines, the `finish` and parity splits, the
// property wrappers' billing and the last-step reader ride here too, for the
// same reason: their numbers come from a Figma run, but which remainder a set
// of numbers prints, whether line one still reads the way older logs do,
// whether the parts of a span sum to it, and which bucket a call lands in can
// all be wrong with no Figma session at all.
import {
  addPreOverwrite,
  addStampAndParity,
  formatBuildDetail,
  formatBuildTiming,
  formatFailureTiming,
  formatNfrEReport,
  formatTextStyleAttachLine,
  NfrEMeasurement,
  ParitySplit,
} from '../src/generate';
import { formatGrowth, GrowthSampler, GrowthStats } from '../src/growth';
import {
  bindFocusRing,
  bindTextProp,
  defineProp,
  installSubProgressListener,
  kYieldBudgetMs,
  reportSubProgressAndYield,
} from '../src/helpers';
import {
  BuildCost,
  closeComboLoop,
  completePendingMounts,
  drainResetNodeCost,
  mountSet,
  recordDetailSpan,
  recordYield,
  splitAppend,
  splitFinish,
  zeroAppendSplit,
} from '../src/identity';
import { parseLastStep } from '../src/last-step';
import { parseVariantKey } from '../src/variant-safety';

// Runs under plain Node — no `@types/node`, so `process` and `require` are
// declared locally (same pattern as the other selftests).
declare const process: { exit(code: number): never };
declare const require: (id: string) => unknown;
const { readFileSync, readdirSync } = require('fs') as {
  readFileSync(path: string, encoding: 'utf8'): string;
  readdirSync(path: string): string[];
};

let failures = 0;
function check(label: string, cond: boolean, detail?: string): void {
  if (cond) {
    console.log(`  ✓ ${label}`);
  } else {
    failures++;
    console.error(`  ✗ ${label}${detail ? ` — ${detail}` : ''}`);
  }
}

const kMinute = 60 * 1000;

function measurement(over: Partial<NfrEMeasurement> = {}): NfrEMeasurement {
  return {
    totalMs: 100_000,
    scoped: true,
    loadAsyncMs: 20_000,
    pageCount: 102,
    nodeIndexMs: 10_000,
    nodeCount: 101,
    buildPhaseMs: 50_000,
    docsPhaseMs: 20_000,
    largestSet: { name: 'Button', variants: 144, ms: 30_000 },
    ...over,
  };
}

const joined = (m: NfrEMeasurement): string => formatNfrEReport(m).join('\n');

console.log('three line items (항목별 소요)');
{
  const out = joined(measurement());
  check('header names the 재계측', out.indexOf('NFR-E 재계측') >= 0);
  check('line item 1 — loadAsync, with page count', out.indexOf('loadAsync: 20.0s') >= 0 && out.indexOf('102 pages') >= 0);
  check('line item 1b — 문서 전체 인덱스 (B1), with node count', out.indexOf('문서 전체 인덱스 10.0s') >= 0 && out.indexOf('101 nodes') >= 0);
  check('line item 2 — docs frames named as the TextNode cost', out.indexOf('docs frames (TextNode): 20.0s') >= 0);
  check('builders reported apart from docs frames', out.indexOf('builders: 50.0s') >= 0);
  check('line item 3 — largest set named with its variant count', out.indexOf('Button — 144 variants in 30.0s') >= 0);
}

console.log('loaded pages vs document pages (#4803 component-index cache)');
{
  const full = joined(measurement({ totalPageCount: 102 }));
  check('a full walk prints the page count as before', full.indexOf('102 pages · 문서 전체 인덱스') >= 0);
  check('a full walk does not claim a cache hit', full.indexOf('캐시') < 0);
  const hit = joined(measurement({ pageCount: 7, totalPageCount: 199 }));
  check('a hit prints loaded/total, not the document count alone', hit.indexOf('7/199 pages (인덱스 캐시 적중)') >= 0);
  check('a hit does not call its index the whole-document one', hit.indexOf('문서 전체 인덱스') < 0 && hit.indexOf('캐시 인덱스 10.0s') >= 0);
}

console.log('shares are of the total, not of each other');
{
  const out = joined(measurement());
  check('loadAsync 20/100 → 20%', out.indexOf('20.0s (20%)') >= 0);
  check('builders 50/100 → 50%', out.indexOf('50.0s (50%)') >= 0);
  check('144-set 30/100 → 30%', out.indexOf('30.0s (30%)') >= 0);
}

console.log('degenerate inputs do not produce a nonsense report');
{
  const out = joined(measurement({ totalMs: 0, loadAsyncMs: 0, nodeIndexMs: 0, buildPhaseMs: 0, docsPhaseMs: 0, largestSet: null }));
  check('totalMs 0 → shares read "—", not NaN/Infinity', out.indexOf('—') >= 0 && out.indexOf('NaN') < 0 && out.indexOf('Infinity') < 0);
  check('no set built → says so instead of naming a phantom set', out.indexOf('none built this run') >= 0);
}

console.log('R-3 verdict thresholds');
{
  const under = joined(measurement({ totalMs: 4 * kMinute }));
  check('4분 — no warning at all', under.indexOf('⚠') < 0);

  const atFive = joined(measurement({ totalMs: 5 * kMinute }));
  check('정확히 5분 — still no warning (budget is a ceiling, not a trigger)', atFive.indexOf('⚠') < 0);

  const overFive = joined(measurement({ totalMs: 6 * kMinute }));
  check('6분 — 5-minute NFR-007 warning', overFive.indexOf('5-minute NFR-007 budget') >= 0);
  check('6분 — NOT yet the R-3 split verdict', overFive.indexOf('섹션 단위 분할 실행') < 0);

  const atTen = joined(measurement({ totalMs: 10 * kMinute }));
  check('정확히 10분 — still the 5-minute line, R-3 not yet triggered', atTen.indexOf('5-minute NFR-007 budget') >= 0 && atTen.indexOf('섹션 단위 분할 실행') < 0);

  const overTen = joined(measurement({ totalMs: 11 * kMinute }));
  check('11분 — R-3 split verdict', overTen.indexOf('섹션 단위 분할 실행') >= 0);
  check('11분 — the two verdicts do not both fire', overTen.indexOf('5-minute NFR-007 budget') < 0);
  check(
    'R-3 message points at the section UI that actually does the split',
    overTen.indexOf('섹션 체크박스') >= 0,
  );
  check(
    'R-3 message says it is not feature loss (the renegotiation the story insists on)',
    overTen.indexOf('기능 축소 아님') >= 0,
  );
}

console.log('#5008 — a full run (scoped: false) is not gated by NFR-007 at all');
{
  // The same totals that trigger the 5-minute and 10-minute R-3 verdicts for
  // a scoped run must NOT trigger them here — a full run has no smaller unit
  // to split into by definition, so it is judged only against the separate,
  // non-gating ceiling below.
  const sixMin = joined(measurement({ scoped: false, totalMs: 6 * kMinute }));
  check('6분 전량 실행 — no NFR-007 warning', sixMin.indexOf('NFR-007') < 0, sixMin);
  const elevenMin = joined(measurement({ scoped: false, totalMs: 11 * kMinute }));
  check('11분 전량 실행 — no R-3 split verdict either', elevenMin.indexOf('섹션 단위 분할 실행') < 0, elevenMin);

  const under = joined(measurement({ scoped: false, totalMs: 39 * kMinute }));
  check('39분 — under the 40-minute observation ceiling, no line at all', under.indexOf('ℹ') < 0 && under.indexOf('⚠') < 0, under);

  const at = joined(measurement({ scoped: false, totalMs: 40 * kMinute }));
  check('정확히 40분 — still no line (a ceiling, not a trigger)', at.indexOf('ℹ') < 0, at);

  const over = joined(measurement({ scoped: false, totalMs: 41 * kMinute }));
  check('41분 — observation-only line appears', over.indexOf('관찰용 상한(40분) 초과') >= 0, over);
  check('…marked info (ℹ), not a warning (⚠) — this never blocks anything', over.indexOf('ℹ') >= 0 && over.indexOf('⚠') < 0, over);
  check(
    '…and says it is not a budget violation nor a call to split',
    over.indexOf('예산 위반이 아니라') >= 0 && over.indexOf('섹션 단위 분할 실행') < 0,
    over,
  );

  // A scoped run past 41 minutes is a different story entirely — it still
  // gets the ordinary R-3 verdict, unaffected by the observation ceiling.
  const scopedPast = joined(measurement({ scoped: true, totalMs: 41 * kMinute }));
  check(
    'the same total, but scoped — ordinary R-3 verdict, no observation line',
    scopedPast.indexOf('섹션 단위 분할 실행') >= 0 && scopedPast.indexOf('관찰용 상한') < 0,
    scopedPast,
  );
}

console.log('parity split rides beside 지문/대조, total unchanged');
{
  const out = joined(
    measurement({
      parityPhaseMs: 30_000,
      paritySplit: { preMs: 1_000, snapshotMs: 0, stampMs: 12_000, parityMs: 17_000 },
    }),
  );
  check(
    'split printed beside the unchanged total',
    out.indexOf('지문/대조: 30.0s (30%) [사전 지문 1.0s · 스냅샷 0.0s · 지문 기록 12.0s · 대조 17.0s]') >= 0,
    out,
  );
  const bare = joined(measurement({ parityPhaseMs: 30_000 }));
  check('no split given → the total alone', bare.indexOf('지문/대조: 30.0s (30%)') >= 0 && bare.indexOf('사전 지문') < 0);
}

console.log('지문/대조 split — each block counted once, the parity mark in neither part');
{
  const split: ParitySplit = { preMs: 0, snapshotMs: 0, stampMs: 0, parityMs: 0 };
  let total = 0;
  total += addPreOverwrite(split, 1_000, 1_500, 300);
  check(
    'pre-overwrite: the copy is its own part, the reads around it are the rest',
    split.snapshotMs === 300 && split.preMs === 200,
    JSON.stringify(split),
  );
  total += addStampAndParity(split, 2_000, 2_400, 2_410, 2_600);
  check(
    'stamp and comparison keep their own milliseconds, the mark between them in neither',
    split.stampMs === 400 && split.parityMs === 190,
    JSON.stringify(split),
  );
  total += addStampAndParity(split, 3_000, null, null, 3_300);
  check('a stamp that threw bills its whole block to stamp', split.stampMs === 700 && split.parityMs === 190, JSON.stringify(split));
  check(
    'the parts sum to what the blocks added — nothing counted twice',
    split.preMs + split.snapshotMs + split.stampMs + split.parityMs === total,
    `${JSON.stringify(split)} vs ${total}`,
  );
  check('the total leaves out the mark and nothing else', total === 500 + 590 + 300, String(total));
  const out = joined(measurement({ parityPhaseMs: total, paritySplit: split }));
  check(
    '…and the report prints those parts beside that total',
    out.indexOf('지문/대조: 1.4s (1%) [사전 지문 0.2s · 스냅샷 0.3s · 지문 기록 0.7s · 대조 0.2s]') >= 0,
    out,
  );
}

// The per-span numbers are the 9,208s Button run's own (build 8315.5s, 972
// members), so the "before" line below is the shape a real log had.
const kNoGrowth: GrowthStats = { count: 0, first100Ms: null, last100Ms: null, maxMs: 0 };
function buttonCost(detail: Partial<BuildCost['detail']> = {}): BuildCost {
  return {
    ms: 29_400,
    calls: 972,
    childRemovals: 5130,
    recycled: 972,
    minted: 0,
    finishMs: 714_800,
    spans: {
      node: { ms: 0, calls: 972 },
      instance: { ms: 0, calls: 0 },
      icon: { ms: 11_500, calls: 1944 },
      text: { ms: 3_700, calls: 972 },
      chrome: { ms: 26_100, calls: 7884 },
      ring: { ms: 8_100, calls: 972 },
      geom: { ms: 600, calls: 972 },
      yield: { ms: 95_600, calls: 972 },
    },
    detail: {
      spans: {
        detach: { ms: 0, calls: 0 },
        define: { ms: 0, calls: 0 },
        props: { ms: 0, calls: 0 },
        tints: { ms: 0, calls: 0 },
        attach: { ms: 0, calls: 0 },
        stage: { ms: 0, calls: 0 },
      },
      finish: { appendMs: 0, postMs: 0, layoutMs: 0, offPage: false },
      yieldSplit: { markMs: 0, postMs: 0, tickMs: 0, reports: 0 },
      growth: { loop: kNoGrowth, props: kNoGrowth, define: kNoGrowth, attach: kNoGrowth },
      appendSplit: zeroAppendSplit(),
      appendGrowth: kNoGrowth,
      ...detail,
    },
  };
}
const kButtonBuildMs = 8_315_500;
const kLineOneBefore =
  '⏱ Button: build 8315.5s — reset 29.4s (972 node(s), 5130 child removal(s)) · finish 714.8s · ' +
  'draw(나머지) 7571.3s [yield 95.6s/972 · chrome 26.1s/7884 · icon 11.5s/1944 · ring 8.1s/972 · ' +
  'text 3.7s/972 · geom 0.6s/972 · node 0.0s/972 · 미계측 7425.7s] · 972 recycled / 0 minted';

// The remainder the line SHOULD print, computed from the cost rather than read
// off a literal — so a formatter that drops a span fails here even if someone
// edits an expected string to match it.
function expectedRemainder(buildMs: number, c: BuildCost): string {
  const draw = buildMs - c.ms - c.finishMs;
  let named = 0;
  for (const k of Object.keys(c.spans) as (keyof BuildCost['spans'])[]) {
    if (c.spans[k].calls > 0) named += c.spans[k].ms;
  }
  const d = c.detail.spans;
  const beside = d.detach.ms + d.define.ms + d.props.ms + d.tints.ms + d.attach.ms + d.stage.ms;
  return `미계측 ${(Math.max(0, draw - named - beside) / 1000).toFixed(1)}s]`;
}

console.log('⏱ line one — byte-compatible, and 미계측 loses exactly what line two names');
{
  const [before] = formatBuildTiming('Button', kButtonBuildMs, buttonCost());
  check('no second-line spans → the line older logs have, byte for byte', before === kLineOneBefore, before);

  const cost = buttonCost({
    spans: {
      detach: { ms: 900, calls: 1 },
      define: { ms: 400, calls: 7 },
      props: { ms: 38_800, calls: 6804 },
      tints: { ms: 100, calls: 1 },
      attach: { ms: 0, calls: 0 },
      stage: { ms: 0, calls: 0 },
    },
  });
  const [lineOne] = formatBuildTiming('Button', kButtonBuildMs, cost);
  check(
    'detach + define + props + tints come off 미계측 and nothing else on the line moves',
    lineOne === kLineOneBefore.replace('미계측 7425.7s', '미계측 7385.5s'),
    lineOne,
  );
  check(
    'remainder = draw − named − detach − define − props − tints',
    lineOne.indexOf(expectedRemainder(kButtonBuildMs, cost)) >= 0,
    `${lineOne} (want ${expectedRemainder(kButtonBuildMs, cost)})`,
  );
  const swamped = buttonCost({
    spans: {
      detach: { ms: 0, calls: 0 },
      define: { ms: 0, calls: 0 },
      props: { ms: 9_000_000, calls: 1 },
      tints: { ms: 0, calls: 0 },
      attach: { ms: 0, calls: 0 },
      stage: { ms: 0, calls: 0 },
    },
  });
  check(
    'a remainder driven below zero clamps instead of printing negative',
    formatBuildTiming('Button', kButtonBuildMs, swamped)[0].indexOf('미계측 0.0s]') >= 0,
  );

  // What the redraw kept of the old inner nodes (`redraw-keep.ts`) goes on the
  // end of line one, and its time comes off 미계측 — nothing else moves.
  const kept = buttonCost();
  kept.keep = { kept: 5000, replaced: 130, ms: 4_000, reasons: { unpaired: 100, main: 30 } };
  const [withKeep] = formatBuildTiming('Button', kButtonBuildMs, kept);
  check(
    'kept / replaced ride on the end of line one, reasons by count',
    withKeep ===
      kLineOneBefore.replace('미계측 7425.7s', '미계측 7421.7s') +
        ' · 유지 kept 5000 / replaced 130 (4.0s; unpaired 100 · main 30)',
    withKeep,
  );
}

console.log('⏱ line two — every detail field, in a fixed order');
{
  const loop = new GrowthSampler();
  for (let i = 0; i < 972; i++) loop.add(i < 100 ? 10 : i >= 872 ? 30 : i === 500 ? 500 : 20);
  const props = new GrowthSampler();
  for (let i = 0; i < 150; i++) props.add(i % 8);
  const define = new GrowthSampler();
  for (let i = 1; i <= 7; i++) define.add(50 + i);
  const attach = new GrowthSampler();
  for (let i = 0; i < 972; i++) attach.add(i < 100 ? 11 : 13);
  const appended = new GrowthSampler();
  for (let i = 0; i < 972; i++) appended.add(i < 100 ? 200 : i >= 872 ? 1_200 : 700);
  const cost = buttonCost({
    spans: {
      detach: { ms: 900, calls: 1 },
      define: { ms: 400, calls: 7 },
      props: { ms: 38_800, calls: 6804 },
      tints: { ms: 100, calls: 1 },
      attach: { ms: 12_000, calls: 972 },
      stage: { ms: 0, calls: 0 },
    },
    finish: { appendMs: 700_100, postMs: 200, layoutMs: 14_500, offPage: false },
    yieldSplit: { markMs: 60_100, postMs: 30_200, tickMs: 5_300, reports: 972 },
    growth: { loop: loop.stats(), props: props.stats(), define: define.stats(), attach: attach.stats() },
    appendSplit: {
      deferMs: 100,
      deferCalls: 1,
      flushMs: 1_100,
      flushCalls: 972,
      checkMs: 0,
      appendChildMs: 689_900,
      appendChildCalls: 972,
      readbackMs: 9_000,
      readbackCalls: 972,
      parkedMs: 0,
      parkedCalls: 0,
    },
    appendGrowth: appended.stats(),
  });
  const lines = formatBuildTiming('Button', kButtonBuildMs, cost);
  check('two lines', lines.length === 2);
  check(
    'the second line, whole — definitions apart from binds, each with its own growth',
    lines[1] ===
      '⏱ Button: 세부 — detach 0.9s · define 0.4s/7 · props 38.8s/6804 · tints 0.1s · ' +
        'attach 12.0s/972 · stage 0.0s/0 · ' +
        'finish 714.8s (append 700.1s · post 0.2s · layout 14.5s) · ' +
        'yield 95.6s/972 (mark 60.1s · post 30.2s · tick 5.3s · 보고 972) · ' +
        '증가 loop[972: first100 10.0ms · last100 30.0ms · max 500ms] ' +
        'props[150: 표본 200 미만 — first100·last100 비교 불가 · max 7ms] ' +
        'define[7: 표본 200 미만 — first100·last100 비교 불가 · max 57ms] ' +
        'attach[972: first100 11.0ms · last100 13.0ms · max 13ms] · ' +
        'append 분해 (defer 0.1s/1 · flush 1.1s/972 · 이름 0.0s · appendChild 689.9s/972 · vp읽기 9.0s/972 · parked 0.0s/0) ' +
        'append[972: first100 200.0ms · last100 1200.0ms · max 1200ms]',
    lines[1],
  );
  check(
    'the failure path prints the same fields under ↯',
    formatBuildDetail('↯', 'Button', cost) === lines[1].replace('⏱', '↯'),
  );

  // The keep time cut into its steps goes on the very end of line two, after
  // the append cut, and only where something was parked (#5009).
  const members = new GrowthSampler();
  for (let i = 0; i < 972; i++) members.add(i < 100 ? 1_000 : i >= 872 ? 2_000 : 1_500);
  const keptCost = buttonCost(cost.detail);
  keptCost.keep = {
    kept: 6210,
    replaced: 0,
    ms: 1_473_500,
    reasons: {},
    split: {
      members: 972,
      snapshotMs: 120_000,
      snapshotNodes: 31_000,
      applyMs: 900_000,
      verifyMs: 300_000,
      verifyNodes: 31_000,
      cleanNodes: 29_500,
      tidyMs: 40_000,
      remapMs: 10_000,
      skippedReads: 90_000,
      fullReadTypes: [],
      memberGrowth: members.stats(),
    },
  };
  check(
    'the keep cut rides on the end of line two, its parts summing to the keep time',
    formatBuildDetail('⏱', 'Button', keptCost) ===
      lines[1] +
        ' · 유지 분해 (snapshot 120.0s/31000 · apply 900.0s · verify 300.0s/31000 · 변경 없음 29500 · ' +
        '정리 40.0s · remap 10.0s · 나머지 103.5s · 줄인 읽기 90000) 유지[972: first100 1000.0ms · last100 2000.0ms · max 2000ms]',
    formatBuildDetail('⏱', 'Button', keptCost),
  );
  keptCost.keep.split!.fullReadTypes = ['GROUP', 'TEXT'];
  check(
    'a type the field table was wrong about is named after the skipped reads',
    formatBuildDetail('⏱', 'Button', keptCost).indexOf('줄인 읽기 90000 · 필드표 밖 GROUP,TEXT)') >= 0,
    formatBuildDetail('⏱', 'Button', keptCost),
  );
  const handMade = buttonCost(cost.detail);
  handMade.keep = { kept: 5000, replaced: 130, ms: 4_000, reasons: {} };
  check(
    'a keep cost without a split leaves line two as it was',
    formatBuildDetail('⏱', 'Button', handMade) === lines[1],
  );
  // The off-page option leaves its mark inside the finish bracket and nowhere
  // else — two runs are compared on this line, so the one with the option on
  // has to say so.
  const offPage = buttonCost({ finish: { appendMs: 700_100, postMs: 200, layoutMs: 14_500, offPage: true } });
  const offLine = formatBuildDetail('⏱', 'Button', offPage);
  check(
    'reassembly off-page is marked inside the finish bracket',
    offLine.indexOf('finish 714.8s (append 700.1s · post 0.2s · layout 14.5s · 페이지 밖)') >= 0 &&
      offLine.replace(' · 페이지 밖', '') === formatBuildDetail('⏱', 'Button', buttonCost({ finish: { appendMs: 700_100, postMs: 200, layoutMs: 14_500, offPage: false } })),
    offLine,
  );
}

console.log('↯ failure lines — line one nets out line two, and line two needs no reset');
{
  const cost = buttonCost({
    spans: {
      detach: { ms: 900, calls: 1 },
      define: { ms: 400, calls: 7 },
      props: { ms: 38_800, calls: 6804 },
      tints: { ms: 0, calls: 0 },
      attach: { ms: 0, calls: 0 },
      stage: { ms: 0, calls: 0 },
    },
  });
  const spentMs = 1_000_000;
  const lines = formatFailureTiming('Button', spentMs, cost);
  check(
    'an entry that reset members prints the reset line, then the detail line',
    lines.length === 2 &&
      lines[0].indexOf('↯ Button: 실패 전 reset 29.4s (972 node(s)) — 이 비용은 이 엔트리의 것이다 [') === 0 &&
      lines[1] === formatBuildDetail('↯', 'Button', cost),
    lines.join('\n'),
  );
  check(
    'line one remainder = spent − reset − finish − named − detach − define − props − tints',
    lines.length > 0 && lines[0].indexOf(expectedRemainder(spentMs, cost)) >= 0,
    `${lines[0]} (want ${expectedRemainder(spentMs, cost)})`,
  );

  // An entry that minted every member resets nothing, so these start from a
  // drained, all-zero cost and add one kind of spend each.
  const zeroCost = (): BuildCost => {
    drainResetNodeCost();
    return drainResetNodeCost();
  };
  check('nothing spent → no lines at all', formatFailureTiming('Button', 500, zeroCost()).length === 0);
  const onlyProps = zeroCost();
  onlyProps.detail.spans.props = { ms: 12, calls: 3 };
  const onlyFinish = zeroCost();
  onlyFinish.finishMs = 40;
  const onlyYield = zeroCost();
  onlyYield.spans.yield = { ms: 5, calls: 2 };
  const cases: [string, BuildCost][] = [
    ['props', onlyProps],
    ['finish', onlyFinish],
    ['yield', onlyYield],
  ];
  for (const [label, c] of cases) {
    const out = formatFailureTiming('Button', 500, c);
    check(
      `no reset, only ${label} → the detail line alone`,
      out.length === 1 && out[0] === formatBuildDetail('↯', 'Button', c),
      out.join('\n') || '(no lines)',
    );
  }
}

console.log('growth — first/last 100 answer "does cost climb", and decline below 200');
{
  const rising = new GrowthSampler();
  for (let i = 0; i < 972; i++) rising.add(i < 100 ? 10 : i >= 872 ? 30 : i === 500 ? 500 : 20);
  const s = rising.stats();
  check('count', s.count === 972);
  check('first100 is the first window only', s.first100Ms === 10, String(s.first100Ms));
  check('last100 is the last window only (the ring wrapped)', s.last100Ms === 30, String(s.last100Ms));
  check('max keeps the one spike a mean would hide', s.maxMs === 500);

  const exactly = new GrowthSampler();
  for (let i = 0; i < 200; i++) exactly.add(i < 100 ? 1 : 3);
  const e = exactly.stats();
  check('200 samples — the windows are disjoint, so both are reported', e.first100Ms === 1 && e.last100Ms === 3);

  const few = new GrowthSampler();
  for (let i = 0; i < 199; i++) few.add(i);
  const f = few.stats();
  check('199 samples — first/last withheld, not faked', f.first100Ms === null && f.last100Ms === null && f.maxMs === 198);
  const fewLine = formatGrowth('loop', f);
  check('…and the line says so', fewLine.indexOf('표본 200 미만') >= 0 && fewLine.indexOf('first100 ') < 0, fewLine);
  check('no samples → says there are none', formatGrowth('loop', new GrowthSampler().stats()) === 'loop[표본 없음]');
}

console.log('yield split sums to the yield total; one combo sample per gap');
{
  drainResetNodeCost(); // whatever module state an import left behind
  recordYield(1_000, 1_010, 1_030, 1_100);
  recordYield(1_500, 1_505, 1_505, 1_600);
  closeComboLoop(1_900);
  const c = drainResetNodeCost();
  const y = c.detail.yieldSplit;
  check('yield total and calls keep their meaning', c.spans.yield.ms === 200 && c.spans.yield.calls === 2, JSON.stringify(c.spans.yield));
  check('mark + post + tick === yield', y.markMs + y.postMs + y.tickMs === c.spans.yield.ms, JSON.stringify(y));
  check('each boundary lands in its own part', y.markMs === 15 && y.postMs === 20 && y.tickMs === 165, JSON.stringify(y));
  check(
    'a sample per gap between yields, the last one closed at finish',
    c.detail.growth.loop.count === 2 && c.detail.growth.loop.maxMs === 400,
    JSON.stringify(c.detail.growth.loop),
  );

  recordYield(0, 1, 2, 3); // an entry that dies mid-loop leaves a combo open…
  drainResetNodeCost();
  recordYield(10_000, 10_000, 10_000, 10_000);
  closeComboLoop(10_050);
  check(
    '…and the drain closes it instead of billing it to the next entry',
    drainResetNodeCost().detail.growth.loop.count === 1,
  );

  recordYield(0, null, null, 50);
  recordYield(100, 110, null, 180);
  const t = drainResetNodeCost();
  check(
    'a boundary never reached bills nothing past itself — parts still sum',
    t.detail.yieldSplit.markMs === 60 &&
      t.detail.yieldSplit.postMs === 70 &&
      t.detail.yieldSplit.tickMs === 0 &&
      t.spans.yield.ms === 130,
    JSON.stringify(t.detail.yieldSplit),
  );
}

console.log('a call inside the budget is a report and a combo boundary, not a yield');
{
  drainResetNodeCost();
  recordYield(1_000, 1_010, 1_030, 1_100); // ticked
  recordYield(1_500, 1_505, 1_520, 1_520, false); // marked and posted, no timer
  recordYield(2_000, 2_002, 2_004, 2_050); // ticked
  closeComboLoop(2_400);
  const c = drainResetNodeCost();
  const y = c.detail.yieldSplit;
  check('yield.calls counts the ticks only', c.spans.yield.calls === 2, JSON.stringify(c.spans.yield));
  check('reports counts every call', y.reports === 3, JSON.stringify(y));
  check(
    'the untickd call\'s mark and post are still billed, and the parts still sum',
    y.markMs === 17 && y.postMs === 37 && y.tickMs === 116 && y.markMs + y.postMs + y.tickMs === c.spans.yield.ms,
    JSON.stringify({ y, total: c.spans.yield.ms }),
  );
  check(
    'every call is a combo boundary for the sampler — three combos, not two',
    c.detail.growth.loop.count === 3 && c.detail.growth.loop.maxMs === 480,
    JSON.stringify(c.detail.growth.loop),
  );
}

// The one asynchronous block — `reportSubProgressAndYield` awaits a real timer
// on a tick. Run last, from the tail of this file, so the tally below still
// sees every check (the script bundles to CJS, which has no top-level await).
async function yieldBudgetDrill(): Promise<void> {
  console.log(`reportSubProgressAndYield ticks once per ${kYieldBudgetMs}ms of drawing, and on the first and last combo`);
  // A fake clock: each combo "draws" for a fixed slice before the next report,
  // so the ticks land where the budget says and nowhere else. `setTimeout(0)`
  // is real — what is faked is only the drawing time between calls.
  const realNow = Date.now;
  const drive = async (
    combos: number,
    comboMs: number,
    from = 0,
  ): Promise<{ ticks: number; reports: number; listened: number; loop: number }> => {
    let clock = 100_000;
    let listened = 0;
    try {
      Date.now = () => clock;
      installSubProgressListener(() => {
        listened += 1;
      });
      drainResetNodeCost();
      for (let i = from; i < combos; i++) {
        await reportSubProgressAndYield(i, combos);
        clock += comboMs;
      }
      closeComboLoop(clock);
      const c = drainResetNodeCost();
      return {
        ticks: c.spans.yield.calls,
        reports: c.detail.yieldSplit.reports,
        listened,
        loop: c.detail.growth.loop.count,
      };
    } finally {
      installSubProgressListener(null);
      Date.now = realNow;
    }
  };
  // 20 combos at 100ms: the budget lets a tick through every third combo
  // (0, 3, 6, 9, 12, 15, 18) and the last one (19) ticks regardless.
  const slow = await drive(20, 100);
  check(
    `20 combos at 100ms → 8 ticks (every ${kYieldBudgetMs}ms, plus the last), 20 reports`,
    slow.ticks === 8 && slow.reports === 20 && slow.listened === 20,
    JSON.stringify(slow),
  );
  check('every call is still a combo sample', slow.loop === 20, JSON.stringify(slow));
  // Combos slower than the budget tick every time — nothing is withheld from
  // a loop that already gives the host its turn rarely enough.
  const heavy = await drive(5, kYieldBudgetMs + 1);
  check('combos slower than the budget tick every time', heavy.ticks === 5 && heavy.reports === 5, JSON.stringify(heavy));
  // A loop of one: first and last are the same call, and it ticks once.
  const single = await drive(1, 10);
  check('a loop of one ticks once', single.ticks === 1 && single.reports === 1, JSON.stringify(single));
  // The budget does not leak across loops: a new loop's first combo ticks even
  // if the previous loop ticked a moment ago — and so does a loop that starts
  // past 0, because installing a listener (what generate.ts does before every
  // build) resets the stamp. Started at 1 on purpose: at 0 the reset is the
  // loop's own rule, and this check would pass without the install's.
  await drive(2, 1);
  const later = await drive(3, 1, 1);
  check('a new loop\'s first combo ticks whatever the last loop did', later.ticks === 2 && later.reports === 2, JSON.stringify(later));
}

console.log('finish split — the parts sum to the total, the :finish:post mark in neither part');
{
  const whole = splitFinish(1_000, 1_700, 1_705, 1_710, 1_725);
  check('each boundary lands in its own part', whole.appendMs === 700 && whole.postMs === 5 && whole.layoutMs === 15, JSON.stringify(whole));
  check('the parts sum to the total', whole.appendMs + whole.postMs + whole.layoutMs === whole.totalMs, JSON.stringify(whole));
  check('the mark between append and post is in no part and not in the total', whole.totalMs === 725 - 5, JSON.stringify(whole));
  const died = splitFinish(1_000, null, null, null, 1_300);
  check(
    'a throw before the members were back bills the whole call to append',
    died.appendMs === 300 && died.postMs === 0 && died.layoutMs === 0 && died.totalMs === 300,
    JSON.stringify(died),
  );
  const stranded = splitFinish(1_000, 1_700, 1_705, null, 1_800);
  check(
    'a throw in the post-condition bills the rest to post, none to layout',
    stranded.appendMs === 700 && stranded.postMs === 95 && stranded.layoutMs === 0 && stranded.totalMs === 795,
    JSON.stringify(stranded),
  );
  const firstBuild = splitFinish(1_000, 1_400, 1_400, 1_400, 1_450);
  check(
    'a first build — one combine, no post-condition — has nothing in post',
    firstBuild.appendMs === 400 && firstBuild.postMs === 0 && firstBuild.layoutMs === 50 && firstBuild.totalMs === 450,
    JSON.stringify(firstBuild),
  );
}

console.log('append split — five parts that sum to append, whatever boundary a throw stopped at');
{
  const sum = (p: ReturnType<typeof splitAppend>): number =>
    p.flushMs + p.checkMs + p.appendChildMs + p.readbackMs + p.parkedMs;
  const whole = splitAppend(1_000, 1_010, 1_012, 1_700, 1_709, 1_710);
  check(
    'each boundary lands in its own part',
    whole.flushMs === 10 && whole.checkMs === 2 && whole.appendChildMs === 688 && whole.readbackMs === 9 && whole.parkedMs === 1,
    JSON.stringify(whole),
  );
  check('the parts sum to append', sum(whole) === 710, JSON.stringify(whole));
  // Cut against the same end splitFinish gave append — the two lines agree.
  const finish = splitFinish(1_000, 1_710, 1_712, 1_713, 1_720);
  check('the five parts equal the finish split\'s append', sum(whole) === finish.appendMs, JSON.stringify({ whole, finish }));
  const midAppend = splitAppend(1_000, 1_010, 1_012, null, null, 1_400);
  check(
    'a throw inside the appendChild loop bills the rest to appendChild, nothing past it',
    midAppend.appendChildMs === 388 && midAppend.readbackMs === 0 && midAppend.parkedMs === 0 && sum(midAppend) === 400,
    JSON.stringify(midAppend),
  );
  const inFlush = splitAppend(1_000, null, null, null, null, 1_050);
  check('a throw while flushing bills everything to flush', inFlush.flushMs === 50 && sum(inFlush) === 50, JSON.stringify(inFlush));
}

console.log('loop growth — a builder-shaped loop gives one sample per combo, the last closed at finish');
{
  // The shape `closeComboLoop` documents: the yield opens each combo and
  // finish() follows the loop. The first hundred combos draw 10ms, the rest
  // 30ms, and the very last 999ms — the one sample only the close can take.
  drainResetNodeCost();
  const kCombos = 200;
  let clock = 50_000;
  for (let i = 0; i < kCombos; i++) {
    recordYield(clock, clock + 1, clock + 2, clock + 3);
    clock += 3 + (i === kCombos - 1 ? 999 : i < 100 ? 10 : 30);
  }
  closeComboLoop(clock);
  const g = drainResetNodeCost().detail.growth.loop;
  check('one sample per combo', g.count === kCombos, JSON.stringify(g));
  check('the first window is the first hundred combos', g.first100Ms === 10, JSON.stringify(g));
  check(
    'the last combo is in the last window, and is the max',
    g.last100Ms === (99 * 30 + 999) / 100 && g.maxMs === 999,
    JSON.stringify(g),
  );
}

console.log('…and it is mountSet().finish() that closes it');
{
  // The smallest document a first build needs: `mountSet` finds nothing, mints
  // each member loose on the page, and `finish()` combines them. `figma.root`
  // is left undefined, which `markStep` swallows as it would a refused write.
  interface ProbeNode {
    type: string;
    name: string;
    parent: ProbeNode | null;
    children: ProbeNode[];
    pluginData: Record<string, string>;
    width: number;
    height: number;
    x: number;
    y: number;
    removed: boolean;
    variantProperties?: Record<string, string>;
    setPluginData(key: string, value: string): void;
    getPluginData(key: string): string;
    appendChild(child: ProbeNode): void;
    resize(width: number, height: number): void;
    resizeWithoutConstraints(width: number, height: number): void;
  }
  const appendTo = (parent: ProbeNode, child: ProbeNode): void => {
    if (child.parent) child.parent.children = child.parent.children.filter((c) => c !== child);
    child.parent = parent;
    parent.children.push(child);
    // A set derives a member's axes from its name on append (the registry
    // harness models the same) — reassembly verifies each one it puts back.
    if (parent.type === 'COMPONENT_SET' && child.type === 'COMPONENT') {
      child.variantProperties = parseVariantKey(child.name);
    }
  };
  const probeNode = (type: string): ProbeNode => {
    const node: ProbeNode = {
      type,
      name: '',
      parent: null,
      children: [],
      pluginData: {},
      width: 40,
      height: 20,
      x: 0,
      y: 0,
      removed: false,
      setPluginData: (key, value) => {
        node.pluginData[key] = value;
      },
      getPluginData: (key) => node.pluginData[key] ?? '',
      appendChild: (child) => appendTo(node, child),
      resize: (width, height) => {
        node.width = width;
        node.height = height;
      },
      resizeWithoutConstraints: (width, height) => {
        node.width = width;
        node.height = height;
      },
    };
    return node;
  };
  const host = globalThis as unknown as { figma?: unknown };
  host.figma = {
    createComponent: (): ProbeNode => probeNode('COMPONENT'),
    combineAsVariants: (members: ProbeNode[], parent: ProbeNode): ProbeNode => {
      const set = probeNode('COMPONENT_SET');
      appendTo(parent, set);
      for (const m of members) {
        appendTo(set, m);
        m.variantProperties = parseVariantKey(m.name);
      }
      return set;
    },
  };
  try {
    const page = probeNode('PAGE');
    const names = ['Size=sm', 'Size=md', 'Size=lg'];
    drainResetNodeCost();
    const mount = mountSet(page as never, 'Probe', names);
    for (const name of names) {
      const at = Date.now();
      recordYield(at, at, at, at); // the yield that opens the combo
      mount.getOrCreate(name);
    }
    const set = mount.finish() as unknown as ProbeNode;
    // The run loop's step — `finish()` withholds the members until it.
    completePendingMounts();
    const probe = drainResetNodeCost();
    check(
      'the probe built what a first build builds',
      set.type === 'COMPONENT_SET' && set.children.length === names.length && probe.minted === names.length,
      JSON.stringify({ type: set.type, members: set.children.length, minted: probe.minted }),
    );
    const a = probe.detail.appendSplit;
    check(
      'the append split sums to the append it cuts',
      a.deferMs + a.flushMs + a.checkMs + a.appendChildMs + a.readbackMs + a.parkedMs ===
        probe.detail.finish.appendMs && a.deferCalls === 1,
      JSON.stringify({ split: a, append: probe.detail.finish.appendMs }),
    );
    check(
      'every appendChild is one growth sample, and one read-back each',
      probe.detail.appendGrowth.count === a.appendChildCalls && a.readbackCalls === a.appendChildCalls,
      JSON.stringify({ split: a, growth: probe.detail.appendGrowth }),
    );
    check(
      'three combos, three samples — the third taken by finish()',
      probe.detail.growth.loop.count === names.length && probe.spans.yield.calls === names.length,
      JSON.stringify({ loop: probe.detail.growth.loop, yield: probe.spans.yield }),
    );
  } finally {
    delete host.figma;
  }
}

console.log('attach drained between two yields is billed to attach and taken out of the loop sample');
{
  drainResetNodeCost();
  const t0 = Date.now();
  recordYield(t0, t0, t0, t0);
  recordDetailSpan('attach', Date.now() - 400);
  recordYield(t0 + 1_000, t0 + 1_000, t0 + 1_000, t0 + 1_000);
  recordDetailSpan('attach', Date.now() - 300);
  closeComboLoop(t0 + 2_000);
  const probe = drainResetNodeCost();
  const loop = probe.detail.growth.loop;
  check(
    'two combos, two samples, each net of the attach inside it',
    loop.count === 2 && loop.maxMs >= 690 && loop.maxMs <= 700,
    JSON.stringify(loop),
  );
  check(
    'the attach is on its own span, one call and one sample per label',
    probe.detail.spans.attach.calls === 2 &&
      probe.detail.spans.attach.ms >= 700 &&
      probe.detail.spans.attach.ms <= 720 &&
      probe.detail.growth.attach.count === 2,
    JSON.stringify({ span: probe.detail.spans.attach, growth: probe.detail.growth.attach }),
  );
}

console.log('✎ line keeps its head, names what is not per-label, and gains the per-label growth');
{
  const labels = new GrowthSampler();
  for (let i = 0; i < 972; i++) labels.add(i < 100 ? 400 : 900);
  const line = formatTextStyleAttachLine(
    972,
    972,
    752_200,
    { fontLoadMs: 1_300, faces: 2 },
    labels.stats(),
    { before: 72, restored: 72 },
  );
  check('head unchanged', line.indexOf('✎ 텍스트 스타일 972/972 노드 부착 (752.2s)') === 0, line);
  check(
    'the face preload and the underline count are named on the line',
    line.indexOf('(752.2s) · 글꼴 로드 1.3s/2종 · 밑줄 72/72 복원 · 증가 ') > 0,
    line,
  );
  check(
    'no underline segment when no label carried a decoration',
    formatTextStyleAttachLine(972, 972, 752_200, { fontLoadMs: 1_300, faces: 2 }, labels.stats())
      .indexOf('밑줄') < 0,
  );
  check(
    'growth appended',
    line.endsWith(' · 증가 label[972: first100 400.0ms · last100 900.0ms · max 900ms]'),
    line,
  );
}

console.log('property wrappers bill the bucket they name, once per call, and sample it');
{
  interface PropHost {
    componentPropertyDefinitions: Record<string, { type: string; defaultValue: unknown }>;
    addComponentProperty(name: string, type: string, defaultValue: unknown): string;
  }
  const set: PropHost = {
    componentPropertyDefinitions: {},
    addComponentProperty(name, type, defaultValue) {
      const id = `${name}#${Object.keys(set.componentPropertyDefinitions).length}:0`;
      set.componentPropertyDefinitions[id] = { type, defaultValue };
      return id;
    },
  };
  const label: { componentPropertyReferences?: Record<string, string> } = {};
  const ring: { componentPropertyReferences?: Record<string, string> } = {};
  const band: { componentPropertyReferences?: Record<string, string> } = {};
  drainResetNodeCost();
  const childId = defineProp(set as never, 'Child', 'TEXT', 'Button');
  const showId = defineProp(set as never, 'Show focus ring', 'BOOLEAN', false);
  bindTextProp(label as never, childId);
  bindFocusRing({ ring, band } as never, showId);
  const wired = drainResetNodeCost();
  check(
    'the wrapped calls still reached the nodes',
    childId !== null &&
      label.componentPropertyReferences?.characters === childId &&
      ring.componentPropertyReferences?.visible === showId &&
      band.componentPropertyReferences?.visible === showId,
    JSON.stringify({ childId, showId, label, ring, band }),
  );
  check(
    'defineProp bills define — two definitions, two define samples',
    wired.detail.spans.define.calls === 2 && wired.detail.growth.define.count === 2,
    JSON.stringify({ spans: wired.detail.spans, growth: wired.detail.growth.define }),
  );
  check(
    'the binds bill props — one per wrapper call, the ring and its band as one',
    wired.detail.spans.props.calls === 2 && wired.detail.growth.props.count === 2,
    JSON.stringify({ spans: wired.detail.spans, growth: wired.detail.growth.props }),
  );
}

console.log('builders reach the measured helpers through the barrel');
{
  // A builder that imports a wrapped helper from its defining module draws the
  // same thing with none of the billing: its calls drop out of the span and
  // reappear as `미계측`. The wrapped names are read off the barrel, so a
  // helper wrapped later is covered without editing a list here.
  const barrel = readFileSync('src/helpers.ts', 'utf8');
  const wrapped = new Set<string>();
  const wrapRe = /^export const (\w+) = measured(?:Detail)?\(/gm;
  for (let m = wrapRe.exec(barrel); m !== null; m = wrapRe.exec(barrel)) wrapped.add(m[1]);
  check(
    'the wrapped names were found — a scan that reads none can never fail',
    wrapped.has('focusRing') && wrapped.has('bindFocusRing') && wrapped.has('defineProp') && wrapped.has('panel'),
    [...wrapped].join(', '),
  );
  const files = readdirSync('src/components').filter((f) => f.endsWith('.ts'));
  const bypasses: string[] = [];
  const importRe = /import\s+(type\s+)?\{([^}]*)\}\s*from\s*'([^']+)'/g;
  for (const file of files) {
    const text = readFileSync(`src/components/${file}`, 'utf8');
    for (let m = importRe.exec(text); m !== null; m = importRe.exec(text)) {
      if (m[1] || /\/helpers$/.test(m[3])) continue;
      for (const raw of m[2].split(',')) {
        const name = raw.trim().replace(/^type\s+/, '').split(/\s+as\s+/)[0];
        if (wrapped.has(name)) bypasses.push(`${file}: ${name} from '${m[3]}'`);
      }
    }
  }
  check(`builders scanned (${files.length} files)`, files.length > 10);
  check('no builder imports a measured helper around the barrel', bypasses.length === 0, bypasses.join('; '));
}

console.log('last-step reads back what markStep wrote');
{
  const empty = parseLastStep('', 5_000);
  check('empty → no step and no age (the UI says 기록 없음)', empty.raw === '' && empty.step === null && empty.ageMs === null);
  const normal = parseLastStep('Button:finish:appended:50|1000', 4_000);
  check(
    'step, time and age',
    normal.step === 'Button:finish:appended:50' && normal.markedAt === 1_000 && normal.ageMs === 3_000,
    JSON.stringify(normal),
  );
  const piped = parseLastStep('a|b|123', 200);
  check('split at the last bar — a step may contain one', piped.step === 'a|b' && piped.markedAt === 123);
  const malformed = parseLastStep('Button:props|', 200);
  check(
    'no parsable time → the step is kept and no age is invented',
    malformed.step === 'Button:props|' && malformed.markedAt === null && malformed.ageMs === null,
    JSON.stringify(malformed),
  );
}

yieldBudgetDrill().then(
  () => {
    if (failures > 0) {
      console.error(`\n${failures} NFR-E report self-test(s) failed.`);
      process.exit(1);
    }
    console.log('\nAll NFR-E report self-tests passed.');
  },
  (err: unknown) => {
    console.error(`✗ yield budget drill threw: ${err instanceof Error ? err.stack : String(err)}`);
    process.exit(1);
  },
);
