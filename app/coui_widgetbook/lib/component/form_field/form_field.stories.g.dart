// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'form_field.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<FormFieldDemo, StoryArgs<FormFieldDemo>>;
typedef _Scenario = FormFieldDemoScenario;
typedef _Defaults = FormFieldDemoDefaults;
typedef _Story = FormFieldDemoStory;
typedef _Args = FormFieldDemoArgs;
final FormFieldDemoComponent =
    Component<FormFieldDemo, StoryArgs<FormFieldDemo>>(
      name: kComponentMeta.name ?? 'FormFieldDemo',
      path: kComponentMeta.path ?? 'component/form_field',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [FormField] stories.''',
      stories: [
        $Default..$generatedName = 'Default',
        $WithError..$generatedName = 'WithError',
        $InteractiveValidation..$generatedName = 'InteractiveValidation',
      ],
    );
typedef FormFieldDemoScenario = Scenario<FormFieldDemo, FormFieldDemoArgs>;
typedef FormFieldDemoDefaults = Defaults<FormFieldDemo, FormFieldDemoArgs>;

class FormFieldDemoStory extends Story<FormFieldDemo, FormFieldDemoArgs> {
  FormFieldDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    FormFieldDemoArgs? args,
    StoryWidgetBuilder<FormFieldDemo, FormFieldDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FormFieldDemoArgs(),
         builder:
             builder ??
             (context, args) => FormFieldDemo(
               key: args.key,
               label: args.label,
               description: args.description,
               error: args.error,
               required: args.required,
               enabled: args.enabled,
               interactive: args.interactive,
             ),
       );
}

class FormFieldDemoArgs extends StoryArgs<FormFieldDemo> {
  FormFieldDemoArgs({
    Arg<Key?>? key,
    Arg<String>? label,
    Arg<String>? description,
    Arg<String>? error,
    Arg<bool>? required,
    Arg<bool>? enabled,
    Arg<bool>? interactive,
  }) : this.keyArg = $initArg('key', key, null),
       this.labelArg = $initArg('label', label, StringArg('Email'))!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg('Enter your work email address.'),
       )!,
       this.errorArg = $initArg('error', error, StringArg(''))!,
       this.requiredArg = $initArg('required', required, BoolArg(true))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.interactiveArg = $initArg(
         'interactive',
         interactive,
         BoolArg(false),
       )!;

  FormFieldDemoArgs.fixed({
    Key? key,
    String label = 'Email',
    String description = 'Enter your work email address.',
    String error = '',
    bool required = true,
    bool enabled = true,
    bool interactive = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.errorArg = $initArg('error', Arg.fixed(error), null)!,
       this.requiredArg = $initArg('required', Arg.fixed(required), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.interactiveArg = $initArg(
         'interactive',
         Arg.fixed(interactive),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<String> labelArg;

  final Arg<String> descriptionArg;

  final Arg<String> errorArg;

  final Arg<bool> requiredArg;

  final Arg<bool> enabledArg;

  final Arg<bool> interactiveArg;

  Key? get key => keyArg?.value;

  String get label => labelArg.value;

  String get description => descriptionArg.value;

  String get error => errorArg.value;

  bool get required => requiredArg.value;

  bool get enabled => enabledArg.value;

  bool get interactive => interactiveArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    labelArg,
    descriptionArg,
    errorArg,
    requiredArg,
    enabledArg,
    interactiveArg,
  ];
}
