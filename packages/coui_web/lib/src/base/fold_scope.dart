import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/fold_feed.dart';
import 'package:jaspr/jaspr.dart';

/// The folds of the viewport at a context: the segments a panel keeps to, the
/// kind of foldable the device is (`CoreFoldableKind.flip` or `.fold`), and
/// how it is held (`CoreFoldPosture`).
///
/// Named and shaped like the Flutter call so an app reads the same line on
/// both platforms. The answers come from one rule (`CoreFoldLayout`); only
/// what each platform measures differs. Here it is what the browser reports:
/// the viewport segments (`window.viewport.segments`), with the gap between
/// two of them as the fold, and the posture media query (`device-posture`).
/// A browser reports segments only while the fold splits the viewport, so a
/// screen that bends and lies flat reads here as no fold at all, where
/// Flutter on Android still reports it.
///
/// On the server, and in a browser that reports no segments, the viewport is
/// unmeasured: no segment, no kind, no posture.
abstract final class FoldScope {
  /// The folds at [context].
  static CoreFoldLayout of(BuildContext context) =>
      context
          .dependOnInheritedComponentOfExactType<FoldLayoutScope>()
          ?.layout ??
      CoreFoldLayout.unmeasured;
}

/// Reads the folds the browser reports and publishes them to [child], read in
/// [direction]. Mounted by `CoUIWeb`.
///
/// A component of its own so that a fold, a change of posture or a resize
/// rebuilds this scope and the components that read it, and not the app root:
/// [child] is handed through, and the browser fires a resize for every frame
/// a window is dragged.
class FoldScopeHost extends StatefulComponent {
  /// Hosts [child] under the browser's folds.
  const FoldScopeHost({
    required this.direction,
    required this.child,
    super.key,
  });

  /// The direction the root reads in.
  final CoreTextDirection direction;

  /// The app below the scope.
  final Component child;

  @override
  State<FoldScopeHost> createState() => _FoldScopeHostState();
}

class _FoldScopeHostState extends State<FoldScopeHost> {
  WebFoldFeed? _feed;
  CoreFoldLayout _layout = CoreFoldLayout.unmeasured;

  @override
  void initState() {
    super.initState();
    _feed = WebFoldFeed.start(onChange: _handleChange);
    _layout = _feed?.current ?? CoreFoldLayout.unmeasured;
  }

  void _handleChange(CoreFoldLayout layout) {
    if (!mounted) return;
    setState(() => _layout = layout);
  }

  @override
  void dispose() {
    _feed?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) => FoldLayoutScope(
    layout: _layout,
    direction: component.direction,
    child: component.child,
  );
}

/// Publishes the folds the browser reports to everything below it. Mounted by
/// [FoldScopeHost]; an app reads it through [FoldScope.of].
///
/// It also carries the direction the root reads in, which is where a panel
/// that nothing anchors opens (`CoreFoldLayout.startSegmentIndex`). Flutter's
/// dialog route takes that from the app's `Directionality`; the Web has no
/// such scope, so the root that sets `<html dir>` hands its direction to the
/// host that mounts this.
///
/// An ambient scope rather than a module-level value for the reason the other
/// app-wide scopes are: a Jaspr app can be rendered on a server that handles
/// requests concurrently.
class FoldLayoutScope extends InheritedComponent {
  /// Publishes [layout], read in [direction], to [child].
  const FoldLayoutScope({
    required this.layout,
    required super.child,
    this.direction = CoreTextDirection.ltr,
    super.key,
  });

  /// The folds below this scope.
  final CoreFoldLayout layout;

  /// The direction the root reads in.
  final CoreTextDirection direction;

  @override
  bool updateShouldNotify(FoldLayoutScope oldComponent) =>
      layout != oldComponent.layout || direction != oldComponent.direction;
}
