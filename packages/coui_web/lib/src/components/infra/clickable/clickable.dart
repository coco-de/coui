import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/infra/clickable/clickable_style.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show RawText, Styles;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Long-press threshold — a held pointer fires `onLongPress` after
/// this delay (matches Flutter's `GestureDetector` long-press timing).
const _kLongPressDelay = Duration(milliseconds: CoreDuration.slow);

/// Monotonic id source so each clickable instance owns a unique scope
/// id for its per-instance pseudo-state rules.
int _clickableIdCounter = 0;

/// A unified, cross-platform clickable interaction wrapper.
///
/// `Clickable` wraps [child] and makes it interactive — it owns the
/// pointer cursor, focus ring, press-feedback scale and keyboard
/// activation (Enter / Space). It is an infrastructure primitive used
/// as a building block by `Button`, `Checkbox`, `Toggle`,
/// `DotIndicator` and similar components.
///
/// `Clickable` has no visual variant — every chrome decision flows
/// through the single [clickableStyle] slot (a [CoreClickableStyle]).
/// Behavioural fields (`child`, `enabled`, `focusOutline`,
/// `enableFeedback`, callbacks) stay flat on the widget.
///
/// The Flutter `Clickable` shares the same parameter names and
/// renders the same interactions, so cross-platform code stays
/// identical.
///
/// ```dart
/// Clickable(
///   onPressed: () => print('clicked'),
///   child: const Text('Click me'),
/// )
/// ```
class Clickable extends UiStatefulComponent
    implements
        CoreClickableContract<
          Component,
          CorePointerCallback,
          CorePointerCallback,
          CorePointerCallback,
          CorePointerCallback,
          CoreDragCallback,
          CoreAlignment
        > {
  /// Creates a [Clickable].
  const Clickable({
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
    this.onPressed,
    this.onDoubleTap,
    this.onLongPress,
    this.onHover,
    this.onFocus,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onSecondaryTapCancel,
    this.onTertiaryTapDown,
    this.onTertiaryTapUp,
    this.onTertiaryTapCancel,
    this.onLongPressStart,
    this.onLongPressUp,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.onSecondaryLongPress,
    this.onTertiaryLongPress,
    this.marginAlignment,
    this.enabled = true,
    this.focusOutline = true,
    this.semanticsButton = true,
    this.semanticsSelected,
    this.enableFeedback = true,
    this.clickableStyle,
  });

  @override
  final Component? child;

  @override
  final void Function()? onPressed;

  @override
  final void Function()? onDoubleTap;

  @override
  final void Function()? onLongPress;

  @override
  final CoreValueChanged<bool>? onHover;

  @override
  final CoreValueChanged<bool>? onFocus;

  // Secondary / tertiary / low-level long-press gesture callbacks.
  // Declared for cross-platform API parity (Epic #2365) — the primary
  // click / long-press capability is wired below; the exotic gesture
  // *mechanism* is the browser's native pointer model, matching the
  // declare-only surface of the Web `Button`.

  @override
  final CorePointerCallback? onTapDown;

  @override
  final CorePointerCallback? onTapUp;

  @override
  final VoidCallback? onTapCancel;

  @override
  final CorePointerCallback? onSecondaryTapDown;

  @override
  final CorePointerCallback? onSecondaryTapUp;

  @override
  final VoidCallback? onSecondaryTapCancel;

  @override
  final CorePointerCallback? onTertiaryTapDown;

  @override
  final CorePointerCallback? onTertiaryTapUp;

  @override
  final VoidCallback? onTertiaryTapCancel;

  @override
  final CorePointerCallback? onLongPressStart;

  @override
  final VoidCallback? onLongPressUp;

  @override
  final CoreDragCallback? onLongPressMoveUpdate;

  @override
  final CorePointerCallback? onLongPressEnd;

  @override
  final VoidCallback? onSecondaryLongPress;

  @override
  final VoidCallback? onTertiaryLongPress;

  @override
  final CoreAlignment? marginAlignment;

  @override
  final bool enabled;

  @override
  final bool focusOutline;

  /// Whether this announces itself as a button to assistive technology.
  ///
  /// Defaults to `true` — most things built on `Clickable` are buttons, and
  /// a control a screen reader cannot identify as a control is unreachable
  /// rather than merely unlabelled.
  ///
  /// Composing components that are a *more specific* control (checkbox,
  /// switch, radio, tab) set this to `false` and supply their own role, so
  /// the reader announces "checkbox, checked" rather than "button". Honoured
  /// here by omitting the `role="button"` attribute; the Flutter twin reads
  /// the same parameter and drops its `button:` semantics flag.
  ///
  /// Focusability is unaffected — `tabindex` follows [enabled], because a
  /// control that stops naming itself a button is still reachable.
  @override
  final bool semanticsButton;

  /// See [CoreClickableContract.semanticsSelected]. Emitted as
  /// `aria-selected`; a caller attribute of the same name still wins.
  @override
  final bool? semanticsSelected;

  @override
  final bool enableFeedback;

  /// Platform focus node — Flutter framework only. Always `null` on
  /// Web, where focus is managed natively via `tabindex`.
  @override
  Object? get focusNode => null;

  /// Platform mouse cursor — Flutter framework only. Always `null` on
  /// Web, where the cursor is derived from [enabled] automatically.
  @override
  Object? get mouseCursor => null;

  @override
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this [Clickable] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Clickable copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    void Function()? onPressed,
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
    void Function()? onDoubleTap,
    void Function()? onLongPress,
    CoreValueChanged<bool>? onHover,
    CoreValueChanged<bool>? onFocus,
    CorePointerCallback? onTapDown,
    CorePointerCallback? onTapUp,
    VoidCallback? onTapCancel,
    CorePointerCallback? onSecondaryTapDown,
    CorePointerCallback? onSecondaryTapUp,
    VoidCallback? onSecondaryTapCancel,
    CorePointerCallback? onTertiaryTapDown,
    CorePointerCallback? onTertiaryTapUp,
    VoidCallback? onTertiaryTapCancel,
    CorePointerCallback? onLongPressStart,
    VoidCallback? onLongPressUp,
    CoreDragCallback? onLongPressMoveUpdate,
    CorePointerCallback? onLongPressEnd,
    VoidCallback? onSecondaryLongPress,
    VoidCallback? onTertiaryLongPress,
    CoreAlignment? marginAlignment,
    bool? enabled,
    bool? focusOutline,
    bool? semanticsButton,
    bool? semanticsSelected,
    bool? enableFeedback,
    CoreClickableStyle? clickableStyle,
    Component? child,
  }) {
    return Clickable(
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
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
      onDoubleTap: onDoubleTap ?? this.onDoubleTap,
      onLongPress: onLongPress ?? this.onLongPress,
      onHover: onHover ?? this.onHover,
      onFocus: onFocus ?? this.onFocus,
      onTapDown: onTapDown ?? this.onTapDown,
      onTapUp: onTapUp ?? this.onTapUp,
      onTapCancel: onTapCancel ?? this.onTapCancel,
      onSecondaryTapDown: onSecondaryTapDown ?? this.onSecondaryTapDown,
      onSecondaryTapUp: onSecondaryTapUp ?? this.onSecondaryTapUp,
      onSecondaryTapCancel: onSecondaryTapCancel ?? this.onSecondaryTapCancel,
      onTertiaryTapDown: onTertiaryTapDown ?? this.onTertiaryTapDown,
      onTertiaryTapUp: onTertiaryTapUp ?? this.onTertiaryTapUp,
      onTertiaryTapCancel: onTertiaryTapCancel ?? this.onTertiaryTapCancel,
      onLongPressStart: onLongPressStart ?? this.onLongPressStart,
      onLongPressUp: onLongPressUp ?? this.onLongPressUp,
      onLongPressMoveUpdate:
          onLongPressMoveUpdate ?? this.onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd ?? this.onLongPressEnd,
      onSecondaryLongPress: onSecondaryLongPress ?? this.onSecondaryLongPress,
      onTertiaryLongPress: onTertiaryLongPress ?? this.onTertiaryLongPress,
      marginAlignment: marginAlignment ?? this.marginAlignment,
      enabled: enabled ?? this.enabled,
      focusOutline: focusOutline ?? this.focusOutline,
      semanticsButton: semanticsButton ?? this.semanticsButton,
      semanticsSelected: semanticsSelected ?? this.semanticsSelected,
      enableFeedback: enableFeedback ?? this.enableFeedback,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Clickable> createState() => _ClickableState();
}

class _ClickableState extends State<Clickable> {
  // Press / focus VISUALS are browser-native (`:active` /
  // `:focus-visible` on the resolved className) — no Dart state, no
  // re-render, alive before hydration. The handlers below only relay
  // caller callbacks and drive the long-press timer.
  //
  // Keyboard activation is the one exception: the browser attaches
  // `:active` on Space/Enter only to a native `<button>`, never to the
  // `<div role="button">` this component renders (#4421). The
  // keydown/keyup/blur handlers below drive [kClickableKeyPressedMarker]
  // by hand instead — still a direct DOM class toggle, not `setState`,
  // so it stays on the same no-re-render footing as the pointer path.
  Timer? _longPressTimer;
  Timer? _activationPulseTimer;
  late final String _generatedId;

  /// The keyboard-activation press-pulse duration (see
  /// [ResolvedClickableTiming]), refreshed on every `build()`. Lives on
  /// the state rather than being re-resolved inside the keydown handler
  /// — event handlers run outside `build()`, and `resolveClickable`'s
  /// merge chain has already been walked once for the same frame.
  int _pressDurationMs = CoreClickableStyle.defaultPressDuration.inMilliseconds;

  @override
  void initState() {
    super.initState();
    final id = _clickableIdCounter++;
    _generatedId = 'co-clickable-$id';
  }

  /// Scope id for the per-instance pseudo-state rules — the caller's
  /// id wins (passthrough), else the generated one.
  String get _scopeId => component.id ?? _generatedId;

  void _handleClick(web.MouseEvent event) {
    if (!component.enabled) return;
    // The second click of a double click belongs to `onDoubleTap` — the
    // browser follows it with `dblclick`. Without this a caller sees two
    // `onPressed` per double press where the Flutter twin's tap count
    // reports one, and a press that toggles something undoes itself
    // before the double-tap action runs. `detail` is the click count; it
    // is read in the browser only (the VM's DOM stub throws on it).
    if (kIsWeb && component.onDoubleTap != null && event.detail == 2) return;
    component.onPressed?.call();
  }

  void _handleDoubleClick(web.Event event) {
    if (!component.enabled) return;
    component.onDoubleTap?.call();
  }

  void _handleMouseEnter(web.Event event) {
    component.onHover?.call(true);
  }

  void _handleMouseLeave(web.Event event) {
    _longPressTimer?.cancel();
    component.onHover?.call(false);
  }

  void _handleFocusIn(web.Event event) {
    component.onFocus?.call(true);
  }

  void _handleFocusOut(web.Event event) {
    // A Space held past a blur (focus moves away mid-press) never gets
    // a keyup, and a blur mid-pulse should cut the Enter pulse short
    // too — either way the marker must not survive the element losing
    // focus, or it reads as permanently pressed.
    if (_isSelfTarget(event)) {
      _activationPulseTimer?.cancel();
      _setKeyPressed(event, false);
    }
    component.onFocus?.call(false);
  }

  void _handlePointerDown(web.Event event) {
    if (!component.enabled) return;
    final onLongPress = component.onLongPress;
    if (onLongPress != null) {
      _longPressTimer?.cancel();
      _longPressTimer = Timer(_kLongPressDelay, onLongPress);
    }
  }

  void _handlePointerUp(web.Event event) {
    _longPressTimer?.cancel();
  }

  /// Whether [event]'s `target` is the element the listener is bound
  /// to — filters out keyboard/focus events bubbling up from a nested
  /// focusable (e.g. an inner composed control) so this `Clickable`'s
  /// activation and press-visual state don't react to an inner
  /// element's own interaction (native `<button>` semantics; prevents
  /// double-toggle and a nested control's own press reading as this
  /// one's).
  bool _isSelfTarget(web.Event event) {
    final target = event.target;
    final currentTarget = event.currentTarget;
    if (target == null || currentTarget == null) return false;
    return (target as web.Node).isSameNode(currentTarget as web.Node);
  }

  /// Toggles [kClickableKeyPressedMarker] directly on the DOM node
  /// [event] is bound to — a raw class-list mutation, not `setState`,
  /// so it costs no re-render and needs no hydration to take effect
  /// (mirrors the pointer path's reliance on browser-native `:active`).
  void _setKeyPressed(web.Event event, bool pressed) {
    if (event.currentTarget case final web.HTMLElement el) {
      if (pressed) {
        el.classList.add(kClickableKeyPressedMarker);
      } else {
        el.classList.remove(kClickableKeyPressedMarker);
      }
    }
  }

  /// Sets the press marker on, then clears it again after
  /// [_pressDurationMs] — one press cycle standing in for the down/up
  /// pair Enter never produces (see [_handleKeyDown]).
  ///
  /// Captures the element itself rather than re-reading
  /// `event.currentTarget` from the timer callback: `currentTarget` is
  /// only live for the duration of dispatch and reads back `null` once
  /// the browser has finished delivering the event.
  void _pulseActivationPress(web.Event event) {
    if (event.currentTarget case final web.HTMLElement el) {
      _activationPulseTimer?.cancel();
      el.classList.add(kClickableKeyPressedMarker);
      _activationPulseTimer = Timer(
        Duration(milliseconds: _pressDurationMs),
        () => el.classList.remove(kClickableKeyPressedMarker),
      );
    }
  }

  void _handleKeyDown(web.KeyboardEvent event) {
    if (!component.enabled) return;
    // Keyboard activation only when the clickable itself is the
    // focused element — a keydown bubbling up from a nested focusable
    // (e.g. an inner composed control) is that control's activation,
    // not ours (native <button> semantics; prevents double-toggle).
    if (!_isSelfTarget(event)) return;
    final key = event.key;
    if (key == ' ' || key == 'Spacebar') {
      // Native <button> holds `:active` for as long as Space stays
      // down — mirror that with a real keydown/keyup pair (cleared in
      // `_handleKeyUp` / `_handleFocusOut`).
      event.preventDefault();
      _setKeyPressed(event, true);
      component.onPressed?.call();
    } else if (key == 'Enter') {
      // Native <button> activates on Enter's keydown with no
      // observable press window — `:active` never engages, so there is
      // no down/up pair to mirror. Pulse the marker once instead, same
      // rationale as the Flutter twin's `_pulseActivationPress`
      // (#4406 / PR #4410).
      event.preventDefault();
      component.onPressed?.call();
      _pulseActivationPress(event);
    }
  }

  void _handleKeyUp(web.KeyboardEvent event) {
    if (!_isSelfTarget(event)) return;
    final key = event.key;
    if (key == ' ' || key == 'Spacebar') {
      _setKeyPressed(event, false);
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _activationPulseTimer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // The resolver owns every chrome decision; the widget reads the
    // paint-ready strings directly. Press and focus visuals are
    // browser-native pseudo-classes on the class name, and
    // per-instance pseudo overrides arrive as scoped rules below.
    final resolved = resolveClickable(
      context,
      enabled: component.enabled,
      focusOutline: component.focusOutline,
      enableFeedback: component.enableFeedback,
      clickableStyle: component.clickableStyle,
    );
    final rules = resolveClickableRules(
      context,
      scopeId: _scopeId,
      enabled: component.enabled,
      focusOutline: component.focusOutline,
      enableFeedback: component.enableFeedback,
      clickableStyle: component.clickableStyle,
    );
    // Refresh the keydown handler's pulse duration for this build — see
    // `_pressDurationMs`'s doc for why the value has to be cached
    // rather than re-resolved inside the (build-external) handler.
    _pressDurationMs = resolveClickableTiming(
      context,
      clickableStyle: component.clickableStyle,
    ).pressDurationMs;

    final enabled = component.enabled;

    final events = {
      'click': EventHandlers.createMouseEventHandler(_handleClick),
      'mouseenter': _handleMouseEnter,
      'mouseleave': _handleMouseLeave,
      'mousedown': _handlePointerDown,
      'mouseup': _handlePointerUp,
      if (component.onFocus != null) 'focusin': _handleFocusIn,
      // Always wired, not just `if (component.onFocus != null)` — the
      // keyboard-press marker needs a blur hook of its own regardless
      // of whether the caller listens for focus changes (see
      // `_handleFocusOut`'s doc).
      'focusout': _handleFocusOut,
      'keydown': EventHandlers.createKeyboardEventHandler(_handleKeyDown),
      'keyup': EventHandlers.createKeyboardEventHandler(_handleKeyUp),
      if (component.onDoubleTap != null) 'dblclick': _handleDoubleClick,
    };

    return Component.element(
      tag: 'div',
      // The element needs its id only for the scoped pseudo rules (or
      // caller passthrough) — default-path instances stay id-less so
      // SSR markup doesn't churn.
      id: rules.css.isNotEmpty ? _scopeId : component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        // `semanticsButton` is the cross-platform off switch a composing
        // component uses when it is a more specific control — the role goes
        // away, focusability does not, because a checkbox is still reachable.
        if (component.semanticsButton) 'role': CoreSemanticRole.button.ariaRole,
        if (enabled) 'tabindex': '0',
        if (!enabled) 'aria-disabled': 'true',
        if (component.semanticsSelected case final selected?)
          'aria-selected': '$selected',
        // Caller identity / semantic attributes win (passthrough) — a
        // composing component overrides the generic button role with
        // its own (checkbox / switch / tab …) and may pin tabindex.
        ...component.componentAttributes,
      },
      events: {...component.events, ...events},
      children: [
        // `<style>` is `display: none`, so it never affects the
        // inline-flex layout.
        if (rules.css.isNotEmpty)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        ?component.child,
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `Clickable.withStyle` extension —
/// merges a [CoreClickableStyle] patch into [Clickable.clickableStyle]
/// via the existing [Clickable.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreClickableStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` primitive — the
/// getter *name* is the token name, so `.radius4` always means
/// `CoreRadius.radius4`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreClickableStyle.borderRadius]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Clickable(child: Text('Click me')).radius4
/// ```
extension ClickableStyleChain on Clickable {
  /// Returns a copy of this [Clickable] with [patch] merged into
  /// [clickableStyle] (patch fields win on conflict).
  Clickable withStyle(CoreClickableStyle patch) => copyWith(
    clickableStyle: (clickableStyle ?? const CoreClickableStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Clickable get radius0 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Clickable get radius2 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Clickable get radius4 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Clickable get radius6 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Clickable get radius8 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Clickable get radius10 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Clickable get radius12 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Clickable get radius14 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Clickable get radius16 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Clickable get radius20 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Clickable get radius24 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Clickable get radius28 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Clickable get radius32 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Clickable get radius36 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Clickable get radius40 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Clickable get radius48 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Clickable get radius56 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Clickable get radius64 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Clickable get radius9999 => withStyle(
    const CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
