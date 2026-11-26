import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'slider.stories.g.dart';

/// Default upper bound of the slider range.
const _kDefaultMax = 100.0;

/// Default initial slider value.
const _kDefaultInitialValue = 50.0;

/// Initial value used by the ranged story.
const _kRangedInitialValue = 20.0;

/// Divisions count used by the divisions story.
const _kDefaultDivisions = 10;

/// Upper bound used by the divisions story (one unit per division).
const _kDivisionsMax = 10.0;

/// Initial value used by the divisions story.
const _kDivisionsInitialValue = 5.0;

/// Interactive demo host for [Slider] stories.
///
/// Manages the dragged value so the thumb follows the pointer. The
/// value resets to [initialValue] whenever that knob changes.
class SliderDemo extends StatefulWidget {
  /// Creates a [SliderDemo].
  const SliderDemo({
    super.key,
    this.initialValue = _kDefaultInitialValue,
    this.enabled = true,
    this.min = 0,
    this.max = _kDefaultMax,
    this.divisions,
  });

  /// Value shown before the user drags the thumb.
  final double initialValue;

  /// Whether the slider is interactive.
  final bool enabled;

  /// Lower bound of the slider range.
  final double min;

  /// Upper bound of the slider range.
  final double max;

  /// Number of discrete divisions (null = continuous).
  final int? divisions;

  @override
  State<SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<SliderDemo> {
  double? _value;

  @override
  void didUpdateWidget(SliderDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = null;
    }
  }

  void handleChanged(double newValue) {
    setState(() => _value = newValue);
  }

  @override
  Widget build(BuildContext context) {
    final value = (_value ?? widget.initialValue).clamp(widget.min, widget.max);

    return Slider(
      onChanged: widget.enabled ? handleChanged : null,
      value: value,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      enabled: widget.enabled,
    );
  }
}

/// Navigation metadata for the Slider component.
const kComponentMeta = ComponentMeta(name: 'Slider', path: 'form');

/// Story metadata for [SliderDemo].
const kMeta = Meta(SliderDemo.new);

/// Single-value slider with editable knobs.
final $Default = _Story();

/// Slider snapping to discrete divisions.
final $WithDivisions = _Story(
  name: 'With Divisions',
  args: _Args(
    initialValue: DoubleArg(_kDivisionsInitialValue),
    max: DoubleArg(_kDivisionsMax),
    divisions: NullableIntArg(_kDefaultDivisions),
  ),
);

/// Lower starting value ("ranged" in v3 — the unified [Slider] is
/// single-thumb, so this renders a single draggable value).
final $Ranged = _Story(
  args: _Args(initialValue: DoubleArg(_kRangedInitialValue)),
);
