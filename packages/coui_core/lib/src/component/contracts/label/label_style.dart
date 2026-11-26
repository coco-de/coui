/// Per-instance style for `Label`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/spacing.dart' show CoreSpace;
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Label` should render.
///
/// `CoreLabelStyle` carries chrome / dimensional flat fields plus
/// nested text style slots. Behavioural / semantic fields (`text`,
/// `icon`, `isRequired`, `disabled`, `semanticLabel`) stay flat on
/// the widget / contract.
///
/// ```text
/// design system default (CoreLabelStyle.defaultX static const)
///   → CoreLabelTheme.style                           // 프로젝트 공통
///   → parent component slot override
///   → widget.labelStyle                              // 인스턴스별
/// ```
@immutable
class CoreLabelStyle implements CoreStyle<CoreLabelStyle> {
  /// Creates a [CoreLabelStyle].
  const CoreLabelStyle({
    this.iconStyle,
    this.iconLabelGapStyle,
    this.labelRequiredGapStyle,
    this.disabledOpacity,
    this.requiredColor,
    this.textStyle,
    this.disabledTextStyle,
  });

  // ─── Design-system defaults (Phase 6f option D, Epic #1696 Phase 4) ─
  // Single source of truth shared by Flutter and Web — both platforms
  // resolve `CoreColor` via their own extension (`.toValue()` /
  // `scheme.resolve(...)`) and the typography token-backed reference
  // via the matching adapter (`tailwindTypographyRole` /
  // `resolveTypographyRole`).

  /// Default leading icon style — `size` only (16 logical px).
  /// Per-instance override flows through [iconStyle] (merged on top of
  /// this default).
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default gap style between leading icon and text — nested
  /// [CoreGapStyle] slot forwarded to the `Gap` widget that sits
  /// between the leading icon and the label text. Per-instance
  /// override flows through [iconLabelGapStyle] (merged on top of this
  /// default).
  static const CoreGapStyle defaultIconLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
  );

  /// Default gap style between text and required indicator (`*`) —
  /// nested [CoreGapStyle] slot forwarded to the `Gap` widget that
  /// sits between the label text and the required indicator. Per-
  /// instance override flows through [labelRequiredGapStyle] (merged
  /// on top of this default).
  static const CoreGapStyle defaultLabelRequiredGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default opacity applied when `disabled` is `true`.
  /// The disabled label already carries [CoreColors.disabledContent]; a
  /// multiplier on top would make its contrast depend on the surface it
  /// happens to sit on.
  static const double defaultDisabledOpacity = CoreOpacity.opacity100;

  /// Default required indicator (`*`) colour token — the enabled state
  /// only. While `disabled` the `*` takes the colour of the disabled text
  /// style instead, so a disabled label never keeps a live-looking red mark.
  static const CoreColor defaultRequiredColor = CoreColor.token(
    CoreColors.error,
  );

  /// Default text style applied to the label text — token-backed
  /// reference to the `labelLarge` slot with `onSurface` colour and a
  /// `medium` font-weight overlay (form labels read slightly heavier
  /// than the surrounding body text). The enabled text colour lives
  /// inside this slot's [CoreTextStyle.color] (1:1 with the [textStyle]
  /// field).
  ///
  /// `static final` because the [CoreTextStyle.token] const factory
  /// does not accept `fontWeight`; the `copyWith` overlay must run at
  /// field-initialiser time.
  static final CoreTextStyle defaultTextStyle = const CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurface),
  ).copyWith(fontWeight: CoreFontWeight.medium);

  /// Default text style applied to the label text when `disabled` is
  /// `true`. Same typography role as [defaultTextStyle] but carrying
  /// the dedicated `disabledContent` colour so the disabled state lives
  /// in the nested `CoreTextStyle` slot (1:1 with the
  /// [disabledTextStyle] field — sb8 — raw `disabledTextColor` field
  /// removed).
  ///
  /// That one colour paints the whole disabled label — the text, the
  /// required indicator (`*`) and the leading icon — so overriding
  /// [disabledTextStyle] recolours all three together.
  static final CoreTextStyle defaultDisabledTextStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelLarge,
        color: CoreColor.token(CoreColors.disabledContent),
      ).copyWith(fontWeight: CoreFontWeight.medium);

  // ── Chrome (flat) ────────────────────────────

  /// Leading icon style override. `size` defers to [defaultIconStyle].
  final CoreIconStyle? iconStyle;

  /// Gap between the leading icon and the label text, passed to
  /// `Gap(gapStyle: …)` as is.
  ///
  /// `Gap` runs its own resolve / scaling step so this slot is
  /// passed raw (pre-scaling) by the parent resolver.
  final CoreGapStyle? iconLabelGapStyle;

  /// Gap between the label text and the required indicator (`*`), passed
  /// to `Gap(gapStyle: …)` as is.
  ///
  /// `Gap` runs its own resolve / scaling step so this slot is passed raw
  /// (pre-scaling) by the parent resolver.
  final CoreGapStyle? labelRequiredGapStyle;

  /// Opacity applied when `disabled` is `true`.
  final double? disabledOpacity;

  /// Required indicator (`*`) colour override for the enabled state.
  /// While `disabled` the `*` follows the colour of [disabledTextStyle].
  final CoreColor? requiredColor;

  // ── Slot Styles (nested) ─────────────────────

  /// Text style override for the label text (enabled state).
  /// Text colour is carried via [CoreTextStyle.color] inside this slot
  /// (sb8 — raw `textColor` field removed).
  final CoreTextStyle? textStyle;

  /// Text style override for the label text when `disabled` is `true`.
  /// Mirrors [textStyle] but applies only in the disabled state, laid over
  /// [defaultDisabledTextStyle]. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot.
  ///
  /// sb8 — raw `disabledTextColor` field removed.
  final CoreTextStyle? disabledTextStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreLabelStyle merge(CoreLabelStyle? other) {
    if (other == null) return this;
    return CoreLabelStyle(
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      iconLabelGapStyle: _mergeGap(iconLabelGapStyle, other.iconLabelGapStyle),
      labelRequiredGapStyle: _mergeGap(
        labelRequiredGapStyle,
        other.labelRequiredGapStyle,
      ),
      disabledOpacity: other.disabledOpacity ?? disabledOpacity,
      requiredColor: other.requiredColor ?? requiredColor,
      textStyle: _mergeText(textStyle, other.textStyle),
      disabledTextStyle: _mergeText(disabledTextStyle, other.disabledTextStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreLabelStyle copyWith({
    CoreIconStyle? iconStyle,
    CoreGapStyle? iconLabelGapStyle,
    CoreGapStyle? labelRequiredGapStyle,
    double? disabledOpacity,
    CoreColor? requiredColor,
    CoreTextStyle? textStyle,
    CoreTextStyle? disabledTextStyle,
  }) {
    return CoreLabelStyle(
      iconStyle: iconStyle ?? this.iconStyle,
      iconLabelGapStyle: iconLabelGapStyle ?? this.iconLabelGapStyle,
      labelRequiredGapStyle:
          labelRequiredGapStyle ?? this.labelRequiredGapStyle,
      disabledOpacity: disabledOpacity ?? this.disabledOpacity,
      requiredColor: requiredColor ?? this.requiredColor,
      textStyle: textStyle ?? this.textStyle,
      disabledTextStyle: disabledTextStyle ?? this.disabledTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreLabelStyle &&
          runtimeType == other.runtimeType &&
          iconStyle == other.iconStyle &&
          iconLabelGapStyle == other.iconLabelGapStyle &&
          labelRequiredGapStyle == other.labelRequiredGapStyle &&
          disabledOpacity == other.disabledOpacity &&
          requiredColor == other.requiredColor &&
          textStyle == other.textStyle &&
          disabledTextStyle == other.disabledTextStyle;

  @override
  int get hashCode => Object.hash(
    iconStyle,
    iconLabelGapStyle,
    labelRequiredGapStyle,
    disabledOpacity,
    requiredColor,
    textStyle,
    disabledTextStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
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
