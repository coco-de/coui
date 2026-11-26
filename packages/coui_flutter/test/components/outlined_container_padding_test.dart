import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    for (final directional in [false, true]) {
      testWidgets(
        'four padding sides follow $direction directional=$directional',
        (tester) async {
          const root = Key('root');
          const content = Key('content');
          final insets = directional
              ? const CoreEdgeInsets.directional(
                  start: 4,
                  top: 8,
                  end: 16,
                  bottom: 24,
                )
              : const CoreEdgeInsets.fromLTRB(4, 8, 16, 24);
          await tester.pumpWidget(
            buildTestApp(
              SizedBox(
                key: root,
                width: 100,
                height: 100,
                child: OutlinedContainer(
                  containerStyle: CoreOutlinedContainerStyle(
                    borderColor: CoreColor.transparent,
                    padding: insets,
                  ),
                  child: const SizedBox.expand(key: content),
                ),
              ),
              textDirection: direction,
            ),
          );
          await tester.pumpAndSettle();
          final outer = tester.getRect(find.byKey(root));
          final inner = tester.getRect(find.byKey(content));
          final left = directional && direction == TextDirection.rtl
              ? 16.0
              : 4.0;
          final right = directional && direction == TextDirection.rtl
              ? 4.0
              : 16.0;
          expect(inner.left - outer.left, left);
          expect(inner.top - outer.top, 8);
          expect(outer.right - inner.right, right);
          expect(outer.bottom - inner.bottom, 24);
        },
      );
    }
  }
}
