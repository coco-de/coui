// The tail corner of a chat bubble — which corner it is, and what a style says
// about it.
//
// The corner is chosen by two things: the edge the tail sits on and the side
// the bubble is aligned to. Each of the four combinations names exactly one
// corner, and every other corner keeps what `borderRadius` stated. The cases
// below say the corner by its name, so a swapped edge or side fails on the
// one combination it breaks.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const CoreBorderRadius _kFour = CoreBorderRadius.only(
  topLeft: CoreRadius.radius10,
  topRight: CoreRadius.radius12,
  bottomLeft: CoreRadius.radius14,
  bottomRight: CoreRadius.radius16,
);

const double _kCorner = CoreRadius.radius6;

void main() {
  group('CoreChatBubbleTailEdge.withTailCorner', () {
    test('bottom edge, start: the bottom-left corner', () {
      expect(
        CoreChatBubbleTailEdge.bottom.withTailCorner(
          _kFour,
          alignment: .start,
          corner: _kCorner,
        ),
        const CoreBorderRadius.only(
          topLeft: CoreRadius.radius10,
          topRight: CoreRadius.radius12,
          bottomLeft: _kCorner,
          bottomRight: CoreRadius.radius16,
        ),
      );
    });

    test('bottom edge, end: the bottom-right corner', () {
      expect(
        CoreChatBubbleTailEdge.bottom.withTailCorner(
          _kFour,
          alignment: .end,
          corner: _kCorner,
        ),
        const CoreBorderRadius.only(
          topLeft: CoreRadius.radius10,
          topRight: CoreRadius.radius12,
          bottomLeft: CoreRadius.radius14,
          bottomRight: _kCorner,
        ),
      );
    });

    test('top edge, start: the top-left corner', () {
      expect(
        CoreChatBubbleTailEdge.top.withTailCorner(
          _kFour,
          alignment: .start,
          corner: _kCorner,
        ),
        const CoreBorderRadius.only(
          topLeft: _kCorner,
          topRight: CoreRadius.radius12,
          bottomLeft: CoreRadius.radius14,
          bottomRight: CoreRadius.radius16,
        ),
      );
    });

    test('top edge, end: the top-right corner', () {
      expect(
        CoreChatBubbleTailEdge.top.withTailCorner(
          _kFour,
          alignment: .end,
          corner: _kCorner,
        ),
        const CoreBorderRadius.only(
          topLeft: CoreRadius.radius10,
          topRight: _kCorner,
          bottomLeft: CoreRadius.radius14,
          bottomRight: CoreRadius.radius16,
        ),
      );
    });

    test('a square corner is a corner like any other', () {
      // The pointer squares its corner through this same path.
      expect(
        CoreChatBubbleTailEdge.bottom
            .withTailCorner(_kFour, alignment: .end, corner: 0)
            .bottomRight,
        0,
      );
    });
  });

  group('CoreChatBubbleStyle tail edge and corner', () {
    test('the tail sits on the bottom edge unless a style says otherwise', () {
      expect(
        CoreChatBubbleStyle.defaultTailEdge,
        CoreChatBubbleTailEdge.bottom,
      );
    });

    test('the tail corner has no value of its own until one is stated', () {
      // Null is the statement "the matching corner of borderRadius" — the
      // resolvers fall through to it, so a theme that restates the radius
      // moves all four corners together.
      expect(const CoreChatBubbleStyle().tailCornerRadius, isNull);
      expect(const CoreChatBubbleStyle().tailEdge, isNull);
    });

    test('merge: a stated edge and corner win, an unstated one keeps', () {
      const base = CoreChatBubbleStyle(
        tailEdge: .top,
        tailCornerRadius: CoreRadius.radius6,
      );

      expect(
        base.merge(const CoreChatBubbleStyle(tailCornerRadius: 2)),
        const CoreChatBubbleStyle(tailEdge: .top, tailCornerRadius: 2),
      );
      expect(
        base.merge(const CoreChatBubbleStyle(tailEdge: .bottom)),
        const CoreChatBubbleStyle(
          tailEdge: .bottom,
          tailCornerRadius: CoreRadius.radius6,
        ),
      );
      expect(base.merge(const CoreChatBubbleStyle()), base);
    });

    test('copyWith carries both', () {
      expect(
        const CoreChatBubbleStyle().copyWith(
          tailEdge: .top,
          tailCornerRadius: CoreRadius.radius6,
        ),
        const CoreChatBubbleStyle(
          tailEdge: .top,
          tailCornerRadius: CoreRadius.radius6,
        ),
      );
    });

    test('equality and hash tell a different edge or corner apart', () {
      const a = CoreChatBubbleStyle(
        tailEdge: .top,
        tailCornerRadius: CoreRadius.radius6,
      );

      expect(
        a,
        isNot(
          const CoreChatBubbleStyle(
            tailEdge: .bottom,
            tailCornerRadius: CoreRadius.radius6,
          ),
        ),
      );
      expect(
        a,
        isNot(
          const CoreChatBubbleStyle(
            tailEdge: .top,
            tailCornerRadius: CoreRadius.radius8,
          ),
        ),
      );
      expect(
        a.hashCode,
        const CoreChatBubbleStyle(
          tailEdge: .top,
          tailCornerRadius: CoreRadius.radius6,
        ).hashCode,
      );
      expect(
        a.hashCode,
        isNot(const CoreChatBubbleStyle(tailEdge: .top).hashCode),
      );
    });
  });
}
