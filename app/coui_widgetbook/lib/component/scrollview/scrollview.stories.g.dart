// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'scrollview.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<ScrollViewInterceptorDemo, StoryArgs<ScrollViewInterceptorDemo>>;
typedef _Scenario = ScrollViewInterceptorDemoScenario;
typedef _Defaults = ScrollViewInterceptorDemoDefaults;
typedef _Story = ScrollViewInterceptorDemoStory;
typedef _Args = ScrollViewInterceptorDemoArgs;
final ScrollViewInterceptorDemoComponent =
    Component<ScrollViewInterceptorDemo, StoryArgs<ScrollViewInterceptorDemo>>(
      name: kComponentMeta.name ?? 'ScrollViewInterceptorDemo',
      path: kComponentMeta.path ?? 'component/scrollview',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [ScrollViewInterceptor] stories.

Wraps a [ListView] so wheel / drag scrolling can be intercepted
(or passed through) depending on [enabled].''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef ScrollViewInterceptorDemoScenario =
    Scenario<ScrollViewInterceptorDemo, ScrollViewInterceptorDemoArgs>;
typedef ScrollViewInterceptorDemoDefaults =
    Defaults<ScrollViewInterceptorDemo, ScrollViewInterceptorDemoArgs>;

class ScrollViewInterceptorDemoStory
    extends Story<ScrollViewInterceptorDemo, ScrollViewInterceptorDemoArgs> {
  ScrollViewInterceptorDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ScrollViewInterceptorDemoArgs? args,
    StoryWidgetBuilder<
      ScrollViewInterceptorDemo,
      ScrollViewInterceptorDemoArgs
    >?
    builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ScrollViewInterceptorDemoArgs(),
         builder:
             builder ??
             (context, args) => ScrollViewInterceptorDemo(
               key: args.key,
               enabled: args.enabled,
             ),
       );
}

class ScrollViewInterceptorDemoArgs
    extends StoryArgs<ScrollViewInterceptorDemo> {
  ScrollViewInterceptorDemoArgs({Arg<Key?>? key, Arg<bool>? enabled})
    : this.keyArg = $initArg('key', key, null),
      this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  ScrollViewInterceptorDemoArgs.fixed({Key? key, bool enabled = true})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg];
}
