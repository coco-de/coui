import 'dart:ui' as ui;

import 'package:coui_core/coui_core.dart' as core;
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// Test constants — the Figma canvas widths the geometry was measured at.
const _kPhonePreviewWidth = 160.0;
const _kPhoneLandscapePreviewWidth = 328.0;
const _kTabletPreviewWidth = 321.0;
const _kTabletLandscapePreviewWidth = 455.0;
const _kScaling = 1.5;

/// Logical px per iOS point at the phone's canvas width (144 / 402); the
/// status bar and the gesture bar are authored in points.
const double _kPoint = 144 / 402;

const _kOverrideBezel = core.CoreColor(0xFF112233);
const _kOverrideRail = core.CoreColor(0xFFAABBCC);
const _kOverrideCutout = core.CoreColor(0xFF010203);
const _kOverrideLens = core.CoreColor(0xFF405060);
const _kOverrideButton = core.CoreColor(0xFF708090);
const _kOverrideGestureBar = core.CoreColor(0xFF123456);

/// The designer copy's hardware colours, as the canvas prints them. They are
/// literals, so every mode and every palette paints them the same.
const _kBodyLit = Color(0xFFC3C4C6); // the body gradient's top stop
const _kBodyMiddle = Color(0xFF7D7F82); // its middle, and the solid body
const _kBodyLowLit = Color(0xFFAEAFB2); // its bottom stop
const _kRim = Color(0xFF646568);
const _kButton = Color(0xFFAEAFB2);
const _kBezelOutline = Color(0xFF27282B);
const _kBlack = Color(0xFF000000); // bezel, lens, camera
const _kWhite = Color(0xFFFFFFFF); // rim highlight, lens glint
const _kAntenna = [Color(0xFFFCFCFD), Color(0xFFE4E5E7)];
const _kCore = [
  Color(0xFF000000),
  Color(0xFF0A3348),
  Color(0xFF0C3B52),
  Color(0xFF105171),
  Color(0xFF0C3B52),
  Color(0xFF000000),
];

/// Every hardware colour a distinct literal, so a part wired to the wrong
/// resolved slot paints a colour the test can tell apart.
const _kDistinctHardware = core.CoreMockupDeviceStyle(
  bezelColor: _kOverrideBezel,
  cutoutColor: _kOverrideCutout,
  lensColor: _kOverrideLens,
  buttonColor: _kOverrideButton,
  gestureBarColor: _kOverrideGestureBar,
);

/// [colorScheme] states the whole scheme; without it [dark] picks the light or
/// dark preset.
Widget _buildApp(
  Widget child, {
  double scaling = 1,
  bool dark = false,
  ResolvedColorScheme? colorScheme,
  TextDirection direction = TextDirection.ltr,
}) {
  return material.MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Theme(
        data: ThemeData(
          scaling: scaling,
          colorScheme:
              colorScheme ??
              (dark
                  ? CoreThemePresets.darkColorScheme
                  : CoreThemePresets.lightColorScheme),
        ),
        child: material.Material(child: Center(child: child)),
      ),
    ),
  );
}

/// The resolver scales every rect once; the expectation mirrors that.
Rect _scaled(Rect rect, double factor) => Rect.fromLTWH(
  rect.left * factor,
  rect.top * factor,
  rect.width * factor,
  rect.height * factor,
);

/// The canvas states every length to three decimals, so each edge is
/// compared with a tolerance instead of the rect as a whole.
void _expectRect(Rect actual, Rect expected, {double tolerance = 1e-3}) {
  expect(actual.left, closeTo(expected.left, tolerance), reason: 'left');
  expect(actual.top, closeTo(expected.top, tolerance), reason: 'top');
  expect(actual.width, closeTo(expected.width, tolerance), reason: 'width');
  expect(actual.height, closeTo(expected.height, tolerance), reason: 'height');
}

/// The `Position` the pumped tree paints at [rect] — exactly one.
///
/// [tolerance] is the canvas's own: a rect stated to three decimals is
/// matched to a thousandth.
Finder _positionAt(Rect rect, {double tolerance = 1e-6}) {
  bool near(double? a, double b) => a != null && (a - b).abs() < tolerance;
  return find.byWidgetPredicate(
    (widget) =>
        widget is Position &&
        near(widget.left, rect.left) &&
        near(widget.top, rect.top) &&
        near(widget.width, rect.width) &&
        near(widget.height, rect.height),
  );
}

/// The decoration of the part painted at [rect].
///
/// Read off the widget tree — the `Position` at that rectangle and the
/// `DecoratedBox` it holds — never recomputed from the resolver, so a part
/// the widget wires to the wrong resolved slot fails here.
BoxDecoration _partAt(
  WidgetTester tester,
  Rect rect, {
  double tolerance = 1e-6,
}) {
  final part = _positionAt(rect, tolerance: tolerance);
  expect(part, findsOneWidget, reason: 'exactly one part painted at $rect');
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: part, matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as BoxDecoration;
}

/// The fill the pumped tree paints for the hardware part at [rect].
Color _partFillAt(WidgetTester tester, Rect rect, {double tolerance = 1e-6}) =>
    _partAt(tester, rect, tolerance: tolerance).color!;

/// The bezel's painted decoration — the fill the inner shadow rides over.
BoxDecoration _bezelDecoration(WidgetTester tester) {
  final bezel = tester
      .widgetList<InsetShadow>(find.byType(InsetShadow))
      .map((shadow) => shadow.child)
      .whereType<DecoratedBox>()
      .where((box) => box.decoration is BoxDecoration);
  expect(bezel, hasLength(1));
  return bezel.single.decoration as BoxDecoration;
}

/// Resolves inside a real element tree so the scheme / scaling are live.
Future<ResolvedMockupDevice> _resolve(
  WidgetTester tester, {
  core.CoreMockupDevice device = .phone,
  core.CoreMockupOrientation orientation = .portrait,
  double width = _kPhonePreviewWidth,
  core.CoreMockupDeviceStyle? style,
  double scaling = 1,
  bool dark = false,
  ResolvedColorScheme? colorScheme,
  core.CoreMockupDeviceFinish finish = .realistic,
  bool? showCamera = true,
  bool? showStatusBar = true,
  bool? showGestureBar = true,
}) async {
  late ResolvedMockupDevice resolved;
  await tester.pumpWidget(
    _buildApp(
      Builder(
        builder: (context) {
          resolved = resolveMockupDevice(
            context,
            device: device,
            orientation: orientation,
            widgetWidth: width,
            finish: finish,
            showCamera: showCamera,
            showStatusBar: showStatusBar,
            showGestureBar: showGestureBar,
            mockupDeviceStyle: style,
          );
          return const SizedBox.shrink();
        },
      ),
      scaling: scaling,
      dark: dark,
      colorScheme: colorScheme,
    ),
  );
  return resolved;
}

/// The body's own colours, as the composed `OutlinedContainer` resolves them
/// for the device's `containerStyle` under [colorScheme].
///
/// The device hands its body fill and rim to that primitive as Core values, so
/// the Flutter colours of the body exist only after it has run.
Future<ResolvedOutlinedContainer> _resolveBody(
  WidgetTester tester, {
  required ResolvedColorScheme colorScheme,
  core.CoreMockupDevice device = .phone,
  double width = _kPhonePreviewWidth,
}) async {
  late ResolvedOutlinedContainer body;
  await tester.pumpWidget(
    _buildApp(
      Builder(
        builder: (context) {
          body = resolveOutlinedContainer(
            context,
            containerStyle: resolveMockupDevice(
              context,
              device: device,
              orientation: .portrait,
              widgetWidth: width,
            ).containerStyle,
          );
          return const SizedBox.shrink();
        },
      ),
      colorScheme: colorScheme,
    ),
  );
  return body;
}

/// One colour source resolved in the four modes a theme can be in — light
/// and dark, each with and without the platform's high-contrast preference.
Map<String, ResolvedColorScheme> _modes(core.CoreSchemeSource source) => {
  for (final brightness in core.CoreBrightness.values)
    for (final highContrast in [false, true])
      '${brightness.name}${highContrast ? ' / high contrast' : ''}': core
          .resolveThemeSchemeFrom(
            source,
            brightness: brightness,
            highContrast: highContrast,
          )
          .resolved(brightness),
};

/// A chromatic brand palette, seeded like the Core suite's brand fixture.
final core.PrimitiveColors _kBrandPalette = core.PrimitiveColors.generate(
  primaryHSL: (h: 220.0, s: 0.65, l: 0.535),
  secondaryHSL: (h: 260.0, s: 0.60, l: 0.50),
  tertiaryHSL: (h: 272.0, s: 0.75, l: 0.46),
  successHSL: (h: 140.0, s: 0.70, l: 0.30),
  infoHSL: (h: 200.0, s: 0.75, l: 0.38),
  warningHSL: (h: 45.0, s: 0.85, l: 0.50),
  errorHSL: (h: 0.0, s: 0.75, l: 0.50),
  neutralHue: 220,
);

/// The sources an app renders from — CoUI's own palette and a chromatic
/// brand's through the standard mapping — each in the four modes.
final Map<String, Map<String, ResolvedColorScheme>> _kModesBySource = {
  'coui': _modes(core.CouiColorPresets.source),
  'brand': _modes(core.CoreSemanticMappingSet.standard.bind(_kBrandPalette)),
};

/// Every colour the device draws as hardware — frame, bezel, buttons, camera,
/// lens, antenna, rim and the lens core — under [colorScheme], by name.
///
/// The screen, the status bar and the home bar are not here: they are the
/// part of the device that follows the scheme.
Future<Map<String, Object?>> _hardware(
  WidgetTester tester, {
  required ResolvedColorScheme colorScheme,
  required core.CoreMockupDevice device,
}) async {
  final body = await _resolveBody(
    tester,
    colorScheme: colorScheme,
    device: device,
  );
  final r = await _resolve(tester, device: device, colorScheme: colorScheme);
  return {
    'body gradient': body.backgroundGradient,
    'body fill': body.backgroundColor,
    'body border': body.borderColor,
    // The cast under the body: a literal black, not the palette's `shadow`
    // slot — this is the entry that fails if the device ever asks the slot.
    'body shadow': body.boxShadow,
    'button fill': r.buttonColor,
    'power button gloss': r.powerButton!.lengthGradient,
    'power button shade': r.powerButton!.depthGradient,
    'rim highlight': r.rimHighlight!.color,
    'rim glow': r.rimGlow!.gradient,
    'antenna gradient': r.antennaGradient,
    'antenna opacity': r.antennaOpacity,
    'bezel fill': r.bezelColor,
    'bezel outline': r.bezelOutline!.color,
    'bezel inner shadow': r.bezelInnerShadow,
    'camera fill': r.cameraColor,
    'lens ring fill': r.lensColor,
    'cut-out fill': r.cutoutColor,
    'lens core gradient': r.coreGradient,
    'lens highlight': r.lensHighlightColor,
  };
}

/// Logical px of clear space around the body in [_paintedPixels], so the
/// buttons that stand outside the body are inside the captured image.
const double _kPixelMargin = 8;

/// The RGBA (red in the high byte) the device paints at each of [points] —
/// logical px from the body's top-left — read back off the rendered image
/// under [colorScheme].
Future<List<int>> _paintedPixels(
  WidgetTester tester, {
  required ResolvedColorScheme colorScheme,
  required List<Offset> points,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    _buildApp(
      Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: key,
          child: Padding(
            padding: const EdgeInsets.all(_kPixelMargin),
            child: SizedBox(width: 160, child: _device(_kPhonePortrait)),
          ),
        ),
      ),
      colorScheme: colorScheme,
    ),
  );
  // The body is an implicitly animated surface: let it reach the scheme.
  await tester.pumpAndSettle();
  late List<int> pixels;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = (await image.toByteData())!;
    pixels = [
      for (final point in points)
        data.getUint32(
          (((point.dy + _kPixelMargin).floor() * image.width) +
                  (point.dx + _kPixelMargin).floor()) *
              4,
        ),
    ];
  });
  return pixels;
}

/// A canvas member: a device in a pose at the body width the canvas draws it.
typedef _Member = ({
  core.CoreMockupDevice device,
  core.CoreMockupOrientation orientation,
  double width,
});

const _Member _kPhonePortrait = (
  device: core.CoreMockupDevice.phone,
  orientation: core.CoreMockupOrientation.portrait,
  width: _kPhonePreviewWidth,
);
const _Member _kPhoneLandscape = (
  device: core.CoreMockupDevice.phone,
  orientation: core.CoreMockupOrientation.landscape,
  width: _kPhoneLandscapePreviewWidth,
);
const _Member _kTabletPortrait = (
  device: core.CoreMockupDevice.tablet,
  orientation: core.CoreMockupOrientation.portrait,
  width: _kTabletPreviewWidth,
);
const _Member _kTabletLandscape = (
  device: core.CoreMockupDevice.tablet,
  orientation: core.CoreMockupOrientation.landscape,
  width: _kTabletLandscapePreviewWidth,
);

const List<_Member> _kMembers = [
  _kPhonePortrait,
  _kPhoneLandscape,
  _kTabletPortrait,
  _kTabletLandscape,
];

/// The insets each part reserves at the canvas members, `(top, left)` for the
/// status bar / camera and `bottom` for the home indicator (screen px).
({double top, double left, double bottom, double statusBar, double camera})
_expectedInsets(_Member m) {
  if (m.device == .phone && m.orientation == .portrait) {
    return (
      top: 21.134,
      left: 0,
      bottom: 12.179,
      statusBar: 21.134,
      camera: 21,
    );
  }
  if (m.device == .phone) {
    return (top: 0, left: 21, bottom: 7.497, statusBar: 0, camera: 0);
  }
  return (top: 11.463, left: 0, bottom: 7.164, statusBar: 11.463, camera: 0);
}

Widget _device(
  _Member m, {
  Key? contentKey,
  bool showCamera = true,
  bool showStatusBar = true,
  bool showGestureBar = true,
  core.CoreMockupDeviceStyle? style,
}) => MockupDevice(
  device: m.device,
  orientation: m.orientation,
  width: m.width,
  showCamera: showCamera,
  showStatusBar: showStatusBar,
  showGestureBar: showGestureBar,
  mockupDeviceStyle: style,
  child: SizedBox.expand(key: contentKey),
);

void main() {
  group('MockupDevice widget', () {
    for (final device in core.CoreMockupDevice.values) {
      testWidgets('$device backgroundColor covers the child and safe area', (
        tester,
      ) async {
        const background = Color(0xFFFFE0B2);
        await tester.pumpWidget(
          _buildApp(
            MockupDevice(
              device: device,
              width: _kPhonePreviewWidth,
              mockupDeviceStyle: const core.CoreMockupDeviceStyle(
                backgroundColor: core.CoreColor(0xFFFFE0B2),
              ),
              child: const ColoredBox(
                key: ValueKey('child-background'),
                color: background,
              ),
            ),
          ),
        );
        final child = find.byKey(const ValueKey('child-background'));
        final screenBackground = find
            .ancestor(of: child, matching: find.byType(ColoredBox))
            .first;
        expect(tester.widget<ColoredBox>(screenBackground).color, background);
        expect(tester.widget<ColoredBox>(child).color, background);
        expect(
          tester.getRect(screenBackground),
          tester.getRect(find.byType(ClipRRect)),
        );
        expect(
          tester.getRect(child).top,
          greaterThan(tester.getRect(screenBackground).top),
        );
        expect(
          tester.getRect(child).bottom,
          lessThan(tester.getRect(screenBackground).bottom),
        );
      });
    }

    for (final member in _kMembers) {
      for (final showCamera in [true, false]) {
        for (final showStatusBar in [true, false]) {
          for (final showGestureBar in [true, false]) {
            testWidgets(
              '${member.device} ${member.orientation} camera=$showCamera '
              'statusBar=$showStatusBar gestureBar=$showGestureBar — each '
              'flag releases only its own inset',
              (tester) async {
                const key = ValueKey('screen-content');
                final mockup = _device(member, contentKey: key);
                await tester.pumpWidget(_buildApp(mockup));
                final body = tester.getRect(find.byType(OutlinedContainer));
                final screen = tester.getRect(find.byType(ClipRRect));
                final contentElement = tester.element(find.byKey(key));

                await tester.pumpWidget(
                  _buildApp(
                    _device(
                      member,
                      contentKey: key,
                      showCamera: showCamera,
                      showStatusBar: showStatusBar,
                      showGestureBar: showGestureBar,
                    ),
                  ),
                );
                final inset = _expectedInsets(member);
                // The top is the deeper of the two sources, never their sum.
                final top = [
                  if (showStatusBar) inset.statusBar,
                  if (showCamera) inset.camera,
                ].fold<double>(0, (a, b) => a > b ? a : b);
                expect(tester.getRect(find.byType(OutlinedContainer)), body);
                expect(tester.getRect(find.byType(ClipRRect)), screen);
                _expectRect(
                  tester.getRect(find.byKey(key)),
                  Rect.fromLTRB(
                    screen.left + (showCamera ? inset.left : 0),
                    screen.top + top,
                    screen.right,
                    screen.bottom - (showGestureBar ? inset.bottom : 0),
                  ),
                );
                // The child is the same element — a flag changes the
                // surroundings, never the caller's subtree.
                expect(tester.element(find.byKey(key)), same(contentElement));
                expect(tester.takeException(), isNull);
              },
            );
          }
        }
      }
    }

    testWidgets('SafeArea isolates host insets and is not consumed twice', (
      tester,
    ) async {
      late MediaQueryData childMedia;
      await tester.pumpWidget(
        _buildApp(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(1200, 900),
              padding: EdgeInsets.fromLTRB(24, 80, 24, 48),
              viewPadding: EdgeInsets.fromLTRB(24, 80, 24, 48),
              viewInsets: EdgeInsets.only(bottom: 300),
              systemGestureInsets: EdgeInsets.all(20),
              textScaler: TextScaler.linear(1.5),
            ),
            child: MockupDevice(
              width: _kPhonePreviewWidth,
              child: SafeArea(
                child: Builder(
                  builder: (context) {
                    childMedia = MediaQuery.of(context);
                    return const SizedBox.expand(key: ValueKey('safe-content'));
                  },
                ),
              ),
            ),
          ),
          scaling: _kScaling,
        ),
      );
      final screen = tester.getRect(find.byType(ClipRRect));
      // The status bar's 59 points and the home indicator's 34, at this
      // screen's scale, then at the theme's scaling.
      _expectRect(
        tester.getRect(find.byKey(const ValueKey('safe-content'))),
        Rect.fromLTRB(
          screen.left,
          screen.top + 59 * _kPoint * _kScaling,
          screen.right,
          screen.bottom - 34 * _kPoint * _kScaling,
        ),
      );
      expect(childMedia.padding, EdgeInsets.zero);
      expect(childMedia.viewPadding, EdgeInsets.zero);
      expect(childMedia.viewInsets, EdgeInsets.zero);
      expect(childMedia.systemGestureInsets, EdgeInsets.zero);
      expect(childMedia.size, screen.size);
      expect(childMedia.textScaler.scale(10), 15);
      expect(tester.takeException(), isNull);
    });

    testWidgets('safe insets follow oversized overrides and scaling', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        scaling: _kScaling,
        style: const core.CoreMockupDeviceStyle(
          cameraOffset: 12,
          cameraHeight: 20,
          lensSize: 60,
          gestureBarHeight: 8,
          gestureBarOffset: 40,
        ),
      );
      // The lens reaches 52 below the screen's top, plus the 12 the camera
      // sits down — deeper than the status bar, so it wins. The bar's own
      // footprint (40 + 8 points) reaches higher than its 34-point area.
      expect(resolved.safeAreaPadding.left, 0);
      expect(resolved.safeAreaPadding.right, 0);
      expect(resolved.safeAreaPadding.top, closeTo(96, 1e-9));
      expect(
        resolved.safeAreaPadding.bottom,
        closeTo(48 * _kPoint * _kScaling, 1e-9),
      );
    });

    test('copyWith and style chains preserve independent visibility', () {
      const mockup = MockupDevice(child: SizedBox.shrink());
      // Unstated follows the finish — see 'MockupDevice finish'.
      expect(mockup.showCamera, isNull);
      expect(mockup.showStatusBar, isNull);
      expect(mockup.showGestureBar, isNull);
      final hidden = mockup.copyWith(
        showCamera: false,
        showStatusBar: false,
        showGestureBar: false,
      );
      final styled = hidden.copyWith(width: 240).radius8.primary;
      expect(styled.showCamera, isFalse);
      expect(styled.showStatusBar, isFalse);
      expect(styled.showGestureBar, isFalse);
      final cameraOnly = styled.copyWith(showCamera: true);
      expect(cameraOnly.showCamera, isTrue);
      expect(cameraOnly.showStatusBar, isFalse);
      expect(cameraOnly.showGestureBar, isFalse);
      final statusOnly = hidden.copyWith(showStatusBar: true);
      expect(statusOnly.showCamera, isFalse);
      expect(statusOnly.showStatusBar, isTrue);
      expect(statusOnly.showGestureBar, isFalse);
      final barOnly = hidden.copyWith(showGestureBar: true);
      expect(barOnly.showCamera, isFalse);
      expect(barOnly.showStatusBar, isFalse);
      expect(barOnly.showGestureBar, isTrue);
    });

    testWidgets('renders with required child, composed from the primitives', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const MockupDevice(child: Text('screen'))),
      );

      expect(find.byType(MockupDevice), findsOneWidget);
      expect(find.text('screen'), findsOneWidget);
      expect(find.byType(OutlinedContainer), findsOneWidget);
      // The screen is the only clipped surface.
      expect(find.byType(ClipRRect), findsOneWidget);
      // No raw Flutter Stack / Positioned outside the unified primitives:
      // every Stack is a `Stacks` (outer body, bezel, screen, battery).
      expect(find.byType(Stacks), findsNWidgets(4));
    });

    testWidgets('the widget carries orientation through to the geometry', (
      tester,
    ) async {
      // The resolver's own landscape rules are covered below; what this
      // asserts is the wiring — a widget that accepts the axis and drops it
      // on the floor would pass every resolver test and still draw upright.
      await tester.pumpWidget(
        _buildApp(
          const Row(
            children: [
              MockupDevice(width: 160, child: SizedBox.shrink()),
              MockupDevice(
                orientation: .landscape,
                width: 328,
                child: SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      final sizes = find
          .byType(OutlinedContainer)
          .evaluate()
          .map((e) => e.size!)
          .toList();
      expect(sizes.length, 2);
      // Upright is taller than wide; turned is the other way round.
      expect(sizes[0].height, greaterThan(sizes[0].width));
      expect(sizes[1].width, greaterThan(sizes[1].height));
      expect(sizes[0].width, closeTo(160, 1e-9));
      expect(sizes[0].height, closeTo(328, 1e-9));
      expect(sizes[1].width, closeTo(328, 1e-9));
      expect(sizes[1].height, closeTo(160, 1e-9));
    });

    testWidgets('the body is exactly the canvas size at every member', (
      tester,
    ) async {
      for (final m in _kMembers) {
        await tester.pumpWidget(_buildApp(_device(m)));
        final body = tester.getSize(find.byType(OutlinedContainer));
        final expected = switch ((m.device, m.orientation)) {
          (.phone, .portrait) => const Size(160, 328),
          (.phone, .landscape) => const Size(328, 160),
          (.tablet, .portrait) => const Size(321, 455),
          (.tablet, .landscape) => const Size(455, 321),
        };
        expect(body.width, closeTo(expected.width, 1e-3), reason: '$m');
        expect(body.height, closeTo(expected.height, 1e-3), reason: '$m');
      }
    });

    testWidgets('a new width reaches the body and its parts in one frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const MockupDevice(width: 160, child: SizedBox.shrink())),
      );
      await tester.pumpWidget(
        _buildApp(const MockupDevice(width: 240, child: SizedBox.shrink())),
      );
      // One frame, no settling: the body must not glide behind the parts that
      // stand on it.
      final body = tester.getRect(find.byType(OutlinedContainer));
      final screen = tester.getRect(find.byType(ClipRRect));
      expect(body.width, closeTo(240, 1e-9));
      _expectRect(screen, body.deflate(8));
    });

    testWidgets('the screen sits where the canvas puts it', (tester) async {
      for (final m in _kMembers) {
        await tester.pumpWidget(_buildApp(_device(m)));
        final body = tester.getRect(find.byType(OutlinedContainer));
        final screen = tester.getRect(find.byType(ClipRRect));
        // Rail 3 + bezel 5 on a phone, rail 3 + bezel 8 on a tablet.
        final inset = m.device == .phone ? 8.0 : 11.0;
        _expectRect(screen, body.deflate(inset));
      }
    });
  });

  group('MockupDevice status bar', () {
    testWidgets('the phone draws its clock, and showStatusBar removes it', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_device(_kPhonePortrait)));
      expect(find.text('9:41'), findsOneWidget);
      // Nothing else in the phone's bar is text.
      expect(find.text('오전'), findsNothing);

      await tester.pumpWidget(
        _buildApp(_device(_kPhonePortrait, showStatusBar: false)),
      );
      expect(find.text('9:41'), findsNothing);
    });

    testWidgets('the tablet draws clock, meridiem, date and percentage', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_device(_kTabletPortrait)));
      expect(find.text('9:41'), findsOneWidget);
      expect(find.text('오전'), findsOneWidget);
      expect(find.text('4월 1일 수요일'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      await tester.pumpWidget(
        _buildApp(_device(_kTabletPortrait, showStatusBar: false)),
      );
      expect(find.text('9:41'), findsNothing);
      expect(find.text('4월 1일 수요일'), findsNothing);
      expect(find.text('100%'), findsNothing);
    });

    testWidgets('the bar is opaque in the screen fill, over the child', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          _device(
            _kPhonePortrait,
            style: const core.CoreMockupDeviceStyle(
              backgroundColor: core.CoreColor(0xFFFFE0B2),
            ),
          ),
        ),
      );
      final bar = _partAt(
        tester,
        const Rect.fromLTWH(0, 0, 144, 59 * _kPoint),
      );
      expect(bar.color, const Color(0xFFFFE0B2));
    });

    testWidgets('the bar is behind the camera set', (tester) async {
      await tester.pumpWidget(_buildApp(_device(_kPhonePortrait)));
      final bar = tester.getRect(
        _positionAt(const Rect.fromLTWH(0, 0, 144, 59 * _kPoint)),
      );
      final camera = _positionAt(const Rect.fromLTWH(49.5, 4, 45, 13));
      expect(camera, findsOneWidget);
      // Both are children of the screen's stack; the later child paints on
      // top, and the pill must be the later one.
      final stack = find.ancestor(of: camera, matching: find.byType(Stack));
      final children = tester.widget<Stack>(stack.first).children;
      final cameraIndex = children.indexOf(tester.widget(camera));
      final barIndex = children.indexOf(
        tester.widget(
          _positionAt(const Rect.fromLTWH(0, 0, 144, 59 * _kPoint)),
        ),
      );
      expect(bar.height, closeTo(21.134, 1e-3));
      expect(cameraIndex, greaterThan(barIndex));
    });

    testWidgets('the status bar is a picture: excluded from semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_buildApp(_device(_kPhonePortrait)));
      expect(find.bySemanticsLabel('9:41'), findsNothing);
      handle.dispose();
    });

    testWidgets('the bar keeps its left-to-right layout under an RTL root', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(_device(_kTabletPortrait), direction: TextDirection.rtl),
      );
      final screen = tester.getRect(find.byType(ClipRRect));
      // The clock is at the leading (left) edge of a device that does not
      // mirror with the text; the percentage is at the right.
      expect(
        tester.getCenter(find.text('9:41')).dx,
        lessThan(screen.center.dx),
      );
      expect(
        tester.getCenter(find.text('100%')).dx,
        greaterThan(screen.center.dx),
      );
    });

    testWidgets('hardware gradients keep their direction under an RTL root', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(_device(_kPhoneLandscape), direction: TextDirection.rtl),
      );
      // The gloss of a horizontal button is authored left-to-right: the
      // layers read the device's fixed direction, not the text's.
      final power = find.descendant(
        of: _positionAt(const Rect.fromLTWH(189.6, 159.5, 40, 2)),
        matching: find.byType(DecoratedBox),
      );
      expect(power, findsNWidgets(3));
      final context = tester.element(power.last);
      expect(Directionality.of(context), TextDirection.ltr);
    });
  });

  group('MockupDevice turned and tablet hardware', () {
    testWidgets('a phone on its side has no status bar and a left inset', (
      tester,
    ) async {
      const key = ValueKey('content');
      await tester.pumpWidget(
        _buildApp(_device(_kPhoneLandscape, contentKey: key)),
      );
      // Even with `showStatusBar` on, a turned phone draws none.
      expect(find.text('9:41'), findsNothing);
      // The camera stands on the screen's left edge, as a pill on end.
      final camera = _positionAt(const Rect.fromLTWH(4, 49.5, 13, 45));
      expect(camera, findsOneWidget);
      final screen = tester.getRect(find.byType(ClipRRect));
      final content = tester.getRect(find.byKey(key));
      expect(content.top, closeTo(screen.top, 1e-3));
      expect(content.left, closeTo(screen.left + 21, 1e-3));
      expect(content.bottom, closeTo(screen.bottom - 7.497, 1e-3));
      expect(content.right, closeTo(screen.right, 1e-3));
    });

    testWidgets('the turned phone releases its left inset with the camera', (
      tester,
    ) async {
      const key = ValueKey('content');
      await tester.pumpWidget(
        _buildApp(
          _device(_kPhoneLandscape, contentKey: key, showCamera: false),
        ),
      );
      final screen = tester.getRect(find.byType(ClipRRect));
      expect(tester.getRect(find.byKey(key)).left, closeTo(screen.left, 1e-3));
    });

    testWidgets('the tablet camera is in the bezel strip, not the screen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_device(_kTabletPortrait)));
      final camera = _positionAt(const Rect.fromLTWH(155.5, 2, 4, 4));
      expect(camera, findsOneWidget);
      // Not a descendant of the clipped screen.
      expect(
        find.descendant(of: find.byType(ClipRRect), matching: camera),
        findsNothing,
      );
      // It stands above the screen: the camera's centre is in the bezel's top
      // strip, over the screen's top edge.
      final body = tester.getRect(find.byType(OutlinedContainer));
      final screen = tester.getRect(find.byType(ClipRRect));
      final rect = tester.getRect(camera);
      expect(rect.bottom, lessThan(screen.top));
      expect(rect.center.dx, closeTo(body.center.dx, 1e-3));
      expect(rect.top - body.top, closeTo(3 + 2, 1e-3));
    });

    testWidgets('the tablet camera reserves no inset of its own', (
      tester,
    ) async {
      const key = ValueKey('content');
      await tester.pumpWidget(
        _buildApp(
          _device(_kTabletPortrait, contentKey: key, showStatusBar: false),
        ),
      );
      final screen = tester.getRect(find.byType(ClipRRect));
      expect(tester.getRect(find.byKey(key)).top, closeTo(screen.top, 1e-3));
    });

    testWidgets('antenna bands are the phone only, each at layer opacity', (
      tester,
    ) async {
      Finder bands() => find.byWidgetPredicate(
        (w) => w is Opacity && (w.opacity - 0.7).abs() < 1e-9,
      );

      await tester.pumpWidget(_buildApp(_device(_kPhonePortrait)));
      expect(bands(), findsNWidgets(6));
      // The first band of the portrait list: top edge, 122.441 in.
      expect(
        _positionAt(const Rect.fromLTWH(122.441, 0, 1.9, 3)),
        findsOneWidget,
      );

      await tester.pumpWidget(_buildApp(_device(_kPhoneLandscape)));
      expect(bands(), findsNWidgets(6));
      // The landscape list is the portrait one carried one edge clockwise.
      expect(
        _positionAt(const Rect.fromLTWH(325, 122.441, 3, 1.9)),
        findsOneWidget,
      );

      await tester.pumpWidget(_buildApp(_device(_kTabletPortrait)));
      expect(bands(), findsNothing);
    });

    testWidgets('the rim glow is a blurred stroke at half opacity', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_device(_kPhonePortrait)));
      final glow = tester.widget<Opacity>(
        find.byWidgetPredicate(
          (w) => w is Opacity && (w.opacity - 0.5).abs() < 1e-9,
        ),
      );
      expect(glow.opacity, 0.5);
      final filtered = tester.widget<ImageFiltered>(find.byType(ImageFiltered));
      expect(
        filtered.imageFilter,
        ui.ImageFilter.blur(sigmaX: 0.4, sigmaY: 0.4, tileMode: TileMode.decal),
      );
    });

    testWidgets('the bezel paints its outline outside its box', (tester) async {
      await tester.pumpWidget(_buildApp(_device(_kPhonePortrait)));
      final bezel = _bezelDecoration(tester);
      expect(bezel.color, _kBlack);
      // The outline is a stroke of the picture, not a border of the box.
      expect(bezel.border, isNull);
      expect(bezel.borderRadius, BorderRadius.circular(21));
      // The inner shadow rides over the bezel's fill.
      final shadow = tester.widget<InsetShadow>(
        find.ancestor(
          of: find.byWidgetPredicate(
            (w) => w is DecoratedBox && w.decoration == bezel,
          ),
          matching: find.byType(InsetShadow),
        ),
      );
      expect(shadow.shadows.single.color, const Color(0x29FFFFFF));
      expect(shadow.shadows.single.spreadRadius, closeTo(0.3, 1e-9));
      final outline = (await _resolve(tester)).bezelOutline!;
      expect(outline.color, _kBezelOutline);
      expect(outline.width, 0.5);
      expect(outline.borderRadius, BorderRadius.circular(21));
      expect(outline.rect, const Rect.fromLTWH(0, 0, 154, 322));
    });

    testWidgets('the body is a gradient, lit at the top, resting beneath', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _buildApp(
          Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(width: 160, child: _device(_kPhonePortrait)),
            ),
          ),
        ),
      );
      late int topRed;
      late int middleRed;
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = (await image.toByteData())!;
        int redAt(int x, int y) => data.getUint8((y * image.width + x) * 4);
        // The rail ring just inside the 1px rim: along the top edge (lit) and
        // down the left edge (resting), clear of the corners and the bands.
        topRed = redAt(80, 1);
        middleRed = redAt(1, 164);
      });
      // The lit top stop fades to the middle over the first tenth, then the
      // middle holds.
      expect(
        middleRed,
        closeTo((_kBodyMiddle.r * 255).round(), 3),
      );
      expect(topRed, greaterThan(middleRed + 20));
    });
  });

  group('MockupDevice painted parts', () {
    testWidgets('phone parts paint the fill they name — the pill is a hole', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const MockupDevice(
            width: _kPhonePreviewWidth,
            mockupDeviceStyle: _kDistinctHardware,
            child: SizedBox.shrink(),
          ),
        ),
      );
      // The pill holds a lens ring, so it is a cut-out: `cutoutColor`
      // reaches the whole 45 × 13 pill, not just the core.
      expect(
        _partFillAt(tester, const Rect.fromLTWH(49.5, 4, 45, 13)),
        const Color(0xFF010203),
      );
      expect(
        _partFillAt(tester, const Rect.fromLTWH(84.75, 7.25, 6.5, 6.5)),
        const Color(0xFF405060),
      );
      // A stated cut-out fill colours the core too, instead of the gradient.
      final core = _partAt(
        tester,
        const Rect.fromLTWH(86.05, 8.55, 3.9, 3.9),
      );
      expect(core.color, const Color(0xFF010203));
      expect(core.gradient, isNull);
      // The glint was not stated, so it is the default: white.
      expect(
        _partFillAt(tester, const Rect.fromLTWH(86.57, 8.81, 1.04, 1.04)),
        _kWhite,
      );
      // The button's solid is the bottom of its three layers.
      final power = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: _positionAt(const Rect.fromLTWH(159.5, 98.4, 2, 40)),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (power.decoration as BoxDecoration).color,
        const Color(0xFF708090),
      );
      expect(_bezelDecoration(tester).color, const Color(0xFF112233));
      expect(
        _partFillAt(
          tester,
          const Rect.fromLTWH(46.209, 307.343, 51.582, 1.791),
          tolerance: 1e-3,
        ),
        const Color(0xFF123456),
      );
    });

    testWidgets('tablet round cut-out is the lens — it paints lensColor', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const MockupDevice(
            device: .tablet,
            width: _kTabletPreviewWidth,
            mockupDeviceStyle: _kDistinctHardware,
            child: SizedBox.shrink(),
          ),
        ),
      );
      expect(
        _partFillAt(tester, const Rect.fromLTWH(155.5, 2, 4, 4)),
        const Color(0xFF405060),
      );
      expect(
        _partFillAt(tester, const Rect.fromLTWH(156.3, 2.8, 2.4, 2.4)),
        const Color(0xFF010203),
      );
    });

    testWidgets('default hardware fills reach the painted parts', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const MockupDevice(
            width: _kPhonePreviewWidth,
            child: SizedBox.shrink(),
          ),
        ),
      );
      expect(
        _partFillAt(tester, const Rect.fromLTWH(49.5, 4, 45, 13)),
        _kBlack,
      );
      // The designer copy's lens is pure black — the same as the cut-out.
      expect(
        _partFillAt(tester, const Rect.fromLTWH(84.75, 7.25, 6.5, 6.5)),
        _kBlack,
      );
      // The core is the radial gradient, not a solid.
      final core = _partAt(
        tester,
        const Rect.fromLTWH(86.05, 8.55, 3.9, 3.9),
      );
      expect(core.color, isNull);
      expect(core.gradient, isA<RadialGradient>());
      expect(_bezelDecoration(tester).color, _kBlack);
      // A button's three layers, bottom to top: solid, gloss, depth.
      final power = find.descendant(
        of: _positionAt(const Rect.fromLTWH(159.5, 98.4, 2, 40)),
        matching: find.byType(DecoratedBox),
      );
      final layers = tester
          .widgetList<DecoratedBox>(power)
          .map((b) => b.decoration as BoxDecoration)
          .toList();
      expect(layers, hasLength(3));
      // The base is the designer copy's own grey, not the rail's colour.
      expect(layers[0].color, _kButton);
      expect(layers[1].gradient, isA<LinearGradient>());
      expect(layers[2].gradient, isA<LinearGradient>());
      // A vertical button: the gloss runs down it; the shade runs across,
      // darkest on the side nearest the body (the right edge's body is to
      // its left).
      final gloss = layers[1].gradient! as LinearGradient;
      expect(gloss.begin, AlignmentDirectional.topCenter);
      expect(gloss.end, AlignmentDirectional.bottomCenter);
      final depth = layers[2].gradient! as LinearGradient;
      expect(depth.begin, AlignmentDirectional.centerStart);
      expect(depth.end, AlignmentDirectional.centerEnd);
      expect(depth.colors.first, const Color(0x59000000));
    });

    testWidgets('a horizontal button runs its gloss along its length', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_device(_kPhoneLandscape)));
      // Power is on the bottom edge when the phone is turned.
      final power = find.descendant(
        of: _positionAt(const Rect.fromLTWH(189.6, 159.5, 40, 2)),
        matching: find.byType(DecoratedBox),
      );
      final layers = tester
          .widgetList<DecoratedBox>(power)
          .map((b) => b.decoration as BoxDecoration)
          .toList();
      final gloss = layers[1].gradient! as LinearGradient;
      expect(gloss.begin, AlignmentDirectional.centerStart);
      expect(gloss.end, AlignmentDirectional.centerEnd);
      final depth = layers[2].gradient! as LinearGradient;
      // The body lies above a bottom-edge button.
      expect(depth.begin, AlignmentDirectional.topCenter);
      expect(depth.end, AlignmentDirectional.bottomCenter);
    });

    testWidgets('lays out without an exception at any size, pose or scale', (
      tester,
    ) async {
      for (final device in core.CoreMockupDevice.values) {
        for (final orientation in core.CoreMockupOrientation.values) {
          for (final scaling in [0.75, 1.0, 2.0]) {
            for (final width in [48.0, 160.0, 320.0]) {
              await tester.pumpWidget(
                _buildApp(
                  MockupDevice(
                    device: device,
                    orientation: orientation,
                    width: width,
                    child: const Text('App'),
                  ),
                  scaling: scaling,
                ),
              );
              expect(
                tester.takeException(),
                isNull,
                reason: '$device $orientation width $width scaling $scaling',
              );
            }
          }
        }
      }
    });

    testWidgets('respects provided key', (tester) async {
      const key = Key('mockup-device');
      await tester.pumpWidget(
        _buildApp(const MockupDevice(key: key, child: SizedBox.shrink())),
      );
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('tight wide viewport does not overflow', (tester) async {
      final overflows = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          overflows.add(details.exceptionAsString());
          return;
        }
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);

      await tester.pumpWidget(
        const material.MaterialApp(
          home: Theme(
            data: ThemeData(),
            child: SizedBox(
              width: 766,
              height: 800,
              child: MockupDevice(child: Text('App Screen')),
            ),
          ),
        ),
      );

      expect(overflows, isEmpty);
    });
  });

  group('resolveMockupDevice — phone geometry (canvas 160 / 328)', () {
    testWidgets('radii are concentric: 24 → 21 → 16', (tester) async {
      final r = await _resolve(tester);
      expect(
        r.containerStyle.borderRadius,
        equals(const core.CoreBorderRadius.all(24)),
      );
      expect(r.bezelBorderRadius, equals(BorderRadius.circular(21)));
      expect(r.screenBorderRadius, equals(BorderRadius.circular(16)));
      // The rim strokes keep the body's own corners.
      expect(r.rimHighlight!.borderRadius, equals(BorderRadius.circular(24)));
      expect(r.rimGlow!.borderRadius, equals(BorderRadius.circular(24)));
    });

    testWidgets('body 160 × 328, rail 3 + bezel 5, v1 body shadow', (
      tester,
    ) async {
      final r = await _resolve(tester);
      expect(r.width, 160);
      expect(r.height, closeTo(328, 1e-9));
      _expectRect(r.bezelRect, const Rect.fromLTWH(3, 3, 154, 322));
      // One bezel in from the bezel's corner.
      _expectRect(r.screenRect, const Rect.fromLTWH(5, 5, 144, 312));
      // The body states its own size, in logical px the primitive keeps.
      expect(r.containerStyle.width, 160);
      expect(r.containerStyle.height, closeTo(328, 1e-9));
      expect(r.containerStyle.borderWidth, core.CoreStrokeWidth.stroke1);
      expect(
        r.containerStyle.boxShadow,
        core.CoreMockupDeviceStyle.defaultBodyShadow,
      );
      expect(r.containerStyle.padding, isNull);
    });

    testWidgets('rim strokes sit where the canvas puts them', (tester) async {
      final r = await _resolve(tester);
      _expectRect(
        r.rimHighlight!.rect,
        const Rect.fromLTWH(0, 0.4, 160, 327.2),
      );
      _expectRect(r.rimGlow!.rect, const Rect.fromLTWH(0, 0.8, 160, 326.8));
      expect(r.rimHighlight!.width, 0.5);
      expect(r.rimGlow!.width, 0.6);
      expect(r.rimGlowOpacity, 0.5);
      // Figma's radius is twice σ.
      expect(r.rimGlowBlurSigma, closeTo(0.4, 1e-9));
      expect(r.rimHighlight!.gradient, isNull);
      expect(r.rimGlow!.color, isNull);
      expect(r.rimGlow!.gradient, isA<LinearGradient>());
    });

    testWidgets('camera set sits where the table says (screen-space)', (
      tester,
    ) async {
      final r = await _resolve(tester);
      expect(r.cameraPlacement, core.CoreMockupCameraPlacement.screen);
      _expectRect(r.cameraRect, const Rect.fromLTWH(49.5, 4, 45, 13));
      expect(r.cameraBorderRadius, equals(BorderRadius.circular(6.5)));
      _expectRect(r.lensRect!, const Rect.fromLTWH(84.75, 7.25, 6.5, 6.5));
      expect(r.lensBorderRadius, equals(BorderRadius.circular(3.25)));
      _expectRect(r.coreRect, const Rect.fromLTWH(86.05, 8.55, 3.9, 3.9));
      expect(r.coreBorderRadius.topLeft.x, closeTo(1.95, 1e-9));
      _expectRect(
        r.lensHighlightRect,
        const Rect.fromLTWH(86.57, 8.81, 1.04, 1.04),
      );
    });

    testWidgets('phone portrait buttons: volume left, power right', (
      tester,
    ) async {
      final r = await _resolve(tester);
      _expectRect(
        r.volumeUpButton!.rect,
        const Rect.fromLTWH(-1.5, 65.6, 2, 26),
      );
      _expectRect(
        r.volumeDownButton!.rect,
        const Rect.fromLTWH(-1.5, 99.6, 2, 26),
      );
      _expectRect(r.powerButton!.rect, const Rect.fromLTWH(159.5, 98.4, 2, 40));
      expect(r.buttonBorderRadius, equals(BorderRadius.circular(1)));
    });

    testWidgets('the home indicator is the canvas HomeIndicator', (
      tester,
    ) async {
      final r = await _resolve(tester);
      _expectRect(
        r.gestureBarRect,
        const Rect.fromLTWH(46.209, 307.343, 51.582, 1.791),
      );
      expect(r.gestureBarBorderRadius.topLeft.x, closeTo(0.716, 1e-3));
      expect(r.safeAreaPadding.bottom, closeTo(12.179, 1e-3));
      expect(r.safeAreaPadding.top, closeTo(21.134, 1e-3));
      expect(r.safeAreaPadding.left, 0);
    });

    testWidgets('landscape: camera on the left, buttons one edge on', (
      tester,
    ) async {
      final r = await _resolve(
        tester,
        orientation: .landscape,
        width: _kPhoneLandscapePreviewWidth,
      );
      _expectRect(r.cameraRect, const Rect.fromLTWH(4, 49.5, 13, 45));
      _expectRect(r.lensRect!, const Rect.fromLTWH(7.25, 52.75, 6.5, 6.5));
      _expectRect(
        r.powerButton!.rect,
        const Rect.fromLTWH(189.6, 159.5, 40, 2),
      );
      _expectRect(
        r.volumeUpButton!.rect,
        const Rect.fromLTWH(65.6, -1.5, 26, 2),
      );
      expect(r.statusBar, isNull);
      expect(r.safeAreaPadding.left, closeTo(21, 1e-3));
      expect(r.safeAreaPadding.top, 0);
      expect(r.safeAreaPadding.bottom, closeTo(7.497, 1e-3));
      _expectRect(
        r.gestureBarRect,
        const Rect.fromLTWH(118.696, 139.359, 74.609, 1.785),
      );
    });
  });

  group('resolveMockupDevice — tablet geometry (canvas 321 / 455)', () {
    testWidgets('radii 16 → 13 → 5, one rocker, no lens, no antenna', (
      tester,
    ) async {
      final r = await _resolve(
        tester,
        device: .tablet,
        width: _kTabletPreviewWidth,
      );
      expect(r.bezelBorderRadius, equals(BorderRadius.circular(13)));
      expect(r.screenBorderRadius, equals(BorderRadius.circular(5)));
      _expectRect(r.bezelRect, const Rect.fromLTWH(3, 3, 315, 449));
      _expectRect(r.screenRect, const Rect.fromLTWH(8, 8, 299, 433));
      expect(r.lensRect, isNull);
      expect(r.volumeDownButton, isNull);
      expect(r.antennaBands, isEmpty);
      _expectRect(
        r.powerButton!.rect,
        const Rect.fromLTWH(238.096, -1.5, 45.433, 2),
      );
      _expectRect(
        r.volumeUpButton!.rect,
        const Rect.fromLTWH(-1.5, 83.642, 2, 33.317),
      );
    });

    testWidgets('the camera is in the bezel space, centred on the strip', (
      tester,
    ) async {
      final r = await _resolve(
        tester,
        device: .tablet,
        width: _kTabletPreviewWidth,
      );
      expect(r.cameraPlacement, core.CoreMockupCameraPlacement.bezel);
      _expectRect(r.cameraRect, const Rect.fromLTWH(155.5, 2, 4, 4));
      _expectRect(r.coreRect, const Rect.fromLTWH(156.3, 2.8, 2.4, 2.4));
      _expectRect(
        r.lensHighlightRect,
        const Rect.fromLTWH(156.62, 2.96, 0.64, 0.64),
      );
      // No ring: the cut-out is the lens.
      expect(r.cameraColor, r.lensColor);
    });

    testWidgets('landscape reads its own lengths and offsets', (tester) async {
      final r = await _resolve(
        tester,
        device: .tablet,
        orientation: .landscape,
        width: _kTabletLandscapePreviewWidth,
      );
      _expectRect(
        r.powerButton!.rect,
        const Rect.fromLTWH(454.5, 49.748, 2, 49.522),
      );
      _expectRect(
        r.volumeUpButton!.rect,
        const Rect.fromLTWH(282.343, -1.5, 36.316, 2),
      );
      expect(r.statusBar!.rect.width, closeTo(433, 1e-3));
      expect(r.statusBar!.rect.height, closeTo(11.463, 1e-3));
      _expectRect(r.cameraRect, const Rect.fromLTWH(222.5, 2, 4, 4));
    });
  });

  group('resolveMockupDevice — status bar', () {
    testWidgets('the phone bar is two wings with a three-part battery', (
      tester,
    ) async {
      final r = await _resolve(tester);
      final bar = r.statusBar!;
      _expectRect(bar.rect, const Rect.fromLTWH(0, 0, 144, 21.134));
      expect(bar.leading.items, hasLength(1));
      expect(bar.leading.items.single, isA<ResolvedMockupStatusBarText>());
      expect(bar.trailing.items, hasLength(3));
      final cellular = bar.trailing.items[0] as ResolvedMockupStatusBarGlyph;
      final wifi = bar.trailing.items[1] as ResolvedMockupStatusBarGlyph;
      final battery = bar.trailing.items[2] as ResolvedMockupStatusBarBattery;
      expect(cellular.size.width, closeTo(6.878, 1e-3));
      expect(cellular.size.height, closeTo(4.380, 1e-3));
      expect(wifi.size.width, closeTo(6.140, 1e-3));
      expect(battery.size.width, closeTo(9.789, 1e-3));
      expect(battery.size.height, closeTo(4.657, 1e-3));
      // The nub is the one drawing that fills non-zero.
      expect(battery.capPath.fillType, PathFillType.nonZero);
      expect(cellular.path.fillType, PathFillType.evenOdd);
      // The paths are scaled to their boxes.
      expect(cellular.path.getBounds().width, closeTo(6.878, 1e-2));
      expect(cellular.path.getBounds().height, closeTo(4.380, 1e-2));
      // 35% outline, 40% nub, opaque level.
      expect(battery.outline.color!.a, closeTo(0.35, 1e-2));
      expect(battery.capColor.a, closeTo(0.4, 1e-2));
      expect(battery.capacityColor.a, 1);
      expect(battery.outline.width, closeTo(0.358, 1e-3));
    });

    testWidgets('the phone clock is the title role at the bar scale', (
      tester,
    ) async {
      final r = await _resolve(tester);
      final clock =
          r.statusBar!.leading.items.single as ResolvedMockupStatusBarText;
      expect(clock.text, '9:41');
      // titleSmall: 16 / semibold (the title roles' weight) / −0.01 em, shrunk
      // by the bar's scale.
      expect(clock.style.fontSize, closeTo(16 * _kPoint, 1e-9));
      expect(clock.style.fontWeight, FontWeight.w600);
      expect(
        clock.style.letterSpacing! / clock.style.fontSize!,
        closeTo(-0.01, 1e-9),
      );
    });

    testWidgets('the text size follows the typography axis, not scaling', (
      tester,
    ) async {
      final unscaled = await _resolve(tester);
      final scaled = await _resolve(tester, scaling: _kScaling);
      final a =
          unscaled.statusBar!.leading.items.single
              as ResolvedMockupStatusBarText;
      final b =
          scaled.statusBar!.leading.items.single as ResolvedMockupStatusBarText;
      // Multiplying by `theme.scaling` here would make this 1.5×.
      expect(b.style.fontSize, a.style.fontSize);
      // The geometry beside it does scale.
      expect(scaled.statusBar!.rect.height, closeTo(21.134 * _kScaling, 1e-3));
    });

    testWidgets('the tablet bar hugs the edges and sets its clock in label', (
      tester,
    ) async {
      final r = await _resolve(
        tester,
        device: .tablet,
        width: _kTabletPreviewWidth,
      );
      final bar = r.statusBar!;
      _expectRect(bar.rect, const Rect.fromLTWH(0, 0, 299, 11.463));
      expect(bar.leading.alignment, MainAxisAlignment.start);
      expect(bar.trailing.alignment, MainAxisAlignment.end);
      expect(bar.leading.items, hasLength(3));
      expect(bar.trailing.items, hasLength(3));
      final clock = bar.leading.items.first as ResolvedMockupStatusBarText;
      expect(clock.style.fontSize, closeTo(14 * _kPoint, 1e-9));
      expect(clock.style.fontWeight, FontWeight.w500);
      expect(clock.gapAfter, closeTo(2 * _kPoint, 1e-9));
    });
  });

  group('resolveMockupDevice — colour', () {
    testWidgets('hardware colours ignore the scheme, the screen follows it', (
      tester,
    ) async {
      final light = await _resolve(tester);
      final dark = await _resolve(tester, dark: true);

      expect(light.bezelColor, equals(dark.bezelColor));
      expect(light.buttonColor, equals(dark.buttonColor));
      expect(light.lensColor, equals(dark.lensColor));
      expect(light.cutoutColor, equals(dark.cutoutColor));
      expect(light.cameraColor, equals(dark.cameraColor));
      expect(light.coreGradient, equals(dark.coreGradient));
      expect(light.rimGlow!.gradient, equals(dark.rimGlow!.gradient));
      expect(light.antennaGradient, equals(dark.antennaGradient));
      expect(
        light.powerButton!.lengthGradient,
        dark.powerButton!.lengthGradient,
      );
      expect(
        light.containerStyle.backgroundColor,
        dark.containerStyle.backgroundColor,
      );
      expect(
        light.containerStyle.backgroundGradient,
        dark.containerStyle.backgroundGradient,
      );
      expect(light.containerStyle.borderColor, dark.containerStyle.borderColor);
      // Designer copy: black bezel, lens and camera, its own grey under the
      // button gloss, a darker grey rim.
      expect(light.bezelColor, equals(_kBlack));
      expect(light.bezelOutline!.color, equals(_kBezelOutline));
      expect(light.lensColor, equals(_kBlack));
      expect(light.cutoutColor, equals(_kBlack));
      expect(light.buttonColor, equals(_kButton));
      expect(
        light.containerStyle.backgroundGradient,
        core.CoreMockupDeviceStyle.defaultRailGradient,
      );
      expect(
        light.containerStyle.borderColor,
        equals(const core.CoreColor(0xFF646568)),
      );

      // The screen, the home bar and the status bar's text flip with it.
      expect(light.backgroundColor, isNot(equals(dark.backgroundColor)));
      expect(light.gestureBarColor, isNot(equals(dark.gestureBarColor)));
      final lightClock =
          light.statusBar!.leading.items.single as ResolvedMockupStatusBarText;
      final darkClock =
          dark.statusBar!.leading.items.single as ResolvedMockupStatusBarText;
      expect(lightClock.style.color, isNot(equals(darkClock.style.color)));
    });

    testWidgets('the body is the default gradient unless a solid is stated', (
      tester,
    ) async {
      final byDefault = await _resolve(tester);
      expect(
        byDefault.containerStyle.backgroundGradient,
        core.CoreMockupDeviceStyle.defaultRailGradient,
      );

      final solid = await _resolve(
        tester,
        style: const core.CoreMockupDeviceStyle(railColor: _kOverrideRail),
      );
      expect(solid.containerStyle.backgroundColor, _kOverrideRail);
      expect(solid.containerStyle.backgroundGradient, isNull);
    });

    testWidgets('style colour overrides flow through', (tester) async {
      final r = await _resolve(
        tester,
        style: const core.CoreMockupDeviceStyle(
          bezelColor: _kOverrideBezel,
          railColor: _kOverrideRail,
        ),
      );
      expect(r.bezelColor, equals(const Color(0xFF112233)));
      expect(r.containerStyle.backgroundColor, _kOverrideRail);
    });

    testWidgets('shared CoreMockupTheme.style seeds rail / rim / screen', (
      tester,
    ) async {
      late ResolvedMockupDevice resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(
              coreComponentTheme: CoreComponentTheme(
                mockup: CoreMockupTheme(
                  style: CoreMockupStyle(frameColor: _kOverrideRail),
                ),
                mockupDevice: CoreMockupDeviceTheme(
                  deviceStyles: {
                    core.CoreMockupDevice.tablet: core.CoreMockupDeviceStyle(
                      bezelColor: _kOverrideBezel,
                    ),
                  },
                ),
              ),
            ),
            child: Builder(
              builder: (context) {
                resolved = resolveMockupDevice(
                  context,
                  device: .tablet,
                  orientation: .portrait,
                  widgetWidth: _kTabletPreviewWidth,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved.containerStyle.backgroundColor, _kOverrideRail);
      // The shared theme's frame colour is a solid: it beats the gradient.
      expect(resolved.containerStyle.backgroundGradient, isNull);
      expect(resolved.bezelColor, equals(const Color(0xFF112233)));
    });
  });

  group("MockupDevice hardware is the designer copy's literals", () {
    for (final mappingEntry in _kModesBySource.entries) {
      for (final device in core.CoreMockupDevice.values) {
        testWidgets(
          '${mappingEntry.key} $device: the hardware is the same in all four '
          'modes',
          (tester) async {
            final modes = mappingEntry.value;
            final first = modes.entries.first;
            final reference = await _hardware(
              tester,
              colorScheme: first.value,
              device: device,
            );
            for (final mode in modes.entries.skip(1)) {
              expect(
                await _hardware(
                  tester,
                  colorScheme: mode.value,
                  device: device,
                ),
                equals(reference),
                reason: '${mode.key} against ${first.key}',
              );
            }

            // The control: the part that should move does move, so the
            // equality above is not the result of four identical schemes.
            final screens = {
              for (final mode in modes.entries)
                mode.key: (await _resolve(
                  tester,
                  device: device,
                  colorScheme: mode.value,
                )).backgroundColor,
            };
            expect(
              screens['light'],
              isNot(equals(screens['dark'])),
              reason: 'the screen follows the brightness',
            );
            expect(
              screens['light / high contrast'],
              isNot(equals(screens['dark / high contrast'])),
              reason: 'the screen follows the brightness in high contrast',
            );
          },
        );
      }
    }

    for (final device in core.CoreMockupDevice.values) {
      testWidgets(
        '$device: the hardware is the same under every palette',
        (tester) async {
          final coui = _kModesBySource['coui']!['light']!;
          final brand = _kModesBySource['brand']!['light']!;
          expect(
            await _hardware(tester, colorScheme: brand, device: device),
            equals(await _hardware(tester, colorScheme: coui, device: device)),
          );

          // The control: a fixed slot holds still across the modes but is
          // the palette's colour, so the brand moves it. Were the hardware
          // standing on one, the equality above would fail.
          expect(
            brand.primaryFixedDim.argb,
            isNot(coui.primaryFixedDim.argb),
          );
          expect(
            brand.onPrimaryFixedVariant.argb,
            isNot(coui.onPrimaryFixedVariant.argb),
          );
        },
      );
    }

    testWidgets('the cast under the body is black in every mode', (
      tester,
    ) async {
      const layers = core.CoreMockupDeviceStyle.defaultBodyShadow;
      for (final mappingEntry in _kModesBySource.entries) {
        for (final mode in mappingEntry.value.entries) {
          final body = await _resolveBody(tester, colorScheme: mode.value);
          final reason = '${mappingEntry.key} / ${mode.key}';
          expect(body.boxShadow, hasLength(layers.length), reason: reason);
          for (final (i, shadow) in body.boxShadow.indexed) {
            // Black, at the alpha the stack states for that layer — a literal,
            // not the palette's `shadow` slot, so a palette that turns the
            // slot over cannot put a pale halo under the body.
            expect(
              shadow.color.withValues(alpha: 1),
              const Color(0xFF000000),
              reason: reason,
            );
            expect(
              shadow.color.a,
              closeTo(layers[i].opacity, 1 / 255),
              reason: reason,
            );
          }
        }
      }
    });

    testWidgets('a dark theme does not strengthen the cast under the body', (
      tester,
    ) async {
      // The real fold (`applySurfaceStyle`) puts the dark brightness on the
      // geometry; a bare `ThemeData` would be light strength in either mode
      // and prove nothing. The device is pinned to v1, which drew the same
      // alpha on a dark page as on a light one (#5485).
      Future<List<BoxShadow>> castUnder(
        ThemeData base, {
        required bool device,
      }) async {
        late List<BoxShadow> cast;
        await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: applySurfaceStyle(
                base,
                surfaceStyle: .defaultStyle,
                highContrast: false,
              ),
              child: Builder(
                builder: (context) {
                  final style = device
                      ? resolveMockupDevice(
                          context,
                          device: .phone,
                          orientation: .portrait,
                          widgetWidth: _kPhonePreviewWidth,
                        ).containerStyle
                      : const core.CoreOutlinedContainerStyle(
                          boxShadow:
                              core.CoreMockupDeviceStyle.defaultBodyShadow,
                          shadowBaseColor: core.CoreColor(0xFF000000),
                        );
                  cast = resolveOutlinedContainer(
                    context,
                    containerStyle: style,
                  ).boxShadow;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        return cast;
      }

      final light = ThemeData(colorScheme: CoreThemePresets.lightColorScheme);
      final dark = ThemeData(colorScheme: CoreThemePresets.darkColorScheme);
      const layers = core.CoreMockupDeviceStyle.defaultBodyShadow;
      final lit = await castUnder(light, device: true);
      final dim = await castUnder(dark, device: true);
      expect(dim, hasLength(2));
      for (final (i, layer) in layers.indexed) {
        for (final shadow in [lit[i], dim[i]]) {
          expect(shadow.color.a, closeTo(layer.opacity, 1 / 255));
          expect(shadow.offset, Offset(layer.offsetX, layer.offsetY));
        }
      }
      expect(dim, lit);

      // The control: the same stack on a container that does not pin it is
      // strengthened by the dark fold, so the equality above is the pin's.
      final strengthened = await castUnder(dark, device: false);
      expect(
        strengthened.first.color.a,
        closeTo(layers.first.opacity * core.CoreShadow.darkStrength, 1 / 255),
      );
    });

    testWidgets("the body, its rim and the buttons are the copy's colours", (
      tester,
    ) async {
      final body = await _resolveBody(
        tester,
        colorScheme: CoreThemePresets.lightColorScheme,
      );
      final gradient = body.backgroundGradient! as LinearGradient;
      expect(gradient.colors, [
        _kBodyLit,
        _kBodyMiddle,
        _kBodyMiddle,
        _kBodyLowLit,
      ]);
      expect(gradient.stops, [0, 0.1, 0.9, 1]);
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
      expect(body.borderColor, _kRim);

      final r = await _resolve(tester);
      expect(r.buttonColor, _kButton);
      expect(r.bezelColor, _kBlack);
      expect(r.bezelOutline!.color, _kBezelOutline);
    });

    testWidgets("the solid body default is the gradient's middle", (
      tester,
    ) async {
      // The default body is the gradient above; the solid is painted only
      // when a rail colour is stated, so state the default one.
      late ResolvedOutlinedContainer solid;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              solid = resolveOutlinedContainer(
                context,
                containerStyle: resolveMockupDevice(
                  context,
                  device: .phone,
                  orientation: .portrait,
                  widgetWidth: _kPhonePreviewWidth,
                  mockupDeviceStyle: const core.CoreMockupDeviceStyle(
                    railColor: core.CoreMockupDeviceStyle.defaultRailColor,
                  ),
                ).containerStyle,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(solid.backgroundGradient, isNull);
      expect(solid.backgroundColor, _kBodyMiddle);
    });

    testWidgets("the camera, the lens core and the antenna are the copy's", (
      tester,
    ) async {
      final r = await _resolve(tester);
      expect(r.cameraColor, _kBlack);
      expect(r.lensColor, _kBlack);
      expect(r.cutoutColor, _kBlack);

      final core = r.coreGradient! as RadialGradient;
      expect(core.colors, _kCore);
      expect(core.stops, [0.2, 0.35, 0.5, 0.62, 0.8, 1]);

      // Pale, top to bottom — the band's own opacity is a separate
      // layer over it.
      final antenna = r.antennaGradient as LinearGradient;
      expect(antenna.colors, _kAntenna);
      expect(r.antennaOpacity, 0.7);
    });

    testWidgets('the rim highlight and the lens glint are white at full '
        'strength', (tester) async {
      final r = await _resolve(tester);
      expect(r.rimHighlight!.color, _kWhite);
      expect(r.lensHighlightColor, _kWhite);
      // White is opaque and no opacity is stated on top.
      expect(r.rimHighlight!.color!.a, 1.0);
      expect(r.lensHighlightColor.a, 1.0);
    });

    testWidgets('the optical layers are literals, not slots', (tester) async {
      final r = await _resolve(tester);
      // White fading to clear; the gloss and shade over the buttons; the
      // glass edge inside the bezel. None of them reads the scheme.
      final glow = r.rimGlow!.gradient! as LinearGradient;
      expect(glow.colors, [const Color(0xFFFFFFFF), const Color(0x00FFFFFF)]);
      final depth = r.powerButton!.depthGradient as LinearGradient;
      expect(depth.colors.first, const Color(0x59000000));
      expect(r.bezelInnerShadow!.color, const Color(0x29FFFFFF));
    });

    for (final mappingEntry in _kModesBySource.entries) {
      testWidgets(
        '${mappingEntry.key}: the pixels of the hardware do not move between '
        'modes, the screen does',
        (tester) async {
          // Hardware, in body space: the rail's lit edge and its resting
          // side, the bezel ring, the power button standing outside the body,
          // an antenna band, the camera pill and the ring of the lens core.
          const hardware = [
            Offset(80, 1),
            Offset(1, 164),
            Offset(5, 164),
            Offset(160, 118),
            Offset(123, 1),
            Offset(65, 18),
            Offset(97, 18),
          ];
          const screen = Offset(80, 164);
          // The cast under the body, a logical px below its bottom edge.
          const cast = Offset(80, 329);
          final read = {
            for (final mode in mappingEntry.value.entries)
              mode.key: await _paintedPixels(
                tester,
                colorScheme: mode.value,
                points: [...hardware, screen, cast],
              ),
          };

          final reference = read.values.first.sublist(0, hardware.length);
          for (final entry in read.entries) {
            expect(
              entry.value.sublist(0, hardware.length),
              equals(reference),
              reason: '${entry.key} hardware pixels',
            );
          }
          // Not vacuous: the pixels are opaque and are not one colour.
          expect(
            reference.every((p) => p & 0xFF == 0xFF),
            isTrue,
            reason: 'RGBA $reference',
          );
          expect(reference.toSet().length, greaterThan(3));

          final screenAt = hardware.length;
          expect(
            read['light']![screenAt],
            isNot(equals(read['dark']![screenAt])),
            reason: 'the screen follows the brightness',
          );

          // The cast is black at a fraction of alpha in every mode — a
          // literal, not the palette's `shadow` slot, so the device's colour
          // never moves with a palette that turns the slot over.
          final castAt = hardware.length + 1;
          final lit = read['light']![castAt];
          expect(lit & 0xFFFFFF00, 0, reason: 'RGB of the cast: $lit');
          expect(lit & 0xFF, inExclusiveRange(0, 0xFF));
          for (final entry in read.entries) {
            expect(entry.value[castAt], lit, reason: '${entry.key} cast');
          }
        },
      );
    }
  });

  group('resolveMockupDevice — scaling', () {
    testWidgets('every dimensional value is scaled once', (tester) async {
      final r = await _resolve(tester, scaling: _kScaling);
      expect(r.width, 160 * _kScaling);
      expect(r.height, closeTo(328 * _kScaling, 1e-9));
      expect(r.containerStyle.width, 160 * _kScaling);
      expect(r.screenRect.size, const Size(144, 312) * _kScaling);
      expect(
        r.bezelBorderRadius,
        equals(BorderRadius.circular(21 * _kScaling)),
      );
      expect(
        r.cameraRect,
        equals(_scaled(const Rect.fromLTWH(49.5, 4, 45, 13), _kScaling)),
      );
      _expectRect(
        r.powerButton!.rect,
        _scaled(const Rect.fromLTWH(159.5, 98.4, 2, 40), _kScaling),
        tolerance: 1e-9,
      );
      _expectRect(
        r.rimGlow!.rect,
        _scaled(const Rect.fromLTWH(0, 0.8, 160, 326.8), _kScaling),
        tolerance: 1e-9,
      );
      expect(r.rimGlow!.width, closeTo(0.6 * _kScaling, 1e-9));
      expect(r.rimGlowBlurSigma, closeTo(0.4 * _kScaling, 1e-9));
      expect(r.bezelOutline!.width, closeTo(0.5 * _kScaling, 1e-9));
      expect(
        r.safeAreaPadding.top,
        closeTo(59 * _kPoint * _kScaling, 1e-9),
      );
    });

    testWidgets('a stroke floor does not reach the strokes of the picture', (
      tester,
    ) async {
      late ResolvedMockupDevice r;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: Builder(
            builder: (context) {
              r = resolveMockupDevice(
                context,
                device: .phone,
                orientation: .portrait,
                widgetWidth: _kPhonePreviewWidth,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(r.bezelOutline!.width, 0.5);
      expect(r.rimHighlight!.width, 0.5);
      expect(r.rimGlow!.width, closeTo(0.6, 1e-9));
    });
  });

  group('MockupDevice finish', () {
    const flatWidth = 256.0;
    const ringToken = core.CoreColor.token(
      core.CoreColors.surfaceContainerHighest,
    );
    Color ring(ResolvedColorScheme scheme) =>
        scheme.resolve(ringToken).toValue();
    final light = CoreThemePresets.lightColorScheme;
    final dark = CoreThemePresets.darkColorScheme;

    testWidgets('realistic is the default and keeps every layer', (
      tester,
    ) async {
      const mockup = MockupDevice(child: SizedBox.shrink());
      expect(mockup.finish, core.CoreMockupDeviceFinish.realistic);
      final r = await _resolve(
        tester,
        showCamera: null,
        showStatusBar: null,
        showGestureBar: null,
      );
      expect(r.showCamera, isTrue);
      expect(r.showStatusBar, isTrue);
      expect(r.showGestureBar, isTrue);
      expect(r.powerButton, isNotNull);
      expect(r.volumeUpButton, isNotNull);
      expect(r.volumeDownButton, isNotNull);
      expect(r.rimHighlight, isNotNull);
      expect(r.rimGlow, isNotNull);
      expect(r.bezelOutline, isNotNull);
      expect(r.bezelInnerShadow, isNotNull);
      expect(r.antennaBands, hasLength(6));
      expect(
        r.containerStyle.boxShadow,
        core.CoreMockupDeviceStyle.defaultBodyShadow,
      );
      expect(r.bezelColor, _kBlack);
    });

    for (final device in core.CoreMockupDevice.values) {
      for (final orientation in core.CoreMockupOrientation.values) {
        testWidgets('flat $device $orientation resolves no hardware layer', (
          tester,
        ) async {
          final r = await _resolve(
            tester,
            device: device,
            orientation: orientation,
            width: flatWidth,
            finish: .flat,
            showCamera: null,
            showStatusBar: null,
            showGestureBar: null,
          );
          expect(r.powerButton, isNull);
          expect(r.volumeUpButton, isNull);
          expect(r.volumeDownButton, isNull);
          expect(r.antennaBands, isEmpty);
          expect(r.rimHighlight, isNull);
          expect(r.rimGlow, isNull);
          expect(r.bezelOutline, isNull);
          expect(r.bezelInnerShadow, isNull);
          expect(r.containerStyle.boxShadow, isEmpty);
          expect(r.containerStyle.borderWidth, 0);
          expect(r.showCamera, isFalse);
          expect(r.showStatusBar, isFalse);
          expect(r.showGestureBar, isFalse);
          expect(r.safeAreaPadding, EdgeInsets.zero);
          // Rail 0 + a ring of 8: the screen sits 8 in, radius 32 - 8 = 24.
          expect(r.bezelRect, Rect.fromLTWH(0, 0, r.width, r.height));
          expect(r.screenRect.left, 8);
          expect(r.screenRect.top, 8);
          expect(r.screenBorderRadius, BorderRadius.circular(24));
          expect(r.bezelBorderRadius, BorderRadius.circular(32));
          expect(r.screenRect.width, 240);
          expect(
            r.screenRect.height,
            orientation == core.CoreMockupOrientation.landscape ? 120 : 480,
          );
        });
      }
    }

    for (final isDark in [false, true]) {
      testWidgets(
        'flat ring follows the theme (${isDark ? 'dark' : 'light'})',
        (tester) async {
          final scheme = isDark ? dark : light;
          final r = await _resolve(
            tester,
            width: flatWidth,
            finish: .flat,
            dark: isDark,
          );
          expect(r.bezelColor, ring(scheme));
          // The body underneath is the same colour, so no fill can show at
          // the anti-aliased corners.
          final body = await _resolveBody(
            tester,
            colorScheme: scheme,
            width: flatWidth,
          );
          expect(body, isNotNull);

          await tester.pumpWidget(
            _buildApp(
              const MockupDevice(
                finish: .flat,
                child: SizedBox.expand(),
              ),
              dark: isDark,
            ),
          );
          final bezel = tester
              .widgetList<DecoratedBox>(find.byType(DecoratedBox))
              .map((box) => box.decoration)
              .whereType<BoxDecoration>()
              .where(
                (decoration) =>
                    decoration.color == ring(scheme) &&
                    decoration.borderRadius == BorderRadius.circular(32),
              )
              .toList();
          // The bezel and the body under it, in the same colour.
          expect(bezel, hasLength(2));
          final bodyLine = bezel.singleWhere((d) => d.border != null).border!;
          expect(bodyLine.top.color.a, 0, reason: 'no hairline on the body');
        },
      );
    }

    testWidgets('the ring colour differs between light and dark', (
      tester,
    ) async {
      expect(ring(light), isNot(ring(dark)));
      expect(ring(light), isNot(_kBlack));
    });

    testWidgets('flat paints no button, rim, band, shadow or glow layer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const MockupDevice(finish: .flat, child: SizedBox.expand()),
        ),
      );
      final r = await _resolve(tester, width: flatWidth, finish: .flat);
      await tester.pumpWidget(
        _buildApp(
          const MockupDevice(finish: .flat, child: SizedBox.expand()),
        ),
      );
      // The one inset shadow left is the composed body's own — the bezel's
      // is the second one a realistic device has.
      expect(find.byType(InsetShadow), findsOneWidget);
      expect(find.byType(ImageFiltered), findsNothing);
      // The glow and the antenna bands are the only layers wrapped in an
      // `Opacity`.
      expect(find.byType(Opacity), findsNothing);
      // The two `Directionality` widgets are the app's: a button pins its
      // own left-to-right, and the phone's three are absent.
      expect(find.byType(Directionality), findsNWidgets(2));
      expect(r.width, flatWidth);
      expect(
        tester.getSize(find.byType(OutlinedContainer)),
        const Size(flatWidth, 496),
      );
    });

    testWidgets('realistic still paints its buttons, rim and glow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const MockupDevice(width: 320, child: SizedBox.expand()),
        ),
      );
      expect(find.byType(InsetShadow), findsNWidgets(2));
      expect(find.byType(ImageFiltered), findsOneWidget);
      // Glow + six antenna bands.
      expect(find.byType(Opacity), findsNWidgets(7));
      // The app's two, the phone's three buttons and the status bar's two
      // groups.
      expect(find.byType(Directionality), findsNWidgets(7));
    });

    testWidgets('flat defaults to the 256 body: a 240 x 480 screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const MockupDevice(finish: .flat, child: SizedBox.expand())),
      );
      expect(tester.getSize(find.byType(ClipRRect)), const Size(240, 480));
      expect(
        tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
        BorderRadius.circular(24),
      );
    });

    testWidgets('a stated width wins over the finish default', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const MockupDevice(
            finish: .flat,
            width: 136,
            child: SizedBox.expand(),
          ),
        ),
      );
      expect(tester.getSize(find.byType(ClipRRect)).width, 120);
    });

    for (final device in core.CoreMockupDevice.values) {
      testWidgets('flat $device: camera, status bar and home bar off', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            MockupDevice(
              device: device,
              finish: .flat,
              child: const SizedBox.expand(),
            ),
          ),
        );
        expect(find.text('9:41'), findsNothing);
        final r = await _resolve(
          tester,
          device: device,
          width: flatWidth,
          finish: .flat,
          showCamera: null,
          showStatusBar: null,
          showGestureBar: null,
        );
        expect(_positionAt(r.cameraRect), findsNothing);
        expect(_positionAt(r.gestureBarRect), findsNothing);
      });

      testWidgets('flat $device: an explicit true turns each one on', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            MockupDevice(
              device: device,
              finish: .flat,
              showCamera: true,
              showStatusBar: true,
              showGestureBar: true,
              child: const SizedBox.expand(),
            ),
          ),
        );
        expect(find.text('9:41'), findsOneWidget);
        final r = await _resolve(
          tester,
          device: device,
          width: flatWidth,
          finish: .flat,
        );
        expect(r.showCamera, isTrue);
        expect(r.showStatusBar, isTrue);
        expect(r.showGestureBar, isTrue);
        expect(r.safeAreaPadding, isNot(EdgeInsets.zero));
      });
    }

    testWidgets('one explicit flag leaves the other two at the finish', (
      tester,
    ) async {
      final r = await _resolve(
        tester,
        width: flatWidth,
        finish: .flat,
        showCamera: null,
        showGestureBar: null,
      );
      // The status bar flag is left at the helper's explicit `true`.
      expect(r.showStatusBar, isTrue);
      expect(r.showCamera, isFalse);
      expect(r.showGestureBar, isFalse);
    });

    testWidgets('finish is kept by copyWith and the style chain', (
      tester,
    ) async {
      const mockup = MockupDevice(finish: .flat, child: SizedBox.shrink());
      expect(
        mockup.copyWith(width: 100).finish,
        core.CoreMockupDeviceFinish.flat,
      );
      expect(mockup.radius8.finish, core.CoreMockupDeviceFinish.flat);
      expect(
        mockup.copyWith(finish: .realistic).finish,
        core.CoreMockupDeviceFinish.realistic,
      );
    });

    testWidgets('an instance style still wins over the flat row', (
      tester,
    ) async {
      final r = await _resolve(
        tester,
        width: flatWidth,
        finish: .flat,
        style: const core.CoreMockupDeviceStyle(
          bezelColor: _kOverrideBezel,
          bezelWidth: 4,
          containerStyle: core.CoreOutlinedContainerStyle(
            boxShadow: core.CoreShadow.md,
          ),
        ),
      );
      expect(r.bezelColor, const Color(0xFF112233));
      expect(r.screenRect.left, 4);
      expect(r.containerStyle.boxShadow, core.CoreShadow.md);
    });

    testWidgets('the theme finishStyles restate the flat ring', (
      tester,
    ) async {
      late ResolvedMockupDevice r;
      late ResolvedMockupDevice realistic;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: ThemeData(
              colorScheme: CoreThemePresets.lightColorScheme,
              coreComponentTheme: const CoreComponentTheme(
                mockupDevice: core.CoreMockupDeviceTheme(
                  finishStyles: {
                    core.CoreMockupDeviceFinish.flat:
                        core.CoreMockupDeviceStyle(
                          bezelColor: _kOverrideBezel,
                        ),
                  },
                ),
              ),
            ),
            child: Builder(
              builder: (context) {
                r = resolveMockupDevice(
                  context,
                  device: .phone,
                  orientation: .portrait,
                  widgetWidth: flatWidth,
                  finish: .flat,
                );
                realistic = resolveMockupDevice(
                  context,
                  device: .phone,
                  orientation: .portrait,
                  widgetWidth: flatWidth,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(r.bezelColor, const Color(0xFF112233));
      // The realistic finish is not reached by the flat entry.
      expect(realistic.bezelColor, _kBlack);
    });
  });
}
