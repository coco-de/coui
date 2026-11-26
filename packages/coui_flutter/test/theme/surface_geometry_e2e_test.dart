import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a hard-edged surface style states: square corners, and no border
/// thinner than 3.
const _brutal = CoreSurfaceGeometryConstraint(
  radiusCap: 0,
  strokeFloor: CoreStrokeWidth.stroke3,
);

ThemeData _theme({CoreSurfaceGeometryConstraint? geometry}) =>
    ThemeData.fromCore(CoreThemePresets.light).copyWith(
      geometry: () => geometry ?? const CoreSurfaceGeometryConstraint(),
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  CoreSurfaceGeometryConstraint? geometry,
}) => tester.pumpWidget(
  CoUIApp(
    theme: _theme(geometry: geometry),
    home: Center(child: child),
  ),
);

/// Every `BoxDecoration` painted in the tree, in paint order.
Iterable<BoxDecoration> _decorations(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((d) => d.decoration)
    .whereType<BoxDecoration>();

double? _maxCorner(BorderRadiusGeometry? radius) {
  if (radius is! BorderRadius) return null;

  return [
    radius.topLeft.x,
    radius.topRight.x,
    radius.bottomLeft.x,
    radius.bottomRight.x,
  ].reduce((a, b) => a > b ? a : b);
}

void main() {
  group('the axis reaches painted geometry, not just the theme', () {
    testWidgets('the shared surface primitive squares its corners', (
      tester,
    ) async {
      // This is the path most components compose through, so if the axis
      // could only reach one thing it should reach this.
      await _pump(
        tester,
        const OutlinedContainer(child: SizedBox(width: 40, height: 40)),
        geometry: _brutal,
      );

      final rounded = _decorations(
        tester,
      ).map((d) => _maxCorner(d.borderRadius)).whereType<double>();

      expect(rounded, isNotEmpty, reason: 'nothing painted a radius');
      expect(
        rounded.every((r) => r == 0),
        isTrue,
        reason: 'a corner survived the cap: $rounded',
      );
    });

    testWidgets('a component that paints its own box is reached too', (
      tester,
    ) async {
      // Badge is one of the ~77 components that build a `BoxDecoration`
      // directly rather than composing the shared primitive. Those are the
      // ones a style silently misses, producing a screen where a handful of
      // components changed and the rest did not.
      await _pump(
        tester,
        const Badge(child: Text('9')),
        geometry: _brutal,
      );

      final rounded = _decorations(
        tester,
      ).map((d) => _maxCorner(d.borderRadius)).whereType<double>();

      expect(rounded, isNotEmpty);
      expect(
        rounded.every((r) => r == 0),
        isTrue,
        reason: 'an escape-hatch component kept its radius: $rounded',
      );
    });

    testWidgets('a composed component inherits through its nested style', (
      tester,
    ) async {
      await _pump(
        tester,
        const Card(child: SizedBox(width: 80, height: 40)),
        geometry: _brutal,
      );

      final rounded = _decorations(
        tester,
      ).map((d) => _maxCorner(d.borderRadius)).whereType<double>();

      expect(rounded, isNotEmpty);
      expect(rounded.every((r) => r == 0), isTrue, reason: '$rounded');
    });
  });

  group('stroke floors reach painted borders', () {
    testWidgets('a drawn border is raised to the floor', (tester) async {
      await _pump(
        tester,
        const OutlinedContainer(child: SizedBox(width: 40, height: 40)),
        geometry: _brutal,
      );

      final widths = _decorations(
        tester,
      ).map((d) => d.border?.top.width).whereType<double>().where((w) => w > 0);

      expect(widths, isNotEmpty, reason: 'nothing painted a border');
      expect(
        widths.every((w) => w >= CoreStrokeWidth.stroke3),
        isTrue,
        reason: 'a border stayed under the floor: $widths',
      );
    });
  });

  group('the default surface is untouched', () {
    testWidgets('identity geometry paints the original radii', (tester) async {
      // The regression that matters most: every app not opting in must
      // render exactly as before.
      await _pump(
        tester,
        const Card(child: SizedBox(width: 80, height: 40)),
      );

      final rounded = _decorations(
        tester,
      ).map((d) => _maxCorner(d.borderRadius)).whereType<double>();

      expect(rounded, isNotEmpty);
      expect(
        rounded.any((r) => r > 0),
        isTrue,
        reason: 'the default surface lost its rounding',
      );
    });
  });
}
