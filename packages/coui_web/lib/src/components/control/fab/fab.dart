import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/control/fab/fab_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/popup/popup.dart';
import 'package:coui_web/src/components/menu/menu_item/menu_item.dart';
import 'package:coui_web/src/components/overlay/popover/popover.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// A single speed-dial action for [Fab] on Web.
///
/// Type alias kept symmetrical with the Flutter `FabAction`. Both
/// wrap [CoreFabAction] from `coui_core` with the platform component
/// type bound.
typedef FabAction = CoreFabAction<Component>;

/// Unified cross-platform Floating Action Button for CoUI Web with
/// token-based rendering.
///
/// `Fab` renders a circular floating button that can optionally open a
/// menu of actions. The main circle is a composed `Button` (variant
/// `primary`) and each action is a composed `MenuItem` row inside a
/// composed `Popup` panel — so colour, hover, focus ring, keyboard
/// activation, press states and cursor of the circle come from `Button`,
/// the rows from `MenuItem` (the row every menu draws), and the panel from
/// `Popup`. The FAB-specific shape / dimensional overrides (circle radius,
/// diameter, shadow, icon size) flow through the single [fabStyle] (a
/// [CoreFabStyle]) nested `buttonStyle` / `actionItemStyle` / `popupStyle`
/// slots. Semantic fields (`size` / `expandDirection`) and behaviour fields
/// stay flat on the component.
///
/// When [actions] is non-empty the menu is hosted in a composed `Popover`,
/// so it lives in the overlay layer — hit-testable and never clipped by an
/// ancestor's `overflow` / `transform` bounds. The host is chrome-less
/// ([CoreFabStyle.popoverStyle]) because the `Popup` is the visible box.
/// The panel aligns to the FAB's **end edge** (the right edge of a
/// right-hand FAB), not to its centre: a FAB sits at a screen edge, and a
/// centred panel wider than the circle would be pushed off the screen.
///
/// ```text
/// design system default (CoreFabStyle.defaultX)
///   → CoreFabTheme.style                  // 프로젝트 공통
///   → component.fabStyle                  // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// Fab(
///   trigger: const Icon(LucideIcons.plus),
///   onPressed: () => print('FAB pressed'),
/// )
/// ```
///
/// surface:functional — sits over the scrolling body, and its speed-dial
/// opens in the overlay layer.
class Fab extends UiStatefulComponent implements CoreFabContract<Component> {
  /// Creates a [Fab].
  const Fab({
    required this.trigger,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.label,
    this.onPressed,
    this.actions,
    this.open = false,
    this.onOpenChanged,
    this.size = CoreFabSize.defaultSize,
    this.expandDirection = CoreFabExpandDirection.defaultDirection,
    this.closeIcon,
    this.tooltip,
    this.fabStyle,
  });

  @override
  final Component trigger;

  @override
  final Component? label;

  @override
  final CoreVoidCallback? onPressed;

  @override
  final List<FabAction>? actions;

  @override
  final bool open;

  @override
  final CoreValueChanged<bool>? onOpenChanged;

  @override
  final CoreFabSize size;

  @override
  final CoreFabExpandDirection expandDirection;

  @override
  final Component? closeIcon;

  @override
  final String? tooltip;

  /// Per-instance composite style — main FAB and action chrome. See
  /// [CoreFabStyle] for the merge chain.
  @override
  final CoreFabStyle? fabStyle;

  /// Returns a copy of this [Fab] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Fab copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiMouseEventHandler? onClick,
    CoreVoidCallback? onPressed,
    Component? trigger,
    Component? label,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    List<FabAction>? actions,
    bool? open,
    CoreValueChanged<bool>? onOpenChanged,
    CoreFabSize? size,
    CoreFabExpandDirection? expandDirection,
    Component? closeIcon,
    String? tooltip,
    CoreFabStyle? fabStyle,
  }) {
    return Fab(
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
      onClick: onClick ?? this.onClick,
      trigger: trigger ?? this.trigger,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      actions: actions ?? this.actions,
      open: open ?? this.open,
      onOpenChanged: onOpenChanged ?? this.onOpenChanged,
      size: size ?? this.size,
      expandDirection: expandDirection ?? this.expandDirection,
      closeIcon: closeIcon ?? this.closeIcon,
      tooltip: tooltip ?? this.tooltip,
      fabStyle: fabStyle ?? this.fabStyle,
      label: label ?? this.label,
    );
  }

  @override
  State<Fab> createState() => _FabState();
}

class _FabState extends State<Fab> {
  /// Drives the composed `Popover` that hosts the expanded speed dial.
  /// `Fab` owns it (passes it as `controller:`) so it can toggle / close
  /// the overlay from the main button and reconcile open state on
  /// outside-tap / Escape dismissal.
  final _popover = PopoverController();

  /// Uncontrolled open state. Ignored when [Fab.onOpenChanged] is set
  /// (controlled mode — the parent owns `open`).
  bool _internalOpen = false;

  @override
  void initState() {
    super.initState();
    _internalOpen = component.open;
    _popover.addListener(_handlePopoverChanged);
    // Drive the popover open after the first frame when the FAB starts
    // expanded: the composed `Popover` attaches its show/close handlers in
    // its own `initState`, which runs after this component's first build.
    if (_isOpen && _hasActions) {
      scheduleNextFrame(_syncPopover);
    }
  }

  /// Whether the parent owns the open state (controlled mode).
  bool get _isControlled => component.onOpenChanged != null;

  bool get _isOpen => _isControlled ? component.open : _internalOpen;

  bool get _hasActions =>
      component.actions != null && component.actions!.isNotEmpty;

  /// Maps the FAB expand direction onto the popover placement. `up` and
  /// `down` align the panel to the FAB's end edge; `fan` reuses `up` — the
  /// menu opens on that side of the FAB, hit-testable in the overlay.
  ///
  /// `End` is the physical right edge (the placement vocabulary is
  /// physical), so the panel does not mirror under a right-to-left locale.
  CorePopoverPlacement get _placement => switch (component.expandDirection) {
    .up || .fan => .topEnd,
    .down => .bottomEnd,
    .left => .left,
    .right => .right,
  };

  Map<String, String> _tooltipAttributes(String? tooltip) {
    if (tooltip == null) return const {};
    // `aria-label` only — the *visual* tooltip is the unified `Tooltip`
    // component (composed in `_buildMainButton` / `_buildRow`), matching
    // Flutter. A native `title` would double up with the unstyled
    // OS-default tooltip.
    return {'aria-label': tooltip};
  }

  /// Reconciles the popover controller to match [_isOpen]. Called directly
  /// from pointer-driven handlers (safe — outside build) and via
  /// [scheduleNextFrame] from lifecycle callbacks (deferred — driving the
  /// overlay during build throws).
  void _syncPopover() {
    if (!_hasActions) return;
    if (_isOpen && !_popover.isOpen) {
      _popover.show();
    } else if (!_isOpen && _popover.isOpen) {
      _popover.close();
    }
  }

  /// Listener on [_popover] — fires on every open / close transition,
  /// including outside-tap / Escape dismissal driven by the overlay itself.
  void _handlePopoverChanged() {
    final open = _popover.isOpen;
    if (open == _isOpen) {
      // Open state already matches — rebuild so the main button swaps its
      // trigger / close glyph.
      setState(() {});
      return;
    }
    // The popover changed independently of us (dismissed) — reconcile.
    if (_isControlled) {
      component.onOpenChanged?.call(open);
    } else {
      setState(() => _internalOpen = open);
    }
  }

  /// Toggles the speed dial from the main button. Drives the popover in
  /// uncontrolled mode; defers to the parent in controlled mode.
  void _handleToggle() {
    final next = !_isOpen;
    if (_isControlled) {
      component.onOpenChanged?.call(next);
    } else {
      setState(() => _internalOpen = next);
      _syncPopover();
    }
  }

  void _handleClose() {
    if (!_isOpen) return;
    if (_isControlled) {
      component.onOpenChanged?.call(false);
    } else {
      setState(() => _internalOpen = false);
      _syncPopover();
    }
  }

  void _handleActionPressed(FabAction action) {
    action.onPressed?.call();
    _handleClose();
  }

  /// Builds the main FAB circle — a composed primary `Button` whose press
  /// either toggles the speed dial (when [Fab.actions] is non-empty) or
  /// fires [Fab.onPressed] directly. While open it shows the close glyph.
  Component _buildMainButton(ResolvedFab resolved) {
    final showClose = _hasActions && _isOpen;
    final child = showClose
        ? (component.closeIcon ?? const Icon(LucideIcons.x))
        : component.trigger;

    // Extended — 라벨이 있으면 원이 아니라 알약이다. 높이 사다리와 라벨
    // 크기는 `Button` 이 이미 갖고 있으므로 사이즈를 골라 상속받고, 글리프는
    // `leading` 슬롯으로 간다. 스피드 다이얼과는 조합되지 않는다(생성자
    // assert 가 막는다) — Flutter 와 같은 조건.
    final isExtended = component.label != null && !_hasActions;
    final attributes = {
      ..._tooltipAttributes(component.tooltip),
      if (_hasActions) 'aria-expanded': '$_isOpen',
    };
    final button = isExtended
        ? Button(
            onPressed: component.onPressed,
            size: component.size.toExtendedButtonSize(),
            buttonStyle: resolved.extendedButtonStyle,
            attributes: attributes,
            leading: child,
            child: component.label!,
          )
        : Button(
            onPressed: _hasActions ? _handleToggle : component.onPressed,
            buttonStyle: resolved.buttonStyle,
            attributes: attributes,
            child: child,
          );
    // Unified styled tooltip on hover (parity with Flutter), wrapping the
    // Popover trigger.
    if (component.tooltip == null) return button;
    return Tooltip(message: component.tooltip!, child: button);
  }

  /// Builds the menu hosted inside the FAB's [Popover]: a composed `Popup`
  /// panel holding one `MenuItem` row per [Fab.actions] — the same two
  /// primitives `Menu` composes, used directly here because a
  /// [FabAction]'s label is a component, not the string a `Menu` item
  /// takes. The rows read top to bottom in the caller's order, whichever
  /// side of the FAB the panel opens on (mirrors the Flutter `_FabMenu`).
  Component _buildMenu(ResolvedFab resolved) {
    return Popup(
      popupStyle: resolved.popupStyle,
      children: [
        for (final action in component.actions!) _buildRow(action, resolved),
      ],
    );
  }

  Component _buildRow(FabAction action, ResolvedFab resolved) {
    // `MenuItem.label` is required; an action with no label draws an icon
    // row with an empty text seat. A label stays on one line and ends in an
    // ellipsis once the panel reaches its maximum width, rather than
    // wrapping the row taller (mirrors the Flutter row's `maxLines: 1`).
    final label = action.label;
    final row = MenuItem(
      label: label == null
          ? const Component.fragment([])
          : div(
              [label],
              classes: resolved.actionLabel.className,
              styles: resolved.actionLabel.inlineStyles,
            ),
      // 48 은 touch-target(터치 화면의 권장 크기) — 고정 높이가 아니라
      // 사이즈로 고른다(행의 높이 토큰은 최소 높이라 글자 배율이 커지면
      // 행이 늘어나야 한다).
      size: CoreFabContract.actionItemSize,
      leading: action.icon,
      onPressed: () => _handleActionPressed(action),
      menuItemStyle: resolved.actionItemStyle,
      attributes: _tooltipAttributes(action.tooltip),
    );
    // Unified styled tooltip on hover (parity with Flutter).
    return action.tooltip == null
        ? row
        : Tooltip(message: action.tooltip!, child: row);
  }

  @override
  void didUpdateComponent(covariant Fab oldComponent) {
    super.didUpdateComponent(oldComponent);
    // Controlled mode: the parent owns `open`. When it flips, reconcile the
    // overlay after the current build pass (driving it during build throws).
    if (_isControlled && component.open != oldComponent.open) {
      scheduleNextFrame(_syncPopover);
    }
  }

  @override
  void dispose() {
    _popover
      ..removeListener(_handlePopoverChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveFab(
      context,
      size: component.size,
      fabStyle: component.fabStyle,
    );

    final mainButton = _buildMainButton(resolved);

    if (!_hasActions) {
      // No menu — return the main `Button` wrapped so the caller
      // chrome (id / classes / css / attributes / events) still has an
      // outermost element to land on (`Button` does not expose the full
      // passthrough surface). `resolved.root` is an `inline-flex`
      // shrink-wrap.
      return div(
        [mainButton],
        id: component.id,
        classes: component.rootClasses(resolved.root.className),
        styles: component.css != null
            ? Styles.combine([?resolved.root.inlineStyles, component.css!])
            : resolved.root.inlineStyles,
        attributes: component.componentAttributes,
        events: component.events,
      );
    }

    // Host the menu in a composed `Popover` (overlay layer — hit-testable,
    // never clipped by an ancestor's bounds). `manual` open mode: the main
    // `Button`'s own `onPressed` toggles the controller (see
    // `_handleToggle`); letting `Popover` also detect the trigger tap would
    // double-toggle. Caller chrome raw-forwards onto the `Popover` (it is
    // the outermost element).
    return Popover(
      onClick: component.onClick,
      trigger: mainButton,
      content: _buildMenu(resolved),
      attributes: component.userAttributes,
      classes: component.classes,
      css: component.css,
      eventHandlers: component.eventHandlers,
      id: component.id,
      onChange: component.onChange,
      onInput: component.onInput,
      onKeyDown: component.onKeyDown,
      onKeyUp: component.onKeyUp,
      onMouseEnter: component.onMouseEnter,
      onMouseLeave: component.onMouseLeave,
      placement: _placement,
      controller: _popover,
      openTrigger: .manual,
      popoverStyle: resolved.popoverStyle,
    );
  }
}

/// Chain sugar mirroring the Flutter `Fab.withStyle` extension — merges
/// a [CoreFabStyle] patch into [Fab.fabStyle] via the existing
/// [Fab.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFabStyle.merge` right-side-wins semantics).
extension FabStyleChain on Fab {
  /// Returns a copy of this [Fab] with [patch] merged into [fabStyle]
  /// (patch fields win on conflict).
  Fab withStyle(CoreFabStyle patch) =>
      copyWith(fabStyle: (fabStyle ?? const CoreFabStyle()).merge(patch));
}
