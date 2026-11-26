import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'loading_region.stories.g.dart';

/// Width of the skeleton lines the region announces for.
const _kLineWidth = 240.0;

/// Height of each skeleton line.
const _kLineHeight = 20.0;

/// Knob input for [LoadingRegion] stories.
class LoadingRegionInput {
  /// Creates a [LoadingRegionInput].
  const LoadingRegionInput({
    this.semanticLabel = 'Loading orders',
    this.lines = 3,
  });

  /// What the region announces.
  final String semanticLabel;

  /// How many skeleton lines the region wraps — still one announcement.
  final int lines;
}

/// Navigation metadata for the LoadingRegion component.
const kComponentMeta = ComponentMeta(name: 'LoadingRegion', path: 'display');

/// Story metadata for [LoadingRegion].
const kMeta = Meta(LoadingRegion.new, argsType: LoadingRegionInput.new);

/// Default builder mapping [LoadingRegionInput] args to a [LoadingRegion].
final LoadingRegionDefaults defaults = _Defaults(
  builder: (context, args) => LoadingRegion(
    semanticLabel: args.semanticLabel,
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: CoreSpace.space8,
      children: [
        for (var i = 0; i < args.lines; i++)
          const Skeleton(width: _kLineWidth, height: _kLineHeight),
      ],
    ),
  ),
);

/// Three skeleton lines announced once, with editable knobs.
final $Default = _Story();
