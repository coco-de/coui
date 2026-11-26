/// Top-layer promotion for portaled overlay panels.
///
/// A floating panel is `position: fixed` and is placed with viewport
/// coordinates (`OverlayPositioner` reads `getBoundingClientRect()`).
/// That only lands on the trigger when the panel's containing block is
/// the viewport. Any ancestor of the `OverlayHost` that is a containing
/// block for fixed descendants — `transform`, `filter`, `backdrop-filter`,
/// `contain`, `will-change`, `container-type` … — makes the same numbers
/// resolve against that ancestor instead, and the panel lands off the
/// trigger by the ancestor's offset (and is clipped by its `overflow`).
/// A client island roots its own host where it hydrates, so every
/// ancestor the page wraps it in is such a candidate.
///
/// The browser has one primitive for this: the **top layer**. An element
/// shown through the Popover API is rendered against the viewport and
/// ignores every ancestor's transform, clip and stacking context, yet it
/// stays at its place in the DOM — so it keeps inheriting the colour,
/// typography and scoped theme variables of the subtree it was rendered
/// in, which a body-level portal would lose.
///
/// Two halves:
///
///  * declarative — a panel's outermost wrapper carries
///    [TopLayer.attributesFor] (`popover="manual"` plus a marker);
///  * imperative — `installTopLayerPromoter` (browser only, installed by
///    `OverlayHost`) calls `showPopover()` on every marked panel the
///    moment it is inserted, before the next paint, so a panel whose DOM
///    node is re-created by a render never shows a frame outside the top
///    layer.
///
/// `popover="manual"` keeps the UA's light dismiss and Escape handling out
/// of the way: the components own dismissal. Browsers without the Popover
/// API ignore the attribute and render the panel exactly as before.
library;

import 'package:coui_web/src/overlay/overlay_portal.dart';
import 'package:jaspr/jaspr.dart';

/// Marker carried by every panel that `OverlayHost` promotes into the top
/// layer. The host's reset stylesheet and the promoter both key on it, so
/// a panel that is not meant to be promoted (a `Drawer` root, which
/// promotes itself) is left alone.
const String kTopLayerPanelAttribute = 'data-coui-overlay-panel';

/// Declarative half of the top-layer promotion.
abstract final class TopLayer {
  /// Attributes for a panel's outermost fixed wrapper.
  static const Map<String, String> attributes = {
    'popover': 'manual',
    kTopLayerPanelAttribute: '',
  };

  /// [attributes] when a host is in scope above [context], otherwise empty.
  ///
  /// Without a host nothing would ever call `showPopover()`, and the UA
  /// stylesheet hides a `popover` element that is not open — a panel
  /// rendered inline (SSR, or a tree without `CoUIWeb`) must stay visible.
  static Map<String, String> attributesFor(BuildContext context) =>
      OverlayPortal.maybeOf(context) == null ? const {} : attributes;
}
