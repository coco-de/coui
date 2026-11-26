import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/form/number_input/number_input_style.dart';
import 'package:coui_web/src/components/form/text_field/text_field.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Unified cross-platform number input for CoUI Web — `[ − ] value [ + ]`.
///
/// A composed [TextField] (border, fill, hover, focus, error, label and
/// description all come from it) with a [Button] at each end. The value can
/// be typed; the buttons and the arrow / page keys move it by [step], and it
/// stays within [min] .. [max]. At a bound the button that would pass it is
/// disabled.
///
/// Behaviour / semantic fields (`value`, `min`, `max`, `step`, `enabled`,
/// `onChanged`) and the text slots (`label`, `description`) stay flat on the
/// component; all chrome flows through the single [numberInputStyle].
///
/// Example:
/// ```dart
/// NumberInput(
///   label: 'Guests',
///   min: 1,
///   max: 8,
///   onChanged: (value) => print(value),
/// )
/// ```
class NumberInput extends UiStatefulComponent
    implements CoreNumberInputContract {
  /// Creates a [NumberInput].
  const NumberInput({
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
    this.initialValue,
    this.onChanged,
    this.min,
    this.max,
    this.step = CoreNumberInputContract.defaultStep,
    this.variant = CoreNumberInputVariant.defaultNumberInputVariant,
    this.size = CoreNumberInputSize.defaultSize,
    this.enabled,
    this.label,
    this.description,
    this.errorText,
    this.numberInputStyle,
  }) : assert(step > 0, 'step must be positive');

  @override
  final double? value;

  @override
  final double? initialValue;

  @override
  final CoreValueChanged<double>? onChanged;

  @override
  final double? min;

  @override
  final double? max;

  @override
  final double step;

  @override
  final CoreNumberInputVariant variant;

  @override
  final CoreNumberInputSize size;

  @override
  final bool? enabled;

  @override
  final String? label;

  @override
  final String? description;

  @override
  final String? errorText;

  @override
  final CoreNumberInputStyle? numberInputStyle;

  /// Returns a copy of this [NumberInput] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  NumberInput copyWith({
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
    double? value,
    double? initialValue,
    CoreValueChanged<double>? onChanged,
    double? min,
    double? max,
    double? step,
    CoreNumberInputVariant? variant,
    CoreNumberInputSize? size,
    bool? enabled,
    String? label,
    String? description,
    String? errorText,
    CoreNumberInputStyle? numberInputStyle,
  }) {
    return NumberInput(
      key: key ?? this.key,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onClick: onClick ?? this.onClick,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      value: value ?? this.value,
      initialValue: initialValue ?? this.initialValue,
      onChanged: onChanged ?? this.onChanged,
      min: min ?? this.min,
      max: max ?? this.max,
      step: step ?? this.step,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      enabled: enabled ?? this.enabled,
      label: label ?? this.label,
      description: description ?? this.description,
      errorText: errorText ?? this.errorText,
      numberInputStyle: numberInputStyle ?? this.numberInputStyle,
    );
  }

  @override
  State<NumberInput> createState() => _NumberInputState();
}

/// Chain sugar mirroring the Flutter `NumberInput.withStyle` extension —
/// merges a [CoreNumberInputStyle] patch into
/// [NumberInput.numberInputStyle] via [NumberInput.copyWith].
extension NumberInputStyleChain on NumberInput {
  /// Returns a copy of this [NumberInput] with [patch] merged into
  /// [numberInputStyle] (patch fields win on conflict).
  NumberInput withStyle(CoreNumberInputStyle patch) => copyWith(
    numberInputStyle: (numberInputStyle ?? const CoreNumberInputStyle()).merge(
      patch,
    ),
  );
}

/// A bound as the `num` the `<input>` attribute prints — `0`, not `0.0`.
num? _wholeOrNull(double? bound) {
  if (bound == null) return null;
  return bound == bound.roundToDouble() ? bound.toInt() : bound;
}

class _NumberInputState extends State<NumberInput> {
  late double _value;

  /// The text the field shows. Held apart from [_value] so a half-typed
  /// entry (`-`, or `1` on the way to `15`) is not rewritten under the
  /// caret; it is settled on [_commit].
  late String _text;

  bool get _enabled => component.enabled ?? true;

  @override
  void initState() {
    super.initState();
    _value = _bounded(
      component.value ?? component.initialValue ?? component.min ?? 0,
    );
    _text = CoreNumberInputMath.format(_value);
  }

  @override
  void didUpdateComponent(covariant NumberInput oldComponent) {
    super.didUpdateComponent(oldComponent);
    final controlled = component.value;
    if (controlled != null && controlled != oldComponent.value) {
      _setValue(controlled, notify: false);
    } else if (component.min != oldComponent.min ||
        component.max != oldComponent.max) {
      _setValue(_value, notify: false);
    }
  }

  double _bounded(double value) =>
      CoreNumberInputMath.clamp(value, min: component.min, max: component.max);

  /// Moves to [next] (bounded), rewrites the text, and reports a change.
  void _setValue(double next, {bool notify = true}) {
    final bounded = _bounded(next);
    final changed = bounded != _value;
    setState(() {
      _value = bounded;
      _text = CoreNumberInputMath.format(bounded);
    });
    if (changed && notify) component.onChanged?.call(bounded);
  }

  void _handleStep(int steps) {
    if (!_enabled) return;
    _setValue(
      CoreNumberInputMath.stepped(
        _value,
        step: component.step,
        steps: steps,
        min: component.min,
        max: component.max,
      ),
    );
  }

  /// A typed number moves the value as soon as it is inside the bounds; one
  /// outside waits for [_commit] so `1` on the way to `15` is not rejected.
  void _handleTextChanged(String text) {
    _text = text;
    final parsed = CoreNumberInputMath.parse(text);
    if (parsed == null || parsed == _value) return;
    final inside =
        (component.min == null || parsed >= component.min!) &&
        (component.max == null || parsed <= component.max!);
    if (!inside) return;
    setState(() => _value = parsed);
    component.onChanged?.call(parsed);
  }

  /// Settles what is typed: a number is bounded, anything else reverts.
  void _commit() {
    final parsed = CoreNumberInputMath.parse(_text);
    _setValue(parsed ?? _value);
  }

  void _handleKeyDown(web.KeyboardEvent event) {
    if (!_enabled) return;
    final steps = switch (event.key) {
      'ArrowUp' => 1,
      'ArrowDown' => -1,
      'PageUp' => CoreNumberInputMath.pageSteps,
      'PageDown' => -CoreNumberInputMath.pageSteps,
      _ => 0,
    };
    if (steps == 0) return;
    event.preventDefault();
    _handleStep(steps);
  }

  CoreTextFieldVariant get _fieldVariant => switch (component.variant) {
    CoreNumberInputVariant.defaultVariant =>
      CoreTextFieldVariant.defaultVariant,
    CoreNumberInputVariant.filled => CoreTextFieldVariant.filled,
    CoreNumberInputVariant.error => CoreTextFieldVariant.error,
  };

  @override
  Component build(BuildContext context) {
    final resolved = resolveNumberInput(
      context,
      size: component.size,
      variant: component.variant,
      numberInputStyle: component.numberInputStyle,
    );
    final localizations = CouiLocalizations.of(context);
    final canDecrease =
        _enabled && CoreNumberInputMath.canDecrease(_value, min: component.min);
    final canIncrease =
        _enabled && CoreNumberInputMath.canIncrease(_value, max: component.max);

    Component stepButton({
      required IconName icon,
      required String name,
      required bool enabled,
      required int steps,
    }) {
      return Button(
        variant: CoreNumberInputContract.stepButtonVariant,
        shape: CoreNumberInputContract.stepButtonShape,
        size: component.size.toStepButtonSize(),
        enabled: enabled,
        buttonStyle: resolved.buttonStyle,
        attributes: {'aria-label': name},
        onPressed: () => _handleStep(steps),
        child: Icon(icon),
      );
    }

    final field = TextField(
      value: _text,
      enabled: _enabled,
      size: component.size.toComponentSize(),
      variant: _fieldVariant,
      label: component.label,
      description: component.description,
      errorText: component.errorText,
      type: CoreInputType.number,
      min: _wholeOrNull(component.min),
      max: _wholeOrNull(component.max),
      textFieldStyle: resolved.fieldStyle,
      onChanged: _handleTextChanged,
      onSubmitted: (_) => _commit(),
      prefix: stepButton(
        icon: LucideIcons.minus,
        name: localizations.numberInputDecrease,
        enabled: canDecrease,
        steps: -1,
      ),
      suffix: stepButton(
        icon: LucideIcons.plus,
        name: localizations.numberInputIncrease,
        enabled: canIncrease,
        steps: 1,
      ),
    );

    return Component.element(
      tag: 'div',
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: {
        ...component.events,
        'keydown': EventHandlers.createKeyboardEventHandler(_handleKeyDown),
        'focusout': (_) => _commit(),
      },
      children: [field],
    );
  }
}
