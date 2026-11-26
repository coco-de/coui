/// Variant enum for navigation bar components.
library;

import 'package:coui_core/src/component/contracts/tooltip/core_tooltip_position.dart';

/// Visual variant of a `NavigationBar`.
///
/// Navigation bar currently exposes a single visual treatment, but the
/// enum is kept so the widget default and any future variants flow
/// through a single source of truth (Phase 6f convention).
enum CoreNavigationBarVariant {
  /// The standard navigation container treatment.
  standard;

  /// Widget default variant — referenced by both the Flutter and Web
  /// `NavigationBar` constructors so the two platforms never diverge.
  static const CoreNavigationBarVariant defaultVariant = standard;
}

/// Layout mode of a `NavigationBar`.
///
/// Replaces the three legacy widgets (`NavigationBar` / `NavigationRail`
/// / `NavigationSidebar`) with one semantic enum so a single component
/// covers every navigation layout.
enum CoreNavigationBarMode {
  /// Horizontal bar — typically positioned at the top or bottom of a
  /// screen. Items are laid out left-to-right.
  bar,

  /// Vertical compact rail — typically positioned at the side of a
  /// screen. Items are laid out top-to-bottom and stay narrow.
  rail,

  /// Expanded vertical sidebar — full-width items with prominent
  /// labels, suited to desktop / tablet navigation.
  @Deprecated(
    'Use Sidebar (since 0.164) — the side navigation now has its own '
    'component with a header, search, sections, groups and a rail; this '
    'mode keeps drawing the old sidebar row until it is removed.',
  )
  sidebar;

  /// Widget default mode.
  static const CoreNavigationBarMode defaultMode = bar;

  /// Whether this mode lays its items out vertically.
  bool get isVertical => this != bar;

  /// Whether this is the announced [sidebar] mode — the kit's own way to ask
  /// while that mode is deprecated, so the bar keeps drawing it unchanged
  /// until it is removed without each call site naming the deprecated value.
  bool get isSidebar => this == sidebar;

  /// How a destination drawn at this mode's density marks the selected one,
  /// when the caller states no `indicator`.
  ///
  /// The bar marks with colour and weight alone: its destinations are wide
  /// on a phone, and a face across one reads as a heavy slab — a wash under
  /// the pointer would read as a face appearing, so it darkens the
  /// foreground instead. The rail and the sidebar stack their destinations,
  /// paint the selected one's whole tile and lay the wash.
  CoreNavigationSelectionIndicator get defaultIndicator => this == bar
      ? CoreNavigationSelectionIndicator.color
      : CoreNavigationSelectionIndicator.fill;

  /// [defaultIndicator], for a container that may be drawn as the floating
  /// glass capsule ([floatingGlass] — the container takes
  /// `CoreNavigationBarStyle.glassStyleFor` this mode).
  ///
  /// A floating glass container moves one lens over its destinations, and
  /// that lens is the selected face. So it marks with colour alone in every
  /// mode, and the glass presets give up the tile face the opaque
  /// container paints: a face and a lens on one destination would state the
  /// selection twice, and only the lens could follow a drag.
  CoreNavigationSelectionIndicator defaultIndicatorFor({
    required bool floatingGlass,
  }) => floatingGlass
      ? CoreNavigationSelectionIndicator.defaultGlassIndicator
      : defaultIndicator;

  /// When a destination drawn at this mode's density shows its label, when
  /// the caller states no `labelMode` and the container is not the floating
  /// glass capsule. Read [defaultLabelModeFor] to answer for both.
  CoreNavigationLabelMode get defaultLabelMode => switch (this) {
    bar => CoreNavigationLabelMode.defaultBarMode,
    rail => CoreNavigationLabelMode.defaultRailMode,
    sidebar => CoreNavigationLabelMode.defaultSidebarMode,
  };

  /// [defaultLabelMode], for a container that may be drawn as the floating
  /// glass capsule ([floatingGlass] — the container takes
  /// `CoreNavigationBarStyle.glassStyleFor` this mode).
  ///
  /// The glass rail is a narrow column of bare glyphs, so it hides its
  /// captions ([CoreNavigationLabelMode.defaultGlassRailMode]); the glass
  /// bar keeps the bar's own answer. The bar and a standalone
  /// `NavigationBarItem` both read this, so a destination composed by the
  /// bar and one placed on its own answer the same way.
  CoreNavigationLabelMode defaultLabelModeFor({required bool floatingGlass}) =>
      floatingGlass && this == rail
      ? CoreNavigationLabelMode.defaultGlassRailMode
      : defaultLabelMode;

  /// Where a destination drawn at this mode's density places its label,
  /// when the caller states no `labelPosition` — beside the icon in a
  /// sidebar row, under it in the bar and the rail.
  CoreNavigationLabelPosition get defaultLabelPosition => this == sidebar
      ? CoreNavigationLabelPosition.defaultSidebarPosition
      : CoreNavigationLabelPosition.defaultBarPosition;

  /// The side of a destination its tooltip opens on.
  ///
  /// A row of destinations names one from above. In a column a bubble
  /// above a destination covers the one before it — where the pointer is
  /// as likely to go next — so a column's opens beside the destination
  /// instead, over the content.
  ///
  /// The column's side is stated as `right`. The overlay engine moves a
  /// bubble that does not fit to the opposite side, so a column standing at
  /// the right edge of the screen opens its tooltips to the left, and the
  /// bubble faces the content on either side of the screen.
  CoreTooltipPosition get tooltipPosition =>
      isVertical ? CoreTooltipPosition.right : CoreTooltipPosition.top;

  /// Whether a destination at this mode carries its badge at the row's
  /// trailing end, after the icon and label, rather than over the icon's
  /// top-end corner.
  ///
  /// A sidebar row carries it at the far end; the bar and the rail hang it
  /// on the icon. A destination with no icon ([hasIcon] `false`) has no
  /// corner to hang it on, so it follows the label like a sidebar row does.
  bool badgeAtRowEnd({required bool hasIcon}) => this == sidebar || !hasIcon;
}

/// Controls when navigation item labels are shown.
enum CoreNavigationLabelMode {
  /// Every item always shows its label.
  all,

  /// Only the selected item shows its label.
  selected,

  /// No item shows a label (icon-only).
  none;

  /// Widget default label mode for the [CoreNavigationBarMode.bar]
  /// layout — every destination is named under its icon, the bottom bar's
  /// 64-tall destination. A bar that states [none] paints its icon-only
  /// destinations shorter (`CoreNavigationBarStyle.iconOnlyItemMinHeight`).
  static const CoreNavigationLabelMode defaultBarMode = all;

  /// Widget default label mode for the [CoreNavigationBarMode.rail]
  /// layout — every destination is named, so the rail reads without hovering
  /// for a tooltip.
  static const CoreNavigationLabelMode defaultRailMode = all;

  /// Widget default label mode for the [CoreNavigationBarMode.sidebar]
  /// layout.
  static const CoreNavigationLabelMode defaultSidebarMode = all;

  /// Widget default label mode for a [CoreNavigationBarMode.rail] drawn as
  /// the floating glass capsule — no destination shows a label.
  ///
  /// The capsule is one glyph wide. A caption under each glyph would set
  /// the capsule's width by its longest word, and a platform that moves its
  /// tab bar to the side of the screen draws that bar from glyphs alone. A
  /// hidden label is still the destination's accessible name and its
  /// tooltip, and a caller that states `all` or `selected` gets captions
  /// back.
  static const CoreNavigationLabelMode defaultGlassRailMode = none;

  /// Whether a destination shows its label under this mode — always for
  /// [all], only while it is the [selected] one for
  /// [CoreNavigationLabelMode.selected], never for [none].
  ///
  /// A hidden label is still the destination's accessible name and its
  /// tooltip; only the visible text is left out.
  bool showsLabel({required bool selected}) => switch (this) {
    CoreNavigationLabelMode.all => true,
    CoreNavigationLabelMode.selected => selected,
    CoreNavigationLabelMode.none => false,
  };
}

/// Position of an item's label relative to its icon.
enum CoreNavigationLabelPosition {
  /// Label sits below the icon.
  bottom,

  /// Label sits above the icon.
  top,

  /// Label sits after the icon (right in LTR).
  end,

  /// Label sits before the icon (left in LTR).
  start;

  /// Widget default label position for horizontal-style layouts.
  static const CoreNavigationLabelPosition defaultBarPosition = bottom;

  /// Widget default label position for the sidebar layout.
  static const CoreNavigationLabelPosition defaultSidebarPosition = end;

  /// Whether this position places the label on the icon's main axis
  /// horizontally (`start` / `end`) rather than vertically.
  bool get isHorizontal => this == .start || this == .end;
}

/// Distribution of items along the navigation container's main axis.
enum CoreNavigationAlignment {
  /// Items packed at the start of the container.
  start,

  /// Items centred within the container.
  center,

  /// Items packed at the end of the container.
  end,

  /// Items distributed with equal space between them.
  spaceBetween,

  /// Items distributed with equal space around each.
  spaceAround,

  /// Items distributed with equal space between and around them.
  spaceEvenly;

  /// Widget default alignment.
  static const CoreNavigationAlignment defaultAlignment = center;
}

/// How an item's label is treated when it overflows the available
/// space.
enum CoreNavigationOverflow {
  /// The label is clipped to the available width.
  clip,

  /// The label is truncated with an ellipsis (`…`).
  ellipsis,

  /// No overflow handling — the label may overflow visibly.
  none;

  /// Widget default overflow treatment.
  static const CoreNavigationOverflow defaultOverflow = ellipsis;
}

/// What marks the selected destination besides its label's colour and
/// weight.
enum CoreNavigationSelectionMark {
  /// Nothing more — the label (and the selected fill, where the mode states
  /// one) says which destination is selected.
  none,

  /// A small dot above the destination's content — a `Badge` dot, the mark a
  /// bar of bare-label tabs uses. Every destination keeps the dot's room so
  /// the labels stay level, and only the selected one shows it.
  dot;

  /// Widget default — no mark, so a bar draws what it drew before the field
  /// existed. Shared by the Flutter / Web constructors.
  static const CoreNavigationSelectionMark defaultSelectionMark = none;

  /// Whether a destination whose label sits at [position] draws this mark.
  ///
  /// The mark sits above the content, and only a destination that stacks
  /// its label under or over its icon (the bar and the rail) has a top to
  /// put it on. A row — the label beside the icon, the sidebar — draws none;
  /// its selected fill already marks it.
  bool marksAt(CoreNavigationLabelPosition position) =>
      this == dot && !position.isHorizontal;
}

/// How the selected destination is told apart from the others.
enum CoreNavigationSelectionIndicator {
  /// The selected destination's whole tile takes a face
  /// (`selectedBackgroundColor`), and hover lays the state layer's wash.
  fill,

  /// No face — the selected destination's icon and label take the selected
  /// colour and weight, and hover darkens the foreground instead of laying
  /// a wash.
  color;

  /// How a floating glass container marks its selection when the caller
  /// states no `indicator` — [color], in every mode: the lens the container
  /// moves over its destinations is the face
  /// (`CoreNavigationBarMode.defaultIndicatorFor`), and the glass presets
  /// state no tile face under it.
  static const CoreNavigationSelectionIndicator defaultGlassIndicator = color;
}

/// When a `NavigationBar` draws its compact form — smaller and without its
/// captions, stepping back from the content it navigates.
///
/// What the compact form looks like is the bar's style
/// (`CoreNavigationBarStyle.compactScale`); this says when it is drawn.
enum CoreNavigationCompact {
  /// The bar keeps its resting size.
  never,

  /// The bar follows the content: it becomes compact while the content is
  /// scrolled toward its end, and returns to its resting size when the
  /// content is scrolled back or reaches its start
  /// (`CoreNavigationScrollCompaction`).
  ///
  /// The content is the visible outer vertical scrollable in the scaffold
  /// the bar belongs to (or the scrollport holding that scaffold on Web).
  /// Nested vertical lists/editors, inactive tabs, the bar's own scrolling,
  /// and sideways scrolling do not count. A vertical list inside a
  /// horizontal page still counts as content.
  onScroll,

  /// The bar is drawn compact — for an app that decides for itself when the
  /// bar steps back.
  always;

  /// Widget default — the bar keeps its resting size, as it did before the
  /// field existed. Shared by the Flutter / Web constructors.
  static const CoreNavigationCompact defaultCompact = never;
}

/// Kind of a `CoreNavigationBarItem` entry.
///
/// Replaces the legacy 5-class item hierarchy
/// (`NavigationItem` / `NavigationButton` / `NavigationLabel` /
/// `NavigationDivider` / `NavigationGap`) with one tagged data model.
enum CoreNavigationItemKind {
  /// A selectable navigation destination (icon + optional label).
  item,

  /// A non-selectable section header label.
  label,

  /// A separating divider line.
  divider,

  /// An empty spacing gap.
  gap,
}
