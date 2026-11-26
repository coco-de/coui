/// Per-instance style for `Pagination`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Pagination` should render.
///
/// Carries the chrome / dimensional fields for the page-number,
/// previous and next buttons plus the ellipsis text style.
/// Platform-neutral (Epic #1415 option D).
///
/// All design-system defaults live here as `static const` fields so the
/// Flutter and Web resolvers share a single source of truth.
@immutable
class CorePaginationStyle implements CoreStyle<CorePaginationStyle> {
  /// Creates a [CorePaginationStyle].
  const CorePaginationStyle({
    this.itemSpacing,
    this.buttonSize,
    this.buttonRadius,
    this.labelButtonPadding,
    this.buttonTextStyle,
    this.activeButtonTextStyle,
    this.activeBackgroundColor,
    this.activeTextStyle,
    this.hoverBackgroundColor,
    this.hoverTextStyle,
    this.textStyle,
    this.disabledColor,
    this.disabledBackgroundColor,
    this.iconStyle,
    this.hoverDuration,
    this.ellipsisStyle,
    this.clickableStyle,
  });

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// Default spacing between adjacent pagination buttons applied as
  /// the host-layout `Row.spacing` (Flutter) / CSS flex `gap` (Web).
  /// Logical px — design-system default.
  static const double defaultItemSpacing = CoreSpace.space4;

  /// Default width / height of a square pagination button (logical px).
  static const double defaultButtonSize = CoreSpace.space36;

  /// Default inner padding of the previous / next buttons when they show
  /// their label (`showLabel: true`). Horizontal only: the label button
  /// keeps [defaultButtonSize] as its height and takes its width from its
  /// content — icon, gap, label and this padding — instead of the square
  /// page-button box, which a word does not fit in.
  static const CoreEdgeInsets defaultLabelButtonPadding =
      CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12);

  /// Default corner radius of a pagination button.
  static const CoreBorderRadius defaultButtonRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Default base text style shared by every page-number / prev / next
  /// button — the `bodyMedium` role (14 / Regular / 150%). Per-state text
  /// colour is layered downstream via [activeTextStyle] / [hoverTextStyle] /
  /// [textStyle], so this slot carries no colour.
  static const CoreTextStyle defaultButtonTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
  );

  /// Default typography of the active (current) page button — the
  /// `labelLarge` role (14 / 140%) at `semiBold`, so the one selected number
  /// is the only heavier glyph in the row. Carries no colour
  /// ([defaultActiveTextStyle] does) and replaces [defaultButtonTextStyle]
  /// for the active button alone.
  static final CoreTextStyle defaultActiveButtonTextStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelLarge,
      ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default background colour of the active (current) page button.
  static const CoreColor defaultActiveBackgroundColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default background colour applied to a button on hover — the
  /// `surfaceContainerHigh` tone, a neutral step off the page.
  ///
  /// Not an accent: the current page is already the `primary` fill, and
  /// CoUI's accent is that same colour, so an accent hover would be
  /// indistinguishable from the current page.
  static const CoreColor defaultHoverBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default text colour of the active (current) page button — `onPrimary`,
  /// the text tone of the [defaultActiveBackgroundColor] fill. Colour only:
  /// the active button's typography is [defaultActiveButtonTextStyle].
  static const CoreTextStyle defaultActiveTextStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.onPrimary),
  );

  /// Default text colour applied to a button on hover — `onSurface`, the
  /// text tone of the [defaultHoverBackgroundColor] fill, one step above the
  /// resting [defaultTextStyle]. Colour only.
  static const CoreTextStyle defaultHoverTextStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default text colour of an inactive / prev / next button —
  /// `onSurfaceVariant`, the secondary tone that keeps the selected page the
  /// only high-contrast number. The chevrons take the same colour. Colour
  /// only.
  static const CoreTextStyle defaultTextStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default ellipsis (`…`) text style — colour only (`onSurfaceSubtle`, the
  /// decorative step: the `…` stands for pages, it is not one). Typography is
  /// inherited from [defaultButtonTextStyle], so the condensed range still
  /// reads as the same control.
  static const CoreTextStyle defaultEllipsisStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default colour of every number, the `…` and the chevrons while the
  /// pagination is disabled (`enabled: false`) — the active number included,
  /// which sits on [defaultDisabledBackgroundColor].
  static const CoreColor defaultDisabledColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default fill of the active (current) page button while the pagination is
  /// disabled — the muted container the disabled content colour is set for.
  static const CoreColor defaultDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default nested [CoreIconStyle] slot for the previous / next chevron —
  /// the size alone (16); the colour is the button's foreground.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default colour-transition duration for button hover.
  static const Duration defaultHoverDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default nested [CoreClickableStyle] slot for the composed
  /// per-button `Clickable` — the button's corner (`radius8`, the same value
  /// as [defaultButtonRadius]) and nothing else: the focus ring is drawn
  /// around the button at that corner plus the ring's own reach (12), and
  /// every other press / focus / cursor chrome is the Clickable's own. The
  /// radius is stated here because the Clickable's own default (4) would draw
  /// the ring tighter than the button it wraps. Named so the resolver's
  /// `defaultClickableStyle.merge(merged.clickableStyle)` forward has a
  /// single-source default.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
  );

  // ─── Fields ───────────────────────────────────────────────────────

  /// Spacing between adjacent pagination buttons (logical px),
  /// applied as the host-layout `Row.spacing` (Flutter) / CSS flex
  /// `gap` (Web) of the outer pagination row.
  final double? itemSpacing;

  /// Width / height of a square pagination button (logical px).
  final double? buttonSize;

  /// Corner radius of a pagination button.
  final CoreBorderRadius? buttonRadius;

  /// Inner padding of the previous / next buttons in label mode
  /// (`showLabel: true`), whose width follows their content. Defaults to
  /// [defaultLabelButtonPadding].
  final CoreEdgeInsets? labelButtonPadding;

  /// Base text style override shared by every page-number / prev / next
  /// button (typography role + weight; carries no per-state colour).
  /// Layered on top of [defaultButtonTextStyle].
  final CoreTextStyle? buttonTextStyle;

  /// Typography override of the active (current) page button, layered on top
  /// of [buttonTextStyle] and [defaultActiveButtonTextStyle]. Carries no
  /// colour — that is [activeTextStyle].
  final CoreTextStyle? activeButtonTextStyle;

  /// Background colour of the active (current) page button.
  final CoreColor? activeBackgroundColor;

  /// Text colour override for the active (current) page button, carried via
  /// [CoreTextStyle.color] inside this slot. Defaults to
  /// [defaultActiveTextStyle]. The active button's typography is
  /// [activeButtonTextStyle], not this slot.
  final CoreTextStyle? activeTextStyle;

  /// Background colour applied to a button on hover.
  final CoreColor? hoverBackgroundColor;

  /// Text colour override applied to a button on hover, carried via
  /// [CoreTextStyle.color] inside this slot. Defaults to
  /// [defaultHoverTextStyle].
  final CoreTextStyle? hoverTextStyle;

  /// Text colour override for an inactive / prev / next button, carried via
  /// [CoreTextStyle.color] inside this slot. The chevrons take it too.
  /// Defaults to [defaultTextStyle].
  final CoreTextStyle? textStyle;

  /// Override colour of every number, the `…` and the chevrons while the
  /// pagination is disabled. `null` defers to [defaultDisabledColor].
  final CoreColor? disabledColor;

  /// Override fill of the active (current) page button while the pagination
  /// is disabled. `null` defers to [defaultDisabledBackgroundColor].
  final CoreColor? disabledBackgroundColor;

  /// Style of the previous / next chevron (its size; the colour is the
  /// button's foreground unless this slot states one). `null` defers to
  /// [defaultIconStyle].
  final CoreIconStyle? iconStyle;

  /// Colour-transition duration for button hover. `null` → token
  /// default ([defaultHoverDuration]).
  final Duration? hoverDuration;

  /// Ellipsis (`…`) text style override, layered on top of
  /// [defaultEllipsisStyle] — colour only by default, so the `…` takes the
  /// shared button typography ([buttonTextStyle]) and differs from a page
  /// number by its colour alone. A typography overlay stated here is applied
  /// to the `…` alone.
  final CoreTextStyle? ellipsisStyle;

  /// Style for each page button's `Clickable` — press scale, durations,
  /// focus ring, disabled opacity. Laid over [defaultClickableStyle] and
  /// passed to the `Clickable` as is, which fills in the rest.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CorePaginationStyle merge(CorePaginationStyle? other) {
    if (other == null) return this;
    return CorePaginationStyle(
      itemSpacing: other.itemSpacing ?? itemSpacing,
      buttonSize: other.buttonSize ?? buttonSize,
      buttonRadius: other.buttonRadius ?? buttonRadius,
      labelButtonPadding: other.labelButtonPadding ?? labelButtonPadding,
      buttonTextStyle: _mergeText(buttonTextStyle, other.buttonTextStyle),
      activeButtonTextStyle: _mergeText(
        activeButtonTextStyle,
        other.activeButtonTextStyle,
      ),
      activeBackgroundColor:
          other.activeBackgroundColor ?? activeBackgroundColor,
      activeTextStyle: _mergeText(activeTextStyle, other.activeTextStyle),
      hoverBackgroundColor: other.hoverBackgroundColor ?? hoverBackgroundColor,
      hoverTextStyle: _mergeText(hoverTextStyle, other.hoverTextStyle),
      textStyle: _mergeText(textStyle, other.textStyle),
      disabledColor: other.disabledColor ?? disabledColor,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      iconStyle: iconStyle?.merge(other.iconStyle) ?? other.iconStyle,
      hoverDuration: other.hoverDuration ?? hoverDuration,
      ellipsisStyle: _mergeText(ellipsisStyle, other.ellipsisStyle),
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CorePaginationStyle copyWith({
    double? itemSpacing,
    double? buttonSize,
    CoreBorderRadius? buttonRadius,
    CoreEdgeInsets? labelButtonPadding,
    CoreTextStyle? buttonTextStyle,
    CoreTextStyle? activeButtonTextStyle,
    CoreColor? activeBackgroundColor,
    CoreTextStyle? activeTextStyle,
    CoreColor? hoverBackgroundColor,
    CoreTextStyle? hoverTextStyle,
    CoreTextStyle? textStyle,
    CoreColor? disabledColor,
    CoreColor? disabledBackgroundColor,
    CoreIconStyle? iconStyle,
    Duration? hoverDuration,
    CoreTextStyle? ellipsisStyle,
    CoreClickableStyle? clickableStyle,
  }) {
    return CorePaginationStyle(
      itemSpacing: itemSpacing ?? this.itemSpacing,
      buttonSize: buttonSize ?? this.buttonSize,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      labelButtonPadding: labelButtonPadding ?? this.labelButtonPadding,
      buttonTextStyle: buttonTextStyle ?? this.buttonTextStyle,
      activeButtonTextStyle:
          activeButtonTextStyle ?? this.activeButtonTextStyle,
      activeBackgroundColor:
          activeBackgroundColor ?? this.activeBackgroundColor,
      activeTextStyle: activeTextStyle ?? this.activeTextStyle,
      hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
      hoverTextStyle: hoverTextStyle ?? this.hoverTextStyle,
      textStyle: textStyle ?? this.textStyle,
      disabledColor: disabledColor ?? this.disabledColor,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      iconStyle: iconStyle ?? this.iconStyle,
      hoverDuration: hoverDuration ?? this.hoverDuration,
      ellipsisStyle: ellipsisStyle ?? this.ellipsisStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePaginationStyle &&
          runtimeType == other.runtimeType &&
          itemSpacing == other.itemSpacing &&
          buttonSize == other.buttonSize &&
          buttonRadius == other.buttonRadius &&
          labelButtonPadding == other.labelButtonPadding &&
          buttonTextStyle == other.buttonTextStyle &&
          activeButtonTextStyle == other.activeButtonTextStyle &&
          activeBackgroundColor == other.activeBackgroundColor &&
          activeTextStyle == other.activeTextStyle &&
          hoverBackgroundColor == other.hoverBackgroundColor &&
          hoverTextStyle == other.hoverTextStyle &&
          textStyle == other.textStyle &&
          disabledColor == other.disabledColor &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          iconStyle == other.iconStyle &&
          hoverDuration == other.hoverDuration &&
          ellipsisStyle == other.ellipsisStyle &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(
    itemSpacing,
    buttonSize,
    buttonRadius,
    labelButtonPadding,
    buttonTextStyle,
    activeButtonTextStyle,
    activeBackgroundColor,
    activeTextStyle,
    hoverBackgroundColor,
    hoverTextStyle,
    textStyle,
    disabledColor,
    disabledBackgroundColor,
    iconStyle,
    hoverDuration,
    ellipsisStyle,
    clickableStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
