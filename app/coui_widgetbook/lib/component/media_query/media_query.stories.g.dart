// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'media_query.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<MediaQueryVisibilityDemo, StoryArgs<MediaQueryVisibilityDemo>>;
typedef _Scenario = MediaQueryVisibilityDemoScenario;
typedef _Defaults = MediaQueryVisibilityDemoDefaults;
typedef _Story = MediaQueryVisibilityDemoStory;
typedef _Args = MediaQueryVisibilityDemoArgs;
final MediaQueryVisibilityDemoComponent =
    Component<MediaQueryVisibilityDemo, StoryArgs<MediaQueryVisibilityDemo>>(
      name: kComponentMeta.name ?? 'MediaQueryVisibilityDemo',
      path: kComponentMeta.path ?? 'component/media_query',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Interactive demo host for [MediaQueryVisibility] stories.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef MediaQueryVisibilityDemoScenario =
    Scenario<MediaQueryVisibilityDemo, MediaQueryVisibilityDemoArgs>;
typedef MediaQueryVisibilityDemoDefaults =
    Defaults<MediaQueryVisibilityDemo, MediaQueryVisibilityDemoArgs>;

class MediaQueryVisibilityDemoStory
    extends Story<MediaQueryVisibilityDemo, MediaQueryVisibilityDemoArgs> {
  MediaQueryVisibilityDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    MediaQueryVisibilityDemoArgs? args,
    StoryWidgetBuilder<MediaQueryVisibilityDemo, MediaQueryVisibilityDemoArgs>?
    builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? MediaQueryVisibilityDemoArgs(),
         builder:
             builder ??
             (context, args) => MediaQueryVisibilityDemo(
               key: args.key,
               minWidth: args.minWidth,
               maxWidth: args.maxWidth,
             ),
       );
}

class MediaQueryVisibilityDemoArgs extends StoryArgs<MediaQueryVisibilityDemo> {
  MediaQueryVisibilityDemoArgs({
    Arg<Key?>? key,
    Arg<double>? minWidth,
    Arg<double>? maxWidth,
  }) : this.keyArg = $initArg('key', key, null),
       this.minWidthArg = $initArg('minWidth', minWidth, DoubleArg(0))!,
       this.maxWidthArg = $initArg(
         'maxWidth',
         maxWidth,
         DoubleArg(_kDefaultMaxWidth),
       )!;

  MediaQueryVisibilityDemoArgs.fixed({
    Key? key,
    double minWidth = 0,
    double maxWidth = _kDefaultMaxWidth,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.minWidthArg = $initArg('minWidth', Arg.fixed(minWidth), null)!,
       this.maxWidthArg = $initArg('maxWidth', Arg.fixed(maxWidth), null)!;

  final Arg<Key?>? keyArg;

  final Arg<double> minWidthArg;

  final Arg<double> maxWidthArg;

  Key? get key => keyArg?.value;

  double get minWidth => minWidthArg.value;

  double get maxWidth => maxWidthArg.value;

  @override
  List<Arg?> get list => [keyArg, minWidthArg, maxWidthArg];
}
