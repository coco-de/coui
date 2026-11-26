import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'tooltip.stories.g.dart';

/// Knob input for [Tooltip] stories.
class TooltipInput {
  /// Creates a [TooltipInput].
  const TooltipInput({
    this.message = 'Helpful message',
    this.position = CoreTooltipPosition.top,
    this.showIconChild = true,
    this.label = 'Hover me',
  });

  /// Tooltip message text.
  final String message;

  /// Side of the child where the tooltip appears.
  final CoreTooltipPosition position;

  /// Whether the anchor is an info icon instead of a button.
  final bool showIconChild;

  /// Button label used when [showIconChild] is false.
  final String label;
}

/// Navigation metadata for the Tooltip component.
const kComponentMeta = ComponentMeta(name: 'Tooltip', path: 'overlay');

/// Story metadata for [Tooltip].
const kMeta = Meta(Tooltip.new, argsType: TooltipInput.new);

void _handleNoop() {}

/// Default builder mapping [TooltipInput] args to a [Tooltip].
final TooltipDefaults defaults = _Defaults(
  builder: (context, args) => Tooltip(
    message: args.message,
    position: args.position,
    child: args.showIconChild
        ? const Icon(
            LucideIcons.info,
            iconStyle: CoreIconStyle(size: CoreSpace.space24),
          )
        : Button(
            onPressed: _handleNoop,
            child: Text(args.label),
          ),
  ),
);

/// Tooltip on an info icon with editable knobs.
final $Default = _Story();

/// Tooltip above a button.
final $Top = _Story(
  args: _Args(
    position: EnumArg(
      CoreTooltipPosition.top,
      values: CoreTooltipPosition.values,
    ),
    showIconChild: BoolArg(false),
    label: StringArg('Top'),
  ),
);

/// Tooltip below a button.
final $Bottom = _Story(
  args: _Args(
    position: EnumArg(
      CoreTooltipPosition.bottom,
      values: CoreTooltipPosition.values,
    ),
    showIconChild: BoolArg(false),
    label: StringArg('Bottom'),
  ),
);

/// Tooltip to the left of a button.
final $Left = _Story(
  args: _Args(
    position: EnumArg(
      CoreTooltipPosition.left,
      values: CoreTooltipPosition.values,
    ),
    showIconChild: BoolArg(false),
    label: StringArg('Left'),
  ),
);

/// Tooltip to the right of a button.
final $Right = _Story(
  args: _Args(
    position: EnumArg(
      CoreTooltipPosition.right,
      values: CoreTooltipPosition.values,
    ),
    showIconChild: BoolArg(false),
    label: StringArg('Right'),
  ),
);
