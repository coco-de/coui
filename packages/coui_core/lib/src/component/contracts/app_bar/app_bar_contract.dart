/// Platform-independent contract for unified AppBar components.
///
/// Defines the interface that all `AppBar` implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/app_bar/app_bar_style.dart';
import 'package:coui_core/src/component/contracts/app_bar/app_bar_variant.dart';
import 'package:coui_core/src/component/contracts/bar_action/bar_action_axis_behavior.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';

/// Contract for a unified application bar component.
///
/// Every chrome / dimensional override flows through the single
/// [appBarStyle] field — see [CoreAppBarStyle] for the merge chain.
/// Semantic fields ([variant]), composition slots ([title] / [header] /
/// [subtitle] / [child] / [leading] / [trailing]) and behaviour flags
/// ([trailingExpanded] / [centerTitle] / [showDivider] / [elevated] /
/// [actionsAxis]) stay flat on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreAppBarContract<W> {
  // Behaviour defaults shared by both platforms — the constructors bind
  // their flags to these so Flutter ↔ Web stay in sync. Values match the
  // designer set's component-property defaults (divider=true,
  // elevated=false, align=start).

  /// Default for letting the trailing cluster take the remaining width.
  static const bool defaultTrailingExpanded = false;

  /// Default for centring the title — the designer set's `align` axis
  /// defaults to `start`.
  static const bool defaultCenterTitle = false;

  /// Default for the bottom hairline divider — on in the designer set.
  static const bool defaultShowDivider = true;

  /// Default for the elevated drop shadow — off in the designer set.
  static const bool defaultElevated = false;

  /// Default for where the bar's actions stand — in the bar's own row.
  static const CoreAxis defaultActionsAxis = CoreAxis.horizontal;

  /// Whether a bar whose actions stand along [actionsAxis] draws an action
  /// with [behavior] itself.
  ///
  /// A bar draws every action while they stand in its row. Once they stand
  /// in a column beside the content it keeps only the ones that may not
  /// leave the row — the rest are the column's.
  static bool keepsAction(
    CoreBarActionAxisBehavior behavior, {
    required CoreAxis actionsAxis,
  }) => actionsAxis == CoreAxis.horizontal || !behavior.allows(actionsAxis);

  /// Bar shape variant (standard / compact / medium / dense / prominent).
  CoreAppBarVariant get variant;

  /// Main title slot.
  W? get title;

  /// Header slot rendered above the title.
  W? get header;

  /// Subtitle slot rendered below the title.
  W? get subtitle;

  /// Free-form centre slot — replaces the header / title / subtitle
  /// column when supplied.
  W? get child;

  /// Widgets in the leading cluster (typically one navigation icon).
  List<W> get leading;

  /// Widgets in the trailing action cluster.
  List<W> get trailing;

  /// Whether the trailing cluster expands to take the remaining width.
  ///
  /// The expanded cluster leaves no free width to centre a title in, so a
  /// [centerTitle] bar with this flag keeps its title next to the leading
  /// cluster and centres only the title's own text.
  bool get trailingExpanded;

  /// Whether the title is centred instead of start-aligned.
  ///
  /// On a single-row bar the title sits on the centre of the **whole** bar —
  /// not on the space the clusters leave between them — in every material.
  /// Both sides are held at the wider cluster's width, so the title's room is
  /// `width − 2 × max(leading, trailing) − 2 × spacing`, symmetric about the
  /// centre; a longer title stays on the centre, takes one line and ends in
  /// an ellipsis instead of shifting, and the clusters are never pushed. The
  /// `medium` variant bottom-centres its large title instead.
  bool get centerTitle;

  /// Whether the bottom hairline divider is drawn.
  bool get showDivider;

  /// Whether the elevated drop shadow is drawn.
  bool get elevated;

  /// Where the bar's actions stand: in the bar's row (the default), or in
  /// a column beside the content.
  ///
  /// State `vertical` when the screen has a strip at its side for bar
  /// controls and the app draws the actions there. The bar then leaves out
  /// every [leading] and [trailing] action except the ones marked
  /// `BarAction(axisBehavior: horizontalOnly)` — a text button stays in the
  /// bar — and a `ToolbarGroup(direction: vertical)` handed the same two
  /// lists draws the rest, so the lists are written once.
  ///
  /// Enable Scaffold.adaptiveAppBarActions to let the scaffold detect a
  /// reserved right strip and host the column automatically. A custom shell
  /// can still choose the axis and host its own ToolbarGroup.
  CoreAxis get actionsAxis;

  /// Per-instance AppBar chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreAppBarStyle.defaultX / defaultsByVariant)
  ///   → CoreAppBarTheme.style
  ///   → CoreAppBarTheme.variantStyles[variant]
  ///   → widget.appBarStyle
  /// ```
  CoreAppBarStyle? get appBarStyle;
}
