import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart' as dom_utils;
import 'package:coui_web/src/components/navigation/switcher/switcher_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// A unified swipeable container that transitions between child views.
///
/// `Switcher` shows one of [items] at a time and animates a smooth
/// slide / fade transition along [direction] whenever [index] changes.
/// When [gestureEnabled] is set the user can drag to scrub between
/// adjacent views; releasing snaps to the nearest view and reports the
/// new index through [onIndexChanged].
///
/// `Switcher` is the unified replacement for the legacy Web
/// `Switcher` and Flutter `Switcher` — same parameter names, same
/// semantics, full visual / interaction parity.
///
/// Mirrors Flutter `Switcher` 1:1 — same parameter names, same
/// semantics.
///
/// Example:
/// ```dart
/// Switcher(
///   index: _index,
///   direction: CoreSwitcherDirection.left,
///   onIndexChanged: (i) { /* handle change */ },
///   items: [
///     div([text('Page 1')]),
///     div([text('Page 2')]),
///     div([text('Page 3')]),
///   ],
/// )
/// ```
class Switcher extends UiStatefulComponent
    implements CoreSwitcherContract<Component> {
  /// Creates a [Switcher].
  const Switcher({
    required this.items,
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
    this.index = 0,
    this.direction = CoreSwitcherDirection.defaultDirection,
    this.gestureEnabled = true,
    this.onIndexChanged,
    this.switcherStyle,
  });

  @override
  final int index;

  @override
  final List<Component> items;

  @override
  final CoreSwitcherDirection direction;

  @override
  final bool gestureEnabled;

  @override
  final void Function(int)? onIndexChanged;

  @override
  final CoreSwitcherStyle? switcherStyle;

  /// Returns a copy of this [Switcher] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Switcher copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    List<Component>? items,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    int? index,
    CoreSwitcherDirection? direction,
    bool? gestureEnabled,
    void Function(int)? onIndexChanged,
    CoreSwitcherStyle? switcherStyle,
  }) {
    return Switcher(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      items: items ?? this.items,
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
      index: index ?? this.index,
      direction: direction ?? this.direction,
      gestureEnabled: gestureEnabled ?? this.gestureEnabled,
      onIndexChanged: onIndexChanged ?? this.onIndexChanged,
      switcherStyle: switcherStyle ?? this.switcherStyle,
    );
  }

  @override
  State<Switcher> createState() => _SwitcherState();
}

/// Chain sugar mirroring the Flutter `Switcher.withStyle` extension —
/// merges a [CoreSwitcherStyle] patch into [Switcher.switcherStyle] via
/// the existing [Switcher.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSwitcherStyle.merge` right-side-wins semantics).
extension SwitcherStyleChain on Switcher {
  /// Returns a copy of this [Switcher] with [patch] merged into
  /// [switcherStyle] (patch fields win on conflict).
  Switcher withStyle(CoreSwitcherStyle patch) => copyWith(
    switcherStyle: (switcherStyle ?? const CoreSwitcherStyle()).merge(patch),
  );
}

class _SwitcherState extends State<Switcher> {
  /// Fractional active position — `index` while idle, anything in
  /// `[0, itemCount - 1]` while a drag is in flight.
  late double _position;

  bool _dragging = false;
  double _dragStart = 0;
  double _dragExtent = 1;

  @override
  void initState() {
    super.initState();
    _position = component.index.toDouble();
  }

  void _handleDragStart(web.MouseEvent event) {
    if (!component.gestureEnabled) return;
    final currentTarget = event.currentTarget;
    final extent = switch (currentTarget) {
      final web.HTMLElement target =>
        component.direction.isHorizontal
            ? target.clientWidth.toDouble()
            : target.clientHeight.toDouble(),
      _ => 1.0,
    };
    setState(() {
      _dragging = true;
      _dragExtent = extent <= 0 ? 1 : extent;
      // `mouseClientX/Y` re-read the coordinates as doubles — browsers
      // deliver sub-pixel mouse positions and the `int`-declared
      // getters throw a cast error on them.
      _dragStart =
          (component.direction.isHorizontal
              ? dom_utils.mouseClientX(event)
              : dom_utils.mouseClientY(event)) ??
          0;
    });

    dom_utils.registerDragListeners(
      onMove: (e) {
        if (!_dragging) return;
        if (e case final web.MouseEvent me) {
          final pointer = component.direction.isHorizontal
              ? dom_utils.mouseClientX(me)
              : dom_utils.mouseClientY(me);
          if (pointer == null) return;
          // Match the paging translate sign so a drag follows the
          // pointer: for `left`/`up`, moving the pointer toward the start
          // advances the position (next slide follows the finger in).
          final sign =
              (component.direction == .up || component.direction == .left)
              ? 1
              : -1;
          final delta = (pointer - _dragStart) / _dragExtent * sign;
          setState(() {
            _position = (_position - delta)
                .clamp(0, component.items.length - 1)
                .toDouble();
            _dragStart = pointer;
          });
        }
      },
      onUp: (_) => _handleDragSettled(),
      downEvent: event,
    );
  }

  void _handleDragSettled() {
    if (!_dragging) return;
    final settled = _position.round();
    setState(() {
      _dragging = false;
      _position = settled.toDouble();
    });
    component.onIndexChanged?.call(settled);
  }

  @override
  void didUpdateComponent(covariant Switcher oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.index != component.index && !_dragging) {
      setState(() => _position = component.index.toDouble());
    }
  }

  @override
  Component build(BuildContext context) {
    // Single entry point — merge chain + token fallback + per-slot
    // chrome all resolved in `switcher_style.dart`. Runtime state
    // (`direction` / `position` / `itemCount` / `dragging`) flows in
    // as resolver arguments so this build only reads
    // `resolved.<slot>.className / inlineStyles`.
    final resolved = resolveSwitcher(
      context,
      direction: component.direction,
      position: _position,
      itemCount: component.items.length,
      dragging: _dragging,
      switcherStyle: component.switcherStyle,
    );

    final slots = <Component>[];
    for (var i = 0; i < component.items.length; i++) {
      final slotChrome = resolved.slots[i];
      slots.add(
        div(
          [component.items[i]],
          classes: slotChrome.className,
          styles: slotChrome.inlineStyles,
          attributes: {'aria-hidden': '${i != component.index}'},
        ),
      );
    }

    return div(
      [
        div(
          slots,
          classes: resolved.track.className,
          styles: resolved.track.inlineStyles,
        ),
      ],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {...component.componentAttributes, 'role': 'group'},
      events: {
        ...component.events,
        ...(component.gestureEnabled
            ? {
                // Trigger on pointerdown because the drag listeners are pointer
                // events — on touch devices the compatibility mousedown fires after
                // the gesture's pointerup and would leak them.
                'pointerdown': EventHandlers.createMouseEventHandler(
                  _handleDragStart,
                ),
              }
            : const {}),
      },
    );
  }
}
