import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/validation_badge/validation_badge.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

Map<String, String> _root() {
  final spans = find
      .tag('span')
      .evaluate()
      .map((e) => e.component as DomComponent)
      .where((s) => s.styles?.properties['height'] != null);
  return spans.first.styles!.properties;
}

void main() {
  group('ValidationBadge geometry (Web)', () {
    testComponents('heights are 20 · 24 · 28', (tester) async {
      for (final entry in {
        CoreValidationBadgeSize.extraSmall: 20,
        CoreValidationBadgeSize.small: 24,
        CoreValidationBadgeSize.medium: 28,
      }.entries) {
        pumpWithTheme(
          tester,
          ValidationBadge(
            label: 'Valid',
            state: CoreValidationState.valid,
            size: entry.key,
          ),
        );
        expect(_root()['height'], '${entry.value / 16}rem');
      }
    });

    testComponents('draws no border by default, and a width brings it back', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ValidationBadge(label: 'Valid', state: CoreValidationState.valid),
      );
      expect(_root()['border-width'], contains('stroke-width-0'));
      pumpWithTheme(
        tester,
        const ValidationBadge(
          label: 'Valid',
          state: CoreValidationState.valid,
          style: CoreValidationBadgeStyle(borderWidth: 1),
        ),
      );
      expect(_root()['border-width'], contains('stroke-width-1'));
    });

    testComponents('the sides and gap follow the size', (tester) async {
      pumpWithTheme(
        tester,
        const ValidationBadge(
          label: 'Valid',
          state: CoreValidationState.valid,
          size: CoreValidationBadgeSize.medium,
        ),
      );
      final styles = _root();
      expect(styles['padding'], contains('space-10'));
      expect(styles['gap'], contains('space-6'));
    });
  });
}
