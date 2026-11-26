import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/overlay/trigger_tap_detector.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;

/// A unified popover component anchored to a [trigger] widget.
///
/// On [openTrigger] interaction (or imperative [controller] call),
/// a floating panel containing [content] appears anchored to the
/// trigger with collision-aware [placement]. Outside taps and the
/// Escape key dismiss the popover by default — opt out via
/// [dismissOnOutsideTap] / [dismissOnEscape].
///
/// Use [controller] to drive open / close from outside the widget
/// tree (e.g. a swatch button toggling a color picker popover).
///
/// Per Epic #1302, panel chrome / dimensional / animation overrides
/// flow through the single [popoverStyle] field — see
/// [CorePopoverStyle] for the merge chain. Behaviour fields
/// (placement / openTrigger / modal / dismiss / collision / constraint
/// / controller / onClose) stay flat on the widget because they
/// describe interaction policy, not chrome.
///
/// To change the trigger's **variant** (e.g. outline vs primary),
/// inject the trigger widget directly via `Popover(trigger: ...)`
/// rather than packing variant into `popoverStyle.triggerStyle` —
/// `popoverStyle.triggerStyle` only carries chrome/dimensional
/// overrides for [Button] triggers.
///
/// surface:functional — the panel it anchors is mounted by the overlay
/// layer, over the page.
class Popover extends StatefulWidget
    implements CorePopoverContract<Widget, VoidCallback, PopoverController> {
  /// Creates a [Popover].
  const Popover({
    required this.trigger,
    required this.content,
    super.key,
    this.placement = CorePopoverPlacement.bottom,
    this.controller,
    this.openTrigger = CorePopoverTrigger.click,
    this.modal = false,
    this.dismissOnOutsideTap = true,
    this.dismissOnEscape = true,
    this.closeOnScroll = false,
    this.collision,
    this.widthConstraint,
    this.heightConstraint,
    this.onClose,
    this.popoverStyle,
  });

  @override
  final Widget trigger;

  @override
  final Widget content;

  @override
  final CorePopoverPlacement placement;

  @override
  final PopoverController? controller;

  @override
  final CorePopoverTrigger openTrigger;

  @override
  final bool modal;

  @override
  final bool dismissOnOutsideTap;

  @override
  final bool dismissOnEscape;

  /// Whether scrolling an ancestor of the trigger dismisses the panel.
  /// Defaults to false; scrolling the panel or unrelated lists does not close
  /// it.
  final bool closeOnScroll;

  @override
  final Set<CorePopoverCollision>? collision;

  @override
  final CorePopoverConstraint? widthConstraint;

  @override
  final CorePopoverConstraint? heightConstraint;

  @override
  final VoidCallback? onClose;

  @override
  final CorePopoverStyle? popoverStyle;

  /// Returns a copy of this [Popover] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Popover copyWith({
    Key? key,
    Widget? trigger,
    Widget? content,
    CorePopoverPlacement? placement,
    PopoverController? controller,
    CorePopoverTrigger? openTrigger,
    bool? modal,
    bool? dismissOnOutsideTap,
    bool? dismissOnEscape,
    bool? closeOnScroll,
    Set<CorePopoverCollision>? collision,
    CorePopoverConstraint? widthConstraint,
    CorePopoverConstraint? heightConstraint,
    VoidCallback? onClose,
    CorePopoverStyle? popoverStyle,
  }) {
    return Popover(
      key: key ?? this.key,
      trigger: trigger ?? this.trigger,
      content: content ?? this.content,
      placement: placement ?? this.placement,
      controller: controller ?? this.controller,
      openTrigger: openTrigger ?? this.openTrigger,
      modal: modal ?? this.modal,
      dismissOnOutsideTap: dismissOnOutsideTap ?? this.dismissOnOutsideTap,
      dismissOnEscape: dismissOnEscape ?? this.dismissOnEscape,
      closeOnScroll: closeOnScroll ?? this.closeOnScroll,
      collision: collision ?? this.collision,
      widthConstraint: widthConstraint ?? this.widthConstraint,
      heightConstraint: heightConstraint ?? this.heightConstraint,
      onClose: onClose ?? this.onClose,
      popoverStyle: popoverStyle ?? this.popoverStyle,
    );
  }

  @override
  State<Popover> createState() => _PopoverState();
}

class _PopoverState extends State<Popover> {
  /// Internal overlay handler — directly drives the unified popover
  /// overlay primitives in `co_popover_overlay.dart`. Replaces the
  /// previous delegation to the legacy `popover.dart`
  /// `PopoverController.show()` so `Popover` no longer depends on
  /// the legacy public API.
  static const PopoverOverlayHandler _handler = PopoverOverlayHandler();

  /// Tracks the currently open overlay entry so a second open call
  /// is a no-op and close can dismiss the active panel.
  PopoverEntryHandle<void>? _activeEntry;

  /// Resolved external controller — `widget.controller` if provided,
  /// otherwise an internally-owned controller so callers always get
  /// a working object back from `widget.controller!.isOpen` etc.
  late PopoverController _external;
  bool _ownsExternal = false;

  /// Shared `TapRegion` group for the trigger and the floating panel. Taps
  /// inside either are NOT "outside taps", so tapping the (open) trigger does
  /// not fire the panel's outside-tap dismiss — without this the trigger tap
  /// both dismisses the panel AND fires the consumer's own toggle, racing to
  /// reopen it. Mirrors the Web popover's trigger exclusion (composedPath).
  final Object _regionGroupId = Object();
  final List<ScrollPosition> _scrollPositions = [];

  void _removeScrollListeners() {
    for (final position in _scrollPositions) {
      position.removeListener(_handleAncestorScroll);
    }
    _scrollPositions.clear();
  }

  void _listenToAncestorScroll() {
    _removeScrollListeners();
    if (!widget.closeOnScroll) return;
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final position = (element.state as ScrollableState).position;
        if (!_scrollPositions.contains(position)) {
          _scrollPositions.add(position);
          position.addListener(_handleAncestorScroll);
        }
      }
      return true;
    });
  }

  void _handleAncestorScroll() => _handleClose();

  @override
  void initState() {
    super.initState();
    _external = widget.controller ?? PopoverController();
    _ownsExternal = widget.controller == null;
    _external.attachHandlers(show: _handleOpen, close: _handleClose);
  }

  /// Builds the floating panel chrome wrapping `widget.content`.
  ///
  /// Re-resolves the theme on every rebuild so light↔dark toggles
  /// reach the open popover. `InheritedTheme.capture` (in
  /// `_handler.show`) wires [popoverContext] to the trigger's theme
  /// ancestor, so `Theme.of(popoverContext)` reflects the live theme
  /// rather than the snapshot at open time.
  Widget _buildPanel(BuildContext popoverContext) {
    // Re-resolve on every rebuild so a light↔dark toggle reaches the open
    // panel (the composed `Popup` re-resolves its forwarded `panelStyle`
    // tokens with the live theme). The panel box (background / border /
    // radius / shadow / padding / content colour) is a single source of
    // truth in `Popup` — this popover only forwards its `panelStyle`.
    final liveResolved = resolvePopover(
      popoverContext,
      popoverStyle: widget.popoverStyle,
    );
    return Popup(
      popupStyle: liveResolved.panelStyle,
      children: [widget.content],
    );
  }

  void _handleOpen() {
    if (_activeEntry != null) return;
    final resolved = resolvePopover(
      context,
      popoverStyle: widget.popoverStyle,
    );
    // `placementOffset` and `duration` are captured once because the
    // overlay handler reads them up-front (placement / show animation
    // parameters); `placementOffset` already carries `theme.scaling` from
    // the resolver. The visual chrome (background, border, shadow, text
    // color) is intentionally *not* captured — it re-resolves through
    // `Theme.of(popoverContext)` inside `_buildPanel` so a light↔dark
    // toggle while the popover is open refreshes the panel colors
    // instead of leaving them stale.
    final placementOffset = resolved.placementOffset;
    final duration = resolved.openAnimationDuration;
    final collisionSet = widget.collision ?? CorePopoverStyle.defaultCollision;

    _external.notifyOpenChanged(isOpen: true);

    final entry = _handler.show<void>(
      alignment: widget.placement.toPopoverAlignment(),
      context: context,
      anchorAlignment: widget.placement.toAnchorAlignment(),
      allowInvertHorizontal: collisionSet.contains(CorePopoverCollision.flip),
      allowInvertVertical: collisionSet.contains(CorePopoverCollision.flip),
      consumeOutsideTaps: widget.dismissOnOutsideTap,
      dismissBackdropFocus: widget.dismissOnEscape,
      dismissDuration: resolved.closeAnimationDuration,
      heightConstraint: widget.heightConstraint ?? .flexible,
      margin: resolved.viewportMargin,
      modal: widget.modal,
      // The one caller that opts in for now. Everything composed on
      // `Popover` — Select, Autocomplete, the pickers, PhoneInput, Fab —
      // gets it from here without naming it.
      morph: true,
      morphPanelStyle: resolved.panelStyle,
      offset: widget.placement.toPopoverOffset(placementOffset),
      regionGroupId: _regionGroupId,
      showDuration: duration,
      widthConstraint: widget.widthConstraint ?? .flexible,
      builder: _buildPanel,
    );

    // Through `setState`: the trigger's `expanded` flag below is read from
    // this field. Assigned bare, a panel opened or closed through the
    // controller left the flag at whatever the last unrelated rebuild saw
    // — a composite that did not happen to rebuild (an outside tap, an
    // Escape, a field that only calls `show()`) kept announcing the old
    // state.
    setState(() => _activeEntry = entry);
    _listenToAncestorScroll();
    unawaited(
      entry.future.whenComplete(() {
        _removeScrollListeners();
        if (!mounted) {
          _activeEntry = null;
          return;
        }
        setState(() => _activeEntry = null);
        _external.notifyOpenChanged(isOpen: false);
        widget.onClose?.call();
      }),
    );
  }

  void _handleClose() {
    _activeEntry?.close();
  }

  void _handleTriggerTap() {
    if (widget.openTrigger != .click) return;
    if (_activeEntry != null) {
      _handleClose();
    } else {
      _handleOpen();
    }
  }

  void _handleFocusChange(bool focused) {
    if (focused) {
      _handleOpen();
    } else {
      _handleClose();
    }
  }

  /// Wraps [child] according to the resolved trigger sizing —
  /// `intrinsic` means "size to the child's natural width" (mirrors
  /// Web `inline-flex`); `expand` means "fill the parent's inline-axis"
  /// (Flutter's default unconstrained behaviour), and where the parent
  /// leaves that axis unbounded — a `Row` — there is nothing to fill, so the
  /// trigger takes its natural width rather than throwing.
  /// Mirrors the `CoreCardSizing` pattern used by `Card`.
  Widget _applySizing(Widget child, CorePopoverTriggerSizing sizing) {
    if (sizing == .intrinsic) {
      return IntrinsicWidth(child: child);
    }
    return _HugWhenUnbounded(child: child);
  }

  @override
  void didUpdateWidget(covariant Popover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.closeOnScroll != widget.closeOnScroll &&
        _activeEntry != null) {
      _listenToAncestorScroll();
    }
    if (oldWidget.controller != widget.controller) {
      _external.detachHandlers();
      if (_ownsExternal) {
        _external.dispose();
      }
      _external = widget.controller ?? PopoverController();
      _ownsExternal = widget.controller == null;
      _external.attachHandlers(show: _handleOpen, close: _handleClose);
    }
    // The open panel is mounted in the app's overlay, outside this subtree:
    // new content reaches it only when it is told to run its builder again.
    if (oldWidget.content != widget.content) {
      _activeEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _removeScrollListeners();
    _external.detachHandlers();
    if (_ownsExternal) {
      _external.dispose();
    }
    _activeEntry?.dismissImmediately();
    _activeEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolvePopover(
      context,
      popoverStyle: widget.popoverStyle,
    );
    final sizing = resolved.triggerSizing;
    // `.click` uses a `Listener`-based `TriggerTapDetector` (not a
    // `GestureDetector`) so an interactive trigger (e.g. `Button`) does not win
    // the gesture arena and swallow the open tap — mirrors Web DOM bubbling.
    final triggerChild = switch (widget.openTrigger) {
      .manual => widget.trigger,
      .hover => MouseRegion(
        onEnter: (_) => _handleOpen(),
        onExit: (_) => _handleClose(),
        child: widget.trigger,
      ),
      .focus => Focus(
        onFocusChange: _handleFocusChange,
        child: widget.trigger,
      ),
      .click => TriggerTapDetector(
        onTap: _handleTriggerTap,
        child: widget.trigger,
      ),
    };
    // Register the trigger in the panel's dismiss-exclusion group (see
    // `_regionGroupId`) so re-tapping the open trigger only runs the consumer's
    // toggle (close) instead of also firing an outside-tap dismiss that races
    // to reopen it.
    // Web twin: role="dialog" on the floating panel.
    // Whether the panel is showing rides the trigger, matching Web's
    // `aria-expanded` on the same control. Without it a reader has no
    // way to know activating opens or closes — nor that it opened.
    return Semantics(
      container: true,
      expanded: _activeEntry != null,
      child: _applySizing(
        TapRegion(groupId: _regionGroupId, child: triggerChild),
        sizing,
      ),
    );
  }
}

/// Chain sugar for merging a [CorePopoverStyle] patch into
/// [Popover.popoverStyle] without hand-reconstructing every field.
/// Mirrors the Web `Popover.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CorePopoverStyle.merge` right-side-wins semantics).
extension PopoverStyleChain on Popover {
  /// Returns a copy of this [Popover] with [patch] merged into
  /// [popoverStyle] (patch fields win on conflict).
  Popover withStyle(CorePopoverStyle patch) => copyWith(
    popoverStyle: (popoverStyle ?? const CorePopoverStyle()).merge(patch),
  );
}

/// Passes the parent's constraints through when the width is bounded, and
/// lays its child out at the child's widest intrinsic width when it is not.
///
/// This is `expand` where there is nothing to expand into: a field trigger
/// fills the width it is offered, but a `Row` offers none, and a field that
/// stretches asserts there. A `LayoutBuilder` that picked between the two
/// would throw on intrinsic queries (an `IntrinsicWidth` or a `Table` above
/// the popover), so this box answers intrinsics from its child.
class _HugWhenUnbounded extends SingleChildRenderObjectWidget {
  const _HugWhenUnbounded({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHugWhenUnbounded();
}

class _RenderHugWhenUnbounded extends RenderProxyBox {
  BoxConstraints _childConstraints(BoxConstraints constraints, RenderBox box) =>
      constraints.hasBoundedWidth
      ? constraints
      : constraints.tighten(
          width: box.getMaxIntrinsicWidth(constraints.maxHeight),
        );

  @override
  void performLayout() {
    final box = child;
    if (box == null) {
      size = constraints.smallest;
      return;
    }
    box.layout(_childConstraints(constraints, box), parentUsesSize: true);
    size = box.size;
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final box = child;
    if (box == null) return constraints.smallest;
    return box.getDryLayout(_childConstraints(constraints, box));
  }

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final box = child;
    if (box == null) return null;
    return box.getDryBaseline(_childConstraints(constraints, box), baseline);
  }
}
