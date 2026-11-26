import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'panel_header.stories.g.dart';

// PanelHeader widgetbook constants.
//
// The header fills the width it is given, so the harness hands it a panel's
// width.
const double _kPanelWidth = CoreLayout.layout400;

void _handleNoop() {}

/// Knob input for [PanelHeader] stories.
class PanelHeaderInput {
  /// Creates a [PanelHeaderInput].
  const PanelHeaderInput({
    this.title = 'Recent files',
    this.showAction = true,
    this.headingLevel = CorePanelHeaderContract.defaultHeadingLevel,
  });

  /// Panel title text.
  final String title;

  /// Whether a small ghost action sits at the end of the row.
  final bool showAction;

  /// Heading level of the title, 1–6.
  final int headingLevel;
}

/// Builds a [PanelHeader] from [args].
PanelHeader _header(_Args args) => PanelHeader(
  title: Text(args.title),
  action: args.showAction
      ? const Button(
          variant: .ghost,
          size: .sm,
          onPressed: _handleNoop,
          child: Text('View all'),
        )
      : null,
  headingLevel: args.headingLevel.clamp(1, 6),
);

/// Navigation metadata for the PanelHeader component.
const kComponentMeta = ComponentMeta(name: 'PanelHeader', path: 'layout');

/// Story metadata for [PanelHeader].
const kMeta = Meta(PanelHeader.new, argsType: PanelHeaderInput.new);

/// Default builder mapping [PanelHeaderInput] args to a [PanelHeader].
final PanelHeaderDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(width: _kPanelWidth, child: child),
  builder: (context, args) => _header(args),
);

/// A title and a small ghost action, centred on each other.
final $Default = _Story();

/// The title alone.
final $WithoutAction = _Story(
  name: 'Without Action',
  args: _Args(showAction: BoolArg(false)),
);

/// A title long enough to take two lines — the action stays centred on it.
final $LongTitle = _Story(
  name: 'Long Title',
  args: _Args(
    title: StringArg('Files shared with you across every workspace'),
  ),
);
