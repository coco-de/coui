/// Mounted Native counterpart controls for the Web composition regression.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets(
      'MockupCode owns the inset over an outlined theme (${direction.name})',
      (tester) async {
        const inherited = CoreEdgeInsets.only(
          top: 32,
          right: 48,
          bottom: 64,
          left: 24,
        );
        const product = CoreEdgeInsets.directional(
          top: 4,
          bottom: 12,
          start: 16,
          end: 8,
        );
        const codeKey = ValueKey('code');
        const bareKey = ValueKey('bare');
        const contentKey = ValueKey('bare-content');
        await pumpTestApp(
          tester,
          const SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MockupCode(
                  key: codeKey,
                  lines: [
                    CoreCodeLine(text: 'first'),
                    CoreCodeLine(text: 'second', prefix: '2'),
                  ],
                  mockupCodeStyle: CoreMockupCodeStyle(padding: product),
                ),
                OutlinedContainer(
                  key: bareKey,
                  child: SizedBox(key: contentKey, width: 40, height: 24),
                ),
              ],
            ),
          ),
          textDirection: direction,
          componentTheme: const CoreComponentTheme(
            outlinedContainer: CoreOutlinedContainerTheme(
              style: CoreOutlinedContainerStyle(
                padding: inherited,
                borderColor: CoreColor.transparent,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final bare = tester.getRect(find.byKey(bareKey));
        final bareContent = tester.getRect(find.byKey(contentKey));
        // Positive fixture control: the primitive still inherits T unchanged.
        expect(bareContent.left - bare.left, 24);
        expect(bareContent.top - bare.top, 32);
        final frames = find.descendant(
          of: find.byKey(codeKey),
          matching: find.byType(OutlinedContainer),
        );
        expect(frames, findsOneWidget);
        final frame = tester.getRect(frames);
        final first = tester.getRect(find.text('first'));
        final last = tester.getRect(find.text('second'));
        final left = direction == TextDirection.ltr ? 16 : 8;
        final right = direction == TextDirection.ltr ? 8 : 16;
        expect(first.left - frame.left, left);
        expect(frame.right - first.right, right);
        expect(first.top - frame.top, 4);
        // Every line, including the final one, has its own bottom spacing4.
        expect(frame.bottom - last.bottom, 12 + 4);
        expect(find.text('2'), findsOneWidget);
      },
    );
  }
}
