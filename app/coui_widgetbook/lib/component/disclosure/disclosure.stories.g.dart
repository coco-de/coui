// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'disclosure.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Disclosure, StoryArgs<Disclosure>>;
typedef _Scenario = DisclosureScenario;
typedef _Defaults = DisclosureDefaults;
typedef _Story = DisclosureStory;
typedef _Args = DisclosureInputArgs;
final DisclosureComponent = Component<Disclosure, StoryArgs<Disclosure>>(
  name: kComponentMeta.name ?? 'Disclosure',
  path: kComponentMeta.path ?? 'component/disclosure',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''A titled section the reader opens and closes, owning no state the
caller has to hold.

The Web twin renders `<details>/<summary>`, where the browser drives
the toggle with no script at all — which is the point of the
component. Flutter has no such hand-off (there is nothing to
hydrate), so it keeps the open state internally and exposes the same
surface: [open] seeds it, [onToggle] reports it.

```dart
Disclosure(
  title: 'What is CoUI?',
  content: Text('A cross-platform design system.'),
)
```

Use `Collapsible` when the caller must own the open state or the
reveal has to animate, and `Accordion` when opening one section
should close its siblings.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Open..$generatedName = 'Open',
    $CustomTrigger..$generatedName = 'CustomTrigger',
    $Group..$generatedName = 'Group',
  ],
);
typedef DisclosureScenario = Scenario<Disclosure, DisclosureInputArgs>;
typedef DisclosureDefaults = Defaults<Disclosure, DisclosureInputArgs>;

class DisclosureStory extends Story<Disclosure, DisclosureInputArgs> {
  DisclosureStory({
    super.name,
    super.designLink,
    SetupBuilder<Disclosure, DisclosureInputArgs>? setup,
    super.modes,
    DisclosureInputArgs? args,
    StoryWidgetBuilder<Disclosure, DisclosureInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DisclosureInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class DisclosureInputArgs extends StoryArgs<Disclosure> {
  DisclosureInputArgs({
    Arg<String>? title,
    Arg<String>? body,
    Arg<bool>? open,
    Arg<bool>? customTrigger,
    Arg<bool>? grouped,
  }) : this.titleArg = $initArg('title', title, StringArg(_kTitleText))!,
       this.bodyArg = $initArg('body', body, StringArg(_kBodyText))!,
       this.openArg = $initArg('open', open, BoolArg(false))!,
       this.customTriggerArg = $initArg(
         'customTrigger',
         customTrigger,
         BoolArg(false),
       )!,
       this.groupedArg = $initArg('grouped', grouped, BoolArg(false))!;

  DisclosureInputArgs.fixed({
    String title = _kTitleText,
    String body = _kBodyText,
    bool open = false,
    bool customTrigger = false,
    bool grouped = false,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.bodyArg = $initArg('body', Arg.fixed(body), null)!,
       this.openArg = $initArg('open', Arg.fixed(open), null)!,
       this.customTriggerArg = $initArg(
         'customTrigger',
         Arg.fixed(customTrigger),
         null,
       )!,
       this.groupedArg = $initArg('grouped', Arg.fixed(grouped), null)!;

  final Arg<String> titleArg;

  final Arg<String> bodyArg;

  final Arg<bool> openArg;

  final Arg<bool> customTriggerArg;

  final Arg<bool> groupedArg;

  String get title => titleArg.value;

  String get body => bodyArg.value;

  bool get open => openArg.value;

  bool get customTrigger => customTriggerArg.value;

  bool get grouped => groupedArg.value;

  @override
  List<Arg?> get list => [
    titleArg,
    bodyArg,
    openArg,
    customTriggerArg,
    groupedArg,
  ];
}
