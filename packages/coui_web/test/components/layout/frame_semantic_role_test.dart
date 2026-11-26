import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/layout/frame/frame.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('a Core role reaches the DOM as its ARIA spelling', () {
    testComponents('navigation', (tester) async {
      pumpWithTheme(
        tester,
        Frame(
          a11y: const CoreFrameA11y(
            role: CoreSemanticRole.navigation,
            label: 'primary',
          ),
          child: Component.text('x'),
        ),
      );

      expect(
        find
            .tag('div')
            .evaluate()
            .any(
              (e) =>
                  (e.component as DomComponent).attributes?['role'] ==
                  'navigation',
            ),
        isTrue,
      );
    });

    testComponents('a role whose identifier differs from its ARIA name', (
      tester,
    ) async {
      // `tabList` is `tablist` and `image` is `img`. A Dart identifier
      // forwarded verbatim would emit a role no browser recognises,
      // which is silent — the element simply stops being announced.
      pumpWithTheme(
        tester,
        Frame(
          a11y: const CoreFrameA11y(role: CoreSemanticRole.tabList),
          child: Component.text('x'),
        ),
      );

      expect(
        find
            .tag('div')
            .evaluate()
            .any(
              (e) =>
                  (e.component as DomComponent).attributes?['role'] ==
                  'tablist',
            ),
        isTrue,
      );
    });
  });

  group('the ARIA vocabulary stays well-formed', () {
    test('every role has a lower-case, unspaced spelling', () {
      for (final role in CoreSemanticRole.values) {
        final aria = role.ariaRole;

        expect(aria, isNotEmpty, reason: '${role.name} has no ARIA spelling');
        expect(
          aria,
          equals(aria.toLowerCase()),
          reason: 'ARIA role tokens are lower-case; ${role.name} is "$aria"',
        );
        expect(
          aria.contains(' '),
          isFalse,
          reason: '${role.name} emits "$aria", which is two tokens',
        );
      }
    });

    test('no two roles share a spelling', () {
      // Two Core roles collapsing onto one ARIA name would make the
      // distinction invisible on Web while staying visible on Flutter —
      // the asymmetry this seat exists to remove.
      final seen = <String, CoreSemanticRole>{};

      for (final role in CoreSemanticRole.values) {
        final clash = seen[role.ariaRole];

        expect(
          clash,
          isNull,
          reason:
              '${role.name} and ${clash?.name} both emit '
              '"${role.ariaRole}"',
        );
        seen[role.ariaRole] = role;
      }
    });
  });
}
