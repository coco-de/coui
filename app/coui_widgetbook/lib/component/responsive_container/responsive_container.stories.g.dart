// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'responsive_container.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<ResponsiveContainer, StoryArgs<ResponsiveContainer>>;
typedef _Scenario = ResponsiveContainerScenario;
typedef _Defaults = ResponsiveContainerDefaults;
typedef _Story = ResponsiveContainerStory;
typedef _Args = ResponsiveContainerInputArgs;
final ResponsiveContainerComponent =
    Component<ResponsiveContainer, StoryArgs<ResponsiveContainer>>(
      name: kComponentMeta.name ?? 'ResponsiveContainer',
      path: kComponentMeta.path ?? 'component/responsive_container',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Horizontally-centred, max-width-constrained layout wrapper.

Mirrors the Web `ResponsiveContainer` — same parameter names,
same defaults (`maxWidth: xl`, `centered: true`, horizontal
`CoreSpace.space16` padding), same visual outcome. Content wider
than the effective max-width is clipped by the parent; narrower
viewports see the container stretch to the full parent width and
the padding remains applied.''',
      stories: [
        $Default..$generatedName = 'Default',
        $MaxWidth..$generatedName = 'MaxWidth',
      ],
    );
typedef ResponsiveContainerScenario =
    Scenario<ResponsiveContainer, ResponsiveContainerInputArgs>;
typedef ResponsiveContainerDefaults =
    Defaults<ResponsiveContainer, ResponsiveContainerInputArgs>;

class ResponsiveContainerStory
    extends Story<ResponsiveContainer, ResponsiveContainerInputArgs> {
  ResponsiveContainerStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ResponsiveContainerInputArgs? args,
    StoryWidgetBuilder<ResponsiveContainer, ResponsiveContainerInputArgs>?
    builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ResponsiveContainerInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class ResponsiveContainerInputArgs extends StoryArgs<ResponsiveContainer> {
  ResponsiveContainerInputArgs({
    Arg<CoreResponsiveContainerMaxWidth>? maxWidth,
    Arg<bool>? centered,
  }) : this.maxWidthArg = $initArg(
         'maxWidth',
         maxWidth,
         EnumArg<CoreResponsiveContainerMaxWidth>(
           CoreResponsiveContainerMaxWidth.sm,
           values: CoreResponsiveContainerMaxWidth.values,
         ),
       )!,
       this.centeredArg = $initArg('centered', centered, BoolArg(true))!;

  ResponsiveContainerInputArgs.fixed({
    CoreResponsiveContainerMaxWidth maxWidth =
        CoreResponsiveContainerMaxWidth.sm,
    bool centered = true,
  }) : this.maxWidthArg = $initArg('maxWidth', Arg.fixed(maxWidth), null)!,
       this.centeredArg = $initArg('centered', Arg.fixed(centered), null)!;

  final Arg<CoreResponsiveContainerMaxWidth> maxWidthArg;

  final Arg<bool> centeredArg;

  CoreResponsiveContainerMaxWidth get maxWidth => maxWidthArg.value;

  bool get centered => centeredArg.value;

  @override
  List<Arg?> get list => [maxWidthArg, centeredArg];
}
