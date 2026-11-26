import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kTestColor = CoreColor(0xFFFF0000);
const _kTestBorderRadius = 16.0;
const _kConstraintWidth = 400.0;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(
      data: const ThemeData(),
      child: SizedBox(
        width: _kConstraintWidth,
        child: child,
      ),
    ),
  );
}

/// The style a [finder]'s text is painted with — the paragraph's own, so an
/// inherited [DefaultTextStyle] is what is read, not what a caller stated.
TextStyle? _paintedStyleOf(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder).text.style;

/// The colour [token] paints under the test theme, read off a widget that is
/// already on screen.
Color _toneAt(WidgetTester tester, Finder at, CoreColorToken token) => Theme.of(
  tester.element(at),
).colorScheme.resolve(CoreColor.token(token)).toValue();

/// Tail painters under a bubble — the pointer is its own `CustomPaint`.
Finder _tailPainters() => find.descendant(
  of: find.byType(ChatBubble),
  matching: find.byWidgetPredicate(
    (w) =>
        w is CustomPaint &&
        w.painter.runtimeType.toString() == '_ChatTailPainter',
  ),
);

void main() {
  group('ChatBubble widget', () {
    testWidgets('renders with required child', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ChatBubble(child: Text('Hello!'))),
      );

      expect(find.byType(ChatBubble), findsOneWidget);
      expect(find.text('Hello!'), findsOneWidget);
    });

    testWidgets('renders with a variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ChatBubble(
            variant: CoreChatBubbleVariant.primary,
            child: Text('Hello!'),
          ),
        ),
      );

      expect(find.text('Hello!'), findsOneWidget);
    });

    testWidgets('renders with end alignment', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ChatBubble(
            alignment: CoreChatAlignment.end,
            child: Text('Hello!'),
          ),
        ),
      );

      expect(find.text('Hello!'), findsOneWidget);
    });

    testWidgets('renders with custom chrome via chatBubbleStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const ChatBubble(
            chatBubbleStyle: CoreChatBubbleStyle(
              backgroundColor: _kTestColor,
              borderRadius: CoreBorderRadius.all(_kTestBorderRadius),
            ),
            child: Text('Hello!'),
          ),
        ),
      );

      expect(find.text('Hello!'), findsOneWidget);
    });

    testWidgets('draws no tail by default on the start side', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ChatBubble(child: Text('Hello!'))),
      );

      expect(find.text('Hello!'), findsOneWidget);
      expect(_tailPainters(), findsNothing);
      // Unstated — the side decides, and the start side keeps the default.
      expect(const ChatBubble(child: Text('Hello!')).tail, isNull);
      expect(
        CoreChatBubbleContract.defaultTailFor(CoreChatAlignment.start),
        CoreChatBubbleContract.defaultTail,
      );
    });

    testWidgets('draws a tail by default on the end side', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ChatBubble(alignment: .end, child: Text('Hello!')),
        ),
      );

      expect(_tailPainters(), findsOneWidget);
    });

    testWidgets('draws a tail when asked', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ChatBubble(tail: true, child: Text('Hello!'))),
      );

      expect(find.text('Hello!'), findsOneWidget);
      expect(_tailPainters(), findsOneWidget);
    });

    testWidgets('renders without a tail', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ChatBubble(child: Text('Hello!')),
        ),
      );

      expect(find.text('Hello!'), findsOneWidget);
      expect(_tailPainters(), findsNothing);
    });

    testWidgets('respects provided key', (tester) async {
      const testKey = Key('test-chat-bubble');

      await tester.pumpWidget(
        _buildApp(
          const ChatBubble(key: testKey, child: Text('Hello!')),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });
  });

  group('ChatGroup widget', () {
    testWidgets('renders its bubbles', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ChatGroup(
            bubbles: [
              ChatBubble(child: Text('Message 1')),
              ChatBubble(child: Text('Message 2')),
            ],
          ),
        ),
      );

      expect(find.byType(ChatGroup), findsOneWidget);
      expect(find.text('Message 1'), findsOneWidget);
      expect(find.text('Message 2'), findsOneWidget);
    });

    testWidgets('renders with an avatar', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ChatGroup(
            avatar: SizedBox.square(dimension: 32),
            bubbles: [ChatBubble(child: Text('Hello!'))],
          ),
        ),
      );

      expect(find.text('Hello!'), findsOneWidget);
    });

    testWidgets('renders with header and footer', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ChatGroup(
            header: Text('Alice'),
            footer: Text('sent'),
            bubbles: [ChatBubble(child: Text('Hello!'))],
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('sent'), findsOneWidget);
      expect(find.text('Hello!'), findsOneWidget);
    });

    testWidgets('respects provided key', (tester) async {
      const testKey = Key('test-chat-group');

      await tester.pumpWidget(
        _buildApp(
          const ChatGroup(
            key: testKey,
            bubbles: [ChatBubble(child: Text('Hello!'))],
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });
  });

  group('Chat widget', () {
    testWidgets('renders a single bubble', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Chat(
            bubble: ChatBubble(child: Text('Hi there')),
          ),
        ),
      );

      expect(find.byType(Chat), findsOneWidget);
      expect(find.text('Hi there'), findsOneWidget);
    });

    testWidgets('renders with avatar/header/footer slots', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Chat(
            avatar: SizedBox.square(dimension: 32),
            header: Text('Bob'),
            footer: Text('2:00 PM'),
            bubble: ChatBubble(child: Text('Hi there')),
          ),
        ),
      );

      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('2:00 PM'), findsOneWidget);
      expect(find.text('Hi there'), findsOneWidget);
    });
  });

  // The header and footer are plain `Text` the caller hands in; the row gives
  // them their type. What is read is the style the paragraph is painted with.
  group('Chat header and footer text', () {
    const header = 'Bob';
    const footer = '2:00 PM';

    testWidgets('the sender is 12 / medium in on-surface-variant and the '
        'timestamp 12 / regular in on-surface-subtle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Chat(
            header: Text(header),
            footer: Text(footer),
            bubble: ChatBubble(child: Text('Hi there')),
          ),
        ),
      );

      final sender = _paintedStyleOf(tester, find.text(header))!;
      expect(sender.fontSize, 12);
      expect(sender.fontWeight, FontWeight.w500);
      expect(sender.height, 1.4);
      expect(sender.letterSpacing, closeTo(-0.12, 0.000001));
      expect(
        sender.color,
        _toneAt(tester, find.text(header), CoreColors.onSurfaceVariant),
      );

      final stamp = _paintedStyleOf(tester, find.text(footer))!;
      expect(stamp.fontSize, 12);
      expect(stamp.fontWeight, FontWeight.w400);
      expect(stamp.height, 1.5);
      expect(stamp.letterSpacing, closeTo(-0.12, 0.000001));
      expect(
        stamp.color,
        _toneAt(tester, find.text(footer), CoreColors.onSurfaceSubtle),
      );
    });

    testWidgets('a ChatGroup reads the same defaults', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ChatGroup(
            header: Text(header),
            footer: Text(footer),
            bubbles: [ChatBubble(child: Text('Hello!'))],
          ),
        ),
      );

      final sender = _paintedStyleOf(tester, find.text(header))!;
      expect(sender.fontSize, 12);
      expect(sender.fontWeight, FontWeight.w500);
      expect(
        sender.color,
        _toneAt(tester, find.text(header), CoreColors.onSurfaceVariant),
      );
      final stamp = _paintedStyleOf(tester, find.text(footer))!;
      expect(stamp.fontSize, 12);
      expect(stamp.fontWeight, FontWeight.w400);
      expect(
        stamp.color,
        _toneAt(tester, find.text(footer), CoreColors.onSurfaceSubtle),
      );
    });

    testWidgets('a stated chatStyle still wins over the defaults', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Chat(
            header: Text(header),
            footer: Text(footer),
            bubble: ChatBubble(child: Text('Hi there')),
            chatStyle: CoreChatStyle(
              headerTextStyle: CoreTextStyle.token(
                CoreTextStyles.labelLarge,
                color: CoreColor.token(CoreColors.primary),
              ),
            ),
          ),
        ),
      );

      final sender = _paintedStyleOf(tester, find.text(header))!;
      expect(sender.fontSize, 14);
      expect(
        sender.color,
        _toneAt(tester, find.text(header), CoreColors.primary),
      );
      // The footer was not stated: it keeps its default.
      expect(_paintedStyleOf(tester, find.text(footer))!.fontSize, 12);
    });
  });
}
