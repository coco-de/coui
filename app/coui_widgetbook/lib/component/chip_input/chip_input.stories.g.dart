// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'chip_input.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ChipInputDemo, StoryArgs<ChipInputDemo>>;
typedef _Scenario = ChipInputDemoScenario;
typedef _Defaults = ChipInputDemoDefaults;
typedef _Story = ChipInputDemoStory;
typedef _Args = ChipInputDemoArgs;
final ChipInputDemoComponent =
    Component<ChipInputDemo, StoryArgs<ChipInputDemo>>(
      name: kComponentMeta.name ?? 'ChipInputDemo',
      path: kComponentMeta.path ?? 'component/chip_input',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [ChipInput] stories.

Owns the chip list so typed entries are appended on submit and
removed chips disappear.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Disabled..$generatedName = 'Disabled',
      ],
    );
typedef ChipInputDemoScenario = Scenario<ChipInputDemo, ChipInputDemoArgs>;
typedef ChipInputDemoDefaults = Defaults<ChipInputDemo, ChipInputDemoArgs>;

class ChipInputDemoStory extends Story<ChipInputDemo, ChipInputDemoArgs> {
  ChipInputDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ChipInputDemoArgs? args,
    StoryWidgetBuilder<ChipInputDemo, ChipInputDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ChipInputDemoArgs(),
         builder:
             builder ??
             (context, args) => ChipInputDemo(
               key: args.key,
               enabled: args.enabled,
               maxChips: args.maxChips,
               placeholder: args.placeholder,
             ),
       );
}

class ChipInputDemoArgs extends StoryArgs<ChipInputDemo> {
  ChipInputDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? enabled,
    Arg<int>? maxChips,
    Arg<String>? placeholder,
  }) : this.keyArg = $initArg('key', key, null),
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.maxChipsArg = $initArg(
         'maxChips',
         maxChips,
         IntArg(_kDefaultMaxChips),
       )!,
       this.placeholderArg = $initArg(
         'placeholder',
         placeholder,
         StringArg('Add tags...'),
       )!;

  ChipInputDemoArgs.fixed({
    Key? key,
    bool enabled = true,
    int maxChips = _kDefaultMaxChips,
    String placeholder = 'Add tags...',
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.maxChipsArg = $initArg('maxChips', Arg.fixed(maxChips), null)!,
       this.placeholderArg = $initArg(
         'placeholder',
         Arg.fixed(placeholder),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  final Arg<int> maxChipsArg;

  final Arg<String> placeholderArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  int get maxChips => maxChipsArg.value;

  String get placeholder => placeholderArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg, maxChipsArg, placeholderArg];
}
