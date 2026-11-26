import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'step_item.stories.g.dart';

// StepItem widgetbook constants.
//
// A step row fills the width it is given and pins its trailing note to the
// end, so the harness has to hand it a bounded width the way a card or a
// `Steps` list would.
const _kRowWidth = 280.0;

/// Knob input for [StepItem] stories.
class StepItemInput {
  /// Creates a [StepItemInput].
  const StepItemInput({
    this.title = 'Run tests',
    this.status = CoreStepStatus.defaultStatus,
    this.trailing = '41s',
  });

  /// Step name — one line, cut with an ellipsis when it does not fit.
  final String title;

  /// Where the step stands — picks the glyph and the colours.
  final CoreStepStatus status;

  /// Note pinned to the end of the row — hidden when empty.
  final String trailing;
}

/// Builds a [StepItem] from [args].
StepItem _row(_Args args) => StepItem(
  title: args.title,
  status: args.status,
  trailing: args.trailing.isEmpty ? null : args.trailing,
);

/// Navigation metadata for the StepItem component.
const kComponentMeta = ComponentMeta(name: 'StepItem', path: 'layout');

/// Story metadata for [StepItem].
const kMeta = Meta(StepItem.new, argsType: StepItemInput.new);

/// Default builder mapping [StepItemInput] args to a [StepItem].
final StepItemDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(width: _kRowWidth, child: child),
  builder: (context, args) => _row(args),
);

/// A step nobody has reached yet — the quietest status, and the default.
/// Walk the status knob through the whole [CoreStepStatus] set.
final $Default = _Story();

/// Finished step — a `circle-check` in `success`.
final $Done = _Story(
  args: _Args(
    title: StringArg('Install dependencies'),
    status: EnumArg(CoreStepStatus.done, values: CoreStepStatus.values),
    trailing: StringArg('12s'),
  ),
);

/// Step in progress — a `circle-dot` in `primary`.
final $Current = _Story(
  args: _Args(
    status: EnumArg(CoreStepStatus.current, values: CoreStepStatus.values),
  ),
);

/// Step that ran and stopped — a `circle-x` in `error`, with the reason in
/// the error family's text ink.
final $Failed = _Story(
  args: _Args(
    title: StringArg('Lint'),
    status: EnumArg(CoreStepStatus.failed, values: CoreStepStatus.values),
    trailing: StringArg('exit 1'),
  ),
);

/// Row without a note — the title takes the whole width and the gap before
/// the note goes with it.
final $WithoutTrailing = _Story(
  name: 'Without Trailing',
  args: _Args(trailing: StringArg('')),
);

/// A title longer than the row — it ends in an ellipsis and the note keeps
/// its width.
final $LongTitle = _Story(
  name: 'Long Title',
  args: _Args(
    title: StringArg('Install dependencies from the private package registry'),
  ),
);
