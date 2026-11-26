// Where the Flutter chat bubble puts its tail, and what its tail corner is.
//
// The tail sits on one edge (`tailEdge`, bottom by default) on the side the
// bubble is aligned to. A drawn pointer squares that corner and leaves from
// it; a bubble with no pointer can shape that one corner with
// `tailCornerRadius`. Every expectation is read back from the tree — the
// painted corners, where the pointer box sits against the body, and the
// pointer's pixels — so a resolver and a painter that disagreed about the
// edge would fail here rather than agree with each other.
//
// Only the coui barrel is imported: pulling in `package:flutter/widgets.dart`
// as well re-introduces Flutter's own `Banner`, which that barrel hides.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const Key _kBubble = ValueKey('bubble');

const Radius _k14 = Radius.circular(CoreRadius.radius14);
const Radius _k6 = Radius.circular(CoreRadius.radius6);

const CoreChatBubbleStyle _kTopTail = CoreChatBubbleStyle(tailEdge: .top);

Future<void> _pump(
  WidgetTester tester,
  Widget bubble, {
  CoreDensity density = .defaultDensity,
  TextDirection textDirection = .ltr,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      Align(
        alignment: Alignment.topLeft,
        // Loose inside the room, the way a chat row's column hands it out:
        // the pointer is placed against the bubble's own box, not the room.
        child: SizedBox(
          width: 400,
          child: Align(alignment: Alignment.topLeft, child: bubble),
        ),
      ),
      theme: ThemeData.fromCore(CoreThemePresets.light),
      density: density,
      textDirection: textDirection,
    ),
  );
  await tester.pumpAndSettle();
}

/// The bubble body's painted corners.
BorderRadius _corners(WidgetTester tester) {
  final box = find.descendant(
    of: find.byKey(_kBubble),
    matching: find.byType(DecoratedBox),
  );
  final decoration = tester.widget<DecoratedBox>(box.first).decoration;
  return (decoration as BoxDecoration).borderRadius!.resolve(.ltr);
}

/// The bubble body's rect.
Rect _body(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byKey(_kBubble),
        matching: find.byType(DecoratedBox),
      )
      .first,
);

/// The pointer's box — the one `CustomPaint` sized to the tail.
Rect _tail(WidgetTester tester) {
  final paints = find.descendant(
    of: find.byKey(_kBubble),
    matching: find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.size ==
              const Size(
                CoreChatBubbleStyle.defaultTailWidth,
                CoreChatBubbleStyle.defaultTailHeight,
              ),
    ),
  );
  expect(paints, findsOneWidget, reason: 'one pointer');
  return tester.getRect(paints);
}

/// Reads one pixel of [boundary] back, as `0xAARRGGBB`.
Future<int> _pixel(
  WidgetTester tester,
  GlobalKey boundary,
  Offset at,
) async {
  final result = await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    final data = (await image.toByteData())!;
    final i = ((at.dy.round() * image.width) + at.dx.round()) * 4;
    final r = data.getUint8(i);
    final g = data.getUint8(i + 1);
    final b = data.getUint8(i + 2);
    final a = data.getUint8(i + 3);
    image.dispose();
    return (a << 24) | (r << 16) | (g << 8) | b;
  });
  return result!;
}

void main() {
  group('ChatBubble tail on the top edge', () {
    testWidgets('start: the top-left corner is square, the pointer sits '
        'left of the body, flush with its top', (tester) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          tail: true,
          chatBubbleStyle: _kTopTail,
          child: Text('hi'),
        ),
      );

      expect(
        _corners(tester),
        const BorderRadius.only(
          topRight: _k14,
          bottomLeft: _k14,
          bottomRight: _k14,
        ),
      );
      final body = _body(tester);
      final tail = _tail(tester);
      expect(tail.top, body.top);
      expect(
        tail.right,
        body.left + CoreChatBubbleContract.tailEdgeOverlap,
      );
    });

    testWidgets('end: the top-right corner is square, the pointer sits '
        'right of the body, flush with its top', (tester) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          alignment: .end,
          tail: true,
          chatBubbleStyle: _kTopTail,
          child: Text('hi'),
        ),
      );

      expect(
        _corners(tester),
        const BorderRadius.only(
          topLeft: _k14,
          bottomLeft: _k14,
          bottomRight: _k14,
        ),
      );
      final body = _body(tester);
      final tail = _tail(tester);
      expect(tail.top, body.top);
      expect(tail.left, body.right - CoreChatBubbleContract.tailEdgeOverlap);
    });

    testWidgets('the default edge keeps the pointer flush with the bottom', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChatBubble(key: _kBubble, tail: true, child: Text('hi')),
      );

      expect(_tail(tester).bottom, _body(tester).bottom);
    });

    for (final onTop in [true, false]) {
      testWidgets(
        '${onTop ? 'top' : 'bottom'} edge: the pointer is filled along that '
        'edge and empty across from it',
        (tester) async {
          // The pointer's fat end hugs the body along the tail edge; the far
          // corner of its box, on the opposite edge, is outside the triangle.
          final boundary = GlobalKey();
          tester.view.physicalSize = const Size(600, 200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            buildTestApp(
              Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: boundary,
                  child: ColoredBox(
                    color: const Color(0xFFFF00FF),
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: ChatBubble(
                        key: _kBubble,
                        tail: true,
                        chatBubbleStyle: onTop ? _kTopTail : null,
                        child: const Text('hi'),
                      ),
                    ),
                  ),
                ),
              ),
              theme: ThemeData.fromCore(CoreThemePresets.light),
            ),
          );
          await tester.pumpAndSettle();

          final tail = _tail(tester);
          const w = CoreChatBubbleStyle.defaultTailWidth;
          const h = CoreChatBubbleStyle.defaultTailHeight;
          // Start-aligned: the bubble side is the tail box's right edge.
          final alongEdge = Offset(
            tail.right - w / 4,
            onTop ? tail.top + h / 4 : tail.bottom - h / 4,
          );
          final acrossFromIt = Offset(
            tail.left + w / 4,
            onTop ? tail.bottom - h / 4 : tail.top + h / 4,
          );
          final fill = CoreThemePresets.lightColorScheme.surfaceContainerHigh
              .toValue();
          final filled = await _pixel(tester, boundary, alongEdge);
          final empty = await _pixel(tester, boundary, acrossFromIt);

          expect(
            filled,
            isNot(0xFFFF00FF),
            reason: 'the fat end on the tail edge is painted',
          );
          expect(
            (filled >> 16) & 0xFF,
            closeTo((fill.r * 255).round(), 1),
          );
          expect(
            empty,
            0xFFFF00FF,
            reason: 'the corner across from the tail edge is outside it',
          );
        },
      );
    }
  });

  group('ChatBubble tail corner without a pointer', () {
    const corner = CoreChatBubbleStyle(tailCornerRadius: CoreRadius.radius6);

    // The end side draws a pointer unless told not to, so a bubble that is
    // about the corner of one with no pointer says `tail: false`.

    testWidgets('bottom edge, start: the bottom-left corner is the stated '
        'one, three stay 14', (tester) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          chatBubbleStyle: corner,
          child: Text('hi'),
        ),
      );

      expect(
        _corners(tester),
        const BorderRadius.only(
          topLeft: _k14,
          topRight: _k14,
          bottomLeft: _k6,
          bottomRight: _k14,
        ),
      );
    });

    testWidgets('bottom edge, end: the bottom-right corner', (tester) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          alignment: .end,
          tail: false,
          chatBubbleStyle: corner,
          child: Text('hi'),
        ),
      );

      expect(
        _corners(tester),
        const BorderRadius.only(
          topLeft: _k14,
          topRight: _k14,
          bottomLeft: _k14,
          bottomRight: _k6,
        ),
      );
    });

    testWidgets('top edge, start: the top-left corner', (tester) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          chatBubbleStyle: CoreChatBubbleStyle(
            tailEdge: .top,
            tailCornerRadius: CoreRadius.radius6,
          ),
          child: Text('hi'),
        ),
      );

      expect(
        _corners(tester),
        const BorderRadius.only(
          topLeft: _k6,
          topRight: _k14,
          bottomLeft: _k14,
          bottomRight: _k14,
        ),
      );
    });

    testWidgets('top edge, end: the top-right corner', (tester) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          alignment: .end,
          tail: false,
          chatBubbleStyle: CoreChatBubbleStyle(
            tailEdge: .top,
            tailCornerRadius: CoreRadius.radius6,
          ),
          child: Text('hi'),
        ),
      );

      expect(
        _corners(tester),
        const BorderRadius.only(
          topLeft: _k14,
          topRight: _k6,
          bottomLeft: _k14,
          bottomRight: _k14,
        ),
      );
    });

    testWidgets('unstated, the corner follows a restated borderRadius', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          chatBubbleStyle: CoreChatBubbleStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
          ),
          child: Text('hi'),
        ),
      );

      expect(_corners(tester), BorderRadius.circular(CoreRadius.radius20));
    });

    testWidgets('a drawn pointer still squares the corner', (tester) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          tail: true,
          chatBubbleStyle: corner,
          child: Text('hi'),
        ),
      );

      expect(
        _corners(tester),
        const BorderRadius.only(
          topLeft: _k14,
          topRight: _k14,
          bottomRight: _k14,
        ),
        reason:
            'the pointer continues the side — a rounded corner would '
            'open a notch',
      );
    });

    testWidgets('a density moves the stated corner with the other three', (
      tester,
    ) async {
      final corner6 = CoreDensity.spacious.radius(CoreRadius.radius6);
      final corner14 = CoreDensity.spacious.radius(CoreRadius.radius14);
      // A density that left either corner alone would prove nothing here.
      expect(corner6, isNot(CoreRadius.radius6));
      expect(corner14, isNot(CoreRadius.radius14));

      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          chatBubbleStyle: CoreChatBubbleStyle(
            tailEdge: .top,
            tailCornerRadius: CoreRadius.radius6,
          ),
          child: Text('hi'),
        ),
        density: .spacious,
      );

      expect(
        _corners(tester),
        BorderRadius.only(
          topLeft: Radius.circular(corner6),
          topRight: Radius.circular(corner14),
          bottomLeft: Radius.circular(corner14),
          bottomRight: Radius.circular(corner14),
        ),
      );
    });

    testWidgets('right to left does not mirror it: the corner is physical', (
      tester,
    ) async {
      // The documented reach, like `CoreBorderRadius` itself — an end-aligned
      // bubble keeps its right-hand corner on a right-to-left page.
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          alignment: .end,
          tail: false,
          chatBubbleStyle: CoreChatBubbleStyle(
            tailEdge: .top,
            tailCornerRadius: CoreRadius.radius6,
          ),
          child: Text('hi'),
        ),
        textDirection: .rtl,
      );

      expect(_corners(tester).topRight, _k6);
      expect(_corners(tester).topLeft, _k14);
    });
  });
}
