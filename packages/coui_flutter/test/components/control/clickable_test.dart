import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('Clickable', () {
    testWidgets('renders child widget', (tester) async {
      await pumpTestApp(
        tester,
        Clickable(
          onPressed: () {},
          child: const Text('Click Me'),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('fires onPressed callback on tap', (tester) async {
      var pressed = false;
      await pumpTestApp(
        tester,
        Clickable(
          onPressed: () => pressed = true,
          child: const Text('Tap'),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not fire onPressed when disabled', (tester) async {
      var pressed = false;
      await pumpTestApp(
        tester,
        Clickable(
          onPressed: () => pressed = true,
          enabled: false,
          child: const Text('Disabled'),
        ),
      );

      await tester.tap(find.text('Disabled'));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('does not fire when onPressed is null', (tester) async {
      await pumpTestApp(
        tester,
        const Clickable(child: Text('No Action')),
      );

      expect(find.text('No Action'), findsOneWidget);
    });
  });

  group('WidgetStatesController', () {
    test('starts with empty states', () {
      final controller = WidgetStatesController();

      expect(controller.value, isEmpty);

      controller.dispose();
    });

    test('update adds state', () {
      final controller = WidgetStatesController();

      controller.update(.hovered, true);

      expect(controller.value, contains(WidgetState.hovered));

      controller.dispose();
    });

    test('update removes state', () {
      final controller = WidgetStatesController({.hovered});

      controller.update(.hovered, false);

      expect(controller.value, isNot(contains(WidgetState.hovered)));

      controller.dispose();
    });
  });
}
