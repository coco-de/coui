import 'dart:async';
import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
// The travel node reads the overlay engine's resolved origin at paint
// time; the barrel does not re-export the rendering layer.
import 'package:flutter/rendering.dart'
    show BoxHitTestResult, PaintingContext, RenderProxyBox;

/// A unified cross-platform horizontal navigation mega-menu.
///
/// `NavigationMenu` renders a horizontal row of top-level
/// [CoreNavigationMenuItem]s. Each item is one of:
///
/// * **Content trigger** — has `content`; hovering or clicking the
///   trigger reveals the content as a dropdown panel anchored beneath
///   the trigger, and a chevron is shown.
/// * **Link** — has `href`; the trigger navigates on click.
/// * **Action** — has `onTap`; activating the trigger invokes the
///   callback.
///
/// Data-driven: pass an [items] list of [CoreNavigationMenuItem]s. Every
/// chrome / dimensional override flows through the single
/// [navigationMenuStyle] field — see [CoreNavigationMenuStyle] for the
/// merge chain.
///
/// Pass [activeIndex] + [onActiveIndexChanged] to control the open
/// state externally; omit [activeIndex] to let the widget manage its
/// own open state.
///
/// Mirrors Web `NavigationMenu` 1:1 — same parameter names, same
/// semantics.
///
/// The mega-menu panel is driven through the shared [PopoverOverlayHandler]
/// engine inline — the same positioning engine `Popover` / `Tooltip` /
/// `HoverCard` drive — anchored beneath the active trigger (`bottomStart`)
/// with collision-aware flip, parity with Web's per-trigger
/// `OverlayPositioner`. The panel stays mounted while any content trigger
/// is active: as the hovered / active trigger changes it re-anchors
/// (`PopoverEntryHandle.anchorContext`) and animates the move — the box
/// travels from the old origin to the new one while the content crosses
/// over in the direction the pointer moved — instead of closing and
/// reopening.
///
/// Leaving a trigger or the panel does not close immediately: the bar and
/// the panel are separate hit regions, so a pointer crossing between them
/// leaves the menu for a moment. The exit arms a close after
/// `CoreNavigationMenuStyle.closeDelay`, which any re-entry cancels.
///
/// ```dart
/// NavigationMenu(
///   items: [
///     CoreNavigationMenuItem(
///       label: 'Products',
///       content: const Text('Browse the product catalog'),
///     ),
///     CoreNavigationMenuItem(label: 'Pricing', href: '/pricing'),
///     CoreNavigationMenuItem(label: 'About', onTap: () {}),
///   ],
/// )
/// ```
///
/// surface:functional — the viewport panel opens through the overlay
/// positioner, over the page.
class NavigationMenu extends StatefulWidget
    implements CoreNavigationMenuContract<Widget> {
  /// Creates a [NavigationMenu].
  const NavigationMenu({
    required this.items,
    this.activeIndex,
    this.onActiveIndexChanged,
    this.variant = CoreNavigationMenuVariant.defaultVariant,
    this.navigationMenuStyle,
    super.key,
  });

  @override
  final List<CoreNavigationMenuItem<Widget>> items;

  @override
  final int? activeIndex;

  @override
  final void Function(int?)? onActiveIndexChanged;

  @override
  final CoreNavigationMenuStyle? navigationMenuStyle;

  /// The visual variant of the navigation menu.
  final CoreNavigationMenuVariant variant;

  /// Returns a copy of this [NavigationMenu] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  NavigationMenu copyWith({
    Key? key,
    List<CoreNavigationMenuItem<Widget>>? items,
    int? activeIndex,
    void Function(int?)? onActiveIndexChanged,
    CoreNavigationMenuVariant? variant,
    CoreNavigationMenuStyle? navigationMenuStyle,
  }) {
    return NavigationMenu(
      key: key ?? this.key,
      items: items ?? this.items,
      activeIndex: activeIndex ?? this.activeIndex,
      onActiveIndexChanged: onActiveIndexChanged ?? this.onActiveIndexChanged,
      variant: variant ?? this.variant,
      navigationMenuStyle: navigationMenuStyle ?? this.navigationMenuStyle,
    );
  }

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  /// Half-turn rotation applied to the chevron of an open trigger.
  static const double _kChevronTurn = math.pi;

  /// Panel anchored beneath the active trigger, left edges aligned.
  static const CorePopoverPlacement _placement = .bottomStart;

  /// Shared overlay engine — driven inline like `Popover._PopoverState`.
  static const PopoverOverlayHandler _handler = PopoverOverlayHandler();

  /// Per-trigger anchor keys so the engine can anchor the panel to the
  /// specific hovered / active trigger's `RenderBox` (not the whole bar —
  /// parity with Web, which anchors each `OverlayPositioner` to that
  /// trigger's element id). Rebuilt immutably (no in-place mutation) while
  /// preserving existing keys. Mirrors `Menubar`'s `_triggerKeys`.
  List<GlobalKey> _triggerKeys = const [];

  /// Live panel phase — the content plus, while the open menu is moving
  /// between triggers, everything the panel needs to animate that move
  /// (the outgoing content, the origin delta, the travel direction).
  final ValueNotifier<_PanelPhase> _panelPhase = ValueNotifier(
    const _PanelPhase(),
  );

  /// Monotonic switch id — keys the switch animation so each move
  /// restarts it rather than continuing the previous one.
  int _switchCounter = 0;

  /// Anchors the panel box so a switch can read its painted origin.
  final GlobalKey _panelKey = GlobalKey();

  /// Pending pointer-intent close, and the token that guards it.
  ///
  /// The bar and the panel are separate hit regions, so a pointer moving
  /// from a trigger into the panel (or to a sibling trigger) leaves the
  /// menu for a frame. Closing on that exit would flicker the panel shut
  /// mid-travel, so the exit only *arms* a close; any re-entry bumps
  /// [_hoverToken], which strands the armed timer.
  Timer? _closeTimer;
  int _hoverToken = 0;

  /// Index of the trigger the pointer is currently over, or `null`.
  /// Lets an exit tell "the pointer left the menu" apart from "a sibling
  /// trigger already claimed it" without depending on whether the
  /// framework delivers enter or exit first.
  int? _hoveredTrigger;

  /// Close grace period, cached from the single `build` resolve so the
  /// pointer handlers arm the timer without resolving again.
  Duration _closeDelay = CoreNavigationMenuStyle.defaultCloseDelay;

  /// The currently open panel handle, or `null` when none is open.
  PopoverEntryHandle<void>? _activeEntry;

  /// Index of the trigger the engine panel is currently anchored to, or
  /// `null` when closed.
  int? _shownIndex;

  /// Internally-tracked open index — used only in uncontrolled mode.
  int? _internalIndex;

  /// The effective open index — widget-controlled when `activeIndex` is
  /// non-null, otherwise internally tracked.
  int? get _openIndex => widget.activeIndex ?? _internalIndex;

  void _ensureTriggerKeys() {
    if (_triggerKeys.length == widget.items.length) return;
    _triggerKeys = [
      for (var i = 0; i < widget.items.length; i++)
        if (i < _triggerKeys.length) _triggerKeys[i] else GlobalKey(),
    ];
  }

  void _setActiveIndex(int? index) {
    final clamped = (index != null && index >= 0 && index < widget.items.length)
        ? index
        : null;
    if (_openIndex == clamped) return;
    widget.onActiveIndexChanged?.call(clamped);
    if (widget.activeIndex == null) {
      setState(() => _internalIndex = clamped);
    } else {
      // Controlled mode — rebuild so the chevron / highlight reflect
      // the request even before the parent rebuilds.
      setState(() {});
    }
  }

  void _handleTriggerActivate(int index) {
    final item = widget.items[index];
    if (item.content != null) {
      _setActiveIndex(_openIndex == index ? null : index);
    } else {
      _setActiveIndex(null);
    }
    item.onTap?.call();
  }

  void _handleTriggerHover(int index, {required bool hovered}) {
    // Hover-to-open: hovering a content trigger opens it. The trigger's
    // hover highlight is owned by its `Button` (WidgetState hover); the
    // index tracked here is only the pointer-intent bookkeeping below.
    if (hovered) {
      _hoveredTrigger = index;
      _handlePointerEnteredMenu();
      if (widget.items[index].content != null) {
        _setActiveIndex(index);
      }

      return;
    }
    // Only clear if this trigger still owns the pointer — when the
    // pointer crosses to a sibling, that sibling's enter may land first.
    if (_hoveredTrigger == index) _hoveredTrigger = null;
    _handlePointerLeftMenu();
  }

  /// Arms the close after the pointer leaves a trigger or the panel —
  /// unless another trigger already holds the pointer, in which case that
  /// enter has already cancelled for us.
  void _handlePointerLeftMenu() {
    if (_hoveredTrigger != null) return;
    if (_openIndex == null) return;
    _scheduleClose(_closeDelay);
  }

  /// Cancels any armed close and strands its timer via the token, so a
  /// timer that has already fired past its `cancel` window still can't
  /// close a menu the pointer has re-entered.
  void _handlePointerEnteredMenu() {
    _hoverToken++;
    _closeTimer?.cancel();
    _closeTimer = null;
  }

  void _scheduleClose(Duration delay) {
    _closeTimer?.cancel();
    final token = ++_hoverToken;
    _closeTimer = Timer(delay, () {
      if (!mounted || token != _hoverToken) return;
      _closeTimer = null;
      _handleClose();
    });
  }

  void _handleClose() {
    _setActiveIndex(null);
  }

  /// Where the panel is painted right now, in global coordinates, or
  /// `null` while it isn't laid out.
  ///
  /// This is the point a travel starts from. It is **observed**, never
  /// computed: the panel's origin is chosen by the overlay engine's
  /// collision resolution (flip / shift), which depends on the panel's
  /// own size — so no arithmetic over trigger geometry can predict it,
  /// and the version of this component that tried produced travel that
  /// began at a position the panel had never occupied.
  ///
  /// Reading through [_panelKey] rather than the travel node matters
  /// during an interrupted switch: `Popup` sits *under* the travel node,
  /// so `localToGlobal` routes through its paint transform and reports
  /// where the panel is *painted* mid-flight, not where it is laid out.
  /// A second switch therefore continues from the point on screen.
  Offset? _paintedPanelOrigin() {
    final box = _panelKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return null;
    if (!box.attached || !box.hasSize) return null;

    return box.localToGlobal(.zero);
  }

  /// Reconciles the engine panel with the effective [_openIndex]: opens
  /// the panel anchored to the active trigger when a content trigger is
  /// active (swapping content + sliding the anchor live when the active
  /// trigger changes while already open — parity with Web's per-trigger
  /// `OverlayPositioner`), and closes it when no content trigger is active.
  void _syncEngine() {
    final open = _openIndex;
    final content = (open != null && open >= 0 && open < widget.items.length)
        ? widget.items[open].content
        : null;
    if (content == null) {
      _panelPhase.value = const _PanelPhase();
      if (_activeEntry != null) _activeEntry?.close();

      return;
    }
    if (_activeEntry == null) {
      // Fresh open — the engine's own enter motion carries it, so no
      // switch phase (a slide from nowhere would fight that animation).
      _panelPhase.value = _PanelPhase(content: content);
      _openEngine(open!);
    } else if (_shownIndex != open) {
      // Moving between triggers: the panel stays mounted and travels.
      // Capture the outgoing content + the distance *before* re-anchoring
      // so the panel can start where it was and settle where it is.
      final from = _shownIndex;
      _panelPhase.value = _PanelPhase(
        content: content,
        outgoingContent: (from != null && from < widget.items.length)
            ? widget.items[from].content
            : null,
        // Read before re-anchoring — after it, this point is gone.
        travelFrom: _paintedPanelOrigin(),
        direction: (from == null || open! > from) ? 1 : -1,
        switchId: ++_switchCounter,
      );
      _reanchorEngine(open!);
    } else if (_panelPhase.value.outgoingContent == null &&
        _panelPhase.value.content != content) {
      // Same trigger, caller swapped the item's content widget.
      //
      // The `outgoingContent == null` half of this guard is what keeps a
      // travel alive: `Widget` has no value equality, so a caller that
      // builds its content inline — as this component's own default
      // example does — produces a fresh instance every frame, and the
      // post-frame sync runs every frame. Comparing content alone would
      // therefore replace the in-flight phase within a frame or two,
      // dropping the outgoing half and the travel distance, and the panel
      // would teleport mid-slide. While a travel is running the content is
      // already correct; refreshing the instance buys nothing.
      _panelPhase.value = _PanelPhase(content: content);
    }
  }

  void _openEngine(int index) {
    final triggerContext = _triggerKeys[index].currentContext;
    if (triggerContext == null) return;
    final resolved = resolveNavigationMenu(
      context,
      variant: widget.variant,
      navigationMenuStyle: widget.navigationMenuStyle,
    );
    // Enter / exit motion chained from the panel `Popup`'s `CorePopupStyle`
    // (single source) so it is user-overridable via
    // `navigationMenuStyle.panelStyle.openAnimationDuration` — parity with
    // Web.
    final panelPopup = resolvePopup(
      context,
      popupStyle: resolved.panelStyle,
    );
    final entry = _handler.show<void>(
      alignment: _placement.toPopoverAlignment(),
      context: triggerContext,
      anchorAlignment: _placement.toAnchorAlignment(),
      dismissDuration: panelPopup.closeAnimationDuration,
      // Anchored once beneath the active trigger; flip resolves at layout.
      // The modal barrier is translucent, so hover still reaches the bar
      // triggers (live content + anchor swap) while outside-tap dismisses.
      follow: false,
      offset: _placement.toPopoverOffset(resolved.menuOffset),
      showDuration: panelPopup.openAnimationDuration,
      builder: _buildPanel,
    );
    _activeEntry = entry;
    _shownIndex = index;
    unawaited(
      entry.future.whenComplete(() {
        if (!mounted) return;
        // Only act if this panel is still the active one — a switch to a
        // fresh anchor re-uses the same entry (see `_reanchorEngine`), so
        // an identity check isn't needed here, but stays consistent with
        // `Menubar`'s close-then-reopen guard.
        if (_activeEntry == entry) {
          _activeEntry = null;
          _shownIndex = null;
          // Engine dismissed (outside tap) — clear the open index too.
          if (_openIndex != null) _handleClose();
        }
      }),
    );
  }

  /// Slides the still-open panel to the newly active trigger [index]
  /// instead of closing / reopening — the panel stays mounted and its
  /// content already swapped via `_panelContent` (see `_syncEngine`).
  void _reanchorEngine(int index) {
    final triggerContext = _triggerKeys[index].currentContext;
    if (triggerContext == null) return;
    _activeEntry?.anchorContext = triggerContext;
    _shownIndex = index;
  }

  Widget _buildTrigger(
    int index,
    ResolvedNavigationMenu resolved,
  ) {
    final item = widget.items[index];
    final isOpen = _openIndex == index;
    final hasContent = item.content != null;

    final chevron = hasContent
        ? AnimatedRotation(
            turns: isOpen ? _kChevronTurn / (2 * math.pi) : 0,
            curve: CoreEasing.move.toValue(),
            duration: resolved.duration,
            child: Icon(
              LucideIcons.chevronDown,
              iconStyle: resolved.chevronIconStyle,
            ),
          )
        : null;

    // Composed `Button(variant: menubar)` — the variant owns the resting
    // fill (a flicker-free grey-hue lerp, unified with `Menubar`); this
    // component states the hover and open fill and the insets through the
    // Core nested slots. Hovering a content trigger opens it (nav
    // hover-to-open) via `onHover` → `_handleTriggerHover`; `onPressed`
    // activates. The trigger whose panel is open keeps its fill (open ≠
    // hovered) through the open-trigger style. A trigger without a dropdown
    // takes the plain style (no chevron, symmetric inset). Focus ring
    // suppressed for parity.
    final buttonStyle = !hasContent
        ? resolved.triggerButtonStyle
        : isOpen
        ? resolved.openTriggerButtonStyle
        : resolved.contentTriggerButtonStyle;

    return Semantics(
      link: item.href != null,
      expanded: hasContent ? isOpen : null,
      child: Button(
        key: _triggerKeys[index],
        onPressed: () => _handleTriggerActivate(index),
        variant: .menubar,
        trailing: chevron,
        buttonStyle: buttonStyle,
        disableFocusOutline: true,
        onHover: (hovered) => _handleTriggerHover(index, hovered: hovered),
        child: Text(item.label, style: resolved.triggerTextStyle),
      ),
    );
  }

  Widget _buildPanel(BuildContext overlayContext) {
    return ValueListenableBuilder<_PanelPhase>(
      valueListenable: _panelPhase,
      builder: (panelContext, phase, _) {
        final content = phase.content;
        if (content == null) return const SizedBox.shrink();
        final resolved = resolveNavigationMenu(
          panelContext,
          variant: widget.variant,
          navigationMenuStyle: widget.navigationMenuStyle,
        );
        final outgoing = phase.outgoingContent;
        // A zero-length travel is not a travel. Reduced motion collapses
        // `panelSwitchDuration` to zero (and a caller may pass zero
        // outright), and handing that to `TweenAnimationBuilder` is not
        // merely pointless — it completes *synchronously inside its own
        // `initState`*, so `onEnd` would write `_panelPhase` while this
        // build is still running and trip the framework's `!_dirty`
        // assertion, replacing the panel with an error box. Render the
        // settled panel instead and retire the phase after the frame.
        if (outgoing == null || resolved.panelSwitchDuration <= .zero) {
          if (outgoing != null) _retireSwitchPhaseAfterFrame(phase);

          return _panelBox(resolved, content);
        }

        // The menu is moving between triggers, and the engine has already
        // re-anchored, so the panel would otherwise appear at its new
        // origin instantly. Holding it back to where it was and releasing
        // that hold makes the move read as travel, while the content
        // crosses over in the same window — entering from whichever side
        // the pointer moved toward.
        return TweenAnimationBuilder<double>(
          key: ValueKey(phase.switchId),
          tween: Tween(begin: 0, end: 1),
          duration: resolved.panelSwitchDuration,
          curve: CoreEasing.move.toValue(),
          onEnd: () => _handleSwitchEnd(phase),
          builder: (context, t, _) => _TravelOffset(
            travelFrom: phase.travelFrom,
            progress: t,
            child: _panelBox(
              resolved,
              ClipRect(
                child: Stacks(
                  children: [
                    // Incoming sizes the stack, so the box takes the new
                    // content's size up front — no snap when the fade ends.
                    FractionalTranslation(
                      translation: Offset(phase.direction * (1 - t), 0),
                      child: Opacity(opacity: t, child: content),
                    ),
                    // Loosely placed rather than stretched to fill, so
                    // taller outgoing content is clipped instead of
                    // squashed for the duration of the fade.
                    Position(
                      left: 0,
                      top: 0,
                      child: FractionalTranslation(
                        translation: Offset(-phase.direction * t, 0),
                        child: Opacity(
                          opacity: 1 - t,
                          // Both halves are on screen for one transition,
                          // but only the incoming half should be read out.
                          child: ExcludeSemantics(child: outgoing),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Retires a switch phase that has no travel to play, from outside the
  /// build that discovered it.
  ///
  /// `_panelPhase` drives a `ValueListenableBuilder`, so writing it during
  /// build would mark an element dirty while it is being built. Deferring
  /// one frame is the whole point.
  void _retireSwitchPhaseAfterFrame(_PanelPhase phase) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleSwitchEnd(phase);
    });
  }

  /// Drops the outgoing half once the travel has played out, returning
  /// the panel to a single-content resting state.
  ///
  /// Without this the outgoing content would stay mounted at zero opacity
  /// for as long as the menu is open — invisible, but still built, still
  /// holding its subtree, and still findable.
  ///
  /// Ignored if another switch has started in the meantime; that newer
  /// phase owns the panel now.
  void _handleSwitchEnd(_PanelPhase phase) {
    if (!mounted) return;
    if (_panelPhase.value.switchId != phase.switchId) return;
    _panelPhase.value = _PanelPhase(
      content: phase.content,
      switchId: phase.switchId,
    );
  }

  /// The dropdown box: the unified `Popup` (no self-painted
  /// `Container` / `DecoratedBox`) plus the pointer-intent region that
  /// keeps the menu alive while the pointer is inside it.
  ///
  /// Panel chrome (background / border / radius / padding / shadow /
  /// min-width) lives in `resolved.panelStyle`, which the popup resolver
  /// finishes.
  Widget _panelBox(ResolvedNavigationMenu resolved, Widget child) {
    return MouseRegion(
      onEnter: (_) => _handlePointerEnteredMenu(),
      onExit: (_) => _handlePointerLeftMenu(),
      child: Popup(
        // Keyed so a switch can read where the panel is *painted* before
        // re-anchoring. It sits on `Popup` rather than the travel node
        // because `Popup` is in both branches of `_buildPanel` — the
        // travel node exists only during a travel, which is exactly when
        // the previous origin is no longer readable from it.
        key: _panelKey,
        popupStyle: resolved.panelStyle,
        children: [
          Semantics(
            container: true,
            child: child,
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant NavigationMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    final open = _internalIndex;
    if (open != null && open >= widget.items.length) {
      _internalIndex = null;
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _closeTimer = null;
    _activeEntry?.dismissImmediately();
    _activeEntry = null;
    _panelPhase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureTriggerKeys();
    final resolved = resolveNavigationMenu(
      context,
      variant: widget.variant,
      navigationMenuStyle: widget.navigationMenuStyle,
    );
    // Cache the chained grace period from this single resolve so the
    // pointer handlers arm the close timer without resolving again.
    _closeDelay = resolved.closeDelay;

    // Reconcile the engine panel with the effective open index — covers
    // both interactive (hover / click) and controlled-mode updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncEngine();
    });

    final triggers = <Widget>[
      for (var i = 0; i < widget.items.length; i++) _buildTrigger(i, resolved),
    ];

    final bar = Row(
      mainAxisSize: .min,
      spacing: resolved.triggerSpacing,
      children: triggers,
    );

    // A labelled navigation landmark — the twin of the Web `<nav
    // aria-label>`. A bare labelled container reads as a group, not a
    // landmark, so a reader's landmark list would skip it on this
    // platform alone. `explicitChildNodes` keeps each trigger its own
    // node: without it a bar with a single trigger folds that button into
    // the landmark, and the reader hears one node that is both the
    // navigation and its only control — the Web `<nav>` never merges its
    // children that way.
    return CoUISemantics(
      role: .navigation,
      label: CoUILocalizations.of(context).navigationLabel,
      container: true,
      explicitChildNodes: true,
      child: bar,
    );
  }
}

/// Holds its child back at the global point it started from, releasing
/// that hold as [progress] runs 0 → 1.
///
/// This exists because the panel's destination is not knowable when the
/// travel is scheduled: the overlay engine picks it during layout, from
/// the panel's own post-swap size and the viewport it has to fit in. A
/// delta computed ahead of time is therefore a guess, and near a viewport
/// edge — where the engine flips or shifts the panel — a wrong one.
///
/// Paint is the one moment where the answer exists and is still
/// actionable: it runs after layout in the same frame, so by the time
/// `paint` is called the engine has already committed the destination.
/// Reading it here needs no callback, no extra frame, and no change to
/// the shared engine.
class _TravelOffset extends SingleChildRenderObjectWidget {
  const _TravelOffset({
    required this.travelFrom,
    required this.progress,
    required Widget super.child,
  });

  /// Global point to hold the child at while [progress] is 0, or `null`
  /// for no travel.
  final Offset? travelFrom;

  /// 0 → hold at [travelFrom]; 1 → wherever the engine put the panel.
  final double progress;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTravelOffset(travelFrom: travelFrom, progress: progress);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderTravelOffset renderObject,
  ) {
    renderObject
      ..travelFrom = travelFrom
      ..progress = progress;
  }
}

class _RenderTravelOffset extends RenderProxyBox {
  _RenderTravelOffset({required Offset? travelFrom, required double progress})
    : _travelFrom = travelFrom,
      _progress = progress;

  Offset? _travelFrom;
  double _progress;

  Offset? get travelFrom => _travelFrom;

  set travelFrom(Offset? value) {
    if (_travelFrom == value) return;
    _travelFrom = value;
    markNeedsPaint();
  }

  double get progress => _progress;

  set progress(double value) {
    if (_progress == value) return;
    _progress = value;
    markNeedsPaint();
  }

  /// How far to hold the child back from where it was laid out, in this
  /// node's own coordinate space.
  Offset get _shift {
    final from = _travelFrom;
    if (from == null || _progress >= 1 || !attached) return .zero;
    // `getTransformTo(null)` excludes this node's own transform, so this
    // is the engine-resolved origin — not the shifted one. Without that
    // property the shift would feed back into itself.
    final toGlobal = getTransformTo(null);
    final origin = MatrixUtils.transformPoint(toGlobal, .zero);
    // The delta is global but applied locally; those differ under any
    // ancestor scale — including the engine's own 0.9 → 1.0 open
    // animation, so a switch that interrupts an opening panel would drift
    // without this.
    final scale = toGlobal.getMaxScaleOnAxis();
    if (scale == 0) return .zero;

    return (from - origin) / scale * (1 - _progress);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      super.paint(context, offset + _shift);

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    // Keeps `localToGlobal` (and therefore hit testing, semantics, and
    // the tests' `getTopLeft`) agreeing with what is on screen — this is
    // also how an interrupted switch reads its own painted position.
    final shift = _shift;
    transform.translateByDouble(shift.dx, shift.dy, 0, 1);
    super.applyPaintTransform(child, transform);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintOffset(
        offset: _shift,
        position: position,
        hitTest: (innerResult, innerPosition) =>
            super.hitTestChildren(innerResult, position: innerPosition),
      );
}

/// What the open panel is showing, and — while the menu is moving from
/// one trigger to another — what it is moving away from.
///
/// [outgoingContent] is non-null only for the duration of a switch; a
/// fresh open leaves it null so the overlay engine's own enter motion
/// plays alone.
///
/// Value equality matters here: the post-frame sync assigns a phase every
/// frame, and a phase that compares equal must not notify (an identity
/// comparison would rebuild the panel — and restart the switch
/// animation — on every frame).
@immutable
class _PanelPhase {
  const _PanelPhase({
    this.content,
    this.outgoingContent,
    this.travelFrom,
    this.direction = 1,
    this.switchId = 0,
  });

  /// The content of the trigger that is open now.
  final Widget? content;

  /// The content being left behind, or `null` outside a switch.
  final Widget? outgoingContent;

  /// Global point the panel occupied when this switch began, or `null`
  /// when there is nothing to travel from (a fresh open, or a panel that
  /// wasn't laid out yet).
  ///
  /// Deliberately an absolute point rather than a delta: the destination
  /// is decided by the overlay engine at layout time and is not knowable
  /// when this phase is built, so the travel is expressed as "hold the
  /// panel here" and the destination is read where it becomes available.
  final Offset? travelFrom;

  /// `1` when the menu moved toward a later trigger, `-1` toward an
  /// earlier one. Drives which side the incoming content enters from.
  final int direction;

  /// Increments per switch so each move restarts the animation.
  final int switchId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PanelPhase &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          outgoingContent == other.outgoingContent &&
          travelFrom == other.travelFrom &&
          direction == other.direction &&
          switchId == other.switchId;

  @override
  int get hashCode => Object.hash(
    content,
    outgoingContent,
    travelFrom,
    direction,
    switchId,
  );
}

/// Chain sugar for merging a [CoreNavigationMenuStyle] patch into
/// [NavigationMenu.navigationMenuStyle] without hand-reconstructing every
/// field. Mirrors the Web `NavigationMenu.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreNavigationMenuStyle.merge` right-side-wins semantics).
extension NavigationMenuStyleChain on NavigationMenu {
  /// Returns a copy of this [NavigationMenu] with [patch] merged into
  /// [navigationMenuStyle] (patch fields win on conflict).
  NavigationMenu withStyle(CoreNavigationMenuStyle patch) => copyWith(
    navigationMenuStyle:
        (navigationMenuStyle ?? const CoreNavigationMenuStyle()).merge(patch),
  );
}
