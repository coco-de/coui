import 'package:coui_flutter/coui_flutter.dart';

/// App-level host that scales the app content behind an open drawer —
/// the shadcn "zoom-out" backdrop transform.
///
/// The CoUI app shell (`CoUILayer`) mounts one of these around the
/// navigator subtree. A `Drawer` route opened with
/// `transformBackdrop: true` registers its route animation here; the
/// host drives the backdrop with it:
///
/// ```text
/// DrawerBackdropLayer
///   └─ ClipRRect (cornerRadius × t — animated corner clip)
///        └─ Transform.scale (1.0 → backdropScale as t → 1)
///             └─ child (navigator + app content)
/// ```
///
/// The wrapper structure is constant (identity transform + `Clip.none`
/// while idle) so registering / unregistering a drawer never reparents
/// the app subtree — descendant state survives. Without a host in the
/// tree the drawer's backdrop transform silently no-ops (plain
/// `MaterialApp` embeds and widget tests).
class DrawerBackdropLayer extends StatefulWidget {
  /// Creates a [DrawerBackdropLayer].
  const DrawerBackdropLayer({required this.child, super.key});

  /// The nearest host state, or null when no CoUI app shell installed
  /// one (the drawer then skips the backdrop transform).
  static DrawerBackdropLayerState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_DrawerBackdropScope>()?.state;

  /// The app content the backdrop transform scales.
  final Widget child;

  @override
  State<DrawerBackdropLayer> createState() => DrawerBackdropLayerState();
}

/// Registration handle a drawer route holds while it participates in
/// the backdrop transform.
class DrawerBackdropRegistration {
  const DrawerBackdropRegistration._({
    required this.animation,
    required this.scale,
    required this.cornerRadius,
    required this.panel,
  });

  /// The drawer route's open/close animation (0 = closed, 1 = open).
  final Animation<double> animation;

  /// The backdrop scale when fully open (`CoreDrawerStyle.backdropScale`).
  final double scale;

  /// The corner radius the backdrop clips to when fully open — the
  /// full 4-corner [BorderRadius] (not a scalar), so an asymmetric
  /// `CoreDrawerStyle.backdropCornerRadius` override survives all the
  /// way to paint (`BorderRadius.lerp` interpolates each corner
  /// independently, matching Web's CSS `border-radius` shorthand).
  final BorderRadius cornerRadius;

  /// The drawer panel (slide transition included), rendered by the
  /// host **above** the scaled-and-clipped backdrop. It cannot live in
  /// the route's own subtree in this mode: the route sits inside the
  /// navigator, which the host clips — and no descendant can paint
  /// outside an ancestor clip, so a route-rendered panel would get its
  /// corners cut and its edges inset with the backdrop.
  final Widget panel;

  /// The scale factor at progress [t] (1.0 at 0, [scale] at 1).
  double scaleAt(double t) => 1 - (1 - scale) * t;
}

/// State for [DrawerBackdropLayer] — drawer routes [register] /
/// [unregister] their animations through it.
class DrawerBackdropLayerState extends State<DrawerBackdropLayer> {
  List<DrawerBackdropRegistration> _registrations = const [];

  /// Registers a drawer route's animation; the host starts driving the
  /// backdrop from it. Returns the handle to pass to [unregister].
  DrawerBackdropRegistration register({
    required Animation<double> animation,
    required double scale,
    required BorderRadius cornerRadius,
    required Widget panel,
  }) {
    final registration = DrawerBackdropRegistration._(
      animation: animation,
      scale: scale,
      cornerRadius: cornerRadius,
      panel: panel,
    );
    setState(() => _registrations = [..._registrations, registration]);
    return registration;
  }

  /// Removes a registration when its drawer route is disposed.
  void unregister(DrawerBackdropRegistration registration) {
    final remaining = _registrations
        .where((entry) => entry != registration)
        .toList();
    if (!mounted) {
      _registrations = remaining;
      return;
    }
    setState(() => _registrations = remaining);
  }

  /// The most advanced open progress across active registrations.
  double get _progress {
    var t = 0.0;
    for (final registration in _registrations) {
      if (registration.animation.value > t) t = registration.animation.value;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    // The first (root) registration owns the spec; later stacked
    // drawers reuse it rather than compounding the scale.
    final root = _registrations.isEmpty ? null : _registrations.first;

    return _DrawerBackdropScope(
      state: this,
      child: Stacks(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([
              for (final registration in _registrations) registration.animation,
            ]),
            builder: (context, child) {
              final t = root == null ? 0.0 : _progress;
              final scale = root == null ? 1.0 : root.scaleAt(t);
              // Per-corner lerp (not a uniform scalar × t) — preserves
              // an asymmetric `cornerRadius` override through the open
              // animation instead of collapsing every corner to one
              // representative value.
              final radius = root == null
                  ? BorderRadius.zero
                  : BorderRadius.lerp(.zero, root.cornerRadius, t)!;
              // Constant wrapper structure — identity transform and a
              // disabled clip while idle so the app subtree is never
              // reparented (descendant state survives).
              return Transform.scale(
                scale: scale,
                child: ClipRRect(
                  borderRadius: radius,
                  clipBehavior: t == 0 ? .none : .antiAlias,
                  child: child,
                ),
              );
            },
            child: widget.child,
          ),
          // Registered drawer panels paint above the clipped backdrop
          // (the scrim stays inside the clip — it dims exactly the
          // visible backdrop).
          for (final registration in _registrations) registration.panel,
        ],
      ),
    );
  }
}

class _DrawerBackdropScope extends InheritedWidget {
  const _DrawerBackdropScope({required this.state, required super.child});

  final DrawerBackdropLayerState state;

  @override
  bool updateShouldNotify(_DrawerBackdropScope oldWidget) =>
      state != oldWidget.state;
}
