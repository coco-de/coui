// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'form_label.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<FormLabel, StoryArgs<FormLabel>>;
typedef _Scenario = FormLabelScenario;
typedef _Defaults = FormLabelDefaults;
typedef _Story = FormLabelStory;
typedef _Args = FormLabelInputArgs;
final FormLabelComponent = Component<FormLabel, StoryArgs<FormLabel>>(
  name: kComponentMeta.name ?? 'FormLabel',
  path: kComponentMeta.path ?? 'component/form_label',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''A unified label for form fields.

`FormLabel` renders descriptive text for a form input with an
optional required indicator (`*`) appended after the label. It is
the unified replacement for the legacy Flutter and Web `FormLabel`
— same parameter names, same semantics, full visual parity.

When [isRequired] is `true`, the [requiredIndicator] is shown after
the label; when no custom indicator is supplied an error-coloured
asterisk is rendered.

Every chrome / typography override flows through the single
[formLabelStyle] field — see [CoreFormLabelStyle] for the merge
chain.

Mirrors Web `FormLabel` 1:1 — same parameter names, same
semantics.

```dart
FormLabel(label: Text('Email Address'))
FormLabel(label: Text('Password'), isRequired: true)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $CustomRequiredIndicator..$generatedName = 'CustomRequiredIndicator',
  ],
);
typedef FormLabelScenario = Scenario<FormLabel, FormLabelInputArgs>;
typedef FormLabelDefaults = Defaults<FormLabel, FormLabelInputArgs>;

class FormLabelStory extends Story<FormLabel, FormLabelInputArgs> {
  FormLabelStory({
    super.name,
    super.designLink,
    SetupBuilder<FormLabel, FormLabelInputArgs>? setup,
    super.modes,
    FormLabelInputArgs? args,
    StoryWidgetBuilder<FormLabel, FormLabelInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FormLabelInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class FormLabelInputArgs extends StoryArgs<FormLabel> {
  FormLabelInputArgs({
    Arg<String>? label,
    Arg<bool>? required,
    Arg<bool>? customIndicator,
  }) : this.labelArg = $initArg('label', label, StringArg('Email Address'))!,
       this.requiredArg = $initArg('required', required, BoolArg(false))!,
       this.customIndicatorArg = $initArg(
         'customIndicator',
         customIndicator,
         BoolArg(false),
       )!;

  FormLabelInputArgs.fixed({
    String label = 'Email Address',
    bool required = false,
    bool customIndicator = false,
  }) : this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.requiredArg = $initArg('required', Arg.fixed(required), null)!,
       this.customIndicatorArg = $initArg(
         'customIndicator',
         Arg.fixed(customIndicator),
         null,
       )!;

  final Arg<String> labelArg;

  final Arg<bool> requiredArg;

  final Arg<bool> customIndicatorArg;

  String get label => labelArg.value;

  bool get required => requiredArg.value;

  bool get customIndicator => customIndicatorArg.value;

  @override
  List<Arg?> get list => [labelArg, requiredArg, customIndicatorArg];
}
