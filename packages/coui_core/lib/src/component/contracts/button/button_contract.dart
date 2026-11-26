/// Platform-independent contract for button components.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/button/button_shape.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/button/button_variant.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/surface/surface_role.dart';

/// Contract for a button component.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [buttonStyle] field — see [CoreButtonStyle] for the
/// merge chain. Semantic enums (`variant` / `size` / `shape`) stay
/// flat on the contract because they describe the button's
/// **identity**, not its appearance — Style is the chrome layer
/// applied on top of whichever variant / size / shape was selected.
/// (Epic #1302 원칙 6 / 7.) Behaviour fields (callbacks, focus,
/// states …) likewise stay flat.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
/// - [TapDownCb] — tap down callback (Flutter `GestureTapDownCallback`).
/// - [TapUpCb] — tap up callback (Flutter `GestureTapUpCallback`).
/// - [LongStartCb] — long press start callback
///   (Flutter `GestureLongPressStartCallback`).
/// - [LongEndCb] — long press end callback
///   (Flutter `GestureLongPressEndCallback`).
/// - [LongMoveCb] — long press move callback
///   (Flutter `GestureLongPressMoveUpdateCallback`).
/// - [Align] — alignment type (Flutter `AlignmentGeometry`).
/// - [Focus] — focus node type (Flutter `FocusNode`).
/// - [States] — states controller type (Flutter `WidgetStatesController`).
abstract interface class CoreButtonContract<
  W,
  TapDownCb,
  TapUpCb,
  LongStartCb,
  LongEndCb,
  LongMoveCb,
  Align,
  Focus,
  States
> {
  /// Default for [enableFeedback] when a button states nothing — on,
  /// on every platform. Shared so the two widgets cannot pick different
  /// answers for the same unset parameter.
  static const bool defaultEnableFeedback = true;

  // === Content ===

  /// The main content of the button.
  W get child;

  /// Widget displayed before the main content (e.g. icon).
  W? get leading;

  /// Widget displayed after the main content (e.g. icon).
  W? get trailing;

  /// Called when the button is pressed.
  CoreVoidCallback? get onPressed;

  /// Whether the button is enabled.
  bool? get enabled;

  /// Destination of a link-button. `null` keeps a plain action button.
  ///
  /// On Web, a non-empty [href] renders a real `<a href>` while the
  /// button is enabled — crawlable, middle-click, open-in-new-tab.
  /// An explicit `enabled: false` stays a disabled `<button>` and does
  /// not publish the URL, so disabled chrome (`:disabled`) still applies.
  ///
  /// On Flutter there is no anchor element. [href] is a semantics
  /// declaration (`Semantics.link` + `linkUrl`); the host navigates in
  /// [onPressed]. A set [href] still counts as interactive, so the
  /// button is not painted disabled merely because [onPressed] is null.
  String? get href;

  /// Whether a link-button opens in a new browsing context.
  ///
  /// On Web, sets `target="_blank"` and `rel="noopener noreferrer"`
  /// when the button renders as an anchor. Ignored when [href] is
  /// null or the button is disabled. On Flutter the host's
  /// [onPressed] is expected to honour the external intent.
  bool get external;

  // === Semantic identity (widget params, not chrome) ===

  /// Visual variant. Identifies the button semantically (primary /
  /// secondary / outline / …); the design system maps this to a
  /// pre-defined chrome look.
  CoreButtonVariant get variant;

  /// Size token (xs / sm / md / lg / xl).
  CoreComponentSize get size;

  /// Shape (rectangle / square / circle).
  CoreButtonShape get shape;

  /// Which layer this button sits on, and therefore which content-role
  /// material its fill scales under a style that states one.
  ///
  /// Not a style choice. It answers the same question the widget's own
  /// `surface:<role>` declaration answers — whether the code has
  /// evidence that this instance floats over content (an overlay
  /// portal, an anchored popover, sticky/fixed docking) — and it exists
  /// because a caller composing a button into a floating affordance the
  /// button itself has no way to detect needs a way to say so, the same
  /// reason `CoreCardContract.role` exists.
  ///
  /// Defaults to [CoreSurfaceRole.defaultRole] (`content`) — a plain
  /// button has none of that evidence on its own, so every existing
  /// caller keeps the material it already had.
  CoreSurfaceRole get role;

  // === Style (chrome / dimensional / nested slot) ===

  /// Per-instance button style covering chrome + dimensional
  /// overrides plus nested label / leading / trailing icon styles.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default for variant
  ///   → CoreButtonTheme.style
  ///   → CoreButtonTheme.variantStyles[variant]
  ///   → parent component slot override
  ///   → widget.buttonStyle
  /// ```
  ///
  /// Named [buttonStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreButtonStyle? get buttonStyle;

  // === Layout (behaviour, not chrome) ===

  /// Content alignment within the button.
  Align? get alignment;

  /// Margin alignment for the button.
  Align? get marginAlignment;

  /// Whether the button expands to fill available width. Layout
  /// behaviour distinct from a width override — kept on the contract.
  bool get expanded;

  // === Interaction callbacks ===

  /// Called when hover state changes.
  CoreValueChanged<bool>? get onHover;

  /// Called when focus state changes.
  CoreValueChanged<bool>? get onFocus;

  // -- Primary tap --

  /// Called when a primary pointer contacts the button.
  TapDownCb? get onTapDown;

  /// Called when a primary pointer is released on the button.
  TapUpCb? get onTapUp;

  /// Called when a primary tap is cancelled.
  CoreVoidCallback? get onTapCancel;

  // -- Secondary tap (right-click / two-finger tap) --

  /// Called when a secondary pointer contacts the button.
  TapDownCb? get onSecondaryTapDown;

  /// Called when a secondary pointer is released on the button.
  TapUpCb? get onSecondaryTapUp;

  /// Called when a secondary tap is cancelled.
  CoreVoidCallback? get onSecondaryTapCancel;

  // -- Tertiary tap (middle-click) --

  /// Called when a tertiary pointer contacts the button.
  TapDownCb? get onTertiaryTapDown;

  /// Called when a tertiary pointer is released on the button.
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

  // === Visual options (interaction-bound) ===

  /// Whether to disable state transition animations.
  bool get disableTransition;

  /// Whether to disable the focus outline.
  bool get disableFocusOutline;

  /// Whether pressing the button gives feedback: the press shrink
  /// (`CoreButtonStyle.pressedScale`) on both platforms, plus the tap
  /// announcement and — on a mobile platform whose theme allows it —
  /// the click sound on Flutter. `null` defers to
  /// [defaultEnableFeedback]; `false` turns all of it off.
  bool? get enableFeedback;

  // === Focus & State ===

  /// Focus node for keyboard focus management.
  Focus? get focusNode;

  /// External controller for component interaction states.
  States? get statesController;
}
