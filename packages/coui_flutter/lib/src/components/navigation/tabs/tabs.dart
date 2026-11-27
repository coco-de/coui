import 'package:coui_flutter/coui_flutter.dart';

/// A unified cross-platform tab bar.
///
/// `Tabs` renders a horizontal row of selectable tab buttons. Two
/// visual variants are supported:
///
/// - [CoreTabVariant.pill] — a rounded surface container with a filled
///   "pill" indicator behind the active tab.
/// - [CoreTabVariant.underline] — a flat row separated from content by
///   a bottom border, with an underline indicator under the active
///   tab.
///
/// Selecting a tab invokes [onChanged] with the new index. Horizontal
/// swipe gestures also switch tabs when [swipeable] is `true`.
/// Set [scrollable] to retain full labels in a horizontal viewport;
/// in that mode drags scroll instead of selecting, and [expand] is ignored.
/// A tab whose item carries [CoreTabItem.onClose] draws a close × after
/// its label and badge; pressing it calls `onClose` and never [onChanged].
///
/// Data-driven: pass a [tabs] list of [CoreTabItem]s and the current
/// [selectedIndex], or use the [Tabs.labels] shortcut. Every tab-bar
/// chrome / dimensional override flows through the single [tabsStyle]
/// field — see [CoreTabsStyle] for the merge chain.
///
/// ```dart
/// Tabs(
///   tabs: const [
///     CoreTabItem(label: 'Account'),
///     CoreTabItem(label: 'Password'),
///   ],
///   selectedIndex: index,
///   onChanged: (i) => setState(() => index = i),
/// )
/// ```
///
/// surface:behind — whatever the tab bar lands on. The `pill` variant
/// fills its own box (a parent surface, or the page, shows through until
/// a caller opts one in via [tabsStyle]); the `underline` variant paints
/// no fill at all, only a bottom rule.
///
/// surface:content — a face in the content layer alongside the panes it
/// switches between — no sticky, fixed, or overlay mount on either
/// platform (re-verified: an identical segmented rail — `filter` — was
/// already content, and this one had zero overlay evidence in its own
/// source).
class Tabs extends StatelessWidget implements CoreTabsContract<Widget> {
  /// Creates a [Tabs] from a list of [CoreTabItem]s.
  const Tabs({
    required this.tabs,
    required this.selectedIndex,
    this.onChanged,
    this.variant = CoreTabVariant.defaultVariant,
    this.size = CoreTabsSize.defaultSize,
    this.swipeable = true,
    this.expand = false,
    this.scrollable = false,
    this.tabsStyle,
    super.key,
  });

  /// Creates a [Tabs] from a list of plain string [labels].
  ///
  /// Each label becomes an enabled [CoreTabItem].
  Tabs.labels({
    required List<String> labels,
    required this.selectedIndex,
    this.onChanged,
    this.variant = CoreTabVariant.defaultVariant,
    this.size = CoreTabsSize.defaultSize,
    this.swipeable = true,
    this.expand = false,
    this.scrollable = false,
    this.tabsStyle,
    super.key,
  }) : tabs = [for (final label in labels) CoreTabItem<Widget>(label: label)];

  @override
  final List<CoreTabItem<Widget>> tabs;

  @override
  final int selectedIndex;

  @override
  final CoreValueChanged<int>? onChanged;

  @override
  final CoreTabVariant variant;

  @override
  final CoreTabsSize size;

  @override
  final CoreTabsStyle? tabsStyle;

  @override
  final bool swipeable;

  @override
  final bool expand;

  @override
  final bool scrollable;

  /// Returns a copy of this [Tabs] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Tabs copyWith({
    Key? key,
    CoreValueChanged<int>? onChanged,
    List<CoreTabItem<Widget>>? tabs,
    int? selectedIndex,
    CoreTabVariant? variant,
    CoreTabsSize? size,
    bool? swipeable,
    bool? expand,
    bool? scrollable,
    CoreTabsStyle? tabsStyle,
  }) {
    return Tabs(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      tabs: tabs ?? this.tabs,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      swipeable: swipeable ?? this.swipeable,
      expand: expand ?? this.expand,
      scrollable: scrollable ?? this.scrollable,
      tabsStyle: tabsStyle ?? this.tabsStyle,
    );
  }

  void _handleHorizontalDragEnd(
    BuildContext context,
    DragEndDetails details,
    double swipeSensitivity,
  ) {
    final callback = onChanged;
    if (callback == null) return;
    final direction = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    final velocity = (details.primaryVelocity ?? 0) * direction;
    if (velocity.abs() <= swipeSensitivity) return;
    final step = velocity < 0 ? 1 : -1;
    for (
      var next = selectedIndex + step;
      next >= 0 && next < tabs.length;
      next += step
    ) {
      if (!tabs[next].enabled) continue;
      callback(next);
      return;
    }
  }

  /// The tab's content — the coloured [label], and after it the item's
  /// caller-supplied `badge` behind a 1-off `Gap`. Shared by both
  /// variants so the badge sits at the same distance in each. A `Badge`
  /// paints its own colours, so it deliberately sits outside the
  /// `DefaultTextStyle.merge` that tints the label; an item without a
  /// badge composes neither the `Gap` nor the slot (a spacer with no
  /// sibling would widen the tab for nothing). Mirrors the Web
  /// `_buildTab`, whose span carries `Text` → `Gap` → badge.
  static Widget _labelWithBadge(
    CoreTabItem<Widget> item,
    Widget label,
    CoreGapStyle labelBadgeGapStyle,
  ) {
    return Row(
      mainAxisSize: .min,
      children: [
        label,
        if (item.badge != null) Gap(gapStyle: labelBadgeGapStyle),
        ?item.badge,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTabs(
      context,
      variant: variant,
      size: size,
      tabsStyle: tabsStyle,
    );

    final tabButtons = <Widget>[
      for (var i = 0; i < tabs.length; i++)
        _TabButton(
          scrollable: scrollable,
          item: tabs[i],
          index: i,
          isActive: i == selectedIndex,
          variant: variant,
          resolved: resolved,
          onSelected: onChanged == null ? null : () => onChanged!(i),
          labelWithBadge: _labelWithBadge,
        ),
    ];

    final fill = expand && !scrollable;
    final rowChildren = fill
        ? [for (final button in tabButtons) Expanded(child: button)]
        : tabButtons;

    // `RenderFlex` bills spacing as `spacing * (childCount - 1)`, so an
    // empty tab strip reports a *negative* intrinsic — illegal, and
    // asserted on under `debugCheckIntrinsicSizes`. There is no gap
    // between fewer than two siblings, so there is nothing to bill for;
    // this is arithmetic, not a design decision.
    final row = IntrinsicHeight(
      child: Row(
        mainAxisSize: fill ? .max : .min,
        crossAxisAlignment: .stretch,
        spacing: rowChildren.length > 1 ? resolved.tabSpacing : 0.0,
        children: rowChildren,
      ),
    );

    final strip = scrollable
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: row,
          )
        : row;

    Widget tabBar;
    // The shape the cast is knocked out of — the underline branch draws a
    // bottom rule rather than a box, so it has no radius to match.
    BorderRadius castRadius;
    if (variant == .underline) {
      castRadius = .zero;
      // The rule is the tab-bar box's, not the row's: it spans the whole
      // width the parent offers even when the tabs hug (`expand: false`)
      // — the same shape as Material's `TabBar`, and the Web twin's
      // `w-full` on the ruled `role="tablist"` root. The row keeps
      // `mainAxisSize: .min` and sits at the reading-direction start of
      // the ruled box; `Align` hands it loose constraints so it can still
      // hug, and `heightFactor: 1` keeps the box hugging the row's height
      // (a bare `Align` would stretch to any bounded height and drop the
      // rule to the bottom of it). The expanded row already fills, so it
      // is wired bare.
      tabBar = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: .new(
              color: resolved.borderColor ?? const Color(0x00000000),
              width: resolved.borderWidth,
            ),
          ),
        ),
        child: fill
            ? strip
            : Align(
                alignment: AlignmentDirectional.centerStart,
                heightFactor: 1,
                child: strip,
              ),
      );
    } else {
      castRadius = resolved.containerRadius;
      tabBar = DecoratedBox(
        decoration: BoxDecoration(
          color: resolved.backgroundColor,
          borderRadius: resolved.containerRadius,
        ),
        child: Padding(
          padding: resolved.tabBarPadding,
          child: strip,
        ),
      );

      // The resolver hands these over only when the `pill` container
      // states a fill (`resolveTabs` gates `surfaceBlur`/`surfaceSheen`
      // on it), so a bar with no box to blur behind pays for no backdrop
      // pass.
      final effectiveBlur = resolved.surfaceBlur;
      if ((effectiveBlur != null && effectiveBlur > 0) ||
          resolved.surfaceSheen != null) {
        tabBar = SurfaceBlur(
          borderRadius: resolved.containerRadius,
          surfaceBlur: effectiveBlur,
          surfaceSaturation: resolved.surfaceSaturation,
          surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
          surfaceSheen: resolved.surfaceSheen,
          // The active material's bend — every surface that draws the
          // material draws all of it (mirrors `Drawer`/`Table`).
          refraction: Theme.of(context).surfaceRefraction,
          child: tabBar,
        );
      }
    }

    // Painted outside the box rather than behind it, and lifted out of
    // both branches rather than added to each. The underline branch
    // states no fill at all, so a cast drawn behind it has nothing
    // painting over it; per-branch wiring is also the shape that already
    // went wrong here once, when the cast reached underline and left the
    // default variant flat.
    tabBar = InjectedCast(
      shadows: resolved.boxShadow,
      borderRadius: castRadius,
      child: tabBar,
    );

    if (swipeable && !scrollable && onChanged != null) {
      tabBar = GestureDetector(
        onHorizontalDragEnd: (details) => _handleHorizontalDragEnd(
          context,
          details,
          resolved.swipeSensitivity,
        ),
        child: tabBar,
      );
    }

    return Semantics(container: true, child: tabBar);
  }
}

/// One tab button — a `Clickable` composing the label (+ badge) content,
/// the state-layer wash, and (`underline` only) the active indicator. An
/// item that carries `onClose` puts the box around the select `Clickable`
/// and a close × instead, and reads the box's hover / press itself.
///
/// Split out from `Tabs.build` because the hover / pressed wash needs
/// per-item state — `Clickable(onHover:, onPressedChange:)` is the
/// DETECTION half of the state-layer axis (`widget/interaction.md`
/// "hover-list-item"), and `Tabs` itself stays a `StatelessWidget` so
/// this is the only place that state lives.
class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.scrollable,
    required this.item,
    required this.index,
    required this.isActive,
    required this.variant,
    required this.resolved,
    required this.onSelected,
    required this.labelWithBadge,
  });

  final bool scrollable;
  final CoreTabItem<Widget> item;
  final int index;
  final bool isActive;
  final CoreTabVariant variant;
  final ResolvedTabs resolved;
  final VoidCallback? onSelected;
  final Widget Function(CoreTabItem<Widget>, Widget, CoreGapStyle)
  labelWithBadge;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _hovered = false;
  bool _pressed = false;

  void _handleRevealOnFocus(bool focused) {
    if (focused && widget.scrollable) {
      Scrollable.ensureVisible(context);
    }
  }

  bool get _isEnabled => widget.item.enabled && widget.onSelected != null;

  /// The item's own foreground/indicator base — `on-surface` 8%/16% state
  /// layer alpha-blended over it. `Color.alphaBlend` over `transparent`
  /// hands back the overlay unchanged, so a tab with no active fill still
  /// shows a plain wash — no `base == null` branch needed.
  Color _withStateLayer(Color? base) {
    if (!_isEnabled) return base ?? const Color(0x00000000);
    final overlay = _pressed
        ? widget.resolved.pressedStateLayerColor
        : _hovered
        ? widget.resolved.hoverStateLayerColor
        : null;
    if (overlay == null) return base ?? const Color(0x00000000);
    return Color.alphaBlend(overlay, base ?? const Color(0x00000000));
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.resolved;
    final item = widget.item;
    final isActive = widget.isActive;
    final disabled = !_isEnabled;

    final contentColor = disabled
        ? resolved.disabledContentColor
        : isActive
        ? resolved.activeContentColor
        : resolved.inactiveContentColor;

    final label = DefaultTextStyle.merge(
      style:
          (isActive
                  ? resolved.activeContentTextStyle
                  : resolved.inactiveContentTextStyle)
              .copyWith(color: contentColor),
      child: Text(item.label),
    );
    final content = widget.labelWithBadge(
      item,
      label,
      resolved.labelBadgeGapStyle,
    );

    final decoration = widget.variant == .underline
        ? BoxDecoration(color: _withStateLayer(null))
        : BoxDecoration(
            // A disabled selected pill keeps its indicator as an area.
            color: _withStateLayer(
              isActive
                  ? (disabled
                        ? resolved.disabledIndicatorColor
                        : resolved.activeIndicatorColor)
                  : null,
            ),
            borderRadius: resolved.activeIndicatorRadius,
          );
    final foregroundDecoration = widget.variant == .underline
        ? BoxDecoration(
            border: Border(
              bottom: .new(
                // Visible only when selected — a disabled selected tab
                // still has to say which one is current.
                color: isActive
                    ? (disabled
                          ? resolved.disabledIndicatorColor
                          : resolved.activeIndicatorColor)
                    : resolved.inactiveIndicatorColor,
                width: resolved.activeIndicatorThickness,
              ),
            ),
          )
        : null;

    final selectContent = Semantics(
      enabled: _isEnabled,
      selected: isActive,
      button: true,
      child: content,
    );
    // The tab's box: the indicator, the state-layer wash, the padding and
    // the height floor.
    Widget tabBox(Widget child) => AnimatedContainer(
      alignment: Alignment.center,
      padding: resolved.tabPadding,
      decoration: decoration,
      // Container adds a decoration border to its padding. The underline
      // paints at the edge while content stays centered in the full box.
      foregroundDecoration: foregroundDecoration,
      // A floor, not a clip — `itemHeight` already carries the text
      // scaler (#4626), and a fixed height silently cuts the label off
      // at large OS font sizes.
      constraints: BoxConstraints(minHeight: resolved.itemHeight),
      curve: CoreEasing.move.toValue(),
      duration: resolved.indicatorTransitionDuration,
      child: child,
    );

    final onClose = item.onClose;
    if (onClose == null) {
      return Clickable(
        onFocus: _handleRevealOnFocus,
        onPressed: widget.onSelected,
        enabled: _isEnabled,
        clickableStyle: resolved.clickableStyle,
        onHover: (h) => setState(() => _hovered = h),
        onPressedChange: (p) => setState(() => _pressed = p),
        child: tabBox(selectContent),
      );
    }

    // A closable tab: the close × sits beside the select region, not
    // inside it, so a click on it never fires `onSelected` — `TabPane`'s
    // rule for the same item field. The box then holds both, so its hover
    // and press are read off the whole box, the way the Web twin's
    // `hover:` / `active:` on the box read them: a `MouseRegion` and a
    // `Listener` detect them here, where the select `Clickable` covers
    // only the label. The select region stretches to the box's height
    // and centres the label; the close × keeps its own size, centred.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: tabBox(
          Row(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Clickable(
                onFocus: _handleRevealOnFocus,
                onPressed: widget.onSelected,
                enabled: _isEnabled,
                clickableStyle: resolved.clickableStyle,
                child: Center(child: selectContent),
              ),
              Gap(gapStyle: resolved.labelBadgeGapStyle),
              Center(
                // The glyph is an icon, so the button has no text to name
                // it; the Web twin emits the same string as `aria-label`.
                child: Semantics(
                  button: true,
                  label: CoUILocalizations.of(context).buttonClose,
                  child: Button(
                    onPressed: onClose,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreTabsStyle] patch into [Tabs.tabsStyle]
/// without hand-reconstructing every field. Mirrors the Web
/// `Tabs.withStyle` extension so both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTabsStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreColors` primitive — the
/// getter *name* is the token name, so `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreTabsStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Tabs(tabs: const [], selectedIndex: 0).primary
/// ```
extension TabsStyleChain on Tabs {
  /// Sets the border color.
  Tabs borderColor(CoreColor value) =>
      withStyle(CoreTabsStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  Tabs borderWidth(double value) =>
      withStyle(CoreTabsStyle(borderWidth: value));

  /// Sets the background paint and preserves the other style fields.
  Tabs backgroundColor(CoreColor value) =>
      withStyle(CoreTabsStyle(backgroundColor: value));

  /// Returns a copy of this [Tabs] with [patch] merged into [tabsStyle]
  /// (patch fields win on conflict).
  Tabs withStyle(CoreTabsStyle patch) =>
      copyWith(tabsStyle: (tabsStyle ?? const CoreTabsStyle()).merge(patch));

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Tabs get primary => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Tabs get secondary => withStyle(
    const CoreTabsStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Tabs get tertiary => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Tabs get surface => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Tabs get surfaceContainer => withStyle(
    const CoreTabsStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Tabs get error => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Tabs get success => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Tabs get warning => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Tabs get info => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Tabs get outline => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Tabs get transparent =>
      withStyle(const CoreTabsStyle(backgroundColor: .transparent));
}
