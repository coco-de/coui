// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'validation_badge.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ValidationBadge, StoryArgs<ValidationBadge>>;
typedef _Scenario = ValidationBadgeScenario;
typedef _Defaults = ValidationBadgeDefaults;
typedef _Story = ValidationBadgeStory;
typedef _Args = ValidationBadgeInputArgs;
final ValidationBadgeComponent =
    Component<ValidationBadge, StoryArgs<ValidationBadge>>(
      name: kComponentMeta.name ?? 'ValidationBadge',
      path: kComponentMeta.path ?? 'component/validation_badge',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Cross-platform validation badge — communicates the result of a single
validation rule (pending / valid / invalid) with a colored chip-style
container, an icon, and a label.

```dart
ValidationBadge(
  label: '8 characters or more',
  state: password.length >= 8
      ? CoreValidationState.valid
      : CoreValidationState.invalid,
);

ValidationBadge.fromBool(label: 'Has digit', isValid: hasDigit);

ValidationBadge.withPending(
  label: 'Has digit',
  hasInput: password.isNotEmpty,
  isValid: hasDigit,
);
```

surface:behind — whatever the badge is set inline against (a form
field's helper row, a card). It draws its own box rather than
composing `OutlinedContainer` — the Web twin's root is a fixed
`<span>`, and wrapping that in `OutlinedContainer`'s `<div>` breaks
the inline flow it is meant to sit in (#4358) — so the marker is
restated here directly.

surface:content — a state chip in the content layer, not a floating
affordance: no sticky, fixed, or overlay mount on either platform.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Valid..$generatedName = 'Valid',
        $Invalid..$generatedName = 'Invalid',
      ],
    );
typedef ValidationBadgeScenario =
    Scenario<ValidationBadge, ValidationBadgeInputArgs>;
typedef ValidationBadgeDefaults =
    Defaults<ValidationBadge, ValidationBadgeInputArgs>;

class ValidationBadgeStory
    extends Story<ValidationBadge, ValidationBadgeInputArgs> {
  ValidationBadgeStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ValidationBadgeInputArgs? args,
    StoryWidgetBuilder<ValidationBadge, ValidationBadgeInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ValidationBadgeInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class ValidationBadgeInputArgs extends StoryArgs<ValidationBadge> {
  ValidationBadgeInputArgs({
    Arg<String>? label,
    Arg<CoreValidationState>? state,
    Arg<CoreValidationBadgeSize>? size,
  }) : this.labelArg = $initArg(
         'label',
         label,
         StringArg('Validation Status'),
       )!,
       this.stateArg = $initArg(
         'state',
         state,
         EnumArg<CoreValidationState>(
           CoreValidationState.pending,
           values: CoreValidationState.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreValidationBadgeSize>(
           CoreValidationBadgeSize.small,
           values: CoreValidationBadgeSize.values,
         ),
       )!;

  ValidationBadgeInputArgs.fixed({
    String label = 'Validation Status',
    CoreValidationState state = CoreValidationState.pending,
    CoreValidationBadgeSize size = CoreValidationBadgeSize.small,
  }) : this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.stateArg = $initArg('state', Arg.fixed(state), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!;

  final Arg<String> labelArg;

  final Arg<CoreValidationState> stateArg;

  final Arg<CoreValidationBadgeSize> sizeArg;

  String get label => labelArg.value;

  CoreValidationState get state => stateArg.value;

  CoreValidationBadgeSize get size => sizeArg.value;

  @override
  List<Arg?> get list => [labelArg, stateArg, sizeArg];
}
