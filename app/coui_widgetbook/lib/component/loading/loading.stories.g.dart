// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'loading.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<LoadingDemo, StoryArgs<LoadingDemo>>;
typedef _Scenario = LoadingDemoScenario;
typedef _Defaults = LoadingDemoDefaults;
typedef _Story = LoadingDemoStory;
typedef _Args = LoadingDemoArgs;
final LoadingDemoComponent = Component<LoadingDemo, StoryArgs<LoadingDemo>>(
  name: kComponentMeta.name ?? 'LoadingDemo',
  path: kComponentMeta.path ?? 'component/loading',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Loading] stories.

Shows the [Loading] indicator itself, or — in progress mode — an
interactive radial / linear progress showcase driven by a button.''',
  stories: [
    $Spinner..$generatedName = 'Spinner',
    $Default..$generatedName = 'Default',
    $Dots..$generatedName = 'Dots',
    $Pulse..$generatedName = 'Pulse',
    $Bar..$generatedName = 'Bar',
    $WithProgress..$generatedName = 'WithProgress',
  ],
);
typedef LoadingDemoScenario = Scenario<LoadingDemo, LoadingDemoArgs>;
typedef LoadingDemoDefaults = Defaults<LoadingDemo, LoadingDemoArgs>;

class LoadingDemoStory extends Story<LoadingDemo, LoadingDemoArgs> {
  LoadingDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    LoadingDemoArgs? args,
    StoryWidgetBuilder<LoadingDemo, LoadingDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? LoadingDemoArgs(),
         builder:
             builder ??
             (context, args) => LoadingDemo(
               key: args.key,
               variant: args.variant,
               componentSize: args.componentSize,
               showProgress: args.showProgress,
             ),
       );
}

class LoadingDemoArgs extends StoryArgs<LoadingDemo> {
  LoadingDemoArgs({
    Arg<Key?>? key,
    Arg<CoreLoadingVariant>? variant,
    Arg<CoreComponentSize?>? componentSize,
    Arg<bool>? showProgress,
  }) : this.keyArg = $initArg('key', key, null),
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreLoadingVariant>(
           CoreLoadingVariant.spinner,
           values: CoreLoadingVariant.values,
         ),
       )!,
       this.componentSizeArg = $initArg(
         'componentSize',
         componentSize,
         NullableEnumArg<CoreComponentSize>(
           null,
           values: CoreComponentSize.values,
         ),
       )!,
       this.showProgressArg = $initArg(
         'showProgress',
         showProgress,
         BoolArg(false),
       )!;

  LoadingDemoArgs.fixed({
    Key? key,
    CoreLoadingVariant variant = CoreLoadingVariant.spinner,
    CoreComponentSize? componentSize = null,
    bool showProgress = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.componentSizeArg = $initArg(
         'componentSize',
         componentSize == null ? null : Arg.fixed(componentSize),
         null,
       ),
       this.showProgressArg = $initArg(
         'showProgress',
         Arg.fixed(showProgress),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<CoreLoadingVariant> variantArg;

  final Arg<CoreComponentSize?>? componentSizeArg;

  final Arg<bool> showProgressArg;

  Key? get key => keyArg?.value;

  CoreLoadingVariant get variant => variantArg.value;

  CoreComponentSize? get componentSize => componentSizeArg?.value;

  bool get showProgress => showProgressArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    variantArg,
    componentSizeArg,
    showProgressArg,
  ];
}
