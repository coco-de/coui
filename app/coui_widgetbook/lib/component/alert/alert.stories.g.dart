// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'alert.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Alert, StoryArgs<Alert>>;
typedef _Scenario = AlertScenario;
typedef _Defaults = AlertDefaults;
typedef _Story = AlertStory;
typedef _Args = AlertInputArgs;
final AlertComponent = Component<Alert, StoryArgs<Alert>>(
  name: kComponentMeta.name ?? 'Alert',
  path: kComponentMeta.path ?? 'component/alert',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''A unified alert component for displaying important messages.

Renders a styled alert box with variant-based colors, optional icon,
title, description, dismiss button, and action widget.

Per Epic #1302 every chrome / dimensional / nested-slot override
flows through the single [alertStyle] (a [CoreAlertStyle]). The
semantic enums (`variant` / `layout`), the composition slots
(`leading` / `action`) and behaviour fields (`title` / `description` /
`onDismiss`) stay flat on the widget.

```text
design system default for alert
  → CoreAlertTheme.style                  // 프로젝트 공통
  → parent component slot override
  → widget.alertStyle                     // 인스턴스별
```

Example:
```dart
Alert(
  title: 'Heads up!',
  description: 'You can add components using the CLI.',
  variant: CoreAlertVariant.info,
  onDismiss: () => setState(() => _show = false),
)

// A one-line status strip — a badge in place of the glyph.
Alert(
  layout: CoreAlertLayout.inline,
  leading: Badge(
    tone: CoreBadgeTone.success,
    showDot: true,
    child: Text('Synced'),
  ),
  title: 'All changes saved to the cloud.',
)
```

surface:content — a banner in the page flow rather than something
mounted over it.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Info..$generatedName = 'Info',
    $Success..$generatedName = 'Success',
    $Destructive..$generatedName = 'Destructive',
    $Inline..$generatedName = 'Inline',
  ],
);
typedef AlertScenario = Scenario<Alert, AlertInputArgs>;
typedef AlertDefaults = Defaults<Alert, AlertInputArgs>;

class AlertStory extends Story<Alert, AlertInputArgs> {
  AlertStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AlertInputArgs? args,
    StoryWidgetBuilder<Alert, AlertInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AlertInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class AlertInputArgs extends StoryArgs<Alert> {
  AlertInputArgs({
    Arg<String>? title,
    Arg<String>? message,
    Arg<CoreAlertVariant>? variant,
    Arg<CoreAlertLayout>? layout,
    Arg<bool>? showLeading,
    Arg<bool>? dismissible,
  }) : this.titleArg = $initArg('title', title, StringArg('Alert Title'))!,
       this.messageArg = $initArg(
         'message',
         message,
         StringArg('This is an alert message.'),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreAlertVariant>(
           CoreAlertVariant.defaultVariant,
           values: CoreAlertVariant.values,
         ),
       )!,
       this.layoutArg = $initArg(
         'layout',
         layout,
         EnumArg<CoreAlertLayout>(
           CoreAlertLayout.defaultLayout,
           values: CoreAlertLayout.values,
         ),
       )!,
       this.showLeadingArg = $initArg(
         'showLeading',
         showLeading,
         BoolArg(false),
       )!,
       this.dismissibleArg = $initArg(
         'dismissible',
         dismissible,
         BoolArg(false),
       )!;

  AlertInputArgs.fixed({
    String title = 'Alert Title',
    String message = 'This is an alert message.',
    CoreAlertVariant variant = CoreAlertVariant.defaultVariant,
    CoreAlertLayout layout = CoreAlertLayout.defaultLayout,
    bool showLeading = false,
    bool dismissible = false,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.messageArg = $initArg('message', Arg.fixed(message), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.layoutArg = $initArg('layout', Arg.fixed(layout), null)!,
       this.showLeadingArg = $initArg(
         'showLeading',
         Arg.fixed(showLeading),
         null,
       )!,
       this.dismissibleArg = $initArg(
         'dismissible',
         Arg.fixed(dismissible),
         null,
       )!;

  final Arg<String> titleArg;

  final Arg<String> messageArg;

  final Arg<CoreAlertVariant> variantArg;

  final Arg<CoreAlertLayout> layoutArg;

  final Arg<bool> showLeadingArg;

  final Arg<bool> dismissibleArg;

  String get title => titleArg.value;

  String get message => messageArg.value;

  CoreAlertVariant get variant => variantArg.value;

  CoreAlertLayout get layout => layoutArg.value;

  bool get showLeading => showLeadingArg.value;

  bool get dismissible => dismissibleArg.value;

  @override
  List<Arg?> get list => [
    titleArg,
    messageArg,
    variantArg,
    layoutArg,
    showLeadingArg,
    dismissibleArg,
  ];
}
