// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'dropdown_menu.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DropdownMenuDemo, StoryArgs<DropdownMenuDemo>>;
typedef _Scenario = DropdownMenuDemoScenario;
typedef _Defaults = DropdownMenuDemoDefaults;
typedef _Story = DropdownMenuDemoStory;
typedef _Args = DropdownMenuDemoArgs;
final DropdownMenuDemoComponent =
    Component<DropdownMenuDemo, StoryArgs<DropdownMenuDemo>>(
      name: kComponentMeta.name ?? 'DropdownMenuDemo',
      path: kComponentMeta.path ?? 'component/dropdown_menu',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Interactive demo host that opens a [DropdownMenu] from a trigger
button.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef DropdownMenuDemoScenario =
    Scenario<DropdownMenuDemo, DropdownMenuDemoArgs>;
typedef DropdownMenuDemoDefaults =
    Defaults<DropdownMenuDemo, DropdownMenuDemoArgs>;

class DropdownMenuDemoStory
    extends Story<DropdownMenuDemo, DropdownMenuDemoArgs> {
  DropdownMenuDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    DropdownMenuDemoArgs? args,
    StoryWidgetBuilder<DropdownMenuDemo, DropdownMenuDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DropdownMenuDemoArgs(),
         builder: builder ?? (context, args) => DropdownMenuDemo(key: args.key),
       );
}

class DropdownMenuDemoArgs extends StoryArgs<DropdownMenuDemo> {
  DropdownMenuDemoArgs({Arg<Key?>? key})
    : this.keyArg = $initArg('key', key, null);

  DropdownMenuDemoArgs.fixed({Key? key})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
