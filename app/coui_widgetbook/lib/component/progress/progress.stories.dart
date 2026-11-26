import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'progress.stories.g.dart';

// Progress widgetbook constants.
const _kProgressInitial = 65.0;
const _kProgressMax = 100.0;

/// Knob input for [Progress] stories.
class ProgressInput {
  /// Creates a [ProgressInput].
  const ProgressInput({
    this.value = _kProgressInitial,
    this.max = _kProgressMax,
    this.indeterminate = false,
    this.disableAnimation = false,
    this.size = CoreProgressSize.defaultSize,
    this.tone = CoreProgressTone.defaultTone,
    this.label = '',
    this.valueLabel = '',
    this.caption = '',
  });

  /// Current progress value (ignored when [indeterminate] is true).
  final double value;

  /// Maximum progress value.
  final double max;

  /// Whether the bar renders the looping indeterminate animation.
  final bool indeterminate;

  /// Whether the value-change animation is disabled.
  final bool disableAnimation;

  /// Bar thickness step.
  final CoreProgressSize size;

  /// What the fill colour means.
  final CoreProgressTone tone;

  /// Text of the cell above the bar on the left — empty for no cell.
  final String label;

  /// Text of the cell above the bar on the right — empty for no cell.
  final String valueLabel;

  /// Text of the cell below the bar — empty for no cell.
  final String caption;
}

/// Navigation metadata for the Progress component.
const kComponentMeta = ComponentMeta(name: 'Progress', path: 'display');

/// Story metadata for [Progress].
const kMeta = Meta(Progress.new, argsType: ProgressInput.new);

/// Default builder mapping [ProgressInput] args to a [Progress].
final ProgressDefaults defaults = _Defaults(
  builder: (context, args) => Progress(
    value: args.indeterminate ? null : args.value,
    max: args.max,
    disableAnimation: args.disableAnimation,
    size: args.size,
    tone: args.tone,
    label: args.label.isEmpty ? null : Text(args.label),
    valueLabel: args.valueLabel.isEmpty ? null : Text(args.valueLabel),
    caption: args.caption.isEmpty ? null : Text(args.caption),
  ),
);

/// Determinate progress bar with editable knobs.
final $Default = _Story();

/// Indeterminate progress bar (no value).
final $Indeterminate = _Story(
  args: _Args(indeterminate: BoolArg(true)),
);

/// A quota close to its limit — the warning tone over the neutral track.
final $Tone = _Story(
  args: _Args(
    tone: EnumArg(CoreProgressTone.warning, values: CoreProgressTone.values),
  ),
);

/// The three cells — a label and its value above the bar, a caption below.
final $Labelled = _Story(
  args: _Args(
    label: StringArg('Team plan'),
    valueLabel: StringArg('62%'),
    caption: StringArg('AI usage · 18 days left'),
  ),
);
