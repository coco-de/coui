import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/brightness_scope.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/display/mockup_device/mockup_device_style.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform device mockup for CoUI Web.
///
/// Draws a phone or tablet body — gradient rail, rim, antenna bands, uniform
/// bezel, concentric screen, camera, hardware buttons, and the operating
/// system's status bar and home gesture bar — around the caller's screen
/// content. Uses [CoreMockupDeviceContract] from `coui_core` for a
/// consistent cross-platform API. Chrome / colour / dimensional overrides
/// flow through the single [mockupDeviceStyle] slot; which hardware to draw
/// is the semantic [device] axis and which way it is held is [orientation] —
/// a turned body carries its buttons to the next edge round. The layout knob
/// ([width]) stays flat on the widget.
///
/// How it is finished is the semantic [finish] axis: `realistic` (the
/// default) draws all of the above, `flat` a plain preview frame — one ring
/// around the screen with no rail, buttons, rim light or shadow. The camera,
/// status bar and gesture bar flags left unstated follow the finish.
///
/// Example:
/// ```dart
/// MockupDevice(
///   device: CoreMockupDevice.tablet,
///   orientation: CoreMockupOrientation.landscape,
///   child: div([img(src: '/images/wallpaper.jpg')]),
/// )
/// ```
class MockupDevice extends UiComponent
    implements CoreMockupDeviceContract<Component> {
  /// Creates a [MockupDevice].
  const MockupDevice({
    required this.child,
    this.device = CoreMockupDevice.defaultDevice,
    this.orientation = CoreMockupOrientation.defaultOrientation,
    this.finish = CoreMockupDeviceFinish.defaultFinish,
    this.width,
    this.showCamera,
    this.showStatusBar,
    this.showGestureBar,
    this.screenBrightness,
    this.mockupDeviceStyle,
    super.tag = 'div',
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
    super.key,
  });

  @override
  final Component child;

  @override
  final CoreMockupDevice device;

  @override
  final CoreMockupOrientation orientation;

  @override
  final CoreMockupDeviceFinish finish;

  @override
  final double? width;

  @override
  final bool? showCamera;

  @override
  final bool? showStatusBar;

  @override
  final bool? showGestureBar;

  @override
  final CoreBrightness? screenBrightness;

  @override
  final CoreMockupDeviceStyle? mockupDeviceStyle;

  @override
  Component build(BuildContext context) {
    final resolved = resolveMockupDevice(
      context,
      device: device,
      orientation: orientation,
      finish: finish,
      // Semantic layout knob — the widget supplies the design-system
      // `CoreMockupDeviceStyle.defaultWidthFor(finish)` fallback so the
      // resolver consumes an already resolved value (the theme cannot
      // override `width`). Single source of truth shared with the Flutter
      // resolver.
      widgetWidth: width ?? CoreMockupDeviceStyle.defaultWidthFor(finish),
      showCamera: showCamera,
      showStatusBar: showStatusBar,
      showGestureBar: showGestureBar,
      mockupDeviceStyle: mockupDeviceStyle,
    );

    final userClasses = classes;
    final finalClasses = userClasses == null || userClasses.isEmpty
        ? resolved.root.className
        : '${resolved.root.className} $userClasses';

    return Component.element(
      tag: tag,
      id: id,
      classes: finalClasses,
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
      children: [
        // Back to front: every part is absolute in the root, so DOM order is
        // paint order. Buttons first, so the body paints over the part of
        // each slab that tucks behind it.
        if (resolved.powerButton != null) _part(resolved.powerButton!),
        if (resolved.volumeUpButton != null) _part(resolved.volumeUpButton!),
        if (resolved.volumeDownButton != null)
          _part(resolved.volumeDownButton!),
        // Body — composed `OutlinedContainer`, not a hand-rolled `<div>`
        // (`core/style-contract.md`'s child-component-composition rule). It
        // holds no child: the rim, the antenna bands and the bezel are
        // siblings painted over it.
        OutlinedContainer(
          containerStyle: resolved.frameStyle,
          classes: resolved.frame.className,
        ),
        if (resolved.rimHighlight != null) _part(resolved.rimHighlight!),
        // The glow's blur and opacity apply to what is inside the wrapper,
        // so the ring is cut first and the wrapper then softens it.
        if (resolved.rimGlow != null && resolved.rimGlowRing != null)
          div(
            [_part(resolved.rimGlowRing!)],
            classes: resolved.rimGlow!.className,
            styles: resolved.rimGlow!.inlineStyles,
          ),
        for (final band in resolved.antennaBands) _part(band),
        div(
          [
            _inScreenBrightness(
              div(
                [
                  // The full-screen wrapper reserves the simulated safe area.
                  div(
                    [child],
                    classes: resolved.content.className,
                    styles: resolved.content.inlineStyles,
                  ),
                  // The status bar paints over the child and under the camera
                  // set: the phone's pill stands inside the bar's band.
                  if (resolved.statusBar != null)
                    _statusBar(resolved.statusBar!),
                  ...resolved.screenCameraParts.map(_part),
                  if (resolved.gestureBar != null) _part(resolved.gestureBar!),
                ],
                classes: resolved.screen.className,
                styles: resolved.screen.inlineStyles,
              ),
            ),
            ...resolved.bezelCameraParts.map(_part),
          ],
          classes: resolved.bezel.className,
          styles: resolved.bezel.inlineStyles,
        ),
      ],
    );
  }

  @override
  MockupDevice copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    Component? child,
    CoreMockupDevice? device,
    CoreMockupOrientation? orientation,
    CoreMockupDeviceFinish? finish,
    double? width,
    bool? showCamera,
    bool? showStatusBar,
    bool? showGestureBar,
    CoreBrightness? screenBrightness,
    CoreMockupDeviceStyle? mockupDeviceStyle,
    String? tag,
  }) {
    return MockupDevice(
      key: key ?? this.key,
      device: device ?? this.device,
      orientation: orientation ?? this.orientation,
      finish: finish ?? this.finish,
      width: width ?? this.width,
      showCamera: showCamera ?? this.showCamera,
      showStatusBar: showStatusBar ?? this.showStatusBar,
      showGestureBar: showGestureBar ?? this.showGestureBar,
      screenBrightness: screenBrightness ?? this.screenBrightness,
      mockupDeviceStyle: mockupDeviceStyle ?? this.mockupDeviceStyle,
      tag: tag ?? this.tag,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }

  /// [screen] in [screenBrightness], or as it is when none is stated.
  ///
  /// The scope wraps the screen element itself, so the screen's own fill
  /// and everything drawn on it read the scope's colour variables. The
  /// wrapper draws no box, so the screen keeps the bezel as its
  /// containing block.
  Component _inScreenBrightness(Component screen) => switch (screenBrightness) {
    null => screen,
    final brightness => BrightnessScope(brightness: brightness, child: screen),
  };

  /// One flat hardware part — an empty `<div>` wearing its slot chrome.
  static Component _part(WebElementChrome chrome) =>
      div(const [], classes: chrome.className, styles: chrome.inlineStyles);

  /// The status bar: the bar's band, and the two groups of items laid in it.
  /// A picture of an operating system, not content — hidden from assistive
  /// technology like the rest of the hardware.
  static Component _statusBar(ResolvedMockupDeviceStatusBar bar) => div(
    [
      div(
        [for (final item in bar.leadingItems) _statusItem(item)],
        classes: bar.leading.className,
        styles: bar.leading.inlineStyles,
      ),
      div(
        [for (final item in bar.trailingItems) _statusItem(item)],
        classes: bar.trailing.className,
        styles: bar.trailing.inlineStyles,
      ),
    ],
    classes: bar.root.className,
    styles: bar.root.inlineStyles,
    attributes: const {'aria-hidden': 'true'},
  );

  /// One status bar item: its text, its drawing, or the box its parts draw.
  static Component _statusItem(ResolvedMockupDeviceStatusItem item) {
    final content = item.content;
    final text = content.text;
    if (text != null) {
      return Component.element(
        tag: 'span',
        classes: item.root.className,
        styles: item.root.inlineStyles,
        // The span carries the role's typography and colour; `Text` sets
        // neither of its own, so it inherits them.
        children: [Text(text)],
      );
    }
    if (content.path != null) {
      return Component.element(
        tag: 'svg',
        classes: item.root.className,
        styles: item.root.inlineStyles,
        attributes: {'viewBox': content.viewBox!, 'aria-hidden': 'true'},
        children: [
          Component.element(
            tag: 'path',
            attributes: {
              'd': content.path!,
              'fill': 'currentColor',
              'fill-rule': content.fillRule!,
            },
          ),
        ],
      );
    }

    return div(
      [for (final part in item.parts) _statusItem(part)],
      classes: item.root.className,
      styles: item.root.inlineStyles,
    );
  }
}

/// Chain sugar mirroring the Flutter `MockupDevice.withStyle` extension —
/// merges a [CoreMockupDeviceStyle] patch into
/// [MockupDevice.mockupDeviceStyle] via the existing
/// [MockupDevice.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMockupDeviceStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreMockupDeviceStyle.borderRadius] and `.primary` sets
/// [CoreMockupDeviceStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// MockupDevice(child: screenshot).radius4.primary
/// ```
extension MockupDeviceStyleChain on MockupDevice {
  /// Sets the background paint and preserves the other style fields.
  MockupDevice backgroundColor(CoreColor value) =>
      withStyle(CoreMockupDeviceStyle(backgroundColor: value));

  /// Returns a copy of this [MockupDevice] with [patch] merged into
  /// [mockupDeviceStyle] (patch fields win on conflict).
  MockupDevice withStyle(CoreMockupDeviceStyle patch) => copyWith(
    mockupDeviceStyle: (mockupDeviceStyle ?? const CoreMockupDeviceStyle())
        .merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  MockupDevice get radius0 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: .zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  MockupDevice get radius2 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  MockupDevice get radius4 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  MockupDevice get radius6 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  MockupDevice get radius8 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  MockupDevice get radius10 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  MockupDevice get radius12 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  MockupDevice get radius14 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  MockupDevice get radius16 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  MockupDevice get radius20 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  MockupDevice get radius24 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  MockupDevice get radius28 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  MockupDevice get radius32 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  MockupDevice get radius36 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  MockupDevice get radius40 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  MockupDevice get radius48 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  MockupDevice get radius56 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  MockupDevice get radius64 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  MockupDevice get radius9999 => withStyle(
    const CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  MockupDevice get primary => withStyle(
    const CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  MockupDevice get secondary => withStyle(
    const CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  MockupDevice get tertiary => withStyle(
    const CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  MockupDevice get surface => withStyle(
    const CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  MockupDevice get surfaceContainer => withStyle(
    const CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  MockupDevice get error => withStyle(
    const CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  MockupDevice get success => withStyle(
    const CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  MockupDevice get warning => withStyle(
    const CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  MockupDevice get info => withStyle(
    const CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  MockupDevice get outline => withStyle(
    const CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  MockupDevice get transparent => withStyle(
    const CoreMockupDeviceStyle(backgroundColor: .transparent),
  );
}
