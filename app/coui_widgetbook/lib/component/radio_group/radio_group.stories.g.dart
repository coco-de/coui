// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'radio_group.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<RadioGroupDemo, StoryArgs<RadioGroupDemo>>;
typedef _Scenario = RadioGroupDemoScenario;
typedef _Defaults = RadioGroupDemoDefaults;
typedef _Story = RadioGroupDemoStory;
typedef _Args = RadioGroupDemoArgs;
final RadioGroupDemoComponent =
    Component<RadioGroupDemo, StoryArgs<RadioGroupDemo>>(
      name: kComponentMeta.name ?? 'RadioGroupDemo',
      path: kComponentMeta.path ?? 'component/radio_group',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [RadioGroup] stories.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Sizes..$generatedName = 'Sizes',
      ],
    );
typedef RadioGroupDemoScenario = Scenario<RadioGroupDemo, RadioGroupDemoArgs>;
typedef RadioGroupDemoDefaults = Defaults<RadioGroupDemo, RadioGroupDemoArgs>;

class RadioGroupDemoStory extends Story<RadioGroupDemo, RadioGroupDemoArgs> {
  RadioGroupDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    RadioGroupDemoArgs? args,
    StoryWidgetBuilder<RadioGroupDemo, RadioGroupDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? RadioGroupDemoArgs(),
         builder:
             builder ??
             (context, args) => RadioGroupDemo(
               key: args.key,
               orientation: args.orientation,
               size: args.size,
               enabled: args.enabled,
             ),
       );
}

class RadioGroupDemoArgs extends StoryArgs<RadioGroupDemo> {
  RadioGroupDemoArgs({
    Arg<Key?>? key,
    Arg<CoreRadioGroupOrientation>? orientation,
    Arg<CoreComponentSize>? size,
    Arg<bool>? enabled,
  }) : this.keyArg = $initArg('key', key, null),
       this.orientationArg = $initArg(
         'orientation',
         orientation,
         EnumArg<CoreRadioGroupOrientation>(
           CoreRadioGroupOrientation.vertical,
           values: CoreRadioGroupOrientation.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreComponentSize>(
           CoreComponentSize.md,
           values: CoreComponentSize.values,
         ),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  RadioGroupDemoArgs.fixed({
    Key? key,
    CoreRadioGroupOrientation orientation = CoreRadioGroupOrientation.vertical,
    CoreComponentSize size = CoreComponentSize.md,
    bool enabled = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.orientationArg = $initArg(
         'orientation',
         Arg.fixed(orientation),
         null,
       )!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CoreRadioGroupOrientation> orientationArg;

  final Arg<CoreComponentSize> sizeArg;

  final Arg<bool> enabledArg;

  Key? get key => keyArg?.value;

  CoreRadioGroupOrientation get orientation => orientationArg.value;

  CoreComponentSize get size => sizeArg.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [keyArg, orientationArg, sizeArg, enabledArg];
}
