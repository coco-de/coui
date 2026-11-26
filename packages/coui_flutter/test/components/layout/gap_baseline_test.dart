import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/gap/render_gap.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderFlex;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('Gap in a baseline row', () {
    // A parent that lays a row out dry — a `Table` cell aligned on the
    // baseline, an intrinsic-sized ancestor — asks it for its dry baseline,
    // and the row asks every child. A render object that leaves
    // `computeDryBaseline` alone throws "does not implement" there. The
    // figure-and-unit row of a `Stat` is this shape.
    testWidgets('a baseline Row holding a Gap answers a dry baseline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: material.TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                material.Text('12,480'),
                Gap(gapStyle: CoreGapStyle(size: CoreSpace.space4)),
                material.Text('명'),
              ],
            ),
          ),
        ),
      );

      final row = tester.renderObject<RenderFlex>(find.byType(Row));
      final dry = row.getDryBaseline(
        row.constraints,
        material.TextBaseline.alphabetic,
      );

      expect(tester.takeException(), isNull);
      expect(dry, isNotNull);
      expect(dry, isPositive);
    });

    test('RenderGap has no baseline of its own', () {
      final gap = RenderGap(mainAxisExtent: 4);

      expect(
        gap.getDryBaseline(
          const BoxConstraints(),
          material.TextBaseline.alphabetic,
        ),
        isNull,
      );
    });
  });
}
