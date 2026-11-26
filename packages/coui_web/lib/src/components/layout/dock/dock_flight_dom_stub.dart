/// SSR stub for the dock's flight measurement.
library;

import 'package:coui_core/coui_core.dart';

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

/// Always null. There is no document to measure on the server.
DockFlightMeasure? measureDockFlight({
  required String trackId,
  required String fromId,
  required String toId,
  required CoreEdgeInsets padding,
}) => null;
