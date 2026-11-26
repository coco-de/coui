import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'join.stories.g.dart';

/// Knob input for [Join] stories.
class JoinInput {
  /// Creates a [JoinInput].
  const JoinInput({this.vertical = false});

  /// Whether children are joined along the vertical axis.
  final bool vertical;
}

/// Navigation metadata for the Join component.
const kComponentMeta = ComponentMeta(name: 'Join', path: 'layout');

/// Story metadata for [Join].
const kMeta = Meta(Join.new, argsType: JoinInput.new);

void _handleNoop() {}

/// Default builder mapping [JoinInput] args to a [Join] of buttons.
final JoinDefaults defaults = _Defaults(
  builder: (context, args) => Join(
    vertical: args.vertical,
    children: const [
      Button(
        onPressed: _handleNoop,
        variant: .outline,
        child: Text('1'),
      ),
      Button(
        onPressed: _handleNoop,
        variant: .outline,
        child: Text('2'),
      ),
      Button(
        onPressed: _handleNoop,
        variant: .outline,
        child: Text('3'),
      ),
    ],
  ),
);

/// Horizontal join of outline buttons with editable knobs.
final $Default = _Story();

/// Vertically joined buttons.
final $Vertical = _Story(
  args: _Args(vertical: BoolArg(true)),
);
