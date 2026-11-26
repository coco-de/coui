import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'aspect_ratio_box.stories.g.dart';

const _kBoxWidth = 280.0;
const double _kWidescreenRatio = 16 / 9;
const double _kStandardRatio = 4 / 3;
const _kSquareRatio = 1.0;
const double _kUltrawideRatio = 21 / 9;

/// Aspect ratio presets selectable from the knob panel.
enum AspectRatioOption {
  /// 1:1 square ratio.
  square,

  /// 4:3 standard ratio.
  standard,

  /// 21:9 ultrawide ratio.
  ultrawide,

  /// 16:9 widescreen ratio.
  widescreen,
}

/// Knob input for [AspectRatioBox] stories.
class AspectRatioBoxInput {
  /// Creates an [AspectRatioBoxInput].
  const AspectRatioBoxInput({this.ratio = AspectRatioOption.widescreen});

  /// Selected aspect ratio preset.
  final AspectRatioOption ratio;
}

/// Navigation metadata for the AspectRatioBox component.
const kComponentMeta = ComponentMeta(name: 'AspectRatioBox', path: 'display');

/// Story metadata for [AspectRatioBox].
const kMeta = Meta(AspectRatioBox.new, argsType: AspectRatioBoxInput.new);

/// Maps an [AspectRatioOption] knob value to its numeric ratio.
double _toRatio(AspectRatioOption option) => switch (option) {
  .widescreen => _kWidescreenRatio,
  .standard => _kStandardRatio,
  .square => _kSquareRatio,
  .ultrawide => _kUltrawideRatio,
};

/// Maps an [AspectRatioOption] knob value to its display label.
String _toLabel(AspectRatioOption option) => switch (option) {
  .widescreen => '16 / 9',
  .standard => '4 / 3',
  .square => '1',
  .ultrawide => '21 / 9',
};

/// Default builder mapping [AspectRatioBoxInput] args to an
/// [AspectRatioBox].
final AspectRatioBoxDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(
    width: _kBoxWidth,
    child: child,
  ),
  builder: (context, args) => AspectRatioBox(
    ratio: _toRatio(args.ratio),
    child: Card(
      child: Center(child: Text(_toLabel(args.ratio)).titleMedium),
    ),
  ),
);

/// Widescreen ratio box with editable knobs.
final $Default = _Story();

/// Square (1:1) ratio box.
final $Square = _Story(
  args: _Args(
    ratio: EnumArg(
      AspectRatioOption.square,
      values: AspectRatioOption.values,
    ),
  ),
);
