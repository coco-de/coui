/// Per-instance style for `BottomSheet`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/bottom_action_bar/bottom_action_bar_style.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/divider/divider_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `BottomSheet` renders.
///
/// Carries the surface fill and its two rounded top corners, the grab handle,
/// the header's inset and spacing, the look of the title and the description,
/// the content's inset, and the chrome of the composed close button and
/// divider, the sheet's height ceiling, and the action area — the hairline
/// the sheet draws above the footer and the chrome it hands a
/// `BottomActionBar` placed there. Platform-neutral — the Flutter and Web
/// resolvers read the same static defaults.
///
/// The sheet draws no border and no shadow of its own: the surface's
/// material (blur, rim) is the active surface style's, applied to the filled
/// panel.
///
/// ```text
/// CoreBottomSheetStyle.default*
///   → CoreBottomSheetTheme.style                     // project-wide
///   → widget.bottomSheetStyle                        // per-instance
/// ```
@immutable
class CoreBottomSheetStyle implements CoreStyle<CoreBottomSheetStyle> {
  /// Creates a [CoreBottomSheetStyle].
  const CoreBottomSheetStyle({
    this.backgroundColor,
    this.borderRadius,
    this.handleWidth,
    this.handleHeight,
    this.handleColor,
    this.handleBorderRadius,
    this.handlePadding,
    this.headerPadding,
    this.headerSpacing,
    this.titleGapStyle,
    this.titleTextStyle,
    this.descriptionTextStyle,
    this.contentPadding,
    this.closeButtonStyle,
    this.dividerStyle,
    this.maxHeightFactor,
    this.footerDividerColor,
    this.footerDividerWidth,
    this.footerBarStyle,
  });

  /// Surface fill colour. `null` → [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// Corners of the panel. `null` → [defaultBorderRadius].
  final CoreBorderRadius? borderRadius;

  /// Width of the handle bar (logical px, pre-scaling). `null` →
  /// [defaultHandleWidth].
  final double? handleWidth;

  /// Height of the handle bar (logical px, pre-scaling). `null` →
  /// [defaultHandleHeight].
  final double? handleHeight;

  /// Colour of the handle bar. `null` → [defaultHandleColor].
  final CoreColor? handleColor;

  /// Corners of the handle bar. `null` → [defaultHandleBorderRadius].
  final CoreBorderRadius? handleBorderRadius;

  /// Inset around the handle bar — its top edge is the space above it.
  /// `null` → [defaultHandlePadding].
  final CoreEdgeInsets? handlePadding;

  /// Inset around the title row and the description. `null` →
  /// [defaultHeaderPadding].
  final CoreEdgeInsets? headerPadding;

  /// Space between the title and the close button (logical px,
  /// pre-scaling). `null` → [defaultHeaderSpacing].
  final double? headerSpacing;

  /// Gap between the title row and the description. `null` →
  /// [defaultTitleGapStyle].
  final CoreGapStyle? titleGapStyle;

  /// Text style the title slot's content inherits, laid over
  /// [defaultTitleTextStyle].
  final CoreTextStyle? titleTextStyle;

  /// Text style the description slot's content inherits, laid over
  /// [defaultDescriptionTextStyle].
  final CoreTextStyle? descriptionTextStyle;

  /// Inset around the content. `null` → [defaultContentPadding].
  final CoreEdgeInsets? contentPadding;

  /// Style for the close button, a
  /// `Button(variant: .plain, size: .sm, shape: .square)`. Laid over
  /// [defaultCloseButtonStyle] and passed to the `Button` as is.
  final CoreButtonStyle? closeButtonStyle;

  /// Style for the `Divider` between the header and the content, passed to
  /// it as is. `null` leaves the divider to its own defaults.
  ///
  /// This field deliberately has no `default*`: the sheet's divider does not
  /// diverge from `Divider`'s own look, so a default here would only copy the
  /// child's defaults (composition forwards a partial style only for the
  /// values that differ).
  final CoreDividerStyle? dividerStyle;

  /// Tallest the sheet grows, as a fraction of the viewport's height. Past
  /// it the content scrolls between the header and the footer. `null` →
  /// [defaultMaxHeightFactor].
  final double? maxHeightFactor;

  /// Colour of the hairline the sheet draws above the footer while more
  /// content lies below. `null` → [defaultFooterDividerColor].
  final CoreColor? footerDividerColor;

  /// Thickness of that hairline (logical px, pre-scaling). `null` →
  /// [defaultFooterDividerWidth].
  final double? footerDividerWidth;

  /// Style for a `BottomActionBar` placed in the footer — set as that bar's
  /// theme style around the footer, so the bar's own per-instance style
  /// still wins. Laid over [defaultFooterBarStyle].
  final CoreBottomActionBarStyle? footerBarStyle;

  // ─── Design-system defaults (single source, Flutter ↔ Web) ──────

  /// The panel's fill — `surfaceBright`, the lifted surface a sheet floats
  /// on.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceBright,
  );

  /// The two top corners — 24; the bottom edge meets the screen edge and
  /// stays square.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.only(
    topLeft: CoreRadius.radius24,
    topRight: CoreRadius.radius24,
  );

  /// The handle bar's width — 36.
  static const double defaultHandleWidth = 36;

  /// The handle bar's height — 4.
  static const double defaultHandleHeight = 4;

  /// The handle bar's colour — `outline`.
  static const CoreColor defaultHandleColor = CoreColor.token(
    CoreColors.outline,
  );

  /// The handle bar is a pill.
  static const CoreBorderRadius defaultHandleBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// `space8` above the bar, so the handle's area is 8 + 4 = 12 tall.
  static const CoreEdgeInsets defaultHandlePadding = CoreEdgeInsets.only(
    top: CoreSpace.space8,
  );

  /// `space20` above and at the sides, `space8` below.
  static const CoreEdgeInsets defaultHeaderPadding = CoreEdgeInsets.only(
    left: CoreSpace.space20,
    top: CoreSpace.space20,
    right: CoreSpace.space20,
    bottom: CoreSpace.space8,
  );

  /// Between the title and the close button — `space12`.
  static const double defaultHeaderSpacing = CoreSpace.space12;

  /// Between the title row and the description — `space8`.
  static const CoreGapStyle defaultTitleGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// The title — `titleLarge` in `onSurface`.
  static const CoreTextStyle defaultTitleTextStyle = CoreTextStyle.token(
    CoreTextStyles.titleLarge,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// The description — `bodyLarge` in `onSurfaceVariant`.
  static const CoreTextStyle defaultDescriptionTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyLarge,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// `space8` above and below the content, `space20` at the sides.
  static const CoreEdgeInsets defaultContentPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space20,
    vertical: CoreSpace.space8,
  );

  /// The close button — the `sm` control row's 32 square with no padding
  /// (the square centres the glyph), the `sm` corner and the quiet
  /// `onSurfaceVariant` foreground.
  static const CoreButtonStyle defaultCloseButtonStyle = CoreButtonStyle(
    foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    height: CoreControlSize.heightSm,
    width: CoreControlSize.heightSm,
    padding: CoreEdgeInsets.zero,
  );

  /// The sheet stops at 90 % of the viewport's height, leaving a strip of
  /// the page above it in view.
  static const double defaultMaxHeightFactor = 0.9;

  /// The footer hairline is the action bar's own hairline colour — the sheet
  /// takes the line over from the bar, so the line looks the same as a
  /// standalone bar's.
  static const CoreColor defaultFooterDividerColor =
      CoreBottomActionBarStyle.defaultDividerColor;

  /// The footer hairline's thickness — the action bar's own.
  static const double defaultFooterDividerWidth =
      CoreBottomActionBarStyle.defaultDividerWidth;

  /// A bar in the sheet's footer paints no fill — the sheet's surface shows
  /// through — and no hairline of its own: the sheet draws the line, and
  /// only while the content continues below. Only the two values that
  /// diverge from the bar's defaults are stated; the bar's resolver fills
  /// the rest.
  static const CoreBottomActionBarStyle defaultFooterBarStyle =
      CoreBottomActionBarStyle(
        backgroundColor: CoreColor.transparent,
        dividerWidth: CoreStrokeWidth.stroke0,
      );

  /// Merges [other] on top of this style — every field [other] states wins;
  /// the text styles and the nested slots merge field by field.
  @override
  CoreBottomSheetStyle merge(CoreBottomSheetStyle? other) {
    if (other == null) return this;
    return CoreBottomSheetStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      handleWidth: other.handleWidth ?? handleWidth,
      handleHeight: other.handleHeight ?? handleHeight,
      handleColor: other.handleColor ?? handleColor,
      handleBorderRadius: other.handleBorderRadius ?? handleBorderRadius,
      handlePadding: other.handlePadding ?? handlePadding,
      headerPadding: other.headerPadding ?? headerPadding,
      headerSpacing: other.headerSpacing ?? headerSpacing,
      titleGapStyle:
          titleGapStyle?.merge(other.titleGapStyle) ?? other.titleGapStyle,
      titleTextStyle: titleTextStyle == null
          ? other.titleTextStyle
          : titleTextStyle!.merge(other.titleTextStyle),
      descriptionTextStyle: descriptionTextStyle == null
          ? other.descriptionTextStyle
          : descriptionTextStyle!.merge(other.descriptionTextStyle),
      contentPadding: other.contentPadding ?? contentPadding,
      closeButtonStyle:
          closeButtonStyle?.merge(other.closeButtonStyle) ??
          other.closeButtonStyle,
      dividerStyle:
          dividerStyle?.merge(other.dividerStyle) ?? other.dividerStyle,
      maxHeightFactor: other.maxHeightFactor ?? maxHeightFactor,
      footerDividerColor: other.footerDividerColor ?? footerDividerColor,
      footerDividerWidth: other.footerDividerWidth ?? footerDividerWidth,
      footerBarStyle:
          footerBarStyle?.merge(other.footerBarStyle) ?? other.footerBarStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreBottomSheetStyle copyWith({
    CoreColor? backgroundColor,
    CoreBorderRadius? borderRadius,
    double? handleWidth,
    double? handleHeight,
    CoreColor? handleColor,
    CoreBorderRadius? handleBorderRadius,
    CoreEdgeInsets? handlePadding,
    CoreEdgeInsets? headerPadding,
    double? headerSpacing,
    CoreGapStyle? titleGapStyle,
    CoreTextStyle? titleTextStyle,
    CoreTextStyle? descriptionTextStyle,
    CoreEdgeInsets? contentPadding,
    CoreButtonStyle? closeButtonStyle,
    CoreDividerStyle? dividerStyle,
    double? maxHeightFactor,
    CoreColor? footerDividerColor,
    double? footerDividerWidth,
    CoreBottomActionBarStyle? footerBarStyle,
  }) {
    return CoreBottomSheetStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      handleWidth: handleWidth ?? this.handleWidth,
      handleHeight: handleHeight ?? this.handleHeight,
      handleColor: handleColor ?? this.handleColor,
      handleBorderRadius: handleBorderRadius ?? this.handleBorderRadius,
      handlePadding: handlePadding ?? this.handlePadding,
      headerPadding: headerPadding ?? this.headerPadding,
      headerSpacing: headerSpacing ?? this.headerSpacing,
      titleGapStyle: titleGapStyle ?? this.titleGapStyle,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
      contentPadding: contentPadding ?? this.contentPadding,
      closeButtonStyle: closeButtonStyle ?? this.closeButtonStyle,
      dividerStyle: dividerStyle ?? this.dividerStyle,
      maxHeightFactor: maxHeightFactor ?? this.maxHeightFactor,
      footerDividerColor: footerDividerColor ?? this.footerDividerColor,
      footerDividerWidth: footerDividerWidth ?? this.footerDividerWidth,
      footerBarStyle: footerBarStyle ?? this.footerBarStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBottomSheetStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderRadius == other.borderRadius &&
          handleWidth == other.handleWidth &&
          handleHeight == other.handleHeight &&
          handleColor == other.handleColor &&
          handleBorderRadius == other.handleBorderRadius &&
          handlePadding == other.handlePadding &&
          headerPadding == other.headerPadding &&
          headerSpacing == other.headerSpacing &&
          titleGapStyle == other.titleGapStyle &&
          titleTextStyle == other.titleTextStyle &&
          descriptionTextStyle == other.descriptionTextStyle &&
          contentPadding == other.contentPadding &&
          closeButtonStyle == other.closeButtonStyle &&
          dividerStyle == other.dividerStyle &&
          maxHeightFactor == other.maxHeightFactor &&
          footerDividerColor == other.footerDividerColor &&
          footerDividerWidth == other.footerDividerWidth &&
          footerBarStyle == other.footerBarStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderRadius,
    handleWidth,
    handleHeight,
    handleColor,
    handleBorderRadius,
    handlePadding,
    headerPadding,
    headerSpacing,
    titleGapStyle,
    titleTextStyle,
    descriptionTextStyle,
    contentPadding,
    closeButtonStyle,
    dividerStyle,
    maxHeightFactor,
    footerDividerColor,
    footerDividerWidth,
    footerBarStyle,
  );
}
