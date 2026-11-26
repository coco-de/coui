// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'command.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Command, StoryArgs<Command>>;
typedef _Scenario = CommandScenario;
typedef _Defaults = CommandDefaults;
typedef _Story = CommandStory;
typedef _Args = CommandInputArgs;
final CommandComponent = Component<Command, StoryArgs<Command>>(
  name: kComponentMeta.name ?? 'Command',
  path: kComponentMeta.path ?? 'component/command',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Command palette — a searchable, keyboard-driven list of grouped
commands: a search field, an optional scope-chip row, grouped rows
with an accent-marked active row, and a keyboard-hint footer.

Three shapes ([presentation]) and a density ladder ([size]) cover a
page-embedded panel, a dialog and a fullscreen (touch) palette from one
component. The shape decides chrome and bounds only — a `dialog` palette
is placed inside `Dialog` by the caller, a `fullscreen` one is pushed as
a route; scrim and modality are the host's.

Keyboard: Arrow Up / Down move the active row, Arrow Left / Right move
the scope, Enter selects, Escape calls [onDismiss], Home / End jump.
Focus stays on the search field throughout — rows are never focus
targets, the shared active fill is the only cursor.

Semantic props (`presentation` / `size` / data / callbacks) stay flat;
every piece of chrome flows through the single [commandStyle] slot.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithCategories..$generatedName = 'WithCategories',
    $Dialog..$generatedName = 'Dialog',
    $Fullscreen..$generatedName = 'Fullscreen',
    $SizeSm..$generatedName = 'SizeSm',
    $SizeLg..$generatedName = 'SizeLg',
  ],
);
typedef CommandScenario = Scenario<Command, CommandInputArgs>;
typedef CommandDefaults = Defaults<Command, CommandInputArgs>;

class CommandStory extends Story<Command, CommandInputArgs> {
  CommandStory({
    super.name,
    super.designLink,
    SetupBuilder<Command, CommandInputArgs>? setup,
    super.modes,
    CommandInputArgs? args,
    StoryWidgetBuilder<Command, CommandInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CommandInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class CommandInputArgs extends StoryArgs<Command> {
  CommandInputArgs({
    Arg<String>? placeholder,
    Arg<int>? itemCount,
    Arg<bool>? categorized,
  }) : this.placeholderArg = $initArg(
         'placeholder',
         placeholder,
         StringArg('Search commands...'),
       )!,
       this.itemCountArg = $initArg(
         'itemCount',
         itemCount,
         IntArg(_kDefaultItemCount),
       )!,
       this.categorizedArg = $initArg(
         'categorized',
         categorized,
         BoolArg(false),
       )!;

  CommandInputArgs.fixed({
    String placeholder = 'Search commands...',
    int itemCount = _kDefaultItemCount,
    bool categorized = false,
  }) : this.placeholderArg = $initArg(
         'placeholder',
         Arg.fixed(placeholder),
         null,
       )!,
       this.itemCountArg = $initArg('itemCount', Arg.fixed(itemCount), null)!,
       this.categorizedArg = $initArg(
         'categorized',
         Arg.fixed(categorized),
         null,
       )!;

  final Arg<String> placeholderArg;

  final Arg<int> itemCountArg;

  final Arg<bool> categorizedArg;

  String get placeholder => placeholderArg.value;

  int get itemCount => itemCountArg.value;

  bool get categorized => categorizedArg.value;

  @override
  List<Arg?> get list => [placeholderArg, itemCountArg, categorizedArg];
}
