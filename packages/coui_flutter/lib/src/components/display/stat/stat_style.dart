/// Style slot resolution for Flutter `Stat`.
///
/// Single entry point — `resolveStat` runs the full merge chain
/// (`CoreStatStyle.defaults*` → `defaultsByVariant[variant]` →
/// `CoreStatTheme.style` → `variantStyles[variant]` →
/// `widget.statStyle`) and produces [ResolvedStat]. The widget reads
/// `resolved.X` only and never touches `theme.coreComponentTheme`
/// directly.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/theme/theme.dart';
import 'package:coui_flutter/src/util/core_to_flutter.dart';
import 'package:flutter/widgets.dart';

// ═══════════════════════════════════════════════════
// ResolvedStat
// ═══════════════════════════════════════════════════

/// Resolver output for Flutter `Stat`.
///
/// ```text
/// OutlinedContainer (containerStyle)
///   └─ Column
///        ├─ Row (label + optional icon)
///        │    └─ Text(label, labelTextStyle)
///        ├─ Gap (contentGapStyle — row gap)
///        ├─ Row (baseline-aligned value row, shrink-wrapped)
///        │    ├─ Flexible → Text(value, valueTextStyle)
///        │    │    — or Text('—', emptyValueTextStyle) when value == null
///        │    └─ when unit != null and value != null:
///        │         ├─ Gap (valueUnitGapStyle — inner gap)
///        │         └─ Text(unit, unitTextStyle)
///        ├─ when change != null:
///        │    ├─ Gap (contentGapStyle — row gap)
///        │    └─ Row
///        │         ├─ Text(arrow, changeTextStyle)
///        │         ├─ Gap (changeIconGapStyle — inner gap)
///        │         └─ Text(change, changeTextStyle)
///        └─ when description != null:
///             ├─ Gap (contentGapStyle — row gap)
///             └─ Text(description, descriptionTextStyle)
/// ```
///
/// The outer chrome box (background / border / radius / padding) is
/// composed via `OutlinedContainer` (`containerStyle`) rather than
/// hand-drawn — the same primitive `Card` composes — so `Stat` picks
/// up the active theme's surface material (glass blur / opacity),
/// forced-colours-safe border, and injected control-shadow fallback
/// for free (`core/style-contract.md`'s child-component-composition
/// rule). Holds every other value the widget needs, with type
/// conversions already applied (Flutter `TextStyle`). Gap slots are
/// forwarded raw (`CoreGapStyle`) so `Gap` runs its own resolve /
/// scaling step.
class ResolvedStat {
  /// Creates a [ResolvedStat].
  const ResolvedStat({
    required this.variant,
    required this.containerStyle,
    required this.contentGapStyle,
    required this.changeIconGapStyle,
    required this.valueUnitGapStyle,
    required this.labelTextStyle,
    required this.valueTextStyle,
    required this.emptyValueTextStyle,
    required this.unitTextStyle,
    required this.changeTextStylePositive,
    required this.changeTextStyleNegative,
    required this.changeTextStyleNeutral,
    required this.descriptionTextStyle,
  });

  /// Variant chosen by the widget.
  final CoreStatVariant variant;

  /// Child-component contract slot for the composed `OutlinedContainer`,
  /// which owns the card box — fill, border, radius, and padding.
  ///
  /// Carries *pre-EMIT* Core values on purpose: `OutlinedContainer` runs
  /// the same `scheme.resolve` / `geometry.stroke` / scaling steps this
  /// resolver would, so handing it finished Flutter values would bend
  /// them twice.
  final CoreOutlinedContainerStyle containerStyle;

  /// Nested [CoreGapStyle] slot for the 1-off gap between the content
  /// rows (label-row / value-row / change-row / description) — forwarded
  /// straight to `Gap(gapStyle: …)`. Pre-scaling (the receiving `Gap`
  /// owns scaling).
  final CoreGapStyle contentGapStyle;

  /// Nested [CoreGapStyle] slot for the 1-off inner gap between the
  /// change arrow glyph and the change text inside the change row —
  /// forwarded straight to `Gap(gapStyle: …)`. Pre-scaling.
  final CoreGapStyle changeIconGapStyle;

  /// Nested [CoreGapStyle] slot for the 1-off gap between the value and
  /// its unit inside the value row — forwarded straight to
  /// `Gap(gapStyle: …)`. Pre-scaling.
  final CoreGapStyle valueUnitGapStyle;

  /// Effective label text style (typography role + label colour).
  final TextStyle labelTextStyle;

  /// Effective value text style (typography role + value colour).
  final TextStyle valueTextStyle;

  /// Effective style of the empty-value placeholder — the value's
  /// typography role with the empty-value colour baked in. The widget
  /// selects it in place of [valueTextStyle] when the value is `null`.
  final TextStyle emptyValueTextStyle;

  /// Effective unit text style (typography role + weight overlay + unit
  /// colour).
  final TextStyle unitTextStyle;

  /// Pre-composed change text style when `changeType == positive` —
  /// the change typography role with the positive change colour baked
  /// in. The widget selects this slot via a `switch` on the semantic
  /// enum (render-only — no `copyWith` in the widget body).
  final TextStyle changeTextStylePositive;

  /// Pre-composed change text style when `changeType == negative`.
  final TextStyle changeTextStyleNegative;

  /// Pre-composed change text style when `changeType == neutral`.
  final TextStyle changeTextStyleNeutral;

  /// Effective description text style (typography role + description
  /// colour).
  final TextStyle descriptionTextStyle;
}

// ═══════════════════════════════════════════════════
// resolveStat (single entry point)
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStat] for the given [context].
///
/// ```text
/// CoreStatStyle.defaults*
///   → CoreStatStyle.defaultsByVariant[variant]
///   → CoreStatTheme.style
///   → CoreStatTheme.variantStyles[variant]
///   → widget.statStyle
/// ```
ResolvedStat resolveStat(
  BuildContext context, {
  required CoreStatVariant variant,
  CoreComponentSize size = CoreComponentSize.md,
  CoreStatStyle? statStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final stTheme = theme.coreComponentTheme?.stat;

  // Variant-specific chrome defaults from defaultsByVariant.
  final chrome = CoreStatStyle.defaultsByVariant[variant]!;

  // Size-dependent defaults (padding / row gap / text roles).
  final sizeStyle = resolveSizeRow(CoreStatStyle.defaultsBySize, size);

  // 3-stage merge chain.
  final merged = resolveStyleChain(const CoreStatStyle(), [
    stTheme?.style,
    stTheme?.variantStyles?[variant],
    statStyle,
  ]);

  // The card box (background / border / radius / padding) is composed via
  // `OutlinedContainer` rather than drawn here — the same primitive `Card`
  // composes for its own box (`core/style-contract.md`'s
  // child-component-composition rule). Passing Core values (not resolved
  // Flutter ones) is what keeps the geometry bend applied exactly once:
  // `OutlinedContainer` runs `scheme.resolve` / `geometry.stroke` /
  // scaling itself. Composing is also what gets this surface the active
  // theme's injected material (glass blur / opacity) and control-shadow
  // fallback, which it drew nothing of while it owned its own
  // `BoxDecoration`.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: merged.backgroundColor ?? chrome.backgroundColor,
    borderColor: merged.borderColor ?? chrome.borderColor,
    borderRadius: merged.borderRadius ?? CoreStatStyle.defaultBorderRadius,
    borderWidth: merged.borderWidth ?? chrome.borderWidth,
    padding: merged.padding ?? sizeStyle.padding!,
  );

  // Nested `CoreGapStyle` slots — merge the design-system default
  // with the per-instance override and forward raw (pre-scaling) to
  // `Gap`, which runs its own resolve / scaling step.
  final contentGapStyle = sizeStyle.contentGapStyle!.merge(
    merged.contentGapStyle,
  );
  final changeIconGapStyle = CoreStatStyle.defaultChangeIconGapStyle.merge(
    merged.changeIconGapStyle,
  );
  final valueUnitGapStyle = CoreStatStyle.defaultValueUnitGapStyle.merge(
    merged.valueUnitGapStyle,
  );

  // ─── Stage 1 RESOLVE — text colours (CoreColor, scalar `??`) ───
  final labelColorCore = merged.labelColor ?? CoreStatStyle.defaultLabelColor;
  final valueColorCore = merged.valueColor ?? CoreStatStyle.defaultValueColor;
  final emptyValueColorCore =
      merged.emptyValueColor ?? CoreStatStyle.defaultEmptyValueColor;
  final unitColorCore = merged.unitColor ?? CoreStatStyle.defaultUnitColor;
  final positiveColorCore =
      merged.positiveColor ?? CoreStatStyle.defaultPositiveColor;
  final negativeColorCore =
      merged.negativeColor ?? CoreStatStyle.defaultNegativeColor;
  final neutralColorCore =
      merged.neutralColor ?? CoreStatStyle.defaultNeutralColor;
  final descriptionColorCore =
      merged.descriptionColor ?? CoreStatStyle.defaultDescriptionColor;

  // ─── Stage 1 RESOLVE — typography (CoreTextStyle, composite merge) ──
  // Token-backed design-system role merged with the per-instance overlay
  // (composite — a caller overriding only `fontWeight` keeps the role).
  final labelTextStyleCore = sizeStyle.labelTextStyle!.merge(
    merged.labelTextStyle,
  );
  final valueTextStyleCore = sizeStyle.valueTextStyle!.merge(
    merged.valueTextStyle,
  );
  final unitTextStyleCore = sizeStyle.unitTextStyle!.merge(
    merged.unitTextStyle,
  );
  final changeTextStyleCore = sizeStyle.changeTextStyle!.merge(
    merged.changeTextStyle,
  );
  final descriptionTextStyleCore = sizeStyle.descriptionTextStyle!.merge(
    merged.descriptionTextStyle,
  );

  // ─── Stage 2 EMIT (Flutter) — color = .resolve.toValue ─────────
  final labelColor = scheme.resolve(labelColorCore).toValue();
  final valueColor = scheme.resolve(valueColorCore).toValue();
  final emptyValueColor = scheme.resolve(emptyValueColorCore).toValue();
  final unitColor = scheme.resolve(unitColorCore).toValue();
  final positiveColor = scheme.resolve(positiveColorCore).toValue();
  final negativeColor = scheme.resolve(negativeColorCore).toValue();
  final neutralColor = scheme.resolve(neutralColorCore).toValue();
  final descriptionColor = scheme.resolve(descriptionColorCore).toValue();

  // ─── Stage 2 EMIT (Flutter) — typography = .toValue(theme:, color:) ──
  // `toValue(theme:)` materialises the token role against the active
  // theme typography and resolves any token colour through the scheme.
  // The `color:` override forces each row's chrome colour. The change
  // row carries a per-change-type colour (positive / negative / neutral)
  // baked into three pre-composed slots so the widget selects via
  // `switch` (render-only — no widget-side `copyWith`); the empty-value
  // placeholder is the value role with its own colour baked in, for the
  // same reason.
  final labelTextStyle = labelTextStyleCore.toValue(
    color: labelColor,
    theme: theme,
  );
  final valueTextStyle = valueTextStyleCore.toValue(
    color: valueColor,
    theme: theme,
  );
  final emptyValueTextStyle = valueTextStyleCore.toValue(
    color: emptyValueColor,
    theme: theme,
  );
  final unitTextStyle = unitTextStyleCore.toValue(
    color: unitColor,
    theme: theme,
  );
  final changeTextStylePositive = changeTextStyleCore.toValue(
    color: positiveColor,
    theme: theme,
  );
  final changeTextStyleNegative = changeTextStyleCore.toValue(
    color: negativeColor,
    theme: theme,
  );
  final changeTextStyleNeutral = changeTextStyleCore.toValue(
    color: neutralColor,
    theme: theme,
  );
  final descriptionTextStyle = descriptionTextStyleCore.toValue(
    color: descriptionColor,
    theme: theme,
  );

  return ResolvedStat(
    variant: variant,
    containerStyle: containerStyle,
    contentGapStyle: contentGapStyle,
    changeIconGapStyle: changeIconGapStyle,
    valueUnitGapStyle: valueUnitGapStyle,
    labelTextStyle: labelTextStyle,
    valueTextStyle: valueTextStyle,
    emptyValueTextStyle: emptyValueTextStyle,
    unitTextStyle: unitTextStyle,
    changeTextStylePositive: changeTextStylePositive,
    changeTextStyleNegative: changeTextStyleNegative,
    changeTextStyleNeutral: changeTextStyleNeutral,
    descriptionTextStyle: descriptionTextStyle,
  );
}
