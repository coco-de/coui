import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kStartOffset = 10.0;
const _kEndOffset = 20.0;
const _kItemCount = 50;
const _kItemHeight = 40.0;
const _kContainerHeight = 200.0;
const _kScrollDelta = 300.0;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(data: const ThemeData(), child: child),
  );
}

// Non-scrolling content for `FadeScroll`, which provides its own
// `SingleChildScrollView` internally — the child must NOT itself scroll.
Widget _items(int count) => Column(
  children: [
    for (var i = 0; i < count; i++)
      SizedBox(height: _kItemHeight, child: Text('Item $i')),
  ],
);

void main() {
  group('FadeScroll', () {
    testWidgets('renders child widget', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(
          SizedBox(
            height: _kContainerHeight,
            child: FadeScroll(
              controller: controller,
              child: _items(_kItemCount),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FadeScroll), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('renders without shader when not scrollable', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(
          SizedBox(
            height: _kContainerHeight,
            child: FadeScroll(
              controller: controller,
              child: const Column(children: [Text('Only item')]),
            ),
          ),
        ),
      );
      await tester.pump();

      // With non-scrollable content, no ShaderMask is needed.
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('shows fade effect when content is scrollable', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(
          SizedBox(
            height: _kContainerHeight,
            child: FadeScroll(
              controller: controller,
              child: _items(_kItemCount),
            ),
          ),
        ),
      );
      await tester.pump();

      // Trigger a scroll notification so the ListenableBuilder rebuilds.
      controller.jumpTo(1);
      await tester.pump();

      // Content exceeds container so end fade should be shown.
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('updates fade on scroll', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(
          SizedBox(
            height: _kContainerHeight,
            child: FadeScroll(
              controller: controller,
              child: _items(_kItemCount),
            ),
          ),
        ),
      );
      await tester.pump();

      // Scroll down to trigger both fades.
      controller.jumpTo(_kScrollDelta);
      await tester.pump();

      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('renders with custom start and end offsets', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(
          SizedBox(
            height: _kContainerHeight,
            child: FadeScroll(
              controller: controller,
              fadeScrollStyle: const CoreFadeScrollStyle(
                endOffset: _kEndOffset,
                startOffset: _kStartOffset,
              ),
              child: _items(_kItemCount),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FadeScroll), findsOneWidget);
    });

    testWidgets('renders with custom gradient colors', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(
          SizedBox(
            height: _kContainerHeight,
            child: FadeScroll(
              controller: controller,
              fadeScrollStyle: const CoreFadeScrollStyle(
                gradient: [CoreColor(0xFF000000), CoreColor(0x00000000)],
              ),
              child: _items(_kItemCount),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FadeScroll), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      const testKey = Key('fade-scroll-test');

      await tester.pumpWidget(
        _buildApp(
          SizedBox(
            height: _kContainerHeight,
            child: FadeScroll(
              key: testKey,
              controller: controller,
              child: const Column(children: [Text('content')]),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(testKey), findsOneWidget);
    });
  });
}
