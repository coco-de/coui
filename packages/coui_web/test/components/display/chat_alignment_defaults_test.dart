// What a Web chat bubble that states nothing takes from the row it sits in.
//
// A `Chat` row hands its alignment to the bubble it holds. On the `end` side
// (the reader's own message) a bubble that states no variant, alignment or
// tail is `primary` with its tail on that side; on the `start` side it is the
// neutral bubble with none. A value a bubble states is kept. `ChatGroup` does
// not hand its side to its bubbles.
//
// Every expectation is read off the DOM the page renders — the fill class on
// the bubble element, the tail element's `clip-path` and which side it is
// anchored to — not off the resolver, so a resolver that chose one thing and
// a component that rendered another would fail here.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The bubble `<div>`s in the rendered tree: the ones that carry a fill class
/// (`bg-*`) — the bubble element itself, not its wrapper or tail.
List<DomComponent> _bubbles() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .where((c) => (c.classes ?? '').split(' ').any((k) => k.startsWith('bg-')))
    .toList();

/// The fill class of the only bubble in the tree.
String _fill() {
  final bubbles = _bubbles();
  expect(bubbles, hasLength(1), reason: 'one bubble');
  return (bubbles.single.classes ?? '')
      .split(' ')
      .singleWhere((k) => k.startsWith('bg-'));
}

/// The tail elements — the ones clipped to the pointer outline.
List<DomComponent> _tails() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .where((c) => c.styles?.properties['clip-path'] != null)
    .toList();

DomComponent _tail() {
  final tails = _tails();
  expect(tails, hasLength(1), reason: 'one tail');
  return tails.single;
}

void main() {
  group('Chat on the end side', () {
    testComponents('a bubble that states nothing is primary with its tail on '
        'the end side', (tester) async {
      pumpWithTheme(
        tester,
        const Chat(
          alignment: .end,
          bubble: ChatBubble(child: Text('hi')),
        ),
      );

      expect(_fill(), 'bg-primary');
      final tail = _tail().styles!.properties;
      // Anchored to the end side: pushed out past the body's right edge.
      expect(tail.containsKey('right'), isTrue);
      expect(tail.containsKey('left'), isFalse);
    });

    testComponents('the corner the tail leaves from is square', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Chat(
          alignment: .end,
          bubble: ChatBubble(child: Text('hi')),
        ),
      );

      final radius = _bubbles().single.styles!.properties['border-radius']!;
      final square = radiusCss(0);
      // topLeft topRight bottomRight bottomLeft — the bottom-right one.
      final corners = radius.split(' ');
      expect(corners, hasLength(4));
      expect(corners[2], square);
      expect(corners[0], isNot(square));
    });

    testComponents('a stated variant is kept — only what is unstated follows '
        'the side', (tester) async {
      pumpWithTheme(
        tester,
        const Chat(
          alignment: .end,
          bubble: ChatBubble(variant: .neutral, child: Text('hi')),
        ),
      );

      expect(_fill(), 'bg-surface-container-high');
      expect(_tails(), hasLength(1));
    });

    testComponents('a stated tail is kept: tail false draws none', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Chat(
          alignment: .end,
          bubble: ChatBubble(tail: false, child: Text('hi')),
        ),
      );

      expect(_fill(), 'bg-primary');
      expect(_tails(), isEmpty);
    });

    testComponents('a stated alignment is the bubble itself: the start side '
        'brings its own defaults', (tester) async {
      pumpWithTheme(
        tester,
        const Chat(
          alignment: .end,
          bubble: ChatBubble(alignment: .start, child: Text('hi')),
        ),
      );

      expect(_fill(), 'bg-surface-container-high');
      expect(_tails(), isEmpty);
    });

    testComponents("a bubble in the header slot is not in the row's scope", (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Chat(
          alignment: .end,
          header: ChatBubble(child: Text('header')),
          bubble: ChatBubble(child: Text('hi')),
        ),
      );

      final fills = _bubbles()
          .map(
            (c) => (c.classes ?? '')
                .split(' ')
                .singleWhere((k) => k.startsWith('bg-')),
          )
          .toList();
      expect(
        fills,
        unorderedEquals(['bg-surface-container-high', 'bg-primary']),
      );
      expect(_tails(), hasLength(1));
    });
  });

  group('Chat on the start side', () {
    testComponents('a bubble that states nothing is neutral with no tail', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Chat(bubble: ChatBubble(child: Text('hi'))),
      );

      expect(_fill(), 'bg-surface-container-high');
      expect(_tails(), isEmpty);
    });

    testComponents('a stated tail is drawn on the start side', (tester) async {
      pumpWithTheme(
        tester,
        const Chat(bubble: ChatBubble(tail: true, child: Text('hi'))),
      );

      final tail = _tail().styles!.properties;
      expect(tail.containsKey('left'), isTrue);
      expect(tail.containsKey('right'), isFalse);
    });
  });

  group('a bubble outside any row', () {
    testComponents('keeps the start-side defaults', (tester) async {
      pumpWithTheme(tester, const ChatBubble(child: Text('hi')));

      expect(_fill(), 'bg-surface-container-high');
      expect(_tails(), isEmpty);
    });

    testComponents('a stated end alignment brings the end-side defaults', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ChatBubble(alignment: .end, child: Text('hi')),
      );

      expect(_fill(), 'bg-primary');
      expect(_tails(), hasLength(1));
    });
  });

  group('ChatGroup is not a row that hands its side', () {
    // Handing the side to the bubbles of a group is not decided: whether each
    // bubble of a group carries a tail is a design call. Until it is made a
    // group changes nothing — its bubbles read no side from it, so they are the
    // neutral bubble with no tail unless they state otherwise.
    testComponents('an end group leaves its bubbles as they state themselves', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ChatGroup(
          alignment: .end,
          bubbles: [
            ChatBubble(child: Text('one')),
            ChatBubble(variant: .primary, child: Text('two')),
          ],
        ),
      );

      final fills = _bubbles()
          .map(
            (c) => (c.classes ?? '')
                .split(' ')
                .singleWhere((k) => k.startsWith('bg-')),
          )
          .toList();
      expect(fills, ['bg-surface-container-high', 'bg-primary']);
      expect(_tails(), isEmpty);
    });
  });
}
