import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedSelect
// ═══════════════════════════════════════════════════

/// Resolver output for `Select`.
///
/// Every chrome / dimensional / nested-slot override has been merged
/// through:
///
/// ```text
/// design system default for select
///   → theme.coreComponentTheme.select.style
///   → theme.coreComponentTheme.select.variantStyles[variant]
///   → widget.selectStyle
/// ```
///
/// Widget tree:
///
/// ```text
/// Popover (popoverStyle — panel box, 4 below the trigger, width = trigger)
///   ├─ trigger TextField (triggerStyle · readOnly · suffix chevron)
///   │    └─ Icon(chevronDown) — chevronIconStyle
///   └─ panel ConstrainedBox(maxHeight: optionsPanelMaxHeight)
///         ├─ MenuItem × n (optionStyle) — mark = check on the selected row
///         └─ Padding(emptyStateInsets) → Text — emptyStateTextStyle
/// ```
///
/// The trigger is a field and the rows are menu rows, so almost nothing
/// here is Select's own: [triggerStyle] and [optionStyle] are raw-forwarded
/// and each child resolver fills its own ladder. What Select settles is the
/// panel ([popoverStyle]), the chevron ([chevronIconStyle]), and the
/// empty-state copy.
class ResolvedSelect {
  /// Creates a [ResolvedSelect].
  const ResolvedSelect({
    required this.optionsPanelMaxHeight,
    required this.optionSpacing,
    required this.popoverStyle,
    required this.triggerStyle,
    required this.optionStyle,
    required this.chevronIconStyle,
    required this.emptyStateInsets,
    required this.emptyStateTextStyle,
  });

  /// Maximum height of the options panel (logical px, scaling-applied).
  final double optionsPanelMaxHeight;

  /// Vertical gap between consecutive option rows (logical px,
  /// scaling-applied).
  final double optionSpacing;

  /// Nested popover style — forwarded to the wrapping [Popover].
  final CorePopoverStyle popoverStyle;

  /// Nested trigger style — forwarded to the composed [TextField].
  final CoreTextFieldStyle triggerStyle;

  /// Nested row style — forwarded to each composed [MenuItem].
  final CoreMenuItemStyle optionStyle;

  /// Trigger chevron icon style — raw-forwarded to `Icon(iconStyle:)`.
  final CoreIconStyle chevronIconStyle;

  /// Empty-state surface padding (paint-ready, scaling-applied).
  final EdgeInsets emptyStateInsets;

  /// Empty-state copy text style (paint-ready).
  final TextStyle emptyStateTextStyle;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSelect] for the given [context].
ResolvedSelect resolveSelect(
  BuildContext context, {
  CoreSelectSize size = CoreSelectSize.defaultSize,
  CoreSelectVariant variant = CoreSelectVariant.defaultSelectVariant,
  CoreSelectStyle? selectStyle,
  bool enabled = true,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final selectTheme = theme.coreComponentTheme?.select;

  final merged = resolveStyleChain(const CoreSelectStyle(), [
    selectTheme?.style,
    selectTheme?.variantStyles?[variant],
    selectStyle,
  ]);
  final sizeStyle = CoreSelectStyle.defaultsBySize[size]!;

  // ─── Stage 1 RESOLVE ──────────────────────────────────
  final optionsPanelMaxHeight =
      merged.optionsPanelMaxHeight ??
      CoreSelectStyle.defaultOptionsPanelMaxHeight;
  final optionSpacing =
      merged.optionSpacing ?? CoreSelectStyle.defaultOptionSpacing;
  final emptyStateInsets =
      merged.emptyStateInsets ?? CoreSelectStyle.defaultEmptyStateInsets;

  // Nested slots — raw-forwarded; each child resolver fills its own
  // ladder. Select diverges from the field and the row in nothing.
  final popoverStyle = CoreSelectStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );
  // guard-nested-override: contentColor — `merged.contentColor` is folded
  // into `effectiveTriggerStyle` as the value text colour.
  // guard-nested-override: selectedIconColor — `merged.selectedIconColor`
  // is folded into `effectiveOptionStyle` as the mark colour.
  final triggerStyle = enabled
      ? merged.effectiveTriggerStyle
      : merged.effectiveDisabledTriggerStyle;
  final optionStyle = merged.effectiveOptionStyle;

  // The chevron: the size ladder's rung, tinted like the placeholder —
  // it is the field's affordance, not its content. That tint wins over
  // a caller-supplied `trailingIconStyle.color`; the dedicated entry
  // point for it is `placeholderColor`.
  // guard-nested-override: color — placeholder tint wins over
  // `trailingIconStyle.color`; override via `placeholderColor` instead.
  // A disabled select leaves the chevron untinted: the field's own icon
  // tone for a disabled control applies (`disabledContent`).
  final chevronRung = sizeStyle.trailingIconStyle!.merge(
    merged.trailingIconStyle,
  );
  final chevronIconStyle = enabled
      ? chevronRung.copyWith(
          color:
              merged.placeholderColor ??
              CoreSelectStyle.defaultPlaceholderColor,
        )
      : chevronRung;

  // ─── Stage 2 EMIT ─────────────────────────────────────
  final optionsPanelMaxHeightValue = optionsPanelMaxHeight * scaling;
  final optionSpacingValue = theme.geometry.space(optionSpacing) * scaling;
  final emptyStateInsetsValue =
      emptyStateInsets.toValue(geometry: theme.geometry) * scaling;
  final emptyStateTextStyle = CoreTextStyle(
    color: merged.emptyStateColor ?? CoreSelectStyle.defaultEmptyStateColor,
  ).merge(merged.emptyStateStyle).toValue(theme: theme);

  return ResolvedSelect(
    optionsPanelMaxHeight: optionsPanelMaxHeightValue,
    optionSpacing: optionSpacingValue,
    popoverStyle: popoverStyle,
    triggerStyle: triggerStyle,
    optionStyle: optionStyle,
    chevronIconStyle: chevronIconStyle,
    emptyStateInsets: emptyStateInsetsValue,
    emptyStateTextStyle: emptyStateTextStyle,
  );
}
