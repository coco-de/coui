import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final closeEarly in [false, true]) {
    testWidgets('toast cancels its timer after early close=$closeEarly', (
      tester,
    ) async {
      late BuildContext toastContext;
      await tester.pumpWidget(
        CoUIApp(
          theme: const ThemeData(),
          home: Builder(
            builder: (context) {
              toastContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final overlay = showToast(
        context: toastContext,
        builder: (_, _) => const Toast(message: 'Saved'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);

      if (closeEarly) {
        overlay.close();
        await tester.pumpAndSettle();
        expect(find.text('Saved'), findsNothing);
      } else {
        await tester.pumpWidget(const SizedBox.shrink());
      }
      expect(tester.takeException(), isNull);
      // Do not advance through the five-second timeout. The test binding's
      // pending-timer invariant must pass because disposal cancelled it.
    });
  }
}
