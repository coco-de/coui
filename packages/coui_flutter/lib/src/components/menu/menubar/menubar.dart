import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';

/// A unified cross-platform desktop-style application menubar.
///
/// `Menubar` renders a horizontal row of top-level [CoreMenubarMenu]s.
/// Activating a menu reveals its [CoreMenubarEntry] list as a dropdown
/// panel anchored beneath its trigger. Selecting an enabled action
/// entry invokes its `onSelect` callback and closes the panel; clicking
/// outside the panel or pressing Escape also closes it.
///
/// Once a menu is open the bar tracks the pointer: hovering a sibling
/// trigger switches to that menu without a second click, as desktop
/// menubars do. Hovering the bar while it is closed opens nothing — the
/// first click is what arms it.
///
/// Data-driven: pass a [menus] list of [CoreMenubarMenu]s, each holding
/// a label and a list of `CoreMenubarEntry.action` / `divider` entries.
/// Every chrome / dimensional override flows through the single
/// [menubarStyle] field — see [CoreMenubarStyle] for the merge chain.
///
/// Mirrors Web `Menubar` 1:1 — same parameter names, same semantics.
///
/// The dropdown panel is driven through the shared [PopoverOverlayHandler]
/// engine inline — the same positioning engine `Popover` / `Tooltip` /
/// `HoverCard` drive — anchored beneath the clicked trigger
/// (`bottomStart`) with collision-aware flip at screen edges.
///
/// ```dart
/// Menubar(
///   menus: [
///     CoreMenubarMenu(
///       label: 'File',
///       entries: [
///         CoreMenubarEntry.action(label: 'New', shortcut: 'Ctrl+N'),
///         CoreMenubarEntry.action(label: 'Open'),
///         CoreMenubarEntry.divider(),
///         CoreMenubarEntry.action(label: 'Exit'),
///       ],
///     ),
///     CoreMenubarMenu(
///       label: 'Edit',
///       entries: [
///         CoreMenubarEntry.action(label: 'Cut'),
///         CoreMenubarEntry.action(label: 'Copy'),
///       ],
///     ),
///   ],
/// )
/// ```
///
/// surface:functional — its menus open through the overlay handler over the
/// page the bar sits on.
class Menubar extends StatefulWidget implements CoreMenubarContract {
  /// Creates a [Menubar].
  const Menubar({
    required this.menus,
    this.border = true,
    this.activeIndex,
    this.onActiveIndexChanged,
    this.variant = CoreMenubarVariant.defaultVariant,
    this.menubarStyle,
    super.key,
  });

  @override
  final List<CoreMenubarMenu> menus;

  @override
  final bool border;

  @override
  final int? activeIndex;

  @override
  final void Function(int?)? onActiveIndexChanged;

  @override
  final CoreMenubarStyle? menubarStyle;

  /// The visual variant of the menubar.
  final CoreMenubarVariant variant;

  /// Returns a copy of this [Menubar] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Menubar copyWith({
    Key? key,
    List<CoreMenubarMenu>? menus,
    bool? border,
    int? activeIndex,
    void Function(int?)? onActiveIndexChanged,
    CoreMenubarVariant? variant,
    CoreMenubarStyle? menubarStyle,
  }) {
    return Menubar(
      key: key ?? this.key,
      menus: menus ?? this.menus,
      border: border ?? this.border,
      activeIndex: activeIndex ?? this.activeIndex,
      onActiveIndexChanged: onActiveIndexChanged ?? this.onActiveIndexChanged,
      variant: variant ?? this.variant,
      menubarStyle: menubarStyle ?? this.menubarStyle,
    );
  }

  @override
  State<Menubar> createState() => _MenubarState();
}

class _MenubarState extends State<Menubar> {
  /// Panel anchored beneath the clicked trigger, left edges aligned.
  static const CorePopoverPlacement _placement = .bottomStart;

  /// Shared overlay engine — driven inline like `Popover._PopoverState`.
  static const PopoverOverlayHandler _handler = PopoverOverlayHandler();

  /// `TapRegion` group id linking the bar's triggers to every dropdown
  /// panel this menubar opens — a tap on any trigger counts as "inside"
  /// the open panel's dismissal scope (mirrors the Web menubar's
  /// `containerIds: [bar, panel]`), so a sibling-trigger tap reaches the
  /// trigger and switches the open menu instead of being swallowed as an
  /// outside-tap dismissal. Stable across the menubar's lifetime so all of
  /// its panels share the one group.
  final Object _regionGroupId = Object();

  /// Per-trigger anchor keys so the engine can anchor the panel to the
  /// specific clicked trigger's `RenderBox` (not the whole bar). Rebuilt
  /// immutably (no in-place mutation) while preserving existing keys.
  List<GlobalKey> _triggerKeys = const [];

  /// The currently open panel handle, or `null` when none is open.
  PopoverEntryHandle<void>? _activeEntry;

  /// Index the engine panel is currently showing, or `null` when closed.
  int? _shownIndex;

  /// Internally-tracked open index — used only in uncontrolled mode.
  int? _internalIndex;

  /// The effective open index — widget-controlled when [Menubar.activeIndex] is
  /// non-null, otherwise internally tracked. Mirrors `NavigationMenu`.
  int? get _openIndex => widget.activeIndex ?? _internalIndex;

  void _ensureTriggerKeys() {
    if (_triggerKeys.length == widget.menus.length) return;
    _triggerKeys = [
      for (var i = 0; i < widget.menus.length; i++)
        if (i < _triggerKeys.length) _triggerKeys[i] else GlobalKey(),
    ];
  }

  void _setActiveIndex(int? index) {
    final clamped = (index != null && index >= 0 && index < widget.menus.length)
        ? index
        : null;
    if (_openIndex == clamped) return;
    widget.onActiveIndexChanged?.call(clamped);
    if (widget.activeIndex == null) {
      setState(() => _internalIndex = clamped);
    } else {
      // Controlled mode — rebuild so the highlight reflects the request
      // even before the parent rebuilds.
      setState(() {});
    }
  }

  void _handleMenuToggle(int index) {
    _setActiveIndex(_openIndex == index ? null : index);
  }

  /// Hover-switch — while a menu is **already open**, moving the pointer
  /// onto a sibling trigger switches the open menu with no second click.
  /// This is what desktop menubars (macOS / Windows) and Radix do: the
  /// first click arms the bar, and from then on the bar tracks the
  /// pointer.
  ///
  /// Deliberately does nothing while closed. A menubar that opened on
  /// bare hover would fire every time the pointer crossed the bar on its
  /// way somewhere else — which is why `NavigationMenu` (hover-to-open,
  /// no click needed) and `Menubar` differ here despite sharing the
  /// trigger widget.
  ///
  /// Only hover-IN acts. Hover-OUT must not close, because the pointer
  /// necessarily leaves the trigger to reach the panel hanging beneath
  /// it; closing stays with outside-tap / `Escape` / entry selection.
  /// Re-hovering the open trigger is a no-op — [_setActiveIndex] returns
  /// early on an unchanged index, so the open panel is never torn down
  /// and rebuilt.
  ///
  /// Mouse-only by construction: `Clickable.onHover` is driven by
  /// `FocusableActionDetector.onShowHoverHighlight` (a `MouseRegion`),
  /// which never reports touch. So a tap cannot synthesize a hover that
  /// switches the menu only for the tap's own `_handleMenuToggle` to
  /// toggle it shut. Web has no such guarantee and gates on
  /// `(hover: hover)` instead — same capability, each platform's idiom.
  void _handleTriggerHover(int index, {required bool hovered}) {
    if (!hovered || _openIndex == null) return;
    _setActiveIndex(index);
  }

  /// Closes the open menu — fired by the panel's `Menu.onActivate` (close
  /// first) when an action row is selected; the entry's own `onSelect`
  /// runs after, inside `Menu`.
  void _handleClose() {
    _setActiveIndex(null);
  }

  /// Reconciles the engine panel with the effective [_openIndex] — opens
  /// the panel beneath the open menu's trigger, switches triggers on
  /// index change (close + reopen at the new anchor), and closes when no
  /// menu is open. Covers both interactive and controlled-mode updates.
  void _syncEngine() {
    final desired = _openIndex;
    final target =
        (desired != null && desired >= 0 && desired < widget.menus.length)
        ? desired
        : null;
    if (target == _shownIndex) return;
    // Close the currently shown panel (entry-identity guard in its own
    // whenComplete prevents it from clobbering the freshly opened one).
    _activeEntry?.close();
    if (target != null) {
      _openMenuAt(target);
    }
  }

  void _openMenuAt(int index) {
    final triggerContext = _triggerKeys[index].currentContext;
    if (triggerContext == null) return;
    final resolved = resolveMenubar(
      context,
      variant: widget.variant,
      menubarStyle: widget.menubarStyle,
    );
    // Enter / exit motion chained from the panel `Popup`'s `CorePopupStyle`
    // (single source) so it is user-overridable via
    // `menubarStyle.menuPanelStyle.openAnimationDuration` — parity with Web.
    final panelPopup = resolvePopup(
      context,
      popupStyle: resolved.menuPanelStyle,
    );
    final entry = _handler.show<void>(
      alignment: _placement.toPopoverAlignment(),
      context: triggerContext,
      anchorAlignment: _placement.toAnchorAlignment(),
      dismissDuration: panelPopup.closeAnimationDuration,
      // A menu can have more rows than the viewport has room for; it takes
      // the room and scrolls rather than running off the screen.
      fitViewportHeight: true,
      // Anchored once beneath the trigger; flip resolves at layout.
      follow: false,
      // Non-modal + shared `regionGroupId`: a menubar is a bar of sibling
      // triggers, so it must NOT install a tap-consuming barrier (that
      // would absorb a tap on `Edit` while `File` is open, only dismissing
      // `File`). With `modal: false` the panel dismisses via its own
      // `TapRegion.onTapOutside`, and `regionGroupId` links it to the
      // `TapRegion` wrapping the bar (`build`) so a tap on ANY trigger is
      // "inside" the group → no outside-tap dismissal fires, the tap
      // reaches the trigger, and `_handleMenuToggle` switches (or, for the
      // open trigger, closes — no dismiss-then-reopen race). Mirrors the
      // Web menubar's `containerIds: [bar, panel]` document-listener scope.
      modal: false,
      offset: _placement.toPopoverOffset(resolved.menuOffset),
      regionGroupId: _regionGroupId,
      showDuration: panelPopup.openAnimationDuration,
      // Read lazily: the menus can change (and shrink) under an open panel,
      // and `_syncEngine` closes a panel whose menu is gone only after this
      // frame.
      builder: (_) => index < widget.menus.length
          ? _MenubarPanel(
              menu: widget.menus[index],
              variant: widget.variant,
              menubarStyle: widget.menubarStyle,
              onClose: _handleClose,
            )
          : const SizedBox.shrink(),
    );
    _activeEntry = entry;
    _shownIndex = index;
    unawaited(
      entry.future.whenComplete(() {
        if (!mounted) return;
        // Only act if this panel is still the active one — switching
        // menus already advanced `_activeEntry` to the new panel.
        if (_activeEntry == entry) {
          _activeEntry = null;
          _shownIndex = null;
          // Engine dismissed (outside tap) — clear the open index too.
          if (_openIndex == index) _setActiveIndex(null);
        }
      }),
    );
  }

  Widget _buildTrigger(int index, ResolvedMenubar resolved) {
    final menu = widget.menus[index];
    final isOpen = _openIndex == index;

    // Composed `Button(variant: menubar)` — the variant owns the resting /
    // hover / open (selected) fill, a flicker-free alpha-0 → 1 lerp within
    // the grey hue (resting fill is the hover colour at zero alpha), so no
    // hand-rolled `AnimatedContainer` / transparent-black resting. The open
    // menu's trigger stays highlighted (open ≠ hovered) via an ambient
    // `WidgetStatesData(selected)`. `onPressed` toggles through the
    // UNCHANGED `_handleMenuToggle`, so the close path is preserved: the
    // engine's outside-tap dismissal fires `whenComplete` gated on
    // `_openIndex == index` and `_syncEngine` on `target == _shownIndex`,
    // which together stop a close-then-reopen double-toggle when the open
    // trigger is re-tapped. Focus ring suppressed for parity with the old
    // plain trigger. Chrome (padding / radius) is the Core nested slot
    // `resolved.triggerButtonStyle` — no resolver-side assembly. The open
    // trigger takes `resolved.openTriggerButtonStyle` and the heavier
    // `resolved.openLabelTextStyle` instead.
    return Data.inherit(
      data: WidgetStatesData({if (isOpen) .selected}),
      child: Semantics(
        expanded: isOpen,
        child: Button(
          key: _triggerKeys[index],
          onPressed: () => _handleMenuToggle(index),
          variant: .menubar,
          buttonStyle: isOpen
              ? resolved.openTriggerButtonStyle
              : resolved.triggerButtonStyle,
          disableFocusOutline: true,
          onHover: (hovered) => _handleTriggerHover(index, hovered: hovered),
          child: Text(
            menu.label,
            style: isOpen
                ? resolved.openLabelTextStyle
                : resolved.labelTextStyle,
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant Menubar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final open = _internalIndex;
    if (open != null && open >= widget.menus.length) {
      _internalIndex = null;
    }
    // The open panel is mounted in the app's overlay, outside this subtree:
    // new menus reach it only when it is told to run its builder again.
    if (oldWidget.menus != widget.menus) {
      _activeEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _activeEntry?.dismissImmediately();
    _activeEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureTriggerKeys();
    final resolved = resolveMenubar(
      context,
      variant: widget.variant,
      menubarStyle: widget.menubarStyle,
    );

    // Reconcile the engine panel with the effective open index — covers
    // both interactive (tap toggle) and controlled-mode updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncEngine();
    });

    final triggers = <Widget>[];
    for (var i = 0; i < widget.menus.length; i++) {
      triggers.add(_buildTrigger(i, resolved));
    }

    Widget bar = Row(
      mainAxisSize: .min,
      children: triggers,
    );

    bar = Padding(padding: resolved.barPadding, child: bar);

    if (widget.border) {
      bar = DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: resolved.boxShadow,
          color: resolved.barBackgroundColor,
          border: Border.all(
            color: resolved.barBorderColor,
            width: resolved.barBorderWidth,
          ),
          borderRadius: resolved.barBorderRadius,
        ),
        child: bar,
      );

      // The resolver hands these over only when the bar states a fill
      // (`border: false` never reaches this branch at all), so a
      // borderless bar never stacks a second backdrop pass.
      final effectiveBlur = resolved.surfaceBlur;
      if ((effectiveBlur != null && effectiveBlur > 0) ||
          resolved.surfaceSheen != null) {
        bar = SurfaceBlur(
          borderRadius: resolved.barBorderRadius,
          surfaceBlur: effectiveBlur,
          surfaceSaturation: resolved.surfaceSaturation,
          surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
          surfaceSheen: resolved.surfaceSheen,
          // The active material's bend — every surface that draws the
          // material draws all of it (mirrors `Drawer`/`Table`).
          refraction: resolved.refraction,
          child: bar,
        );
      }
    }

    // The bar shares the open panel's `regionGroupId` so a tap on any
    // trigger counts as "inside" the dropdown's dismissal scope — the tap
    // reaches the trigger (switch / toggle) instead of dismissing the open
    // menu as an outside tap. Mirrors the Web menubar's bar-inside scope.
    return TapRegion(
      groupId: _regionGroupId,
      child: Semantics(
        container: true,
        label: CoUILocalizations.of(context).menubarLabel,
        child: bar,
      ),
    );
  }
}

/// The dropdown panel rendered in the overlay for the open menu.
///
/// Composes the shared [Menu] (Epic #2676 L2-c) — the menubar no longer
/// hand-rolls a `Popup` + per-entry `Button(variant: menu)` / `Separator`.
/// Each [CoreMenubarEntry] maps to a [CoreMenuItem] (`action` →
/// `CoreMenuItem.action`, `divider` → `CoreMenuItem.divider`), and `Menu`
/// owns the whole item-row renderer (panel `Popup`, the
/// `Button(variant: menu)` rows, dividers, shortcuts). The menubar's panel
/// chrome (`resolved.menuPanelStyle`, borderless) flows into `Menu`'s panel
/// slot. `onActivate: onClose` dismisses the open menu first when an action
/// row is selected — the "close then act" order the old
/// `_handleEntrySelected` had (the entry's own `onSelect` runs after, as the
/// converted item's `onPressed`, inside `Menu`).
class _MenubarPanel extends StatelessWidget {
  const _MenubarPanel({
    required this.menu,
    required this.variant,
    required this.menubarStyle,
    required this.onClose,
  });

  final CoreMenubarMenu menu;
  final CoreMenubarVariant variant;
  final CoreMenubarStyle? menubarStyle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMenubar(
      context,
      variant: variant,
      menubarStyle: menubarStyle,
    );

    return Menu(
      items: [
        for (final entry in menu.entries)
          if (entry.kind == .divider)
            const CoreMenuItem<Widget>.divider()
          else
            CoreMenuItem<Widget>.action(
              entry.label,
              onPressed: entry.onSelect,
              shortcut: entry.shortcut,
              standardAction: entry.standardAction,
              disabled: !entry.enabled,
            ),
      ],
      menuStyle: CoreMenuStyle(popupStyle: resolved.menuPanelStyle),
      onActivate: onClose,
    );
  }
}

/// Chain sugar for merging a [CoreMenubarStyle] patch into
/// [Menubar.menubarStyle] without hand-reconstructing every field. Mirrors
/// the Web `Menubar.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMenubarStyle.merge` right-side-wins semantics).
extension MenubarStyleChain on Menubar {
  /// Returns a copy of this [Menubar] with [patch] merged into
  /// [menubarStyle] (patch fields win on conflict).
  Menubar withStyle(CoreMenubarStyle patch) => copyWith(
    menubarStyle: (menubarStyle ?? const CoreMenubarStyle()).merge(patch),
  );
}
