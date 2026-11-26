// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'dialog.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DialogDemo, StoryArgs<DialogDemo>>;
typedef _Scenario = DialogDemoScenario;
typedef _Defaults = DialogDemoDefaults;
typedef _Story = DialogDemoStory;
typedef _Args = DialogDemoArgs;
final DialogDemoComponent = Component<DialogDemo, StoryArgs<DialogDemo>>(
  name: kComponentMeta.name ?? 'DialogDemo',
  path: kComponentMeta.path ?? 'component/dialog',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Interactive demo host that opens a [Dialog] from a trigger button.''',
  stories: [
    $Basic..$generatedName = 'Basic',
    $WithActions..$generatedName = 'WithActions',
    $WithIcon..$generatedName = 'WithIcon',
    $Stretch..$generatedName = 'Stretch',
  ],
);
typedef DialogDemoScenario = Scenario<DialogDemo, DialogDemoArgs>;
typedef DialogDemoDefaults = Defaults<DialogDemo, DialogDemoArgs>;

class DialogDemoStory extends Story<DialogDemo, DialogDemoArgs> {
  DialogDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    DialogDemoArgs? args,
    StoryWidgetBuilder<DialogDemo, DialogDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DialogDemoArgs(),
         builder:
             builder ??
             (context, args) => DialogDemo(
               key: args.key,
               title: args.title,
               content: args.content,
               icon: args.icon,
               showCancelButton: args.showCancelButton,
               showConfirmButton: args.showConfirmButton,
               cancelLabel: args.cancelLabel,
               buttonLabel: args.buttonLabel,
               actionsLayout: args.actionsLayout,
             ),
       );
}

class DialogDemoArgs extends StoryArgs<DialogDemo> {
  DialogDemoArgs({
    Arg<Key?>? key,
    Arg<String>? title,
    Arg<String>? content,
    Arg<DialogDemoIcon>? icon,
    Arg<bool>? showCancelButton,
    Arg<bool>? showConfirmButton,
    Arg<String>? cancelLabel,
    Arg<String>? buttonLabel,
    Arg<CoreDialogActionsLayout>? actionsLayout,
  }) : this.keyArg = $initArg('key', key, null),
       this.titleArg = $initArg('title', title, StringArg('Dialog Title'))!,
       this.contentArg = $initArg(
         'content',
         content,
         StringArg('Dialog content goes here.'),
       )!,
       this.iconArg = $initArg(
         'icon',
         icon,
         EnumArg<DialogDemoIcon>(
           DialogDemoIcon.none,
           values: DialogDemoIcon.values,
         ),
       )!,
       this.showCancelButtonArg = $initArg(
         'showCancelButton',
         showCancelButton,
         BoolArg(false),
       )!,
       this.showConfirmButtonArg = $initArg(
         'showConfirmButton',
         showConfirmButton,
         BoolArg(false),
       )!,
       this.cancelLabelArg = $initArg(
         'cancelLabel',
         cancelLabel,
         StringArg('Cancel'),
       )!,
       this.buttonLabelArg = $initArg(
         'buttonLabel',
         buttonLabel,
         StringArg('Show Dialog'),
       )!,
       this.actionsLayoutArg = $initArg(
         'actionsLayout',
         actionsLayout,
         EnumArg<CoreDialogActionsLayout>(
           CoreDialogStyle.defaultActionsLayout,
           values: CoreDialogActionsLayout.values,
         ),
       )!;

  DialogDemoArgs.fixed({
    Key? key,
    String title = 'Dialog Title',
    String content = 'Dialog content goes here.',
    DialogDemoIcon icon = DialogDemoIcon.none,
    bool showCancelButton = false,
    bool showConfirmButton = false,
    String cancelLabel = 'Cancel',
    String buttonLabel = 'Show Dialog',
    CoreDialogActionsLayout actionsLayout =
        CoreDialogStyle.defaultActionsLayout,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.contentArg = $initArg('content', Arg.fixed(content), null)!,
       this.iconArg = $initArg('icon', Arg.fixed(icon), null)!,
       this.showCancelButtonArg = $initArg(
         'showCancelButton',
         Arg.fixed(showCancelButton),
         null,
       )!,
       this.showConfirmButtonArg = $initArg(
         'showConfirmButton',
         Arg.fixed(showConfirmButton),
         null,
       )!,
       this.cancelLabelArg = $initArg(
         'cancelLabel',
         Arg.fixed(cancelLabel),
         null,
       )!,
       this.buttonLabelArg = $initArg(
         'buttonLabel',
         Arg.fixed(buttonLabel),
         null,
       )!,
       this.actionsLayoutArg = $initArg(
         'actionsLayout',
         Arg.fixed(actionsLayout),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<String> titleArg;

  final Arg<String> contentArg;

  final Arg<DialogDemoIcon> iconArg;

  final Arg<bool> showCancelButtonArg;

  final Arg<bool> showConfirmButtonArg;

  final Arg<String> cancelLabelArg;

  final Arg<String> buttonLabelArg;

  final Arg<CoreDialogActionsLayout> actionsLayoutArg;

  Key? get key => keyArg?.value;

  String get title => titleArg.value;

  String get content => contentArg.value;

  DialogDemoIcon get icon => iconArg.value;

  bool get showCancelButton => showCancelButtonArg.value;

  bool get showConfirmButton => showConfirmButtonArg.value;

  String get cancelLabel => cancelLabelArg.value;

  String get buttonLabel => buttonLabelArg.value;

  CoreDialogActionsLayout get actionsLayout => actionsLayoutArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    titleArg,
    contentArg,
    iconArg,
    showCancelButtonArg,
    showConfirmButtonArg,
    cancelLabelArg,
    buttonLabelArg,
    actionsLayoutArg,
  ];
}
