// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'link.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<LinkDemo, StoryArgs<LinkDemo>>;
typedef _Scenario = LinkDemoScenario;
typedef _Defaults = LinkDemoDefaults;
typedef _Story = LinkDemoStory;
typedef _Args = LinkDemoArgs;
final LinkDemoComponent = Component<LinkDemo, StoryArgs<LinkDemo>>(
  name: kComponentMeta.name ?? 'LinkDemo',
  path: kComponentMeta.path ?? 'component/link',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Link] stories.

In interactive mode the link handles taps and shows a click
counter below.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Muted..$generatedName = 'Muted',
    $Underlined..$generatedName = 'Underlined',
    $Interactive..$generatedName = 'Interactive',
  ],
);
typedef LinkDemoScenario = Scenario<LinkDemo, LinkDemoArgs>;
typedef LinkDemoDefaults = Defaults<LinkDemo, LinkDemoArgs>;

class LinkDemoStory extends Story<LinkDemo, LinkDemoArgs> {
  LinkDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    LinkDemoArgs? args,
    StoryWidgetBuilder<LinkDemo, LinkDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? LinkDemoArgs(),
         builder:
             builder ??
             (context, args) => LinkDemo(
               key: args.key,
               text: args.text,
               external: args.external,
               underline: args.underline,
               variant: args.variant,
               interactive: args.interactive,
             ),
       );
}

class LinkDemoArgs extends StoryArgs<LinkDemo> {
  LinkDemoArgs({
    Arg<Key?>? key,
    Arg<String>? text,
    Arg<bool>? external,
    Arg<bool>? underline,
    Arg<CoreLinkVariant>? variant,
    Arg<bool>? interactive,
  }) : this.keyArg = $initArg('key', key, null),
       this.textArg = $initArg('text', text, StringArg('Click here'))!,
       this.externalArg = $initArg('external', external, BoolArg(false))!,
       this.underlineArg = $initArg('underline', underline, BoolArg(false))!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreLinkVariant>(
           CoreLinkVariant.standard,
           values: CoreLinkVariant.values,
         ),
       )!,
       this.interactiveArg = $initArg(
         'interactive',
         interactive,
         BoolArg(false),
       )!;

  LinkDemoArgs.fixed({
    Key? key,
    String text = 'Click here',
    bool external = false,
    bool underline = false,
    CoreLinkVariant variant = CoreLinkVariant.standard,
    bool interactive = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.externalArg = $initArg('external', Arg.fixed(external), null)!,
       this.underlineArg = $initArg('underline', Arg.fixed(underline), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.interactiveArg = $initArg(
         'interactive',
         Arg.fixed(interactive),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<String> textArg;

  final Arg<bool> externalArg;

  final Arg<bool> underlineArg;

  final Arg<CoreLinkVariant> variantArg;

  final Arg<bool> interactiveArg;

  Key? get key => keyArg?.value;

  String get text => textArg.value;

  bool get external => externalArg.value;

  bool get underline => underlineArg.value;

  CoreLinkVariant get variant => variantArg.value;

  bool get interactive => interactiveArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    textArg,
    externalArg,
    underlineArg,
    variantArg,
    interactiveArg,
  ];
}
