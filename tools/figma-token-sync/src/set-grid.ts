// Where each member of a COMPONENT_SET goes, decided from its variant name and
// its size alone. Pure — no `figma.*` — so `scripts/selftest-set-grid.ts` can
// run it under plain Node and break it on purpose.
//
// WHY THIS EXISTS. `defaultSetLayout` used to be a square-root wrap: ceil(√N)
// columns, fixed width, `layoutWrap = 'WRAP'`. Members are appended in combo
// order (Variant → Size → State → Shape for Button), so the wrap breaks a row
// wherever the width runs out — and with 1,080 members that put `primary xl`
// and `secondary xs` on the same line, states interleaved with sizes, and a
// 5625 × 1304 set nobody could read. The designer's own question was "can you
// arrange the buttons so I can see them", and the answer has to survive the
// next Generate: `mountSet.finish()` re-applies the default layout on every
// run, so anything arranged by hand on the canvas is undone by the plugin.
//
// THE RULE, in the order a reader scans the set:
//
//   band   — one horizontal band per value of the FIRST axis that is not the
//            row axis (Button: Variant). Bands stack top to bottom. Only when
//            the set has three or more axes; two axes are a plain grid.
//   block  — inside a band, one block per combination of the "block" axes,
//            left to right (Button: Shape → rectangle | square | circle).
//   row    — inside a block, one row per value of the axis that drives member
//            HEIGHT (Button: Size). Every member in a row has the same height,
//            so the rows read as a size ladder. If no axis explains height,
//            the first axis not taken by the band becomes the row axis.
//   column — one column per value of the remaining axis with the MOST values
//            (Button: State). Columns inside a block share a pitch — the
//            widest member in the block plus the gap — so a column of
//            `hover` lines up from `xs` down to `xl2`.
//
// Any remaining axes (Chip: Variant, Selected, Emphasis, Shape, once State
// took the column) become nested block axes, outer to inner in name order,
// with the wider gap between the outer groups.
//
// WHY THESE THREE ROLES ARE MEASURED, NOT NAMED. Nothing here knows the word
// "Size". The row axis is the one whose values partition member heights
// (every value one height, values differing); the column axis is the one with
// the most values among what is left. Naming them would be a list that rots the
// first time a set calls its size axis `Density`, and this repo already has the
// scar for that (`core/theme-axis-composition.md` — "이름은 이 질문에 대해 눈이
// 멀어 있다").
//
// WHAT FALLS BACK. One axis, an unparseable name, or members that do not share
// one axis list — `planAxisGrid` returns null and the caller keeps the wrap. An
// icon set (`Size=16 … 48`) is a single row today and stays one.
//
// THE LEAD MEMBER. Figma takes the member in the set's TOP-LEFT corner as the
// set's default — what a freshly placed instance holds — whatever the layer
// order says. The rules above never ask which member that is, so a ladder that
// climbs by height can hand the corner to a member the code does not default
// to: EmptyState's `compact` is shorter than `normal`, so it took the corner and
// every new instance came in compact. A builder that knows its default passes
// it as `lead` — axis → value, only the axes the code states a default for —
// and each named value moves to the front of its band, block, row or column;
// every other value, and every axis left out, keeps the order the rules gave it.

import { parseVariantKey } from './variant-safety';

export interface GridMember {
  readonly name: string;
  readonly width: number;
  readonly height: number;
}

export interface GridPlacement {
  /** Index into the `members` array the plan was made from. */
  readonly index: number;
  readonly x: number;
  readonly y: number;
}

export interface GridSpacing {
  /** Inset from the set's edge to the first member. */
  readonly pad: number;
  /** Between columns and between rows. */
  readonly gap: number;
  /** Between blocks whose OUTER block-axis value differs. */
  readonly blockGap: number;
  /** Between blocks that differ only in an inner block-axis value. */
  readonly subBlockGap: number;
  /** Between bands. */
  readonly bandGap: number;
}

// Cadence, not tokens: these are canvas scaffolding distances a designer reads
// as "same block / next block / next band", the same family as the 16/24 the
// wrap layouts already used. They bind to nothing in coui_core on purpose.
export const kGridSpacing: GridSpacing = {
  pad: 24,
  gap: 16,
  blockGap: 48,
  subBlockGap: 32,
  bandGap: 64,
};

export interface GridPlan {
  readonly axes: readonly string[];
  readonly bandAxis: string | null;
  readonly rowAxis: string;
  readonly blockAxes: readonly string[];
  readonly colAxis: string;
  readonly width: number;
  readonly height: number;
  readonly placements: readonly GridPlacement[];
}

interface Parsed {
  readonly index: number;
  readonly axes: Record<string, string>;
  readonly width: number;
  readonly height: number;
}

interface HeightGroup {
  min: number;
  max: number;
  sum: number;
  n: number;
}

/**
 * The axis whose values partition member heights — one height per value,
 * different heights across values. Scored as (spread between value means) −
 * (spread inside values), so an axis that only partly explains height loses
 * to one that fully does, and an axis that does not touch height at all
 * (`between ≤ 1`) is never chosen. Returns null when no axis qualifies.
 */
function pickRowAxis(parsed: readonly Parsed[], axisOrder: readonly string[]): string | null {
  let best: string | null = null;
  let bestScore = 0;
  for (const axis of axisOrder) {
    const byValue = new Map<string, HeightGroup>();
    for (const p of parsed) {
      const v = p.axes[axis];
      const g = byValue.get(v);
      if (!g) byValue.set(v, { min: p.height, max: p.height, sum: p.height, n: 1 });
      else {
        g.min = Math.min(g.min, p.height);
        g.max = Math.max(g.max, p.height);
        g.sum += p.height;
        g.n += 1;
      }
    }
    let within = 0;
    let meanMin = Infinity;
    let meanMax = -Infinity;
    for (const g of byValue.values()) {
      within += g.max - g.min;
      const mean = g.sum / g.n;
      if (mean < meanMin) meanMin = mean;
      if (mean > meanMax) meanMax = mean;
    }
    const between = meanMax - meanMin;
    const score = between - within;
    // Strict `>` keeps the earlier axis on a tie — name order is the builder's
    // declared order, and it already reads as "most important first".
    if (between > 1 && score > bestScore) {
      best = axis;
      bestScore = score;
    }
  }
  return best;
}

function cartesian(lists: readonly (readonly string[])[]): string[][] {
  let out: string[][] = [[]];
  for (const list of lists) {
    const next: string[][] = [];
    for (const prefix of out) for (const v of list) next.push([...prefix, v]);
    out = next;
  }
  return out;
}

// Moves [value] to the front of [list], keeping the rest in order. A value the
// list does not hold leaves it as it was.
function leadFirst<T>(list: readonly T[], value: T | undefined): T[] {
  if (value === undefined || !list.includes(value)) return [...list];
  return [value, ...list.filter((v) => v !== value)];
}

export function planAxisGrid(
  members: readonly GridMember[],
  spacing: GridSpacing = kGridSpacing,
  lead?: Readonly<Record<string, string>>,
): GridPlan | null {
  if (members.length < 2) return null;
  const parsed: Parsed[] = [];
  for (let i = 0; i < members.length; i++) {
    let axes: Record<string, string>;
    try {
      axes = parseVariantKey(members[i].name);
    } catch {
      return null;
    }
    parsed.push({ index: i, axes, width: members[i].width, height: members[i].height });
  }
  const axisOrder = Object.keys(parsed[0].axes);
  if (axisOrder.length < 2) return null;
  for (const p of parsed) {
    const keys = Object.keys(p.axes);
    if (keys.length !== axisOrder.length || keys.some((k, i) => k !== axisOrder[i])) return null;
  }

  // Value order = first appearance in member order. The builder emits combos
  // in the order its size/state ladders are declared, so this is `xs → xl2`
  // and `enabled → disabled` without this file knowing either word.
  const values = new Map<string, string[]>();
  for (const axis of axisOrder) values.set(axis, []);
  for (const p of parsed) {
    for (const axis of axisOrder) {
      const list = values.get(axis)!;
      const v = p.axes[axis];
      if (!list.includes(v)) list.push(v);
    }
  }

  const measuredRow = pickRowAxis(parsed, axisOrder);
  const bandAxis = axisOrder.length >= 3 ? (axisOrder.find((a) => a !== measuredRow) ?? null) : null;
  const rowAxis = measuredRow ?? axisOrder.find((a) => a !== bandAxis)!;
  const remaining = axisOrder.filter((a) => a !== rowAxis && a !== bandAxis);
  let colAxis = remaining[0];
  for (const a of remaining) if (values.get(a)!.length > values.get(colAxis)!.length) colAxis = a;
  const blockAxes = remaining.filter((a) => a !== colAxis);

  const bands: (string | null)[] = bandAxis
    ? leadFirst(values.get(bandAxis)!, lead?.[bandAxis])
    : [null];
  // Rows read as a ladder only if they climb. Member order is not that ladder
  // when a size was added after the others — TextField's `xs` sits LAST in
  // its set because it arrived a release later — so rows sort by the height
  // they were chosen for, and a tie keeps first-appearance order (stable sort).
  const tallest = new Map<string, number>();
  for (const p of parsed) {
    const r = p.axes[rowAxis];
    tallest.set(r, Math.max(tallest.get(r) ?? 0, p.height));
  }
  const rows = leadFirst(
    [...values.get(rowAxis)!].sort((a, b) => tallest.get(a)! - tallest.get(b)!),
    lead?.[rowAxis],
  );
  const cols = leadFirst(values.get(colAxis)!, lead?.[colAxis]);
  const blockCombos = cartesian(
    blockAxes.map((a) => leadFirst(values.get(a)!, lead?.[a])),
  );

  const placements: GridPlacement[] = [];
  let y = spacing.pad;
  let width = 0;
  for (const band of bands) {
    const inBand = band === null ? parsed : parsed.filter((p) => p.axes[bandAxis!] === band);
    if (inBand.length === 0) continue;
    // Row height is the tallest member of that row across every block in the
    // band, so blocks sit on one set of baselines.
    const rowH = new Map<string, number>();
    for (const p of inBand) {
      const r = p.axes[rowAxis];
      rowH.set(r, Math.max(rowH.get(r) ?? 0, Math.ceil(p.height)));
    }
    const bandRows = rows.filter((r) => rowH.has(r));
    const rowTop = new Map<string, number>();
    {
      let ry = y;
      for (const r of bandRows) {
        rowTop.set(r, ry);
        ry += rowH.get(r)! + spacing.gap;
      }
    }
    let x = spacing.pad;
    let prev: string[] | null = null;
    for (const combo of blockCombos) {
      const inBlock = inBand.filter((p) => combo.every((v, i) => p.axes[blockAxes[i]] === v));
      if (inBlock.length === 0) continue;
      if (prev) x += combo[0] !== prev[0] ? spacing.blockGap : spacing.subBlockGap;
      let maxW = 0;
      for (const p of inBlock) if (p.width > maxW) maxW = p.width;
      const pitch = Math.ceil(maxW) + spacing.gap;
      for (const p of inBlock) {
        placements.push({
          index: p.index,
          x: x + cols.indexOf(p.axes[colAxis]) * pitch,
          y: rowTop.get(p.axes[rowAxis])!,
        });
      }
      x += cols.length * pitch - spacing.gap;
      prev = combo;
    }
    width = Math.max(width, x + spacing.pad);
    const bandH =
      bandRows.reduce((sum, r) => sum + rowH.get(r)!, 0) + spacing.gap * (bandRows.length - 1);
    y += bandH + spacing.bandGap;
  }
  const height = y - spacing.bandGap + spacing.pad;

  return { axes: axisOrder, bandAxis, rowAxis, blockAxes, colAxis, width, height, placements };
}
