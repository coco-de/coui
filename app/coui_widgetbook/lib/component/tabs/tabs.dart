import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Tabs] use case.
@UseCase(
  name: 'default',
  type: coui.Tabs,
)
Widget buildTabsDefaultUseCase(BuildContext context) {
  final index = context.knobs.int.slider(
    label: 'active tab',
    max: 2,
  );

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      coui.Tabs(
        index: index,
        onChanged: (i) => debugPrint('tabs-default changed: $i'),
        children: [
          coui.TabItem(
            child: Text(
              context.knobs.string(
                initialValue: 'Tab 1',
                label: 'tab 1 label',
              ),
            ),
          ),
          coui.TabItem(
            child: Text(
              context.knobs.string(
                initialValue: 'Tab 2',
                label: 'tab 2 label',
              ),
            ),
          ),
          coui.TabItem(
            child: Text(
              context.knobs.string(
                initialValue: 'Tab 3',
                label: 'tab 3 label',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      IndexedStack(
        index: index,
        children: const [
          Center(child: Text('Content of Tab 1')),
          Center(child: Text('Content of Tab 2')),
          Center(child: Text('Content of Tab 3')),
        ],
      ),
    ],
  );
}

/// A [coui.Tabs] with icons use case.
@UseCase(
  name: 'with icons',
  type: coui.Tabs,
)
Widget buildTabsWithIconsUseCase(BuildContext context) {
  final index = context.knobs.int.slider(
    label: 'active tab',
    max: 2,
  );

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      coui.Tabs(
        index: index,
        onChanged: (i) => debugPrint('tabs-icons changed: $i'),
        children: const [
          coui.TabItem(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home, size: 20),
                SizedBox(width: 8),
                Text('Home'),
              ],
            ),
          ),
          coui.TabItem(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 20),
                SizedBox(width: 8),
                Text('Profile'),
              ],
            ),
          ),
          coui.TabItem(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings, size: 20),
                SizedBox(width: 8),
                Text('Settings'),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      IndexedStack(
        index: index,
        children: const [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home, size: 48),
                SizedBox(height: 16),
                Text('Home Content'),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 48),
                SizedBox(height: 16),
                Text('Profile Content'),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings, size: 48),
                SizedBox(height: 16),
                Text('Settings Content'),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

/// A [coui.Tabs] with disabled tab use case.
@UseCase(
  name: 'with disabled',
  type: coui.Tabs,
)
Widget buildTabsWithDisabledUseCase(BuildContext context) {
  final index = context.knobs.int.slider(
    label: 'active tab',
    max: 2,
  );

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      coui.Tabs(
        index: index,
        onChanged: (i) => debugPrint('tabs-disabled changed: $i'),
        children: const [
          coui.TabItem(child: Text('Enabled')),
          coui.TabItem(child: Text('Disabled')),
          coui.TabItem(child: Text('Another Tab')),
        ],
      ),
      const SizedBox(height: 12),
      IndexedStack(
        index: index,
        children: const [
          Center(child: Text('This tab is enabled')),
          Center(child: Text('This tab is disabled')),
          Center(child: Text('Another enabled tab')),
        ],
      ),
    ],
  );
}

/// A controlled [coui.Tabs] use case.
@UseCase(
  name: 'controlled',
  type: coui.Tabs,
)
Widget buildTabsControlledUseCase(BuildContext context) {
  final index = context.knobs.int.slider(
    label: 'active tab',
    max: 2,
  );

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      coui.Tabs(
        index: index,
        onChanged: (i) {
          // ignore: avoid_print
          print('Tab changed to: $i');
        },
        children: const [
          coui.TabItem(child: Text('Tab 1')),
          coui.TabItem(child: Text('Tab 2')),
          coui.TabItem(child: Text('Tab 3')),
        ],
      ),
      const SizedBox(height: 12),
      IndexedStack(
        index: index,
        children: const [
          Center(child: Text('Content 1')),
          Center(child: Text('Content 2')),
          Center(child: Text('Content 3')),
        ],
      ),
    ],
  );
}
