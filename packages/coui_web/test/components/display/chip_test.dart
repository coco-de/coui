import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/chip/chip.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('Chip', () {
    testComponents('renders label text', (tester) async {
      pumpWithTheme(tester, Chip(label: 'Filter'));

      expect(find.text('Filter'), findsOneComponent);
    });

    testComponents('renders a custom child, bypassing label', (
      tester,
    ) async {
      pumpWithTheme(tester, Chip(child: Component.text('Custom chip')));

      expect(find.text('Custom chip'), findsOneComponent);
    });

    testComponents('renders leading and trailing slots', (tester) async {
      pumpWithTheme(
        tester,
        Chip(
          label: 'Tag',
          leading: Component.text('L'),
          trailing: Component.text('T'),
        ),
      );

      expect(find.text('L'), findsOneComponent);
      expect(find.text('Tag'), findsOneComponent);
      expect(find.text('T'), findsOneComponent);
    });

    test('accepts custom id', () {
      final chip = Chip(label: 'Tag', id: 'chip-1');
      expect(chip.id, equals('chip-1'));
    });

    test('copyWith preserves properties', () {
      final original = Chip(
        label: 'Tag',
        chipColor: CoreChipColor.primary,
        selected: true,
        enabled: false,
        id: 'chip-orig',
      );

      final copy = original.copyWith(id: 'chip-new');

      expect(copy.id, equals('chip-new'));
      expect(copy.label, equals('Tag'));
      expect(copy.chipColor, equals(CoreChipColor.primary));
      expect(copy.selected, isTrue);
      expect(copy.enabled, isFalse);
    });

    test('implements CoreChipContract', () {
      final chip = Chip(
        label: 'Tag',
        chipColor: CoreChipColor.primary,
        size: CoreChipSize.lg,
        selected: true,
      );

      expect(chip.label, equals('Tag'));
      expect(chip.chipColor, equals(CoreChipColor.primary));
      expect(chip.size, equals(CoreChipSize.lg));
      expect(chip.selected, isTrue);
    });
  });
}
