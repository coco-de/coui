// What the header and the footer of a Web chat row read when a caller states
// nothing.
//
// The sender above the bubble is the `label-small` role (12 / 500) in
// `on-surface-variant`; the timestamp below it is the `body-xs` role (12 / 400)
// in `on-surface-subtle`. Both are read off the DOM the page renders — the
// classes on the element that wraps the slot — not off the resolver, so a
// resolver that chose one thing and a row that rendered another would fail
// here. A role is a class: nothing is inlined over it unless a caller states
// a scalar.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The element that wraps the slot holding [text]: the `<div>` whose first
/// child is the slot's own content.
DomComponent _wrapperOf(String text) {
  final wrappers = find
      .byType(DomComponent)
      .evaluate()
      .map((e) => e.component as DomComponent)
      .where(
        (c) =>
            c.tag == 'div' &&
            (c.classes ?? '').split(' ').any((k) => k.startsWith('text-')) &&
            c.children?.any(
                  (child) => child is Text && child.data == text,
                ) ==
                true,
      )
      .toList();
  expect(wrappers, hasLength(1), reason: 'one wrapper around "$text"');
  return wrappers.single;
}

List<String> _classes(DomComponent element) =>
    (element.classes ?? '').split(' ');

String _ink(CoreColorToken token) =>
    'text-${CoreColor.token(token).tailwindColor}';

void main() {
  group('Chat header and footer text', () {
    testComponents('the sender is label-small in on-surface-variant and the '
        'timestamp body-xs in on-surface-subtle', (tester) async {
      pumpWithTheme(
        tester,
        const Chat(
          header: Text('Bob'),
          footer: Text('2:00 PM'),
          bubble: ChatBubble(child: Text('hi')),
        ),
      );

      final sender = _wrapperOf('Bob');
      expect(
        _classes(sender),
        containsAll(['text-label-small', _ink(CoreColors.onSurfaceVariant)]),
      );
      expect(_classes(sender), isNot(contains('text-body-medium')));
      expect(sender.styles, isNull, reason: 'a role is a class, not inline');

      final stamp = _wrapperOf('2:00 PM');
      expect(
        _classes(stamp),
        containsAll(['text-body-xs', _ink(CoreColors.onSurfaceSubtle)]),
      );
      expect(_classes(stamp), isNot(contains('text-body-medium')));
      expect(stamp.styles, isNull, reason: 'a role is a class, not inline');
    });

    testComponents('a ChatGroup reads the same defaults', (tester) async {
      pumpWithTheme(
        tester,
        const ChatGroup(
          header: Text('Bob'),
          footer: Text('2:00 PM'),
          bubbles: [ChatBubble(child: Text('hi'))],
        ),
      );

      expect(
        _classes(_wrapperOf('Bob')),
        containsAll(['text-label-small', _ink(CoreColors.onSurfaceVariant)]),
      );
      expect(
        _classes(_wrapperOf('2:00 PM')),
        containsAll(['text-body-xs', _ink(CoreColors.onSurfaceSubtle)]),
      );
    });

    testComponents('a stated chatStyle wins, the footer keeps its default', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Chat(
          header: Text('Bob'),
          footer: Text('2:00 PM'),
          bubble: ChatBubble(child: Text('hi')),
          chatStyle: CoreChatStyle(
            headerTextStyle: CoreTextStyle.token(
              CoreTextStyles.labelLarge,
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      );

      expect(
        _classes(_wrapperOf('Bob')),
        containsAll(['text-label-large', _ink(CoreColors.primary)]),
      );
      expect(
        _classes(_wrapperOf('2:00 PM')),
        containsAll(['text-body-xs', _ink(CoreColors.onSurfaceSubtle)]),
      );
    });
  });
}
