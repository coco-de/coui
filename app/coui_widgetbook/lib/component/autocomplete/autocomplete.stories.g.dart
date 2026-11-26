// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'autocomplete.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AutocompleteDemo, StoryArgs<AutocompleteDemo>>;
typedef _Scenario = AutocompleteDemoScenario;
typedef _Defaults = AutocompleteDemoDefaults;
typedef _Story = AutocompleteDemoStory;
typedef _Args = AutocompleteDemoArgs;
final AutocompleteDemoComponent =
    Component<AutocompleteDemo, StoryArgs<AutocompleteDemo>>(
      name: kComponentMeta.name ?? 'AutocompleteDemo',
      path: kComponentMeta.path ?? 'component/autocomplete',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [Autocomplete] stories.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Disabled..$generatedName = 'Disabled',
      ],
    );
typedef AutocompleteDemoScenario =
    Scenario<AutocompleteDemo, AutocompleteDemoArgs>;
typedef AutocompleteDemoDefaults =
    Defaults<AutocompleteDemo, AutocompleteDemoArgs>;

class AutocompleteDemoStory
    extends Story<AutocompleteDemo, AutocompleteDemoArgs> {
  AutocompleteDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AutocompleteDemoArgs? args,
    StoryWidgetBuilder<AutocompleteDemo, AutocompleteDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AutocompleteDemoArgs(),
         builder:
             builder ??
             (context, args) => AutocompleteDemo(
               key: args.key,
               placeholder: args.placeholder,
               enabled: args.enabled,
             ),
       );
}

class AutocompleteDemoArgs extends StoryArgs<AutocompleteDemo> {
  AutocompleteDemoArgs({
    Arg<Key?>? key,
    Arg<String>? placeholder,
    Arg<bool>? enabled,
  }) : this.keyArg = $initArg('key', key, null),
       this.placeholderArg = $initArg(
         'placeholder',
         placeholder,
         StringArg('Type to search...'),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  AutocompleteDemoArgs.fixed({
    Key? key,
    String placeholder = 'Type to search...',
    bool enabled = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.placeholderArg = $initArg(
         'placeholder',
         Arg.fixed(placeholder),
         null,
       )!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<Key?>? keyArg;

  final Arg<String> placeholderArg;

  final Arg<bool> enabledArg;

  Key? get key => keyArg?.value;

  String get placeholder => placeholderArg.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [keyArg, placeholderArg, enabledArg];
}
