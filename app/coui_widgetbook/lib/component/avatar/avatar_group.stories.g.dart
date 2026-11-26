// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'avatar_group.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AvatarGroup, StoryArgs<AvatarGroup>>;
typedef _Scenario = AvatarGroupScenario;
typedef _Defaults = AvatarGroupDefaults;
typedef _Story = AvatarGroupStory;
typedef _Args = AvatarGroupInputArgs;
final AvatarGroupComponent = Component<AvatarGroup, StoryArgs<AvatarGroup>>(
  name: kComponentMeta.name ?? 'AvatarGroup',
  path: kComponentMeta.path ?? 'component/avatar',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Displays multiple [Avatar] widgets in an overlapping layout.

Example:
```dart
AvatarGroup(
  children: [
    Avatar(imageUrl: 'url1', initials: 'A'),
    Avatar(imageUrl: 'url2', initials: 'B'),
    Avatar(initials: 'C'),
  ],
  max: 3,
)
AvatarGroup.toRight(children: [...])
```''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef AvatarGroupScenario = Scenario<AvatarGroup, AvatarGroupInputArgs>;
typedef AvatarGroupDefaults = Defaults<AvatarGroup, AvatarGroupInputArgs>;

class AvatarGroupStory extends Story<AvatarGroup, AvatarGroupInputArgs> {
  AvatarGroupStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AvatarGroupInputArgs? args,
    StoryWidgetBuilder<AvatarGroup, AvatarGroupInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AvatarGroupInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class AvatarGroupInputArgs extends StoryArgs<AvatarGroup> {
  AvatarGroupInputArgs({Arg<int>? count, Arg<int>? max})
    : this.countArg = $initArg('count', count, IntArg(_kDefaultGroupCount))!,
      this.maxArg = $initArg('max', max, IntArg(0))!;

  AvatarGroupInputArgs.fixed({int count = _kDefaultGroupCount, int max = 0})
    : this.countArg = $initArg('count', Arg.fixed(count), null)!,
      this.maxArg = $initArg('max', Arg.fixed(max), null)!;

  final Arg<int> countArg;

  final Arg<int> maxArg;

  int get count => countArg.value;

  int get max => maxArg.value;

  @override
  List<Arg?> get list => [countArg, maxArg];
}
