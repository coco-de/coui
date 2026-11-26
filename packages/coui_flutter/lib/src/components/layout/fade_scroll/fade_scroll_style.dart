import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [FadeScroll].
///
/// Single struct produced by [resolveFadeScroll] — `FadeScroll`
/// reads `resolved.X` only. Every field has had the nested-merge chain
/// applied plus the [CoreFadeScrollStyle] `static const` default
/// fallback.
class ResolvedFadeScroll {
  /// Creates a [ResolvedFadeScroll].
  const ResolvedFadeScroll({
    required this.startOffset,
    required this.endOffset,
    required this.gradient,
  });

  /// Effective start-edge fade offset (logical px).
  final double startOffset;

  /// Effective end-edge fade offset (logical px).
  final double endOffset;

  /// Effective gradient stops (already resolved to Flutter `Color`).
  final List<Color> gradient;
}

/// Resolves [ResolvedFadeScroll] for [FadeScroll].
///
/// Single entry point for the merge chain:
///
/// ```text
/// CoreFadeScrollStyle.defaultX
///   → theme.coreComponentTheme.fadeScroll.style
///   → widget.fadeScrollStyle
/// ```
///
/// Tokens are converted to Flutter types here so the widget never
/// touches [CoreColor] / [CoreFadeScrollStyle] directly.
ResolvedFadeScroll resolveFadeScroll(
  BuildContext context, {
  CoreFadeScrollStyle? fadeScrollStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final fadeScrollTheme = theme.coreComponentTheme?.fadeScroll;

  // 2단 merge chain — variant 가 없는 컴포넌트.
  final merged = resolveStyleChain(const CoreFadeScrollStyle(), [
    fadeScrollTheme?.style,
    fadeScrollStyle,
  ]);

  final startOffset =
      (merged.startOffset ?? CoreFadeScrollStyle.defaultStartOffset) * scaling;
  final endOffset =
      (merged.endOffset ?? CoreFadeScrollStyle.defaultEndOffset) * scaling;
  final gradientCore = merged.gradient ?? CoreFadeScrollStyle.defaultGradient;
  final gradient = gradientCore
      .map((coreColor) => scheme.resolve(coreColor).toValue())
      .toList(growable: false);

  return ResolvedFadeScroll(
    startOffset: startOffset,
    endOffset: endOffset,
    gradient: gradient,
  );
}
