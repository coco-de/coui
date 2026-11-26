// CoreFormLabelStyle — the size-keyed typography ladder (Figma "❖
// FormLabel", Size axis md/lg extended onto the shared six-tier
// CoreComponentSize scale) and the disabled-colour override, both added
// 2026-09-11.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('defaultsBySize', () {
    test('covers every CoreComponentSize member', () {
      expect(
        CoreFormLabelStyle.defaultsBySize.keys.toSet(),
        CoreComponentSize.values.toSet(),
      );
    });

    test('xs/sm/md read at the 13px (labelMedium) rung', () {
      for (final size in [
        CoreComponentSize.xs,
        CoreComponentSize.sm,
        CoreComponentSize.md,
      ]) {
        expect(
          CoreFormLabelStyle.defaultsBySize[size]!.labelStyle,
          CoreFormLabelStyle.defaultLabelStyle,
          reason: '$size should read at the 13px rung',
        );
      }
    });

    test('lg/xl/xl2 read at the 14px (labelLarge) rung', () {
      for (final size in [
        CoreComponentSize.lg,
        CoreComponentSize.xl,
        CoreComponentSize.xl2,
      ]) {
        expect(
          CoreFormLabelStyle.defaultsBySize[size]!.labelStyle,
          CoreFormLabelStyle.defaultLabelStyleLarge,
          reason: '$size should read at the 14px rung',
        );
      }
    });

    test('the two rungs read the label family at 13 / 500 and 14 / 500', () {
      const scale = CoreTypography.coui;
      final small = scale.resolve(CoreFormLabelStyle.defaultLabelStyle);
      final large = scale.resolve(CoreFormLabelStyle.defaultLabelStyleLarge);
      expect(small.fontSize, 13);
      expect(small.fontWeight, CoreFontWeight.medium);
      expect(large.fontSize, 14);
      expect(large.fontWeight, CoreFontWeight.medium);
    });

    test('defaultSize is md, matching the flat pre-ladder default', () {
      expect(CoreFormLabelStyle.defaultSize, CoreComponentSize.md);
    });
  });

  group('token values', () {
    test('defaultLabelStyle is labelMedium (13px) on-surface-variant', () {
      expect(
        CoreFormLabelStyle.defaultLabelStyle.token,
        CoreTextStyles.labelMedium,
      );
      expect(
        CoreFormLabelStyle.defaultLabelStyle.color!.token,
        CoreColors.onSurfaceVariant,
      );
    });

    test('defaultLabelStyleLarge is labelLarge (14px) on-surface-variant', () {
      expect(
        CoreFormLabelStyle.defaultLabelStyleLarge.token,
        CoreTextStyles.labelLarge,
      );
      expect(
        CoreFormLabelStyle.defaultLabelStyleLarge.color!.token,
        CoreColors.onSurfaceVariant,
      );
    });

    test('every rung of the ladder reads the label at on-surface-variant', () {
      // The colour travels with the role in one slot, so a rung that
      // restated its own would be the one label on a form that is louder or
      // quieter than the rest.
      for (final entry in CoreFormLabelStyle.defaultsBySize.entries) {
        expect(
          entry.value.labelStyle!.color,
          const CoreColor.token(CoreColors.onSurfaceVariant),
          reason: '${entry.key} label colour',
        );
      }
    });

    test('the label is a tier below the value ink, not the disabled ink', () {
      // A label names the control; the value in it is the louder line, and a
      // disabled label is a different token again (`disabledContent`, until
      // a field states its own tint).
      final label = CoreFormLabelStyle.defaultLabelStyle.color;
      expect(label, isNot(const CoreColor.token(CoreColors.onSurface)));
      expect(label, isNot(CoreFormLabelStyle.defaultDisabledColor));
    });

    test('defaultDisabledColor is disabled-content', () {
      expect(
        CoreFormLabelStyle.defaultDisabledColor.token,
        CoreColors.disabledContent,
      );
    });
  });

  group('merge / copyWith / ==', () {
    test('null other returns this', () {
      const a = CoreFormLabelStyle(disabledColor: CoreColor.transparent);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('disabledColor: right-most non-null wins', () {
      const base = CoreFormLabelStyle(disabledColor: CoreColor.transparent);
      const over = CoreFormLabelStyle(
        disabledColor: CoreColor.token(CoreColors.error),
      );
      expect(base.merge(over).disabledColor!.token, CoreColors.error);
      expect(over.merge(base).disabledColor, CoreColor.transparent);
    });

    test('copyWith replaces only disabledColor; == compares it', () {
      const a = CoreFormLabelStyle(requiredColor: CoreColor.transparent);
      final b = a.copyWith(
        disabledColor: const CoreColor.token(CoreColors.error),
      );
      expect(b.requiredColor, CoreColor.transparent);
      expect(b.disabledColor!.token, CoreColors.error);
      expect(a == b, isFalse);
      expect(a.hashCode, isNot(b.hashCode));
    });
  });
}
