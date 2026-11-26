import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';

/// Unified cross-platform formatted / masked input.
///
/// `FormattedInput` renders a single continuous [TextField] that displays
/// and edits the whole masked value at once (DDR-01) — a mix of static
/// separators and editable digits defined by the [parts] list of
/// [CoreFormattedInputPart]s. A [TextInputFormatter] wraps Story #3867's
/// platform-neutral `CoreFormattedInputMaskEngine`, so literals are
/// auto-inserted as the user types, Backspace deletes the nearest digit
/// regardless of where the caret sits relative to a literal (DDR-05), and
/// paste / arbitrary-position edits reformat the whole value in one step.
/// The factory constructors [FormattedInput.phone],
/// [FormattedInput.koreanPhone], [FormattedInput.creditCard] and
/// [FormattedInput.date] provide common masks.
///
/// Per Epic #1302 원칙 6/7, behaviour / semantic fields (`parts`,
/// `value`, `enabled`, `onChanged`) and composition slots (`leading`,
/// `trailing`) stay flat on the widget. All chrome / dimensional
/// overrides flow through the single [formattedInputStyle].
///
/// Example:
/// ```dart
/// FormattedInput.phone(
///   onChanged: (value) => print(value),
/// )
/// ```
///
/// surface:content — draws its own box (composes `OutlinedContainer`
/// rather than being drawn inside a parent panel), on the page rather
/// than floating over it.
class FormattedInput extends StatefulWidget
    implements CoreFormattedInputContract<ValueChanged<String>?, Widget> {
  /// Creates a [FormattedInput] from an explicit [parts] mask.
  const FormattedInput({
    required this.parts,
    super.key,
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
    super.key,
    this.value,
    this.enabled = true,
    this.onChanged,
    this.leading,
    this.trailing,
    this.formattedInputStyle,
    this.autofillHints = const [AutofillHints.telephoneNumber],
  }) : parts = CoreFormattedInputMasks.phone;

  /// Creates a Korean mobile phone formatted input: `___-____-____`
  /// (3-4-4, 11 digits — e.g. `010-1234-5678`).
  const FormattedInput.koreanPhone({
    super.key,
    this.value,
    this.enabled = true,
    this.onChanged,
    this.leading,
    this.trailing,
    this.formattedInputStyle,
    this.autofillHints = const [AutofillHints.telephoneNumber],
  }) : parts = CoreFormattedInputMasks.koreanPhone;

  /// Creates a credit card formatted input: `____ ____ ____ ____`.
  const FormattedInput.creditCard({
    super.key,
    this.value,
    this.enabled = true,
    this.onChanged,
    this.leading,
    this.trailing,
    this.formattedInputStyle,
    this.autofillHints = const [AutofillHints.creditCardNumber],
  }) : parts = CoreFormattedInputMasks.creditCard;

  /// Creates a date formatted input: `__/__/____`.
  const FormattedInput.date({
    super.key,
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
  final ValueChanged<String>? onChanged;

  @override
  final Widget? leading;

  @override
  final Widget? trailing;

  // === Style (chrome / dimensional) ===

  @override
  final CoreFormattedInputStyle? formattedInputStyle;

  /// Autofill hints forwarded to the single composed [TextField] — the
  /// same name/type `TextField` already exposes (DDR-04), so OS/browser
  /// autofill and password-manager extensions recognise this field the
  /// same way they would a plain `TextField`. [FormattedInput.phone] and
  /// [FormattedInput.koreanPhone] default to
  /// `[AutofillHints.telephoneNumber]` and [FormattedInput.creditCard]
  /// defaults to `[AutofillHints.creditCardNumber]`; pass an explicit
  /// value to override.
  final Iterable<String>? autofillHints;

  /// Returns a copy of this [FormattedInput] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  FormattedInput copyWith({
    Key? key,
    ValueChanged<String>? onChanged,
    List<CoreFormattedInputPart>? parts,
    String? value,
    bool? enabled,
    Widget? leading,
    Widget? trailing,
    CoreFormattedInputStyle? formattedInputStyle,
    Iterable<String>? autofillHints,
  }) {
    return FormattedInput(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      parts: parts ?? this.parts,
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

class _FormattedInputState extends State<FormattedInput> {
  static int _editableCapacity(List<CoreFormattedInputPart> parts) {
    var total = 0;
    for (final part in parts) {
      if (part.editable) total += part.length;
    }
    return total;
  }

  /// The full mask pattern (e.g. `(___) ___-____`) shown as a placeholder
  /// when the field is empty — literals rendered as-is, editable slots
  /// filled with their own [CoreFormattedInputPart.placeholder] character,
  /// matching the always-visible mask shape the previous per-segment
  /// rendering showed.
  static String _placeholderPattern(List<CoreFormattedInputPart> parts) {
    final buffer = StringBuffer();
    for (final part in parts) {
      buffer.write(
        part.editable ? part.placeholder * part.length : (part.text ?? ''),
      );
    }
    return buffer.toString();
  }

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;
  bool _hovered = false;

  /// Concatenated content of all editable segments (no literals) — the
  /// raw value this widget last reported through [FormattedInput.onChanged]
  /// / seeded [FormattedInput.value] with. Tracked locally so a mask-only
  /// [didUpdateWidget] rebuild (e.g. a sibling state change round-tripping
  /// the very value just typed) can reformat without disturbing an
  /// in-progress edit.
  late String _rawValue;

  @override
  void initState() {
    super.initState();
    _rawValue = widget.value ?? '';
    _controller = TextEditingController(
      text: CoreFormattedInputMaskEngine.format(widget.parts, _rawValue),
    );
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  void _handleHoverEnter(PointerEnterEvent _) {
    if (!_hovered) setState(() => _hovered = true);
  }

  void _handleHoverExit(PointerExitEvent _) {
    if (_hovered) setState(() => _hovered = false);
  }

  void _handleFocusChanged() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  /// Invoked by [_FormattedInputMaskFormatter] with the mask engine's
  /// concatenated raw (literal-free) value after every genuine platform
  /// edit — forwarded to [FormattedInput.onChanged] unchanged.
  void _handleRawValueChanged(String rawValue) {
    _rawValue = rawValue;
    widget.onChanged?.call(rawValue);
  }

  @override
  void didUpdateWidget(covariant FormattedInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A structurally different mask (segment count changed) reformats the
    // still-current raw value under the new template, dropping whatever no
    // longer fits.
    if (oldWidget.parts.length != widget.parts.length) {
      final capacity = _editableCapacity(widget.parts);
      if (_rawValue.length > capacity) {
        _rawValue = _rawValue.substring(0, capacity);
      }
      _controller.text = CoreFormattedInputMaskEngine.format(
        widget.parts,
        _rawValue,
      );
      return;
    }

    // Controlled `value`: the parent owns the raw digits, so push external
    // changes into the controller (mirroring `TextField`'s own controlled-
    // value handling) — mirroring the just-typed value back through
    // `value:` is a no-op here, so an active edit's caret is undisturbed.
    final nextValue = widget.value;
    if (nextValue != null &&
        nextValue != oldWidget.value &&
        nextValue != _rawValue) {
      _rawValue = nextValue;
      _controller.text = CoreFormattedInputMaskEngine.format(
        widget.parts,
        nextValue,
      );
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveFormattedInput(
      context,
      formattedInputStyle: widget.formattedInputStyle,
    );

    final placeholder = _placeholderPattern(widget.parts);

    // Part of this composite: walled off from the enclosing
    // `FormField`, which is shown the composite's own value.
    final field = Data<FormFieldHandle>.boundary(
      child: TextField(
        enabled: widget.enabled,
        variant: resolved.segmentInputVariant,
        size: resolved.segmentInputSize,
        textFieldStyle: widget.enabled
            ? resolved.segmentInputStyle
            : resolved.disabledSegmentInputStyle,
        hintText: placeholder.isEmpty ? null : placeholder,
        controller: _controller,
        focusNode: _focusNode,
        inputFormatters: [
          _FormattedInputMaskFormatter(
            parts: widget.parts,
            onRawValueChanged: _handleRawValueChanged,
          ),
        ],
        autofillHints: widget.autofillHints,
      ),
    );

    final leading = widget.leading;
    final trailing = widget.trailing;

    // The single visual boundary is a composed `OutlinedContainer` —
    // it owns the fill / border / radius / padding, geometry
    // conversion, and the `surface:content` material reach a preset
    // can now apply. `role` is left at its own default (`.content`).
    // Disabled outranks focus: a field that cannot be edited should not
    // claim the focus ring, and the two can coexist (a field disabled while
    // it held focus).
    //
    // `disabled > focus > hover > rest` — the pointer steps the border only
    // on an enabled container that does not hold focus.
    return MouseRegion(
      onEnter: _handleHoverEnter,
      onExit: _handleHoverExit,
      child: OutlinedContainer(
        containerStyle: switch ((widget.enabled, _focused)) {
          (false, _) => resolved.disabledContainerStyle,
          (true, true) => resolved.focusedContainerStyle,
          (true, false) =>
            _hovered
                ? resolved.hoveredContainerStyle
                : resolved.unfocusedContainerStyle,
        },
        child: Row(
          spacing: resolved.contentSpacing,
          children: [
            ?leading,
            Expanded(child: field),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Thin [TextInputFormatter] adapter wrapping
/// [CoreFormattedInputMaskEngine.apply] — all masking logic (literal
/// auto-insertion, DDR-05 backspace-through-literal behaviour, paste,
/// mid-string insertion/deletion, range deletion) lives in the
/// platform-neutral engine. This class only translates between Flutter's
/// [TextEditingValue] and the engine's [CoreFormattedInputEditValue] /
/// [CoreFormattedInputEditResult] shapes, and reports the concatenated raw
/// (literal-free) value back to [_FormattedInputState] via
/// [onRawValueChanged].
class _FormattedInputMaskFormatter extends TextInputFormatter {
  const _FormattedInputMaskFormatter({
    required this.parts,
    required this.onRawValueChanged,
  });

  /// The mask segments driving [CoreFormattedInputMaskEngine.apply].
  final List<CoreFormattedInputPart> parts;

  /// Called with the mask engine's concatenated raw value after every edit.
  final ValueChanged<String> onRawValueChanged;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final result = CoreFormattedInputMaskEngine.apply(
      parts: parts,
      oldValue: _toEditValue(oldValue),
      newValue: _toEditValue(newValue),
    );
    onRawValueChanged(result.rawValue);
    return TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.cursorOffset),
    );
  }

  static CoreFormattedInputEditValue _toEditValue(TextEditingValue value) {
    final length = value.text.length;
    final start = value.selection.start < 0 ? length : value.selection.start;
    final end = value.selection.end < 0 ? length : value.selection.end;
    return CoreFormattedInputEditValue(
      text: value.text,
      selectionStart: start,
      selectionEnd: end,
    );
  }
}

/// Chain sugar for merging a [CoreFormattedInputStyle] patch into
/// [FormattedInput.formattedInputStyle] without hand-reconstructing every
/// field. Mirrors the Web `FormattedInput.withStyle` extension so both
/// platforms read identically. Composition slots (`leading` / `trailing`)
/// keep being passed directly — this extension only covers the
/// [CoreFormattedInputStyle] chrome slot.
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
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
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
