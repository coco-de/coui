import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [HeroSection].
class ResolvedHero {
  /// Creates a [ResolvedHero].
  const ResolvedHero({
    required this.backgroundColor,
    required this.containerStyle,
    required this.minHeight,
    required this.padding,
    required this.splitIsRow,
    required this.splitGapStyle,
    required this.appearDuration,
    required this.appearCurve,
    required this.appearOffset,
    this.overlayColor,
  });

  /// Resolved background colour — read directly by `co_hero_section`
  /// only for the background-*image* path, where `OutlinedContainer`
  /// cannot be composed (it has no image slot) and the box stays
  /// hand-drawn.
  final Color backgroundColor;

  /// Composed-`OutlinedContainer` chrome for the solid-colour hero
  /// panel (pre-EMIT `CoreOutlinedContainerStyle`) — used only when the
  /// widget has no `imageUrl`. `OutlinedContainer` runs the
  /// scheme-resolve / scaling bend itself; carrying the Core token (not
  /// the resolved Flutter one) keeps that bend applied exactly once.
  /// `boxShadow: []` is forced because this panel never painted a cast
  /// of its own.
  final CoreOutlinedContainerStyle containerStyle;

  /// Resolved minimum height (already scaled).
  final double minHeight;

  /// Resolved outer padding (already scaled).
  final EdgeInsetsGeometry padding;

  /// Whether a split pair is a row. False stacks the copy above the
  /// media. Same tablet threshold as `ResponsiveRowColumn`. The widget
  /// decides center versus split from [heroEffectiveLayout]; this record
  /// only carries the paint-ready row-or-stack fact.
  final bool splitIsRow;

  /// Gutter between copy and media. Raw [CoreGapStyle] — the inner
  /// `Gap` resolves and scales it.
  final CoreGapStyle splitGapStyle;

  /// Resolved overlay colour (`null` = no overlay).
  final Color? overlayColor;

  /// Entrance duration, already passed through [resolveMotionDuration].
  ///
  /// [Duration.zero] when the ambient reduced-motion preference is on,
  /// so the entrance snaps instead of travelling.
  final Duration appearDuration;

  /// Entrance curve, adapted from [CoreCubicBezier] to a Flutter [Curve].
  final Curve appearCurve;

  /// Upward travel of the centred content, in logical pixels, already
  /// multiplied by the theme scaling factor.
  final double appearOffset;
}

/// Resolves [ResolvedHero] for [HeroSection].
///
/// Priority (per-field): merged composite style (`widget.heroSectionStyle`
/// over `CoreHeroSectionTheme.style`) > design-system default
/// (`CoreHeroStyle.defaultX`).
ResolvedHero resolveHero(
  BuildContext context, {
  CoreHeroLayout? layout,
  CoreHeroStyle? heroSectionStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.heroSection;

  final merged = resolveStyleChain(const CoreHeroStyle(), [
    coreTheme?.style,
    heroSectionStyle,
  ]);

  // C7 colour path: every `CoreColor → Color` runs through
  // `scheme.resolve(x).toValue()` so the surface-container default and
  // any override stay scheme-aware (dark-mode parity, #1601 class).
  final backgroundToken =
      merged.backgroundColor ?? CoreHeroStyle.defaultBackgroundColor;
  final effectiveBg = scheme.resolve(backgroundToken).toValue();

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT ────────────────
  // Only reachable via the solid-colour path (`co_hero_section` composes
  // it when `imageUrl == null`) — `OutlinedContainer` has no image slot,
  // so a picture hero keeps its hand-drawn `Container(decoration:
  // BoxDecoration(image: …))` and no material (see the class doc: "무엇
  // 위에" is undefined for a picture the surface itself paints).
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundToken,
    borderRadius: .zero,
    borderWidth: 0,
    boxShadow: const [],
  );

  final overlayOverride = merged.overlayColor;
  final effectiveOverlay = overlayOverride == null
      ? null
      : scheme.resolve(overlayOverride).toValue();

  final minHeight =
      (merged.minHeight ?? CoreHeroStyle.defaultMinHeight) * scaling;

  // Stage2 EMIT — paint-ready padding (toValue + scaling) finishes in
  // the local var so the return literal stays a bare mapping.
  final padding =
      (merged.padding ?? CoreHeroStyle.defaultPadding).toValue(
        geometry: theme.geometry,
      ) *
      scaling;

  // Layout stays off [ResolvedHero]. The widget branches on
  // [heroEffectiveLayout]; this read is the same merge so a style
  // override still reaches the row-or-stack fact below.
  final effectiveLayout =
      layout ?? merged.layout ?? CoreHeroStyle.defaultLayout;
  final splitIsRow =
      effectiveLayout == CoreHeroLayout.split &&
      heroSplitIsRow(resolveBreakpoint(context).tier);

  final splitGapStyle = CoreHeroStyle.defaultSplitGapStyle.merge(
    merged.splitGapStyle,
  );

  // Entrance recipe. Always resolved so a theme override is in force
  // the moment `appear` flips on; the widget only consumes it then.
  // `resolveMotionDuration` is what zeroes a transition-tier duration
  // when the platform asks for reduced motion (`resolveReducedMotion`) —
  // the same policy Web gets by publishing `--coui-duration-*`.
  final appearDuration = resolveMotionDuration(
    context,
    merged.appearDuration ?? CoreHeroStyle.defaultAppearDuration,
  );
  final appearCurve = (merged.appearCurve ?? CoreHeroStyle.defaultAppearCurve)
      .toValue();
  final appearOffset =
      (merged.appearOffset ?? CoreHeroStyle.defaultAppearOffset) * scaling;

  return ResolvedHero(
    backgroundColor: effectiveBg,
    containerStyle: containerStyle,
    minHeight: minHeight,
    padding: padding,
    splitIsRow: splitIsRow,
    splitGapStyle: splitGapStyle,
    overlayColor: effectiveOverlay,
    appearDuration: appearDuration,
    appearCurve: appearCurve,
    appearOffset: appearOffset,
  );
}
