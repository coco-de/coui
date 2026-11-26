// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'menu_item.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<MenuItem, StoryArgs<MenuItem>>;
typedef _Scenario = MenuItemScenario;
typedef _Defaults = MenuItemDefaults;
typedef _Story = MenuItemStory;
typedef _Args = MenuItemInputArgs;
final MenuItemComponent = Component<MenuItem, StoryArgs<MenuItem>>(
  name: kComponentMeta.name ?? 'MenuItem',
  path: kComponentMeta.path ?? 'component/menu_item',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''One interactive row of a menu — the surface `Menu`, `DropdownMenu`,
`ContextMenu`, `Menubar` and `Select` all place, drawn once here so the
five agree.

Anatomy, start to end: `[ mark ] [ leading ] [ label / description ]
[ shortcut | chevron ] [ trailing ]`, one
[CoreMenuItemStyle.contentGapStyle] between each seat. A [description] makes the row grow past its
minimum height and top-aligns the two lines; [hasSubmenu] draws the
chevron where the [shortcut] would sit.

Drawn as `Clickable` + `Text` + `Icon` + `Gap`, not as a `Button`: a
menu row's accessibility contract is different in kind — a disabled
row stays reachable by keyboard (inert, announced as disabled) and the
role is `menuItem`, not `button`. The row paints its own state layer,
the way `Command`'s rows do: the foreground washed over the fill at
[CoreMenuItemStyle.stateLayer]'s hover / focus / pressed weight.

```dart
MenuItem(
  label: const Text('Rename'),
  shortcut: const Text('F2'),
  leading: const Icon(LucideIcons.pencil),
  onPressed: () {},
)
```

The Web `MenuItem` shares the same parameter names and order.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithShortcut..$generatedName = 'WithShortcut',
    $WithDescription..$generatedName = 'WithDescription',
    $WithMark..$generatedName = 'WithMark',
    $WithTrailingBadge..$generatedName = 'WithTrailingBadge',
    $Submenu..$generatedName = 'Submenu',
    $Selected..$generatedName = 'Selected',
    $Critical..$generatedName = 'Critical',
    $Disabled..$generatedName = 'Disabled',
    $Compact..$generatedName = 'Compact',
  ],
);
typedef MenuItemScenario = Scenario<MenuItem, MenuItemInputArgs>;
typedef MenuItemDefaults = Defaults<MenuItem, MenuItemInputArgs>;

class MenuItemStory extends Story<MenuItem, MenuItemInputArgs> {
  MenuItemStory({
    super.name,
    super.designLink,
    SetupBuilder<MenuItem, MenuItemInputArgs>? setup,
    super.modes,
    MenuItemInputArgs? args,
    StoryWidgetBuilder<MenuItem, MenuItemInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? MenuItemInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class MenuItemInputArgs extends StoryArgs<MenuItem> {
  MenuItemInputArgs({
    Arg<String>? label,
    Arg<CoreMenuItemSize>? size,
    Arg<CoreMenuItemTone>? tone,
    Arg<String>? description,
    Arg<String>? shortcut,
    Arg<String>? trailingBadge,
    Arg<bool>? showLeadingIcon,
    Arg<bool>? showMark,
    Arg<bool>? reserveMark,
    Arg<bool>? hasSubmenu,
    Arg<bool>? selected,
    Arg<bool>? enabled,
  }) : this.labelArg = $initArg('label', label, StringArg('Rename'))!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreMenuItemSize>(
           CoreMenuItemSize.md,
           values: CoreMenuItemSize.values,
         ),
       )!,
       this.toneArg = $initArg(
         'tone',
         tone,
         EnumArg<CoreMenuItemTone>(
           CoreMenuItemTone.neutral,
           values: CoreMenuItemTone.values,
         ),
       )!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg(''),
       )!,
       this.shortcutArg = $initArg('shortcut', shortcut, StringArg(''))!,
       this.trailingBadgeArg = $initArg(
         'trailingBadge',
         trailingBadge,
         StringArg(''),
       )!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         showLeadingIcon,
         BoolArg(true),
       )!,
       this.showMarkArg = $initArg('showMark', showMark, BoolArg(false))!,
       this.reserveMarkArg = $initArg(
         'reserveMark',
         reserveMark,
         BoolArg(false),
       )!,
       this.hasSubmenuArg = $initArg('hasSubmenu', hasSubmenu, BoolArg(false))!,
       this.selectedArg = $initArg('selected', selected, BoolArg(false))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  MenuItemInputArgs.fixed({
    String label = 'Rename',
    CoreMenuItemSize size = CoreMenuItemSize.md,
    CoreMenuItemTone tone = CoreMenuItemTone.neutral,
    String description = '',
    String shortcut = '',
    String trailingBadge = '',
    bool showLeadingIcon = true,
    bool showMark = false,
    bool reserveMark = false,
    bool hasSubmenu = false,
    bool selected = false,
    bool enabled = true,
  }) : this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.toneArg = $initArg('tone', Arg.fixed(tone), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.shortcutArg = $initArg('shortcut', Arg.fixed(shortcut), null)!,
       this.trailingBadgeArg = $initArg(
         'trailingBadge',
         Arg.fixed(trailingBadge),
         null,
       )!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         Arg.fixed(showLeadingIcon),
         null,
       )!,
       this.showMarkArg = $initArg('showMark', Arg.fixed(showMark), null)!,
       this.reserveMarkArg = $initArg(
         'reserveMark',
         Arg.fixed(reserveMark),
         null,
       )!,
       this.hasSubmenuArg = $initArg(
         'hasSubmenu',
         Arg.fixed(hasSubmenu),
         null,
       )!,
       this.selectedArg = $initArg('selected', Arg.fixed(selected), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<String> labelArg;

  final Arg<CoreMenuItemSize> sizeArg;

  final Arg<CoreMenuItemTone> toneArg;

  final Arg<String> descriptionArg;

  final Arg<String> shortcutArg;

  final Arg<String> trailingBadgeArg;

  final Arg<bool> showLeadingIconArg;

  final Arg<bool> showMarkArg;

  final Arg<bool> reserveMarkArg;

  final Arg<bool> hasSubmenuArg;

  final Arg<bool> selectedArg;

  final Arg<bool> enabledArg;

  String get label => labelArg.value;

  CoreMenuItemSize get size => sizeArg.value;

  CoreMenuItemTone get tone => toneArg.value;

  String get description => descriptionArg.value;

  String get shortcut => shortcutArg.value;

  String get trailingBadge => trailingBadgeArg.value;

  bool get showLeadingIcon => showLeadingIconArg.value;

  bool get showMark => showMarkArg.value;

  bool get reserveMark => reserveMarkArg.value;

  bool get hasSubmenu => hasSubmenuArg.value;

  bool get selected => selectedArg.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [
    labelArg,
    sizeArg,
    toneArg,
    descriptionArg,
    shortcutArg,
    trailingBadgeArg,
    showLeadingIconArg,
    showMarkArg,
    reserveMarkArg,
    hasSubmenuArg,
    selectedArg,
    enabledArg,
  ];
}
