import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kItems = [
  CoreTimelineItem(
    title: 'Created',
    timestamp: '2 hours ago',
    description: 'Welcome email sent to the address on file.',
  ),
  CoreTimelineItem(
    title: 'Updated',
    timestamp: '1 hour ago',
    description: 'Display name and avatar changed.',
  ),
];

/// Every element the rendered `Timeline` emitted, as the markup carries it.
Iterable<DomComponent> _rendered(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

bool _hasClass(DomComponent c, String name) =>
    (c.classes ?? '').split(' ').contains(name);

Iterable<DomComponent> _withClass(ComponentTester tester, String name) =>
    _rendered(tester).where((c) => _hasClass(c, name));

String? _style(DomComponent c, String property) =>
    c.styles?.properties[property];

void main() {
  group('Timeline redesign defaults (rendered markup)', () {
    testComponents('the dot is a 10 px circle in the primary colour', (
      tester,
    ) async {
      pumpWithTheme(tester, const Timeline(items: _kItems));

      final dots = _withClass(tester, 'bg-primary').toList();
      expect(dots, hasLength(2));
      for (final dot in dots) {
        // 10 px at a 16 px root.
        expect(_style(dot, 'width'), '0.625rem');
        expect(_style(dot, 'height'), '0.625rem');
        expect(_style(dot, 'border-radius'), 'var(--coui-radius-9999)');
      }
    });

    testComponents('the dot is seated 5 px down, as a pinned length', (
      tester,
    ) async {
      pumpWithTheme(tester, const Timeline(items: _kItems));

      final dot = _withClass(tester, 'bg-primary').first;
      // 5 is the centre of the title's first line less half the dot, not a
      // spacing step — so it must not name a spacing variable.
      expect(_style(dot, 'margin-top'), pinnedLengthCss(5));
      expect(_style(dot, 'margin-top'), '0.3125rem');
      expect(_style(dot, 'margin-top'), isNot(contains('var(')));
    });

    testComponents('the marker column is as wide as the dot', (tester) async {
      pumpWithTheme(tester, const Timeline(items: _kItems));

      // No width of its own: a flex column that centres its children is as
      // wide as the widest of them, which is the dot.
      final columns = _withClass(tester, 'items-center').toList();
      expect(columns, hasLength(2));
      for (final column in columns) {
        expect(_style(column, 'width'), isNull);
        expect(_style(column, 'min-width'), isNull);
      }
    });

    testComponents('the connector is outlineVariant, not the dot colour', (
      tester,
    ) async {
      pumpWithTheme(tester, const Timeline(items: _kItems));

      // One connector: the last item has none.
      final connectors = _withClass(tester, 'bg-outline-variant').toList();
      expect(connectors, hasLength(1));
      expect(_hasClass(connectors.single, 'bg-primary'), isFalse);
      expect(_style(connectors.single, 'width'), 'var(--coui-stroke-width-2)');
    });

    testComponents('the connector keeps a 4 gap under its dot and above the '
        'next', (tester) async {
      pumpWithTheme(tester, const Timeline(items: _kItems));

      final connector = _withClass(tester, 'bg-outline-variant').single;
      // 4 below its own dot, as a spacing variable (the gap moves with the
      // density like every other gap between elements).
      expect(_style(connector, 'margin-top'), spaceCss(4));
      // Past the bottom of its row by row spacing + dot top margin - gap
      // (16 + 5 - 4), which stops it 4 above the next dot. The row spacing
      // and the gap are spacing variables; the dot margin is a position.
      expect(
        _style(connector, 'margin-bottom'),
        'calc(-1 * (${spaceCss(16)} + ${pinnedLengthCss(5)} - '
        '${spaceCss(4)}))',
      );
    });

    testComponents('the title is the label-large role with no weight laid over '
        'it', (tester) async {
      pumpWithTheme(tester, const Timeline(items: _kItems));

      final titles = _withClass(tester, 'text-label-large').toList();
      expect(titles, hasLength(2));
      for (final title in titles) {
        expect(_hasClass(title, 'text-on-surface'), isTrue);
        // The role states the weight; a weight class on top would be the
        // overlay the size-ladder rule forbids.
        expect((title.classes ?? '').contains('font-'), isFalse);
        expect(title.styles?.properties.containsKey('font-weight'), isFalse);
        expect(title.styles?.properties.containsKey('font-size'), isFalse);
      }
      // The old title was body-medium over a semibold weight.
      expect(_withClass(tester, 'text-body-medium'), isEmpty);
    });

    testComponents('the title has no inset', (tester) async {
      pumpWithTheme(tester, const Timeline(items: _kItems));

      final title = _withClass(tester, 'text-label-large').first;
      final zero = spaceCss(0);

      expect(_style(title, 'padding'), '$zero $zero $zero $zero');
      expect(_style(title, 'padding-inline-start'), isNull);
    });

    testComponents('the description sits 2 px under the title', (
      tester,
    ) async {
      pumpWithTheme(tester, const Timeline(items: _kItems));

      final descriptions = _withClass(tester, 'text-body-small')
          .where((c) => c.styles?.properties.containsKey('margin-top') ?? false)
          .toList();
      expect(descriptions, hasLength(2));
      for (final description in descriptions) {
        expect(_style(description, 'margin-top'), spaceCss(2));
        expect(_style(description, 'margin-top'), 'var(--coui-space-2)');
      }
    });
  });

  group('Timeline overrides still win over the redesign defaults', () {
    testComponents('a caller-set dot, connector and title inset', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Timeline(
          items: _kItems,
          timelineStyle: CoreTimelineStyle(
            dotSize: CoreSpace.space16,
            dotTopMargin: CoreSpace.space8,
            connectorColor: CoreColor.token(CoreColors.primary),
            titlePadding: CoreEdgeInsets.directional(start: CoreSpace.space16),
          ),
        ),
      );

      final dot = _withClass(tester, 'bg-primary').first;
      expect(_style(dot, 'width'), '1.0rem');
      expect(_style(dot, 'margin-top'), pinnedLengthCss(CoreSpace.space8));
      // Both the dot and the connector are primary now; none is outline.
      expect(_withClass(tester, 'bg-outline-variant'), isEmpty);
      final title = _withClass(tester, 'text-label-large').first;
      expect(
        _style(title, 'padding-inline-start'),
        spaceCss(CoreSpace.space16),
      );
    });
  });
}
