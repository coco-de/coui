import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'bottom_action_bar.stories.g.dart';

// BottomActionBar widgetbook constants.
//
// The bar fills the width it is given, so the harness hands it a phone
// screen's width. The harness has no device frame, so its safe area is zero;
// the safe-area story states the inset itself.
const double _kScreenWidth = CoreLayout.layout400;

/// The bottom inset of a phone with a home indicator — the device's value,
/// not a token.
const double _kHomeIndicatorInset = 34;

void _handleNoop() {}

/// Knob input for [BottomActionBar] stories.
class BottomActionBarInput {
  /// Creates a [BottomActionBarInput].
  const BottomActionBarInput({
    this.description = 'By continuing you agree to the terms.',
    this.primaryLabel = 'Register',
    this.secondaryLabel = 'Not now',
    this.showSecondary = true,
    this.layout = CoreBottomActionBarLayout.defaultLayout,
    this.showDivider = CoreBottomActionBarContract.defaultShowDivider,
  });

  /// Note above the actions (hidden when empty).
  final String description;

  /// Label of the primary action.
  final String primaryLabel;

  /// Label of the secondary action.
  final String secondaryLabel;

  /// Whether the secondary action is drawn.
  final bool showSecondary;

  /// How the actions are arranged — one column or one row.
  final CoreBottomActionBarLayout layout;

  /// Whether the hairline above the bar is drawn.
  final bool showDivider;
}

/// Builds a [BottomActionBar] from [args].
BottomActionBar _bar(_Args args) => BottomActionBar(
  description: args.description.isEmpty ? null : Text(args.description),
  primaryAction: Button(
    size: .xl,
    onPressed: _handleNoop,
    child: Text(args.primaryLabel),
  ),
  secondaryAction: args.showSecondary
      ? Button(
          variant: .ghost,
          // 44 is not a step of the size ladder: the column's secondary is
          // the step below the primary, the row's matches it.
          size: args.layout == .horizontal ? .xl : .lg,
          onPressed: _handleNoop,
          child: Text(args.secondaryLabel),
        )
      : null,
  layout: args.layout,
  showDivider: args.showDivider,
);

/// Navigation metadata for the BottomActionBar component.
const kComponentMeta = ComponentMeta(name: 'BottomActionBar', path: 'layout');

/// Story metadata for [BottomActionBar].
const kMeta = Meta(BottomActionBar.new, argsType: BottomActionBarInput.new);

/// Default builder mapping [BottomActionBarInput] args to a
/// [BottomActionBar].
final BottomActionBarDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(width: _kScreenWidth, child: child),
  builder: (context, args) => _bar(args),
);

/// A note over a primary and a secondary action, one column.
final $Default = _Story();

/// One row of equal-width cells — the secondary action first, the primary
/// last.
final $Horizontal = _Story(
  name: 'Horizontal',
  args: _Args(
    layout: EnumArg(
      CoreBottomActionBarLayout.horizontal,
      values: CoreBottomActionBarLayout.values,
    ),
  ),
);

/// The primary action alone — no note, no secondary action.
final $PrimaryOnly = _Story(
  name: 'Primary Only',
  args: _Args(description: StringArg(''), showSecondary: BoolArg(false)),
);

/// No hairline above the bar.
final $NoDivider = _Story(
  name: 'No Divider',
  args: _Args(showDivider: BoolArg(false)),
);

/// A phone with a home indicator: the bar's bottom padding sits on top of
/// the device's bottom inset, and the surface paints under it.
final $SafeArea = _Story(
  name: 'Safe Area',
  setup: (context, child, args) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(padding: const EdgeInsets.only(bottom: _kHomeIndicatorInset)),
    child: SizedBox(width: _kScreenWidth, child: child),
  ),
);
