// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'status.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Status, StoryArgs<Status>>;
typedef _Scenario = StatusScenario;
typedef _Defaults = StatusDefaults;
typedef _Story = StatusStory;
typedef _Args = StatusArgs;
final StatusComponent = Component<Status, StoryArgs<Status>>(
  name: kComponentMeta.name ?? 'Status',
  path: kComponentMeta.path ?? 'component/status',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform status dot indicator with token-based rendering.

Displays a small colored dot to indicate current state
such as online, offline, or error.
Uses [CoreStatusContract] from `coui_core` for consistent
cross-platform API.

Per Epic #1302 chrome / dimensional overrides flow through the
single [statusStyle] slot. Behavioural fields (`color`, `size`,
`semanticLabel`) stay flat on the widget.

Example:
```dart
Status(
  color: CoreStatusColor.success,
  size: CoreStatusSize.lg,
  semanticLabel: 'Online',
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $Neutral..$generatedName = 'Neutral',
    $Primary..$generatedName = 'Primary',
    $Secondary..$generatedName = 'Secondary',
    $Tertiary..$generatedName = 'Tertiary',
    $Info..$generatedName = 'Info',
    $Warning..$generatedName = 'Warning',
    $Error..$generatedName = 'Error',
  ],
);
typedef StatusScenario = Scenario<Status, StatusArgs>;
typedef StatusDefaults = Defaults<Status, StatusArgs>;

class StatusStory extends Story<Status, StatusArgs> {
  StatusStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    StatusArgs? args,
    StoryWidgetBuilder<Status, StatusArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? StatusArgs(),
         builder:
             builder ??
             (context, args) => Status(
               key: args.key,
               color: args.color,
               size: args.size,
               semanticLabel: args.semanticLabel,
               animated: args.animated,
               statusStyle: args.statusStyle,
             ),
       );
}

class StatusArgs extends StoryArgs<Status> {
  StatusArgs({
    Arg<Key?>? key,
    Arg<CoreStatusColor>? color,
    Arg<CoreStatusSize>? size,
    Arg<String?>? semanticLabel,
    Arg<bool>? animated,
    Arg<CoreStatusStyle?>? statusStyle,
  }) : this.keyArg = $initArg('key', key, null),
       this.colorArg = $initArg(
         'color',
         color,
         EnumArg<CoreStatusColor>(
           CoreStatusColor.neutral,
           values: CoreStatusColor.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreStatusSize>(
           CoreStatusSize.md,
           values: CoreStatusSize.values,
         ),
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         NullableStringArg(null),
       )!,
       this.animatedArg = $initArg('animated', animated, BoolArg(false))!,
       this.statusStyleArg = $initArg('statusStyle', statusStyle, null);

  StatusArgs.fixed({
    Key? key,
    CoreStatusColor color = CoreStatusColor.neutral,
    CoreStatusSize size = CoreStatusSize.md,
    String? semanticLabel = null,
    bool animated = false,
    CoreStatusStyle? statusStyle,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.colorArg = $initArg('color', Arg.fixed(color), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel == null ? null : Arg.fixed(semanticLabel),
         null,
       ),
       this.animatedArg = $initArg('animated', Arg.fixed(animated), null)!,
       this.statusStyleArg = $initArg(
         'statusStyle',
         statusStyle == null ? null : Arg.fixed(statusStyle),
         null,
       );

  final Arg<Key?>? keyArg;

  final Arg<CoreStatusColor> colorArg;

  final Arg<CoreStatusSize> sizeArg;

  final Arg<String?>? semanticLabelArg;

  final Arg<bool> animatedArg;

  final Arg<CoreStatusStyle?>? statusStyleArg;

  Key? get key => keyArg?.value;

  CoreStatusColor get color => colorArg.value;

  CoreStatusSize get size => sizeArg.value;

  String? get semanticLabel => semanticLabelArg?.value;

  bool get animated => animatedArg.value;

  CoreStatusStyle? get statusStyle => statusStyleArg?.value;

  @override
  List<Arg?> get list => [
    keyArg,
    colorArg,
    sizeArg,
    semanticLabelArg,
    animatedArg,
    statusStyleArg,
  ];
}
