// The palette's row, search row, list and heading chrome on Web — read from
// the resolver and from the SSR markup. The Flutter twin reads the same rows
// back from the painted tree
// (`coui_flutter/test/components/control/command_row_chrome_test.dart`).

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Future<String> _render(ServerTester tester, Component child) async {
  tester.pumpComponent(CoUIWeb(theme: .coui, child: child));
  return (await tester.request('/')).body;
}

/// The `class` of the `<svg>` that draws [glyph].
String _iconClass(String html, String glyph) {
  final m = RegExp(
    '<svg class="([^"]*)"[^>]*data-icon="lucide:$glyph"',
  ).firstMatch(html);
  expect(m, isNotNull, reason: 'no $glyph glyph in the markup');
  return m!.group(1)!;
}

/// The `style` of the element whose `class` attribute starts with [prefix].
String _styleOf(String html, String prefix) {
  final m = RegExp('class="$prefix[^"]*" style="([^"]*)"').firstMatch(html);
  expect(m, isNotNull, reason: 'no element with class $prefix');
  return m!.group(1)!;
}

Command _palette({
  CoreCommandPresentation presentation = .inline,
  CoreCommandSize size = .md,
  void Function()? onDismiss,
}) => Command(
  presentation: presentation,
  size: size,
  onDismiss: onDismiss,
  onSelect: (_) {},
  groups: const [
    CoreCommandGroup(
      heading: 'Suggestions',
      items: [
        CoreCommandItem(
          value: 'a',
          label: 'Calendar',
          icon: Icon(LucideIcons.calendar),
        ),
        CoreCommandItem(
          value: 'b',
          label: 'Home',
          icon: Icon(LucideIcons.house),
        ),
        CoreCommandItem(
          value: 'c',
          label: 'Off',
          enabled: false,
          icon: Icon(LucideIcons.heart),
        ),
      ],
    ),
  ],
);

void main() {
  group('search row', () {
    for (final size in CoreCommandSize.values) {
      testServer('${size.name}: 12 across, a 10 gap, an on-surface-variant '
          'glyph', (tester) async {
        final html = await _render(tester, _palette(size: size));
        final header = _styleOf(html, 'flex items-center border-');
        expect(
          header,
          contains(
            'padding: var(--coui-space-0) var(--coui-space-12) '
            'var(--coui-space-0) var(--coui-space-12)',
          ),
        );
        expect(_iconClass(html, 'search').split(' '), [
          'text-on-surface-variant',
        ]);
        expect(html, contains('flex-basis: var(--coui-space-10)'));
      });
    }

    testServer('a dialog that can be dismissed names Escape on the search '
        'row', (tester) async {
      final html = await _render(
        tester,
        _palette(presentation: .dialog, onDismiss: () {}),
      );
      final header = html.substring(
        html.indexOf('class="flex items-center border-'),
        html.indexOf('-listbox" class='),
      );
      expect(header, contains('aria-label="esc"'));
    });

    testServer('inline, or a dialog that cannot be dismissed, names nothing', (
      tester,
    ) async {
      for (final component in [
        _palette(onDismiss: () {}),
        _palette(presentation: .dialog),
      ]) {
        final html = await _render(tester, component);
        final header = html.substring(
          html.indexOf('class="flex items-center border-'),
          html.indexOf('-listbox" class='),
        );
        expect(header, isNot(contains('aria-label="esc"')));
      }
    });
  });

  group('row', () {
    const insets = {
      CoreCommandSize.sm: ('4', '10'),
      CoreCommandSize.md: ('8', '10'),
      CoreCommandSize.lg: ('10', '12'),
    };
    for (final MapEntry(key: size, value: (v, h)) in insets.entries) {
      testServer('${size.name}: insets $v · $h, a 10 gap', (tester) async {
        final html = await _render(tester, _palette(size: size));
        expect(
          _styleOf(html, 'co-command-row'),
          contains(
            'padding: var(--coui-space-$v) var(--coui-space-$h) '
            'var(--coui-space-$v) var(--coui-space-$h)',
          ),
        );
      });
    }

    testServer('the active fill is surface-container', (tester) async {
      final html = await _render(tester, _palette());
      final active = RegExp(
        'class="(co-command-row[^"]*)"',
      ).firstMatch(html)!.group(1)!;
      expect(active.split(' '), contains('bg-surface-container'));
    });

    testServer('the glyph is on-surface on the active row, '
        'on-surface-variant at rest and the disabled token when disabled', (
      tester,
    ) async {
      final html = await _render(tester, _palette());
      expect(_iconClass(html, 'calendar').split(' '), ['text-on-surface']);
      expect(_iconClass(html, 'house').split(' '), [
        'text-on-surface-variant',
      ]);
      expect(_iconClass(html, 'heart').split(' '), [
        'text-disabled-content',
      ]);
    });
  });

  group('list and heading', () {
    for (final presentation in CoreCommandPresentation.values) {
      testServer('${presentation.name}: an 8 inset and a 2 gap', (
        tester,
      ) async {
        final html = await _render(
          tester,
          _palette(presentation: presentation),
        );
        final list = RegExp(
          r'id="coui-command-\d+-listbox" class="[^"]*" style="([^"]*)"',
        ).firstMatch(html)!.group(1)!;
        expect(
          list,
          contains(
            'padding: var(--coui-space-8) var(--coui-space-8) '
            'var(--coui-space-8) var(--coui-space-8)',
          ),
        );
        expect(list, contains('gap: var(--coui-space-2)'));
      });
    }

    const ends = {
      CoreCommandSize.sm: '8',
      CoreCommandSize.md: '12',
      CoreCommandSize.lg: '16',
    };
    for (final MapEntry(key: size, value: end) in ends.entries) {
      testServer('${size.name}: the heading is 10 where the text starts, $end '
          'where it ends and 6 above and below — logical sides', (
        tester,
      ) async {
        final html = await _render(tester, _palette(size: size));
        final heading = RegExp(
          'style="([^"]*)" role="presentation" data-group="0"',
        ).firstMatch(html)!.group(1)!;
        expect(heading, contains('padding-block-start: var(--coui-space-6)'));
        expect(heading, contains('padding-block-end: var(--coui-space-6)'));
        expect(
          heading,
          contains('padding-inline-start: var(--coui-space-10)'),
        );
        expect(
          heading,
          contains('padding-inline-end: var(--coui-space-$end)'),
        );
      });
    }
  });

  group('footer', () {
    testServer('a dialog names Escape on its search row, not in its footer', (
      tester,
    ) async {
      final html = await _render(
        tester,
        _palette(presentation: .dialog, onDismiss: () {}),
      );
      expect(RegExp('aria-label="esc"').allMatches(html).length, 1);
      expect(html, isNot(contains('>Close<')));
    });

    testServer('an inline palette with a footer still names Escape there', (
      tester,
    ) async {
      final html = await _render(
        tester,
        Command(
          showFooter: true,
          onDismiss: () {},
          onSelect: (_) {},
          groups: const [],
        ),
      );
      expect(html, contains('Close'));
      expect(RegExp('aria-label="esc"').allMatches(html).length, 1);
    });
  });
}
