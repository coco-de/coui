// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'popup.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Popup, StoryArgs<Popup>>;
typedef _Scenario = PopupScenario;
typedef _Defaults = PopupDefaults;
typedef _Story = PopupStory;
typedef _Args = PopupInputArgs;
final PopupComponent = Component<Popup, StoryArgs<Popup>>(
  name: kComponentMeta.name ?? 'Popup',
  path: kComponentMeta.path ?? 'component/popup',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''A unified styled floating-panel container.

`Popup` is a chrome-styled surface for floating content such as
menus, dropdowns and tooltips. It lays its [children] out along
[direction] inside a bordered, elevated, rounded panel and shows /
hides through the [open] flag.

`Popup` is the unified replacement for the legacy Flutter
`MenuPopup` and Web `Popup` — same parameter names, same
semantics, full visual parity.

Mirrors Web `Popup` 1:1 — same parameter names, same semantics.

```dart
Popup(
  children: const [
    Text('Profile'),
    Text('Settings'),
    Text('Sign out'),
  ],
)
```

surface:behind — a floating anchored panel — its host mounts it over page content.

surface:functional — the anchored panel itself — its host mounts it over
page content.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef PopupScenario = Scenario<Popup, PopupInputArgs>;
typedef PopupDefaults = Defaults<Popup, PopupInputArgs>;

class PopupStory extends Story<Popup, PopupInputArgs> {
  PopupStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    PopupInputArgs? args,
    StoryWidgetBuilder<Popup, PopupInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? PopupInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class PopupInputArgs extends StoryArgs<Popup> {
  PopupInputArgs({Arg<bool>? open, Arg<CoreAxis>? direction})
    : this.openArg = $initArg('open', open, BoolArg(true))!,
      this.directionArg = $initArg(
        'direction',
        direction,
        EnumArg<CoreAxis>(CoreAxis.vertical, values: CoreAxis.values),
      )!;

  PopupInputArgs.fixed({
    bool open = true,
    CoreAxis direction = CoreAxis.vertical,
  }) : this.openArg = $initArg('open', Arg.fixed(open), null)!,
       this.directionArg = $initArg('direction', Arg.fixed(direction), null)!;

  final Arg<bool> openArg;

  final Arg<CoreAxis> directionArg;

  bool get open => openArg.value;

  CoreAxis get direction => directionArg.value;

  @override
  List<Arg?> get list => [openArg, directionArg];
}
