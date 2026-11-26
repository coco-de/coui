// The chip label ladder is three ROLES (`labelSmall` / `labelMedium` /
// `labelLarge` — 12 / 13 / 14), not one role with a `fontSize` overlay per
// size. Below 20px every label role states the same tracking ratio (−1%) and
// the same line-height, so the three roles part on size alone — and the
// tracking the row draws is that ratio times the role's OWN size, so it is a
// different pixel value on every row. The weight is the role's own 500 too —
// no row states one over its role.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Future<({ResolvedChip resolved, CoreTypography typography})> _resolve(
  WidgetTester tester, {
  required CoreChipSize size,
}) async {
  late ResolvedChip resolved;
  late CoreTypography typography;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: Builder(
          builder: (context) {
            typography = Theme.of(context).typography;
            resolved = resolveChip(
              context,
              variant: CoreChipVariant.outlined,
              chipColor: CoreChipColor.neutral,
              emphasis: CoreChipEmphasis.high,
              size: size,
              selected: false,
              enabled: true,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return (resolved: resolved, typography: typography);
}

void main() {
  group('Chip label role ladder', () {
    testWidgets('each size materialises its own label role', (tester) async {
      final roles = {
        CoreChipSize.sm: (CoreTypography t) => t.labelSmall,
        CoreChipSize.md: (CoreTypography t) => t.labelMedium,
        CoreChipSize.lg: (CoreTypography t) => t.labelLarge,
      };
      for (final size in CoreChipSize.values) {
        final r = await _resolve(tester, size: size);
        final role = roles[size]!(r.typography);
        final label = r.resolved.labelTextStyle;
        expect(label.fontSize, role.fontSize, reason: '${size.name} size');
        // The role's own weight — no row states one on top.
        expect(
          label.fontWeight,
          fontWeightFromInt(CoreFontWeight.medium),
          reason: '${size.name} weight',
        );
        expect(label.height, role.lineHeight, reason: '${size.name} height');
        // em → px is the conversion's job: ratio × the role's own size.
        expect(
          label.letterSpacing,
          closeTo(role.letterSpacing! * role.fontSize!, 1e-9),
          reason: '${size.name} tracking',
        );
      }
    });

    testWidgets('weight and line-height do not move across the ladder', (
      tester,
    ) async {
      final md = (await _resolve(tester, size: CoreChipSize.md)).resolved;
      for (final size in [CoreChipSize.sm, CoreChipSize.lg]) {
        final other = (await _resolve(tester, size: size)).resolved;
        expect(other.labelTextStyle.fontWeight, md.labelTextStyle.fontWeight);
        expect(other.labelTextStyle.height, md.labelTextStyle.height);
      }
    });

    testWidgets("sm tracking is its own size's, not labelMedium's pixels", (
      tester,
    ) async {
      // The ratio is shared below 20px, so what keeps sm apart is the size
      // the ratio is multiplied by: labelSmall's own, not the md row's.
      // A conversion that reused one row's pixels for every row would draw
      // md's tracking on sm.
      final r = await _resolve(tester, size: CoreChipSize.sm);
      final own = r.typography.labelSmall;
      final md = r.typography.labelMedium;
      expect(
        own.fontSize,
        isNot(md.fontSize),
        reason: 'if the two roles were one size this would tell nothing apart',
      );
      expect(
        r.resolved.labelTextStyle.letterSpacing,
        closeTo(own.letterSpacing! * own.fontSize!, 1e-9),
      );
      expect(
        r.resolved.labelTextStyle.letterSpacing,
        isNot(closeTo(md.letterSpacing! * md.fontSize!, 1e-9)),
      );
    });
  });
}
