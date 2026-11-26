// What a Flutter chat bubble that states nothing takes from the row it sits in.
//
// A `Chat` row hands its alignment to the bubble it holds. On the `end` side
// (the reader's own message) a bubble that states no variant, alignment or
// tail is `primary` with its tail on that side; on the `start` side it is the
// neutral bubble with none. A value a bubble states is kept. `ChatGroup` does
// not hand its side to its bubbles.
//
// Every expectation is read back from the tree — the painted fill, the painted
// corners and where the pointer box sits against the body — so a resolver that
// picked one thing and a widget that drew another would fail here.
//
// Only the coui barrel is imported: pulling in `package:flutter/widgets.dart`
// as well re-introduces Flutter's own `Banner`, which that barrel hides.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const Key _kBubble = ValueKey('bubble');
const Key _kOther = ValueKey('other');

const Radius _k14 = Radius.circular(CoreRadius.radius14);

ThemeData get _theme => ThemeData.fromCore(CoreThemePresets.light);

Color _fill(CoreColorToken token) =>
    _theme.colorScheme.resolve(CoreColor.token(token)).toValue();

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    buildTestApp(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 400, child: child),
      ),
      theme: _theme,
    ),
  );
  await tester.pumpAndSettle();
}

DecoratedBox _body(WidgetTester tester, Key key) => tester.widget<DecoratedBox>(
  find
      .descendant(of: find.byKey(key), matching: find.byType(DecoratedBox))
      .first,
);

Color _bodyFill(WidgetTester tester, Key key) =>
    (_body(tester, key).decoration as BoxDecoration).color!;

BorderRadius _corners(WidgetTester tester, Key key) =>
    (_body(tester, key).decoration as BoxDecoration).borderRadius!.resolve(
      .ltr,
    );

Finder _pointer(Key key) => find.descendant(
  of: find.byKey(key),
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

Rect _bodyRect(WidgetTester tester, Key key) => tester.getRect(
  find
      .descendant(of: find.byKey(key), matching: find.byType(DecoratedBox))
      .first,
);

/// Text colour the bubble hands its content.
Color? _textColor(WidgetTester tester, Key key) => DefaultTextStyle.of(
  tester.element(
    find.descendant(of: find.byKey(key), matching: find.text('hi')),
  ),
).style.color;

final Color _neutralFill = _fill(CoreColors.surfaceContainerHigh);
final Color _primaryFill = _fill(CoreColors.primary);

void main() {
  group('Chat on the end side', () {
    testWidgets('a bubble that states nothing is primary with its tail '
        'on the end side', (tester) async {
      await _pump(
        tester,
        const Chat(
          alignment: .end,
          bubble: ChatBubble(key: _kBubble, child: Text('hi')),
        ),
      );

      expect(_bodyFill(tester, _kBubble), _primaryFill);
      expect(_textColor(tester, _kBubble), _fill(CoreColors.onPrimary));
      expect(_pointer(_kBubble), findsOneWidget);
      // The corner the pointer leaves from is square: bottom-right.
      expect(
        _corners(tester, _kBubble),
        const BorderRadius.only(
          topLeft: _k14,
          topRight: _k14,
          bottomLeft: _k14,
        ),
      );
      // The pointer sits on the end side of the body, not the start side.
      final pointer = tester.getRect(_pointer(_kBubble));
      expect(
        pointer.left,
        _bodyRect(tester, _kBubble).right -
            CoreChatBubbleContract.tailEdgeOverlap,
      );
    });

    testWidgets('a stated variant is kept — only what is unstated follows '
        'the side', (tester) async {
      await _pump(
        tester,
        const Chat(
          alignment: .end,
          bubble: ChatBubble(
            key: _kBubble,
            variant: .neutral,
            child: Text('hi'),
          ),
        ),
      );

      expect(_bodyFill(tester, _kBubble), _neutralFill);
      expect(_pointer(_kBubble), findsOneWidget);
    });

    testWidgets('a stated tail is kept: tail false draws none and leaves '
        'the corners round', (tester) async {
      await _pump(
        tester,
        const Chat(
          alignment: .end,
          bubble: ChatBubble(key: _kBubble, tail: false, child: Text('hi')),
        ),
      );

      expect(_bodyFill(tester, _kBubble), _primaryFill);
      expect(_pointer(_kBubble), findsNothing);
      expect(
        _corners(tester, _kBubble),
        const BorderRadius.all(_k14),
      );
    });

    testWidgets('a stated alignment is the bubble itself: the start side '
        'brings its own defaults', (tester) async {
      await _pump(
        tester,
        const Chat(
          alignment: .end,
          bubble: ChatBubble(
            key: _kBubble,
            alignment: .start,
            child: Text('hi'),
          ),
        ),
      );

      expect(_bodyFill(tester, _kBubble), _neutralFill);
      expect(_pointer(_kBubble), findsNothing);
    });

    testWidgets("a bubble in the header slot is not in the row's scope", (
      tester,
    ) async {
      await _pump(
        tester,
        const Chat(
          alignment: .end,
          header: ChatBubble(key: _kOther, child: Text('hi')),
          bubble: ChatBubble(key: _kBubble, child: Text('hi')),
        ),
      );

      expect(_bodyFill(tester, _kBubble), _primaryFill);
      expect(_bodyFill(tester, _kOther), _neutralFill);
      expect(_pointer(_kOther), findsNothing);
    });
  });

  group('Chat on the start side', () {
    testWidgets('a bubble that states nothing is neutral with no tail', (
      tester,
    ) async {
      await _pump(
        tester,
        const Chat(
          bubble: ChatBubble(key: _kBubble, child: Text('hi')),
        ),
      );

      expect(_bodyFill(tester, _kBubble), _neutralFill);
      expect(_pointer(_kBubble), findsNothing);
      expect(_corners(tester, _kBubble), const BorderRadius.all(_k14));
    });

    testWidgets('a stated tail is drawn on the start side', (tester) async {
      await _pump(
        tester,
        const Chat(
          bubble: ChatBubble(key: _kBubble, tail: true, child: Text('hi')),
        ),
      );

      expect(_pointer(_kBubble), findsOneWidget);
      expect(
        tester.getRect(_pointer(_kBubble)).right,
        _bodyRect(tester, _kBubble).left +
            CoreChatBubbleContract.tailEdgeOverlap,
      );
    });
  });

  group('a bubble outside any row', () {
    testWidgets('keeps the start-side defaults', (tester) async {
      await _pump(
        tester,
        const ChatBubble(key: _kBubble, child: Text('hi')),
      );

      expect(_bodyFill(tester, _kBubble), _neutralFill);
      expect(_pointer(_kBubble), findsNothing);
    });

    testWidgets('a stated end alignment brings the end-side defaults', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChatBubble(key: _kBubble, alignment: .end, child: Text('hi')),
      );

      expect(_bodyFill(tester, _kBubble), _primaryFill);
      expect(_pointer(_kBubble), findsOneWidget);
    });
  });

  group('ChatGroup is not a row that hands its side', () {
    // Handing the side to the bubbles of a group is not decided: whether each
    // bubble of a group carries a tail is a design call. Until it is made a
    // group changes nothing — its bubbles read no side from it, so they are the
    // neutral bubble with no tail unless they state otherwise.
    testWidgets('an end group leaves its bubbles as they state themselves', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChatGroup(
          alignment: .end,
          bubbles: [
            ChatBubble(key: _kBubble, child: Text('hi')),
            ChatBubble(key: _kOther, variant: .primary, child: Text('hi')),
          ],
        ),
      );

      expect(_bodyFill(tester, _kBubble), _neutralFill);
      expect(_pointer(_kBubble), findsNothing);
      expect(_bodyFill(tester, _kOther), _primaryFill);
      expect(_pointer(_kOther), findsNothing);
      expect(find.byType(ChatAlignmentScope), findsNothing);
    });
  });

  group('the row changing sides', () {
    testWidgets("the bubble follows when the row's alignment changes", (
      tester,
    ) async {
      // One tree, rebuilt in place — the bubble is the same const instance on
      // both sides, so only the scope can make it draw differently.
      late StateSetter rebuild;
      var side = CoreChatAlignment.start;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Chat(
              alignment: side,
              bubble: const ChatBubble(key: _kBubble, child: Text('hi')),
            );
          },
        ),
      );
      expect(_bodyFill(tester, _kBubble), _neutralFill);
      expect(_pointer(_kBubble), findsNothing);

      rebuild(() => side = CoreChatAlignment.end);
      await tester.pumpAndSettle();
      expect(_bodyFill(tester, _kBubble), _primaryFill);
      expect(_pointer(_kBubble), findsOneWidget);

      rebuild(() => side = CoreChatAlignment.start);
      await tester.pumpAndSettle();
      expect(_bodyFill(tester, _kBubble), _neutralFill);
      expect(_pointer(_kBubble), findsNothing);
    });
  });
}
