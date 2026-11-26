// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'validated.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Validated, StoryArgs<Validated>>;
typedef _Scenario = ValidatedScenario;
typedef _Defaults = ValidatedDefaults;
typedef _Story = ValidatedStory;
typedef _Args = ValidatedInputArgs;
final ValidatedComponent = Component<Validated, StoryArgs<Validated>>(
  name: kComponentMeta.name ?? 'Validated',
  path: kComponentMeta.path ?? 'component/validated',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''A unified validation wrapper for form fields.

`Validated` wraps a form field and visually indicates its
validation [state] through a coloured ring around the field, plus
an optional [message] rendered below it. It is the unified
presentational replacement for the legacy Web `Validated` and the
visual layer of the legacy Flutter `Validated<T>` — same parameter
names, same semantics, full visual parity.

When [state] is [CoreValidationState.pending] no ring is drawn and
the message is hidden; the `invalid` / `valid` states apply the
matching ring colour.

Every chrome / dimensional override flows through the single
[validatedStyle] field — see [CoreValidatedStyle] for the merge
chain.

Mirrors Web `Validated` 1:1 — same parameter names, same
semantics.

```dart
Validated(
  state: CoreValidationState.invalid,
  message: Text('This field is required.'),
  child: TextField(placeholder: 'Enter value'),
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $Pending..$generatedName = 'Pending',
    $Valid..$generatedName = 'Valid',
    $Invalid..$generatedName = 'Invalid',
  ],
);
typedef ValidatedScenario = Scenario<Validated, ValidatedInputArgs>;
typedef ValidatedDefaults = Defaults<Validated, ValidatedInputArgs>;

class ValidatedStory extends Story<Validated, ValidatedInputArgs> {
  ValidatedStory({
    super.name,
    super.designLink,
    SetupBuilder<Validated, ValidatedInputArgs>? setup,
    super.modes,
    ValidatedInputArgs? args,
    StoryWidgetBuilder<Validated, ValidatedInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ValidatedInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class ValidatedInputArgs extends StoryArgs<Validated> {
  ValidatedInputArgs({Arg<CoreValidationState>? state, Arg<String>? message})
    : this.stateArg = $initArg(
        'state',
        state,
        EnumArg<CoreValidationState>(
          CoreValidationState.invalid,
          values: CoreValidationState.values,
        ),
      )!,
      this.messageArg = $initArg(
        'message',
        message,
        StringArg('This field is required.'),
      )!;

  ValidatedInputArgs.fixed({
    CoreValidationState state = CoreValidationState.invalid,
    String message = 'This field is required.',
  }) : this.stateArg = $initArg('state', Arg.fixed(state), null)!,
       this.messageArg = $initArg('message', Arg.fixed(message), null)!;

  final Arg<CoreValidationState> stateArg;

  final Arg<String> messageArg;

  CoreValidationState get state => stateArg.value;

  String get message => messageArg.value;

  @override
  List<Arg?> get list => [stateArg, messageArg];
}
