// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'navigation_bar_item.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<NavigationBarItem, StoryArgs<NavigationBarItem>>;
typedef _Scenario = NavigationBarItemScenario;
typedef _Defaults = NavigationBarItemDefaults;
typedef _Story = NavigationBarItemStory;
typedef _Args = NavigationBarItemInputArgs;
final NavigationBarItemComponent =
    Component<NavigationBarItem, StoryArgs<NavigationBarItem>>(
      name: kComponentMeta.name ?? 'NavigationBarItem',
      path: kComponentMeta.path ?? 'component/navigation_bar_item',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''One navigation destination drawn on its own — an icon, a name, an
optional count, and a face that says whether it is the current place.

This is the destination a [NavigationBar] composes for each
[CoreNavigationBarItem.destination], public so a screen can assemble a
sidebar outside the bar — a [Drawer]'s content, an app's own rail, a
settings column. A row placed by hand reads exactly like a row the bar
placed, because it is the same widget.

The chrome is the bar's: [navigationBarStyle] is a
[CoreNavigationBarStyle], and the item draws its item fields at [mode]'s
density — a sidebar row by default
([CoreNavigationBarItemContract.defaultMode]). Selection, the count badge,
hover, keyboard focus and activation (Enter / Space) work on their own;
the item only needs [selected] and [onPressed] from the screen that owns
the current place.

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    NavigationBarItem(
      icon: const Icon(LucideIcons.inbox),
      label: 'Inbox',
      badge: const Badge(
        form: CoreBadgeForm.count,
        tone: CoreBadgeTone.info,
        variant: CoreBadgeVariant.filled,
        size: CoreComponentSize.xs,
        child: Text('3'),
      ),
      selected: page == 0,
      onPressed: () => setState(() => page = 0),
    ),
    NavigationBarItem(
      icon: const Icon(LucideIcons.settings),
      label: 'Settings',
      selected: page == 1,
      onPressed: () => setState(() => page = 1),
    ),
  ],
)
```''',
      stories: [
        $Default..$generatedName = 'Default',
        $Selected..$generatedName = 'Selected',
        $Disabled..$generatedName = 'Disabled',
        $LabelOnly..$generatedName = 'LabelOnly',
      ],
    );
typedef NavigationBarItemScenario =
    Scenario<NavigationBarItem, NavigationBarItemInputArgs>;
typedef NavigationBarItemDefaults =
    Defaults<NavigationBarItem, NavigationBarItemInputArgs>;

class NavigationBarItemStory
    extends Story<NavigationBarItem, NavigationBarItemInputArgs> {
  NavigationBarItemStory({
    super.name,
    super.designLink,
    SetupBuilder<NavigationBarItem, NavigationBarItemInputArgs>? setup,
    super.modes,
    NavigationBarItemInputArgs? args,
    StoryWidgetBuilder<NavigationBarItem, NavigationBarItemInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? NavigationBarItemInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class NavigationBarItemInputArgs extends StoryArgs<NavigationBarItem> {
  NavigationBarItemInputArgs({
    Arg<String>? label,
    Arg<bool>? showIcon,
    Arg<bool>? showCount,
    Arg<bool>? selected,
    Arg<bool>? enabled,
  }) : this.labelArg = $initArg('label', label, StringArg('Inbox'))!,
       this.showIconArg = $initArg('showIcon', showIcon, BoolArg(true))!,
       this.showCountArg = $initArg('showCount', showCount, BoolArg(true))!,
       this.selectedArg = $initArg('selected', selected, BoolArg(false))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  NavigationBarItemInputArgs.fixed({
    String label = 'Inbox',
    bool showIcon = true,
    bool showCount = true,
    bool selected = false,
    bool enabled = true,
  }) : this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.showIconArg = $initArg('showIcon', Arg.fixed(showIcon), null)!,
       this.showCountArg = $initArg('showCount', Arg.fixed(showCount), null)!,
       this.selectedArg = $initArg('selected', Arg.fixed(selected), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<String> labelArg;

  final Arg<bool> showIconArg;

  final Arg<bool> showCountArg;

  final Arg<bool> selectedArg;

  final Arg<bool> enabledArg;

  String get label => labelArg.value;

  bool get showIcon => showIconArg.value;

  bool get showCount => showCountArg.value;

  bool get selected => selectedArg.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [
    labelArg,
    showIconArg,
    showCountArg,
    selectedArg,
    enabledArg,
  ];
}
