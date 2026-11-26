// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'mockup_phone.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<MockupDevice, StoryArgs<MockupDevice>>;
typedef _Scenario = MockupDeviceScenario;
typedef _Defaults = MockupDeviceDefaults;
typedef _Story = MockupDeviceStory;
typedef _Args = MockupPhoneInputArgs;
final MockupDeviceComponent = Component<MockupDevice, StoryArgs<MockupDevice>>(
  name: kComponentMeta.name ?? 'MockupDevice',
  path: kComponentMeta.path ?? 'component/mockup_phone',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform device mockup with token-based rendering.

Draws a phone or tablet body — rail, rim, uniform bezel, concentric
screen, camera, hardware buttons, antenna bands, status bar and a home
gesture bar — around the caller's screen content. Uses
[CoreMockupDeviceContract] from `coui_core` for a consistent
cross-platform API. Chrome / colour / dimensional overrides flow through
the single [mockupDeviceStyle] slot; which hardware to draw is the
semantic [device] axis and which way it is held is [orientation] — a
turned body carries its buttons to the next edge round and a phone's
camera onto the screen's leading edge.

The camera, the status bar and the gesture bar are each switched by
their own flag, and each releases exactly the safe-area inset it
reserved.

Example:
```dart
MockupDevice(
  device: CoreMockupDevice.tablet,
  orientation: CoreMockupOrientation.landscape,
  child: Image.asset('screenshot.png'),
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $CustomWidth..$generatedName = 'CustomWidth',
    $Tablet..$generatedName = 'Tablet',
    $Landscape..$generatedName = 'Landscape',
    $TabletLandscape..$generatedName = 'TabletLandscape',
    $NoStatusBar..$generatedName = 'NoStatusBar',
    $BackgroundColor..$generatedName = 'BackgroundColor',
  ],
);
typedef MockupDeviceScenario = Scenario<MockupDevice, MockupPhoneInputArgs>;
typedef MockupDeviceDefaults = Defaults<MockupDevice, MockupPhoneInputArgs>;

class MockupDeviceStory extends Story<MockupDevice, MockupPhoneInputArgs> {
  MockupDeviceStory({
    super.name,
    super.designLink,
    SetupBuilder<MockupDevice, MockupPhoneInputArgs>? setup,
    super.modes,
    MockupPhoneInputArgs? args,
    StoryWidgetBuilder<MockupDevice, MockupPhoneInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? MockupPhoneInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class MockupPhoneInputArgs extends StoryArgs<MockupDevice> {
  MockupPhoneInputArgs({
    Arg<String>? content,
    Arg<double>? width,
    Arg<CoreMockupDevice>? device,
    Arg<CoreMockupOrientation>? orientation,
    Arg<bool>? showCamera,
    Arg<bool>? showStatusBar,
    Arg<bool>? showGestureBar,
    Arg<Color?>? backgroundColor,
  }) : this.contentArg = $initArg('content', content, StringArg('App Screen'))!,
       this.widthArg = $initArg(
         'width',
         width,
         DoubleArg(CoreMockupDeviceStyle.defaultWidth),
       )!,
       this.deviceArg = $initArg(
         'device',
         device,
         EnumArg<CoreMockupDevice>(
           CoreMockupDevice.phone,
           values: CoreMockupDevice.values,
         ),
       )!,
       this.orientationArg = $initArg(
         'orientation',
         orientation,
         EnumArg<CoreMockupOrientation>(
           CoreMockupOrientation.portrait,
           values: CoreMockupOrientation.values,
         ),
       )!,
       this.showCameraArg = $initArg(
         'showCamera',
         showCamera,
         BoolArg(CoreMockupDeviceContract.defaultShowCamera),
       )!,
       this.showStatusBarArg = $initArg(
         'showStatusBar',
         showStatusBar,
         BoolArg(CoreMockupDeviceContract.defaultShowStatusBar),
       )!,
       this.showGestureBarArg = $initArg(
         'showGestureBar',
         showGestureBar,
         BoolArg(CoreMockupDeviceContract.defaultShowGestureBar),
       )!,
       this.backgroundColorArg = $initArg(
         'backgroundColor',
         backgroundColor,
         NullableColorArg(null),
       )!;

  MockupPhoneInputArgs.fixed({
    String content = 'App Screen',
    double width = CoreMockupDeviceStyle.defaultWidth,
    CoreMockupDevice device = CoreMockupDevice.phone,
    CoreMockupOrientation orientation = CoreMockupOrientation.portrait,
    bool showCamera = CoreMockupDeviceContract.defaultShowCamera,
    bool showStatusBar = CoreMockupDeviceContract.defaultShowStatusBar,
    bool showGestureBar = CoreMockupDeviceContract.defaultShowGestureBar,
    Color? backgroundColor = null,
  }) : this.contentArg = $initArg('content', Arg.fixed(content), null)!,
       this.widthArg = $initArg('width', Arg.fixed(width), null)!,
       this.deviceArg = $initArg('device', Arg.fixed(device), null)!,
       this.orientationArg = $initArg(
         'orientation',
         Arg.fixed(orientation),
         null,
       )!,
       this.showCameraArg = $initArg(
         'showCamera',
         Arg.fixed(showCamera),
         null,
       )!,
       this.showStatusBarArg = $initArg(
         'showStatusBar',
         Arg.fixed(showStatusBar),
         null,
       )!,
       this.showGestureBarArg = $initArg(
         'showGestureBar',
         Arg.fixed(showGestureBar),
         null,
       )!,
       this.backgroundColorArg = $initArg(
         'backgroundColor',
         backgroundColor == null ? null : Arg.fixed(backgroundColor),
         null,
       );

  final Arg<String> contentArg;

  final Arg<double> widthArg;

  final Arg<CoreMockupDevice> deviceArg;

  final Arg<CoreMockupOrientation> orientationArg;

  final Arg<bool> showCameraArg;

  final Arg<bool> showStatusBarArg;

  final Arg<bool> showGestureBarArg;

  final Arg<Color?>? backgroundColorArg;

  String get content => contentArg.value;

  double get width => widthArg.value;

  CoreMockupDevice get device => deviceArg.value;

  CoreMockupOrientation get orientation => orientationArg.value;

  bool get showCamera => showCameraArg.value;

  bool get showStatusBar => showStatusBarArg.value;

  bool get showGestureBar => showGestureBarArg.value;

  Color? get backgroundColor => backgroundColorArg?.value;

  @override
  List<Arg?> get list => [
    contentArg,
    widthArg,
    deviceArg,
    orientationArg,
    showCameraArg,
    showStatusBarArg,
    showGestureBarArg,
    backgroundColorArg,
  ];
}
