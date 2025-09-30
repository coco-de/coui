import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/control/hover.dart';

/// Theme data for customizing [Select] widget appearance and behavior.
///
/// This class defines the visual and behavioral properties that can be applied to
/// [Select] widgets, including popup constraints, positioning, styling, and
/// interaction behaviors. These properties can be set at the theme level
/// to provide consistent behavior across the application.
class SelectTheme {
  const SelectTheme({
    this.autoClosePopover,
    this.borderRadius,
    this.canUnselect,
    this.disableHoverEffect,
    this.padding,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popupConstraints,
  });

  final BoxConstraints? popupConstraints;
  final AlignmentGeometry? popoverAlignment;
  final AlignmentGeometry? popoverAnchorAlignment;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool? disableHoverEffect;
  final bool? canUnselect;

  final bool? autoClosePopover;

  @override
  bool operator ==(Object other) {
    return other is SelectTheme &&
        other.popupConstraints == popupConstraints &&
        other.popoverAlignment == popoverAlignment &&
        other.popoverAnchorAlignment == popoverAnchorAlignment &&
        other.borderRadius == borderRadius &&
        other.padding == padding &&
        other.disableHoverEffect == disableHoverEffect &&
        other.canUnselect == canUnselect &&
        other.autoClosePopover == autoClosePopover;
  }

  @override
  int get hashCode => Object.hash(
    popupConstraints,
    popoverAlignment,
    popoverAnchorAlignment,
    borderRadius,
    padding,
    disableHoverEffect,
    canUnselect,
    autoClosePopover,
  );
}

/// Controller for managing [ControlledSelect] state programmatically.
///
/// Extends [ValueNotifier] to provide reactive state management for select
/// components. Can be used to programmatically change selection, listen to
/// state changes, and integrate with forms and other reactive systems.
///
/// Example:
/// ```dart
/// final controller = SelectController<String>('initial');
///
/// // Listen to changes
/// controller.addListener(() {
///   print('Selection changed to: ${controller.value}');
/// });
///
/// // Update selection
/// controller.value = 'new_value';
/// ```
class SelectController<T> extends ValueNotifier<T?>
    with ComponentController<T?> {
  /// Creates a [SelectController] with an optional initial value.
  ///
  /// The [value] parameter sets the initial selected item. Can be null
  /// to start with no selection.
  ///
  /// Parameters:
  /// - [value] (T?, optional): Initial selected value
  SelectController([super.value]);
}

/// Reactive single-selection dropdown with automatic state management.
///
/// A high-level select widget that provides automatic state management through
/// the controlled component pattern. Supports both controller-based and callback-based
/// state management with comprehensive customization options for item presentation,
/// popup behavior, and interaction handling.
///
/// ## Features
///
/// - **Flexible item rendering**: Custom builders for complete visual control over items
/// - **Popup positioning**: Configurable alignment and constraints for the dropdown
/// - **Keyboard navigation**: Full keyboard support with arrow keys and Enter/Escape
/// - **Form integration**: Automatic validation and form field registration
/// - **Unselection support**: Optional ability to deselect the current selection
///
/// ## Usage Patterns
///
/// **Controller-based (recommended for complex state):**
/// ```dart
/// final controller = SelectController<String>('apple');
///
/// ControlledSelect<String>(
///   controller: controller,
///   items: ['apple', 'banana', 'cherry'],
///   itemBuilder: (context, item) => Text(item),
///   placeholder: Text('Choose fruit'),
/// )
/// ```
///
/// **Callback-based (simple state management):**
/// ```dart
/// String? selectedFruit;
///
/// ControlledSelect<String>(
///   initialValue: selectedFruit,
///   onChanged: (fruit) => setState(() => selectedFruit = fruit),
///   items: ['apple', 'banana', 'cherry'],
///   itemBuilder: (context, item) => Text(item),
/// )
/// ```
class ControlledSelect<T> extends StatelessWidget
    with ControlledComponent<T?>, SelectBase<T> {
  /// Creates a [ControlledSelect].
  ///
  /// Either [controller] or [onChanged] should be provided for interactivity.
  /// The widget supports both controller-based and callback-based state management
  /// patterns depending on application architecture needs.
  ///
  /// Parameters:
  /// - [controller] (SelectController<T>?, optional): external state controller
  /// - [initialValue] (T?, optional): starting selection when no controller
  /// - [onChanged] (ValueChanged<T?>?, optional): selection change callback
  /// - [enabled] (bool, default: true): whether select is interactive
  /// - [placeholder] (Widget?, optional): widget shown when no item selected
  /// - [filled] (bool, default: false): whether to use filled appearance
  /// - [focusNode] (FocusNode?, optional): custom focus node for keyboard handling
  /// - [constraints] (BoxConstraints?, optional): size constraints for select widget
  /// - [popupConstraints] (BoxConstraints?, optional): size constraints for popup
  /// - [popupWidthConstraint] (PopoverConstraint, default: anchorFixedSize): popup width behavior
  /// - [borderRadius] (BorderRadiusGeometry?, optional): override select border radius
  /// - [padding] (EdgeInsetsGeometry?, optional): override internal padding
  /// - [popoverAlignment] (AlignmentGeometry, default: topCenter): popup alignment
  /// - [popoverAnchorAlignment] (AlignmentGeometry?, optional): anchor alignment
  /// - [disableHoverEffect] (bool, default: false): disable item hover effects
  /// - [canUnselect] (bool, default: false): allow deselecting current item
  /// - [autoClosePopover] (bool, default: true): close popup after selection
  /// - [popup] (SelectPopupBuilder, required): builder for popup content
  /// - [itemBuilder] (SelectItemBuilder<T>, required): builder for individual items
  /// - [valueSelectionHandler] (SelectValueSelectionHandler<T>?, optional): custom selection logic
  /// - [valueSelectionPredicate] (SelectValueSelectionPredicate<T>?, optional): selection validation
  /// - [showValuePredicate] (Predicate<T>?, optional): visibility filter for values
  ///
  /// Example:
  /// ```dart
  /// ControlledSelect<String>(
  ///   controller: controller,
  ///   popup: (context, items) => ListView(children: items),
  ///   itemBuilder: (context, item, selected) => Text(item),
  ///   placeholder: Text('Select option'),
  /// )
  /// ```
  const ControlledSelect({
    this.autoClosePopover = true,
    this.borderRadius,
    this.canUnselect = false,
    this.constraints,
    this.controller,
    this.disableHoverEffect = false,
    this.enabled = true,
    this.filled = false,
    this.focusNode,
    this.initialValue,
    required this.itemBuilder,
    super.key,
    this.onChanged,
    this.padding,
    this.placeholder,
    this.popoverAlignment = Alignment.topCenter,
    this.popoverAnchorAlignment,
    required this.popup,
    this.popupConstraints,
    this.popupWidthConstraint = PopoverConstraint.anchorFixedSize,
    this.showValuePredicate,
    this.valueSelectionHandler,
    this.valueSelectionPredicate,
  });

  @override
  final T? initialValue;
  @override
  final ValueChanged<T?>? onChanged;
  @override
  final bool enabled;

  @override
  final SelectController<T>? controller;
  @override
  final Widget? placeholder;
  @override
  final bool filled;
  @override
  final FocusNode? focusNode;
  @override
  final BoxConstraints? constraints;
  @override
  final BoxConstraints? popupConstraints;
  @override
  final PopoverConstraint popupWidthConstraint;
  @override
  final BorderRadiusGeometry? borderRadius;
  @override
  final EdgeInsetsGeometry? padding;
  @override
  final AlignmentGeometry popoverAlignment;
  @override
  final AlignmentGeometry? popoverAnchorAlignment;
  @override
  final bool disableHoverEffect;
  @override
  final bool canUnselect;
  @override
  final bool autoClosePopover;
  @override
  final SelectPopupBuilder popup;
  @override
  final SelectValueBuilder<T> itemBuilder;
  @override
  final SelectValueSelectionHandler<T>? valueSelectionHandler;
  @override
  final SelectValueSelectionPredicate<T>? valueSelectionPredicate;

  @override
  final Predicate<T>? showValuePredicate;

  @override
  Widget build(BuildContext context) {
    return ControlledComponentAdapter<T?>(
      builder: (context, data) {
        return Select<T>(
          autoClosePopover: autoClosePopover,
          borderRadius: borderRadius,
          canUnselect: canUnselect,
          constraints: constraints,
          disableHoverEffect: disableHoverEffect,
          enabled: data.enabled,
          filled: filled,
          focusNode: focusNode,
          itemBuilder: itemBuilder,
          onChanged: data.onChanged,
          padding: padding,
          placeholder: placeholder,
          popoverAlignment: popoverAlignment,
          popoverAnchorAlignment: popoverAnchorAlignment,
          popup: popup,
          popupConstraints: popupConstraints,
          popupWidthConstraint: popupWidthConstraint,
          showValuePredicate: showValuePredicate,
          value: data.value,
          valueSelectionHandler: valueSelectionHandler,
          valueSelectionPredicate: valueSelectionPredicate,
        );
      },
      controller: controller,
      enabled: enabled,
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }
}

/// Controller for managing [ControlledMultiSelect] state programmatically.
///
/// Extends [SelectController] to provide reactive state management for multi-selection
/// components. Manages a collection of selected items with methods for adding,
/// removing, and bulk operations.
///
/// Example:
/// ```dart
/// final controller = MultiSelectController<String>(['apple', 'banana']);
///
/// // Listen to changes
/// controller.addListener(() {
///   print('Selection changed to: ${controller.value}');
/// });
///
/// // Update selection
/// controller.value = ['apple', 'cherry'];
/// ```
class MultiSelectController<T> extends SelectController<Iterable<T>> {}

class SelectItemButton<T> extends StatelessWidget {
  const SelectItemButton({
    required this.child,
    this.enabled,
    super.key,
    this.style = const ButtonStyle.ghost(),
    required this.value,
  });

  final T value;
  final Widget child;
  final AbstractButtonStyle style;

  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final data = Data.maybeOf<SelectPopupHandle>(context);
    final isSelected = data?.isSelected(value) ?? false;
    final hasSelection = data?.hasSelection ?? false;

    return Actions(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            data?.selectItem(value, !isSelected);

            return null;
          },
        ),
      },
      child: SubFocus(
        builder: (context, subFocusState) {
          return WidgetStatesProvider(
            states: {if (subFocusState.isFocused) WidgetState.hovered},
            child: Button(
              alignment: AlignmentDirectional.centerStart,
              disableTransition: true,
              enabled: enabled,
              onPressed: () {
                data?.selectItem(value, !isSelected);
              },
              style: style.copyWith(
                mouseCursor: (context, states, value) {
                  return SystemMouseCursors.basic;
                },
                padding: (context, states, value) => EdgeInsets.symmetric(
                  horizontal: scaling * 8,
                  vertical: scaling * 8,
                ),
              ),
              trailing: isSelected
                  ? const Icon(LucideIcons.check).iconSmall()
                  : hasSelection
                  ? SizedBox(width: scaling * 16)
                  : null,
              child: child.normal(),
            ),
          );
        },
      ),
    );
  }
}

class SelectGroup extends StatelessWidget {
  const SelectGroup({
    required this.children,
    this.footers,
    this.headers,
    super.key,
  });

  final List<Widget>? headers;
  final List<Widget> children;

  final List<Widget>? footers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (headers != null) ...headers!,
        ...children,
        if (footers != null) ...footers!,
      ],
    );
  }
}

class SelectLabel extends StatelessWidget {
  const SelectLabel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return Padding(
      padding: const EdgeInsets.all(8) * scaling,
      child: child.semiBold().small(),
    );
  }
}

typedef SelectPopupBuilder = Widget Function(BuildContext context);
typedef SelectValueBuilder<T> = Widget Function(BuildContext context, T value);
typedef SelectValueSelectionHandler<T> =
    T? Function(T? oldValue, bool selected, Object? value);
typedef SelectValueSelectionPredicate<T> =
    bool Function(Object? test, T? value);

T? _defaultSingleSelectValueSelectionHandler<T>(
  T? oldValue,
  Object? value,
  bool selected,
) {
  if (value is! T?) {
    return null;
  }

  return selected ? value : null;
}

bool _defaultSingleSelectValueSelectionPredicate<T>(T? value, Object? test) {
  return value == test;
}

Iterable<T>? _defaultMultiSelectValueSelectionHandler<T>(
  Iterable<T>? oldValue,
  Object? newValue,
  bool selected,
) {
  if (newValue == null) {
    return null;
  }
  final wrappedNewValue = [newValue as T];
  if (oldValue == null) {
    return selected ? wrappedNewValue : null;
  }
  if (selected) {
    return oldValue.followedBy(wrappedNewValue);
  }
  final newIterable = oldValue.where((element) => element != newValue);

  return newIterable.isEmpty ? null : newIterable;
}

bool _defaultMultiSelectValueSelectionPredicate<T>(
  Iterable<T>? value,
  Object? test,
) {
  if (value == null) {
    return test == null;
  }

  return test == null ? false : value.contains(test);
}

mixin SelectBase<T> {
  ValueChanged<T?>? get onChanged;
  Widget? get placeholder;
  bool get filled;
  FocusNode? get focusNode;
  BoxConstraints? get constraints;
  BoxConstraints? get popupConstraints;
  PopoverConstraint get popupWidthConstraint;
  BorderRadiusGeometry? get borderRadius;
  EdgeInsetsGeometry? get padding;
  AlignmentGeometry get popoverAlignment;
  AlignmentGeometry? get popoverAnchorAlignment;
  bool get disableHoverEffect;
  bool get canUnselect;
  bool? get autoClosePopover;
  SelectPopupBuilder get popup;
  SelectValueBuilder<T> get itemBuilder;
  SelectValueSelectionHandler<T>? get valueSelectionHandler;
  SelectValueSelectionPredicate<T>? get valueSelectionPredicate;
  Predicate<T>? get showValuePredicate;
}

/// A customizable dropdown selection widget for single-value selection.
///
/// [Select] provides a comprehensive dropdown selection experience with support for
/// custom item rendering, keyboard navigation, search functionality, and extensive
/// customization options. It displays a trigger button that opens a popup containing
/// selectable options when activated.
///
/// Key features:
/// - Single-value selection with optional null/unselect capability
/// - Customizable item rendering through builder functions
/// - Keyboard navigation and accessibility support
/// - Configurable popup positioning and constraints
/// - Search and filtering capabilities
/// - Focus management and interaction handling
/// - Theming and visual customization
/// - Form integration and validation support
///
/// The widget supports various configuration modes:
/// - Filled or outlined appearance styles
/// - Custom popup positioning and alignment
/// - Conditional item visibility and selection
/// - Hover effects and interaction feedback
/// - Auto-closing popup behavior
///
/// Selection behavior can be customized through:
/// - [valueSelectionHandler]: Custom logic for handling selection
/// - [valueSelectionPredicate]: Conditions for allowing selection
/// - [showValuePredicate]: Conditions for displaying items
/// - [canUnselect]: Whether to allow deselecting the current value
///
/// Example:
/// ```dart
/// Select<String>(
///   value: selectedItem,
///   placeholder: Text('Choose an option'),
///   onChanged: (value) => setState(() => selectedItem = value),
///   popup: SelectPopup.menu(
///     children: [
///       SelectItem(value: 'option1', child: Text('Option 1')),
///       SelectItem(value: 'option2', child: Text('Option 2')),
///       SelectItem(value: 'option3', child: Text('Option 3')),
///     ],
///   ),
/// );
/// ```
class Select<T> extends StatefulWidget with SelectBase<T> {
  const Select({
    this.autoClosePopover = true,
    this.borderRadius,
    this.canUnselect = false,
    this.constraints,
    this.disableHoverEffect = false,
    this.enabled,
    this.filled = false,
    this.focusNode,
    required this.itemBuilder,
    super.key,
    this.onChanged,
    this.padding,
    this.placeholder,
    this.popoverAlignment = Alignment.topCenter,
    this.popoverAnchorAlignment,
    required this.popup,
    this.popupConstraints,
    this.popupWidthConstraint = PopoverConstraint.anchorFixedSize,
    this.showValuePredicate,
    this.value,
    this.valueSelectionHandler,
    this.valueSelectionPredicate,
  });

  /// Default maximum height for select popups in logical pixels.
  static const kDefaultSelectMaxHeight = 240.0;
  @override
  final ValueChanged<T?>? onChanged; // if null, then it's a disabled combobox
  @override
  final Widget? placeholder; // placeholder when value is null
  @override
  final bool filled;
  @override
  final FocusNode? focusNode;
  @override
  final BoxConstraints? constraints;
  @override
  final BoxConstraints? popupConstraints;
  @override
  final PopoverConstraint popupWidthConstraint;
  final T? value;
  @override
  final BorderRadiusGeometry? borderRadius;
  @override
  final EdgeInsetsGeometry? padding;
  @override
  final AlignmentGeometry popoverAlignment;
  @override
  final AlignmentGeometry? popoverAnchorAlignment;
  @override
  final bool disableHoverEffect;
  @override
  final bool canUnselect;
  @override
  final bool? autoClosePopover;
  final bool? enabled;
  @override
  final SelectPopupBuilder popup;
  @override
  final SelectValueBuilder<T> itemBuilder;
  @override
  final SelectValueSelectionHandler<T>? valueSelectionHandler;
  @override
  final SelectValueSelectionPredicate<T>? valueSelectionPredicate;

  @override
  final Predicate<T>? showValuePredicate;

  @override
  SelectState<T> createState() => SelectState();
}

class SelectState<T> extends State<Select<T>>
    with FormValueSupplier<T, Select<T>> {
  FocusNode _focusNode;
  final _popoverController = PopoverController();
  ValueNotifier<T?> _valueNotifier;

  SelectTheme? _theme;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _valueNotifier = ValueNotifier(widget.value);
    formValue = widget.value;
  }

  BoxDecoration _overrideBorderRadius(
    BuildContext context,
    Set<WidgetState> states,
    Decoration value,
  ) {
    return (value as BoxDecoration).copyWith(borderRadius: _borderRadius);
  }

  EdgeInsetsGeometry _overridePadding(
    BuildContext context,
    Set<WidgetState> states,
    EdgeInsetsGeometry value,
  ) {
    return _padding!;
  }

  bool _onChanged(Object? value, bool selected) {
    if (!selected && !_canUnselect) {
      return false;
    }
    final selectionHandler =
        widget.valueSelectionHandler ??
        _defaultSingleSelectValueSelectionHandler;
    final newValue = selectionHandler(widget.value, value, selected);
    widget.onChanged?.call(newValue);

    return true;
  }

  bool _isSelected(Object? value) {
    final selectionPredicate =
        widget.valueSelectionPredicate ??
        _defaultSingleSelectValueSelectionPredicate;

    return selectionPredicate(widget.value, value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = ComponentTheme.maybeOf<SelectTheme>(context);
  }

  @override
  void didUpdateWidget(Select<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.value != oldWidget.value) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _valueNotifier.value = widget.value;
      });
      formValue = widget.value;
    } else if (widget.valueSelectionPredicate !=
        oldWidget.valueSelectionPredicate) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _valueNotifier.value = widget.value;
      });
    }
    if (widget.enabled != oldWidget.enabled ||
        widget.onChanged != oldWidget.onChanged) {
      final enabled = widget.enabled ?? widget.onChanged != null;
      if (!enabled) {
        _focusNode.unfocus();
        _popoverController.close();
      }
    }
  }

  @override
  void didReplaceFormValue(T value) {
    widget.onChanged?.call(value);
  }

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  BoxConstraints? get _popupConstraints => styleValue(
    defaultValue: null,
    themeValue: _theme?.popupConstraints,
    widgetValue: widget.popupConstraints,
  );

  AlignmentGeometry get _popoverAlignment => styleValue(
    defaultValue: Alignment.topCenter,
    themeValue: _theme?.popoverAlignment,
    widgetValue: widget.popoverAlignment,
  );

  AlignmentGeometry? get _popoverAnchorAlignment => styleValue(
    defaultValue: null,
    themeValue: _theme?.popoverAnchorAlignment,
    widgetValue: widget.popoverAnchorAlignment,
  );

  BorderRadiusGeometry? get _borderRadius => styleValue(
    defaultValue: null,
    themeValue: _theme?.borderRadius,
    widgetValue: widget.borderRadius,
  );

  EdgeInsetsGeometry? get _padding => styleValue(
    defaultValue: null,
    themeValue: _theme?.padding,
    widgetValue: widget.padding,
  );

  bool get _disableHoverEffect => styleValue(
    defaultValue: false,
    themeValue: _theme?.disableHoverEffect,
    widgetValue: widget.disableHoverEffect,
  );

  bool get _canUnselect => styleValue(
    defaultValue: false,
    themeValue: _theme?.canUnselect,
    widgetValue: widget.canUnselect,
  );

  bool get _autoClosePopover => styleValue(
    defaultValue: true,
    themeValue: _theme?.autoClosePopover,
    widgetValue: widget.autoClosePopover,
  );

  Widget get _placeholder {
    return widget.placeholder != null ? widget.placeholder! : const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final enabled = widget.enabled ?? widget.onChanged != null;

    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: widget.constraints ?? const BoxConstraints(),
        child: TapRegion(
          onTapOutside: (event) {
            _focusNode.unfocus();
          },
          child: Button(
            disableHoverEffect: _disableHoverEffect,
            enabled: enabled,
            focusNode: _focusNode,
            onPressed: widget.onChanged == null
                ? null
                : () {
                    // to prevent entire ListView from rebuilding
                    // while the Data<SelectData> is being updated
                    final popupKey = GlobalKey();
                    _popoverController
                        .show(
                          alignment: _popoverAlignment,
                          anchorAlignment: _popoverAnchorAlignment,
                          builder: (context) {
                            return ConstrainedBox(
                              constraints:
                                  _popupConstraints ??
                                  BoxConstraints(
                                    maxHeight:
                                        Select.kDefaultSelectMaxHeight *
                                        scaling,
                                  ),
                              child: ListenableBuilder(
                                builder: (context, _) {
                                  return Data.inherit(
                                    key: ValueKey(widget.value),
                                    data: SelectData(
                                      autoClose: _autoClosePopover,
                                      enabled: enabled,
                                      hasSelection: widget.value != null,
                                      isSelected: _isSelected,
                                      onChanged: _onChanged,
                                    ),
                                    child: Builder(
                                      key: popupKey,
                                      builder: (context) {
                                        return widget.popup(context);
                                      },
                                    ),
                                  );
                                },
                                listenable: _valueNotifier,
                              ),
                            );
                          },
                          context: context,
                          offset: Offset(0, scaling * 8),
                          overlayBarrier: OverlayBarrier(
                            borderRadius: BorderRadius.circular(theme.radiusLg),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8) *
                                scaling,
                          ),
                          widthConstraint: widget.popupWidthConstraint,
                        )
                        .then((value) {
                          _focusNode.requestFocus();
                        });
                  },
            style:
                (widget.filled
                        ? ButtonVariance.secondary
                        : ButtonVariance.outline)
                    .copyWith(
                      decoration: _borderRadius == null
                          ? null
                          : _overrideBorderRadius,
                      padding: _padding == null ? null : _overridePadding,
                    ),
            child: WidgetStatesProvider.boundary(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Data.inherit(
                    data: SelectData(
                      autoClose: _autoClosePopover,
                      enabled: enabled,
                      hasSelection: widget.value != null,
                      isSelected: _isSelected,
                      onChanged: _onChanged,
                    ),
                    child: Expanded(
                      child:
                          widget.value != null &&
                              (widget.showValuePredicate?.call(
                                    widget.value as T,
                                  ) ??
                                  true)
                          ? Builder(
                              builder: (context) {
                                return widget.itemBuilder(
                                  context,
                                  widget.value as T,
                                );
                              },
                            )
                          : _placeholder,
                    ),
                  ),
                  SizedBox(width: scaling * 8),
                  IconTheme.merge(
                    data: IconThemeData(
                      color: theme.colorScheme.foreground,
                      opacity: 0.5,
                    ),
                    child: const Icon(LucideIcons.chevronsUpDown).iconSmall(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip widget designed for multi-select contexts with automatic removal functionality.
///
/// A specialized chip widget that integrates with multi-select components to display
/// selected items with built-in removal capabilities. Automatically detects its
/// multi-select context and provides appropriate removal behavior.
///
/// ## Features
///
/// - **Context-aware removal**: Automatically integrates with parent multi-select state
/// - **Visual feedback**: Clear visual indication of selected state
/// - **Interactive deletion**: Built-in X button for removing selections
/// - **Consistent styling**: Matches multi-select component design patterns
/// - **Accessibility**: Full screen reader support for selection management
///
/// This widget is typically used within multi-select components to represent
/// individual selected items with the ability to remove them from the selection.
///
/// Example:
/// ```dart
/// MultiSelectChip(
///   value: 'apple',
///   child: Text('Apple'),
///   style: ButtonStyle.secondary(),
/// );
/// ```
class MultiSelectChip extends StatelessWidget {
  /// Creates a [MultiSelectChip].
  ///
  /// Designed to be used within multi-select components where it automatically
  /// integrates with the parent selection state for removal functionality.
  ///
  /// Parameters:
  /// - [value] (Object?, required): the value this chip represents in the selection
  /// - [child] (Widget, required): content displayed inside the chip
  /// - [style] (AbstractButtonStyle, default: primary): chip styling
  ///
  /// Example:
  /// ```dart
  /// MultiSelectChip(
  ///   value: user.id,
  ///   child: Row(
  ///     children: [
  ///       Avatar(user: user),
  ///       Text(user.name),
  ///     ],
  ///   ),
  ///   style: ButtonStyle.secondary(),
  /// )
  /// ```
  const MultiSelectChip({
    required this.child,
    super.key,
    this.style = const ButtonStyle.primary(),
    required this.value,
  });

  final Object? value;
  final Widget child;

  final AbstractButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final data = Data.maybeOf<SelectData>(context);

    return Chip(
      style: style,
      trailing: data?.enabled == false
          ? null
          : ChipButton(
              onPressed: () {
                data?.onChanged(value, false);
              },
              child: const Icon(LucideIcons.x).iconSmall(),
            ),
      child: child,
    );
  }
}

class MultiSelect<T> extends StatelessWidget with SelectBase<Iterable<T>> {
  const MultiSelect({
    this.autoClosePopover = false,
    this.borderRadius,
    this.canUnselect = true,
    this.constraints,
    this.disableHoverEffect = false,
    this.enabled,
    this.filled = false,
    this.focusNode,
    required SelectValueBuilder<T> itemBuilder,
    super.key,
    this.onChanged,
    this.padding,
    this.placeholder,
    this.popoverAlignment = Alignment.topCenter,
    this.popoverAnchorAlignment,
    required this.popup,
    this.popupConstraints,
    this.popupWidthConstraint = PopoverConstraint.anchorFixedSize,
    this.showValuePredicate,
    required this.value,
    this.valueSelectionHandler,
    this.valueSelectionPredicate,
  }) : multiItemBuilder = itemBuilder;

  static Widget _buildItem<T>(
    BuildContext context,
    SelectValueBuilder<T> multiItemBuilder,
    Iterable<T> value,
  ) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: scaling * 4,
      spacing: scaling * 4,
      children: [for (final value in value) multiItemBuilder(context, value)],
    );
  }

  @override
  final ValueChanged<Iterable<T>?>? onChanged; // if null, then it's a disabled combobox
  @override
  final Widget? placeholder; // placeholder when value is null
  @override
  final bool filled;
  @override
  final FocusNode? focusNode;
  @override
  final BoxConstraints? constraints;
  @override
  final BoxConstraints? popupConstraints;
  @override
  final PopoverConstraint popupWidthConstraint;
  final Iterable<T>? value;
  @override
  final BorderRadiusGeometry? borderRadius;
  @override
  final EdgeInsetsGeometry? padding;
  @override
  final AlignmentGeometry popoverAlignment;
  @override
  final AlignmentGeometry? popoverAnchorAlignment;
  @override
  final bool disableHoverEffect;
  @override
  final bool canUnselect;
  @override
  final bool? autoClosePopover;
  final bool? enabled;
  @override
  final SelectPopupBuilder popup;
  @override
  final SelectValueSelectionHandler<Iterable<T>>? valueSelectionHandler;
  @override
  final SelectValueSelectionPredicate<Iterable<T>>? valueSelectionPredicate;
  final SelectValueBuilder<T> multiItemBuilder;

  @override
  final Predicate<Iterable<T>>? showValuePredicate;

  @override
  SelectValueBuilder<Iterable<T>> get itemBuilder => (context, value) {
    return _buildItem(multiItemBuilder, context, value);
  };

  @override
  Widget build(BuildContext context) {
    return Select<Iterable<T>>(
      autoClosePopover: autoClosePopover ?? true,
      borderRadius: borderRadius,
      canUnselect: canUnselect,
      constraints: constraints,
      disableHoverEffect: disableHoverEffect,
      enabled: enabled,
      filled: filled,
      focusNode: focusNode,
      itemBuilder: itemBuilder,
      onChanged: onChanged,
      padding: padding,
      placeholder: placeholder,
      popoverAlignment: popoverAlignment,
      popoverAnchorAlignment: popoverAnchorAlignment,
      popup: popup,
      popupConstraints: popupConstraints,
      popupWidthConstraint: popupWidthConstraint,
      showValuePredicate: (test) {
        return test.isNotEmpty && (showValuePredicate?.call(test) ?? true);
      },
      value: value,
      valueSelectionHandler:
          valueSelectionHandler ?? _defaultMultiSelectValueSelectionHandler,
      valueSelectionPredicate:
          valueSelectionPredicate ?? _defaultMultiSelectValueSelectionPredicate,
    );
  }
}

typedef SelectValueChanged<T> = bool Function(bool selected, T value);

class SelectData {
  const SelectData({
    required this.autoClose,
    required this.enabled,
    required this.hasSelection,
    required this.isSelected,
    required this.onChanged,
  });

  final bool? autoClose;
  final Predicate<Object?> isSelected;
  final SelectValueChanged<Object?> onChanged;
  final bool hasSelection;

  final bool enabled;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SelectData) return false;

    return other.isSelected == isSelected &&
        other.onChanged == onChanged &&
        other.hasSelection == hasSelection &&
        other.autoClose == autoClose &&
        other.enabled == enabled;
  }

  @override
  int get hashCode =>
      Object.hash(isSelected, onChanged, autoClose, hasSelection, enabled);
}

typedef SelectItemsBuilder =
    FutureOr<SelectItemDelegate> Function(
      BuildContext context,
      String? searchQuery,
    );

class SelectPopup<T> extends StatefulWidget {
  const SelectPopup({
    this.autoClose,
    this.emptyBuilder,
    this.errorBuilder,
    this.items,
    super.key,
    this.loadingBuilder,
    this.scrollController,
    this.searchController,
    this.searchPlaceholder,
    this.shrinkWrap = true,
    this.surfaceBlur,
    this.surfaceOpacity,
  }) : builder = null,
       enableSearch = false,
       disableVirtualization = false;

  const SelectPopup.builder({
    this.autoClose,
    required this.builder,
    this.emptyBuilder,
    this.enableSearch = true,
    this.errorBuilder,
    super.key,
    this.loadingBuilder,
    this.scrollController,
    this.searchController,
    this.searchPlaceholder,
    this.surfaceBlur,
    this.surfaceOpacity,
  }) : items = null,
       shrinkWrap = false,
       disableVirtualization = false;

  const SelectPopup.noVirtualization({
    this.autoClose,
    this.emptyBuilder,
    this.errorBuilder,
    FutureOr<SelectItemList?>? this.items,
    super.key,
    this.loadingBuilder,
    this.scrollController,
    this.searchController,
    this.searchPlaceholder,
    this.surfaceBlur,
    this.surfaceOpacity,
  }) : builder = null,
       enableSearch = false,
       disableVirtualization = true,
       shrinkWrap = false;

  final SelectItemsBuilder<T>? builder;
  final FutureOr<SelectItemDelegate?>? items;
  final TextEditingController? searchController;
  final Widget? searchPlaceholder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? loadingBuilder;
  final ErrorWidgetBuilder? errorBuilder;
  final double? surfaceBlur;
  final double? surfaceOpacity;
  final bool? autoClose;
  final bool enableSearch;

  final ScrollController? scrollController;

  final bool shrinkWrap;

  final bool disableVirtualization;

  @override
  State<SelectPopup<T>> createState() => _SelectPopupState<T>();
}

mixin SelectPopupHandle {
  bool isSelected(Object? value);

  void selectItem(bool selected, Object? value);
  bool get hasSelection;
}

class _SelectPopupState<T> extends State<SelectPopup<T>>
    with SelectPopupHandle {
  TextEditingController _searchController;
  ScrollController _scrollController;
  SelectData? _selectData;

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
    _scrollController = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // because the controller did not get notified when a scroll position is attached
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant SelectPopup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchController != oldWidget.searchController) {
      _searchController = widget.searchController ?? TextEditingController();
    }
    if (widget.scrollController != oldWidget.scrollController) {
      _scrollController = widget.scrollController ?? ScrollController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectData = Data.maybeOf<SelectData>(context);
  }

  @override
  bool get hasSelection => _selectData?.hasSelection ?? false;

  @override
  bool isSelected(Object? value) {
    return _selectData?.isSelected(value) ?? false;
  }

  @override
  void selectItem(bool selected, Object? value) {
    _selectData?.onChanged(value, selected);
    if (widget.autoClose ?? _selectData?.autoClose ?? false) {
      closeOverlay(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return SubFocusScope(
      builder: (context, subFocusScope) {
        return Actions(
          actions: {
            NextItemIntent: CallbackAction<NextItemIntent>(
              onInvoke: (intent) {
                subFocusScope.nextFocus();

                return null;
              },
            ),
            PreviousItemIntent: CallbackAction<PreviousItemIntent>(
              onInvoke: (intent) {
                subFocusScope.nextFocus(TraversalDirection.up);

                return null;
              },
            ),
            CloseMenuIntent: CallbackAction<CloseMenuIntent>(
              onInvoke: (intent) {
                closeOverlay(context);

                return null;
              },
            ),
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                subFocusScope.invokeActionOnFocused(intent);

                return null;
              },
            ),
          },
          child: Shortcuts(
            shortcuts: {
              LogicalKeySet(LogicalKeyboardKey.tab): const NextItemIntent(),
              LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab):
                  const PreviousItemIntent(),
              LogicalKeySet(LogicalKeyboardKey.escape): const CloseMenuIntent(),
              LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
              LogicalKeySet(LogicalKeyboardKey.numpadEnter):
                  const ActivateIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowDown):
                  const NextItemIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowUp):
                  const PreviousItemIntent(),
            },
            child: Focus(
              autofocus: !widget
                  .enableSearch, // autofocus on TextField when search enabled instead
              child: Data<SelectPopupHandle>.inherit(
                data: this,
                child: ModalContainer(
                  clipBehavior: Clip.hardEdge,
                  padding: EdgeInsets.zero,
                  surfaceBlur: widget.surfaceBlur,
                  surfaceOpacity: widget.surfaceOpacity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.enableSearch)
                        ComponentTheme(
                          data: const FocusOutlineTheme(
                            border: Border.fromBorderSide(BorderSide.none),
                          ),
                          child: TextField(
                            autofocus: true,
                            border: const Border.fromBorderSide(
                              BorderSide.none,
                            ),
                            borderRadius: BorderRadius.zero,
                            controller: _searchController,
                            features: [
                              InputFeature.leading(
                                const Icon(
                                  LucideIcons.search,
                                ).iconSmall().iconMutedForeground(),
                              ),
                            ],
                            padding: const EdgeInsets.all(12) * scaling,
                            placeholder: widget.searchPlaceholder,
                          ),
                        ),
                      Flexible(
                        child: ListenableBuilder(
                          builder: (context, _) {
                            return CachedValueWidget(
                              builder: (context, searchQuery) {
                                return FutureOrBuilder<SelectItemDelegate?>(
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      final loadingBuilder = widget
                                          .loadingBuilder
                                          ?.call(context);

                                      return loadingBuilder != null
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (widget.enableSearch)
                                                  const Divider(),
                                                Flexible(child: loadingBuilder),
                                              ],
                                            )
                                          : const SizedBox();
                                    }
                                    if (snapshot.hasError) {
                                      final errorBuilder = widget.errorBuilder
                                          ?.call(
                                            context,
                                            snapshot.error!,
                                            snapshot.stackTrace,
                                          );

                                      return errorBuilder != null
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (widget.enableSearch)
                                                  const Divider(),
                                                Flexible(child: errorBuilder),
                                              ],
                                            )
                                          : const SizedBox();
                                    }
                                    if (snapshot.hasData &&
                                        snapshot.data?.estimatedChildCount !=
                                            0) {
                                      final data = snapshot.data!;

                                      return CachedValueWidget(
                                        builder: (context, data) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (widget.enableSearch)
                                                const Divider(),
                                              Flexible(
                                                child: Stack(
                                                  fit: StackFit.passthrough,
                                                  children: [
                                                    if (widget
                                                        .disableVirtualization)
                                                      SingleChildScrollView(
                                                        controller:
                                                            _scrollController,
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4,
                                                            ) *
                                                            scaling,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            for (
                                                              int i = 0;
                                                              i <
                                                                  (data
                                                                          as SelectItemList)
                                                                      .children
                                                                      .length;
                                                              i += 1
                                                            )
                                                              data.build(
                                                                context,
                                                                i,
                                                              ),
                                                          ],
                                                        ),
                                                      )
                                                    else
                                                      ListView.builder(
                                                        controller:
                                                            _scrollController,
                                                        itemBuilder: data.build,
                                                        itemCount: data
                                                            .estimatedChildCount,
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4,
                                                            ) *
                                                            scaling,
                                                        shrinkWrap:
                                                            widget.shrinkWrap,
                                                      ),
                                                    ListenableBuilder(
                                                      builder: (context, child) {
                                                        return Visibility(
                                                          visible:
                                                              _scrollController
                                                                  .offset >
                                                              0,
                                                          child: Positioned(
                                                            left: 0,
                                                            right: 0,
                                                            top: 0,
                                                            child: HoverActivity(
                                                              debounceDuration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        16,
                                                                  ),
                                                              hitTestBehavior:
                                                                  HitTestBehavior
                                                                      .translucent,
                                                              onHover: () {
                                                                double value =
                                                                    _scrollController
                                                                        .offset -
                                                                    8;
                                                                value = value.clamp(
                                                                  0.0,
                                                                  _scrollController
                                                                      .position
                                                                      .maxScrollExtent,
                                                                );
                                                                _scrollController
                                                                    .jumpTo(
                                                                      value,
                                                                    );
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      vertical:
                                                                          4,
                                                                    ) *
                                                                    scaling,
                                                                child: const Icon(
                                                                  RadixIcons
                                                                      .chevronUp,
                                                                ).iconX3Small(),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      listenable:
                                                          _scrollController,
                                                    ),
                                                    ListenableBuilder(
                                                      builder: (context, child) {
                                                        return Visibility(
                                                          visible:
                                                              _scrollController
                                                                  .hasClients &&
                                                              _scrollController
                                                                  .position
                                                                  .hasContentDimensions &&
                                                              _scrollController
                                                                      .offset <
                                                                  _scrollController
                                                                      .position
                                                                      .maxScrollExtent,
                                                          child: Positioned(
                                                            bottom: 0,
                                                            left: 0,
                                                            right: 0,
                                                            child: HoverActivity(
                                                              debounceDuration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        16,
                                                                  ),
                                                              hitTestBehavior:
                                                                  HitTestBehavior
                                                                      .translucent,
                                                              onHover: () {
                                                                double value =
                                                                    _scrollController
                                                                        .offset +
                                                                    8;
                                                                value = value.clamp(
                                                                  0.0,
                                                                  _scrollController
                                                                      .position
                                                                      .maxScrollExtent,
                                                                );
                                                                _scrollController
                                                                    .jumpTo(
                                                                      value,
                                                                    );
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      vertical:
                                                                          4,
                                                                    ) *
                                                                    scaling,
                                                                child: const Icon(
                                                                  RadixIcons
                                                                      .chevronDown,
                                                                ).iconX3Small(),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      listenable:
                                                          _scrollController,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        value: data,
                                      );
                                    }
                                    final emptyBuilder = widget.emptyBuilder
                                        ?.call(context);

                                    return emptyBuilder != null
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (widget.enableSearch)
                                                const Divider(),
                                              Flexible(child: emptyBuilder),
                                            ],
                                          )
                                        : const SizedBox();
                                  },
                                  future: widget.builder == null
                                      ? widget.items == null
                                            ? SelectItemDelegate.empty
                                            : widget.items!
                                      : widget.builder!(context, searchQuery),
                                );
                              },
                              value: _searchController.text.isEmpty
                                  ? null
                                  : _searchController.text,
                            );
                          },
                          listenable: _searchController,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

abstract class SelectItemDelegate with CachedValue {
  const SelectItemDelegate();
  static const empty = EmptySelectItem();

  Widget? build(BuildContext context, int index);
  int? get estimatedChildCount => null;
}

class EmptySelectItem extends SelectItemDelegate {
  const EmptySelectItem();

  @override
  Widget? build(BuildContext context, int index) => null;

  @override
  int get estimatedChildCount => 0;

  @override
  bool shouldRebuild(covariant EmptySelectItem oldDelegate) {
    return false;
  }
}

typedef SelectItemWidgetBuilder =
    Widget Function(
      BuildContext context,
      int index,
    );

class SelectItemBuilder extends SelectItemDelegate {
  const SelectItemBuilder({required this.builder, this.childCount});

  final SelectItemWidgetBuilder builder;

  final int? childCount;

  @override
  Widget build(BuildContext context, int index) {
    return builder(context, index);
  }

  @override
  bool shouldRebuild(covariant SelectItemBuilder oldDelegate) {
    return oldDelegate.builder != builder &&
        oldDelegate.childCount != childCount;
  }

  @override
  int? get estimatedChildCount => childCount;
}

class SelectItemList extends SelectItemDelegate {
  const SelectItemList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context, int index) {
    return children[index];
  }

  @override
  bool shouldRebuild(covariant SelectItemList oldDelegate) {
    return !listEquals(oldDelegate.children, children);
  }

  @override
  int get estimatedChildCount => children.length;
}
