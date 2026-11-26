import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/indicator/indicator.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The `style` map of the overlay `<div>` (the second child of the root).
Map<String, String> _overlayStyles() {
  final divs = find
      .tag('div')
      .evaluate()
      .map((e) => e.component as DomComponent)
      .toList();
  final overlay = divs.firstWhere(
    (d) => d.styles?.properties['z-index'] != null,
  );
  return overlay.styles!.properties;
}

void main() {
  group('Indicator (Web)', () {
    testComponents(
      'the ring is a surface-coloured shadow spread outside the item',
      (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          const Indicator(
            item: Component.text('•'),
            child: Component.text('A'),
          ),
        );
        final styles = _overlayStyles();
        expect(styles['box-shadow'], contains('0 0 0'));
        expect(styles['box-shadow'], contains('--coui-surface'));
        expect(styles['box-shadow'], contains('stroke-width-2'));
        // The item's own corner meets the child's — the ring never moves it.
        expect(styles['top'], '0.0rem');
        expect(styles['right'], '0.0rem');
      },
    );

    testComponents('the ring corner is pill by default and styleable', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Indicator(
          item: Component.text('•'),
          child: Component.text('A'),
        ),
      );
      final defaultRadius = _overlayStyles()['border-radius'];
      expect(defaultRadius, isNotNull);
      pumpWithTheme(
        tester,
        const Indicator(
          item: Component.text('•'),
          indicatorStyle: CoreIndicatorStyle(
            ringBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
          child: Component.text('A'),
        ),
      );
      expect(_overlayStyles()['border-radius'], isNot(defaultRadius));
    });

    testComponents('ringWidth 0 draws no ring', (tester) async {
      pumpWithTheme(
        tester,
        const Indicator(
          item: Component.text('•'),
          child: Component.text('A'),
          indicatorStyle: CoreIndicatorStyle(ringWidth: 0),
        ),
      );
      final styles = _overlayStyles();
      expect(styles.containsKey('box-shadow'), isFalse);
    });
  });
}
