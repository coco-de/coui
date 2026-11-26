// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'form.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<FormDemo, StoryArgs<FormDemo>>;
typedef _Scenario = FormDemoScenario;
typedef _Defaults = FormDemoDefaults;
typedef _Story = FormDemoStory;
typedef _Args = FormDemoArgs;
final FormDemoComponent = Component<FormDemo, StoryArgs<FormDemo>>(
  name: kComponentMeta.name ?? 'FormDemo',
  path: kComponentMeta.path ?? 'component/form',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Form] stories.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef FormDemoScenario = Scenario<FormDemo, FormDemoArgs>;
typedef FormDemoDefaults = Defaults<FormDemo, FormDemoArgs>;

class FormDemoStory extends Story<FormDemo, FormDemoArgs> {
  FormDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    FormDemoArgs? args,
    StoryWidgetBuilder<FormDemo, FormDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FormDemoArgs(),
         builder:
             builder ??
             (context, args) =>
                 FormDemo(key: args.key, rowSpacing: args.rowSpacing),
       );
}

class FormDemoArgs extends StoryArgs<FormDemo> {
  FormDemoArgs({Arg<Key?>? key, Arg<double>? rowSpacing})
    : this.keyArg = $initArg('key', key, null),
      this.rowSpacingArg = $initArg(
        'rowSpacing',
        rowSpacing,
        DoubleArg(CoreSpace.space16),
      )!;

  FormDemoArgs.fixed({Key? key, double rowSpacing = CoreSpace.space16})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.rowSpacingArg = $initArg('rowSpacing', Arg.fixed(rowSpacing), null)!;

  final Arg<Key?>? keyArg;

  final Arg<double> rowSpacingArg;

  Key? get key => keyArg?.value;

  double get rowSpacing => rowSpacingArg.value;

  @override
  List<Arg?> get list => [keyArg, rowSpacingArg];
}
