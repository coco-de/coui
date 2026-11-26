// MockupFoldable — the status island: the column at the right edge of each
// screen that holds the cover's camera, the clock and the status indicator,
// where a slab phone has a status bar across the top.
//
// Every box expected here is worked out from the style's lengths (iOS points)
// and the scale the face draws system lengths at, and read back from what is
// laid out and painted — the island's own boxes, the content's box, the
// colours handed to the canvas, the pixels.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mockup_foldable_harness.dart';

const Key _kContent = ValueKey('content');

/// The scale both default faces draw the operating system's lengths at.
const double _kScale = CoreMockupFoldableStyle.defaultSystemScale;

// The island's default lengths, in logical px.
const double _kColumn = CoreMockupFoldableStyle.defaultIslandWidth * _kScale;
const double _kOffset = CoreMockupFoldableStyle.defaultIslandOffset * _kScale;
const double _kCameraGap = CoreMockupFoldableStyle.islandCameraGap * _kScale;
const double _kCamera =
    CoreMockupFoldableStyle.defaultIslandCameraSize * _kScale;
const double _kClockHeight =
    CoreMockupFoldableStyle.islandClockHeight * _kScale;
const double _kClockGap = CoreMockupFoldableStyle.islandClockGap * _kScale;
const double _kIndicator =
    CoreMockupFoldableStyle.islandIndicatorSize * _kScale;

/// A box may differ from the arithmetic by rounding only.
const double _kTolerance = 1e-6;

const CoreMockupDevice _kCover = CoreMockupDevice.phone;
const CoreMockupDevice _kInner = CoreMockupDevice.tablet;

Widget _foldable(
  double angle, {
  bool showCamera = true,
  bool showStatus = true,
  bool showGestureBar = false,
  CoreBrightness? screenBrightness,
  CoreMockupFoldableStyle style = kAtOnce,
  Widget child = const SizedBox.expand(key: _kContent),
}) => MockupFoldable(
  foldAngle: angle,
  showCamera: showCamera,
  showStatus: showStatus,
  showGestureBar: showGestureBar,
  screenBrightness: screenBrightness,
  mockupFoldableStyle: style,
  child: child,
);

/// A part of the island on [device]'s screen.
Finder _part(CoreMockupDevice device, Key part) =>
    find.descendant(of: faceOf(device), matching: find.byKey(part));

/// Where [finder] is laid out on [device]'s screen — in the screen's own
/// space, its top-left corner the origin.
Rect _onScreen(WidgetTester tester, CoreMockupDevice device, Finder finder) {
  final screen = screenBoxOf(tester, device);
  final box = tester.renderObject<RenderBox>(finder);

  return box.localToGlobal(Offset.zero, ancestor: screen) & box.size;
}

void _expectRect(Rect drawn, Rect stated, String what) {
  expect(drawn.left, closeTo(stated.left, _kTolerance), reason: '$what left');
  expect(drawn.top, closeTo(stated.top, _kTolerance), reason: '$what top');
  expect(
    drawn.width,
    closeTo(stated.width, _kTolerance),
    reason: '$what width',
  );
  expect(
    drawn.height,
    closeTo(stated.height, _kTolerance),
    reason: '$what height',
  );
}

Rect _rectOf(CoreMockupDeviceRect? rect) =>
    Rect.fromLTWH(rect!.left, rect.top, rect.width, rect.height);

/// A box [size] square, centred across a column [column] wide at the right
/// edge of a screen [screenWidth] wide, [top] below its top edge.
Rect _centred(
  double screenWidth,
  double top,
  double size, {
  double column = _kColumn,
}) => Rect.fromLTWH(screenWidth - column / 2 - size / 2, top, size, size);

/// The clock's box: the column's whole width, [top] below the screen's top.
Rect _clockBox(double screenWidth, double top, {double column = _kColumn}) =>
    Rect.fromLTWH(screenWidth - column, top, column, _kClockHeight);

/// The clock's words on [device]'s screen.
Finder _clock(CoreMockupDevice device) =>
    find.descendant(of: faceOf(device), matching: find.text('9:41'));

/// The two colours the status indicator of [device] is painted in: the ring,
/// then the dots.
List<Color> _indicatorColors(CoreMockupDevice device) {
  final colors = <Color>[];
  expect(
    find.descendant(
      of: _part(device, kIslandIndicator),
      matching: find.byType(CustomPaint),
    ),
    paints..everything((method, arguments) {
      if (method == #drawPath) colors.add((arguments.last as Paint).color);

      return true;
    }),
  );

  return colors;
}

Color _cameraColor(WidgetTester tester, CoreMockupDevice device) =>
    (tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: _part(device, kIslandCamera),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration)
        .color!;

TextStyle _clockStyle(WidgetTester tester, CoreMockupDevice device) =>
    tester.widget<Text>(_clock(device)).style!;

/// Reports the screen it is laid out on, as the content sees it.
class _MediaProbe extends StatelessWidget {
  const _MediaProbe(this.onMedia);

  final ValueChanged<MediaQueryData> onMedia;

  @override
  Widget build(BuildContext context) {
    onMedia(MediaQuery.of(context));

    return const SizedBox.expand(key: _kContent);
  }
}

void main() {
  group('MockupFoldable — the island on the cover', () {
    testWidgets('the camera stands at the top of a column at the right edge '
        'of the screen, the clock and the status indicator under it', (
      tester,
    ) async {
      await tester.pumpWidget(foldableApp(_foldable(CoreMockupFold.closed)));
      final screen = screenBoxOf(tester, _kCover).size;

      final camera = _centred(screen.width, _kOffset, _kCamera);
      final clock = _clockBox(screen.width, camera.bottom + _kCameraGap);
      final indicator = _centred(
        screen.width,
        clock.bottom + _kClockGap,
        _kIndicator,
      );
      _expectRect(
        _onScreen(tester, _kCover, _part(_kCover, kIslandCamera)),
        camera,
        'camera',
      );
      _expectRect(
        _onScreen(tester, _kCover, _part(_kCover, kIslandClock)),
        clock,
        'clock',
      );
      _expectRect(
        _onScreen(tester, _kCover, _part(_kCover, kIslandIndicator)),
        indicator,
        'indicator',
      );

      // At the top right: in the last column's width of the screen, and
      // nearer its top than a status bar is deep.
      expect(camera.left, greaterThan(screen.width - _kColumn));
      expect(camera.right, lessThan(screen.width));
      expect(camera.top, lessThan(screen.height / 10));

      // The same boxes the shared layout states — the ones the Web twin
      // draws.
      final stated = defaultFoldableLayout().islandOf(
        CoreMockupFoldScreen.cover,
        showCamera: true,
        showStatus: true,
      )!;
      _expectRect(camera, _rectOf(stated.camera), 'stated camera');
      _expectRect(clock, _rectOf(stated.clock), 'stated clock');
      _expectRect(indicator, _rectOf(stated.indicator), 'stated indicator');
      expect(stated.column.width, closeTo(_kColumn, _kTolerance));
    });

    testWidgets('the camera is a filled circle in the lens black; the clock '
        'reads 9:41, centred in its box on one line', (tester) async {
      await tester.pumpWidget(foldableApp(_foldable(CoreMockupFold.closed)));

      final hole = tester.widget<DecoratedBox>(
        find.descendant(
          of: _part(_kCover, kIslandCamera),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((hole.decoration as BoxDecoration).shape, BoxShape.circle);
      expect(_cameraColor(tester, _kCover), const Color(0xFF000000));

      final words = tester.widget<Text>(_clock(_kCover));
      expect(words.data, CoreMockupFoldableStyle.sampleTime);
      expect(words.maxLines, 1);
      expect(words.softWrap, isFalse);
      expect(words.textScaler, TextScaler.noScaling);
      final box = _onScreen(tester, _kCover, _part(_kCover, kIslandClock));
      final drawn = _onScreen(tester, _kCover, _clock(_kCover));
      expect(drawn.center.dx, closeTo(box.center.dx, _kTolerance));
      expect(drawn.center.dy, closeTo(box.center.dy, _kTolerance));
    });

    testWidgets('the content is laid out clear of the column, and is told of '
        'no inset left to keep', (tester) async {
      late MediaQueryData seen;
      await tester.pumpWidget(
        foldableApp(
          _foldable(
            CoreMockupFold.closed,
            child: _MediaProbe((media) => seen = media),
          ),
        ),
      );
      final screen = screenBoxOf(tester, _kCover).size;

      _expectRect(
        _onScreen(tester, _kCover, find.byKey(_kContent)),
        Rect.fromLTWH(0, 0, screen.width - _kColumn, screen.height),
        'content',
      );
      // The column was the screen's padding and is used up: content with a
      // `SafeArea` of its own does not keep clear of it twice.
      expect(seen.padding, EdgeInsets.zero);
      expect(seen.viewPadding, EdgeInsets.zero);
      // The screen the content is on is still the whole screen.
      expect(seen.size.width, closeTo(screen.width, _kTolerance));
      expect(seen.size.height, closeTo(screen.height, _kTolerance));
    });

    testWidgets('without a camera the clock moves up into its place', (
      tester,
    ) async {
      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.closed, showCamera: false)),
      );
      final screen = screenBoxOf(tester, _kCover).size;

      expect(_part(_kCover, kIslandCamera), findsNothing);
      final clock = _clockBox(screen.width, _kOffset);
      _expectRect(
        _onScreen(tester, _kCover, _part(_kCover, kIslandClock)),
        clock,
        'clock',
      );
      _expectRect(
        _onScreen(tester, _kCover, _part(_kCover, kIslandIndicator)),
        _centred(screen.width, clock.bottom + _kClockGap, _kIndicator),
        'indicator',
      );
      // The column is still kept clear.
      expect(
        tester.getSize(find.byKey(_kContent)).width,
        closeTo(screen.width - _kColumn, _kTolerance),
      );
    });

    testWidgets('without the status only the camera is left, in the same '
        'place, and its column with it', (tester) async {
      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.closed, showStatus: false)),
      );
      final screen = screenBoxOf(tester, _kCover).size;

      _expectRect(
        _onScreen(tester, _kCover, _part(_kCover, kIslandCamera)),
        _centred(screen.width, _kOffset, _kCamera),
        'camera',
      );
      expect(_part(_kCover, kIslandClock), findsNothing);
      expect(_part(_kCover, kIslandIndicator), findsNothing);
      expect(find.text('9:41'), findsNothing);
      expect(
        tester.getSize(find.byKey(_kContent)).width,
        closeTo(screen.width - _kColumn, _kTolerance),
      );
    });

    testWidgets('in an app that reads right to left the island is still on '
        'the right: a device does not mirror when the text does', (
      tester,
    ) async {
      await tester.pumpWidget(
        foldableApp(
          _foldable(CoreMockupFold.closed),
          textDirection: TextDirection.rtl,
        ),
      );
      final screen = screenBoxOf(tester, _kCover).size;

      _expectRect(
        _onScreen(tester, _kCover, _part(_kCover, kIslandCamera)),
        _centred(screen.width, _kOffset, _kCamera),
        'camera',
      );
      _expectRect(
        _onScreen(tester, _kCover, find.byKey(_kContent)),
        Rect.fromLTWH(0, 0, screen.width - _kColumn, screen.height),
        'content',
      );
    });

    testWidgets('a device too small for its island still lays out', (
      tester,
    ) async {
      for (final angle in const [
        CoreMockupFold.closed,
        CoreMockupFold.halfOpen,
        CoreMockupFold.flat,
      ]) {
        await tester.pumpWidget(
          foldableApp(
            MockupFoldable(
              foldAngle: angle,
              width: 40,
              mockupFoldableStyle: kAtOnce,
              child: const SizedBox.expand(key: _kContent),
            ),
          ),
        );

        expect(tester.takeException(), isNull, reason: '$angle°');
        // The column is never wider than the screen it stands on.
        final device = angle == CoreMockupFold.closed ? _kCover : _kInner;
        expect(
          tester.getSize(find.byKey(_kContent)).width,
          inInclusiveRange(0, screenBoxOf(tester, device).size.width),
          reason: '$angle°',
        );
      }
    });

    testWidgets('with neither it has no island, and the content has the '
        'whole screen', (tester) async {
      await tester.pumpWidget(
        foldableApp(
          _foldable(
            CoreMockupFold.closed,
            showCamera: false,
            showStatus: false,
          ),
        ),
      );

      for (final part in const [
        kIslandCamera,
        kIslandClock,
        kIslandIndicator,
      ]) {
        expect(find.byKey(part), findsNothing);
      }
      expect(
        tester.getSize(find.byKey(_kContent)),
        screenBoxOf(tester, _kCover).size,
      );
    });
  });

  group('MockupFoldable — the island on the inner screen', () {
    testWidgets('has no camera: the clock at the top of the column, the '
        'status indicator under it', (tester) async {
      await tester.pumpWidget(foldableApp(_foldable(CoreMockupFold.flat)));
      final screen = screenBoxOf(tester, _kInner).size;

      expect(_part(_kInner, kIslandCamera), findsNothing);
      final clock = _clockBox(screen.width, _kOffset);
      final indicator = _centred(
        screen.width,
        clock.bottom + _kClockGap,
        _kIndicator,
      );
      _expectRect(
        _onScreen(tester, _kInner, _part(_kInner, kIslandClock)),
        clock,
        'clock',
      );
      _expectRect(
        _onScreen(tester, _kInner, _part(_kInner, kIslandIndicator)),
        indicator,
        'indicator',
      );
      _expectRect(
        _onScreen(tester, _kInner, find.byKey(_kContent)),
        Rect.fromLTWH(0, 0, screen.width - _kColumn, screen.height),
        'content',
      );

      final stated = defaultFoldableLayout().islandOf(
        CoreMockupFoldScreen.inner,
        showCamera: true,
        showStatus: true,
      )!;
      expect(stated.camera, isNull);
      _expectRect(clock, _rectOf(stated.clock), 'stated clock');
      _expectRect(indicator, _rectOf(stated.indicator), 'stated indicator');
    });

    testWidgets('without the status it has no island — the camera belongs '
        'to the cover alone — and the content has the whole screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.flat, showStatus: false)),
      );

      for (final part in const [
        kIslandCamera,
        kIslandClock,
        kIslandIndicator,
      ]) {
        expect(find.byKey(part), findsNothing);
      }
      expect(
        tester.getSize(find.byKey(_kContent)),
        screenBoxOf(tester, _kInner).size,
      );
    });

    testWidgets('each screen keeps its island while the content is on the '
        'other', (tester) async {
      // Shut: the content is on the cover; the inner screen, dark under it,
      // still has its clock.
      await tester.pumpWidget(foldableApp(_foldable(CoreMockupFold.closed)));
      expect(
        find.ancestor(of: find.byKey(_kContent), matching: faceOf(_kCover)),
        findsOneWidget,
      );
      expect(_part(_kInner, kIslandClock), findsOneWidget);
      expect(_part(_kInner, kIslandIndicator), findsOneWidget);

      // Nearly shut the other way round: the content is on the inner screen
      // and the cover, still in sight, keeps its camera and clock.
      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.coverUntil + 1)),
      );
      expect(
        find.ancestor(of: find.byKey(_kContent), matching: faceOf(_kInner)),
        findsOneWidget,
      );
      expect(_part(_kCover, kIslandCamera), findsOneWidget);
      expect(_part(_kCover, kIslandClock), findsOneWidget);
    });

    testWidgets('the picture a bent screen is drawn from is taken with the '
        'island and the room kept for it', (tester) async {
      final layout = defaultFoldableLayout();
      useOneToOneView(tester, Size(layout.width, layout.height));
      final boundary = GlobalKey();
      const red = Color(0xFFFF0000);
      await tester.pumpWidget(
        foldableApp(
          _foldable(
            CoreMockupFold.halfOpen,
            child: const ColoredBox(
              key: _kContent,
              color: red,
              child: SizedBox.expand(),
            ),
          ),
          boundary: boundary,
        ),
      );

      // The island is under the picture, so it is in it.
      expect(
        find.descendant(
          of: find.byType(SnapshotWidget),
          matching: find.byKey(kIslandIndicator),
        ),
        findsOneWidget,
      );

      // Two points of the right half's screen, level with each other well
      // below the island: one in the column, one beside it.
      final pose = layout.poseAt(CoreMockupFold.halfOpen);
      final matrix = Matrix4.fromList(pose.innerRight.matrix);
      final screen = layout.innerScreen;
      Offset onStage(double x) => MatrixUtils.transformPoint(
        matrix,
        Offset(screen.left + x, screen.top + screen.height * 0.6),
      );
      final pixels = await capture(tester, boundary);
      final inColumn = pixels.onStage(onStage(screen.width - _kColumn / 2));
      final beside = pixels.onStage(onStage(screen.width - _kColumn - 20));

      // Beside the column the content shows; in it, the screen's own fill —
      // lit, and no more red than it is green or blue.
      expect(beside.r - beside.g, greaterThan(0.5));
      expect(inColumn.r - inColumn.g, lessThan(0.1));
      expect(inColumn.g, greaterThan(0.5));

      // The island goes while the screen is bent: the picture is taken
      // again, and the content has the column's room in it.
      await tester.pumpWidget(
        foldableApp(
          _foldable(
            CoreMockupFold.halfOpen,
            showStatus: false,
            child: const ColoredBox(
              key: _kContent,
              color: red,
              child: SizedBox.expand(),
            ),
          ),
          boundary: boundary,
        ),
      );
      final without = (await capture(
        tester,
        boundary,
      )).onStage(onStage(screen.width - _kColumn / 2));
      expect(without.r - without.g, greaterThan(0.5));
    });
  });

  group('MockupFoldable — the island and the gesture bar', () {
    testWidgets('there is no gesture bar unless it is asked for; asked for, '
        'the content keeps clear of it too', (tester) async {
      await tester.pumpWidget(foldableApp(_foldable(CoreMockupFold.flat)));
      final screen = screenBoxOf(tester, _kInner).size;
      expect(tester.getSize(find.byKey(_kContent)).height, screen.height);

      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.flat, showGestureBar: true)),
      );
      final content = _onScreen(tester, _kInner, find.byKey(_kContent));
      expect(content.top, 0);
      expect(content.bottom, lessThan(screen.height));
      expect(content.width, closeTo(screen.width - _kColumn, _kTolerance));
      // The island stands where it stood: it hangs from the screen's top.
      _expectRect(
        _onScreen(tester, _kInner, _part(_kInner, kIslandClock)),
        _clockBox(screen.width, _kOffset),
        'clock',
      );
    });

    testWidgets('neither face draws a camera or a status bar of its own', (
      tester,
    ) async {
      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.closed, showGestureBar: true)),
      );

      for (final device in const [_kInner, _kCover]) {
        final face = tester.widget<MockupDevice>(faceOf(device));
        expect(face.showCamera, isFalse, reason: '$device');
        expect(face.showStatusBar, isFalse, reason: '$device');
        expect(face.showGestureBar, isTrue, reason: '$device');
      }
      // One clock on each screen, and it is the island's.
      expect(
        find.descendant(
          of: _part(_kCover, kIslandClock),
          matching: find.text('9:41'),
        ),
        findsOneWidget,
      );
      expect(_clock(_kCover), findsOneWidget);
      expect(_clock(_kInner), findsOneWidget);
    });
  });

  group('MockupFoldable — what the island is to input and assistive '
      'technology', () {
    testWidgets('it takes no input', (tester) async {
      await tester.pumpWidget(foldableApp(_foldable(CoreMockupFold.closed)));

      for (final part in const [
        kIslandCamera,
        kIslandClock,
        kIslandIndicator,
      ]) {
        final box = tester.renderObject<RenderBox>(_part(_kCover, part));
        final hit = tester.hitTestOnBinding(
          box.localToGlobal(box.size.center(Offset.zero)),
        );

        expect(
          hit.path.map((entry) => entry.target),
          isNot(contains(box)),
          reason: '$part',
        );
      }
    });

    testWidgets('it is not read, on either screen', (tester) async {
      final handle = tester.ensureSemantics();
      for (final angle in const [CoreMockupFold.closed, CoreMockupFold.flat]) {
        await tester.pumpWidget(foldableApp(_foldable(angle)));
        await tester.pump();

        expect(find.text('9:41'), findsWidgets, reason: '$angle°');
        expect(find.semantics.byLabel('9:41'), findsNothing, reason: '$angle°');
      }
      handle.dispose();
    });
  });

  group('MockupFoldable — the island is drawn in the colours of its '
      'screen', () {
    final light = ThemeData.fromCore(CoreThemePresets.light);
    final dark = ThemeData.fromCore(CoreThemePresets.dark);

    Future<void> pump(
      WidgetTester tester, {
      required CoreThemeMode page,
      CoreBrightness? screen,
    }) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: light,
          darkTheme: dark,
          themeMode: page,
          home: Center(
            child: _foldable(CoreMockupFold.closed, screenBrightness: screen),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final (page, screen, inScreen, onPage) in [
      (CoreThemeMode.dark, CoreBrightness.light, light, dark),
      (CoreThemeMode.light, CoreBrightness.dark, dark, light),
    ]) {
      testWidgets('a $screen screen on a ${page.name} page draws its clock '
          'and its indicator in the colours of the screen', (tester) async {
        await pump(tester, page: page, screen: screen);
        final ink = inScreen.colorScheme.onSurface.toValue();
        final pageInk = onPage.colorScheme.onSurface.toValue();
        expect(ink, isNot(pageInk));

        expect(_clockStyle(tester, _kCover).color, ink);
        // A colour read back from the canvas has been through its single
        // precision, so it is the same colour rather than an equal one.
        final [ring, dots] = _indicatorColors(_kCover);
        expect(ring, isSameColorAs(ink));
        expect(
          dots,
          isSameColorAs(
            inScreen.colorScheme
                .resolve(CoreMockupFoldableStyle.defaultIslandDotColor)
                .toValue(),
          ),
        );
        expect(dots.a, closeTo(CoreOpacity.opacity30, 1e-6));
        // The camera is hardware: the same black on any screen.
        expect(_cameraColor(tester, _kCover), const Color(0xFF000000));
      });
    }

    testWidgets('a screen that states no brightness draws them in the '
        'colours of the page', (tester) async {
      await pump(tester, page: CoreThemeMode.dark);

      final ink = dark.colorScheme.onSurface.toValue();
      expect(_clockStyle(tester, _kCover).color, ink);
      expect(_indicatorColors(_kCover).first, isSameColorAs(ink));
    });
  });

  group('MockupFoldable — the style of the island', () {
    testWidgets('its lengths, colours and type are those the style states', (
      tester,
    ) async {
      const column = 120 * _kScale;
      await tester.pumpWidget(
        foldableApp(
          _foldable(
            CoreMockupFold.closed,
            style: const CoreMockupFoldableStyle(
              islandWidth: 120,
              islandOffset: 40,
              islandCameraSize: 20,
              islandCameraColor: CoreColor(0xFF0000FF),
              islandTextStyle: CoreTextStyle.token(
                CoreTextStyles.labelSmall,
                color: CoreColor(0xFF112233),
              ),
              islandIconColor: CoreColor(0xFFFF0000),
              islandDotColor: CoreColor(0xFF00FF00),
              duration: Duration.zero,
            ),
          ),
        ),
      );
      final screen = screenBoxOf(tester, _kCover).size;

      final camera = _centred(
        screen.width,
        40 * _kScale,
        20 * _kScale,
        column: column,
      );
      _expectRect(
        _onScreen(tester, _kCover, _part(_kCover, kIslandCamera)),
        camera,
        'camera',
      );
      _expectRect(
        _onScreen(tester, _kCover, _part(_kCover, kIslandClock)),
        _clockBox(screen.width, camera.bottom + _kCameraGap, column: column),
        'clock',
      );
      expect(
        tester.getSize(find.byKey(_kContent)).width,
        closeTo(screen.width - column, _kTolerance),
      );
      expect(_cameraColor(tester, _kCover), const Color(0xFF0000FF));
      expect(_indicatorColors(_kCover), const [
        Color(0xFFFF0000),
        Color(0xFF00FF00),
      ]);

      // The role's own size and weight, at the island's scale.
      final clock = _clockStyle(tester, _kCover);
      final role = CoreTypography.coui.labelSmall;
      expect(clock.color, const Color(0xFF112233));
      expect(clock.fontSize, closeTo(role.fontSize! * _kScale, _kTolerance));
      expect(clock.fontWeight, fontWeightFromInt(role.fontWeight));
    });

    testWidgets('a style that states only the colour of the clock keeps its '
        'role', (tester) async {
      await tester.pumpWidget(
        foldableApp(
          _foldable(
            CoreMockupFold.closed,
            style: const CoreMockupFoldableStyle(
              islandTextStyle: CoreTextStyle(color: CoreColor(0xFF112233)),
              duration: Duration.zero,
            ),
          ),
        ),
      );

      final clock = _clockStyle(tester, _kCover);
      final role = CoreTypography.coui.titleSmall;
      expect(clock.color, const Color(0xFF112233));
      expect(clock.fontSize, closeTo(role.fontSize! * _kScale, _kTolerance));
      expect(clock.fontWeight, fontWeightFromInt(role.fontWeight));
      // Tracking is the role's ratio of the size it is drawn at.
      expect(
        clock.letterSpacing,
        closeTo(role.letterSpacing! * role.fontSize! * _kScale, _kTolerance),
      );
    });

    testWidgets('the project theme and the instance both reach the island, '
        'the instance last', (tester) async {
      const theme = CoreComponentTheme(
        mockupFoldable: CoreMockupFoldableTheme(
          style: CoreMockupFoldableStyle(
            islandIconColor: CoreColor(0xFFFF0000),
            islandWidth: 120,
            duration: Duration.zero,
          ),
        ),
      );

      await tester.pumpWidget(
        foldableApp(
          const MockupFoldable(
            foldAngle: CoreMockupFold.closed,
            child: SizedBox.expand(key: _kContent),
          ),
          componentTheme: theme,
        ),
      );
      final screen = screenBoxOf(tester, _kCover).size;
      expect(_indicatorColors(_kCover).first, const Color(0xFFFF0000));
      expect(
        tester.getSize(find.byKey(_kContent)).width,
        closeTo(screen.width - 120 * _kScale, _kTolerance),
      );

      await tester.pumpWidget(
        foldableApp(
          const MockupFoldable(
            foldAngle: CoreMockupFold.closed,
            mockupFoldableStyle: CoreMockupFoldableStyle(
              islandIconColor: CoreColor(0xFF0000FF),
            ),
            child: SizedBox.expand(key: _kContent),
          ),
          componentTheme: theme,
        ),
      );
      expect(_indicatorColors(_kCover).first, const Color(0xFF0000FF));
      // What the instance does not state is still the theme's.
      expect(
        tester.getSize(find.byKey(_kContent)).width,
        closeTo(screen.width - 120 * _kScale, _kTolerance),
      );
    });

    testWidgets('the boxes of the island follow the theme scaling; its clock '
        'is set by the theme typography and does not', (tester) async {
      const scaling = 1.5;
      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.closed), scaling: scaling),
      );
      final screen = screenBoxOf(tester, _kCover).size;

      final camera = _onScreen(tester, _kCover, _part(_kCover, kIslandCamera));
      expect(camera.width, closeTo(_kCamera * scaling, _kTolerance));
      expect(camera.top, closeTo(_kOffset * scaling, _kTolerance));
      expect(
        camera.center.dx,
        closeTo(screen.width - _kColumn * scaling / 2, _kTolerance),
      );
      expect(
        tester.getSize(find.byKey(_kContent)).width,
        closeTo(screen.width - _kColumn * scaling, _kTolerance),
      );
      expect(
        _clockStyle(tester, _kCover).fontSize,
        closeTo(CoreTypography.coui.titleSmall.fontSize! * _kScale, 1e-6),
      );
    });

    testWidgets('a face drawn at another system scale draws its island at '
        'that scale, the other face at its own', (tester) async {
      const style = CoreMockupFoldableStyle(
        coverDeviceStyle: CoreMockupDeviceStyle(systemBarReferenceScale: 1),
        duration: Duration.zero,
      );
      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.closed, style: style)),
      );
      final cover = screenBoxOf(tester, _kCover).size;
      final inner = screenBoxOf(tester, _kInner).size;

      // The cover: every length at one logical px to the point.
      _expectRect(
        _onScreen(tester, _kCover, _part(_kCover, kIslandCamera)),
        _centred(
          cover.width,
          CoreMockupFoldableStyle.defaultIslandOffset,
          CoreMockupFoldableStyle.defaultIslandCameraSize,
          column: CoreMockupFoldableStyle.defaultIslandWidth,
        ),
        'camera',
      );
      expect(
        _clockStyle(tester, _kCover).fontSize,
        CoreTypography.coui.titleSmall.fontSize,
      );
      // The inner screen is the open body's, still at its own scale.
      _expectRect(
        _onScreen(tester, _kInner, _part(_kInner, kIslandClock)),
        _clockBox(inner.width, _kOffset),
        'inner clock',
      );
    });
  });

  group('MockupFoldable — the body it stands on', () {
    testWidgets('by default the body is graphite, with corners rounder than '
        'those of the kit tablet', (tester) async {
      final layout = defaultFoldableLayout();
      useOneToOneView(tester, Size(layout.width, layout.height));
      final boundary = GlobalKey();
      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.flat), boundary: boundary),
      );
      final pixels = await capture(tester, boundary);

      // The body's ring, half way down its left side: a neutral dark grey.
      final ring = pixels.onStage(Offset(2, layout.height / 2));
      expect(ring.r, closeTo(ring.g, 0.01));
      expect(ring.g, closeTo(ring.b, 0.01));
      expect(ring.r, inInclusiveRange(0.25, 0.45));

      // A corner of radius 36 leaves the page showing 8 in from the body's
      // corner on the diagonal and covers it 13 in; the kit's tablet, with
      // 16, covers both.
      bool deviceAt(double x, double y) =>
          pixels.isDevice((x + kMargin).floor(), (y + kMargin).floor());
      expect(deviceAt(8, 8), isFalse);
      expect(deviceAt(13, 13), isTrue);
      expect(deviceAt(layout.width - 8, 8), isFalse);
      expect(deviceAt(layout.width - 13, 13), isTrue);
    });
  });
}
