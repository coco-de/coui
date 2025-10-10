import 'dart:math';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'package:coui_flutter/coui_flutter.dart';

/// Reactive controller for managing slider state with value operations.
///
/// Extends [ValueNotifier] to provide state management for slider widgets
/// using [SliderValue] objects that support both single and range slider
/// configurations. Enables programmatic slider value changes and provides
/// convenient methods for common slider operations.
///
/// The controller manages [SliderValue] objects which can represent either
/// single values or dual-thumb range values, providing unified state management
/// for different slider types.
///
/// Example:
/// ```dart
/// final controller = SliderController(SliderValue.single(0.5));
///
/// // React to changes
/// controller.addListener(() {
///   print('Slider value: ${controller.value}');
/// });
///
/// // Programmatic control
/// controller.setValue(0.75);
/// controller.setRange(0.2, 0.8);
/// ```
class SliderController extends ValueNotifier<SliderValue>
    with ComponentController<SliderValue> {
  /// Creates a [SliderController] with the specified initial value.
  ///
  /// The [value] parameter provides the initial slider configuration as a
  /// [SliderValue]. The controller notifies listeners when the value changes
  /// through any method calls or direct value assignment.
  ///
  /// Example:
  /// ```dart
  /// final controller = SliderController(SliderValue.single(0.3));
  /// ```
  SliderController(super.value);

  /// Sets the slider to a single value configuration.
  ///
  /// Converts the slider to single-thumb mode with the specified [value].
  /// The value should be within the slider's min/max bounds.
  void setValue(double value) {
    this.value = SliderValue.single(value);
  }

  /// Sets the slider to a range value configuration.
  ///
  /// Converts the slider to dual-thumb mode with the specified [start] and [end] values.
  /// The values should be within the slider's min/max bounds with start <= end.
  void setRange(double end, double start) {
    value = SliderValue.ranged(start, end);
  }

  /// Returns true if the slider is in single-value mode.
  bool get isSingle => !value.isRanged;

  /// Returns true if the slider is in range mode.
  bool get isRanged => value.isRanged;

  /// Gets the current single value (valid only in single mode).
  ///
  /// Throws an exception if called when the slider is in range mode.
  double get singleValue => value.value;

  /// Gets the current range start value (valid only in range mode).
  ///
  /// Throws an exception if called when the slider is in single mode.
  double get rangeStart => value.start;

  /// Gets the current range end value (valid only in range mode).
  ///
  /// Throws an exception if called when the slider is in single mode.
  double get rangeEnd => value.end;
}

/// Reactive slider with automatic state management and controller support.
///
/// A high-level slider widget that provides automatic state management through
/// the controlled component pattern. Supports both single-value and range sliders
/// with comprehensive customization options for styling, behavior, and interaction.
///
/// ## Features
///
/// - **Single and range modes**: Unified interface for different slider types
/// - **Discrete divisions**: Optional snap-to-value behavior with tick marks
/// - **Keyboard navigation**: Full arrow key support with custom step sizes
/// - **Hint values**: Visual preview of suggested or default values
/// - **Accessibility support**: Screen reader compatibility and semantic labels
/// - **Form integration**: Automatic validation and form field registration
///
/// ## Usage Patterns
///
/// **Controller-based (recommended for complex state):**
/// ```dart
/// final controller = SliderController(SliderValue.single(0.5));
///
/// ControlledSlider(
///   controller: controller,
///   min: 0.0,
///   max: 100.0,
///   divisions: 100,
/// )
/// ```
///
/// **Callback-based (simple state management):**
/// ```dart
/// double currentValue = 50.0;
///
/// ControlledSlider(
///   initialValue: SliderValue.single(currentValue),
///   onChanged: (value) => setState(() => currentValue = value.single),
///   min: 0.0,
///   max: 100.0,
/// )
/// ```
class ControlledSlider extends StatelessWidget
    with ControlledComponent<SliderValue> {
  const ControlledSlider({
    this.controller,
    this.decreaseStep,
    this.divisions,
    this.enabled = true,
    this.hintValue,
    this.increaseStep,
    this.initialValue = const SliderValue.single(0),
    super.key,
    this.max = 1,
    this.min = 0,
    this.onChangeEnd,
    this.onChangeStart,
    this.onChanged,
  });

  @override
  final SliderValue initialValue;
  @override
  final ValueChanged<SliderValue>? onChanged;
  @override
  final SliderController? controller;

  @override
  final bool enabled;
  final ValueChanged<SliderValue>? onChangeStart;
  final ValueChanged<SliderValue>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final SliderValue? hintValue;
  final double? increaseStep;

  final double? decreaseStep;

  @override
  Widget build(BuildContext context) {
    return ControlledComponentAdapter(
      initialValue: initialValue,
      builder: (context, data) {
        return Slider(
          decreaseStep: decreaseStep,
          divisions: divisions,
          enabled: data.enabled,
          hintValue: hintValue,
          increaseStep: increaseStep,
          max: max,
          min: min,
          onChangeEnd: onChangeEnd,
          onChangeStart: onChangeStart,
          onChanged: data.onChanged,
          value: data.value,
        );
      },
      controller: controller,
      onChanged: onChanged,
    );
  }
}

class SliderValue {
  const SliderValue.single(double value) : _start = null, _end = value;
  const SliderValue.ranged(this._end, double this._start);

  /// If start is null, it means its not ranged slider, its a single value slider.
  /// If its a single value slider, then the trackbar is clickable and the thumb can be dragged.
  /// If its a ranged slider, then the trackbar is not clickable and the thumb can be dragged.
  final double? _start;
  final double _end;

  static SliderValue? lerp(SliderValue? a, SliderValue? b, double t) {
    if (a == null || b == null) return null;
    if (a.isRanged && b.isRanged) {
      return SliderValue.ranged(
        lerpDouble(a.start, b.start, t)!,
        lerpDouble(a.end, b.end, t)!,
      );
    } else if (!a.isRanged && !b.isRanged) {
      return SliderValue.single(lerpDouble(a.value, b.value, t)!);
    }

    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SliderValue && other._start == _start && other._end == _end;
  }

  SliderValue roundToDivisions(int divisions) {
    return !isRanged
        ? SliderValue.single((_end * divisions).round() / divisions)
        : SliderValue.ranged(
            (_start! * divisions).round() / divisions,
            (_end * divisions).round() / divisions,
          );
  }

  bool get isRanged => _start != null;
  double get start => _start ?? _end;

  double get end => _end;

  double get value => _end;

  @override
  int get hashCode => _start.hashCode ^ _end.hashCode;
}

/// Theme for [Slider].
class SliderTheme {
  /// Creates a [SliderTheme].
  const SliderTheme({
    this.disabledTrackColor,
    this.disabledValueColor,
    this.thumbBorderColor,
    this.thumbColor,
    this.thumbFocusedBorderColor,
    this.thumbSize,
    this.trackColor,
    this.trackHeight,
    this.valueColor,
  });

  /// Height of the track.
  final double? trackHeight;

  /// Color of the inactive track.
  final Color? trackColor;

  /// Color of the active portion of the track.
  final Color? valueColor;

  /// Color of the inactive track when disabled.
  final Color? disabledTrackColor;

  /// Color of the active track when disabled.
  final Color? disabledValueColor;

  /// Background color of the thumb.
  final Color? thumbColor;

  /// Border color of the thumb.
  final Color? thumbBorderColor;

  /// Border color of the thumb when focused.
  final Color? thumbFocusedBorderColor;

  /// Size of the thumb.
  final double? thumbSize;

  /// Returns a copy of this theme with the given fields replaced.
  SliderTheme copyWith({
    ValueGetter<Color?>? disabledTrackColor,
    ValueGetter<Color?>? disabledValueColor,
    ValueGetter<Color?>? thumbBorderColor,
    ValueGetter<Color?>? thumbColor,
    ValueGetter<Color?>? thumbFocusedBorderColor,
    ValueGetter<double?>? thumbSize,
    ValueGetter<Color?>? trackColor,
    ValueGetter<double?>? trackHeight,
    ValueGetter<Color?>? valueColor,
  }) {
    return SliderTheme(
      disabledTrackColor: disabledTrackColor == null
          ? this.disabledTrackColor
          : disabledTrackColor(),
      disabledValueColor: disabledValueColor == null
          ? this.disabledValueColor
          : disabledValueColor(),
      thumbBorderColor: thumbBorderColor == null
          ? this.thumbBorderColor
          : thumbBorderColor(),
      thumbColor: thumbColor == null ? this.thumbColor : thumbColor(),
      thumbFocusedBorderColor: thumbFocusedBorderColor == null
          ? this.thumbFocusedBorderColor
          : thumbFocusedBorderColor(),
      thumbSize: thumbSize == null ? this.thumbSize : thumbSize(),
      trackColor: trackColor == null ? this.trackColor : trackColor(),
      trackHeight: trackHeight == null ? this.trackHeight : trackHeight(),
      valueColor: valueColor == null ? this.valueColor : valueColor(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SliderTheme &&
        other.trackHeight == trackHeight &&
        other.trackColor == trackColor &&
        other.valueColor == valueColor &&
        other.disabledTrackColor == disabledTrackColor &&
        other.disabledValueColor == disabledValueColor &&
        other.thumbColor == thumbColor &&
        other.thumbBorderColor == thumbBorderColor &&
        other.thumbFocusedBorderColor == thumbFocusedBorderColor &&
        other.thumbSize == thumbSize;
  }

  @override
  int get hashCode => Object.hash(
    trackHeight,
    trackColor,
    valueColor,
    disabledTrackColor,
    disabledValueColor,
    thumbColor,
    thumbBorderColor,
    thumbFocusedBorderColor,
    thumbSize,
  );
}

class IncreaseSliderValue extends Intent {
  const IncreaseSliderValue();
}

class DecreaseSliderValue extends Intent {
  const DecreaseSliderValue();
}

class Slider extends StatefulWidget {
  const Slider({
    this.decreaseStep,
    this.divisions,
    this.enabled = true,
    this.hintValue,
    this.increaseStep,
    super.key,
    this.max = 1,
    this.min = 0,
    this.onChangeEnd,
    this.onChangeStart,
    this.onChanged,
    required this.value,
  }) : assert(min <= max);

  final SliderValue value;
  final ValueChanged<SliderValue>? onChanged;
  final ValueChanged<SliderValue>? onChangeStart;
  final ValueChanged<SliderValue>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final SliderValue? hintValue;
  final double? increaseStep;
  final double? decreaseStep;

  final bool? enabled;

  @override
  _SliderState createState() => _SliderState();
}

class _SliderState extends State<Slider>
    with FormValueSupplier<SliderValue, Slider> {
  /// Used for the thumb position (not the trackbar).
  /// Trackbar position uses the widget.value.
  late SliderValue _currentValue;
  bool _dragging = false;
  bool _moveStart = false;

  bool _focusing = false;
  bool _focusingEnd = false;

  bool get enabled => widget.enabled ?? widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    if (widget.value.isRanged) {
      final start =
          (widget.value.start - widget.min) / (widget.max - widget.min);
      final end = (widget.value.end - widget.min) / (widget.max - widget.min);
      final newStart = min(start, end);
      final newEnd = max(start, end);
      _currentValue = SliderValue.ranged(newStart, newEnd);
    } else {
      final value =
          (widget.value.value - widget.min) / (widget.max - widget.min);
      _currentValue = SliderValue.single(value);
    }
    formValue = _currentValue;
  }

  void _dispatchValueChangeStart(SliderValue value) {
    if (!enabled) return;
    if (widget.divisions != null) {
      value = value.roundToDivisions(widget.divisions!);
    }
    widget.onChangeStart?.call(value);
  }

  void _dispatchValueChange(SliderValue value) {
    if (!enabled) return;
    if (widget.divisions != null) {
      value = value.roundToDivisions(widget.divisions!);
    }
    if (value != widget.value) {
      widget.onChanged?.call(value);
    }
  }

  void _dispatchValueChangeEnd(SliderValue value) {
    if (!enabled) return;
    if (widget.divisions != null) {
      value = value.roundToDivisions(widget.divisions!);
    }
    if (value != widget.value) {
      widget.onChangeEnd?.call(value);
    }
  }

  @override
  void didUpdateWidget(covariant Slider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_dragging) {
      if (widget.value.isRanged) {
        final start =
            (widget.value.start - widget.min) / (widget.max - widget.min);
        final end = (widget.value.end - widget.min) / (widget.max - widget.min);
        final newStart = min(start, end);
        final newEnd = max(start, end);
        _currentValue = SliderValue.ranged(newStart, newEnd);
      } else {
        final value =
            (widget.value.value - widget.min) / (widget.max - widget.min);
        _currentValue = SliderValue.single(value);
      }
      formValue = _currentValue;
    }
  }

  @override
  void didReplaceFormValue(SliderValue value) {
    widget.onChanged?.call(value);
    widget.onChangeEnd?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: scaling * 20,
        minHeight: scaling * 16,
        maxHeight: scaling * 16,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scaling * 4.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: enabled
                  ? widget.value.isRanged
                        ? (details) {
                            /// Set _moveStart to true if the tap is closer to the start thumb.
                            final offset = details.localPosition.dx;
                            double newValue = offset / constraints.maxWidth;
                            double start = _currentValue.start;
                            double end = _currentValue.end;
                            if (widget.divisions != null) {
                              start =
                                  (start * widget.divisions!).round() /
                                  widget.divisions!;
                              end =
                                  (end * widget.divisions!).round() /
                                  widget.divisions!;
                            }
                            _moveStart =
                                (start - newValue).abs() <
                                (end - newValue).abs();

                            /// Find the closest thumb and move it to the tap position.
                            if (_moveStart) {
                              if (widget.divisions != null) {
                                final deltaValue = newValue - start;
                                if (deltaValue >= 0 &&
                                    deltaValue < 0.5 / widget.divisions!) {
                                  newValue += 0.5 / widget.divisions!;
                                } else if (deltaValue < 0 &&
                                    deltaValue > -0.5 / widget.divisions!) {
                                  newValue -= 0.5 / widget.divisions!;
                                }
                              }
                              final newSliderValue = SliderValue.ranged(
                                newValue,
                                widget.value.end,
                              );
                              _dispatchValueChangeStart(newSliderValue);
                              _dispatchValueChange(newSliderValue);
                              _dispatchValueChangeEnd(newSliderValue);
                              setState(() {
                                _currentValue = SliderValue.ranged(
                                  newValue,
                                  end,
                                );
                              });
                            } else {
                              if (widget.divisions != null) {
                                final deltaValue = newValue - end;
                                if (deltaValue >= 0 &&
                                    deltaValue < 0.5 / widget.divisions!) {
                                  newValue += 0.5 / widget.divisions!;
                                } else if (deltaValue < 0 &&
                                    deltaValue > -0.5 / widget.divisions!) {
                                  newValue -= 0.5 / widget.divisions!;
                                }
                              }
                              final newSliderValue = SliderValue.ranged(
                                widget.value.start,
                                newValue,
                              );
                              _dispatchValueChangeStart(newSliderValue);
                              _dispatchValueChange(newSliderValue);
                              _dispatchValueChangeEnd(newSliderValue);
                              setState(() {
                                _currentValue = SliderValue.ranged(
                                  start,
                                  newValue,
                                );
                              });
                            }
                          }
                        : (details) {
                            final offset = details.localPosition.dx;
                            double newValue = offset / constraints.maxWidth;
                            newValue = newValue.clamp(0, 1).toDouble();
                            if (widget.divisions != null) {
                              final deltaValue = newValue - _currentValue.value;
                              if (deltaValue >= 0 &&
                                  deltaValue < 0.5 / widget.divisions!) {
                                newValue += 0.5 / widget.divisions!;
                              } else if (deltaValue < 0 &&
                                  deltaValue > -0.5 / widget.divisions!) {
                                newValue -= 0.5 / widget.divisions!;
                              }
                              newValue =
                                  (newValue * widget.divisions!).round() /
                                  widget.divisions!;
                            }
                            final newSliderValue = SliderValue.single(
                              newValue * (widget.max - widget.min) + widget.min,
                            );
                            _dispatchValueChangeStart(newSliderValue);
                            _dispatchValueChange(newSliderValue);
                            _dispatchValueChangeEnd(newSliderValue);
                            setState(() {
                              _currentValue = SliderValue.single(newValue);
                            });
                          }
                  : null,
              onHorizontalDragStart: enabled
                  ? (details) {
                      _dragging = true;
                      if (_currentValue.isRanged) {
                        /// Change _moveStart to true if the tap is closer to the start thumb.
                        final offset = details.localPosition.dx;
                        final newValue = offset / constraints.maxWidth;
                        double start = _currentValue.start;
                        double end = _currentValue.end;
                        if (widget.divisions != null) {
                          start =
                              (start * widget.divisions!).round() /
                              widget.divisions!;
                          end =
                              (end * widget.divisions!).round() /
                              widget.divisions!;
                        }
                        _moveStart =
                            (start - newValue).abs() < (end - newValue).abs();
                        final startValue =
                            start * (widget.max - widget.min) + widget.min;
                        final endValue =
                            end * (widget.max - widget.min) + widget.min;
                        final newStartValue = min(startValue, endValue);
                        final newEndValue = max(startValue, endValue);
                        final newSliderValue = SliderValue.ranged(
                          newStartValue,
                          newEndValue,
                        );
                        _dispatchValueChangeStart(newSliderValue);
                      } else {
                        double value = _currentValue.value;
                        if (widget.divisions != null) {
                          value =
                              (value * widget.divisions!).round() /
                              widget.divisions!;
                        }
                        final newSliderValue = SliderValue.single(
                          value * (widget.max - widget.min) + widget.min,
                        );
                        _dispatchValueChangeStart(newSliderValue);
                      }
                    }
                  : null,
              onHorizontalDragUpdate: enabled
                  ? widget.value.isRanged
                        ? (details) {
                            /// Drag the closest thumb to the drag position
                            /// but use delta to calculate the new value.
                            final delta =
                                details.primaryDelta! / constraints.maxWidth;
                            if (_moveStart) {
                              double newStart = _currentValue.start + delta;
                              double newEnd = _currentValue.end;
                              newStart = newStart.clamp(0, 1).toDouble();
                              newEnd = newEnd.clamp(0, 1).toDouble();
                              final newInternalSliderValue = SliderValue.ranged(
                                newStart,
                                newEnd,
                              );
                              if (newInternalSliderValue == _currentValue) {
                                return;
                              }
                              double sliderStart = newStart;
                              double sliderEnd = newEnd;
                              if (widget.divisions != null) {
                                sliderStart =
                                    (sliderStart * widget.divisions!).round() /
                                    widget.divisions!;
                                sliderEnd =
                                    (sliderEnd * widget.divisions!).round() /
                                    widget.divisions!;
                              }
                              final startSliderValue =
                                  sliderStart * (widget.max - widget.min) +
                                  widget.min;
                              final endSliderValue =
                                  sliderEnd * (widget.max - widget.min) +
                                  widget.min;
                              final newSliderValue = SliderValue.ranged(
                                min(startSliderValue, endSliderValue),
                                max(startSliderValue, endSliderValue),
                              );
                              _dispatchValueChange(newSliderValue);
                              setState(() {
                                _currentValue = SliderValue.ranged(
                                  newStart,
                                  newEnd,
                                );
                              });
                            } else {
                              double newStart = _currentValue.start;
                              double newEnd = _currentValue.end + delta;
                              newStart = newStart.clamp(0, 1).toDouble();
                              newEnd = newEnd.clamp(0, 1).toDouble();
                              final newInternalSliderValue = SliderValue.ranged(
                                newStart,
                                newEnd,
                              );
                              if (newInternalSliderValue == _currentValue) {
                                return;
                              }
                              double sliderStart = newStart;
                              double sliderEnd = newEnd;
                              if (widget.divisions != null) {
                                sliderStart =
                                    (sliderStart * widget.divisions!).round() /
                                    widget.divisions!;
                                sliderEnd =
                                    (sliderEnd * widget.divisions!).round() /
                                    widget.divisions!;
                              }
                              final startSliderValue =
                                  sliderStart * (widget.max - widget.min) +
                                  widget.min;
                              final endSliderValue =
                                  sliderEnd * (widget.max - widget.min) +
                                  widget.min;
                              final newSliderValue = SliderValue.ranged(
                                min(startSliderValue, endSliderValue),
                                max(startSliderValue, endSliderValue),
                              );
                              _dispatchValueChange(newSliderValue);
                              setState(() {
                                _currentValue = SliderValue.ranged(
                                  newStart,
                                  newEnd,
                                );
                              });
                            }
                          }
                        : (details) {
                            final delta =
                                details.primaryDelta! / constraints.maxWidth;
                            double newValue = _currentValue.value + delta;
                            newValue = newValue.clamp(0, 1).toDouble();
                            double sliderValue = newValue;
                            if (widget.divisions != null) {
                              sliderValue =
                                  (sliderValue * widget.divisions!).round() /
                                  widget.divisions!;
                            }
                            final newSliderValue = SliderValue.single(
                              sliderValue * (widget.max - widget.min) +
                                  widget.min,
                            );
                            _dispatchValueChange(newSliderValue);
                            setState(() {
                              _currentValue = SliderValue.single(newValue);
                            });
                          }
                  : null,
              onHorizontalDragEnd: enabled
                  ? (details) {
                      _dragging = false;
                      if (_currentValue.isRanged) {
                        final start = _currentValue.start;
                        final end = _currentValue.end;
                        final newStart = min(start, end);
                        final newEnd = max(start, end);
                        _dispatchValueChangeEnd(
                          SliderValue.ranged(
                            newStart * (widget.max - widget.min) + widget.min,
                            newEnd * (widget.max - widget.min) + widget.min,
                          ),
                        );
                      } else {
                        _dispatchValueChangeEnd(
                          SliderValue.single(
                            _currentValue.value * (widget.max - widget.min) +
                                widget.min,
                          ),
                        );
                      }
                      setState(() {});
                    }
                  : null,
              child: MouseRegion(
                cursor: enabled
                    ? (widget.onChanged != null ||
                              widget.onChangeStart != null ||
                              widget.onChangeEnd != null)
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic
                    : SystemMouseCursors.forbidden,
                child: widget.value.isRanged
                    ? buildRangedSlider(constraints, context, theme)
                    : buildSingleSlider(constraints, context, theme),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildSingleSlider(
    BoxConstraints constraints,
    BuildContext context,
    ThemeData theme,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        buildTrackBar(context, constraints, theme),
        if (widget.hintValue != null) buildHint(context, constraints, theme),
        buildTrackValue(context, constraints, theme),
        buildThumb(
          context,
          constraints,
          theme,
          _currentValue.value,
          _focusing,
          (focusing) {
            setState(() {
              _focusing = focusing;
            });
          },

          /// On increase uses increaseStep or divisions or 1.
          /// And so decrease.
          () {
            double value = _currentValue.value;
            if (widget.divisions != null) {
              value = (value * widget.divisions!).round() / widget.divisions!;
            }
            final step = widget.increaseStep ?? 1 / (widget.divisions ?? 100);
            value = (value + step).clamp(0, 1).toDouble();
            double sliderValue = value;
            if (widget.divisions != null) {
              sliderValue =
                  (sliderValue * widget.divisions!).round() / widget.divisions!;
            }
            final newSliderValue = SliderValue.single(
              sliderValue * (widget.max - widget.min) + widget.min,
            );
            _dispatchValueChangeStart(newSliderValue);
            _dispatchValueChange(newSliderValue);
            _dispatchValueChangeEnd(newSliderValue);
            setState(() {
              _currentValue = SliderValue.single(value);
            });
          },
          () {
            double value = _currentValue.value;
            if (widget.divisions != null) {
              value = (value * widget.divisions!).round() / widget.divisions!;
            }
            final step = widget.decreaseStep ?? 1 / (widget.divisions ?? 100);
            value = (value - step).clamp(0, 1).toDouble();
            double sliderValue = value;
            if (widget.divisions != null) {
              sliderValue =
                  (sliderValue * widget.divisions!).round() / widget.divisions!;
            }
            final newSliderValue = SliderValue.single(
              sliderValue * (widget.max - widget.min) + widget.min,
            );
            _dispatchValueChangeStart(newSliderValue);
            _dispatchValueChange(newSliderValue);
            _dispatchValueChangeEnd(newSliderValue);
            setState(() {
              _currentValue = SliderValue.single(value);
            });
          },
        ),
      ],
    );
  }

  Widget buildHint(
    BuildContext context,
    BoxConstraints constraints,
    ThemeData theme,
  ) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return AnimatedValueBuilder(
      value: widget.hintValue,
      duration: _dragging ? Duration.zero : kDefaultDuration,
      builder: (context, hintValue, _) {
        final start = hintValue!.start;
        final end = hintValue.end;
        final newStart = min(start, end);
        final newEnd = max(start, end);
        final left =
            (newStart - widget.min) /
            (widget.max - widget.min) *
            constraints.maxWidth;
        final right =
            (1 - (newEnd - widget.min) / (widget.max - widget.min)) *
            constraints.maxWidth;

        return Positioned(
          left: _isRanged ? left : 0,
          top: 0,
          right: right,
          bottom: 0,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.scaleAlpha(0.2),
                borderRadius: BorderRadius.circular(theme.radiusSm),
              ),
              height: scaling * 6,
            ),
          ),
        );
      },
      curve: Curves.easeInOut,
      lerp: SliderValue.lerp,
    );
  }

  bool get _isRanged => widget.value.isRanged;

  Widget buildTrackValue(
    BuildContext context,
    BoxConstraints constraints,
    ThemeData theme,
  ) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<SliderTheme>(context);
    final value = widget.value;
    double start = value.start;
    double end = value.end;
    if (widget.divisions != null) {
      double normalizedStart = (start - widget.min) / (widget.max - widget.min);
      double normalizedEnd = (end - widget.min) / (widget.max - widget.min);
      normalizedStart =
          (normalizedStart * widget.divisions!).round() / widget.divisions!;
      normalizedEnd =
          (normalizedEnd * widget.divisions!).round() / widget.divisions!;
      start = normalizedStart * (widget.max - widget.min) + widget.min;
      end = normalizedEnd * (widget.max - widget.min) + widget.min;
    }
    final newStart = min(start, end);
    final newEnd = max(start, end);

    return AnimatedValueBuilder(
      value: Offset(newStart, newEnd),
      duration: _dragging && widget.divisions == null
          ? Duration.zero
          : kDefaultDuration,
      builder: (context, value, _) {
        final newStart = value!.dx;
        final newEnd = value.dy;
        final left =
            (newStart - widget.min) /
            (widget.max - widget.min) *
            constraints.maxWidth;
        final right =
            (1 - (newEnd - widget.min) / (widget.max - widget.min)) *
            constraints.maxWidth;

        return Positioned(
          left: _isRanged ? left : 0,
          top: 0,
          right: right,
          bottom: 0,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: enabled
                    ? (compTheme?.valueColor ?? theme.colorScheme.primary)
                    : (compTheme?.disabledValueColor ??
                          theme.colorScheme.mutedForeground),
                borderRadius: BorderRadius.circular(theme.radiusSm),
              ),
              height: (compTheme?.trackHeight ?? 6) * scaling,
            ),
          ),
        );
      },
      curve: Curves.easeInOut,
      lerp: Offset.lerp,
    );
  }

  Widget buildTrackBar(
    BuildContext context,
    BoxConstraints constraints,
    ThemeData theme,
  ) {
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<SliderTheme>(context);

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: enabled
                ? (compTheme?.trackColor ??
                      theme.colorScheme.primary.scaleAlpha(0.2))
                : (compTheme?.disabledTrackColor ?? theme.colorScheme.muted),
            borderRadius: BorderRadius.circular(theme.radiusSm),
          ),
          height: (compTheme?.trackHeight ?? 6) * scaling,
        ),
      ),
    );
  }

  Widget buildThumb(
    BuildContext context,
    BoxConstraints constraints,
    ThemeData theme,
    double value,
    bool focusing,
    ValueChanged<bool> onFocusing,
    VoidCallback onIncrease,
    VoidCallback onDecrease,
  ) {
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<SliderTheme>(context);
    if (widget.divisions != null) {
      value = (value * widget.divisions!).round() / widget.divisions!;
    }

    return AnimatedValueBuilder(
      value: value.toDouble(),
      duration: _dragging && widget.divisions == null
          ? Duration.zero
          : kDefaultDuration,
      builder: (context, value, _) {
        return Positioned(
          left: value! * constraints.maxWidth - scaling * 8,
          child: FocusableActionDetector(
            enabled: enabled,
            shortcuts: {
              LogicalKeySet(LogicalKeyboardKey.arrowLeft):
                  const DecreaseSliderValue(),
              LogicalKeySet(LogicalKeyboardKey.arrowRight):
                  const IncreaseSliderValue(),
              LogicalKeySet(LogicalKeyboardKey.arrowUp):
                  const IncreaseSliderValue(),
              LogicalKeySet(LogicalKeyboardKey.arrowDown):
                  const DecreaseSliderValue(),
            },
            actions: {
              IncreaseSliderValue: CallbackAction(
                onInvoke: (e) {
                  onIncrease();

                  return true;
                },
              ),
              DecreaseSliderValue: CallbackAction(
                onInvoke: (e) {
                  onDecrease();

                  return true;
                },
              ),
            },
            onShowFocusHighlight: (showHighlight) {
              onFocusing(showHighlight);
            },
            child: Container(
              decoration: BoxDecoration(
                color: compTheme?.thumbColor ?? theme.colorScheme.background,
                border: Border.all(
                  color: focusing
                      ? (enabled
                            ? (compTheme?.thumbFocusedBorderColor ??
                                  theme.colorScheme.primary)
                            : (compTheme?.disabledValueColor ??
                                  theme.colorScheme.mutedForeground))
                      : (enabled
                            ? (compTheme?.thumbBorderColor ??
                                  theme.colorScheme.primary.scaleAlpha(0.5))
                            : (compTheme?.disabledValueColor ??
                                  theme.colorScheme.mutedForeground)),
                  width: focusing ? scaling * 2 : scaling * 1,
                  strokeAlign: focusing
                      ? BorderSide.strokeAlignOutside
                      : BorderSide.strokeAlignInside,
                ),
                shape: BoxShape.circle,
              ),
              width: (compTheme?.thumbSize ?? 16) * scaling,
              height: (compTheme?.thumbSize ?? 16) * scaling,
            ),
          ),
        );
      },
      curve: Curves.easeInOut,
      lerp: lerpDouble,
    );
  }

  Widget buildRangedSlider(
    BoxConstraints constraints,
    BuildContext context,
    ThemeData theme,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        buildTrackBar(context, constraints, theme),
        if (widget.hintValue != null) buildHint(context, constraints, theme),
        buildTrackValue(context, constraints, theme),
        buildThumb(
          context,
          constraints,
          theme,
          min(_currentValue.start, _currentValue.end),
          _focusing,
          (focusing) {
            setState(() {
              _focusing = focusing;
            });
          },
          () {
            double value = _currentValue.start;
            if (widget.divisions != null) {
              value = (value * widget.divisions!).round() / widget.divisions!;
            }
            final step = widget.increaseStep ?? 1 / (widget.divisions ?? 100);
            value = (value + step).clamp(0, 1).toDouble();
            double sliderValue = value;
            if (widget.divisions != null) {
              sliderValue =
                  (sliderValue * widget.divisions!).round() / widget.divisions!;
            }
            final newSliderValue = SliderValue.ranged(
              sliderValue * (widget.max - widget.min) + widget.min,
              _currentValue.end * (widget.max - widget.min) + widget.min,
            );
            _dispatchValueChangeStart(newSliderValue);
            _dispatchValueChange(newSliderValue);
            _dispatchValueChangeEnd(newSliderValue);
            setState(() {
              _currentValue = SliderValue.ranged(value, _currentValue.end);
            });
          },
          () {
            double value = _currentValue.start;
            if (widget.divisions != null) {
              value = (value * widget.divisions!).round() / widget.divisions!;
            }
            final step = widget.decreaseStep ?? 1 / (widget.divisions ?? 100);
            value = (value - step).clamp(0, 1).toDouble();
            double sliderValue = value;
            if (widget.divisions != null) {
              sliderValue =
                  (sliderValue * widget.divisions!).round() / widget.divisions!;
            }
            final newSliderValue = SliderValue.ranged(
              sliderValue * (widget.max - widget.min) + widget.min,
              _currentValue.end * (widget.max - widget.min) + widget.min,
            );
            _dispatchValueChangeStart(newSliderValue);
            _dispatchValueChange(newSliderValue);
            _dispatchValueChangeEnd(newSliderValue);
            setState(() {
              _currentValue = SliderValue.ranged(value, _currentValue.end);
            });
          },
        ),
        buildThumb(
          context,
          constraints,
          theme,
          max(_currentValue.start, _currentValue.end),
          _focusingEnd,
          (focusing) {
            setState(() {
              _focusingEnd = focusing;
            });
          },
          () {
            double value = _currentValue.end;
            if (widget.divisions != null) {
              value = (value * widget.divisions!).round() / widget.divisions!;
            }
            final step = widget.increaseStep ?? 1 / (widget.divisions ?? 100);
            value = (value + step).clamp(0, 1).toDouble();
            double sliderValue = value;
            if (widget.divisions != null) {
              sliderValue =
                  (sliderValue * widget.divisions!).round() / widget.divisions!;
            }
            final newSliderValue = SliderValue.ranged(
              _currentValue.start * (widget.max - widget.min) + widget.min,
              sliderValue * (widget.max - widget.min) + widget.min,
            );
            _dispatchValueChangeStart(newSliderValue);
            _dispatchValueChange(newSliderValue);
            _dispatchValueChangeEnd(newSliderValue);
            setState(() {
              _currentValue = SliderValue.ranged(_currentValue.start, value);
            });
          },
          () {
            double value = _currentValue.end;
            if (widget.divisions != null) {
              value = (value * widget.divisions!).round() / widget.divisions!;
            }
            final step = widget.decreaseStep ?? 1 / (widget.divisions ?? 100);
            value = (value - step).clamp(0, 1).toDouble();
            double sliderValue = value;
            if (widget.divisions != null) {
              sliderValue =
                  (sliderValue * widget.divisions!).round() / widget.divisions!;
            }
            final newSliderValue = SliderValue.ranged(
              _currentValue.start * (widget.max - widget.min) + widget.min,
              sliderValue * (widget.max - widget.min) + widget.min,
            );
            _dispatchValueChangeStart(newSliderValue);
            _dispatchValueChange(newSliderValue);
            _dispatchValueChangeEnd(newSliderValue);
            setState(() {
              _currentValue = SliderValue.ranged(_currentValue.start, value);
            });
          },
        ),
      ],
    );
  }
}
