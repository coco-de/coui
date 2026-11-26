// The ARIA APG menu pattern requires `role="separator"` on the divider
// that marks a boundary between item groups — this file asserts `Menu`
// states it (#3497) without leaking it onto a decorative `Divider` used
// outside a `Menu` (the over-announce guard lives in
// `../display/divider_test.dart`).

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Component _menu() => const Menu(
  items: [
    CoreMenuItem<Component>.action('First'),
    CoreMenuItem<Component>.divider(),
    CoreMenuItem<Component>.action('Second'),
  ],
);

void main() {
  group('Menu hosted corners (#5967)', () {
    for (final size in CoreMenuItemSize.values) {
      for (final vertical in [true, false]) {
        testServer('$size vertical=$vertical renders the copy’s 8', (
          tester,
        ) async {
          tester.pumpComponent(
            CoUIWeb(
              theme: .coui,
              child: Menu(
                size: size,
                vertical: vertical,
                items: const [CoreMenuItem<Component>.action('Open')],
              ),
            ),
          );
          final response = await tester.request('/');
          final rows = response.document!.querySelectorAll('[role="menuitem"]');
          expect(rows, hasLength(1));
          expect(
            rows.single.attributes['style'],
            contains(
              'border-radius: '
              'var(--coui-radius-8) var(--coui-radius-8) '
              'var(--coui-radius-8) var(--coui-radius-8)',
            ),
          );
        });
      }
    }

    for (final corner in [null, 10.0]) {
      testServer('theme row 4 with instance corner $corner and padding', (
        tester,
      ) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: ThemeData.coui.copyWith(
              coreComponentTheme: const CoreComponentTheme(
                menu: CoreMenuTheme(
                  style: CoreMenuStyle(
                    itemStyle: CoreMenuItemStyle(
                      borderRadius: CoreBorderRadius.all(4),
                    ),
                  ),
                ),
              ),
            ),
            child: Menu(
              items: const [CoreMenuItem<Component>.action('Open')],
              menuStyle: CoreMenuStyle(
                itemStyle: CoreMenuItemStyle(
                  padding: const CoreEdgeInsets.all(6),
                  borderRadius: corner == null
                      ? null
                      : CoreBorderRadius.all(corner),
                ),
              ),
            ),
          ),
        );
        final response = await tester.request('/');
        final row = response.document!.querySelector('[role="menuitem"]')!;
        final radius = (corner ?? 4).toInt();
        final corners = List.filled(4, 'var(--coui-radius-$radius)').join(' ');
        expect(row.attributes['style'], contains('border-radius: $corners'));
      });
    }
  });

  group('Menu accessibility (#3497)', () {
    testServer('the divider between item groups exposes role="separator"', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _menu()));
      final response = await tester.request('/');
      final separators = response.document?.querySelectorAll(
        '[role="separator"]',
      );

      expect(separators, hasLength(1));
    });

    testServer('the menu itself still states role="menu"', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _menu()));
      final response = await tester.request('/');
      final menus = response.document?.querySelectorAll('[role="menu"]');

      expect(menus, hasLength(1));
    });
  });

  group('Menu group title', () {
    testServer('reads onSurfaceSubtle at 12 Medium, not the variant ink', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const Menu(
            items: [
              CoreMenuItem<Component>.label('Navigation'),
              CoreMenuItem<Component>.action('Home'),
            ],
          ),
        ),
      );
      final response = await tester.request('/');
      final title = response.document!
          .querySelectorAll('span')
          .firstWhere(
            (e) =>
                e.text.trim() == 'Navigation' &&
                (e.attributes['class'] ?? '').contains('text-label-small'),
          );

      // The role states the weight (Medium) — no weight class on top of it.
      expect(title.attributes['class'], isNot(contains('font-semibold')));
      expect(
        title.attributes['style'],
        contains('color: rgb(var(--coui-on-surface-subtle))'),
      );
      expect(
        title.attributes['style'],
        isNot(contains('on-surface-variant')),
      );
    });
  });

  group('Menu label and divider room (#5967)', () {
    testServer('the heading keeps its 4 bottom inset under the row inset', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const Menu(
            items: [
              CoreMenuItem<Component>.label('Navigation'),
              CoreMenuItem<Component>.action('Home'),
            ],
          ),
        ),
      );
      final response = await tester.request('/');
      final heading = response.document!
          .querySelectorAll('[role="presentation"]')
          .firstWhere((e) => e.text.contains('Navigation'));
      final padding = heading.attributes['style'] ?? '';

      // 6 · 8 · 4 · 8 — the default (sm) row's top and sides, the heading's
      // own bottom.
      expect(
        padding,
        contains(
          'padding: var(--coui-space-6) var(--coui-space-8) '
          'var(--coui-space-4) var(--coui-space-8)',
        ),
      );
    });

    testServer('the heading follows the row ladder of the size it is given', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const Menu(
            size: CoreMenuItemSize.md,
            items: [
              CoreMenuItem<Component>.label('Navigation'),
              CoreMenuItem<Component>.action('Home'),
            ],
          ),
        ),
      );
      final response = await tester.request('/');
      final heading = response.document!
          .querySelectorAll('[role="presentation"]')
          .firstWhere((e) => e.text.contains('Navigation'));

      // 8 · 10 · 4 · 10 — the md row's top and sides, the heading's own bottom.
      expect(
        heading.attributes['style'] ?? '',
        contains(
          'padding: var(--coui-space-8) var(--coui-space-10) '
          'var(--coui-space-4) var(--coui-space-10)',
        ),
      );
    });

    testServer(
      'a divider entry sits in a holder that keeps 4 above and below',
      (
        tester,
      ) async {
        tester.pumpComponent(CoUIWeb(theme: .coui, child: _menu()));
        final response = await tester.request('/');
        final separator = response.document!.querySelector(
          '[role="separator"]',
        )!;
        final holder = separator.parent!;
        final style = holder.attributes['style'] ?? '';

        expect(holder.attributes['role'], 'presentation');
        expect(style, contains('padding-top: var(--coui-space-4)'));
        expect(style, contains('padding-bottom: var(--coui-space-4)'));
      },
    );

    testServer('a bar leaves its dividers without a holder inset', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const Menu(
            vertical: false,
            items: [
              CoreMenuItem<Component>.action('First'),
              CoreMenuItem<Component>.divider(),
              CoreMenuItem<Component>.action('Second'),
            ],
          ),
        ),
      );
      final response = await tester.request('/');
      final separator = response.document!.querySelector('[role="separator"]')!;

      expect(
        separator.parent!.attributes['style'] ?? '',
        isNot(contains('padding')),
      );
    });
  });
}
