import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'navigation_bar_item.stories.g.dart';

// NavigationBarItem widgetbook constants.
//
// A sidebar row fills the width it is given, so the harness hands it a
// sidebar's width.
const double _kSidebarWidth = CoreLayout.layout240;

void _handleNoop() {}

/// Knob input for [NavigationBarItem] stories.
class NavigationBarItemInput {
  /// Creates a [NavigationBarItemInput].
  const NavigationBarItemInput({
    this.label = 'Inbox',
    this.showIcon = true,
    this.showCount = true,
    this.selected = false,
    this.enabled = true,
  });

  /// The destination's name.
  final String label;

  /// Whether the row leads with an icon.
  final bool showIcon;

  /// Whether a count badge sits at the row's far end.
  final bool showCount;

  /// Whether the row is the current place.
  final bool selected;

  /// Whether the row can be activated.
  final bool enabled;
}

/// Builds a [NavigationBarItem] from [args].
NavigationBarItem _item(_Args args) => NavigationBarItem(
  icon: args.showIcon ? const Icon(LucideIcons.inbox) : null,
  label: args.label,
  badge: args.showCount
      ? const Badge(
          form: CoreBadgeForm.count,
          tone: CoreBadgeTone.info,
          variant: CoreBadgeVariant.filled,
          size: CoreComponentSize.xs,
          child: Text('3'),
        )
      : null,
  selected: args.selected,
  enabled: args.enabled,
  onPressed: _handleNoop,
);

/// Navigation metadata for the NavigationBarItem component.
const kComponentMeta = ComponentMeta(
  name: 'NavigationBarItem',
  path: 'navigation',
);

/// Story metadata for [NavigationBarItem].
const kMeta = Meta(
  NavigationBarItem.new,
  argsType: NavigationBarItemInput.new,
);

/// Default builder mapping [NavigationBarItemInput] args to a
/// [NavigationBarItem].
final NavigationBarItemDefaults defaults = _Defaults(
  setup: (context, child, args) =>
      SizedBox(width: _kSidebarWidth, child: child),
  builder: (context, args) => _item(args),
);

/// A sidebar row — icon, name and count.
final $Default = _Story();

/// The current place: the selected face and label.
final $Selected = _Story(
  name: 'Selected',
  args: _Args(selected: BoolArg(true)),
);

/// A row that cannot be activated — never drawn selected.
final $Disabled = _Story(
  name: 'Disabled',
  args: _Args(enabled: BoolArg(false)),
);

/// A name alone, the bare-label row.
final $LabelOnly = _Story(
  name: 'Label Only',
  args: _Args(showIcon: BoolArg(false), showCount: BoolArg(false)),
);
