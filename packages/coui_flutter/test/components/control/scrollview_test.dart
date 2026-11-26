import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kItemCount = 20;
const _kItemHeight = 50.0;

void main() {
  group('ScrollViewInterceptor', () {
    testWidgets('renders child widget', (tester) async {
      await pumpTestApp(
        tester,
        ScrollViewInterceptor(
          child: ListView.builder(
            itemBuilder: (_, index) => SizedBox(
              height: _kItemHeight,
              child: Text('Item $index'),
            ),
            itemCount: _kItemCount,
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('renders with enabled false', (tester) async {
      await pumpTestApp(
        tester,
        ScrollViewInterceptor(
          enabled: false,
          child: ListView.builder(
            itemBuilder: (_, index) => SizedBox(
              height: _kItemHeight,
              child: Text('Item $index'),
            ),
            itemCount: _kItemCount,
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('defaults to enabled true', (tester) async {
      await pumpTestApp(
        tester,
        const ScrollViewInterceptor(child: SizedBox()),
      );

      expect(find.byType(ScrollViewInterceptor), findsOneWidget);
    });
  });
}
