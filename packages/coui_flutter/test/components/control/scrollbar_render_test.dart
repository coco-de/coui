// Reads the pixels the bar actually paints.
//
// `scrollbar_redesign_test.dart` asserts the numbers handed to the painter.
// That cannot see a painter that is handed the right numbers and draws
// something else — a square thumb where a capsule was asked for, a gap on
// the wrong side, a colour blended twice. Pixels can, so this test renders
// the bar into an image and checks single pixels against the colours the
// design states.
import 'dart:io';
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../parity/parity_fonts.dart';

const _kItemCount = 50;
const _kItemHeight = 40.0;

/// Side of the square the bar is drawn in. Content is ten times taller, so
/// the thumb is clamped to its minimum length and is easy to locate.
const _kSide = 200.0;

/// Gap the thumb keeps from the edge (`space/2`) and the thumb itself
/// (`size/6`). Stated here as plain numbers on purpose: this test is the
/// second opinion on what the design says, so it must not read the token
/// it is checking back out of the code under test.
const _kInset = 2;
const _kThickness = 6;
const _kHoverThickness = 8;
const _kMinThumbLength = 48;

/// Allowed distance, per channel, between a painted pixel and the colour the
/// design says it should be — 8-bit rounding of a translucent blend.
const _kChannelTolerance = 2;

/// How much of the thumb colour a pixel at the corner of the thumb's
/// bounding box may carry and still be called "outside the round cap". The
/// cap only grazes that pixel (about a tenth of it); a rectangle would cover
/// all of it.
const _kCornerCoverageCeiling = 0.3;

/// Environment variable that, when set, names a directory the evidence
/// images are written to.
const _kCaptureDirEnv = 'SCROLLBAR_CAPTURE_DIR';

/// Pixel ratio the evidence images are written at.
const _kCaptureScale = 3.0;

/// Corner radius of the card the evidence images draw the bar in.
const _kCardRadius = 16.0;

final GlobalKey _boundaryKey = GlobalKey();

Widget _bar(ScrollController controller, {CoreScrollbarStyle? style}) =>
    Scrollbar(
      controller: controller,
      visibility: CoreScrollbarVisibility.always,
      scrollbarStyle: style,
      child: ListView.builder(
        controller: controller,
        itemBuilder: (_, index) => SizedBox(
          height: _kItemHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('Scroll item $index').bodyMedium,
            ),
          ),
        ),
        itemCount: _kItemCount,
      ),
    );

/// The bar over a flat surface fill, nothing else — so a pixel is either
/// the surface, the thumb, or a blend of the two.
Widget _flat(ScrollController controller, {CoreScrollbarStyle? style}) =>
    RepaintBoundary(
      key: _boundaryKey,
      child: Builder(
        builder: (context) => ColoredBox(
          color: Theme.of(context).colorScheme.surface.toValue(),
          child: SizedBox(
            width: _kSide,
            height: _kSide,
            child: _bar(controller, style: style),
          ),
        ),
      ),
    );

/// The bar inside a card with a rounded border, the shape the gap exists
/// for: a thumb flush with the edge would be cut by the corner.
Widget _card(ScrollController controller) => RepaintBoundary(
  key: _boundaryKey,
  child: Builder(
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.all(CoreSpace.space16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.toValue(),
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border.all(color: scheme.outlineVariant.toValue()),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_kCardRadius - 1),
            child: SizedBox(
              width: _kSide,
              height: _kSide,
              child: _bar(controller),
            ),
          ),
        ),
      );
    },
  ),
);

Color _resolved(WidgetTester tester, CoreColor core) {
  final theme = Theme.of(tester.element(find.byType(Scrollbar)));
  return theme.colorScheme.resolve(core).toValue();
}

/// The boundary rendered to RGBA bytes at 1 logical pixel per pixel.
Future<({ByteData bytes, int width})> _render(
  WidgetTester tester, {
  double scale = 1,
}) async {
  final image = (await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    return await boundary.toImage(pixelRatio: scale);
  }))!;
  final bytes = (await tester.runAsync(image.toByteData))!;
  return (bytes: bytes, width: image.width);
}

Color _pixel(({ByteData bytes, int width}) frame, int x, int y) {
  final offset = (y * frame.width + x) * 4;
  return Color.fromARGB(
    frame.bytes.getUint8(offset + 3),
    frame.bytes.getUint8(offset),
    frame.bytes.getUint8(offset + 1),
    frame.bytes.getUint8(offset + 2),
  );
}

/// [ink] laid over [ground] — the colour a translucent thumb has to paint
/// on a flat surface.
Color _over(Color ink, Color ground) => Color.alphaBlend(ink, ground);

/// How much of [thumb] a painted [pixel] carries: 0 for the bare [surface],
/// 1 for the full thumb colour.
double _coverage(
  Color pixel, {
  required Color surface,
  required Color thumb,
}) {
  double apart(Color a, Color b) =>
      (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs();
  return apart(pixel, surface) / apart(thumb, surface);
}

Matcher _isColor(Color expected) => _ColorWithin(expected);

class _ColorWithin extends Matcher {
  const _ColorWithin(this.expected);

  final Color expected;

  int _channel(double value) => (value * 255).round();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Color) return false;
    return (_channel(item.r) - _channel(expected.r)).abs() <=
            _kChannelTolerance &&
        (_channel(item.g) - _channel(expected.g)).abs() <= _kChannelTolerance &&
        (_channel(item.b) - _channel(expected.b)).abs() <= _kChannelTolerance;
  }

  @override
  Description describe(Description description) =>
      description.add('a colour within $_kChannelTolerance of $expected');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) => mismatchDescription.add('was $item');
}

Future<void> _pumpBar(
  WidgetTester tester,
  ScrollController controller, {
  required Widget Function(ScrollController) host,
  bool dark = false,
}) async {
  await pumpTestApp(
    tester,
    host(controller),
    theme: ThemeData(
      colorScheme: dark
          ? CoreThemePresets.darkColorScheme
          : CoreThemePresets.lightColorScheme,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _hoverThumb(WidgetTester tester) async {
  final origin = tester.getTopLeft(find.byKey(_boundaryKey));
  // Middle of the thumb: across its resting width, half a minimum length
  // down from the top edge.
  final gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
  await gesture.addPointer(location: const Offset(1, 1));
  addTearDown(gesture.removePointer);
  await gesture.moveTo(
    origin +
        const Offset(
          _kSide - _kInset - _kThickness / 2,
          _kInset + _kMinThumbLength / 2,
        ),
  );
  await tester.pump();
  await tester.pump(
    const Duration(milliseconds: CoreScrollbarContract.hoverTransitionMs + 50),
  );
}

void main() {
  setUpAll(loadParityFonts);

  for (final dark in const [false, true]) {
    final mode = dark ? 'dark' : 'light';

    group('Scrollbar painted pixels — $mode', () {
      testWidgets(
        'rest: a capsule of surface ink at half strength, 2px clear of the '
        'edge',
        (tester) async {
          final controller = ScrollController();
          addTearDown(controller.dispose);
          await _pumpBar(tester, controller, host: _flat, dark: dark);

          final surface = _resolved(
            tester,
            const CoreColor.token(CoreColors.surface),
          );
          final ink = _resolved(
            tester,
            CoreScrollbarStyle.defaultThumbColor,
          );
          final thumb = _over(ink, surface);
          final frame = await _render(tester);

          const left = _kSide - _kInset - _kThickness; // first thumb pixel
          const right = _kSide - _kInset; // first pixel past the thumb
          const middle = _kInset + _kMinThumbLength ~/ 2;

          // The body of the thumb: the surface ink over the surface.
          expect(_pixel(frame, left.toInt(), middle), _isColor(thumb));
          expect(_pixel(frame, right.toInt() - 1, middle), _isColor(thumb));
          // Both sides of it are the surface: the gap to the edge on the
          // right, the content area on the left.
          expect(_pixel(frame, right.toInt(), middle), _isColor(surface));
          expect(_pixel(frame, _kSide.toInt() - 1, middle), _isColor(surface));
          expect(_pixel(frame, left.toInt() - 1, middle), _isColor(surface));
          // The gap above the thumb.
          expect(
            _pixel(frame, (left + _kThickness ~/ 2).toInt(), 0),
            _isColor(surface),
          );
          // A capsule, not a rectangle: the corner pixel of the thumb's
          // bounding box only grazes the round cap, so it is mostly surface.
          // A square-cornered thumb would cover it entirely.
          expect(
            _coverage(
              _pixel(frame, left.toInt(), _kInset),
              surface: surface,
              thumb: thumb,
            ),
            lessThan(_kCornerCoverageCeiling),
          );
          expect(
            _coverage(
              _pixel(frame, left.toInt(), _kInset + _kMinThumbLength - 1),
              surface: surface,
              thumb: thumb,
            ),
            lessThan(_kCornerCoverageCeiling),
          );
        },
        variant: TargetPlatformVariant.desktop(),
      );

      testWidgets(
        'hover: darker and 8px wide, with the same footprint — the extra '
        'width comes out of the gap',
        (tester) async {
          final controller = ScrollController();
          addTearDown(controller.dispose);
          await _pumpBar(tester, controller, host: _flat, dark: dark);
          await _hoverThumb(tester);

          final surface = _resolved(
            tester,
            const CoreColor.token(CoreColors.surface),
          );
          final ink = _resolved(
            tester,
            CoreScrollbarStyle.defaultHoverThumbColor,
          );
          final thumb = _over(ink, surface);
          final frame = await _render(tester);

          const gap = (_kInset * 2 + _kThickness - _kHoverThickness) ~/ 2;
          const left = _kSide - gap - _kHoverThickness;
          const right = _kSide - gap;
          const middle = _kInset + _kMinThumbLength ~/ 2;

          expect(gap, 1);
          expect(_pixel(frame, left.toInt(), middle), _isColor(thumb));
          expect(_pixel(frame, right.toInt() - 1, middle), _isColor(thumb));
          // One pixel of gap left at the edge, and the content side starts
          // right where the thumb does.
          expect(_pixel(frame, _kSide.toInt() - 1, middle), _isColor(surface));
          expect(_pixel(frame, left.toInt() - 1, middle), _isColor(surface));
          // Where the resting thumb's gap was, there is now thumb: this is
          // the pixel that tells "grew into the gap" from "grew sideways".
          expect(
            _pixel(frame, _kSide.toInt() - _kInset, middle),
            _isColor(thumb),
          );
        },
        variant: TargetPlatformVariant.desktop(),
      );
    });
  }

  // The control for the capsule checks above. A check that cannot fail says
  // nothing, so this shows the same pixel reads as a rectangle when the thumb
  // is asked to be one.
  testWidgets(
    'a square-cornered thumb fails the capsule check',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await _pumpBar(
        tester,
        controller,
        host: (c) => _flat(
          c,
          style: const CoreScrollbarStyle(
            thumbRadius: CoreBorderRadius.zero,
          ),
        ),
      );

      final surface = _resolved(
        tester,
        const CoreColor.token(CoreColors.surface),
      );
      final thumb = _over(
        _resolved(tester, CoreScrollbarStyle.defaultThumbColor),
        surface,
      );
      final frame = await _render(tester);

      expect(
        _coverage(
          _pixel(frame, _kSide.toInt() - _kInset - _kThickness, _kInset),
          surface: surface,
          thumb: thumb,
        ),
        greaterThan(1 - _kCornerCoverageCeiling),
      );
    },
    variant: TargetPlatformVariant.desktop(),
  );

  group('Scrollbar evidence images', () {
    final captureDir = Platform.environment[_kCaptureDirEnv];

    for (final dark in const [false, true]) {
      for (final hover in const [false, true]) {
        final name = '${dark ? 'dark' : 'light'}-${hover ? 'hover' : 'rest'}';

        testWidgets(
          'card $name',
          (tester) async {
            final controller = ScrollController();
            addTearDown(controller.dispose);
            await _pumpBar(tester, controller, host: _card, dark: dark);
            if (hover) {
              // The pointer goes where the thumb is inside the card: the
              // card's own padding and border shift it from the flat case.
              final origin = tester.getTopLeft(find.byType(Scrollbar));
              final gesture = await tester.createGesture(
                kind: ui.PointerDeviceKind.mouse,
              );
              await gesture.addPointer(location: const Offset(1, 1));
              addTearDown(gesture.removePointer);
              await gesture.moveTo(
                origin +
                    const Offset(
                      _kSide - _kInset - _kThickness / 2,
                      _kInset + _kMinThumbLength / 2,
                    ),
              );
              await tester.pump();
              await tester.pump(
                const Duration(
                  milliseconds: CoreScrollbarContract.hoverTransitionMs + 50,
                ),
              );
            }

            final frame = await _render(tester, scale: _kCaptureScale);
            // Not vacuous without the switch: the card must contain a thumb.
            final surface = _resolved(
              tester,
              const CoreColor.token(CoreColors.surface),
            );
            final thumbX =
                ((_kCardRadius +
                            _kSide -
                            _kInset -
                            _kThickness / 2 +
                            1 /* border */ ) *
                        _kCaptureScale)
                    .toInt();
            final thumbY =
                ((_kCardRadius + 1 + _kInset + _kMinThumbLength / 2) *
                        _kCaptureScale)
                    .toInt();
            expect(
              _pixel(frame, thumbX, thumbY),
              isNot(_isColor(surface)),
              reason: 'no thumb was painted inside the card',
            );

            if (captureDir == null) return;
            final image = (await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(_boundaryKey),
              );
              return await boundary.toImage(pixelRatio: _kCaptureScale);
            }))!;
            final png = (await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.png),
            ))!;
            Directory(captureDir).createSync(recursive: true);
            File(
              '$captureDir/flutter-$name.png',
            ).writeAsBytesSync(png.buffer.asUint8List());
          },
        );
      }
    }
  });
}
