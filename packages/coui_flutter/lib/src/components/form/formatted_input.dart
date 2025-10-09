import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

class FormattedInputTheme {
  const FormattedInputTheme({this.height, this.padding});

  final double? height;

  final EdgeInsetsGeometry? padding;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FormattedInputTheme &&
        other.height == height &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(height, padding);
}

abstract class InputPart implements FormattedValuePart {
  const InputPart();
  const factory InputPart.static(String text) = StaticPart;
  const factory InputPart.editable({
    List<TextInputFormatter> inputFormatters,
    required int length,
    bool obscureText,
    Widget? placeholder,
    required double width,
  }) = EditablePart;
  Widget build(BuildContext context, FormattedInputData data);
  Object? get partKey;

  bool get canHaveValue => false;

  @override
  String? get value => null;

  @override
  InputPart get part => this;

  @override
  FormattedValuePart withValue(String value) {
    return FormattedValuePart(this, value);
  }
}

class WidgetPart extends InputPart {
  const WidgetPart(this.widget);

  final Widget widget;

  @override
  Widget build(BuildContext context, FormattedInputData data) {
    return widget;
  }

  @override
  Object? get partKey => widget.key;
}

class StaticPart extends InputPart {
  const StaticPart(this.text);

  final String text;

  @override
  Widget build(BuildContext context, FormattedInputData data) {
    return _StaticPartWidget(text: text);
  }

  @override
  String toString() {
    return 'StaticPart{text: $text}';
  }

  @override
  String get partKey => text;
}

class _StaticPartWidget extends StatefulWidget {
  const _StaticPartWidget({required this.text});

  final String text;

  @override
  State<_StaticPartWidget> createState() => _StaticPartWidgetState();
}

class _StaticPartWidgetState extends State<_StaticPartWidget> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.text).muted().base().center();
  }
}

class EditablePart extends InputPart {
  const EditablePart({
    this.inputFormatters = const [],
    required this.length,
    this.obscureText = false,
    this.placeholder,
    required this.width,
  });

  final int length;
  final bool obscureText;
  final List<TextInputFormatter> inputFormatters;
  final double width;
  final Widget? placeholder;

  @override
  Object? get partKey => null;

  @override
  bool get canHaveValue => true;

  @override
  Widget build(BuildContext context, FormattedInputData data) {
    return _EditablePartWidget(
      data: data,
      inputFormatters: inputFormatters,
      length: length,
      obscureText: obscureText,
      placeholder: placeholder,
      width: width,
    );
  }

  @override
  String toString() {
    return 'EditablePart{length: $length, obscureText: $obscureText, inputFormatters: $inputFormatters, width: $width, placeholder: $placeholder}';
  }
}

class _EditablePartController extends TextEditingController {
  _EditablePartController({
    required this.hasPlaceholder,
    required this.maxLength,
    super.text,
  });

  final int maxLength;
  final bool hasPlaceholder;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final theme = Theme.of(context);
    assert(
      !value.composing.isValid || !withComposing || value.isComposingRangeValid,
    );
    final composingRegionOutOfRange =
        !value.isComposingRangeValid || !withComposing;

    if (composingRegionOutOfRange) {
      final text = this.text;
      if (text.isEmpty && hasPlaceholder) {
        return const TextSpan();
      }
      final padding = '_' * max(0, maxLength - text.length);

      return TextSpan(
        children: [
          TextSpan(text: text, style: style),
          TextSpan(
            text: padding,
            style: style?.copyWith(color: theme.colorScheme.mutedForeground),
          ),
        ],
      );
    }

    final composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
        const TextStyle(decoration: TextDecoration.underline);
    final textBefore = value.composing.textBefore(value.text);
    final textInside = value.composing.textInside(value.text);
    final textAfter = value.composing.textAfter(value.text);
    final totalTextLength =
        textBefore.length + textInside.length + textAfter.length;
    if (totalTextLength == 0 && hasPlaceholder) {
      return const TextSpan();
    }
    final padding = '_' * max(0, maxLength - totalTextLength);

    return TextSpan(
      style: style,
      children: <TextSpan>[
        TextSpan(text: textBefore),
        TextSpan(text: textInside, style: composingStyle),
        TextSpan(text: textAfter),
        TextSpan(
          text: padding,
          style: style?.copyWith(color: theme.colorScheme.mutedForeground),
        ),
      ],
    );
  }
}

class _EditablePartWidget extends StatefulWidget {
  const _EditablePartWidget({
    required this.data,
    this.inputFormatters = const [],
    required this.length,
    this.obscureText = false,
    this.placeholder,
    required this.width,
  });

  final FormattedInputData data;
  final int length;
  final bool obscureText;
  final List<TextInputFormatter> inputFormatters;
  final double width;
  final Widget? placeholder;

  @override
  State<_EditablePartWidget> createState() => _EditablePartWidgetState();
}

class _EditablePartWidgetState extends State<_EditablePartWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _EditablePartController(
      hasPlaceholder: widget.placeholder != null,
      maxLength: widget.length,
      text: widget.data.initialValue,
    );
    if (widget.data.controller != null) {
      widget.data.controller!.addListener(_onFormattedInputControllerChange);
    }
  }

  bool _updating = false;

  void _onFormattedInputControllerChange() {
    if (_updating) {
      return;
    }
    _updating = true;
    try {
      if (widget.data.controller != null) {
        final value = widget.data.controller!.value;
        final part = value.values.elementAt(widget.data.partIndex);
        final newText = part.value ?? '';
        _controller.value = _controller.value.replaceText(newText);
      }
    } finally {
      _updating = false;
    }
  }

  void _onChanged(String value) {
    final length = value.length;
    if (length >= widget.length) {
      _nextFocus();
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace &&
          _controller.selection.isCollapsed &&
          _controller.selection.baseOffset == 0) {
        _previousFocus();

        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
          _controller.selection.isCollapsed &&
          _controller.selection.baseOffset == 0) {
        _previousFocus();

        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
          _controller.selection.isCollapsed &&
          _controller.selection.baseOffset == _controller.text.length) {
        _nextFocus();

        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _nextFocus() {
    final nextIndex = data.partIndex + 1;
    if (nextIndex < data.focusNodes.length) {
      final nextNode = data.focusNodes[nextIndex];
      nextNode.requestFocus();
    }
  }

  void _previousFocus() {
    final nextIndex = data.partIndex - 1;
    if (nextIndex >= 0) {
      final nextNode = data.focusNodes[nextIndex];
      nextNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant _EditablePartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length) {
      final oldValue = _controller.value;
      _controller = _EditablePartController(
        hasPlaceholder: widget.placeholder != null,
        maxLength: widget.length,
        text: oldValue.text,
      );
    }
    if (oldWidget.data.controller != widget.data.controller) {
      if (oldWidget.data.controller != null) {
        oldWidget.data.controller!.removeListener(
          _onFormattedInputControllerChange,
        );
      }
      if (widget.data.controller != null) {
        widget.data.controller!.addListener(_onFormattedInputControllerChange);
      }
    }
  }

  @override
  void dispose() {
    if (widget.data.controller != null) {
      widget.data.controller!.removeListener(_onFormattedInputControllerChange);
    }
    super.dispose();
  }

  FormattedInputData get data => widget.data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      onKeyEvent: _onKeyEvent,
      child: FormEntry(
        key: TextFieldKey(data.partIndex),
        child: SizedBox(
          width: widget.width,
          child: ComponentTheme(
            data: const FocusOutlineTheme(
              border: Border.fromBorderSide(BorderSide.none),
            ),
            child: TextField(
              border: const Border.fromBorderSide(BorderSide.none),
              controller: _controller,
              decoration: const BoxDecoration(),
              focusNode: data.focusNode,
              initialValue: data.initialValue,
              inputFormatters: widget.inputFormatters,
              maxLength: widget.length,
              obscureText: widget.obscureText,
              onChanged: _onChanged,
              padding: EdgeInsets.symmetric(horizontal: theme.scaling * 6),
              placeholder: widget.placeholder,
              style: DefaultTextStyle.of(
                context,
              ).style.merge(theme.typography.mono),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class FormattedValuePart {
  const FormattedValuePart(this.part, [this.value]);

  final InputPart part;

  final String? value;

  FormattedValuePart withValue(String value) {
    return FormattedValuePart(part, value);
  }

  @override
  String toString() {
    return 'FormattedValuePart{part: $part, value: $value}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FormattedValuePart &&
        part == other.part &&
        value == other.value;
  }

  @override
  int get hashCode => Object.hash(part, value);
}

class FormattedValue {
  const FormattedValue([this.parts = const []]);

  final List<FormattedValuePart> parts;

  Iterable<FormattedValuePart> get values =>
      parts.where((part) => part.part.canHaveValue);

  FormattedValuePart? operator [](int index) {
    int partIndex = 0;
    for (final part in parts) {
      if (part.part.canHaveValue) {
        if (partIndex == index) {
          return part;
        }
        partIndex += 1;
      }
    }

    return null;
  }

  @override
  String toString() => parts.join();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FormattedValue && listEquals(parts, other.parts);
  }

  @override
  int get hashCode => parts.hashCode;
}

/// A controller for managing [FormattedInput] values programmatically.
///
/// This controller extends [ValueNotifier<FormattedValue>] to provide reactive
/// state management for formatted input components. It implements [ComponentController]
/// to integrate with the controlled component system, allowing external control
/// and listening to formatted input changes.
///
/// Example:
/// ```dart
/// final controller = FormattedInputController(
///   FormattedValue([
///     FormattedValuePart.static('('),
///     FormattedValuePart.editable('', length: 3),
///     FormattedValuePart.static(') '),
///     FormattedValuePart.editable('', length: 3),
///     FormattedValuePart.static('-'),
///     FormattedValuePart.editable('', length: 4),
///   ])
/// );
/// ```
class FormattedInputController extends ValueNotifier<FormattedValue>
    with ComponentController<FormattedValue> {
  /// Creates a [FormattedInputController] with an optional initial value.
  ///
  /// Parameters:
  /// - [value] (FormattedValue, default: empty): Initial formatted value
  FormattedInputController([super.value = const FormattedValue()]);
}

/// A controlled input widget for structured data entry with formatting.
///
/// This widget provides a sophisticated input system that combines static text
/// elements with editable fields in a single input interface. It's ideal for
/// formatted inputs like phone numbers, credit cards, dates, or any structured
/// data that requires specific formatting patterns.
///
/// The FormattedInput manages multiple editable segments, each with their own
/// validation, formatting, and input restrictions. It automatically handles
/// focus management between segments and provides a seamless user experience
/// with proper keyboard navigation.
///
/// Example:
/// ```dart
/// FormattedInput(
///   style: TextStyle(fontFamily: 'monospace'),
///   leading: Icon(Icons.phone),
///   initialValue: FormattedValue([
///     FormattedValuePart.static('('),
///     FormattedValuePart.editable('555', length: 3),
///     FormattedValuePart.static(') '),
///     FormattedValuePart.editable('123', length: 3),
///     FormattedValuePart.static('-'),
///     FormattedValuePart.editable('4567', length: 4),
///   ]),
/// );
/// ```
class FormattedInput extends StatefulWidget
    with ControlledComponent<FormattedValue> {
  /// Creates a [FormattedInput].
  ///
  /// The input structure is defined by the [initialValue] or [controller]
  /// value, which contains the mix of static text and editable segments.
  /// Each editable segment can have its own length restrictions and formatting.
  ///
  /// Parameters:
  /// - [initialValue] (FormattedValue?, optional): Initial structure and values
  /// - [onChanged] (ValueChanged<FormattedValue>?, optional): Callback for value changes
  /// - [style] (TextStyle?, optional): Text styling for all segments
  /// - [leading] (Widget?, optional): Widget displayed before the input
  /// - [trailing] (Widget?, optional): Widget displayed after the input
  /// - [enabled] (bool, default: true): Whether the input accepts user interaction
  /// - [controller] (FormattedInputController?, optional): External controller for programmatic control
  ///
  /// Example:
  /// ```dart
  /// FormattedInput(
  ///   initialValue: FormattedValue([
  ///     FormattedValuePart.static('$'),
  ///     FormattedValuePart.editable('0.00', length: 8),
  ///   ]),
  ///   leading: Icon(Icons.attach_money),
  ///   style: TextStyle(fontSize: 16),
  /// );
  /// ```
  const FormattedInput({
    this.controller,
    this.enabled = true,
    this.initialValue,
    super.key,
    this.leading,
    this.onChanged,
    this.trailing,
  });

  @override
  final FormattedValue? initialValue;
  @override
  final ValueChanged<FormattedValue>? onChanged;
  @override
  final bool enabled;

  @override
  final FormattedInputController? controller;

  /// Widget displayed at the beginning of the input.
  ///
  /// Commonly used for icons or labels that provide context for the input
  /// content, such as a phone icon for phone number inputs.
  final Widget? leading;

  /// Widget displayed at the end of the input.
  ///
  /// Can be used for action buttons, status indicators, or additional
  /// context related to the input content.
  final Widget? trailing;

  @override
  State<FormattedInput> createState() => _FormattedInputState();
}

class _FormattedInputState extends State<FormattedInput> {
  static List<FocusNode> _allocateFocusNodes(
    int newLength, [
    List<FocusNode>? oldNodes,
  ]) {
    if (oldNodes == null) {
      return List.generate(newLength, (index) => FocusNode());
    }
    if (newLength == oldNodes.length) {
      return oldNodes;
    }
    if (newLength < oldNodes.length) {
      for (int i = newLength; i < oldNodes.length; i += 1) {
        oldNodes[i].dispose();
      }

      return oldNodes.sublist(0, newLength);
    }

    return [
      ...oldNodes,
      ...List.generate(newLength - oldNodes.length, (index) => FocusNode()),
    ];
  }

  final _controller = FormController();
  bool _hasFocus = false;
  FormattedValue? _value;

  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue ?? widget.controller?.value;
    _controller.addListener(_notifyChanged);
    int partIndex = 0;
    if (_value != null) {
      for (final part in _value!.parts) {
        if (part.part.canHaveValue) {
          partIndex += 1;
        }
      }
    }
    _focusNodes = _allocateFocusNodes(partIndex);
  }

  Widget _buildPart(int index, InputPart part) {
    final formattedInputData = FormattedInputData(
      controller: widget.controller,
      enabled: widget.enabled,
      focusNode: index < 0 ? null : _focusNodes[index],
      focusNodes: _focusNodes,
      initialValue: index < 0 ? null : (_value?[index]?.value ?? ''),
      partIndex: index,
    );

    return part.build(context, formattedInputData);
  }

  void _notifyChanged() {
    if (_updating) {
      return;
    }
    _updating = true;
    try {
      final parts = <FormattedValuePart>[];
      final values = _controller.values;
      final value = _value;
      if (value == null) {
        _focusNodes = _allocateFocusNodes(0, _focusNodes);
      } else {
        int partIndex = 0;
        for (int i = 0; i < value.parts.length; i += 1) {
          final part = value.parts[i];
          if (part.part.canHaveValue) {
            final key = FormKey<String>(partIndex);
            final val = values[key];
            parts.add(part.withValue(val as String? ?? ''));
            partIndex += 1;
          } else {
            parts.add(part);
          }
        }
        _focusNodes = _allocateFocusNodes(partIndex, _focusNodes);
      }
      if (widget.onChanged != null) {
        widget.onChanged!(FormattedValue(parts));
      }
    } finally {
      _updating = false;
    }
  }

  bool _updating = false;

  @override
  void dispose() {
    _controller.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    if (_value != null) {
      int partIndex = 0;
      for (final part in _value!.parts) {
        if (part.part.canHaveValue) {
          children.add(_buildPart(partIndex, part.part));
          partIndex += 1;
        } else {
          children.add(_buildPart(-1, part.part));
        }
      }
    }
    final compTheme = ComponentTheme.maybeOf<FormattedInputTheme>(context);

    return SizedBox(
      height: (compTheme?.height ?? kTextFieldHeight) * theme.scaling, // 32 + 2
      child: TextFieldTapRegion(
        child: Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _hasFocus = hasFocus;
            });
          },
          child: FocusOutline(
            borderRadius: theme.borderRadiusMd,
            focused: _hasFocus,
            child: OutlinedContainer(
              backgroundColor: theme.colorScheme.input.scaleAlpha(0.3),
              borderColor: theme.colorScheme.border,
              borderRadius: theme.borderRadiusMd,
              padding:
                  compTheme?.padding ??
                  EdgeInsets.symmetric(horizontal: theme.scaling * 6),
              child: Form(
                controller: _controller,
                child: FocusTraversalGroup(
                  policy: WidgetOrderTraversalPolicy(),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.leading != null) widget.leading!,
                        ...children,
                        if (widget.trailing != null) widget.trailing!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FormattedInputData {
  const FormattedInputData({
    required this.controller,
    required this.enabled,
    required this.focusNode,
    required this.focusNodes,
    required this.initialValue,
    required this.partIndex,
  });

  final int partIndex;
  final String? initialValue;
  final bool enabled;
  final FormattedInputController? controller;
  final FocusNode? focusNode;
  final List<FocusNode> focusNodes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FormattedInputData &&
        partIndex == other.partIndex &&
        initialValue == other.initialValue &&
        enabled == other.enabled &&
        controller == other.controller &&
        focusNode == other.focusNode &&
        focusNodes == other.focusNodes;
  }

  @override
  int get hashCode => Object.hash(
    partIndex,
    initialValue,
    enabled,
    controller,
    focusNode,
    focusNodes,
  );
}

typedef FormattedInputPopupBuilder<T> =
    Widget Function(
      BuildContext context,
      ComponentController<T?> controller,
    );

class FormattedObjectInput<T> extends StatefulWidget
    with ControlledComponent<T?> {
  const FormattedObjectInput({
    this.controller,
    required this.converter,
    this.enabled = true,
    this.initialValue,
    super.key,
    this.onChanged,
    this.onPartsChanged,
    required this.parts,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popoverIcon,
    this.popoverOffset,
    this.popupBuilder,
  });

  @override
  final T? initialValue;
  @override
  final ValueChanged<T?>? onChanged;
  final ValueChanged<List<String>>? onPartsChanged;
  final FormattedInputPopupBuilder<T>? popupBuilder;
  @override
  final bool enabled;
  @override
  final ComponentController<T?>? controller;
  final BiDirectionalConvert<T?, List<String?>> converter;
  final List<InputPart> parts;
  final AlignmentGeometry? popoverAlignment;
  final AlignmentGeometry? popoverAnchorAlignment;
  final Offset? popoverOffset;

  final Widget? popoverIcon;

  @override
  State<FormattedObjectInput<T>> createState() =>
      _FormattedObjectInputState<T>();
}

class _FormattedObjectController<T> extends ValueNotifier<T?>
    with ComponentController<T?> {
  _FormattedObjectController([super.value]);
}

class _FormattedObjectInputState<T> extends State<FormattedObjectInput<T>> {
  late FormattedInputController _formattedController;
  late ComponentController<T?> _controller;

  final _popoverController = PopoverController();

  bool _updating = false; // to prevent circular updates

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _FormattedObjectController<T>();
    final values = widget.converter.convertA(
      widget.initialValue ?? widget.controller?.value,
    );
    final valueParts = <FormattedValuePart>[];
    int partIndex = 0;
    for (int i = 0; i < widget.parts.length; i += 1) {
      final part = widget.parts[i];
      if (part.canHaveValue) {
        final value = values[partIndex];
        if (value == null) {
          valueParts.add(FormattedValuePart(part));
        } else {
          valueParts.add(part.withValue(value));
        }
        partIndex += 1;
      } else {
        valueParts.add(FormattedValuePart(part));
      }
    }
    _formattedController = FormattedInputController(
      FormattedValue(valueParts),
    );
    _formattedController.addListener(_onFormattedControllerUpdate);
    _controller.addListener(_onControllerUpdate);
  }

  void _onFormattedControllerUpdate() {
    if (_updating) return;
    _updating = true;
    try {
      final value = _formattedController.value;
      final newValue = widget.converter.convertB(
        value.values.map((part) {
          return part.value ?? '';
        }).toList(),
      );
      _controller.value = newValue;
      widget.onChanged?.call(newValue);
    } finally {
      _updating = false;
    }
  }

  void _onControllerUpdate() {
    if (_updating) return;
    _updating = true;
    try {
      final values = widget.converter.convertA(_controller.value);
      final valueParts = <FormattedValuePart>[];
      int partIndex = 0;
      final oldValues = _formattedController.value.values.toList();
      for (int i = 0; i < widget.parts.length; i += 1) {
        final part = widget.parts[i];
        if (part.canHaveValue) {
          final value = values[partIndex];
          if (value == null) {
            final oldValue = partIndex < oldValues.length
                ? oldValues[partIndex]
                : null;
            if (oldValue == null) {
              valueParts.add(FormattedValuePart(part));
            } else {
              valueParts.add(oldValue);
            }
          } else {
            valueParts.add(part.withValue(value));
          }
          partIndex += 1;
        } else {
          valueParts.add(FormattedValuePart(part));
        }
      }
      _formattedController.value = FormattedValue(valueParts);
      widget.onChanged?.call(_controller.value);
    } finally {
      _updating = false;
    }
  }

  void _openPopover() {
    final popupBuilder = widget.popupBuilder;
    if (popupBuilder == null) {
      return;
    }
    final theme = Theme.of(context);
    _popoverController.show<void>(
      alignment: widget.popoverAlignment ?? AlignmentDirectional.topStart,
      anchorAlignment:
          widget.popoverAnchorAlignment ?? AlignmentDirectional.bottomStart,
      builder: (context) {
        return popupBuilder(context, _controller);
      },
      context: context,
      offset: widget.popoverOffset ?? (const Offset(0, 4) * theme.scaling),
    );
  }

  @override
  void didUpdateWidget(covariant FormattedObjectInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.parts, oldWidget.parts)) {
      final values = widget.converter.convertA(_controller.value);
      final valueParts = <FormattedValuePart>[];
      final oldValues = _formattedController.value.values.toList();
      int partIndex = 0;
      for (int i = 0; i < widget.parts.length; i += 1) {
        final part = widget.parts[i];
        if (part.canHaveValue) {
          final value = values[partIndex];
          if (value == null) {
            final oldValue = partIndex < oldValues.length
                ? oldValues[partIndex]
                : null;
            if (oldValue == null) {
              valueParts.add(FormattedValuePart(part));
            } else {
              valueParts.add(oldValue);
            }
          } else {
            valueParts.add(part.withValue(value));
          }
          partIndex += 1;
        } else {
          valueParts.add(FormattedValuePart(part));
        }
      }
      _updating = true;
      try {
        _formattedController.value = FormattedValue(valueParts);
      } finally {
        _updating = false;
      }
    }
  }

  @override
  void dispose() {
    _formattedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popoverIcon = widget.popoverIcon;

    return FormattedInput(
      controller: _formattedController,
      onChanged: (value) {
        final values = value.values.map((part) {
          return part.value ?? '';
        }).toList();
        widget.onPartsChanged?.call(values);
        final newValue = widget.converter.convertB(values);
        _controller.value = newValue;
      },
      trailing: popoverIcon == null
          ? null
          : ListenableBuilder(
              listenable: _popoverController,
              builder: (context, child) {
                return WidgetStatesProvider(
                  states: {
                    if (_popoverController.hasOpenPopover) WidgetState.hovered,
                  },
                  child: child!,
                );
              },
              child: IconButton.text(
                onPressed: _openPopover,
                icon: popoverIcon,
                density: ButtonDensity.compact,
              ),
            ),
    );
  }
}
