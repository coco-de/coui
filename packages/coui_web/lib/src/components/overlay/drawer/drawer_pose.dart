/// Reading back where a Web drawer panel is drawn.
///
/// The panel's pose is the browser's to know while it is on its way back to
/// the dock: a CSS transition owns the number, and it is not one the entry
/// holds. When a pointer takes hold of a panel at that moment the drag has to
/// carry on from where the panel is, so the entry asks the browser — the
/// computed `transform` is the transition's current value — and this turns
/// the answer into the pose `CoreDrawerRubberBand` works in.
library;

import 'package:coui_core/coui_core.dart';

/// The pose a computed `transform` ([css], as `getComputedStyle` hands it back:
/// `none`, `matrix(...)` or `matrix3d(...)`) puts a panel in.
///
/// A panel is either slid along its slide axis or scaled along it about the
/// edge it is docked to, never both, so the answer is one or the other:
///
/// * a scale above 1 on the slide axis is a stretch of
///   `(scale - 1) * extent` px, where [extent] is the panel's own length on
///   that axis;
/// * otherwise the shift on the slide axis, signed by the edge the panel
///   hides behind ([side]: toward that edge is positive), is a slide, and a
///   shift the other way is no slide.
///
/// Anything the function cannot read is a panel at its dock.
CoreDrawerPose drawerPoseOf(
  String? css, {
  required CoreDrawerSide side,
  required double extent,
}) {
  final text = css?.trim();
  if (text == null || text.isEmpty || text == 'none') {
    return CoreDrawerRubberBand.rest;
  }
  final open = text.indexOf('(');
  final close = text.lastIndexOf(')');
  if (open < 0 || close < open) return CoreDrawerRubberBand.rest;

  final values = <double>[];
  for (final part in text.substring(open + 1, close).split(',')) {
    final value = double.tryParse(part.trim());
    if (value == null) return CoreDrawerRubberBand.rest;
    values.add(value);
  }

  final horizontal =
      side == CoreDrawerSide.left || side == CoreDrawerSide.right;
  // The scale and the shift on the slide axis, from the matrix's own layout
  // (column-major for `matrix3d`).
  final (double scale, double shift) = switch ((
    text.substring(0, open),
    values.length,
  )) {
    ('matrix', 6) =>
      horizontal ? (values[0], values[4]) : (values[3], values[5]),
    ('matrix3d', 16) =>
      horizontal ? (values[0], values[12]) : (values[5], values[13]),
    _ => (1, 0),
  };

  if (scale > 1) return (slide: 0, stretch: (scale - 1) * extent);

  final towardHidingEdge = switch (side) {
    CoreDrawerSide.left || CoreDrawerSide.top => -shift,
    CoreDrawerSide.right || CoreDrawerSide.bottom => shift,
  };

  return (slide: towardHidingEdge > 0 ? towardHidingEdge : 0, stretch: 0);
}
