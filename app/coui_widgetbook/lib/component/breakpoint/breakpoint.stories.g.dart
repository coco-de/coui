// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'breakpoint.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<BreakpointDemo, StoryArgs<BreakpointDemo>>;
typedef _Scenario = BreakpointDemoScenario;
typedef _Defaults = BreakpointDemoDefaults;
typedef _Story = BreakpointDemoStory;
typedef _Args = BreakpointDemoArgs;
final BreakpointDemoComponent =
    Component<BreakpointDemo, StoryArgs<BreakpointDemo>>(
      name: kComponentMeta.name ?? 'BreakpointDemo',
      path: kComponentMeta.path ?? 'component/breakpoint',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [Breakpoint] stories.

[Breakpoint] renders nothing — it is a value accessor answering "how wide
is the global viewport right now" through [Breakpoint.width],
[Breakpoint.coreBreakpoint] and [Breakpoint.tier]. This host prints those
three values and branches its pane layout on the resolved tier, so the
branch is visible rather than merely described.

The preview box keeps a fixed width on purpose: [Breakpoint] observes the
global viewport rather than its own containing box, so the tier flips
while the box stays put.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Mobile..$generatedName = 'Mobile',
        $Tablet..$generatedName = 'Tablet',
        $Desktop..$generatedName = 'Desktop',
      ],
    );
typedef BreakpointDemoScenario = Scenario<BreakpointDemo, BreakpointDemoArgs>;
typedef BreakpointDemoDefaults = Defaults<BreakpointDemo, BreakpointDemoArgs>;

class BreakpointDemoStory extends Story<BreakpointDemo, BreakpointDemoArgs> {
  BreakpointDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    BreakpointDemoArgs? args,
    StoryWidgetBuilder<BreakpointDemo, BreakpointDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? BreakpointDemoArgs(),
         builder:
             builder ??
             (context, args) => BreakpointDemo(
               key: args.key,
               simulatedWidth: args.simulatedWidth,
             ),
       );
}

class BreakpointDemoArgs extends StoryArgs<BreakpointDemo> {
  BreakpointDemoArgs({Arg<Key?>? key, Arg<double>? simulatedWidth})
    : this.keyArg = $initArg('key', key, null),
      this.simulatedWidthArg = $initArg(
        'simulatedWidth',
        simulatedWidth,
        DoubleArg(_kObserveHostViewport),
      )!;

  BreakpointDemoArgs.fixed({
    Key? key,
    double simulatedWidth = _kObserveHostViewport,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.simulatedWidthArg = $initArg(
         'simulatedWidth',
         Arg.fixed(simulatedWidth),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<double> simulatedWidthArg;

  Key? get key => keyArg?.value;

  double get simulatedWidth => simulatedWidthArg.value;

  @override
  List<Arg?> get list => [keyArg, simulatedWidthArg];
}
