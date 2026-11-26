import 'package:coui_flutter/coui_flutter.dart';

// Local private constants for radio group component

/// Controller for managing [ControlledRadioGroup] state programmatically.
///
/// Extends [ValueNotifier] to provide reactive state management for radio group.
/// Components. Can be used to programmatically change selection, listen to.
/// State changes, and integrate with forms and other reactive systems.
///
/// Example:
/// ```dart
/// final controller = RadioGroupController<String>('option1');
///
/// // Listen to changes.
/// Controller.addListener(() {
///   print('Selection changed to: ${controller.value}');
/// });
///
/// // Update selection.
/// Controller.value = 'option2';
/// ```
class RadioGroupController<T> extends ValueNotifier<T?>
    with ComponentController<T?> {
  /// Creates a [RadioGroupController] with an optional initial value.
  ///
  /// The [value] parameter sets the initial selected option. Can be null.
  /// To start with no selection.
  ///
  /// Parameters:
  /// - [value] (T?, optional): Initial selected value.
  RadioGroupController([super.value]);
}
