// CoreFormStyle's `actionSpacing` slot (Figma "❖ Form" actions row —
// primaryAction/secondaryAction default-render Submit/Cancel buttons,
// spaced by this value), added 2026-09-11.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('defaults', () {
    test('defaultActionSpacing is 8px, matching CoreDialogStyle', () {
      expect(CoreFormStyle.defaultActionSpacing, CoreSpace.space8);
    });

    test('defaultRowSpacing is unaffected by the new field', () {
      expect(CoreFormStyle.defaultRowSpacing, CoreSpace.space24);
    });
  });

  group('merge', () {
    test('null other returns this', () {
      const a = CoreFormStyle(actionSpacing: 12);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('actionSpacing: right-most non-null wins', () {
      const base = CoreFormStyle(actionSpacing: 8);
      const over = CoreFormStyle(actionSpacing: 16);
      expect(base.merge(over).actionSpacing, 16);
      expect(over.merge(base).actionSpacing, 8);
    });

    test('actionSpacing is independent of rowSpacing during merge', () {
      const base = CoreFormStyle(rowSpacing: 24, actionSpacing: 8);
      const over = CoreFormStyle(actionSpacing: 16);
      final merged = base.merge(over);
      expect(merged.rowSpacing, 24);
      expect(merged.actionSpacing, 16);
    });
  });

  group('copyWith', () {
    test('replaces only actionSpacing; rowSpacing untouched', () {
      const a = CoreFormStyle(rowSpacing: 24);
      final b = a.copyWith(actionSpacing: 16);
      expect(b.rowSpacing, 24);
      expect(b.actionSpacing, 16);
    });
  });

  group('== / hashCode', () {
    test('equal when both fields match', () {
      const a = CoreFormStyle(rowSpacing: 24, actionSpacing: 8);
      const b = CoreFormStyle(rowSpacing: 24, actionSpacing: 8);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when only actionSpacing differs', () {
      const a = CoreFormStyle(rowSpacing: 24, actionSpacing: 8);
      const b = CoreFormStyle(rowSpacing: 24, actionSpacing: 16);
      expect(a == b, isFalse);
      expect(a.hashCode, isNot(b.hashCode));
    });
  });
}
