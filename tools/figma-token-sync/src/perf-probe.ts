/// <reference types="@figma/plugin-typings" />

// ─── Performance probe — what a call inside a large set costs, measured ──────
//
// Every number the generate path's bottleneck has been judged by so far was
// read off the ⏱ lines of a real Button run and reasoned backwards: 1.46s a
// bind on a 972-member set, milliseconds on a loose member, a text style at
// 0.77s inside and nothing outside. Two explanations fit those lines and ask
// for different fixes — H1, a write inside a set costs in proportion to the
// set; H2, a READ after a write makes Figma re-derive the whole set, so the
// write is cheap and the next read pays. A run cannot tell them apart,
// because a builder reads and writes in whatever order it draws.
//
// This probe can. It builds synthetic sets of 64 / 256 / 972 members on a
// scratch page — frames, texts and rectangles, ~15 nodes a member, the shape of
// a Button member but no builder involved — and times one call at a time, 20
// repeats each, in the orders that separate the two: a write with and without
// a read before it, a read with and without a write before it, the same write
// inside the set and on a loose member, an append with and without the
// `variantProperties` read the reassembly does after it. The medians go into
// one table, and a rule at the end says which hypothesis the table supports.
//
// The table and the rule are pure (`formatProbeReport`, `judgeHypotheses`) so
// the self-test can fix their shape and the verdict thresholds without a
// canvas. `runPerfProbe` is the only part that touches Figma, and it leaves
// the document as it found it: both scratch pages and the probe's text style
// are removed, the current page is put back, and one undo boundary closes the
// whole thing.

export const kProbeSizes: readonly number[] = [64, 256, 972];
export const kProbeRepeats = 20;
/** Nodes a synthetic member carries besides its root — a Button member's count. */
export const kProbeNodesPerMember = 14;

export const kProbeScratchPageName = '🧪 CoUI Perf Probe (safe to delete)';
export const kProbeOtherPageName = '🧪 CoUI Perf Probe — other page (safe to delete)';
const kProbeTextStyleName = '🧪 CoUI Perf Probe';

/** Ordered as they print. Each is one timed call on one node of one member.
 *  Short on purpose — the plugin's log pane is 400px wide and wraps — with
 *  the abbreviations spelled out in `kProbeLegend`. */
export const kProbeMetrics: readonly string[] = [
  'append (+vp 읽기)',
  'append (읽기 없음)',
  'detach → 페이지',
  'fills 쓰기 · 세트 안',
  'fills 쓰기 · loose',
  'refs 쓰기 · 직전 읽기',
  'refs 쓰기 · 읽기 없음',
  'visible 읽기 · 직전 쓰기',
  'visible 읽기 · 쓰기 없음',
  '스테이징 왕복 (2멤버)',
  'textStyle · 세트 안',
  'textStyle · loose',
  'append · 현재 페이지',
  'append · 다른 페이지',
];
export const kProbeLegend =
  'append = 페이지→세트 appendChild · vp = variantProperties · refs = componentPropertyReferences · ' +
  'textStyle = setTextStyleIdAsync · loose = 세트 밖 멤버';

/** One metric's median milliseconds per call, by set size. `null` when the
 *  probe could not take the measurement at that size. */
export interface ProbeRow {
  metric: string;
  msBySize: Record<number, number | null>;
}

export interface ProbeTable {
  sizes: readonly number[];
  rows: ProbeRow[];
}

export function median(samples: readonly number[]): number {
  if (samples.length === 0) return 0;
  const sorted = samples.slice().sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 1 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

function fmtMs(ms: number | null): string {
  if (ms === null) return '—';
  if (ms >= 100) return ms.toFixed(0);
  if (ms >= 10) return ms.toFixed(1);
  return ms.toFixed(2);
}

/** Terminal cells a string takes in a monospace pane — Hangul, CJK, fullwidth
 *  forms and emoji are two cells, everything else one. `.length` would count
 *  a Korean label as half its width and drift every numeric column. */
export function displayWidth(s: string): number {
  let width = 0;
  for (const ch of Array.from(s)) {
    const cp = ch.codePointAt(0) ?? 0;
    const wide =
      (cp >= 0x1100 && cp <= 0x115f) || // Hangul Jamo
      (cp >= 0x2e80 && cp <= 0xa4cf) || // CJK radicals … Yi
      (cp >= 0xac00 && cp <= 0xd7a3) || // Hangul syllables
      (cp >= 0xf900 && cp <= 0xfaff) || // CJK compatibility ideographs
      (cp >= 0xfe30 && cp <= 0xfe4f) || // CJK compatibility forms
      (cp >= 0xff00 && cp <= 0xff60) || // fullwidth forms
      (cp >= 0xffe0 && cp <= 0xffe6) ||
      (cp >= 0x1f300 && cp <= 0x1faff) || // emoji
      (cp >= 0x20000 && cp <= 0x3fffd);
    width += wide ? 2 : 1;
  }
  return width;
}

function padStart(s: string, width: number): string {
  let out = s;
  while (displayWidth(out) < width) out = ' ' + out;
  return out;
}

function padEnd(s: string, width: number): string {
  let out = s;
  while (displayWidth(out) < width) out += ' ';
  return out;
}

/**
 * The table, one line per metric, milliseconds per call (median of the
 * repeats) under a column per set size. Monospace-aligned for the plugin's
 * log pane; a metric the probe could not measure prints `—`.
 */
export function formatProbeTable(table: ProbeTable): string[] {
  const label = Math.max(...table.rows.map((r) => displayWidth(r.metric)), 4);
  const col = 8;
  const head =
    padEnd('ms/호출 (중앙값)', label) +
    table.sizes.map((n) => padStart(`n=${n}`, col)).join('');
  const rule = '─'.repeat(head.length);
  const lines = [head, rule];
  for (const row of table.rows) {
    lines.push(
      padEnd(row.metric, label) +
        table.sizes.map((n) => padStart(fmtMs(row.msBySize[n] ?? null), col)).join(''),
    );
  }
  return lines;
}

export type Hypothesis = 'H1' | 'H2' | 'H1+H2' | 'neither' | 'inconclusive';

export interface ProbeVerdict {
  verdict: Hypothesis;
  reason: string;
}

/** Below this the clock cannot separate one call from another. */
export const kProbeFloorMs = 0.5;
/** A write that grows this much from the smallest set to the largest scales with the set. */
export const kH1GrowthRatio = 4;
/** …and costs this much more inside the set than on a loose member. */
export const kH1InOutRatio = 4;
/** A read-then-write (or write-then-read) that costs this much more than the bare call re-derives. */
export const kH2Ratio = 2;

function cell(table: ProbeTable, metric: string, size: number): number | null {
  const row = table.rows.find((r) => r.metric === metric);
  if (!row) return null;
  return row.msBySize[size] ?? null;
}

// The denominator is clamped to the clock's floor. A 1ms clock reads a
// sub-millisecond call as 0, and a ratio against 0 is infinite whatever the
// numerator — which would turn "1ms inside, 0ms outside" into a verdict. Against
// the floor, that pair reads as 2× and clears no threshold, while a real
// 300ms-against-nothing still reads as 600×.
function ratio(a: number | null, b: number | null): number | null {
  if (a === null || b === null) return null;
  return a / Math.max(b, kProbeFloorMs);
}

/**
 * Which explanation the table supports.
 *
 * H1 (a write inside a set costs in proportion to the set) shows as the
 * in-set `fills` write growing from the smallest set to the largest AND
 * dwarfing the same write on a loose member. H2 (a read after a write
 * re-derives the set) shows as the reference write with a read before it, or
 * the `visible` read with a write before it, costing a multiple of the bare
 * call on the largest set. The two are not exclusive — a table can say both —
 * and a table whose largest numbers sit under the clock's floor says nothing.
 */
export function judgeHypotheses(table: ProbeTable): ProbeVerdict {
  const sizes = table.sizes.slice().sort((a, b) => a - b);
  if (sizes.length === 0 || table.rows.length === 0) {
    return { verdict: 'inconclusive', reason: '표가 비어 있다' };
  }
  const small = sizes[0];
  const large = sizes[sizes.length - 1];
  let peak = 0;
  for (const row of table.rows) {
    for (const n of sizes) {
      const v = row.msBySize[n];
      if (v !== null && v !== undefined && v > peak) peak = v;
    }
  }
  if (peak < kProbeFloorMs) {
    return {
      verdict: 'inconclusive',
      reason: `가장 큰 값이 ${fmtMs(peak)}ms — 시계 하한(${kProbeFloorMs}ms) 아래라 어느 가설도 구분되지 않는다`,
    };
  }
  const fillsIn = kProbeMetrics[3];
  const fillsOut = kProbeMetrics[4];
  const refsRead = kProbeMetrics[5];
  const refsBare = kProbeMetrics[6];
  const visWrite = kProbeMetrics[7];
  const visBare = kProbeMetrics[8];

  const growth = ratio(cell(table, fillsIn, large), cell(table, fillsIn, small));
  const inOut = ratio(cell(table, fillsIn, large), cell(table, fillsOut, large));
  const h1 = growth !== null && inOut !== null && growth >= kH1GrowthRatio && inOut >= kH1InOutRatio;

  const refs = ratio(cell(table, refsRead, large), cell(table, refsBare, large));
  const vis = ratio(cell(table, visWrite, large), cell(table, visBare, large));
  const h2 = (refs !== null && refs >= kH2Ratio) || (vis !== null && vis >= kH2Ratio);

  const r = (v: number | null): string => (v === null ? '—' : `${v.toFixed(1)}×`);
  const evidence =
    `fills 세트 안 n=${small}→${large} ${r(growth)} · 세트 안/밖 ${r(inOut)} · ` +
    `참조 쓰기 읽기 있음/없음 ${r(refs)} · visible 읽기 쓰기 있음/없음 ${r(vis)}`;
  if (h1 && h2) return { verdict: 'H1+H2', reason: `쓰기가 세트 크기에 비례하고, 읽기가 쓰기 뒤 재유도한다 (${evidence})` };
  if (h1) return { verdict: 'H1', reason: `쓰기가 세트 크기에 비례한다; 읽기 뒤 재유도는 보이지 않는다 (${evidence})` };
  if (h2) return { verdict: 'H2', reason: `쓰기 뒤 읽기가 재유도한다; 쓰기 자체는 세트 크기에 비례하지 않는다 (${evidence})` };
  return { verdict: 'neither', reason: `어느 가설도 문턱을 넘지 않는다 (${evidence})` };
}

/** The lines the `done` log shows: a heading, the table, the verdict. */
export function formatProbeReport(table: ProbeTable, verdict: ProbeVerdict, elapsedMs: number): string[] {
  return [
    `🔬 성능 프로브 — 합성 세트 n ∈ {${table.sizes.join(', ')}}, 멤버당 노드 ${kProbeNodesPerMember + 1}, ` +
      `호출당 최대 ${kProbeRepeats}회 중앙값 (${(elapsedMs / 1000).toFixed(1)}s)`,
    kProbeLegend,
    ...formatProbeTable(table),
    `판정: ${verdict.verdict} — ${verdict.reason}`,
  ];
}

// ─── The half that touches Figma ─────────────────────────────────────────────

interface ProbeMember {
  comp: ComponentNode;
  /** A rectangle two levels down — the `fills` write target. */
  rect: RectangleNode;
  /** A frame two levels down — the reference and `visible` target. */
  frame: FrameNode;
  /** A text node two levels down — the text-style target. */
  text: TextNode;
}

function mintMember(page: PageNode, name: string): ProbeMember {
  const comp = figma.createComponent();
  page.appendChild(comp);
  comp.name = name;
  comp.layoutMode = 'HORIZONTAL';
  comp.primaryAxisSizingMode = 'AUTO';
  comp.counterAxisSizingMode = 'AUTO';
  const row = figma.createFrame();
  row.name = 'row';
  row.layoutMode = 'HORIZONTAL';
  row.primaryAxisSizingMode = 'AUTO';
  row.counterAxisSizingMode = 'AUTO';
  comp.appendChild(row);
  const rects: RectangleNode[] = [];
  const texts: TextNode[] = [];
  const frames: FrameNode[] = [];
  // 14 nodes under the root: row + 3 frames + 6 rectangles + 4 texts — the
  // mix a Button member has (holders, glyph boxes, label, ring, band).
  const nested = (host: FrameNode, tag: string, rectCount: number, textCount: number): void => {
    for (let i = 0; i < rectCount; i++) {
      const r = figma.createRectangle();
      r.name = `${tag}-rect-${i}`;
      r.resize(16, 16);
      host.appendChild(r);
      rects.push(r);
    }
    for (let i = 0; i < textCount; i++) {
      const t = figma.createText();
      t.name = `${tag}-text-${i}`;
      host.appendChild(t);
      texts.push(t);
    }
  };
  nested(row, 'a', 2, 1);
  for (const tag of ['b', 'c']) {
    const f = figma.createFrame();
    f.name = `${tag}-frame`;
    f.layoutMode = 'VERTICAL';
    f.primaryAxisSizingMode = 'AUTO';
    f.counterAxisSizingMode = 'AUTO';
    row.appendChild(f);
    frames.push(f);
    nested(f, tag, 2, 1);
  }
  const extra = figma.createText();
  extra.name = 'd-text';
  row.appendChild(extra);
  texts.push(extra);
  return { comp, rect: rects[2], frame: frames[0], text: texts[1] };
}

// The clock is `Date.now()`, 1ms — `performance` is not in the sandbox. A call
// that takes less than `kProbeQuickMs` is run `kProbeBatch` times and the
// total divided, so a 0.3ms call reads as 0.3 and not as 0 or 1; a call that
// already took longer is one sample on its own, so a 1.4s in-set write is not
// repeated ten times per sample.
export const kProbeQuickMs = 8;
export const kProbeBatch = 10;
function timed(fn: () => void): number {
  const t = Date.now();
  fn();
  const first = Date.now() - t;
  if (first >= kProbeQuickMs) return first;
  const more = Date.now();
  for (let i = 1; i < kProbeBatch; i++) fn();
  return (first + (Date.now() - more)) / kProbeBatch;
}

async function timedAsync(fn: () => Promise<void>): Promise<number> {
  const t = Date.now();
  await fn();
  const first = Date.now() - t;
  if (first >= kProbeQuickMs) return first;
  const more = Date.now();
  for (let i = 1; i < kProbeBatch; i++) await fn();
  return (first + (Date.now() - more)) / kProbeBatch;
}

// A member's name flattens when it leaves its set (`identity.ts` says why);
// put it back so the next append is a valid variant again.
function moveOut(page: PageNode, m: ProbeMember): void {
  const name = m.comp.name;
  page.appendChild(m.comp);
  m.comp.name = name;
}

const kSolidFill: readonly Paint[] = [{ type: 'SOLID', color: { r: 0.2, g: 0.4, b: 0.8 } }];

async function breathe(): Promise<void> {
  await new Promise<void>((resolve) => setTimeout(resolve, 0));
}

/**
 * Builds the sets, takes every measurement, removes everything it made.
 * Reports progress through the same `progress` message Generate uses, so the
 * label reads `probe n=972 · fills 쓰기 — 세트 안` while it runs.
 */
export async function runPerfProbe(
  onProgress?: (p: { index: number; total: number; name: string; elapsedMs: number }) => void,
): Promise<string[]> {
  const startedAt = Date.now();
  const log: string[] = [];
  // One boundary before, one after: the whole probe is a single undo step,
  // and nothing the user did before it is folded in.
  figma.commitUndo();
  const homePage = figma.currentPage;
  // Everything the probe creates is declared here and made inside the `try`,
  // so a failure at any point — creating a page, switching to it, minting the
  // style — still reaches the teardown below with whatever exists.
  let scratch: PageNode | null = null;
  let other: PageNode | null = null;
  let style: TextStyle | null = null;
  const table: ProbeTable = { sizes: kProbeSizes, rows: kProbeMetrics.map((metric) => ({ metric, msBySize: {} })) };
  const put = (metric: string, n: number, samples: number[]): void => {
    const row = table.rows.find((r) => r.metric === metric);
    if (row) row.msBySize[n] = samples.length > 0 ? median(samples) : null;
  };
  // One step per metric per size, plus the build of each size.
  const total = kProbeSizes.length * (kProbeMetrics.length + 1);
  let step = 0;
  const report = (n: number, metric: string): void => {
    step += 1;
    onProgress?.({ index: step, total, name: `probe n=${n} · ${metric}`, elapsedMs: Date.now() - startedAt });
  };
  try {
    scratch = figma.createPage();
    scratch.name = kProbeScratchPageName;
    other = figma.createPage();
    other.name = kProbeOtherPageName;
    await figma.setCurrentPageAsync(scratch);
    await scratch.loadAsync();
    await other.loadAsync();
    style = figma.createTextStyle();
    style.name = kProbeTextStyleName;
    await figma.loadFontAsync(style.fontName);
    const scratchPage: PageNode = scratch;
    const otherPage: PageNode = other;
    const textStyle: TextStyle = style;
    for (const n of kProbeSizes) {
      // ── build ──
      report(n, `세트 조립 (${n} 멤버)`);
      const members: ProbeMember[] = [];
      for (let i = 0; i < n; i++) {
        members.push(mintMember(scratchPage, `Variant=v${i}`));
        if (i % 64 === 63) await breathe();
      }
      const set = figma.combineAsVariants(members.map((m) => m.comp), scratchPage);
      set.name = `🧪 probe set n=${n}`;
      const showId = set.addComponentProperty('Show', 'BOOLEAN', true);
      // The staging set: two members of its own, so the staged write lands
      // in a set that never holds more than two.
      const anchor = mintMember(scratchPage, 'Variant=anchor');
      const staged = mintMember(scratchPage, 'Variant=staged');
      const tiny = figma.combineAsVariants([anchor.comp], scratchPage);
      tiny.name = `🧪 probe staging set (n=${n})`;
      // Two properties, so consecutive trips write different values — a write
      // of the value already there may be short-circuited and read as free.
      const tinyShowIds = [
        tiny.addComponentProperty('Show', 'BOOLEAN', true),
        tiny.addComponentProperty('Show alt', 'BOOLEAN', true),
      ];
      // Members 1.. are handed out in five disjoint pools (offsets of REPEATS),
      // so a "no write before it" read never lands on a node another metric
      // wrote this pass; member 0 stays put as the anchor. Five pools have to
      // fit in n − 1 members, which caps the repeats at the smallest size.
      const REPEATS = Math.min(kProbeRepeats, Math.floor((n - 1) / 5));
      const pick = (k: number): ProbeMember => members[1 + (k % (n - 1))];
      const samples = (): number[] => [];

      // 1 · 2 append, with and without the read the reassembly does after it
      {
        report(n, kProbeMetrics[0]);
        const withRead = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k);
          moveOut(scratchPage, m);
          withRead.push(
            timed(() => {
              set.appendChild(m.comp);
              void m.comp.variantProperties;
            }),
          );
        }
        put(kProbeMetrics[0], n, withRead);
        await breathe();
        report(n, kProbeMetrics[1]);
        const bare = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k + REPEATS);
          moveOut(scratchPage, m);
          bare.push(timed(() => set.appendChild(m.comp)));
        }
        put(kProbeMetrics[1], n, bare);
        await breathe();
      }
      // 3 detach — the reparent alone; the rename that follows it is untimed
      {
        report(n, kProbeMetrics[2]);
        const out = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k);
          const name = m.comp.name;
          const page = scratchPage;
          out.push(timed(() => page.appendChild(m.comp)));
          m.comp.name = name;
          set.appendChild(m.comp);
        }
        put(kProbeMetrics[2], n, out);
        await breathe();
      }
      // 4 · 5 fills, inside and outside
      {
        report(n, kProbeMetrics[3]);
        const inside = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k);
          inside.push(timed(() => { m.rect.fills = kSolidFill.slice(); }));
        }
        put(kProbeMetrics[3], n, inside);
        await breathe();
        report(n, kProbeMetrics[4]);
        const outside = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k + REPEATS);
          moveOut(scratchPage, m);
          outside.push(timed(() => { m.rect.fills = kSolidFill.slice(); }));
          set.appendChild(m.comp);
        }
        put(kProbeMetrics[4], n, outside);
        await breathe();
      }
      // 6 · 7 reference write, with and without a read just before it
      {
        report(n, kProbeMetrics[5]);
        const withRead = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k);
          withRead.push(
            timed(() => {
              void m.frame.componentPropertyReferences;
              m.frame.componentPropertyReferences = { visible: showId };
            }),
          );
        }
        put(kProbeMetrics[5], n, withRead);
        await breathe();
        report(n, kProbeMetrics[6]);
        const bare = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k + REPEATS);
          bare.push(timed(() => { m.frame.componentPropertyReferences = { visible: showId }; }));
        }
        put(kProbeMetrics[6], n, bare);
        await breathe();
      }
      // 8 · 9 visible read, without and then with a write just before it
      // (bare first, on nodes nothing has written since the build)
      {
        report(n, kProbeMetrics[8]);
        const bare = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k + 3 * REPEATS);
          bare.push(timed(() => { void m.rect.visible; }));
        }
        put(kProbeMetrics[8], n, bare);
        await breathe();
        report(n, kProbeMetrics[7]);
        const afterWrite = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k + 4 * REPEATS);
          m.rect.visible = k % 2 === 0;
          afterWrite.push(timed(() => { void m.rect.visible; }));
        }
        put(kProbeMetrics[7], n, afterWrite);
        await breathe();
      }
      // 10 staging round trip on the two-member set
      {
        report(n, kProbeMetrics[9]);
        const trips = samples();
        for (let k = 0; k < REPEATS; k++) {
          const page = scratchPage;
          trips.push(
            timed(() => {
              tiny.appendChild(staged.comp);
              staged.frame.componentPropertyReferences = { visible: tinyShowIds[k % 2] };
              moveOut(page, staged);
            }),
          );
        }
        put(kProbeMetrics[9], n, trips);
        await breathe();
      }
      // 11 · 12 text style, inside and loose
      {
        report(n, kProbeMetrics[10]);
        const inside = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k);
          inside.push(await timedAsync(() => m.text.setTextStyleIdAsync(textStyle.id)));
        }
        put(kProbeMetrics[10], n, inside);
        report(n, kProbeMetrics[11]);
        const loose = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k + REPEATS);
          moveOut(scratchPage, m);
          loose.push(await timedAsync(() => m.text.setTextStyleIdAsync(textStyle.id)));
          set.appendChild(m.comp);
        }
        put(kProbeMetrics[11], n, loose);
      }
      // 13 · 14 append while the set's page is current, and while it is not
      {
        report(n, kProbeMetrics[12]);
        const current = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k);
          moveOut(scratchPage, m);
          current.push(timed(() => set.appendChild(m.comp)));
        }
        put(kProbeMetrics[12], n, current);
        await figma.setCurrentPageAsync(otherPage);
        report(n, kProbeMetrics[13]);
        const elsewhere = samples();
        for (let k = 0; k < REPEATS; k++) {
          const m = pick(k + REPEATS);
          moveOut(scratchPage, m);
          elsewhere.push(timed(() => set.appendChild(m.comp)));
        }
        put(kProbeMetrics[13], n, elsewhere);
        await figma.setCurrentPageAsync(scratchPage);
      }
      // ── tear down this size before the next, so sizes do not stack ──
      set.remove();
      tiny.remove();
      if (!staged.comp.removed) staged.comp.remove();
      await breathe();
    }
    const verdict = judgeHypotheses(table);
    for (const line of formatProbeReport(table, verdict, Date.now() - startedAt)) log.push(line);
  } catch (err) {
    log.push(`✗ 성능 프로브 실패: ${String(err)} — 스크래치 페이지는 정리했다`);
  } finally {
    // Each step on its own, so one that fails does not leave the rest undone.
    // The current page has to be somewhere else before a scratch page goes:
    // home first, and failing that any page that is not the probe's.
    if (style) {
      try {
        style.remove();
      } catch {
        // A style that was never applied may already be gone.
      }
    }
    const isProbePage = (p: BaseNode): boolean => p === scratch || p === other;
    try {
      await figma.setCurrentPageAsync(homePage);
    } catch {
      const elsewhere = figma.root.children.find((p) => !isProbePage(p));
      if (elsewhere) {
        try {
          await figma.setCurrentPageAsync(elsewhere);
        } catch {
          // Nowhere to go — the removals below will refuse the current page and say so.
        }
      }
    }
    for (const page of [scratch, other]) {
      if (!page || page.removed) continue;
      try {
        page.remove();
      } catch (err) {
        log.push(`⚠ 성능 프로브: 스크래치 페이지 "${page.name}" 을 지우지 못했다 (${String(err)}) — 손으로 지우세요`);
      }
    }
    figma.commitUndo();
  }
  return log;
}
