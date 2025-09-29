import 'package:core/core.dart' hide UseCase;
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// NavBar 유즈케이스
@UseCase(
  name: 'Navigation',
  type: NavBar,
  path: '[Component]',
)
Widget buildWidgetbookNavigationUseCase(BuildContext context) {
  final isShowNavigationRail = context.breakpoint.largerThan(MOBILE);
  const label = 'Navigation';
  final menuItems = <NavigationRailItem>[
    (
      icon: Icon(
        FluentIcons.home_24_regular,
        color: context.colorScheme.onSurfaceVariant,
      ),
      selectedIcon: Icon(
        FluentIcons.home_24_filled,
        color: context.colorScheme.onSurfaceVariant,
      ),
      label: context.i10n.main.bottom_navigation_home,
      children: null,
      enabled: true,
    ),
    (
      icon: Icon(
        FluentIcons.comment_24_regular,
        color: context.colorScheme.onSurfaceVariant,
      ),
      selectedIcon: Icon(
        FluentIcons.comment_24_filled,
        color: context.colorScheme.onSurfaceVariant,
      ),
      label: context.i10n.main.bottom_navigation_community,
      children: null,
      enabled: true,
    ),
    (
      icon: Icon(
        FluentIcons.person_24_regular,
        color: context.colorScheme.onSurfaceVariant,
      ),
      selectedIcon: Icon(
        FluentIcons.person_24_filled,
        color: context.colorScheme.onSurfaceVariant,
      ),
      label: context.i10n.main.bottom_navigation_my_page,
      children: null,
      enabled: true,
    ),
  ];
  final selectedIndex = context.knobs.object.dropdown<int>(
    initialOption: 0,
    label: label,
    labelBuilder: (index) => menuItems[index].label,
    options: List.generate(5, (i) => i),
  );

  return Scaffold(
    body: SafeArea(
      child: isShowNavigationRail
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                NavRail(
                  collapsedWidth: 30,
                  items: menuItems,
                  onItemTapped: (BuildContext context, int index) {
                    WidgetbookState.of(context).updateQueryField(
                      field: label,
                      group: 'knobs',
                      value: menuItems[index].label,
                    );
                  },
                  selectedIndex: selectedIndex,
                  width: 120,
                ),
                Expanded(
                  child: Center(
                    child: Text(menuItems[selectedIndex].label),
                  ),
                ),
              ],
            )
          : Center(
              child: Text('$selectedIndex'),
            ),
    ),
    bottomNavigationBar: isShowNavigationRail
        ? null
        : NavBar(
            items: menuItems,
            onItemTapped: (BuildContext context, int index) {
              WidgetbookState.of(context).updateQueryField(
                field: label,
                group: 'knobs',
                value: menuItems[index].label,
              );
            },
            selectedIndex: selectedIndex,
          ),
  );
}
