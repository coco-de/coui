part of '../navigation_bar/navigation_bar.dart';

int _navigationItemId = 0;

/// One navigation destination drawn on its own for CoUI Web — an icon, a
/// name, an optional count, and a face that says whether it is the current
/// place.
///
/// This is the destination a [NavigationBar] composes for each
/// [CoreNavigationBarItem.destination], public so a page can assemble a
/// sidebar outside the bar — a `Drawer`'s content, an app's own rail, a
/// settings column. A row placed by hand reads exactly like a row the bar
/// placed, because it is the same component.
///
/// The chrome is the bar's: [navigationBarStyle] is a
/// [CoreNavigationBarStyle], and the item draws its item fields at [mode]'s
/// density — a sidebar row by default
/// ([CoreNavigationBarItemContract.defaultMode]). Selection
/// (`aria-current="page"`), the count badge, hover, keyboard focus and
/// activation (Enter / Space) work on their own; the item only needs
/// [selected] and [onPressed] from the page that owns the current place.
///
/// Mirrors Flutter `NavigationBarItem` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// NavigationBarItem(
///   icon: const Icon(LucideIcons.inbox),
///   label: 'Inbox',
///   selected: page == 0,
///   onPressed: () => setState(() => page = 0),
/// )
/// ```
class NavigationBarItem extends UiStatefulComponent
    implements CoreNavigationBarItemContract<Component> {
  /// Creates a [NavigationBarItem].
  const NavigationBarItem({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    this.icon,
    this.label,
    this.badge,
    this.tooltip,
    this.selected = false,
    this.enabled,
    this.onPressed,
    this.mode = CoreNavigationBarItemContract.defaultMode,
    this.variant = CoreNavigationBarVariant.defaultVariant,
    this.labelMode,
    this.labelPosition,
    this.overflow = CoreNavigationOverflow.defaultOverflow,
    this.selectionMark = CoreNavigationSelectionMark.defaultSelectionMark,
    this.indicator,
    this.showDot = false,
    this.navigationBarStyle,
  }) : _composition = null;

  /// The destination a [NavigationBar] places — [_composition] carries what
  /// the bar already worked out for the whole row.
  const NavigationBarItem._(
    this._composition, {
    required this.icon,
    required this.label,
    required this.badge,
    required this.tooltip,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    required this.mode,
    required this.variant,
    required this.labelMode,
    required this.labelPosition,
    required this.overflow,
    required this.selectionMark,
    required this.indicator,
    required this.showDot,
    required this.navigationBarStyle,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
  });

  @override
  final Component? icon;

  @override
  final String? label;

  @override
  final Component? badge;

  @override
  final String? tooltip;

  @override
  final bool selected;

  @override
  final bool? enabled;

  @override
  final CoreVoidCallback? onPressed;

  @override
  final CoreNavigationBarMode mode;

  @override
  final CoreNavigationBarVariant variant;

  @override
  final CoreNavigationLabelMode? labelMode;

  @override
  final CoreNavigationLabelPosition? labelPosition;

  @override
  final CoreNavigationOverflow overflow;

  @override
  final CoreNavigationSelectionMark selectionMark;

  @override
  final CoreNavigationSelectionIndicator? indicator;

  @override
  final bool showDot;

  @override
  final CoreNavigationBarStyle? navigationBarStyle;

  /// What the bar hands the destination it composes. `null` on an item
  /// placed on its own, which resolves its chrome itself.
  final _NavigationItemComposition? _composition;

  /// Returns a copy of this [NavigationBarItem] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  NavigationBarItem copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    Component? icon,
    String? label,
    Component? badge,
    String? tooltip,
    bool? selected,
    bool? enabled,
    CoreVoidCallback? onPressed,
    CoreNavigationBarMode? mode,
    CoreNavigationBarVariant? variant,
    CoreNavigationLabelMode? labelMode,
    CoreNavigationLabelPosition? labelPosition,
    CoreNavigationOverflow? overflow,
    CoreNavigationSelectionMark? selectionMark,
    CoreNavigationSelectionIndicator? indicator,
    bool? showDot,
    CoreNavigationBarStyle? navigationBarStyle,
  }) {
    return NavigationBarItem._(
      _composition,
      key: key ?? this.key,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      icon: icon ?? this.icon,
      label: label ?? this.label,
      badge: badge ?? this.badge,
      tooltip: tooltip ?? this.tooltip,
      selected: selected ?? this.selected,
      enabled: enabled ?? this.enabled,
      onPressed: onPressed ?? this.onPressed,
      mode: mode ?? this.mode,
      variant: variant ?? this.variant,
      labelMode: labelMode ?? this.labelMode,
      labelPosition: labelPosition ?? this.labelPosition,
      overflow: overflow ?? this.overflow,
      selectionMark: selectionMark ?? this.selectionMark,
      indicator: indicator ?? this.indicator,
      showDot: showDot ?? this.showDot,
      navigationBarStyle: navigationBarStyle ?? this.navigationBarStyle,
    );
  }

  @override
  State<NavigationBarItem> createState() => _NavigationBarItemState();
}

/// Chain sugar mirroring the Flutter `NavigationBarItem.withStyle`
/// extension — merges a [CoreNavigationBarStyle] patch into
/// [NavigationBarItem.navigationBarStyle] via the existing
/// [NavigationBarItem.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreNavigationBarStyle.merge` right-side-wins semantics).
///
/// ```dart
/// NavigationBarItem(label: 'Inbox').withStyle(
///   const CoreNavigationBarStyle(
///     itemRadius: CoreBorderRadius.all(CoreRadius.radius6),
///   ),
/// )
/// ```
extension NavigationBarItemStyleChain on NavigationBarItem {
  /// Sets the background paint and preserves the other style fields.
  NavigationBarItem backgroundColor(CoreColor value) =>
      withStyle(CoreNavigationBarStyle(backgroundColor: value));

  /// Returns a copy of this [NavigationBarItem] with [patch] merged into
  /// [navigationBarStyle] (patch fields win on conflict).
  NavigationBarItem withStyle(CoreNavigationBarStyle patch) => copyWith(
    navigationBarStyle: (navigationBarStyle ?? const CoreNavigationBarStyle())
        .merge(patch),
  );
}

/// What a [NavigationBar] works out once for the whole row and hands each
/// destination it composes.
///
/// A standalone item works these out for itself — the chrome through its
/// own resolver call, its ids from its own `id` — or has no use for them:
/// only the bar has a glass selection that previews another destination,
/// and a runtime that finds destinations by their place.
class _NavigationItemComposition {
  const _NavigationItemComposition({
    required this.resolved,
    required this.index,
    required this.itemId,
    this.previewSelected,
    this.captionFolded = false,
  });

  /// The bar's chrome, resolved once for the row.
  final ResolvedNavigationBar resolved;

  /// The destination's place among the bar's destinations — what the glass
  /// runtime reads off `data-coui-nav-index`.
  final int index;

  /// The id the destination's label and badge ids are built from, scoped to
  /// the bar's own id.
  final String itemId;

  /// Whether this is the destination the glass selection is previewing
  /// while it is dragged — `null` when nothing is previewed, so the
  /// committed selection shows.
  final bool? previewSelected;

  /// Whether the destination's caption is folded away — the bar is compact
  /// (`NavigationBar.compact`) and has a compact form.
  ///
  /// A folded caption is not a hidden one: the destination stays the one it
  /// was — the same elements and chrome, no tooltip standing in for the
  /// caption — and only the caption's fold closes, so a bar can fold and
  /// unfold on every scroll without its destinations losing their hover or
  /// focus.
  final bool captionFolded;
}

class _NavigationBarItemState extends State<NavigationBarItem> {
  late final String _generatedId =
      'coui-navigation-item-${_navigationItemId++}';

  /// Whether the pointer is over the item.
  bool _hovered = false;

  void _handleHoverChanged(bool hovering) {
    if (_hovered == hovering) return;
    setState(() => _hovered = hovering);
  }

  WebElementChrome _pickDestinationChrome({
    required ResolvedNavigationBar resolved,
    required bool selected,
    required bool enabled,
    required bool hovered,
    required bool iconOnly,
  }) {
    if (iconOnly) {
      if (selected) return resolved.iconOnlyDestinationSelected;
      if (!enabled) return resolved.iconOnlyDestinationDisabled;
      if (hovered) return resolved.iconOnlyDestinationEnabledHovered;
      return resolved.iconOnlyDestinationEnabledIdle;
    }
    if (selected) return resolved.destinationSelected;
    if (!enabled) return resolved.destinationDisabled;
    if (hovered) return resolved.destinationEnabledHovered;
    return resolved.destinationEnabledIdle;
  }

  WebElementChrome _pickLabelChrome({
    required ResolvedNavigationBar resolved,
    required bool selected,
    required bool enabled,
    required bool disabledSelected,
  }) {
    if (disabledSelected) return resolved.labelDisabledSelected;
    if (!enabled) return resolved.labelDisabled;
    if (selected) return resolved.labelSelected;
    if (_hovered) return resolved.labelHovered;
    return resolved.label;
  }

  Component _buildLabel(
    String label,
    ResolvedNavigationBar resolved, {
    required bool selected,
    required bool enabled,
    required bool disabledSelected,
    required String id,
  }) {
    // The typography — colour included — rides on the label's own element
    // rather than being inherited from the item: the role class sets a
    // weight and a colour here, and an inherited one would lose to it.
    final chrome = _pickLabelChrome(
      resolved: resolved,
      selected: selected,
      enabled: enabled,
      disabledSelected: disabledSelected,
    );

    return Component.element(
      tag: 'span',
      id: id,
      classes: chrome.className,
      styles: chrome.inlineStyles,
      children: [Text(label)],
    );
  }

  Component _buildIcon(
    Component icon,
    ResolvedNavigationBar resolved, {
    required bool selected,
    required bool enabled,
  }) {
    final iconStyle = !enabled
        ? resolved.disabledIconStyle
        : selected
        ? (resolved.selectedIconStyle ?? resolved.iconStyle)
        : _hovered
        ? resolved.hoverIconStyle
        : resolved.iconStyle;
    return Component.element(
      tag: 'span',
      classes: resolved.icon.className,
      styles: resolved.icon.inlineStyles,
      children: [
        // Nearest `IconTheme` so the nav-bar icon size outranks the
        // app-root ambient `IconTheme` — the wrapper span's CSS
        // `font-size` only reaches an `Icon` through CSS inheritance,
        // which the Dart-channel ambient silently outranks (mirrors
        // the Flutter twin's per-destination `IconTheme.merge`). The
        // colour is also carried here rather than left to CSS
        // inheritance from the destination's per-state label colour —
        // the icon is state-independent across rest / hover / selected
        // and follows only the disabled state.
        IconTheme(
          data: IconThemeData(
            size: iconStyle.size,
            color: iconStyle.color,
          ),
          child: icon,
        ),
      ],
    );
  }

  @override
  Component build(BuildContext context) {
    final composition = component._composition;
    final labelPosition =
        component.labelPosition ?? component.mode.defaultLabelPosition;
    // Single entry point — the bar resolved its chrome once for the row and
    // hands it in; an item placed on its own resolves the same chain itself.
    final resolved =
        composition?.resolved ??
        resolveNavigationBar(
          context,
          mode: component.mode,
          variant: component.variant,
          overflow: component.overflow,
          labelPosition: labelPosition,
          indicator: component.indicator,
          navigationBarStyle: component.navigationBarStyle,
        );
    // The state layer is a blend, so it has no preset utility to prefix — it
    // rides scoped rules keyed to a class the resolver already put on the
    // item. Inside a bar the bar writes them once for every destination; an
    // item placed on its own writes its own.
    final stateLayerCss = composition != null
        ? ''
        : resolveNavigationBarRules(
            context,
            mode: component.mode,
            variant: component.variant,
            indicator: component.indicator,
            navigationBarStyle: component.navigationBarStyle,
          ).css;

    final enabled = component.enabled ?? component.onPressed != null;
    // Disabled outranks the selection's behaviour: a disabled item states no
    // selection and answers no pointer. Its selection mark stays, dimmed
    // (`disabledSelected` below), so the label shows as a selected one would.
    final selected = enabled && component.selected;
    final visualSelection =
        enabled && (composition?.previewSelected ?? selected);
    // Selected and disabled: the tile's face in the disabled area
    // tone, the label in the disabled tone at the selected weight. Outside
    // the glass preview, which draws the selection itself — the Flutter
    // twin's `disabledSelected`.
    final disabledSelected =
        !enabled && component.selected && composition?.previewSelected == null;
    final handler = component.onPressed;
    final isInteractive = enabled && handler != null;
    final label = component.label;
    final hasLabel = label != null && label.isNotEmpty;
    // Against the default the resolved chrome was drawn for: a destination
    // in the floating glass rail hides its caption unless the caller states
    // a label mode (the Flutter twin reads the same Core answer). The
    // resolver settles the material; the capsule's pane is how it says so.
    final renderLabel =
        hasLabel &&
        (component.labelMode ??
                component.mode.defaultLabelModeFor(
                  floatingGlass: resolved.glassPane != null,
                ))
            .showsLabel(selected: component.selected);
    final icon = component.icon;
    final badge = component.badge;
    // Where a badge sits follows the layout mode: a sidebar row carries it
    // at the row's trailing end, the bar and the rail over the icon's
    // top-end corner (through the composed `Indicator`). An icon-less bar
    // or rail destination has no corner to hang it on, so it takes the row
    // end like a sidebar row does.
    final badgeAtRowEnd =
        badge != null && component.mode.badgeAtRowEnd(hasIcon: icon != null);
    // The destination's accessible name is its label followed by what the
    // badge says (`Home 3`), named by reference so the browser joins the
    // two with a space. The label element is always present to be named —
    // visually hidden when the label is not shown — so an icon-only
    // destination keeps its name.
    final itemId = composition?.itemId ?? component.id ?? _generatedId;
    final labelId = '$itemId-label';
    final badgeId = '$itemId-badge';

    // A stacked destination keeps its icon in a box of its own, so the
    // destinations stay the same width whichever one is selected — the
    // selected face is the whole tile, not this box.
    final stacked = !labelPosition.isHorizontal;

    Component? iconNode;
    if (icon != null) {
      iconNode = _buildIcon(
        icon,
        resolved,
        selected: visualSelection,
        enabled: enabled,
      );
      if (badge != null && !badgeAtRowEnd) {
        iconNode = Indicator(
          classes: resolved.badgeAnchor.className,
          indicatorStyle: resolved.badgeIndicatorStyle,
          item: Component.element(tag: 'span', id: badgeId, children: [badge]),
          child: iconNode,
        );
      } else if (badge == null && component.showDot) {
        iconNode = Indicator(
          classes: resolved.badgeAnchor.className,
          indicatorStyle: resolved.notificationDotIndicatorStyle,
          item: Component.element(
            tag: 'span',
            attributes: const {'aria-hidden': 'true'},
            children: [
              Badge(
                form: CoreBadgeForm.dot,
                badgeStyle: resolved.notificationDotStyle,
              ),
            ],
          ),
          child: iconNode,
        );
      }
      if (stacked) {
        iconNode = Component.element(
          tag: 'span',
          classes: resolved.iconAnchor.className,
          styles: resolved.iconAnchor.inlineStyles,
          children: [iconNode],
        );
      }
    }

    // In a bar with a compact form the caption sits in a fold, open or
    // closed — the fold carries the gap to the icon, so it is there for an
    // item placed on its own too. The label element inside is the same
    // either way and keeps naming the destination.
    final fold = icon == null
        ? null
        : (composition?.captionFolded ?? false)
        ? resolved.captionFoldFolded
        : resolved.captionFold;
    final foldBody = resolved.captionFoldBody;
    final labelNode = renderLabel
        ? _buildLabel(
            label,
            resolved,
            selected: visualSelection,
            enabled: enabled,
            disabledSelected: disabledSelected,
            id: labelId,
          )
        : null;
    final innerChildren = <Component>[
      ?iconNode,
      if (labelNode != null)
        if (fold != null && foldBody != null)
          Component.element(
            tag: 'span',
            classes: fold.className,
            styles: fold.inlineStyles,
            children: [
              Component.element(
                tag: 'span',
                classes: foldBody.className,
                styles: foldBody.inlineStyles,
                children: [labelNode],
              ),
            ],
          )
        else
          labelNode,
    ];
    // Order icon / label according to the resolved label position.
    final ordered = (labelPosition == .start || labelPosition == .top)
        ? innerChildren.reversed.toList()
        : innerChildren;

    final iconOnly = stacked && icon != null && !renderLabel;
    final itemLayout = _resolveNavigationBarItemLayout(
      resolved,
      mode: component.mode,
      iconOnly: iconOnly,
    );
    final sizer = itemLayout.sizer;
    final innerChrome = itemLayout.inner;
    final inner = Component.element(
      tag: 'span',
      classes: innerChrome.className,
      styles: innerChrome.inlineStyles,
      children: [
        ...ordered,
        if (sizer != null)
          Component.element(
            tag: 'span',
            attributes: const {'aria-hidden': 'true'},
            classes: sizer.className,
            styles: sizer.inlineStyles,
          ),
      ],
    );
    // The selection mark sits above the content. Every marked destination
    // keeps the mark's room so the labels stay level across the bar; only
    // the selected one shows the dot, fading on the selection's own clock
    // (the Flutter twin's `AnimatedOpacity`). Decorative: the selection is
    // already `aria-current`.
    final marked = component.selectionMark.marksAt(labelPosition);
    // Dimmed when the selected destination is disabled (the Flutter twin's
    // `disabledSelected`).
    final markChrome = visualSelection || disabledSelected
        ? resolved.selectionMarkShown
        : resolved.selectionMarkHidden;
    final content = marked
        ? Component.element(
            tag: 'span',
            classes: resolved.selectionMarkColumn.className,
            styles: resolved.selectionMarkColumn.inlineStyles,
            children: [
              Component.element(
                tag: 'span',
                attributes: const {'aria-hidden': 'true'},
                classes: markChrome.className,
                styles: markChrome.inlineStyles,
                children: [
                  Badge(
                    form: CoreBadgeForm.dot,
                    badgeStyle: disabledSelected
                        ? resolved.disabledSelectionMarkStyle
                        : resolved.selectionMarkStyle,
                  ),
                ],
              ),
              Gap(gapStyle: resolved.selectionMarkGapStyle),
              inner,
            ],
          )
        : inner;
    final nameIds = [
      if (hasLabel) labelId,
      if (badge != null) badgeId,
    ];

    // Tooltip text when the label is hidden (rail / icon-only modes) —
    // rendered by composing the unified `Tooltip` below, mirroring the
    // Flutter twin (a native `title` attribute has a long OS delay, no
    // design-system chrome and no touch support, so it reads as "no
    // tooltip").
    final tooltip = component.tooltip ?? (renderLabel ? null : label);

    // An icon-only stacked destination paints a shorter box than a labelled
    // one; what accepts a pointer stays `touchTargetSize`.
    final itemChrome = disabledSelected
        ? (iconOnly
              ? resolved.iconOnlyDestinationDisabledSelected
              : resolved.destinationDisabledSelected)
        : _pickDestinationChrome(
            resolved: resolved,
            selected: visualSelection,
            enabled: enabled,
            hovered: _hovered,
            iconOnly: iconOnly,
          );

    // Composition: the destination's click / keyboard activation (Enter /
    // Space) / cursor / `:focus-visible` ring / press feedback flow
    // through the unified `Clickable` — no hand-rolled `role="button"`
    // `<div>` with click / keydown / mouseenter / mouseleave handlers.
    // The Clickable provides `role="button"` + `tabindex` +
    // `aria-disabled` from `enabled: isInteractive`; the caller
    // attributes add the label / current / tooltip semantics
    // (passthrough wins). `onHover` feeds this item's own hover flag so
    // the per-state chrome is SELECTED here (mirrors item_picker). The
    // item surface (per-state background / foreground / padding / radius
    // / transition, incl. the CSS-native `hover:bg-*`) lives on the child
    // `<div>`, which is `w-full` so it fills the Clickable's cell in every
    // mode (the Clickable itself is `w-full` in a vertical layout and
    // `flex-1` in the bar) and the highlight spans the whole cell.
    final destination = Clickable(
      onPressed: isInteractive ? handler : null,
      attributes: {
        if (composition != null) 'data-coui-nav-index': '${composition.index}',
        if (nameIds.isNotEmpty) 'aria-labelledby': nameIds.join(' '),
        if (selected) 'aria-current': 'page',
        ...component.componentAttributes,
      },
      // `flex-1` in bar mode grows the Clickable — the actual flex item
      // inside the `<nav>` row — to an equal share, up to the resolved cap;
      // the item chrome `<div>` inside it is not the row's direct child, so
      // `flex-1` on that inner element alone would not move the needle.
      classes: component.rootClasses(resolved.destinationCell.className),
      css: switch ((resolved.destinationCell.inlineStyles, component.css)) {
        (final cell?, final caller?) => Styles.combine([cell, caller]),
        (final cell, final caller) => cell ?? caller,
      },
      eventHandlers: component.eventHandlers,
      id: component.id,
      onHover: isInteractive ? _handleHoverChanged : null,
      enabled: isInteractive,
      clickableStyle: resolved.clickableStyle,
      child: Component.element(
        tag: 'div',
        attributes: const {'data-coui-nav-chrome': ''},
        classes: itemChrome.className,
        styles: itemChrome.inlineStyles,
        children: [
          // `<style>` is `display: none`, so it never joins the item's flex
          // row.
          if (stateLayerCss.isNotEmpty)
            Component.element(
              tag: 'style',
              children: [RawText(stateLayerCss)],
            ),
          content,
          if (hasLabel && !renderLabel)
            Component.element(
              tag: 'span',
              id: labelId,
              // `fixed`, not plain `sr-only`: the bar scrolls sideways,
              // and an absolutely placed hidden box inside it would widen
              // the page's own scroll area.
              classes: WebLayout.srOnlyFixed,
              children: [Text(label)],
            ),
          if (badge != null && badgeAtRowEnd)
            Component.element(
              tag: 'span',
              id: badgeId,
              classes: resolved.badgeTrailing.className,
              styles: resolved.badgeTrailing.inlineStyles,
              children: [badge],
            ),
        ],
      ),
    );

    // Compose the unified `Tooltip` only while the label is hidden —
    // the Flutter twin gates the same way (`!renderLabel`), so a
    // visible label never doubles up with a tooltip. Vertical (rail /
    // sidebar) rows put the grid display class on the tooltip root
    // because the inline-flex trigger wrapper otherwise shrinks to
    // content width and left-aligns inside the full-width root (icons
    // sat 4 px off-centre); as the sole grid item the wrapper
    // blockifies and stretches to the full row width, keeping the
    // destination geometry identical to a tooltip-less row.
    if (tooltip != null && tooltip.isNotEmpty && !renderLabel) {
      return Tooltip(
        // The tooltip trigger wrapper — not the Clickable inside it — is
        // the row's direct flex child, so it carries whichever growth class
        // the mode wants.
        classes: itemLayout.tooltip.className,
        css: itemLayout.tooltip.inlineStyles,
        message: tooltip,
        // Beside the destination in a column, above it in a row.
        position: component.mode.tooltipPosition,
        child: destination,
      );
    }
    return destination;
  }
}
