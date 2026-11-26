// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'label.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Label, StoryArgs<Label>>;
typedef _Scenario = LabelScenario;
typedef _Defaults = LabelDefaults;
typedef _Story = LabelStory;
typedef _Args = LabelInputArgs;
final LabelComponent = Component<Label, StoryArgs<Label>>(
  name: kComponentMeta.name ?? 'Label',
  path: kComponentMeta.path ?? 'component/label',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Static text label suitable for form fields.

Renders the label text with an optional leading icon and
required indicator (`*`). Supports a disabled state with reduced
opacity and a muted text color.

Chrome / dimensional / text-style overrides flow through the
single [labelStyle] slot per Epic #1302.

```dart
Label(
  text: 'Email',
  icon: Icon(LucideIcons.mail),
  isRequired: true,
)
```''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef LabelScenario = Scenario<Label, LabelInputArgs>;
typedef LabelDefaults = Defaults<Label, LabelInputArgs>;

class LabelStory extends Story<Label, LabelInputArgs> {
  LabelStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    LabelInputArgs? args,
    StoryWidgetBuilder<Label, LabelInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? LabelInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class LabelInputArgs extends StoryArgs<Label> {
  LabelInputArgs({
    Arg<String>? text,
    Arg<bool>? showIcon,
    Arg<bool>? isRequired,
    Arg<bool>? disabled,
  }) : this.textArg = $initArg('text', text, StringArg('Email'))!,
       this.showIconArg = $initArg('showIcon', showIcon, BoolArg(false))!,
       this.isRequiredArg = $initArg('isRequired', isRequired, BoolArg(false))!,
       this.disabledArg = $initArg('disabled', disabled, BoolArg(false))!;

  LabelInputArgs.fixed({
    String text = 'Email',
    bool showIcon = false,
    bool isRequired = false,
    bool disabled = false,
  }) : this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.showIconArg = $initArg('showIcon', Arg.fixed(showIcon), null)!,
       this.isRequiredArg = $initArg(
         'isRequired',
         Arg.fixed(isRequired),
         null,
       )!,
       this.disabledArg = $initArg('disabled', Arg.fixed(disabled), null)!;

  final Arg<String> textArg;

  final Arg<bool> showIconArg;

  final Arg<bool> isRequiredArg;

  final Arg<bool> disabledArg;

  String get text => textArg.value;

  bool get showIcon => showIconArg.value;

  bool get isRequired => isRequiredArg.value;

  bool get disabled => disabledArg.value;

  @override
  List<Arg?> get list => [textArg, showIconArg, isRequiredArg, disabledArg];
}
