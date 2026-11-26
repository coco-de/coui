import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Red at the top, blue at the bottom, opaque.
const _redToBlue = CoreGradient(
  type: CoreGradientType.linear,
  colors: [CoreColor(0xFFFF0000), CoreColor(0xFF0000FF)],
  stops: [0, 1],
  begin: CoreAlignment.topCenter,
  end: CoreAlignment.bottomCenter,
);

const _tokenStops = CoreGradient(
  type: CoreGradientType.linear,
  colors: [
    CoreColor.token(CoreColors.surface),
    CoreColor.token(CoreColors.onSurface),
  ],
  begin: CoreAlignment.topCenter,
  end: CoreAlignment.bottomCenter,
);

Widget _app(Widget child, {CoreThemeData? theme}) => CoUIApp(
  theme: ThemeData.fromCore(theme ?? CoreThemePresets.light),
  home: child,
);

Future<ResolvedOutlinedContainer> _resolve(
  WidgetTester tester,
  CoreOutlinedContainerStyle style, {
  bool dark = false,
}) async {
  late ResolvedOutlinedContainer resolved;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: ThemeData(
          colorScheme: dark
              ? CoreThemePresets.darkColorScheme
              : CoreThemePresets.lightColorScheme,
        ),
        child: Builder(
          builder: (context) {
            resolved = resolveOutlinedContainer(context, containerStyle: style);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return resolved;
}

/// The decoration the primitive paints its chrome with — the outer
/// `AnimatedContainer`, the one that carries the fill, border and shadow.
BoxDecoration _bodyDecoration(WidgetTester tester) {
  final body = tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .first;
  return body.decoration! as BoxDecoration;
}

void main() {
  group('resolveOutlinedContainer — backgroundGradient', () {
    testWidgets('absent by default: nothing changes for other components', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        const CoreOutlinedContainerStyle(
          backgroundColor: CoreColor(0xFF112233),
        ),
      );
      expect(resolved.backgroundGradient, isNull);
      expect(resolved.backgroundColor, const Color(0xFF112233));
    });

    testWidgets('a stated gradient is carried paint-ready', (tester) async {
      final resolved = await _resolve(
        tester,
        const CoreOutlinedContainerStyle(backgroundGradient: _redToBlue),
      );
      final gradient = resolved.backgroundGradient! as LinearGradient;
      expect(gradient.colors, const [Color(0xFFFF0000), Color(0xFF0000FF)]);
      expect(gradient.stops, const [0.0, 1.0]);
      expect(gradient.begin, AlignmentDirectional.topCenter);
      expect(gradient.end, AlignmentDirectional.bottomCenter);
    });

    testWidgets('token stops resolve through the active scheme', (
      tester,
    ) async {
      final light = await _resolve(
        tester,
        const CoreOutlinedContainerStyle(backgroundGradient: _tokenStops),
      );
      final dark = await _resolve(
        tester,
        const CoreOutlinedContainerStyle(backgroundGradient: _tokenStops),
        dark: true,
      );
      final lightColors = (light.backgroundGradient! as LinearGradient).colors;
      final darkColors = (dark.backgroundGradient! as LinearGradient).colors;
      expect(lightColors, isNot(darkColors));
      // Light's first stop is its surface; dark's is dark's own.
      expect(lightColors.first, light.backgroundColor);
      expect(darkColors.first, dark.backgroundColor);
    });

    testWidgets('surfaceOpacity scales the alpha of every stop', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        const CoreOutlinedContainerStyle(
          backgroundGradient: _redToBlue,
          surfaceOpacity: 0.5,
        ),
      );
      final colors = (resolved.backgroundGradient! as LinearGradient).colors;
      expect(colors, hasLength(2));
      for (final c in colors) {
        expect(c.a, closeTo(0.5, 1 / 255));
      }
      // The channels are untouched — only the alpha moves.
      expect(colors.first.r, closeTo(1, 1e-9));
      expect(colors.last.b, closeTo(1, 1e-9));
    });
  });

  group('OutlinedContainer — backgroundGradient', () {
    testWidgets('the gradient is painted instead of the colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Align(
            alignment: Alignment.topLeft,
            child: OutlinedContainer(
              containerStyle: CoreOutlinedContainerStyle(
                backgroundColor: CoreColor(0xFF00FF00),
                backgroundGradient: _redToBlue,
                width: 40,
                height: 40,
              ),
            ),
          ),
        ),
      );
      final decoration = _bodyDecoration(tester);
      expect(decoration.gradient, isA<LinearGradient>());
      // Not layered over the solid.
      expect(decoration.color, isNull);
    });

    testWidgets('without a gradient the solid is painted, as before', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Align(
            alignment: Alignment.topLeft,
            child: OutlinedContainer(
              containerStyle: CoreOutlinedContainerStyle(
                backgroundColor: CoreColor(0xFF00FF00),
                width: 40,
                height: 40,
              ),
            ),
          ),
        ),
      );
      final decoration = _bodyDecoration(tester);
      expect(decoration.gradient, isNull);
      expect(decoration.color, const Color(0xFF00FF00));
    });

    testWidgets('a dashed border keeps the gradient fill', (tester) async {
      await tester.pumpWidget(
        _app(
          const Align(
            alignment: Alignment.topLeft,
            child: OutlinedContainer(
              containerStyle: CoreOutlinedContainerStyle(
                backgroundGradient: _redToBlue,
                borderStyle: CoreOutlinedContainerBorderStyle.dashed,
                width: 40,
                height: 40,
              ),
            ),
          ),
        ),
      );
      expect(_bodyDecoration(tester).gradient, isA<LinearGradient>());
      // The dash painter draws the border only, over the body.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('a blurred surface keeps the gradient fill', (tester) async {
      await tester.pumpWidget(
        _app(
          const Align(
            alignment: Alignment.topLeft,
            child: OutlinedContainer(
              containerStyle: CoreOutlinedContainerStyle(
                backgroundGradient: _redToBlue,
                surfaceBlur: 4,
                width: 40,
                height: 40,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(_bodyDecoration(tester).gradient, isA<LinearGradient>());
    });

    testWidgets('the painted pixels follow the gradient, top to bottom', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: const OutlinedContainer(
                containerStyle: CoreOutlinedContainerStyle(
                  backgroundGradient: _redToBlue,
                  borderColor: CoreColor.transparent,
                  borderRadius: CoreBorderRadius.zero,
                  elevation: CoreOutlinedContainerElevation.none,
                  width: 80,
                  height: 80,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      late List<int> top;
      late List<int> bottom;
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = (await image.toByteData())!;
        List<int> at(int x, int y) {
          final i = (y * image.width + x) * 4;
          return [for (var c = 0; c < 4; c++) data.getUint8(i + c)];
        }

        top = at(40, 1);
        bottom = at(40, 78);
      });
      // Red (r high, b low) at the top, blue (r low, b high) at the bottom.
      expect(top[0], greaterThan(230));
      expect(top[2], lessThan(25));
      expect(bottom[0], lessThan(25));
      expect(bottom[2], greaterThan(230));
    });

    testWidgets('a faint solid does not dim the gradient painted instead', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: const OutlinedContainer(
                containerStyle: CoreOutlinedContainerStyle(
                  // A `Paint` carrying both a colour and a shader scales the
                  // shader by the colour's alpha, so a solid left in the
                  // decoration would wash the gradient out to a tenth.
                  backgroundColor: CoreColor(0x1AFF0000),
                  backgroundGradient: _redToBlue,
                  borderColor: CoreColor.transparent,
                  borderRadius: CoreBorderRadius.zero,
                  elevation: CoreOutlinedContainerElevation.none,
                  width: 80,
                  height: 80,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      late int bottomBlue;
      late int bottomAlpha;
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = (await image.toByteData())!;
        final i = (78 * image.width + 40) * 4;
        bottomBlue = data.getUint8(i + 2);
        bottomAlpha = data.getUint8(i + 3);
      });
      expect(bottomAlpha, 255);
      expect(bottomBlue, greaterThan(230));
    });
  });
}
