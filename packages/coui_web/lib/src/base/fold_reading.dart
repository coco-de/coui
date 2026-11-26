import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';

/// The folds a browser's viewport [segments] imply, at [state].
///
/// The browser reports the parts of the viewport, not the fold: the fold is
/// what lies between two neighbouring parts — a line of no width where a
/// screen bends, the strip a hinge hides between two screens. Every fold is
/// at the one [state] the posture query reports, since a page sees one
/// posture.
///
/// The rule then decides what the folds mean, so a seamless fold that the
/// browser split while the posture says flat reads as one surface, as it does
/// on Flutter. No segments is a viewport nothing measured.
CoreFoldLayout foldLayoutFromSegments(
  List<CoreViewportRect> segments, {
  required CoreFoldState state,
}) {
  if (segments.isEmpty) return CoreFoldLayout.unmeasured;
  var width = 0.0;
  var height = 0.0;
  for (final segment in segments) {
    width = math.max(width, segment.right);
    height = math.max(height, segment.bottom);
  }
  final folds = <CoreFold>[];
  for (final a in segments) {
    // The nearest part beside [a] in its row, and the nearest below it in its
    // column — each pair of neighbours once.
    CoreViewportRect? right;
    CoreViewportRect? below;
    for (final b in segments) {
      if (identical(a, b)) continue;
      if (b.top == a.top && b.height == a.height && b.left >= a.right) {
        if (right == null || b.left < right.left) right = b;
      }
      if (b.left == a.left && b.width == a.width && b.top >= a.bottom) {
        if (below == null || b.top < below.top) below = b;
      }
    }
    if (right != null) {
      folds.add(
        CoreFold(
          bounds: CoreViewportRect(
            left: a.right,
            top: a.top,
            width: right.left - a.right,
            height: a.height,
          ),
          state: state,
        ),
      );
    }
    if (below != null) {
      folds.add(
        CoreFold(
          bounds: CoreViewportRect(
            left: a.left,
            top: a.bottom,
            width: a.width,
            height: below.top - a.bottom,
          ),
          state: state,
        ),
      );
    }
  }

  return CoreFoldLayout(width: width, height: height, folds: folds);
}

/// What the posture media queries answer: [folded] for `(device-posture:
/// folded)`, [continuous] for `(device-posture: continuous)`. Neither is a
/// browser that does not know the query.
CoreFoldState foldStateFromPosture({
  required bool folded,
  required bool continuous,
}) {
  if (folded) return CoreFoldState.halfOpened;
  if (continuous) return CoreFoldState.flat;

  return CoreFoldState.unknown;
}
