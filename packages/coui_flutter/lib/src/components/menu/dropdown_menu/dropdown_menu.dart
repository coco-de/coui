import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/clickable/clickable_activation_scope.dart';
import 'package:coui_flutter/src/components/overlay/trigger_tap_detector.dart';
import 'package:flutter/rendering.dart'
    show
        RenderSemanticsAnnotations,
        SemanticsAction,
        SemanticsConfiguration,
        SemanticsNode,
        SemanticsProperties;

/// A unified dropdown-menu component.
///
/// `DropdownMenu` renders a [trigger] that, when activated, reveals
/// its [items] as a floating panel anchored beneath it. Selecting an
/// enabled action entry invokes its `onSelect` callback and closes the
/// panel; clicking outside the panel or pressing Escape also closes
/// it.
///
/// `DropdownMenu` is the unified replacement for the legacy Flutter
/// `DropdownMenu` and Web `DropdownMenu` — same parameter names, same
/// semantics, full visual parity.
///
/// Mirrors Web `DropdownMenu` 1:1 — same parameter names, same
/// semantics.
///
/// The floating panel is driven through the shared
/// [PopoverOverlayHandler] engine inline — the same positioning engine
/// `Popover` / `Tooltip` / `HoverCard` drive (`_handler.show()` +
/// `_activeEntry`) — so it gets collision-aware flip/shift at screen
/// edges. The panel is anchored `bottomStart` (top-left of the panel
/// pinned to the trigger's bottom-left).
///
/// Pass [controller] to drive open / close imperatively from outside the
/// widget tree — it shares the unified [PopoverController] with `Popover`
/// (the dropdown is a single trigger-anchored panel, so it reuses the
/// same controller rather than a bespoke one).
///
/// ```dart
/// DropdownMenu(
///   trigger: Button(
///     variant: CoreButtonVariant.outline,
///     onPressed: () {},
///     child: const Text('Open Menu'),
///   ),
///   items: [
///     CoreMenuItem.action('Profile', onPressed: () {}),
///     CoreMenuItem.action('Settings'),
///     const CoreMenuItem.divider(),
///     CoreMenuItem.action('Sign out'),
///   ],
/// )
/// ```
///
/// surface:functional — opens through the overlay handler, anchored over
/// its trigger.
class DropdownMenu extends StatefulWidget
    implements CoreDropdownMenuViewContract<Widget> {
  /// Creates a [DropdownMenu].
  const DropdownMenu({
    required this.trigger,
    required this.items,
    this.dropdownMenuStyle,
    this.controller,
    super.key,
  });

  @override
  final Widget trigger;

  @override
  final List<CoreMenuItem<Widget>> items;

  @override
  final CoreDropdownMenuStyle? dropdownMenuStyle;

  @override
  final PopoverController? controller;

  /// Returns a copy of this [DropdownMenu] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  DropdownMenu copyWith({
    Key? key,
    Widget? trigger,
    List<CoreMenuItem<Widget>>? items,
    CoreDropdownMenuStyle? dropdownMenuStyle,
    PopoverController? controller,
  }) {
    return DropdownMenu(
      key: key ?? this.key,
      trigger: trigger ?? this.trigger,
      items: items ?? this.items,
      dropdownMenuStyle: dropdownMenuStyle ?? this.dropdownMenuStyle,
      controller: controller ?? this.controller,
    );
  }

  @override
  State<DropdownMenu> createState() => _DropdownMenuState();
}

class _DropdownMenuState extends State<DropdownMenu> {
  /// Panel anchored beneath the trigger, left edges aligned — the
  /// `CompositedTransformFollower(targetAnchor: .bottomLeft,
  /// followerAnchor: .topLeft)` geometry, now expressed through the
  /// shared engine's placement so it inherits flip/shift.
  static const CorePopoverPlacement _placement = .bottomStart;

  /// Shared overlay engine — drives the panel inline exactly like
  /// `Popover._PopoverState` (`_handler.show()` + `_activeEntry`).
  static const PopoverOverlayHandler _handler = PopoverOverlayHandler();

  /// The currently open panel handle, or `null` when closed — drives the
  /// trigger's `Semantics(expanded:)`.
  PopoverEntryHandle<void>? _activeEntry;

  /// Resolved external controller — `widget.controller` if provided,
  /// otherwise an internally-owned one so the widget always has a live
  /// controller to drive open / close (mirrors `Popover`).
  late PopoverController _external;
  bool _ownsExternal = false;

  @override
  void initState() {
    super.initState();
    _external = widget.controller ?? PopoverController();
    _ownsExternal = widget.controller == null;
    _external.attachHandlers(show: _handleOpen, close: _handleClose);
  }

  void _handleToggle() {
    if (_activeEntry != null) {
      _handleClose();
    } else {
      _handleOpen();
    }
  }

  void _handleOpen() {
    if (!mounted || _activeEntry != null) return;
    // Resolve the placement-axis gap through the style chain (rather than
    // hardcoding the token) so it is user-overridable via
    // `CoreDropdownMenuTheme.style.menuOffset` — same source the panel
    // builder reads, and same pattern as `Menubar._openMenuAt`.
    final resolved = resolveDropdownMenu(
      context,
      dropdownMenuStyle: widget.dropdownMenuStyle,
    );
    _external.notifyOpenChanged(isOpen: true);
    // Enter / exit motion chained from the panel `Popup`'s `CorePopupStyle`
    // (single source) so it is user-overridable via
    // `popupStyle.openAnimationDuration` — parity with Web. (`showDuration`
    // / `dismissDuration` sit at their `show()` declaration positions for
    // `arguments-ordering`.)
    final entry = _handler.show<void>(
      alignment: _placement.toPopoverAlignment(),
      context: context,
      anchorAlignment: _placement.toAnchorAlignment(),
      dismissDuration: resolved.panel.closeAnimationDuration,
      // A menu can have more rows than the viewport has room for; it takes
      // the room and scrolls rather than running off the screen.
      fitViewportHeight: true,
      // Modal menu anchored once at open — flip/shift still resolves at
      // layout time. No per-frame follow ticker (the trigger can't move
      // under the modal barrier), so the panel settles for tests/animation.
      follow: false,
      offset: _placement.toPopoverOffset(resolved.menuOffset),
      showDuration: resolved.panel.openAnimationDuration,
      builder: _buildPanel,
    );
    setState(() => _activeEntry = entry);
    unawaited(
      entry.future.whenComplete(() {
        if (!mounted) return;
        setState(() => _activeEntry = null);
        _external.notifyOpenChanged(isOpen: false);
      }),
    );
  }

  void _handleClose() {
    _activeEntry?.close();
  }

  /// Builds the floating panel as a composed [Menu] (Epic #2676 L2-b).
  ///
  /// The dropdown no longer hand-rolls a `Popup` + per-entry `Button` /
  /// `Separator`; `Menu` owns the whole item-row renderer (the panel
  /// `Popup`, the `Button(variant: menu)` rows, dividers, shortcuts,
  /// checkbox / radio / submenu entries). The merged
  /// `dropdownMenuStyle.menuStyle` (`resolved.menuStyle`) flows straight
  /// into `Menu`'s `menuStyle` slot so panel + item overrides apply on top
  /// of the canonical menu chrome. `onActivate: _handleClose`
  /// dismisses the overlay first when an action row is selected — the
  /// "close then act" order the old `_handleItemSelected` had (the action
  /// row's own handler runs after, inside `Menu`).
  Widget _buildPanel(BuildContext overlayContext) {
    final resolved = resolveDropdownMenu(
      overlayContext,
      dropdownMenuStyle: widget.dropdownMenuStyle,
    );
    return Menu(
      items: widget.items,
      menuStyle: resolved.menuStyle,
      onActivate: _handleClose,
    );
  }

  @override
  void didUpdateWidget(covariant DropdownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    // new items reach it only when it is told to run its builder again.
    if (oldWidget.items != widget.items) {
      _activeEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
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
    return Actions(
      actions: const {},
      dispatcher: _DropdownActionDispatcher(
        delegate: Actions.of(context),
        onActivate: _handleOpen,
      ),
      child: _DropdownTriggerSemantics(
        onActivate: _handleOpen,
        child: ClickableActivationScope(
          onActivate: _handleOpen,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            // A `Listener`-based detector (not `GestureDetector`) so an
            // interactive trigger (e.g. `Button`) does not win the gesture
            // arena and swallow the open tap — mirrors Web DOM bubbling.
            child: TriggerTapDetector(
              onTap: _handleToggle,
              child: Semantics(
                button: true,
                expanded: _activeEntry != null,
                child: widget.trigger,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// The dispatcher composes with the action the descendant actually selected.
// Shortcuts calls invokeActionIfEnabled directly, while Actions.invoke calls
// invokeAction, so both entry points preserve their normal delegate/result.
class _DropdownActionDispatcher extends ActionDispatcher {
  const _DropdownActionDispatcher({
    required this.delegate,
    required this.onActivate,
  });

  final ActionDispatcher delegate;
  final VoidCallback onActivate;

  bool _opensMenu(Intent intent) =>
      intent is ActivateIntent || intent is ButtonActivateIntent;

  @override
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    final result = delegate.invokeAction(action, intent, context);
    if (_opensMenu(intent)) onActivate();
    return result;
  }

  @override
  (bool, Object?) invokeActionIfEnabled(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    final result = delegate.invokeActionIfEnabled(action, intent, context);
    if (result.$1 && _opensMenu(intent)) onActivate();
    return result;
  }
}

// Replaces only the existing outer Semantics(container: true) boundary.
// RenderSemanticsAnnotations retains its canonical default properties/flags,
// layout, painting and child traversal. No descendant node is replaced.
class _DropdownTriggerSemantics extends SingleChildRenderObjectWidget {
  const _DropdownTriggerSemantics({
    required this.onActivate,
    required Widget super.child,
  });

  final VoidCallback onActivate;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDropdownTriggerSemantics(onActivate);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderDropdownTriggerSemantics renderObject,
  ) {
    renderObject.onActivate = onActivate;
  }
}

class _RenderDropdownTriggerSemantics extends RenderSemanticsAnnotations {
  _RenderDropdownTriggerSemantics(this._onActivate)
    : super(container: true, properties: const SemanticsProperties());

  VoidCallback _onActivate;

  VoidCallback get onActivate => _onActivate;

  set onActivate(VoidCallback value) {
    if (_onActivate == value) return;
    _onActivate = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    // Child tap handlers replace parent annotations when configurations merge.
    // Compose the actual effective action here, preserving every other field,
    // action and child node. Separate descendant boundaries stay untouched.
    if (config.isEnabled == false || config.isBlockingUserActions) {
      super.assembleSemanticsNode(node, config, children);
      return;
    }
    final originalTap = config.getActionHandler(SemanticsAction.tap);
    // Do not invent another action above an independently bounded child.
    // The opt-in callback handles a CoUI trigger's own activation instead.
    if (originalTap == null && children.isNotEmpty) {
      super.assembleSemanticsNode(node, config, children);
      return;
    }
    final composed = config.copy()
      ..onTap = () {
        originalTap?.call(null);
        if (attached) _onActivate();
      };
    super.assembleSemanticsNode(node, composed, children);
  }
}

/// Chain sugar for merging a [CoreDropdownMenuStyle] patch into
/// [DropdownMenu.dropdownMenuStyle] without hand-reconstructing every
/// field. Mirrors the Web `DropdownMenu.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDropdownMenuStyle.merge` right-side-wins semantics).
extension DropdownMenuStyleChain on DropdownMenu {
  /// Returns a copy of this [DropdownMenu] with [patch] merged into
  /// [dropdownMenuStyle] (patch fields win on conflict).
  DropdownMenu withStyle(CoreDropdownMenuStyle patch) => copyWith(
    dropdownMenuStyle: (dropdownMenuStyle ?? const CoreDropdownMenuStyle())
        .merge(patch),
  );
}
