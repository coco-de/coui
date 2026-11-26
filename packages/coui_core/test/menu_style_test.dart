// Tests for CoreMenuStyle defaults (#5967).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreMenuStyle group heading', () {
    test('is the labelSmall role as it stands, in the subtle ink', () {
      const heading = CoreMenuStyle.defaultLabelTextStyle;

      expect(heading.token, CoreTextStyles.labelSmall);
      // The role states 12 Medium; the slot writes no weight over it.
      expect(heading.fontWeight, isNull);
      expect(heading.color, const CoreColor.token(CoreColors.onSurfaceSubtle));
    });

    test('leaves 4 below the heading and 4 either side of a divider', () {
      expect(CoreMenuStyle.defaultLabelBottomInset, CoreSpace.space4);
      expect(CoreMenuStyle.defaultLabelBottomInset, 4);
      expect(CoreMenuStyle.defaultDividerInset, CoreSpace.space4);
      expect(CoreMenuStyle.defaultDividerInset, 4);
    });
  });

  group('CoreMenuStyle label and divider insets', () {
    test('merge — a stated inset wins, an unstated one is kept', () {
      const base = CoreMenuStyle(labelBottomInset: 2, dividerInset: 6);
      final merged = base.merge(const CoreMenuStyle(dividerInset: 8));

      expect(merged.labelBottomInset, 2);
      expect(merged.dividerInset, 8);
    });

    test('copyWith / == / hashCode carry both fields', () {
      const a = CoreMenuStyle(labelBottomInset: 2, dividerInset: 6);
      final b = a.copyWith(dividerInset: 6);
      final c = a.copyWith(labelBottomInset: 3);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a.copyWith(dividerInset: 7), isNot(a));
    });
  });
}
