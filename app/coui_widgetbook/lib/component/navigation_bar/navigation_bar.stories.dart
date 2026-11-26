import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_widgetbook/preview/surface_preview.dart';
import 'package:widgetbook/widgetbook.dart';

part 'navigation_bar.stories.g.dart';

// analyzer requires explicit type here.
const _kBarItems = <CoreNavigationBarItem<Widget>>[
  CoreNavigationBarItem.destination(
    icon: Icon(LucideIcons.house),
    label: 'Home',
  ),
  CoreNavigationBarItem.destination(
    icon: Icon(LucideIcons.search),
    label: 'Search',
  ),
  CoreNavigationBarItem.destination(
    icon: Icon(LucideIcons.heart),
    label: 'Favorites',
  ),
  CoreNavigationBarItem.destination(
    icon: Icon(LucideIcons.user),
    label: 'Profile',
  ),
];

// analyzer requires explicit type here.
const _kSidebarItems = <CoreNavigationBarItem<Widget>>[
  CoreNavigationBarItem.label('Main'),
  CoreNavigationBarItem.destination(
    icon: Icon(LucideIcons.house),
    label: 'Home',
  ),
  CoreNavigationBarItem.destination(
    icon: Icon(LucideIcons.search),
    label: 'Search',
    // A count rides at the row's trailing end in a sidebar (and over the
    // icon's top-end corner in the bar and the rail).
    badge: Badge(
      form: CoreBadgeForm.count,
      tone: CoreBadgeTone.info,
      variant: CoreBadgeVariant.filled,
      size: CoreComponentSize.xs,
      child: Text('3'),
    ),
  ),
  CoreNavigationBarItem.divider(),
  CoreNavigationBarItem.label('Other'),
  CoreNavigationBarItem.destination(
    icon: Icon(LucideIcons.heart),
    label: 'Favorites',
  ),
  CoreNavigationBarItem.destination(
    icon: Icon(LucideIcons.settings),
    label: 'Settings',
  ),
];

/// Interactive demo host for [NavigationBar] stories.
class NavigationBarDemo extends StatefulWidget {
  /// Creates a [NavigationBarDemo].
  const NavigationBarDemo({
    super.key,
    this.mode = CoreNavigationBarMode.bar,
    this.labelMode = CoreNavigationLabelMode.all,
    this.alignment = CoreNavigationAlignment.center,
  });

  /// Layout mode of the navigation bar.
  final CoreNavigationBarMode mode;

  /// When item labels are shown.
  final CoreNavigationLabelMode labelMode;

  /// Item distribution along the main axis.
  final CoreNavigationAlignment alignment;

  @override
  State<NavigationBarDemo> createState() => _NavigationBarDemoState();
}

class _NavigationBarDemoState extends State<NavigationBarDemo> {
  int _selectedIndex = 0;

  void handleSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isSidebar = widget.mode == .sidebar;
    final bar = NavigationBar(
      items: isSidebar ? _kSidebarItems : _kBarItems,
      selectedIndex: _selectedIndex,
      onSelected: handleSelected,
      mode: widget.mode,
      labelMode: widget.labelMode,
      alignment: widget.alignment,
      // The footer sits inside the bar's chrome, after the items.
      footer: isSidebar
          ? const Text('Free plan · 3 of 5 seats').labelMedium.onSurfaceVariant
          : null,
    );
    final detail = Expanded(
      child: Center(child: Text('Selected: $_selectedIndex')),
    );

    return widget.mode == .bar
        ? SurfaceChromePreview(footer: bar)
        : Row(children: [bar, detail]);
  }
}

/// Navigation metadata for the NavigationBar component.
const kComponentMeta = ComponentMeta(name: 'NavigationBar', path: 'navigation');

/// Story metadata for [NavigationBarDemo].
const kMeta = Meta(NavigationBarDemo.new);

/// Material and layout controls rebuild the demo without resetting selection.
final NavigationBarDemoDefaults defaults = _Defaults(
  setup: (context, child, args) => child,
);

/// Horizontal bar with labels always shown.
final $Default = _Story();

/// Vertical compact rail with the selected label shown.
final $Rail = _Story(
  args: _Args(
    mode: EnumArg(
      CoreNavigationBarMode.rail,
      values: CoreNavigationBarMode.values,
    ),
    labelMode: EnumArg(
      CoreNavigationLabelMode.selected,
      values: CoreNavigationLabelMode.values,
    ),
  ),
);

/// Expanded sidebar with section labels and dividers.
final $Sidebar = _Story(
  args: _Args(
    mode: EnumArg(
      CoreNavigationBarMode.sidebar,
      values: CoreNavigationBarMode.values,
    ),
    alignment: EnumArg(
      CoreNavigationAlignment.start,
      values: CoreNavigationAlignment.values,
    ),
  ),
);
