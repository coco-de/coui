import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/validation_badge/validation_badge_size.dart';
import 'package:coui_core/src/component/contracts/validation_badge/validation_state.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Per-state color override bundle for `ValidationBadge`.
@immutable
class CoreValidationBadgeStyle implements CoreStyle<CoreValidationBadgeStyle> {
  /// Creates a [CoreValidationBadgeStyle].
  const CoreValidationBadgeStyle({
    this.pendingBackgroundColor,
    this.pendingLabelTextStyle,
    this.pendingBorderColor,
    this.validBackgroundColor,
    this.validLabelTextStyle,
    this.validBorderColor,
    this.invalidBackgroundColor,
    this.invalidLabelTextStyle,
    this.invalidBorderColor,
    this.iconLabelGapStyle,
    this.iconStyle,
    this.borderWidth,
  });

  /// Pending background color override.
  final CoreColor? pendingBackgroundColor;

  /// Pending label text style override. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `pendingForegroundColor` field removed). `null` defers to
  /// [defaultPendingLabelTextStyle] over the per-size role from
  /// [defaultsBySize] `[size].labelStyle`.
  final CoreTextStyle? pendingLabelTextStyle;

  /// Pending border color override.
  final CoreColor? pendingBorderColor;

  /// Valid background color override.
  final CoreColor? validBackgroundColor;

  /// Valid label text style override. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `validForegroundColor` field removed). `null` defers to
  /// [defaultValidLabelTextStyle] over the per-size role from
  /// [defaultsBySize] `[size].labelStyle`.
  final CoreTextStyle? validLabelTextStyle;

  /// Valid border color override.
  final CoreColor? validBorderColor;

  /// Invalid background color override.
  final CoreColor? invalidBackgroundColor;

  /// Invalid label text style override. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `invalidForegroundColor` field removed). `null` defers to
  /// [defaultInvalidLabelTextStyle] over the per-size role from
  /// [defaultsBySize] `[size].labelStyle`.
  final CoreTextStyle? invalidLabelTextStyle;

  /// Invalid border color override.
  final CoreColor? invalidBorderColor;

  /// Style of the gap between the icon and the label. `null` defers to
  /// [CoreValidationBadgeStyle.defaultsBySize] `[size].iconLabelGapStyle`.
  ///
  /// Forwarded straight to `Gap(gapStyle: …)` (Flutter) / reflected as the
  /// inline `gap` rem rule (Web).
  final CoreGapStyle? iconLabelGapStyle;

  /// Style of the state icon, passed to `Icon(iconStyle: …)`. `null` uses
  /// a base whose `size` comes from [CoreValidationBadgeStyle.defaultsBySize]
  /// `[size].iconSize` and whose `color` is the state's foreground colour.
  ///
  /// sb #2305 — flat `iconSize` + `iconColor` folded into one nested slot,
  /// mirroring the Web resolver's `iconStyle`.
  ///
  /// No paired `default*`: every value it would carry varies on an axis a
  /// `static const` cannot hold — `size` per size preset, and `color` per
  /// state on Flutter but deliberately absent on Web (the icon inherits the
  /// chip's colour). The slot is an overlay on the base each resolver
  /// composes, not a value with a baseline of its own.
  final CoreIconStyle? iconStyle;

  /// Border stroke width override (logical px). Overrides
  /// [defaultBorderWidth] when set.
  final double? borderWidth;

  // ─── Design-system defaults (Phase 6f option D) ─────────────────

  /// Default size preset when none specified.
  static const CoreValidationBadgeSize defaultSize = .small;

  /// Default border stroke width (logical px). The badge states itself with a
  /// fill, a glyph and a label, so by default it draws no border; a width
  /// above 0 brings back the per-state border colours.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke0;

  // ─── Per-state surface defaults ─────────────────────────────────
  //
  // One named `default*` per overridable per-state colour slot, so each
  // instance field has the 1:1 default the layer mapping requires. The
  // [defaultsByState] table below references these — the named const is
  // the single source and the table is the state dispatch over it, so
  // there is no second copy of any value.

  /// Default `pending` background colour — neutral surface container.
  static const CoreColor defaultPendingBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default `pending` label + icon colour — the muted neutral that reads
  /// as "not judged yet".
  static const CoreColor defaultPendingForegroundColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default `pending` border colour — 20% of the pending foreground.
  ///
  /// Every state's border is the colour that represents that state, at 20%:
  /// `success` for valid, `error` for invalid. Pending has no state colour
  /// of its own, so its representative is its label colour
  /// ([defaultPendingForegroundColor]). The three borders therefore carry
  /// the same visual weight — a solid `outline` here would make "not judged
  /// yet" the loudest of the three, the opposite of its importance.
  ///
  /// It is derived from a foreground, never from a surface tier. The fill
  /// above is `surfaceContainer`; a border one surface tier up sits
  /// ~1.1:1 against it and vanishes completely in a theme that folds the
  /// two tiers onto one primitive. A tint of the foreground stays distinct
  /// from the fill whatever the surface ramp does.
  ///
  /// None of the three borders reaches 3:1 against its fill. The state is
  /// carried by the label and the glyph; the border is not what identifies
  /// it.
  static const CoreColor defaultPendingBorderColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
    opacity: CoreOpacity.opacity20,
  );

  /// Default `valid` background colour — the success container.
  static const CoreColor defaultValidBackgroundColor = CoreColor.token(
    CoreColors.successContainer,
  );

  /// Default `valid` label + icon colour.
  static const CoreColor defaultValidForegroundColor = CoreColor.token(
    CoreColors.onSuccessContainer,
  );

  /// Default `valid` border colour — 20% success tint.
  static const CoreColor defaultValidBorderColor = CoreColor.token(
    CoreColors.success,
    opacity: CoreOpacity.opacity20,
  );

  /// Default `invalid` background colour — the error container.
  static const CoreColor defaultInvalidBackgroundColor = CoreColor.token(
    CoreColors.errorContainer,
  );

  /// Default `invalid` label + icon colour.
  static const CoreColor defaultInvalidForegroundColor = CoreColor.token(
    CoreColors.onErrorContainer,
  );

  /// Default `invalid` border colour — 20% error tint.
  static const CoreColor defaultInvalidBorderColor = CoreColor.token(
    CoreColors.error,
    opacity: CoreOpacity.opacity20,
  );

  // ─── Per-state label typography defaults ────────────────────────
  //
  // Colour only, deliberately. A label's typography here is composed on
  // two axes: the **role** varies by size and lives in
  // [defaultsBySize] `[size].labelStyle` (`labelMedium` for xs/sm,
  // `bodySmall` for md), while the **colour** varies by state and is
  // what these three carry. Naming a role in one of these would freeze
  // the label typography across all three size presets, so each stays a
  // partial that both resolvers merge *onto* the size role
  // (`tokens.labelStyle.merge(default…LabelTextStyle)`) — the
  // partial-nested-Style shape `style-contract.md` prescribes.
  //
  // The colour itself is not a second copy: each references the same
  // `default…ForegroundColor` const the [defaultsByState] triplet reads,
  // so the label slot and the icon colour cannot drift apart.

  /// Default `pending` label typography — [defaultPendingForegroundColor]
  /// over the per-size role from [defaultsBySize].
  static const CoreTextStyle defaultPendingLabelTextStyle = CoreTextStyle(
    color: defaultPendingForegroundColor,
  );

  /// Default `valid` label typography — [defaultValidForegroundColor] over
  /// the per-size role from [defaultsBySize].
  static const CoreTextStyle defaultValidLabelTextStyle = CoreTextStyle(
    color: defaultValidForegroundColor,
  );

  /// Default `invalid` label typography — [defaultInvalidForegroundColor]
  /// over the per-size role from [defaultsBySize].
  static const CoreTextStyle defaultInvalidLabelTextStyle = CoreTextStyle(
    color: defaultInvalidForegroundColor,
  );

  /// Per-size token bundle — size-dependent dimensional chrome plus the
  /// size-aware label typography role.
  ///
  /// Single source of truth shared by Flutter and Web resolvers. The
  /// label role is `labelXs` · `labelSmall` · `labelMedium` (11 · 12 · 13).
  static const Map<CoreValidationBadgeSize, CoreValidationBadgeSizeStyle>
  defaultsBySize = {
    CoreValidationBadgeSize.extraSmall: CoreValidationBadgeSizeStyle(
      height: CoreSize.size20,
      verticalPadding: CoreSpace.space0,
      horizontalPadding: CoreSpace.space8,
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
      borderRadius: CoreRadius.radius4,
      iconSize: CoreSpace.space12,
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelXs),
    ),
    CoreValidationBadgeSize.small: CoreValidationBadgeSizeStyle(
      height: CoreSize.size24,
      verticalPadding: CoreSpace.space0,
      horizontalPadding: CoreSpace.space8,
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
      borderRadius: CoreRadius.radius6,
      iconSize: CoreSpace.space12,
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
    ),
    CoreValidationBadgeSize.medium: CoreValidationBadgeSizeStyle(
      height: CoreSize.size28,
      verticalPadding: CoreSpace.space0,
      horizontalPadding: CoreSpace.space10,
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      borderRadius: CoreRadius.radius6,
      iconSize: CoreSpace.space14,
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
    ),
  };

  /// Per-state design-system default colour triplet. Single source of
  /// truth shared by Flutter and Web resolvers — the per-instance colour
  /// override (carried by the `xxxBackgroundColor` / `xxxLabelTextStyle
  /// .color` / `xxxBorderColor` slots) wins, else these tokens take over.
  ///
  /// Each surface is a token-bound [CoreColor] so the value flows through
  /// one source: `pending` is neutral (surface-container fill, outline
  /// border, muted on-surface label), `valid` is success-tinted (10% fill / full label / 20%
  /// border), `invalid` is error-tinted with the same alpha steps. The
  /// alpha is carried by the token's `opacity` modifier so dark-mode
  /// resolution survives (Flutter `scheme.resolve` / Web `bg-{token}/{pct}`).
  static const Map<CoreValidationState, CoreValidationBadgeStateColors>
  defaultsByState = {
    CoreValidationState.pending: CoreValidationBadgeStateColors(
      backgroundColor: defaultPendingBackgroundColor,
      foregroundColor: defaultPendingForegroundColor,
      borderColor: defaultPendingBorderColor,
    ),
    CoreValidationState.valid: CoreValidationBadgeStateColors(
      backgroundColor: defaultValidBackgroundColor,
      foregroundColor: defaultValidForegroundColor,
      borderColor: defaultValidBorderColor,
    ),
    CoreValidationState.invalid: CoreValidationBadgeStateColors(
      backgroundColor: defaultInvalidBackgroundColor,
      foregroundColor: defaultInvalidForegroundColor,
      borderColor: defaultInvalidBorderColor,
    ),
  };

  /// Merges [other] into this style. `other` fields win when non-null.
  @override
  CoreValidationBadgeStyle merge(CoreValidationBadgeStyle? other) {
    if (other == null) return this;
    return CoreValidationBadgeStyle(
      pendingBackgroundColor:
          other.pendingBackgroundColor ?? pendingBackgroundColor,
      pendingLabelTextStyle: _mergeText(
        pendingLabelTextStyle,
        other.pendingLabelTextStyle,
      ),
      pendingBorderColor: other.pendingBorderColor ?? pendingBorderColor,
      validBackgroundColor: other.validBackgroundColor ?? validBackgroundColor,
      validLabelTextStyle: _mergeText(
        validLabelTextStyle,
        other.validLabelTextStyle,
      ),
      validBorderColor: other.validBorderColor ?? validBorderColor,
      invalidBackgroundColor:
          other.invalidBackgroundColor ?? invalidBackgroundColor,
      invalidLabelTextStyle: _mergeText(
        invalidLabelTextStyle,
        other.invalidLabelTextStyle,
      ),
      invalidBorderColor: other.invalidBorderColor ?? invalidBorderColor,
      iconLabelGapStyle: _mergeGap(iconLabelGapStyle, other.iconLabelGapStyle),
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      borderWidth: other.borderWidth ?? borderWidth,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreValidationBadgeStyle copyWith({
    CoreColor? pendingBackgroundColor,
    CoreTextStyle? pendingLabelTextStyle,
    CoreColor? pendingBorderColor,
    CoreColor? validBackgroundColor,
    CoreTextStyle? validLabelTextStyle,
    CoreColor? validBorderColor,
    CoreColor? invalidBackgroundColor,
    CoreTextStyle? invalidLabelTextStyle,
    CoreColor? invalidBorderColor,
    CoreGapStyle? iconLabelGapStyle,
    CoreIconStyle? iconStyle,
    double? borderWidth,
  }) {
    return CoreValidationBadgeStyle(
      pendingBackgroundColor:
          pendingBackgroundColor ?? this.pendingBackgroundColor,
      pendingLabelTextStyle:
          pendingLabelTextStyle ?? this.pendingLabelTextStyle,
      pendingBorderColor: pendingBorderColor ?? this.pendingBorderColor,
      validBackgroundColor: validBackgroundColor ?? this.validBackgroundColor,
      validLabelTextStyle: validLabelTextStyle ?? this.validLabelTextStyle,
      validBorderColor: validBorderColor ?? this.validBorderColor,
      invalidBackgroundColor:
          invalidBackgroundColor ?? this.invalidBackgroundColor,
      invalidLabelTextStyle:
          invalidLabelTextStyle ?? this.invalidLabelTextStyle,
      invalidBorderColor: invalidBorderColor ?? this.invalidBorderColor,
      iconLabelGapStyle: iconLabelGapStyle ?? this.iconLabelGapStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CoreValidationBadgeStyle &&
      other.pendingBackgroundColor == pendingBackgroundColor &&
      other.pendingLabelTextStyle == pendingLabelTextStyle &&
      other.pendingBorderColor == pendingBorderColor &&
      other.validBackgroundColor == validBackgroundColor &&
      other.validLabelTextStyle == validLabelTextStyle &&
      other.validBorderColor == validBorderColor &&
      other.invalidBackgroundColor == invalidBackgroundColor &&
      other.invalidLabelTextStyle == invalidLabelTextStyle &&
      other.invalidBorderColor == invalidBorderColor &&
      other.iconLabelGapStyle == iconLabelGapStyle &&
      other.iconStyle == iconStyle &&
      other.borderWidth == borderWidth;

  @override
  int get hashCode => Object.hash(
    pendingBackgroundColor,
    pendingLabelTextStyle,
    pendingBorderColor,
    validBackgroundColor,
    validLabelTextStyle,
    validBorderColor,
    invalidBackgroundColor,
    invalidLabelTextStyle,
    invalidBorderColor,
    iconLabelGapStyle,
    iconStyle,
    borderWidth,
  );

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreIconStyle? _mergeIcon(
    CoreIconStyle? base,
    CoreIconStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Per-size token bundle for `ValidationBadge`.
///
/// All values are platform-neutral logical pixels — Flutter consumes them
/// directly while Web emits them as `var(--coui-space-N)` / Tailwind
/// equivalents. The icon ↔ label gap is exposed as a nested
/// [CoreGapStyle] slot (`iconLabelGapStyle`) so the resolvers can forward
/// it straight to `Gap(gapStyle: …)` / inline `gap` rem. The label
/// typography role is carried as a token-bound [CoreTextStyle]
/// (`labelStyle`) so both resolvers route it through the single
/// typography path (`emitTypography` / `.toValue(theme:, color:)`)
/// instead of reading a `theme.typography.<role>` directly.
///
/// A class (not a record) — the reader that walks every `CoreXxxStyle`
/// default table needs a declared field list to census, and a `typedef
/// record` has none (see `core/style-contract.md`'s "typedef record
/// dispatch 금지" — this was the sole structural exception among the
/// component Style files).
///
/// Declared *after* [CoreValidationBadgeStyle] (not before) — the docs
/// table generator (`tool/generate_style_tables.dart`) picks the first
/// `class Core\w+Style` match in the file, and this bundle's name also
/// matches that pattern. Ordering the MAIN Style class first keeps that
/// generator (and every other tool assuming "first Style class = the
/// component's Style") pointed at the right class, mirroring every other
/// `defaultsByVariant`/`defaultsBySize` value class in the codebase (e.g.
/// `CoreCardVariantStyle`, declared after `CoreCardStyle`).
@immutable
class CoreValidationBadgeSizeStyle {
  /// Creates a per-size token bundle.
  const CoreValidationBadgeSizeStyle({
    required this.height,
    required this.verticalPadding,
    required this.horizontalPadding,
    required this.iconLabelGapStyle,
    required this.borderRadius,
    required this.iconSize,
    required this.labelStyle,
  });

  /// Fixed height of the badge (logical px) — the content is centred in it.
  final double height;

  /// Vertical padding (logical px).
  final double verticalPadding;

  /// Horizontal padding (logical px).
  final double horizontalPadding;

  /// Icon ↔ label gap, forwarded to `Gap(gapStyle: …)`.
  final CoreGapStyle iconLabelGapStyle;

  /// Corner radius (logical px).
  final double borderRadius;

  /// State icon size (logical px).
  final double iconSize;

  /// Label typography role.
  final CoreTextStyle labelStyle;
}

/// Per-state default colour triplet for `ValidationBadge`.
///
/// Each surface is a token-bound [CoreColor] (`CoreColor.token`) so both
/// resolvers share a single source of truth — Flutter resolves it through
/// the active scheme (`scheme.resolve(...).toValue()`) and Web emits a
/// Tailwind token class (`bg-{token}/{alpha}`) via the `emitColor` family
/// (layer-mapping.md "모든 디자인 값은 Core Style 단일 출처"). The alpha
/// is carried by the token's `opacity` modifier so it survives dark-mode
/// resolution.
///
/// A class (not a record) — see [CoreValidationBadgeSizeStyle]'s doc
/// comment for why.
@immutable
class CoreValidationBadgeStateColors {
  /// Creates a per-state colour triplet.
  const CoreValidationBadgeStateColors({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  /// Background colour.
  final CoreColor backgroundColor;

  /// Foreground (label/icon) colour.
  final CoreColor foregroundColor;

  /// Border colour.
  final CoreColor borderColor;
}
