/// <reference types="@figma/plugin-typings" />

// A drop shadow's EFFECT STYLE, linked rather than copied.
//
// `setShadow` writes a shadow's layers straight onto the node. That draws the
// right picture in any document, and it leaves the node holding a value the
// document ALSO names: the file keeps one effect style per step of the shadow
// scale (`shadow/xs` … `shadow/3xl`, `shadow/inset`), and a designer's own
// component wears the style, not a copy of its numbers. The two look identical
// until the style is edited — then the designer's component follows and the
// generated one stays on the old shadow, and nothing on the canvas says why.
//
// The link is made by VALUE. The export states a shadow's layers and not the
// scale step that produced them, so there is no style name to look up — what
// can be asked is whether the document has a `shadow/<step>` style that states
// exactly these layers. When it does, the node is pointed at it; when it does
// not (a document without the styles, or a step the styles do not carry), the
// node keeps the direct value `setShadow` already wrote and the miss is listed
// for the build summary. This module never creates a style: the styles belong
// to the document, and a second source for them would be one more thing to
// disagree with the designer's.

import type { ShadowData } from './paint';

/** Styles of the shadow scale are named `shadow/<step>`. */
const kStylePrefix = 'shadow/';

/**
 * Geometry and alpha are compared to this. A style stores 32-bit floats — `0.04`
 * reads back as `0.03999999910593033` — so equality would never match a value the
 * export wrote as a double.
 */
const kTolerance = 1e-3;

const near = (a: number, b: number): boolean => Math.abs(a - b) <= kTolerance;

function statesLayers(all: readonly Effect[], shadow: ShadowData): boolean {
  // A style the Import has bound carries a mirror layer after each cast — the
  // twin a mirroring surface style throws, drawn at zero alpha everywhere else
  // (`bindShadowStyles`). It is not a layer the export states, and no authored
  // layer is transparent, so a transparent drop shadow is set aside here.
  const effects = all.filter(
    (e) => !(e.type === 'DROP_SHADOW' && e.visible !== false && e.color.a <= kTolerance),
  );
  if (effects.length !== shadow.layers.length) return false;
  return shadow.layers.every((layer, i) => {
    const e = effects[i];
    if (e.type !== 'DROP_SHADOW' && e.type !== 'INNER_SHADOW') return false;
    if ((e.type === 'INNER_SHADOW') !== layer.inset) return false;
    if (e.visible === false) return false;
    // Every step of the scale is black at the layer's own alpha — the colour is
    // not part of what the export states, and `setShadow` paints black. A style
    // with a tint is a different shadow.
    if (!near(e.color.r, 0) || !near(e.color.g, 0) || !near(e.color.b, 0)) return false;
    return (
      near(e.offset.x, layer.x) &&
      near(e.offset.y, layer.y) &&
      near(e.radius, layer.blur) &&
      near(e.spread ?? 0, layer.spread) &&
      near(e.color.a, layer.opacity)
    );
  });
}

/**
 * The `shadow/<step>` style that states exactly `shadow`'s layers, in order — or
 * `undefined`. Two styles stating the same layers resolve to the first by name,
 * so the answer does not depend on the order the document lists them in.
 */
export function shadowStyleFor(
  shadow: ShadowData,
  styles: readonly EffectStyle[],
): EffectStyle | undefined {
  if (shadow.layers.length === 0) return undefined;
  return styles
    .filter((s) => s.name.startsWith(kStylePrefix))
    .sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0))
    .find((s) => statesLayers(s.effects, shadow));
}

/** One line per shadow left as a direct value, for the build summary. */
const unlinked: string[] = [];

/**
 * What `linkShadowStyle` could not link since the last drain. `generate.ts` drains
 * it per entry and prints the lines beside the component that owns them — a link
 * that quietly did not happen is the same invisible state as no link at all.
 */
export function drainUnlinkedShadows(): string[] {
  return unlinked.splice(0, unlinked.length);
}

function describe(shadow: ShadowData): string {
  return shadow.layers
    .map(
      (l) =>
        `${l.inset ? 'inset ' : ''}${l.x} ${l.y} ${l.blur} ${l.spread} @${l.opacity}`,
    )
    .join(' · ');
}

/**
 * Points `node` at the `shadow/<step>` style that states `shadow`. `node` already
 * carries the direct value (`setShadow`) — this replaces what it draws with the
 * style's own, which is the same layers, and keeps it following the style.
 *
 * Returns whether the link was made. A shadow with no layers has nothing to link
 * and is not a miss.
 *
 * A read or a write that throws is a miss too, and carries the error: the node
 * already draws the right shadow, so a style the document cannot hand over costs
 * the link and not the component. Letting it throw would leave the entry half
 * drawn for a picture that was already correct.
 */
export async function linkShadowStyle(
  node: SceneNode & BlendMixin,
  shadow: ShadowData | null | undefined,
  what: string,
): Promise<boolean> {
  if (shadow == null || shadow.layers.length === 0) return false;
  try {
    const style = shadowStyleFor(shadow, await figma.getLocalEffectStylesAsync());
    if (style == null) {
      unlinked.push(`${what} (${describe(shadow)})`);
      return false;
    }
    await node.setEffectStyleIdAsync(style.id);
    return true;
  } catch (err) {
    unlinked.push(`${what} (${describe(shadow)}) — ${String(err)}`);
    return false;
  }
}
