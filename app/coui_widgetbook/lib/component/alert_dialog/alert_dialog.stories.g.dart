// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'alert_dialog.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AlertDialogDemo, StoryArgs<AlertDialogDemo>>;
typedef _Scenario = AlertDialogDemoScenario;
typedef _Defaults = AlertDialogDemoDefaults;
typedef _Story = AlertDialogDemoStory;
typedef _Args = AlertDialogDemoArgs;
final AlertDialogDemoComponent =
    Component<AlertDialogDemo, StoryArgs<AlertDialogDemo>>(
      name: kComponentMeta.name ?? 'AlertDialogDemo',
      path: kComponentMeta.path ?? 'component/alert_dialog',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Opens a confirmation dialog without blocking the catalog on initial render.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Destructive..$generatedName = 'Destructive',
      ],
    );
typedef AlertDialogDemoScenario =
    Scenario<AlertDialogDemo, AlertDialogDemoArgs>;
typedef AlertDialogDemoDefaults =
    Defaults<AlertDialogDemo, AlertDialogDemoArgs>;

class AlertDialogDemoStory extends Story<AlertDialogDemo, AlertDialogDemoArgs> {
  AlertDialogDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AlertDialogDemoArgs? args,
    StoryWidgetBuilder<AlertDialogDemo, AlertDialogDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AlertDialogDemoArgs(),
         builder:
             builder ??
             (context, args) => AlertDialogDemo(
               key: args.key,
               title: args.title,
               message: args.message,
               showCancelButton: args.showCancelButton,
               destructive: args.destructive,
             ),
       );
}

class AlertDialogDemoArgs extends StoryArgs<AlertDialogDemo> {
  AlertDialogDemoArgs({
    Arg<Key?>? key,
    Arg<String>? title,
    Arg<String>? message,
    Arg<bool>? showCancelButton,
    Arg<bool>? destructive,
  }) : this.keyArg = $initArg('key', key, null),
       this.titleArg = $initArg('title', title, StringArg('Confirm Action'))!,
       this.messageArg = $initArg(
         'message',
         message,
         StringArg('Are you sure you want to proceed with this action?'),
       )!,
       this.showCancelButtonArg = $initArg(
         'showCancelButton',
         showCancelButton,
         BoolArg(false),
       )!,
       this.destructiveArg = $initArg(
         'destructive',
         destructive,
         BoolArg(false),
       )!;

  AlertDialogDemoArgs.fixed({
    Key? key,
    String title = 'Confirm Action',
    String message = 'Are you sure you want to proceed with this action?',
    bool showCancelButton = false,
    bool destructive = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.messageArg = $initArg('message', Arg.fixed(message), null)!,
       this.showCancelButtonArg = $initArg(
         'showCancelButton',
         Arg.fixed(showCancelButton),
         null,
       )!,
       this.destructiveArg = $initArg(
         'destructive',
         Arg.fixed(destructive),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<String> titleArg;

  final Arg<String> messageArg;

  final Arg<bool> showCancelButtonArg;

  final Arg<bool> destructiveArg;

  Key? get key => keyArg?.value;

  String get title => titleArg.value;

  String get message => messageArg.value;

  bool get showCancelButton => showCancelButtonArg.value;

  bool get destructive => destructiveArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    titleArg,
    messageArg,
    showCancelButtonArg,
    destructiveArg,
  ];
}
