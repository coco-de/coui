/// <reference types="@figma/plugin-typings" />

import { Color, Dim, dimVal } from './compat/v1';
import { VarLookup } from './variables';
import { mint } from './identity';
import {
  ColorData,
  borderData,
  fillSem,
  paintTokenFill,
  setBorder,
  setShadow,
  solid,
  StrokeSides,
} from './paint';
import { PadData, bindBox, bindPad, bindRadiusN, bindSize, bindSpaceField } from './box';

// The frames builders assemble out of: auto-layout wrappers, panels, chrome
// application, the indicator box.
//
// These own no domain of their own — they are the shapes that recur across 144
// builders, which is exactly why they were the last thing left in `helpers.ts` and
// the reason it read as a grab bag.
//
// Split out of `helpers.ts` (see the barrel note there).
export function indicatorBox(lk: VarLookup, radiusN: number | Dim, side: number | Dim = 16): FrameNode {
  const b = figma.createFrame();
  b.layoutMode = 'HORIZONTAL';
  b.primaryAxisAlignItems = 'CENTER';
  b.counterAxisAlignItems = 'CENTER';
  b.primaryAxisSizingMode = 'FIXED';
  b.counterAxisSizingMode = 'FIXED';
  bindRadiusN(b, lk, radiusN);
  bindSize(b, lk, side, side);
  return b;
}

export function applyFormRowChrome(c: ComponentNode, lk: VarLookup, gap: number | Dim = 8): void {
  c.layoutMode = 'HORIZONTAL';
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'AUTO';
  c.primaryAxisAlignItems = 'CENTER';
  c.counterAxisAlignItems = 'CENTER';
  bindSpaceField(c, 'itemSpacing', lk, dimVal(gap));
  c.fills = [];
}

export function autoFrame(
  name: string,
  dir: 'HORIZONTAL' | 'VERTICAL' = 'VERTICAL',
): FrameNode {
  const f = figma.createFrame();
  f.name = name;
  f.layoutMode = dir;
  f.primaryAxisSizingMode = 'AUTO';
  f.counterAxisSizingMode = 'AUTO';
  f.fills = [];
  return f;
}

export interface ChromeOpts {
  bg?: string;
  bgOp?: number;
  /**
   * The bg token's literal RGB, for a sub-1 `bgOp`. Required there and ignored
   * otherwise — see `solid`: a bound colour overwrites the alpha, so a tint below
   * full strength has to be painted literally, and the RGB has to come from the
   * caller because the plugin cannot read a Variable's value back.
   */
  bgArgb?: number;
  border?: string;
  borderOp?: number;
  /** The border token's literal RGB, on the same terms as `bgArgb`. */
  borderArgb?: number;
  strokeN?: number | Dim;
  /** Which edges the stroke lands on. Omitted → all four. */
  strokeSides?: StrokeSides;
  radius?: number | Dim;
  pl?: number | Dim;
  pr?: number | Dim;
  pt?: number | Dim;
  pb?: number | Dim;
  gap?: number | Dim;
}

export function applyChrome(
  node: FrameNode | ComponentNode,
  lk: VarLookup,
  o: ChromeOpts,
): void {
  if (o.pl != null) bindSpaceField(node, 'paddingLeft', lk, dimVal(o.pl));
  if (o.pr != null) bindSpaceField(node, 'paddingRight', lk, dimVal(o.pr));
  if (o.pt != null) bindSpaceField(node, 'paddingTop', lk, dimVal(o.pt));
  if (o.pb != null) bindSpaceField(node, 'paddingBottom', lk, dimVal(o.pb));
  if (o.gap != null) bindSpaceField(node, 'itemSpacing', lk, dimVal(o.gap));
  if (o.radius != null) bindRadiusN(node, lk, o.radius);
  if (o.bg) fillSem(node, lk, o.bg, o.bgOp == null ? 1 : o.bgOp);
  if (o.border) {
    setBorder(
      node, lk, o.border, o.borderOp == null ? 1 : o.borderOp,
      o.strokeN == null ? 1 : o.strokeN,
      o.strokeSides,
    );
  }
}

export function panel(
  name: string,
  dir: 'HORIZONTAL' | 'VERTICAL',
  lk: VarLookup,
  o: ChromeOpts,
): FrameNode {
  const f = autoFrame(name, dir);
  applyChrome(f, lk, o);
  return f;
}

export function applyPanelCompChrome(
  c: ComponentNode,
  dir: 'HORIZONTAL' | 'VERTICAL',
  lk: VarLookup,
  o: ChromeOpts,
): void {
  c.layoutMode = dir;
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'AUTO';
  c.fills = [];
  applyChrome(c, lk, o);
}

export function mintPanelComp(
  page: PageNode,
  name: string,
  dir: 'HORIZONTAL' | 'VERTICAL',
  lk: VarLookup,
  o: ChromeOpts,
): ComponentNode {
  const c = mint(page, name);
  applyPanelCompChrome(c, dir, lk, o);
  return c;
}

export function lockWidth(c: ComponentNode | FrameNode, w: number | Dim): void {
  const width = dimVal(w);
  if (c.layoutMode === 'VERTICAL') {
    c.counterAxisSizingMode = 'FIXED';
    c.resize(width, c.height);
    c.primaryAxisSizingMode = 'AUTO';
  } else {
    c.primaryAxisSizingMode = 'FIXED';
    c.resize(width, c.height);
    c.counterAxisSizingMode = 'AUTO';
  }
}
