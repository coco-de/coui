import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('CoreTimelineItem', () {
    test('stores title and leaves optional fields null', () {
      const item = CoreTimelineItem(title: 'Meeting');

      expect(item.title, equals('Meeting'));
      expect(item.description, isNull);
      expect(item.timestamp, isNull);
    });

    test('stores description and timestamp', () {
      const item = CoreTimelineItem(
        title: 'Meeting',
        description: 'Discuss roadmap',
        timestamp: '10:00 AM',
      );

      expect(item.description, equals('Discuss roadmap'));
      expect(item.timestamp, equals('10:00 AM'));
    });
  });

  group('Timeline', () {
    testWidgets('renders a single item with title/description/timestamp', (
      tester,
    ) async {
      // A single item renders no inter-item connector; the multi-item
      // geometry (connector included) is read in the group below.
      await tester.pumpWidget(
        _buildApp(
          const Timeline(
            items: [
              CoreTimelineItem(
                title: 'Code Review',
                description: 'Review pull requests.',
                timestamp: '2:00 PM',
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Timeline), findsOneWidget);
      expect(find.text('2:00 PM'), findsOneWidget);
      expect(find.text('Code Review'), findsOneWidget);
      expect(find.text('Review pull requests.'), findsOneWidget);
    });

    testWidgets('renders with empty items', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Timeline(items: [])),
      );
      await tester.pump();

      expect(find.byType(Timeline), findsOneWidget);
    });
  });

  group('Timeline geometry', () {
    // Titles are short on purpose: `flutter test` draws every glyph one em
    // wide (Ahem), so a longer title would wrap inside the 198-wide content
    // column and the "first line" would stop being the whole title. The
    // descriptions wrap, which is what the connector test needs.
    const items = [
      CoreTimelineItem(
        title: 'Created',
        timestamp: '2 hours ago',
        description: 'Welcome email sent to the address on file.',
      ),
      CoreTimelineItem(
        title: 'Updated',
        timestamp: '1 hour ago',
        description: 'Display name and avatar changed.',
      ),
    ];

    final boundary = GlobalKey();

    Future<void> pumpTimeline(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        buildTestApp(
          RepaintBoundary(
            key: boundary,
            child: const SizedBox(width: 360, child: Timeline(items: items)),
          ),
        ),
      );
      await tester.pump();
    }

    // The painted dots, in row order: the `DecoratedBox` inside each dot
    // `Container` (the `Container` itself also carries the top margin).
    List<Rect> dotRects(WidgetTester tester) => [
      for (final box in tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(Timeline),
          matching: find.byType(DecoratedBox),
        ),
      ))
        if (box.decoration case BoxDecoration(shape: BoxShape.circle))
          tester.getRect(find.byWidget(box)),
    ];

    /// One pixel of the timeline, `0xRRGGBB`, at [at] in global coordinates.
    Future<int> pixel(WidgetTester tester, Offset at) async {
      final origin = tester.getTopLeft(find.byKey(boundary));
      final local = at - origin;
      final rgb = await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final data = (await image.toByteData())!;
        final i = ((local.dy.floor() * image.width) + local.dx.floor()) * 4;
        final value =
            (data.getUint8(i) << 16) |
            (data.getUint8(i + 1) << 8) |
            data.getUint8(i + 2);
        image.dispose();
        return value;
      });
      return rgb!;
    }

    int schemeRgb(WidgetTester tester, CoreColor color) {
      final scheme = Theme.of(
        tester.element(find.byType(Timeline)),
      ).colorScheme;
      return scheme.resolve(color).toValue().toARGB32() & 0xFFFFFF;
    }

    testWidgets('the dot is a 10 circle seated 5 below the row top', (
      tester,
    ) async {
      await pumpTimeline(tester);

      final dots = dotRects(tester);
      expect(dots, hasLength(2));
      expect(dots[0].size, const Size(10, 10));

      final rowTop = tester.getTopLeft(find.byType(Timeline)).dy;
      expect(dots[0].top - rowTop, 5);
    });

    testWidgets('the dot centre meets the centre of the title first line', (
      tester,
    ) async {
      await pumpTimeline(tester);

      final dot = dotRects(tester).first;
      final title = tester.getRect(find.text('Created'));

      // The title is one `labelLarge` line: 14 × 1.4 = 19.6, which the text
      // engine lays out as a 20 px line. The dot margin is a whole px (5), so
      // the centres land within the half px the whole-px margin allows.
      expect(title.height, 20);
      expect((dot.center.dy - title.center.dy).abs(), lessThanOrEqualTo(0.5));
    });

    testWidgets('the dot column is as wide as the dot', (tester) async {
      await pumpTimeline(tester);

      final timelineLeft = tester.getTopLeft(find.byType(Timeline)).dx;
      final dot = dotRects(tester).first;
      final title = tester.getRect(find.text('Created'));

      // 120 timestamp column + 16 gap, then the dot column.
      expect(dot.left - timelineLeft, 136);
      // dot column (10) + 16 gap, then the content column — no title inset.
      expect(title.left - timelineLeft, 136 + 10 + 16);
      expect(title.left - dot.right, 16);
    });

    testWidgets('the title sits 2 above the description', (tester) async {
      await pumpTimeline(tester);

      final title = tester.getRect(find.text('Created'));
      final description = tester.getRect(
        find.text('Welcome email sent to the address on file.'),
      );

      expect(description.top - title.bottom, closeTo(2, 0.01));
    });

    testWidgets('the title is the labelLarge role, not a weight over body', (
      tester,
    ) async {
      await pumpTimeline(tester);

      final style = tester.widget<Text>(find.text('Created')).style!;
      final role = CoreTypography.coui.labelLarge;

      expect(style.fontSize, role.fontSize);
      expect(style.height, role.lineHeight);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.fontWeight, isNot(FontWeight.w600));
    });

    testWidgets('the dot is painted primary and the connector outlineVariant', (
      tester,
    ) async {
      await pumpTimeline(tester);

      final dot = dotRects(tester).first;
      final dotPixel = await pixel(tester, dot.center);
      // Below the dot, on the line (x 4..6 of the 10-wide column).
      final linePixel = await pixel(
        tester,
        Offset(dot.left + 4.5, dot.bottom + 6),
      );

      expect(
        dotPixel,
        schemeRgb(tester, const CoreColor.token(CoreColors.primary)),
      );
      expect(
        linePixel,
        schemeRgb(tester, const CoreColor.token(CoreColors.outlineVariant)),
      );
      expect(linePixel, isNot(dotPixel));
    });

    // The rows of line colour down one column of the timeline: the first
    // and last pixel row that is line, and whether every row between is.
    Future<({int first, int last, bool unbroken})> lineSpan(
      WidgetTester tester, {
      required double x,
      required double from,
      required double to,
    }) async {
      final line = schemeRgb(
        tester,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      int? first;
      int? last;
      var unbroken = true;
      for (var y = from.floor(); y < to.ceil(); y += 1) {
        final isLine = await pixel(tester, Offset(x, y + 0.5)) == line;
        if (isLine) {
          first ??= y;
          if (last != null && last != y - 1) unbroken = false;
          last = y;
        }
      }
      return (first: first!, last: last!, unbroken: unbroken);
    }

    testWidgets(
      'the connector keeps a 4 gap under its dot and above the next',
      (
        tester,
      ) async {
        await pumpTimeline(tester);

        final dots = dotRects(tester);
        final span = await lineSpan(
          tester,
          x: dots[0].left + 4.5,
          from: dots[0].bottom,
          to: dots[1].top,
        );

        // Pixel rows [first, last] are line; the dot ends at its bottom edge
        // and the next dot begins at its top edge.
        expect(span.first - dots[0].bottom, 4, reason: 'gap under the dot');
        expect(dots[1].top - (span.last + 1), 4, reason: 'gap above next dot');
      },
    );

    testWidgets('the connector runs unbroken past a two-line description', (
      tester,
    ) async {
      await pumpTimeline(tester);

      final dots = dotRects(tester);
      final span = await lineSpan(
        tester,
        x: dots[0].left + 4.5,
        from: dots[0].bottom,
        to: dots[1].top,
      );

      // The first row is the tall one (its description wraps), and the line
      // still has no break between its two ends.
      expect(span.unbroken, isTrue);
      expect(dots[1].top - dots[0].bottom, greaterThan(40));
    });

    testWidgets('the connector gap moves with the density, both ends', (
      tester,
    ) async {
      // 8 is a spacing step; one rung down is 4 (compact), up is 12
      // (spacious). The gap is spacing between two elements, so it follows.
      Future<(double, double)> gapsAt(CoreDensity density) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          buildTestApp(
            RepaintBoundary(
              key: boundary,
              child: const SizedBox(
                width: 360,
                child: Timeline(
                  items: items,
                  timelineStyle: CoreTimelineStyle(
                    connectorSpacing: CoreSpace.space8,
                  ),
                ),
              ),
            ),
            density: density,
          ),
        );
        await tester.pump();
        final dots = dotRects(tester);
        final span = await lineSpan(
          tester,
          x: dots[0].left + 4.5,
          from: dots[0].bottom,
          to: dots[1].top,
        );
        return (
          span.first - dots[0].bottom,
          dots[1].top - (span.last + 1),
        );
      }

      expect(await gapsAt(CoreDensity.compact), (4.0, 4.0));
      expect(await gapsAt(CoreDensity.spacious), (12.0, 12.0));
    });

    testWidgets('the last item has no connector below its dot', (tester) async {
      await pumpTimeline(tester);

      final last = dotRects(tester).last;
      final below = await pixel(
        tester,
        Offset(last.left + 4.5, last.bottom + 6),
      );
      final line = schemeRgb(
        tester,
        const CoreColor.token(CoreColors.outlineVariant),
      );

      expect(below, isNot(line));
    });
  });
}
