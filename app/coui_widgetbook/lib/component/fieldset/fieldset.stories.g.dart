// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'fieldset.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Fieldset, StoryArgs<Fieldset>>;
typedef _Scenario = FieldsetScenario;
typedef _Defaults = FieldsetDefaults;
typedef _Story = FieldsetStory;
typedef _Args = FieldsetInputArgs;
final FieldsetComponent = Component<Fieldset, StoryArgs<Fieldset>>(
  name: kComponentMeta.name ?? 'Fieldset',
  path: kComponentMeta.path ?? 'component/fieldset',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''A grouped form section container with an optional legend and description.

Draws the group's boundary as set by [variant] — a faint panel
(`filled`, the default), the hairline edge alone (`outlined`), or no box
(`plain`) — with an optional [legend] and [description] at the top and a
vertical list of [children] with consistent spacing.

Per Epic #1302, every chrome / dimensional / nested-slot override
flows through the single [fieldsetStyle] (a [CoreFieldsetStyle]):

```text
design system default (variant row, size row)
  → CoreFieldsetTheme.style
  → CoreFieldsetTheme.variantStyles[variant]
  → parent component slot override
  → widget.fieldsetStyle
```

Example:
```dart
Fieldset(
  legend: Text('Personal Information'),
  description: Text('Used for billing and receipts.'),
  children: [
    TextField(placeholder: Text('Name')),
    TextField(placeholder: Text('Email')),
  ],
)
```

surface:content — a grouped-field panel that sits in the flow, not
something mounted over content.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Outlined..$generatedName = 'Outlined',
    $Plain..$generatedName = 'Plain',
    $WithoutLegend..$generatedName = 'WithoutLegend',
    $WithoutDescription..$generatedName = 'WithoutDescription',
    $Disabled..$generatedName = 'Disabled',
  ],
);
typedef FieldsetScenario = Scenario<Fieldset, FieldsetInputArgs>;
typedef FieldsetDefaults = Defaults<Fieldset, FieldsetInputArgs>;

class FieldsetStory extends Story<Fieldset, FieldsetInputArgs> {
  FieldsetStory({
    super.name,
    super.designLink,
    SetupBuilder<Fieldset, FieldsetInputArgs>? setup,
    super.modes,
    FieldsetInputArgs? args,
    StoryWidgetBuilder<Fieldset, FieldsetInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FieldsetInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class FieldsetInputArgs extends StoryArgs<Fieldset> {
  FieldsetInputArgs({
    Arg<CoreFieldsetVariant>? variant,
    Arg<String>? legend,
    Arg<bool>? showLegend,
    Arg<String>? description,
    Arg<bool>? showDescription,
    Arg<bool>? enabled,
  }) : this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreFieldsetVariant>(
           CoreFieldsetVariant.defaultVariant,
           values: CoreFieldsetVariant.values,
         ),
       )!,
       this.legendArg = $initArg('legend', legend, StringArg('Account'))!,
       this.showLegendArg = $initArg('showLegend', showLegend, BoolArg(true))!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg('Used to sign in.'),
       )!,
       this.showDescriptionArg = $initArg(
         'showDescription',
         showDescription,
         BoolArg(true),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  FieldsetInputArgs.fixed({
    CoreFieldsetVariant variant = CoreFieldsetVariant.defaultVariant,
    String legend = 'Account',
    bool showLegend = true,
    String description = 'Used to sign in.',
    bool showDescription = true,
    bool enabled = true,
  }) : this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.legendArg = $initArg('legend', Arg.fixed(legend), null)!,
       this.showLegendArg = $initArg(
         'showLegend',
         Arg.fixed(showLegend),
         null,
       )!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.showDescriptionArg = $initArg(
         'showDescription',
         Arg.fixed(showDescription),
         null,
       )!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<CoreFieldsetVariant> variantArg;

  final Arg<String> legendArg;

  final Arg<bool> showLegendArg;

  final Arg<String> descriptionArg;

  final Arg<bool> showDescriptionArg;

  final Arg<bool> enabledArg;

  CoreFieldsetVariant get variant => variantArg.value;

  String get legend => legendArg.value;

  bool get showLegend => showLegendArg.value;

  String get description => descriptionArg.value;

  bool get showDescription => showDescriptionArg.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [
    variantArg,
    legendArg,
    showLegendArg,
    descriptionArg,
    showDescriptionArg,
    enabledArg,
  ];
}
