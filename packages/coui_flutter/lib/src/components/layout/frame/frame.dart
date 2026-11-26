import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform layout primitive.
///
/// `Frame` is the Flutter equivalent of a Figma Frame / CSS `<div>`. It
/// absorbs the role of `Container`, `Row`, `Column`, `Wrap`, `Padding`,
/// `Center`, `Align`, `SizedBox`, `Expanded`, `DecoratedBox`, `Opacity`,
/// `Transform`, `ClipRRect`, and `Visibility` into a single component
/// that maps 1:1 onto Figma's "Inspect" panel slots.
///
/// Resolve precedence per slot: widget parameter > theme override
/// (`CoreFrameTheme`) > component default.
///
/// ```dart
/// Frame(
///   direction: CoreFrameDirection.row,
///   gap: CoreSpace.space12,
///   padding: const EdgeInsets.all(CoreSpace.space16),
///   backgroundColor: theme.colorScheme.surface,
///   borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
///   children: [icon, label],
/// )
/// ```
class Frame extends StatelessWidget
    implements CoreFrameContract<Widget, Matrix4> {
  /// Creates a [Frame].
  const Frame({
    super.key,
    this.direction,
    this.gap,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.alignment,
    this.width,
    this.height,
    this.minWidth,
    this.minHeight,
    this.maxWidth,
    this.maxHeight,
    this.flex,
    this.fit,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.backgroundImage,
    this.borderColor,
    this.borderWidth,
    this.borderStyle,
    this.borderRadius,
    this.boxShadow,
    this.innerShadow,
    this.layerBlur,
    this.backdropBlur,
    this.elevation,
    this.clipBehavior = CoreFrameStyle.defaultClipBehavior,
    this.opacity,
    this.transform,
    this.transformAlignment,
    this.visible = true,
    this.onTap,
    this.onHover,
    this.onFocus,
    this.cursor,
    this.tag = 'div',
    this.a11y,
    this.duration,
    this.frameStyle,
    this.child,
    this.children,
  }) : assert(
         child == null || children == null,
         'Pass either child or children, not both.',
       );

  // --- Layout ---

  @override
  final CoreFrameDirection? direction;

  @override
  final double? gap;

  @override
  final CoreMainAxisAlignment? mainAxisAlignment;

  @override
  final CoreCrossAxisAlignment? crossAxisAlignment;

  @override
  final CoreAlignment? alignment;

  // --- Sizing ---

  @override
  final double? width;

  @override
  final double? height;

  @override
  final double? minWidth;

  @override
  final double? minHeight;

  @override
  final double? maxWidth;

  @override
  final double? maxHeight;

  // --- Flex ---

  @override
  final int? flex;

  @override
  final CoreFlexFit? fit;

  // --- Spacing ---

  @override
  final CoreEdgeInsets? padding;

  @override
  final CoreEdgeInsets? margin;

  // --- Fill ---

  @override
  final CoreColor? backgroundColor;

  @override
  final CoreGradient? gradient;

  @override
  final CoreImageSource? backgroundImage;

  // --- Stroke ---

  @override
  final CoreColor? borderColor;

  @override
  final double? borderWidth;

  @override
  final CoreFrameBorderStyle? borderStyle;

  @override
  final CoreBorderRadius? borderRadius;

  // --- Effects ---

  @override
  final List<CoreShadowLayer>? boxShadow;

  @override
  final List<CoreShadowLayer>? innerShadow;

  @override
  final double? layerBlur;

  @override
  final double? backdropBlur;

  @override
  final CoreFrameElevation? elevation;

  // --- Behaviour ---

  @override
  final CoreClipBehavior clipBehavior;

  @override
  final double? opacity;

  @override
  final Matrix4? transform;

  @override
  final CoreAlignment? transformAlignment;

  @override
  final bool visible;

  // --- Interaction ---

  @override
  final void Function()? onTap;

  @override
  final CoreValueChanged<bool>? onHover;

  @override
  final CoreValueChanged<bool>? onFocus;

  @override
  final CoreCursor? cursor;

  // --- HTML / SEO ---

  @override
  final String tag;

  // --- Accessibility ---

  @override
  final CoreFrameA11y? a11y;

  /// Animation duration for chrome property changes.
  final Duration? duration;

  // --- Style slot ---

  @override
  final CoreFrameStyle? frameStyle;

  // --- Children ---

  @override
  final Widget? child;

  @override
  final List<Widget>? children;

  Widget _buildContent(BuildContext context, {required double spacing}) {
    final kids = children ?? (child != null ? [child!] : const <Widget>[]);
    if (direction == null) {
      if (kids.length <= 1) {
        return kids.isEmpty ? const SizedBox.shrink() : kids.first;
      }
      // Multiple children with no direction → stack them vertically by
      // default. This matches CSS `<div>` block-flow semantics.
      return Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: kids,
      );
    }

    final dir = direction!;
    final mainAlign = mainAxisAlignment != null
        ? coreMainAxisAlignmentToFlutter(mainAxisAlignment!)
        : MainAxisAlignment.start;
    final crossAlign = crossAxisAlignment != null
        ? coreCrossAxisAlignmentToFlutter(crossAxisAlignment!)
        : CrossAxisAlignment.start;
    if (dir == .wrap) {
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        crossAxisAlignment: _wrapCrossAxisAlignmentFromCore(crossAlign),
        children: kids,
      );
    }

    final axis = coreFrameDirectionToAxis(dir)!;
    if (axis == .horizontal) {
      return Row(
        mainAxisAlignment: mainAlign,
        mainAxisSize: .min,
        crossAxisAlignment: crossAlign,
        textDirection: dir == .rowReverse ? .rtl : null,
        spacing: spacing,
        children: kids,
      );
    }
    return Column(
      mainAxisAlignment: mainAlign,
      mainAxisSize: .min,
      crossAxisAlignment: crossAlign,
      verticalDirection: coreFrameDirectionToVerticalDirection(dir),
      spacing: spacing,
      children: kids,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final resolved = resolveFrame(
      context,
      clipBehavior: clipBehavior,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderStyle: borderStyle,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      gap: gap,
      elevation: elevation,
      boxShadow: boxShadow,
      innerShadow: innerShadow,
      gradient: gradient,
      backgroundImage: backgroundImage,
      duration: duration,
      frameStyle: frameStyle,
    );
    final resolvedBackground = resolved.backgroundColor;
    final resolvedBorderColor = resolved.borderColor;
    final resolvedBorderWidth = resolved.borderWidth;
    final resolvedBorderStyle = resolved.borderStyle;
    final resolvedBorderRadius = resolved.borderRadius;
    final resolvedPadding = resolved.padding;
    final resolvedShadows = resolved.boxShadow;
    final resolvedInnerShadows = resolved.innerShadow;
    final resolvedGradient = resolved.gradient;
    final resolvedBackgroundImage = resolved.backgroundImage;
    final resolvedClip = resolved.clipBehavior;
    final resolvedDuration = resolved.duration;

    var current = _buildContent(context, spacing: resolved.gap);

    if (resolvedPadding != null && resolvedPadding != EdgeInsets.zero) {
      current = Padding(padding: resolvedPadding, child: current);
    }

    final hasChrome =
        resolvedBackground != null ||
        resolvedBorderColor != null ||
        resolvedBorderRadius != null ||
        resolvedShadows.isNotEmpty ||
        resolvedGradient != null ||
        resolvedBackgroundImage != null;

    final hasSize =
        width != null ||
        height != null ||
        minWidth != null ||
        maxWidth != null ||
        minHeight != null ||
        maxHeight != null;

    if (hasChrome) {
      final scaledBorderWidth = resolvedBorderWidth ?? 0.0;
      final renderBorderStyle = resolvedBorderColor == null
          ? BorderStyle.none
          : (resolvedBorderStyle == .dashed || resolvedBorderStyle == .dotted
                ? BorderStyle.none
                : coreFrameBorderStyleToFlutter(resolvedBorderStyle));

      final usePainter =
          resolvedBorderColor != null &&
          (resolvedBorderStyle == .dashed || resolvedBorderStyle == .dotted);

      current = AnimatedContainer(
        decoration: BoxDecoration(
          color: resolvedGradient == null ? resolvedBackground : null,
          image: resolvedBackgroundImage,
          border: resolvedBorderColor != null
              ? Border.all(
                  color: resolvedBorderColor,
                  width: scaledBorderWidth,
                  style: renderBorderStyle,
                )
              : null,
          borderRadius: resolvedBorderRadius,
          boxShadow: resolvedShadows,
          gradient: resolvedGradient,
        ),
        clipBehavior: resolvedClip,
        duration: resolvedDuration,
        curve: resolved.curve,
        child: current,
      );

      if (usePainter) {
        final radius = resolvedBorderRadius is BorderRadius
            ? resolvedBorderRadius
            : (resolvedBorderRadius?.resolve(Directionality.of(context)) ??
                  .zero);
        current = CustomPaint(
          foregroundPainter: _DashedRectPainter(
            color: resolvedBorderColor,
            strokeWidth: scaledBorderWidth,
            radius: radius,
            dotted: resolvedBorderStyle == .dotted,
            dashLength: resolved.dashLength,
            dashGap: resolved.dashSpacing,
          ),
          child: current,
        );
      }

      if (resolvedInnerShadows.isNotEmpty) {
        current = CustomPaint(
          foregroundPainter: _InnerShadowPainter(
            shadows: resolvedInnerShadows,
            radius: resolvedBorderRadius is BorderRadius
                ? resolvedBorderRadius
                : (resolvedBorderRadius?.resolve(
                        Directionality.of(context),
                      ) ??
                      .zero),
          ),
          child: current,
        );
      }

      if (backdropBlur != null && backdropBlur! > 0) {
        current = ClipRRect(
          borderRadius: resolvedBorderRadius ?? BorderRadius.zero,
          child: Stacks(
            fit: .passthrough,
            children: [
              Position.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: backdropBlur!,
                    sigmaY: backdropBlur!,
                  ),
                  child: const SizedBox(),
                ),
              ),
              current,
            ],
          ),
        );
      }
    }

    if (hasSize) {
      current = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 0.0,
          maxWidth: maxWidth ?? .infinity,
          minHeight: minHeight ?? 0.0,
          maxHeight: maxHeight ?? .infinity,
        ),
        child: current,
      );
      if (width != null || height != null) {
        current = SizedBox(width: width, height: height, child: current);
      }
    }

    if (alignment != null && direction == null) {
      current = Align(
        alignment: coreAlignmentToFlutter(alignment!),
        child: current,
      );
    }

    final resolvedMargin = resolved.margin;
    if (resolvedMargin != null) {
      current = Padding(padding: resolvedMargin, child: current);
    }

    if (opacity != null && opacity! < 1.0) {
      current = Opacity(opacity: opacity!, child: current);
    }

    if (layerBlur != null && layerBlur! > 0) {
      current = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: layerBlur!,
          sigmaY: layerBlur!,
        ),
        child: current,
      );
    }

    if (transform != null) {
      current = Transform(
        transform: transform!,
        alignment: transformAlignment != null
            ? coreAlignmentToFlutter(transformAlignment!)
            : null,
        child: current,
      );
    }

    if (onTap != null || onHover != null || cursor != null) {
      final resolvedCursor = cursor != null
          ? coreCursorToFlutter(cursor!)
          : (onTap != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic);
      current = MouseRegion(
        onEnter: onHover != null ? (_) => onHover!(true) : null,
        onExit: onHover != null ? (_) => onHover!(false) : null,
        cursor: resolvedCursor,
        child: GestureDetector(
          onTap: onTap,
          behavior: .opaque,
          child: current,
        ),
      );
    }

    if (onFocus != null) {
      current = Focus(
        onFocusChange: onFocus,
        child: current,
      );
    }

    if (a11y != null) {
      current = CoUISemantics(
        onTap: onTap,
        // A tappable frame that states no role is a button, which is
        // what the previous `role == 'button' || onTap != null` string
        // comparison meant. A frame that *does* state a role keeps it —
        // the old form quietly turned every tappable navigation
        // landmark into a button.
        role: a11y!.role ?? (onTap != null ? .button : null),
        label: a11y!.label,
        container: true,
        explicitChildNodes: true,
        child: current,
      );
    } else if (onTap != null) {
      current = Semantics(button: true, child: current);
    }

    if (flex != null) {
      current = Flexible(
        flex: flex!,
        fit: fit != null ? coreFlexFitToFlutter(fit!) : .loose,
        child: current,
      );
    }

    return current;
  }

  /// Returns a copy of this [Frame] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Frame copyWith({
    Key? key,
    void Function()? onTap,
    CoreFrameDirection? direction,
    double? gap,
    CoreMainAxisAlignment? mainAxisAlignment,
    CoreCrossAxisAlignment? crossAxisAlignment,
    CoreAlignment? alignment,
    double? width,
    double? height,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
    int? flex,
    CoreFlexFit? fit,
    CoreEdgeInsets? padding,
    CoreEdgeInsets? margin,
    CoreColor? backgroundColor,
    CoreGradient? gradient,
    CoreImageSource? backgroundImage,
    CoreColor? borderColor,
    double? borderWidth,
    CoreFrameBorderStyle? borderStyle,
    CoreBorderRadius? borderRadius,
    List<CoreShadowLayer>? boxShadow,
    List<CoreShadowLayer>? innerShadow,
    double? layerBlur,
    double? backdropBlur,
    CoreFrameElevation? elevation,
    CoreClipBehavior? clipBehavior,
    double? opacity,
    Matrix4? transform,
    CoreAlignment? transformAlignment,
    bool? visible,
    CoreValueChanged<bool>? onHover,
    CoreValueChanged<bool>? onFocus,
    CoreCursor? cursor,
    String? tag,
    CoreFrameA11y? a11y,
    Duration? duration,
    CoreFrameStyle? frameStyle,
    List<Widget>? children,
    Widget? child,
  }) {
    return Frame(
      key: key ?? this.key,
      onTap: onTap ?? this.onTap,
      direction: direction ?? this.direction,
      gap: gap ?? this.gap,
      mainAxisAlignment: mainAxisAlignment ?? this.mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment ?? this.crossAxisAlignment,
      alignment: alignment ?? this.alignment,
      width: width ?? this.width,
      height: height ?? this.height,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      flex: flex ?? this.flex,
      fit: fit ?? this.fit,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradient: gradient ?? this.gradient,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderStyle: borderStyle ?? this.borderStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      innerShadow: innerShadow ?? this.innerShadow,
      layerBlur: layerBlur ?? this.layerBlur,
      backdropBlur: backdropBlur ?? this.backdropBlur,
      elevation: elevation ?? this.elevation,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      opacity: opacity ?? this.opacity,
      transform: transform ?? this.transform,
      transformAlignment: transformAlignment ?? this.transformAlignment,
      visible: visible ?? this.visible,
      onHover: onHover ?? this.onHover,
      onFocus: onFocus ?? this.onFocus,
      cursor: cursor ?? this.cursor,
      tag: tag ?? this.tag,
      a11y: a11y ?? this.a11y,
      duration: duration ?? this.duration,
      frameStyle: frameStyle ?? this.frameStyle,
      children: children ?? this.children,
      child: child ?? this.child,
    );
  }
}

/// Chain sugar for merging a [CoreFrameStyle] patch into
/// [Frame.frameStyle] without hand-reconstructing every field. Mirrors
/// the Web `Frame.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFrameStyle.merge` right-side-wins semantics).
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
/// sets [CoreFrameStyle.borderRadius] and `.primary` sets
/// [CoreFrameStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Frame(child: Text('Hi')).radius4.primary
/// ```
extension FrameStyleChain on Frame {
  /// Returns a copy of this [Frame] with [patch] merged into
  /// [frameStyle] (patch fields win on conflict).
  Frame withStyle(CoreFrameStyle patch) =>
      copyWith(frameStyle: (frameStyle ?? const CoreFrameStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Frame get radius0 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Frame get radius2 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Frame get radius4 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Frame get radius6 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Frame get radius8 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Frame get radius10 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Frame get radius12 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Frame get radius14 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Frame get radius16 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Frame get radius20 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Frame get radius24 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Frame get radius28 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Frame get radius32 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Frame get radius36 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Frame get radius40 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Frame get radius48 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Frame get radius56 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Frame get radius64 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Frame get radius9999 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Frame get primary => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Frame get secondary => withStyle(
    const CoreFrameStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Frame get tertiary => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Frame get surface => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Frame get surfaceContainer => withStyle(
    const CoreFrameStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Frame get error => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Frame get success => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Frame get warning => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Frame get info => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Frame get outline => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Frame get transparent =>
      withStyle(const CoreFrameStyle(backgroundColor: .transparent));
}

WrapCrossAlignment _wrapCrossAxisAlignmentFromCore(CrossAxisAlignment a) =>
    switch (a) {
      .start || .stretch || .baseline => .start,
      .end => .end,
      .center => .center,
    };

/// Paints a rounded-rect border in dashed or dotted style.
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

/// Paints inner shadows by clipping to the frame's rounded rect and
/// drawing offset/blurred shadow stamps inside.
class _InnerShadowPainter extends CustomPainter {
  const _InnerShadowPainter({required this.shadows, required this.radius});

  final List<BoxShadow> shadows;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: radius.topLeft,
      topRight: radius.topRight,
      bottomRight: radius.bottomRight,
      bottomLeft: radius.bottomLeft,
    );
    canvas
      ..save()
      ..clipRRect(rrect);
    for (final s in shadows) {
      final paint = Paint()
        ..color = s.color
        ..maskFilter = MaskFilter.blur(.normal, s.blurRadius);
      final shadowRect = rrect.outerRect.translate(s.offset.dx, s.offset.dy);
      canvas.drawDRRect(
        RRect.fromRectAndCorners(
          shadowRect.inflate(s.spreadRadius + s.blurRadius * 2),
          topLeft: radius.topLeft,
          topRight: radius.topRight,
          bottomRight: radius.bottomRight,
          bottomLeft: radius.bottomLeft,
        ),
        rrect,
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter old) {
    return !const ListEquality<BoxShadow>().equals(old.shadows, shadows) ||
        old.radius != radius;
  }
}
