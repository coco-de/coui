/// Web implementation of the dock's flight measurement.
///
/// Reads three rectangles and subtracts one from the other two. Small, and
/// kept beside the component rather than inside it because it is the one
/// thing here that needs a document: `dock.dart` decides *whether* to fly
/// and what the bodies mean; this only says where they are.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:web/web.dart' as web;

/// One box in the track's own coordinates.
typedef DockFlightBox = ({
  double left,
  double top,
  double width,
  double height,
});

/// The pill's overhang past an item on each side, in CSS pixels.
typedef DockFlightPad = ({
  double left,
  double top,
  double right,
  double bottom,
});

/// The departing and arriving item boxes, relative to the track's padding
/// box, and the overhang the settled pill draws — or null when any of the
/// three elements cannot be found.
typedef DockFlightMeasure = ({
  DockFlightBox from,
  DockFlightBox to,
  DockFlightPad pad,
});

/// Measures the two items against the track.
///
/// The flight element is `position: absolute; inset: 0` inside the track,
/// which resolves against the track's *padding* box — inside its border.
/// So the origin subtracted here is the border box's corner plus the
/// border widths (`clientLeft` / `clientTop`), not the border box alone: a
/// bar with a line around it would otherwise carve its plates one pixel off.
///
/// [padding] is the authored overhang. The settled pill draws each side
/// through its spacing variable, which a density re-maps, so the side is
/// read back from that variable here — a flight that used the authored
/// number would land on a pill the stylesheet no longer draws.
DockFlightMeasure? measureDockFlight({
  required String trackId,
  required String fromId,
  required String toId,
  required CoreEdgeInsets padding,
}) {
  final track = web.document.getElementById(trackId);
  final from = web.document.getElementById(fromId);
  final to = web.document.getElementById(toId);
  if (track == null || from == null || to == null) return null;

  final origin = track.getBoundingClientRect();
  final originX = origin.left + track.clientLeft;
  final originY = origin.top + track.clientTop;

  DockFlightBox box(web.Element element) {
    final rect = element.getBoundingClientRect();

    return (
      left: rect.left - originX,
      top: rect.top - originY,
      width: rect.width,
      height: rect.height,
    );
  }

  final scope = web.window.getComputedStyle(track);
  final root = web.document.documentElement;
  final rootFontPx = root == null
      ? kRemDivisor
      : _cssPx(
              web.window.getComputedStyle(root).getPropertyValue('font-size'),
              kRemDivisor,
            ) ??
            kRemDivisor;

  // The length a side draws: the variable when the side is a step on the
  // spacing scale (what `spaceCss` emits), the authored number otherwise.
  double side(double px) {
    if (!CoreSpace.steps.contains(px)) return px;
    final value = scope.getPropertyValue('--coui-space-${px.toInt()}');

    return _cssPx(value, rootFontPx) ?? px;
  }

  return (
    from: box(from),
    to: box(to),
    pad: (
      left: side(padding.left),
      top: side(padding.top),
      right: side(padding.right),
      bottom: side(padding.bottom),
    ),
  );
}

/// A `px` or `rem` length in CSS pixels, or null for anything else.
double? _cssPx(String value, double rootFontPx) {
  final v = value.trim();
  if (v.endsWith('rem')) {
    final n = double.tryParse(v.substring(0, v.length - 3));

    return n == null ? null : n * rootFontPx;
  }
  if (v.endsWith('px')) return double.tryParse(v.substring(0, v.length - 2));

  return null;
}
