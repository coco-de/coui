/// Platform-independent contract for navigation bar components.
///
/// Defines the interface that all navigation bar implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/navigation_bar/navigation_bar_style.dart';
import 'package:coui_core/src/component/contracts/navigation_bar/navigation_bar_variant.dart';

/// A single entry in a `NavigationBar`.
///
/// Replaces the legacy 5-class item hierarchy
/// (`NavigationItem` / `NavigationButton` / `NavigationLabel` /
/// `NavigationDivider` / `NavigationGap`) with one tagged data model so
/// the same list literal works on Flutter and Web.
///
/// Construct entries through the named factories:
///
/// - [CoreNavigationBarItem.destination] — a selectable navigation
///   destination (icon + optional label).
/// - [CoreNavigationBarItem.label] — a non-selectable section header.
/// - [CoreNavigationBarItem.divider] — a separating line.
/// - [CoreNavigationBarItem.gap] — empty spacing.
///
/// `W` is the platform widget type (`Widget` on Flutter, `Component`
/// on Web) used for the optional [icon] and [badge] slots.
class CoreNavigationBarItem<W> {
  /// Creates a selectable navigation destination.
  const CoreNavigationBarItem.destination({
    this.icon,
    this.label,
    this.badge,
    this.tooltip,
    this.enabled = true,
    this.showDot = false,
  }) : kind = CoreNavigationItemKind.item,
       gapStyle = null;

  /// Creates a non-selectable section header label.
  const CoreNavigationBarItem.label(String this.label)
    : kind = CoreNavigationItemKind.label,
      icon = null,
      badge = null,
      tooltip = null,
      enabled = true,
      showDot = false,
      gapStyle = null;

  /// Creates a separating divider line.
  const CoreNavigationBarItem.divider()
    : kind = CoreNavigationItemKind.divider,
      icon = null,
      badge = null,
      label = null,
      tooltip = null,
      enabled = true,
      showDot = false,
      gapStyle = null;

  /// Creates an empty spacing gap of [size] logical pixels.
  ///
  /// Convenience factory that folds [size] into a [CoreGapStyle] slot —
  /// the rendered gap flows through `Gap`, the unified 1-off spacer
  /// primitive, so scaling and design defaults are handled by `Gap`'s
  /// own resolver (not by this parent). For full control over the gap's
  /// chrome (colour / cross-axis extent), use [CoreNavigationBarItem.gapStyled].
  CoreNavigationBarItem.gap(double size)
    : kind = CoreNavigationItemKind.gap,
      icon = null,
      badge = null,
      label = null,
      tooltip = null,
      enabled = true,
      showDot = false,
      gapStyle = CoreGapStyle(size: size);

  /// Creates an empty spacing gap from a [CoreGapStyle] slot.
  ///
  /// Use this constructor to pass a full [CoreGapStyle] (size + colour
  /// + cross-axis extent) — the slot is forwarded raw to `Gap` so its
  /// own resolver folds in scaling and design defaults.
  const CoreNavigationBarItem.gapStyled(CoreGapStyle this.gapStyle)
    : kind = CoreNavigationItemKind.gap,
      icon = null,
      badge = null,
      label = null,
      tooltip = null,
      enabled = true,
      showDot = false;

  /// What kind of entry this is.
  final CoreNavigationItemKind kind;

  /// The leading icon of a destination item. `null` for label-only
  /// destinations and for non-item kinds.
  final W? icon;

  /// The text label. Used for [CoreNavigationItemKind.item] and
  /// [CoreNavigationItemKind.label] kinds; `null` for icon-only items.
  final String? label;

  /// Badge shown with a destination — typically a count, e.g.
  /// `Badge(form: .count, tone: .info, variant: .filled, size: .xs,
  /// child: Text('3'))`, the 18-tall count that fits a 36 sidebar row.
  ///
  /// Where it sits follows the layout mode: a sidebar row carries it at the
  /// row's trailing end, after the label; the bar and the rail lay it over
  /// the icon's top-end corner. Its text is part of the destination's
  /// accessible name, after the label (`Inbox, 3`), so a screen reader hears
  /// the count with the destination it belongs to. `null` renders no badge.
  /// Only set for [CoreNavigationItemKind.item].
  final W? badge;

  /// Tooltip text shown on hover when an item's label is hidden.
  final String? tooltip;

  /// Whether a destination shows a notification dot over its icon's top-end
  /// corner — something new is there, without a count. A [badge] wins over
  /// the dot. Only set for [CoreNavigationItemKind.item].
  final bool showDot;

  /// Whether a destination item can be selected. Always `true` for
  /// non-item kinds.
  final bool enabled;

  /// Nested [CoreGapStyle] slot — only set for
  /// [CoreNavigationItemKind.gap]. Forwarded raw to `Gap(gapStyle:)`
  /// by the platform widget so the gap component's own resolver folds
  /// in scaling and design defaults.
  final CoreGapStyle? gapStyle;

  /// Whether this entry participates in selection indexing.
  bool get isSelectable => kind == .item && enabled;
}

/// Contract for a navigation bar component.
///
/// The behaviour / semantic fields (`items` / `selectedIndex` /
/// `onSelected` / `mode` / `variant` / `labelMode` / `labelPosition` /
/// `alignment` / `overflow` / `selectionMark` / `compact`) stay flat on the
/// widget — they change the *behaviour* or *layout vocabulary* of the
/// control, not its visual chrome. All chrome / dimensional overrides flow through
/// [navigationBarStyle].
abstract interface class CoreNavigationBarContract<W> {
  /// The navigation entries to render, in order.
  List<CoreNavigationBarItem<W>> get items;

  /// The index of the currently selected destination item.
  ///
  /// Indexing counts only selectable destination items (kind ==
  /// [CoreNavigationItemKind.item]); labels / dividers / gaps are
  /// skipped. `null` → nothing selected.
  int? get selectedIndex;

  /// Called when the user activates a destination item.
  ///
  /// Receives the destination index (selectable items only).
  CoreValueChanged<int>? get onSelected;

  /// The layout mode — bar / rail / sidebar.
  CoreNavigationBarMode get mode;

  /// The visual variant of the navigation bar.
  CoreNavigationBarVariant get variant;

  /// When to show item labels. `null` → mode-appropriate default.
  CoreNavigationLabelMode? get labelMode;

  /// Where labels sit relative to icons. `null` → mode-appropriate
  /// default.
  CoreNavigationLabelPosition? get labelPosition;

  /// Distribution of items along the container's main axis.
  CoreNavigationAlignment get alignment;

  /// How item labels behave when they overflow.
  CoreNavigationOverflow get overflow;

  /// What marks the selected destination besides its label — `none` by
  /// default ([CoreNavigationSelectionMark.defaultSelectionMark]), or a dot
  /// above the content of a destination that stacks its label under or over
  /// its icon. The dot's chrome is [CoreNavigationBarStyle.selectionMarkStyle].
  CoreNavigationSelectionMark get selectionMark;

  /// How the selected destination is marked — a tile (`fill`) or colour
  /// alone (`color`). `null` → [mode]'s default
  /// ([CoreNavigationBarMode.defaultIndicator]): colour for the bar, a tile
  /// for the rail and the sidebar.
  CoreNavigationSelectionIndicator? get indicator;

  /// When the bar draws its compact form — never by default, while the
  /// content is scrolled toward its end ([CoreNavigationCompact.onScroll]),
  /// or always. The compact form itself is
  /// [CoreNavigationBarStyle.compactScale]: the floating glass bar drops its
  /// captions and shrinks toward its bottom edge, and a docked bar, which
  /// holds its room in the layout, stays as it is.
  CoreNavigationCompact get compact;

  /// Content placed inside the bar before the items, at the start of the
  /// main axis — the top of a rail or sidebar, the leading end of a
  /// horizontal bar. Typically the app's logo. It sits inside the bar's
  /// chrome and stays in place while the items scroll. `null` renders
  /// nothing.
  W? get header;

  /// Content placed inside the bar after the items, at the end of the
  /// main axis — the bottom of a rail or sidebar, the trailing end of a
  /// horizontal bar. Typically an account or plan card.
  ///
  /// It sits inside the bar's chrome (face, content-facing hairline and
  /// padding), so a caller does not redraw the bar around it. When the
  /// parent fixes the bar's length along that axis it lands on the far
  /// edge; when the items need more room than the bar has, they scroll and
  /// the footer stays in place. A bar left to size itself is as long as its
  /// items and footer together. `null` renders nothing.
  W? get footer;

  /// Per-instance navigation bar chrome / dimensional style.
  CoreNavigationBarStyle? get navigationBarStyle;
}
