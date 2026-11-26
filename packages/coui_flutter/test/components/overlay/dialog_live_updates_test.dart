import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'open dialog updates slots and action callbacks without losing input',
    (
      tester,
    ) async {
      final revision = ValueNotifier(0);
      final controller = material.TextEditingController();
      final focus = material.FocusNode();
      var activated = -1;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: ValueListenableBuilder<int>(
              valueListenable: revision,
              builder: (_, value, _) => Dialog(
                title: Text('title $value'),
                leading: Text('L$value', style: const TextStyle(fontSize: 12)),
                trailing: Text('R$value', style: const TextStyle(fontSize: 12)),
                content: material.Material(
                  child: material.Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('body $value'),
                      material.TextField(
                        controller: controller,
                        focusNode: focus,
                      ),
                    ],
                  ),
                ),
                actions: [
                  material.Material(
                    child: material.TextButton(
                      onPressed: value == 1 ? null : () => activated = value,
                      child: Text('action $value'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('title 0'), findsOneWidget);
      await tester.tap(find.byType(material.TextField));
      await tester.enterText(find.byType(material.TextField), 'preserved');
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      revision.value = 1;
      await tester.pumpAndSettle();
      expect(find.text('title 1'), findsOneWidget);
      expect(find.text('L1'), findsOneWidget);
      expect(find.text('R1'), findsOneWidget);
      expect(find.text('body 1'), findsOneWidget);
      expect(find.text('action 1'), findsOneWidget);
      expect(
        tester
            .widget<material.TextButton>(find.byType(material.TextButton))
            .onPressed,
        isNull,
      );
      expect(controller.text, 'preserved');
      expect(focus.hasFocus, isTrue);
      revision.value = 2;
      await tester.pumpAndSettle();
      expect(find.text('action 2'), findsOneWidget);
      expect(controller.text, 'preserved');
      expect(focus.hasFocus, isTrue);
      await tester.tap(find.text('action 2'));
      expect(activated, 2);
      await tester.pumpWidget(const material.SizedBox());
      controller.dispose();
      focus.dispose();
      revision.dispose();
    },
  );

  testWidgets(
    'closing and reopening does not let the old route close the new one',
    (
      tester,
    ) async {
      final open = ValueNotifier(true);
      final revision = ValueNotifier(0);
      var closes = 0;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: ValueListenableBuilder<bool>(
              valueListenable: open,
              builder: (_, isOpen, _) => ValueListenableBuilder<int>(
                valueListenable: revision,
                builder: (_, value, _) => Dialog(
                  open: isOpen,
                  onClose: () => closes++,
                  content: Text('body $value'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      open.value = false;
      await tester.pump();
      open.value = true;
      await tester.pump();
      await tester.pumpAndSettle();
      expect(closes, 0);
      expect(find.text('body 0'), findsOneWidget);
      revision.value = 1;
      await tester.pumpAndSettle();
      expect(find.text('body 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const material.SizedBox());
      await tester.pumpAndSettle();
      open.dispose();
      revision.dispose();
    },
  );

  testWidgets('removing the owner while an update is pending is safe', (
    tester,
  ) async {
    final revision = ValueNotifier(0);
    await tester.pumpWidget(
      material.MaterialApp(
        home: Theme(
          data: const ThemeData(),
          child: ValueListenableBuilder<int>(
            valueListenable: revision,
            builder: (_, value, _) => Dialog(content: Text('body $value')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    revision.value = 1;
    await tester.pumpWidget(const material.SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    revision.dispose();
  });
}
