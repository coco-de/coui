import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A horizontal [coui.NavigationBar] use case.
@UseCase(
  name: 'horizontal',
  type: coui.NavigationBar,
)
Widget buildNavigationBarHorizontalUseCase(BuildContext context) {
  final selectedIndex = context.knobs.int.slider(
    initialValue: 0,
    label: 'selectedIndex',
    min: 0,
    max: 4,
  );

  return coui.NavigationBar(
    index: selectedIndex,
    direction: Axis.horizontal,
    labelType: coui.NavigationLabelType.all,
    children: [
      coui.NavigationItem(
        label: const Text('Home'),
        child: const Icon(Icons.home),
      ),
      coui.NavigationItem(
        label: const Text('Search'),
        child: const Icon(Icons.search),
      ),
      coui.NavigationItem(
        label: const Text('Favorites'),
        child: const Icon(Icons.favorite),
      ),
      coui.NavigationItem(
        label: const Text('Profile'),
        child: const Icon(Icons.person),
      ),
      coui.NavigationItem(
        label: const Text('Settings'),
        child: const Icon(Icons.settings),
      ),
    ],
  );
}

/// A vertical [coui.NavigationRail] use case.
@UseCase(
  name: 'vertical rail',
  type: coui.NavigationRail,
)
Widget buildNavigationRailUseCase(BuildContext context) {
  final selectedIndex = context.knobs.int.slider(
    initialValue: 0,
    label: 'selectedIndex',
    min: 0,
    max: 4,
  );

  return SizedBox(
    height: 400,
    child: coui.NavigationRail(
      index: selectedIndex,
      labelType: coui.NavigationLabelType.selected,
      children: [
        coui.NavigationItem(
          label: const Text('Home'),
          child: const Icon(Icons.home),
        ),
        coui.NavigationItem(
          label: const Text('Search'),
          child: const Icon(Icons.search),
        ),
        const coui.NavigationDivider(),
        coui.NavigationItem(
          label: const Text('Settings'),
          child: const Icon(Icons.settings),
        ),
        coui.NavigationItem(
          label: const Text('Help'),
          child: const Icon(Icons.help),
        ),
      ],
    ),
  );
}

/// A [coui.NavigationSidebar] use case.
@UseCase(
  name: 'sidebar',
  type: coui.NavigationSidebar,
)
Widget buildNavigationSidebarUseCase(BuildContext context) {
  final selectedIndex = context.knobs.int.slider(
    initialValue: 0,
    label: 'selectedIndex',
    min: 0,
    max: 5,
  );

  return SizedBox(
    height: 500,
    child: coui.NavigationSidebar(
      index: selectedIndex,
      children: [
        const coui.NavigationLabel(child: Text('MAIN')),
        coui.NavigationItem(
          label: const Text('Dashboard'),
          child: const Icon(Icons.dashboard),
        ),
        coui.NavigationItem(
          label: const Text('Analytics'),
          child: const Icon(Icons.analytics),
        ),
        const coui.NavigationDivider(),
        const coui.NavigationLabel(child: Text('SETTINGS')),
        coui.NavigationItem(
          label: const Text('Profile'),
          child: const Icon(Icons.person),
        ),
        coui.NavigationItem(
          label: const Text('Preferences'),
          child: const Icon(Icons.settings),
        ),
        coui.NavigationItem(
          label: const Text('Help'),
          child: const Icon(Icons.help),
        ),
      ],
    ),
  );
}