import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  for (final angle in [0.0, math.pi / 2, math.pi, -math.pi / 4]) {
    for (final rating in [false, true]) {
      testWidgets('rotation $angle radians / rating=$rating', (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            rating
                ? StarRating(value: 1, max: 1, starRotation: angle)
                : Star(state: CoreStarState.filled, starRotation: angle),
            theme: ThemeData.fromCore(CoreThemePresets.light),
          ),
        );
        final decorations = tester
            .widgetList<Container>(find.byType(Container))
            .map((c) => c.decoration)
            .whereType<ShapeDecoration>()
            .where((d) => d.shape is StarBorder);
        expect(decorations, hasLength(1));
        final shape = decorations.single.shape as StarBorder;
        const bounds = Rect.fromLTWH(0, 0, 24, 24);
        final reference = shape.copyWith(rotation: 0).getOuterPath(bounds);
        final actual = shape.getOuterPath(bounds);
        final before = reference.computeMetrics().single;
        final after = actual.computeMetrics().single;
        for (final fraction in [0.0, 0.13, 0.37, 0.61, 0.89]) {
          final p = before
              .getTangentForOffset(before.length * fraction)!
              .position;
          final q = after
              .getTangentForOffset(after.length * fraction)!
              .position;
          final offset = p - bounds.center;
          final expected =
              bounds.center +
              Offset(
                offset.dx * math.cos(angle) - offset.dy * math.sin(angle),
                offset.dx * math.sin(angle) + offset.dy * math.cos(angle),
              );
          expect((q - expected).distance, lessThan(0.001));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
