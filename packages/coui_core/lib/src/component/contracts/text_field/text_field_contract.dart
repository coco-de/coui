/// Platform-independent contract for text field components.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/text_field/input_type.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_variant.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/retiring_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a text field component.
///
/// Per Epic #1302, every chrome / dimensional / cursor / slot-text
/// override flows through the single [textFieldStyle] field — see
/// [CoreTextFieldStyle] for the merge chain. Semantic enums
/// (`variant` / `size`) stay flat on the contract because they
/// describe the field's **identity**. Behaviour fields (callbacks,
/// validation flags, keyboard config, scroll, selection, autofill,
/// platform-specific advanced options) likewise stay flat.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
/// - [Focus] — focus node type (Flutter `FocusNode`, Web `CoreFocusNode`).
/// - [States] — states controller
///   (Flutter `WidgetStatesController`, Web `CoreStatesController`).
/// - [Ctrl] — text editing controller (Flutter `TextEditingController`).
/// - [TapOutCb] — pointer-down-outside callback (Flutter
///   `TapRegionCallback`, Web `void Function()`).
/// - [TapUpOutCb] — pointer-up-outside callback (Flutter
///   `TapRegionUpCallback`, Web `void Function()`). A separate parameter
///   because Flutter hands the two callbacks different event types — a
///   single shared one typed the up callback with the down event, which
///   no framework hook could ever call.
/// - [InputFmt] — input formatter list (Flutter `List<TextInputFormatter>`).
///
/// The submit callback is the platform-neutral [CoreValueChanged] —
/// Flutter's `ValueChanged<String>` is structurally identical, so no
/// platform type parameter is needed.
abstract interface class CoreTextFieldContract<
  W,
  Focus,
  States,
  Ctrl,
  TapOutCb,
  TapUpOutCb,
  InputFmt
> {
  /// Default maximum visible text lines. Single-line is the canonical
  /// text-field shape; multi-line input is served by `TextArea`.
  /// Shared by Flutter / Web widget const constructors so the row
  /// count stays in sync.
  static const int defaultMaxLines = 1;

  /// The sizes this field is retiring — handed to `noticeRetiringSize`
  /// by both platform resolvers, which log it once wherever asserts are on.
  ///
  /// `xs` (announced in coui_core 0.141): from coui_core 0.153 at the
  /// earliest its ladder row is gone, so `xs` renders the `sm` row and a
  /// run with asserts on stops on it.
  static const List<CoreRetiringSize> retiringSizes = [
    CoreRetiringSize(
      size: CoreComponentSize.xs,
      fallback: CoreComponentSize.sm,
      removedIn: '0.153',
    ),
  ];

  // === Behaviour defaults (project-wide policy — single source) ===
  //
  // Input-policy booleans are not chrome, so they live on the contract
  // as `static const` (not in `CoreTextFieldTheme`, which is
  // `{style, variantStyles}` only). Both platform widgets default their
  // constructor flags to these so Flutter ↔ Web stay in sync.

  /// Default for selecting all text on focus.
  static const bool defaultSelectAllOnFocus = false;

  /// Autocorrect where the platform has nothing to infer from.
  ///
  /// Not a constructor default. [CoreTextFieldContract.autocorrect] is
  /// nullable so that null can mean "the platform decides", and Flutter
  /// decides from the autofill hints — a username or password hint turns
  /// autocorrect off on iOS, which a stated `true` would override. This
  /// is the value a platform falls back to when it has no such inference,
  /// which on the web is always.
  static const bool defaultAutocorrect = true;

  /// Default for showing input method suggestions.
  static const bool defaultEnableSuggestions = true;

  /// Default for enabling interactive text selection.
  static const bool defaultEnableInteractiveSelection = true;

  /// Default for enabling IME personalised learning.
  static const bool defaultEnableIMEPersonalizedLearning = true;

  /// Default for stylus handwriting input.
  static const bool defaultStylusHandwritingEnabled = true;

  /// Default for cursor opacity animation (blink).
  static const bool defaultCursorOpacityAnimates = true;

  /// Default inset used when the field is scrolled into view — 20
  /// logical/CSS px on all four sides. Shared by the Flutter / Web
  /// widget const constructors.
  ///
  /// Flutter hands this to `EditableText.scrollPadding`, whose own doc
  /// calls it the padding around the scrollable when the field is
  /// scrolled into view; nothing is painted at any value, so it lives on
  /// the widget plane (`core/style-contract.md`: Style slots carry
  /// visual chrome only) rather than in `CoreTextFieldStyle`.
  static const CoreEdgeInsets defaultScrollPadding = CoreEdgeInsets.all(
    CoreSpace.space20,
  );

  // === Content ===

  /// Placeholder shown when the input is empty.
  /// Flutter: `Widget?`, Web: `Component?`.
  W? get placeholder;

  /// Initial text value, seeding the field when **uncontrolled**
  /// (no [value] / [controller] supplied).
  String? get initialValue;

  /// Controlled current value, absorbed from the unified `Input`
  /// primitive. When non-null the field is **controlled** — the parent
  /// owns the text and pushes updates here (mirroring the HTML `<input
  /// value>` model), so the displayed text follows [value] and the
  /// parent must update it from [onChanged]. Leave null for the
  /// uncontrolled [initialValue] / [controller] model.
  String? get value;

  /// Called when the text value changes.
  CoreValueChanged<String>? get onChanged;

  /// Called when the user submits (e.g. pressing Enter).
  CoreValueChanged<String>? get onSubmitted;

  /// Whether the text field is enabled.
  bool get enabled;

  /// Inset kept clear when the field is scrolled into view. Behaviour,
  /// not chrome — Flutter forwards it to `EditableText.scrollPadding`
  /// and Web emits it as the input's `scroll-padding`; neither paints
  /// anything.
  CoreEdgeInsets get scrollPadding;

  /// Whether the text field is read-only.
  bool get readOnly;

  /// Whether to automatically focus this field.
  bool get autofocus;

  // === Semantic identity (widget params, not chrome) ===

  /// Size token (sm / md / lg / xl / xl2).
  ///
  /// `xs` is accepted but retiring on this field (since 0.141) — see
  /// `CoreTextFieldStyle.defaultsBySize` for why and [retiringSizes] for
  /// when. Until its row is removed (coui_core 0.153 at the earliest) it
  /// still renders its own row, so passing it is not an error (a run with
  /// asserts on logs a notice once); new call sites should pick `sm`
  /// instead.
  CoreComponentSize get size;

  /// The chrome variant when the field is not in error. `null` → the
  /// normal boxed field; `plain` is a bare field for a host that draws the
  /// boundary itself. An `errorText` always wins — a field cannot be bare
  /// and in error at once.
  CoreTextFieldVariant? get variant;

  // === Style (chrome / dimensional / cursor / slot text + icon) ===

  /// Per-instance text field style covering chrome + dimensional +
  /// cursor + nested label / placeholder / value / description /
  /// error / leading / trailing icon styles.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default for variant
  ///   → CoreTextFieldTheme.style
  ///   → CoreTextFieldTheme.variantStyles[variant]
  ///   → parent component slot override
  ///   → widget.textFieldStyle
  /// ```
  ///
  /// Named [textFieldStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding, and so the widget's `style` parameter (raw
  /// platform-specific input text style) stays unambiguous.
  CoreTextFieldStyle? get textFieldStyle;

  // === Validation ===

  /// Label text displayed above the field.
  String? get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  /// Description/helper text below the field.
  String? get description;

  /// Error message. When non-null, field shows error variant.
  String? get errorText;

  /// Whether the field is required.
  bool get required;

  // === Text behaviour ===

  /// Whether the field **starts** obscured (password mode).
  ///
  /// This is an initial seed, not a live binding: the field reads it once
  /// when it mounts (OR-ed with `type: .password`) and owns the obscured
  /// state from then on. Changing it on a later rebuild does nothing — the
  /// field keeps whatever state it had. When no `passwordToggle` feature is
  /// present, a debug build reports the change (a non-fatal error report on
  /// Flutter, a console warning on Web) so the mismatch does not pass
  /// silently — it does not throw.
  ///
  /// To let the user show and hide the text, add
  /// `CoreInputFeature.passwordToggle()` to `features`. To restart from a
  /// different seed, give the field a new `key` so it mounts again.
  bool get obscureText;

  /// Character used to obscure text when [obscureText] is true.
  String get obscuringCharacter;

  /// Maximum character count.
  int? get maxLength;

  // === HTML-semantic type + validation (absorbed from `Input`) ===
  //
  // The unified `Input` primitive folded into `TextField`; these mirror
  // the HTML `<input>` element's `type` and validation attributes. On
  // Web they emit native `<input>` attributes, so the browser runs its
  // own constraint validation on top of whatever the widgets do.
  //
  // [min] / [max] are enforced by both platforms through
  // [isRangeViolation], which feeds the same error state the rest of the
  // field's validation uses. [pattern] / [minLength] / [title] are still
  // Web-only metadata — Flutter does not read them, and this comment is
  // the only place that says so.

  /// The text input type (text / password / email / number / …).
  /// Drives the platform keyboard and obscuring defaults; on Web emits
  /// the native `<input type>` attribute.
  CoreInputType get type;

  /// Minimum number of characters allowed.
  int? get minLength;

  /// Validation pattern (regular expression source). Web `<input
  /// pattern>`; carried as metadata on Flutter.
  String? get pattern;

  /// Minimum numeric value (for `number` type). Web `<input min>`.
  num? get min;

  /// Maximum numeric value (for `number` type). Web `<input max>`.
  num? get max;

  /// Whether [text] sits outside the `[min, max]` range.
  ///
  /// Mirrors the browser's `rangeUnderflow` / `rangeOverflow` validity
  /// flags — the ones `<input type="number" min max>` raises. Text that
  /// does not parse as a number is *not* a range violation (the browser
  /// files that under `badInput`), an absent bound does not constrain,
  /// and empty text is unconstrained.
  ///
  /// This reports; it does not repair. A browser leaves `99` sitting in a
  /// `max="10"` field and only marks it `:invalid` — clamping would make
  /// Flutter silently rewrite what someone typed while Web preserved it,
  /// which trades one divergence for another instead of closing it.
  /// Clamping belongs to stepper affordances, which neither platform has
  /// yet.
  static bool isRangeViolation(String text, {num? min, num? max}) {
    if (min == null && max == null) return false;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final value = num.tryParse(trimmed);
    if (value == null) return false;

    if (min != null && value < min) return true;

    return max != null && value > max;
  }

  /// Advisory title shown on validation failure. Web `<input title>`.
  String? get title;

  /// Maximum number of lines (1 = single line).
  int? get maxLines;

  /// Minimum number of lines.
  int? get minLines;

  /// Whether the field expands to fill available height.
  bool get expands;

  /// Whether to enable autocorrect, or null to let the platform infer it.
  ///
  /// Null is the useful default rather than a missing value: Flutter reads
  /// the autofill hints and turns autocorrect off for a username or
  /// password field, and a stated `true` silently replaces that. Callers
  /// that state a value are taken at their word.
  ///
  /// An obscured field disables autocorrect regardless of what is stated
  /// here — see [obscureText].
  bool? get autocorrect;

  /// Whether to select the entire text when the field gains focus.
  bool get selectAllOnFocus;

  /// Whether to show input suggestions.
  bool get enableSuggestions;

  /// Whether interactive selection is enabled.
  bool get enableInteractiveSelection;

  /// Whether to enable IME personalised learning.
  bool get enableIMEPersonalizedLearning;

  /// Whether stylus handwriting is enabled.
  bool get stylusHandwritingEnabled;

  // === Prefix/Suffix ===

  /// Widget displayed before the input.
  W? get prefix;

  /// Widget displayed after the input.
  W? get suffix;

  // === Form ===

  /// Form field name for submission.
  String? get name;

  /// Hint text for autofill.
  String? get hintText;

  /// The value a field reports to an enclosing `FormField` for [text].
  ///
  /// A text field sitting inside a `FormField` reports what it holds — on
  /// mount, and again on every change — so the form controller can validate
  /// it. Empty text is *no value* (`null`), not the empty string: an
  /// optional field left blank is "not answered", which is what
  /// `FormController.hasValue` and a validator's `value == null` branch
  /// read. Both platforms take the rule from here so a blank field is the
  /// same answer on each.
  ///
  /// Not a form-participation switch: a field outside a `FormField`
  /// reports to nothing, and an input a composite embeds as an
  /// implementation detail (`PhoneInput`'s number field, `Select`'s
  /// trigger…) is walled off from the field around the composite — the
  /// composite owns the value the field sees.
  static String? formValueOf(String text) => text.isEmpty ? null : text;

  // === Controller ===

  /// Text editing controller.
  /// Flutter: `TextEditingController?`.
  Ctrl? get controller;

  // === Focus & State ===

  /// Focus node for keyboard focus management.
  Focus? get focusNode;

  /// External controller for component interaction states.
  States? get statesController;

  // === Cursor (chrome-bound, but interaction toggles stay here) ===

  /// Whether to show the cursor.
  bool? get showCursor;

  /// Whether cursor opacity animates on blink.
  bool get cursorOpacityAnimates;

  // === Keyboard ===

  /// Keyboard type.
  /// Flutter: `TextInputType?`. Web: `Object?`.
  Object? get keyboardType;

  /// Text input action (e.g. done, next).
  /// Flutter: `TextInputAction?`. Web: `Object?`.
  Object? get textInputAction;

  /// Text capitalisation behaviour.
  /// Flutter: `TextCapitalization`. Web: `Object?`.
  Object? get textCapitalization;

  /// Keyboard appearance (light/dark).
  /// Flutter: `Brightness?`. Web: `Object?`.
  Object? get keyboardAppearance;

  // === Input formatting ===

  /// Maximum length enforcement strategy.
  /// Flutter: `MaxLengthEnforcement?`. Web: `Object?`.
  Object? get maxLengthEnforcement;

  /// Input formatters applied during editing.
  /// Flutter: `List<TextInputFormatter>?`.
  InputFmt? get inputFormatters;

  /// Formatters applied on submit.
  /// Flutter: `List<TextInputFormatter>?`.
  InputFmt? get submitFormatters;

  // === Callbacks ===

  /// Called when editing is complete (e.g. focus lost).
  CoreVoidCallback? get onEditingComplete;

  /// Called when the field is tapped.
  CoreVoidCallback? get onTap;

  /// Called when the user taps outside the field.
  /// Flutter: `TapRegionCallback?`.
  TapOutCb? get onTapOutside;

  /// Called when tap-up occurs outside the field.
  /// Flutter: `TapRegionUpCallback?`.
  TapUpOutCb? get onTapUpOutside;

  // === Scrolling ===

  /// Scroll controller for the input.
  /// Flutter: `ScrollController?`. Web: `Object?`.
  Object? get scrollController;

  /// Scroll physics for the input.
  /// Flutter: `ScrollPhysics?`. Web: `Object?`.
  Object? get scrollPhysics;

  // === Selection ===

  /// Selection controls (copy/paste handles).
  /// Flutter: `TextSelectionControls?`. Web: `Object?`.
  Object? get selectionControls;

  /// Selection highlight height style.
  /// Flutter: `BoxHeightStyle`. Web: `Object?`.
  Object? get selectionHeightStyle;

  /// Selection highlight width style.
  /// Flutter: `BoxWidthStyle`. Web: `Object?`.
  Object? get selectionWidthStyle;

  /// Drag start behaviour.
  /// Flutter: `DragStartBehavior`. Web: `Object?`.
  Object? get dragStartBehavior;

  // === Layout (behaviour, not chrome) ===

  /// Text direction (LTR/RTL).
  /// Flutter: `TextDirection?`. Web: `Object?`.
  Object? get textDirection;

  // === Autofill ===

  /// Autofill hints for the platform.
  Iterable<String>? get autofillHints;

  // === Accessibility ===

  /// Semantic label for the clear button.
  String? get clearButtonSemanticLabel;

  // === Clip & Restoration ===

  /// Clip behaviour for the field.
  /// Flutter: `Clip`. Web: `Object?`.
  Object? get clipBehavior;

  /// Restoration ID for state restoration.
  String? get restorationId;

  // === Advanced platform configuration ===

  /// Content insertion configuration.
  /// Flutter: `ContentInsertionConfiguration?`. Web: `Object?`.
  Object? get contentInsertionConfiguration;

  /// Context menu builder.
  /// Flutter: `EditableTextContextMenuBuilder?`. Web: `Object?`.
  Object? get contextMenuBuilder;

  /// Magnifier configuration.
  /// Flutter: `TextMagnifierConfiguration?`. Web: `Object?`.
  Object? get magnifierConfiguration;

  /// Strut style controlling the vertical line-height layout of the
  /// editable text.
  ///
  /// Flutter-only: when omitted, `EditableText` derives an implicit
  /// strut from the resolved value `TextStyle` with
  /// `forceStrutHeight: true`, which can render a visibly different
  /// line spacing than a plain `Text` widget given the *same*
  /// `TextStyle` (no Web equivalent — browsers size lines from CSS
  /// `line-height` directly, with no separate forced-strut concept).
  /// Pass `StrutStyle.disabled` to make the field's line spacing match
  /// a sibling `Text` widget exactly.
  ///
  /// Flutter: `StrutStyle?`. Web: `Object?`.
  Object? get strutStyle;

  /// Spell check configuration.
  ///
  /// Ignored while the field is obscured — spell check sends the text to
  /// a platform service, and an obscured field's text is the one thing
  /// that must not go there. Obscuring by [obscureText], by a password
  /// type, or by the reveal toggle all count.
  ///
  /// Flutter: `SpellCheckConfiguration?`. Web: `Object?` — the web states
  /// spell check as an element attribute rather than a configuration
  /// object, so this stays null there and the attribute carries it.
  Object? get spellCheckConfiguration;

  /// Undo history controller.
  /// Flutter: `UndoHistoryController?`. Web: `Object?`.
  Object? get undoController;

  // === Feature system ===

  /// Input features (e.g. password toggle, clear button).
  /// Flutter: `List<InputFeature>`. Web: `Object?`.
  Object? get features;

  /// Whether to skip focus traversal for input features.
  ///
  /// When `true` the affordance buttons stay reachable by pointer and by
  /// programmatic focus, but drop out of the Tab order — the semantics of
  /// `tabindex="-1"`, which is what the Web side emits. Excluding them from
  /// focus entirely is a different (and wrong) behaviour.
  bool get skipInputFeatureFocusTraversal;

  /// Default for [skipInputFeatureFocusTraversal].
  static const bool defaultSkipInputFeatureFocusTraversal = true;

  /// Group ID for text field grouping.
  Object get groupId;
}
