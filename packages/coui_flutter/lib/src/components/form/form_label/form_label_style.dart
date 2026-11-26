import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedFormLabel
// ═══════════════════════════════════════════════════

/// Resolver output for [FormLabel].
///
/// Single struct that the widget reads — every chrome / typography
/// override has had the nested-merge chain applied plus the
/// `CoreFormLabelStyle.defaultX` static const fallback and Flutter
/// type conversion:
///
/// ```text
/// CoreFormLabelStyle.defaultX            // design system default
///   → theme.coreComponentTheme.formLabel.style
///   → widget.formLabelStyle
/// ```
class ResolvedFormLabel {
  /// Creates a [ResolvedFormLabel].
  const ResolvedFormLabel({
    required this.labelTextStyle,
    required this.requiredColor,
    required this.requiredIndicatorGapStyle,
  });

  /// Effective text style applied to the label content (typography
  /// role + label colour overlay).
  final TextStyle labelTextStyle;

  /// Effective colour of the required indicator (`*`).
  final Color requiredColor;

  /// Nested [CoreGapStyle] slot for the gap between the label and the
  /// required indicator — forwarded straight to `Gap(gapStyle: …)`.
  /// `Gap` runs its own resolve step, so this slot is the merged
  /// design-system default + per-instance override in pre-scaling
  /// units (the receiving widget owns scaling).
  final CoreGapStyle requiredIndicatorGapStyle;
}

// ═══════════════════════════════════════════════════
// resolveFormLabel — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFormLabel] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreFormLabelStyle.defaultX` static const fallback so the widget
/// reads only fully-resolved Flutter-typed values.
ResolvedFormLabel resolveFormLabel(
  BuildContext context, {
  required CoreComponentSize size,
  bool enabled = true,
  CoreFormLabelStyle? formLabelStyle,
}) {
  final theme = Theme.of(context);
  final formLabelTheme = theme.coreComponentTheme?.formLabel;

  // Stage 1 RESOLVE — theme.style → widget.formLabelStyle.
  final merged = resolveStyleChain(const CoreFormLabelStyle(), [
    formLabelTheme?.style,
    formLabelStyle,
  ]);

  // Stage 1 RESOLVE — the size-keyed default (role + colour) is the
  // merge base for the composite typography slot, not `defaultLabelStyle`
  // directly — `xs`/`sm`/`md` settle on the 13px rung, `lg`/`xl`/`xl2` on
  // the 14px rung (`CoreFormLabelStyle.defaultsBySize`).
  final sizeLabelStyle = CoreFormLabelStyle.defaultsBySize[size]!.labelStyle!;
  final disabledColor =
      merged.disabledColor ?? CoreFormLabelStyle.defaultDisabledColor;

  // `enabled` forces the colour half of the label's composite style —
  // the size-derived role (fontSize/weight) still applies underneath,
  // and any per-instance colour override is overridden right back to
  // `disabledColor` rather than silently winning over the disabled
  // state (the same "select between resolved values" shape as any
  // other per-state VALUE, not a runtime DETECTION branch).
  final labelStyleBase = enabled
      ? sizeLabelStyle
      : sizeLabelStyle.copyWith(color: disabledColor);
  final labelStyleOverride = enabled
      ? merged.labelStyle
      : merged.labelStyle?.copyWith(color: disabledColor);
  final labelStyle = labelStyleBase.merge(labelStyleOverride);

  final requiredColor = enabled
      ? (merged.requiredColor ?? CoreFormLabelStyle.defaultRequiredColor)
      : disabledColor;

  final requiredIndicatorGapStyle = CoreFormLabelStyle
      .defaultRequiredIndicatorGapStyle
      .merge(merged.requiredIndicatorGapStyle);

  // Stage 2 EMIT — typography role + colour materialised through the
  // single `style.toValue(theme:)` primitive; required colour through
  // `scheme.resolve(c).toValue()`.
  final labelTextStyle = labelStyle.toValue(theme: theme);
  final requiredColorValue = theme.colorScheme.resolve(requiredColor).toValue();

  return ResolvedFormLabel(
    labelTextStyle: labelTextStyle,
    requiredColor: requiredColorValue,
    requiredIndicatorGapStyle: requiredIndicatorGapStyle,
  );
}
