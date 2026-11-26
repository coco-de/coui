// A Scrollbar (and the ScrollArea that composes it) is as wide as the width it
// is given — the same width the Web scroller fills as a block box.
//
// The painted bar used to hand its child to a loose Stack, which turned a
// tight width into "anything up to this much", so a vertical scroller inside
// `SizedBox(width: 260)` shrank to its widest line (about 48px for a column of
// short labels) while the Web twin stayed 260. The thumb then sat against the
// text instead of the edge of the box it was meant to bound.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const double _kBoxWidth = 260;

/// The width of the scrollable itself — the box the thumb is painted against
/// and the content is clipped to — as opposed to the widget that wraps it.
/// The two can differ: a wrapper can be told to fill while the scrollable
/// inside it was handed a looser width.
double _scrollerWidth(WidgetTester tester) {
  final scrollable = find.byType(Scrollable);
  expect(scrollable, findsOneWidget);

  return tester.getSize(scrollable).width;
}

Widget _labels() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [for (var i = 1; i <= 20; i += 1) Text('항목 $i')],
);

void main() {
  group('a scroller fills the width it is given', () {
    testWidgets('ScrollArea in a tight box is that box wide', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Center(
            child: SizedBox(
              width: _kBoxWidth,
              child: ScrollArea(
                scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 160),
                child: _labels(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(ScrollArea)).width, _kBoxWidth);
      expect(tester.getSize(find.byType(Scrollbar)).width, _kBoxWidth);
      expect(_scrollerWidth(tester), _kBoxWidth);
    });

    testWidgets('ScrollViewInterceptor over a ScrollArea changes nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Center(
            child: SizedBox(
              width: _kBoxWidth,
              child: ScrollViewInterceptor(
                child: ScrollArea(
                  scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 160),
                  child: _labels(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(ScrollArea)).width, _kBoxWidth);
      expect(_scrollerWidth(tester), _kBoxWidth);
    });

    testWidgets('a bare Scrollbar around a list is that box wide', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Center(
            child: SizedBox(
              width: 240,
              height: 160,
              child: Scrollbar(
                child: ListView.builder(
                  itemBuilder: (_, i) => Text('항목 $i'),
                  itemCount: 40,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(Scrollbar)).width, 240);
      expect(_scrollerWidth(tester), 240);
    });

    testWidgets('hidden visibility fills it too — the two branches agree', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Center(
            child: SizedBox(
              width: _kBoxWidth,
              child: ScrollArea(
                showScrollbar: false,
                scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 160),
                child: _labels(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(ScrollArea)).width, _kBoxWidth);
      expect(_scrollerWidth(tester), _kBoxWidth);
    });

    testWidgets('stretch in a Column fills the cross axis', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: _kBoxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScrollArea(
                  scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 160),
                  child: _labels(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(ScrollArea)).width, _kBoxWidth);
      expect(_scrollerWidth(tester), _kBoxWidth);
    });
  });

  group('a scroller with room to spare still sizes to its content', () {
    testWidgets('under loose constraints the width is the widest line', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Align(
            alignment: Alignment.topLeft,
            child: ScrollArea(
              scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 160),
              child: _labels(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final width = tester.getSize(find.byType(ScrollArea)).width;
      expect(width, greaterThan(0));
      expect(width, lessThan(_kBoxWidth));
    });
  });
}
