import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/text/link/link_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('Link leading / trailing icons', () {
    for (final acting in [false, true]) {
      testComponents('lay out as one centred row beside the label '
          '(${acting ? 'acting' : 'navigating'})', (tester) async {
        pumpWithTheme(
          tester,
          Link(
            href: '/docs',
            onPressed: acting ? () {} : null,
            leading: const Icon(LucideIcons.link2),
            trailing: const Icon(LucideIcons.externalLink),
            child: const Text('GitHub에서 보기'),
          ),
        );

        final row = acting ? find.tag('span').first : find.tag('a');
        final classes =
            (row.evaluate().first.component as DomComponent).classes ?? '';
        expect(
          classes.split(' '),
          containsAll(['inline-flex', 'items-center']),
        );
        expect(find.byType(Gap), findsNComponents(2));
        expect(find.byType(IconTheme), findsOneComponent);
      });
    }

    testComponents('a link without icons keeps its inline box', (
      tester,
    ) async {
      pumpWithTheme(tester, const Link(href: '/docs', child: Text('docs')));

      final classes =
          (find.tag('a').evaluate().first.component as DomComponent).classes ??
          '';
      expect(classes.split(' '), isNot(contains('inline-flex')));
      expect(find.byType(Gap), findsNothing);
    });

    testComponents('the icon theme is the slot size with no colour, so the '
        'glyph paints the text colour', (tester) async {
      late ResolvedLink resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveLink(
              context,
              variant: .standard,
              withIcons: true,
            );
            return const Component.text('');
          },
        ),
      );
      expect(resolved.iconStyle.size, CoreLinkStyle.defaultIconStyle.size);
      expect(resolved.iconStyle.color, isNull);
      expect(
        resolved.iconLabelGapStyle,
        CoreLinkStyle.defaultIconLabelGapStyle,
      );
    });
  });
}
