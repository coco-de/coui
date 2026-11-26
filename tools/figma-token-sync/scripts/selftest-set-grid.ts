// Self-test for src/set-grid.ts — the axis grid every COMPONENT_SET is laid
// out with. Pure logic, no Figma runtime; runs under plain Node via
// `npm run selftest`. Exits non-zero on any assertion failure.
//
// The sets below are shaped like the real ones (Button 10×6×6×3, Chip
// 4×6×5×2×2, Banner 5×2, Loading 4×6, AppBar 3×4×2) but built from ladders,
// not read from the file — the test is about the RULE (which axis becomes
// band / row / block / column, and that nothing overlaps), not about pixels.

import { type GridMember, type GridPlan, kGridSpacing, planAxisGrid } from '../src/set-grid';

declare const process: { exit(code: number): never };

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

function assertEq<T>(actual: T, expected: T, what: string): void {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${what}: got ${a}, expected ${e}`);
}

function plan(members: GridMember[]): GridPlan {
  const p = planAxisGrid(members);
  if (!p) throw new Error('planAxisGrid returned null');
  return p;
}

interface Box {
  index: number;
  x: number;
  y: number;
  w: number;
  h: number;
}

function boxes(members: GridMember[], p: GridPlan): Box[] {
  return p.placements.map((pl) => ({
    index: pl.index,
    x: pl.x,
    y: pl.y,
    w: members[pl.index].width,
    h: members[pl.index].height,
  }));
}

function assertNoOverlap(bs: Box[]): void {
  for (let i = 0; i < bs.length; i++) {
    for (let j = i + 1; j < bs.length; j++) {
      const a = bs[i];
      const b = bs[j];
      const overlap = a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
      if (overlap) throw new Error(`members ${a.index} and ${b.index} overlap`);
    }
  }
}

function assertInside(bs: Box[], p: GridPlan): void {
  const pad = kGridSpacing.pad;
  for (const b of bs) {
    assert(b.x >= pad && b.y >= pad, `member ${b.index} inside the pad`);
    assert(b.x + b.w <= p.width - pad + 0.001, `member ${b.index} inside the width`);
    assert(b.y + b.h <= p.height - pad + 0.001, `member ${b.index} inside the height`);
  }
}

// ─── Button: Variant × Size × State × Shape ─────────────────────────────────

const kVariants = ['primary', 'secondary', 'outline', 'ghost', 'link', 'plain', 'destructive', 'card', 'menu', 'menubar'];
const kSizes = ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'];
const kStates = ['enabled', 'hover', 'focus', 'pressed', 'selected', 'disabled'];
const kShapes = ['rectangle', 'square', 'circle'];
const kHeight: Record<string, number> = { xs: 24, sm: 32, md: 40, lg: 48, xl: 56, xl2: 64 };
const kLabelWidth: Record<string, number> = { xs: 47, sm: 67, md: 75, lg: 113, xl: 135, xl2: 151 };

function buttonMembers(): GridMember[] {
  const out: GridMember[] = [];
  for (const v of kVariants)
    for (const s of kSizes)
      for (const st of kStates)
        for (const sh of kShapes)
          out.push({
            name: `Variant=${v}, Size=${s}, State=${st}, Shape=${sh}`,
            width: sh === 'rectangle' ? kLabelWidth[s] + (v === 'outline' ? 2 : 0) : kHeight[s],
            height: kHeight[s],
          });
  return out;
}

console.log('Button — 4 axes');
{
  const members = buttonMembers();
  const p = plan(members);
  const axesOf = (name: string): Record<string, string> =>
    Object.fromEntries(name.split(',').map((seg) => seg.split('=').map((t) => t.trim()) as [string, string]));

  check('roles: band=Variant row=Size col=State block=[Shape]', () => {
    assertEq(p.bandAxis, 'Variant', 'bandAxis');
    assertEq(p.rowAxis, 'Size', 'rowAxis');
    assertEq(p.colAxis, 'State', 'colAxis');
    assertEq([...p.blockAxes], ['Shape'], 'blockAxes');
  });
  check('every member is placed exactly once', () => {
    const seen = new Set(p.placements.map((pl) => pl.index));
    assertEq(seen.size, members.length, 'placed count');
  });
  const bs = boxes(members, p);
  check('no two members overlap', () => assertNoOverlap(bs));
  check('every member sits inside the set pad', () => assertInside(bs, p));
  check('a column shares one x across the size ladder (State aligns inside a block)', () => {
    const key = (b: Box): string => {
      const a = axesOf(members[b.index].name);
      return `${a.Variant}|${a.Shape}|${a.State}`;
    };
    const xs = new Map<string, Set<number>>();
    for (const b of bs) (xs.get(key(b)) ?? xs.set(key(b), new Set()).get(key(b))!).add(b.x);
    for (const [k, set] of xs) assert(set.size === 1, `${k} spans ${set.size} x positions`);
  });
  check('a row shares one y across blocks (Size aligns inside a band)', () => {
    const key = (b: Box): string => {
      const a = axesOf(members[b.index].name);
      return `${a.Variant}|${a.Size}`;
    };
    const ys = new Map<string, Set<number>>();
    for (const b of bs) (ys.get(key(b)) ?? ys.set(key(b), new Set()).get(key(b))!).add(b.y);
    for (const [k, set] of ys) assert(set.size === 1, `${k} spans ${set.size} y positions`);
  });
  check('sizes descend the band in ladder order and bands stack in variant order', () => {
    const top = (v: string, s: string): number =>
      bs.find((b) => members[b.index].name.startsWith(`Variant=${v}, Size=${s},`))!.y;
    for (let i = 1; i < kSizes.length; i++) assert(top('primary', kSizes[i]) > top('primary', kSizes[i - 1]), `size ${kSizes[i]} below ${kSizes[i - 1]}`);
    for (let i = 1; i < kVariants.length; i++) assert(top(kVariants[i], 'xs') > top(kVariants[i - 1], 'xl2'), `band ${kVariants[i]} below ${kVariants[i - 1]}`);
  });
  check('blocks go rectangle → square → circle, left to right', () => {
    const left = (sh: string): number =>
      bs.find((b) => members[b.index].name === `Variant=primary, Size=xs, State=enabled, Shape=${sh}`)!.x;
    assert(left('rectangle') < left('square') && left('square') < left('circle'), 'block order');
  });
  check('the set is taller than wide — bands stack, they do not wrap', () => {
    assert(p.height > p.width, `${p.width}×${p.height}`);
  });
}

// ─── Chip: Color × Variant × Size × State × Selected × Emphasis × Shape ─────

console.log('Chip — 7 axes, four nested block axes');
{
  const members: GridMember[] = [];
  for (const c of ['neutral', 'primary'])
    for (const v of ['outlined', 'filled'])
      for (const s of kSizes)
        for (const st of ['enabled', 'hover', 'focus', 'pressed', 'disabled'])
          for (const sel of ['false', 'true'])
            for (const em of ['low', 'high'])
              for (const sh of ['rounded', 'pill'])
                members.push({
                  name: `Color=${c}, Variant=${v}, Size=${s}, State=${st}, Selected=${sel}, Emphasis=${em}, Shape=${sh}`,
                  width: 60 + kSizes.indexOf(s) * 12,
                  height: 16 + kSizes.indexOf(s) * 8,
                });
  const p = plan(members);
  check('roles: band=Color row=Size col=State (most values) block=[Variant, Selected, Emphasis, Shape]', () => {
    assertEq(p.bandAxis, 'Color', 'bandAxis');
    assertEq(p.rowAxis, 'Size', 'rowAxis');
    assertEq(p.colAxis, 'State', 'colAxis');
    assertEq([...p.blockAxes], ['Variant', 'Selected', 'Emphasis', 'Shape'], 'blockAxes');
  });
  const bs = boxes(members, p);
  check('no overlap across 960 members', () => assertNoOverlap(bs));
  check('outer block gap is wider than the inner one', () => {
    const left = (variant: string, sel: string, em: string, sh: string): number =>
      bs.find(
        (b) =>
          members[b.index].name ===
          `Color=neutral, Variant=${variant}, Size=xs, State=enabled, Selected=${sel}, Emphasis=${em}, Shape=${sh}`,
      )!.x;
    // Neighbouring blocks differ only in Shape (the innermost axis) →
    // subBlockGap; crossing from Variant=outlined to Variant=filled (the
    // outer axis) → blockGap.
    const innerStep = left('outlined', 'false', 'low', 'pill') - left('outlined', 'false', 'low', 'rounded');
    const outerStep = left('filled', 'false', 'low', 'rounded') - left('outlined', 'true', 'high', 'pill');
    assert(outerStep > innerStep, 'outer gap > inner gap');
    assertEq(outerStep - innerStep, kGridSpacing.blockGap - kGridSpacing.subBlockGap, 'gap difference');
  });
}

// ─── Two-axis sets ──────────────────────────────────────────────────────────

console.log('Banner — 2 axes, uniform height');
{
  const members: GridMember[] = [];
  for (const v of ['neutral', 'info', 'success', 'warning', 'destructive'])
    for (const st of ['weak', 'solid']) members.push({ name: `Variant=${v}, Style=${st}`, width: 480, height: 72 });
  const p = plan(members);
  check('no height axis → rows = first axis, columns = the other, no band', () => {
    assertEq(p.bandAxis, null, 'bandAxis');
    assertEq(p.rowAxis, 'Variant', 'rowAxis');
    assertEq(p.colAxis, 'Style', 'colAxis');
    assertEq([...p.blockAxes], [], 'blockAxes');
  });
  check('5 rows × 2 columns measure out exactly', () => {
    assertEq(p.width, 24 + 480 + 16 + 480 + 24, 'width');
    assertEq(p.height, 24 + 5 * 72 + 4 * 16 + 24, 'height');
  });
  check('no overlap', () => assertNoOverlap(boxes(members, p)));
}

console.log('TextField — a size appended after the others still climbs the ladder');
{
  // The real set lists `xs` last: it was added a release after sm…xl2, and
  // recycled members keep their slot. Rows must sort by height, not by order.
  const members: GridMember[] = [];
  for (const v of ['defaultVariant', 'error'])
    for (const s of ['sm', 'md', 'lg', 'xl', 'xl2', 'xs'])
      for (const st of ['enabled', 'hover', 'focus', 'disabled'])
        members.push({ name: `Variant=${v}, Size=${s}, State=${st}`, width: 240, height: kHeight[s] });
  const p = plan(members);
  const bs = boxes(members, p);
  check('xs is the top row of its band even though it was declared last', () => {
    const top = (s: string): number => bs.find((b) => members[b.index].name === `Variant=defaultVariant, Size=${s}, State=enabled`)!.y;
    for (let i = 1; i < kSizes.length; i++) assert(top(kSizes[i]) > top(kSizes[i - 1]), `${kSizes[i]} below ${kSizes[i - 1]}`);
    assertEq(top('xs'), kGridSpacing.pad, 'xs row top');
  });
  check('no overlap', () => assertNoOverlap(bs));
}

console.log('Loading — 2 axes, height on the second axis');
{
  const members: GridMember[] = [];
  for (const v of ['spinner', 'dots', 'bar', 'pulse'])
    for (const s of kSizes) members.push({ name: `Variant=${v}, Size=${s}`, width: kHeight[s], height: kHeight[s] });
  const p = plan(members);
  check('the measured height axis wins the row role even when declared second', () => {
    assertEq(p.rowAxis, 'Size', 'rowAxis');
    assertEq(p.colAxis, 'Variant', 'colAxis');
    assertEq(p.bandAxis, null, 'bandAxis');
  });
  check('no overlap', () => assertNoOverlap(boxes(members, p)));
}

// ─── Three axes with height on the first axis ───────────────────────────────

console.log('AppBar — 3 axes, height on the first axis');
{
  const members: GridMember[] = [];
  const h: Record<string, number> = { compact: 56, standard: 64, medium: 112 };
  for (const v of ['compact', 'standard', 'medium'])
    for (const l of ['none', 'back', 'close', 'menu'])
      for (const a of ['start', 'center']) members.push({ name: `Variant=${v}, Leading=${l}, Align=${a}`, width: 360, height: h[v] });
  const p = plan(members);
  check('row = Variant (height), band = next axis in name order, col = the last', () => {
    assertEq(p.rowAxis, 'Variant', 'rowAxis');
    assertEq(p.bandAxis, 'Leading', 'bandAxis');
    assertEq(p.colAxis, 'Align', 'colAxis');
  });
  check('no overlap', () => assertNoOverlap(boxes(members, p)));
}

// ─── Fallbacks ──────────────────────────────────────────────────────────────

console.log('fallbacks → null (caller keeps the wrap)');
check('one axis (an icon size ladder) is not a grid', () => {
  const members = [10, 12, 14, 16, 18, 20, 24, 28, 32, 48].map((s) => ({ name: `Size=${s}`, width: s, height: s }));
  assertEq(planAxisGrid(members), null, 'plan');
});
check('a single member is not a grid', () => {
  assertEq(planAxisGrid([{ name: 'Variant=a, Size=b', width: 10, height: 10 }]), null, 'plan');
});
check('a malformed name falls back instead of throwing', () => {
  assertEq(
    planAxisGrid([
      { name: 'Variant=a, Size=xs', width: 10, height: 10 },
      { name: 'Button/primary/xs', width: 10, height: 10 },
    ]),
    null,
    'plan',
  );
});
check('members that disagree on their axis list fall back', () => {
  assertEq(
    planAxisGrid([
      { name: 'Variant=a, Size=xs', width: 10, height: 10 },
      { name: 'Variant=a, Tone=x', width: 10, height: 10 },
    ]),
    null,
    'plan',
  );
});

// ─── The lead member ─────────────────────────────────────────────────────────
// Figma reads the top-left member as the set's default. A ladder that climbs by
// height can put a non-default member there; `lead` pins the code default.

console.log('a lead member takes the top-left corner');
// EmptyState: `normal` is taller than `compact`, so the ladder alone hands the
// corner to `compact` and every new instance comes in compact.
const kEmptyState: GridMember[] = [
  { name: 'Variant=normal, Tone=neutral', width: 464, height: 251 },
  { name: 'Variant=compact, Tone=neutral', width: 432, height: 240 },
  { name: 'Variant=normal, Tone=failure', width: 464, height: 251 },
  { name: 'Variant=compact, Tone=failure', width: 432, height: 240 },
];
function cornerName(members: GridMember[], p: GridPlan): string {
  const top = p.placements.reduce((a, b) => (b.y < a.y || (b.y === a.y && b.x < a.x) ? b : a));
  return members[top.index].name;
}
check('without a lead the shorter row takes the corner', () => {
  assertEq(cornerName(kEmptyState, plan(kEmptyState)), 'Variant=compact, Tone=neutral', 'corner');
});
check('the lead takes the corner even when its row is the taller one', () => {
  // Only the axis the code states a default for — the other keeps its order.
  const p = planAxisGrid(kEmptyState, undefined, { Variant: 'normal' });
  assert(p !== null, 'no plan');
  assertEq(cornerName(kEmptyState, p!), 'Variant=normal, Tone=neutral', 'corner');
  const bs = boxes(kEmptyState, p!);
  assertNoOverlap(bs);
  assertInside(bs, p!);
});
check('a lead deep in a banded set still lands in the corner, without overlap', () => {
  const members = buttonMembers();
  const p = planAxisGrid(members, undefined, {
    Variant: 'secondary',
    Size: 'md',
    State: 'hover',
    Shape: 'rectangle',
  });
  assert(p !== null, 'no plan');
  assertEq(
    cornerName(members, p!),
    'Variant=secondary, Size=md, State=hover, Shape=rectangle',
    'corner',
  );
  const bs = boxes(members, p!);
  assertNoOverlap(bs);
  assertInside(bs, p!);
});
check('a lead value the set does not hold changes nothing', () => {
  const members = buttonMembers();
  assertEq(
    JSON.stringify(planAxisGrid(members, undefined, { Variant: 'nope' })),
    JSON.stringify(plan(members)),
    'plan',
  );
});

// ─── Regression trap ────────────────────────────────────────────────────────
// A plan that placed two members on one spot would still "look" fine at the
// role level. Inject that failure and make sure the overlap check sees it —
// a check that cannot fail is not a check.

console.log('the overlap check itself can fail');
check('two boxes on one spot are reported', () => {
  let threw = false;
  try {
    assertNoOverlap([
      { index: 0, x: 24, y: 24, w: 10, h: 10 },
      { index: 1, x: 28, y: 28, w: 10, h: 10 },
    ]);
  } catch {
    threw = true;
  }
  assert(threw, 'overlap went unreported');
});

if (failures > 0) {
  console.error(`\n${failures} failure(s).`);
  process.exit(1);
}
console.log('\nall set-grid checks passed.');
