import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kItemCount = 50;
const _kItemHeight = 40.0;
const _kTestThickness = 8.0;
const _kTestRadius = 4.0;
const _kAltThickness = 10.0;

void main() {
  group('Scrollbar', () {
    testWidgets('renders with scrollable child', (tester) async {
      await pumpTestApp(
        tester,
        Scrollbar(
          child: ListView.builder(
            itemBuilder: (_, index) => SizedBox(
              height: _kItemHeight,
              child: Text('Item $index'),
            ),
            itemCount: _kItemCount,
          ),
        ),
      );

      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('renders with controller', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await pumpTestApp(
        tester,
        Scrollbar(
          controller: controller,
          child: ListView.builder(
            controller: controller,
            itemBuilder: (_, index) => SizedBox(
              height: _kItemHeight,
              child: Text('Item $index'),
            ),
            itemCount: _kItemCount,
          ),
        ),
      );

      expect(find.byType(Scrollbar), findsOneWidget);
    });

    testWidgets('renders with thumbVisibility', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await pumpTestApp(
        tester,
        Scrollbar(
          controller: controller,
          child: ListView.builder(
            controller: controller,
            itemBuilder: (_, index) => SizedBox(
              height: _kItemHeight,
              child: Text('Item $index'),
            ),
            itemCount: _kItemCount,
          ),
        ),
      );

      expect(find.byType(Scrollbar), findsOneWidget);
    });
  });
}
