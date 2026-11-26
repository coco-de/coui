import 'package:coui_flutter/coui_flutter.dart';

/// Resolved `DotIndicator` style values after merging
/// `widget.dotIndicatorStyle` > `CoreDotIndicatorTheme.style` >
/// `CoreDotIndicatorStyle.defaultX`. All numeric values are already
/// scaled by `theme.scaling`.
class ResolvedDotIndicator {
  /// Creates a [ResolvedDotIndicator].
  const ResolvedDotIndicator({
    required this.dotSize,
    required this.activeLength,
    required this.spacing,
    required this.padding,
    required this.borderRadius,
    required this.inactiveBorderWidth,
    required this.activeColor,
    required this.inactiveBorderColor,
    required this.hoverBorderColor,
    required this.transitionDuration,
    required this.focusOutlineStyle,
    required this.curve,
    required this.inactiveColor,
  });

  /// Effective dot diameter (logical px, already scaled).
  final double dotSize;

  /// Active indicator length along the layout axis (logical px).
  final double activeLength;

  /// Effective gap between dots (logical px, already scaled).
  final double spacing;

  /// Outer container padding (already scaled).
  final EdgeInsets padding;

  /// Effective dot border radius.
  final BorderRadius borderRadius;

  /// Effective inactive border width (logical px, already scaled).
  final double inactiveBorderWidth;

  /// Resolved active dot fill colour.
  final Color activeColor;

  /// Resolved inactive dot border colour.
  final Color inactiveBorderColor;

  /// Resolved inactive dot fill colour (null = transparent).
  final Color inactiveColor;

  /// Resolved hover border colour for clickable inactive dots. Only
  /// reaches the screen when [inactiveBorderWidth] is non-zero, which
  /// the shipped default is not.
  final Color hoverBorderColor;

  /// Effective transition duration for active / hover state changes.
  final Duration transitionDuration;

  /// The shape the chrome change takes over time.
  ///
  /// Paired with the duration beside it rather than left to the framework.
  /// Flutter's implicit animations default to `Curves.linear` and the Web
  /// twin's CSS transition does not — same length, different shape, so
  /// side by side one pane slides at a constant rate while the other eases
  /// in and out. Both platforms name the same `CoreEasing` alias instead.
  final Curve curve;

  /// Nested focus-outline slot for the ring drawn around the selected
  /// dot while the indicator group holds keyboard focus —
  /// `CoreDotIndicatorStyle.defaultFocusOutlineStyle` (an empty partial)
  /// merged with the per-instance override and raw-forwarded to
  /// `FocusOutline(focusOutlineStyle: …)`, which fills its own defaults.
  final CoreFocusOutlineStyle? focusOutlineStyle;
}

/// Resolves [ResolvedDotIndicator] for [DotIndicator].
///
/// Merge chain: `widget.dotIndicatorStyle` >
/// `CoreDotIndicatorTheme.style` > `CoreDotIndicatorStyle.defaultX`.
///
/// [size] is a semantic identifier (widget-only prop — the theme cannot
/// override it, mirroring `resolveProgress`'s `size`) that selects the
/// per-size dot diameter + spacing from
/// [CoreDotIndicatorStyle.defaultsBySize].
ResolvedDotIndicator resolveDotIndicator(
  BuildContext context, {
  required CoreDotIndicatorSize size,
  CoreDotIndicatorStyle? dotIndicatorStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final directionality = Directionality.of(context);
  final diTheme = theme.coreComponentTheme?.dotIndicator;
  final colorScheme = theme.colorScheme;

  final merged = resolveStyleChain(const CoreDotIndicatorStyle(), [
    diTheme?.style,
    dotIndicatorStyle,
  ]);

  // ─── Dimensional fallback ─────────────────────────────
  // Each value finishes its merge + fallback (+ scaling / conversion)
  // here so the return literal below stays a bare mapping. Scaling is
  // applied to the design-system default only (an explicit per-instance
  // override is taken as the final logical-px value), preserving the
  // pre-sweep behaviour exactly.
  //
  // Semantic `size` is a widget-only prop (the theme cannot override it).
  // Resolve straight to the per-size default style (dotSize / spacing).
  final sizeStyle = CoreDotIndicatorStyle.defaultsBySize[size]!;
  final dotSize = merged.dotSize ?? (scaling * sizeStyle.dotSize!);
  // The density moves both — an override is still spacing on the
  // scale; only the size factor stays with the default, as above.
  final spacing = merged.spacing != null
      ? theme.geometry.space(merged.spacing!)
      : scaling * theme.geometry.space(sizeStyle.spacing!);
  final paddingCore = merged.padding ?? CoreDotIndicatorStyle.defaultPadding;
  final padding =
      paddingCore.toValue(geometry: theme.geometry).resolve(directionality) *
      scaling;
  final borderRadius =
      (merged.borderRadius ?? CoreDotIndicatorStyle.defaultBorderRadius)
          .toValue(geometry: theme.geometry);
  final inactiveBorderWidth = theme.geometry.stroke(
    merged.inactiveBorderWidth ??
        CoreDotIndicatorStyle.defaultInactiveBorderWidth,
    scaling: scaling,
  );
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ??
        CoreDotIndicatorStyle.defaultTransitionDuration,
  );

  // ─── Colour resolution ────────────────────────────────
  final activeColor = colorScheme
      .resolve(merged.activeColor ?? CoreDotIndicatorStyle.defaultActiveColor)
      .toValue();
  final inactiveBorderColor = colorScheme
      .resolve(
        merged.inactiveBorderColor ??
            CoreDotIndicatorStyle.defaultInactiveBorderColor,
      )
      .toValue();
  final hoverBorderColor = colorScheme
      .resolve(
        merged.hoverBorderColor ??
            CoreDotIndicatorStyle.defaultHoverBorderColor,
      )
      .toValue();
  final inactiveColor = colorScheme
      .resolve(
        merged.inactiveColor ?? CoreDotIndicatorStyle.defaultInactiveColor,
      )
      .toValue();

  return ResolvedDotIndicator(
    // The same alias the Web twin names for this element's CSS
    // transition. Chrome moving between states is `move`; a curve
    // stated on one platform and defaulted on the other is the
    // divergence nothing renders differently enough to notice until
    // the two are put side by side.
    curve: CoreEasing.move.toValue(),
    dotSize: dotSize,
    activeLength:
        merged.activeLength ??
        CoreDotIndicatorStyle.defaultActiveLength(dotSize),
    spacing: spacing,
    padding: padding,
    borderRadius: borderRadius,
    inactiveBorderWidth: inactiveBorderWidth,
    activeColor: activeColor,
    inactiveBorderColor: inactiveBorderColor,
    hoverBorderColor: hoverBorderColor,
    transitionDuration: transitionDuration,
    focusOutlineStyle: CoreDotIndicatorStyle.defaultFocusOutlineStyle.merge(
      merged.focusOutlineStyle,
    ),
    inactiveColor: inactiveColor,
  );
}
