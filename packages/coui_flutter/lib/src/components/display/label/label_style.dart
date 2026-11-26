import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedLabel
// ═══════════════════════════════════════════════════

/// Resolver output for `Label`.
///
/// Single struct that the widget reads — every chrome / dimensional /
/// text-style override has been merged through:
///
/// ```text
/// design system default (CoreLabelStyle.defaultX static const)
///   → theme.coreComponentTheme.label.style
///   → widget.labelStyle
/// ```
class ResolvedLabel {
  /// Creates a [ResolvedLabel].
  const ResolvedLabel({
    required this.iconSize,
    required this.iconLabelGapStyle,
    required this.labelRequiredGapStyle,
    required this.disabledOpacity,
    required this.requiredColor,
    required this.textStyle,
  });

  /// Leading icon size — flat paint-ready value (already `* scaling`).
  /// The widget feeds this straight into an `IconTheme` (the caller's
  /// icon is a plain `Widget`, not a `Icon`), so the resolver owns
  /// scaling here rather than forwarding a nested `CoreIconStyle` slot.
  final double iconSize;

  /// Nested [CoreGapStyle] slot for the gap between the leading icon
  /// and the label text — forwarded straight to `Gap(gapStyle: …)`.
  /// `Gap` runs its own resolve / scaling step, so this slot is the
  /// merged design-system default + per-instance override in
  /// pre-scaling units (the receiving widget owns scaling).
  final CoreGapStyle iconLabelGapStyle;

  /// Nested [CoreGapStyle] slot for the gap between the label text
  /// and the required indicator (`*`) — forwarded straight to
  /// `Gap(gapStyle: …)`. `Gap` runs its own resolve / scaling
  /// step, so this slot is the merged design-system default +
  /// per-instance override in pre-scaling units (the receiving widget
  /// owns scaling).
  final CoreGapStyle labelRequiredGapStyle;

  /// Opacity applied when `disabled` is `true`.
  final double disabledOpacity;

  /// Required indicator (`*`) colour — `error` when enabled, the colour of
  /// [textStyle] when disabled.
  final Color requiredColor;

  /// Text style for the label text (final colour already applied —
  /// `onSurface` when enabled, `disabledContent` when disabled).
  final TextStyle textStyle;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedLabel] for the given [context].
///
/// Priority (per-field):
/// `widget.labelStyle` > `CoreLabelTheme.style` > `CoreLabelStyle.defaultX`
/// design-system defaults.
ResolvedLabel resolveLabel(
  BuildContext context, {
  required bool disabled,
  CoreLabelStyle? labelStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final labelTheme = theme.coreComponentTheme?.label;

  final merged = resolveStyleChain(const CoreLabelStyle(), [
    labelTheme?.style,
    labelStyle,
  ]);

  // Leading icon — the caller passes a plain `Widget` that the widget
  // wraps in an `IconTheme`, not a `Icon`, so there is no child
  // resolver to delegate scaling to. Merge the design-system default
  // with the per-instance override, then emit a flat paint-ready
  // `iconSize` (scaled at the return) instead of a nested `CoreIconStyle`
  // slot — keeping scaling inside the resolver (Anti-Pattern A: no
  // `copyWith(size: … * scaling)` on a forwarded nested Style slot).
  final mergedIconStyle = CoreLabelStyle.defaultIconStyle.merge(
    merged.iconStyle,
  );
  final iconSize = (mergedIconStyle.size!) * scaling;
  // Nested `CoreGapStyle` slots — merge the design-system default with
  // the per-instance override and forward raw (pre-scaling) to
  // `Gap`, which runs its own resolve / scaling step.
  final iconLabelGapStyle = CoreLabelStyle.defaultIconLabelGapStyle.merge(
    merged.iconLabelGapStyle,
  );
  final labelRequiredGapStyle = CoreLabelStyle.defaultLabelRequiredGapStyle
      .merge(merged.labelRequiredGapStyle);
  final disabledOpacity =
      merged.disabledOpacity ?? CoreLabelStyle.defaultDisabledOpacity;

  // RESOLVE Stage 1 — the token-backed default text style merged with the
  // per-instance override, picked by state. The disabled axis lives in its
  // own nested `disabledTextStyle` slot (sb8) so typography + colour for
  // the muted state stay 1:1 with the enabled path.
  final labelTextStyle = disabled
      ? CoreLabelStyle.defaultDisabledTextStyle.merge(merged.disabledTextStyle)
      : CoreLabelStyle.defaultTextStyle.merge(merged.textStyle);

  // EMIT Stage 2 (Flutter) — the text style is materialised in one step via
  // `.toValue(theme:)`. That single primitive resolves the typography
  // role slot (size/weight/spacing/height) AND resolves the slot's own
  // `color` token through the active scheme (dark-mode tracks), so no
  // hand-rolled `typography.resolve` + `scheme.resolve(...).copyWith`
  // assembly.
  final textStyle = labelTextStyle.toValue(theme: theme);
  // A disabled label paints its text, its `*` and its icon with the one
  // colour its text style carries, so `requiredColor` only speaks for the
  // enabled state.
  final requiredColor = scheme
      .resolve(
        disabled
            ? labelTextStyle.color!
            : merged.requiredColor ?? CoreLabelStyle.defaultRequiredColor,
      )
      .toValue();

  return ResolvedLabel(
    iconSize: iconSize,
    iconLabelGapStyle: iconLabelGapStyle,
    labelRequiredGapStyle: labelRequiredGapStyle,
    disabledOpacity: disabledOpacity,
    requiredColor: requiredColor,
    textStyle: textStyle,
  );
}
