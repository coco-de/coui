/// <reference types="@figma/plugin-typings" />

import {
  Color,
  Dim,
  argbAlpha,
  argbToRgb,
  colorData,
  dimVal,
  semanticNameOf,
} from './compat/v1';
import { bindRadiusN } from './box';
import { VarLookup } from './variables';
import { ownStrokeInsets } from './surface-layers';

// Paint: fills, strokes, shadows, and the tint layer.
//
// Every colour a builder draws lands here, and lands BOUND to a Figma Variable
// wherever the value came from a token. `solid` binds opaque tokens; translucent
// containers can use a composed COLOR alias through `fillComposedColor`, while
// the older builders retain their separate tint layers.
//
// Split out of `helpers.ts` (see the barrel note there).

export interface ColorData {
  color: string | null;
  opacity?: number;
  argb?: number;
}
// ─── Gradients ───────────────────────────────────────────────────────────────
//
// `CoreGradient` as the exporter emits it (`FieldKind.gradient`): `{type,
// colors, stops, begin, end}`, colours as ordinary `Color` leaves, stops always
// explicit, `begin` / `end` present for a linear gradient only. A radial one is
// centred on its box and runs to the nearest side, which is what Flutter's
// `RadialGradient(radius: 0.5)` and CSS `closest-side` draw and what Figma's
// identity transform draws.
//
// A gradient is a PAINT, and each of its stops can ride a variable on its own:
// `ColorStop.boundVariables.color`. A stop that states a token (`ref`) is bound to
// that Semantic variable and keeps the token's Light value as its literal colour,
// the way a bound solid paint keeps one beneath its binding; a stop with no `ref`
// is a literal and stays one. A bound colour supplies its own alpha, so a token
// stop below full strength has nothing to bind and `gradientPaint` refuses it
// instead of painting a hex where the design system put a token.
export interface GradientData {
  /** `linear` or `radial`, as `CoreGradientType` names them. */
  type: string;
  colors: readonly { ref: string | null; argb: number; opacity: number }[];
  stops: readonly number[];
  begin?: { x: number; y: number };
  end?: { x: number; y: number };
}

/**
 * `CoreAlignment`'s four edge-centre anchors, in the `-1..1` space (y down) the
 * exporter writes `begin` / `end` in. Named because a caller that RE-POINTS a
 * stated gradient (a button's gloss is authored top to bottom and laid along
 * whichever edge the button sits on) needs the same anchors Core points it with.
 */
export const kGradientAnchor = {
  topCenter: { x: 0, y: -1 },
  bottomCenter: { x: 0, y: 1 },
  centerStart: { x: -1, y: 0 },
  centerEnd: { x: 1, y: 0 },
} as const;

// `CoreAlignment` (-1..1) → the node-normalised 0..1 space Figma's gradient
// transform reads.
function unitPoint(a: { x: number; y: number }): { x: number; y: number } {
  return { x: (a.x + 1) / 2, y: (a.y + 1) / 2 };
}

/**
 * The `gradientTransform` of a linear gradient running from `begin` to `end`.
 *
 * Figma's transform maps a point of the node (0..1 on each axis) INTO gradient
 * space, where the ramp runs along x from 0 to 1. So x is the projection of the
 * point onto the begin → end line and y is the perpendicular (it only has to
 * keep the matrix invertible). Checked against the canvas: top → bottom comes
 * out as `[[0,1,0],[-1,0,1]]`, the matrix the designer's body gradient carries,
 * and left → right as the identity.
 */
export function linearGradientTransform(
  begin: { x: number; y: number },
  end: { x: number; y: number },
): Transform {
  const b = unitPoint(begin);
  const e = unitPoint(end);
  const dx = e.x - b.x;
  const dy = e.y - b.y;
  const span = dx * dx + dy * dy;
  if (span === 0) {
    throw new Error('gradientPaint: a linear gradient needs a begin and an end that differ.');
  }
  // The two row offsets, written out: x = ((p - b) . d) / |d|^2 and the
  // perpendicular y = ((p - b) x d) / |d|^2 + 1/2.
  return [
    [dx / span, dy / span, -(b.x * dx + b.y * dy) / span],
    [-dy / span, dx / span, (b.x * dy - b.y * dx) / span + 1 / 2],
  ];
}

// A radial gradient is centred on `begin` (Core states `center`, the box's
// middle) and reaches the node's nearest side at stop 1.
function radialGradientTransform(centre: { x: number; y: number }): Transform {
  const c = unitPoint(centre);
  return [
    [1, 0, 1 / 2 - c.x],
    [0, 1, 1 / 2 - c.y],
  ];
}

/**
 * A `CoreGradient` as a Figma paint. `opacity` is the PAINT's — a stroke whose
 * whole ramp is laid at half strength (`rimGlowOpacity`) — and is separate from
 * every stop's own alpha.
 *
 * `lk` is what binds a token stop: a stop that states a `ref` reaches its
 * Semantic variable through `lk.sem` (the route a solid paint takes), and the
 * stop's `boundVariables.color` is the alias of it. Without `lk` a token stop has
 * nothing to bind to and the call throws — a gradient with no token stops needs
 * none.
 */
export function gradientPaint(
  g: GradientData,
  opts: { opacity?: number | Dim; lk?: VarLookup } = {},
): GradientPaint {
  if (g.colors.length < 2) {
    throw new Error(
      `gradientPaint: ${g.colors.length} stop(s) — a ramp needs at least two. A single ` +
        'colour belongs in `fills` as a SolidPaint.',
    );
  }
  if (g.stops.length !== g.colors.length) {
    throw new Error(
      `gradientPaint: ${g.colors.length} colours against ${g.stops.length} stops — the ` +
        'exporter always states both, so a mismatch is a malformed leaf.',
    );
  }
  const gradientStops: ColorStop[] = [];
  for (let i = 0; i < g.colors.length; i++) {
    const c = g.colors[i];
    const color = Object.assign({}, argbToRgb(c.argb), { a: argbAlpha(c.argb, c.opacity) });
    if (c.ref == null) {
      gradientStops.push({ position: g.stops[i], color: color });
      continue;
    }
    if (opts.lk == null) {
      throw new Error(
        `gradientPaint: stop ${i} states the token "${c.ref}" and no VarLookup was passed ` +
          'to bind it. Painting its hex instead would put a literal where the design system ' +
          'put a token — pass `{ lk }`.',
      );
    }
    if (color.a < 1) {
      throw new Error(
        `gradientPaint: stop ${i} states the token "${c.ref}" at alpha ${color.a}. A bound ` +
          'colour supplies its own alpha, so the binding would paint the stop at full ' +
          'strength. A stop that is meant to fade states a literal (no `ref`).',
      );
    }
    gradientStops.push({
      position: g.stops[i],
      // The token's Light value (the leaf's argb, Core's resolution under the
      // default mapping): the colour the stop reads where its binding cannot
      // resolve (a consumer outside the collection's modes, a detached copy).
      color: color,
      boundVariables: {
        color: figma.variables.createVariableAlias(opts.lk.sem(semanticNameOf(c.ref))),
      },
    });
  }
  let transform: Transform;
  let type: GradientPaint['type'];
  if (g.type === 'linear') {
    if (g.begin == null || g.end == null) {
      throw new Error('gradientPaint: a linear gradient states a begin and an end.');
    }
    type = 'GRADIENT_LINEAR';
    transform = linearGradientTransform(g.begin, g.end);
  } else if (g.type === 'radial') {
    type = 'GRADIENT_RADIAL';
    transform = radialGradientTransform(g.begin ?? { x: 0, y: 0 });
  } else {
    throw new Error(`gradientPaint: unknown gradient type "${g.type}" (linear and radial are drawn).`);
  }
  return {
    type,
    gradientTransform: transform,
    gradientStops,
    visible: true,
    opacity: opts.opacity == null ? 1 : dimVal(opts.opacity),
    blendMode: 'NORMAL',
  };
}

/**
 * A solid paint written as a literal — the raw-colour branch `fillData` takes,
 * for a caller that composes a fill LIST (a hardware part's three layers) and so
 * cannot hand the node to `fillData`, which replaces the whole list.
 */
export function literalPaint(cd: ColorData): SolidPaint {
  if (cd.argb == null) {
    throw new Error('literalPaint: a literal paint needs the colour\'s argb.');
  }
  return { type: 'SOLID', color: argbToRgb(cd.argb), opacity: argbAlpha(cd.argb, cd.opacity) };
}

/**
 * A colour leaf as a SOLID paint whose opacity is the PAINT's — a bound token
 * drawn at a stated strength (a token at 90%, say) rather than a node faded to
 * it.
 *
 * Lives beside `solid` and not inside it because `solid` refuses a sub-1 opacity
 * on purpose: a caller that reaches for it with a translucent token is usually
 * about to ship a saturated block, and the two routes it names (`fadeNode`,
 * `tintLayer`) are right for them. This is the third route, for a part that has
 * to keep BOTH the binding and the paint's own opacity — a hardware highlight a
 * designer states as "this token, at N%" on the paint, with the node at full
 * strength. The paint carries its opacity only once `assignPaints` has put it on
 * the node and read it back (the write resets it — see there), so a caller hands
 * the result to `assignPaints`, never to `node.fills` directly.
 *
 * A leaf with no token is a literal paint: its alpha is the colour's own.
 */
export function colorPaint(lk: VarLookup, cd: ColorData, consumer?: SceneNode): SolidPaint {
  if (cd.color == null) return literalPaint(cd);
  return Object.assign({}, solid(lk.sem(cd.color), 1, consumer), {
    opacity: cd.opacity == null ? 1 : cd.opacity,
  }) as SolidPaint;
}

// Plugin data on a node whose bound paint states a strength on purpose. The
// fidelity readback refuses a bound paint below full strength — the shape every
// forgotten-alpha tint had — and reads this to tell a strength written on purpose
// (`assignPaints`) from one that was meant to be a layer and never became one.
export const kPaintStrengthKey = 'coui-paint-strength';

/**
 * Marks a text node whose ink is the composed child's, drawn here only because
 * an instance's inner text cannot take a component property (`NumberInput`'s
 * `Value`). The component's own data does not state that ink, so the fill-alpha
 * readback has nothing to compare it with — and another token stated at a
 * strength (a button's dashed border at 30%) would read as a disagreement.
 */
export const kAmbientInkKey = 'coui-ambient-ink';

// What `assignPaints` could not make a node keep, as `<node> <field>[<index>]`, and
// a layer whose bound opacity does not read back as the strength it was bound for
// (`bindLayerOpacity`), as `<node> opacity`. Drained per entry by `generate.ts`, the
// way a skipped pin is: a write that Figma takes without complaint and then does not
// hold is invisible on the canvas until a designer compares the strength, so the
// build log is where it has to surface.
export const paintOpacityNotHeld: string[] = [];

const kPaintOpacityTolerance = 1e-3;

/**
 * Writes `paints` to a node's `fills` or `strokes` and makes the opacity stick.
 *
 * A paint made by `setBoundVariableForPaint` comes out of the node's setter at
 * opacity 100% and blend mode NORMAL, whatever the paint asked for — the write
 * resets both. What survives is a value set on the paint READ BACK from the node,
 * so this writes, reads, re-states the opacity and blend mode that differ, and
 * writes again. A write that is already faithful (a literal paint, a gradient, a
 * bound paint at full strength) reads back equal and costs no second write.
 *
 * That account is the designer's, from the MockupDevice canvas, and the selftest
 * doubles model it; that the platform holds the overwrite on every paint kind is
 * the one thing a run in Figma settles, which is why the result is read again
 * below and a miss is logged.
 *
 * The result is read once more. A node that still does not hold what was asked is
 * recorded in `paintOpacityNotHeld` rather than thrown over: the picture is wrong
 * by a few percent of strength on one layer, against a component left half-drawn
 * if the entry failed.
 *
 * A bound paint stated below full strength marks its node (`kPaintStrengthKey`),
 * so the fidelity readback judges that strength against the alphas the component
 * states instead of refusing every bound paint under 100%.
 */
export function assignPaints(
  node: SceneNode & MinimalFillsMixin & MinimalStrokesMixin,
  field: 'fills' | 'strokes',
  paints: readonly Paint[],
): void {
  // A bound solid below full strength is the shape the marker exists for.
  const statesStrength = paints.some(
    (p) => p.type === 'SOLID' && p.boundVariables?.color != null && (p.opacity == null ? 1 : p.opacity) < 1,
  );
  if (statesStrength) node.setPluginData(kPaintStrengthKey, '1');
  node[field] = paints.slice();
  const held = (stored: unknown): boolean[] | null => {
    if (!Array.isArray(stored)) return null;
    return paints.map((asked, i) => {
      const got = (stored as readonly Paint[])[i];
      if (got == null) return false;
      return (
        Math.abs((got.opacity == null ? 1 : got.opacity) - (asked.opacity == null ? 1 : asked.opacity)) <=
          kPaintOpacityTolerance &&
        (got.blendMode == null ? 'NORMAL' : got.blendMode) ===
          (asked.blendMode == null ? 'NORMAL' : asked.blendMode)
      );
    });
  };
  const first = held(node[field]);
  if (first == null || first.every((ok) => ok)) return;
  const stored = node[field] as readonly Paint[];
  node[field] = stored.map((got, i) =>
    first[i]
      ? got
      : (Object.assign({}, got, {
          opacity: paints[i].opacity == null ? 1 : paints[i].opacity,
          blendMode: paints[i].blendMode == null ? 'NORMAL' : paints[i].blendMode,
        }) as Paint),
  );
  const second = held(node[field]);
  if (second == null) return;
  second.forEach((ok, i) => {
    if (!ok) paintOpacityNotHeld.push(`${node.name} ${field}[${i}]`);
  });
}

/**
 * `fillData` for a fill whose opacity is the PAINT's (`colorPaint`): the node is
 * left at full strength and the paint carries the strength. For a childless part —
 * a highlight, a glint — where the two draw the same pixels and the designer's
 * canvas states the paint.
 */
export function fillDataOnPaint(
  node: SceneNode & MinimalFillsMixin & MinimalStrokesMixin,
  lk: VarLookup,
  cd: ColorData | null | undefined,
): void {
  if (!cd || (cd.color == null && cd.argb == null)) {
    node.fills = [];
    return;
  }
  assignPaints(node, 'fills', [colorPaint(lk, cd, node)]);
}

/**
 * `fillData` for a childless part whose strength is the NODE's, kept readable as
 * the token that states it.
 *
 * The fill is the token at full strength and the node's opacity carries the
 * alpha (`fadeNode` — the route `paintTokenFill` already takes for a node that
 * holds nothing). What this adds is the last step: the opacity is bound to the
 * `Primitives/opacity/<n>` step that holds the strength, so the layer reads
 * "this colour, at `opacity/50`" instead of "this colour, at 0.5". A literal
 * renders the same pixels and puts a number where the design system put a
 * token — the bypass `solid` refuses for the paint, and this refuses for the
 * node. A strength with no step on the scale (88%) keeps the literal: there is
 * nothing to bind, and a throw would leave half a component behind.
 *
 * It also says the strength OUT LOUD in the other direction. A part that sits
 * inside an instance inherits whatever opacity — bound or not — its main
 * component gave it, and `fadeNode` only ever lowers it. A composing parent that
 * forwards an opaque colour to a child whose default is translucent would
 * therefore still draw the child's default strength; stating 100% here removes
 * the inherited opacity and its binding.
 *
 * Not for a node that can hold children: node opacity dims every descendant,
 * which is the whole reason `tintLayer` exists. That is `fillData`'s call.
 */
export function fillDataOnNode(
  node: SceneNode & MinimalFillsMixin & BlendMixin,
  lk: VarLookup,
  cd: ColorData | null | undefined,
): void {
  if (canHoldChildren(node)) {
    throw new Error(
      `fillDataOnNode: "${node.name}" can hold children, and node opacity would fade them ` +
        'along with the fill. Use `fillData` (a tint layer) for a container.',
    );
  }
  fillData(node, lk, cd);
  // A literal colour states its alpha on the paint (`fillData` wrote it there);
  // only a token carries its strength as a separate number, and that is the
  // number that belongs on the node.
  const alpha = cd != null && cd.color != null && cd.opacity != null ? cd.opacity : 1;
  if (alpha < 1) {
    // A strength that is a rung binds to it, and `bindLayerOpacity` also reads the
    // node back to see it kept the number the binding drove it to. One between two
    // rungs has nothing to bind, so the node states it as a literal.
    if (lk.opacityOrNull(alpha) !== undefined) bindLayerOpacity(node, lk, alpha);
    else fadeNode(node, alpha);
    return;
  }
  if (node.boundVariables?.opacity != null) node.setBoundVariable('opacity', null);
  node.opacity = 1;
}

export function fadeNode(node: { opacity: number }, alpha: number | Dim): void {
  const a = dimVal(alpha);
  if (a >= 1) return;
  node.opacity = a;
}

/**
 * `fadeNode` for a strength a Core field states as an opacity TOKEN: the layer's
 * opacity is BOUND to `Primitives/opacity/<pct>`, so the right panel reads the
 * token instead of a number that happens to equal it.
 *
 * The node takes the Core alpha (0–1) before the binding and never after: the
 * `opacity/*` variables hold the percent, and Figma resolves a bound opacity to
 * percent ÷ 100 on its own. That the layer then reads back at the asked alpha is
 * the one thing this cannot establish from the code, so the result is read and a
 * miss goes to `paintOpacityNotHeld` — the same per-entry report a paint that
 * does not hold its strength uses — instead of leaving a layer at a silent 0.7%.
 */
export function bindLayerOpacity(
  node: SceneNode & MinimalBlendMixin,
  lk: VarLookup,
  alpha: number | Dim,
): void {
  const a = dimVal(alpha);
  if (a >= 1) return;
  // Resolved first: a step the ladder lacks must throw before anything is half-written.
  const variable = lk.opacity(a);
  node.opacity = a;
  node.setBoundVariable('opacity', variable);
  const held = node.opacity;
  if (typeof held !== 'number' || Math.abs(held - a) > kPaintOpacityTolerance) {
    paintOpacityNotHeld.push(`${node.name} opacity`);
  }
}

export function tintLayer(
  host: FrameNode | ComponentNode,
  lk: VarLookup,
  cd: ColorData,
  o: { radius?: number | Dim; stroke?: number | Dim; strength?: number | Dim } = {},
): RectangleNode {
  const tint = figma.createRectangle();
  // Named for what it is, so a designer selecting it reads why a second layer is
  // there rather than "rectangle 12".
  tint.name = o.stroke == null ? 'tint' : 'tint border';
  // Bound at full strength — the alpha is the LAYER's, below.
  if (o.stroke == null) {
    tint.fills = [solid(lk.sem(cd.color!), 1, tint)];
  } else {
    tint.fills = [];
    tint.strokes = [solid(lk.sem(cd.color!), 1, tint)];
    tint.setBoundVariable('strokeWeight', lk.stroke(dimVal(o.stroke)));
  }
  if (o.radius != null) bindRadiusN(tint, lk, o.radius);
  tint.resize(Math.max(host.width, 0.01), Math.max(host.height, 0.01));
  host.insertChild(0, tint);
  pinInFlow(host, tint);
  tint.x = 0;
  tint.y = 0;
  fadeNode(tint, cd.opacity == null ? 1 : cd.opacity);
  if (o.strength != null) bindLayerOpacity(tint, lk, o.strength);
  // Sized at the END of the build, not here. A container is painted before its
  // content exists — `applyChrome` runs while the frame is still its padding — so a
  // size measured now is a size the frame has already outgrown by the time anyone
  // looks. `STRETCH` constraints were supposed to carry it and did not: the first
  // canvas run drew every Banner tint short of the right and bottom edges by about
  // its padding.
  //
  // Deferred instead of predicted, because the number that is right is the one the
  // frame settles at. `x`/`y` stay 0: an absolutely positioned child measures from
  // the FRAME's origin, not from inside its padding (plugin-api.d.ts's own example
  // puts a 20px circle at x=90 on the top-RIGHT corner of a 100px frame).
  pendingTints.push({ tint: tint, host: host });
  return tint;
}

const pendingTints: { tint: RectangleNode; host: FrameNode | ComponentNode }[] = [];

export function flushTintLayers(): void {
  for (const p of pendingTints.splice(0)) {
    p.tint.resize(Math.max(p.host.width, 0.01), Math.max(p.host.height, 0.01));
    p.tint.x = 0;
    p.tint.y = 0;
    // Set after the size, so the insets Figma records are the zeroes it should keep.
    p.tint.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
  }
  for (const p of pendingMaterialLayers.splice(0)) {
    // Back to the bottom of the stack first: a builder that wrote a translucent
    // border after the material put its `tint border` layer at index 0, under
    // the fill — and a stroke is painted over a fill, never under it.
    let at = 0;
    const inset = ownStrokeInsets(p.host);
    for (const layer of p.layers) {
      if (layer.parent !== p.host) continue;
      p.host.insertChild(at, layer);
      at += 1;
      // Pinned again after the move: a pin made before a later insertion does
      // not hold the final placement (see the MockupBrowser toolbar).
      pinInFlow(p.host, layer);
      // Inside the host's own stroke, not under it: a frame paints its stroke
      // over its own fill but UNDER its children, so a layer that covers the
      // whole box hides the border the surface node carries. Measured on an
      // outline Button: the pixel on the box's edge read the surface fill, the
      // designer's copy (fill and stroke on one node) read the border colour.
      layer.resize(
        Math.max(p.host.width - inset.left - inset.right, 0.01),
        Math.max(p.host.height - inset.top - inset.bottom, 0.01),
      );
      layer.x = inset.left;
      layer.y = inset.top;
      // Set after the size and the offset, so the insets Figma records are the
      // stroke's, which a resize of the host must keep.
      layer.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
      insetLayerCorners(layer, inset);
    }
  }
}

type LayerCorner = 'topLeftRadius' | 'topRightRadius' | 'bottomLeftRadius' | 'bottomRightRadius';

/**
 * Pulls [layer]'s corners in by the stroke reach [inset], so a layer seated
 * inside its host's stroke shares the stroke's inner edge instead of keeping the
 * host's outer radius one stroke in. Kept at the outer radius, the layer leaves a
 * sliver at each corner and a seam along each edge where the border shows the
 * page through — a border the colour of the fill (a light subtle Tag) reads as a
 * ring floating off its chip. Web and Flutter paint border and fill on one box,
 * so neither has the gap.
 *
 * The corner is the radius the layer already rounds to (bound to the surface's
 * step, or its literal) less the larger of the two strokes that meet there. The
 * result is a literal: no variable states the radius less a stroke, so a bordered
 * surface's layer corners stay at the mode the file is in — the same reach its
 * offset already has. A corner no stroke reaches keeps its binding.
 *
 * Call after the layer has been rounded like its surface; idempotent only in that
 * order, which is the one every caller keeps (round, then pull in).
 */
export function insetLayerCorners(
  layer: RectangleNode,
  inset: { readonly top: number; readonly right: number; readonly bottom: number; readonly left: number },
): void {
  const corners: [LayerCorner, number][] = [
    ['topLeftRadius', Math.max(inset.top, inset.left)],
    ['topRightRadius', Math.max(inset.top, inset.right)],
    ['bottomLeftRadius', Math.max(inset.bottom, inset.left)],
    ['bottomRightRadius', Math.max(inset.bottom, inset.right)],
  ];
  for (const [field, reach] of corners) {
    if (reach <= 0) continue;
    const outer = layer[field];
    if (typeof outer !== 'number') continue;
    layer.setBoundVariable(field, null);
    layer[field] = Math.max(outer - reach, 0);
  }
}

// The layers `applySurfaceMaterial` (surface-material.ts) put behind a surface's
// content — sized, like a tint, once the host has settled at the end of the entry,
// and put back at the bottom of the host in their own order.
const pendingMaterialLayers: {
  host: FrameNode | ComponentNode;
  layers: RectangleNode[];
}[] = [];

/** Defers sizing [layers] to [host] until `flushTintLayers` — see there. */
export function deferMaterialLayers(
  host: FrameNode | ComponentNode,
  layers: RectangleNode[],
): void {
  const queued = pendingMaterialLayers.find((p) => p.host === host);
  if (queued != null) queued.layers = layers;
  else pendingMaterialLayers.push({ host: host, layers: layers });
}

export function solid(
  colorVar: Variable,
  opacity = 1,
  consumer?: SceneNode,
): SolidPaint {
  // MEASURED, not inferred. A one-off probe wrote exactly this shape — a paint bound
  // to `Semantic/color/info` asking `opacity: 0.1` — and read back what Figma stored:
  //
  //   opacity=1, colour still bound=true
  //
  // So the binding overwrites the paint's alpha with the variable's own (1). The
  // typings settle the other half: `VariableBindablePaintField` is `'color'` and
  // nothing else, so a paint's alpha can never be a Variable either — it is a plain
  // number, and a plain number next to a bound colour is discarded.
  //
  // Below alpha 1 the paint CANNOT be bound. A bound `color` supplies the whole
  // RGBA and its alpha (1) replaces whatever the paint asked for — so the paint
  // object reads 0.1 and the canvas renders solid. `setShadow` has known this since
  // it was written ("a bound `color` overwrites `a`, so binding a sub-1 alpha is
  // how a 6% shadow becomes a solid one") and gated its own binding on `>= 1`;
  // paints did not, and every tint stated as a token below full strength shipped
  // saturated. `Banner` and `Alert`'s four toned variants are 0.1 backgrounds that
  // came out as blocks — and since both draw their text in the SAME token, the
  // words vanished into the block. `CodeDiff`'s row tints are the same bug.
  //
  // There is no literal escape hatch, deliberately. A literal renders the right
  // pixels and puts a HEX where the design system put a token — the exact bypass
  // this pipeline exists to remove, and the first thing a designer notices when
  // they open the fill. So the alpha moves to a layer instead and the paint keeps
  // its Variable.
  if (opacity < 1) {
    {
      // Loud, because the quiet version is a saturated block that reads as a
      // design choice. A caller asking for a sub-1 alpha without the literal to
      // paint it with has two honest answers and this function cannot pick:
      // pass the token's `argb` (the colour is what is transparent — what Core
      // states when the alpha lives inside a colour leaf), or set `node.opacity`
      // (the ELEMENT is faded — right only where the node has no children that
      // must stay full strength, since node opacity dims every descendant).
      throw new Error(
        `solid: alpha ${opacity} on "${colorVar.name}" cannot be painted here. A ` +
          'bound colour supplies its own alpha and overwrites the paint\'s, so this ' +
          'would render at full strength. Two routes keep the TOKEN and render the ' +
          'alpha: `fadeNode(node, alpha)` when the node has no children (a rect, a ' +
          'dot, a track — node opacity on a bound fill is exactly "this colour at ' +
          'N%"), or `tintLayer(host, lk, cd, radius)` when it does (its own pinned ' +
          'layer behind the content, so the words above it stay full strength). A ' +
          'literal RGB would render correctly and put a hex where the design system ' +
          'put a token — which is the bypass this pipeline exists to remove.',
      );
    }
  }
  // The RESOLVED value goes into the paint first, then the binding. A bound
  // paint renders from its variable, so the literal underneath it is
  // normally invisible — but where the binding cannot resolve (a consumer
  // outside the collection's modes, a headless render, a detached copy) the
  // literal is what shows, and `{0,0,0}` there is a black switch nobody
  // authored. `resolveForConsumer` asks the variable for the value it would
  // take at THIS node (mode-aware); absent a consumer, or on a double that
  // does not implement it, the placeholder stays.
  let p: SolidPaint = {
    type: 'SOLID',
    color: resolvedRgbFor(colorVar, consumer),
    opacity,
  };
  p = figma.variables.setBoundVariableForPaint(p, 'color', colorVar) as SolidPaint;
  // Object.assign (not object spread) — the Figma plugin runtime rejects `...`.
  return Object.assign({}, p, { opacity }) as SolidPaint;
}

// The colour `colorVar` resolves to at `consumer`, as the paint's own literal —
// see `solid`. `{0,0,0}` when there is nothing to ask.
function resolvedRgbFor(colorVar: Variable, consumer: SceneNode | undefined): RGB {
  const fallback: RGB = { r: 0, g: 0, b: 0 };
  if (!consumer) return fallback;
  const resolve = (colorVar as unknown as { resolveForConsumer?: unknown }).resolveForConsumer;
  if (typeof resolve !== 'function') return fallback;
  try {
    const resolved = colorVar.resolveForConsumer(consumer);
    if (resolved.resolvedType !== 'COLOR') return fallback;
    const value = resolved.value as RGBA;
    return { r: value.r, g: value.g, b: value.b };
  } catch {
    return fallback;
  }
}

export function fillSem(
  node: SceneNode & MinimalFillsMixin,
  lk: VarLookup,
  name: string,
  opacity = 1,
): void {
  paintTokenFill(node, lk, { color: name, opacity: opacity });
}

/** Native translucent fill for a container whose children stay opaque.
 * Figma discards opacity beside an opaque color binding. A composed COLOR
 * alias supplies both values and needs no tint rectangle (verified in Figma). */
export function fillComposedColor(
  node: SceneNode & MinimalFillsMixin,
  lk: VarLookup,
  cd: ColorData | null,
): void {
  if (cd?.color == null) {
    fillData(node, lk, cd);
    return;
  }
  node.fills = [composedColorPaint(lk, cd.color, cd.opacity ?? 1, node)];
}

/** A paint bound to [name] at [opacity] through a composed COLOR alias — the
 * paint `fillComposedColor` writes, for a caller that owns the fill list. */
export function composedColorPaint(
  lk: VarLookup,
  name: string,
  opacity: number,
  consumer: SceneNode,
): SolidPaint {
  const variable = lk.semWithOpacity(name, opacity);
  return figma.variables.setBoundVariableForPaint({
    type: 'SOLID', color: resolvedRgbFor(variable, consumer),
  }, 'color', variable) as SolidPaint;
}

export function setBorder(
  node: SceneNode & MinimalStrokesMixin,
  lk: VarLookup,
  name: string,
  opacity = 1,
  strokeN: number | Dim = 1,
  sides?: StrokeSides,
): void {
  borderData(
    node as SceneNode & MinimalStrokesMixin,
    lk,
    { color: name, opacity: opacity },
    strokeN,
    sides,
  );
}

export interface ShadowLayerData {
  x: number;
  y: number;
  blur: number;
  spread: number;
  opacity: number;
  inset: boolean;
}

export interface ShadowData {
  layers: ShadowLayerData[];
  /**
   * The step of the shadow scale these layers are (`md`, `2xl`, `inset`), when
   * the export could read it off the source — `CoreShadow.md` is a name there.
   * Present, it lets `setShadow` bind each layer to the `Semantic/ Surface`
   * rows a surface style bends per mode; absent (a shadow written inline, a
   * document predating the rows), the layers are drawn as the numbers they are.
   */
  step?: string;
}

export function setShadow(
  node: SceneNode & { effects: readonly Effect[] },
  sd: ShadowData | null | undefined,
  lk?: VarLookup,
  base?: ColorData | null,
): void {
  if (!sd) return;
  const semantic = base != null && base.color != null && lk != null ? lk.sem(base.color) : null;
  const rgb =
    base != null && base.color == null && base.argb != null
      ? argbToRgb(base.argb)
      : { r: 0, g: 0, b: 0 };
  const baseAlpha =
    base != null && base.color == null && base.argb != null ? argbAlpha(base.argb) : 1;
  // A cast of the shadow scale in the scale's own black follows the surface
  // style a frame pins: each layer binds to the `Semantic/ Surface` rows the
  // style bends, and each cast gets its mirror layer — present under every
  // style, drawing at zero alpha under the ones that do not mirror. "Black" is
  // what this function would paint anyway: a base token whose colour a sub-1
  // alpha cannot carry (see below) draws black too. A tinted shadow is not a
  // step of the scale in black, so it stays the numbers it is.
  const paintsBlack = rgb.r === 0 && rgb.g === 0 && rgb.b === 0 && baseAlpha === 1;
  const rows = lk != null && paintsBlack && sd.step != null ? castRows(lk, sd.step, sd.layers) : null;
  const effects: Effect[] = [];
  sd.layers.forEach((l, i) => {
    const alpha =
      l.opacity * baseAlpha * (base != null && base.opacity != null ? base.opacity : 1);
    let e: Effect = {
      type: l.inset ? 'INNER_SHADOW' : 'DROP_SHADOW',
      color: { r: rgb.r, g: rgb.g, b: rgb.b, a: alpha },
      offset: { x: l.x, y: l.y },
      radius: l.blur,
      spread: l.spread,
      visible: true,
      blendMode: 'NORMAL',
    };
    // `>= 1` and not `!= null`: see the note above. A bound `color` overwrites
    // `a`, so binding a sub-1 alpha is how a 6% shadow becomes a solid one.
    if (semantic != null && alpha >= 1) {
      e = figma.variables.setBoundVariableForEffect(e, 'color', semantic);
    }
    // A layer the semantic colour already holds at full strength is not black.
    const row = semantic != null && alpha >= 1 ? undefined : rows?.[i];
    if (row != null) e = bindCast(e, row.cast);
    effects.push(e);
    if (row?.mirror != null) {
      effects.push(
        bindCast(
          {
            type: 'DROP_SHADOW',
            color: { r: 1, g: 1, b: 1, a: 0 },
            offset: { x: 0, y: 0 },
            radius: l.blur,
            spread: l.spread,
            visible: true,
            blendMode: 'NORMAL',
          },
          row.mirror,
        ),
      );
    }
  });
  node.effects = effects;
}

/** The four rows one shadow layer binds to. */
export interface CastRow {
  x: Variable;
  y: Variable;
  blur: Variable;
  color: Variable;
}

/**
 * The `Semantic/ Surface` rows for every layer of `step`, in layer order — or
 * `null` when the document lacks any of them (imported before the rows
 * existed), so a half-bound shadow never happens: either every layer follows
 * the style or the shadow is drawn as plain numbers.
 */
function castRows(
  lk: VarLookup,
  step: string,
  layers: readonly ShadowLayerData[],
): { cast: CastRow; mirror: CastRow | null }[] | null {
  const read = (layer: string): CastRow | null => {
    const x = lk.shadowRowOrNull(step, layer, 'x');
    const y = lk.shadowRowOrNull(step, layer, 'y');
    const blur = lk.shadowRowOrNull(step, layer, 'blur');
    const color = lk.shadowRowOrNull(step, layer, 'color');
    return x && y && blur && color ? { x, y, blur, color } : null;
  };
  const out: { cast: CastRow; mirror: CastRow | null }[] = [];
  for (let i = 0; i < layers.length; i++) {
    const cast = read(`${i}`);
    if (cast == null) return null;
    let mirror: CastRow | null = null;
    if (!layers[i].inset) {
      mirror = read(`${i}-mirror`);
      if (mirror == null) return null;
    }
    out.push({ cast, mirror });
  }
  return out;
}

/** [e] with its offset, blur and colour bound to [row]. */
export function bindCast(e: Effect, row: CastRow): Effect {
  let bound = figma.variables.setBoundVariableForEffect(e, 'offsetX', row.x);
  bound = figma.variables.setBoundVariableForEffect(bound, 'offsetY', row.y);
  bound = figma.variables.setBoundVariableForEffect(bound, 'radius', row.blur);
  return figma.variables.setBoundVariableForEffect(bound, 'color', row.color);
}

function canHoldChildren(node: SceneNode): boolean {
  return node.type === 'FRAME' || node.type === 'COMPONENT' || node.type === 'INSTANCE';
}

/**
 * `strength` names the opacity token the caller already folded into `cd.opacity`
 * (a skeleton's pulse start): it is provenance for the binding, not a second
 * multiplication, so the layer's opacity is bound to `Primitives/opacity/<pct>`
 * instead of written as a bare number. One layer holds one alpha, so a colour
 * that carries a different alpha than the token throws rather than drawing a
 * strength the token does not state.
 */
export function paintTokenFill(
  node: SceneNode & MinimalFillsMixin,
  lk: VarLookup,
  cd: ColorData,
  strength?: number | Dim,
): void {
  const alpha = cd.opacity == null ? 1 : cd.opacity;
  if (strength != null && Math.abs(alpha - dimVal(strength)) > kPaintOpacityTolerance) {
    throw new Error(
      `paintTokenFill: strength ${dimVal(strength)} is the token ${node.name} binds its opacity to, ` +
        `but the colour carries alpha ${alpha}; a layer holds ONE alpha — pass the token as the whole alpha or leave it off`,
    );
  }
  if (alpha >= 1) {
    node.fills = [solid(lk.sem(cd.color!), 1, node as SceneNode)];
    return;
  }
  // The step is looked up before any node is touched: one the ladder lacks throws
  // here with nothing drawn, not after a tint layer already exists.
  if (strength != null) lk.opacity(dimVal(strength));
  if (canHoldChildren(node as SceneNode) && !insideInstance(node as SceneNode)) {
    // The host keeps no fill of its own — the tint layer IS the fill, and keeping
    // both would paint the colour twice at two different strengths.
    node.fills = [];
    tintLayer(node as unknown as FrameNode, lk, cd, { radius: cornerOf(node), strength: strength });
    return;
  }
  node.fills = [solid(lk.sem(cd.color!), 1, node as SceneNode)];
  fadeNode(node as unknown as { opacity: number }, alpha);
  if (strength != null) bindLayerOpacity(node as unknown as SceneNode & MinimalBlendMixin, lk, strength);
}

/**
 * Which edges a stroke lands on. Omitted → all four, the only shape every
 * caller but `Banner` wants.
 *
 * A rule on one edge is not the same picture as a box: `Banner`'s `weak`
 * emphasis draws a hairline under itself and nothing on the other three
 * sides, which is what both widgets draw (`Border(bottom:)` /
 * `border-bottom-width`). Painting all four made the canvas a boxed
 * banner the code never renders.
 */
export interface StrokeSides {
  top?: boolean;
  right?: boolean;
  bottom?: boolean;
  left?: boolean;
}

/** Binds the token to the named edges and zeroes the rest. */
function applyStrokeSides(
  node: SceneNode & MinimalStrokesMixin,
  lk: VarLookup,
  strokeN: number | Dim,
  sides: StrokeSides | undefined,
): void {
  if (!sides) {
    node.setBoundVariable('strokeWeight', lk.stroke(dimVal(strokeN)));
    return;
  }
  // Per-side weights are individually bindable, so a one-edge rule keeps
  // its token provenance instead of becoming a literal.
  const wanted = lk.stroke(dimVal(strokeN));
  const edges = [
    ['strokeTopWeight', sides.top],
    ['strokeRightWeight', sides.right],
    ['strokeBottomWeight', sides.bottom],
    ['strokeLeftWeight', sides.left],
  ] as const;
  for (const [field, on] of edges) {
    if (on) {
      node.setBoundVariable(field, wanted);
    } else {
      (node as unknown as IndividualStrokesMixin)[field] = 0;
    }
  }
}

export function borderData(
  node: SceneNode & MinimalStrokesMixin,
  lk: VarLookup,
  cd: ColorData | null | undefined,
  strokeN: number | Dim = 1,
  sides?: StrokeSides,
): void {
  if (!cd || (cd.color == null && cd.argb == null)) return;
  if (cd.color == null) {
    const alpha = argbAlpha(cd.argb!, cd.opacity);
    if (alpha === 0) {
      // A transparent border is a STATEMENT — the same one `fillData` makes with
      // `fills = []`: this node draws no border. Returning here used to leave
      // whatever stroke the node already carried. On a fresh frame that is
      // nothing; on a node reached inside an instance it is the main
      // component's stroke. `FormattedInput` states `segmentInputStyle`
      // (border 0, transparent) on the composed `TextField`'s `field` row, and
      // the row kept the field's own 1px `outline-variant` under the root's
      // border — two borders on all four members (2026-09-12 parity, #4863).
      node.strokes = [];
      return;
    }
    node.strokes = [{ type: 'SOLID', color: argbToRgb(cd.argb!), opacity: alpha }];
    applyStrokeSides(node, lk, strokeN, sides);
    return;
  }
  const alpha = cd.opacity == null ? 1 : cd.opacity;
  if (alpha >= 1 || !canHoldChildren(node as SceneNode) || insideInstance(node as SceneNode)) {
    node.strokes = [solid(lk.sem(cd.color!), 1, node as SceneNode)];
    applyStrokeSides(node, lk, strokeN, sides);
    if (alpha < 1) fadeNode(node as unknown as { opacity: number }, alpha);
    return;
  }
  // A container's own stroke cannot be faded — the fade would take its contents
  // with it — so the outline becomes its own pinned layer, bound and faded there.
  tintLayer(node as unknown as FrameNode, lk, cd, {
    radius: cornerOf(node),
    stroke: strokeN,
  });
  applyStrokeSides(node, lk, strokeN, sides);
}

export function pinInFlow(
  host: { layoutMode?: string },
  node: { layoutPositioning: string; name?: string; parent?: unknown },
): void {
  if (typeof host.layoutMode !== 'string' || host.layoutMode === 'NONE') return;
  // The OTHER refusal, and it is about the ancestry rather than the parent: Figma
  // will not let a node that lives inside an instance be absolutely positioned,
  // because its layout belongs to the instance's main component. Skipping is not a
  // fallback here — an in-instance node cannot be pinned at all, so there is no
  // second-best placement being chosen, only "the pin, or a failed entry with a
  // half-drawn component left on the page".
  //
  // Recorded rather than skipped silently: `ColorPicker` and `TimePicker` failed
  // twice on this and Figma's message names the property, never the node — so
  // the node says its own name now, in the build log next to the component that
  // owns it.
  let scan = node.parent as { type?: string; parent?: unknown } | null | undefined;
  while (scan != null) {
    if (scan.type === 'INSTANCE') {
      pinsSkippedInsideInstance.push(node.name == null ? '<unnamed>' : node.name);
      return;
    }
    scan = scan.parent as { type?: string; parent?: unknown } | null | undefined;
  }
  // Guarded, and the guard is the point. Figma's refusal names the PROPERTY and
  // never the node, so a throw here fails the entry over one child's placement
  // with nothing to localize it by — and the throw is not rolled back, so a
  // half-drawn component is left on the page until the next run blanks it. That
  // is what `ColorPicker` and `TimePicker` did three runs in a row while every
  // static check said the write was legal. The scans above catch the two
  // conditions this code knows about; a condition it does not know about still
  // must not cost the whole entry.
  //
  // Degrading is the better failure here: an unpinned child sits in its parent's
  // flow instead of over it, which is visibly odd on one node, against a whole
  // component left half-finished. And it is RECORDED, so the next run names it.
  // Written directly, not inside a try/catch. Catching a throw that comes from a
  // NATIVE setter is the one thing added here that can leave this runtime's stack
  // in a state it then reports as `InternalError: stack underflow` — a VM-level
  // failure is worse than the component-level one the catch was insuring against,
  // and both conditions Figma actually refuses are ruled out above.
  node.layoutPositioning = 'ABSOLUTE';
}

export const pinsSkippedInsideInstance: string[] = [];

export function pinAbsolute(
  host: FrameNode | ComponentNode,
  node: FrameNode | InstanceNode | RectangleNode | EllipseNode | TextNode,
  x: number,
  y: number,
  constraints: Constraints,
): FrameNode | InstanceNode | RectangleNode | EllipseNode | TextNode {
  const pinned = node.type === 'INSTANCE' ? wrapForPin(node) : node;
  host.appendChild(pinned);
  pinInFlow(host, pinned);
  pinned.x = x;
  pinned.y = y;
  pinned.constraints = constraints;
  pinConstraints.set(pinned, constraints);
  return pinned;
}

// What each pin was asked to keep, by the node `pinAbsolute` returned — so
// `sizePin` can say it again once the node has the size those constraints are
// meant to hold. Weak: a pinned node that is removed takes its entry with it.
const pinConstraints = new WeakMap<object, Constraints>();

/**
 * Gives a pinned node the size its constraints will then keep it at — the call
 * a builder makes LAST, once the flow children have settled the host's bounds.
 *
 * Why this exists rather than `resize()` on the thing that was pinned: an
 * instance is pinned through a holder (`wrapForPin`), and the holder is the node
 * carrying the constraints. Sizing the instance and leaving the holder at the
 * size it was minted at — the instance's own default, `OutlinedContainer`'s
 * 162×50 — is how `Card` shipped: the surface instance read 260×137 on the
 * canvas while its holder still said 162×50, and the STRETCH the holder could
 * have carried was pinned as `MIN` anyway. A consumer setting the Card to FILL
 * across a 358 column then got a 260-wide outline under a 358-wide column of
 * text (Saem 내 교실, 2026-09-07). Both halves are fixed here: the holder is what
 * gets sized, and the instance inside follows it by FILL (set in `wrapForPin`)
 * rather than by its own `constraints`, which Figma refuses on an instance.
 *
 * The constraints are re-asserted after the size so what Figma keeps is the
 * geometry the builder settled on — the same ordering `flushTintLayers` states
 * for its tint rectangles.
 */
export function sizePin(
  pinned: FrameNode | InstanceNode | RectangleNode | EllipseNode | TextNode,
  width: number,
  height: number,
): void {
  pinned.resize(Math.max(width, 0.01), Math.max(height, 0.01));
  if (pinned.type === 'FRAME') {
    repairWrapHolder(pinned);
  }
  const asked = pinConstraints.get(pinned);
  if (asked != null) pinned.constraints = asked;
}

function insideInstance(node: SceneNode): boolean {
  // Starts at the NODE, not its parent: a host that IS an instance is an instance
  // subtree too, and a tint inserted into it is refused exactly the same way.
  let scan: BaseNode | null = node;
  while (scan != null) {
    if (scan.type === 'INSTANCE') return true;
    scan = scan.parent;
  }
  return false;
}

function cornerOf(node: unknown): number | undefined {
  const r = (node as { cornerRadius?: unknown }).cornerRadius;
  return typeof r === 'number' && r > 0 ? r : undefined;
}

function wrapForPin(instance: InstanceNode): FrameNode {
  const holder = figma.createFrame();
  holder.name = instance.name;
  holder.fills = [];
  holder.clipsContent = false;
  // An auto-layout box, not a plain one, and that is the whole reason the
  // instance inside it can follow the holder's size. A plain frame positions its
  // children by `constraints`, and `constraints` is the one property Figma refuses
  // on an instance ("This property cannot be overridden in an instance") — so an
  // instance in a plain holder is nailed to its minted size whatever the holder
  // does. `layoutSizing* = 'FILL'` is accepted on an instance, and a FILL child
  // of a FIXED auto-layout box IS the box: stretch the holder (its `constraints`,
  // or `sizePin`) and the instance stretches with it.
  //
  // Zero padding and gap, one child: the picture is the instance's, exactly as
  // the plain holder drew it.
  holder.layoutMode = 'HORIZONTAL';
  holder.primaryAxisSizingMode = 'FIXED';
  holder.counterAxisSizingMode = 'FIXED';
  // A zero dimension is illegal in Figma; an instance that has not been laid out
  // yet reports 0, and the caller resizes or fills afterwards in that case.
  holder.resize(Math.max(instance.width, 0.01), Math.max(instance.height, 0.01));
  holder.appendChild(instance);
  instance.layoutSizingHorizontal = 'FILL';
  instance.layoutSizingVertical = 'FILL';
  pinHolders.add(holder);
  return holder;
}

const pinHolders = new WeakSet<FrameNode>();

function wrapHolderInstance(holder: FrameNode): InstanceNode | null {
  const insts = holder.children.filter((c): c is InstanceNode => c.type === 'INSTANCE');
  if (insts.length !== 1) return null;
  if (holder.name !== insts[0].name) return null;
  return insts[0];
}

function repairWrapHolder(holder: FrameNode): void {
  const inst = wrapHolderInstance(holder);
  const known = pinHolders.has(holder);
  if (!known && inst == null) return;
  if (holder.layoutMode === 'NONE') {
    holder.layoutMode = 'HORIZONTAL';
    holder.primaryAxisSizingMode = 'FIXED';
    holder.counterAxisSizingMode = 'FIXED';
  }
  for (const kid of holder.children) {
    if (kid.type !== 'INSTANCE') continue;
    kid.layoutSizingHorizontal = 'FILL';
    kid.layoutSizingVertical = 'FILL';
  }
}

export function isStaleWrapHolder(holder: FrameNode): boolean {
  const inst = wrapHolderInstance(holder);
  if (inst == null) return false;
  if (holder.layoutPositioning !== 'ABSOLUTE') return false;
  return holder.layoutMode === 'NONE';
}

export function collectStaleWrapHolders(root: BaseNode): FrameNode[] {
  const out: FrameNode[] = [];
  const walk = (n: BaseNode): void => {
    if (n.type === 'FRAME' && isStaleWrapHolder(n)) out.push(n);
    if ('children' in n) {
      for (const c of (n as ChildrenMixin).children) walk(c);
    }
  };
  walk(root);
  return out;
}



/**
 * `strength` is the opacity token a caller has already folded into `cd.opacity`;
 * only a token colour has a layer to bind it on, so a literal (`argb`) colour
 * ignores it. See `paintTokenFill`.
 */
export function fillData(
  node: SceneNode & MinimalFillsMixin,
  lk: VarLookup,
  cd: ColorData | null | undefined,
  strength?: number | Dim,
): void {
  if (!cd || (cd.color == null && cd.argb == null)) {
    node.fills = [];
    return;
  }
  if (cd.color == null) {
    const alpha = argbAlpha(cd.argb!, cd.opacity);
    node.fills = alpha === 0 ? [] : [{ type: 'SOLID', color: argbToRgb(cd.argb!), opacity: alpha }];
    return;
  }
  paintTokenFill(node, lk, cd, strength);
}

export function weightStyle(fontWeight: number | null | undefined): string {
  if (fontWeight == null) return 'Regular';
  return FONT_WEIGHT_STYLES[fontWeight] ?? 'Regular';
}

const FONT_WEIGHT_STYLES: Record<number, string> = {
  100: 'Thin',
  200: 'ExtraLight',
  300: 'Light',
  400: 'Regular',
  500: 'Medium',
  600: 'SemiBold',
  700: 'Bold',
  800: 'ExtraBold',
  900: 'Black',
};
