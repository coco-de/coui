import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// A cast far enough from the preset's authored one that reading the
/// authored value by mistake cannot pass.
const CoreSurfaceTuning _kHeavyCast = CoreSurfaceTuning(
  shadowOffsetX: 6,
  shadowOffsetY: 6,
);

const CoreSurfaceTuning _kSquare = CoreSurfaceTuning(radiusCap: 0);

/// The size-scaling factor the pumped app resolved to.
///
/// A tuned offset is a *logical* length, so it scales on the way to paint
/// exactly like every other dimensional value. Reading the factor from the
/// tree rather than hardcoding it keeps these assertions true on whichever
/// platform default the harness picks.
double _scaling = 1;

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  CoreSurfaceTuning tuning = CoreSurfaceTuning.none,
  TargetPlatform platform = TargetPlatform.android,
}) => tester.pumpWidget(
  CoUIApp(
    theme: ThemeData.fromCore(
      CoreThemePresets.light,
    ).copyWith(platform: () => platform),
    surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
    surfaceTuning: tuning,
    home: Builder(
      builder: (context) {
        _scaling = Theme.of(context).scaling;

        return Center(child: child);
      },
    ),
  ),
);

Iterable<BorderRadius> _radii(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((d) => d.decoration)
    .whereType<BoxDecoration>()
    .map((d) => d.borderRadius)
    .whereType<BorderRadius>();

/// The translation every press-shift wrapper is carrying right now.
Iterable<Offset> _translations(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((c) => c.transform)
    .whereType<Matrix4>()
    .map((m) => Offset(m.storage[12], m.storage[13]));

void main() {
  group('a tuning changes what is painted', () {
    testWidgets('a squaring cap reaches a real corner', (tester) async {
      await _pump(
        tester,
        const Card(child: SizedBox(width: 80, height: 40)),
        tuning: _kSquare,
      );

      final corners = _radii(tester).toList();
      expect(corners, isNotEmpty, reason: 'nothing was painted to check');
      // Read off the painted decoration rather than the theme: a transport
      // that reached `ThemeData` and stopped there would satisfy a theme
      // assertion while the screen kept its rounded corners.
      for (final r in corners) {
        expect(r.topLeft.x, 0);
        expect(r.bottomRight.x, 0);
      }
    });

    testWidgets('the preset keeps its own corners when untuned', (
      tester,
    ) async {
      await _pump(tester, const Card(child: SizedBox(width: 80, height: 40)));

      // The counterweight to the test above: if corners were zero here too,
      // that test would pass for a reason that has nothing to do with
      // tuning.
      expect(
        _radii(tester).any((r) => r.topLeft.x > 0),
        isTrue,
      );
    });
  });

  group('the cast and the press it implies move together', () {
    testWidgets('a pressed control retreats by the tuned offset', (
      tester,
    ) async {
      await _pump(
        tester,
        Button(onPressed: () {}, child: const Text('Press')),
        tuning: _kHeavyCast,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Button)),
      );
      addTearDown(gesture.up);
      await tester.pumpAndSettle();

      // The press affordance derives from `shadowOffsetAdd` rather than
      // carrying its own number, so tuning the cast has to move the press
      // by the same distance. A tuning that reached the shadow and not the
      // press would leave a control that slides out from under its own
      // shadow.
      expect(
        _translations(tester),
        contains(Offset(6 * _scaling, 6 * _scaling)),
      );
    });

    testWidgets('the retreat happens on desktop too', (tester) async {
      // The squash is the *style's* affordance, not a platform
      // convention, and its Web twin is a global `:active` rule with no
      // platform gate. It used to ride `enableFeedback`, which defaults
      // to mobile-only — so on every desktop build the signature of this
      // style simply did not happen, and a desktop build is exactly what
      // the docs preview is.
      //
      // `flutter_test` defaults the platform to android, which is why
      // the case above passed while the screen showed nothing.
      await _pump(
        tester,
        Button(onPressed: () {}, child: const Text('Press')),
        tuning: _kHeavyCast,
        platform: TargetPlatform.macOS,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Button)),
      );
      addTearDown(gesture.up);
      await tester.pumpAndSettle();

      expect(
        _translations(tester),
        contains(Offset(6 * _scaling, 6 * _scaling)),
      );
    });

    testWidgets('an untuned control retreats by the authored offset', (
      tester,
    ) async {
      final authored = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.neoBrutalism,
      ).geometry.shadowOffsetAdd;
      expect(authored, isNotNull);

      await _pump(tester, Button(onPressed: () {}, child: const Text('P')));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Button)),
      );
      addTearDown(gesture.up);
      await tester.pumpAndSettle();

      expect(
        _translations(tester),
        contains(Offset(authored!.dx * _scaling, authored.dy * _scaling)),
      );
    });
  });
}

// The accessibility contract is deliberately not tested here. A widget test
// that pumped a tuning and then asserted the ring width off
// `CoreSurfaceRecipe.of(...)` would be comparing one constant to another
// with a rendered tree around it for decoration — it would pass whether or
// not tuning could reach `a11y`. That claim is pinned where it can actually
// fail: `coui_core/test/surface_tuning_test.dart`, against the folded
// recipe.
