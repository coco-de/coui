/// <reference types="@figma/plugin-typings" />

import { RegistryEntry, kSlotStandInComponent } from '../helpers';

import {
  kPopupPaddings,
  popupPaddingData,
  POPUP,
  kPopupDefaultPadding,
  popupVariantName,
  kPopupShowContentProp,
  kPopupContentSlotName,
} from '../popup-composition';
import {
  VarLookup,
  applySurfaceMaterial,
  applyPanelCompChrome,
  autoFrame,
  bindPad,
  bindSwapProp,
  bindVisibleProp,
  borderData,
  defineProp,
  mountSet,
  setShadow,
  slotStandIn,
  slotStandInDefault,
  vStackSet,
} from '../helpers';
import { colorData, dimVal } from '../compat/v1';
// The floating panel box every menu / popover surface composes. Fully
// data-driven from coui_core POPUP.fields: padding · borderRadius ·
// backgroundColor · borderColor + borderWidth · spacing (the `Column`'s
// inter-child gap, `0` — bound rather than skipped so the flush stacking is
// a stated value, not an accident) · minWidth (the widget's
// `ConstrainedBox(minWidth) + IntrinsicWidth` pair, which is exactly an
// auto-layout frame that hugs its content with a bound floor) · contentColor
// (the ambient text colour the widget installs over its children via
// `DefaultTextStyle`).
//
// `boxShadow` + `shadowBaseColor` are drawn together — the stack's layers,
// tinted by the base colour, at the alpha each layer states. (An older note
// here said `shadowBaseColor` was "not drawn" because "no builder in this
// plugin draws shadows"; `setShadow` exists now and the layer geometry is
// fully in the export, so that paragraph described a plugin that no longer
// exists.)
//
// `openAnimationDuration` / `closeAnimationDuration` are transition timings,
// with no meaning in a static frame (same as every other component's
// `*Duration` field here).
function buildPopup(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = POPUP.fields;
  // `Padding=content` (the field's own default) is the member the loose
  // component this set grew out of was already drawing, so it is ADOPTED: the
  // node keeps its id and `key`, and every `Popup` instance in a consuming file
  // keeps pointing at it. Retiring it would orphan them.
  const mount = mountSet(
    page,
    'Popup',
    kPopupPaddings.map(popupVariantName),
    { adoptLooseAs: popupVariantName(kPopupDefaultPadding) },
  );
  const slots: PopupContentSlot[] = [];
  for (const padding of kPopupPaddings) {
    const c = mount.getOrCreate(popupVariantName(padding));
    applyPanelCompChrome(c, 'VERTICAL', lk, {
      gap: f.spacing,
      radius: f.borderRadius.topLeft,
    });
    bindPad(c, lk, popupPaddingData(padding));
    slots.push(popupBoxChrome(page, c, lk));
  }
  const set = mount.finish();
  // `children` — two properties on the set, bound in every member, so the slot
  // a parent fills or empties is the same one whichever inset it composes. The
  // BOOLEAN sits on the holder and the swap on the stand-in inside it: one node
  // carries one `componentPropertyReferences` map (see `slotNodes`, overlay.ts).
  const showContent = defineProp(set, kPopupShowContentProp, 'BOOLEAN', true);
  const contentProp = defineProp(set, 'Content', 'INSTANCE_SWAP', slotStandInDefault(page, kPopupContentShape));
  for (const slot of slots) {
    bindVisibleProp(slot.holder, showContent);
    bindSwapProp(slot.instance, contentProp);
  }
  vStackSet(set);
  return set;
}
const kPopupContentShape = 'rectangular';

interface PopupContentSlot {
  /// Carries `Show content`.
  holder: FrameNode;
  /// The `.Slot` stand-in — carries `Content`.
  instance: InstanceNode;
}

// Everything on the box that does not depend on the inset preset — identical
// across the two members, so it is drawn once per member from one place.
function popupBoxChrome(page: PageNode, c: ComponentNode, lk: VarLookup): PopupContentSlot {
  const f = POPUP.fields;
  // A floating surface on both platforms — `popup_style.dart` reads
  // `theme.surfaceFor(.functional)` and the Web twin marks itself
  // `webSurfaceMarkerFor(.functional)` — and both opt it into the style's rim.
  applySurfaceMaterial(c, lk, colorData(f.backgroundColor), 'functional', {
    radius: f.borderRadius.topLeft,
    rim: true,
  });
  borderData(c, lk, colorData(f.borderColor), f.borderWidth);
  c.minWidth = dimVal(f.minWidth);
  c.setBoundVariable('minWidth', lk.spaceLadder(dimVal(f.minWidth)));
  // The ceiling is optional — `double.infinity` means "no ceiling", which
  // the exporter spells as `{ unbounded: true }` and Figma has no way to
  // draw. A finite one is a real constraint and is set; the popup's own
  // default is unbounded, so the plain panel passes through unchanged and
  // only a caller that states a ceiling (a menu's 280) gets one.
  // `{ unbounded: true }` has no `v`; a finite ceiling does.
  // The cast widens the JSON literal type: today's export is unbounded, so
  // TS narrows `maxWidth` to a shape with no `v` and a caller that states a
  // finite ceiling would not typecheck against it.
  const ceilingField = f.maxWidth as { v?: number };
  const ceiling = typeof ceilingField.v === 'number' ? ceilingField.v : null;
  if (ceiling != null && ceiling > 0) {
    c.maxWidth = ceiling;
    try {
      c.setBoundVariable('maxWidth', lk.layout(ceiling));
    } catch (_e) {
      // Off the layout scale — the literal stays, as `bindSize` leaves it.
    }
  }
  // The popup's elevation stack, a floating-panel rung. A panel that casts no
  // shadow reads as flush with the page, which is the one thing a popup is not.
  setShadow(c, f.boxShadow, lk, colorData(f.shadowBaseColor));
  // `children` is `List<W>` — arbitrary widgets — so it is the `.Slot`
  // stand-in, swappable through `Content` (bound in `buildPopup`, once the set
  // exists). See `kPopupContentSlotName`.
  // The holder hugs the stand-in, so the slot box is the `.Slot` member's.
  const holder = autoFrame(kPopupContentSlotName, 'HORIZONTAL');
  const instance = slotStandIn(page, `${kPopupContentSlotName} slot`, kPopupContentShape);
  holder.appendChild(instance);
  c.appendChild(holder);
  return { holder: holder, instance: instance };
}

export const POPUP_BUILDERS: RegistryEntry[] = [
  // `.Slot` is what `children` is drawn as and the `Content` swap's default.
  { section: 'Display', name: 'Popup', build: buildPopup, needs: [kSlotStandInComponent] },
];
