import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _contentKey = ValueKey<String>('content');

Future<void> _hover(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(find.text('Target')));
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('HoverCard panel inset and width', () {
    testWidgets('the panel keeps a 16 inset with the edge painted inside it', (
      tester,
    ) async {
      late double scaling;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            scaling = Theme.of(context).scaling;
            return const HoverCard(
              content: Text('Panel', key: _contentKey),
              trigger: Text('Target'),
            );
          },
        ),
      );
      await _hover(tester);

      expect(find.byKey(_contentKey), findsOneWidget);
      // The outer rect of the composed `Popup`'s box — the `DecoratedBox`
      // that paints the border — not the layout wrapper around it.
      final panel = tester.getRect(
        find
            .descendant(
              of: find.byType(Popup),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final content = tester.getRect(find.byKey(_contentKey));

      // The `Popup` paints its border inside the box the padding insets, so
      // the content sits exactly the content preset (16) from the panel edge
      // on every side — not 16 plus the edge.
      final inset = CorePopupStyle.defaultContentPadding.left * scaling;
      expect(
        CorePopupStyle.defaultContentPadding,
        const CoreEdgeInsets.all(16),
      );
      expect(
        content.left - panel.left,
        moreOrLessEquals(inset, epsilon: 0.01),
      );
      expect(content.top - panel.top, moreOrLessEquals(inset, epsilon: 0.01));
    });

    testWidgets('a long line wraps at the 256 ceiling instead of overflowing', (
      tester,
    ) async {
      late double scaling;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            scaling = Theme.of(context).scaling;
            return HoverCard(
              content: Text('long ' * 80, key: _contentKey),
              trigger: const Text('Target'),
            );
          },
        ),
      );
      await _hover(tester);

      final panel = tester.getRect(
        find
            .descendant(
              of: find.byType(Popup),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );

      expect(
        panel.width,
        moreOrLessEquals(CoreSpace.space256 * scaling, epsilon: 0.01),
      );
    });

    testWidgets('a short line is not stretched to the Popup minimum', (
      tester,
    ) async {
      late double scaling;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            scaling = Theme.of(context).scaling;
            return const HoverCard(
              content: SizedBox(width: 24, height: 8, key: _contentKey),
              trigger: Text('Target'),
            );
          },
        ),
      );
      await _hover(tester);

      final panel = tester.getRect(
        find
            .descendant(
              of: find.byType(Popup),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );

      // 24 content + 2 × 16 inset: well under a bare Popup's 128.
      expect(CorePopupStyle.defaultMinWidth, 128);
      expect(
        panel.width,
        moreOrLessEquals((24 + 2 * 16) * scaling, epsilon: 0.01),
      );
    });
  });
}
