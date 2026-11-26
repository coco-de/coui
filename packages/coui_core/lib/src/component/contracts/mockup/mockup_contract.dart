/// Platform-independent contract for unified mockup components.
///
/// Defines the interfaces that all MockupBrowser, MockupCode and
/// MockupDevice implementations (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/mockup/mockup_browser_style.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_code_line_tone.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_code_style.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_finish.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_style.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_orientation.dart';
import 'package:coui_core/src/theme/brightness.dart';

/// Contract for a unified browser mockup component.
///
/// Displays a window frame — controls, navigation, address bar — around a
/// content card. With [addressBar] set it reads as a web page; with
/// [addressBar] `null` only the window controls remain and it reads as a
/// desktop app window.
///
/// Chrome / colour / dimensional overrides flow through the single
/// [mockupBrowserStyle] slot. Behavioural / content fields
/// ([showControls], [addressBar], [child]) stay flat. `[W]` is the
/// platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreMockupBrowserContract<W> {
  /// Default for [showControls] — the window controls render.
  static const bool defaultShowControls = true;

  /// Default for [addressBar] — a placeholder host, so a bare
  /// `MockupBrowser()` reads as a web page. Pass `null` explicitly for the
  /// app-window composition.
  static const String defaultAddressBar = 'example.com';

  /// Whether the three window-control dots render at the toolbar's
  /// leading edge.
  bool get showControls;

  /// Address bar text. `null` switches the toolbar to the app-window
  /// composition: the address pill, the back / forward chevrons and the
  /// trailing action glyph are all left out of the tree — they are
  /// browser affordances, and an app window has none of them.
  String? get addressBar;

  /// Main content inside the content card. The card has no height of its
  /// own, so `null` collapses it to zero height on both platforms — the
  /// window keeps its toolbar and the bottom `chromeWidth` of thickness,
  /// with no empty card between them.
  W? get child;

  /// Per-instance chrome / colour / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreMockupTheme.style (shared cross-variant fallback)
  ///   → CoreMockupBrowserTheme.style
  ///   → parent component slot override
  ///   → widget.mockupBrowserStyle
  /// ```
  CoreMockupBrowserStyle? get mockupBrowserStyle;
}

/// Contract for a unified code mockup component.
///
/// Per Epic #1302 chrome / colour overrides flow through the single
/// [mockupCodeStyle] slot. Behavioural / content fields (`lines`)
/// stay flat.
abstract interface class CoreMockupCodeContract {
  /// Lines of code to display.
  List<CoreCodeLine> get lines;

  /// Per-instance chrome / colour style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreMockupTheme.style (shared cross-variant fallback)
  ///   → CoreMockupCodeTheme.style
  ///   → parent component slot override
  ///   → widget.mockupCodeStyle
  /// ```
  CoreMockupCodeStyle? get mockupCodeStyle;
}

/// Platform-independent data class for a single code line.
class CoreCodeLine {
  /// Creates a [CoreCodeLine].
  const CoreCodeLine({
    required this.text,
    this.prefix,
    this.tone = CoreCodeLineTone.defaultTone,
  });

  /// Code text content.
  final String text;

  /// Optional line prefix (e.g. line number or symbol).
  final String? prefix;

  /// What the line means (command, path, success, failure …). The colour
  /// it is drawn with comes from the `CoreMockupCodeStyle` tone slots; the
  /// prefix keeps its own colour whatever the tone.
  final CoreCodeLineTone tone;
}

/// Contract for a unified device mockup component — a phone or a tablet
/// frame around the caller's screen content.
///
/// Chrome / colour / dimensional overrides flow through the single
/// [mockupDeviceStyle] slot. Behavioural / content fields (`child`,
/// `device`, `orientation`, `finish`, `width`, `showCamera`,
/// `showStatusBar`, `showGestureBar`) stay flat — `device`, `orientation` and
/// `finish` are the three semantic axes and `width` a semantic layout knob.
/// `[W]` is the platform widget type (`Widget` on Flutter, `Component` on
/// Web).
abstract interface class CoreMockupDeviceContract<W> {
  /// Default for [showCamera] on the `realistic` finish — the complete
  /// camera assembly renders. The default for any finish is
  /// [defaultShowCameraFor].
  static const bool defaultShowCamera = true;

  /// Default for [showStatusBar] on the `realistic` finish — the status bar
  /// renders. The default for any finish is [defaultShowStatusBarFor].
  static const bool defaultShowStatusBar = true;

  /// Default for [showGestureBar] on the `realistic` finish — the home
  /// gesture indicator renders. The default for any finish is
  /// [defaultShowGestureBarFor].
  static const bool defaultShowGestureBar = true;

  /// Default for [showCamera] on [finish]: a device picture has a camera, a
  /// frame does not.
  static bool defaultShowCameraFor(CoreMockupDeviceFinish finish) =>
      switch (finish) {
        .realistic => defaultShowCamera,
        .flat => false,
      };

  /// Default for [showStatusBar] on [finish]: a device picture has a status
  /// bar, a frame does not.
  static bool defaultShowStatusBarFor(CoreMockupDeviceFinish finish) =>
      switch (finish) {
        .realistic => defaultShowStatusBar,
        .flat => false,
      };

  /// Default for [showGestureBar] on [finish]: a device picture has a home
  /// bar, a frame does not.
  static bool defaultShowGestureBarFor(CoreMockupDeviceFinish finish) =>
      switch (finish) {
        .realistic => defaultShowGestureBar,
        .flat => false,
      };

  /// Content laid out inside the device's simulated safe area.
  /// Visible camera, status bar and gesture hardware each reserve their own
  /// edge inset.
  W get child;

  /// Which device kind to draw. Keys `CoreMockupDeviceStyle
  /// .defaultsByDevice` and `CoreMockupDeviceTheme.deviceStyles`.
  CoreMockupDevice get device;

  /// Which way the device is turned.
  ///
  /// Orthogonal to [device]: it decides which edge each hardware button
  /// sits on and which way the screen's long side runs. It does not key
  /// a defaults map — a turned device is the same hardware, so every
  /// chrome value is shared and only the derived geometry turns.
  CoreMockupOrientation get orientation;

  /// How the device is finished: a picture of hardware (`realistic`) or a
  /// plain preview frame (`flat`). Keys `CoreMockupDeviceStyle
  /// .defaultsByFinish` and `CoreMockupDeviceTheme.finishStyles`, and sets
  /// the default of [width], [showCamera], [showStatusBar] and
  /// [showGestureBar].
  CoreMockupDeviceFinish get finish;

  /// Width of the device body (semantic layout — stays flat). `null` is the
  /// finish's default width (`CoreMockupDeviceStyle.defaultWidthFor`).
  double? get width;

  /// Whether the camera cutout, lens and core render over the screen.
  /// Hiding them releases the edge inset the camera reserved, not the screen
  /// geometry. `null` is the finish's default ([defaultShowCameraFor]).
  bool? get showCamera;

  /// Whether the status bar — the clock and the signal, wifi and battery
  /// glyphs along the screen's top edge — renders over the screen.
  /// Independent of [showCamera] and [showGestureBar]; hiding it releases the
  /// top safe-area inset it reserved. A device that draws no status bar in the
  /// pose it is held in (a phone turned on its side) ignores it. `null` is
  /// the finish's default ([defaultShowStatusBarFor]).
  bool? get showStatusBar;

  /// Whether the home gesture bar renders over the screen.
  /// Independent of [showCamera] and [showStatusBar]; hiding it releases the
  /// bottom safe-area inset. `null` is the finish's default
  /// ([defaultShowGestureBarFor]).
  bool? get showGestureBar;

  /// The brightness the screen renders in. `null` follows the theme around
  /// the device.
  ///
  /// A device previews an app, and the app on its screen has its own
  /// brightness whatever the page around it: a light app shown in a dark
  /// editor is still light. Only the screen and what draws on it (the
  /// content, the status bar, the gesture bar) take this brightness; the
  /// body, bezel and buttons stay with the page. Both platforms render the
  /// screen as a `BrightnessScope` of it.
  CoreBrightness? get screenBrightness;

  /// Per-instance chrome / colour / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (defaultX / defaultsByDevice[device])
  ///   → defaultsByFinish[finish]
  ///   → CoreMockupTheme.style (shared cross-variant fallback)
  ///   → CoreMockupDeviceTheme.style
  ///   → CoreMockupDeviceTheme.deviceStyles[device]
  ///   → CoreMockupDeviceTheme.finishStyles[finish]
  ///   → widget.mockupDeviceStyle
  /// ```
  CoreMockupDeviceStyle? get mockupDeviceStyle;
}
