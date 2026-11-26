import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/control/hover/hover_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Unified cross-platform hover component for CoUI Web.
///
/// Wraps a [child] and provides two features that stay in sync across
/// Flutter and Web:
///
/// 1. **Hover-state tracking** — reports the pointer hover state via
///    [onHover] / [onEnter] / [onExit]. [onHover] fires `true` once the
///    pointer has rested for [waitDuration] and `false` once it has
///    left for [showDuration] (kept active at least [minDuration]).
/// 2. **Hover visual effect** — animates the chosen [effect]
///    (scale / fade / brighten / shadow) while the pointer is over the
///    child.
///
/// Uses [CoreHoverContract] from `coui_core` for a consistent
/// cross-platform API.
///
/// Example:
/// ```dart
/// Hover(
///   effect: CoreHoverEffect.scaleUp,
///   onHover: (hovered) => print('hovered: $hovered'),
///   child: Card(child: text('Hover me')),
/// )
/// ```
class Hover extends UiStatefulComponent
    implements CoreHoverContract<Component> {
  /// Creates a [Hover].
  const Hover({
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
    this.effect = CoreHoverEffect.defaultEffect,
    this.minDuration,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.showDuration,
    this.waitDuration,
    this.hoverStyle,
    this.child,
  });

  @override
  final Component? child;

  @override
  final CoreHoverEffect effect;

  @override
  final ValueChanged<bool>? onHover;

  @override
  final void Function()? onEnter;

  @override
  final void Function()? onExit;

  @override
  final Duration? waitDuration;

  @override
  final Duration? showDuration;

  @override
  final Duration? minDuration;

  /// Per-instance hover-effect chrome override (scale / fade / brighten /
  /// shadow / effect duration). Forwarded into `resolveHover` so Web
  /// callers can override the effect chrome — matching Flutter `Hover`
  /// (Epic #2317, Flutter is the cross-platform reference). Widget-level
  /// field (not part of `CoreHoverContract`), mirroring Flutter.
  final CoreHoverStyle? hoverStyle;

  /// Returns a copy of this [Hover] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Hover copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
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
    CoreHoverEffect? effect,
    Duration? minDuration,
    void Function()? onEnter,
    void Function()? onExit,
    ValueChanged<bool>? onHover,
    Duration? showDuration,
    Duration? waitDuration,
    CoreHoverStyle? hoverStyle,
    Component? child,
  }) {
    return Hover(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      attributes: attributes ?? this.userAttributes,
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
      effect: effect ?? this.effect,
      minDuration: minDuration ?? this.minDuration,
      onEnter: onEnter ?? this.onEnter,
      onExit: onExit ?? this.onExit,
      onHover: onHover ?? this.onHover,
      showDuration: showDuration ?? this.showDuration,
      waitDuration: waitDuration ?? this.waitDuration,
      hoverStyle: hoverStyle ?? this.hoverStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Hover> createState() => _HoverState();
}

/// Chain sugar mirroring the Flutter `Hover.withStyle` extension —
/// merges a [CoreHoverStyle] patch into [Hover.hoverStyle] via the
/// existing [Hover.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreHoverStyle.merge` right-side-wins semantics).
extension HoverStyleChain on Hover {
  /// Returns a copy of this [Hover] with [patch] merged into
  /// [hoverStyle] (patch fields win on conflict).
  Hover withStyle(CoreHoverStyle patch) =>
      copyWith(hoverStyle: (hoverStyle ?? const CoreHoverStyle()).merge(patch));
}

class _HoverState extends State<Hover> {
  /// Pointer is physically over the child — drives the visual effect
  /// immediately (no timing delay).
  bool _pointerInside = false;

  /// Resolved hover state reported via [Hover.onHover] — governed by
  /// the wait / show / min timings.
  bool _reportedHovered = false;

  int? _enterTime;
  Timer? _enterTimer;
  Timer? _exitTimer;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }

  void _handleMouseEnter(web.MouseEvent event) {
    component.onEnter?.call();
    _exitTimer?.cancel();
    setState(() => _pointerInside = true);
    _enterTime = DateTime.now().millisecondsSinceEpoch;
    final timing = resolveHoverTiming(
      context: context,
      waitDuration: component.waitDuration,
      showDuration: component.showDuration,
      minDuration: component.minDuration,
    );
    _enterTimer?.cancel();
    _enterTimer = Timer(Duration(milliseconds: timing.waitDurationMs), () {
      if (!_isMounted) return;
      _reportedHovered = true;
      component.onHover?.call(true);
    });
  }

  void _handleMouseLeave(web.MouseEvent event) {
    component.onExit?.call();
    _enterTimer?.cancel();
    setState(() => _pointerInside = false);
    final timing = resolveHoverTiming(
      context: context,
      waitDuration: component.waitDuration,
      showDuration: component.showDuration,
      minDuration: component.minDuration,
    );
    // Mirrors the Flutter `Hover` reverse-duration calculation: when
    // the pointer leaves quickly (before `minDuration` has elapsed)
    // the reported state stays active for the remainder of
    // `minDuration`; otherwise it deactivates after `showDuration`.
    final enterTime = _enterTime;
    final elapsed = enterTime == null
        ? 0
        : DateTime.now().millisecondsSinceEpoch - enterTime;
    final minMs = timing.minDurationMs;
    final exitDelay = elapsed < minMs ? minMs - elapsed : timing.showDurationMs;
    _enterTime = null;
    _exitTimer?.cancel();
    _exitTimer = Timer(Duration(milliseconds: exitDelay), () {
      if (!_isMounted) return;
      if (!_reportedHovered) return;
      _reportedHovered = false;
      component.onHover?.call(false);
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    _enterTimer?.cancel();
    _exitTimer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes inlineStyles synthesis (Epic #1601 PoC —
    // `WebResolvedChrome` contract). `co_hover` reads the paint-ready
    // styles directly without invoking the top-level builder helpers.
    final resolved = resolveHover(
      context,
      effect: component.effect,
      pointerInside: _pointerInside,
      hoverStyle: component.hoverStyle,
    );

    return div(
      [?component.child],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: {
        ...component.events,
        'mouseenter': EventHandlers.createMouseEventHandler(_handleMouseEnter),
        'mouseleave': EventHandlers.createMouseEventHandler(_handleMouseLeave),
      },
    );
  }
}
