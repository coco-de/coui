/// Holding a floating panel to the room the viewport leaves it — the Web
/// half of `CoreOverlayFit`.
///
/// The browser lays the panel out before the positioner can ask how tall it
/// is, so the positioner measures first and decides after: a panel that does
/// not fit is given the room as its `max-height` and scrolls inside it, and,
/// because a panel that takes all the room fits nowhere else, it sits at the
/// top of it. The rule itself — how much room, when a panel is capped, where
/// it then starts — is `CoreOverlayFit`, the one Flutter's overlay engine
/// reads too; this file is the measuring around it.
///
/// Pure Dart (no DOM) so the decision can be tested without a browser.
library;

import 'package:coui_core/coui_core.dart';

/// The class a host puts on the element that scrolls a capped panel.
///
/// The positioner looks for it to learn how tall the panel really is: a
/// capped panel's box is the room, and only its scroller still knows how much
/// more it holds. A capped panel that hid its own size would never be given
/// more room again when the viewport grows.
const String kOverlayFitScrollerClass = 'co-fit-scroller';

/// How far a measurement may disagree with itself — half a CSS pixel.
///
/// `scrollHeight` and `clientHeight` are whole numbers while a box is laid out
/// in fractions, so a panel that is exactly as tall as the room can read as a
/// pixel over it, then as a pixel under it, and flip between capped and not on
/// every update.
const double _kMeasureSlack = 0.5;

/// The height the panel would have if nothing held it to the room.
///
/// [measuredHeight] is the box the browser gave it; [overflow] is how much
/// more its scroller holds than shows (zero when nothing scrolls); [room] is
/// what [CoreOverlayFit.availableExtent] allows; [wasCapped] is whether the
/// panel is currently held.
///
/// A panel that is held and still fills the room stays held even when the
/// measurement cannot tell how much more it holds: letting it go on a
/// rounding error would re-measure it uncapped one update later and cap it
/// again the next.
double overlayNaturalHeight({
  required double measuredHeight,
  required double overflow,
  required double room,
  required bool wasCapped,
}) {
  final natural = measuredHeight + (overflow > 0 ? overflow : 0);
  if (wasCapped && measuredHeight >= room - _kMeasureSlack && natural <= room) {
    return room + _kMeasureSlack;
  }

  return natural;
}
