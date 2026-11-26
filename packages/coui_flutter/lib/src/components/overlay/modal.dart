import 'package:coui_flutter/coui_flutter.dart';

// === Local Constants ===

/// Large size constant for screen-filling barrier effects (1,000,000px).
const kModalBigSize = 1000000.0;

/// Default barrier opacity (0.8).
const kModalBarrierOpacity = 0.8;

/// Default barrier color with opacity.
const kDefaultModalBarrierColor = Color.fromRGBO(0, 0, 0, kModalBarrierOpacity);

/// Default border width for fullscreen dialogs (0px).
const kFullscreenBorderWidth = 0.0;

/// Chrome transition duration for the modal surface (matches the legacy
/// `SurfaceCard` surface animation).
const _kModalChromeDuration = Duration(milliseconds: CoreDuration.normal);

/// Theme configuration for the modal backdrop appearance and behavior.
class ModalBackdropTheme {
  /// Creates a [ModalBackdropTheme].
  const ModalBackdropTheme({
    this.barrierColor,
    this.borderRadius,
    this.modal,
    this.padding,
    this.surfaceClip,
  });

  /// Border radius applied to the modal surface.
  final BorderRadiusGeometry? borderRadius;

  /// Padding around the modal content area.
  final EdgeInsetsGeometry? padding;

  /// Barrier color behind the modal.
  final Color? barrierColor;

  /// Whether the backdrop acts as modal (blocks interaction).
  final bool? modal;

  /// Whether to clip the surface for visual effects.
  final bool? surfaceClip;

  /// Returns a copy with the given fields replaced.
  ModalBackdropTheme copyWith({
    ValueGetter<Color?>? barrierColor,
    ValueGetter<BorderRadiusGeometry?>? borderRadius,
    ValueGetter<bool?>? modal,
    ValueGetter<EdgeInsetsGeometry?>? padding,
    ValueGetter<bool?>? surfaceClip,
  }) {
    return ModalBackdropTheme(
      barrierColor: barrierColor == null ? this.barrierColor : barrierColor(),
      borderRadius: borderRadius == null ? this.borderRadius : borderRadius(),
      modal: modal == null ? this.modal : modal(),
      padding: padding == null ? this.padding : padding(),
      surfaceClip: surfaceClip == null ? this.surfaceClip : surfaceClip(),
    );
  }

  /// Merges this theme with [other]. Values from this take priority.
  ModalBackdropTheme mergeWith(ModalBackdropTheme? other) {
    if (other == null) return this;
    return ModalBackdropTheme(
      barrierColor: barrierColor ?? other.barrierColor,
      borderRadius: borderRadius ?? other.borderRadius,
      modal: modal ?? other.modal,
      padding: padding ?? other.padding,
      surfaceClip: surfaceClip ?? other.surfaceClip,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ModalBackdropTheme &&
        other.borderRadius == borderRadius &&
        other.padding == padding &&
        other.barrierColor == barrierColor &&
        other.modal == modal &&
        other.surfaceClip == surfaceClip;
  }

  @override
  int get hashCode => Object.hash(
    borderRadius,
    padding,
    barrierColor,
    modal,
    surfaceClip,
  );
}

/// Visual backdrop widget for modal-style overlays.
class ModalBackdrop extends StatelessWidget {
  /// Creates a [ModalBackdrop].
  const ModalBackdrop({
    this.barrierColor,
    this.borderRadius,
    required this.child,
    this.fadeAnimation,
    super.key,
    this.modal,
    this.padding,
    this.surfaceClip,
  });

  /// Determines if surface clipping should be enabled based on opacity.
  static bool shouldClipSurface(double? surfaceOpacity) {
    return surfaceOpacity == null ? true : surfaceOpacity < 1;
  }

  /// Child widget displayed over the backdrop.
  final Widget child;

  /// Border radius for the backdrop cutout around the child.
  final BorderRadiusGeometry? borderRadius;

  /// Padding around the child widget.
  final EdgeInsetsGeometry? padding;

  /// Barrier color of the backdrop.
  final Color? barrierColor;

  /// Fade in/out transition animation.
  final Animation<double>? fadeAnimation;

  /// Whether the backdrop should act as modal.
  final bool? modal;

  /// Whether to apply surface clipping effects.
  final bool? surfaceClip;

  @override
  Widget build(BuildContext context) {
    final modal = this.modal ?? true;
    final surfaceClip = this.surfaceClip ?? true;
    final borderRadius = this.borderRadius ?? BorderRadius.zero;
    final padding = this.padding ?? EdgeInsets.zero;
    final barrierColor = this.barrierColor ?? kDefaultModalBarrierColor;
    if (!modal) {
      return child;
    }
    final textDirection = Directionality.of(context);
    final resolvedBorderRadius = borderRadius.resolve(textDirection);
    final resolvedPadding = padding.resolve(textDirection);
    Widget paintWidget = CustomPaint(
      painter: SurfaceBarrierPainter(
        barrierColor: barrierColor,
        borderRadius: resolvedBorderRadius,
        clip: surfaceClip,
        padding: resolvedPadding,
      ),
    );
    if (fadeAnimation != null) {
      paintWidget = FadeTransition(
        opacity: fadeAnimation!,
        child: paintWidget,
      );
    }

    return RepaintBoundary(
      child: Stacks(
        fit: .passthrough,
        children: [
          if (!surfaceClip)
            Position.fill(child: IgnorePointer(child: paintWidget)),
          child,
          if (surfaceClip)
            Position.fill(child: IgnorePointer(child: paintWidget)),
        ],
      ),
    );
  }
}

/// Folds the active surface opacity into a fill, leaving a null fill
/// null — a panel told not to fill has nothing to make translucent.
Color? _withSurfaceOpacity(Color? fill, double? opacity) {
  if (fill == null || opacity == null) return fill;
  return fill.withValues(alpha: fill.a * opacity);
}

/// Container widget for modal content with consistent styling.
///
/// surface:behind — the panel a modal route draws over a barrier that
/// covers the page. Everything behind it is page content.
class ModalContainer extends StatelessWidget {
  /// Creates a [ModalContainer].
  const ModalContainer({
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.boxShadow,
    required this.child,
    this.clipBehavior = Clip.none,
    this.duration,
    this.fillColor,
    this.filled = false,
    super.key,
    this.padding,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  /// Model key used to identify full-screen modal mode.
  static const kFullScreenMode = #modal_surface_card_fullscreen;

  /// The child widget to display inside the modal container.
  final Widget child;

  /// Padding applied inside the container around the child.
  final EdgeInsetsGeometry? padding;

  /// Whether the container should have a filled background.
  final bool filled;

  /// Background fill color when [filled] is true.
  final Color? fillColor;

  /// Border radius for the container corners.
  final BorderRadiusGeometry? borderRadius;

  /// Color of the container border.
  final Color? borderColor;

  /// Width of the container border in logical pixels.
  final double? borderWidth;

  /// Clipping behavior for the container content.
  final Clip clipBehavior;

  /// Drop shadow effects applied to the container.
  final List<BoxShadow>? boxShadow;

  /// Surface opacity for backdrop effects.
  final double? surfaceOpacity;

  /// Surface blur intensity for backdrop effects.
  final double? surfaceBlur;

  /// Animation duration for surface transitions.
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final fullScreenMode = Model.maybeOf<bool>(context, kFullScreenMode);
    final theme = Theme.of(context);
    final isFullScreen = fullScreenMode ?? false;
    final effectiveRadius = isFullScreen
        ? BorderRadius.zero
        : (borderRadius ??
              BorderRadius.circular(
                theme.geometry.radius(CoreRadius.radius16) *
                    theme.radiusScaling,
              ));
    final useFill = filled;
    final effectiveBlur = surfaceBlur ?? theme.surfaceBlur;
    // The other half of the material. This panel already fell back to
    // the theme for its blur but painted a fully opaque `surface` fill
    // in front of it, so under a preset the backdrop pass ran and was
    // then covered — the widget declared `surfaceOpacity` and only ever
    // read it to decide whether to clip.
    final effectiveOpacity = surfaceOpacity ?? theme.surfaceOpacity;
    final effectiveBorderWidth = isFullScreen
        ? kFullscreenBorderWidth
        : theme.geometry.stroke(borderWidth ?? CoreStrokeWidth.stroke1);

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    Widget result = _ModalChrome(
      decoration: BoxDecoration(
        color: _withSurfaceOpacity(
          useFill
              ? (fillColor ?? theme.colorScheme.surface.toValue())
              : fillColor,
          effectiveOpacity,
        ),
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: effectiveBorderWidth,
              )
            : null,
        borderRadius: effectiveRadius,
        boxShadow: isFullScreen ? const [] : boxShadow,
      ),
      clipBehavior: clipBehavior,
      duration: resolveMotionDuration(
        context,
        duration ?? _kModalChromeDuration,
      ),
      // Named here rather than carried on a resolved value, because this
      // widget has none — it reads the theme directly. Same alias every
      // other chrome transition in the kit uses, on both platforms.
      curve: CoreEasing.move.toValue(),
      child: content,
    );

    final effectiveSheen = resolveSurfaceSheen(theme);
    if ((effectiveBlur ?? 0) > 0 || effectiveSheen != null) {
      result = SurfaceBlur(
        borderRadius: effectiveRadius,
        surfaceBlur: effectiveBlur,
        surfaceSaturation: theme.surfaceSaturation,
        surfaceBackdropBrightness: theme.surfaceBackdropBrightness,
        surfaceSheen: effectiveSheen,
        // The active material's bend. Every surface that draws the material
        // draws all of it — the frost and the chroma without the bend is a
        // blurred panel, not glass, and the bend is the term the material
        // is named for.
        //
        // Falls back rather than being required: a style that states no
        // refraction leaves this null and the surface simply does not
        // bend, which is how every preset but glass renders.
        refraction: Theme.of(context).surfaceRefraction,
        child: result,
      );
    }

    return result;
  }
}

// Reset only chrome animation state when motion is disabled during a flight.
// The stable content subtree retains focus and state across that reset, while
// the enclosing SurfaceBlur keeps its filter and shader resources mounted.
class _ModalChrome extends StatefulWidget {
  const _ModalChrome({
    required this.decoration,
    required this.clipBehavior,
    required this.duration,
    required this.curve,
    required this.child,
  });

  final BoxDecoration decoration;
  final Clip clipBehavior;
  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<_ModalChrome> createState() => _ModalChromeState();
}

class _ModalChromeState extends State<_ModalChrome> {
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: ValueKey(widget.duration == Duration.zero),
    decoration: widget.decoration,
    clipBehavior: widget.clipBehavior,
    duration: widget.duration,
    curve: widget.curve,
    child: KeyedSubtree(key: _contentKey, child: widget.child),
  );
}

/// Custom painter that creates a barrier effect with an optional cutout.
class SurfaceBarrierPainter extends CustomPainter {
  /// Creates a [SurfaceBarrierPainter].
  const SurfaceBarrierPainter({
    required this.barrierColor,
    required this.borderRadius,
    required this.clip,
    this.padding = EdgeInsets.zero,
  });

  /// Large screen size for painting operations.
  static const bigScreen = Size(kModalBigSize, kModalBigSize);

  /// Large offset to center the big screen.
  static const bigOffset = Offset(-(kModalBigSize / 2), -(kModalBigSize / 2));

  /// Whether to clip a cutout area in the barrier.
  final bool clip;

  /// Border radius for the cutout area.
  final BorderRadius borderRadius;

  /// Color of the barrier.
  final Color barrierColor;

  /// Padding around the cutout area.
  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = barrierColor
      ..blendMode = .srcOver
      ..style = .fill;
    if (clip) {
      Rect rect = Offset.zero & size;
      rect = _padRect(rect);
      final path = Path()
        ..addRect(bigOffset & bigScreen)
        ..addRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: borderRadius.topLeft,
            topRight: borderRadius.topRight,
            bottomRight: borderRadius.bottomRight,
            bottomLeft: borderRadius.bottomLeft,
          ),
        );
      path.fillType = .evenOdd;
      canvas.clipPath(path);
    }
    canvas.drawRect(bigOffset & bigScreen, paint);
  }

  @override
  bool shouldRepaint(covariant SurfaceBarrierPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.barrierColor != barrierColor ||
        oldDelegate.padding != padding ||
        oldDelegate.clip != clip;
  }

  Rect _padRect(Rect rect) {
    return Rect.fromLTRB(
      rect.left + padding.left,
      rect.top + padding.top,
      rect.right - padding.right,
      rect.bottom - padding.bottom,
    );
  }
}
