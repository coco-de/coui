import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/theme/fold_box.dart';
import 'package:coui_flutter/src/theme/fold_scope.dart';
import 'package:flutter/widgets.dart';

/// Keeps [child] to one segment of a viewport a fold splits: lays it out in
/// the part of this widget's box that segment covers, and narrows the
/// [MediaQuery] below it to the segment — the system bars that border the
/// segment, and no fold.
///
/// What the framework's dialog route does for its page
/// (`DisplayFeatureSubScreen`), for the panels the kit places itself: a
/// drawer docked to an edge, the toasts stacked in a corner. Which segment is
/// the fold rule's answer for a panel placed at [alignment] of this widget's
/// box (`CoreFoldLayout.segmentIndexAligned`), so both platforms open the
/// panel on the same side.
///
/// Its box may be the viewport — a route's page, a layer over the app — or
/// any part of it: a layer inside a frame that stops short of an edge, a
/// page of a navigator that fills one pane. A box the fold does not cross is
/// left as it is, with only the media query narrowed. Where nothing splits
/// the viewport the child fills the box as before. Where the box lies is
/// read from its last layout ([FoldBox]): a box that is not the viewport's
/// size may be set right one frame after it is mounted or moved.
///
/// The media query below keeps the viewport's size, as it does under the
/// dialog route: only the insets and the display features are the
/// segment's. A subtree that asks [FoldScope.of] there reads no fold, so a
/// panel opened from inside one is not narrowed twice.
class FoldSegment extends StatelessWidget {
  /// Keeps [child] to the segment a panel placed at [alignment] opens in.
  const FoldSegment({required this.alignment, required this.child, super.key});

  /// Where in this widget's box the panel is placed: the edge a drawer is
  /// docked to, the corner a stack of toasts gathers in.
  final AlignmentGeometry alignment;

  /// The panel, laid out in the segment.
  final Widget child;

  /// The part of the viewport at [context] a panel anchored at [point] keeps
  /// to: the segment that holds the point — the nearest, for a point on the
  /// fold — or the whole viewport where nothing splits it. [point] is in the
  /// viewport's coordinates ([FoldScope.viewportOf]).
  static Rect rectAt(BuildContext context, Offset point) {
    final layout = FoldScope.of(context);
    final index = layout.segmentIndexAt(point.dx, point.dy);
    if (index == null || !layout.isSplit) {
      return Offset.zero & (MediaQuery.maybeSizeOf(context) ?? Size.zero);
    }

    return _rectOf(layout.segments[index]);
  }

  static Rect _rectOf(CoreViewportRect segment) =>
      Rect.fromLTWH(segment.left, segment.top, segment.width, segment.height);

  @override
  Widget build(BuildContext context) => FoldBox(
    builder: (context, layout, box) {
      final media = MediaQuery.of(context);
      var padding = EdgeInsets.zero;
      var below = media;
      if (box != null) {
        final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
        final at = alignment.resolve(direction);
        final index = layout.segmentIndexAligned(
          at.x,
          at.y,
          direction == TextDirection.rtl
              ? CoreTextDirection.rtl
              : CoreTextDirection.ltr,
          within: CoreViewportRect(
            left: box.left,
            top: box.top,
            width: box.width,
            height: box.height,
          ),
        );
        if (index != null) {
          final segment = _rectOf(layout.segments[index]);
          final kept = box.intersect(segment);
          // A segment that does not reach the box leaves it as it is.
          if (kept.width > 0 && kept.height > 0) {
            padding = EdgeInsets.fromLTRB(
              kept.left - box.left,
              kept.top - box.top,
              box.right - kept.right,
              box.bottom - kept.bottom,
            );
            below = media.removeDisplayFeatures(segment);
          }
        }
      }

      // The same two widgets whether or not a fold splits the viewport: a
      // panel that is open while the device folds is moved, not remounted.
      return Padding(
        padding: padding,
        child: MediaQuery(data: below, child: child),
      );
    },
  );
}
