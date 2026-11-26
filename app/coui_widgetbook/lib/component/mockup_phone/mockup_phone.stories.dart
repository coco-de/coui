import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'mockup_phone.stories.g.dart';

// MockupDevice widgetbook constants.
const _kNarrowWidth = 240.0;
const _kPreviewBackground = Color(0xFFFFE0B2);

/// Knob input for [MockupDevice] stories.
///
/// The file name and this input class keep the `MockupPhone` spelling on
/// purpose — renaming the story directory would only churn generated code.
/// The **generated** names do not: the builder derives them from the widget
/// under test, so `.g.dart` declares `MockupDevice*`. The widget is
/// `MockupDevice`; the phone is its default device.
class MockupPhoneInput {
  /// Creates a [MockupPhoneInput].
  const MockupPhoneInput({
    this.content = 'App Screen',
    this.width = CoreMockupDeviceStyle.defaultWidth,
    this.device = CoreMockupDevice.phone,
    this.orientation = CoreMockupOrientation.portrait,
    this.showCamera = CoreMockupDeviceContract.defaultShowCamera,
    this.showStatusBar = CoreMockupDeviceContract.defaultShowStatusBar,
    this.showGestureBar = CoreMockupDeviceContract.defaultShowGestureBar,
    this.backgroundColor,
  });

  /// Screen content text.
  final String content;

  /// Device body width in pixels.
  final double width;

  /// Device frame to draw.
  final CoreMockupDevice device;

  /// Which way the device is held.
  final CoreMockupOrientation orientation;

  /// Whether the complete camera assembly is shown.
  final bool showCamera;

  /// Whether the status bar is shown. A phone held on its side has none.
  final bool showStatusBar;

  /// Whether the home gesture indicator is shown.
  final bool showGestureBar;

  /// Shared screen and safe-area fill. Null follows the active theme.
  final Color? backgroundColor;
}

/// Navigation metadata for the MockupDevice component.
const kComponentMeta = ComponentMeta(name: 'MockupDevice', path: 'display');

/// Story metadata for [MockupDevice].
const kMeta = Meta(MockupDevice.new, argsType: MockupPhoneInput.new);

/// Default builder mapping [MockupPhoneInput] args to a [MockupDevice].
final MockupDeviceDefaults defaults = _Defaults(
  setup: (context, child, args) => SingleChildScrollView(child: child),
  builder: (context, args) {
    final backgroundColor = args.backgroundColor;

    return MockupDevice(
      device: args.device,
      orientation: args.orientation,
      width: args.width,
      showCamera: args.showCamera,
      showStatusBar: args.showStatusBar,
      showGestureBar: args.showGestureBar,
      mockupDeviceStyle: CoreMockupDeviceStyle(
        backgroundColor: backgroundColor == null
            ? null
            : CoreColor(backgroundColor.toARGB32()),
      ),
      child: Text(args.content),
    );
  },
);

/// Phone mockup at the design-system default width.
final $Default = _Story();

/// Phone mockup at a narrower custom width.
final $CustomWidth = _Story(
  name: 'Custom Width',
  args: _Args(width: DoubleArg(_kNarrowWidth)),
);

/// Tablet mockup — the other value of the `Device` axis.
final $Tablet = _Story(
  name: 'Tablet',
  args: _Args(
    device: EnumArg(CoreMockupDevice.tablet, values: CoreMockupDevice.values),
  ),
);

/// Phone held on its side — the camera stands on the screen's left edge and
/// there is no status bar.
final $Landscape = _Story(
  name: 'Landscape',
  args: _Args(
    orientation: EnumArg(
      CoreMockupOrientation.landscape,
      values: CoreMockupOrientation.values,
    ),
  ),
);

/// Tablet held on its side — the camera stays in the top bezel strip and the
/// status bar remains.
final $TabletLandscape = _Story(
  name: 'Tablet Landscape',
  args: _Args(
    device: EnumArg(CoreMockupDevice.tablet, values: CoreMockupDevice.values),
    orientation: EnumArg(
      CoreMockupOrientation.landscape,
      values: CoreMockupOrientation.values,
    ),
  ),
);

/// Status bar hidden — the top safe-area inset it reserved is released.
final $NoStatusBar = _Story(
  name: 'No Status Bar',
  args: _Args(showStatusBar: BoolArg(false)),
);

/// One continuous fill behind the child and both safe-area bands.
final $BackgroundColor = _Story(
  name: 'Background Color',
  args: _Args(backgroundColor: NullableColorArg(_kPreviewBackground)),
);
