import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform device mockup with token-based rendering.
///
/// Draws a phone or tablet body — rail, rim, uniform bezel, concentric
/// screen, camera, hardware buttons, antenna bands, status bar and a home
/// gesture bar — around the caller's screen content. Uses
/// [CoreMockupDeviceContract] from `coui_core` for a consistent
/// cross-platform API. Chrome / colour / dimensional overrides flow through
/// the single [mockupDeviceStyle] slot; which hardware to draw is the
/// semantic [device] axis and which way it is held is [orientation] — a
/// turned body carries its buttons to the next edge round and a phone's
/// camera onto the screen's leading edge.
///
/// The camera, the status bar and the gesture bar are each switched by
/// their own flag, and each releases exactly the safe-area inset it
/// reserved. A flag left unstated follows the [finish]: `realistic` (the
/// default) draws all three, `flat` — a plain preview frame, one ring around
/// the screen with no rail, buttons, rim light or shadow — draws none.
///
/// Example:
/// ```dart
/// MockupDevice(
///   device: CoreMockupDevice.tablet,
///   orientation: CoreMockupOrientation.landscape,
///   child: Image.asset('screenshot.png'),
/// )
/// ```
class MockupDevice extends StatelessWidget
    implements CoreMockupDeviceContract<Widget> {
  /// Creates a [MockupDevice].
  const MockupDevice({
    required this.child,
    super.key,
    this.device = CoreMockupDevice.defaultDevice,
    this.orientation = CoreMockupOrientation.defaultOrientation,
    this.finish = CoreMockupDeviceFinish.defaultFinish,
    this.width,
    this.showCamera,
    this.showStatusBar,
    this.showGestureBar,
    this.screenBrightness,
    this.mockupDeviceStyle,
  });

  /// One flat hardware part — a filled, rounded box at an absolute
  /// rectangle inside the enclosing [Stacks]. The fill is a solid colour or,
  /// when [gradient] is set, that gradient instead.
  static Widget _part(
    Rect rect,
    BorderRadius borderRadius, {
    Color? color,
    Gradient? gradient,
  }) => Position(
    top: rect.top,
    left: rect.left,
    width: rect.width,
    height: rect.height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: borderRadius,
      ),
    ),
  );

  /// One hardware button: the solid under two gradient layers.
  ///
  /// The device is fixed hardware and does not mirror with the text, so the
  /// layers are laid out left-to-right whatever the ambient direction is — a
  /// gloss authored along a horizontal button would otherwise run backwards.
  static Widget _button(
    ResolvedMockupButton button,
    Color color,
    BorderRadius borderRadius,
  ) => Position(
    top: button.rect.top,
    left: button.rect.left,
    width: button.rect.width,
    height: button.rect.height,
    child: Directionality(
      textDirection: .ltr,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: borderRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: button.lengthGradient,
            borderRadius: borderRadius,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: button.depthGradient,
              borderRadius: borderRadius,
            ),
          ),
        ),
      ),
    ),
  );

  /// A hairline stroke along a rounded box, over the whole enclosing stack:
  /// inside the box, or outside it when [outside].
  static Widget _rim(ResolvedMockupStroke rim, {bool outside = false}) =>
      Position.fill(
        child: CustomPaint(painter: _StrokePainter(rim, outside: outside)),
      );

  /// The bezel's fill, under the inner shadow when the finish states one.
  static Widget _bezelFill(ResolvedMockupDevice resolved) {
    final fill = DecoratedBox(
      decoration: BoxDecoration(
        color: resolved.bezelColor,
        borderRadius: resolved.bezelBorderRadius,
      ),
    );
    final innerShadow = resolved.bezelInnerShadow;

    return innerShadow == null
        ? fill
        : InsetShadow(
            shadows: [innerShadow],
            radius: resolved.bezelBorderRadius,
            child: fill,
          );
  }

  /// The camera set — the cut-out, the lens ring, the core and the glint —
  /// in the space [ResolvedMockupDevice.cameraPlacement] names.
  static List<Widget> _cameraSet(ResolvedMockupDevice resolved) => [
    _part(
      resolved.cameraRect,
      resolved.cameraBorderRadius,
      color: resolved.cameraColor,
    ),
    if (resolved.lensRect != null)
      _part(
        resolved.lensRect!,
        resolved.lensBorderRadius,
        color: resolved.lensColor,
      ),
    _part(
      resolved.coreRect,
      resolved.coreBorderRadius,
      color: resolved.cutoutColor,
      gradient: resolved.coreGradient,
    ),
    _part(
      resolved.lensHighlightRect,
      resolved.lensHighlightBorderRadius,
      color: resolved.lensHighlightColor,
    ),
  ];

  /// The status bar: an opaque rectangle in the screen's own fill, then the
  /// two groups over it.
  static List<Widget> _statusBar(
    ResolvedMockupStatusBar bar,
    Color background,
  ) => [
    _part(bar.rect, .zero, color: background),
    _statusBarGroup(bar.leading),
    _statusBarGroup(bar.trailing),
  ];

  /// One status bar group: a row of its items, aligned in its box and
  /// centred on the bar's content line.
  ///
  /// The bar is a picture of an operating system caught at one moment — it
  /// carries no information of its own — so it stays out of the semantics
  /// tree, keeps the device's fixed left-to-right layout, and its text does
  /// not follow the host's text scale (the glyphs beside it could not).
  static Widget _statusBarGroup(ResolvedMockupStatusBarGroup group) => Position(
    top: group.box.top,
    left: group.box.left,
    width: group.box.width,
    height: group.box.height,
    child: ExcludeSemantics(
      child: Directionality(
        textDirection: .ltr,
        child: OverflowBox(
          alignment: group.contentAlignment,
          minWidth: 0,
          maxWidth: double.infinity,
          child: Row(
            mainAxisSize: .min,
            mainAxisAlignment: group.alignment,
            children: [
              for (final item in group.items)
                Padding(
                  padding: .only(right: item.gapAfter),
                  child: _statusBarItem(item),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  static Widget _statusBarItem(ResolvedMockupStatusBarItem item) =>
      switch (item) {
        ResolvedMockupStatusBarText(:final text, :final style) => Text(
          text,
          style: style,
          maxLines: 1,
          softWrap: false,
          textScaler: .noScaling,
        ),
        ResolvedMockupStatusBarGlyph(:final size, :final path, :final color) =>
          CustomPaint(
            size: size,
            painter: _GlyphPainter(path: path, color: color),
          ),
        final ResolvedMockupStatusBarBattery battery => SizedBox.fromSize(
          size: battery.size,
          child: Stacks(
            clipBehavior: .none,
            children: [
              _rim(battery.outline),
              _part(
                battery.capacityRect,
                battery.capacityRadius,
                color: battery.capacityColor,
              ),
              Position(
                top: battery.capRect.top,
                left: battery.capRect.left,
                width: battery.capRect.width,
                height: battery.capRect.height,
                child: CustomPaint(
                  painter: _GlyphPainter(
                    path: battery.capPath,
                    color: battery.capColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      };

  @override
  final Widget child;

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

  /// Returns a copy of this [MockupDevice] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  MockupDevice copyWith({
    Key? key,
    CoreMockupDevice? device,
    CoreMockupOrientation? orientation,
    CoreMockupDeviceFinish? finish,
    double? width,
    bool? showCamera,
    bool? showStatusBar,
    bool? showGestureBar,
    CoreBrightness? screenBrightness,
    CoreMockupDeviceStyle? mockupDeviceStyle,
    Widget? child,
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
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    ResolvedMockupDevice resolveIn(BuildContext context) => resolveMockupDevice(
      context,
      device: device,
      orientation: orientation,
      finish: finish,
      // Semantic layout knob — the widget supplies the design-system
      // `CoreMockupDeviceStyle.defaultWidthFor(finish)` fallback so the
      // resolver consumes an already resolved value (the theme cannot
      // override `width`). Single source of truth shared with the Web
      // resolver.
      widgetWidth: width ?? CoreMockupDeviceStyle.defaultWidthFor(finish),
      showCamera: showCamera,
      showStatusBar: showStatusBar,
      showGestureBar: showGestureBar,
      mockupDeviceStyle: mockupDeviceStyle,
    );
    final resolved = resolveIn(context);
    final cameraOnScreen = resolved.cameraPlacement == .screen;

    // The screen and what draws on it — the content, the status bar, the
    // camera when it sits on the screen, the gesture bar. A screen that
    // states its brightness is resolved again inside that scope: its colours
    // are the screen app's, and only the scope's theme resolves them. The
    // geometry is the same in either brightness.
    Widget screenOf(ResolvedMockupDevice screen) {
      final statusBar = screen.statusBar;

      return ClipRRect(
        borderRadius: screen.screenBorderRadius,
        child: ColoredBox(
          color: screen.backgroundColor,
          child: Stacks(
            children: [
              // Use this mockup's insets, not the host phone's
              // notch/keyboard. SafeArea consumes them, so a
              // child with its own SafeArea does not add the
              // inset twice.
              Position.fill(
                child: MediaQuery(
                  data: (MediaQuery.maybeOf(context) ?? const MediaQueryData())
                      .copyWith(
                        size: screen.screenRect.size,
                        padding: screen.safeAreaPadding,
                        viewPadding: screen.safeAreaPadding,
                        viewInsets: .zero,
                        systemGestureInsets: .zero,
                      ),
                  child: SafeArea(child: child),
                ),
              ),
              // Over the child, behind the camera: the pill
              // of a phone stands inside the bar's rectangle.
              if (screen.showStatusBar && statusBar != null)
                ..._statusBar(statusBar, screen.backgroundColor),
              if (screen.showCamera && cameraOnScreen) ..._cameraSet(screen),
              if (screen.showGestureBar)
                _part(
                  screen.gestureBarRect,
                  screen.gestureBarBorderRadius,
                  color: screen.gestureBarColor,
                ),
            ],
          ),
        ),
      );
    }

    // The glow's layer blur is a node effect, so the stroke is painted
    // under an `ImageFiltered`; the layer opacity wraps it. A finish with no
    // rim light resolves no glow stroke, and then there is no layer at all.
    final rimGlowStroke = resolved.rimGlow;
    Widget? rimGlow = rimGlowStroke == null
        ? null
        : CustomPaint(painter: _StrokePainter(rimGlowStroke));
    if (rimGlow != null && resolved.rimGlowBlurSigma > 0) {
      rimGlow = ImageFiltered(
        imageFilter: .blur(
          sigmaX: resolved.rimGlowBlurSigma,
          sigmaY: resolved.rimGlowBlurSigma,
          tileMode: .decal,
        ),
        child: rimGlow,
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      // The body width — the same box the Web root states inline.
      child: SizedBox(
        width: resolved.width,
        child: Stacks(
          // The buttons protrude past the body — never clip them.
          clipBehavior: .none,
          children: [
            // Buttons first so the body paints over the part of each slab
            // that tucks behind it.
            if (resolved.powerButton != null)
              _button(
                resolved.powerButton!,
                resolved.buttonColor,
                resolved.buttonBorderRadius,
              ),
            if (resolved.volumeUpButton != null)
              _button(
                resolved.volumeUpButton!,
                resolved.buttonColor,
                resolved.buttonBorderRadius,
              ),
            if (resolved.volumeDownButton != null)
              _button(
                resolved.volumeDownButton!,
                resolved.buttonColor,
                resolved.buttonBorderRadius,
              ),
            // Body — composed `OutlinedContainer`, not a hand-rolled
            // `Container` (`core/style-contract.md`'s child-component-
            // composition rule): fill, rim stroke, radius and shadow all
            // come from the single shared primitive. It draws no child: the
            // bezel and everything on it are siblings in body-space.
            OutlinedContainer(containerStyle: resolved.containerStyle),
            if (resolved.rimHighlight != null) _rim(resolved.rimHighlight!),
            if (rimGlow != null)
              Position.fill(
                child: Opacity(
                  opacity: resolved.rimGlowOpacity,
                  child: rimGlow,
                ),
              ),
            for (final band in resolved.antennaBands)
              Position(
                top: band.top,
                left: band.left,
                width: band.width,
                height: band.height,
                child: Opacity(
                  opacity: resolved.antennaOpacity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: resolved.antennaGradient,
                    ),
                  ),
                ),
              ),
            Position(
              top: resolved.bezelRect.top,
              left: resolved.bezelRect.left,
              width: resolved.bezelRect.width,
              height: resolved.bezelRect.height,
              child: Stacks(
                // The bezel's outline is drawn outside its box.
                clipBehavior: .none,
                children: [
                  if (resolved.bezelOutline != null)
                    _rim(resolved.bezelOutline!, outside: true),
                  Position.fill(
                    child: _bezelFill(resolved),
                  ),
                  Position(
                    top: resolved.screenRect.top,
                    left: resolved.screenRect.left,
                    width: resolved.screenRect.width,
                    height: resolved.screenRect.height,
                    child: switch (screenBrightness) {
                      null => screenOf(resolved),
                      final brightness => BrightnessScope(
                        brightness: brightness,
                        child: Builder(
                          builder: (scoped) => screenOf(resolveIn(scoped)),
                        ),
                      ),
                    },
                  ),
                  if (resolved.showCamera && !cameraOnScreen)
                    ..._cameraSet(resolved),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a hairline stroke along a rounded box: no fill, a solid colour or
/// a gradient laid over the box. The box is in the canvas's own space.
class _StrokePainter extends CustomPainter {
  const _StrokePainter(this.rim, {this.outside = false});

  final ResolvedMockupStroke rim;

  /// Whether the stroke lies outside the box rather than inside it.
  final bool outside;

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = rim.gradient;
    // A stroke is centred on its path, so the path sits half a stroke in
    // from the box edge (or out from it) for the stroke to lie wholly on
    // one side.
    final box = rim.borderRadius.toRRect(rim.rect);
    final path = outside
        ? box.inflate(rim.width / 2)
        : box.deflate(rim.width / 2);
    final paint = Paint()
      ..style = .stroke
      ..strokeWidth = rim.width;
    if (rim.color != null) {
      paint.color = rim.color!;
    }
    if (gradient != null) {
      paint.shader = gradient.createShader(rim.rect, textDirection: .ltr);
    }
    canvas.drawRRect(path, paint);
  }

  @override
  bool shouldRepaint(_StrokePainter oldDelegate) =>
      oldDelegate.rim != rim || oldDelegate.outside != outside;
}

/// Fills a pre-scaled vector path.
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.path, required this.color});

  final Path path;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.path != path || oldDelegate.color != color;
}

/// Chain sugar for merging a [CoreMockupDeviceStyle] patch into
/// [MockupDevice.mockupDeviceStyle] without hand-reconstructing every
/// field. Mirrors the Web `MockupDevice.withStyle` extension so both
/// platforms read identically.
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
