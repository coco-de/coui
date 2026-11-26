// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'divider.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Divider, StoryArgs<Divider>>;
typedef _Scenario = DividerScenario;
typedef _Defaults = DividerDefaults;
typedef _Story = DividerStory;
typedef _Args = DividerInputArgs;
final DividerComponent = Component<Divider, StoryArgs<Divider>>(
  name: kComponentMeta.name ?? 'Divider',
  path: kComponentMeta.path ?? 'component/divider',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified divider line for CoUI Flutter.

Renders a thin line to visually separate content, optionally with a
centered [child] (e.g. "OR" label). All chrome / dimensional
overrides flow through [dividerStyle] (Epic #1415 option D).''',
  stories: [
    $Default..$generatedName = 'Default',
    $Vertical..$generatedName = 'Vertical',
  ],
);
typedef DividerScenario = Scenario<Divider, DividerInputArgs>;
typedef DividerDefaults = Defaults<Divider, DividerInputArgs>;

class DividerStory extends Story<Divider, DividerInputArgs> {
  DividerStory({
    super.name,
    super.designLink,
    SetupBuilder<Divider, DividerInputArgs>? setup,
    super.modes,
    DividerInputArgs? args,
    StoryWidgetBuilder<Divider, DividerInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DividerInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class DividerInputArgs extends StoryArgs<Divider> {
  DividerInputArgs({
    Arg<CoreDividerOrientation>? orientation,
    Arg<double>? thickness,
  }) : this.orientationArg = $initArg(
         'orientation',
         orientation,
         EnumArg<CoreDividerOrientation>(
           CoreDividerOrientation.horizontal,
           values: CoreDividerOrientation.values,
         ),
       )!,
       this.thicknessArg = $initArg(
         'thickness',
         thickness,
         DoubleArg(_kThicknessDefault),
       )!;

  DividerInputArgs.fixed({
    CoreDividerOrientation orientation = CoreDividerOrientation.horizontal,
    double thickness = _kThicknessDefault,
  }) : this.orientationArg = $initArg(
         'orientation',
         Arg.fixed(orientation),
         null,
       )!,
       this.thicknessArg = $initArg('thickness', Arg.fixed(thickness), null)!;

  final Arg<CoreDividerOrientation> orientationArg;

  final Arg<double> thicknessArg;

  CoreDividerOrientation get orientation => orientationArg.value;

  double get thickness => thicknessArg.value;

  @override
  List<Arg?> get list => [orientationArg, thicknessArg];
}
