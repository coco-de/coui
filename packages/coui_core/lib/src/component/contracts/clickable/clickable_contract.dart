/// Platform-independent contract for unified clickable components.
///
/// Defines the interface that all Clickable implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';

/// Contract for a unified clickable interaction wrapper.
///
/// `Clickable` wraps [child] and makes it interactive — it owns
/// pointer cursor, focus ring, press-feedback scale and keyboard
/// activation (Enter / Space). It is an infrastructure primitive used
/// as a building block by `Button`, `Checkbox`, `Toggle`,
/// `DotIndicator` and similar components.
///
/// `Clickable` has no visual variant — every chrome decision flows
/// through the single [clickableStyle] field (see
/// [CoreClickableStyle] for the merge chain). Behavioural fields
/// (`child`, `enabled`, `focusOutline`, `enableFeedback`, callbacks)
/// stay flat on the widget.
///
/// The secondary / tertiary / long-press gesture callbacks are typed
/// through generics so each platform binds them to its idiom — Flutter
/// to the native `GestureXxxCallback` types, Web to the platform-neutral
/// `CorePointerCallback` / `CoreDragCallback`. The *capability* (respond
/// to right-click / middle-click / long-press) is symmetric; only the
/// callback *mechanism* differs (Epic #2365 — Button transport off the
/// deprecated `Clickable`).
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
/// - [TapDownCb] — tap down callback (Flutter `GestureTapDownCallback`,
///   Web `CorePointerCallback`).
/// - [TapUpCb] — tap up callback (Flutter `GestureTapUpCallback`,
///   Web `CorePointerCallback`).
/// - [LongStartCb] — long press start callback
///   (Flutter `GestureLongPressStartCallback`, Web `CorePointerCallback`).
/// - [LongEndCb] — long press end callback
///   (Flutter `GestureLongPressEndCallback`, Web `CorePointerCallback`).
/// - [LongMoveCb] — long press move callback
///   (Flutter `GestureLongPressMoveUpdateCallback`, Web `CoreDragCallback`).
/// - [Align] — alignment type (Flutter `AlignmentGeometry`,
///   Web `CoreAlignment`).
abstract interface class CoreClickableContract<
  W,
  TapDownCb,
  TapUpCb,
  LongStartCb,
  LongEndCb,
  LongMoveCb,
  Align
> {
  /// The content wrapped and made interactive.
  W? get child;

  /// Whether the clickable accepts interaction. When `false` the
  /// callbacks are suppressed and a disabled appearance is applied.
  bool get enabled;

  /// Whether the focus ring is drawn while the clickable is focused.
  bool get focusOutline;

  /// Whether this announces itself as a button to assistive technology.
  ///
  /// Defaults to `true` — most things built on `Clickable` are buttons,
  /// and a control a screen reader cannot identify as a control is
  /// unreachable rather than merely unlabelled.
  ///
  /// A composing component that is a *more specific* control (checkbox,
  /// switch, radio, tab) sets this to `false` and supplies its own role,
  /// so the reader announces "checkbox, checked" rather than "button".
  /// Both platforms honour the flag with their own mechanism — Flutter
  /// through the `button:` semantics flag, Web by omitting the
  /// `role="button"` attribute.
  bool get semanticsButton;

  /// The selection state announced to assistive technology — a row in a
  /// list of options that is the chosen one.
  ///
  /// `null` (the default) states nothing, which a reader announces
  /// differently from `false`: a plain button has no selection at all.
  /// A composing component whose rows are options (a picker, a listbox)
  /// passes each row's state so the choice is heard, not only seen as a
  /// background wash and a check mark. Both platforms honour it with
  /// their own mechanism — Flutter through the `selected:` semantics
  /// flag, Web as `aria-selected` (a caller attribute still wins).
  bool? get semanticsSelected;

  /// Whether platform tap feedback (sound / haptics) plays on press.
  ///
  /// Honoured by Flutter (`SystemSound.play`); a no-op on Web where no
  /// equivalent platform feedback exists.
  bool get enableFeedback;

  /// Primary activation callback — fired on tap, click, or keyboard
  /// Enter / Space.
  void Function()? get onPressed;

  /// Double-tap / double-click callback.
  ///
  /// The second press of a double press is reported here **instead of**
  /// [onPressed]. The first press has already fired [onPressed] without
  /// waiting for a possible second one, so adding a double-tap never delays
  /// a single tap — and a caller sees one [onPressed] per double press on
  /// both platforms, not two.
  ///
  /// Two presses pair by when the user made them (pointer event time, the
  /// browser's click count), not by when they were handled, so a first press
  /// that does heavy work cannot split a quick double press in two. A pointer
  /// event synthesised without a timestamp (automation, a test) is timed when
  /// handled instead, and never pairs with a timestamped one. Keyboard
  /// activation is always a single [onPressed].
  void Function()? get onDoubleTap;

  /// Long-press callback.
  void Function()? get onLongPress;

  /// Hover state change callback. Receives `true` on enter, `false`
  /// on leave.
  CoreValueChanged<bool>? get onHover;

  /// Focus state change callback. Receives `true` on focus, `false`
  /// on blur.
  CoreValueChanged<bool>? get onFocus;

  // -- Primary tap (low-level) --

  /// Called when a primary pointer contacts the clickable.
  TapDownCb? get onTapDown;

  /// Called when a primary pointer is released on the clickable.
  TapUpCb? get onTapUp;

  /// Called when a primary tap is cancelled.
  CoreVoidCallback? get onTapCancel;

  // -- Secondary tap (right-click / two-finger tap) --

  /// Called when a secondary pointer contacts the clickable.
  TapDownCb? get onSecondaryTapDown;

  /// Called when a secondary pointer is released on the clickable.
  TapUpCb? get onSecondaryTapUp;

  /// Called when a secondary tap is cancelled.
  CoreVoidCallback? get onSecondaryTapCancel;

  // -- Tertiary tap (middle-click) --

  /// Called when a tertiary pointer contacts the clickable.
  TapDownCb? get onTertiaryTapDown;

  /// Called when a tertiary pointer is released on the clickable.
  TapUpCb? get onTertiaryTapUp;

  /// Called when a tertiary tap is cancelled.
  CoreVoidCallback? get onTertiaryTapCancel;

  // -- Long press --

  /// Called when a long press begins.
  LongStartCb? get onLongPressStart;

  /// Called when a long press ends with pointer up.
  CoreVoidCallback? get onLongPressUp;

  /// Called when the pointer moves during a long press.
  LongMoveCb? get onLongPressMoveUpdate;

  /// Called when a long press ends.
  LongEndCb? get onLongPressEnd;

  /// Called when a secondary long press completes.
  CoreVoidCallback? get onSecondaryLongPress;

  /// Called when a tertiary long press completes.
  CoreVoidCallback? get onTertiaryLongPress;

  /// Alignment of the clickable within its margin.
  Align? get marginAlignment;

  /// Platform focus node. Flutter framework only — Web returns `null`.
  Object? get focusNode;

  /// Platform mouse cursor override. Flutter framework only — Web
  /// derives the cursor from [enabled] automatically.
  Object? get mouseCursor;

  /// Per-instance chrome / dimensional / animation style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreClickableTheme.style
  ///   → parent component slot override
  ///   → widget.clickableStyle
  /// ```
  CoreClickableStyle? get clickableStyle;
}
