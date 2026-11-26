// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'avatar.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Avatar, StoryArgs<Avatar>>;
typedef _Scenario = AvatarScenario;
typedef _Defaults = AvatarDefaults;
typedef _Story = AvatarStory;
typedef _Args = AvatarInputArgs;
final AvatarComponent = Component<Avatar, StoryArgs<Avatar>>(
  name: kComponentMeta.name ?? 'Avatar',
  path: kComponentMeta.path ?? 'component/avatar',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform avatar with token-based rendering.

Per Epic #1302 every chrome / dimensional / nested-slot override
flows through the single [avatarStyle] (a [CoreAvatarStyle]). The
semantic enums (`size`, `shape`) and behaviour (`ring` / `badge`) stay
flat on the widget. Every chrome default — fill colour, ring colour,
border radius, badge gap, badge alignment — lives on
`CoreAvatarStyle.defaultX` as a `static const` so Flutter and Web
share a single source of truth.

```text
CoreAvatarStyle.defaultX
  → CoreAvatarTheme.style
  → widget.avatarStyle
```

Example:
```dart
Avatar(
  imageUrl: 'https://example.com/photo.jpg',
  initials: 'JD',
  size: CoreComponentSize.lg,
  badge: AvatarBadge(
    avatarBadgeStyle: CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  ),
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $ExtraSmall..$generatedName = 'ExtraSmall',
    $Small..$generatedName = 'Small',
    $Large..$generatedName = 'Large',
    $ExtraLarge..$generatedName = 'ExtraLarge',
    $WithBadge..$generatedName = 'WithBadge',
    $WithRing..$generatedName = 'WithRing',
    $Rounded..$generatedName = 'Rounded',
  ],
);
typedef AvatarScenario = Scenario<Avatar, AvatarInputArgs>;
typedef AvatarDefaults = Defaults<Avatar, AvatarInputArgs>;

class AvatarStory extends Story<Avatar, AvatarInputArgs> {
  AvatarStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AvatarInputArgs? args,
    StoryWidgetBuilder<Avatar, AvatarInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AvatarInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class AvatarInputArgs extends StoryArgs<Avatar> {
  AvatarInputArgs({
    Arg<String>? initials,
    Arg<CoreComponentSize>? size,
    Arg<CoreAvatarShape>? shape,
    Arg<bool>? showBadge,
    Arg<bool>? ring,
  }) : this.initialsArg = $initArg('initials', initials, StringArg('AB'))!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreComponentSize>(
           CoreAvatarContract.defaultSize,
           values: CoreComponentSize.values,
         ),
       )!,
       this.shapeArg = $initArg(
         'shape',
         shape,
         EnumArg<CoreAvatarShape>(
           CoreAvatarShape.defaultShape,
           values: CoreAvatarShape.values,
         ),
       )!,
       this.showBadgeArg = $initArg('showBadge', showBadge, BoolArg(false))!,
       this.ringArg = $initArg('ring', ring, BoolArg(false))!;

  AvatarInputArgs.fixed({
    String initials = 'AB',
    CoreComponentSize size = CoreAvatarContract.defaultSize,
    CoreAvatarShape shape = CoreAvatarShape.defaultShape,
    bool showBadge = false,
    bool ring = false,
  }) : this.initialsArg = $initArg('initials', Arg.fixed(initials), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.shapeArg = $initArg('shape', Arg.fixed(shape), null)!,
       this.showBadgeArg = $initArg('showBadge', Arg.fixed(showBadge), null)!,
       this.ringArg = $initArg('ring', Arg.fixed(ring), null)!;

  final Arg<String> initialsArg;

  final Arg<CoreComponentSize> sizeArg;

  final Arg<CoreAvatarShape> shapeArg;

  final Arg<bool> showBadgeArg;

  final Arg<bool> ringArg;

  String get initials => initialsArg.value;

  CoreComponentSize get size => sizeArg.value;

  CoreAvatarShape get shape => shapeArg.value;

  bool get showBadge => showBadgeArg.value;

  bool get ring => ringArg.value;

  @override
  List<Arg?> get list => [
    initialsArg,
    sizeArg,
    shapeArg,
    showBadgeArg,
    ringArg,
  ];
}
