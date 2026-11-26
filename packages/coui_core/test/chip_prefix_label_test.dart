// The key a filter chip draws in front of its value ("필터" before "전체").
//
// What Core owns here is the table both platforms read: the key's role on
// every size row, its resting colour column, and the name a reader hears.
// The resolvers' half — that the role and colour actually reach the drawn
// key — is read back on each platform.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('Chip prefix label — Core table', () {
    test(
      'each size row states the key as a ROLE, one step below its label',
      () {
        const roles = {
          CoreChipSize.sm: CoreTextStyles.labelXs,
          CoreChipSize.md: CoreTextStyles.labelSmall,
          CoreChipSize.lg: CoreTextStyles.labelMedium,
        };
        for (final size in CoreChipSize.values) {
          final row = CoreChipStyle.defaultsBySize[size]!;
          final key = row.prefixLabelStyle!;
          expect(key.token, roles[size], reason: '${size.name} role');
          // A role, not a scalar overlay — the role carries size, tracking and
          // line height together. A `fontSize` here would keep the base role's
          // tracking on a different size.
          expect(key.fontSize, isNull, reason: '${size.name} no size overlay');
          // The role's own 500, as is the value beside it.
          expect(
            key.fontWeight,
            isNull,
            reason: '${size.name} no weight overlay',
          );
          expect(
            row.labelStyle!.fontWeight,
            isNull,
            reason: "${size.name} the value keeps its role's 500",
          );
          expect(key.color, isNull, reason: '${size.name} colour is by state');
        }
      },
    );

    test('the key roles are 11 / 12 / 13 at weight 500', () {
      // Read through the scale, so a role that moved would show here.
      const typography = CoreTypography.coui;
      expect(typography.labelXs.fontSize, 11);
      expect(typography.labelSmall.fontSize, 12);
      expect(typography.labelMedium.fontSize, 13);
      for (final role in [
        typography.labelXs,
        typography.labelSmall,
        typography.labelMedium,
      ]) {
        expect(role.fontWeight, CoreFontWeight.medium);
      }
    });

    test('the flat default is the default size row', () {
      expect(
        CoreChipStyle.defaultPrefixLabelStyle,
        CoreChipStyle
            .defaultsBySize[CoreChipSize.defaultSize]!
            .prefixLabelStyle,
      );
    });

    test('the resting key colour is one column, the same in every row', () {
      final rows = CoreChipStyle.defaultsByColor.values.toList();
      for (final row in rows) {
        expect(
          row.unselectedPrefixFg,
          const CoreColor.token(CoreColors.onSurfaceVariant),
        );
        // One column for both emphases: quieter than the high resting value
        // it sits beside, the same ink as the low one — there the pair is
        // told apart by role alone. The docs state both halves.
        expect(row.unselectedPrefixFg, isNot(row.unselectedFg));
        expect(row.unselectedPrefixFg, row.lowUnselectedFg);
      }
    });

    test('prefixLabelStyle goes through merge · copyWith · == · hashCode', () {
      const override = CoreTextStyle(color: CoreColor.token(CoreColors.error));
      const style = CoreChipStyle(prefixLabelStyle: override);
      expect(const CoreChipStyle().merge(style).prefixLabelStyle, override);
      expect(
        const CoreChipStyle().copyWith(prefixLabelStyle: override),
        style,
      );
      expect(style, isNot(const CoreChipStyle()));
      expect(style.hashCode, isNot(const CoreChipStyle().hashCode));
    });

    test('merge layers a caller overlay over the row role', () {
      final row = CoreChipStyle.defaultsBySize[CoreChipSize.lg]!;
      final merged = row.merge(
        const CoreChipStyle(
          prefixLabelStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.error),
          ),
        ),
      );
      expect(merged.prefixLabelStyle!.token, CoreTextStyles.labelMedium);
      expect(
        merged.prefixLabelStyle!.color,
        const CoreColor.token(CoreColors.error),
      );
    });

    test('the accessible name reads key then value', () {
      expect(
        CoreChipContract.accessibleName(prefixLabel: '필터', label: '전체'),
        '필터 전체',
      );
      expect(CoreChipContract.accessibleName(label: '전체'), '전체');
      expect(CoreChipContract.accessibleName(prefixLabel: '필터'), '필터');
      expect(CoreChipContract.accessibleName(), '');
    });
  });
}
