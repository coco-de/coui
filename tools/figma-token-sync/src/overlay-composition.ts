/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { mainComponentIdOf, ColorData, IconOpts, VarLookup, pinAbsolute } from './helpers';
import { Dim, argbAlpha, argbToRgb } from './compat/v1';
// A plain horizontal rule — `const Divider()` / `Divider(dividerStyle: …)`
// with no label child.
export const kPlainDividerAxes = { Orientation: 'Horizontal', Label: 'None' };

// The row rung a `Menu` carries when nothing names one — `CoreMenuItemSize
// .defaultSize`, which `Menu(size:)` and the menus that compose it
// (`DropdownMenu`, `ContextMenu`, `Menubar`) all default to. The exporter
// carries an enum's default only for the Variant axis, so it is spelled here
// the way `Tag` and `InputOtp` spell theirs; `buildMenu` checks it against the
// exported members, so an enum change fails loudly instead of resting on a
// member the enumeration no longer produces.
export const kMenuRestingSize = 'sm';

// ─── Caller slots ────────────────────────────────────────────────────────────
//
// A `W` / `W?` contract slot is drawn as the shared slot stand-in
// (`slotStandIn`, slot-stand-in.ts) with an INSTANCE_SWAP defaulting to it —
// why, and why it is a placeholder rather than content:
// docs/contributing/figma.md, "빈 슬롯의 대역". Drawing a content slot as a
// *plausible filling* instead (a nav list, a paragraph) is what that replaced:
// four `Button(variant: .menu)` rows inside `Drawer.content` said a drawer
// contains a nav list, and the contract only says it contains a widget.
//
// Trigger / target slots are the exception, and deliberately so: a popover's
// trigger and a context menu's right-click target are affordances the library
// should *show*, so they default to the component the widget's own example
// puts there. The INSTANCE_SWAP is what keeps that a default rather than a
// claim.

// The main-component id an INSTANCE_SWAP default needs.
//
// It cannot be read back off the instance just created: `documentAccess:
// "dynamic-page"` (manifest.json) makes `InstanceNode.mainComponent`
// write-only and its async replacement is unreachable from a synchronous
// builder — so the node is located by name, exactly the way `iconMainId`
// (helpers.ts) locates an `Icon` variant. `''` when the set is absent, for
// `iconMainId`'s reason: the property is still declared, so the slot shows as
// swappable with no default instead of the whole entry failing and leaving a
// half-built component on the page.
//
// (helpers.ts owns the general form now — `mainComponentIdOf`, which this wraps
// for the `''` fallback. Six copies of the page-local version had drifted from
// `instanceOf`, and the drift failed the `Alert`, `Card`, `Avatar` and
// `FormField` entries, each leaving a half-drawn component on the page.)
// `''` rather than a throw when the child is absent: `defineProp` skips an
// INSTANCE_SWAP with no default (Figma refuses the declaration), so the component
// survives with a non-swappable slot instead of the entry failing half-drawn.
export function mainId(page: PageNode, setName: string, variantName?: string): string {
  try {
    return mainComponentIdOf(page, setName, variantName);
  } catch {
    return '';
  }
}

// `IconOpts` from a resolved colour — the `makeIcon` twin of `glyphOpts`
// (helpers.ts), which returns `LabelOpts` and so cannot feed an icon.
export function iconOpts(lk: VarLookup, cd: ColorData, size: number | Dim): IconOpts {
  if (cd.color != null) {
    // `argb` rides along for the same reason `labelColor` carries it: a bound paint
    // overwrites its own alpha, so a sub-1 token colour has to be painted literally
    // and this is the only literal there is.
    return { size: size, colorVar: lk.sem(cd.color), opacity: cd.opacity, argb: cd.argb };
  }
  return {
    size: size,
    rawColor: argbToRgb(cd.argb!),
    opacity: argbAlpha(cd.argb!, cd.opacity),
  };
}

// A glyph that belongs INSIDE a composed instance's box.
//
// Figma refuses to add a child to an instance — an instance mirrors its main's
// subtree — so the glyph rides above it as an absolutely-positioned sibling in
// the host frame. Pinned CENTER so it stays put when the instance is resized.
//
// Takes a text node as well as an `Icon` instance, because a composed
// `Button`'s `trailing` slot is not always a glyph: `menu.dart`'s action row
// hands it either `Icon(chevronRight)` or the keyboard-shortcut hint
// (`Text(item.shortcut!, style: style.shortcutTextStyle)`). Both are the same
// problem — a child of the instance's own slot — so both take the same route
// rather than one of them going undrawn for want of a signature.
//
// ⚠️ Absolute placement is also what `figma_composition_parity`'s `Stacks`
// heuristic looks for (`.x =`), so every caller of this is credited with
// composing `Stacks`. Two of them genuinely do (`Toast`'s panel, `Swiper`'s
// ghost layer); `Drawer` and `Menu` do not, and their own notes say what their
// real `Stacks` reference is.
export function overlayGlyph(
  host: FrameNode,
  glyph: InstanceNode | TextNode,
  x: number,
  y: number,
): void {
  pinAbsolute(host, glyph, x, y, {
    horizontal: 'CENTER',
    vertical: 'CENTER',
  });
}
