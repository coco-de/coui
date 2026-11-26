import 'package:coui_flutter/coui_flutter.dart';

// All HoverGallery defaults live as `static const` on
// `CoreHoverGalleryStyle` (Phase 6f / Epic #1415 option D). HoverGallery
// has no variant so there is no `defaultsByVariant` map.

// ═══════════════════════════════════════════════════
// Resolved style
// ═══════════════════════════════════════════════════

/// Resolved styling values for [HoverGallery].
///
/// Every chrome / dimensional override has been merged through:
///
/// ```text
/// CoreHoverGalleryStyle.defaultX
///   → theme.coreComponentTheme.hoverGallery.style
///   → widget.hoverGalleryStyle
/// ```
class ResolvedHoverGallery {
  /// Creates a [ResolvedHoverGallery].
  const ResolvedHoverGallery({
    required this.height,
    required this.borderRadius,
    required this.animationDuration,
  });

  /// Container height (logical px, already scaled).
  final double height;

  /// Container corner radius (logical px, already scaled).
  final BorderRadius borderRadius;

  /// Image crossfade animation duration.
  final Duration animationDuration;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedHoverGallery] for the given [context].
ResolvedHoverGallery resolveHoverGallery(
  BuildContext context, {
  CoreHoverGalleryStyle? hoverGalleryStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final hgTheme = theme.coreComponentTheme?.hoverGallery;

  // 2 단 merge chain — HoverGallery 는 variant 없음.
  final merged = resolveStyleChain(const CoreHoverGalleryStyle(), [
    hgTheme?.style,
    hoverGalleryStyle,
  ]);

  // 변환 — merged (사용자 의도) 가 null 인 필드만 static const default 사용.
  final borderRadiusCore =
      merged.borderRadius ?? CoreHoverGalleryStyle.defaultBorderRadius;

  return ResolvedHoverGallery(
    height: (merged.height ?? CoreHoverGalleryStyle.defaultHeight) * scaling,
    borderRadius: borderRadiusCore.toValue(geometry: theme.geometry) * scaling,
    animationDuration:
        merged.animationDuration ??
        CoreHoverGalleryStyle.defaultAnimationDuration,
  );
}
