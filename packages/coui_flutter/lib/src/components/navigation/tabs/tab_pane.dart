import 'package:coui_flutter/coui_flutter.dart';

/// A unified card of underline tabs + integrated content panel — or, with
/// [CoreTabPaneVariant.editorStrip], the strip-only IDE editor chrome.
///
/// In the default [CoreTabPaneVariant.boxed] variant, `TabPane` renders
/// a bordered card holding a horizontally scrollable tab bar over the
/// content area. The selected tab is marked by a bar along its bottom edge.
/// Each [CoreTabItem] supplies a `label` for its tab and a
/// `content` widget shown in the panel when that tab is focused.
///
/// In [CoreTabPaneVariant.editorStrip], only the strip is rendered —
/// `CoreTabItem.content` is ignored (strip-only API; not an empty-content
/// hack). Style chrome comes from [CoreTabPaneStyle.defaultsByVariant]
/// (a 36 px strip whose chips fill its height, `tabSpacing: 0` with only a
/// hairline between tabs, flat strip band, flush corners, a bottom line under
/// the strip that the selected tab's face covers, and a tab focus ring drawn
/// inside the tab's box so the scrolling strip does not clip it, a
/// `primary` indicator bar along the inside of the selected tab's top edge
/// (paint only — the label does not move), and a 20 px close box with a
/// 12 px `onSurfaceSubtle` glyph that hover does not change).
///
/// When [reorderable] is `true`, tabs can be dragged left / right to
/// change their order; the new order is reported through [onReorder].
/// Optional [leading] / [trailing] widgets bracket the scrollable tab
/// area. Per-tab [CoreTabItem.onClose] / [CoreTabItem.trailing] sit
/// outside the select `Clickable` so close × does not fire [onChanged].
///
/// Every chrome / dimensional override flows through the single
/// [tabPaneStyle] field — see [CoreTabPaneStyle] for the merge chain.
///
/// ```dart
/// TabPane(
///   tabs: [
///     CoreTabItem(label: 'Account', content: accountPanel),
///     CoreTabItem(label: 'Password', content: passwordPanel),
///   ],
///   selectedIndex: index,
///   onChanged: (i) => setState(() => index = i),
/// )
///
/// // IDE editor chrome — strip only:
/// TabPane(
///   variant: .editorStrip,
///   tabs: [
///     CoreTabItem(label: 'main.dart', onClose: () {}),
///     CoreTabItem(label: 'pubspec.yaml', onClose: () {}),
///   ],
///   selectedIndex: index,
///   onChanged: (i) => setState(() => index = i),
/// )
/// ```
///
/// surface:behind — whatever the content panel lands on (boxed only). It
/// always paints its own fill (see [CoreTabPaneStyle.defaultBackgroundColor]),
/// so a parent surface — or the page itself — shows through it until a
/// caller overrides [tabPaneStyle] to something transparent.
///
/// surface:content — a panel in the page flow — no sticky, fixed, or
/// overlay mount on either platform. [CoreTabPaneVariant.editorStrip]
/// has no content panel.
class TabPane extends StatefulWidget implements CoreTabPaneContract<Widget> {
  /// Creates a [TabPane].
  const TabPane({
    required this.tabs,
    required this.selectedIndex,
    this.variant = CoreTabPaneVariant.defaultVariant,
    this.onChanged,
    this.reorderable = false,
    this.onReorder,
    this.leading = const [],
    this.trailing = const [],
    this.tabPaneStyle,
    super.key,
  });

  @override
  final List<CoreTabItem<Widget>> tabs;

  @override
  final int selectedIndex;

  @override
  final CoreTabPaneVariant variant;

  @override
  final CoreValueChanged<int>? onChanged;

  @override
  final bool reorderable;

  @override
  final void Function(List<CoreTabItem<Widget>>)? onReorder;

  @override
  final List<Widget> leading;

  @override
  final List<Widget> trailing;

  @override
  final CoreTabPaneStyle? tabPaneStyle;

  /// Returns a copy of this [TabPane] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  TabPane copyWith({
    Key? key,
    CoreValueChanged<int>? onChanged,
    List<CoreTabItem<Widget>>? tabs,
    int? selectedIndex,
    CoreTabPaneVariant? variant,
    bool? reorderable,
    void Function(List<CoreTabItem<Widget>>)? onReorder,
    List<Widget>? leading,
    List<Widget>? trailing,
    CoreTabPaneStyle? tabPaneStyle,
  }) {
    return TabPane(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      tabs: tabs ?? this.tabs,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      variant: variant ?? this.variant,
      reorderable: reorderable ?? this.reorderable,
      onReorder: onReorder ?? this.onReorder,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      tabPaneStyle: tabPaneStyle ?? this.tabPaneStyle,
    );
  }

  @override
  State<TabPane> createState() => _TabPaneState();
}

class _TabPaneState extends State<TabPane> {
  final _scrollController = ScrollController();

  void _handleReorder(int from, int to) {
    final callback = widget.onReorder;
    if (callback == null) return;
    if (from == to) return;
    final next = [...widget.tabs];
    final moved = next.removeAt(from);
    next.insert(to > from ? to - 1 : to, moved);
    callback(next);
  }

  Widget _buildTab({
    required CoreTabItem<Widget> item,
    required int index,
    required ResolvedTabPane resolved,
  }) {
    final isFocused = index == widget.selectedIndex;
    final isEnabled = item.enabled && widget.onChanged != null;
    final stripOnly = resolved.stripOnly;
    // The `leading` / `trailing` glyphs are caller widgets: the slot's size
    // reaches them as the ambient icon size (an `Icon` that states its own
    // keeps it).
    final slotIconTheme = IconThemeData(size: resolved.slotIconStyle.size);
    // A focused-tab outline is drawn only when the style states one
    // (`tabBorderColor`); both variant rows leave it off, and the indicator
    // marks the focused tab instead.
    final tabBorderColor = resolved.tabBorderColor;
    final showTabBorder =
        isFocused &&
        !stripOnly &&
        tabBorderColor != null &&
        resolved.borderWidth > 0;

    // Label + badge (+ leading) live inside the select Clickable.
    // `trailing` and the synthesised close × sit OUTSIDE it so their hit
    // targets do not fire `onChanged` (P1 — close must not select).
    final selectRow = Row(
      mainAxisSize: .min,
      children: [
        if (item.leading != null)
          IconTheme.merge(
            data: slotIconTheme,
            child: item.leading!,
          ),
        if (item.leading != null) Gap(gapStyle: resolved.labelBadgeGapStyle),
        DefaultTextStyle.merge(
          style: resolved.contentTextStyle.copyWith(
            color: isFocused
                ? resolved.activeContentColor
                : resolved.inactiveContentColor,
          ),
          child: Text(item.label),
        ),
        if (item.badge != null) Gap(gapStyle: resolved.labelBadgeGapStyle),
        ?item.badge,
      ],
    );

    // Each side slot is centred in the chip, not stretched to it: the row
    // below stretches so the select region keeps the chip's whole height,
    // and a slot that took that height would paint its own box (the close
    // Button's hover face) taller than it is. Centred, it keeps its own
    // size — what the Web chip's `items-center` does.
    final sideChildren = <Widget>[];
    if (item.trailing != null) {
      sideChildren
        ..add(Gap(gapStyle: resolved.labelBadgeGapStyle))
        ..add(
          Center(
            child: IconTheme.merge(data: slotIconTheme, child: item.trailing!),
          ),
        );
    }
    if (item.onClose != null) {
      sideChildren
        ..add(Gap(gapStyle: resolved.labelBadgeGapStyle))
        ..add(
          Center(
            // The glyph is an icon, so the button has no text to name it;
            // the Web twin emits the same string as `aria-label`.
            child: Semantics(
              button: true,
              label: CoUILocalizations.of(context).buttonClose,
              child: Button(
                onPressed: item.onClose,
                variant: .ghost,
                size: .sm,
                buttonStyle: resolved.closeButtonStyle,
                child: Icon(
                  LucideIcons.x,
                  iconStyle: resolved.closeIconStyle,
                ),
              ),
            ),
          ),
        );
    }

    final chipDecoration = BoxDecoration(
      // The editor strip's focused tab is a face on the band. A boxed tab has
      // none unless it states an outline: it sits on the card's own surface.
      color: isFocused && (stripOnly || tabBorderColor != null)
          ? resolved.backgroundColor
          : null,
      border: showTabBorder
          ? Border(
              top: BorderSide(
                color: tabBorderColor,
                width: resolved.borderWidth,
              ),
              left: BorderSide(
                color: tabBorderColor,
                width: resolved.borderWidth,
              ),
              right: BorderSide(
                color: tabBorderColor,
                width: resolved.borderWidth,
              ),
            )
          : null,
    );

    // The selected tab's indicator bar. PAINT only, laid over the chip: a
    // border would inflate the chip's padding by the bar's width and push the
    // label down on the selected tab only. It runs the chip's full width —
    // along the INSIDE of the top edge on the editor strip, the INSIDE of the
    // bottom edge on the boxed card (over the bar's line). `null` for an
    // unselected tab and for a style that states no indicator, where no
    // wrapper is added.
    final indicatorColor = isFocused ? resolved.indicatorColor : null;
    Widget chipBox({required Widget child}) {
      final box = DecoratedBox(decoration: chipDecoration, child: child);
      if (indicatorColor == null) return box;
      return Stacks(
        children: [
          box,
          Position(
            left: 0,
            right: 0,
            top: stripOnly ? 0 : null,
            bottom: stripOnly ? null : 0,
            height: resolved.indicatorWidth,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: resolved.indicatorBorderRadius,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final selectContent = Center(
      child: Semantics(
        enabled: isEnabled,
        selected: isFocused,
        button: true,
        child: selectRow,
      ),
    );

    // `tabPadding` is the chip's padding: it wraps everything the chip
    // holds, from the leading glyph to the close ×, so the × is measured
    // from the chip's edge like the label is — what the Web twin's chip
    // `<span>` and the Figma tab frame both do.
    Widget tab;
    if (sideChildren.isEmpty) {
      // The chip holds only the select region, so the Clickable can wrap
      // the whole padded chip. Historic tree: DecoratedBox inside
      // Clickable — the snapshots / tests read that nesting.
      tab = Clickable(
        onPressed: isEnabled ? () => widget.onChanged!(index) : null,
        enabled: isEnabled,
        clickableStyle: resolved.clickableStyle,
        child: chipBox(
          child: Padding(padding: resolved.tabPadding, child: selectContent),
        ),
      );
    } else {
      // Side chrome (trailing / onClose) sits on the same chip but outside
      // the select Clickable, so its hit target never fires `onChanged`.
      tab = chipBox(
        child: Padding(
          padding: resolved.tabPadding,
          child: Row(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Clickable(
                onPressed: isEnabled ? () => widget.onChanged!(index) : null,
                enabled: isEnabled,
                clickableStyle: resolved.clickableStyle,
                child: selectContent,
              ),
              ...sideChildren,
            ],
          ),
        ),
      );
    }

    if (widget.reorderable && widget.onReorder != null) {
      // Capture the leaf before assigning the wrapper. Capturing `tab` itself
      // makes the builder return its own DragTarget recursively.
      final tabChild = tab;
      tab = DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) => _handleReorder(details.data, index),
        builder: (context, candidate, rejected) {
          final dragFeedback = Opacity(
            opacity: resolved.dragOpacity,
            child: tabChild,
          );
          return Draggable(
            // Feedback moves to the root Overlay, outside a locally scoped
            // CoUI theme (for example a Widgetbook preview).
            feedback: InheritedTheme.captureAll(context, dragFeedback),
            data: index,
            childWhenDragging: dragFeedback,
            child: tabChild,
          );
        },
      );
    }

    return tab;
  }

  /// The boxed card — the bar over the content panel, inside one hairline
  /// edge. The one slot in this boxed-tab pair that restates the
  /// content-material seat (see `ResolvedTabPane.panelBackgroundColor`).
  /// Wrapped in `SurfaceBlur` only when the resolver hands over a fill to
  /// blur behind, so a fully transparent override never stacks a second
  /// backdrop pass.
  Widget _buildCard(ResolvedTabPane resolved, Widget bar, Widget? content) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: resolved.panelBackgroundColor,
        border: Border.all(
          color: resolved.panelBorderColor,
          width: resolved.borderWidth,
        ),
        borderRadius: resolved.borderRadius,
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [bar, ?content],
      ),
    );

    final effectiveBlur = resolved.surfaceBlur;
    if ((effectiveBlur != null && effectiveBlur > 0) ||
        resolved.surfaceSheen != null) {
      card = SurfaceBlur(
        borderRadius: resolved.borderRadius,
        surfaceBlur: effectiveBlur,
        surfaceSaturation: resolved.surfaceSaturation,
        surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
        surfaceSheen: resolved.surfaceSheen,
        // The active material's bend — every surface that draws the
        // material draws all of it (mirrors `Drawer`/`Table`).
        refraction: Theme.of(context).surfaceRefraction,
        child: card,
      );
    }

    return card;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTabPane(
      context,
      variant: widget.variant,
      tabPaneStyle: widget.tabPaneStyle,
    );

    final tabButtons = <Widget>[
      for (var i = 0; i < widget.tabs.length; i++)
        // The wrapper carries the inter-tab rule. It has no corner radius,
        // which is the whole reason the rule lives here and not on the tab
        // box: `BoxDecoration` asserts on a per-side stroke colour once a
        // `borderRadius` is present. `BorderDirectional.end` so the rule
        // follows reading direction.
        Container(
          padding: .only(right: resolved.tabSpacing),
          decoration: resolved.tabSeparatorColor == null
              ? null
              : BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(
                      color: resolved.tabSeparatorColor!,
                      width: resolved.tabSeparatorWidth,
                    ),
                  ),
                ),
          child: _buildTab(
            item: widget.tabs[i],
            index: i,
            resolved: resolved,
          ),
        ),
    ];

    // The tabs start inside the bar by `resolved.barPadding`: the boxed card
    // states 16 so the first tab clears the card's corner; the editor strip
    // is flush.
    // The band wraps the SIZED box, outside the bar padding, so it spans
    // the strip edge to edge while the padding still pulls the tabs in. A
    // band inside the padding would leave two unpainted gutters.
    //
    // Wrapped only when the resolver states a band: a transparent box
    // paints nothing but is still a node, and the preset render snapshots
    // read the node list rather than the pixels — so an unconditional box
    // would rewrite every baseline for a change no one can see.
    Widget bar = SizedBox(
      height: resolved.barHeight,
      child: Padding(
        padding: resolved.barPadding,
        child: Row(
          crossAxisAlignment: .stretch,
          children: [
            ...widget.leading,
            Expanded(
              child: FadeScroll(
                controller: _scrollController,
                direction: .horizontal,
                child: Row(
                  crossAxisAlignment: .end,
                  children: tabButtons,
                ),
              ),
            ),
            ...widget.trailing,
          ],
        ),
      ),
    );
    // The bar's bottom line rides the same box as the band: a decoration
    // paints before its child, so the line lies under the chips — the editor
    // strip's focused face covers it, and a boxed tab's indicator is laid
    // over it — while the unfocused tabs (no fill) leave it visible. A
    // `Border` takes no layout space, so the line sits inside [barHeight].
    // Wrapped only when the resolver states a band or a line.
    final band = resolved.stripBackgroundColor;
    final line = resolved.stripBorderColor;
    if (band != null || line != null) {
      bar = DecoratedBox(
        decoration: BoxDecoration(
          color: band,
          border: line == null
              ? null
              : Border(
                  bottom: BorderSide(color: line, width: resolved.borderWidth),
                ),
        ),
        child: bar,
      );
    }

    // Strip-only ([CoreTabPaneVariant.editorStrip]): no content panel and no
    // card. The strip is the whole component.
    if (resolved.stripOnly) {
      return bar;
    }

    final hasFocused =
        widget.selectedIndex >= 0 && widget.selectedIndex < widget.tabs.length;
    final content = hasFocused
        ? widget.tabs[widget.selectedIndex].content
        : null;

    return _buildCard(resolved, bar, content);
  }
}

/// Chain sugar for merging a [CoreTabPaneStyle] patch into
/// [TabPane.tabPaneStyle] without hand-reconstructing every field.
/// Mirrors the Web `TabPane.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTabPaneStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreTabPaneStyle.borderRadius] and `.primary` sets
/// [CoreTabPaneStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// TabPane(tabs: tabs, selectedIndex: index).radius4.surface
/// ```
extension TabPaneStyleChain on TabPane {
  /// Returns a copy of this [TabPane] with [patch] merged into
  /// [tabPaneStyle] (patch fields win on conflict).
  TabPane withStyle(CoreTabPaneStyle patch) => copyWith(
    tabPaneStyle: (tabPaneStyle ?? const CoreTabPaneStyle()).merge(patch),
  );

  /// IDE editor chrome — sets [variant] to
  /// [CoreTabPaneVariant.editorStrip]. Style chrome comes from
  /// [CoreTabPaneStyle.defaultsByVariant] (a 36 px strip, `tabSpacing: 0`,
  /// flat strip band, flush corners, a bottom line under the strip).
  /// Content panel is not rendered.
  TabPane get editorStrip => copyWith(variant: CoreTabPaneVariant.editorStrip);

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  TabPane get radius0 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  TabPane get radius2 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  TabPane get radius4 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  TabPane get radius6 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  TabPane get radius8 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  TabPane get radius10 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  TabPane get radius12 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  TabPane get radius14 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  TabPane get radius16 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  TabPane get radius20 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  TabPane get radius24 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  TabPane get radius28 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  TabPane get radius32 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  TabPane get radius36 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  TabPane get radius40 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  TabPane get radius48 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  TabPane get radius56 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  TabPane get radius64 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  TabPane get radius9999 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  TabPane get primary => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  TabPane get secondary => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  TabPane get tertiary => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  TabPane get surface => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  TabPane get surfaceContainer => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  TabPane get error => withStyle(
    const CoreTabPaneStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  TabPane get success => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  TabPane get warning => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  TabPane get info => withStyle(
    const CoreTabPaneStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  TabPane get outline => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  TabPane get transparent => withStyle(
    const CoreTabPaneStyle(backgroundColor: .transparent),
  );
}
