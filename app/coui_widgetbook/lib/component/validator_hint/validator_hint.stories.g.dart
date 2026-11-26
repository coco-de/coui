// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'validator_hint.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ValidatorHint, StoryArgs<ValidatorHint>>;
typedef _Scenario = ValidatorHintScenario;
typedef _Defaults = ValidatorHintDefaults;
typedef _Story = ValidatorHintStory;
typedef _Args = ValidatorHintInputArgs;
final ValidatorHintComponent =
    Component<ValidatorHint, StoryArgs<ValidatorHint>>(
      name: kComponentMeta.name ?? 'ValidatorHint',
      path: kComponentMeta.path ?? 'component/validator_hint',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''A unified validation-hint message for form fields.

`ValidatorHint` displays a validation message (error / warning /
info / success) below a form input, with a leading severity icon.
It is the unified replacement for the legacy Flutter and Web
`ValidatorHint` — same parameter names, same semantics, full visual
parity.

When [visible] is `false` the component collapses to zero size.
The [type] drives the per-type accent colour (applied to both the
icon and the message) and the default leading icon.

Every chrome / typography override flows through the single
[validatorHintStyle] field — see [CoreValidatorHintStyle] for the
merge chain.

Mirrors Web `ValidatorHint` 1:1 — same parameter names, same
semantics.

```dart
ValidatorHint(message: Text('This field is required'))
ValidatorHint.success(message: Text('Looks good'))
```''',
      stories: [
        $Default..$generatedName = 'Default',
        $Warning..$generatedName = 'Warning',
        $Success..$generatedName = 'Success',
      ],
    );
typedef ValidatorHintScenario = Scenario<ValidatorHint, ValidatorHintInputArgs>;
typedef ValidatorHintDefaults = Defaults<ValidatorHint, ValidatorHintInputArgs>;

class ValidatorHintStory extends Story<ValidatorHint, ValidatorHintInputArgs> {
  ValidatorHintStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ValidatorHintInputArgs? args,
    StoryWidgetBuilder<ValidatorHint, ValidatorHintInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ValidatorHintInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class ValidatorHintInputArgs extends StoryArgs<ValidatorHint> {
  ValidatorHintInputArgs({
    Arg<String>? message,
    Arg<CoreValidatorHintType>? type,
    Arg<bool>? visible,
  }) : this.messageArg = $initArg(
         'message',
         message,
         StringArg('This field is required'),
       )!,
       this.typeArg = $initArg(
         'type',
         type,
         EnumArg<CoreValidatorHintType>(
           CoreValidatorHintType.error,
           values: CoreValidatorHintType.values,
         ),
       )!,
       this.visibleArg = $initArg('visible', visible, BoolArg(true))!;

  ValidatorHintInputArgs.fixed({
    String message = 'This field is required',
    CoreValidatorHintType type = CoreValidatorHintType.error,
    bool visible = true,
  }) : this.messageArg = $initArg('message', Arg.fixed(message), null)!,
       this.typeArg = $initArg('type', Arg.fixed(type), null)!,
       this.visibleArg = $initArg('visible', Arg.fixed(visible), null)!;

  final Arg<String> messageArg;

  final Arg<CoreValidatorHintType> typeArg;

  final Arg<bool> visibleArg;

  String get message => messageArg.value;

  CoreValidatorHintType get type => typeArg.value;

  bool get visible => visibleArg.value;

  @override
  List<Arg?> get list => [messageArg, typeArg, visibleArg];
}
