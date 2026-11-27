part of '../navigation_bar/navigation_bar.dart';

/// One navigation destination drawn on its own — an icon, a name, an
/// optional count, and a face that says whether it is the current place.
///
/// This is the destination a [NavigationBar] composes for each
/// [CoreNavigationBarItem.destination], public so a screen can assemble a
/// sidebar outside the bar — a [Drawer]'s content, an app's own rail, a
/// settings column. A row placed by hand reads exactly like a row the bar
/// placed, because it is the same widget.
///
/// The chrome is the bar's: [navigationBarStyle] is a
/// [CoreNavigationBarStyle], and the item draws its item fields at [mode]'s
/// density — a sidebar row by default
/// ([CoreNavigationBarItemContract.defaultMode]). Selection, the count badge,
/// hover, keyboard focus and activation (Enter / Space) work on their own;
/// the item only needs [selected] and [onPressed] from the screen that owns
/// the current place.
///
/// ```dart
/// Column(
///   crossAxisAlignment: CrossAxisAlignment.stretch,
///   children: [
///     NavigationBarItem(
///       icon: const Icon(LucideIcons.inbox),
///       label: 'Inbox',
///       badge: const Badge(
///         form: CoreBadgeForm.count,
///         tone: CoreBadgeTone.info,
///         variant: CoreBadgeVariant.filled,
///         size: CoreComponentSize.xs,
///         child: Text('3'),
///       ),
///       selected: page == 0,
///       onPressed: () => setState(() => page = 0),
///     ),
///     NavigationBarItem(
///       icon: const Icon(LucideIcons.settings),
///       label: 'Settings',
///       selected: page == 1,
///       onPressed: () => setState(() => page = 1),
///     ),
///   ],
/// )
/// ```
class NavigationBarItem extends StatefulWidget
    implements CoreNavigationBarItemContract<Widget> {
  /// Creates a [NavigationBarItem].
  const NavigationBarItem({
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
    super.key,
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
    super.key,
  });

  @override
  final Widget? icon;

  @override
  final String? label;

  @override
  final Widget? badge;

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
    Key? key,
    Widget? icon,
    String? label,
    Widget? badge,
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

/// Chain sugar for merging a [CoreNavigationBarStyle] patch into
/// [NavigationBarItem.navigationBarStyle] without hand-reconstructing every
/// field. Mirrors the Web `NavigationBarItem.withStyle` extension so both
/// platforms read identically.
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
/// own resolver call — or has no use for them: only the bar has a row whose
/// fill-or-scroll decision needs the badge's width, and a place in it the
/// glass selection tracks.
@immutable
class _NavigationItemComposition {
  const _NavigationItemComposition({
    required this.resolved,
    required this.index,
    this.onRowEndBadgeWidth,
    this.captionFolded,
  });

  /// The bar's chrome, resolved where the bar sits — the destination draws
  /// the same values the bar estimated its row with.
  final ResolvedNavigationBar resolved;

  /// The destination's place among the bar's destinations.
  final int index;

  /// Reports the laid-out width of the row-end badge, for the bar's
  /// fill-or-scroll decision. `null` where no such decision is made.
  final ValueChanged<double>? onRowEndBadgeWidth;

  /// Whether the destination's caption is folded away — the bar is compact
  /// (`NavigationBar.compact`). `null` in a bar with no compact form, whose
  /// destinations keep the caption out of a fold altogether.
  ///
  /// A folded caption is not a hidden one: the destination stays the one it
  /// was — the same subtree, no tooltip standing in for the caption — and
  /// only what it draws changes, so a bar can fold and unfold on every
  /// scroll without its destinations losing their hover or focus.
  final bool? captionFolded;
}

/// Folds a destination's caption away and back: its length along the stack
/// and its opacity go to nothing together, and the gap that separates it
/// from the icon goes with it — [gap] is inside the fold, so a folded
/// caption leaves no room behind.
///
/// At rest the fold is the caption's own size plus the gap, which is what
/// the stack's spacing gives a caption outside a fold.
class _CaptionFold extends StatelessWidget {
  const _CaptionFold({
    required this.folded,
    required this.gap,
    required this.alignment,
    required this.stacked,
    required this.duration,
    required this.child,
  });

  final bool folded;

  /// The inset on the side of the caption that faces the icon.
  final EdgeInsetsGeometry gap;

  /// The side of the fold the caption holds to while it folds — the icon's,
  /// so the caption closes toward the glyph it names.
  final AlignmentGeometry alignment;

  /// Whether the caption stacks with the icon (folds its height) rather
  /// than sitting beside it (folds its width).
  final bool stacked;

  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curve = CoreEasing.move.toValue();

    return ClipRect(
      child: AnimatedAlign(
        alignment: alignment,
        widthFactor: stacked ? 1 : (folded ? 0 : 1),
        heightFactor: stacked ? (folded ? 0 : 1) : 1,
        duration: duration,
        curve: curve,
        child: AnimatedOpacity(
          opacity: folded ? 0 : 1,
          duration: duration,
          curve: curve,
          child: Padding(padding: gap, child: child),
        ),
      ),
    );
  }
}

class _NavigationBarItemState extends State<NavigationBarItem> {
  /// Whether the pointer is over the item.
  bool _hovered = false;

  /// Whether the item holds keyboard focus.
  bool _focused = false;

  /// Whether the item is being held down.
  bool _pressed = false;

  void _handleHoverChanged(bool hovering) {
    if (_hovered == hovering) return;
    setState(() => _hovered = hovering);
  }

  void _handleFocusChanged(bool focusing) {
    if (_focused == focusing) return;
    setState(() => _focused = focusing);
  }

  void _handlePressedChanged(bool pressing) {
    if (_pressed == pressing) return;
    setState(() => _pressed = pressing);
  }

  Widget _buildLabel(TextStyle labelStyle) {
    final text = Text(
      widget.label ?? '',
      style: labelStyle,
      textAlign: .center,
      overflow: switch (widget.overflow) {
        .clip => .clip,
        .ellipsis => .ellipsis,
        .none => .visible,
      },
      maxLines: 1,
    );
    // The destination states its name once, on its own node (see
    // `build`); the visible label would otherwise say it a second time.
    return ExcludeSemantics(
      child: widget.overflow == .clip ? ClipRect(child: text) : text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final composition = widget._composition;
    final resolved =
        composition?.resolved ??
        resolveNavigationBar(
          context,
          mode: widget.mode,
          variant: widget.variant,
          indicator: widget.indicator,
          navigationBarStyle: widget.navigationBarStyle,
        );
    final labelPosition =
        widget.labelPosition ?? widget.mode.defaultLabelPosition;
    final enabled = widget.enabled ?? widget.onPressed != null;
    final disabled = !enabled;
    // Disabled outranks the selection's behaviour: a disabled item states no
    // selection and answers no pointer. Its selection mark stays, dimmed
    // (`disabledSelected` below), so the label shows as a selected one would.
    final selected = enabled && widget.selected;
    // Against the default the resolved chrome was drawn for: a destination
    // in the floating glass rail hides its caption unless the caller states
    // a label mode. The bar that composes this item reads the same answer.
    final showLabel =
        (widget.labelMode ??
                widget.mode.defaultLabelModeFor(
                  floatingGlass: resolved.floatingGlass,
                ))
            .showsLabel(selected: widget.selected);
    final onTap = enabled ? widget.onPressed : null;
    // Whether this destination carries the selection-mark row above its
    // content — the `selectionMark` asks for one and the label stacks with
    // the icon ([CoreNavigationSelectionMark.marksAt]).
    final marked = widget.selectionMark.marksAt(labelPosition);

    // A row — the label beside the icon — paints the selected face behind
    // itself; a stacked destination paints it on the pill around its icon.
    final row = labelPosition.isHorizontal;
    final stacked = !row;
    final selectionScope = context
        .dependOnInheritedWidgetOfExactType<_NavigationSelectionScope>();
    final lensPosition = selectionScope?.lensPosition;
    final index = composition?.index;
    final visuallySelected =
        !disabled &&
        (lensPosition == null || index == null
            ? selected
            : lensPosition.round() == index);
    // Selected and disabled: the selection mark stays, dimmed — the tile in
    // the disabled area tone, the label in the disabled tone at the selected
    // weight. Outside the glass lens, which draws the selection itself.
    final disabledSelected =
        disabled && widget.selected && selectionScope == null;
    final Color backgroundColor;
    final TextStyle labelStyle;
    if (disabledSelected) {
      backgroundColor = resolved.disabledSelectedBackgroundColor;
      labelStyle = resolved.disabledSelectedLabelTextStyle;
    } else if (disabled) {
      backgroundColor = resolved.idleBackgroundColor;
      labelStyle = resolved.disabledLabelTextStyle;
    } else if (visuallySelected && selectionScope != null) {
      // The glass lens draws the selection; the tile stays clear.
      backgroundColor = resolved.idleBackgroundColor;
      labelStyle = resolved.selectedLabelTextStyle;
    } else if (visuallySelected) {
      // The state layer is laid over the selection, not in place of it.
      backgroundColor = _pressed
          ? resolved.selectedPressedBackgroundColor
          : _focused
          ? resolved.selectedFocusBackgroundColor
          : _hovered
          ? resolved.selectedHoverBackgroundColor
          : resolved.selectedBackgroundColor;
      labelStyle = row
          ? resolved.selectedRowLabelTextStyle
          : resolved.selectedLabelTextStyle;
    } else if (lensPosition != null) {
      backgroundColor = resolved.idleBackgroundColor;
      labelStyle = resolved.labelTextStyle;
    } else if (_pressed) {
      backgroundColor = resolved.pressedBackgroundColor;
      labelStyle = resolved.labelTextStyle;
    } else if (_focused) {
      backgroundColor = resolved.focusBackgroundColor;
      labelStyle = resolved.labelTextStyle;
    } else if (_hovered) {
      backgroundColor = resolved.hoverBackgroundColor;
      labelStyle = resolved.hoverLabelTextStyle;
    } else {
      backgroundColor = resolved.idleBackgroundColor;
      labelStyle = resolved.labelTextStyle;
    }

    final icon = widget.icon;
    final badge = widget.badge;
    final label = widget.label;
    final hasLabel = label != null && label.isNotEmpty;
    final renderLabel = hasLabel && showLabel;
    // Where a badge sits follows the layout mode: a sidebar row carries it at
    // the row's trailing end, the bar and the rail over the icon's top-end
    // corner (through the composed `Indicator`). An icon-less bar or rail
    // destination has no corner to hang it on, so it follows the label like a
    // sidebar row does.
    final rowEndBadge =
        badge != null && widget.mode.badgeAtRowEnd(hasIcon: icon != null)
        ? badge
        : null;
    final badgeAtRowEnd = rowEndBadge != null;

    // A stacked destination keeps its icon in a box of its own, so the
    // destinations stay the same width whichever one is selected — the
    // selected face is the whole tile, not this box.
    //
    // An icon-only stacked destination paints a shorter box than a labelled
    // one; what accepts a pointer stays `touchTargetSize` (below).
    //
    // A folded caption is still this destination's caption: the destination
    // keeps the minimum it has with one, so folding moves nothing but the
    // caption — not the constraints, not the chrome picked for them.
    final captionFolded = composition?.captionFolded;
    final foldsCaption = renderLabel && icon != null && captionFolded != null;
    final iconOnly = stacked && icon != null && !renderLabel;
    final hoverForeground = !disabled && !visuallySelected && _hovered
        ? resolved.hoverForegroundColor
        : null;

    Widget? iconWidget;
    if (icon != null) {
      iconWidget = IconTheme.merge(
        // Glass follows selection tint unless the icon has an explicit style.
        // Disabled is the one state the resting icon follows.
        data: IconThemeData(
          size: resolved.iconSize,
          color: disabled
              ? resolved.disabledIconColor
              : visuallySelected
              ? resolved.isGlass
                    ? (resolved.selectedIconColor ??
                          resolved.selectedForegroundColor)
                    : resolved.selectedIconTint
              : hoverForeground ?? resolved.iconColor,
        ),
        child: icon,
      );
      if (badge != null && !badgeAtRowEnd) {
        iconWidget = Indicator(
          indicatorStyle: resolved.badgeIndicatorStyle,
          item: badge,
          child: iconWidget,
        );
      } else if (badge == null && widget.showDot) {
        iconWidget = Indicator(
          indicatorStyle: resolved.notificationDotIndicatorStyle,
          item: ExcludeSemantics(
            child: Badge(
              form: CoreBadgeForm.dot,
              badgeStyle: resolved.notificationDotStyle,
            ),
          ),
          child: iconWidget,
        );
      }
      if (stacked) {
        iconWidget = Padding(
          padding: resolved.iconAnchorPadding,
          child: iconWidget,
        );
      }
    }

    // Icon + label inner layout. In a bar that can turn compact the caption
    // sits in a fold that carries the gap to the icon, so the stack itself
    // spaces nothing.
    final (
      EdgeInsetsGeometry captionGap,
      AlignmentGeometry captionAlignment,
    ) = switch (labelPosition) {
      .bottom => (
        EdgeInsets.only(top: resolved.labelSpacing),
        Alignment.topCenter,
      ),
      .top => (
        EdgeInsets.only(bottom: resolved.labelSpacing),
        Alignment.bottomCenter,
      ),
      .end => (
        EdgeInsetsDirectional.only(start: resolved.labelSpacing),
        AlignmentDirectional.centerStart,
      ),
      .start => (
        EdgeInsetsDirectional.only(end: resolved.labelSpacing),
        AlignmentDirectional.centerEnd,
      ),
    };
    final innerChildren = <Widget>[
      ?iconWidget,
      if (renderLabel)
        if (foldsCaption)
          Flexible(
            child: _CaptionFold(
              folded: captionFolded,
              gap: captionGap,
              alignment: captionAlignment,
              stacked: stacked,
              duration: resolved.compactDuration,
              child: _buildLabel(labelStyle),
            ),
          )
        else if (icon != null)
          Flexible(child: _buildLabel(labelStyle))
        else
          _buildLabel(labelStyle),
    ];
    final innerSpacing = foldsCaption ? 0.0 : resolved.labelSpacing;

    final Widget inner;
    if (innerChildren.length == 1) {
      inner = innerChildren.first;
    } else if (labelPosition.isHorizontal) {
      final ordered = labelPosition == .start
          ? innerChildren.reversed.toList()
          : innerChildren;
      inner = Row(
        mainAxisAlignment: .center,
        mainAxisSize: .min,
        spacing: innerSpacing,
        children: ordered,
      );
    } else {
      final ordered = labelPosition == .top
          ? innerChildren.reversed.toList()
          : innerChildren;
      inner = Column(
        mainAxisAlignment: .center,
        mainAxisSize: .min,
        spacing: innerSpacing,
        children: ordered,
      );
    }

    // The selection mark sits above the content. Every marked destination
    // keeps the mark's room so the labels stay level across the bar; only
    // the selected one shows the dot, fading on the selection's own clock —
    // dimmed when the selected destination is disabled.
    // Decorative: the selection is already the destination's semantics.
    final markedInner = marked
        ? Column(
            mainAxisSize: .min,
            children: [
              ExcludeSemantics(
                child: AnimatedOpacity(
                  opacity: visuallySelected || disabledSelected ? 1 : 0,
                  duration: resolved.duration,
                  curve: CoreEasing.move.toValue(),
                  child: Badge(
                    form: CoreBadgeForm.dot,
                    badgeStyle: disabledSelected
                        ? resolved.disabledSelectionMarkStyle
                        : resolved.selectionMarkStyle,
                  ),
                ),
              ),
              Gap(gapStyle: resolved.selectionMarkGapStyle),
              inner,
            ],
          )
        : inner;

    final alignment = widget.mode.isSidebar
        ? AlignmentDirectional.centerStart
        : Alignment.center;

    // A row-end badge takes the far end of the row: the icon + label group
    // keeps the start edge and gives up its width to the badge before the
    // badge would leave the row. That needs a row with room to share out. A
    // row on an unbounded main axis has none — the group takes its natural
    // width and the badge follows it. Inside the bar that is the scrolling
    // branch, which says so through `_NavigationRowExtent`; an item placed
    // on its own learns it from the width it is given.
    final group = Align(
      alignment: alignment,
      heightFactor: 1,
      child: markedInner,
    );
    final reportBadgeWidth = composition?.onRowEndBadgeWidth;
    Widget rowEndBody(Widget badge, {required bool unboundedRow}) => Row(
      mainAxisSize: unboundedRow ? .min : .max,
      spacing: resolved.labelSpacing,
      children: [
        if (unboundedRow) Flexible(child: group) else Expanded(child: group),
        if (reportBadgeWidth == null)
          badge
        else
          _RowEndBadgeWidth(onWidth: reportBadgeWidth, child: badge),
      ],
    );
    final Widget body;
    if (rowEndBadge == null) {
      body = markedInner;
    } else if (composition != null) {
      body = rowEndBody(
        rowEndBadge,
        unboundedRow: _NavigationRowExtent.unboundedOf(context),
      );
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) => rowEndBody(
          rowEndBadge,
          unboundedRow: !constraints.hasBoundedWidth,
        ),
      );
    }

    final content = AnimatedContainer(
      // A duration change alone does not stop an already running implicit
      // animation. Retire it when accessibility disables motion mid-gesture.
      key: ValueKey(resolved.duration == Duration.zero),
      padding: resolved.itemPadding,
      constraints: iconOnly
          ? BoxConstraints(
              minWidth: resolved.iconOnlyItemMinWidth,
              minHeight: resolved.iconOnlyItemMinHeight,
            )
          : BoxConstraints(minHeight: resolved.itemMinHeight),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: resolved.itemRadius,
      ),
      curve: CoreEasing.move.toValue(),
      duration: resolved.duration,
      // The row is as tall as its content (and `itemMinHeight`), not as tall
      // as the room it is given: a destination placed on its own in a box
      // with height to spare must not grow a full-height hover target. Inside
      // the bar the height is already pinned (the bar's stretched row) or
      // unbounded (the vertical modes), where this reads the same as a plain
      // alignment.
      child: Align(
        alignment: alignment,
        heightFactor: 1,
        child: selectionScope == null || index == null
            ? body
            : AnimatedScale(
                scale:
                    disabled ||
                        resolved.duration == Duration.zero ||
                        lensPosition == null ||
                        selectionScope.opticalLens
                    ? 1
                    : 1 +
                          .12 *
                              (1 - (lensPosition - index).abs()).clamp(
                                0.0,
                                1.0,
                              ),
                duration:
                    lensPosition != null || resolved.duration == Duration.zero
                    ? Duration.zero
                    : const Duration(milliseconds: CoreDuration.fast),
                curve: Curves.easeOutCubic,
                child: body,
              ),
      ),
    );

    // Composition: the destination's tap / keyboard activation (Enter /
    // Space) / cursor / focus ring / press feedback / selection-exclusion
    // all flow through the unified `Clickable` — no hand-rolled
    // `MouseRegion` + `GestureDetector` + `SelectionContainer`. `onHover`
    // feeds this item's own hover flag so the per-state chrome (hover fill /
    // idle hue-held alpha-0) is SELECTED here, not re-derived. A disabled
    // destination (`onTap == null`) passes `enabled: false`, so the
    // Clickable applies its disabled cursor.
    //
    // One destination is one semantics node with its name said once. The
    // Clickable already states the button role, the enabled state and —
    // through `semanticsSelected` — the committed selection; stating any of
    // those flags again on an inner node makes the two configurations
    // incompatible, so the tree splits into a button inside a button. The
    // inner node carries only the name: the label (also when it is hidden,
    // so an icon-only destination is still named), followed by whatever the
    // badge says, so the count is heard with the destination it belongs to.
    // `MergeSemantics` folds a caller badge's own nodes into that one node.
    final clickable = MergeSemantics(
      child: Clickable(
        // The shared glass lens owns press deformation. Shrinking each item on
        // a second clock fights the magnification and survives gesture release.
        enableFeedback: selectionScope == null,
        onPressed: onTap,
        onHover: _handleHoverChanged,
        onFocus: _handleFocusChanged,
        // `Clickable` reports the press as edges, not as a flag — down, then
        // up or cancel. The ramp needs the flag, so the two edges are folded
        // into one here.
        onTapDown: (_) => _handlePressedChanged(true),
        onTapUp: (_) => _handlePressedChanged(false),
        onTapCancel: () => _handlePressedChanged(false),
        enabled: onTap != null,
        semanticsSelected: selected,
        clickableStyle: resolved.clickableStyle,
        child: Semantics(label: label, child: content),
      ),
    );
    // Show a tooltip when the label is hidden but tooltip text exists. It
    // wraps the destination rather than sitting inside it (as on Web): the
    // tooltip's own semantics container would otherwise split the
    // destination's content off into a second node.
    final tooltip = widget.tooltip ?? (showLabel ? null : label);
    final destination = tooltip == null || tooltip.isEmpty || renderLabel
        ? clickable
        : Tooltip(
            message: tooltip,
            // Beside the destination in a column, above it in a row.
            position: widget.mode.tooltipPosition,
            // A tooltip that only restates the hidden label is already the
            // destination's name; announcing it again as a hint is the
            // double reading this destination exists to avoid. Handing the
            // same text in as the bubble content draws the identical bubble
            // without the semantic hint. A caller-authored `tooltip` that
            // differs from the label is new information and keeps its hint.
            tooltipChild: tooltip == label ? Text(tooltip) : null,
            child: clickable,
          );
    // A stacked destination — the bar's and the rail's — accepts a pointer
    // across at least `touchTargetSize` on both axes, whatever it paints.
    // Hit testing only: layout and paint keep the drawn size. Outermost, so
    // no box in between (the tooltip's) turns the pointer away at the drawn
    // edge. A row (the label beside the icon) keeps its own box, which its
    // neighbours sit close to.
    return stacked
        ? TouchTarget(minimum: resolved.touchTargetSize, child: destination)
        : destination;
  }
}
