import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/form/formatted_input/formatted_input_style.dart';
import 'package:jaspr/dom.dart' show RawText, Styles;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Per-instance id counter — yields a stable, SSR/hydration-consistent
/// element id for the single real `<input>` a [FormattedInput] renders.
int _formattedInputIdCounter = 0;

/// HTML `autocomplete` default for [FormattedInput.phone] /
/// [FormattedInput.koreanPhone] — mirrors
/// `CoreFormattedInputMasks.phoneAutofillHint` /
/// `koreanPhoneAutofillHint` (`.telephoneNumber`). `autofillHints` is the
/// same raw-token vocabulary `TextField.autofillHints` already uses on
/// Web (HTML `autocomplete` tokens, not Flutter's `AutofillHints.*`
/// names), so the phone-shaped presets default to `autocomplete="tel"`.
const _kTelephoneAutofillHints = ['tel'];

/// HTML `autocomplete` default for [FormattedInput.creditCard] — mirrors
/// `CoreFormattedInputMasks.creditCardAutofillHint` (`.creditCardNumber`).
const _kCreditCardAutofillHints = ['cc-number'];

/// Matches the digit-only pattern every built-in [CoreFormattedInputMasks]
/// preset uses for its editable slots — the single-field `<input>` opts
/// into `inputmode="numeric"` (a mobile numeric keypad) only when *every*
/// editable part shares this exact pattern, so a custom, non-digit
/// `parts` mask (e.g. the `[A-Z]` slot in the mask engine's own tests)
/// correctly falls back to the browser's default text keyboard.
const _kDigitPattern = r'\d';

/// Container CSS scope, separate from the real input's identity above.
int _formattedInputScopeCounter = 0;

/// Unified cross-platform formatted / masked input for CoUI Web.
///
/// **Architecture (Story #3869 — single real `<input>`)**: one real
/// `<input>` renders the entire masked value and is the sole owner of
/// keyboard focus / caret / browser autofill — there is no per-segment
/// `<input>` and no auto-advance-on-fill focus jump between segments.
/// Every keystroke's native `input` event is fed through
/// [CoreFormattedInputMaskEngine.apply] (the platform-neutral AsYouType
/// engine from Story #3867), which reformats the value and reports where
/// the caret belongs; the handler here is a thin adapter that writes the
/// reformatted text and restores `selectionStart` / `selectionEnd` on the
/// real DOM node. This mirrors why `InputOtp` moved to a single backing
/// `<input>` (`packages/coui_web/.../input_otp/input_otp.dart`) — juggling
/// focus across N separate `<input>`s breaks keyboard continuity and
/// autofill — except `FormattedInput`'s single input stays **visible**
/// (unlike OTP's hidden buffer + decorative overlay) because the whole
/// point is a real, on-screen field a password manager / autofill
/// extension can recognise and fill (see DDR-01 in
/// `.claude/docs/formatted-input-mask/design-decisions.md`).
///
/// `FormattedInput` renders a formatted input — a mix of static
/// separators and editable slots rendered as one continuous string — for
/// structured data entry such as phone numbers, credit cards, and dates.
/// The structure is defined by the [parts] list of [CoreFormattedInputPart]s.
/// The factory constructors [FormattedInput.phone],
/// [FormattedInput.koreanPhone], [FormattedInput.creditCard] and
/// [FormattedInput.date] provide common masks.
///
/// Behaviour / semantic fields (`parts`, `value`, `enabled`, `onChanged`,
/// `autofillHints`) and composition slots (`leading`, `trailing`) stay
/// flat on the widget. All chrome / dimensional overrides flow through
/// the single [formattedInputStyle], whose `segmentInputStyle` nested slot
/// is forwarded to the one real `<input>` (per DDR-06 / DDR-07 the mask's
/// static separators are characters inside that field's own text, so they
/// carry its typography rather than a separator style of their own).
///
/// Example:
/// ```dart
/// FormattedInput.phone(
///   onChanged: (value) => print(value),
/// )
/// ```
class FormattedInput extends UiStatefulComponent
    implements
        CoreFormattedInputContract<CoreValueChanged<String>?, Component> {
  /// Creates a [FormattedInput] from an explicit [parts] mask.
  const FormattedInput({
    required this.parts,
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
    this.value,
    this.enabled = true,
    this.onChanged,
    this.leading,
    this.trailing,
    this.formattedInputStyle,
    this.autofillHints,
  });

  /// Creates a phone number formatted input: `(___) ___-____`.
  const FormattedInput.phone({
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
    this.value,
    this.enabled = true,
    this.onChanged,
    this.leading,
    this.trailing,
    this.formattedInputStyle,
    this.autofillHints = _kTelephoneAutofillHints,
  }) : parts = CoreFormattedInputMasks.phone;

  /// Creates a Korean mobile phone formatted input: `___-____-____`
  /// (3-4-4, 11 digits — e.g. `010-1234-5678`). See DDR-03.
  const FormattedInput.koreanPhone({
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
    this.value,
    this.enabled = true,
    this.onChanged,
    this.leading,
    this.trailing,
    this.formattedInputStyle,
    this.autofillHints = _kTelephoneAutofillHints,
  }) : parts = CoreFormattedInputMasks.koreanPhone;

  /// Creates a credit card formatted input: `____ ____ ____ ____`.
  const FormattedInput.creditCard({
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
    this.value,
    this.enabled = true,
    this.onChanged,
    this.leading,
    this.trailing,
    this.formattedInputStyle,
    this.autofillHints = _kCreditCardAutofillHints,
  }) : parts = CoreFormattedInputMasks.creditCard;

  /// Creates a date formatted input: `__/__/____`.
  const FormattedInput.date({
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
    this.value,
    this.enabled = true,
    this.onChanged,
    this.leading,
    this.trailing,
    this.formattedInputStyle,
    this.autofillHints,
  }) : parts = CoreFormattedInputMasks.date;

  @override
  final List<CoreFormattedInputPart> parts;

  @override
  final String? value;

  @override
  final bool enabled;

  @override
  final CoreValueChanged<String>? onChanged;

  @override
  final Component? leading;

  @override
  final Component? trailing;

  /// HTML `autocomplete` attribute value(s) for the single real `<input>`
  /// — same name / type as `TextField.autofillHints` (raw autocomplete
  /// tokens, e.g. `['tel']`), per DDR-04. `null` / empty emits no
  /// `autocomplete` attribute at all.
  final Iterable<String>? autofillHints;

  // === Style (chrome / dimensional) ===

  @override
  final CoreFormattedInputStyle? formattedInputStyle;

  /// Returns a copy of this [FormattedInput] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  FormattedInput copyWith({
    Map<String, String>? attributes,
    UiMouseEventHandler? onClick,
    CoreValueChanged<String>? onChanged,
    List<CoreFormattedInputPart>? parts,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    String? value,
    bool? enabled,
    Component? leading,
    Component? trailing,
    CoreFormattedInputStyle? formattedInputStyle,
    Iterable<String>? autofillHints,
  }) {
    return FormattedInput(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      parts: parts ?? this.parts,
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
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      formattedInputStyle: formattedInputStyle ?? this.formattedInputStyle,
      autofillHints: autofillHints ?? this.autofillHints,
    );
  }

  @override
  State<FormattedInput> createState() => _FormattedInputState();
}

/// Chain sugar mirroring the Flutter `FormattedInput.withStyle` extension —
/// merges a [CoreFormattedInputStyle] patch into
/// [FormattedInput.formattedInputStyle] via the existing
/// [FormattedInput.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFormattedInputStyle.merge` right-side-wins semantics).
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
/// sets [CoreFormattedInputStyle.borderRadius] and `.primary` sets
/// [CoreFormattedInputStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// FormattedInput.phone().radius4.surface
/// ```
extension FormattedInputStyleChain on FormattedInput {
  /// Sets the background paint and preserves the other style fields.
  FormattedInput backgroundColor(CoreColor value) =>
      withStyle(CoreFormattedInputStyle(backgroundColor: value));

  /// Returns a copy of this [FormattedInput] with [patch] merged into
  /// [formattedInputStyle] (patch fields win on conflict).
  FormattedInput withStyle(CoreFormattedInputStyle patch) => copyWith(
    formattedInputStyle:
        (formattedInputStyle ?? const CoreFormattedInputStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  FormattedInput get radius0 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  FormattedInput get radius2 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  FormattedInput get radius4 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  FormattedInput get radius6 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  FormattedInput get radius8 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  FormattedInput get radius10 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  FormattedInput get radius12 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  FormattedInput get radius14 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  FormattedInput get radius16 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  FormattedInput get radius20 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  FormattedInput get radius24 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  FormattedInput get radius28 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  FormattedInput get radius32 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  FormattedInput get radius36 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  FormattedInput get radius40 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  FormattedInput get radius48 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  FormattedInput get radius56 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  FormattedInput get radius64 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  FormattedInput get radius9999 => withStyle(
    const CoreFormattedInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  FormattedInput get primary => withStyle(
    const CoreFormattedInputStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  FormattedInput get secondary => withStyle(
    const CoreFormattedInputStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  FormattedInput get tertiary => withStyle(
    const CoreFormattedInputStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  FormattedInput get surface => withStyle(
    const CoreFormattedInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  FormattedInput get surfaceContainer => withStyle(
    const CoreFormattedInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  FormattedInput get error => withStyle(
    const CoreFormattedInputStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  FormattedInput get success => withStyle(
    const CoreFormattedInputStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  FormattedInput get warning => withStyle(
    const CoreFormattedInputStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  FormattedInput get info => withStyle(
    const CoreFormattedInputStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  FormattedInput get outline => withStyle(
    const CoreFormattedInputStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  FormattedInput get transparent => withStyle(
    const CoreFormattedInputStyle(backgroundColor: .transparent),
  );
}

class _FormattedInputState extends State<FormattedInput> {
  late final String _scopeId;

  /// Stable element id for the single real `<input>` — SSR/hydration
  /// consistent.
  late final String _inputId =
      'coui-formatted-input-${_formattedInputIdCounter++}';

  /// The (never-reassigned) seed for the `<input>`'s `value` attribute,
  /// computed once in [initState]. Reasserting `value` from Dart state on
  /// every rebuild would fight the DOM's own live value — some browsers
  /// reset the caret on a `value`-attribute patch even when the new value
  /// is unchanged (mirrors `InputOtp._domInitialValue`). Later external
  /// updates (see [didUpdateComponent]) write to the real DOM node
  /// imperatively via [setInputValue] instead of through this field.
  String? _domInitialValue;

  /// The formatted text as of the most recent edit — [_lastText] /
  /// [_lastCursor] together are `oldValue` for the next
  /// [CoreFormattedInputMaskEngine.apply] call, i.e. "what the field
  /// looked like right before this keystroke".
  late String _lastText;

  /// The caret offset as of the most recent edit *or* selection-affecting
  /// event (`keydown` / `click` / `focus`) — refreshed independently of
  /// [_lastText] so a literal-boundary Backspace is correct even when the
  /// caret was moved by a click rather than by typing (DDR-05: "regardless
  /// of cursor position").
  late int _lastCursor;

  /// Whether the `<input>` currently has keyboard focus — drives the
  /// container's focus-ring border colour swap (`resolveFormattedInput`'s
  /// `focused` argument).
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _scopeId =
        'co-formatted-input-${kIsWeb ? 'web' : 'ssr'}-'
        '${_formattedInputScopeCounter++}';
    final formatted = CoreFormattedInputMaskEngine.format(
      component.parts,
      component.value ?? '',
    );
    _lastText = formatted;
    _lastCursor = formatted.length;
    _domInitialValue = formatted.isEmpty ? null : formatted;
  }

  /// Thin adapter over [CoreFormattedInputMaskEngine.apply] — the whole
  /// point of the single-input architecture (DDR-01). Feeds the tracked
  /// pre-edit `oldValue` and the browser-reported post-edit `newValue`
  /// into the platform-neutral engine, writes the reformatted text back
  /// onto the real `<input>`, and restores the caret to
  /// `result.cursorOffset` (DDR-05) — the browser has no notion of "insert
  /// this literal and keep typing past it", so every keystroke round-trips
  /// through this handler.
  void _handleInput(web.Event event, web.HTMLInputElement target) {
    final result = CoreFormattedInputMaskEngine.apply(
      parts: component.parts,
      oldValue: CoreFormattedInputEditValue(
        text: _lastText,
        selectionStart: _lastCursor,
        selectionEnd: _lastCursor,
      ),
      newValue: CoreFormattedInputEditValue(
        text: target.value,
        selectionStart: target.selectionStart ?? target.value.length,
        selectionEnd: target.selectionEnd ?? target.value.length,
      ),
    );
    if (target.value != result.text) target.value = result.text;
    try {
      target.setSelectionRange(result.cursorOffset, result.cursorOffset);
    } on Object {
      // setSelectionRange may not be supported on every input type /
      // browser — the reformatted text is already written either way.
    }
    _lastText = result.text;
    _lastCursor = result.cursorOffset;
    component.onChanged?.call(result.rawValue);
  }

  /// Refreshes [_lastCursor] from the field's current selection without
  /// touching [_lastText] — attached to `keydown` (fires before the key's
  /// edit is applied, capturing the true pre-edit caret) and `click`
  /// (a reposition with no accompanying `input` event) so a Backspace
  /// right after a click still resolves against the caret the user
  /// actually placed, not a stale one left over from the last keystroke.
  void _trackSelection(web.Event event, web.HTMLInputElement target) {
    _lastCursor = target.selectionStart ?? target.value.length;
  }

  void _handleFocus(web.Event event, web.HTMLInputElement target) {
    _trackSelection(event, target);
    setState(() => _focused = true);
  }

  Map<String, EventCallback> _buildFieldEvents() {
    return {
      'input': EventHandlers.createInputTargetEventHandler(_handleInput),
      'keydown': EventHandlers.createInputTargetEventHandler(
        _trackSelection,
      ),
      'click': EventHandlers.createInputTargetEventHandler(_trackSelection),
      'focus': EventHandlers.createInputTargetEventHandler(_handleFocus),
      'blur': (_) => setState(() => _focused = false),
    };
  }

  @override
  void didUpdateComponent(covariant FormattedInput oldComponent) {
    super.didUpdateComponent(oldComponent);
    // An externally-driven `value` change (not an echo of our own
    // `onChanged` report — the parent forwarding back exactly what we
    // reported leaves `oldComponent.value == component.value`) reformats
    // and writes the real DOM node imperatively, mirroring
    // `InputOtp.setInputValue` rather than re-touching the `value`
    // attribute (see [_domInitialValue]).
    if (oldComponent.value != component.value ||
        oldComponent.parts.length != component.parts.length) {
      final formatted = CoreFormattedInputMaskEngine.format(
        component.parts,
        component.value ?? '',
      );
      _lastText = formatted;
      _lastCursor = formatted.length;
      setInputValue(_inputId, formatted);
    }
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveFormattedInput(
      context,
      enabled: component.enabled,
      focused: _focused,
      formattedInputStyle: component.formattedInputStyle,
    );

    // Scope id for the container's hover scoped rule — the caller's own id
    // wins, else a generated one stable across rebuilds via the State's
    // identity.
    final scopeId = component.id ?? _scopeId;
    final rules = resolveFormattedInputRules(
      context,
      scopeId: scopeId,
      inputId: _inputId,
      enabled: component.enabled,
      focused: _focused,
      formattedInputStyle: component.formattedInputStyle,
    );

    final placeholder = _buildPlaceholder(component.parts);
    final autofillHints = component.autofillHints;
    final autocomplete = autofillHints != null && autofillHints.isNotEmpty
        ? autofillHints.join(' ')
        : null;

    final field = Component.element(
      tag: 'input',
      id: _inputId,
      classes: resolved.field.className,
      styles: resolved.field.inlineStyles,
      attributes: {
        'type': 'text',
        'value': ?_domInitialValue,
        if (placeholder.isNotEmpty) ...{
          'placeholder': placeholder,
          'maxlength': '${placeholder.length}',
        },
        if (_isDigitOnlyMask(component.parts)) 'inputmode': 'numeric',
        'autocomplete': ?autocomplete,
        if (!component.enabled) 'disabled': '',
      },
      events: component.enabled ? _buildFieldEvents() : const {},
    );

    final children = [
      // `<style>` is `display: none`, so it creates no flex item and never
      // affects the row.
      if (rules.css.isNotEmpty)
        Component.element(tag: 'style', children: [RawText(rules.css)]),
      ?component.leading,
      field,
      ?component.trailing,
    ];

    return Component.element(
      tag: 'div',
      // The generated scope id is stamped only when a rule actually
      // targets it, so the default path's markup is unchanged.
      id: rules.css.isEmpty ? component.id : scopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
      children: children,
    );
  }
}

/// Builds the full-mask placeholder text shown when the `<input>` is
/// empty — literals render as themselves and every editable slot repeats
/// its [CoreFormattedInputPart.placeholder] character
/// [CoreFormattedInputPart.length] times (e.g. `(___) ___-____` for
/// [CoreFormattedInputMasks.phone]), the
/// single-field equivalent of the old per-segment `hintText`.
String _buildPlaceholder(List<CoreFormattedInputPart> parts) {
  final buffer = StringBuffer();
  for (final part in parts) {
    if (part.editable) {
      buffer.write(part.placeholder * part.length);
    } else {
      buffer.write(part.text ?? '');
    }
  }
  return buffer.toString();
}

/// Whether every editable slot in [parts] shares the digit-only pattern
/// every built-in preset uses — the single [_kDigitPattern] check, not a
/// fuzzy "looks numeric" heuristic, so a custom mask with any other (or
/// no) pattern falls back to the browser's default text keyboard rather
/// than guessing.
bool _isDigitOnlyMask(List<CoreFormattedInputPart> parts) {
  final editableParts = parts.where((part) => part.editable);
  if (editableParts.isEmpty) return false;
  return editableParts.every((part) => part.pattern == _kDigitPattern);
}
