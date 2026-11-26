// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'command_search.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<CommandSearch, StoryArgs<CommandSearch>>;
typedef _Scenario = CommandSearchScenario;
typedef _Defaults = CommandSearchDefaults;
typedef _Story = CommandSearchStory;
typedef _Args = CommandSearchInputArgs;
final CommandSearchComponent = Component<CommandSearch, StoryArgs<CommandSearch>>(
  name: kComponentMeta.name ?? 'CommandSearch',
  path: kComponentMeta.path ?? 'component/command_search',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''The trigger that opens a command palette — a search-shaped button an app
bar or a sidebar places, which calls [onPressed] when it is activated.

It looks like a search field and is not one: typing happens in the
`Command` the app opens from [onPressed] (usually its dialog
presentation), so the trigger is announced as a **button** and takes one
tab stop. Listening for the shortcut it shows (`⌘K`) is the app's job —
the trigger only draws the hint.

Anatomy, start to end: `[ leading ] [ hint ] [ shortcut ]`, one
[CoreCommandSearchStyle.contentGapStyle] between each seat. The hint takes
the remaining width and truncates. The width is the parent's — the
trigger fills the width it is given, so it needs a bounded one (an
`Expanded`, a `SizedBox`, an app bar's centre slot).

Drawn as `Clickable` + `Icon` + `Text` + `Gap` rather than as a `Button`:
a button's face is a centred label, and this face is a start-aligned
hint with a key at the end. The trigger paints its own state layer the
way a menu row does — the state-layer colour washed over the face at
[CoreCommandSearchStyle.stateLayer]'s hover / focus / pressed weight.

```dart
CommandSearch(
  shortcut: const Kbd(keys: ['⌘K']),
  onPressed: () => openCommandPalette(context),
)
```

The Web `CommandSearch` shares the same parameter names and order.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithHint..$generatedName = 'WithHint',
    $Compact..$generatedName = 'Compact',
    $Large..$generatedName = 'Large',
    $Disabled..$generatedName = 'Disabled',
  ],
);
typedef CommandSearchScenario = Scenario<CommandSearch, CommandSearchInputArgs>;
typedef CommandSearchDefaults = Defaults<CommandSearch, CommandSearchInputArgs>;

class CommandSearchStory extends Story<CommandSearch, CommandSearchInputArgs> {
  CommandSearchStory({
    super.name,
    super.designLink,
    SetupBuilder<CommandSearch, CommandSearchInputArgs>? setup,
    super.modes,
    CommandSearchInputArgs? args,
    StoryWidgetBuilder<CommandSearch, CommandSearchInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CommandSearchInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class CommandSearchInputArgs extends StoryArgs<CommandSearch> {
  CommandSearchInputArgs({
    Arg<String>? hint,
    Arg<CoreCommandSize>? size,
    Arg<bool>? showShortcut,
    Arg<bool>? enabled,
  }) : this.hintArg = $initArg('hint', hint, StringArg(''))!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreCommandSize>(
           CoreCommandSize.md,
           values: CoreCommandSize.values,
         ),
       )!,
       this.showShortcutArg = $initArg(
         'showShortcut',
         showShortcut,
         BoolArg(true),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  CommandSearchInputArgs.fixed({
    String hint = '',
    CoreCommandSize size = CoreCommandSize.md,
    bool showShortcut = true,
    bool enabled = true,
  }) : this.hintArg = $initArg('hint', Arg.fixed(hint), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.showShortcutArg = $initArg(
         'showShortcut',
         Arg.fixed(showShortcut),
         null,
       )!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<String> hintArg;

  final Arg<CoreCommandSize> sizeArg;

  final Arg<bool> showShortcutArg;

  final Arg<bool> enabledArg;

  String get hint => hintArg.value;

  CoreCommandSize get size => sizeArg.value;

  bool get showShortcut => showShortcutArg.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [hintArg, sizeArg, showShortcutArg, enabledArg];
}
