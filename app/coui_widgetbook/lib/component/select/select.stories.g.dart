// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'select.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SelectDemo, StoryArgs<SelectDemo>>;
typedef _Scenario = SelectDemoScenario;
typedef _Defaults = SelectDemoDefaults;
typedef _Story = SelectDemoStory;
typedef _Args = SelectDemoArgs;
final SelectDemoComponent = Component<SelectDemo, StoryArgs<SelectDemo>>(
  name: kComponentMeta.name ?? 'SelectDemo',
  path: kComponentMeta.path ?? 'component/select',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Select] stories.

Manages the selected value so choosing an option updates the
trigger label. An empty [placeholder] falls back to the widget
default (no placeholder).''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithPlaceholder..$generatedName = 'WithPlaceholder',
  ],
);
typedef SelectDemoScenario = Scenario<SelectDemo, SelectDemoArgs>;
typedef SelectDemoDefaults = Defaults<SelectDemo, SelectDemoArgs>;

class SelectDemoStory extends Story<SelectDemo, SelectDemoArgs> {
  SelectDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SelectDemoArgs? args,
    StoryWidgetBuilder<SelectDemo, SelectDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SelectDemoArgs(),
         builder:
             builder ??
             (context, args) => SelectDemo(
               key: args.key,
               enabled: args.enabled,
               placeholder: args.placeholder,
             ),
       );
}

class SelectDemoArgs extends StoryArgs<SelectDemo> {
  SelectDemoArgs({Arg<Key?>? key, Arg<bool>? enabled, Arg<String>? placeholder})
    : this.keyArg = $initArg('key', key, null),
      this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
      this.placeholderArg = $initArg(
        'placeholder',
        placeholder,
        StringArg(''),
      )!;

  SelectDemoArgs.fixed({Key? key, bool enabled = true, String placeholder = ''})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
      this.placeholderArg = $initArg(
        'placeholder',
        Arg.fixed(placeholder),
        null,
      )!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  final Arg<String> placeholderArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  String get placeholder => placeholderArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg, placeholderArg];
}
