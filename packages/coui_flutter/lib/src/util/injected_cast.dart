/// The cast a surface style injects into components that state no
/// shadow of their own.
library;

import 'package:coui_flutter/coui_flutter.dart';

/// The active style's injected cast, as paint-ready [BoxShadow]s.
///
/// A surface style can state that every boxed thing under it carries a
/// shadow — neo-brutalism's whole identity is that cast. Components that
/// author a shadow get theirs bent; components that author none have
/// nothing to bend, so the style contributes the cast outright. That
/// second path is what this returns.
///
/// `OutlinedContainer` reaches it by composition, so components that
/// compose it need nothing here. This is for the ones that draw their
/// own box — either because composing would cost more than it gives (a
/// surface with its own hover fill, say) or because the migration has
/// not happened yet. Without it each of those would re-derive the same
/// three steps, and the sweep would leave as many slightly different
/// casts as it touched components.
///
/// Returns an empty list under every style that injects nothing, so a
/// component can hand the result straight to `BoxDecoration.boxShadow`
/// without asking which style is active.
///
/// Inset layers are dropped for the same reason the container drops
/// them: `BoxDecoration.boxShadow` draws outer shadows, and an inset
/// layer handed to it paints as an outer one.
List<BoxShadow> resolveInjectedCast(ThemeData theme) {
  final cast = theme.geometry.controlShadow;
  if (cast.isEmpty) return const <BoxShadow>[];

  final base = theme.colorScheme
      .resolve(const CoreColor.token(CoreColors.shadow))
      .toValue();

  // Identity geometry on purpose: `controlShadow` is what the style
  // already decided to throw, so running the style's own transform over
  // it again would bend a value that was never authored by a component.
  // It is still a shadow on the page, so the theme's brightness
  // strengthens it exactly as it does every authored one.
  const applied = CoreSurfaceGeometryConstraint();

  return theme.geometry
      .strengthen(cast.where((layer) => !layer.inset).toList())
      .toValue(base: base, geometry: applied);
}

/// Paints [shadows] behind [child] the way CSS paints an outer
/// `box-shadow` — outside the box only.
///
/// The two platforms disagree here, and the disagreement is invisible
/// until something translucent sits on top. CSS clips an outer shadow to
/// outside the border box, so a fill at 80% alpha blends with the page.
/// Flutter's `BoxDecoration.boxShadow` draws a *filled* rounded rect
/// behind the box and lets the background paint over it, so the same
/// fill blends with the shadow instead — a hovered button showed its own
/// cast through itself, and only on Flutter.
///
/// Only worth reaching for where something translucent can end up over
/// the cast (a hover fill, a disabled alpha). A surface that is opaque in
/// every state cannot tell the difference and can keep using
/// `BoxDecoration.boxShadow`.
class InjectedCast extends StatelessWidget {
  /// Creates an [InjectedCast].
  const InjectedCast({
    required this.shadows,
    required this.borderRadius,
    required this.child,
    this.visible = true,
    this.duration = Duration.zero,
    super.key,
  });

  /// The cast to paint. Empty paints nothing at all.
  final List<BoxShadow> shadows;

  /// The box's own radius — the shape knocked out of the shadow.
  final BorderRadius borderRadius;

  /// The box. Painted after the shadows, so it sits on top.
  final Widget child;

  /// Whether the cast is currently drawn.
  ///
  /// Separate from an empty [shadows] so there is still something to
  /// animate towards when it hides — a caller that swapped the list for
  /// an empty one would leave nothing to interpolate, and the cast would
  /// cut out instead of retreating.
  final bool visible;

  /// How long a change to [visible] takes.
  ///
  /// The press affordance hides the cast and travels the control into
  /// the space it vacates, and those two have to move together — a cast
  /// that cuts out while the control slides reads as a flicker rather
  /// than as a press. [Duration.zero] snaps, for surfaces with no such
  /// pairing.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (shadows.isEmpty) return child;

    if (duration == Duration.zero) {
      if (!visible) return child;
      return CustomPaint(
        painter: _CastPainter(shadows: shadows, borderRadius: borderRadius),
        child: child,
      );
    }

    // Tweened rather than swapped: `BoxShadow.lerpList` against an empty
    // list is what `AnimatedContainer` did for this before the paint moved
    // out of the decoration, so the press keeps the motion it had.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: visible ? 1 : 0),
      duration: duration,
      builder: (context, t, inner) {
        final painted = BoxShadow.lerpList(const <BoxShadow>[], shadows, t);
        if (painted == null || painted.isEmpty) return inner!;
        return CustomPaint(
          painter: _CastPainter(shadows: painted, borderRadius: borderRadius),
          child: inner,
        );
      },
      child: child,
    );
  }
}

class _CastPainter extends CustomPainter {
  const _CastPainter({required this.shadows, required this.borderRadius});

  final List<BoxShadow> shadows;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final box = borderRadius.toRRect(Offset.zero & size);

    // The knock-out. Bounds are the box grown by the furthest any layer
    // reaches, so the clip never crops a shadow that travels further than
    // it blurs.
    var reach = 0.0;
    for (final shadow in shadows) {
      final layer =
          shadow.offset.distance + shadow.blurRadius + shadow.spreadRadius;
      if (layer > reach) reach = layer;
    }
    // One path holding both rings, with the even-odd rule doing the
    // subtraction: a point inside the box is enclosed by two subpaths, so
    // it falls outside the fill and the clip drops it.
    //
    // Deliberately not `Path.combine(PathOperation.difference, …)`, which
    // is the obvious way to write this and is wrong here. That call is a
    // boolean path operation, and on the web build it comes back without
    // having subtracted anything — the clip then keeps the whole box and
    // the cast paints straight over the surface it belongs behind. It is
    // invisible in `flutter test`, whose rasteriser does perform the
    // subtraction, so the two disagree and only the browser is wrong.
    // Even-odd needs no boolean op: the fill rule is carried by the path
    // itself, so both rasterisers read it the same way.
    //
    // A plain `clipRect(…, ClipOp.difference)` is also wrong, for a
    // different reason worth writing down: it knocks out the bounding box
    // rather than the rounded shape, which erases the cast in the gap
    // between a corner and its bounding box. On a pill that gap is the
    // whole cap, and it shows as a white notch beside the shadow.
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(reach + 1))
      ..addRRect(box);

    canvas.save();
    canvas.clipPath(outside);
    for (final shadow in shadows) {
      canvas.drawRRect(
        box.shift(shadow.offset).inflate(shadow.spreadRadius),
        shadow.toPaint(),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CastPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.shadows.length != shadows.length ||
      Iterable<int>.generate(
        shadows.length,
      ).any((i) => oldDelegate.shadows[i] != shadows[i]);
}
