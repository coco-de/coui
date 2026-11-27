import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/layout/card/card.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  final cases = [
    (
      name: 'directional declarations retain start and end',
      input: const CoreEdgeInsets.directional(
        start: 12,
        top: 4,
        end: 8,
        bottom: 16,
      ),
      expected: const {
        'padding-block-start': 'var(--coui-space-4)',
        'padding-block-end': 'var(--coui-space-16)',
        'padding-inline-start': 'var(--coui-space-12)',
        'padding-inline-end': 'var(--coui-space-8)',
      },
    ),
    (
      name: 'physical asymmetric shorthand is unchanged',
      input: const CoreEdgeInsets.fromLTRB(12, 4, 8, 16),
      expected: const {
        'padding':
            'var(--coui-space-4) var(--coui-space-8) '
            'var(--coui-space-16) var(--coui-space-12)',
      },
    ),
    (
      name: 'default shorthand is unchanged',
      input: null,
      expected: const {
        'padding':
            'var(--coui-space-20) var(--coui-space-24) '
            'var(--coui-space-20) var(--coui-space-24)',
      },
    ),
  ];

  for (final route in ['slots', 'child', 'children']) {
    for (final row in cases) {
      for (final direction in ['ltr', 'rtl']) {
        testComponents('$route/${row.name}/$direction', (tester) async {
          const body = Component.text('public content');
          final style = CoreCardStyle(padding: row.input);
          final card = switch (route) {
            'slots' => Card(
              id: 'card-under-test',
              body: body,
              cardStyle: style,
            ),
            'child' => Card(
              id: 'card-under-test',
              child: body,
              cardStyle: style,
            ),
            _ => Card(
              id: 'card-under-test',
              children: const [body, Component.text('second public child')],
              cardStyle: style,
            ),
          };
          pumpWithTheme(
            tester,
            div([card], attributes: {'dir': direction}),
          );
          expect(find.text('public content'), findsOneComponent);
          if (route == 'children') {
            expect(find.text('second public child'), findsOneComponent);
          }
          // Caller-authored id identifies the actual mounted public root.
          // Its exact direct wrapper is inspected; no style/class search
          // chooses the owner and no component builder is replayed.
          final roots = find
              .tag('div')
              .evaluate()
              .where(
                (element) =>
                    (element.component as DomComponent).id == 'card-under-test',
              )
              .toList();
          expect(roots, hasLength(1));
          final wrappers = <Element>[];
          roots.single.visitChildren(wrappers.add);
          expect(wrappers, hasLength(1));
          expect(wrappers.single.component, isA<div>());
          final hosts = <Element>[];
          wrappers.single.visitChildren(hosts.add);
          expect(hosts, hasLength(1));
          expect(hosts.single.component, isA<DomComponent>());
          final content = hosts.single.component as DomComponent;
          expect(content.tag, 'div');
          final declarations = content.styles!.properties;
          final actualPadding = {
            for (final entry in declarations.entries)
              if (entry.key.startsWith('padding')) entry.key: entry.value,
          };
          expect(actualPadding, row.expected);
        });
      }
    }
  }
}
