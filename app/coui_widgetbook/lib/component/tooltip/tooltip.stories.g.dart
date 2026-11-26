// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'tooltip.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Tooltip, StoryArgs<Tooltip>>;
typedef _Scenario = TooltipScenario;
typedef _Defaults = TooltipDefaults;
typedef _Story = TooltipStory;
typedef _Args = TooltipInputArgs;
final TooltipComponent = Component<Tooltip, StoryArgs<Tooltip>>(
  name: kComponentMeta.name ?? 'Tooltip',
  path: kComponentMeta.path ?? 'component/tooltip',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform tooltip with token-based rendering.

Wraps a trigger [child] and shows a tooltip on pointer hover, driven
by the [Hover] widget for wait / show / min timing and the shared
[PopoverOverlayHandler] for overlay placement. There is no keyboard
focus or touch (long-press) trigger yet — see the component doc for
current platform coverage.

Per Epic #1302, all panel-chrome / dimensional / surface-effect
overrides flow through [tooltipStyle]
(`CoreTooltipStyle`). Semantic [position] stays as a top-level
widget parameter (원칙 6/7).

Example:
```dart
Tooltip(
  message: 'Add to favorites',
  child: Button(
    onPressed: () {},
    leading: Icon(LucideIcons.heart),
  ),
)
```

surface:functional — the overlay positioner anchors it over whatever it
describes.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Top..$generatedName = 'Top',
    $Bottom..$generatedName = 'Bottom',
    $Left..$generatedName = 'Left',
    $Right..$generatedName = 'Right',
  ],
);
typedef TooltipScenario = Scenario<Tooltip, TooltipInputArgs>;
typedef TooltipDefaults = Defaults<Tooltip, TooltipInputArgs>;

class TooltipStory extends Story<Tooltip, TooltipInputArgs> {
  TooltipStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    TooltipInputArgs? args,
    StoryWidgetBuilder<Tooltip, TooltipInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TooltipInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class TooltipInputArgs extends StoryArgs<Tooltip> {
  TooltipInputArgs({
    Arg<String>? message,
    Arg<CoreTooltipPosition>? position,
    Arg<bool>? showIconChild,
    Arg<String>? label,
  }) : this.messageArg = $initArg(
         'message',
         message,
         StringArg('Helpful message'),
       )!,
       this.positionArg = $initArg(
         'position',
         position,
         EnumArg<CoreTooltipPosition>(
           CoreTooltipPosition.top,
           values: CoreTooltipPosition.values,
         ),
       )!,
       this.showIconChildArg = $initArg(
         'showIconChild',
         showIconChild,
         BoolArg(true),
       )!,
       this.labelArg = $initArg('label', label, StringArg('Hover me'))!;

  TooltipInputArgs.fixed({
    String message = 'Helpful message',
    CoreTooltipPosition position = CoreTooltipPosition.top,
    bool showIconChild = true,
    String label = 'Hover me',
  }) : this.messageArg = $initArg('message', Arg.fixed(message), null)!,
       this.positionArg = $initArg('position', Arg.fixed(position), null)!,
       this.showIconChildArg = $initArg(
         'showIconChild',
         Arg.fixed(showIconChild),
         null,
       )!,
       this.labelArg = $initArg('label', Arg.fixed(label), null)!;

  final Arg<String> messageArg;

  final Arg<CoreTooltipPosition> positionArg;

  final Arg<bool> showIconChildArg;

  final Arg<String> labelArg;

  String get message => messageArg.value;

  CoreTooltipPosition get position => positionArg.value;

  bool get showIconChild => showIconChildArg.value;

  String get label => labelArg.value;

  @override
  List<Arg?> get list => [messageArg, positionArg, showIconChildArg, labelArg];
}
