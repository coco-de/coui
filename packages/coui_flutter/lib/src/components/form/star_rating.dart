import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Theme data for customizing [StarRating] widget appearance.
///
/// This class defines the visual properties that can be applied to
/// [StarRating] widgets, including colors for filled and unfilled stars,
/// star sizing, and spacing between stars. These properties can be set
/// at the theme level to provide consistent styling across the application.
class StarRatingTheme {
  /// Creates a [StarRatingTheme].
  const StarRatingTheme({
    this.activeColor,
    this.backgroundColor,
    this.starSize,
    this.starSpacing,
  });

  /// The color of the filled portion of the stars.
  final Color? activeColor;

  /// The color of the unfilled portion of the stars.
  final Color? backgroundColor;

  /// The size of each star.
  final double? starSize;

  /// The spacing between stars.
  final double? starSpacing;

  /// Returns a copy of this theme with the given fields replaced.
  StarRatingTheme copyWith({
    ValueGetter<Color?>? activeColor,
    ValueGetter<Color?>? backgroundColor,
    ValueGetter<double?>? starSize,
    ValueGetter<double?>? starSpacing,
  }) {
    return StarRatingTheme(
      activeColor: activeColor == null ? this.activeColor : activeColor(),
      backgroundColor:
          backgroundColor == null ? this.backgroundColor : backgroundColor(),
      starSize: starSize == null ? this.starSize : starSize(),
      starSpacing: starSpacing == null ? this.starSpacing : starSpacing(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StarRatingTheme &&
        other.activeColor == activeColor &&
        other.backgroundColor == backgroundColor &&
        other.starSize == starSize &&
        other.starSpacing == starSpacing;
  }

  @override
  int get hashCode => Object.hash(
        activeColor,
        backgroundColor,
        starSize,
        starSpacing,
      );
}

/// A controller for managing [StarRating] widget values programmatically.
///
/// This controller extends [ValueNotifier] and implements [ComponentController]
/// to provide a standardized way to control star rating values externally.
/// It allows programmatic manipulation of the rating value and provides
/// change notification capabilities.
///
/// The controller maintains a double value representing the current rating,
/// which is typically in the range of 0.0 to the maximum rating value.
///
/// Example:
/// ```dart
/// final controller = StarRatingController(3.5);
///
/// // Listen to changes
/// controller.addListener(() {
///   print('Rating changed to: ${controller.value}');
/// });
///
/// // Update the rating
/// controller.value = 4.0;
/// ```
class StarRatingController extends ValueNotifier<double>
    with ComponentController<double> {
  /// Creates a [StarRatingController] with the given initial [value].
  ///
  /// The [value] parameter sets the initial rating value. Defaults to 0.0
  /// if not specified. The value should typically be within the range
  /// supported by the star rating widget (0.0 to max value).
  ///
  /// Parameters:
  /// - [value] (double, default: 0.0): Initial rating value
  StarRatingController([super.value = 0.0]);
}

/// Reactive star rating widget with automatic state management and controller support.
///
/// A high-level star rating widget that provides automatic state management through
/// the controlled component pattern. Supports both controller-based and callback-based
/// state management with comprehensive customization options for star appearance,
/// interaction behavior, and rating precision.
///
/// ## Features
///
/// - **Fractional ratings**: Support for decimal values (e.g., 3.5 stars)
/// - **Step control**: Configurable rating increments for precision
/// - **Visual customization**: Comprehensive star shape and appearance options
/// - **Interactive feedback**: Touch and drag support for rating selection
/// - **Form integration**: Automatic validation and form field registration
/// - **Accessibility**: Full screen reader and keyboard navigation support
///
/// ## Usage Patterns
///
/// **Controller-based (recommended for complex state):**
/// ```dart
/// final controller = StarRatingController(3.5);
///
/// ControlledStarRating(
///   controller: controller,
///   max: 5.0,
///   step: 0.5,
///   activeColor: Colors.amber,
/// )
/// ```
///
/// **Callback-based (simple state management):**
/// ```dart
/// double currentRating = 0.0;
///
/// ControlledStarRating(
///   initialValue: currentRating,
///   onChanged: (rating) => setState(() => currentRating = rating),
///   max: 5.0,
///   step: 1.0,
/// )
/// ```
class ControlledStarRating extends StatelessWidget
    with ControlledComponent<double> {
  /// Creates a [ControlledStarRating].
  ///
  /// Either [controller] or [onChanged] should be provided for interactivity.
  /// The widget supports both controller-based and callback-based state management
  /// patterns with extensive star appearance customization options.
  ///
  /// Parameters:
  /// - [controller] (StarRatingController?, optional): external state controller
  /// - [initialValue] (double, default: 0.0): starting rating when no controller
  /// - [onChanged] (ValueChanged<double>?, optional): rating change callback
  /// - [enabled] (bool, default: true): whether star rating is interactive
  /// - [step] (double, default: 0.5): minimum increment for rating changes
  /// - [direction] (Axis, default: horizontal): layout direction of stars
  /// - [max] (double, default: 5.0): maximum rating value
  /// - [activeColor] (Color?, optional): color of filled star portions
  /// - [backgroundColor] (Color?, optional): color of unfilled star portions
  /// - [starPoints] (double, default: 5): number of points per star
  /// - [starSize] (double?, optional): override size of each star
  /// - [starSpacing] (double?, optional): override spacing between stars
  /// - [starPointRounding] (double?, optional): rounding radius for star points
  /// - [starValleyRounding] (double?, optional): rounding radius for star valleys
  /// - [starSquash] (double?, optional): vertical compression factor
  /// - [starInnerRadiusRatio] (double?, optional): inner to outer radius ratio
  /// - [starRotation] (double?, optional): rotation angle in radians
  ///
  /// Example:
  /// ```dart
  /// ControlledStarRating(
  ///   controller: controller,
  ///   max: 5.0,
  ///   step: 0.1,
  ///   activeColor: Colors.amber,
  ///   backgroundColor: Colors.grey[300],
  /// )
  /// ```
  const ControlledStarRating({
    this.activeColor,
    this.backgroundColor,
    this.controller,
    this.direction = Axis.horizontal,
    this.enabled = true,
    this.initialValue = 0.0,
    super.key,
    this.max = 5.0,
    this.onChanged,
    this.starInnerRadiusRatio,
    this.starPointRounding,
    this.starPoints = 5,
    this.starRotation,
    this.starSize,
    this.starSpacing,
    this.starSquash,
    this.starValleyRounding,
    this.step = 0.5,
  });

  @override
  final double initialValue;
  @override
  final ValueChanged<double>? onChanged;
  @override
  final bool enabled;

  @override
  final StarRatingController? controller;
  final double step;
  final Axis direction;
  final double max;
  final Color? activeColor;
  final Color? backgroundColor;
  final double starPoints;
  final double? starSize;
  final double? starSpacing;
  final double? starPointRounding;
  final double? starValleyRounding;
  final double? starSquash;
  final double? starInnerRadiusRatio;

  final double? starRotation;

  @override
  Widget build(BuildContext context) {
    return ControlledComponentAdapter(
      builder: (context, data) {
        return StarRating(
          activeColor: activeColor,
          backgroundColor: backgroundColor,
          direction: direction,
          enabled: data.enabled,
          max: max,
          onChanged: data.onChanged,
          starInnerRadiusRatio: starInnerRadiusRatio,
          starPointRounding: starPointRounding,
          starPoints: starPoints,
          starRotation: starRotation,
          starSize: starSize,
          starSpacing: starSpacing,
          starSquash: starSquash,
          starValleyRounding: starValleyRounding,
          step: step,
          value: data.value,
        );
      },
      controller: controller,
      enabled: enabled,
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }
}

/// An interactive star rating widget for collecting user feedback and ratings.
///
/// [StarRating] provides a customizable rating interface using star-shaped
/// indicators that users can tap or drag to select a rating value. The widget
/// supports fractional ratings, customizable star appearance, and both horizontal
/// and vertical orientations.
///
/// Key features:
/// - Interactive star-based rating selection
/// - Support for fractional ratings (e.g., 3.5 stars)
/// - Customizable star shape with points, rounding, and squashing
/// - Horizontal and vertical layout orientations
/// - Configurable step increments for rating precision
/// - Visual feedback with filled/unfilled star indicators
/// - Touch and drag interaction support
/// - Accessibility integration
///
/// The widget displays a series of star shapes that fill based on the current
/// rating value. Users can interact with the stars to select new rating values,
/// with support for fine-grained control through the step parameter.
///
/// Star appearance can be extensively customized:
/// - Number of points per star
/// - Star size and spacing
/// - Point and valley rounding
/// - Star squashing and inner radius ratio
/// - Rotation angle
/// - Fill and background colors
///
/// Example:
/// ```dart
/// StarRating(
///   value: currentRating,
///   max: 5.0,
///   step: 0.5, // Allow half-star ratings
///   onChanged: (rating) => setState(() => currentRating = rating),
///   activeColor: Colors.amber,
///   backgroundColor: Colors.grey[300],
/// );
/// ```
class StarRating extends StatefulWidget {
  const StarRating({
    this.activeColor,
    this.backgroundColor,
    this.direction = Axis.horizontal,
    this.enabled,
    super.key,
    this.max = 5.0,
    this.onChanged,
    this.starInnerRadiusRatio,
    this.starPointRounding,
    this.starPoints = 5,
    this.starRotation,
    this.starSize,
    this.starSpacing,
    this.starSquash,
    this.starValleyRounding,
    this.step = 0.5,
    required this.value,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double step;
  final Axis direction;
  final double max;
  final Color? activeColor;
  final Color? backgroundColor;
  final double starPoints;
  final double? starSize;
  final double? starSpacing;
  final double? starPointRounding;
  final double? starValleyRounding;
  final double? starSquash;
  final double? starInnerRadiusRatio;
  final double? starRotation;

  final bool? enabled;

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating>
    with FormValueSupplier<double, StarRating> {
  double? _changingValue;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    formValue = widget.value;
  }

  Widget _buildStar(BuildContext context, [bool focusBorder = false]) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<StarRatingTheme>(context);
    final starValleyRounding = widget.starValleyRounding ?? 0.0;
    final starSquash = widget.starSquash ?? 0.0;
    final starInnerRadiusRatio = widget.starInnerRadiusRatio ?? 0.4;
    final starRotation = widget.starRotation ?? 0.0;
    final starSize = styleValue(
          defaultValue: 24,
          themeValue: compTheme?.starSize,
          widgetValue: widget.starSize,
        ) *
        scaling;

    return Container(
      decoration: ShapeDecoration(
        color: focusBorder ? null : Colors.white,
        shape: StarBorder(
          innerRadiusRatio: starInnerRadiusRatio,
          pointRounding: widget.starPointRounding ?? (theme.radius / 2),
          points: widget.starPoints,
          rotation: starRotation,
          side: focusBorder && _focused
              ? BorderSide(
                  color: theme.colorScheme.ring,
                  strokeAlign: BorderSide.strokeAlignOutside,
                  width: scaling * 2.0)
              : BorderSide.none,
          squash: starSquash,
          valleyRounding: starValleyRounding * theme.radius,
        ),
      ),
      height: starSize,
      width: starSize,
    );
  }

  @override
  void didUpdateWidget(covariant StarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      formValue = widget.value;
    }
  }

  @override
  void didReplaceFormValue(double value) {
    widget.onChanged?.call(value);
  }

  bool get _enabled => widget.enabled ?? widget.onChanged != null;

  @override
  Widget build(BuildContext context) {
    final roundedValue =
        ((_changingValue ?? widget.value) / widget.step).round() * widget.step;

    return AnimatedValueBuilder(
      builder: (context, roundedValue, child) {
        final theme = Theme.of(context);
        final scaling = theme.scaling;
        final compTheme = ComponentTheme.maybeOf<StarRatingTheme>(context);
        final starSize = styleValue(
          defaultValue: scaling * 24.0,
          themeValue: compTheme?.starSize,
          widgetValue: widget.starSize,
        );
        final starSpacing = styleValue(
          defaultValue: scaling * 5.0,
          themeValue: compTheme?.starSpacing,
          widgetValue: widget.starSpacing,
        );
        final activeColor = styleValue(
          defaultValue: _enabled
              ? theme.colorScheme.primary
              : theme.colorScheme.mutedForeground,
          themeValue: compTheme?.activeColor,
          widgetValue: widget.activeColor,
        );
        final backgroundColor = styleValue(
          defaultValue: theme.colorScheme.muted,
          themeValue: compTheme?.backgroundColor,
          widgetValue: widget.backgroundColor,
        );

        return FocusableActionDetector(
          actions: {
            IncreaseStarIntent: CallbackAction<IncreaseStarIntent>(
              onInvoke: (intent) {
                if (widget.onChanged != null) {
                  widget.onChanged!(
                    (roundedValue + intent.step).clamp(0.0, widget.max),
                  );
                }

                return null;
              },
            ),
            DecreaseStarIntent: CallbackAction<DecreaseStarIntent>(
              onInvoke: (intent) {
                if (widget.onChanged != null) {
                  widget.onChanged!(
                    (roundedValue - intent.step).clamp(0.0, widget.max),
                  );
                }

                return null;
              },
            ),
          },
          enabled: _enabled,
          mouseCursor: _enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          onShowFocusHighlight: (showFocus) {
            setState(() {
              _focused = showFocus;
            });
          },
          onShowHoverHighlight: (showHover) {
            if (!showHover) {
              setState(() {
                _changingValue = null;
              });
            }
          },
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.arrowRight):
                IncreaseStarIntent(widget.step),
            LogicalKeySet(LogicalKeyboardKey.arrowLeft):
                DecreaseStarIntent(widget.step),
          },
          child: MouseRegion(
            onHover: (event) {
              if (!_enabled) return;
              if (widget.onChanged == null) return;
              final size = context.size!.width;
              final progress = (event.localPosition.dx / size).clamp(0.0, 1.0);
              final newValue = (progress * widget.max).clamp(0.0, widget.max);
              setState(() {
                _changingValue = newValue;
              });
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanCancel: () {
                if (!_enabled) return;
                if (widget.onChanged == null) return;
                widget.onChanged!(_changingValue ?? roundedValue);
                setState(() {
                  _changingValue = null;
                });
              },
              onPanEnd: (details) {
                if (!_enabled) return;
                if (widget.onChanged == null) return;
                widget.onChanged!(_changingValue ?? roundedValue);
                setState(() {
                  _changingValue = null;
                });
              },
              onPanUpdate: (details) {
                if (!_enabled) return;
                if (widget.onChanged == null) return;
                final totalStars = widget.max.ceil();
                final totalStarSize =
                    starSize * totalStars + (starSpacing * (totalStars - 1));
                final progress =
                    (details.localPosition.dx / totalStarSize).clamp(0.0, 1.0);
                final newValue = (progress * widget.max).clamp(0.0, widget.max);
                setState(() {
                  _changingValue = newValue;
                });
              },
              onTap: () {
                if (widget.onChanged != null && roundedValue != widget.value) {
                  widget.onChanged!(roundedValue);
                }
              },
              onTapDown: (details) {
                if (!_enabled) return;
                if (widget.onChanged == null) return;
                final totalStarSize =
                    starSize + (starSpacing * (widget.max.ceil() - 1));
                final progress =
                    (details.localPosition.dx / totalStarSize).clamp(0.0, 1.0);
                final newValue = (progress * widget.max).clamp(0.0, widget.max);
                widget.onChanged!(newValue);
              },
              child: Flex(
                direction: widget.direction,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.max.ceil(); i += 1)
                    Stack(
                      fit: StackFit.passthrough,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: widget.direction == Axis.horizontal
                                  ? Alignment.centerLeft
                                  : Alignment.bottomCenter,
                              colors: [activeColor, backgroundColor],
                              end: widget.direction == Axis.horizontal
                                  ? Alignment.centerRight
                                  : Alignment.topCenter,
                              stops: [
                                (roundedValue - i).clamp(0.0, 1.0),
                                (roundedValue - i).clamp(0.0, 1.0),
                              ],
                            ).createShader(bounds);
                          },
                          child: _buildStar(context),
                        ),
                        _buildStar(context, true),
                      ],
                    ),
                ],
              ).gap(starSpacing),
            ),
          ),
        );
      },
      duration: kDefaultDuration,
      value: roundedValue,
    );
  }
}

class IncreaseStarIntent extends Intent {
  const IncreaseStarIntent(this.step);
  final double step;
}

class DecreaseStarIntent extends Intent {
  const DecreaseStarIntent(this.step);
  final double step;
}
