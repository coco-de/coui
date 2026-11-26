// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'subfocus.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SubfocusScopeDemo, StoryArgs<SubfocusScopeDemo>>;
typedef _Scenario = SubfocusScopeDemoScenario;
typedef _Defaults = SubfocusScopeDemoDefaults;
typedef _Story = SubfocusScopeDemoStory;
typedef _Args = SubfocusScopeDemoArgs;
final SubfocusScopeDemoComponent =
    Component<SubfocusScopeDemo, StoryArgs<SubfocusScopeDemo>>(
      name: kComponentMeta.name ?? 'SubfocusScopeDemo',
      path: kComponentMeta.path ?? 'component/subfocus',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Demo host for [SubfocusScope] stories.''',
      stories: [
        $Default..$generatedName = 'Default',
        $DisabledItem..$generatedName = 'DisabledItem',
      ],
    );
typedef SubfocusScopeDemoScenario =
    Scenario<SubfocusScopeDemo, SubfocusScopeDemoArgs>;
typedef SubfocusScopeDemoDefaults =
    Defaults<SubfocusScopeDemo, SubfocusScopeDemoArgs>;

class SubfocusScopeDemoStory
    extends Story<SubfocusScopeDemo, SubfocusScopeDemoArgs> {
  SubfocusScopeDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SubfocusScopeDemoArgs? args,
    StoryWidgetBuilder<SubfocusScopeDemo, SubfocusScopeDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SubfocusScopeDemoArgs(),
         builder:
             builder ??
             (context, args) => SubfocusScopeDemo(
               key: args.key,
               autofocus: args.autofocus,
               orientation: args.orientation,
               middleItemEnabled: args.middleItemEnabled,
             ),
       );
}

class SubfocusScopeDemoArgs extends StoryArgs<SubfocusScopeDemo> {
  SubfocusScopeDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? autofocus,
    Arg<CoreSubfocusOrientation>? orientation,
    Arg<bool>? middleItemEnabled,
  }) : this.keyArg = $initArg('key', key, null),
       this.autofocusArg = $initArg('autofocus', autofocus, BoolArg(true))!,
       this.orientationArg = $initArg(
         'orientation',
         orientation,
         EnumArg<CoreSubfocusOrientation>(
           CoreSubfocusOrientation.vertical,
           values: CoreSubfocusOrientation.values,
         ),
       )!,
       this.middleItemEnabledArg = $initArg(
         'middleItemEnabled',
         middleItemEnabled,
         BoolArg(true),
       )!;

  SubfocusScopeDemoArgs.fixed({
    Key? key,
    bool autofocus = true,
    CoreSubfocusOrientation orientation = CoreSubfocusOrientation.vertical,
    bool middleItemEnabled = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.autofocusArg = $initArg('autofocus', Arg.fixed(autofocus), null)!,
       this.orientationArg = $initArg(
         'orientation',
         Arg.fixed(orientation),
         null,
       )!,
       this.middleItemEnabledArg = $initArg(
         'middleItemEnabled',
         Arg.fixed(middleItemEnabled),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<bool> autofocusArg;

  final Arg<CoreSubfocusOrientation> orientationArg;

  final Arg<bool> middleItemEnabledArg;

  Key? get key => keyArg?.value;

  bool get autofocus => autofocusArg.value;

  CoreSubfocusOrientation get orientation => orientationArg.value;

  bool get middleItemEnabled => middleItemEnabledArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    autofocusArg,
    orientationArg,
    middleItemEnabledArg,
  ];
}
