import 'package:coui_flutter/coui_flutter.dart';

// === LOCAL CONSTANTS ===

/// Default size for checkbox square in logical pixels.

/// Vertical position ratio for first stroke start point.
const _kFirstStrokeStartY = 0.5;

/// Horizontal position ratio for first stroke end point.
const _kFirstStrokeEndX = 0.35;

/// Reactive controller for managing checkbox state with convenient methods.
///
/// Extends [ValueNotifier] to provide state management for checkbox widgets.
/// With built-in methods for common state transitions. Supports all three.
/// Checkbox states: checked, unchecked, and indeterminate.
///
/// The controller can be used with [ControlledCheckbox] for reactive state.
/// Management or manually to coordinate checkbox behavior across widgets.
///
/// Example:
/// ```dart
/// final controller = CheckboxController(CheckboxState.unchecked);
///
/// // React to changes.
/// Controller.addListener(() {
///   print('Checkbox is now: ${controller.value}');
/// });
///
/// // Programmatic control.
/// Controller.toggle(); // unchecked -> checked.
/// Controller.indeterminate(); // -> indeterminate.
/// ```
class CheckboxController extends ValueNotifier<CheckboxState>
    with ComponentController<CheckboxState> {
  /// Creates a [CheckboxController] with the specified initial [value].
  ///
  /// The controller will notify listeners whenever the checkbox state changes.
  /// Through any of the provided methods or direct value assignment.
  CheckboxController(super.value);

  /// Sets the checkbox state to checked.
  ///
  /// Notifies listeners of the state change. Equivalent to setting.
  /// `value = CheckboxState.checked`.
  void check() {
    value = .checked;
  }

  /// Sets the checkbox state to unchecked.
  ///
  /// Notifies listeners of the state change. Equivalent to setting.
  /// `value = CheckboxState.unchecked`.
  void uncheck() {
    value = .unchecked;
  }

  /// Sets the checkbox state to indeterminate.
  ///
  /// Notifies listeners of the state change. Used for tri-state checkboxes.
  /// To indicate a partially selected or mixed state.
  void indeterminate() {
    value = .indeterminate;
  }

  /// Toggles between checked and unchecked states.
  ///
  /// If currently checked, becomes unchecked. If currently unchecked or.
  /// Indeterminate, becomes checked. Does not cycle through indeterminate state.
  void toggle() {
    value = value == .checked ? .unchecked : .checked;
  }

  /// Cycles through all three states in order: checked -> unchecked -> indeterminate.
  ///
  /// Provides complete tri-state cycling behavior. Use this instead of [toggle]
  /// when working with tri-state checkboxes that need to support indeterminate state.
  void toggleTristate() {
    value = value == .checked
        ? .unchecked
        : value == .unchecked
        ? .indeterminate
        : .checked;
  }

  /// Returns true if the checkbox is currently checked.
  bool get isChecked => value == .checked;

  /// Returns true if the checkbox is currently unchecked.
  bool get isUnchecked => value == .unchecked;

  /// Returns true if the checkbox is currently in indeterminate state.
  bool get isIndeterminate => value == .indeterminate;
}

/// Represents the possible states of a checkbox widget.
///
/// Supports the standard checked/unchecked binary states as well as an.
/// Indeterminate state commonly used to represent partial selection in.
/// Hierarchical or grouped checkbox scenarios.
///
/// The enum implements [Comparable] to provide consistent ordering:
/// Checked < unchecked < indeterminate (based on declaration order).
enum CheckboxState implements Comparable<CheckboxState> {
  /// The checkbox is selected/checked state.
  ///
  /// Visually represented with a checkmark icon inside the checkbox square.
  /// Indicates the associated option or value is selected/enabled.
  checked,

  /// The checkbox is in a partially selected/indeterminate state.
  ///
  /// Visually represented with a small square inside the checkbox.
  /// Typically used in hierarchical structures to indicate some but not.
  /// All child items are selected, or when the state is unknown/mixed.
  indeterminate,

  /// The checkbox is unselected/unchecked state.
  ///
  /// Visually represented as an empty checkbox square with border.
  /// Indicates the associated option or value is not selected/disabled.
  unchecked;

  /// Compares checkbox states based on their declaration order.
  ///
  /// Returns negative if this state comes before [other], zero if equal,.
  /// Positive if this state comes after [other] in the enum declaration.
  @override
  int compareTo(CheckboxState other) {
    return index.compareTo(other.index);
  }
}

/// Custom painter for drawing animated checkmarks in checkboxes.
///
/// Renders a smooth checkmark animation that draws progressively from left to right.
/// In two stroke segments. The animation provides visual feedback when transitioning.
/// To the checked state, creating a satisfying user experience.
///
/// The checkmark is drawn as two connected line segments: a shorter diagonal line.
/// From bottom-left toward center, and a longer diagonal line from center to top-right.
/// The [progress] parameter controls how much of the checkmark is visible.
///
/// Used internally by [Checkbox] - not typically instantiated directly by consumers.
class AnimatedCheckPainter extends CustomPainter {
  /// Creates an [AnimatedCheckPainter].
  ///
  /// All parameters are required as they directly control the checkmark appearance.
  /// And animation state. The painter should be recreated when any parameter changes.
  ///
  /// Parameters:
  /// - [progress] (double, required): animation progress 0.0-1.0.
  /// - [color] (Color, required): checkmark stroke color.
  /// - [strokeWidth] (double, required): stroke thickness in logical pixels.
  ///
  /// Example usage within CustomPaint:
  /// ```dart
  /// customPaint(
  ///   painter: AnimatedCheckPainter(
  ///     progress: animationValue,
  ///     color: theme.primaryForeground,
  ///     strokeWidth: 2.0,
  ///   ),.
  /// )
  /// ```
  const AnimatedCheckPainter({
    required this.color,
    required this.progress,
    required this.strokeWidth,
  });

  /// Animation progress from 0.0 to 1.0 controlling checkmark visibility.
  ///
  /// At 0.0, no checkmark is visible. At 1.0, the complete checkmark is drawn.
  /// Values between 0.0 and 1.0 show partial drawing progress with smooth transitions.
  final double progress;

  /// Color used to draw the checkmark strokes.
  ///
  /// Typically the primary foreground color to provide contrast against.
  /// The checkbox's active background color.
  final Color color;

  /// Width of the checkmark stroke lines in logical pixels.
  ///
  /// Controls the thickness of the drawn checkmark. Usually scaled with.
  /// The theme's scaling factor for consistent appearance across screen densities.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = .stroke
      ..strokeCap = .round;
    final path = Path();
    final firstStrokeStart = Offset(
      0.0,
      size.height * _kFirstStrokeStartY,
    );
    final firstStrokeEnd = Offset(size.width * _kFirstStrokeEndX, size.height);
    final secondStrokeStart = firstStrokeEnd;
    final secondStrokeEnd = Offset(
      size.width,
      0.0,
    );
    final firstStrokeLength =
        (firstStrokeEnd - firstStrokeStart).distanceSquared;
    final secondStrokeLength =
        (secondStrokeEnd - secondStrokeStart).distanceSquared;
    final totalLength = firstStrokeLength + secondStrokeLength;

    final normalizedFirstStrokeLength = firstStrokeLength / totalLength;
    final normalizedSecondStrokeLength = secondStrokeLength / totalLength;

    final firstStrokeProgress =
        progress.clamp(0.0, normalizedFirstStrokeLength) /
        normalizedFirstStrokeLength;
    final secondStrokeProgress =
        (progress - normalizedFirstStrokeLength).clamp(
          0.0,
          normalizedSecondStrokeLength,
        ) /
        normalizedSecondStrokeLength;
    if (firstStrokeProgress <= 0) {
      return;
    }
    final currentPoint = Offset.lerp(
      firstStrokeStart,
      firstStrokeEnd,
      firstStrokeProgress,
    )!;
    path.moveTo(firstStrokeStart.dx, firstStrokeStart.dy);
    path.lineTo(currentPoint.dx, currentPoint.dy);
    if (secondStrokeProgress <= 0) {
      canvas.drawPath(path, paint);

      return;
    }
    final secondPoint = Offset.lerp(
      secondStrokeStart,
      secondStrokeEnd,
      secondStrokeProgress,
    )!;
    path.lineTo(secondPoint.dx, secondPoint.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant AnimatedCheckPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
