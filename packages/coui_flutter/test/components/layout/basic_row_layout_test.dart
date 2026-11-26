import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _leadingKey = ValueKey<String>('leading');
const _trailingKey = ValueKey<String>('trailing');

void main() {
  group('Basic row layout', () {
    Future<double> scalingOf(WidgetTester tester, Widget child) async {
      late double scaling;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            scaling = Theme.of(context).scaling;
            return child;
          },
        ),
      );
      return scaling;
    }

    testWidgets('leading and trailing sit 12 from the body', (tester) async {
      final scaling = await scalingOf(
        tester,
        const Basic(
          leading: Icon(LucideIcons.x, key: _leadingKey),
          title: Text('Title'),
          subtitle: Text('Subtitle'),
          trailing: Icon(LucideIcons.x, key: _trailingKey),
        ),
      );

      final leadingRight = tester.getTopRight(find.byKey(_leadingKey)).dx;
      final titleLeft = tester.getTopLeft(find.text('Title')).dx;
      final subtitleRight = tester.getTopRight(find.text('Subtitle')).dx;
      final titleRight = tester.getTopRight(find.text('Title')).dx;
      final trailingLeft = tester.getTopLeft(find.byKey(_trailingKey)).dx;
      final bodyRight = titleRight > subtitleRight ? titleRight : subtitleRight;

      expect(
        titleLeft - leadingRight,
        moreOrLessEquals(CoreSpace.space12 * scaling, epsilon: 0.01),
      );
      expect(
        trailingLeft - bodyRight,
        moreOrLessEquals(CoreSpace.space12 * scaling, epsilon: 0.01),
      );
    });

    testWidgets('leading and trailing are centered on the row, not its top', (
      tester,
    ) async {
      await scalingOf(
        tester,
        const Basic(
          leading: Icon(LucideIcons.x, key: _leadingKey),
          title: Text('Title'),
          subtitle: Text('Subtitle'),
          trailing: Icon(LucideIcons.x, key: _trailingKey),
        ),
      );

      final rowCenter = tester.getCenter(find.byType(Basic)).dy;

      expect(
        tester.getCenter(find.byKey(_leadingKey)).dy,
        moreOrLessEquals(rowCenter, epsilon: 0.01),
      );
      expect(
        tester.getCenter(find.byKey(_trailingKey)).dy,
        moreOrLessEquals(rowCenter, epsilon: 0.01),
      );
      // The body is taller than the glyph, so a top-aligned slot would sit
      // above the row's center.
      expect(
        tester.getSize(find.byType(Basic)).height,
        greaterThan(tester.getSize(find.byKey(_leadingKey)).height),
      );
    });
  });
}
