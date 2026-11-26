// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'basic.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Basic, StoryArgs<Basic>>;
typedef _Scenario = BasicScenario;
typedef _Defaults = BasicDefaults;
typedef _Story = BasicStory;
typedef _Args = BasicInputArgs;
final BasicComponent = Component<Basic, StoryArgs<Basic>>(
  name: kComponentMeta.name ?? 'Basic',
  path: kComponentMeta.path ?? 'component/basic',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified slot-based layout.

Arranges up to five slots — [leading], [title], [subtitle], [content],
[trailing] — inside a single row. Title/subtitle/content stack vertically
in the middle cell; leading and trailing occupy the outer cells with their
own alignment.

Replaces legacy `Basic` and `BasicLayout` — the `forceTextStyle` flag
chooses between the two behaviours:

- `true` (default): applies CoUI's default text styles
  (title = small-medium, subtitle = xs muted, content = small). Matches
  legacy [Basic].
- `false`: slots are rendered without any enforced typography. Matches
  legacy `BasicLayout`.

```dart
Basic(
  leading: Icon(LucideIcons.star),
  title: Text('Awesome'),
  subtitle: Text('Shiny'),
  content: Text('Long description ...'),
  trailing: Icon(LucideIcons.chevronRight),
)
```''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef BasicScenario = Scenario<Basic, BasicInputArgs>;
typedef BasicDefaults = Defaults<Basic, BasicInputArgs>;

class BasicStory extends Story<Basic, BasicInputArgs> {
  BasicStory({
    super.name,
    super.designLink,
    SetupBuilder<Basic, BasicInputArgs>? setup,
    super.modes,
    BasicInputArgs? args,
    StoryWidgetBuilder<Basic, BasicInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? BasicInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class BasicInputArgs extends StoryArgs<Basic> {
  BasicInputArgs({
    Arg<String>? title,
    Arg<String>? subtitle,
    Arg<String>? content,
    Arg<bool>? showLeading,
    Arg<bool>? showTrailing,
  }) : this.titleArg = $initArg('title', title, StringArg('John Doe'))!,
       this.subtitleArg = $initArg(
         'subtitle',
         subtitle,
         StringArg('Software Engineer'),
       )!,
       this.contentArg = $initArg(
         'content',
         content,
         StringArg('This is the content area of the Basic layout.'),
       )!,
       this.showLeadingArg = $initArg(
         'showLeading',
         showLeading,
         BoolArg(true),
       )!,
       this.showTrailingArg = $initArg(
         'showTrailing',
         showTrailing,
         BoolArg(true),
       )!;

  BasicInputArgs.fixed({
    String title = 'John Doe',
    String subtitle = 'Software Engineer',
    String content = 'This is the content area of the Basic layout.',
    bool showLeading = true,
    bool showTrailing = true,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.subtitleArg = $initArg('subtitle', Arg.fixed(subtitle), null)!,
       this.contentArg = $initArg('content', Arg.fixed(content), null)!,
       this.showLeadingArg = $initArg(
         'showLeading',
         Arg.fixed(showLeading),
         null,
       )!,
       this.showTrailingArg = $initArg(
         'showTrailing',
         Arg.fixed(showTrailing),
         null,
       )!;

  final Arg<String> titleArg;

  final Arg<String> subtitleArg;

  final Arg<String> contentArg;

  final Arg<bool> showLeadingArg;

  final Arg<bool> showTrailingArg;

  String get title => titleArg.value;

  String get subtitle => subtitleArg.value;

  String get content => contentArg.value;

  bool get showLeading => showLeadingArg.value;

  bool get showTrailing => showTrailingArg.value;

  @override
  List<Arg?> get list => [
    titleArg,
    subtitleArg,
    contentArg,
    showLeadingArg,
    showTrailingArg,
  ];
}
