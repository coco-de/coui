/// Per-instance style for `Sidebar`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/sidebar/sidebar_type.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/layout.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Sidebar` frames its regions.
///
/// The sidebar draws the frame only — the face, the edge that meets the
/// page, the widths and the insets of its regions. Every row inside it is a
/// caller-composed `SidebarItem` / `SidebarSection` / `SidebarGroup`, each
/// with its own style, so this style carries no row chrome.
///
/// ```text
/// defaultX → defaultsByType[type]
///   → CoreSidebarTheme.style
///   → CoreSidebarTheme.variantStyles[type]
///   → widget.sidebarStyle
/// ```
@immutable
class CoreSidebarStyle implements CoreStyle<CoreSidebarStyle> {
  /// Creates a [CoreSidebarStyle].
  const CoreSidebarStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.panelWidth,
    this.railWidth,
    this.railBackgroundColor,
    this.railPadding,
    this.railSpacing,
    this.railHeaderGapStyle,
    this.topPadding,
    this.topSpacing,
    this.bodyPadding,
    this.bodySpacing,
    this.bottomPadding,
    this.bottomSpacing,
    this.panelTitleStyle,
    this.panelTitlePadding,
    this.panelTitleSpacing,
    this.panelActionIconStyle,
  });

  // ─── Design-system defaults ──

  /// The face — `surfaceContainerLow`, the chrome tier every app-frame
  /// surface that stays put sits on (the same face `NavigationBar` draws in
  /// the rail and sidebar modes).
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerLow,
  );

  /// The line on the edge that meets the page.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Width of the edge line.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Width of the icon rail drawn by `twoPane` and `collapsed`.
  static const double defaultRailWidth = CoreSize.size64;

  /// The rail's insets — 16 above and below, 12 at the sides, so a 40 rail
  /// item sits centred in the 64 rail.
  static const CoreEdgeInsets defaultRailPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space12,
    vertical: CoreSpace.space16,
  );

  /// Spacing between the rail's items.
  static const double defaultRailSpacing = CoreSpace.space8;

  /// Extra room between the rail's header (a logo) and its first item.
  static const CoreGapStyle defaultRailHeaderGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Spacing between the top region's parts (header, search).
  static const double defaultTopSpacing = CoreSpace.space12;

  /// Spacing between the body's rows.
  static const double defaultBodySpacing = CoreSpace.space2;

  /// The bottom region's insets.
  static const CoreEdgeInsets defaultBottomPadding = CoreEdgeInsets.only(
    left: CoreSpace.space16,
    top: CoreSpace.space12,
    right: CoreSpace.space16,
    bottom: CoreSpace.space16,
  );

  /// Spacing between the bottom region's parts (footer, help, user).
  static const double defaultBottomSpacing = CoreSpace.space8;

  /// The two-pane panel's title — `titleSmall` in `onSurface`.
  static const CoreTextStyle defaultPanelTitleStyle = CoreTextStyle.token(
    CoreTextStyles.titleSmall,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Insets around the panel title row — the title starts 8 in from the
  /// rows below it, a statement about the reading direction.
  static const CoreEdgeInsets defaultPanelTitlePadding =
      CoreEdgeInsets.directional(
        start: CoreSpace.space8,
        top: CoreSpace.space4,
        bottom: CoreSpace.space4,
      );

  /// Spacing between the panel title and its action.
  static const double defaultPanelTitleSpacing = CoreSpace.space8;

  /// The panel title's action glyph — 18 in `onSurfaceVariant`.
  static const CoreIconStyle defaultPanelActionIconStyle = CoreIconStyle(
    size: CoreIconSize.size18,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// What each type changes — the panel's width, the insets of the top and
  /// the body, and the rail's face.
  ///
  /// - `standard` — a 248 panel, 16 at the sides.
  /// - `twoPane` — the rail beside a 240 panel; the panel's sides tighten to
  ///   12 and the rail takes the deeper `surfaceContainer`, so the two read
  ///   as two columns.
  /// - `collapsed` — the rail alone, on the sidebar's own face. No panel.
  static const Map<CoreSidebarType, CoreSidebarStyle> defaultsByType = {
    CoreSidebarType.standard: CoreSidebarStyle(
      panelWidth: CoreLayout.layout248,
      topPadding: CoreEdgeInsets.only(
        left: CoreSpace.space16,
        top: CoreSpace.space16,
        right: CoreSpace.space16,
        bottom: CoreSpace.space12,
      ),
      bodyPadding: CoreEdgeInsets.only(
        left: CoreSpace.space16,
        top: CoreSpace.space4,
        right: CoreSpace.space16,
        bottom: CoreSpace.space12,
      ),
      railBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
    CoreSidebarType.twoPane: CoreSidebarStyle(
      panelWidth: CoreLayout.layout240,
      topPadding: CoreEdgeInsets.only(
        left: CoreSpace.space12,
        top: CoreSpace.space16,
        right: CoreSpace.space12,
        bottom: CoreSpace.space8,
      ),
      bodyPadding: CoreEdgeInsets.only(
        left: CoreSpace.space12,
        top: CoreSpace.space4,
        right: CoreSpace.space12,
        bottom: CoreSpace.space16,
      ),
      railBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
    CoreSidebarType.collapsed: CoreSidebarStyle(
      panelWidth: CoreLayout.layout248,
      topPadding: CoreEdgeInsets.only(
        left: CoreSpace.space16,
        top: CoreSpace.space16,
        right: CoreSpace.space16,
        bottom: CoreSpace.space12,
      ),
      bodyPadding: CoreEdgeInsets.only(
        left: CoreSpace.space16,
        top: CoreSpace.space4,
        right: CoreSpace.space16,
        bottom: CoreSpace.space12,
      ),
      railBackgroundColor: CoreColor.token(CoreColors.surfaceContainerLow),
    ),
  };

  /// The panel's face. `null` defers to [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// The line on the edge that meets the page. `null` defers to
  /// [defaultBorderColor].
  final CoreColor? borderColor;

  /// Width of the edge line (logical px). `null` defers to
  /// [defaultBorderWidth].
  final double? borderWidth;

  /// Width of the panel (logical px). `null` defers to the type's row in
  /// [defaultsByType].
  final double? panelWidth;

  /// Width of the icon rail (logical px). `null` defers to
  /// [defaultRailWidth].
  final double? railWidth;

  /// The rail's face. `null` defers to the type's row in
  /// [defaultsByType].
  final CoreColor? railBackgroundColor;

  /// The rail's insets. `null` defers to [defaultRailPadding].
  final CoreEdgeInsets? railPadding;

  /// Spacing between the rail's items. `null` defers to
  /// [defaultRailSpacing].
  final double? railSpacing;

  /// Extra room after the rail's header. `null` defers to
  /// [defaultRailHeaderGapStyle].
  final CoreGapStyle? railHeaderGapStyle;

  /// The top region's insets (header, search, panel title). `null` defers
  /// to the type's row in [defaultsByType].
  final CoreEdgeInsets? topPadding;

  /// Spacing between the top region's parts. `null` defers to
  /// [defaultTopSpacing].
  final double? topSpacing;

  /// The body's insets. `null` defers to the type's row in
  /// [defaultsByType].
  final CoreEdgeInsets? bodyPadding;

  /// Spacing between the body's rows. `null` defers to
  /// [defaultBodySpacing].
  final double? bodySpacing;

  /// The bottom region's insets. `null` defers to [defaultBottomPadding].
  final CoreEdgeInsets? bottomPadding;

  /// Spacing between the bottom region's parts. `null` defers to
  /// [defaultBottomSpacing].
  final double? bottomSpacing;

  /// The two-pane panel title's text. `null` defers to
  /// [defaultPanelTitleStyle].
  final CoreTextStyle? panelTitleStyle;

  /// Insets around the panel title row. `null` defers to
  /// [defaultPanelTitlePadding].
  final CoreEdgeInsets? panelTitlePadding;

  /// Spacing between the panel title and its action. `null` defers to
  /// [defaultPanelTitleSpacing].
  final double? panelTitleSpacing;

  /// The panel title's action glyph. `null` defers to
  /// [defaultPanelActionIconStyle].
  final CoreIconStyle? panelActionIconStyle;

  /// Returns a copy with non-null fields from [other] overriding the
  /// matching fields here. Nested slot styles merge recursively.
  @override
  CoreSidebarStyle merge(CoreSidebarStyle? other) {
    if (other == null) return this;
    return CoreSidebarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      panelWidth: other.panelWidth ?? panelWidth,
      railWidth: other.railWidth ?? railWidth,
      railBackgroundColor: other.railBackgroundColor ?? railBackgroundColor,
      railPadding: other.railPadding ?? railPadding,
      railSpacing: other.railSpacing ?? railSpacing,
      railHeaderGapStyle:
          railHeaderGapStyle?.merge(other.railHeaderGapStyle) ??
          other.railHeaderGapStyle,
      topPadding: other.topPadding ?? topPadding,
      topSpacing: other.topSpacing ?? topSpacing,
      bodyPadding: other.bodyPadding ?? bodyPadding,
      bodySpacing: other.bodySpacing ?? bodySpacing,
      bottomPadding: other.bottomPadding ?? bottomPadding,
      bottomSpacing: other.bottomSpacing ?? bottomSpacing,
      panelTitleStyle:
          panelTitleStyle?.merge(other.panelTitleStyle) ??
          other.panelTitleStyle,
      panelTitlePadding: other.panelTitlePadding ?? panelTitlePadding,
      panelTitleSpacing: other.panelTitleSpacing ?? panelTitleSpacing,
      panelActionIconStyle:
          panelActionIconStyle?.merge(other.panelActionIconStyle) ??
          other.panelActionIconStyle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreSidebarStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    double? panelWidth,
    double? railWidth,
    CoreColor? railBackgroundColor,
    CoreEdgeInsets? railPadding,
    double? railSpacing,
    CoreGapStyle? railHeaderGapStyle,
    CoreEdgeInsets? topPadding,
    double? topSpacing,
    CoreEdgeInsets? bodyPadding,
    double? bodySpacing,
    CoreEdgeInsets? bottomPadding,
    double? bottomSpacing,
    CoreTextStyle? panelTitleStyle,
    CoreEdgeInsets? panelTitlePadding,
    double? panelTitleSpacing,
    CoreIconStyle? panelActionIconStyle,
  }) {
    return CoreSidebarStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      panelWidth: panelWidth ?? this.panelWidth,
      railWidth: railWidth ?? this.railWidth,
      railBackgroundColor: railBackgroundColor ?? this.railBackgroundColor,
      railPadding: railPadding ?? this.railPadding,
      railSpacing: railSpacing ?? this.railSpacing,
      railHeaderGapStyle: railHeaderGapStyle ?? this.railHeaderGapStyle,
      topPadding: topPadding ?? this.topPadding,
      topSpacing: topSpacing ?? this.topSpacing,
      bodyPadding: bodyPadding ?? this.bodyPadding,
      bodySpacing: bodySpacing ?? this.bodySpacing,
      bottomPadding: bottomPadding ?? this.bottomPadding,
      bottomSpacing: bottomSpacing ?? this.bottomSpacing,
      panelTitleStyle: panelTitleStyle ?? this.panelTitleStyle,
      panelTitlePadding: panelTitlePadding ?? this.panelTitlePadding,
      panelTitleSpacing: panelTitleSpacing ?? this.panelTitleSpacing,
      panelActionIconStyle: panelActionIconStyle ?? this.panelActionIconStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          panelWidth == other.panelWidth &&
          railWidth == other.railWidth &&
          railBackgroundColor == other.railBackgroundColor &&
          railPadding == other.railPadding &&
          railSpacing == other.railSpacing &&
          railHeaderGapStyle == other.railHeaderGapStyle &&
          topPadding == other.topPadding &&
          topSpacing == other.topSpacing &&
          bodyPadding == other.bodyPadding &&
          bodySpacing == other.bodySpacing &&
          bottomPadding == other.bottomPadding &&
          bottomSpacing == other.bottomSpacing &&
          panelTitleStyle == other.panelTitleStyle &&
          panelTitlePadding == other.panelTitlePadding &&
          panelTitleSpacing == other.panelTitleSpacing &&
          panelActionIconStyle == other.panelActionIconStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    panelWidth,
    railWidth,
    railBackgroundColor,
    railPadding,
    railSpacing,
    railHeaderGapStyle,
    topPadding,
    topSpacing,
    bodyPadding,
    bodySpacing,
    bottomPadding,
    bottomSpacing,
    panelTitleStyle,
    panelTitlePadding,
    panelTitleSpacing,
    panelActionIconStyle,
  );
}
