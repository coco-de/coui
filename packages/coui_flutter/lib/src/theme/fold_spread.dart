import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/theme/fold_box.dart';
import 'package:flutter/widgets.dart';

/// Lays [child] out as a spread across the fold that runs through this
/// widget's box: equally far on both sides of it. Content in two columns —
/// or any even number — then divides at the fold, with the gutter between
/// its middle columns on it.
///
/// A viewport a fold splits is two pages, and a box that covers both is not
/// always centred on the fold: an app's frame keeps clear of the device's
/// controls along one edge only, so its middle is off to the other side. Two
/// equal columns in it meet beside the fold, and the second begins on it.
/// This takes the difference off the longer side, and nothing else moves:
/// the columns, and the gutter between them, are the child's own. A gutter
/// narrower than the strip a hinge hides leaves the columns' inner margins
/// on the strip.
///
/// Only a fold that splits the viewport ([CoreFold.separates]) and runs
/// through the box counts: down it for columns side by side
/// ([Axis.horizontal]), across it for rows stacked ([Axis.vertical]). With
/// none, with more than one — there is no one middle then — or where the
/// fold lies along the box's edge, the child fills the box as before.
///
/// What scrolls needs none of this along the way it scrolls: a list that
/// runs down a fold lying across it is read through it. Along the other
/// way its columns divide like any others.
///
/// Where the box lies is read from its last layout ([FoldBox]): a box that
/// is not the viewport's size may be set right one frame after it is mounted
/// or moved.
class FoldSpread extends StatelessWidget {
  /// Lays [child] out equally far on both sides of the fold through it.
  const FoldSpread({
    required this.child,
    this.axis = Axis.horizontal,
    super.key,
  });

  /// The content, in two columns or any even number.
  final Widget child;

  /// The way the content divides: [Axis.horizontal] for columns side by
  /// side, which a fold running down the box divides; [Axis.vertical] for
  /// rows stacked, which a fold running across it divides.
  final Axis axis;

  /// What to take off each side of [box] so that what is left reaches
  /// equally far on both sides of the fold through it.
  EdgeInsets _trim(CoreFoldLayout layout, Rect box) {
    final columns = axis == Axis.horizontal;
    Rect? through;
    for (final fold in layout.folds) {
      if (!fold.separates) continue;
      final bounds = Rect.fromLTWH(
        fold.bounds.left,
        fold.bounds.top,
        fold.bounds.width,
        fold.bounds.height,
      );
      // A fold crosses the whole viewport, so one that runs the other way
      // reaches past both edges of the box and is never between them.
      final between = columns
          ? bounds.left > box.left && bounds.right < box.right
          : bounds.top > box.top && bounds.bottom < box.bottom;
      if (!between) continue;
      if (through != null) return EdgeInsets.zero;
      through = bounds;
    }
    if (through == null) return EdgeInsets.zero;
    final before = columns ? through.left - box.left : through.top - box.top;
    final after = columns
        ? box.right - through.right
        : box.bottom - through.bottom;
    final side = math.min(before, after);

    return columns
        ? EdgeInsets.only(left: before - side, right: after - side)
        : EdgeInsets.only(top: before - side, bottom: after - side);
  }

  @override
  Widget build(BuildContext context) => FoldBox(
    // The same widget whether or not a fold runs through the box: content
    // that is on screen while the device folds is moved, not remounted.
    builder: (context, layout, box) => Padding(
      padding: box == null ? EdgeInsets.zero : _trim(layout, box),
      child: child,
    ),
  );
}
