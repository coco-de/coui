import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// A content surface (`Card`, `OutlinedContainer`) can state its own material.
///
/// The glass preset gives every surface the glass material, and a card inside
/// a glass app is one surface among them. `surfaceStyle` is how one card says
/// it is a different material — and the negative control in every case is the
/// sibling that says nothing, because "this card is opaque" and "something on
/// this card happens to be opaque" read the same until they sit side by side.

const _opaqueKey = ValueKey<String>('opaque');
const _glassKey = ValueKey<String>('glass');

/// The outer chrome `AnimatedContainer`'s decoration — the box that carries
/// the fill and the border — inside [scope].
BoxDecoration _chrome(WidgetTester tester, Finder scope) {
  final chrome = tester
      .widgetList<AnimatedContainer>(
        find.descendant(of: scope, matching: find.byType(AnimatedContainer)),
      )
      .first;
  return chrome.decoration! as BoxDecoration;
}

Finder _blurIn(Finder scope) =>
    find.descendant(of: scope, matching: find.byType(SurfaceBlur));

/// Reads one pixel of [boundary] back, as `0xAARRGGBB`.
Future<int> _pixel(WidgetTester tester, GlobalKey boundary, Offset at) async {
  final result = await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    final data = (await image.toByteData())!;
    final i = ((at.dy.round() * image.width) + at.dx.round()) * 4;
    final r = data.getUint8(i);
    final g = data.getUint8(i + 1);
    final b = data.getUint8(i + 2);
    final a = data.getUint8(i + 3);
    image.dispose();
    return (a << 24) | (r << 16) | (g << 8) | b;
  });
  return result!;
}

/// Each channel of [color] composited over an opaque [page].
int _over(Color color, Color page) {
  int ch(double c, double p) =>
      ((c * color.a + p * (1 - color.a)) * 255).round().clamp(0, 255);
  return (0xFF << 24) |
      (ch(color.r, page.r) << 16) |
      (ch(color.g, page.g) << 8) |
      ch(color.b, page.b);
}

/// Largest per-channel distance between two `0xAARRGGBB` pixels.
int _distance(int a, int b) {
  var worst = 0;
  for (final shift in const [16, 8, 0]) {
    final d = (((a >> shift) & 0xFF) - ((b >> shift) & 0xFF)).abs();
    if (d > worst) worst = d;
  }
  return worst;
}

void main() {
  group('Card inside a glass theme', () {
    testWidgets('names the baseline material and keeps none of the glass', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Column(
          mainAxisSize: .min,
          children: [
            Card(
              key: _opaqueKey,
              variant: .outlined,
              cardStyle: CoreCardStyle(surfaceStyle: .defaultStyle),
              body: Text('Opaque'),
            ),
            Card(key: _glassKey, variant: .outlined, body: Text('Glass')),
          ],
        ),
        surfaceStyle: .liquidGlass,
      );

      // The sibling that states nothing is the control: the same theme does
      // make a card glass, so the absence next to it means something.
      final glassBlur = tester.widget<SurfaceBlur>(
        _blurIn(find.byKey(_glassKey)),
      );
      expect(glassBlur.surfaceBlur, greaterThan(0));
      expect(glassBlur.surfaceSheen, isNotNull);
      expect(glassBlur.refraction, isNotNull);
      final glass = _chrome(tester, find.byKey(_glassKey));
      expect(
        glass.color!.a,
        lessThan(1),
        reason: 'glass lets the page through',
      );
      expect(
        (glass.border! as Border).top.color.a,
        0,
        reason: 'the material draws its own edge, so the resting stroke yields',
      );

      // No backdrop pass, no sheen, no bend — the whole material is gone,
      // not one term of it (the flat `surfaceBlur: 0` could only ever zero
      // the blur and left the sheen, the chroma lift and the dimming).
      expect(_blurIn(find.byKey(_opaqueKey)), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(_opaqueKey),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      final opaque = _chrome(tester, find.byKey(_opaqueKey));
      expect(opaque.color!.a, 1, reason: 'an opaque fill');
      final stroke = (opaque.border! as Border).top;
      expect(stroke.color.a, 1, reason: 'the resting stroke is kept');
      expect(stroke.width, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives the slot layout that resets the padding', (
      tester,
    ) async {
      // A card with slots hands its container a copy with the padding
      // zeroed. A copy that dropped the material would only show on this
      // path, not on a card built from a custom `child`.
      await pumpTestApp(
        tester,
        const Column(
          mainAxisSize: .min,
          children: [
            Card(
              key: _opaqueKey,
              cardStyle: CoreCardStyle(surfaceStyle: .defaultStyle),
              child: Text('Custom child'),
            ),
            Card(
              key: _glassKey,
              cardStyle: CoreCardStyle(surfaceStyle: .defaultStyle),
              header: Text('Header'),
              body: Text('Slots'),
            ),
          ],
        ),
        surfaceStyle: .liquidGlass,
      );
      expect(_blurIn(find.byKey(_opaqueKey)), findsNothing);
      expect(_blurIn(find.byKey(_glassKey)), findsNothing);
    });

    testWidgets('paints its own fill whatever sits behind it', (tester) async {
      // The strongest reading of "opaque": the pixel depends on the card and
      // not on the page. Read in paint, over a dark page so a glass card's
      // share of the page is large enough to measure.
      const page = Color(0xFF101010);
      final boundary = GlobalKey();
      tester.view.physicalSize = const Size(600, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        buildTestApp(
          RepaintBoundary(
            key: boundary,
            child: const ColoredBox(
              color: page,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  mainAxisSize: .min,
                  spacing: 24,
                  children: [
                    Card(
                      key: _opaqueKey,
                      cardStyle: CoreCardStyle(surfaceStyle: .defaultStyle),
                      child: SizedBox(width: 120, height: 80),
                    ),
                    Card(
                      key: _glassKey,
                      child: SizedBox(width: 120, height: 80),
                    ),
                  ],
                ),
              ),
            ),
          ),
          surfaceStyle: .liquidGlass,
        ),
      );
      await tester.pumpAndSettle();

      final origin = tester.getTopLeft(find.byKey(boundary));
      Future<int> centre(Key key) => _pixel(
        tester,
        boundary,
        tester.getCenter(find.byKey(key)) - origin,
      );

      final opaqueFill = _chrome(tester, find.byKey(_opaqueKey)).color!;
      final opaquePixel = await centre(_opaqueKey);
      final glassPixel = await centre(_glassKey);

      expect(
        _distance(opaquePixel, _over(opaqueFill, page)),
        lessThanOrEqualTo(2),
        reason: 'the opaque card is its fill, with nothing of the page in it',
      );
      expect(
        _distance(opaquePixel, glassPixel),
        greaterThan(16),
        reason: 'the sibling in the same theme did not become opaque',
      );
    });

    testWidgets('a theme can make cards opaque and an instance can undo it', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Column(
          mainAxisSize: .min,
          children: [
            Card(key: _opaqueKey, body: Text('From the theme')),
            Card(
              key: _glassKey,
              cardStyle: CoreCardStyle(surfaceStyle: .liquidGlass),
              body: Text('Instance wins'),
            ),
          ],
        ),
        componentTheme: const CoreComponentTheme(
          card: CoreCardTheme(
            style: CoreCardStyle(surfaceStyle: .defaultStyle),
          ),
        ),
        surfaceStyle: .liquidGlass,
      );
      expect(_blurIn(find.byKey(_opaqueKey)), findsNothing);
      expect(_blurIn(find.byKey(_glassKey)), findsOneWidget);
    });
  });

  group('a glass card inside an opaque theme', () {
    testWidgets('takes the whole glass material, bend included', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Column(
          mainAxisSize: .min,
          children: [
            Card(
              key: _glassKey,
              variant: .outlined,
              cardStyle: CoreCardStyle(surfaceStyle: .liquidGlass),
              body: Text('Glass'),
            ),
            Card(key: _opaqueKey, variant: .outlined, body: Text('Plain')),
          ],
        ),
      );
      final blur = tester.widget<SurfaceBlur>(_blurIn(find.byKey(_glassKey)));
      expect(blur.surfaceBlur, greaterThan(0));
      expect(blur.surfaceSheen, isNotNull);
      expect(
        blur.refraction,
        isNotNull,
        reason:
            'the bend is part of the glass material, and the surrounding '
            'theme states none to borrow it from',
      );
      expect(_chrome(tester, find.byKey(_glassKey)).color!.a, lessThan(1));
      expect(_blurIn(find.byKey(_opaqueKey)), findsNothing);
    });

    testWidgets('still yields to reduced transparency', (tester) async {
      await pumpTestApp(
        tester,
        const Card(
          key: _glassKey,
          cardStyle: CoreCardStyle(surfaceStyle: .liquidGlass),
          body: Text('Glass'),
        ),
        theme: const ThemeData(reduceTransparency: true),
      );
      expect(
        _chrome(tester, find.byKey(_glassKey)).color!.a,
        1,
        reason: 'an accessibility preference outranks a local material',
      );
      // The edge band is decoration on a boundary and stays; the backdrop
      // pass is the transparency and goes.
      final blur = tester.widget<SurfaceBlur>(_blurIn(find.byKey(_glassKey)));
      expect(blur.surfaceBlur, isNull);
      expect(blur.refraction, isNull);
      expect(
        find.descendant(
          of: find.byKey(_glassKey),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
    });
  });

  group('OutlinedContainer', () {
    testWidgets('carries the same override as the primitive it is', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Column(
          mainAxisSize: .min,
          children: [
            OutlinedContainer(
              key: _opaqueKey,
              containerStyle: CoreOutlinedContainerStyle(
                surfaceStyle: .defaultStyle,
              ),
              child: SizedBox(width: 80, height: 40),
            ),
            OutlinedContainer(
              key: _glassKey,
              child: SizedBox(width: 80, height: 40),
            ),
          ],
        ),
        surfaceStyle: .liquidGlass,
      );
      expect(_blurIn(find.byKey(_opaqueKey)), findsNothing);
      expect(_blurIn(find.byKey(_glassKey)), findsOneWidget);
    });

    testWidgets('resolves the named material and the ambient everything else', (
      tester,
    ) async {
      late ResolvedOutlinedContainer inherited;
      late ResolvedOutlinedContainer opaque;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            inherited = resolveOutlinedContainer(context);
            opaque = resolveOutlinedContainer(
              context,
              containerStyle: const CoreOutlinedContainerStyle(
                surfaceStyle: .defaultStyle,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
        surfaceStyle: .liquidGlass,
      );

      expect(inherited.surfaceBlur, greaterThan(0));
      expect(inherited.surfaceSaturation, greaterThan(1));
      expect(inherited.surfaceBackdropBrightness, lessThan(1));
      expect(inherited.surfaceSheen, isNotNull);
      expect(inherited.refraction, isNotNull);

      expect(opaque.surfaceBlur, isNull);
      // Identity is the statement "no chroma lift, no dimming": the baseline
      // material states neither, and a flat token reads back as 1.
      expect(
        opaque.surfaceSaturation ?? CoreSurfaceToken.identitySaturation,
        CoreSurfaceToken.identitySaturation,
      );
      expect(
        opaque.surfaceBackdropBrightness ?? CoreSurfaceToken.identityBrightness,
        CoreSurfaceToken.identityBrightness,
      );
      expect(opaque.surfaceSheen, isNull);
      expect(opaque.refraction, isNull);
      expect(opaque.backgroundColor.a, 1);
      // Only the material moved: the geometry the glass preset states is
      // still the surrounding theme's.
      expect(opaque.borderRadius, inherited.borderRadius);
      expect(opaque.padding, inherited.padding);
    });

    // One test per style rather than a loop inside one: the test shell keeps
    // the first tree's overlay entry, so a second pump in the same test
    // would re-run the first tree's builder.
    for (final style in CoreSurfaceStyleId.values) {
      testWidgets('leaves a surface that states nothing as it was ($style)', (
        tester,
      ) async {
        // The refraction used to be read from the theme by the widget; the
        // resolver settles it now. A surface with no `surfaceStyle` has to
        // get the very value it always did, in every style.
        late ResolvedOutlinedContainer resolved;
        late ThemeData theme;
        await pumpTestApp(
          tester,
          Builder(
            builder: (context) {
              theme = Theme.of(context);
              resolved = resolveOutlinedContainer(context);
              return const SizedBox.shrink();
            },
          ),
          // A real palette: the colour-bending presets read concrete values.
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: style,
        );
        expect(resolved.refraction, theme.surfaceRefraction);
      });
    }
  });
}
