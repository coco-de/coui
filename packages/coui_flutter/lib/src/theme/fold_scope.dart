import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/theme/fold_feed.dart';
import 'package:coui_flutter/src/theme/fold_reading.dart';
import 'package:flutter/rendering.dart'
    show
        BoxParentData,
        RenderBox,
        RenderObject,
        RenderSliver,
        RenderViewportBase,
        SliverPhysicalParentData;
import 'package:flutter/widgets.dart';

/// The folds of the viewport at a context: the segments a panel keeps to, the
/// kind of foldable the device is (`CoreFoldableKind.flip` or `.fold`), and
/// how it is held (`CoreFoldPosture`).
///
/// Named and shaped like the Web's so an app reads the same call on both
/// platforms. The answers come from one rule (`CoreFoldLayout`); only what
/// each platform measures differs. Here it is the display features the
/// platform reports through [MediaQuery]: Android reports a fold or a hinge
/// whenever the window lies across it, flat or half open. iOS's embedder
/// reports none of its own, so [FoldScopeHost] — `CoUILayer` mounts one —
/// writes what the package's plugin measures of a folding iPhone into
/// [MediaQueryData.displayFeatures], and it is read the same way.
///
/// Asking depends on [MediaQuery], so a widget that asks is rebuilt when the
/// device folds, turns or is resized, and a subtree whose media query was
/// narrowed — a dialog route keeps its page to one segment — reads that.
abstract final class FoldScope {
  /// The folds at [context]. A viewport with no fold reads as one segment with
  /// no kind and no posture; with no [MediaQuery] above it, as a viewport
  /// nothing measured.
  static CoreFoldLayout of(BuildContext context) {
    final size = MediaQuery.maybeSizeOf(context);
    if (size == null) return CoreFoldLayout.unmeasured;

    return CoreFoldLayout(
      width: size.width,
      height: size.height,
      folds: [
        for (final feature in MediaQuery.displayFeaturesOf(context))
          // A cutout is not a fold. A fold and a hinge are, whichever the
          // platform calls it: the host writes a folding iPhone's hinge as a
          // fold with the width the system reserves across it.
          if (feature.type == DisplayFeatureType.fold ||
              feature.type == DisplayFeatureType.hinge)
            CoreFold(
              bounds: CoreViewportRect(
                left: feature.bounds.left,
                top: feature.bounds.top,
                width: feature.bounds.width,
                height: feature.bounds.height,
              ),
              state: switch (feature.state) {
                DisplayFeatureState.postureFlat => CoreFoldState.flat,
                DisplayFeatureState.postureHalfOpened =>
                  CoreFoldState.halfOpened,
                _ => CoreFoldState.unknown,
              },
            ),
      ],
    );
  }

  /// The box whose coordinates [of] measures in, seen from [box]: the nearest
  /// box around it, or [box] itself, that has the [viewport]'s size
  /// (`MediaQuery.sizeOf`). Null where none has, and the coordinates are the
  /// view's.
  ///
  /// The segments and folds [of] answers with are in the coordinates of the
  /// viewport its media query describes. That is the view for an app, and a
  /// screen drawn inside the page for content shown in a device mockup, which
  /// carries a media query of its own. Taking the nearest box of that size
  /// reads both.
  ///
  /// What a panel anchored to something measures against: where its anchor
  /// is drawn, through `RenderBox.localToGlobal` with this as the ancestor.
  /// A layer that lays its content out measures with [rectOf] instead.
  static RenderBox? viewportOf(RenderBox box, Size viewport) {
    for (RenderObject? at = box; at != null; at = at.parent) {
      if (at is RenderBox && _isViewport(at, viewport)) return at;
    }

    return null;
  }

  /// Where [box] is laid out in the viewport [of] measures — the rectangle to
  /// hold against its segments. [viewport] is that viewport's size
  /// (`MediaQuery.sizeOf`).
  ///
  /// Where it is laid out, not where it is drawn: the offsets its parents
  /// gave it, up to the viewport ([viewportOf]), and none of the transforms
  /// they paint it through. A page sliding in, a panel scaling open or a list
  /// scrolled sideways draw a box away from where it lies, and a layout that
  /// followed them would move its content while they ran. It is also read
  /// from the last layout: a box that has not been laid out since it moved
  /// answers with where it was.
  ///
  /// Inside scrolling content that is where the box lies across the way the
  /// content scrolls — the side padding of a sliver counts — and not how far
  /// it has been scrolled.
  static Rect rectOf(RenderBox box, {required Size viewport}) {
    var origin = Offset.zero;
    for (
      RenderObject at = box;
      !(at is RenderBox && _isViewport(at, viewport));
    ) {
      final parent = at.parent;
      if (parent == null) break;
      final placed = at.parentData;
      if (placed is BoxParentData) {
        origin += placed.offset;
      } else if (placed is SliverPhysicalParentData) {
        origin += _acrossScroll(parent, placed.paintOffset);
      }
      at = parent;
    }

    return origin & box.size;
  }

  /// The part of [offset] — where a sliver, or the viewport that holds it,
  /// paints a child — that the child was laid out with. Across the way the
  /// content scrolls it is a layout fact: a sliver padded on its sides
  /// places its child that far in. Along it, it changes with every scroll.
  static Offset _acrossScroll(RenderObject parent, Offset offset) {
    final axis = switch (parent) {
      RenderSliver() => parent.constraints.axis,
      RenderViewportBase() => parent.axis,
      _ => null,
    };

    return switch (axis) {
      Axis.vertical => Offset(offset.dx, 0),
      Axis.horizontal => Offset(0, offset.dy),
      null => Offset.zero,
    };
  }

  static bool _isViewport(RenderBox box, Size viewport) =>
      box.hasSize &&
      (box.size.width - viewport.width).abs() < _sizeTolerance &&
      (box.size.height - viewport.height).abs() < _sizeTolerance;

  /// How far a box's size may be from the viewport's and still be it: the
  /// rounding of a layout pass.
  static const double _sizeTolerance = 0.5;
}

/// Writes the fold of a platform that does not report it to Flutter into
/// [MediaQueryData.displayFeatures] for [child], so that [FoldScope.of], a
/// dialog route and anything else that reads the display features read it as
/// they read Android's. `CoUILayer` mounts one; an app that hosts CoUI
/// widgets without it can mount one itself, above its navigator.
///
/// That platform is iOS: Flutter's embedder there hands Dart the safe area
/// and nothing about a fold. The host watches a [FoldFeed] — the package's
/// plugin unless one is given — and publishes what [FoldReading] makes of
/// each reading at this viewport's size. On every other platform there is no
/// feed, and the host is [child].
///
/// It stands down wherever the display features above it already carry a
/// fold or a hinge: a Flutter that has started to report an iPhone's fold
/// itself, an outer host, or a preview that draws a device of its own. The
/// fold is never written twice.
///
/// On the Web the component of this name reads the browser's viewport
/// segments; the two share the name because they are the same seat — where
/// the platform's fold enters the tree.
class FoldScopeHost extends StatefulWidget {
  /// Hosts [child] under the platform's fold.
  const FoldScopeHost({required this.child, this.feed, super.key});

  /// What measures the fold. Null is the platform's own
  /// ([FoldFeed.forPlatform]).
  final FoldFeed? feed;

  /// The app below the host.
  final Widget child;

  @override
  State<FoldScopeHost> createState() => _FoldScopeHostState();
}

class _FoldScopeHostState extends State<FoldScopeHost>
    with WidgetsBindingObserver {
  FoldFeed? _feed;
  VoidCallback? _stopWatching;
  FoldReading _reading = FoldReading.none;

  /// The list last published and what it was made from. `MediaQuery` tells
  /// its dependents of a new display-feature list by identity, so an
  /// unchanged fold has to hand back the same list.
  List<DisplayFeature>? _published;
  List<DisplayFeature>? _publishedOver;
  Size? _publishedSize;
  FoldReading? _publishedReading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watch();
  }

  @override
  void didUpdateWidget(FoldScopeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feed == oldWidget.feed) return;
    _stopWatching?.call();
    _reading = FoldReading.none;
    _watch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A device folded while the app was away says so only when asked.
    if (state == AppLifecycleState.resumed) _feed?.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopWatching?.call();
    super.dispose();
  }

  void _watch() {
    _feed = widget.feed ?? FoldFeed.forPlatform();
    _stopWatching = _feed?.watch(_handleReading);
  }

  void _handleReading(FoldReading reading) {
    if (!mounted || reading == _reading) return;
    setState(() => _reading = reading);
  }

  /// The display features [media] carries with this host's fold added, or
  /// [media]'s own list where there is nothing to add.
  List<DisplayFeature> _featuresOver(MediaQueryData media) {
    final over = media.displayFeatures;
    final alreadyFolded = over.any(
      (feature) =>
          feature.type == DisplayFeatureType.fold ||
          feature.type == DisplayFeatureType.hinge,
    );
    if (alreadyFolded) return over;

    final published = _published;
    if (published != null &&
        identical(_publishedOver, over) &&
        _publishedSize == media.size &&
        _publishedReading == _reading) {
      return published;
    }

    final added = _reading.displayFeaturesFor(media.size);
    _publishedOver = over;
    _publishedSize = media.size;
    _publishedReading = _reading;

    return _published = added.isEmpty
        ? over
        : List.unmodifiable([...over, ...added]);
  }

  @override
  Widget build(BuildContext context) {
    // The branch is the platform's and the tree's, not the fold's: a host
    // that wrapped its child only while a fold was there would rebuild the
    // whole app below it — scroll positions and state gone — each time the
    // device folded.
    final media = _feed == null ? null : MediaQuery.maybeOf(context);
    if (media == null) return widget.child;

    final features = _featuresOver(media);

    return MediaQuery(
      data: identical(features, media.displayFeatures)
          ? media
          : media.copyWith(displayFeatures: features),
      child: widget.child,
    );
  }
}
