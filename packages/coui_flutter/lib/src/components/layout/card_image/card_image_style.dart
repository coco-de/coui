import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `CardImage`.
///
/// Widget tree (`co_card_image` decides which optional branches render):
///
/// ```text
/// Button (statesController)                    // only when onPressed is set
///   └─ OutlinedContainer(containerStyle)        // the card's box
///        └─ Flex(direction)
///             ├─ Opacity(contentOpacity)
///             │    └─ OutlinedContainer(frameStyle)
///             │         └─ AnimatedScale(scale, duration)
///             │              └─ caller-supplied image Widget
///             ├─ Gap(imageContentGapStyle)
///             └─ Opacity(contentOpacity)
///                  └─ Basic(contentStyle)       // leading | title | subtitle | trailing
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the image → text spacer is rendered
/// through the unified `Gap` widget, so the resolver carries the
/// nested [imageContentGapStyle] (`CoreGapStyle`) and `co_card_image`
/// forwards it straight to `Gap(gapStyle: …)`.
class ResolvedCardImage {
  /// Creates a [ResolvedCardImage].
  const ResolvedCardImage({
    required this.direction,
    required this.hoverScale,
    required this.normalScale,
    required this.hoverDuration,
    required this.containerStyle,
    required this.frameStyle,
    required this.contentStyle,
    required this.contentOpacity,
    required this.imageContentGapStyle,
  });

  /// Effective layout direction.
  final CoreAxis direction;

  /// Effective hover scale factor.
  final double hoverScale;

  /// Effective idle scale factor.
  final double normalScale;

  /// Effective hover scale transition duration.
  final Duration hoverDuration;

  /// Nested [CoreOutlinedContainerStyle] for the card's own box —
  /// raw-forwarded to the outer `OutlinedContainer(containerStyle: …)`.
  final CoreOutlinedContainerStyle containerStyle;

  /// Nested [CoreBasicStyle] for the text row — raw-forwarded to
  /// `Basic(basicStyle: …)`; `Basic` resolves and scales it itself.
  final CoreBasicStyle contentStyle;

  /// Opacity of the image layer and the text row — the disabled opacity
  /// while the card is disabled, `1` otherwise.
  final double contentOpacity;

  /// Nested [CoreOutlinedContainerStyle] for the image frame —
  /// raw-forwarded straight to `OutlinedContainer(containerStyle: …)`;
  /// that widget's own resolver runs `scheme.resolve` on the colours (no
  /// `CoreColor(color.toARGB32())` round-trip here).
  final CoreOutlinedContainerStyle frameStyle;

  /// Nested [CoreGapStyle] for the image → text spacer — forwarded
  /// straight to `Gap(gapStyle: …)` inside `co_card_image`. The slot
  /// is **not** pre-scaled here; `Gap` applies `theme.scaling` itself
  /// in its own resolver, so the forwarded slot stays in pre-scaling
  /// units (avoids double-scaling under non-default text scaler).
  final CoreGapStyle imageContentGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves the effective `CardImage` style from `widget.cardImageStyle`,
/// the inherited [CoreComponentTheme.cardImage] override and the
/// component-level defaults.
///
/// [disabled] is the card's semantic disabled state (`enabled: false`) — a
/// build-time prop the Web twin receives too, not an interaction state.
ResolvedCardImage resolveCardImage(
  BuildContext context, {
  required bool disabled,
  CoreCardImageStyle? cardImageStyle,
}) {
  final theme = Theme.of(context);
  final coreTheme = theme.coreComponentTheme?.cardImage;
  final themeStyle = coreTheme?.style;

  final merged = resolveStyleChain(const CoreCardImageStyle(), [
    themeStyle,
    cardImageStyle,
  ]);

  // ─── Resolved values (synthesis lives here, never in the return) ──
  final direction = merged.direction ?? CoreCardImageStyle.defaultDirection;
  final hoverScale = merged.hoverScale ?? CoreCardImageStyle.defaultHoverScale;
  final normalScale =
      merged.normalScale ?? CoreCardImageStyle.defaultNormalScale;
  final hoverDuration = resolveMotionDuration(
    context,
    merged.hoverDuration ?? CoreCardImageStyle.defaultHoverDuration,
  );
  // The image frame is a composed `OutlinedContainer`, so its chrome is
  // a single nested `CoreOutlinedContainerStyle` slot — raw-forwarded to
  // `OutlinedContainer(containerStyle: …)`, never assembled from
  // individual colours here (`resolver/resolver-pattern.md`: "resolver
  // 는 자식 Style 을 조립하지 않는다").
  // A disabled card drops its cast: the disabled layer is laid over the
  // resolved box rather than replacing it.
  final restingContainerStyle = CoreCardImageStyle.defaultContainerStyle.merge(
    merged.containerStyle,
  );
  final containerStyle = disabled
      ? restingContainerStyle.merge(
          CoreCardImageStyle.defaultDisabledContainerStyle.merge(
            merged.disabledContainerStyle,
          ),
        )
      : restingContainerStyle;
  final frameStyle = CoreCardImageStyle.defaultFrameStyle.merge(
    merged.frameStyle,
  );
  final contentStyle = CoreCardImageStyle.defaultContentStyle.merge(
    merged.contentStyle,
  );
  final contentOpacity = disabled
      ? merged.disabledContentOpacity ??
            CoreCardImageStyle.defaultDisabledContentOpacity
      : 1.0;
  // Merge the design-system default `CoreGapStyle` with the
  // per-instance override and forward the merged slot raw. `Gap`'s
  // own resolver multiplies `size` by `theme.scaling`, so pre-applying
  // scaling here would double-scale under non-default text scaler
  // (Epic #1603 옵션 B — parent forwards raw nested style slots).
  final imageContentGapStyle = CoreCardImageStyle.defaultImageContentGapStyle
      .merge(merged.imageContentGapStyle);

  return ResolvedCardImage(
    direction: direction,
    hoverScale: hoverScale,
    normalScale: normalScale,
    hoverDuration: hoverDuration,
    containerStyle: containerStyle,
    frameStyle: frameStyle,
    contentStyle: contentStyle,
    contentOpacity: contentOpacity,
    imageContentGapStyle: imageContentGapStyle,
  );
}
