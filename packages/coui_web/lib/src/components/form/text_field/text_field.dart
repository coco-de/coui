import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/debug_warn.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/form_field/form_field_scope.dart';
import 'package:coui_web/src/components/form/form_label/form_label.dart';
import 'package:coui_web/src/components/form/text_field/text_field_style.dart';
import 'package:coui_web/src/components/form/validated/validation_state_scope.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/components/text/text.dart' as coui_text;
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

// The resolver marks only explicitly emitted hint properties and publishes
// their values as input-local variables. These private rules apply them to
// the pseudo-element without adding fields to ResolvedTextFieldRules.
const _kHintTypographyCss =
    '.co-text-field-hint-font-family::placeholder{'
    'font-family:var(--co-text-field-hint-font-family);}'
    '.co-text-field-hint-font-size::placeholder{'
    'font-size:var(--co-text-field-hint-font-size);}'
    '.co-text-field-hint-font-weight::placeholder{'
    'font-weight:var(--co-text-field-hint-font-weight);}'
    '.co-text-field-hint-line-height::placeholder{'
    'line-height:var(--co-text-field-hint-line-height);}'
    '.co-text-field-hint-letter-spacing::placeholder{'
    'letter-spacing:var(--co-text-field-hint-letter-spacing);}';

/// Unified cross-platform text field for CoUI Web with token-based rendering.
///
/// [TextField] auto-determines `variant` from [errorText] and implements
/// [CoreTextFieldContract] for cross-platform API parity with Flutter.
///
/// Internally a [StatefulComponent] so the wrapper can track keyboard
/// focus on the underlying `<input>` (`:focus-visible`) and forward it
/// to [FocusOutline] — the same model the Flutter implementation uses.
///
/// Example:
/// ```dart
/// TextField(
///   placeholder: Text('Enter your email'),
///   onChanged: (value) => print(value),
/// )
/// ```
///
/// surface:behind — the field's box paints on the wrapper `<div>` that
/// holds the native `<input>` and its slots, rather than composing
/// `OutlinedContainer`, so what shows through it is the page it is laid on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class TextField extends UiStatefulComponent
    implements
        CoreTextFieldContract<
          Component,
          CoreFocusNode,
          CoreStatesController,
          Object,
          void Function(),
          void Function(),
          List<CoreInputFormatter>
        > {
  /// Creates a [TextField].
  const TextField({
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
    this.placeholder,
    this.initialValue,
    this.value,
    this.onChanged,
    this.onCaretChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.showCursor,
    this.size = CoreComponentSize.md,
    this.variant,
    this.textFieldStyle,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.errorText,
    this.required = false,
    this.obscureText = false,
    this.maxLength,
    // === HTML-semantic type + validation (absorbed from `Input`) ===
    this.type = CoreInputType.defaultType,
    this.minLength,
    this.pattern,
    this.min,
    this.max,
    this.title,
    this.maxLines,
    this.minLines,
    this.prefix,
    this.suffix,
    this.name,
    this.focusNode,
    this.statesController,
    this.autocorrect,
    this.selectAllOnFocus = false,
    this.scrollPadding = CoreTextFieldContract.defaultScrollPadding,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization,
    this.autofillHints,
    this.textDirection,
    this.onTap,
    this.onEditingComplete,
    this.onTapOutside,
    this.onTapUpOutside,
    this.inputFormatters,
    this.submitFormatters = const [],
    this.features = const [],
    this.skipInputFeatureFocusTraversal =
        CoreTextFieldContract.defaultSkipInputFeatureFocusTraversal,
    this.clearButtonSemanticLabel,
    this.expands = false,
    this.hintText,
  });

  // === Contract fields ===

  @override
  final Component? placeholder;

  @override
  final String? initialValue;

  /// Controlled current value — when non-null, the parent owns the text
  /// and it renders as the `<input value>` attribute (HTML `<input>`
  /// model, absorbed from the unified `Input` primitive).
  @override
  final String? value;

  @override
  final CoreValueChanged<String>? onChanged;

  /// Reports the caret offset each time the text changes.
  ///
  /// Web-only, and deliberately so: this is the DOM-native form of a
  /// capability Flutter already supplies through [controller], which is
  /// itself a Flutter-only runtime type. A composing parent that has to
  /// know *where* in the field an edit happened — completing the word
  /// under the caret rather than the whole field — reads
  /// `TextEditingController.selection` on Flutter and this on Web.
  ///
  /// Fires immediately before [onChanged], so a listener that keeps both
  /// sees a caret that matches the value it is handed.
  final CoreValueChanged<int>? onCaretChanged;

  @override
  final CoreValueChanged<String>? onSubmitted;

  @override
  final bool enabled;

  @override
  final bool readOnly;

  @override
  final bool autofocus;

  @override
  final CoreComponentSize size;

  @override
  final CoreTextFieldVariant? variant;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final String? description;

  @override
  final String? errorText;

  @override
  final bool required;

  /// Initial obscured seed only — later changes are ignored. See
  /// [CoreTextFieldContract.obscureText].
  @override
  final bool obscureText;

  @override
  final int? maxLength;

  // === HTML-semantic type + validation (absorbed from `Input`) ===
  //
  // Emit native `<input>` attributes for real constraint validation.

  /// The HTML input type (text / password / email / number / …) emitted
  /// as the `<input type>` attribute.
  @override
  final CoreInputType type;

  /// Minimum character count — `<input minlength>`.
  @override
  final int? minLength;

  /// Validation pattern (regex source) — `<input pattern>`.
  @override
  final String? pattern;

  /// Minimum numeric value — `<input min>`.
  @override
  final num? min;

  /// Maximum numeric value — `<input max>`.
  @override
  final num? max;

  /// Advisory title shown on validation failure — `<input title>`.
  @override
  final String? title;

  @override
  final int? maxLines;

  @override
  final int? minLines;

  @override
  final Component? prefix;

  @override
  final Component? suffix;

  @override
  final String? name;

  @override
  final CoreFocusNode? focusNode;

  @override
  final CoreStatesController? statesController;

  // === Style (chrome / dimensional / cursor / nested slot) ===

  /// Per-instance style covering chrome (border, background) plus
  /// dimensional (paddings), cursor, and nested label / placeholder /
  /// value / description / error / leading / trailing icon styles.
  @override
  final CoreTextFieldStyle? textFieldStyle;

  @override
  final bool expands;

  @override
  final bool? autocorrect;

  @override
  final bool selectAllOnFocus;

  @override
  final CoreEdgeInsets scrollPadding;

  /// Additional hint text rendered via HTML `placeholder` attribute.
  @override
  final String? hintText;

  /// When `false`, hides the text caret (parity with Flutter
  /// `EditableText.showCursor: false`). `null` / `true` shows the caret.
  @override
  final bool? showCursor;

  /// HTML `dir` attribute value (`'ltr'`, `'rtl'`, `'auto'`).
  @override
  final String? textDirection;

  /// HTML `inputmode` attribute value.
  @override
  final String? keyboardType;

  /// HTML `enterkeyhint` attribute value.
  @override
  final String? textInputAction;

  /// HTML `autocapitalize` attribute value.
  @override
  final String? textCapitalization;

  /// Formatters applied to the text as it changes (parity with Flutter
  /// `TextField.inputFormatters`). Web binds [CoreInputFormatter]; the
  /// param name matches Flutter, the binding type differs (generic).
  @override
  final List<CoreInputFormatter>? inputFormatters;

  /// Formatters applied to the committed text on submit (parity with
  /// Flutter `TextField.submitFormatters`).
  @override
  final List<CoreInputFormatter> submitFormatters;

  /// Called when editing is complete (HTML `change` event).
  @override
  final CoreVoidCallback? onEditingComplete;

  /// Called when the text field is tapped (HTML `click` event).
  @override
  final CoreVoidCallback? onTap;

  /// Called on a pointer-down outside the field (parity with Flutter
  /// `TextField.onTapOutside`). Wired via a document `pointerdown`
  /// listener scoped to the field's root id.
  @override
  final void Function()? onTapOutside;

  /// Called on a pointer-up outside the field (parity with Flutter
  /// `TextField.onTapUpOutside`). Wired via a document `pointerup`
  /// listener scoped to the field's root id.
  @override
  final void Function()? onTapUpOutside;

  /// HTML `autocomplete` attribute value(s).
  @override
  final Iterable<String>? autofillHints;

  /// Accessibility label for a [CoreInputFeature.clear] affordance.
  @override
  final String? clearButtonSemanticLabel;

  /// Built-in affordances (clear button, password toggle) rendered inside
  /// the field. Cross-platform parity with Flutter `TextField.features`;
  /// the binding type is platform-neutral [CoreInputFeature].
  @override
  final List<CoreInputFeature> features;

  /// Whether the [features] affordances drop out of the Tab order.
  ///
  /// Emitted as `tabindex="-1"` on each affordance when `true`, which keeps
  /// them pointer- and script-focusable — the browser-native spelling of the
  /// Flutter side's `FocusNode.skipTraversal`.
  @override
  final bool skipInputFeatureFocusTraversal;

  // === Flutter runtime-infra contract fields (browser-native on Web) ===
  //
  // These are fixed rather than exposed because the browser owns the
  // capability — a constructor parameter would accept a value nothing could
  // honour, which is worse than not offering it. Each one records why, so a
  // later reader does not "finish" a field that cannot be finished.

  /// The masking glyph is chosen by the browser for `<input type="password">`.
  /// CSS `-webkit-text-security` only offers `disc` / `circle` / `square`, so
  /// an arbitrary character is not expressible — `•` is what `disc` renders.
  @override
  String get obscuringCharacter => '•';

  /// Autocomplete / suggestion UI is the browser's, driven by the
  /// `autocomplete` attribute rather than a per-field boolean.
  @override
  bool get enableSuggestions => true;

  /// Text selection gestures are native to the DOM and always available.
  @override
  bool get enableInteractiveSelection => true;

  /// IME personalisation is an OS/browser preference, not a field property.
  @override
  bool get enableIMEPersonalizedLearning => true;

  /// Stylus handwriting is handled by the platform IME on the web.
  @override
  bool get stylusHandwritingEnabled => false;

  @override
  Object? get controller => null;

  @override
  bool get cursorOpacityAnimates => true;

  @override
  Object? get keyboardAppearance => null;

  @override
  Object? get maxLengthEnforcement => null;

  @override
  Object? get scrollController => null;

  @override
  Object? get scrollPhysics => null;

  @override
  Object? get selectionControls => null;

  @override
  Object? get selectionHeightStyle => null;

  @override
  Object? get selectionWidthStyle => null;

  @override
  Object? get dragStartBehavior => null;

  @override
  Object? get clipBehavior => null;

  @override
  String? get restorationId => null;

  @override
  Object? get contentInsertionConfiguration => null;

  @override
  Object? get contextMenuBuilder => null;

  @override
  Object? get magnifierConfiguration => null;

  /// Always null — the web states spell check as an element attribute,
  /// not a configuration object.
  ///
  /// This is not an unimplemented slot. `spellcheck` is emitted on the
  /// `<input>` (off while obscured), which is the same capability through
  /// the platform's own vocabulary.
  @override
  Object? get spellCheckConfiguration => null;

  @override
  Object? get undoController => null;

  // Flutter-only forced-strut workaround — the browser sizes native
  // `<input>`/`<textarea>` lines from CSS `line-height` directly, so
  // there is no separate strut concept to mirror.
  @override
  Object? get strutStyle => null;

  @override
  Object get groupId => TextField;

  /// Custom style override (currently unused on web).
  Object? get style => null;

  // === Internal ===

  static const _kInput = 'input';

  static const _kTypeAttr = 'type';
  static const _kValueAttr = 'value';
  static const _kPlaceholderAttr = 'placeholder';
  static const _kNameAttr = 'name';
  static const _kMaxlengthAttr = 'maxlength';
  static const _kDisabledAttr = 'disabled';
  static const _kReadonlyAttr = 'readonly';
  static const _kRequiredAttr = 'required';
  static const _kAutofocusAttr = 'autofocus';
  static const _kEmptyValue = '';
  static const _kPasswordInputType = 'password';

  /// Returns a copy of this [TextField] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  TextField copyWith({
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
    Component? placeholder,
    String? initialValue,
    String? value,
    CoreValueChanged<String>? onChanged,
    CoreValueChanged<int>? onCaretChanged,
    CoreValueChanged<String>? onSubmitted,
    bool? enabled,
    bool? readOnly,
    bool? autofocus,
    bool? showCursor,
    CoreComponentSize? size,
    CoreTextFieldVariant? variant,
    CoreTextFieldStyle? textFieldStyle,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? description,
    String? errorText,
    bool? required,
    bool? obscureText,
    int? maxLength,
    CoreInputType? type,
    int? minLength,
    String? pattern,
    num? min,
    num? max,
    String? title,
    int? maxLines,
    int? minLines,
    Component? prefix,
    Component? suffix,
    String? name,
    CoreFocusNode? focusNode,
    CoreStatesController? statesController,
    bool? autocorrect,
    bool? selectAllOnFocus,
    CoreEdgeInsets? scrollPadding,
    String? keyboardType,
    String? textInputAction,
    String? textCapitalization,
    Iterable<String>? autofillHints,
    String? textDirection,
    CoreVoidCallback? onTap,
    CoreVoidCallback? onEditingComplete,
    void Function()? onTapOutside,
    void Function()? onTapUpOutside,
    List<CoreInputFormatter>? inputFormatters,
    List<CoreInputFormatter>? submitFormatters,
    List<CoreInputFeature>? features,
    bool? skipInputFeatureFocusTraversal,
    String? clearButtonSemanticLabel,
    bool? expands,
    String? hintText,
  }) {
    return TextField(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onTap: onTap ?? this.onTap,
      onChanged: onChanged ?? this.onChanged,
      onCaretChanged: onCaretChanged ?? this.onCaretChanged,
      initialValue: initialValue ?? this.initialValue,
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
      placeholder: placeholder ?? this.placeholder,
      value: value ?? this.value,
      onSubmitted: onSubmitted ?? this.onSubmitted,
      enabled: enabled ?? this.enabled,
      readOnly: readOnly ?? this.readOnly,
      autofocus: autofocus ?? this.autofocus,
      showCursor: showCursor ?? this.showCursor,
      size: size ?? this.size,
      variant: variant ?? this.variant,
      textFieldStyle: textFieldStyle ?? this.textFieldStyle,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      description: description ?? this.description,
      errorText: errorText ?? this.errorText,
      required: required ?? this.required,
      obscureText: obscureText ?? this.obscureText,
      maxLength: maxLength ?? this.maxLength,
      type: type ?? this.type,
      minLength: minLength ?? this.minLength,
      pattern: pattern ?? this.pattern,
      min: min ?? this.min,
      max: max ?? this.max,
      title: title ?? this.title,
      maxLines: maxLines ?? this.maxLines,
      minLines: minLines ?? this.minLines,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      name: name ?? this.name,
      focusNode: focusNode ?? this.focusNode,
      statesController: statesController ?? this.statesController,
      autocorrect: autocorrect ?? this.autocorrect,
      selectAllOnFocus: selectAllOnFocus ?? this.selectAllOnFocus,
      scrollPadding: scrollPadding ?? this.scrollPadding,
      keyboardType: keyboardType ?? this.keyboardType,
      textInputAction: textInputAction ?? this.textInputAction,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      autofillHints: autofillHints ?? this.autofillHints,
      textDirection: textDirection ?? this.textDirection,
      onEditingComplete: onEditingComplete ?? this.onEditingComplete,
      onTapOutside: onTapOutside ?? this.onTapOutside,
      onTapUpOutside: onTapUpOutside ?? this.onTapUpOutside,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      submitFormatters: submitFormatters ?? this.submitFormatters,
      features: features ?? this.features,
      skipInputFeatureFocusTraversal:
          skipInputFeatureFocusTraversal ?? this.skipInputFeatureFocusTraversal,
      clearButtonSemanticLabel:
          clearButtonSemanticLabel ?? this.clearButtonSemanticLabel,
      expands: expands ?? this.expands,
      hintText: hintText ?? this.hintText,
    );
  }

  @override
  State<TextField> createState() => _TextFieldState();
}

/// Per-instance id seed so the root element can be scoped for the
/// document-level outside-pointer listeners (Flutter `onTapOutside` /
/// `onTapUpOutside` parity) when the caller does not supply `id`.
int _coTextFieldScopeCounter = 0;

class _TextFieldState extends State<TextField>
    with FormValueSupplier<String, TextField> {
  /// Tracks `:focus-visible` on the underlying `<input>` to drive
  /// [FocusOutline]. Mirrors the Flutter widget's `_focusNode.hasFocus`
  /// + highlight-mode logic.
  bool _focused = false;

  // Set by a pointer press on the field and read by the `focus` that the
  // press causes (#5747): a text input matches `:focus-visible` however it
  // was focused, so the browser's own rule would ring a clicked field. The
  // outer ring is a keyboard signal — a pointer focus shows on the `primary`
  // active boundary alone, the way the Flutter twin reads
  // `FocusHighlightMode`.
  final _focusModality = CoreInputFocusModality();

  /// Stable root id used by the outside-pointer listeners' containment
  /// test. Equals the caller [TextField.id] when supplied, otherwise
  /// a generated id.
  late final String _scopeId;

  /// Whether a tap-outside callback is wired (drives whether the root
  /// gets a forced [_scopeId] — keeps the DOM byte-identical when no
  /// callback is set).
  late final bool _needsScope;

  /// Disposer for the document `pointerdown` listener (`onTapOutside`).
  void Function()? _disposeTapOutside;

  /// Disposer for the document `pointerup` listener (`onTapUpOutside`).
  void Function()? _disposeTapUpOutside;

  bool _isMounted = false;

  /// Last committed text — fed to [CoreInputFormatter.format] as the
  /// `oldValue` so filtering formatters see the prior value, and to
  /// `textNotEmpty` / `textEmpty` feature visibility.
  String _lastValue = '';

  /// Whether [_lastValue] sits outside `min` / `max`.
  ///
  /// The browser raises `rangeOverflow` on the element itself, but no rule
  /// here paints `:invalid`, so the verdict is recomputed in Dart from the
  /// same [CoreTextFieldContract.isRangeViolation] the Flutter side uses.
  bool _rangeViolated = false;

  /// Runtime obscured state — seeded from [TextField.obscureText] and
  /// flipped by a [CoreInputFeature.passwordToggle].
  late bool _obscured;

  /// Whether the field is hovered (drives `hovered`-visibility features).
  bool _hovered = false;

  /// Stable `<input>` id used by [CoreInputFeature.clear] to reset the
  /// element value.
  String get _inputId => '$_scopeId-input';

  /// The shared range verdict for [text] under this field's bounds.
  bool _computeRangeViolation(String text) =>
      CoreTextFieldContract.isRangeViolation(
        text,
        min: component.min,
        max: component.max,
      );

  /// Updates [_rangeViolated] for [text]; returns whether the verdict
  /// flipped, so the caller can decide whether a re-render is owed.
  bool _syncRangeViolation(String text) {
    final violated = _computeRangeViolation(text);
    if (violated == _rangeViolated) return false;
    _rangeViolated = violated;

    return true;
  }

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _lastValue = component.value ?? component.initialValue ?? '';
    _rangeViolated = _computeRangeViolation(_lastValue);
    // The text the field starts with. Cached here and reported once the
    // enclosing `FormField` is found (`didChangeDependencies`), so the form
    // sees the initial text at mount rather than `null`.
    formValue = CoreTextFieldContract.formValueOf(_lastValue);
    // `type: password` (absorbed from `Input`) seeds the obscured state
    // alongside the explicit `obscureText` flag.
    _obscured = component.obscureText || component.type == .password;
    _needsScope =
        component.onTapOutside != null || component.onTapUpOutside != null;
    _scopeId = component.id ?? 'co-text-field-${_coTextFieldScopeCounter++}';

    final onTapOutside = component.onTapOutside;
    if (onTapOutside != null) {
      _disposeTapOutside = registerDocumentOutsidePointerListener(
        () {
          if (_isMounted) onTapOutside();
        },
        containerIds: () => [_scopeId],
        eventType: 'pointerdown',
      );
    }

    final onTapUpOutside = component.onTapUpOutside;
    if (onTapUpOutside != null) {
      _disposeTapUpOutside = registerDocumentOutsidePointerListener(
        () {
          if (_isMounted) onTapUpOutside();
        },
        containerIds: () => [_scopeId],
        eventType: 'pointerup',
      );
    }
  }

  String _obscureTextReseedMessage(TextField old) =>
      'TextField.obscureText changed from ${old.obscureText} to '
      '${component.obscureText}, but it is only read when the field mounts — '
      'the change is ignored. Add CoreInputFeature.passwordToggle() to '
      '`features` for a show/hide control, or give the field a new `key` '
      'to restart from a different seed.';

  @override
  void didUpdateComponent(covariant TextField oldComponent) {
    super.didUpdateComponent(oldComponent);

    // `obscureText` seeds `_obscured` once; the field owns it afterwards
    // (a `passwordToggle` flips it). A caller flipping the prop instead —
    // the Material habit — would be silently ignored, so debug builds say
    // so. Reported rather than asserted: a throw here would replace the
    // whole subtree with an error. With a toggle feature present the field
    // already has its own control and the prop is not the caller's lever.
    assert(() {
      if (component.obscureText != oldComponent.obscureText &&
          !component.features.any(
            (feature) => feature.kind == .passwordToggle,
          )) {
        debugWarn(_obscureTextReseedMessage(oldComponent));
      }
      return true;
    }(), 'debug-only report; never fails');

    // Moving the bounds can flip the verdict on text that never changed,
    // so this runs ahead of the controlled-value guard below.
    if ((component.min != oldComponent.min ||
            component.max != oldComponent.max) &&
        _syncRangeViolation(_lastValue)) {
      setState(() {});
    }

    // The *element* already follows a controlled `value`: jaspr
    // special-cases `value` on an `<input>` and assigns the DOM
    // property rather than the content attribute, so the visible text
    // updates even after the field has been typed into. What did not
    // follow is this component's own cached copy of the text, which is
    // seeded at mount and then only ever written by input, submit and
    // clear. So a parent-driven change (reset-to-blank,
    // server-corrected text, undo) left the field showing the new text
    // while `textEmpty` / `textNotEmpty` affordances still described
    // the old one, and while formatters were still handed the old text
    // as their `oldValue`. The Flutter twin has no such cache — it
    // reads the live controller — which is why only Web drifted.
    //
    // Same guard as Flutter's `didUpdateWidget`, so the two platforms
    // agree on what counts as a parent-driven change: only a controlled
    // field, only on an actual change, and never when the value already
    // matches (the parent echoing back what we just reported).
    final nextValue = component.value;
    if (nextValue == null ||
        nextValue == oldComponent.value ||
        nextValue == _lastValue) {
      return;
    }

    final emptinessChanged = nextValue.isEmpty != _lastValue.isEmpty;
    final rangeChanged = _syncRangeViolation(nextValue);
    _lastValue = nextValue;
    // `textEmpty` / `textNotEmpty` features read `_lastValue`, so a
    // change that crosses the empty boundary has to re-render — and so
    // does one that crosses the min / max boundary.
    if (emptinessChanged || rangeChanged) setState(() {});
    // Last, so a form that answers with a replacement finds the field
    // already showing the parent's text.
    formValue = CoreTextFieldContract.formValueOf(nextValue);
  }

  /// Root attributes minus the semantic ones, which moved to the
  /// `<input>` in [_buildInputAttributes]. Leaving them on both would
  /// announce the control twice.
  Map<String, String> _rootAttributes() => {
    for (final entry in component.componentAttributes.entries)
      if (!isSemanticHtmlAttribute(entry.key)) entry.key: entry.value,
  };

  Map<String, String> _buildInputAttributes(
    BuildContext context, {
    required bool enabled,
    required bool hasError,
    bool forceId = false,
  }) {
    final attrs = {
      // The runtime `_obscured` state (seeded from `obscureText` /
      // `type: password`, toggled by a `CoreInputFeature.passwordToggle`)
      // forces `password`; otherwise the HTML-semantic `type` (absorbed
      // from `Input`) selects the native input type.
      TextField._kTypeAttr: _obscured
          ? TextField._kPasswordInputType
          : component.type.htmlType,
      // Stable id so a clear feature can reset the element value, and a
      // `FormField` can write a replacement back. A plain field has no id
      // at all.
      if (component.features.isNotEmpty || forceId) 'id': _inputId,
      if (hasError) 'aria-invalid': 'true',
    };

    // Controlled `value` stays parent-owned. The uncontrolled seed is read
    // once in initState; subsequent builds must retain the last edited text
    // instead of writing initialValue back into the live input.
    final currentValue = component.value ?? _lastValue;
    attrs[TextField._kValueAttr] = currentValue;

    final currentHintText = component.hintText;
    final currentPlaceholder = component.placeholder;
    // `hintText` wins over `placeholder`; accept both jaspr's `Text`
    // (the legacy `Component.text(...)` factory return type) and
    // CoUI's `Text` (the chain-friendly wrapper exported via
    // `coui_web.dart`). Either is the canonical way to pass plain
    // placeholder copy in examples / docs — see cautions.md
    // § "Text 체인 API".
    final placeholderAttr =
        currentHintText ??
        switch (currentPlaceholder) {
          Text() => currentPlaceholder.text,
          coui_text.Text() => currentPlaceholder.data,
          _ => null,
        };
    if (placeholderAttr != null) {
      attrs[TextField._kPlaceholderAttr] = placeholderAttr;
    }

    // `name` — explicit value, else derived from the first autofill
    // hint. Mirrors the Flutter web engine, which stamps the hint as the
    // DOM input's `name` (password managers weigh `name` heavily — a
    // lone field with only `autocomplete` stays below their detection
    // threshold, splitting behaviour from the Flutter twin).
    final currentName = component.name ?? component.autofillHints?.firstOrNull;
    if (currentName != null) {
      attrs[TextField._kNameAttr] = currentName;
    }

    final currentMaxLength = component.maxLength;
    if (currentMaxLength != null) {
      attrs[TextField._kMaxlengthAttr] = currentMaxLength.toString();
    }

    // HTML-semantic validation attributes (absorbed from `Input`).
    final currentMinLength = component.minLength;
    if (currentMinLength != null) {
      attrs['minlength'] = currentMinLength.toString();
    }

    final currentPattern = component.pattern;
    if (currentPattern != null) {
      attrs['pattern'] = currentPattern;
    }

    final currentMin = component.min;
    if (currentMin != null) {
      attrs['min'] = currentMin.toString();
    }

    final currentMax = component.max;
    if (currentMax != null) {
      attrs['max'] = currentMax.toString();
    }

    final currentTitle = component.title;
    if (currentTitle != null) {
      attrs['title'] = currentTitle;
    }

    if (!enabled) {
      attrs[TextField._kDisabledAttr] = TextField._kEmptyValue;
    }

    if (component.readOnly) {
      attrs[TextField._kReadonlyAttr] = TextField._kEmptyValue;
    }

    if (component.required) {
      attrs[TextField._kRequiredAttr] = TextField._kEmptyValue;
    }

    if (component.autofocus) {
      attrs[TextField._kAutofocusAttr] = TextField._kEmptyValue;
    }

    // An obscured field opts out of every text service the browser would
    // otherwise apply. Left alone these default to *on* for a text input,
    // so the platform that needed an explicit statement was this one —
    // Flutter's equivalents default to off and the two disagreed.
    //
    // `spellcheck` is the one that leaves the machine: the browser may
    // send the value to a remote checker. `autocorrect` and
    // `autocapitalize` feed the on-screen keyboard's dictionary, which is
    // the same leak with a longer memory.
    //
    // Keyed on `_obscured`, so `type: .password` and the reveal toggle
    // both count — a field the user just re-hid stops from that moment.
    //
    // No `coreComponentTheme` read here (chrome flows through
    // `resolveTextField`; behaviour policy is a widget concern, not a
    // Theme `{style, variantStyles}` slot).
    if (_obscured) {
      attrs['spellcheck'] = 'false';
    }

    // Null means "let the platform decide", which on the web is the
    // browser's own default — so a plain field states nothing and only a
    // stated `false`, or the obscured state, emits anything.
    if (_obscured || component.autocorrect == false) {
      attrs['autocorrect'] = 'off';
    }

    final currentTextDirection = component.textDirection;
    if (currentTextDirection != null) {
      attrs['dir'] = currentTextDirection;
    }

    final currentKeyboardType = component.keyboardType;
    if (currentKeyboardType != null) {
      attrs['inputmode'] = currentKeyboardType;
    }

    final currentTextInputAction = component.textInputAction;
    if (currentTextInputAction != null) {
      attrs['enterkeyhint'] = currentTextInputAction;
    }

    // An obscured field capitalizes nothing — that is the keyboard's
    // dictionary again, and it wins over a stated value rather than
    // being written after it.
    final currentTextCapitalization = _obscured
        ? 'none'
        : component.textCapitalization;
    if (currentTextCapitalization != null) {
      attrs['autocapitalize'] = currentTextCapitalization;
    }

    // A password field with no stated hint still needs to be one to the
    // browser. Without this it sees an input it cannot place and may
    // offer the ordinary autofill and text services instead of a
    // password manager — the path this whole section exists to close.
    final currentAutofillHints = component.autofillHints;
    final currentAutocomplete =
        currentAutofillHints != null && currentAutofillHints.isNotEmpty
        ? currentAutofillHints.join(' ')
        : (_obscured ? 'current-password' : null);
    if (currentAutocomplete != null) {
      attrs['autocomplete'] = currentAutocomplete;
    }

    // Semantic attributes describe the *control*, so they belong on the
    // `<input>` a screen reader actually lands on — not on the wrapper the
    // caller happened to hand them to. `Command` passes
    // `aria-autocomplete` this way and it sat inert on the root until now;
    // `Autocomplete` needs `role="combobox"` and `aria-activedescendant`
    // in the same place.
    for (final entry
        in (component.userAttributes ?? const <String, String>{}).entries) {
      if (isSemanticHtmlAttribute(entry.key)) {
        attrs[entry.key] = entry.value;
      }
    }

    return attrs;
  }

  Map<String, EventCallback> _buildInputEvents({required bool inForm}) {
    final currentOnChanged = component.onChanged;
    final currentOnCaretChanged = component.onCaretChanged;
    final currentOnSubmitted = component.onSubmitted;
    final currentOnTap = component.onTap;
    final currentOnEditingComplete = component.onEditingComplete;
    final formatters =
        component.inputFormatters ?? const <CoreInputFormatter>[];
    final hasInputFormatters = formatters.isNotEmpty;
    final submitFormatters = component.submitFormatters;
    // A clear / text-conditional feature must re-evaluate visibility when
    // the text empties or fills.
    final reactiveText = component.features.any(
      (feature) =>
          feature.visibility == .textNotEmpty ||
          feature.visibility == .textEmpty,
    );

    return {
      // Even without a caller callback, retain the uncontrolled text across
      // rebuilds. Form reporting and formatter behavior share this one path.
      'input': EventHandlers.createInputTargetEventHandler((_, target) {
        final value = hasInputFormatters
            ? _runFormatters(formatters, target)
            : target.value;
        final emptinessChanged = value.isEmpty != _lastValue.isEmpty;
        final rangeChanged = _syncRangeViolation(value);
        _lastValue = value;
        // Ahead of `onChanged` so a listener holding both ends up with a
        // caret that belongs to the value it is about to receive.
        // `selectionStart` is null only when the element cannot carry a
        // selection, in which case the end of the text is the caret.
        currentOnCaretChanged?.call(target.selectionStart ?? value.length);
        currentOnChanged?.call(value);
        if ((reactiveText && emptinessChanged) || rangeChanged) {
          setState(() {});
        }
        // Last, after the caller has heard the typed text: a form that
        // answers with a `ReplaceResult` is heard second, so what the
        // caller ends up holding is the replacement. (Flutter's
        // replacement lands a frame later and gets the same order.)
        formValue = CoreTextFieldContract.formValueOf(value);
      }),
      if (currentOnSubmitted != null || submitFormatters.isNotEmpty)
        'keydown': EventHandlers.createKeyboardEventHandler((event) {
          if (event.key != 'Enter') return;
          // IME composition guard — the commit-Enter of a composing IME
          // (Korean etc.) fires keydown too; without the guard
          // onSubmitted double-fires (once mid-composition, once on the
          // real Enter). keyCode 229 is the legacy composing marker.
          if (event.isComposing || event.keyCode == _kComposingKeyCode) {
            return;
          }
          if (event.target case final web.HTMLInputElement target) {
            currentOnSubmitted?.call(target.value);
            if (submitFormatters.isNotEmpty) {
              _lastValue = _runFormatters(submitFormatters, target);
              // A submit formatter rewrites the text without an `input`
              // event, so the form is told here.
              formValue = CoreTextFieldContract.formValueOf(_lastValue);
            }
          }
        }),
      if (currentOnTap != null) 'click': (_) => currentOnTap(),
      if (currentOnEditingComplete != null)
        'change': (_) => currentOnEditingComplete(),
      // Mirror W3C `:focus-visible`: ring on iff focus arrived via
      // keyboard. Forward to the surrounding [FocusOutline]. Also
      // honour `selectAllOnFocus` (widget flag — default sources
      // `CoreTextFieldContract.defaultSelectAllOnFocus`) for
      // cross-platform parity with the Flutter implementation.
      //
      // Typed handler via `EventHandlers.createInputTargetEventHandler`:
      // dart2js release minifies dynamic getter dispatches (e.g.
      // `event.target` → `event.gdE`) into mangled names that
      // compile-graph changes can desync, leaving the ring stuck in its
      // unfocused state in production. Routing the cast through the
      // helper keeps the call site mangling-resilient.
      'focus': EventHandlers.createInputTargetEventHandler((_, target) {
        if (component.selectAllOnFocus) {
          selectInputText(target);
        }
        final isVisible = _focusModality.focus(
          platformShowsRing: target.matches(':focus-visible'),
        );
        setState(() => _focused = isVisible);
      }),
      'blur': (_) {
        _focusModality.blur();
        setState(() => _focused = false);
      },
      'pointerdown': (_) => _focusModality.pointerDown(),
    };
  }

  /// The framed box's own events: the hover a `hovered` feature needs, and
  /// a click anywhere on the box that nothing inside answers for itself —
  /// the inset, a prefix / suffix glyph.
  ///
  /// Flutter wraps the whole row in one tap region, so a press on the inset
  /// focuses the field and fires `onTap` just as one on the text does. The
  /// native `<input>` only owns the pixels it covers, so without this a
  /// press beside it does nothing. A control inside the box (a feature or
  /// slotted button, a link) keeps its own click — [isFieldBoxInertTarget]
  /// says which is which. A disabled field takes no press, as on Flutter.
  Map<String, EventCallback>? _buildBoxEvents({
    required bool enabled,
    required bool hover,
  }) {
    if (!enabled && !hover) return null;
    final onTap = component.onTap;
    return {
      if (hover) ...{
        'mouseenter': (_) => _setHovered(true),
        'mouseleave': (_) => _setHovered(false),
      },
      if (enabled) ...{
        // Without this the press blurs a focused input and the click below
        // puts focus back: the active boundary would flash off in between.
        'mousedown': (Object event) {
          if (isFieldBoxInertTarget(event)) preventDefault(event);
        },
        'click': (Object event) {
          if (!isFieldBoxInertTarget(event)) return;
          // A pointer-caused focus draws no outer ring. A press on an input
          // that already has focus raises no focus event, so the press is
          // discarded afterwards (see `CoreInputFocusModality.blur`).
          _focusModality.pointerDown();
          focusInputOfEventBox(event);
          _focusModality.blur();
          onTap?.call();
        },
      },
    };
  }

  /// Runs [formatters] in order against the element's current value,
  /// feeding [_lastValue] as the previous text, writes the result back
  /// when it changed, and returns the committed text.
  String _runFormatters(
    List<CoreInputFormatter> formatters,
    web.HTMLInputElement target,
  ) {
    var value = target.value;
    for (final formatter in formatters) {
      value = formatter.format(_lastValue, value);
    }
    if (value != target.value) {
      target.value = value;
    }
    return value;
  }

  /// Whether [feature] should render given the current value / focus /
  /// hover state.
  bool _isFeatureVisible(CoreInputFeature feature) {
    return switch (feature.visibility) {
      .always => true,
      .textNotEmpty => _lastValue.isNotEmpty,
      .textEmpty => _lastValue.isEmpty,
      .focused => _focused,
      .hovered => _hovered,
    };
  }

  /// Builds one affordance for [feature] — a `Button.plain` (transparent
  /// muted-icon button that brightens on hover) carrying the resolved
  /// [buttonStyle] (nested `featureButtonStyle` slot, raw-forwarded), its
  /// icon reading [iconStyle] (the resolved leading / trailing icon
  /// chrome). aria-label passes through `Button.attributes`, and
  /// `tabindex="-1"` joins it only when
  /// [CoreTextFieldContract.skipInputFeatureFocusTraversal] asks for it —
  /// dropping the affordance out of the Tab order while leaving it
  /// pointer- and script-focusable (the Flutter side spells the same thing
  /// as `FocusNode.skipTraversal`).
  Component _buildFeatureButton(
    CoreInputFeature feature,
    CoreIconStyle iconStyle,
    CoreButtonStyle buttonStyle,
  ) {
    final label = _featureLabel(feature);
    return Button(
      onPressed: () => _handleFeatureTap(feature),
      variant: .plain,
      buttonStyle: buttonStyle,
      attributes: {
        if (component.skipInputFeatureFocusTraversal) 'tabindex': '-1',
        'aria-label': ?label,
      },
      child: Icon(_featureIcon(feature), iconStyle: iconStyle),
    );
  }

  void _handleFeatureTap(CoreInputFeature feature) {
    switch (feature.kind) {
      case .passwordToggle:
        setState(() => _obscured = !_obscured);
      case .clear:
        _clearField();
    }
  }

  /// Empties the `<input>` element + notifies, then re-renders so a
  /// `textNotEmpty` clear feature hides.
  void _clearField() {
    if (web.document.getElementById(_inputId)
        case final web.HTMLInputElement input) {
      input.value = TextField._kEmptyValue;
    }
    _lastValue = TextField._kEmptyValue;
    component.onChanged?.call(TextField._kEmptyValue);
    setState(() {});
    formValue = CoreTextFieldContract.formValueOf(TextField._kEmptyValue);
  }

  /// A validator answered with a `ReplaceResult`: the field adopts the text.
  ///
  /// Writes the `<input>` element (the browser owns what is on screen),
  /// re-reports so the replacement is validated in its turn, and tells the
  /// caller with `onCaretChanged` / `onChanged`, so a controlled `value`
  /// follows — the same order [_buildInputEvents] gives a typed edit.
  ///
  /// The element is reached by the id a field inside a `FormField` always
  /// carries (see [build]); off the browser (server rendering) there is no
  /// element and nothing to write.
  @override
  void didReplaceFormValue(String value) {
    if (value == _lastValue) return;
    final caret = _writeInputValue(value);
    final emptinessChanged = value.isEmpty != _lastValue.isEmpty;
    final rangeChanged = _syncRangeViolation(value);
    _lastValue = value;
    formValue = CoreTextFieldContract.formValueOf(value);
    component.onCaretChanged?.call(caret);
    component.onChanged?.call(value);
    if (emptinessChanged || rangeChanged) setState(() {});
  }

  /// Writes [value] into the `<input>` element and returns where the
  /// caret ended up — the end of the text when there is no element to ask
  /// (server rendering, or the element is not mounted yet).
  int _writeInputValue(String value) {
    if (kIsWeb) {
      if (web.document.getElementById(_inputId)
          case final web.HTMLInputElement input) {
        input.value = value;

        return input.selectionStart ?? value.length;
      }
    }

    return value.length;
  }

  IconName _featureIcon(CoreInputFeature feature) {
    return switch (feature.kind) {
      .passwordToggle =>
        _obscured
            ? (feature.icon ?? LucideIcons.eyeOff)
            : (feature.iconShown ?? LucideIcons.eye),
      .clear => feature.icon ?? LucideIcons.x,
    };
  }

  String? _featureLabel(CoreInputFeature feature) {
    return switch (feature.kind) {
      .clear => feature.semanticLabel ?? component.clearButtonSemanticLabel,
      .passwordToggle => feature.semanticLabel,
    };
  }

  void _setHovered(bool hovered) {
    if (_hovered != hovered) {
      setState(() => _hovered = hovered);
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _disposeTapOutside?.call();
    _disposeTapUpOutside?.call();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final currentLabel = component.label;
    final currentDescription = component.description;
    final currentError = component.errorText;
    final currentPrefix = component.prefix;
    final currentSuffix = component.suffix;

    // Built-in affordances (clear / password toggle) currently visible,
    // split by side.
    final visibleFeatures = component.features.where(_isFeatureVisible);
    final leadingFeatures = visibleFeatures
        .where((feature) => feature.position == .leading)
        .toList();
    final trailingFeatures = visibleFeatures
        .where(
          (feature) => feature.position == .trailing,
        )
        .toList();

    // The disabled / error constraint an enclosing `FormField` or
    // `Fieldset` publishes to this input — null when the field stands
    // alone, which leaves both values below exactly the widget's own.
    //
    // `enabled` folds with AND: a disabled wrapper (an enclosing
    // `Fieldset(enabled: false)`, a `FormField(enabled: false)`) always
    // wins over this field's own `enabled: true` — HTML `<fieldset
    // disabled>` semantics. `hasError` folds with OR: a
    // `FormField(error: ...)` puts this field's chrome into the error
    // tone even when the field was not separately told an `errorText`.
    // The message itself stays the wrapper's to show; only the tone
    // reaches here.
    final formFieldScope = FormFieldScope.maybeOf(context);
    // Whether a `FormField` is waiting on this input's text. It gates the
    // two things a field takes on only then: the `input` listener that
    // reports typing, and the id that lets a replacement be written back.
    final inForm = FormFieldHandleScope.maybeOf(context) != null;
    final effectiveEnabled =
        component.enabled && formFieldScope?.disabled != true;
    final hasError =
        currentError != null ||
        ValidationStateScope.maybeOf(context) == .invalid ||
        _rangeViolated ||
        (formFieldScope?.hasError ?? false);

    // Single entry point — resolves the nested-merge chain
    // (theme.style → theme.errorStyle → widget.textFieldStyle) plus
    // token fallback in `text_field_style.dart`.
    final resolved = resolveTextField(
      context,
      size: component.size,
      expands: component.expands,
      // Which sides of the row carry a slot — those sides take the inset
      // on the wrapper so the slot sits inside it (Flutter pads the row).
      leadingAffixed: currentPrefix != null || leadingFeatures.isNotEmpty,
      trailingAffixed: currentSuffix != null || trailingFeatures.isNotEmpty,
      // Ambient validation state — a wrapping `Validated` propagates its
      // state so the field's own error variant (border + focus ring)
      // switches to the error tone without a second stacked ring.
      // The browser already marks `<input min max>` `:invalid`, but that
      // pseudo paints nothing here — the error tone is resolved in Dart.
      // Reading the same shared verdict Flutter reads keeps the two
      // sides on one answer instead of two.
      hasError: hasError,
      // Build-time semantic state — the disabled label tone is resolved
      // here (mirrors the Flutter resolver), not via a CSS `:disabled`
      // pseudo (the label has no `.peer` sibling to react to).
      enabled: effectiveEnabled,
      scopeId: _scopeId,
      numeric: component.type == CoreInputType.number,
      variant: component.variant,
      showCursor: component.showCursor,
      scrollPadding: component.scrollPadding,
      textFieldStyle: component.textFieldStyle,
    );

    // The state layer rides the FRAMED BOX — the wrapper that holds the
    // input and its slots — not the root. Scoping it to the root would wash
    // the field on hovering its label, which sits in the same column.
    final fieldBoxId = '$_scopeId-fieldbox';
    final scopedRules = resolveTextFieldRules(
      context,
      scopeId: _scopeId,
      stateLayerId: fieldBoxId,
      hasError: hasError,
      enabled: effectiveEnabled,
      numeric: component.type == CoreInputType.number,
      variant: component.variant,
      textFieldStyle: component.textFieldStyle,
    );

    final inputElement = Component.element(
      tag: TextField._kInput,
      classes: resolved.input.className,
      styles: resolved.input.inlineStyles,
      attributes: _buildInputAttributes(
        context,
        enabled: effectiveEnabled,
        hasError: hasError,
        forceId: inForm,
      ),
      events: _buildInputEvents(inForm: inForm),
    );

    // Build the framed body — the box holding the input and its slots — and
    // wrap it in FocusOutline so the keyboard focus ring is rendered
    // uniformly with every other Co component. The box is always this
    // wrapper, never the `<input>`: a replaced element draws no `::after`,
    // so a material that lights its own edge there (a surface style's
    // sheen) would have nowhere to paint, and the Flutter twin's box is a
    // container around an editor in the same way.
    final needsHover = component.features.any(
      (feature) => feature.visibility == .hovered,
    );
    final framedBody = div(
      [
        if (currentPrefix != null)
          span(
            [currentPrefix],
            classes: resolved.leadingSlot.className,
            styles: resolved.leadingSlot.inlineStyles,
          ),
        for (final feature in leadingFeatures)
          _buildFeatureButton(
            feature,
            resolved.leadingIconStyle,
            resolved.featureButtonStyle,
          ),
        inputElement,
        for (final feature in trailingFeatures)
          _buildFeatureButton(
            feature,
            resolved.trailingIconStyle,
            resolved.featureButtonStyle,
          ),
        if (currentSuffix != null)
          span(
            [currentSuffix],
            classes: resolved.trailingSlot.className,
            styles: resolved.trailingSlot.inlineStyles,
          ),
      ],
      id: scopedRules.css.isNotEmpty ? fieldBoxId : null,
      classes: resolved.affixWrapper.className,
      styles: resolved.affixWrapper.inlineStyles,
      events: _buildBoxEvents(
        enabled: effectiveEnabled,
        hover: needsHover,
      ),
    );

    // Forward the resolved focus-outline slot straight to FocusOutline
    // (paint-ready ring colour / width / offset / border radius).
    final ringedBody = FocusOutline(
      focused: _focused,
      focusOutlineStyle: resolved.focusOutlineStyle,
      child: framedBody,
    );

    return div(
      [
        // `<style>` is `display: none`, so it never joins the column.
        if (resolved.input.className.split(' ').contains('co-text-field-hint'))
          const Component.element(
            tag: 'style',
            children: [RawText(_kHintTypographyCss)],
          ),
        if (scopedRules.css.isNotEmpty)
          Component.element(
            tag: 'style',
            children: [RawText(scopedRules.css)],
          ),
        // The `<label>`, the required `*`, and the gap between them are
        // FormLabel's to draw — this field only says what its own label
        // TEXT looks like (typography, on the inner span) and where the
        // label sits relative to the input (`labelHost`). Hand-rolling
        // the marker here is what let the two platforms drift: Flutter
        // has always composed FormLabel, so its `*` took FormLabel's
        // own type size and carried `ExcludeSemantics`, while this
        // element inherited the field's size and announced "asterisk"
        // after every required label.
        if (currentLabel != null)
          FormLabel(
            label: coui_text.Text(
              currentLabel,
              maxLines: component.labelMaxLines,
              overflow: component.labelOverflow,
            ),
            isRequired: component.required,
            size: component.size,
            enabled: effectiveEnabled,
            formLabelStyle: resolved.formLabelStyle,
            classes: resolved.labelHost.className,
            css: resolved.labelHost.inlineStyles,
          ),
        ringedBody,
        if (currentDescription != null && currentError == null)
          p(
            [coui_text.Text(currentDescription)],
            classes: resolved.description.className,
            styles: resolved.description.inlineStyles,
          ),
        if (currentError != null)
          p(
            [coui_text.Text(currentError)],
            classes: resolved.error.className,
            styles: resolved.error.inlineStyles,
          ),
      ],
      id: _needsScope ? _scopeId : component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: _rootAttributes(),
      events: component.events,
    );
  }
}

/// Legacy `keyCode` browsers report for every keydown during an IME
/// composition session (the "Process" key) — the pre-`isComposing`
/// composing marker.
const int _kComposingKeyCode = 229;

/// Chain sugar mirroring the Flutter `TextField.withStyle` extension —
/// merges a [CoreTextFieldStyle] patch into [TextField.textFieldStyle]
/// via the existing [TextField.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTextFieldStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreTextFieldStyle.borderRadius] and `.primary` sets
/// [CoreTextFieldStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// TextField(placeholder: Text('Enter text...')).radius4.surface
/// ```
extension TextFieldStyleChain on TextField {
  /// Returns a copy of this [TextField] with [patch] merged into
  /// [textFieldStyle] (patch fields win on conflict).
  TextField withStyle(CoreTextFieldStyle patch) => copyWith(
    textFieldStyle: (textFieldStyle ?? const CoreTextFieldStyle()).merge(
      patch,
    ),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  TextField get radius0 => withStyle(
    const CoreTextFieldStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  TextField get radius2 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  TextField get radius4 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  TextField get radius6 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  TextField get radius8 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  TextField get radius10 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  TextField get radius12 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  TextField get radius14 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  TextField get radius16 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  TextField get radius20 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  TextField get radius24 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  TextField get radius28 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  TextField get radius32 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  TextField get radius36 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  TextField get radius40 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  TextField get radius48 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  TextField get radius56 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  TextField get radius64 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  TextField get radius9999 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  TextField get primary => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  TextField get secondary => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  TextField get tertiary => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  TextField get surface => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  TextField get surfaceContainer => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  TextField get error => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  TextField get success => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  TextField get warning => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  TextField get info => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  TextField get outline => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  TextField get transparent => withStyle(
    const CoreTextFieldStyle(backgroundColor: .transparent),
  );
}
