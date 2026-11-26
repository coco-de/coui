import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'range.stories.g.dart';

// Range widgetbook constants.
const _kInitialMinValue = 20.0;
const _kInitialMaxValue = 80.0;
const _kDefaultDivisions = 5;

/// Interactive demo host for [Range] stories.
class RangeDemo extends material.StatefulWidget {
  /// Creates a [RangeDemo].
  const RangeDemo({
    super.key,
    this.enabled = true,
    this.stepped = false,
    this.divisions = _kDefaultDivisions,
  });

  /// Whether the range thumbs can be dragged.
  final bool enabled;

  /// Whether the range snaps to [divisions] discrete steps.
  final bool stepped;

  /// Number of discrete divisions used when [stepped] is true.
  final int divisions;

  @override
  material.State<RangeDemo> createState() => _RangeDemoState();
}

class _RangeDemoState extends material.State<RangeDemo> {
  double _min = _kInitialMinValue;
  double _max = _kInitialMaxValue;

  void handleRangeChanged({required double min, required double max}) {
    setState(() {
      _min = min;
      _max = max;
    });
  }

  @override
  material.Widget build(material.BuildContext context) {
    return Range(
      onChanged: widget.enabled
          ? (min, max) => handleRangeChanged(min: min, max: max)
          : null,
      minValue: _min,
      maxValue: _max,
      divisions: widget.stepped ? widget.divisions : null,
      enabled: widget.enabled,
    );
  }
}

/// Navigation metadata for the Range component.
const kComponentMeta = ComponentMeta(name: 'Range', path: 'form');

/// Story metadata for [RangeDemo].
const kMeta = Meta(RangeDemo.new);

/// Interactive range with draggable thumbs.
final $Default = _Story();

/// Range snapping to discrete divisions.
final $Stepped = _Story(
  args: _Args(stepped: BoolArg(true)),
);

/// Disabled range that ignores drags.
final $Disabled = _Story(
  args: _Args(enabled: BoolArg(false)),
);
