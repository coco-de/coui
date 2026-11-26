import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/physics.dart'
    show SpringDescription, SpringSimulation, Tolerance;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, LogicalKeyboardKey;

/// The order a keyboard walks a row in: the leading actions, then the row's own
/// content, then the trailing actions — the document order of the Web seat's
/// DOM, in either reading direction. It is stated rather than left to where
/// the cells happen to be laid out: a closed row clips its actions to nothing,
/// and a row narrower than its actions lays them over one another, so their
/// positions say nothing about the order.
const Map<CoreSwipeSide, NumericFocusOrder> _kPlatterOrder = {
  CoreSwipeSide.leading: NumericFocusOrder(0),
  CoreSwipeSide.trailing: NumericFocusOrder(2),
};
const NumericFocusOrder _kRowOrder = NumericFocusOrder(1);

/// Keeps the row's slot in the stack when a side's platter comes or goes, so
/// the row child keeps its state.
const ValueKey<Symbol> _kRowSlot = ValueKey<Symbol>(#swipeActionsRow);

/// A list row that reveals actions when it is swiped sideways.
///
/// The row is [child]. Dragging it toward the end edge (right in a
/// left-to-right locale) reveals [leadingActions] at the start edge; dragging
/// it toward the start edge reveals [trailingActions] at the end edge. Each
/// action is a composed [Button] — a circle of the `lg` rung — with its label
/// under it, so its chrome is the button's: a theme that restyles `Button`
/// restyles the actions with it. The first action of a side is the outermost,
/// and it is the one a full swipe runs.
///
/// ### How the row moves
///
/// How far the row follows the pointer, how it resists past the actions, when
/// a pull runs the first action and where a released row comes to rest are
/// decided by Core (`CoreSwipeGeometry` / `CoreSwipeDrag`) — the Web seat asks
/// the same code — and this widget only feeds it the framework's drag and
/// paints the answer:
///
/// * a pull past half the actions' width opens them, a flick (400 px/s or
///   more) opens or closes them whatever the distance;
/// * pulling past [fullSwipeThreshold] of the row's width and letting go runs
///   the first action ([allowsFullSwipe] turns this off: the row then
///   resists past the actions instead);
/// * a released row comes to rest on a critically damped spring of
///   `CoreSwipeActionsContract.defaultSettleDuration`, carrying the speed it
///   was released at; with reduced motion on it jumps;
/// * while a side is open, tapping the row closes it instead of reaching
///   [child], and a drag that starts on an open row stays on that side.
///
/// Pressing an action calls its `onPressed` and closes the row.
///
/// ### Keyboard and screen readers
///
/// A swipe is the only way a pointer reaches the actions, so the keyboard has
/// its own: every enabled action stays in the focus order while the row is
/// closed — clipped to nothing, not removed — in the order the Web seat's DOM
/// has (the leading actions, the row's own content, the trailing actions) in
/// either reading direction. Focus reaching one opens its side, so what has
/// focus is seen and the row joins its scope like a swiped one; `Enter` or
/// `Space` runs the focused action and closes the row. `Escape` closes an open
/// row and gives focus back to the row itself, and the key stops there only
/// when it closed something, so a dialog around a closed row still hears it.
/// A disabled action is not a stop.
///
/// A closed row's actions are focusable but are not in the semantics tree
/// until their side is open — a screen reader would otherwise find buttons
/// the screen does not show. For screen readers every enabled action is
/// instead a custom semantics action of the row, named by its label; running
/// one is the same as pressing it.
///
/// Wrap a list in a [SwipeActionScope] to keep one row open at a time. Rows
/// do not close when the list scrolls or on a tap outside the open row.
///
/// Behaviour and semantic fields stay flat on the widget; all chrome flows
/// through the single [swipeActionsStyle].
///
/// Example:
/// ```dart
/// SwipeActions(
///   trailingActions: [
///     CoreSwipeAction(
///       label: 'Delete',
///       icon: Icon(LucideIcons.x),
///       variant: CoreSwipeActionVariant.destructive,
///       onPressed: () => remove(item),
///     ),
///     CoreSwipeAction(
///       label: 'Archive',
///       icon: Icon(LucideIcons.inbox),
///       onPressed: () => archive(item),
///     ),
///   ],
///   child: Text(item.title),
/// )
/// ```
class SwipeActions extends StatefulWidget
    implements CoreSwipeActionsContract<Widget> {
  /// Creates a [SwipeActions].
  const SwipeActions({
    required this.child,
    super.key,
    this.leadingActions = const [],
    this.trailingActions = const [],
    this.allowsFullSwipe = CoreSwipeActionsContract.defaultAllowsFullSwipe,
    this.fullSwipeThreshold =
        CoreSwipeActionsContract.defaultFullSwipeThreshold,
    this.showLabels = CoreSwipeActionsContract.defaultShowLabels,
    this.enabled,
    this.swipeActionsStyle,
  }) : assert(
         fullSwipeThreshold > 0 && fullSwipeThreshold <= 1,
         'fullSwipeThreshold is a fraction of the row: above 0 and at most 1',
       );

  @override
  final List<CoreSwipeAction<Widget>> leadingActions;

  @override
  final List<CoreSwipeAction<Widget>> trailingActions;

  @override
  final bool allowsFullSwipe;

  @override
  final double fullSwipeThreshold;

  @override
  final bool showLabels;

  @override
  final bool? enabled;

  @override
  final CoreSwipeActionsStyle? swipeActionsStyle;

  @override
  final Widget child;

  /// Returns a copy of this [SwipeActions] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  SwipeActions copyWith({
    Key? key,
    List<CoreSwipeAction<Widget>>? leadingActions,
    List<CoreSwipeAction<Widget>>? trailingActions,
    bool? allowsFullSwipe,
    double? fullSwipeThreshold,
    bool? showLabels,
    bool? enabled,
    CoreSwipeActionsStyle? swipeActionsStyle,
    Widget? child,
  }) {
    return SwipeActions(
      key: key ?? this.key,
      leadingActions: leadingActions ?? this.leadingActions,
      trailingActions: trailingActions ?? this.trailingActions,
      allowsFullSwipe: allowsFullSwipe ?? this.allowsFullSwipe,
      fullSwipeThreshold: fullSwipeThreshold ?? this.fullSwipeThreshold,
      showLabels: showLabels ?? this.showLabels,
      enabled: enabled ?? this.enabled,
      swipeActionsStyle: swipeActionsStyle ?? this.swipeActionsStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

/// Chain sugar — merges a [CoreSwipeActionsStyle] patch into
/// [SwipeActions.swipeActionsStyle] via [SwipeActions.copyWith] (patch fields
/// win on conflict).
extension SwipeActionsStyleChain on SwipeActions {
  /// Returns a copy of this [SwipeActions] with [patch] merged into
  /// [swipeActionsStyle].
  SwipeActions withStyle(CoreSwipeActionsStyle patch) => copyWith(
    swipeActionsStyle: (swipeActionsStyle ?? const CoreSwipeActionsStyle())
        .merge(patch),
  );
}

class _SwipeActionsState extends State<SwipeActions>
    with SingleTickerProviderStateMixin {
  /// The row's offset (logical px, physical sign: positive is toward the
  /// right). A drag writes it; the settle animates it. Unbounded: a full
  /// swipe carries the row as far as its own width.
  late final AnimationController _offset = AnimationController.unbounded(
    vsync: this,
  );

  late ResolvedSwipeActions _resolved;
  bool _rtl = false;
  double _rowWidth = 0;
  CoreSwipeDrag? _drag;
  bool _pointerCancelled = false;
  CoreSwipeExclusivity? _scope;
  double _settleTarget = 0;
  bool _settling = false;

  /// The row as a place focus can be sent to without being a stop in the tab
  /// order — what the Web root's `tabindex="-1"` is. An action about to be
  /// clipped away hands its focus here.
  final FocusNode _rowFocus = FocusNode(
    debugLabel: 'SwipeActions',
    skipTraversal: true,
  );

  /// Whether focus is inside a side's actions, and the moment it arrives
  /// there. The nodes take no focus themselves and are not stops.
  late final Map<CoreSwipeSide, FocusNode> _platterFocus = {
    for (final side in CoreSwipeSide.values)
      side: FocusNode(
        debugLabel: 'SwipeActions ${side.name} actions',
        canRequestFocus: false,
        skipTraversal: true,
      ),
  };

  /// Orders the row's three parts by [_kPlatterOrder] and [_kRowOrder]. A
  /// tie — the cells of one platter — keeps the order they were built in,
  /// which is the platter's visual order.
  late final FocusTraversalPolicy _traversal = OrderedTraversalPolicy(
    secondary: WidgetOrderTraversalPolicy(),
  );

  bool get _enabled => widget.enabled ?? true;

  List<CoreSwipeAction<Widget>> _actionsOf(CoreSwipeSide side) =>
      side == CoreSwipeSide.leading
      ? widget.leadingActions
      : widget.trailingActions;

  @override
  void initState() {
    super.initState();
    _offset.addStatusListener(_handleStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (rtl == _rtl) return;
    _rtl = rtl;
    // An open row would point the other way under the new direction; closing
    // it without a settle is the one pose that is right in both.
    _returnFocus();
    _drag = null;
    _settling = false;
    _offset
      ..stop()
      ..value = 0;
    _scope?.release(this);
  }

  @override
  void didUpdateWidget(SwipeActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_offset.value == 0 && _drag == null && !_settling) return;
    // An open row's travel is the width of the platter it uncovers, which is
    // a function of how many actions there are: a row whose actions changed in
    // number would rest at the old width — partly covering the new cells or
    // leaving dead space — so it closes, as the Web seat's row does. A row
    // that can no longer be swiped closes too. Closing hands focus back to
    // the row first, so none is left on a cell the rebuild is about to
    // replace or remove.
    final countChanged =
        oldWidget.leadingActions.length != widget.leadingActions.length ||
        oldWidget.trailingActions.length != widget.trailingActions.length;
    if (!_enabled || countChanged) _close();
  }

  @override
  void dispose() {
    _scope?.release(this);
    _offset
      ..removeStatusListener(_handleStatus)
      ..dispose();
    _rowFocus.dispose();
    for (final node in _platterFocus.values) {
      node.dispose();
    }
    super.dispose();
  }

  // ─── Geometry ─────────────────────────────────────

  /// The measures a drag runs in: Core answers every question about the
  /// row's position from these, so nothing here negates for the reading
  /// direction.
  CoreSwipeGeometry _geometry(double rowWidth) {
    final leading = widget.leadingActions;
    final trailing = widget.trailingActions;

    return CoreSwipeGeometry(
      rowWidth: rowWidth,
      leadingExtent: _resolved.leadingExtent,
      trailingExtent: _resolved.trailingExtent,
      leadingFullSwipe:
          widget.allowsFullSwipe && leading.isNotEmpty && leading.first.enabled,
      trailingFullSwipe:
          widget.allowsFullSwipe &&
          trailing.isNotEmpty &&
          trailing.first.enabled,
      fullSwipeThreshold: widget.fullSwipeThreshold,
      rtl: _rtl,
    );
  }

  // ─── Drag ─────────────────────────────────────────

  void _handleDragStart(DragStartDetails details) {
    _offset.stop();
    _settling = false;
    _pointerCancelled = false;
    _rowWidth = context.size?.width ?? 0;
    _drag = CoreSwipeDrag(
      _geometry(_rowWidth),
      anchor: details.globalPosition.dx,
      startOffset: _offset.value,
    );
    _claim();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final drag = _drag;
    if (drag == null) return;
    _offset.value = drag.update(details.globalPosition.dx);
  }

  void _handleDragEnd(DragEndDetails details) {
    final drag = _drag;
    if (drag == null) return;
    // The framework reports a pointer the system took (an edge gesture, a
    // second finger) through the same `onEnd` as a lift, with whatever
    // velocity it measured; only the raw event tells them apart. A cancelled
    // pull goes back to where it began and never runs an action.
    final cancelled = _pointerCancelled;
    _pointerCancelled = false;
    _apply(
      cancelled ? drag.cancel() : drag.release(details.primaryVelocity ?? 0),
    );
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_drag != null) _pointerCancelled = true;
  }

  /// Settles on what the release decided, and runs the first action of a
  /// side when the pull went far enough.
  void _apply(CoreSwipeRelease release) {
    _settleTo(release.target, velocity: release.velocity);

    final outcome = release.outcome;
    if (!outcome.executes) return;
    final actions = outcome.side == CoreSwipeSide.leading
        ? widget.leadingActions
        : widget.trailingActions;
    // The list may have changed under the finger; what runs is the first
    // action of the side as it is now, and only if it can still be run.
    final first = actions.firstOrNull;
    if (first != null && first.enabled) first.onPressed();
  }

  // ─── Settle ───────────────────────────────────────

  /// Brings the row to rest at [target] (physical px) on a critically damped
  /// spring of the resolved settle duration, carrying [velocity] (px/s) — the
  /// pointer's speed at the release. With reduced motion — a zero duration —
  /// it jumps.
  void _settleTo(double target, {double velocity = 0}) {
    _drag = null;
    _offset.stop();
    _settleTarget = target;

    // A row already at its target has nothing to travel, whatever the pointer
    // was doing: one flicked toward a side with no actions never left rest,
    // and carrying the flick into the spring would kick it sideways.
    final from = _offset.value;
    final distance = (target - from).abs();
    final duration = _resolved.settleDuration;
    if (duration == Duration.zero ||
        distance <= CoreSwipeActionsContract.restTolerance) {
      _offset.value = target;
      _settled();

      return;
    }

    // Critically damped (no bounce): natural frequency 2π / duration, and it
    // reaches the target without crossing it only while the speed carried
    // toward it is at most that frequency × the distance left. A harder
    // flick is held to that, so the row decelerates into rest the way the
    // contract says instead of flying past it and coming back.
    final omega = 2 * math.pi / (duration.inMicroseconds / 1e6);
    final toward = (target - from).sign;
    final carried = velocity * toward > omega * distance
        ? toward * omega * distance
        : velocity;

    _settling = true;
    _offset.animateWith(
      SpringSimulation(
        SpringDescription.withDurationAndBounce(duration: duration),
        from,
        target,
        carried,
        tolerance: const Tolerance(
          distance: CoreSwipeActionsContract.restTolerance,
          velocity: CoreSwipeActionsContract.restTolerance,
        ),
      ),
    );
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_settling) return;
    // The spring is done within a pixel of rest; the row rests exactly on it.
    _offset.value = _settleTarget;
    _settled();
  }

  void _settled() {
    _settling = false;
    if (_settleTarget == 0) {
      // A row at rest closed holds no focus in the actions it has hidden,
      // whatever closed it.
      _returnFocus();
      _scope?.release(this);
    }
  }

  /// Animates the row closed. Also what a scope calls when another row
  /// starts to move.
  void _close() {
    _returnFocus();
    _settleTo(0);
  }

  void _handleOverlayTap() => _close();

  // ─── Keyboard and focus ───────────────────────────

  /// Whether focus is inside the actions of either side.
  bool get _focusInPlatters =>
      _platterFocus.values.any((node) => node.hasFocus);

  /// Whether a side is open or on its way open: what `Escape` has to close.
  bool get _isOpen => _settling
      ? _settleTarget != 0
      : _geometry(_rowWidth).sideOf(_offset.value) != null;

  /// Takes focus off an action that is about to be clipped to nothing, onto
  /// the row — the place a keyboard user was working in. Nothing happens when
  /// focus is elsewhere.
  void _returnFocus() {
    if (_focusInPlatters) _rowFocus.requestFocus();
  }

  /// Focus arrived inside [side]'s actions, or left them.
  void _handlePlatterFocus(CoreSwipeSide side, {required bool hasFocus}) {
    if (hasFocus && _enabled) _open(side);
  }

  /// Opens [side] without a pointer: focus reached one of its actions, so the
  /// side comes out where the focused action is seen. The row takes the scope
  /// as a swiped row does, which closes the row that held it.
  void _open(CoreSwipeSide side) {
    _rowWidth = context.size?.width ?? _rowWidth;
    final geometry = _geometry(_rowWidth);
    if (geometry.extentOf(side) <= 0) return;

    _drag = null;
    _claim();
    final target = geometry.openOffsetOf(side);
    if (_settling && _settleTarget == target) return;
    if (!_settling &&
        (_offset.value - target).abs() <=
            CoreSwipeActionsContract.restTolerance) {
      return;
    }
    _settleTo(target);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        !_isOpen) {
      return KeyEventResult.ignored;
    }
    // The key closed the row; it must not also close a dialog around it.
    _close();

    return KeyEventResult.handled;
  }

  // ─── Scope ────────────────────────────────────────

  void _claim() {
    final scope = SwipeActionScope.maybeOf(context);
    if (!identical(scope, _scope)) _scope?.release(this);
    _scope = scope;
    scope?.claim(this, _close);
  }

  // ─── Actions ──────────────────────────────────────

  /// Runs [action] — pressed, or chosen through the row's semantics — and
  /// closes the row.
  ///
  /// Focus leaves the action before it runs, and the row settles closed
  /// without asking for focus again: the framework applies a request for
  /// focus a moment later, so a hand-off made after the action would be the
  /// last request and take focus back from wherever the action sent it.
  void _run(CoreSwipeAction<Widget> action) {
    _returnFocus();
    action.onPressed();
    if (mounted) _settleTo(0);
  }

  // ─── Build ────────────────────────────────────────

  /// One action: its button, and its label under it. The outermost cell is
  /// the one a full swipe runs, so it alone carries the cue that releasing
  /// now would ([pullsToExecute]) — grown by `fullSwipeScale`.
  Widget _cell(
    CoreSwipeAction<Widget> action, {
    required bool outermost,
    required bool pullsToExecute,
  }) {
    final resolved = _resolved;

    Widget cell = SizedBox(
      width: resolved.actionWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The label is the button's accessible name; the glyph inside it
          // has none, and the visible label below is left out of semantics
          // so it is not read twice. The node replaces the button's own, so
          // it carries the button's focus too: a screen reader follows the
          // keyboard onto it.
          Focus(
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            child: Builder(
              builder: (context) => Semantics(
                container: true,
                label: action.label,
                button: true,
                enabled: action.enabled,
                focused: action.enabled ? Focus.of(context).hasFocus : null,
                onTap: action.enabled ? () => _run(action) : null,
                excludeSemantics: true,
                child: Button(
                  variant: action.variant.toButtonVariant(),
                  size: CoreSwipeActionsContract.actionButtonSize,
                  shape: CoreSwipeActionsContract.actionButtonShape,
                  enabled: action.enabled,
                  buttonStyle: resolved.actionButtonStyle,
                  onPressed: () => _run(action),
                  child: action.icon ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          if (widget.showLabels) ...[
            Gap(gapStyle: resolved.labelGapStyle),
            ExcludeSemantics(
              child: Text(
                action.label,
                style: resolved.labelTextStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );

    // A scale of 1 is no cue: nothing is wrapped, and the default look stays
    // what it was. The wrapper is on the outermost cell whether or not the
    // cue is up, so its growth animates instead of the cell being rebuilt.
    if (outermost && resolved.fullSwipeScale != 1) {
      cell = AnimatedScale(
        scale: pullsToExecute ? resolved.fullSwipeScale : 1,
        duration: resolved.settleDuration,
        curve: resolved.scaleCurve,
        child: cell,
      );
    }

    return cell;
  }

  /// The strip on [side]: [revealed] px of it uncovered, anchored to the outer
  /// edge, with the actions in a row inside. A closed side is `0` px wide, not
  /// absent — its cells stay laid out and focusable, and clip to nothing — and
  /// [shown] says whether the side is uncovered, which is when its cells are
  /// in the semantics tree. [pullsToExecute] is the full-swipe cue — releasing
  /// now would run the first action.
  Widget _platter(
    CoreSwipeSide side, {
    required double revealed,
    required bool shown,
    required bool pullsToExecute,
  }) {
    final resolved = _resolved;
    final leading = side == CoreSwipeSide.leading;
    final actions = _actionsOf(side);
    final extent = leading ? resolved.leadingExtent : resolved.trailingExtent;
    final first = actions.isEmpty ? null : actions.first;

    // Reading order, start to end: the outermost action is at the platter's
    // outer edge, so the leading platter reads outermost first and the
    // trailing one outermost last — in either direction.
    final ordered = leading ? actions : actions.reversed.toList();

    Widget strip = ClipRect(
      child: OverflowBox(
        alignment: leading
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        minWidth: extent,
        maxWidth: extent,
        minHeight: 0,
        maxHeight: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: resolved.platterInset),
          child: Row(
            spacing: resolved.actionSpacing,
            children: [
              for (final action in ordered)
                _cell(
                  action,
                  outermost: identical(action, first),
                  pullsToExecute: pullsToExecute,
                ),
            ],
          ),
        ),
      ),
    );

    final fill = resolved.platterColor;
    if (fill != null) strip = ColoredBox(color: fill, child: strip);

    return PositionedDirectional(
      key: ValueKey(side),
      start: leading ? 0 : null,
      end: leading ? null : 0,
      top: 0,
      bottom: 0,
      width: revealed,
      child: FocusTraversalOrder(
        order: _kPlatterOrder[side]!,
        child: Focus(
          focusNode: _platterFocus[side],
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onFocusChange: (hasFocus) =>
              _handlePlatterFocus(side, hasFocus: hasFocus),
          child: ExcludeSemantics(excluding: !shown, child: strip),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _resolved = resolveSwipeActions(
      context,
      leadingCount: widget.leadingActions.length,
      trailingCount: widget.trailingActions.length,
      swipeActionsStyle: widget.swipeActionsStyle,
    );

    // Every enabled action, in reading order — the leading platter outermost
    // first, then the trailing one outermost last.
    final named = [
      ...widget.leadingActions,
      ...widget.trailingActions.reversed,
    ].where((action) => action.enabled);
    final semanticsActions = _enabled && named.isNotEmpty
        ? {
            for (final action in named)
              CustomSemanticsAction(label: action.label): () => _run(action),
          }
        : null;

    return Listener(
      onPointerCancel: _handlePointerCancel,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        onHorizontalDragStart: _enabled ? _handleDragStart : null,
        onHorizontalDragUpdate: _enabled ? _handleDragUpdate : null,
        onHorizontalDragEnd: _enabled ? _handleDragEnd : null,
        child: Focus(
          focusNode: _rowFocus,
          includeSemantics: false,
          onKeyEvent: _handleKeyEvent,
          child: FocusTraversalGroup(
            policy: _traversal,
            child: AnimatedBuilder(
              animation: _offset,
              child: widget.child,
              builder: (context, row) {
                final offset = _offset.value;
                final geometry = _geometry(_rowWidth);
                final revealedSide = _enabled ? geometry.sideOf(offset) : null;

                return Stacks(
                  fit: CoreStackFit.passthrough,
                  children: [
                    // Both sides are built while the row can be swiped, so
                    // that a keyboard finds the actions of a closed row.
                    for (final side in CoreSwipeSide.values)
                      if (_enabled && _actionsOf(side).isNotEmpty)
                        _platter(
                          side,
                          revealed: side == revealedSide ? offset.abs() : 0,
                          shown: side == revealedSide,
                          pullsToExecute:
                              side == revealedSide &&
                              geometry.settle(offset).executes,
                        ),
                    FocusTraversalOrder(
                      key: _kRowSlot,
                      order: _kRowOrder,
                      // The row's own content keeps its own traversal; the
                      // group makes it one stop of this order.
                      child: FocusTraversalGroup(
                        child: Transform.translate(
                          offset: Offset(offset, 0),
                          child: Semantics(
                            container: semanticsActions != null,
                            customSemanticsActions: semanticsActions,
                            child: Stacks(
                              fit: CoreStackFit.passthrough,
                              children: [
                                row!,
                                // While a side is open the row is a button that
                                // closes it: the tap does not reach [child].
                                if (revealedSide != null)
                                  Position.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      excludeFromSemantics: true,
                                      onTap: _handleOverlayTap,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
