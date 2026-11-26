import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';

/// Unified cross-platform number input — `[ − ] value [ + ]`.
///
/// A composed [TextField] (border, fill, hover, focus, error, label and
/// description all come from it) with a [Button] at each end. The value can
/// be typed; the buttons and the arrow / page keys move it by [step], and it
/// stays within [min] .. [max]. At a bound the button that would pass it is
/// disabled.
///
/// Behaviour / semantic fields (`value`, `min`, `max`, `step`, `enabled`,
/// `onChanged`) and the text slots (`label`, `description`) stay flat on the
/// widget; all chrome flows through the single [numberInputStyle].
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
///
/// surface:content — draws no box of its own; the composed [TextField]
/// draws it.
class NumberInput extends StatefulWidget implements CoreNumberInputContract {
  /// Creates a [NumberInput].
  const NumberInput({
    super.key,
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
  final ValueChanged<double>? onChanged;

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
    Key? key,
    double? value,
    double? initialValue,
    ValueChanged<double>? onChanged,
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

/// Chain sugar — merges a [CoreNumberInputStyle] patch into
/// [NumberInput.numberInputStyle] via [NumberInput.copyWith] (patch fields
/// win on conflict).
extension NumberInputStyleChain on NumberInput {
  /// Returns a copy of this [NumberInput] with [patch] merged into
  /// [numberInputStyle].
  NumberInput withStyle(CoreNumberInputStyle patch) => copyWith(
    numberInputStyle: (numberInputStyle ?? const CoreNumberInputStyle()).merge(
      patch,
    ),
  );
}

class _NumberInputState extends State<NumberInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late double _value;

  bool get _enabled => widget.enabled ?? true;

  @override
  void initState() {
    super.initState();
    _value = _bounded(
      widget.value ?? widget.initialValue ?? widget.min ?? 0,
    );
    _controller = TextEditingController(
      text: CoreNumberInputMath.format(_value),
    );
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(NumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controlled = widget.value;
    if (controlled != null && controlled != oldWidget.value) {
      _setValue(controlled, notify: false);
    } else if (widget.min != oldWidget.min || widget.max != oldWidget.max) {
      _setValue(_value, notify: false);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  double _bounded(double value) =>
      CoreNumberInputMath.clamp(value, min: widget.min, max: widget.max);

  /// Moves to [next] (bounded), rewrites the text, and reports a change.
  void _setValue(double next, {bool notify = true}) {
    final bounded = _bounded(next);
    final changed = bounded != _value;
    setState(() => _value = bounded);
    _writeText();
    if (changed && notify) widget.onChanged?.call(bounded);
  }

  void _writeText() {
    final text = CoreNumberInputMath.format(_value);
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _handleStep(int steps) {
    if (!_enabled) return;
    _setValue(
      CoreNumberInputMath.stepped(
        _value,
        step: widget.step,
        steps: steps,
        min: widget.min,
        max: widget.max,
      ),
    );
  }

  /// A typed number moves the value as soon as it is inside the bounds; one
  /// outside waits for [_commit] so `1` on the way to `15` is not rejected.
  void _handleTextChanged(String text) {
    final parsed = CoreNumberInputMath.parse(text);
    if (parsed == null || parsed == _value) return;
    final inside =
        (widget.min == null || parsed >= widget.min!) &&
        (widget.max == null || parsed <= widget.max!);
    if (!inside) return;
    setState(() => _value = parsed);
    widget.onChanged?.call(parsed);
  }

  /// Settles what is typed: a number is bounded, anything else reverts.
  void _commit() {
    final parsed = CoreNumberInputMath.parse(_controller.text);
    _setValue(parsed ?? _value);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commit();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || !_enabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _handleStep(1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _handleStep(-1);
    } else if (key == LogicalKeyboardKey.pageUp) {
      _handleStep(CoreNumberInputMath.pageSteps);
    } else if (key == LogicalKeyboardKey.pageDown) {
      _handleStep(-CoreNumberInputMath.pageSteps);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  CoreTextFieldVariant get _fieldVariant => switch (widget.variant) {
    CoreNumberInputVariant.defaultVariant =>
      CoreTextFieldVariant.defaultVariant,
    CoreNumberInputVariant.filled => CoreTextFieldVariant.filled,
    CoreNumberInputVariant.error => CoreTextFieldVariant.error,
  };

  @override
  Widget build(BuildContext context) {
    final resolved = resolveNumberInput(
      context,
      size: widget.size,
      variant: widget.variant,
      numberInputStyle: widget.numberInputStyle,
    );
    final localizations = CoUILocalizations.of(context);
    final canDecrease =
        _enabled && CoreNumberInputMath.canDecrease(_value, min: widget.min);
    final canIncrease =
        _enabled && CoreNumberInputMath.canIncrease(_value, max: widget.max);

    Widget stepButton({
      required IconName icon,
      required String name,
      required bool enabled,
      required int steps,
    }) {
      return Semantics(
        label: name,
        button: true,
        enabled: enabled,
        onTap: enabled ? () => _handleStep(steps) : null,
        excludeSemantics: true,
        child: Button(
          variant: CoreNumberInputContract.stepButtonVariant,
          shape: CoreNumberInputContract.stepButtonShape,
          size: widget.size.toStepButtonSize(),
          enabled: enabled,
          buttonStyle: resolved.buttonStyle,
          onPressed: () => _handleStep(steps),
          child: Icon(icon),
        ),
      );
    }

    final field = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _handleKey,
      child: Semantics(
        value: CoreNumberInputMath.format(_value),
        increasedValue: CoreNumberInputMath.format(
          _bounded(_value + widget.step),
        ),
        decreasedValue: CoreNumberInputMath.format(
          _bounded(_value - widget.step),
        ),
        onIncrease: canIncrease ? () => _handleStep(1) : null,
        onDecrease: canDecrease ? () => _handleStep(-1) : null,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: _enabled,
          size: widget.size.toComponentSize(),
          variant: _fieldVariant,
          label: widget.label,
          description: widget.description,
          errorText: widget.errorText,
          type: CoreInputType.number,
          keyboardType: TextInputType.numberWithOptions(
            decimal: true,
            signed: widget.min == null || widget.min! < 0,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.eE+\-]')),
          ],
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
        ),
      ),
    );

    return SizedBox(width: resolved.width, child: field);
  }
}
