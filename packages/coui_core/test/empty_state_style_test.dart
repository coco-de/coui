// Tests for CoreEmptyStateStyle's variant and tone tables.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('variants', () {
    test('the widget default is normal', () {
      expect(
        CoreEmptyStateVariant.defaultVariant,
        CoreEmptyStateVariant.normal,
      );
    });

    test('compact is 24 around, a 20 glyph in a 48 box, 12 / 6 / 16', () {
      final v =
          CoreEmptyStateStyle.defaultsByVariant[CoreEmptyStateVariant.compact]!;
      expect(v.padding, const CoreEdgeInsets.all(24));
      expect(v.iconSize, 20);
      expect(v.iconBoxSize, 48);
      expect(v.iconTitleGapStyle.size, 12);
      expect(v.titleDescriptionGapStyle.size, 6);
      expect(v.descriptionActionGapStyle.size, 16);
      expect(v.minHeight, 0);
      expect(v.titleTextStyle.token, CoreTextStyles.titleSmall);
      expect(v.descriptionTextStyle.token, CoreTextStyles.bodySmall);
    });

    test('normal is 32 around, a 28 glyph in a 64 box, 16 / 8 / 24', () {
      final v =
          CoreEmptyStateStyle.defaultsByVariant[CoreEmptyStateVariant.normal]!;
      expect(v.padding, const CoreEdgeInsets.all(32));
      expect(v.iconSize, 28);
      expect(v.iconBoxSize, 64);
      expect(v.iconTitleGapStyle.size, 16);
      expect(v.titleDescriptionGapStyle.size, 8);
      expect(v.descriptionActionGapStyle.size, 24);
      expect(v.minHeight, 240);
      expect(v.titleTextStyle.token, CoreTextStyles.titleMedium);
    });

    test('large is 40 / 32 around, a 32 glyph in a 72 box, 20 / 8 / 24', () {
      final v =
          CoreEmptyStateStyle.defaultsByVariant[CoreEmptyStateVariant.large]!;
      expect(
        v.padding,
        const CoreEdgeInsets.symmetric(horizontal: 32, vertical: 40),
      );
      expect(v.iconSize, 32);
      expect(v.iconBoxSize, 72);
      expect(v.iconTitleGapStyle.size, 20);
      expect(v.titleDescriptionGapStyle.size, 8);
      expect(v.descriptionActionGapStyle.size, 24);
      expect(v.titleTextStyle.token, CoreTextStyles.titleLarge);
    });

    test('the default description is bodyMedium', () {
      expect(
        CoreEmptyStateStyle.defaultDescriptionTextStyle.token,
        CoreTextStyles.bodyMedium,
      );
    });

    test('every variant has a row', () {
      expect(
        CoreEmptyStateStyle.defaultsByVariant.keys,
        containsAll(CoreEmptyStateVariant.values),
      );
    });
  });

  group('tones', () {
    const expected = {
      CoreEmptyStateTone.neutral: (
        CoreColors.onSurfaceVariant,
        CoreColors.surfaceContainerHigh,
      ),
      CoreEmptyStateTone.failure: (CoreColors.error, CoreColors.errorContainer),
      CoreEmptyStateTone.success: (
        CoreColors.success,
        CoreColors.successContainer,
      ),
    };

    test('every tone states its glyph and box colour', () {
      for (final tone in CoreEmptyStateTone.values) {
        final row = CoreEmptyStateStyle.defaultsByTone[tone]!;
        expect(row.iconStyle!.color, CoreColor.token(expected[tone]!.$1));
        expect(row.iconBoxColor, CoreColor.token(expected[tone]!.$2));
      }
    });

    test('the icon box is a circle', () {
      expect(
        CoreEmptyStateStyle.defaultIconBoxBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    test('box fields take part in merge and equality', () {
      const a = CoreEmptyStateStyle(iconBoxSize: 10);
      final b = a.merge(const CoreEmptyStateStyle(iconBoxSize: 20));
      expect(b.iconBoxSize, 20);
      expect(a == b, isFalse);
    });
  });
}
