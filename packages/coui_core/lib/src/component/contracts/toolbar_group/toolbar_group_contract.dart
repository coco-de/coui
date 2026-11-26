/// Shared contract for a group of related toolbar controls.
library;

import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/button/button_theme.dart';
import 'package:coui_core/src/component/contracts/button/button_variant.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';

/// One shared functional surface for related toolbar controls.
/// Place separate groups in a row with a gap to separate unrelated actions.
abstract interface class CoreToolbarGroupContract<W> {
  /// A group lays its controls out in a row unless told otherwise — the
  /// shape a bar's action cluster takes.
  static const CoreAxis defaultDirection = CoreAxis.horizontal;

  /// Capsule geometry; material is inherited or overridden by [popupStyle].
  static const defaultPopupStyle = CorePopupStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    padding: CoreEdgeInsets.all(CoreSpace.space4),
    minWidth: 0,
    maxWidth: double.infinity,
    spacing: 0,
  );

  /// Native glass controls fill a 44-point seat without a second padded rim.
  static const double glassActionMinSize = CoreSize.size44;

  /// The seat of a glass control in a column: 48, so the capsule is 48
  /// across.
  ///
  /// A column of controls stands at the side of the screen — the strip a
  /// device reserves there for its bar controls — beside the glass
  /// navigation rail, whose capsule is 48 across
  /// (`CoreNavigationBarStyle.glassRailStyle`). Two capsules in one strip
  /// read as one set only at one width, so the column takes the rail's
  /// rather than the row's 44.
  static const double glassVerticalActionMinSize = CoreSize.size48;

  /// The seat a glass control takes along and across a group laid out in
  /// [direction] — one question for both platforms and for the button
  /// defaults below, so the seat and the button filling it cannot disagree.
  static double glassActionMinSizeFor(CoreAxis direction) =>
      switch (direction) {
        CoreAxis.horizontal => glassActionMinSize,
        CoreAxis.vertical => glassVerticalActionMinSize,
      };

  /// The glyph of a glass control in a column: 24.
  ///
  /// The column stands in the same strip as the glass navigation rail and
  /// at the same width, and the rail draws its destinations from 24 glyphs
  /// (`CoreNavigationBarStyle.defaultIconStyle`). A button's own glyph is
  /// sized for a label beside it and is smaller, so two capsules side by
  /// side would carry two weights of icon; the column's buttons take the
  /// rail's instead.
  static const double glassVerticalIconSize = CoreIconSize.size24;

  /// The glyph a glass control draws in a group laid out in [direction],
  /// or `null` where the button keeps its own — the row, whose buttons sit
  /// in a bar among labelled ones.
  static CoreIconStyle? glassIconStyleFor(CoreAxis direction) =>
      switch (direction) {
        CoreAxis.horizontal => null,
        CoreAxis.vertical => const CoreIconStyle(size: glassVerticalIconSize),
      };

  /// One optical capsule shared by a related action cluster.
  static const CorePopupStyle glassPopupStyle = CorePopupStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    padding: CoreEdgeInsets.zero,
    borderWidth: 0,
    minWidth: 0,
    maxWidth: double.infinity,
    spacing: 0,
    boxShadow: CoreShadow.sm,
  );

  /// Group items keep their own actions and focus, while the capsule owns
  /// the material. Authored button styles still win over these defaults.
  ///
  /// A button fills the seat of the group's [direction]
  /// ([glassActionMinSizeFor]) and draws the glyph of that direction
  /// ([glassIconStyleFor]) wherever it carries one — before its label,
  /// after it, or alone.
  static CoreButtonTheme glassButtonTheme(
    CoreButtonTheme? inherited, {
    CoreAxis direction = defaultDirection,
  }) => CoreButtonTheme(
    style: CoreButtonStyle(
      height: glassActionMinSizeFor(direction),
      minWidth: glassActionMinSizeFor(direction),
      pressedScale: 1,
      leadingIconStyle: glassIconStyleFor(direction),
      trailingIconStyle: glassIconStyleFor(direction),
      iconShapeIconStyle: glassIconStyleFor(direction),
    ).merge(inherited?.style),
    variantStyles: {
      ...?inherited?.variantStyles,
      CoreButtonVariant.plain: const CoreButtonStyle(
        borderWidth: 0,
      ).merge(inherited?.variantStyles?[CoreButtonVariant.plain]),
    },
  );

  /// Related controls. Omit hidden items entirely; an empty group draws
  /// nothing.
  ///
  /// A group draws the controls that may be laid out along its
  /// [direction]: a column leaves out a `BarAction` marked
  /// `horizontalOnly`. A column is also one capsule, so a `ToolbarGroup`
  /// among a column's children gives the column its controls instead of
  /// drawing a capsule of its own — a bar's `leading` and `trailing` lists
  /// can be handed to the column as they are.
  List<W> get children;

  /// Localized description of the group. Each icon control also needs a label.
  String get ariaLabel;

  /// The axis the controls run along: a row (the default) or a column.
  ///
  /// A column is for controls that stand beside the content rather than in
  /// a bar — a side strip, a canvas's tool palette. Placed inside a bar's
  /// row it is taller than the bar.
  CoreAxis get direction;

  /// Shared panel chrome, including a component-local material override.
  CorePopupStyle? get popupStyle;
}
