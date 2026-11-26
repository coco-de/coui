import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/object_input/object_input_style.dart';
import 'package:coui_web/src/components/form/text_field/text_field.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' show RawText, Styles;
import 'package:jaspr/jaspr.dart' hide Text;

int _coObjectInputScopeCounter = 0;

/// Unified cross-platform key-value object input for CoUI Web.
///
/// `ObjectInput` renders a row of structured key-value fields
/// separated by an optional [separator], emitting a `Map<String,
/// String>` of field key → value. It is the structured-data sibling of
/// `FormattedInput`.
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
class ObjectInput extends UiStatefulComponent
    implements
        CoreObjectInputContract<
          CoreValueChanged<Map<String, String>>?,
          Component
        > {
  /// Creates a [ObjectInput].
  const ObjectInput({
    required this.fields,
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
  final CoreValueChanged<Map<String, String>>? onChanged;

  @override
  final Component? leading;

  @override
  final Component? trailing;

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
    Map<String, String>? attributes,
    UiMouseEventHandler? onClick,
    CoreValueChanged<Map<String, String>>? onChanged,
    List<CoreObjectInputField>? fields,
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
    Map<String, String>? values,
    String? separator,
    bool? enabled,
    Component? leading,
    Component? trailing,
    int? shortFieldMaxChars,
    int? mediumFieldMaxChars,
    CoreObjectInputStyle? objectInputStyle,
  }) {
    return ObjectInput(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      fields: fields ?? this.fields,
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

class _ObjectInputState extends State<ObjectInput>
    with FormValueSupplier<Map<String, String>, ObjectInput> {
  late final String _scopeId;
  bool _focused = false;
  late Map<String, String> _values;

  @override
  void initState() {
    super.initState();
    _scopeId =
        'co-object-input-${kIsWeb ? 'web' : 'ssr'}-'
        '${_coObjectInputScopeCounter++}';
    _values = _initialValues();
    formValue = _values;
  }

  Map<String, String> _initialValues() => {
    for (final field in component.fields)
      field.key: component.values?[field.key] ?? '',
  };

  void _handleFieldChanged(String key, String text) {
    final updated = {..._values, key: text};
    setState(() => _values = updated);
    formValue = updated;
    component.onChanged?.call(updated);
  }

  @override
  void didUpdateComponent(covariant ObjectInput oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.fields.length != component.fields.length) {
      _values = _initialValues();
      formValue = _values;
    }
  }

  @override
  void didReplaceFormValue(Map<String, String> value) {
    // The field `<input>`s are controlled (their `value` renders from
    // `_values`), so an async validator's normalised value is adopted by
    // re-rendering with it, and forwarded to the caller.
    setState(() => _values = value);
    component.onChanged?.call(value);
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveObjectInput(
      context,
      enabled: component.enabled,
      focused: _focused,
      objectInputStyle: component.objectInputStyle,
    );
    final buckets = resolveObjectInputFieldBuckets(
      context,
      objectInputStyle: component.objectInputStyle,
    );
    // Scope id for the container's hover scoped rule — the caller's own id
    // wins, else a generated one stable across rebuilds via the State's
    // identity.
    final scopeId = component.id ?? _scopeId;
    final rules = resolveObjectInputRules(
      context,
      scopeId: scopeId,
      enabled: component.enabled,
      focused: _focused,
      objectInputStyle: component.objectInputStyle,
    );

    final separator = component.separator;
    final children = <Component>[
      // `<style>` is `display: none`, so it creates no flex item and never
      // affects the row.
      if (rules.css.isNotEmpty)
        Component.element(tag: 'style', children: [RawText(rules.css)]),
    ];
    final leading = component.leading;
    if (leading != null) children.add(leading);

    for (var i = 0; i < component.fields.length; i += 1) {
      final field = component.fields[i];
      final value = _values[field.key] ?? '';
      final fieldResolved = resolveObjectInputField(
        shortFieldMaxWidth: buckets.shortFieldMaxWidth,
        mediumFieldMaxWidth: buckets.mediumFieldMaxWidth,
        longFieldMaxWidth: buckets.longFieldMaxWidth,
        shortFieldMaxChars: component.shortFieldMaxChars,
        mediumFieldMaxChars: component.mediumFieldMaxChars,
        charWidth: buckets.charWidth,
        intrinsicChars: field.maxLength ?? field.placeholder.length,
        maxLength: field.maxLength,
      );
      children.add(
        Component.element(
          tag: 'div',
          classes: fieldResolved.root.className,
          styles: fieldResolved.root.inlineStyles,
          children: [
            // Part of this composite: walled off from the enclosing
            // `FormField`, which is shown the composite's own value.
            FormFieldHandleScope.boundary(
              child: TextField(
                onChanged: component.enabled
                    ? (text) => _handleFieldChanged(field.key, text)
                    : null,
                value: value,
                enabled: component.enabled,
                variant: resolved.fieldInputVariant,
                size: resolved.fieldInputSize,
                textFieldStyle: resolved.fieldInputStyle,
                maxLength: field.maxLength,
                pattern: field.pattern,
                inputFormatters: [
                  if (field.pattern != null)
                    CoreInputFormatters.allow(field.pattern!),
                ],
                hintText: field.placeholder,
              ),
            ),
          ],
        ),
      );
      if (separator != null && i < component.fields.length - 1) {
        children.add(
          Component.element(
            tag: 'span',
            classes: resolved.separator.className,
            styles: resolved.separator.inlineStyles,
            children: [Text(separator)],
          ),
        );
      }
    }

    final trailing = component.trailing;
    if (trailing != null) children.add(trailing);

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
      // `focusin` / `focusout` bubble from the composed field
      // `TextField`s (unlike `focus` / `blur`), so the container tracks
      // focus to drive the focus-ring border.
      events: {
        ...component.events,
        if (component.enabled) ...{
          'focusin': (_) => setState(() => _focused = true),
          'focusout': (_) => setState(() => _focused = false),
        },
      },
      children: children,
    );
  }
}

/// Chain sugar mirroring the Flutter `ObjectInput.withStyle` extension —
/// merges a [CoreObjectInputStyle] patch into
/// [ObjectInput.objectInputStyle] via the existing
/// [ObjectInput.copyWith].
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
      borderRadius: CoreBorderRadius.zero,
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
