import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// Minimum interval below which two taps count as a double-tap.
const _kDoubleTapMinTime = Duration(
  milliseconds: CoreDuration.moderate,
);

/// When a press went down, and on which clock — see
/// `_ClickableState._pointerDownAt`.
typedef _PressTime = ({Duration at, bool engine});

/// Monotonic clock for presses whose pointer event carries no engine
/// timestamp.
final Stopwatch _handlingClock = Stopwatch()..start();

/// Keyboard activators that trigger the primary action — Enter and
/// Space, matching the W3C button keyboard contract.
const Map<ShortcutActivator, Intent> _kActivationShortcuts = {
  SingleActivator(.enter): ActivateIntent(),
  SingleActivator(.space): ActivateIntent(),
};

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
/// The Web `Clickable` shares the same parameter names and renders
/// the same interactions, so cross-platform code stays identical.
///
/// ```dart
/// Clickable(
///   onPressed: () => print('clicked'),
///   child: const Text('Click me'),
/// )
/// ```
class Clickable extends StatefulWidget
    implements
        CoreClickableContract<
          Widget,
          GestureTapDownCallback,
          GestureTapUpCallback,
          GestureLongPressStartCallback,
          GestureLongPressEndCallback,
          GestureLongPressMoveUpdateCallback,
          AlignmentGeometry
        > {
  /// Creates a [Clickable].
  const Clickable({
    required this.child,
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
    this.semanticsEnabled,
    this.enableFeedback = true,
    this.engageOnHover = false,
    this.focusNode,
    this.mouseCursor,
    this.statesController,
    this.onPressedChange,
    this.clickableStyle,
    super.key,
  });

  @override
  final Widget child;

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

  @override
  final GestureTapDownCallback? onTapDown;

  @override
  final GestureTapUpCallback? onTapUp;

  @override
  final VoidCallback? onTapCancel;

  @override
  final GestureTapDownCallback? onSecondaryTapDown;

  @override
  final GestureTapUpCallback? onSecondaryTapUp;

  @override
  final VoidCallback? onSecondaryTapCancel;

  @override
  final GestureTapDownCallback? onTertiaryTapDown;

  @override
  final GestureTapUpCallback? onTertiaryTapUp;

  @override
  final VoidCallback? onTertiaryTapCancel;

  @override
  final GestureLongPressStartCallback? onLongPressStart;

  @override
  final VoidCallback? onLongPressUp;

  @override
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;

  @override
  final GestureLongPressEndCallback? onLongPressEnd;

  @override
  final VoidCallback? onSecondaryLongPress;

  @override
  final VoidCallback? onTertiaryLongPress;

  /// Alignment of the clickable within its margin. When set, the
  /// content is wrapped in an [Align] — mirroring the deprecated
  /// `Clickable.marginAlignment`.
  @override
  final AlignmentGeometry? marginAlignment;

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
  /// here through the `button:` semantics flag; the Web twin reads the same
  /// parameter and omits its `role="button"` attribute.
  @override
  final bool semanticsButton;

  /// See [CoreClickableContract.semanticsSelected]. Honoured here through
  /// the `selected:` semantics flag on this widget's own node.
  @override
  final bool? semanticsSelected;

  /// The enabled state announced to assistive technology, when it differs
  /// from [enabled].
  ///
  /// `null` (the default) follows [enabled]. A composing component whose
  /// disabled state is *inert but reachable* — a menu row, which WAI-ARIA
  /// keeps in the tab order with `aria-disabled` so a keyboard user can
  /// still land on it and hear why it does nothing — leaves [enabled]
  /// `true` (focus, cursor and press feedback stay wired), hands no
  /// [onPressed], and states `false` here so the screen reader announces
  /// the row as disabled. Flutter-framework only: the Web twin reaches
  /// the same announcement through its `attributes` passthrough
  /// (`aria-disabled`), which the Flutter tree has no equivalent for.
  ///
  /// Why a separate knob: Flutter merges a descendant `Semantics(enabled:
  /// true)` over an ancestor `enabled: false` (`Tristate.isTrue` wins on
  /// merge), so a wrapper around this widget cannot override what this
  /// widget states — the statement has to be made here.
  final bool? semanticsEnabled;

  @override
  final bool enableFeedback;

  /// Whether hover counts as an additional engage trigger for the
  /// [CoreClickableStyle.pressedTranslate] / `pressedBoxShadow` pair,
  /// alongside a physical press.
  ///
  /// Default `false` — every existing `Clickable`-based control keeps
  /// keying that pair off press alone, so opting nothing in changes
  /// nothing for them. Deliberately scoped to just the shift/shadow
  /// pair, never [CoreClickableStyle.pressedScale] (see `pressedScale`
  /// below) — a hover-shrinking checkbox would be a new, unwanted
  /// affordance for every control that never asked for it.
  ///
  /// Flutter dispatches hover only where a pointer exists and never on
  /// touch, so a control that opts in reads "engaged" from a mouse
  /// hovering on desktop and falls back to press on mobile with no
  /// platform branch — the event itself is already platform-gated.
  /// Flutter-framework only — Web reaches the same pairing with a CSS
  /// `:hover, :active` selector, so it needs no matching flag.
  final bool engageOnHover;

  /// Platform focus node. When `null`, an internal node is created.
  ///
  /// Implements the contract's `Object? get focusNode` via the
  /// covariant `FocusNode?` field type.
  @override
  final FocusNode? focusNode;

  /// Platform mouse cursor. When `null`, the cursor defaults to
  /// [SystemMouseCursors.click] while enabled and
  /// [SystemMouseCursors.forbidden] while disabled.
  ///
  /// Implements the contract's `Object? get mouseCursor` via the
  /// covariant `MouseCursor?` field type.
  @override
  final MouseCursor? mouseCursor;

  /// Optional external [WidgetStatesController]. When supplied,
  /// `Clickable` keeps it in sync with the `disabled` / `hovered` /
  /// `pressed` / `focused` interaction states so callers can observe
  /// them. Flutter-framework only — has no Web equivalent, so it is
  /// not part of [CoreClickableContract].
  final WidgetStatesController? statesController;

  /// Pressed state change callback. Receives `true` when a primary
  /// pointer/tap engages the clickable, `false` when it releases or
  /// cancels.
  ///
  /// Flutter-framework only — has no Web equivalent, so it is not part
  /// of [CoreClickableContract]. Web's press-state chrome is browser-
  /// native (`:active` on the resolved className, no Dart re-render);
  /// Flutter has no pseudo-class equivalent, so a composing widget that
  /// wants `WidgetState.pressed` in its own per-state chrome selection
  /// (`Button`) needs this callback the same way it already needs
  /// [onHover] / [onFocus] — DETECTION stays here, native to
  /// [GestureDetector]; this only reports what detection already found.
  final CoreValueChanged<bool>? onPressedChange;

  @override
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this [Clickable] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Clickable copyWith({
    Key? key,
    void Function()? onPressed,
    void Function()? onDoubleTap,
    void Function()? onLongPress,
    CoreValueChanged<bool>? onHover,
    CoreValueChanged<bool>? onFocus,
    GestureTapDownCallback? onTapDown,
    GestureTapUpCallback? onTapUp,
    VoidCallback? onTapCancel,
    GestureTapDownCallback? onSecondaryTapDown,
    GestureTapUpCallback? onSecondaryTapUp,
    VoidCallback? onSecondaryTapCancel,
    GestureTapDownCallback? onTertiaryTapDown,
    GestureTapUpCallback? onTertiaryTapUp,
    VoidCallback? onTertiaryTapCancel,
    GestureLongPressStartCallback? onLongPressStart,
    VoidCallback? onLongPressUp,
    GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate,
    GestureLongPressEndCallback? onLongPressEnd,
    VoidCallback? onSecondaryLongPress,
    VoidCallback? onTertiaryLongPress,
    AlignmentGeometry? marginAlignment,
    bool? enabled,
    bool? focusOutline,
    bool? semanticsButton,
    bool? semanticsSelected,
    bool? semanticsEnabled,
    bool? enableFeedback,
    bool? engageOnHover,
    FocusNode? focusNode,
    MouseCursor? mouseCursor,
    WidgetStatesController? statesController,
    CoreValueChanged<bool>? onPressedChange,
    CoreClickableStyle? clickableStyle,
    Widget? child,
  }) {
    return Clickable(
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
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
      semanticsEnabled: semanticsEnabled ?? this.semanticsEnabled,
      enableFeedback: enableFeedback ?? this.enableFeedback,
      engageOnHover: engageOnHover ?? this.engageOnHover,
      focusNode: focusNode ?? this.focusNode,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      statesController: statesController ?? this.statesController,
      onPressedChange: onPressedChange ?? this.onPressedChange,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Clickable> createState() => _ClickableState();
}

class _ClickableState extends State<Clickable> {
  late FocusNode _focusNode;
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  /// Engine timestamp of the latest primary pointer down — the clock a
  /// double tap is judged by.
  ///
  /// Not `DateTime.now()` at handling time: when the first press does heavy
  /// work (opening a document builds an editor surface), the second press
  /// is handled late, and a wall-clock gap measured at handling time would
  /// call a quick double click two single ones. Event timestamps keep the
  /// gap the user actually made — the same clock the framework's own tap
  /// recognizers order events by.
  ///
  /// A pointer event synthesised in Dart — automation such as Marionette,
  /// a widget test that sets no timestamp — carries [Duration.zero], and on
  /// that clock every press is simultaneous: two clicks minutes apart
  /// would pair. Those are timed when handled, as before, on a clock of
  /// their own; a press on one clock never pairs with one on the other.
  _PressTime? _pointerDownAt;

  /// [_pointerDownAt] of the last press that reached [_handlePressed], or
  /// `null` after a keyboard activation — a key press never pairs with
  /// anything into a double tap.
  _PressTime? _lastTapAt;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    widget.statesController?.update(.disabled, !widget.enabled);
  }

  /// Announces the tap, and plays the platform click sound when the app
  /// still wants one.
  ///
  /// The semantics event is unconditional. It is what tells assistive
  /// technology a tap happened, so it is not feedback an app can decline
  /// — gating this whole method instead of the sound line would trade an
  /// audio preference for an accessibility loss, and nothing on screen
  /// would show that it happened.
  ///
  /// Reading a theme axis inside a component file is normally the wrong
  /// shape (`core/theme-axis-composition.md`: components do not read
  /// axes, because then the axis reaches only the components that
  /// remembered to ask). The exemption holds here for one structural
  /// reason: this is the kit's *only* caller of [SystemSound], so there
  /// is no second component that could forget. If a second emitter ever
  /// appears, the axis belongs at whatever seat both of them pass
  /// through, not copied into the new file.
  Future<void> _feedbackForTap() {
    final theme = Theme.of(context);
    context.findRenderObject()!.sendSemanticsEvent(const TapSemanticEvent());

    return isMobile(theme.platform) && theme.tapSoundEnabled
        ? SystemSound.play(.click)
        : Future.value();
  }

  /// [at] is when the press went down; `null` for a keyboard activation,
  /// which always counts as a single press.
  void _handlePressed({_PressTime? at}) {
    if (!widget.enabled) return;
    final previous = _lastTapAt;
    final delta = at == null || previous == null || at.engine != previous.engine
        ? null
        : at.at - previous.at;
    _lastTapAt = at;
    _tapCount =
        (delta != null && !delta.isNegative && delta < _kDoubleTapMinTime)
        ? _tapCount + 1
        : 1;

    if (_tapCount == 2 && widget.onDoubleTap != null) {
      widget.onDoubleTap!();
      _tapCount = 0;
      return;
    }
    final onPressed = widget.onPressed;
    if (onPressed != null) {
      onPressed();
      if (widget.enableFeedback) {
        unawaited(_feedbackForTap());
      }
    }
  }

  void _handleHover(bool hovered) {
    if (!mounted) return;
    // Tracked locally (mirrors `_handleFocus` below) so `build` can fold
    // it into `engageOnHover`'s pairing — the forwarded callback alone
    // tells the caller, not this widget's own next frame.
    if (_hovered != hovered) {
      setState(() => _hovered = hovered);
    }
    widget.statesController?.update(.hovered, hovered);
    widget.onHover?.call(hovered);
  }

  void _handleFocus(bool focused) {
    // Root-overlay drag feedback can disappear before queued focus/pointer
    // notifications are delivered. Its state must not publish after disposal.
    if (!mounted) return;
    if (_focused != focused) {
      setState(() => _focused = focused);
    }
    widget.statesController?.update(.focused, focused);
    widget.onFocus?.call(focused);
  }

  void _handlePressedDown() {
    if (!mounted) return;
    if (!_pressed) {
      setState(() => _pressed = true);
    }
    widget.statesController?.update(.pressed, true);
    widget.onPressedChange?.call(true);
  }

  void _handlePressedUp() {
    if (!mounted) return;
    if (_pressed) {
      setState(() => _pressed = false);
    }
    widget.statesController?.update(.pressed, false);
    widget.onPressedChange?.call(false);
  }

  // `Action.onInvoke` must return `Object?`; activation has no result.
  Object? _handleActivateIntent(ActivateIntent intent) {
    _handlePressed();
    unawaited(_pulseActivationPress());
    return null;
  }

  /// Gives keyboard activation (Enter / Space) the same press affordance
  /// a pointer gets.
  ///
  /// `ActivateIntent` carries no down/up pair to observe — by the time it
  /// fires, the activation is already a completed signal, not an ongoing
  /// press. Without this, `_pressed` never turns on for a keyboard user
  /// and the scale-shrink / neo-brutalism cast shift silently never plays,
  /// even though the Web twin gets it for free from the browser's
  /// `:active` on Space. So this sets `_pressed` and clears it again after
  /// one press cycle — a pulse standing in for the down/up pair a pointer
  /// gets natively.
  ///
  /// The pulse rides `pressDuration` — the same `CoreDuration` token the
  /// pointer press pair already animates over — rather than a literal, so
  /// the two clocks cannot drift apart if that token changes.
  Future<void> _pulseActivationPress() async {
    if (!widget.enabled) return;
    final pressDuration = resolveClickable(
      context,
      clickableStyle: widget.clickableStyle,
    ).pressDuration;
    _handlePressedDown();
    await Future<void>.delayed(pressDuration);
    if (!mounted) return;
    _handlePressedUp();
  }

  @override
  void didUpdateWidget(covariant Clickable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.enabled != oldWidget.enabled) {
      widget.statesController?.update(.disabled, !widget.enabled);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveClickable(
      context,
      clickableStyle: widget.clickableStyle,
    );

    final enabled = widget.enabled;
    // `enableFeedback` gates the press-shrink — a wired-but-inert
    // clickable (e.g. a force-disabled checkbox that keeps its
    // onChanged) must not animate on press. Mirrors the Web
    // Clickable's enableFeedback gate on `active:scale`.
    final pressed = enabled && widget.enableFeedback && _pressed;
    // Scale stays keyed on `pressed` alone, never hover — the shift/
    // shadow pair below is what `engageOnHover` opts into, and pinning
    // scale to press-only is what keeps every non-opted-in control
    // (checkbox, toggle, …) exactly as it renders today: nothing here
    // shrinks just because a mouse passed over it.
    final scale = pressed ? resolved.pressedScale : 1.0;
    final cursor =
        widget.mouseCursor ??
        (enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden);

    // `engaged` is the shift/shadow pair's own trigger — press always
    // counts, and hover counts too when a consumer opted in via
    // [Clickable.engageOnHover]. The two conditions OR together into one
    // value read by both halves of the pair below, so a control that is
    // already engaged by hover shows no jump when a press starts or ends
    // on top of it, and only reverts once both let go.
    final hoverEngaged =
        widget.engageOnHover && enabled && widget.enableFeedback && _hovered;
    final engaged = pressed || hoverEngaged;

    // One controller owns scale, translation and shadow. A duration-only
    // change to zero must also finish an already running transition, even
    // when its target did not change (for example Reduce Motion mid-press).
    // Keeping the feedback subtree mounted preserves child and focus state.
    final shifts = resolved.pressedTranslate != .zero;
    Widget content = _ClickableFeedback(
      scale: scale,
      offset: engaged ? resolved.pressedTranslate : Offset.zero,
      decoration: resolved.pressedBoxShadow == null
          ? null
          : BoxDecoration(
              borderRadius: resolved.borderRadius,
              boxShadow: engaged ? resolved.pressedBoxShadow : const [],
            ),
      hasChrome: shifts || resolved.pressedBoxShadow != null,
      duration: resolved.pressDuration,
      curve: resolved.curve,
      // A control's label must not compete with its press/drag gesture.
      child: SelectionContainer.disabled(child: widget.child),
    );

    if (!enabled) {
      content = Opacity(
        opacity: resolved.disabledOpacity,
        child: content,
      );
    }

    final marginAlignment = widget.marginAlignment;
    if (marginAlignment != null) {
      content = Align(alignment: marginAlignment, child: content);
    }

    final detector = GestureDetector(
      onTap: enabled && widget.onPressed != null
          ? () => _handlePressed(at: _pointerDownAt)
          : null,
      // The caller's `onTapDown` / `onTapUp` still ride the recognizer —
      // they are a *tap* contract and must keep the arena's meaning. Only
      // the press *visual* was moved to the pointer stream below, because
      // it is the one thing the arena's delay makes unpaintable.
      onTapDown: enabled ? widget.onTapDown : null,
      onTapUp: enabled ? widget.onTapUp : null,
      onTapCancel: enabled
          ? () {
              _handlePressedUp();
              widget.onTapCancel?.call();
            }
          : null,
      onSecondaryTapDown: enabled ? widget.onSecondaryTapDown : null,
      onSecondaryTapUp: enabled ? widget.onSecondaryTapUp : null,
      onSecondaryTapCancel: enabled ? widget.onSecondaryTapCancel : null,
      onTertiaryTapDown: enabled ? widget.onTertiaryTapDown : null,
      onTertiaryTapUp: enabled ? widget.onTertiaryTapUp : null,
      onTertiaryTapCancel: enabled ? widget.onTertiaryTapCancel : null,
      onLongPress: enabled ? widget.onLongPress : null,
      onLongPressStart: enabled ? widget.onLongPressStart : null,
      onLongPressMoveUpdate: enabled ? widget.onLongPressMoveUpdate : null,
      onLongPressUp: enabled ? widget.onLongPressUp : null,
      onLongPressEnd: enabled ? widget.onLongPressEnd : null,
      onSecondaryLongPress: enabled ? widget.onSecondaryLongPress : null,
      onTertiaryLongPress: enabled ? widget.onTertiaryLongPress : null,
      behavior: .translucent,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: _focusNode,
        shortcuts: _kActivationShortcuts,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: _handleActivateIntent,
          ),
        },
        onShowFocusHighlight: _handleFocus,
        onShowHoverHighlight: _handleHover,
        mouseCursor: cursor,
        child: content,
      ),
    );

    // The press visual begins on the raw pointer, not on the recognizer.
    //
    // `TapGestureRecognizer` withholds `onTapDown` while it is contesting
    // the gesture arena, and for a tap shorter than `kPressTimeout` (100ms)
    // the arena only resolves at the pointer-up sweep — where
    // `acceptGesture` calls `_checkDown()` and `_checkUp()` back to back,
    // synchronously. `_pressed` then goes true and false inside one batch
    // with no frame between, so the press state is computed perfectly and
    // never painted. Every quick tap looked dead.
    //
    // The arena is contested in practice, not in theory: `CoUIApp` wraps
    // Web content in a `SelectionArea`, which alone reproduces this with no
    // Scrollable anywhere — so it is every control in every Web app, not
    // just the ones inside a list.
    //
    // `Listener` sits below the arena and fires before the first frame, so
    // this matches what the Web twin does: `:active` engages at mousedown
    // with no arbitration, and holds until mouseup wherever the pointer
    // ends up — a drag off the control does not clear it (measured).
    //
    // Cancellation stays with the recognizer, and must: losing the arena to
    // a scroll is precisely the case where the press should retreat, and
    // only the arena knows it happened.
    final pointerAware = Listener(
      onPointerDown: enabled
          ? (event) {
              if ((event.buttons & kPrimaryButton) != 0) {
                _pointerDownAt = event.timeStamp == Duration.zero
                    ? (at: _handlingClock.elapsed, engine: false)
                    : (at: event.timeStamp, engine: true);
              }
              _handlePressedDown();
            }
          : null,
      onPointerUp: enabled ? (_) => _handlePressedUp() : null,
      onPointerCancel: enabled ? (_) => _handlePressedUp() : null,
      child: detector,
    );

    // Screen-reader parity with the Web twin, which emits `role="button"`
    // plus `aria-disabled` on the same element. Announcing this once here
    // covers every component composed on `Clickable` rather than leaving
    // each of them to remember — and a control that a screen reader cannot
    // identify as a control is unreachable, not merely unlabelled.
    final semantic = Semantics(
      enabled: widget.semanticsEnabled ?? enabled,
      button: widget.semanticsButton,
      selected: widget.semanticsSelected,
      child: pointerAware,
    );

    if (!widget.focusOutline) {
      return semantic;
    }

    return FocusOutline(
      focused: enabled && _focused,
      focusOutlineStyle: resolved.focusOutlineStyle,
      child: semantic,
    );
  }
}

/// Stable press chrome with an interruptible motion preference.
class _ClickableFeedback extends ImplicitlyAnimatedWidget {
  const _ClickableFeedback({
    required this.scale,
    required this.offset,
    required this.decoration,
    required this.hasChrome,
    required this.child,
    required super.duration,
    required super.curve,
  });

  final double scale;
  final Offset offset;
  final Decoration? decoration;
  final bool hasChrome;
  final Widget child;

  @override
  AnimatedWidgetBaseState<_ClickableFeedback> createState() =>
      _ClickableFeedbackState();
}

class _ClickableFeedbackState
    extends AnimatedWidgetBaseState<_ClickableFeedback> {
  Tween<double>? _scale;
  Tween<Offset>? _offset;
  DecorationTween? _decoration;

  @override
  void didUpdateWidget(_ClickableFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ImplicitlyAnimatedWidget updates controller.duration, but an existing
    // simulation keeps its original duration when the tween target is equal.
    // Finish it explicitly instead of remounting the child's state or focus.
    if (widget.duration == Duration.zero && controller.isAnimating) {
      controller.value = 1;
    }
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _scale =
        visitor(
              _scale,
              widget.scale,
              (value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
    _offset =
        visitor(
              _offset,
              widget.offset,
              (value) => Tween<Offset>(begin: value as Offset),
            )
            as Tween<Offset>?;
    _decoration =
        visitor(
              _decoration,
              widget.decoration,
              (value) => DecorationTween(begin: value as Decoration),
            )
            as DecorationTween?;
  }

  @override
  Widget build(BuildContext context) {
    final scaled = Transform.scale(
      scale: _scale!.evaluate(animation),
      child: widget.child,
    );
    if (!widget.hasChrome) return scaled;
    final offset = _offset!.evaluate(animation);
    return Container(
      decoration: _decoration?.evaluate(animation),
      transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
      child: scaled,
    );
  }
}

/// Chain sugar for merging a [CoreClickableStyle] patch into
/// [Clickable.clickableStyle] without hand-reconstructing every field.
/// Mirrors the Web `Clickable.withStyle` extension so both platforms
/// read identically.
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
/// Clickable(child: const Text('Click me')).radius4
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
      borderRadius: CoreBorderRadius.zero,
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
