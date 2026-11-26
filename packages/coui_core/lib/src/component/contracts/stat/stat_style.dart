/// Per-instance style for `Stat`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/stat/stat_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Stat` should render.
///
/// `CoreStatStyle` carries chrome / dimensional flat fields plus
/// nested slot styles for the label / value / unit / change /
/// description text and the 1-off gaps that separate the card's rows
/// (label → value + unit → change → description). Behavioural / content
/// fields (`label`, `value`, `unit`, `change`, `description`, etc.) stay
/// flat on the widget / contract.
///
/// ```text
/// CoreStatStyle.defaults*
///   → CoreStatStyle.defaultsByVariant[variant]
///   → CoreStatTheme.style                           // project-wide
///   → CoreStatTheme.variantStyles[variant]
///   → widget.statStyle                              // per-instance
/// ```
@immutable
class CoreStatStyle implements CoreStyle<CoreStatStyle> {
  /// Creates a [CoreStatStyle].
  const CoreStatStyle({
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.backgroundColor,
    this.contentGapStyle,
    this.changeIconGapStyle,
    this.valueUnitGapStyle,
    this.labelColor,
    this.valueColor,
    this.unitColor,
    this.emptyValueColor,
    this.positiveColor,
    this.negativeColor,
    this.neutralColor,
    this.descriptionColor,
    this.labelTextStyle,
    this.valueTextStyle,
    this.unitTextStyle,
    this.changeTextStyle,
    this.descriptionTextStyle,
  });

  // ── Chrome (flat) ────────────────────────────

  /// Inner padding around the stat content.
  final CoreEdgeInsets? padding;

  /// Outer border radius of the stat card.
  final CoreBorderRadius? borderRadius;

  /// Outer border colour.
  final CoreColor? borderColor;

  /// Outer border width (logical px).
  final double? borderWidth;

  /// Card background colour.
  final CoreColor? backgroundColor;

  /// Space between the content rows of the card (label ↔ value ↔ change ↔
  /// description), passed as is to the `Gap` between the rows. `null` uses
  /// [defaultContentGapStyle].
  final CoreGapStyle? contentGapStyle;

  /// Space between the change arrow and the change text inside the change
  /// row, passed as is to the `Gap`. `null` uses [defaultChangeIconGapStyle].
  final CoreGapStyle? changeIconGapStyle;

  /// Space between the value and its unit inside the value row, passed as
  /// is to the `Gap`. `null` uses [defaultValueUnitGapStyle].
  final CoreGapStyle? valueUnitGapStyle;

  /// Label text colour.
  final CoreColor? labelColor;

  /// Value text colour.
  final CoreColor? valueColor;

  /// Unit text colour.
  final CoreColor? unitColor;

  /// Colour of the empty-value placeholder drawn when the stat has no
  /// value. The placeholder keeps the value's text style; only the
  /// colour steps down.
  final CoreColor? emptyValueColor;

  /// Colour of the change indicator when `changeType == positive`.
  final CoreColor? positiveColor;

  /// Colour of the change indicator when `changeType == negative`.
  final CoreColor? negativeColor;

  /// Colour of the change indicator when `changeType == neutral`.
  final CoreColor? neutralColor;

  /// Description (footnote) text colour.
  final CoreColor? descriptionColor;

  // ── Slot Styles (nested) ─────────────────────

  /// Label text style override.
  final CoreTextStyle? labelTextStyle;

  /// Value text style override.
  final CoreTextStyle? valueTextStyle;

  /// Unit text style override.
  final CoreTextStyle? unitTextStyle;

  /// Change indicator text style override.
  final CoreTextStyle? changeTextStyle;

  /// Description (footnote) text style override.
  final CoreTextStyle? descriptionTextStyle;

  // ─── Design-system defaults (Phase 6f single source) ────────────

  /// Default inner padding — 20 above and below, 24 either side: the card
  /// is wider than it is tall, so the sides get the larger inset.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space24,
    vertical: CoreSpace.space20,
  );

  /// Default outer border radius.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius16,
  );

  /// Default gap style — `CoreGapStyle(size: 10)` — for the 1-off
  /// gap between the content rows (label-row / value-row / change-row /
  /// description). The whole nested [CoreGapStyle] slot is forwarded to
  /// the `Gap` widget that separates the rows.
  static const CoreGapStyle defaultContentGapStyle = CoreGapStyle(
    size: CoreSpace.space10,
  );

  /// Default gap style — `CoreGapStyle(size: 4)` — for the 1-off
  /// inner gap between the change arrow glyph and the change text
  /// inside the change row.
  static const CoreGapStyle defaultChangeIconGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default gap style — `CoreGapStyle(size: 4)` — for the 1-off gap
  /// between the value and its unit inside the value row.
  static const CoreGapStyle defaultValueUnitGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default label text colour token.
  static const CoreColor defaultLabelColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default value text colour token.
  static const CoreColor defaultValueColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default unit text colour token — the second text tier, a step under
  /// the figure it qualifies.
  static const CoreColor defaultUnitColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default colour token for the empty-value placeholder — the second
  /// text tier, so an absent figure reads as absent rather than as a
  /// figure. Replaces fading the whole card, which also faded the label.
  static const CoreColor defaultEmptyValueColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default colour for the positive change indicator —
  /// `on-success-container`, the success tone at a strength that reads as
  /// text on a card face in every mode.
  static const CoreColor defaultPositiveColor = CoreColor.token(
    CoreColors.onSuccessContainer,
  );

  /// Default colour for the negative change indicator —
  /// `on-error-container`, the error tone at a strength that reads as text
  /// on a card face in every mode.
  static const CoreColor defaultNegativeColor = CoreColor.token(
    CoreColors.onErrorContainer,
  );

  /// Default colour for the neutral change indicator.
  static const CoreColor defaultNeutralColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default description text colour token — the third text tier: the
  /// footnote reads under the label and the change it follows.
  static const CoreColor defaultDescriptionColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Default label text style — token-backed `labelLarge` role
  /// (14 / 500 / 1.4) so the resolver materialises it through the active
  /// theme typography (Flutter `.toValue(theme:)`) and Web emits the
  /// matching `text-label-large` class. The label colour lives on the
  /// separate [defaultLabelColor] slot, applied at the EMIT step.
  // A label role, not a body one — the slot is the figure's LABEL.
  static const CoreTextStyle defaultLabelTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
  );

  /// Default value text style — token-backed `headlineLarge` role
  /// (32 / 700 / 1.4): the figure is the one thing a stat exists to show.
  /// The value colour lives on the separate [defaultValueColor] slot.
  static const CoreTextStyle defaultValueTextStyle = CoreTextStyle.token(
    CoreTextStyles.headlineLarge,
  );

  /// Default unit text style — token-backed `titleMedium` role (18 / 1.4)
  /// with a 500 component weight over the role's 600, so the unit sits a
  /// weight under the figure it qualifies. The unit colour lives on
  /// the separate [defaultUnitColor] slot.
  ///
  /// `final` rather than `const`: the weight is overlaid with `copyWith`,
  /// which a constant expression cannot invoke, and building it from raw
  /// fields instead would drop the role token the resolvers read.
  static final CoreTextStyle defaultUnitTextStyle = const CoreTextStyle.token(
    CoreTextStyles.titleMedium,
  ).copyWith(fontWeight: CoreFontWeight.medium);

  /// Default change indicator text style — token-backed `labelMedium`
  /// role. The change colour is per-change-type
  /// ([defaultPositiveColor] / [defaultNegativeColor] /
  /// [defaultNeutralColor]) and applied at the EMIT step.
  static const CoreTextStyle defaultChangeTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
  );

  /// Default description text style — token-backed `labelMedium` role
  /// (13 / 500 / 1.4). The description colour lives on the separate
  /// [defaultDescriptionColor] slot.
  static const CoreTextStyle defaultDescriptionTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
  );

  /// Per-variant chrome (border / background) — single source of truth
  /// shared by Flutter and Web. `filled` is the default: the card is
  /// marked by its tone. `outlined` marks it by a line on the page ground.
  static const Map<CoreStatVariant, CoreStatVariantStyle> defaultsByVariant = {
    CoreStatVariant.outlined: CoreStatVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
      borderColor: CoreColor.token(CoreColors.outlineVariant),
      borderWidth: CoreStrokeWidth.stroke1,
    ),
    CoreStatVariant.filled: CoreStatVariantStyle(
      // `surfaceContainerLow` — one step above the page, the elevated-card
      // step: the filled card also casts a shadow, so `surfaceContainer`
      // floated it brighter than the sidebar on dashboards (designer
      // decision 2026-11-04).
      backgroundColor: CoreColor.token(
        CoreColors.surfaceContainerLow,
        fallbacks: [CoreColors.surface],
      ),
      // Explicit transparent border — a null borderColor lets Flutter's
      // `OutlinedContainer` fall back to a `surfaceContainerHigh` hairline
      // even at `borderWidth: 0`, so the filled card would grow a stray
      // border on Flutter that Web (no border class) never drew.
      borderColor: .transparent,
      borderWidth: 0,
    ),
  };

  /// Per-size chrome — padding, the row gap and the five text roles.
  ///
  /// `md` is the card the library has always drawn (the `default*` fields
  /// above). `sm` is the compact card for a dashboard's narrow cells:
  /// 14 above and below, 16 either side, a 4 row gap, and every text one
  /// role down. Each text is its role as the scale states it — no weight
  /// overlay — so the figure is `titleLarge` at the role's own weight and
  /// a canvas label can carry the role's text style. The label and
  /// description are Regular and the figure, unit and change are heavier,
  /// so the figure still leads at the smaller size. Sizes the table does
  /// not state render at the nearest stated one below them
  /// (`resolveSizeRow`).
  static final Map<CoreComponentSize, CoreStatStyle> defaultsBySize = {
    CoreComponentSize.md: CoreStatStyle(
      padding: defaultPadding,
      contentGapStyle: defaultContentGapStyle,
      labelTextStyle: defaultLabelTextStyle,
      valueTextStyle: defaultValueTextStyle,
      unitTextStyle: defaultUnitTextStyle,
      changeTextStyle: defaultChangeTextStyle,
      descriptionTextStyle: defaultDescriptionTextStyle,
    ),
    CoreComponentSize.sm: const CoreStatStyle(
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space16,
        vertical: CoreSpace.space14,
      ),
      contentGapStyle: CoreGapStyle(size: CoreSpace.space4),
      labelTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
      valueTextStyle: CoreTextStyle.token(CoreTextStyles.titleLarge),
      unitTextStyle: CoreTextStyle.token(CoreTextStyles.labelXl),
      changeTextStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
      descriptionTextStyle: CoreTextStyle.token(CoreTextStyles.bodyXs),
    ),
  };

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreStatStyle merge(CoreStatStyle? other) {
    if (other == null) return this;
    return CoreStatStyle(
      padding: other.padding ?? padding,
      borderRadius: other.borderRadius ?? borderRadius,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      contentGapStyle: _mergeGap(contentGapStyle, other.contentGapStyle),
      changeIconGapStyle: _mergeGap(
        changeIconGapStyle,
        other.changeIconGapStyle,
      ),
      valueUnitGapStyle: _mergeGap(valueUnitGapStyle, other.valueUnitGapStyle),
      labelColor: other.labelColor ?? labelColor,
      valueColor: other.valueColor ?? valueColor,
      unitColor: other.unitColor ?? unitColor,
      emptyValueColor: other.emptyValueColor ?? emptyValueColor,
      positiveColor: other.positiveColor ?? positiveColor,
      negativeColor: other.negativeColor ?? negativeColor,
      neutralColor: other.neutralColor ?? neutralColor,
      descriptionColor: other.descriptionColor ?? descriptionColor,
      labelTextStyle: _mergeText(labelTextStyle, other.labelTextStyle),
      valueTextStyle: _mergeText(valueTextStyle, other.valueTextStyle),
      unitTextStyle: _mergeText(unitTextStyle, other.unitTextStyle),
      changeTextStyle: _mergeText(changeTextStyle, other.changeTextStyle),
      descriptionTextStyle: _mergeText(
        descriptionTextStyle,
        other.descriptionTextStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreStatStyle copyWith({
    CoreEdgeInsets? padding,
    CoreBorderRadius? borderRadius,
    CoreColor? borderColor,
    double? borderWidth,
    CoreColor? backgroundColor,
    CoreGapStyle? contentGapStyle,
    CoreGapStyle? changeIconGapStyle,
    CoreGapStyle? valueUnitGapStyle,
    CoreColor? labelColor,
    CoreColor? valueColor,
    CoreColor? unitColor,
    CoreColor? emptyValueColor,
    CoreColor? positiveColor,
    CoreColor? negativeColor,
    CoreColor? neutralColor,
    CoreColor? descriptionColor,
    CoreTextStyle? labelTextStyle,
    CoreTextStyle? valueTextStyle,
    CoreTextStyle? unitTextStyle,
    CoreTextStyle? changeTextStyle,
    CoreTextStyle? descriptionTextStyle,
  }) {
    return CoreStatStyle(
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      contentGapStyle: contentGapStyle ?? this.contentGapStyle,
      changeIconGapStyle: changeIconGapStyle ?? this.changeIconGapStyle,
      valueUnitGapStyle: valueUnitGapStyle ?? this.valueUnitGapStyle,
      labelColor: labelColor ?? this.labelColor,
      valueColor: valueColor ?? this.valueColor,
      unitColor: unitColor ?? this.unitColor,
      emptyValueColor: emptyValueColor ?? this.emptyValueColor,
      positiveColor: positiveColor ?? this.positiveColor,
      negativeColor: negativeColor ?? this.negativeColor,
      neutralColor: neutralColor ?? this.neutralColor,
      descriptionColor: descriptionColor ?? this.descriptionColor,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      valueTextStyle: valueTextStyle ?? this.valueTextStyle,
      unitTextStyle: unitTextStyle ?? this.unitTextStyle,
      changeTextStyle: changeTextStyle ?? this.changeTextStyle,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStatStyle &&
          runtimeType == other.runtimeType &&
          padding == other.padding &&
          borderRadius == other.borderRadius &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          backgroundColor == other.backgroundColor &&
          contentGapStyle == other.contentGapStyle &&
          changeIconGapStyle == other.changeIconGapStyle &&
          valueUnitGapStyle == other.valueUnitGapStyle &&
          labelColor == other.labelColor &&
          valueColor == other.valueColor &&
          unitColor == other.unitColor &&
          emptyValueColor == other.emptyValueColor &&
          positiveColor == other.positiveColor &&
          negativeColor == other.negativeColor &&
          neutralColor == other.neutralColor &&
          descriptionColor == other.descriptionColor &&
          labelTextStyle == other.labelTextStyle &&
          valueTextStyle == other.valueTextStyle &&
          unitTextStyle == other.unitTextStyle &&
          changeTextStyle == other.changeTextStyle &&
          descriptionTextStyle == other.descriptionTextStyle;

  @override
  int get hashCode => Object.hashAll([
    padding,
    borderRadius,
    borderColor,
    borderWidth,
    backgroundColor,
    contentGapStyle,
    changeIconGapStyle,
    valueUnitGapStyle,
    labelColor,
    valueColor,
    unitColor,
    emptyValueColor,
    positiveColor,
    negativeColor,
    neutralColor,
    descriptionColor,
    labelTextStyle,
    valueTextStyle,
    unitTextStyle,
    changeTextStyle,
    descriptionTextStyle,
  ]);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Variant-dependent chrome (background / border colours / border
/// width) for `Stat`.
///
/// Held in [CoreStatStyle.defaultsByVariant] as the single source of
/// truth shared by Flutter and Web `Stat`.
@immutable
class CoreStatVariantStyle {
  /// Creates a [CoreStatVariantStyle].
  const CoreStatVariantStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
  });

  /// Default card background colour.
  final CoreColor backgroundColor;

  /// Default outer border colour.
  final CoreColor borderColor;

  /// Default outer border width (logical px).
  final double borderWidth;
}
