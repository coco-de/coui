import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/layout/swipe_actions/swipe_action_scope.dart';
import 'package:coui_web/src/components/layout/swipe_actions/swipe_actions_row.dart';
import 'package:coui_web/src/components/layout/swipe_actions/swipe_actions_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Source of the generated element ids, so a focus restored from an action
/// can find its row without the caller having to name it.
int _swipeActionsIdCounter = 0;

/// What a press must not start a swipe on: it belongs to a text caret.
const String _kTextControlSelector =
    'input, textarea, select, [contenteditable]:not([contenteditable="false"])';

/// A list row that reveals actions when it is swiped sideways.
///
/// The row is [child]. Dragging it toward the end edge uncovers
/// [leadingActions] at the start edge; dragging it toward the start edge
/// uncovers [trailingActions] at the end edge. Each action is a circular
/// `Button` with its label under it, so its chrome is the button's.
///
/// A pull past [fullSwipeThreshold] of the row's width runs the first action
/// of that side on release ([allowsFullSwipe]). Rows inside a
/// [SwipeActionScope] share one open row.
///
/// Behaviour — how far the row follows the pointer, when a release opens it
/// or runs an action — is Core's (`CoreSwipeGeometry` / `CoreSwipeGesture`);
/// the browser supplies pointer events and a layout, and this component
/// measures the latter when a press begins.
///
/// The actions stay in the DOM, clipped to the revealed width and never
/// hidden, so they are reachable by keyboard and assistive technology:
/// `Tab` into one opens its side, `Escape` closes the row. A disabled row
/// exposes no action at all. When the row comes to rest closed with focus on
/// one of its actions, focus goes to the row itself — whatever closed it:
/// `Escape`, a pressed action, a pan or flick, a tap on the content, another
/// row of the scope opening, an update that changes how many actions there are
/// or that disables the row. The action is clipped to nothing by then. Focus
/// anywhere else stays where it is.
///
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
///
/// There is no close-on-scroll or close-on-outside-tap: an open row closes
/// when another row of its scope moves, when its own content is tapped, or on
/// `Escape`.
class SwipeActions extends UiStatefulComponent
    implements CoreSwipeActionsContract<Component> {
  /// Creates a [SwipeActions].
  const SwipeActions({
    required this.child,
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
         'fullSwipeThreshold must be above 0 and at most 1',
       );

  @override
  final List<CoreSwipeAction<Component>> leadingActions;

  @override
  final List<CoreSwipeAction<Component>> trailingActions;

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
  final Component child;

  /// Returns a copy of this [SwipeActions] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  SwipeActions copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiInputEventHandler? onChange,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    List<CoreSwipeAction<Component>>? leadingActions,
    List<CoreSwipeAction<Component>>? trailingActions,
    bool? allowsFullSwipe,
    double? fullSwipeThreshold,
    bool? showLabels,
    bool? enabled,
    CoreSwipeActionsStyle? swipeActionsStyle,
    Component? child,
  }) {
    return SwipeActions(
      key: key ?? this.key,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onClick: onClick ?? this.onClick,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
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

/// Chain sugar mirroring the Flutter `SwipeActions.withStyle` extension —
/// merges a [CoreSwipeActionsStyle] patch into
/// [SwipeActions.swipeActionsStyle] via [SwipeActions.copyWith].
extension SwipeActionsStyleChain on SwipeActions {
  /// Returns a copy of this [SwipeActions] with [patch] merged into
  /// [swipeActionsStyle] (patch fields win on conflict).
  SwipeActions withStyle(CoreSwipeActionsStyle patch) => copyWith(
    swipeActionsStyle: (swipeActionsStyle ?? const CoreSwipeActionsStyle())
        .merge(patch),
  );
}

class _SwipeActionsState extends State<SwipeActions> {
  final String _generatedId = 'coui-swipe-actions-${_swipeActionsIdCounter++}';
  late final SwipeActionsRow _row = SwipeActionsRow(
    onChanged: _handleChanged,
    onExecute: _handleExecute,
  );

  /// The pointer a press is following, or `null` between presses. A second
  /// finger never joins a swipe that is under way.
  int? _activePointer;
  bool _captured = false;
  bool _updating = false;

  /// Whether the row rested open at the last change it reported, so that the
  /// change which closes it can be told from every other.
  bool _wasOpen = false;
  Timer? _clickTimer;

  String get _rootId => component.id ?? _generatedId;

  /// Whether [row] can be swiped: it is enabled and has something to reveal.
  /// A row that cannot be swiped renders no platter and takes no pointer.
  static bool _isSwipeable(SwipeActions row) =>
      (row.enabled ?? true) &&
      (row.leadingActions.isNotEmpty || row.trailingActions.isNotEmpty);

  bool get _swipeable => _isSwipeable(component);

  @override
  void initState() {
    super.initState();
    _row.enabled = component.enabled ?? true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _row.scope = SwipeActionScope.maybeOf(context);
  }

  @override
  void didUpdateComponent(covariant SwipeActions oldComponent) {
    super.didUpdateComponent(oldComponent);
    final countChanged =
        oldComponent.leadingActions.length != component.leadingActions.length ||
        oldComponent.trailingActions.length != component.trailingActions.length;

    // This update closes the row, or takes its platters away. The old actions
    // are still in the document, so this is the moment to tell whether a
    // keyboard user is on one of them; moving focus waits until the update is
    // over.
    if (countChanged ||
        (_isSwipeable(oldComponent) && !_isSwipeable(component))) {
      _keepPlace(oldComponent.id ?? _generatedId);
    }

    // A rebuild is already under way, so the row's own change notifications
    // must not ask for another.
    _updating = true;
    try {
      _row.enabled = component.enabled ?? true;
      // The open row's travel was measured for the old actions.
      if (countChanged) _row.close();
    } finally {
      _updating = false;
    }
  }

  @override
  void dispose() {
    _clickTimer?.cancel();
    _row.dispose();
    super.dispose();
  }

  // ─── Row model callbacks ───────────────────────────────

  void _handleChanged() {
    // What the next change is measured against. It is kept even while an
    // update is under way: that update reports its own closing.
    final closed = _wasOpen && !_row.isOpen;
    _wasOpen = _row.isOpen;

    if (!mounted || _updating) return;
    // However the row came to rest closed — a release, a flick, a tap on its
    // content, another row of the scope opening — a keyboard user on one of
    // its actions keeps their place on the row.
    if (closed) _keepPlace(_rootId);
    setState(() {});
  }

  /// A release ran the first action of [side].
  void _handleExecute(CoreSwipeSide side) {
    final actions = side == CoreSwipeSide.leading
        ? component.leadingActions
        : component.trailingActions;
    if (actions.isEmpty) return;

    actions.first.onPressed();
  }

  /// An action's button was pressed: run it, then close the row. Whether a
  /// keyboard user on the button keeps their place on the row is decided by
  /// the close, after the action has run: an action that moves focus on has
  /// moved it.
  void _handlePress(CoreSwipeAction<Component> action) =>
      _row.press(action.onPressed);

  // ─── Measurement ───────────────────────────────────────

  /// Whether the first action of [actions] can be run by a full swipe.
  bool _fullSwipeOn(List<CoreSwipeAction<Component>> actions) =>
      component.allowsFullSwipe && actions.isNotEmpty && actions.first.enabled;

  /// What the DOM says now: the row's width, how wide each strip is, which
  /// way the text runs. The strips are measured rather than computed so the
  /// row's travel is the rendered width at every density and zoom.
  CoreSwipeGeometry? _measure(web.Element root) {
    final rootRect = elementRect(root);
    if (rootRect == null) return null;

    return CoreSwipeGeometry(
      rowWidth: rootRect.width,
      leadingExtent: _stripWidth(root, 'leading'),
      trailingExtent: _stripWidth(root, 'trailing'),
      leadingFullSwipe: _fullSwipeOn(component.leadingActions),
      trailingFullSwipe: _fullSwipeOn(component.trailingActions),
      fullSwipeThreshold: component.fullSwipeThreshold,
      rtl: isElementRtl(root),
    );
  }

  double _stripWidth(web.Element root, String side) {
    final strip = root.querySelector(
      ':scope > [data-swipe-platter="$side"] > [data-swipe-strip]',
    );

    return elementRect(strip)?.width ?? 0;
  }

  /// Where the row is painted now, relative to its closed position — a row
  /// grabbed while it settles is somewhere short of where it is heading.
  double? _paintedOffset(web.Element root, double rootLeft) {
    final row = root.querySelector(':scope > [data-swipe-row]');
    final rect = elementRect(row);

    return rect == null ? null : rect.left - rootLeft;
  }

  /// The event's own clock, as a [Duration] — a busy main thread does not
  /// slow a flick down. `timeStamp` is in milliseconds.
  Duration _timeOf(web.Event event) => Duration(
    microseconds: (event.timeStamp * Duration.microsecondsPerMillisecond)
        .round(),
  );

  // ─── Pointer ───────────────────────────────────────────

  void _handlePointerDown(web.PointerEvent event, web.HTMLElement root) {
    if (!_swipeable || _activePointer != null) return;
    if (!event.isPrimary || event.button != 0) return;
    if (_startsOnTextControl(event)) return;

    final x = mouseClientX(event);
    final y = mouseClientY(event);
    final measured = _measure(root);
    if (x == null || y == null || measured == null) return;

    final rootLeft = elementRect(root)?.left;
    final tracked = _row.pointerDown(
      _timeOf(event),
      x,
      y,
      measured,
      paintedOffset: rootLeft == null ? null : _paintedOffset(root, rootLeft),
    );
    if (!tracked) return;

    _activePointer = event.pointerId;
    _captured = false;
  }

  void _handlePointerMove(web.PointerEvent event, web.HTMLElement root) {
    if (_activePointer != event.pointerId) return;
    final x = mouseClientX(event);
    final y = mouseClientY(event);
    if (x == null || y == null) return;

    final phase = _row.pointerMove(_timeOf(event), x, y);
    if (phase == CoreSwipePhase.rejected) {
      // Vertical: the press belongs to a scroller.
      _activePointer = null;
    } else if (phase == CoreSwipePhase.dragging && !_captured) {
      // Capture once the swipe arms, so it keeps streaming here when the
      // pointer leaves the row — capturing on the press would redirect the
      // click of a button the press merely lands on.
      root.setPointerCapture(event.pointerId);
      _captured = true;
      web.window.getSelection()?.removeAllRanges();
    }
  }

  void _handlePointerUp(web.PointerEvent event, web.HTMLElement root) {
    if (_activePointer != event.pointerId) return;
    _activePointer = null;
    _captured = false;

    final release = _row.pointerUp(_timeOf(event));
    if (release == null) return;

    // The browser sends the click of a drag's release to the element that
    // held the pointer; a touch lift sends none. Either way the flag is gone
    // before the next real click.
    _clickTimer?.cancel();
    _clickTimer = Timer(Duration.zero, _row.forgetSwallowedClick);
  }

  void _handlePointerCancel(web.PointerEvent event, web.HTMLElement root) {
    if (_activePointer != event.pointerId) return;
    _activePointer = null;
    _captured = false;
    _row.pointerCancel();
  }

  /// The browser's own drag of an image or a link would take the pointer
  /// away from the swipe; an element that asks to be dragged is left alone.
  void _handleDragStart(web.DragEvent event) {
    if (_activePointer == null) return;
    if (event.target case final web.Element target) {
      if (target.closest('[draggable="true"]') != null) return;
    }
    event.preventDefault();
  }

  /// The click that ends a drag is the drag's own: it must reach neither the
  /// row's content nor the caller's `onClick`.
  void _handleClick(web.Event event, EventCallback? callerClick) {
    if (_row.takeSwallowedClick()) {
      event.stopImmediatePropagation();

      return;
    }
    callerClick?.call(event);
  }

  /// [caller] without the events an action sends up through the row.
  ///
  /// A press on an action, by pointer or by `Enter`, bubbles through the row's
  /// element like any other; the caller's `onClick` / `onKeyDown` on the row
  /// mean the row's content, so an action must not run them as well. That
  /// holds for any row's action, the row's own and one in the content of a row
  /// nested inside it: on Flutter an action is a button that wins the press, so
  /// no handler of a row around it hears it, and the Web row answers the same.
  EventCallback? _unlessFromAction(EventCallback? caller) {
    if (caller == null) return null;

    return (web.Event event) {
      if (!_cameFromAction(event)) caller(event);
    };
  }

  /// Whether [event] was sent from inside an action platter — this row's or a
  /// nested row's, whichever is nearest to the target.
  bool _cameFromAction(web.Event event) {
    if (event.target case final web.Element target) {
      return target.closest('[data-swipe-platter]') != null;
    }

    return false;
  }

  bool _startsOnTextControl(web.Event event) {
    if (event.target case final web.Element target) {
      return target.closest(_kTextControlSelector) != null;
    }

    return false;
  }

  // ─── Keyboard and focus ────────────────────────────────

  /// Focus reached an action: its side opens, so what has focus is seen.
  void _handleFocusIn(web.Event event, web.Element target) {
    if (!_row.enabled) return;
    if (event.currentTarget case final web.Element root) {
      final platter = target.closest('[data-swipe-platter]');
      // A platter of a row nested in this one's content is that row's.
      if (platter == null || !identical(platter.parentElement, root)) return;

      final side = platter.getAttribute('data-swipe-platter') == 'leading'
          ? CoreSwipeSide.leading
          : CoreSwipeSide.trailing;
      final measured = _measure(root);
      if (measured != null) _row.open(side, measured);
    }
  }

  void _handleKeyDown(web.KeyboardEvent event) {
    if (event.key != 'Escape') return;

    // A key that closed the row must not also close a dialog around it; a row
    // with nothing to close lets it go on up.
    if (_row.escape()) event.stopPropagation();
  }

  /// A tap on the open row closes it instead of reaching its content.
  void _handleCatcherClick(web.MouseEvent event) {
    event.stopPropagation();
    _row.close();
  }

  /// Whether focus is on one of the row's own actions. A platter of a row
  /// nested in the row's content is that row's.
  bool _focusIsInPlatter(web.Element root) {
    final platter = web.document.activeElement?.closest(
      '[data-swipe-platter]',
    );

    return platter != null && identical(platter.parentElement, root);
  }

  /// Whether focus has nowhere in particular to be: the document itself has
  /// it, or one of the row's actions still does. An element that took focus
  /// since is where a user or the host put it.
  bool _focusIsAdrift(web.Element root) {
    final active = web.document.activeElement;
    if (active == null) return true;
    if (identical(active, web.document.body) ||
        identical(active, web.document.documentElement)) {
      return true;
    }

    return _focusIsInPlatter(root);
  }

  /// Moves focus off a button that is about to be clipped to nothing, onto
  /// the row — the place a keyboard user was working in. It never scrolls:
  /// another row's pan can close this one while it is out of view.
  void _focusRoot(web.Element? root) {
    if (root case final web.HTMLElement element) {
      element.focus(web.FocusOptions(preventScroll: true));
    }
  }

  /// A keyboard user on one of the row's actions keeps their place on the row
  /// when the row comes to rest closed or loses its platters. Left there,
  /// focus would sit on a button clipped to nothing, or — when the button
  /// goes — fall to the document. Focus anywhere else stays where it is.
  ///
  /// The old actions are in the document now, so this is the moment to tell
  /// whether focus is on one; [rootId] is the id they carry, which an update
  /// may be changing. Moving focus waits until the caller's work is done: the
  /// caller may be inside a build pass, where the focus event would run page
  /// handlers that rebuild, and an update's own changes to the document are
  /// not in yet. It then looks the row up by the id it has by then, and leaves
  /// focus alone if something else took it meanwhile.
  void _keepPlace(String rootId) {
    if (!kIsWeb) return;

    final root = web.document.getElementById(rootId);
    if (root == null || !_focusIsInPlatter(root)) return;

    scheduleMicrotask(() {
      if (!mounted) return;

      final current = web.document.getElementById(_rootId);
      if (current != null && _focusIsAdrift(current)) _focusRoot(current);
    });
  }

  // ─── Build ─────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    final resolved = resolveSwipeActions(
      context,
      offset: _row.offset,
      revealedSide: _row.revealedSide,
      dragging: _row.dragging,
      inFullSwipeZone: _row.inFullSwipeZone,
      interactive: _swipeable,
      swipeActionsStyle: component.swipeActionsStyle,
    );

    final callerEvents = component.events;
    final callerClick = _unlessFromAction(callerEvents['click']);
    final callerKeyDown = _unlessFromAction(callerEvents['keydown']);
    final callerKeyUp = _unlessFromAction(callerEvents['keyup']);
    final events = <String, EventCallback>{
      ...callerEvents,
      'keyup': ?callerKeyUp,
      if (_swipeable) ...{
        'pointerdown': EventHandlers.chain(
          callerEvents['pointerdown'],
          EventHandlers.createPointerCurrentTargetEventHandler(
            _handlePointerDown,
          ),
        ),
        'pointermove': EventHandlers.chain(
          callerEvents['pointermove'],
          EventHandlers.createPointerCurrentTargetEventHandler(
            _handlePointerMove,
          ),
        ),
        'pointerup': EventHandlers.chain(
          callerEvents['pointerup'],
          EventHandlers.createPointerCurrentTargetEventHandler(
            _handlePointerUp,
          ),
        ),
        'pointercancel': EventHandlers.chain(
          callerEvents['pointercancel'],
          EventHandlers.createPointerCurrentTargetEventHandler(
            _handlePointerCancel,
          ),
        ),
        'dragstart': EventHandlers.chain(
          callerEvents['dragstart'],
          EventHandlers.createDragEventHandler(_handleDragStart),
        ),
        'focusin': EventHandlers.chain(
          callerEvents['focusin'],
          EventHandlers.createElementTargetEventHandler(_handleFocusIn),
        ),
        'keydown': EventHandlers.chain(
          callerKeyDown,
          EventHandlers.createKeyboardEventHandler(_handleKeyDown),
        ),
        'click': (web.Event event) => _handleClick(event, callerClick),
      } else ...{
        'keydown': ?callerKeyDown,
        'click': ?callerClick,
      },
    };

    final side = _row.restingSide;
    final state = _row.dragging
        ? 'dragging'
        : side == null
        ? 'closed'
        : 'open';

    return Component.element(
      tag: 'div',
      id: _rootId,
      classes: component.rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?component.css]),
      attributes: {
        'data-swipe-actions': '',
        'data-swipe-state': state,
        'data-swipe-side': ?side?.name,
        // A place focus can be sent to, never a Tab stop — and one that stays
        // when nothing can be swiped any more: an action that goes away hands
        // its focus here, and an attribute dropped by the same update would
        // drop the focus with it.
        'tabindex': '-1',
        ...component.componentAttributes,
      },
      events: events,
      children: [
        if (_swipeable) ..._buildPlatter(CoreSwipeSide.leading, resolved),
        _buildRow(resolved),
        if (_swipeable) ..._buildPlatter(CoreSwipeSide.trailing, resolved),
      ],
    );
  }

  Component _buildRow(ResolvedSwipeActions resolved) {
    return Component.element(
      tag: 'div',
      classes: resolved.row.className,
      styles: resolved.row.inlineStyles,
      attributes: const {'data-swipe-row': ''},
      children: [
        component.child,
        // While open, the whole row is a close button for the eye — a tap
        // anywhere on it closes it instead of reaching its content.
        if (_row.isOpen && !_row.dragging)
          Component.element(
            tag: 'div',
            classes: resolved.tapCatcher.className,
            styles: resolved.tapCatcher.inlineStyles,
            attributes: const {
              'aria-hidden': 'true',
              'data-swipe-tap-catcher': '',
            },
            events: {
              'click': EventHandlers.createMouseEventHandler(
                _handleCatcherClick,
              ),
            },
          ),
      ],
    );
  }

  /// The platter of [side], or nothing when that side has no actions.
  ///
  /// The DOM order is the visual order, which is what keyboard and reading
  /// order follow. The first action is the outermost, so a platter at the
  /// start edge lists them as declared and one at the end edge lists them
  /// backwards — in either text direction.
  List<Component> _buildPlatter(
    CoreSwipeSide side,
    ResolvedSwipeActions resolved,
  ) {
    final leading = side == CoreSwipeSide.leading;
    final actions = leading
        ? component.leadingActions
        : component.trailingActions;
    if (actions.isEmpty) return const [];

    final ordered = leading ? actions : actions.reversed.toList();
    final platter = leading
        ? resolved.leadingPlatter
        : resolved.trailingPlatter;

    return [
      Component.element(
        tag: 'div',
        classes: platter.className,
        styles: platter.inlineStyles,
        attributes: {'data-swipe-platter': side.name},
        children: [
          Component.element(
            tag: 'div',
            classes: resolved.strip.className,
            styles: resolved.strip.inlineStyles,
            attributes: const {'data-swipe-strip': ''},
            children: [
              for (final action in ordered)
                _buildCell(
                  action,
                  resolved,
                  outermost: identical(action, actions.first),
                ),
            ],
          ),
        ],
      ),
    ];
  }

  Component _buildCell(
    CoreSwipeAction<Component> action,
    ResolvedSwipeActions resolved, {
    required bool outermost,
  }) {
    final chrome = outermost ? resolved.outerCell : resolved.cell;

    return Component.element(
      tag: 'div',
      classes: chrome.className,
      styles: chrome.inlineStyles,
      attributes: const {'data-swipe-cell': ''},
      children: [
        Button(
          variant: action.variant.toButtonVariant(),
          size: CoreSwipeActionsContract.actionButtonSize,
          shape: CoreSwipeActionsContract.actionButtonShape,
          enabled: action.enabled,
          buttonStyle: resolved.actionButtonStyle,
          // The label is the button's name; the visible copy is hidden from
          // assistive technology so it is not read twice.
          attributes: {'aria-label': action.label},
          onPressed: () => _handlePress(action),
          child: action.icon ?? const Component.fragment([]),
        ),
        if (component.showLabels) ...[
          Gap(gapStyle: resolved.labelGapStyle),
          Component.element(
            tag: 'div',
            classes: resolved.label.className,
            styles: resolved.label.inlineStyles,
            attributes: const {'aria-hidden': 'true'},
            children: [Text(action.label)],
          ),
        ],
      ],
    );
  }
}
