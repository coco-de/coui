import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The alpha the surface primitive actually painted, read off the box.
///
/// Read from the rendered decoration rather than from the resolver's
/// return value, because the question is whether the role reached paint.
/// This kit has shipped an axis that resolved correctly and was then
/// covered — a resolver assertion cannot tell those apart.
double _paintedAlpha(WidgetTester tester, Finder scope) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(of: scope, matching: find.byType(AnimatedContainer)).first,
  );
  final decoration = container.decoration! as BoxDecoration;

  return decoration.color!.a;
}

Future<void> _pumpUnder(
  WidgetTester tester,
  CoreSurfaceStyleId style,
  Widget child,
) async {
  await tester.pumpWidget(
    CoUIApp(
      surfaceStyle: style,
      home: Align(child: child),
      theme: ThemeData.fromCore(CoreThemePresets.light),
    ),
  );
  await tester.pump();
}

/// Alpha comparison slack. The fill is composed through a colour, so an
/// exact `==` would be asserting the arithmetic rather than the reach.
const double _kAlphaSlack = 0.001;

void main() {
  group('a composed box draws the layer its host declared', () {
    testWidgets('glass: the two roles land on the same translucent fill', (
      tester,
    ) async {
      // Both cards are the same widget with the same style; the only
      // difference is the word each says about where it sits — and under
      // the shipped glass that word changes nothing about the material.
      // A card in the page and a panel floating over it are both glass,
      // by decision: the two-material look (solid card, glass panel) read
      // as a bar treatment rather than a style and was reversed. This
      // pins that both fills are translucent *and* equal, so neither role
      // can drift back to opaque on its own.
      await _pumpUnder(
        tester,
        .liquidGlass,
        const Column(
          children: [
            Card(key: ValueKey('content'), body: Text('in the page')),
            Card(
              key: ValueKey('functional'),
              body: Text('over the page'),
              role: .functional,
            ),
          ],
        ),
      );

      final content = _paintedAlpha(
        tester,
        find.byKey(const ValueKey('content')),
      );
      final floating = _paintedAlpha(
        tester,
        find.byKey(const ValueKey('functional')),
      );

      expect(content, lessThan(1.0), reason: 'the in-page card is glass');
      expect(
        floating,
        closeTo(content, 0.01),
        reason: 'the two roles are one material under this style',
      );
    });

    for (final style in const [
      CoreSurfaceStyleId.defaultStyle,
      CoreSurfaceStyleId.neoBrutalism,
      CoreSurfaceStyleId.claymorphism,
      CoreSurfaceStyleId.neumorphism,
    ]) {
      testWidgets('${style.name}: the flip changes nothing', (tester) async {
        // The acceptance condition, read off the paint rather than argued
        // from the recipe: a preset that states one material has to draw
        // both roles identically, or this story moved pixels on four
        // presets it promised not to touch.
        await _pumpUnder(
          tester,
          style,
          const Column(
            children: [
              Card(key: ValueKey('content'), body: Text('in the page')),
              Card(
                key: ValueKey('functional'),
                body: Text('over the page'),
                role: .functional,
              ),
            ],
          ),
        );

        expect(
          _paintedAlpha(tester, find.byKey(const ValueKey('functional'))),
          _paintedAlpha(tester, find.byKey(const ValueKey('content'))),
        );
      });
    }
  });

  group('the hover card panel floats', () {
    testWidgets('its card is handed the floating material', (tester) async {
      // #4354 found this one: the panel is mounted by the overlay handler
      // and was drawing the content-layer fill, because the `Card` it
      // composes had no way to be told otherwise. Read through the same
      // composition the widget uses, so a future refactor that stops
      // passing the role fails here rather than on someone's screen.
      await _pumpUnder(
        tester,
        .liquidGlass,
        const Card(
          key: ValueKey('panel'),
          body: Text('bio'),
          role: .functional,
        ),
      );

      final theme = ThemeData.fromCore(CoreThemePresets.light);
      final glass = applySurfaceStyle(
        theme,
        surfaceStyle: .liquidGlass,
        highContrast: false,
      );

      expect(
        _paintedAlpha(tester, find.byKey(const ValueKey('panel'))),
        closeTo(
          glass.surfaceFor(.functional)!.opacityIn(glass),
          _kAlphaSlack,
        ),
      );
    });
  });
}
