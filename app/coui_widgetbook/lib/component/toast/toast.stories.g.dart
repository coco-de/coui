// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'toast.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ToastDemo, StoryArgs<ToastDemo>>;
typedef _Scenario = ToastDemoScenario;
typedef _Defaults = ToastDemoDefaults;
typedef _Story = ToastDemoStory;
typedef _Args = ToastDemoArgs;
final ToastDemoComponent = Component<ToastDemo, StoryArgs<ToastDemo>>(
  name: kComponentMeta.name ?? 'ToastDemo',
  path: kComponentMeta.path ?? 'component/toast',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Toast] stories.

Renders a trigger button that shows a [Toast] through the app-level
[ToastLayer] when pressed.''',
  stories: [
    $Default..$generatedName = 'Default',
    $TopLeft..$generatedName = 'TopLeft',
    $TopCenter..$generatedName = 'TopCenter',
    $TopRight..$generatedName = 'TopRight',
    $BottomLeft..$generatedName = 'BottomLeft',
    $BottomCenter..$generatedName = 'BottomCenter',
    $BottomRight..$generatedName = 'BottomRight',
  ],
);
typedef ToastDemoScenario = Scenario<ToastDemo, ToastDemoArgs>;
typedef ToastDemoDefaults = Defaults<ToastDemo, ToastDemoArgs>;

class ToastDemoStory extends Story<ToastDemo, ToastDemoArgs> {
  ToastDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ToastDemoArgs? args,
    StoryWidgetBuilder<ToastDemo, ToastDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ToastDemoArgs(),
         builder:
             builder ??
             (context, args) => ToastDemo(
               key: args.key,
               location: args.location,
               durationSeconds: args.durationSeconds,
               message: args.message,
               description: args.description,
             ),
       );
}

class ToastDemoArgs extends StoryArgs<ToastDemo> {
  ToastDemoArgs({
    Arg<Key?>? key,
    Arg<ToastLocation>? location,
    Arg<int>? durationSeconds,
    Arg<String>? message,
    Arg<String>? description,
  }) : this.keyArg = $initArg('key', key, null),
       this.locationArg = $initArg(
         'location',
         location,
         EnumArg<ToastLocation>(
           ToastLocation.bottomRight,
           values: ToastLocation.values,
         ),
       )!,
       this.durationSecondsArg = $initArg(
         'durationSeconds',
         durationSeconds,
         IntArg(_kDefaultDurationSeconds),
       )!,
       this.messageArg = $initArg(
         'message',
         message,
         StringArg('Changes saved.'),
       )!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg('Your data has been updated successfully.'),
       )!;

  ToastDemoArgs.fixed({
    Key? key,
    ToastLocation location = ToastLocation.bottomRight,
    int durationSeconds = _kDefaultDurationSeconds,
    String message = 'Changes saved.',
    String description = 'Your data has been updated successfully.',
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.locationArg = $initArg('location', Arg.fixed(location), null)!,
       this.durationSecondsArg = $initArg(
         'durationSeconds',
         Arg.fixed(durationSeconds),
         null,
       )!,
       this.messageArg = $initArg('message', Arg.fixed(message), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<ToastLocation> locationArg;

  final Arg<int> durationSecondsArg;

  final Arg<String> messageArg;

  final Arg<String> descriptionArg;

  Key? get key => keyArg?.value;

  ToastLocation get location => locationArg.value;

  int get durationSeconds => durationSecondsArg.value;

  String get message => messageArg.value;

  String get description => descriptionArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    locationArg,
    durationSecondsArg,
    messageArg,
    descriptionArg,
  ];
}
