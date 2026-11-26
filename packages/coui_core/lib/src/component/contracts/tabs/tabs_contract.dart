/// Platform-independent contract for tab components.
///
/// Defines the interface that all tab implementations
/// (Flutter, Jaspr) must satisfy.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/tabs/tab_pane_style.dart';
import 'package:coui_core/src/component/contracts/tabs/tab_pane_variant.dart';
import 'package:coui_core/src/component/contracts/tabs/tabs_size.dart';
import 'package:coui_core/src/component/contracts/tabs/tabs_style.dart';
import 'package:coui_core/src/component/contracts/tabs/tabs_variant.dart';

/// A single tab item within a tab bar.
///
/// Represents one selectable tab with a label, optional disabled
/// state, an optional trailing [badge], and an optional [content]
/// panel widget. The [content] slot is consumed by `TabPane` (the
/// boxed tab + integrated panel component) when its variant is
/// [CoreTabPaneVariant.boxed]; plain `Tabs` ignores it, and so does
/// `TabPane` in [CoreTabPaneVariant.editorStrip]. The [badge] slot is
/// consumed by both.
class CoreTabItem<W> {
  /// Creates a [CoreTabItem] with the given [label], optional
  /// [enabled] flag, optional trailing [badge], and optional
  /// [content] panel widget.
  const CoreTabItem({
    required this.label,
    this.enabled = true,
    this.badge,
    this.content,
    this.leading,
    this.trailing,
    this.onClose,
  });

  /// The text label displayed on the tab.
  final String label;

  /// Whether this tab is enabled and can be selected.
  final bool enabled;

  /// Trailing badge rendered after the label — typically a count,
  /// `Badge(variant: .filled, form: .count, size: .xs, child: Text('3'))`.
  /// Consumed by both `Tabs` and `TabPane`.
  ///
  /// A composition slot: the caller supplies a fully styled widget and
  /// the container states only the spacing between the label and it
  /// (`CoreTabsStyle.labelBadgeGapStyle` /
  /// `CoreTabPaneStyle.labelBadgeGapStyle`). `null` renders no badge
  /// and no gap.
  final W? badge;

  /// The content panel associated with this tab.
  ///
  /// Consumed by `TabPane` in [CoreTabPaneVariant.boxed]; ignored by
  /// `Tabs` and by `TabPane` in [CoreTabPaneVariant.editorStrip]
  /// (strip-only — the editor body is the caller's).
  final W? content;

  /// Leading widget rendered before the label — an editor strip's
  /// file-type icon, say.
  ///
  /// Consumed by `TabPane`; `Tabs` ignores this field, the same split
  /// [content] already documents. `cross-platform/api.md` forbids a
  /// capability existing on one PLATFORM, not on one component — and
  /// both platforms' `TabPane` render it identically.
  ///
  /// A composition slot: the caller supplies a fully styled widget and
  /// the container states only the spacing
  /// (`CoreTabPaneStyle.labelBadgeGapStyle`, the tab's one in-tab step).
  /// `null` renders no widget and no gap.
  final W? leading;

  /// Trailing widget rendered after the label and after [badge] — an
  /// editor strip's custom close affordance, say.
  ///
  /// Consumed by `TabPane`; `Tabs` ignores this field. Spacing comes from
  /// `CoreTabPaneStyle.labelBadgeGapStyle` — the same in-tab step every
  /// slot in the tab uses; `null` renders no widget and no gap.
  ///
  /// Hit-test separation: `TabPane` places [trailing] **outside** the
  /// tab-select `Clickable`, so activating a control inside [trailing]
  /// does **not** fire the pane's `onChanged`. Prefer [onClose] when the
  /// affordance is a standard close × — that path synthesises the control
  /// and documents the same separation.
  final W? trailing;

  /// Called when the tab's synthesised close affordance is activated.
  ///
  /// Consumed by both `TabPane` and `Tabs`. When non-null, the tab renders
  /// a close × after its label and badge, **outside** the tab-select
  /// `Clickable`, so the close hit target does **not** fire `onChanged`.
  /// The box and glyph are the component's `closeButtonStyle` /
  /// `closeIconStyle` (`CoreTabPaneStyle`, `CoreTabsStyle`), and the
  /// accessible name is the active locale's close label, read at render
  /// time. In `TabPane`, custom close chrome can still use [trailing] —
  /// that slot is guarded the same way.
  final CoreVoidCallback? onClose;
}

/// Contract for a tab-bar component (`Tabs`).
///
/// Every chrome / dimensional override flows through the single
/// [tabsStyle] field — see [CoreTabsStyle] for the merge chain.
abstract interface class CoreTabsContract<W> {
  /// The list of tab items to display.
  List<CoreTabItem<W>> get tabs;

  /// The index of the currently selected tab.
  int get selectedIndex;

  /// The visual variant of the tab bar.
  CoreTabVariant get variant;

  /// The bar's size rung — selects the per-size
  /// [CoreTabsStyle.defaultsBySize] entry for [CoreTabsStyle.itemHeight]
  /// and [CoreTabsStyle.contentTextStyle]. Widget-only semantic
  /// identifier, not theme-overridable (mirrors
  /// `CoreProgressContract.size`).
  CoreTabsSize get size;

  /// Whether the tabs expand to fill the available horizontal space.
  bool get expand;

  /// Whether labels retain their intrinsic width in a horizontally scrollable
  /// viewport. Defaults to false. When true, takes precedence over [expand]
  /// and uses horizontal drags for scrolling rather than swipe selection.
  /// Supply a bounded parent width to constrain the viewport.
  bool get scrollable;

  /// Whether horizontal swipe gestures can switch tabs.
  bool get swipeable;

  /// Called when the selected tab changes.
  ///
  /// Receives the index of the newly selected tab.
  CoreValueChanged<int>? get onChanged;

  /// Per-instance tabs chrome / dimensional / slot style.
  CoreTabsStyle? get tabsStyle;
}

/// Contract for a boxed tab + integrated content panel component
/// (`TabPane`).
///
/// In [CoreTabPaneVariant.boxed] (default) renders a card-like content
/// area fused to a horizontally scrollable tab bar. In
/// [CoreTabPaneVariant.editorStrip] renders the strip alone — IDE
/// editor chrome — and does **not** render [CoreTabItem.content].
/// Tabs may be drag-reordered when [reorderable] is `true`.
abstract interface class CoreTabPaneContract<W> {
  /// The list of tab items to display. Each item's [CoreTabItem.content]
  /// is rendered in the content panel when that tab is focused — only
  /// in [CoreTabPaneVariant.boxed].
  List<CoreTabItem<W>> get tabs;

  /// The index of the currently focused tab.
  int get selectedIndex;

  /// Visual / layout variant — boxed settings card vs IDE editor strip.
  ///
  /// Widget-only semantic identifier, not theme-overridable (mirrors
  /// `CoreTabsContract.variant`).
  CoreTabPaneVariant get variant;

  /// Whether tabs can be reordered by drag-and-drop.
  bool get reorderable;

  /// Called when the focused tab changes.
  CoreValueChanged<int>? get onChanged;

  /// Called when tabs are reordered, with the new tab order.
  void Function(List<CoreTabItem<W>>)? get onReorder;

  /// Widgets displayed before the scrollable tab area.
  List<W> get leading;

  /// Widgets displayed after the scrollable tab area.
  List<W> get trailing;

  /// Per-instance tab-pane chrome / dimensional style.
  CoreTabPaneStyle? get tabPaneStyle;
}
