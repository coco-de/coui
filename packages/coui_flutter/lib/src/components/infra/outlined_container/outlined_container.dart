import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/surface_fade.dart';

/// Unified cross-platform outlined-container chrome primitive.
///
/// Wraps [child] in a token-based chrome (border + radius + optional
/// padding + shadow + blur). The same component on Web is built on
/// `<div>` + Tailwind utility classes; both platforms read the same
/// [CoreOutlinedContainerContract] fields and share defaults via
/// [CoreOutlinedContainerTheme].
///
/// All chrome / dimensional overrides flow through the single
/// [containerStyle] (a [CoreOutlinedContainerStyle]) so the
/// nested-merge chain (`theme.outlinedContainer.style` ←
/// `widget.containerStyle`) works uniformly per Epic #1302.
///
/// Example:
/// ```dart
/// OutlinedContainer(
///   containerStyle: const CoreOutlinedContainerStyle(
///     borderStyle: CoreOutlinedContainerBorderStyle.dashed,
///     elevation: CoreOutlinedContainerElevation.soft,
///     padding: CoreEdgeInsets.all(CoreSpace.space16),
///   ),
///   child: const Text('Card body'),
/// )
/// ```
///
/// surface:behind — the box every in-flow panel composes. What shows through
/// it is the page it is laid on, not a parent panel.
///
/// surface:content — the default for a box with no evidence that it
/// floats. A caller that has that evidence says so through [role].
class OutlinedContainer extends StatelessWidget
    implements CoreOutlinedContainerContract<Widget> {
  /// Creates a [OutlinedContainer].
  const OutlinedContainer({
    super.key,
    this.child,
    this.containerStyle,
    this.refraction,
    this.role = .defaultRole,
  });

  @override
  final Widget? child;

  @override
  final CoreSurfaceRefraction? refraction;

  @override
  final CoreOutlinedContainerStyle? containerStyle;

  @override
  final CoreSurfaceRole role;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveOutlinedContainer(
      context,
      containerStyle: containerStyle,
      role: role,
    );

    // Dashed / dotted borders use a CustomPaint overlay since Flutter's
    // BoxDecoration only supports solid / none. Solid + none are
    // rendered natively via Border.all.
    final usePainter =
        resolved.borderStyle == .dashed || resolved.borderStyle == .dotted;
    final renderBorderStyle = resolved.borderStyle == .none
        ? BorderStyle.none
        : (usePainter ? BorderStyle.none : BorderStyle.solid);

    // A fill something can be seen through — a glass material's share, a
    // translucent token, a transparent box — would show a decoration shadow
    // through itself: Flutter paints `BoxDecoration.boxShadow` as a full shape
    // behind the box, where CSS draws `box-shadow` outside the border box only.
    // Such a box takes its cast from a knocked-out painter instead
    // (`cross-platform/api.md`, "그림자는 두 플랫폼이 다른 곳에 칠한다"); an
    // opaque one keeps the decoration, which it cannot tell apart.
    final gradient = resolved.backgroundGradient;
    final seeThrough = gradient == null
        ? resolved.backgroundColor.a < 1
        : gradient.colors.any((c) => c.a < 1);
    final knockOutCast = seeThrough && resolved.boxShadow.isNotEmpty;

    Widget body = _OutlinedContainerMotion(
      resolved: resolved,
      decoration: BoxDecoration(
        // A gradient is painted instead of the colour: a paint that carried
        // both would scale the gradient by the colour's alpha.
        color: resolved.backgroundGradient == null
            ? resolved.backgroundColor
            : null,
        gradient: resolved.backgroundGradient,
        border: Border.all(
          color: resolved.borderColor,
          width: resolved.borderWidth,
          style: renderBorderStyle,
        ),
        borderRadius: resolved.borderRadius,
        boxShadow: knockOutCast ? null : resolved.boxShadow,
      ),
      child: child,
    );

    // Inset layers are drawn over the surface, clipped to it. They cannot
    // ride the decoration: Flutter paints those shadows before the
    // background, so an inset layer left there is covered by the surface
    // and shows only where it spills past the edge.
    body = InsetShadow(
      shadows: resolved.insetBoxShadow,
      radius: resolved.borderRadius,
      child: body,
    );

    if (usePainter) {
      // The dashes carry no information a reader needs, and the painter
      // already says so: with no `semanticsBuilder` it contributes no node.
      // Wrapping this in `ExcludeSemantics` would hide the CHILD too — the
      // content of the container, not its border. The Web twin marks only
      // its dash overlay `aria-hidden` for the same reason.
      body = CustomPaint(
        foregroundPainter: _DashedRectPainter(
          color: resolved.borderColor,
          strokeWidth: resolved.borderWidth,
          radius: resolved.borderRadius,
          dotted: resolved.borderStyle == .dotted,
          dashLength: resolved.dashLength,
          dashGap: resolved.dashSpacing,
        ),
        child: body,
      );
    }

    // Delegated rather than open-coded. This path used to build its own
    // `BackdropFilter`, which meant the surface material had two
    // implementations — and the moment one of them learned about chroma
    // or an edge band, a `Card` and a `Dock` under the same preset drew
    // different glass. That divergence is invisible until the two are
    // put side by side, so the fix is to leave one implementation.
    final blurSigma = resolved.surfaceBlur;
    final sheen = resolved.surfaceSheen;
    // The caller's request when there is one, the surface's own
    // material's otherwise (the resolver settles which material that
    // is: the surrounding theme's, or the one a `surfaceStyle` names).
    // Falling back rather than requiring it is what makes the shipped
    // glass preset bend at all: measured, nothing in the kit passed a
    // refraction to anything, so the material had every term except the
    // one it is named for.
    //
    // What travels is the request — a bezel fraction and a fallback
    // blur. The displacement itself is still built here, from this
    // surface's own rectangle, exactly as it was.
    final materialRefraction = refraction ?? resolved.refraction;
    final hasMaterial = (blurSigma != null && blurSigma > 0) || sheen != null;
    final surface = body;

    // The surface as it is drawn at [fadeProgress] of the way in view, or at
    // rest where it is null — see `SurfaceFadeAdopter`.
    Widget drawMaterial(double? fadeProgress) => hasMaterial
        ? SurfaceBlur(
            borderRadius: resolved.borderRadius,
            surfaceBlur: blurSigma,
            surfaceSaturation: resolved.surfaceSaturation,
            surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
            surfaceSheen: sheen,
            refraction: materialRefraction,
            fadeProgress: fadeProgress,
            child: surface,
          )
        : surface;

    Widget drawSurface(double? fadeProgress) {
      final drawn = drawMaterial(fadeProgress);
      if (!knockOutCast) return drawn;
      // Behind the surface and outside what fades with it, so it fades by
      // the progress itself — the way a glass `Popup` throws its cast.
      return InjectedCast(
        shadows: fadeShadows(resolved.boxShadow, fadeProgress),
        borderRadius: resolved.borderRadius,
        child: drawn,
      );
    }

    // A container that is the surface of a panel a host is fading is offered
    // the fade, whether or not it draws a pass: an opaque one declines, and
    // with it declining nothing below it is asked. With no host above,
    // nothing is mounted and the container is built without a wrapper.
    final fadeScope = SurfaceFadeScope.maybeOf(context);
    if (fadeScope == null) return drawSurface(null);

    return SurfaceFadeAdopter(
      scope: fadeScope,
      drawsPass: surfaceDrawsBackdropPass(
        blur: blurSigma,
        refraction: materialRefraction,
      ),
      builder: drawSurface,
    );
  }
}

// Keep the framework's container interpolation and its normal paint/layout
// behavior. Changing duration alone does not stop an already-running implicit
// animation, so entering zero-duration mode replaces only the chrome states.
// The keyed content subtree survives that replacement with focus and local
// state intact; the enclosing SurfaceBlur and its shader also remain mounted.
class _OutlinedContainerMotion extends StatefulWidget {
  const _OutlinedContainerMotion({
    required this.resolved,
    required this.decoration,
    required this.child,
  });

  final ResolvedOutlinedContainer resolved;
  final BoxDecoration decoration;
  final Widget? child;

  @override
  State<_OutlinedContainerMotion> createState() =>
      _OutlinedContainerMotionState();
}

class _OutlinedContainerMotionState extends State<_OutlinedContainerMotion> {
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final resolved = widget.resolved;
    return AnimatedContainer(
      key: ValueKey(resolved.duration == Duration.zero),
      decoration: widget.decoration,
      width: resolved.width,
      height: resolved.height,
      clipBehavior: resolved.clipBehavior,
      duration: resolved.duration,
      curve: resolved.curve,
      child: AnimatedContainer(
        padding: resolved.padding,
        decoration: BoxDecoration(
          borderRadius: subtractByBorder(
            resolved.borderWidth,
            resolved.borderRadius,
          ),
        ),
        // Clip content to the inner path, preserving the outer border.
        clipBehavior: resolved.clipBehavior,
        duration: resolved.duration,
        curve: resolved.curve,
        child: widget.child == null
            ? null
            : KeyedSubtree(key: _contentKey, child: widget.child!),
      ),
    );
  }
}

/// Paints a rounded-rect border in dashed or dotted style. Used by
/// [OutlinedContainer] when `borderStyle == dashed | dotted` since
/// Flutter's `BoxDecoration` does not support either natively.
class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dotted,
    required this.dashLength,
    required this.dashGap,
  });

  final Color color;
  final double strokeWidth;
  final BorderRadius radius;
  final bool dotted;
  final double dashLength;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    // A stroke is centred on its path. Keep the complete declared width
    // inside the allocated border box, as Border.all and the Web SVG do.
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: radius.topLeft,
      topRight: radius.topRight,
      bottomRight: radius.bottomRight,
      bottomLeft: radius.bottomLeft,
    ).deflate(strokeWidth / 2);
    final r = rrect.scaleRadii();
    // SVG rect starts at the top-left tangent and travels clockwise.
    // addRRect starts elsewhere, which shifts every dash despite equal tokens.
    final path = Path()
      ..moveTo(r.left + r.tlRadiusX, r.top)
      ..lineTo(r.right - r.trRadiusX, r.top)
      ..arcToPoint(Offset(r.right, r.top + r.trRadiusY), radius: r.trRadius)
      ..lineTo(r.right, r.bottom - r.brRadiusY)
      ..arcToPoint(Offset(r.right - r.brRadiusX, r.bottom), radius: r.brRadius)
      ..lineTo(r.left + r.blRadiusX, r.bottom)
      ..arcToPoint(Offset(r.left, r.bottom - r.blRadiusY), radius: r.blRadius)
      ..lineTo(r.left, r.top + r.tlRadiusY)
      ..arcToPoint(Offset(r.left + r.tlRadiusX, r.top), radius: r.tlRadius)
      ..close();
    if (dotted) {
      // SVG dotted strokes use zero-length round caps at 2 × width.
      // A finite path segment plus round caps would draw a capsule.
      if (strokeWidth <= 0) return;
      final paint = Paint()..color = color;
      for (final metric in path.computeMetrics()) {
        for (
          var offset = 0.0;
          offset < metric.length;
          offset += strokeWidth * 2
        ) {
          final tangent = metric.getTangentForOffset(offset)!;
          canvas.drawCircle(tangent.position, strokeWidth / 2, paint);
        }
      }
      return;
    }
    final draw = Path();
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = .butt
      ..style = .stroke;
    for (final metric in path.computeMetrics()) {
      var i = 0.0;
      while (i < metric.length) {
        final end = (i + dashLength).clamp(0.0, metric.length);
        final a = metric.getTangentForOffset(i)!;
        final b = metric.getTangentForOffset(end)!;
        final delta = b.position - a.position;
        // Straight dashes have no joins. Use the line primitive for them;
        // keep the extracted contour whenever a dash crosses a corner.
        final straight =
            a.vector == b.vector &&
            ((delta.dy == 0 &&
                    a.vector.dy == 0 &&
                    end - i <= r.width &&
                    delta.dx * a.vector.dx > 0) ||
                (delta.dx == 0 &&
                    a.vector.dx == 0 &&
                    end - i <= r.height &&
                    delta.dy * a.vector.dy > 0));
        if (straight) {
          canvas.drawLine(a.position, b.position, paint);
        } else {
          draw.addPath(metric.extractPath(i, end), .zero);
        }
        i += dashLength + dashGap;
      }
    }
    canvas.drawPath(
      draw,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter old) {
    return old.color != color ||
        old.strokeWidth != strokeWidth ||
        old.radius != radius ||
        old.dotted != dotted ||
        old.dashLength != dashLength ||
        old.dashGap != dashGap;
  }
}

/// Chain sugar for merging a [CoreOutlinedContainerStyle] patch into
/// [OutlinedContainer.containerStyle] without hand-reconstructing every
/// field. Mirrors the Web `OutlinedContainer.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreOutlinedContainerStyle.merge` right-side-wins semantics).
///
/// ```dart
/// OutlinedContainer(child: const Text('Card body')).withStyle(
///   const CoreOutlinedContainerStyle(
///     borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
///   ),
/// )
/// ```
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreOutlinedContainerStyle.borderRadius] and `.primary` sets
/// [CoreOutlinedContainerStyle.backgroundColor]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// OutlinedContainer(child: const Text('Card body')).radius4.primary
/// ```
extension OutlinedContainerStyleChain on OutlinedContainer {
  /// Sets the content padding.
  OutlinedContainer contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreOutlinedContainerStyle(padding: value));

  /// Sets the border color.
  OutlinedContainer borderColor(CoreColor value) =>
      withStyle(CoreOutlinedContainerStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  OutlinedContainer borderWidth(double value) =>
      withStyle(CoreOutlinedContainerStyle(borderWidth: value));

  /// Sets the background paint and preserves the other style fields.
  OutlinedContainer backgroundColor(CoreColor value) =>
      withStyle(CoreOutlinedContainerStyle(backgroundColor: value));

  /// Returns a copy of this [OutlinedContainer] with [patch] merged into
  /// [containerStyle] (patch fields win on conflict).
  OutlinedContainer withStyle(CoreOutlinedContainerStyle patch) => .new(
    key: key,
    containerStyle: (containerStyle ?? const CoreOutlinedContainerStyle())
        .merge(
          patch,
        ),
    child: child,
    role: role,
    refraction: refraction,
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  OutlinedContainer get radius0 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  OutlinedContainer get radius2 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  OutlinedContainer get radius4 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  OutlinedContainer get radius6 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  OutlinedContainer get radius8 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  OutlinedContainer get radius10 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  OutlinedContainer get radius12 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  OutlinedContainer get radius14 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  OutlinedContainer get radius16 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  OutlinedContainer get radius20 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  OutlinedContainer get radius24 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  OutlinedContainer get radius28 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  OutlinedContainer get radius32 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  OutlinedContainer get radius36 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  OutlinedContainer get radius40 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  OutlinedContainer get radius48 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  OutlinedContainer get radius56 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  OutlinedContainer get radius64 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  OutlinedContainer get radius9999 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  OutlinedContainer get primary => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  OutlinedContainer get secondary => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  OutlinedContainer get tertiary => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  OutlinedContainer get surface => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  OutlinedContainer get surfaceContainer => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  OutlinedContainer get error => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  OutlinedContainer get success => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  OutlinedContainer get warning => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  OutlinedContainer get info => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  OutlinedContainer get outline => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  OutlinedContainer get transparent => withStyle(
    const CoreOutlinedContainerStyle(backgroundColor: .transparent),
  );
}
