import 'package:coui_flutter/coui_flutter.dart';

/// Theme data for customizing [Radio] widget appearance.
///
/// This class defines the visual properties that can be applied to
/// [Radio] widgets, including colors for different states and sizing.
/// These properties can be set at the theme level to provide consistent
/// styling across the application.
///
/// The theme affects the radio button's visual appearance in both
/// selected and unselected states, including border, background,
/// and active indicator colors.
class RadioTheme {
  const RadioTheme({
    this.activeColor,
    this.backgroundColor,
    this.borderColor,
    this.size,
  });

  final Color? activeColor;
  final Color? borderColor;
  final Color? backgroundColor;

  final double? size;

  RadioTheme copyWith({
    ValueGetter<Color?>? activeColor,
    ValueGetter<Color?>? backgroundColor,
    ValueGetter<Color?>? borderColor,
    ValueGetter<double?>? size,
  }) {
    return RadioTheme(
      activeColor: activeColor == null ? this.activeColor : activeColor(),
      backgroundColor: backgroundColor == null
          ? this.backgroundColor
          : backgroundColor(),
      borderColor: borderColor == null ? this.borderColor : borderColor(),
      size: size == null ? this.size : size(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RadioTheme &&
        other.activeColor == activeColor &&
        other.borderColor == borderColor &&
        other.size == size &&
        other.backgroundColor == backgroundColor;
  }

  @override
  int get hashCode =>
      Object.hash(activeColor, borderColor, size, backgroundColor);
}

/// A radio button widget that displays a circular selection indicator.
///
/// [Radio] provides a visual representation of a selectable option within
/// a radio group. It displays as a circular button with an inner dot when
/// selected and an empty circle when unselected. The widget supports focus
/// indication and customizable colors and sizing.
///
/// The radio button animates smoothly between selected and unselected states,
/// providing visual feedback to user interactions. It integrates with the
/// focus system to provide accessibility support and keyboard navigation.
///
/// Typically used within [RadioItem] or [RadioGroup] components rather than
/// standalone, as it only provides the visual representation without the
/// interaction logic.
///
/// Example:
/// ```dart
/// Radio(
///   value: isSelected,
///   focusing: hasFocus,
///   size: 20,
///   activeColor: Colors.blue,
/// );
/// ```
class Radio extends StatelessWidget {
  /// Creates a [Radio] with the specified selection state and styling.
  ///
  /// The [value] parameter is required and determines whether the radio
  /// appears selected. All other parameters are optional and will fall
  /// back to theme values when not specified.
  ///
  /// Parameters:
  /// - [value] (bool, required): Whether the radio button is selected
  /// - [focusing] (bool, default: false): Whether the radio has focus
  /// - [size] (double?, optional): Size of the radio button in pixels
  /// - [activeColor] (Color?, optional): Color of the selection indicator
  /// - [borderColor] (Color?, optional): Color of the outer border
  /// - [backgroundColor] (Color?, optional): Color of the background fill
  ///
  /// Example:
  /// ```dart
  /// Radio(
  ///   value: selectedValue == itemValue,
  ///   focusing: focusNode.hasFocus,
  ///   size: 18,
  /// );
  /// ```
  const Radio({
    this.activeColor,
    this.backgroundColor,
    this.borderColor,
    this.focusing = false,
    super.key,
    this.size,
    required this.value,
  });

  /// Whether this radio button is selected.
  ///
  /// When true, displays the inner selection indicator.
  /// When false, shows only the outer circle border.
  final bool value;

  /// Whether this radio button currently has focus.
  ///
  /// When true, displays a focus outline around the radio button
  /// for accessibility and keyboard navigation indication.
  final bool focusing;

  /// Size of the radio button in logical pixels.
  ///
  /// Controls both the width and height of the circular radio button.
  /// If null, uses the size from the current [RadioTheme].
  final double? size;

  /// Color of the inner selection indicator when selected.
  ///
  /// Applied to the inner dot that appears when [value] is true.
  /// If null, uses the activeColor from the current [RadioTheme].
  final Color? activeColor;

  /// Color of the outer border circle.
  ///
  /// Applied to the border of the radio button in both selected and
  /// unselected states. If null, uses the borderColor from the current [RadioTheme].
  final Color? borderColor;

  /// Background color of the radio button circle.
  ///
  /// Applied as the fill color behind the border. If null, uses the
  /// backgroundColor from the current [RadioTheme].
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<RadioTheme>(context);
    final size = styleValue<double>(
      widgetValue: this.size,
      themeValue: compTheme?.size,
      defaultValue: theme.scaling * 16,
    );
    final activeColor = styleValue<Color>(
      widgetValue: this.activeColor,
      themeValue: compTheme?.activeColor,
      defaultValue: theme.colorScheme.primary,
    );
    final borderColor = styleValue<Color>(
      widgetValue: this.borderColor,
      themeValue: compTheme?.borderColor,
      defaultValue: theme.colorScheme.input,
    );
    final backgroundColor = styleValue<Color>(
      widgetValue: this.backgroundColor,
      themeValue: compTheme?.backgroundColor,
      defaultValue: theme.colorScheme.input.scaleAlpha(0.3),
    );
    final innerSize = value ? (size - (6 + 2) * theme.scaling) : 0.0;

    return FocusOutline(
      focused: focusing,
      shape: BoxShape.circle,
      child: AnimatedContainer(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          shape: BoxShape.circle,
        ),
        width: size,
        height: size,
        duration: kDefaultDuration,
        child: Center(
          child: AnimatedContainer(
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
            ),
            width: innerSize,
            height: innerSize,
            duration: kDefaultDuration,
          ),
        ),
      ),
    );
  }
}

class NextItemIntent extends Intent {
  const NextItemIntent();
}

class PreviousItemIntent extends Intent {
  const PreviousItemIntent();
}

class RadioItem<T> extends StatefulWidget {
  const RadioItem({
    this.enabled = true,
    this.focusNode,
    super.key,
    this.leading,
    this.trailing,
    required this.value,
  });

  final Widget? leading;
  final Widget? trailing;
  final T value;
  final bool enabled;

  final FocusNode? focusNode;

  @override
  State<RadioItem<T>> createState() => _RadioItemState<T>();
}

class _RadioItemState<T> extends State<RadioItem<T>> {
  late FocusNode _focusNode;

  bool _focusing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(covariant RadioItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupData = Data.maybeOf<RadioGroupData<T>>(context);
    final group = Data.maybeOf<RadioGroupState<T>>(context);
    assert(
      groupData != null,
      'RadioItem<$T> must be a descendant of RadioGroup<$T>',
    );

    return GestureDetector(
      onTap: widget.enabled && (groupData?.enabled ?? false)
          ? () {
              group?._setSelected(widget.value);
            }
          : null,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        actions: {
          NextItemIntent: CallbackAction<NextItemIntent>(
            onInvoke: (intent) {
              if (group != null) {
                group._setSelected(widget.value);
              }

              return null;
            },
          ),
          PreviousItemIntent: CallbackAction<PreviousItemIntent>(
            onInvoke: (intent) {
              if (group != null) {
                group._setSelected(widget.value);
              }

              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) {
          if (value && widget.enabled && (groupData?.enabled ?? false)) {
            group?._setSelected(widget.value);
          }
          if (value != _focusing) {
            setState(() {
              _focusing = value;
            });
          }
        },
        mouseCursor: widget.enabled && (groupData?.enabled ?? false)
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: Data<RadioGroupData<T>>.boundary(
          child: Data<_RadioItemState<T>>.boundary(
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.leading != null) widget.leading!,
                  if (widget.leading != null)
                    SizedBox(width: theme.scaling * 8),
                  Radio(
                    focusing:
                        _focusing && groupData?.selectedItem == widget.value,
                    value: groupData?.selectedItem == widget.value,
                  ),
                  if (widget.trailing != null)
                    SizedBox(width: theme.scaling * 8),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RadioCard<T> extends StatefulWidget {
  const RadioCard({
    required this.child,
    this.enabled = true,
    this.focusNode,
    super.key,
    required this.value,
  });

  final Widget child;
  final T value;
  final bool enabled;

  final FocusNode? focusNode;

  @override
  State<RadioCard<T>> createState() => _RadioCardState<T>();
}

/// Theme data for the [RadioCard] widget.
class RadioCardTheme {
  /// Theme data for the [RadioCard] widget.
  const RadioCardTheme({
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.color,
    this.disabledCursor,
    this.enabledCursor,
    this.hoverColor,
    this.padding,
    this.selectedBorderColor,
    this.selectedBorderWidth,
  });

  /// The cursor to use when the radio card is enabled.
  final MouseCursor? enabledCursor;

  /// The cursor to use when the radio card is disabled.
  final MouseCursor? disabledCursor;

  /// The color to use when the radio card is hovered over.
  final Color? hoverColor;

  /// The default color to use.
  final Color? color;

  /// The width of the border of the radio card.
  final double? borderWidth;

  /// The width of the border of the radio card when selected.
  final double? selectedBorderWidth;

  /// The radius of the border of the radio card.
  final BorderRadiusGeometry? borderRadius;

  /// The padding of the radio card.
  final EdgeInsetsGeometry? padding;

  /// The color of the border.
  final Color? borderColor;

  /// The color of the border when selected.
  final Color? selectedBorderColor;

  @override
  String toString() {
    return 'RadioCardTheme(enabledCursor: $enabledCursor, disabledCursor: $disabledCursor, hoverColor: $hoverColor, color: $color, borderWidth: $borderWidth, selectedBorderWidth: $selectedBorderWidth, borderRadius: $borderRadius, padding: $padding, borderColor: $borderColor, selectedBorderColor: $selectedBorderColor)';
  }

  /// Creates a copy of this [RadioCardTheme] but with the given fields replaced with the new values.
  RadioCardTheme copyWith({
    ValueGetter<Color?>? borderColor,
    ValueGetter<BorderRadiusGeometry?>? borderRadius,
    ValueGetter<double?>? borderWidth,
    ValueGetter<Color?>? color,
    ValueGetter<MouseCursor?>? disabledCursor,
    ValueGetter<MouseCursor?>? enabledCursor,
    ValueGetter<Color?>? hoverColor,
    ValueGetter<EdgeInsetsGeometry?>? padding,
    ValueGetter<Color?>? selectedBorderColor,
    ValueGetter<double?>? selectedBorderWidth,
  }) {
    return RadioCardTheme(
      borderColor: borderColor == null ? this.borderColor : borderColor(),
      borderRadius: borderRadius == null ? this.borderRadius : borderRadius(),
      borderWidth: borderWidth == null ? this.borderWidth : borderWidth(),
      color: color == null ? this.color : color(),
      disabledCursor: disabledCursor == null
          ? this.disabledCursor
          : disabledCursor(),
      enabledCursor: enabledCursor == null
          ? this.enabledCursor
          : enabledCursor(),
      hoverColor: hoverColor == null ? this.hoverColor : hoverColor(),
      padding: padding == null ? this.padding : padding(),
      selectedBorderColor: selectedBorderColor == null
          ? this.selectedBorderColor
          : selectedBorderColor(),
      selectedBorderWidth: selectedBorderWidth == null
          ? this.selectedBorderWidth
          : selectedBorderWidth(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RadioCardTheme &&
        other.enabledCursor == enabledCursor &&
        other.disabledCursor == disabledCursor &&
        other.hoverColor == hoverColor &&
        other.color == color &&
        other.borderWidth == borderWidth &&
        other.selectedBorderWidth == selectedBorderWidth &&
        other.borderRadius == borderRadius &&
        other.padding == padding &&
        other.borderColor == borderColor &&
        other.selectedBorderColor == selectedBorderColor;
  }

  @override
  int get hashCode => Object.hash(
    enabledCursor,
    disabledCursor,
    hoverColor,
    color,
    borderWidth,
    selectedBorderWidth,
    borderRadius,
    padding,
    borderColor,
    selectedBorderColor,
  );
}

class _RadioCardState<T> extends State<RadioCard<T>> {
  late FocusNode _focusNode;
  bool _focusing = false;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(covariant RadioCard<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTheme = ComponentTheme.maybeOf<RadioCardTheme>(context);
    final groupData = Data.maybeOf<RadioGroupData<T>>(context);
    final group = Data.maybeOf<RadioGroupState<T>>(context);
    assert(
      groupData != null,
      'RadioCard<$T> must be a descendant of RadioGroup<$T>',
    );

    return GestureDetector(
      onTap: widget.enabled && (groupData?.enabled ?? false)
          ? () {
              group?._setSelected(widget.value);
            }
          : null,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        actions: {
          NextItemIntent: CallbackAction<NextItemIntent>(
            onInvoke: (intent) {
              if (group != null) {
                group._setSelected(widget.value);
              }

              return null;
            },
          ),
          PreviousItemIntent: CallbackAction<PreviousItemIntent>(
            onInvoke: (intent) {
              if (group != null) {
                group._setSelected(widget.value);
              }

              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) {
          if (value && widget.enabled && (groupData?.enabled ?? false)) {
            group?._setSelected(widget.value);
          }
          if (value != _focusing) {
            setState(() {
              _focusing = value;
            });
          }
        },
        onShowHoverHighlight: (value) {
          if (value != _hovering) {
            setState(() {
              _hovering = value;
            });
          }
        },
        mouseCursor: widget.enabled && (groupData?.enabled ?? false)
            ? styleValue(
                themeValue: componentTheme?.enabledCursor,
                defaultValue: SystemMouseCursors.click,
              )
            : styleValue(
                themeValue: componentTheme?.disabledCursor,
                defaultValue: SystemMouseCursors.forbidden,
              ),
        child: Data<RadioGroupData<T>>.boundary(
          child: Data<_RadioCardState<T>>.boundary(
            child: Card(
              borderColor: groupData?.selectedItem == widget.value
                  ? styleValue(
                      themeValue: componentTheme?.selectedBorderColor,
                      defaultValue: theme.colorScheme.primary,
                    )
                  : styleValue(
                      themeValue: componentTheme?.borderColor,
                      defaultValue: theme.colorScheme.muted,
                    ),
              borderRadius: styleValue(
                themeValue: componentTheme?.borderRadius,
                defaultValue: theme.borderRadiusMd,
              ),
              borderWidth: groupData?.selectedItem == widget.value
                  ? styleValue(
                      themeValue: componentTheme?.selectedBorderWidth,
                      defaultValue: theme.scaling * 2,
                    )
                  : styleValue(
                      themeValue: componentTheme?.borderWidth,
                      defaultValue: theme.scaling * 1,
                    ),
              clipBehavior: Clip.antiAlias,
              duration: kDefaultDuration,
              fillColor: _hovering
                  ? styleValue(
                      themeValue: componentTheme?.hoverColor,
                      defaultValue: theme.colorScheme.muted,
                    )
                  : styleValue(
                      themeValue: componentTheme?.color,
                      defaultValue: theme.colorScheme.background,
                    ),
              padding: EdgeInsets.zero,
              child: Container(
                padding: styleValue(
                  themeValue: componentTheme?.padding,
                  defaultValue: EdgeInsets.all(theme.scaling * 16),
                ),
                child: AnimatedPadding(
                  padding: groupData?.selectedItem == widget.value
                      ? styleValue(
                          themeValue: componentTheme?.borderWidth == null
                              ? null
                              : EdgeInsets.all(componentTheme!.borderWidth!),
                          defaultValue: EdgeInsets.zero,
                        )
                      /// To compensate for the border width.
                      : styleValue(
                          themeValue:
                              componentTheme?.borderWidth != null &&
                                  componentTheme?.selectedBorderWidth != null
                              ? EdgeInsets.all(
                                  componentTheme!.borderWidth! -
                                      componentTheme.selectedBorderWidth!,
                                )
                              : null,
                          defaultValue: EdgeInsets.all(theme.scaling * 1),
                        ),
                  duration: kDefaultDuration,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Controller for managing [ControlledRadioGroup] state programmatically.
///
/// Extends [ValueNotifier] to provide reactive state management for radio group
/// components. Can be used to programmatically change selection, listen to
/// state changes, and integrate with forms and other reactive systems.
///
/// Example:
/// ```dart
/// final controller = RadioGroupController<String>('option1');
///
/// // Listen to changes
/// controller.addListener(() {
///   print('Selection changed to: ${controller.value}');
/// });
///
/// // Update selection
/// controller.value = 'option2';
/// ```
class RadioGroupController<T> extends ValueNotifier<T?>
    with ComponentController<T?> {
  /// Creates a [RadioGroupController] with an optional initial value.
  ///
  /// The [value] parameter sets the initial selected option. Can be null
  /// to start with no selection.
  ///
  /// Parameters:
  /// - [value] (T?, optional): Initial selected value
  RadioGroupController([super.value]);
}

/// Reactive radio button group with automatic state management and exclusivity.
///
/// A high-level radio group widget that provides automatic state management through
/// the controlled component pattern. Manages mutual exclusion between radio options
/// and supports both controller-based and callback-based state management.
///
/// ## Features
///
/// - **Mutual exclusion**: Automatically ensures only one radio button is selected
/// - **Flexible layout**: Works with any child layout (Column, Row, Wrap, etc.)
/// - **Keyboard navigation**: Full keyboard support with arrow keys and Space
/// - **Form integration**: Automatic validation and form field registration
/// - **State synchronization**: Keeps all radio buttons in sync automatically
///
/// ## Usage Patterns
///
/// **Controller-based (recommended for complex state):**
/// ```dart
/// final controller = RadioGroupController<String>('small');
///
/// ControlledRadioGroup<String>(
///   controller: controller,
///   child: Column(
///     children: [
///       Radio<String>(value: 'small', label: Text('Small')),
///       Radio<String>(value: 'medium', label: Text('Medium')),
///       Radio<String>(value: 'large', label: Text('Large')),
///     ],
///   ),
/// )
/// ```
///
/// **Callback-based (simple state management):**
/// ```dart
/// String? selectedSize;
///
/// ControlledRadioGroup<String>(
///   initialValue: selectedSize,
///   onChanged: (size) => setState(() => selectedSize = size),
///   child: Column(
///     children: [
///       Radio<String>(value: 'small', label: Text('Small')),
///       Radio<String>(value: 'medium', label: Text('Medium')),
///       Radio<String>(value: 'large', label: Text('Large')),
///     ],
///   ),
/// )
/// ```
class ControlledRadioGroup<T> extends StatelessWidget
    with ControlledComponent<T?> {
  /// Creates a [ControlledRadioGroup].
  ///
  /// Either [controller] or [onChanged] should be provided for interactivity.
  /// The widget supports both controller-based and callback-based state management
  /// patterns with automatic mutual exclusion between radio options.
  ///
  /// Parameters:
  /// - [controller] (RadioGroupController<T>?, optional): external state controller
  /// - [initialValue] (T?, optional): starting selection when no controller
  /// - [onChanged] (ValueChanged<T?>?, optional): selection change callback
  /// - [enabled] (bool, default: true): whether radio group is interactive
  /// - [child] (Widget, required): layout containing radio buttons
  ///
  /// Example:
  /// ```dart
  /// ControlledRadioGroup<String>(
  ///   controller: controller,
  ///   child: Column(
  ///     children: [
  ///       Radio<String>(value: 'option1', label: Text('Option 1')),
  ///       Radio<String>(value: 'option2', label: Text('Option 2')),
  ///     ],
  ///   ),
  /// )
  /// ```
  const ControlledRadioGroup({
    required this.child,
    this.controller,
    this.enabled = true,
    this.initialValue,
    super.key,
    this.onChanged,
  });

  @override
  final T? initialValue;
  @override
  final ValueChanged<T?>? onChanged;
  @override
  final bool enabled;

  @override
  final RadioGroupController<T?>? controller;

  /// Child widget containing the radio buttons.
  ///
  /// Usually a layout widget like Column, Row, or Wrap containing multiple
  /// [Radio] widgets. The radio group will manage the selection state
  /// of all descendant radio buttons automatically.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ControlledComponentAdapter(
      initialValue: initialValue,
      builder: (context, data) {
        return RadioGroup(
          onChanged: data.onChanged,
          value: data.value,
          child: child,
        );
      },
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

class RadioGroup<T> extends StatefulWidget {
  const RadioGroup({
    required this.child,
    this.enabled,
    super.key,
    this.onChanged,
    this.value,
  });

  final Widget child;
  final T? value;
  final ValueChanged<T>? onChanged;
  final bool? enabled;

  @override
  RadioGroupState<T> createState() => RadioGroupState();
}

class RadioGroupData<T> {
  const RadioGroupData(this.enabled, this.selectedItem);

  final T? selectedItem;

  final bool enabled;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RadioGroupData<T> &&
        other.selectedItem == selectedItem &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(selectedItem, enabled);
}

class RadioGroupState<T> extends State<RadioGroup<T>>
    with FormValueSupplier<T, RadioGroup<T>> {
  bool get enabled => widget.enabled ?? widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    formValue = widget.value;
  }

  void _setSelected(T value) {
    if (!enabled) return;
    if (widget.value != value) {
      widget.onChanged?.call(value);
    }
  }

  @override
  void didUpdateWidget(covariant RadioGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      formValue = widget.value;
    }
  }

  @override
  void didReplaceFormValue(T value) {
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      child: Data.inherit(
        data: this,
        child: Data.inherit(
          data: RadioGroupData(enabled, widget.value),
          child: FocusTraversalGroup(child: widget.child),
        ),
      ),
    );
  }
}
