// The Flutter side of the `opacity` field.
//
// Web's probe reads `getComputedStyle(root).opacity` — the root element's
// own opacity, which every element has (`1` when nothing dims it). Flutter
// had nothing on this side: `buildFlutterPropertySnapshotJson` took an
// `opacity` argument and no caller ever passed one, so every capture said
// `null` against Web's `1.0`, and the comparator — which rightly refuses to
// read `null` as "measured, and the answer is 1" — flagged every one of
// the nightly's 262 T2 cells on this field alone.
//
// Not fixed in the comparator. `flutter_property_snapshot.dart` argues the
// case for `backgroundColor` and it holds here too: collapsing an absence
// into a value would report "verified" exactly when the walk broke. So
// this file measures. A found root always yields a number.
//
// What "the root's own opacity" is on Flutter: the product of every
// `Opacity` / `FadeTransition` / `AnimatedOpacity` between the root's
// render object and its chrome node, inclusive. That is the span Web's
// root element covers — an `Opacity` wrapping the whole component dims
// the root element; an `Opacity` around one slot inside the chrome dims a
// descendant, which Web's root-level read would not see either. When the
// chrome walk found no node, the root's own render object is the whole
// span.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fully opaque — what a root with nothing dimming it measures as.
const double kFullyOpaque = 1;

/// The opacity applied to [rootFinder]'s render subtree by every
/// opacity-bearing render object from [chromeRenderObject] up to and
/// including the root's own render object.
///
/// [chromeRenderObject] is `findChromeNode`'s matched box when one was
/// found, and may be `null` — then only the root's own render object is
/// inspected. The walk goes *up* from the chrome node rather than down
/// from the root so it never has to decide which branch to follow: the
/// chrome node is already the one `root_scoped_walk.dart` attributed to
/// root, and everything on the way back up to root is root's own by the
/// same rule.
double probeRootOpacity(
  WidgetTester tester, {
  required Finder rootFinder,
  RenderObject? chromeRenderObject,
}) {
  final rootRenderObject = tester.renderObject(rootFinder);
  var opacity = kFullyOpaque;

  RenderObject? current = chromeRenderObject ?? rootRenderObject;
  while (current != null) {
    opacity *= _ownOpacityOf(current);
    if (identical(current, rootRenderObject)) break;
    current = current.parent;
  }
  return opacity;
}

/// What [renderObject] itself multiplies into its subtree's opacity, or
/// `1` for a render object that does not paint through an opacity layer.
///
/// `RenderAnimatedOpacity` (what `FadeTransition` / `AnimatedOpacity`
/// build) exposes the animation, not a scalar — its current value is the
/// opacity the frame being captured painted with, which is the same thing
/// Web's computed style reports mid-transition.
double _ownOpacityOf(RenderObject renderObject) {
  if (renderObject is RenderOpacity) return renderObject.opacity;
  if (renderObject is RenderAnimatedOpacity) {
    return renderObject.opacity.value;
  }
  return kFullyOpaque;
}
