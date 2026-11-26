/// Cross-platform contract for `NavigationBarItem`.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/navigation_bar/navigation_bar_contract.dart';
import 'package:coui_core/src/component/contracts/navigation_bar/navigation_bar_style.dart';
import 'package:coui_core/src/component/contracts/navigation_bar/navigation_bar_variant.dart';

/// One navigation destination drawn on its own — an icon, a name, an
/// optional count, and a face that says whether it is the current place.
///
/// The destination a `NavigationBar` composes for each
/// [CoreNavigationBarItem.destination], public so a screen can assemble a
/// sidebar outside the bar: a `Drawer`'s content, an app's own rail, a
/// settings column. The bar and a standalone item are the same widget, so a
/// row placed by hand reads exactly like a row the bar placed (and the Figma
/// `NavigationBarItem` set maps to one widget).
///
/// The chrome is the bar's: [navigationBarStyle] is a
/// `CoreNavigationBarStyle`, and the item reads its `item*` / per-state
/// label / icon / badge fields at [mode]'s density through the same merge
/// chain the bar walks (`CoreNavigationBarStyle.defaultX` → `defaultsByMode`
/// → `CoreNavigationBarTheme` → [navigationBarStyle]). A project that themes
/// its navigation bar has themed its standalone items too.
///
/// Anatomy, start to end at the sidebar density: `[ icon ] [ label … ]
/// [ badge ]`; stacked (`labelPosition` bottom / top) at the bar and rail
/// density, with the badge over the icon's top-end corner.
abstract interface class CoreNavigationBarItemContract<W> {
  /// The density a standalone item draws at when the caller states no
  /// [mode] — a sidebar row, the shape a hand-assembled sidebar is made of.
  static const CoreNavigationBarMode defaultMode =
      CoreNavigationBarMode.sidebar;

  /// The leading icon. `null` draws a label-only destination.
  W? get icon;

  /// The destination's name. Shown per [labelMode]; when hidden it is still
  /// the accessible name and the tooltip. `null` for an icon-only item —
  /// give it a [tooltip] so it keeps a name.
  String? get label;

  /// A count or marker shown with the destination — at the row's far end in
  /// the sidebar density, over the icon's top-end corner in the bar and rail
  /// densities (see [CoreNavigationBarMode.badgeAtRowEnd]). Its text joins
  /// the accessible name after the label (`Inbox, 3`). `null` draws none.
  W? get badge;

  /// Tooltip text shown on hover while the label is hidden. `null` falls
  /// back to the label.
  String? get tooltip;

  /// Whether this item is the current place.
  ///
  /// Draws the selected face and label, and states the selection to
  /// assistive technology (`aria-current="page"` on Web). A disabled item
  /// that is selected keeps its selection mark, dimmed — the
  /// `disabledSelected*` fields of `CoreNavigationBarStyle` — but does not
  /// state a selection to assistive technology, which an item that cannot be
  /// activated has nothing to offer.
  bool get selected;

  /// Whether the item can be activated. `null` → enabled exactly when
  /// [onPressed] is set (`enabled ?? onPressed != null`).
  bool? get enabled;

  /// Called when the item is activated — a click, a tap, or Enter / Space
  /// while it holds focus.
  CoreVoidCallback? get onPressed;

  /// The density the item draws at — a sidebar row by default
  /// ([defaultMode]); `bar` / `rail` draw the stacked destination of those
  /// layouts. Picks the mode-dependent defaults of [labelMode] and
  /// [labelPosition] too.
  CoreNavigationBarMode get mode;

  /// The bar variant whose chrome the item draws.
  CoreNavigationBarVariant get variant;

  /// When the label shows. `null` → [mode]'s default
  /// ([CoreNavigationBarMode.defaultLabelMode]) — always in the sidebar
  /// density.
  CoreNavigationLabelMode? get labelMode;

  /// Where the label sits relative to the icon. `null` → [mode]'s default
  /// ([CoreNavigationBarMode.defaultLabelPosition]).
  CoreNavigationLabelPosition? get labelPosition;

  /// How a label longer than the room left behaves.
  CoreNavigationOverflow get overflow;

  /// What marks the selected item besides its face and label — the dot
  /// above a stacked destination's content
  /// ([CoreNavigationSelectionMark.marksAt]).
  CoreNavigationSelectionMark get selectionMark;

  /// How the selected destination is marked — a tile (`fill`) or colour
  /// alone (`color`). `null` → [mode]'s default
  /// ([CoreNavigationBarMode.defaultIndicator]).
  CoreNavigationSelectionIndicator? get indicator;

  /// Whether a notification dot sits over the icon's top-end corner — a
  /// [badge] wins over it. Its chrome is
  /// [CoreNavigationBarStyle.notificationDotStyle].
  bool get showDot;

  /// Per-instance chrome — the bar's style, whose item fields this item
  /// draws.
  CoreNavigationBarStyle? get navigationBarStyle;
}
