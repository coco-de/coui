import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedFilter
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Filter`.
///
/// Widget tree (`filter.dart` decides which optional branches render):
///
/// ```text
/// ToggleGroup (toggleGroupStyle)                  // track · segments · chosen face
///   └─ trailing                                   // * showResetButton && onReset != null
///        Padding (start = dividerLeadingSpacing - the group's item spacing)
///          Row (spacing = trailingSpacing)
///            ├─ SizedBox (height = dividerHeight)
///            │    └─ Divider.vertical (dividerStyle)
///            └─ Button.ghost.sm.square (resetButtonStyle)
///                 └─ Icon(resetButtonStyle.leadingIconStyle)
/// ```
///
/// The segments are not drawn here: `Filter` composes `ToggleGroup`, so the
/// track fill, the raised chosen face and its shadow, the segment geometry,
/// the label roles and the disabled look all come from
/// [toggleGroupStyle], which is raw-forwarded and resolved by the group's
/// own resolver. What this resolver owns is the trailing part — the
/// hairline and the reset affordance.
///
/// Per Epic #1603 옵션 B 최종: the semantic `variant` is **not** stored
/// here — the widget's `variant` prop selects chrome via the merge chain
/// and the theme cannot override identity.
class ResolvedFilter {
  /// Creates a [ResolvedFilter].
  const ResolvedFilter({
    required this.toggleGroupStyle,
    required this.dividerStyle,
    required this.dividerHeight,
    required this.dividerLeadingSpacing,
    required this.trailingSpacing,
    required this.resetButtonStyle,
  });

  /// Nested [CoreToggleGroupStyle] for the composed segments —
  /// `CoreFilterStyle.defaultToggleGroupStyle`, the deprecated flat
  /// track / segment fields and the per-instance slot folded in
  /// (`toggleGroupStyleFor`), raw-forwarded to
  /// `ToggleGroup(toggleGroupStyle:)`.
  final CoreToggleGroupStyle toggleGroupStyle;

  /// Nested [CoreDividerStyle] of the hairline between the segments and the
  /// reset button — raw-forwarded to `Divider(dividerStyle:)`, which scales
  /// its own thickness.
  final CoreDividerStyle dividerStyle;

  /// Length of the hairline (logical px, scaling pre-applied) — a box the
  /// widget sizes itself, so it is scaled here.
  final double dividerHeight;

  /// Room added in front of the hairline (logical px, scaling pre-applied):
  /// the distance from the last segment to the hairline minus the group's
  /// own item spacing, which already sits there. Never negative.
  final double dividerLeadingSpacing;

  /// Spacing between the hairline and the reset button (logical px,
  /// scaling pre-applied) — `Row.spacing`, a native paint API.
  final double trailingSpacing;

  /// Reset-affordance button style — chained design-system default +
  /// per-instance override, raw-forwarded to
  /// `Button(variant: .ghost, size: .sm, shape: .square, buttonStyle: …)`.
  /// The child `Button` resolves its own colours / padding / hover /
  /// focus-ring; only the square `width` / `height` are pre-scaled here
  /// because `Button` paints its dimensional axis raw (it does not
  /// self-scale).
  final CoreButtonStyle resetButtonStyle;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFilter] for the given Flutter [context].
///
/// Walks the nested-merge chain plus token fallback in a single pass:
///
/// ```text
/// design system default → CoreFilterTheme.style
///   → CoreFilterTheme.variantStyles[variant] → widget.filterStyle
/// ```
///
/// [size] picks the Filter's own size row (`CoreFilterStyle.defaultsBySize`
/// — the reset button height and the hairline length); the segments read
/// the same size through the composed `ToggleGroup`.
///
/// The semantic [variant] is widget-only (Epic #1603 옵션 B 최종) — it
/// selects the variant chrome slot but is never stored on the resolved
/// output.
ResolvedFilter resolveFilter(
  BuildContext context, {
  required CoreFilterVariant variant,
  CoreComponentSize size = CoreFilterContract.defaultSize,
  CoreFilterStyle? filterStyle,
  bool enabled = true,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final filterTheme = theme.coreComponentTheme?.filter;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreFilterStyle(), [
    filterTheme?.style,
    filterTheme?.variantStyles?[variant],
    filterStyle,
  ]);

  // The size row — sits between the merged override and the flat default.
  final sizeRow = CoreFilterStyle.sizeDefaults(size);

  // Nested slots — composite `default.merge(override)`, raw-forwarded; the
  // composed `ToggleGroup` / `Divider` resolve their own colours and scale
  // their own chrome.
  final toggleGroupStyle = merged.toggleGroupStyleFor();
  // While disabled the hairline takes the disabled outline so it fades with
  // the disabled track and labels; the enabled colour stays the divider
  // slot's own.
  final dividerStyle = CoreFilterStyle.defaultDividerStyle
      .merge(merged.dividerStyle)
      .merge(
        enabled
            ? null
            : CoreDividerStyle(
                color:
                    merged.disabledDividerColor ??
                    CoreFilterStyle.defaultDisabledDividerColor,
              ),
      );

  // Reset-affordance chrome — chained `defaultResetButtonStyle` (32-px
  // square + zero padding + item radius + 150 ms transition + 16-px
  // glyph + onSurfaceVariant foreground), then the per-instance override.
  // Only `width` / `height` are pre-scaled below: `Button` paints its
  // dimensional axis raw (it does not self-scale).
  final resetButtonChain = CoreFilterStyle.defaultResetButtonStyle
      .merge(sizeRow.resetButtonStyle)
      .merge(merged.resetButtonStyle);
  final resetButtonStyle = resetButtonChain.copyWith(
    height: resetButtonChain.height! * scaling,
    width: resetButtonChain.width! * scaling,
  );

  // ─── Chrome (scaling pre-applied where it is a layout dimension) ─
  final dividerHeight =
      (merged.dividerHeight ??
          sizeRow.dividerHeight ??
          CoreFilterStyle.defaultDividerHeight) *
      scaling;
  final trailingSpacing =
      theme.geometry.space(
        merged.trailingSpacing ?? CoreFilterStyle.defaultTrailingSpacing,
      ) *
      scaling;
  // The group puts its own item spacing between the last segment and the
  // trailing slot; only the rest of the leading distance is added here.
  final groupItemSpacing =
      theme.geometry.space(
        toggleGroupStyle.itemSpacing ?? CoreToggleGroupStyle.defaultItemSpacing,
      ) *
      scaling;
  final dividerLeadingSpacing = math.max<double>(
    0,
    theme.geometry.space(
              merged.dividerLeadingSpacing ??
                  CoreFilterStyle.defaultDividerLeadingSpacing,
            ) *
            scaling -
        groupItemSpacing,
  );

  return ResolvedFilter(
    toggleGroupStyle: toggleGroupStyle,
    dividerStyle: dividerStyle,
    dividerHeight: dividerHeight,
    dividerLeadingSpacing: dividerLeadingSpacing,
    trailingSpacing: trailingSpacing,
    resetButtonStyle: resetButtonStyle,
  );
}
