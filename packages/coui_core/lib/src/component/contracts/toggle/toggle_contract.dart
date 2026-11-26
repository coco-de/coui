/// Platform-independent contract for toggle (switch) components.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/toggle/toggle_style.dart';
import 'package:coui_core/src/component/contracts/toggle/toggle_variant.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/retiring_size.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a toggle (switch) component.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [toggleStyle] field — see [CoreToggleStyle] for the
/// merge chain. Semantic enums (`variant`, `size`) stay flat on the
/// contract because they describe the toggle's **identity**.
/// Behaviour fields (callbacks, focus, controllers) likewise stay
/// flat.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
/// - [Focus] — focus node type
///   (Flutter `FocusNode`, Web `CoreFocusNode`).
/// - [States] — states controller (Flutter `WidgetStatesController`).
/// - [Ctrl] — toggle controller type.
///
/// The value-change callback is the platform-neutral
/// [CoreValueChanged] — Flutter's `ValueChanged<bool>` is structurally
/// identical, so no platform type parameter is needed.
abstract interface class CoreToggleContract<W, Focus, States, Ctrl> {
  /// The sizes this toggle is retiring — handed to `noticeRetiringSize`
  /// by both platform resolvers, which log it once wherever asserts are on.
  ///
  /// `xs` lost its own ladder row in the toggle redesign and already
  /// renders as `sm` (`CoreToggleStyle.sizeDefaults`), so nothing changes
  /// on screen. What changes from coui_core 0.153 at the earliest is that
  /// a run with asserts on stops on it instead of logging this notice.
  static const List<CoreRetiringSize> retiringSizes = [
    CoreRetiringSize(
      size: CoreComponentSize.xs,
      fallback: CoreComponentSize.sm,
      removedIn: '0.153',
      alreadyFallsBack: true,
    ),
  ];

  // === State ===

  /// Whether the toggle is currently on.
  bool get value;

  /// Called when the toggle value changes.
  CoreValueChanged<bool>? get onChanged;

  /// Whether the toggle is enabled.
  bool? get enabled;

  // === Content ===

  /// Widget displayed before the toggle track.
  W? get prefix;

  /// Widget displayed after the toggle track.
  W? get suffix;

  /// Optional text label displayed next to the toggle.
  String? get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  // === Semantic identity (widget params, not chrome) ===

  /// Visual variant. Identifies the toggle semantically.
  CoreToggleVariant get variant;

  /// Size token (sm / md / lg / xl / xl2). `xs` has no row of its own and
  /// resolves to `sm` — see `CoreToggleStyle.sizeDefaults`. It is retiring
  /// ([retiringSizes]): a run with asserts on logs a notice once, and from
  /// coui_core 0.153 at the earliest it stops on it.
  CoreComponentSize get size;

  // === Style (chrome / dimensional / nested slot) ===

  /// Per-instance toggle style covering track + thumb chrome plus
  /// nested label style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default for variant
  ///   → CoreToggleTheme.style
  ///   → CoreToggleTheme.variantStyles[variant]
  ///   → parent component slot override
  ///   → widget.toggleStyle
  /// ```
  ///
  /// Named [toggleStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreToggleStyle? get toggleStyle;

  // === Form ===

  /// Form field name for submission.
  String? get name;

  // === Focus & State ===

  /// Focus node for keyboard focus management.
  Focus? get focusNode;

  /// External controller for component states.
  States? get statesController;

  /// Toggle controller for programmatic state management.
  Ctrl? get controller;
}
