import 'package:coui_flutter/coui_flutter.dart';

/// A single speed-dial action for [Fab] on Flutter.
///
/// Type alias kept symmetrical with the Web `FabAction`. Both wrap
/// [CoreFabAction] from `coui_core` with the platform widget type
/// bound.
typedef FabAction = CoreFabAction<Widget>;

/// Unified cross-platform Floating Action Button with token-based
/// rendering.
///
/// `Fab` provides a circular floating button that can optionally open a
/// menu of actions. The main circle is a composed `Button` (variant
/// `primary`) and each action is a composed `MenuItem` row inside a
/// composed `Popup` panel — so colour, hover, focus ring, keyboard
/// activation, press states and cursor of the circle come from `Button`,
/// the rows from `MenuItem` (the row every menu draws), and the panel from
/// `Popup`. The FAB-specific shape / dimensional overrides (circle radius,
/// diameter, shadow, icon size) flow through the single [fabStyle] (a
/// [CoreFabStyle]) nested `buttonStyle` / `actionItemStyle` / `popupStyle`
/// slots. Semantic fields (`size` / `expandDirection`) and behaviour fields
/// stay flat on the widget.
///
/// When [actions] is non-empty the menu is hosted in a composed `Popover`,
/// so it lives in the overlay layer — hit-testable and never clipped by an
/// ancestor's bounds, and the FAB has no extra layout footprint while
/// closed. The host is chrome-less ([CoreFabStyle.popoverStyle]) because
/// the `Popup` is the visible box. The panel aligns to the FAB's **end
/// edge** (the right edge of a right-hand FAB), not to its centre: a FAB
/// sits at a screen edge, and a centred panel wider than the circle would
/// be pushed off the screen.
///
/// Example:
/// ```dart
/// Fab(
///   trigger: const Icon(LucideIcons.plus),
///   onPressed: () => debugPrint('FAB pressed'),
/// )
/// ```
///
/// surface:functional — sits over the scrolling body, and its speed-dial
/// opens in the overlay layer.
class Fab extends StatefulWidget implements CoreFabContract<Widget> {
  /// Creates a [Fab].
  const Fab({
    required this.trigger,
    this.label,
    super.key,
    this.onPressed,
    this.actions,
    this.open = false,
    this.onOpenChanged,
    this.size = CoreFabSize.defaultSize,
    this.expandDirection = CoreFabExpandDirection.defaultDirection,
    this.closeIcon,
    this.tooltip,
    this.fabStyle,
  }) : assert(
         label == null || actions == null || actions.length == 0,
         'Fab: label 과 actions 는 함께 쓸 수 없다 — 라벨이 이미 액션을 '
         '특정했는데 다시 액션 목록을 여는 것은 의미가 겹친다. Extended 로 '
         '쓰려면 actions 를 비우고, 스피드 다이얼로 쓰려면 label 을 지운다.',
       );

  @override
  final Widget trigger;

  @override
  final Widget? label;

  @override
  final VoidCallback? onPressed;

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
  final Widget? closeIcon;

  @override
  final String? tooltip;

  /// Per-instance composite style — main FAB and action chrome. See
  /// [CoreFabStyle] for the merge chain.
  @override
  final CoreFabStyle? fabStyle;

  /// Returns a copy of this [Fab] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Fab copyWith({
    Key? key,
    VoidCallback? onPressed,
    Widget? trigger,
    Widget? label,
    List<FabAction>? actions,
    bool? open,
    CoreValueChanged<bool>? onOpenChanged,
    CoreFabSize? size,
    CoreFabExpandDirection? expandDirection,
    Widget? closeIcon,
    String? tooltip,
    CoreFabStyle? fabStyle,
  }) {
    return Fab(
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
      trigger: trigger ?? this.trigger,
      label: label ?? this.label,
      actions: actions ?? this.actions,
      open: open ?? this.open,
      onOpenChanged: onOpenChanged ?? this.onOpenChanged,
      size: size ?? this.size,
      expandDirection: expandDirection ?? this.expandDirection,
      closeIcon: closeIcon ?? this.closeIcon,
      tooltip: tooltip ?? this.tooltip,
      fabStyle: fabStyle ?? this.fabStyle,
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
    _internalOpen = widget.open;
    _popover.addListener(_handlePopoverChanged);
    // Drive the popover open after the first frame when the FAB starts
    // expanded: the composed `Popover` attaches its show/close handlers in
    // its own `initState`, which runs after this widget's first build.
    if (_isOpen && _hasActions) {
      _scheduleSync();
    }
  }

  /// Whether the parent owns the open state (controlled mode).
  bool get _isControlled => widget.onOpenChanged != null;

  bool get _isOpen => _isControlled ? widget.open : _internalOpen;

  bool get _hasActions => widget.actions != null && widget.actions!.isNotEmpty;

  /// Maps the FAB expand direction onto the popover placement. `up` and
  /// `down` align the panel to the FAB's end edge; `fan` reuses `up` — the
  /// menu opens on that side of the FAB, hit-testable in the overlay.
  ///
  /// `End` is the physical right edge (the placement vocabulary is
  /// physical), so the panel does not mirror under a right-to-left locale.
  CorePopoverPlacement get _placement => switch (widget.expandDirection) {
    .up || .fan => .topEnd,
    .down => .bottomEnd,
    .left => .left,
    .right => .right,
  };

  /// Reconciles the popover controller to match [_isOpen]. Called directly
  /// from pointer-driven handlers (safe — outside build) and via
  /// [_scheduleSync] from lifecycle callbacks (deferred — driving the
  /// overlay during build throws).
  void _syncPopover() {
    if (!mounted || !_hasActions) return;
    if (_isOpen && !_popover.isOpen) {
      _popover.show();
    } else if (!_isOpen && _popover.isOpen) {
      _popover.close();
    }
  }

  void _scheduleSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPopover());
  }

  /// Listener on [_popover] — fires on every open / close transition,
  /// including outside-tap / Escape dismissal driven by the overlay itself.
  void _handlePopoverChanged() {
    if (!mounted) return;
    final open = _popover.isOpen;
    if (open == _isOpen) {
      // Open state already matches — rebuild so the main button swaps its
      // trigger / close glyph.
      setState(() {});
      return;
    }
    // The popover changed independently of us (dismissed) — reconcile.
    if (_isControlled) {
      widget.onOpenChanged?.call(open);
    } else {
      setState(() => _internalOpen = open);
    }
  }

  /// Toggles the speed dial from the main button. Drives the popover in
  /// uncontrolled mode; defers to the parent in controlled mode.
  void _handleToggle() {
    final next = !_isOpen;
    if (_isControlled) {
      widget.onOpenChanged?.call(next);
    } else {
      setState(() => _internalOpen = next);
      _syncPopover();
    }
  }

  void _handleClose() {
    if (!_isOpen) return;
    if (_isControlled) {
      widget.onOpenChanged?.call(false);
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
  Widget _buildMainFab(ResolvedFab resolved) {
    final showClose = _hasActions && _isOpen;
    final child = showClose
        ? (widget.closeIcon ?? const Icon(LucideIcons.x))
        : widget.trigger;

    // Expanded only when there is something to expand. `false` on a
    // plain action button would announce "collapsed, activate to open"
    // for a control that opens nothing — null says nothing, which is
    // what is true. Web states the same condition.
    // Extended — 라벨이 있으면 원이 아니라 알약이다. 높이 사다리와 라벨
    // 크기는 `Button` 이 이미 갖고 있으므로 사이즈를 골라 상속받고, 글리프는
    // `leading` 슬롯으로 간다. 스피드 다이얼일 때는 닫기 아이콘이 트리거를
    // 대체하므로 Extended 가 될 수 없다(생성자 assert 가 조합을 막는다).
    final isExtended = widget.label != null && !_hasActions;

    Widget fab = CoUISemantics(
      expanded: _hasActions ? _isOpen : null,
      child: isExtended
          ? Button(
              onPressed: widget.onPressed,
              size: widget.size.toExtendedButtonSize(),
              buttonStyle: resolved.extendedButtonStyle,
              leading: child,
              child: widget.label!,
            )
          : Button(
              onPressed: _hasActions ? _handleToggle : widget.onPressed,
              buttonStyle: resolved.buttonStyle,
              child: child,
            ),
    );

    if (widget.tooltip != null) {
      fab = Tooltip(
        message: widget.tooltip!,
        child: fab,
      );
    }
    return fab;
  }

  @override
  void didUpdateWidget(Fab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Controlled mode: the parent owns `open`. When it flips, reconcile the
    // overlay after the current build pass (driving it during build throws).
    if (_isControlled && widget.open != oldWidget.open) {
      _scheduleSync();
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
  Widget build(BuildContext context) {
    final resolved = resolveFab(
      context,
      size: widget.size,
      fabStyle: widget.fabStyle,
    );

    final mainFab = _buildMainFab(resolved);

    if (!_hasActions) {
      return mainFab;
    }

    // Host the menu in a composed `Popover`. `manual` open mode: the main
    // button's own `onPressed` toggles the popover (see `_handleToggle`);
    // letting `Popover` also detect the trigger tap would double-toggle.
    // The menu renders in the overlay layer, so it is hit-testable and
    // never clipped by an ancestor's bounds.
    return Popover(
      trigger: mainFab,
      content: _FabMenu(
        actions: widget.actions!,
        resolved: resolved,
        onActionPressed: _handleActionPressed,
      ),
      placement: _placement,
      controller: _popover,
      openTrigger: .manual,
      popoverStyle: resolved.popoverStyle,
    );
  }
}

/// Chain sugar for merging a [CoreFabStyle] patch into [Fab.fabStyle]
/// without hand-reconstructing every field. Mirrors the Web
/// `Fab.withStyle` extension so both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFabStyle.merge` right-side-wins semantics).
extension FabStyleChain on Fab {
  /// Returns a copy of this [Fab] with [patch] merged into [fabStyle]
  /// (patch fields win on conflict).
  Fab withStyle(CoreFabStyle patch) =>
      copyWith(fabStyle: (fabStyle ?? const CoreFabStyle()).merge(patch));
}

/// The menu hosted inside the FAB's [Popover]: a composed `Popup` panel
/// holding one `MenuItem` row per action — the same two primitives `Menu`
/// composes, used directly here because a [FabAction]'s label is a widget,
/// not the string a `Menu` item takes. The rows read top to bottom in the
/// order the caller gave them, whichever side of the FAB the panel opens
/// on.
class _FabMenu extends StatelessWidget {
  const _FabMenu({
    required this.actions,
    required this.resolved,
    required this.onActionPressed,
  });

  final List<FabAction> actions;
  final ResolvedFab resolved;
  final void Function(FabAction action) onActionPressed;

  Widget _buildRow(FabAction action) {
    // `MenuItem.label` is required; an action with no label draws an icon
    // row with an empty text seat. A label stays on one line and ends in an
    // ellipsis once the panel reaches its maximum width, rather than
    // wrapping the row taller (mirrors the Web row's `truncate`).
    final label = action.label;
    Widget row = MenuItem(
      label: label == null
          ? const SizedBox.shrink()
          : DefaultTextStyle.merge(
              softWrap: false,
              overflow: .ellipsis,
              maxLines: 1,
              child: label,
            ),
      // 48 은 touch-target(터치 화면의 권장 크기) — 고정 높이가 아니라
      // 사이즈로 고른다(행의 높이 토큰은 최소 높이라 글자 배율이 커지면
      // 행이 늘어나야 한다).
      size: CoreFabContract.actionItemSize,
      leading: action.icon,
      onPressed: () => onActionPressed(action),
      menuItemStyle: resolved.actionItemStyle,
    );
    if (action.tooltip != null) {
      row = Tooltip(message: action.tooltip!, child: row);
    }
    return row;
  }

  @override
  Widget build(BuildContext context) {
    return Popup(
      popupStyle: resolved.popupStyle,
      children: [for (final action in actions) _buildRow(action)],
    );
  }
}
