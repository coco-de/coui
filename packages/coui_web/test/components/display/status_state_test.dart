import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/status/status.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The `style` map of the first `<span>` that carries [property].
Map<String, String> _spanWith(String property) {
  final spans = find
      .tag('span')
      .evaluate()
      .map((e) => e.component as DomComponent)
      .where((s) => s.styles?.properties[property] != null);
  return spans.first.styles!.properties;
}

String _classesOfSpanWith(String property) {
  final spans = find
      .tag('span')
      .evaluate()
      .map((e) => e.component as DomComponent)
      .where((s) => s.styles?.properties[property] != null);
  return spans.first.classes ?? '';
}

void main() {
  group('Status state (Web)', () {
    testComponents('sizes are 6 · 8 · 10 · 12 · 14', (tester) async {
      for (final entry in {
        CoreStatusSize.xs: 6,
        CoreStatusSize.sm: 8,
        CoreStatusSize.md: 10,
        CoreStatusSize.lg: 12,
        CoreStatusSize.xl: 14,
      }.entries) {
        pumpWithTheme(
          tester,
          Status(variant: CoreStatusVariant.online, size: entry.key),
        );
        expect(_spanWith('width')['width'], '${entry.value / 16}rem');
      }
    });

    testComponents('online is filled, no ring', (tester) async {
      pumpWithTheme(tester, Status(variant: CoreStatusVariant.online));
      final styles = _spanWith('width');
      expect(styles['border-style'], isNull);
      expect(_classesOfSpanWith('width'), contains('bg-'));
    });

    for (final state in [CoreStatusVariant.away, CoreStatusVariant.offline]) {
      testComponents('$state is a 2px ring', (tester) async {
        pumpWithTheme(tester, Status(variant: state));
        final styles = _spanWith('width');
        expect(styles['border-style'], 'solid');
        expect(styles['border-width'], contains('stroke-width-2'));
        final classes = _classesOfSpanWith('width');
        expect(classes, contains('border-'));
        expect(classes, isNot(contains('bg-')));
      });
    }

    testComponents('busy draws a 6 x 2 bar at md', (tester) async {
      pumpWithTheme(tester, Status(variant: CoreStatusVariant.busy));
      final bar = _spanWith('height');
      // The dot (10) and the bar (2) both carry a height; the bar is the one
      // narrower than the dot.
      final spans = find
          .tag('span')
          .evaluate()
          .map((e) => (e.component as DomComponent).styles?.properties)
          .whereType<Map<String, String>>()
          .where((p) => p['width'] == '${6 / 16}rem');
      expect(spans, hasLength(1));
      expect(spans.first['height'], '${2 / 16}rem');
      expect(bar, isNotEmpty);
    });

    testComponents('busy bar length is 4 · 4 · 6 · 8 · 8 by size', (
      tester,
    ) async {
      for (final entry in {
        CoreStatusSize.xs: 4,
        CoreStatusSize.sm: 4,
        CoreStatusSize.md: 6,
        CoreStatusSize.lg: 8,
        CoreStatusSize.xl: 8,
      }.entries) {
        pumpWithTheme(
          tester,
          Status(variant: CoreStatusVariant.busy, size: entry.key),
        );
        final bars = find
            .tag('span')
            .evaluate()
            .map((e) => (e.component as DomComponent).styles?.properties)
            .whereType<Map<String, String>>()
            .where((p) => p['height'] == '${2 / 16}rem');
        expect(bars, hasLength(1), reason: '${entry.key}');
        expect(bars.first['width'], '${entry.value / 16}rem');
      }
    });

    testComponents('the offline ring is outline, away is warning', (
      tester,
    ) async {
      pumpWithTheme(tester, Status(variant: CoreStatusVariant.offline));
      expect(_classesOfSpanWith('width'), contains('border-outline'));
      pumpWithTheme(tester, Status(variant: CoreStatusVariant.away));
      expect(_classesOfSpanWith('width'), contains('border-warning'));
    });

    testComponents('label reads on-surface, offline alone on-surface-variant', (
      tester,
    ) async {
      for (final state in CoreStatusVariant.values) {
        pumpWithTheme(
          tester,
          Status(variant: state, label: const Component.text('x')),
        );
        final labelColor = state == CoreStatusVariant.offline
            ? 'text-on-surface-variant'
            : 'text-on-surface';
        final spans = find
            .tag('span')
            .evaluate()
            .map((e) => (e.component as DomComponent).classes ?? '')
            .where((c) => c.split(' ').contains(labelColor));
        expect(spans, isNotEmpty, reason: '$state');
      }
    });

    testComponents('a visible label sits beside the dot with the size gap', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Status(
          variant: CoreStatusVariant.online,
          size: CoreStatusSize.lg,
          label: const Component.text('Online'),
        ),
      );
      final wrapper = _spanWith('gap');
      expect(wrapper['gap'], contains('space-8'));
      expect(find.text('Online'), findsOneComponent);
    });

    testComponents('no state keeps the plain dot', (tester) async {
      pumpWithTheme(tester, Status(color: CoreStatusColor.success));
      final styles = _spanWith('width');
      expect(styles['border-style'], isNull);
    });
  });
}
