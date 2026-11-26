// The rim is the one part of the glass edge whose brightness depends on
// where on the contour a pixel sits. A test that reads the resolved value
// can see that a rim was carried; only a rendered pixel can see that it
// peaked on the corner that faces the light.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = CoreSurfaceEdgeBevel(
  thickness: 2,
  lightAngle: -45,
  lightIntensity: 0.8,
  rimWidth: 2,
  rimIntensity: 1,
);

/// Paints and reads back in one real-async hop. Both the rasterisation and
/// the readback are engine futures, which never complete under the test
/// binding's fake clock — so both happen inside `runAsync`, and what comes
/// out is plain bytes.
Future<({ByteData bytes, int width})> _paint(
  WidgetTester tester,
  SurfaceSheenPainter painter,
  Size size,
) async {
  final result = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF000000),
    );
    painter.paint(canvas, size);
    final image = await recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
    final bytes = (await image.toByteData())!;
    image.dispose();

    return (bytes: bytes, width: size.width.round());
  });

  return result!;
}

int _redAt(({ByteData bytes, int width}) image, int x, int y) =>
    image.bytes.getUint8(((y * image.width) + x) * 4);

SurfaceSheenPainter _rimOnly(CoreSurfaceEdgeBevel profile) =>
    SurfaceSheenPainter(
      radius: BorderRadius.circular(30),
      width: 0,
      lightColor: const Color(0x00000000),
      darkColor: const Color(0x00000000),
      fade: 0.18,
      rimWidth: 2,
      rimColor: const Color(0xFFFFFFFF),
      rimProfile: profile,
    );

void main() {
  group('the rim reaches the pixels', () {
    testWidgets('and peaks on the corner that faces the light', (tester) async {
      // A pill, so the corner arcs are wide enough to land a sample on.
      // White rim over black; the red channel is the rim's opacity.
      const size = Size(160, 60);
      final image = await _paint(tester, _rimOnly(_profile), size);

      // The top-left arc's 45° point, one pixel inside the stroke: the
      // light comes from upper-left, so this is the peak. Its mirror on
      // the bottom-right arc is the trough's counter share.
      const r = 30.0;
      const inset = r - 1.0;
      final upperLeft = _redAt(
        image,
        (r - (inset * 0.7071)).round(),
        (r - (inset * 0.7071)).round(),
      );
      final lowerRight = _redAt(
        image,
        (size.width - r + (inset * 0.7071)).round(),
        (size.height - r + (inset * 0.7071)).round(),
      );
      // The straight top edge, mid-run.
      final top = _redAt(image, 80, 1);

      expect(upperLeft, greaterThan(200), reason: 'the lit corner is dark');
      expect(
        lowerRight,
        lessThan(upperLeft ~/ 2),
        reason: 'the far corner is as bright as the lit one',
      );
      expect(
        top,
        greaterThan(lowerRight),
        reason: 'a lit edge is dimmer than the far corner',
      );
      expect(
        top,
        lessThan(upperLeft),
        reason: 'a lit edge outshines the lit corner',
      );
    });

    testWidgets('and a profile with no rim paints none', (tester) async {
      const size = Size(160, 60);
      final image = await _paint(
        tester,
        _rimOnly(_profile.copyWith(rimIntensity: 0)),
        size,
      );

      expect(_redAt(image, 9, 9), 0);
    });
  });

  group('the resolver carries it', () {
    Future<ThemeData> themeUnder(
      WidgetTester tester,
      CoreSurfaceStyleId style,
    ) async {
      late ThemeData theme;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: style,
          home: Builder(
            builder: (context) {
              theme = Theme.of(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      return theme;
    }

    testWidgets('from the shipped glass, in the highlight colour', (
      tester,
    ) async {
      final theme = await themeUnder(tester, CoreSurfaceStyleId.liquidGlass);
      final highlight = theme.colorScheme
          .resolve(const CoreColor.token(CoreColors.surfaceHighlight))
          .toValue();

      for (final role in CoreSurfaceRole.values) {
        final sheen = resolveSurfaceSheen(theme, role: role)!;

        expect(sheen.rimWidth, greaterThan(0), reason: role.name);
        expect(sheen.rimColor, highlight, reason: role.name);
        expect(sheen.rimProfile?.drawsRim, isTrue, reason: role.name);
      }
    });

    testWidgets('and not from a style that states no wall', (tester) async {
      final theme = await themeUnder(tester, CoreSurfaceStyleId.claymorphism);
      final sheen = resolveSurfaceSheen(theme);

      expect(sheen?.rimWidth ?? 0, 0);
      expect(sheen?.rimProfile, isNull);
    });
  });
}
