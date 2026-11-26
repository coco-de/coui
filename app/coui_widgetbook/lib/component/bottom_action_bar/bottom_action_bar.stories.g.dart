// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'bottom_action_bar.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<BottomActionBar, StoryArgs<BottomActionBar>>;
typedef _Scenario = BottomActionBarScenario;
typedef _Defaults = BottomActionBarDefaults;
typedef _Story = BottomActionBarStory;
typedef _Args = BottomActionBarInputArgs;
final BottomActionBarComponent =
    Component<BottomActionBar, StoryArgs<BottomActionBar>>(
      name: kComponentMeta.name ?? 'BottomActionBar',
      path: kComponentMeta.path ?? 'component/bottom_action_bar',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Unified cross-platform action area pinned to the bottom of a screen — the
one or two buttons that finish a flow, and an optional short note above
them.

Uses [CoreBottomActionBarContract] from `coui_core`, so the Web
`BottomActionBar` takes the same named properties. The bar owns the
arrangement, the padding, the hairline above it ([showDivider]) and the
filled surface; the buttons are the caller's own and keep their own size
and look. Each action gets the full width of its cell, so a `Button`
inside needs no `expanded` of its own.

The [layout] stacks the actions in one column (the primary action on
top) or sets them in one row of equal-width cells (the secondary action
first, the primary action last). The note sits above either.

The bottom padding is added to the device's bottom safe area: the
surface paints under the home indicator and the actions sit above it.
Colours, padding, spacing, the hairline and the note's text style flow
from the widget → `CoreComponentTheme.bottomActionBar` → design system
defaults ([CoreBottomActionBarStyle]).

```dart
BottomActionBar(
  description: Text('By continuing you agree to the terms.'),
  primaryAction: Button(size: .xl, child: Text('Register')),
  secondaryAction: Button(variant: .ghost, child: Text('Not now')),
)
```

surface:behind — the shell stacks this bar over a body that scrolls
beneath it.

surface:functional — the bar groups the actions that finish a flow above
the page it is docked to.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Horizontal..$generatedName = 'Horizontal',
        $PrimaryOnly..$generatedName = 'PrimaryOnly',
        $NoDivider..$generatedName = 'NoDivider',
        $SafeArea..$generatedName = 'SafeArea',
      ],
    );
typedef BottomActionBarScenario =
    Scenario<BottomActionBar, BottomActionBarInputArgs>;
typedef BottomActionBarDefaults =
    Defaults<BottomActionBar, BottomActionBarInputArgs>;

class BottomActionBarStory
    extends Story<BottomActionBar, BottomActionBarInputArgs> {
  BottomActionBarStory({
    super.name,
    super.designLink,
    SetupBuilder<BottomActionBar, BottomActionBarInputArgs>? setup,
    super.modes,
    BottomActionBarInputArgs? args,
    StoryWidgetBuilder<BottomActionBar, BottomActionBarInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? BottomActionBarInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class BottomActionBarInputArgs extends StoryArgs<BottomActionBar> {
  BottomActionBarInputArgs({
    Arg<String>? description,
    Arg<String>? primaryLabel,
    Arg<String>? secondaryLabel,
    Arg<bool>? showSecondary,
    Arg<CoreBottomActionBarLayout>? layout,
    Arg<bool>? showDivider,
  }) : this.descriptionArg = $initArg(
         'description',
         description,
         StringArg('By continuing you agree to the terms.'),
       )!,
       this.primaryLabelArg = $initArg(
         'primaryLabel',
         primaryLabel,
         StringArg('Register'),
       )!,
       this.secondaryLabelArg = $initArg(
         'secondaryLabel',
         secondaryLabel,
         StringArg('Not now'),
       )!,
       this.showSecondaryArg = $initArg(
         'showSecondary',
         showSecondary,
         BoolArg(true),
       )!,
       this.layoutArg = $initArg(
         'layout',
         layout,
         EnumArg<CoreBottomActionBarLayout>(
           CoreBottomActionBarLayout.defaultLayout,
           values: CoreBottomActionBarLayout.values,
         ),
       )!,
       this.showDividerArg = $initArg(
         'showDivider',
         showDivider,
         BoolArg(CoreBottomActionBarContract.defaultShowDivider),
       )!;

  BottomActionBarInputArgs.fixed({
    String description = 'By continuing you agree to the terms.',
    String primaryLabel = 'Register',
    String secondaryLabel = 'Not now',
    bool showSecondary = true,
    CoreBottomActionBarLayout layout = CoreBottomActionBarLayout.defaultLayout,
    bool showDivider = CoreBottomActionBarContract.defaultShowDivider,
  }) : this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.primaryLabelArg = $initArg(
         'primaryLabel',
         Arg.fixed(primaryLabel),
         null,
       )!,
       this.secondaryLabelArg = $initArg(
         'secondaryLabel',
         Arg.fixed(secondaryLabel),
         null,
       )!,
       this.showSecondaryArg = $initArg(
         'showSecondary',
         Arg.fixed(showSecondary),
         null,
       )!,
       this.layoutArg = $initArg('layout', Arg.fixed(layout), null)!,
       this.showDividerArg = $initArg(
         'showDivider',
         Arg.fixed(showDivider),
         null,
       )!;

  final Arg<String> descriptionArg;

  final Arg<String> primaryLabelArg;

  final Arg<String> secondaryLabelArg;

  final Arg<bool> showSecondaryArg;

  final Arg<CoreBottomActionBarLayout> layoutArg;

  final Arg<bool> showDividerArg;

  String get description => descriptionArg.value;

  String get primaryLabel => primaryLabelArg.value;

  String get secondaryLabel => secondaryLabelArg.value;

  bool get showSecondary => showSecondaryArg.value;

  CoreBottomActionBarLayout get layout => layoutArg.value;

  bool get showDivider => showDividerArg.value;

  @override
  List<Arg?> get list => [
    descriptionArg,
    primaryLabelArg,
    secondaryLabelArg,
    showSecondaryArg,
    layoutArg,
    showDividerArg,
  ];
}
