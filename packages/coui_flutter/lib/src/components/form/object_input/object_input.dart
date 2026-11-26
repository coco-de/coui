import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show PointerEnterEvent, PointerExitEvent;

/// Unified cross-platform key-value object input.
///
/// `ObjectInput` renders a row of structured key-value fields
/// separated by an optional [separator], emitting a `Map<String,
/// String>` of field key → value. It is the structured-data sibling of
/// `FormattedInput` (which masks a single string).
///
/// Per Epic #1302 원칙 6/7, behaviour / semantic fields (`fields`,
/// `values`, `separator`, `enabled`, `onChanged`) and composition slots
/// (`leading`, `trailing`) stay flat on the widget. All chrome /
/// dimensional overrides flow through the single [objectInputStyle].
///
/// Example:
/// ```dart
/// ObjectInput(
///   fields: const [
///     CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4),
///     CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2),
///     CoreObjectInputField(key: 'day', placeholder: 'DD', maxLength: 2),
///   ],
///   separator: '/',
///   onChanged: (values) => print(values),
/// )
/// ```
///
/// surface:content — draws its own box (composes `OutlinedContainer`
/// rather than being drawn inside a parent panel), on the page rather
/// than floating over it.
class ObjectInput extends StatefulWidget
    implements
        CoreObjectInputContract<ValueChanged<Map<String, String>>?, Widget> {
  /// Creates a [ObjectInput].
  const ObjectInput({
    required this.fields,
    super.key,
    this.values,
    this.separator,
    this.enabled = true,
    this.onChanged,
    this.leading,
    this.trailing,
    this.shortFieldMaxChars = CoreObjectInputContract.defaultShortFieldMaxChars,
    this.mediumFieldMaxChars =
        CoreObjectInputContract.defaultMediumFieldMaxChars,
    this.objectInputStyle,
  });

  @override
  final List<CoreObjectInputField> fields;

  @override
  final Map<String, String>? values;

  @override
  final String? separator;

  @override
  final bool enabled;

  @override
  final ValueChanged<Map<String, String>>? onChanged;

  @override
  final Widget? leading;

  @override
  final Widget? trailing;

  // === Behaviour (bucket boundaries — pick a width, paint nothing) ===

  @override
  final int shortFieldMaxChars;

  @override
  final int mediumFieldMaxChars;

  // === Style (chrome / dimensional) ===

  @override
  final CoreObjectInputStyle? objectInputStyle;

  /// Returns a copy of this [ObjectInput] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  ObjectInput copyWith({
    Key? key,
    ValueChanged<Map<String, String>>? onChanged,
    List<CoreObjectInputField>? fields,
    Map<String, String>? values,
    String? separator,
    bool? enabled,
    Widget? leading,
    Widget? trailing,
    int? shortFieldMaxChars,
    int? mediumFieldMaxChars,
    CoreObjectInputStyle? objectInputStyle,
  }) {
    return ObjectInput(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      fields: fields ?? this.fields,
      values: values ?? this.values,
      separator: separator ?? this.separator,
      enabled: enabled ?? this.enabled,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      shortFieldMaxChars: shortFieldMaxChars ?? this.shortFieldMaxChars,
      mediumFieldMaxChars: mediumFieldMaxChars ?? this.mediumFieldMaxChars,
      objectInputStyle: objectInputStyle ?? this.objectInputStyle,
    );
  }

  @override
  State<ObjectInput> createState() => _ObjectInputState();
}

class _ObjectInputState extends State<ObjectInput> {
  late Map<String, String> _values;
  late List<TextEditingController> _controllers;
  bool _focused = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _allocate();
  }

  List<TextEditingController> _buildControllers() {
    final controllers = <TextEditingController>[];
    for (final field in widget.fields) {
      controllers.add(
        TextEditingController(text: _values[field.key] ?? ''),
      );
    }
    return controllers;
  }

  void _allocate() {
    _values = {
      for (final field in widget.fields)
        field.key: widget.values?[field.key] ?? '',
    };
    _controllers = _buildControllers();
  }

  void _handleHoverEnter(PointerEnterEvent _) {
    if (!_hovered) setState(() => _hovered = true);
  }

  void _handleHoverExit(PointerExitEvent _) {
    if (_hovered) setState(() => _hovered = false);
  }

  void _handleFieldChanged(String key, String text) {
    final updated = {..._values, key: text};
    setState(() => _values = updated);
    widget.onChanged?.call(updated);
  }

  @override
  void didUpdateWidget(covariant ObjectInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields.length != widget.fields.length) {
      for (final controller in _controllers) {
        controller.dispose();
      }
      _allocate();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveObjectInput(
      context,
      objectInputStyle: widget.objectInputStyle,
    );

    final separator = widget.separator;
    final children = <Widget>[];
    final leading = widget.leading;
    if (leading != null) children.add(leading);

    for (var i = 0; i < widget.fields.length; i += 1) {
      final field = widget.fields[i];
      final intrinsicWidth =
          resolved.charWidth * (field.maxLength ?? field.placeholder.length);
      // Cap the per-character intrinsic width with the resolved bucket
      // max-width (short / medium / long) so the field never exceeds the
      // override, mirroring the Web `max-width` rule.
      final maxWidth = resolved.fieldMaxWidthFor(
        field.maxLength,
        shortFieldMaxChars: widget.shortFieldMaxChars,
        mediumFieldMaxChars: widget.mediumFieldMaxChars,
      );
      final fieldWidth = maxWidth == null
          ? intrinsicWidth
          : math.min(intrinsicWidth, maxWidth);
      children.add(
        SizedBox(
          width: fieldWidth,
          // Part of this composite: walled off from the enclosing
          // `FormField`, which is shown the composite's own value.
          child: Data<FormFieldHandle>.boundary(
            child: TextField(
              onChanged: (text) => _handleFieldChanged(field.key, text),
              enabled: widget.enabled,
              variant: resolved.fieldInputVariant,
              size: resolved.fieldInputSize,
              textFieldStyle: resolved.fieldInputStyle,
              maxLength: field.maxLength,
              hintText: field.placeholder,
              controller: _controllers[i],
              inputFormatters: [
                if (field.pattern != null)
                  TextInputFormatters.allow(field.pattern!),
              ],
            ),
          ),
        ),
      );
      if (separator != null && i < widget.fields.length - 1) {
        children.add(
          Padding(
            padding: resolved.separatorPadding,
            child: Text(
              separator,
              style: widget.enabled
                  ? resolved.separatorTextStyle
                  : resolved.disabledSeparatorTextStyle,
            ),
          ),
        );
      }
    }

    final trailing = widget.trailing;
    if (trailing != null) children.add(trailing);

    // The single visual boundary is a composed `OutlinedContainer` —
    // it owns the fill / border / radius / padding, geometry
    // conversion, and the `surface:content` material reach a preset
    // can now apply. `role` is left at its own default (`.content`).
    //
    // `disabled > focus > hover > rest` — the pointer steps the border
    // only on an enabled container that does not hold focus; a focused one
    // keeps its focus border under the pointer.
    final containerStyle = !widget.enabled
        ? resolved.disabledContainerStyle
        : _focused
        ? resolved.focusedContainerStyle
        : _hovered
        ? resolved.hoveredContainerStyle
        : resolved.unfocusedContainerStyle;
    return Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      child: MouseRegion(
        onEnter: _handleHoverEnter,
        onExit: _handleHoverExit,
        child: OutlinedContainer(
          containerStyle: containerStyle,
          child: Row(
            mainAxisSize: .min,
            spacing: resolved.fieldSpacing,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreObjectInputStyle] patch into
/// [ObjectInput.objectInputStyle] without hand-reconstructing every
/// field. Mirrors the Web `ObjectInput.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreObjectInputStyle.merge` right-side-wins semantics).
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
/// sets [CoreObjectInputStyle.borderRadius] and `.primary` sets
/// [CoreObjectInputStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// ObjectInput(fields: fields).radius4.surface
/// ```
extension ObjectInputStyleChain on ObjectInput {
  /// Returns a copy of this [ObjectInput] with [patch] merged into
  /// [objectInputStyle] (patch fields win on conflict).
  ObjectInput withStyle(CoreObjectInputStyle patch) => copyWith(
    objectInputStyle: (objectInputStyle ?? const CoreObjectInputStyle()).merge(
      patch,
    ),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  ObjectInput get radius0 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  ObjectInput get radius2 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  ObjectInput get radius4 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  ObjectInput get radius6 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  ObjectInput get radius8 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  ObjectInput get radius10 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  ObjectInput get radius12 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  ObjectInput get radius14 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  ObjectInput get radius16 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  ObjectInput get radius20 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  ObjectInput get radius24 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  ObjectInput get radius28 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  ObjectInput get radius32 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  ObjectInput get radius36 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  ObjectInput get radius40 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  ObjectInput get radius48 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  ObjectInput get radius56 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  ObjectInput get radius64 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  ObjectInput get radius9999 => withStyle(
    const CoreObjectInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  ObjectInput get primary => withStyle(
    const CoreObjectInputStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  ObjectInput get secondary => withStyle(
    const CoreObjectInputStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  ObjectInput get tertiary => withStyle(
    const CoreObjectInputStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  ObjectInput get surface => withStyle(
    const CoreObjectInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  ObjectInput get surfaceContainer => withStyle(
    const CoreObjectInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  ObjectInput get error => withStyle(
    const CoreObjectInputStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  ObjectInput get success => withStyle(
    const CoreObjectInputStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  ObjectInput get warning => withStyle(
    const CoreObjectInputStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  ObjectInput get info => withStyle(
    const CoreObjectInputStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  ObjectInput get outline => withStyle(
    const CoreObjectInputStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  ObjectInput get transparent => withStyle(
    const CoreObjectInputStyle(backgroundColor: .transparent),
  );
}
