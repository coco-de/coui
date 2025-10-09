import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:coui_flutter/coui_flutter.dart';

/// Function signature for building custom chip widgets in chip input fields.
///
/// Takes a [BuildContext] and chip data of type [T], returning a widget that
/// represents the chip visually. Allows complete customization of chip appearance
/// and behavior within chip input components.
typedef ChipWidgetBuilder<T> = Widget Function(BuildContext context, T chip);

/// Theme configuration for [ChipInput] widget styling and behavior.
///
/// Defines visual properties and default behaviors for chip input components
/// including popover constraints and chip rendering preferences. Applied globally
/// through [ComponentTheme] or per-instance for customization.
class ChipInputTheme {
  /// Creates a [ChipInputTheme].
  ///
  /// All parameters are optional and fall back to framework defaults when null.
  /// The theme can be applied globally or to specific chip input instances.
  const ChipInputTheme({this.popoverConstraints, this.useChips});

  /// Constraints applied to the suggestion popover container.
  ///
  /// Controls the maximum and minimum dimensions of the autocomplete suggestion
  /// popover that appears during typing. When null, uses framework defaults
  /// with reasonable size limits for suggestion lists.
  final BoxConstraints? popoverConstraints;

  /// Whether to render selected items as interactive chip widgets by default.
  ///
  /// When true, selected items appear as dismissible chip widgets with close buttons.
  /// When false, items appear as simple text tokens. Individual [ChipInput] widgets
  /// can override this default behavior.
  final bool? useChips;

  /// Creates a copy of this theme with specified properties overridden.
  ///
  /// Each parameter function is called only if provided, allowing selective
  /// overrides while preserving existing values for unspecified properties.
  ChipInputTheme copyWith({
    ValueGetter<BoxConstraints?>? popoverConstraints,
    ValueGetter<bool?>? useChips,
  }) {
    return ChipInputTheme(
      popoverConstraints: popoverConstraints == null
          ? this.popoverConstraints
          : popoverConstraints(),
      useChips: useChips == null ? this.useChips : useChips(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChipInputTheme &&
        other.popoverConstraints == popoverConstraints &&
        other.useChips == useChips;
  }

  @override
  int get hashCode => Object.hash(popoverConstraints, useChips);
}

/// Reactive controller for managing chip input state with convenient methods.
///
/// Extends [ValueNotifier] to provide state management for chip input widgets
/// containing lists of typed objects. Supports adding, removing, and clearing
/// chips programmatically while notifying listeners of changes.
///
/// The controller maintains a list of items of type [T] and provides methods
/// for common list operations in chip input contexts.
///
/// Example:
/// ```dart
/// final controller = ChipInputController<String>(['initial', 'chips']);
///
/// // React to changes
/// controller.addListener(() {
///   print('Chips: ${controller.value}');
/// });
///
/// // Programmatic control
/// controller.add('new chip');
/// controller.removeAt(0);
/// ```
class ChipInputController<T> extends ValueNotifier<List<T>>
    with ComponentController<List<T>> {
  /// Creates a [ChipInputController] with an optional initial list of chips.
  ///
  /// The [value] parameter provides the initial chip list. When not specified,
  /// starts with an empty list. The controller notifies listeners when the
  /// chip list changes through any method calls or direct value assignment.
  ///
  /// Example:
  /// ```dart
  /// final controller = ChipInputController<String>(['apple', 'banana']);
  /// ```
  ChipInputController([super.value = const []]);

  /// Adds a new chip to the end of the current list.
  ///
  /// Notifies listeners of the change. The chip is appended to maintain
  /// the existing order of chips in the input.
  void add(T chip) {
    value = [...value, chip];
  }

  /// Removes the chip at the specified index.
  ///
  /// Throws [RangeError] if the index is out of bounds. Notifies listeners
  /// of the change if the removal is successful.
  void removeAt(int index) {
    final newList = [...value];
    newList.removeAt(index);
    value = newList;
  }

  /// Removes all chips matching the provided chip.
  ///
  /// Uses equality comparison to find matching chips. Removes all occurrences
  /// and notifies listeners if any chips were removed.
  void remove(T chip) {
    value = value.where((item) => item != chip).toList();
  }

  /// Removes all chips from the input.
  ///
  /// Sets the value to an empty list and notifies listeners of the change.
  void clear() {
    value = [];
  }

  /// Returns true if the chip list contains the specified chip.
  bool contains(T chip) {
    return value.contains(chip);
  }

  /// Returns the number of chips currently in the input.
  int get length => value.length;

  /// Returns true if the chip input is empty.
  bool get isEmpty => value.isEmpty;

  /// Returns true if the chip input contains at least one chip.
  bool get isNotEmpty => value.isNotEmpty;
}

/// Reactive chip input with automatic state management and controller support.
///
/// A high-level chip input widget that provides automatic state management through
/// the controlled component pattern. Supports both controller-based and callback-based
/// state management with comprehensive customization options for chips, suggestions,
/// and input behavior.
///
/// ## Features
///
/// - **Flexible chip rendering**: Custom chip builders for complete visual control
/// - **Autocomplete suggestions**: Real-time suggestions with customizable presentation
/// - **Multiple input modes**: Text tokenization or chip-based entry
/// - **Form integration**: Automatic validation and form field registration
/// - **Keyboard navigation**: Full keyboard support for selection and deletion
///
/// ## Usage Patterns
///
/// **Controller-based (recommended for complex state):**
/// ```dart
/// final controller = ChipInputController<String>(['apple', 'banana']);
///
/// ControlledChipInput<String>(
///   controller: controller,
///   chipBuilder: (context, chip) => Chip(label: Text(chip)),
///   suggestions: ['orange', 'grape', 'mango'],
/// )
/// ```
///
/// **Callback-based (simple state management):**
/// ```dart
/// List<String> selectedItems = [];
///
/// ControlledChipInput<String>(
///   initialValue: selectedItems,
///   onChanged: (items) => setState(() => selectedItems = items),
///   chipBuilder: (context, chip) => CustomChipWidget(chip),
/// )
/// ```
class ControlledChipInput<T> extends StatelessWidget
    with ControlledComponent<List<T>> {
  /// Creates a [ControlledChipInput] with comprehensive customization options.
  ///
  /// The [chipBuilder] parameter is required as it defines how chips are visually
  /// represented. Either [controller] or [onChanged] should be provided for
  /// interactivity, depending on the preferred state management approach.
  ///
  /// Parameters:
  /// - [controller] (ChipInputController<T>?, optional): external state controller
  /// - [initialValue] (List<T>, default: []): starting chips when no controller
  /// - [onChanged] (ValueChanged<List<T>>?, optional): chip list change callback
  /// - [enabled] (bool, default: true): whether input is interactive
  /// - [chipBuilder] (ChipWidgetBuilder<T>, required): chip widget builder
  /// - [suggestions] (List<T>, default: []): available autocomplete options
  /// - [suggestionBuilder] (ChipWidgetBuilder<T>?, optional): custom suggestion builder
  /// - [useChips] (bool?, optional): override chip rendering mode
  /// - [placeholder] (Widget?, optional): empty state placeholder widget
  /// - [undoHistoryController] (UndoHistoryController?, optional): undo/redo controller for text input
  /// - [onSubmitted] (ValueChanged<String>?, optional): callback for text submission
  /// - [initialText] (String?, optional): initial text value for input field
  /// - [focusNode] (FocusNode?, optional): focus node for input field
  /// - [inputFormatters] (List<TextInputFormatter>?, optional): input formatters for text field
  /// - [textInputAction] (TextInputAction?, optional): keyboard action button
  /// - [suggestionLeadingBuilder] (Widget Function(BuildContext, T)?, optional): leading widget builder for suggestions
  /// - [suggestionTrailingBuilder] (Widget Function(BuildContext, T)?, optional): trailing widget builder for suggestions
  /// - [inputTrailingWidget] (Widget?, optional): trailing widget for input field
  ///
  /// Example:
  /// ```dart
  /// ControlledChipInput<String>(
  ///   controller: controller,
  ///   chipBuilder: (context, chip) => Chip(
  ///     label: Text(chip),
  ///     onDeleted: () => controller.remove(chip),
  ///   ),
  ///   suggestions: ['apple', 'banana', 'cherry'],
  ///   placeholder: Text('Type to add fruits...'),
  ///   undoHistoryController: myUndoController,
  ///   onSubmitted: (text) => print('Submitted: $text'),
  ///   initialText: 'Start typing...',
  ///   focusNode: myFocusNode,
  ///   inputFormatters: [myFormatter],
  ///   textInputAction: TextInputAction.done,
  ///   suggestionLeadingBuilder: (context, chip) => Icon(Icons.star),
  ///   suggestionTrailingBuilder: (context, chip) => Icon(Icons.close),
  ///   inputTrailingWidget: Icon(Icons.add),
  /// )
  /// ```
  const ControlledChipInput({
    required this.chipBuilder,
    this.chips = const [],
    this.controller,
    this.enabled = true,
    this.focusNode,
    this.initialText,
    this.initialValue = const [],
    this.inputFormatters,
    this.inputTrailingWidget,
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.onSuggestionChoosen,
    this.placeholder,
    this.popoverConstraints,
    this.suggestionBuilder,
    this.suggestionLeadingBuilder,
    this.suggestionTrailingBuilder,
    this.suggestions = const [],
    this.textEditingController,
    this.textInputAction,
    this.undoHistoryController,
    this.useChips,
  });

  /// Initial chip list when no controller is provided.
  ///
  /// Used only when [controller] is null. Provides the starting set of chips
  /// to display in the input. Defaults to an empty list.
  @override
  final List<T> initialValue;

  /// Callback fired when the chip list changes.
  ///
  /// Called with the new list of chips when user interactions modify the selection.
  /// If both [controller] and [onChanged] are provided, both will receive updates.
  @override
  final ValueChanged<List<T>>? onChanged;

  /// External controller for programmatic chip list management.
  ///
  /// When provided, takes precedence over [initialValue] and [onChanged].
  /// The controller's state changes are automatically reflected in the widget.
  @override
  final ChipInputController<T>? controller;

  /// Whether the chip input is interactive and enabled.
  ///
  /// When false, the input becomes read-only and visually disabled.
  /// When null, automatically determines enabled state based on callbacks.
  @override
  final bool enabled;

  /// External controller for the underlying text input field.
  ///
  /// Provides direct control over the text entry portion of the chip input.
  /// When null, the widget manages its own text input controller internally.
  final TextEditingController? textEditingController;

  /// Constraints applied to the autocomplete suggestion popover.
  ///
  /// Overrides the theme default. Controls the size limits of the suggestion
  /// list that appears during typing. When null, uses theme or framework defaults.
  final BoxConstraints? popoverConstraints;

  /// Undo history controller for text input field.
  ///
  /// Allows programmatic undo/redo of text input changes. Delegated to the underlying [ChipInput].
  final UndoHistoryController? undoHistoryController;

  /// Callback fired when the user submits the input (e.g., presses enter).
  ///
  /// Delegated to the underlying [ChipInput]. Called with the submitted text value.
  final ValueChanged<String>? onSubmitted;

  /// Initial text value for the input field.
  ///
  /// Delegated to the underlying [ChipInput]. Sets the starting text in the input field.
  final String? initialText;

  /// Focus node for managing input focus.
  ///
  /// Delegated to the underlying [ChipInput]. Allows external control of focus state.
  final FocusNode? focusNode;

  /// List of available suggestions for autocomplete functionality.
  ///
  /// Items from this list are filtered and presented to the user during typing.
  /// The actual filtering logic is managed internally based on text input.
  final List<T> suggestions;

  /// Current list of selected chips to display.
  ///
  /// When using controller-based management, this is managed automatically.
  /// For callback-based management, this should reflect the current state.
  final List<T> chips;

  /// List of input formatters for the text field.
  ///
  /// Delegated to the underlying [ChipInput]. Allows customization of text input formatting and restrictions.
  final List<TextInputFormatter>? inputFormatters;

  /// Callback for handling suggestion selection.
  ///
  /// Called with the index of the selected suggestion when a user chooses
  /// an item from the autocomplete list. The callback is responsible for
  /// adding the suggestion to the chip list.
  final void Function(int index)? onSuggestionChoosen;

  /// Builder function for creating chip widget representations.
  ///
  /// Required function that defines how each chip appears visually in the input.
  /// Receives the build context and chip data, returning a widget that represents
  /// the chip with appropriate styling and interaction capabilities.
  final ChipWidgetBuilder<T> chipBuilder;

  /// Optional builder function for customizing suggestion list items.
  ///
  /// When provided, suggestions use this builder instead of default presentation.
  /// Allows complete customization of how suggestions appear in the autocomplete popover.
  final ChipWidgetBuilder<T>? suggestionBuilder;

  /// Whether to render selected items as interactive chip widgets.
  ///
  /// Overrides the theme default. When true, selected items appear as dismissible
  /// chips. When false, items appear as simple text tokens.
  final bool? useChips;

  /// Text input action for the text field (e.g., done, next).
  ///
  /// Delegated to the underlying [ChipInput]. Allows customization of the keyboard action button.
  final TextInputAction? textInputAction;

  /// Widget displayed when no chips are selected and no text is entered.
  ///
  /// Provides helpful instructions or context for the user about what to enter.
  /// Typically a Text widget with muted styling.
  final Widget? placeholder;

  /// Builder for leading widget in suggestion list items.
  ///
  /// Delegated to the underlying [ChipInput]. Allows customization of leading content in suggestions.
  final Widget Function(BuildContext, T)? suggestionLeadingBuilder;

  /// Builder for trailing widget in suggestion list items.
  ///
  /// Delegated to the underlying [ChipInput]. Allows customization of trailing content in suggestions.
  final Widget Function(BuildContext, T)? suggestionTrailingBuilder;

  /// Widget displayed at the end of the input field.
  ///
  /// Delegated to the underlying [ChipInput]. Allows adding custom trailing widgets to the input field.
  final Widget? inputTrailingWidget;

  @override
  Widget build(BuildContext context) {
    return ControlledComponentAdapter(
      builder: (context, data) {
        return ChipInput(
          chipBuilder: chipBuilder,
          chips: data.value,
          controller: textEditingController,
          enabled: data.enabled,
          focusNode: focusNode,
          initialText: initialText,
          inputFormatters: inputFormatters,
          inputTrailingWidget: inputTrailingWidget,
          onChanged: data.onChanged,
          onSubmitted: onSubmitted,
          onSuggestionChoosen: onSuggestionChoosen,
          placeholder: placeholder,
          popoverConstraints: popoverConstraints,
          suggestionBuilder: suggestionBuilder,
          suggestionLeadingBuilder: suggestionLeadingBuilder,
          suggestionTrailingBuilder: suggestionTrailingBuilder,
          suggestions: suggestions,
          textInputAction: textInputAction,
          undoHistoryController: undoHistoryController,
          useChips: useChips,
        );
      },
      controller: controller,
      enabled: enabled,
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }
}

class ChipInput<T> extends StatefulWidget {
  const ChipInput({
    required this.chipBuilder,
    this.chips = const [],
    this.controller,
    this.enabled = true,
    this.focusNode,
    this.initialText,
    this.inputFormatters,
    this.inputTrailingWidget,
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.onSuggestionChoosen,
    this.placeholder,
    this.popoverConstraints,
    this.suggestionBuilder,
    this.suggestionLeadingBuilder,
    this.suggestionTrailingBuilder,
    this.suggestions = const [],
    this.textInputAction,
    this.undoHistoryController,
    this.useChips,
  });

  final TextEditingController? controller;
  final BoxConstraints? popoverConstraints;
  final UndoHistoryController? undoHistoryController;
  final ValueChanged<String>? onSubmitted;
  final String? initialText;
  final FocusNode? focusNode;
  final List<T> suggestions;
  final List<T> chips;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(int index)? onSuggestionChoosen;
  final ValueChanged<List<T>>? onChanged;
  final ChipWidgetBuilder<T> chipBuilder;
  final ChipWidgetBuilder<T>? suggestionBuilder;
  final bool? useChips;
  final TextInputAction? textInputAction;
  final Widget? placeholder;
  final Widget Function(BuildContext, T)? suggestionLeadingBuilder;
  final Widget Function(BuildContext, T)? suggestionTrailingBuilder;
  final Widget? inputTrailingWidget;

  final bool enabled;

  @override
  State<ChipInput<T>> createState() => ChipInputState();
}

class ChipInputState<T> extends State<ChipInput<T>>
    with FormValueSupplier<List<T>, ChipInput<T>> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  late ValueNotifier<List<T>> _suggestions;
  final _selectedSuggestions = ValueNotifier<int>(-1);
  final _popoverController = PopoverController();

  final _textFieldKey = GlobalKey();

  BoxConstraints get _popoverConstraints {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<ChipInputTheme>(context);

    return styleValue(
      widgetValue: widget.popoverConstraints,
      themeValue: compTheme?.popoverConstraints,
      defaultValue: BoxConstraints(maxHeight: theme.scaling * 300),
    );
  }

  bool get _useChips {
    final compTheme = ComponentTheme.maybeOf<ChipInputTheme>(context);

    return styleValue(
      widgetValue: widget.useChips,
      themeValue: compTheme?.useChips,
      defaultValue: true,
    );
  }

  @override
  void initState() {
    super.initState();
    _suggestions = ValueNotifier([]);
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();
    _suggestions.addListener(_onSuggestionsChanged);
    _focusNode.addListener(_onFocusChanged);
    if (widget.suggestions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (!mounted) {
          return;
        }
        _suggestions.value = widget.suggestions;
      });
    }
    formValue = widget.chips;
  }

  void _onFocusChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _onSuggestionsChanged();
    });
  }

  void _onSuggestionsChanged() {
    if (_suggestions.value.isEmpty || !_focusNode.hasFocus) {
      _popoverController.close();
    } else if (!_popoverController.hasOpenPopover &&
        _suggestions.value.isNotEmpty) {
      _popoverController.show<void>(
        alignment: Alignment.topCenter,
        builder: buildPopover,
        context: context,
        dismissBackdropFocus: false,
        handler: const PopoverOverlayHandler(),
        hideDuration: Duration.zero,
        offset: Offset(0, Theme.of(context).scaling * 4),
        showDuration: Duration.zero,
        widthConstraint: PopoverConstraint.anchorFixedSize,
      );
    }
  }

  Widget _chipBuilder(int index) {
    return !_useChips
        ? widget.chipBuilder(context, widget.chips[index])
        : Chip(
            trailing: ChipButton(
              onPressed: () {
                final chips = List<T>.of(widget.chips);
                chips.removeAt(index);
                widget.onChanged?.call(chips);
              },
              child: const Icon(LucideIcons.x),
            ),
            child: widget.chipBuilder(context, widget.chips[index]),
          );
  }

  void _handleSubmitted(String text) {
    /// A suggestion is selected, use it.
    if (_selectedSuggestions.value >= 0 &&
        _selectedSuggestions.value < _suggestions.value.length) {
      widget.onSuggestionChoosen?.call(_selectedSuggestions.value);
    } else if (text.isNotEmpty) {
      /// No suggestion selected, use the entered text.
      widget.onSubmitted?.call(text);
    }
    _focusNode.requestFocus();
    _controller.clear();
    _selectedSuggestions.value = -1;
  }

  @override
  void didUpdateWidget(covariant ChipInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {}
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChanged);
    }
    if (!listEquals(widget.suggestions, _suggestions.value)) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _suggestions.value = widget.suggestions;
      });
    }
    if (!listEquals(widget.chips, oldWidget.chips)) {
      formValue = widget.chips;
    }
  }

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  @override
  void didReplaceFormValue(List<T> value) {
    widget.onChanged?.call(value);
  }

  Widget buildPopover(BuildContext context) {
    final theme = Theme.of(context);

    return TextFieldTapRegion(
      child: Data.inherit(
        data: this,
        child: ConstrainedBox(
          constraints: _popoverConstraints,
          child: OutlinedContainer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_suggestions, _selectedSuggestions]),
              builder: (context, child) {
                return ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(theme.scaling * 4),
                  children: [
                    for (int i = 0; i < _suggestions.value.length; i += 1)
                      SelectedButton(
                        value: i == _selectedSuggestions.value,
                        onChanged: (value) {
                          if (value) {
                            widget.onSuggestionChoosen?.call(i);
                            _controller.clear();
                            _selectedSuggestions.value = -1;
                            _popoverController.close();
                          }
                        },
                        child: Row(
                          children: [
                            if (widget.suggestionLeadingBuilder != null) ...[
                              widget.suggestionLeadingBuilder!(
                                context,
                                _suggestions.value[i],
                              ),
                              SizedBox(
                                width: theme.scaling * 10,
                              ), // Add spacing here
                            ],
                            Expanded(
                              child:
                                  widget.suggestionBuilder?.call(
                                    context,
                                    _suggestions.value[i],
                                  ) ??
                                  Text(
                                    _suggestions.value[i].toString(),
                                  ).normal().small(),
                            ),
                            if (widget.suggestionTrailingBuilder != null) ...[
                              SizedBox(
                                width: theme.scaling * 10,
                              ), // Add spacing here
                              widget
                                  .suggestionTrailingBuilder!(
                                    context,
                                    _suggestions.value[i],
                                  )
                                  .normal()
                                  .small(),
                            ],
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _focusNode,
      builder: (context, child) {
        return FocusOutline(
          borderRadius: theme.borderRadiusMd,
          focused: _focusNode.hasFocus,
          child: child!,
        );
      },
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
        },
        child: FocusableActionDetector(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.tab):
                const SelectSuggestionIntent(),
            LogicalKeySet(LogicalKeyboardKey.arrowDown):
                const NextSuggestionIntent(),
            LogicalKeySet(LogicalKeyboardKey.arrowUp):
                const PreviousSuggestionIntent(),
          },
          actions: {
            SelectSuggestionIntent: CallbackAction(
              onInvoke: (intent) {
                final index = _selectedSuggestions.value;
                if (index >= 0 && index < _suggestions.value.length) {
                  widget.onSuggestionChoosen?.call(index);
                  _controller.clear();
                  _selectedSuggestions.value = -1;
                } else if (_suggestions.value.isNotEmpty) {
                  _selectedSuggestions.value = 0;
                }

                return null;
              },
            ),
            NextSuggestionIntent: CallbackAction(
              onInvoke: (intent) {
                final index = _selectedSuggestions.value;
                if (index < _suggestions.value.length - 1) {
                  _selectedSuggestions.value = index + 1;
                } else if (_suggestions.value.isNotEmpty) {
                  _selectedSuggestions.value = 0;
                }

                return null;
              },
            ),
            PreviousSuggestionIntent: CallbackAction(
              onInvoke: (intent) {
                final index = _selectedSuggestions.value;
                if (index > 0) {
                  _selectedSuggestions.value = index - 1;
                } else if (_suggestions.value.isNotEmpty) {
                  _selectedSuggestions.value = _suggestions.value.length - 1;
                }

                return null;
              },
            ),
          },
          mouseCursor: SystemMouseCursors.text,
          child: AnimatedBuilder(
            animation: _focusNode,
            builder: (context, child) {
              if (widget.chips.isNotEmpty) {
                child = _focusNode.hasFocus
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          child!,
                          Wrap(
                            spacing: theme.scaling * 4,
                            runSpacing: theme.scaling * 4,
                            children: [
                              for (int i = 0; i < widget.chips.length; i += 1)
                                _chipBuilder(i),
                            ],
                          ).withPadding(
                            bottom: theme.scaling * 4,
                            left: theme.scaling * 6,
                            right: theme.scaling * 6,
                          ),
                        ],
                      )
                    : Stack(
                        alignment: AlignmentDirectional.centerStart,
                        children: [
                          Visibility(
                            visible: false,
                            maintainState: true,
                            maintainAnimation: true,
                            maintainSize: true,
                            maintainSemantics: true,
                            maintainInteractivity: true,
                            child: child!,
                          ),
                          Wrap(
                            spacing: theme.scaling * 4,
                            runSpacing: theme.scaling * 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (int i = 0; i < widget.chips.length; i += 1)
                                _chipBuilder(i),
                              if (_controller.text.isNotEmpty) const Gap(4),
                              if (_controller.text.isNotEmpty)
                                Text(_controller.text).base(),
                            ],
                          ).withPadding(
                            horizontal: theme.scaling * 6,
                            vertical: theme.scaling * 4,
                          ),
                        ],
                      );
              }

              return TextFieldTapRegion(
                child: OutlinedContainer(
                  backgroundColor: theme.colorScheme.input.scaleAlpha(0.3),
                  borderColor: theme.colorScheme.border,
                  borderRadius: theme.borderRadiusMd,
                  child: Row(
                    children: [
                      Expanded(child: child!),
                      if (widget.inputTrailingWidget != null) ...[
                        const VerticalDivider(endIndent: 10, indent: 10),
                        widget.inputTrailingWidget!,
                      ],
                    ],
                  ),
                ),
              );
            },
            child: ComponentTheme(
              data: const FocusOutlineTheme(
                border: Border.fromBorderSide(BorderSide.none),
              ),
              child: TextField(
                key: _textFieldKey,
                border: const Border.fromBorderSide(BorderSide.none),
                controller: _controller,
                decoration: const BoxDecoration(),
                enabled: widget.enabled,
                focusNode: _focusNode,
                initialValue: widget.initialText,
                inputFormatters: widget.inputFormatters,
                onSubmitted: _handleSubmitted,
                placeholder: widget.placeholder,
                textInputAction: widget.textInputAction,
                undoController: widget.undoHistoryController,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectSuggestionIntent extends Intent {
  const SelectSuggestionIntent();
}

class NextSuggestionIntent extends Intent {
  const NextSuggestionIntent();
}

class PreviousSuggestionIntent extends Intent {
  const PreviousSuggestionIntent();
}
