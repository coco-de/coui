import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Range`.
///
/// Widget tree (`co_range` decides which optional branches render):
///
/// ```text
/// {row wrapper: Row | none}                 // only when leading/trailing set
///   ├─ leading                              // caller-supplied Widget, optional
///   ├─ Gap (gap)                          // rendered only when leading != null
///   ├─ {Expanded >} GestureDetector > MouseRegion > SizedBox
///   │    └─ Stacks
///   │         ├─ track    (inactive rail)   // inactiveTrackColor
///   │         ├─ fill     (active range)    // activeTrackColor
///   │         ├─ minThumb (Semantics(slider:) > FocusableActionDetector >
///   │         │             _RangeThumb)     // independently focusable
///   │         └─ maxThumb (same shape)       // independently focusable
///   ├─ Gap (gap)                          // rendered only when trailing != null
///   └─ trailing                             // caller-supplied Widget, optional
/// ```
///
/// Every colour field is a paint-ready Flutter [Color] — the resolver
/// runs `scheme.resolve(override ?? default).toValue()` once so the
/// widget never touches `scheme.resolve` itself (Epic #1603 C7 — single
/// colour-resolution point, #1601 dark-mode regression class).
/// Dimensional fields have `theme.scaling` pre-applied; the radius slot
/// is a paint-ready [BorderRadius].
class ResolvedRange {
  /// Creates a [ResolvedRange].
  const ResolvedRange({
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.thumbColor,
    required this.thumbBorderColor,
    required this.trackHeight,
    required this.thumbSize,
    required this.thumbBorderWidth,
    required this.borderRadius,
    required this.minMaxGapStyle,
    required this.focusOutlineStyle,
  });

  // ── Chrome (paint-ready Color) ───────────────

  /// Active (selected, between-thumbs) track fill colour — resolved
  /// (override else `CoreRangeStyle.defaultActiveTrackColor`).
  final Color activeTrackColor;

  /// Inactive (outside-selection) track fill colour — resolved
  /// (override else `CoreRangeStyle.defaultInactiveTrackColor`).
  final Color inactiveTrackColor;

  /// Thumb background fill colour — resolved (override else
  /// `CoreRangeStyle.defaultThumbColor`).
  final Color thumbColor;

  /// Thumb border stroke colour — resolved (override else
  /// `CoreRangeStyle.defaultThumbBorderColor`).
  final Color thumbBorderColor;

  // ── Dimensional chrome (scaling pre-applied) ─

  /// Track height (logical px, scaling pre-applied).
  final double trackHeight;

  /// Thumb size (logical px, scaling pre-applied).
  final double thumbSize;

  /// Thumb border stroke width (logical px, scaling pre-applied).
  final double thumbBorderWidth;

  /// Corner radius for the track / fill / thumbs (paint-ready
  /// [BorderRadius], geometry-bent). Design-system default is a full
  /// pill (`CoreRangeStyle.defaultBorderRadius` = `radius9999`), so this
  /// already renders as a circle under the default surface style and
  /// correctly flattens under a preset with a `radiusCap` (e.g.
  /// neo-brutalism) — never `null`, so a capped preset always reaches
  /// the track/thumb paint instead of the widget re-deriving its own
  /// un-geometried circular fallback.
  final BorderRadius borderRadius;

  /// Nested gap style for the spacer between slider and leading /
  /// trailing slots — `co_range` forwards it straight to two `Gap`
  /// widgets which apply their own scaling.
  final CoreGapStyle minMaxGapStyle;

  /// Keyboard focus ring style forwarded to the `FocusOutline` the
  /// focused thumb composes, which draws the ring on both platforms.
  /// Raw-forwarded: that component's resolver resolves the tokens and
  /// applies scaling, so nothing is resolved here (reaching into its
  /// defaults would duplicate them).
  final CoreFocusOutlineStyle focusOutlineStyle;
}

// ═══════════════════════════════════════════════════
// resolveRange — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedRange] for the given [context].
///
/// Walks the nested-merge chain plus token / dimensional fallback in a
/// single pass:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.range.style
///   → widget.rangeStyle
/// ```
ResolvedRange resolveRange(
  BuildContext context, {
  required bool enabled,
  CoreRangeStyle? rangeStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final rangeTheme = theme.coreComponentTheme?.range;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreRangeStyle(), [
    rangeTheme?.style,
    rangeStyle,
  ]);

  // ─── Resolved chrome colours (single colour-resolution point) ─
  // CoreColor → Flutter Color runs through `scheme.resolve(x).toValue()`
  // here once (Epic #1603 C7); the widget reads paint-ready `Color`s.
  final activeTrackColor = scheme
      .resolve(
        enabled
            ? (merged.activeTrackColor ??
                  CoreRangeStyle.defaultActiveTrackColor)
            : (merged.disabledActiveTrackColor ??
                  CoreRangeStyle.defaultDisabledActiveTrackColor),
      )
      .toValue();
  final inactiveTrackColor = scheme
      .resolve(
        enabled
            ? (merged.inactiveTrackColor ??
                  CoreRangeStyle.defaultInactiveTrackColor)
            : (merged.disabledInactiveTrackColor ??
                  CoreRangeStyle.defaultDisabledInactiveTrackColor),
      )
      .toValue();
  final thumbColor = scheme
      .resolve(
        enabled
            ? (merged.thumbColor ?? CoreRangeStyle.defaultThumbColor)
            : (merged.disabledThumbColor ??
                  CoreRangeStyle.defaultDisabledThumbColor),
      )
      .toValue();
  final thumbBorderColor = scheme
      .resolve(
        enabled
            ? (merged.thumbBorderColor ??
                  CoreRangeStyle.defaultThumbBorderColor)
            : (merged.disabledThumbBorderColor ??
                  CoreRangeStyle.defaultDisabledThumbBorderColor),
      )
      .toValue();

  // ─── Dimensional chrome (paint-ready before scaling; * scaling in return) ─
  final trackHeight =
      (merged.trackHeight ?? CoreRangeStyle.defaultTrackHeight) * scaling;
  final thumbSize =
      (merged.thumbSize ?? CoreRangeStyle.defaultThumbSize) * scaling;
  final thumbBorderWidth = theme.geometry.stroke(
    merged.thumbBorderWidth ?? CoreRangeStyle.defaultThumbBorderWidth,
    scaling: scaling,
  );

  // ─── Paint-ready radius (no scaling — caller scales widget-side) ─
  final borderRadius =
      (merged.borderRadius ?? CoreRangeStyle.defaultBorderRadius).toValue(
        geometry: theme.geometry,
      );

  // ─── Nested gap slot (composite: default.merge(override)) ─
  final minMaxGapStyle = CoreRangeStyle.defaultMinMaxGapStyle.merge(
    merged.minMaxGapStyle,
  );

  // ─── Keyboard focus ring (raw-forwarded nested slot) ──
  // Only the fields this component diverges on are stated; the rest stay
  // null so `FocusOutline`'s resolver supplies its own defaults.
  final focusOutlineStyle = CoreRangeStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );

  return ResolvedRange(
    activeTrackColor: activeTrackColor,
    inactiveTrackColor: inactiveTrackColor,
    thumbColor: thumbColor,
    thumbBorderColor: thumbBorderColor,
    trackHeight: trackHeight,
    thumbSize: thumbSize,
    thumbBorderWidth: thumbBorderWidth,
    borderRadius: borderRadius,
    minMaxGapStyle: minMaxGapStyle,
    focusOutlineStyle: focusOutlineStyle,
  );
}
