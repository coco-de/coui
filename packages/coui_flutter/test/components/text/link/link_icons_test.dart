import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

const ValueKey<String> _leading = ValueKey('leading');
const ValueKey<String> _trailing = ValueKey('trailing');

void main() {
  group('Link leading / trailing icons', () {
    testWidgets('sit either side of the label, a gap away, centred', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Link(
          href: '/docs',
          onPressed: () {},
          leading: const Icon(LucideIcons.link2, key: _leading),
          trailing: const Icon(LucideIcons.externalLink, key: _trailing),
          child: const Text('GitHub에서 보기'),
        ),
      );

      final leading = tester.getRect(find.byKey(_leading));
      final label = tester.getRect(find.text('GitHub에서 보기'));
      final trailing = tester.getRect(find.byKey(_trailing));
      const gap = CoreSpace.space4;

      expect(label.left - leading.right, moreOrLessEquals(gap));
      expect(trailing.left - label.right, moreOrLessEquals(gap));
      expect(leading.center.dy, moreOrLessEquals(label.center.dy));
      expect(trailing.center.dy, moreOrLessEquals(label.center.dy));
      expect(leading.width, CoreLinkStyle.defaultIconStyle.size);
    });

    testWidgets('take the link text colour unless the style states one', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Link(
          href: '/docs',
          variant: .muted,
          trailing: const Icon(LucideIcons.externalLink, key: _trailing),
          child: const Text('docs'),
        ),
      );

      final theme = Theme.of(tester.element(find.byKey(_trailing)));
      final iconColor = IconTheme.of(
        tester.element(find.byKey(_trailing)),
      ).color;
      final textColor = DefaultTextStyle.of(
        tester.element(find.text('docs')),
      ).style.color;
      expect(iconColor, textColor);
      expect(
        iconColor,
        theme.colorScheme
            .resolve(
              CoreLinkStyle.defaultsByVariant[CoreLinkVariant.muted]!.color!,
            )
            .toValue(),
      );

      // The harness's `Overlay` keeps the entries it was first given, so
      // the second case starts from an empty tree.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpTestApp(
        tester,
        Link(
          href: '/docs',
          linkStyle: const CoreLinkStyle(
            iconStyle: CoreIconStyle(
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
          trailing: const Icon(LucideIcons.externalLink, key: _trailing),
          child: const Text('docs'),
        ),
      );
      expect(
        IconTheme.of(tester.element(find.byKey(_trailing))).color,
        theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.primary))
            .toValue(),
      );
    });

    testWidgets('without icons the label is the only child', (tester) async {
      await pumpTestApp(
        tester,
        const Link(href: '/docs', child: Text('docs')),
      );
      expect(
        find.descendant(of: find.byType(Link), matching: find.byType(Gap)),
        findsNothing,
      );
    });
  });
}
