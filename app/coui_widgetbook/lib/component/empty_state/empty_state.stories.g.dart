// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'empty_state.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<EmptyState, StoryArgs<EmptyState>>;
typedef _Scenario = EmptyStateScenario;
typedef _Defaults = EmptyStateDefaults;
typedef _Story = EmptyStateStory;
typedef _Args = EmptyStateInputArgs;
final EmptyStateComponent = Component<EmptyState, StoryArgs<EmptyState>>(
  name: kComponentMeta.name ?? 'EmptyState',
  path: kComponentMeta.path ?? 'component/empty_state',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform empty state.

Displays a placeholder view when there is no content, with optional
icon, title, description, and action button.

Implements [CoreEmptyStateContract] from `coui_core` for a
consistent cross-platform API. All chrome (padding / colours / gaps /
border / icon size) flows through [emptyStateStyle] — a single
[CoreEmptyStateStyle] slot — so widget-level overrides never split
the merge chain.

Example:
```dart
EmptyState(
  icon: Icon(LucideIcons.inbox),
  title: Text('No results found'),
  description: Text('Try adjusting your search criteria'),
  action: Button(
    variant: .primary,
    onPressed: () {},
    child: Text('Clear Filters'),
  ),
)
```''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef EmptyStateScenario = Scenario<EmptyState, EmptyStateInputArgs>;
typedef EmptyStateDefaults = Defaults<EmptyState, EmptyStateInputArgs>;

class EmptyStateStory extends Story<EmptyState, EmptyStateInputArgs> {
  EmptyStateStory({
    super.name,
    super.designLink,
    SetupBuilder<EmptyState, EmptyStateInputArgs>? setup,
    super.modes,
    EmptyStateInputArgs? args,
    StoryWidgetBuilder<EmptyState, EmptyStateInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? EmptyStateInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class EmptyStateInputArgs extends StoryArgs<EmptyState> {
  EmptyStateInputArgs({
    Arg<String>? title,
    Arg<String>? description,
    Arg<bool>? showIcon,
    Arg<bool>? showAction,
  }) : this.titleArg = $initArg('title', title, StringArg('No results found'))!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg('Try adjusting your search or filter criteria'),
       )!,
       this.showIconArg = $initArg('showIcon', showIcon, BoolArg(true))!,
       this.showActionArg = $initArg('showAction', showAction, BoolArg(true))!;

  EmptyStateInputArgs.fixed({
    String title = 'No results found',
    String description = 'Try adjusting your search or filter criteria',
    bool showIcon = true,
    bool showAction = true,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.showIconArg = $initArg('showIcon', Arg.fixed(showIcon), null)!,
       this.showActionArg = $initArg(
         'showAction',
         Arg.fixed(showAction),
         null,
       )!;

  final Arg<String> titleArg;

  final Arg<String> descriptionArg;

  final Arg<bool> showIconArg;

  final Arg<bool> showActionArg;

  String get title => titleArg.value;

  String get description => descriptionArg.value;

  bool get showIcon => showIconArg.value;

  bool get showAction => showActionArg.value;

  @override
  List<Arg?> get list => [titleArg, descriptionArg, showIconArg, showActionArg];
}
