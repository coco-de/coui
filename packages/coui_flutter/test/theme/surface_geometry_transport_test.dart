import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const _square = CoreSurfaceGeometryConstraint(radiusCap: 0);

CoreThemeData _core({CoreSurfaceGeometryConstraint? geometry}) => CoreThemeData(
  colorScheme: CouiColorPresets.source.light(),
  brightness: CoreBrightness.light,
  designSystem: DesignSystem.coui,
  geometry: geometry ?? const CoreSurfaceGeometryConstraint(),
);

void main() {
  group('the constraint is inside theme equality', () {
    test('two themes differing only in geometry are unequal', () {
      // This is the failure the axis rule warns about, and the one no
      // screenshot explains: the constraint resolves correctly, the theme
      // compares equal to the previous one, the framework skips the
      // rebuild, and the screen never changes.
      //
      // It needs its own test because `CoreThemeData.==` is hand-written
      // and sits outside the contract guard, which only scans
      // `contracts/*_style.dart`.
      expect(_core(geometry: _square), isNot(equals(_core())));
      expect(
        _core(geometry: _square).hashCode,
        isNot(equals(_core().hashCode)),
      );
    });

    test('identical geometry still compares equal', () {
      expect(_core(geometry: _square), equals(_core(geometry: _square)));
    });

    test('copyWith carries it', () {
      expect(_core().copyWith(geometry: _square).geometry, _square);
    });
  });

  group('it reaches the Flutter theme', () {
    test('fromCore forwards the core value', () {
      // Without this the field would be a Core-only declaration that no
      // resolver could ever read — the shape both previous geometry axes
      // shipped in.
      expect(ThemeData.fromCore(_core(geometry: _square)).geometry, _square);
    });

    test('a theme stating nothing is identity', () {
      expect(ThemeData.fromCore(_core()).geometry.isIdentity, isTrue);
      expect(
        ThemeData.fromCore(CoreThemePresets.light).geometry.isIdentity,
        isTrue,
      );
    });

    test('copyWith on the Flutter theme carries it', () {
      final base = ThemeData.fromCore(_core());
      expect(base.copyWith(geometry: () => _square).geometry, _square);
    });
  });

  group('the app applies the active style', () {
    testWidgets('a style with no geometry leaves the theme untouched', (
      tester,
    ) async {
      late CoreSurfaceGeometryConstraint seen;

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Builder(
            builder: (context) {
              seen = Theme.of(context).geometry;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen.isIdentity, isTrue);
    });

    testWidgets('a style that states geometry reaches Theme.of', (
      tester,
    ) async {
      // Every shipped recipe is geometry-neutral today, so this asserts the
      // wiring through the recipe rather than a particular preset's values.
      late CoreSurfaceGeometryConstraint seen;

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: Builder(
            builder: (context) {
              seen = Theme.of(context).geometry;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        seen,
        equals(
          resolveThemeGeometry(surfaceStyle: CoreSurfaceStyleId.neoBrutalism),
        ),
      );
    });
  });

  group('the constraint survives the carrier the framework diffs', () {
    // The group above proves `CoreThemeData` compares on geometry. That is
    // the wrong carrier to stop at: the framework diffs the *Flutter*
    // `ThemeData`, and that one is a separate hand-written `==`. Checking
    // only the Core one is how a constraint can be correct in every value
    // test while never reaching a second frame.
    final base = ThemeData.fromCore(CoreThemePresets.light);
    final bent = base.copyWith(geometry: () => _square);

    test('two Flutter themes differing only in geometry are unequal', () {
      expect(base == bent, isFalse);
      expect(base.hashCode == bent.hashCode, isFalse);
    });

    test('a transition does not drop the constraint to identity', () {
      // Snapped rather than interpolated: the scalars are a cap and a floor
      // and both are nullable, so an absent bound has no numeric midpoint
      // with a present one. What must never happen is the constraint
      // vanishing for the duration of the transition.
      expect(ThemeData.lerp(base, bent, 1).geometry, _square);
      expect(ThemeData.lerp(base, bent, 0.9).geometry.isIdentity, isFalse);
      expect(ThemeData.lerp(base, bent, 0.1).geometry, base.geometry);
    });

    testWidgets('a geometry-only change notifies dependents', (tester) async {
      // The child instance is held constant on purpose. Rebuilding the app
      // around a descendant makes it rebuild whatever equality says, which
      // is why a test that swaps the style through a parent passes even
      // when equality is blind — it never exercises the inherited path.
      // Keeping the child identical leaves `updateShouldNotify` as the only
      // thing that can wake it, which is the path a real subtree takes
      // whenever the framework would otherwise skip it.
      const child = _GeometryDependent();
      final a = ThemeData.fromCore(CoreThemePresets.light);
      final b = a.copyWith(geometry: () => _square);

      await tester.pumpWidget(Theme(data: a, child: child));
      final buildsBefore = _dependentBuilds;
      expect(_dependentSaw!.isIdentity, isTrue);

      await tester.pumpWidget(Theme(data: b, child: child));

      expect(_dependentBuilds, greaterThan(buildsBefore));
      expect(_dependentSaw, _square);
    });
  });
}

int _dependentBuilds = 0;
CoreSurfaceGeometryConstraint? _dependentSaw;

class _GeometryDependent extends StatelessWidget {
  const _GeometryDependent();

  @override
  Widget build(BuildContext context) {
    _dependentBuilds++;
    _dependentSaw = Theme.of(context).geometry;

    return const SizedBox.shrink();
  }
}
