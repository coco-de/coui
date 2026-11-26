// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'join.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Join, StoryArgs<Join>>;
typedef _Scenario = JoinScenario;
typedef _Defaults = JoinDefaults;
typedef _Story = JoinStory;
typedef _Args = JoinInputArgs;
final JoinComponent = Component<Join, StoryArgs<Join>>(
  name: kComponentMeta.name ?? 'Join',
  path: kComponentMeta.path ?? 'component/join',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform join component for Flutter.

Groups children into a visually connected strip. Each item is
clipped with a position-aware radius, and an ambient [JoinItemData]
tells radius-bearing children (e.g. `Button`) to flatten their own
corners against the seams — the clip alone only crops outside the
wrapper, so a child's self-painted rounded corner would otherwise
remain as a notch (the Web twin overrides the child radius with a
scoped CSS rule the same way).

Uses [CoreJoinContract] from `coui_core` for consistent
cross-platform API. Chrome / dimensional overrides flow through
the single [joinStyle] slot per Epic #1302.

Example:
```dart
Join(
  children: [
    Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text('1')),
    Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text('2')),
    Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text('3')),
  ],
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $Vertical..$generatedName = 'Vertical',
  ],
);
typedef JoinScenario = Scenario<Join, JoinInputArgs>;
typedef JoinDefaults = Defaults<Join, JoinInputArgs>;

class JoinStory extends Story<Join, JoinInputArgs> {
  JoinStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    JoinInputArgs? args,
    StoryWidgetBuilder<Join, JoinInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? JoinInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class JoinInputArgs extends StoryArgs<Join> {
  JoinInputArgs({Arg<bool>? vertical})
    : this.verticalArg = $initArg('vertical', vertical, BoolArg(false))!;

  JoinInputArgs.fixed({bool vertical = false})
    : this.verticalArg = $initArg('vertical', Arg.fixed(vertical), null)!;

  final Arg<bool> verticalArg;

  bool get vertical => verticalArg.value;

  @override
  List<Arg?> get list => [verticalArg];
}
