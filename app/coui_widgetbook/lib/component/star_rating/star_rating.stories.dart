import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'star_rating.stories.g.dart';

const _kDefaultMax = 5.0;
const _kDefaultStep = 0.5;
const _kInitialRating = 3.5;

/// Interactive demo host for [ControlledStarRating] stories.
class StarRatingDemo extends StatefulWidget {
  /// Creates a [StarRatingDemo].
  const StarRatingDemo({
    super.key,
    this.enabled = true,
    this.max = _kDefaultMax,
    this.step = _kDefaultStep,
  });

  /// Whether the rating reacts to user input.
  final bool enabled;

  /// Maximum rating value.
  final double max;

  /// Rating step granularity.
  final double step;

  @override
  State<StarRatingDemo> createState() => _StarRatingDemoState();
}

class _StarRatingDemoState extends State<StarRatingDemo> {
  final _controller = StarRatingController(_kInitialRating);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space16,
      children: [
        ControlledStarRating(
          controller: _controller,
          enabled: widget.enabled,
          max: widget.max,
          step: widget.step,
        ),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Text('Rating: ${_controller.value.toStringAsFixed(1)}');
          },
        ),
      ],
    );
  }
}

/// Navigation metadata for the StarRating component.
const kComponentMeta = ComponentMeta(name: 'StarRating', path: 'form');

/// Story metadata for [StarRatingDemo].
const kMeta = Meta(StarRatingDemo.new);

/// Interactive star rating with editable knobs.
final $Default = _Story();
