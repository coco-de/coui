// Tests for the Tag contract set — `CoreTagEmphasis` / `CoreTagSize` /
// `CoreTagContract` defaults, `CoreTagStyle` and its tables, and
// `CoreTagTheme`.
//
// The expected values below are written out by hand from the decided spec
// (#5705) rather than read back from the constants, so a value moved in the
// source has to be moved here too — the pin is the decision, not a copy.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// One step of the size table, as the spec states it.
typedef _SizeRow = ({
  double height,
  double horizontalPadding,
  double radius,
  CoreTextStyleToken role,
});

const Map<CoreTagSize, _SizeRow> _kSizeTable = {
  CoreTagSize.sm: (
    height: 20,
    horizontalPadding: 6,
    radius: 4,
    role: CoreTextStyles.labelXs,
  ),
  CoreTagSize.md: (
    height: 24,
    horizontalPadding: 8,
    radius: 6,
    role: CoreTextStyles.labelSmall,
  ),
};

/// The token name of [hue]'s [slot], spelled out rather than read through
/// `CoreCategoryColor.token` — the expectation must not be the lookup under
/// test.
String _name(CoreCategoryColor hue, String slot) => switch (slot) {
  'fill' => 'category-${hue.name}',
  'onFill' => 'on-category-${hue.name}',
  'container' => 'category-${hue.name}-container',
  'onContainer' => 'on-category-${hue.name}-container',
  'outline' => 'category-${hue.name}-outline',
  _ => throw ArgumentError(slot),
};

/// The token name a resolved colour carries, or `null` for a raw one.
String? _tokenOf(CoreColor? color) => color?.token?.name;

void main() {
  group('defaults', () {
    test('the widget defaults are gray, subtle, md', () {
      expect(CoreTagContract.defaultColor, CoreCategoryColor.gray);
      expect(CoreTagEmphasis.defaultEmphasis, CoreTagEmphasis.subtle);
      expect(CoreTagSize.defaultSize, CoreTagSize.md);
    });

    test('the border is one stroke', () {
      expect(CoreTagStyle.defaultBorderWidth, 1);
    });

    test('there are exactly two steps and two emphases', () {
      expect(CoreTagSize.values, [CoreTagSize.sm, CoreTagSize.md]);
      expect(CoreTagEmphasis.values, [
        CoreTagEmphasis.subtle,
        CoreTagEmphasis.bold,
      ]);
    });
  });

  group('defaultsBySize', () {
    for (final entry in _kSizeTable.entries) {
      test('${entry.key.name} is the spec row', () {
        final row = CoreTagStyle.defaultsBySize[entry.key]!;
        final spec = entry.value;
        expect(row.minHeight, spec.height);
        expect(
          row.padding,
          CoreEdgeInsets.symmetric(horizontal: spec.horizontalPadding),
        );
        // No vertical padding: the height is the step, the label centres.
        expect(row.padding!.top, 0);
        expect(row.padding!.bottom, 0);
        expect(row.borderRadius, CoreBorderRadius.all(spec.radius));
        // The ROLE, not a bare font size — tracking and line height come
        // with it.
        expect(row.labelStyle, CoreTextStyle.token(spec.role));
        expect(row.labelStyle!.fontSize, isNull);
        // Colours belong to the hue × emphasis, not to the step.
        expect(row.backgroundColor, isNull);
        expect(row.foregroundColor, isNull);
        expect(row.borderColor, isNull);
      });
    }

    test('covers every step', () {
      expect(
        CoreTagStyle.defaultsBySize.keys.toSet(),
        CoreTagSize.values.toSet(),
      );
    });
  });

  group('defaultsByEmphasis', () {
    test('subtle changes nothing on top of the step', () {
      expect(
        CoreTagStyle.defaultsByEmphasis[CoreTagEmphasis.subtle],
        const CoreTagStyle(),
      );
    });

    test('bold states the 600 weight alone', () {
      final bold = CoreTagStyle.defaultsByEmphasis[CoreTagEmphasis.bold]!;
      expect(
        bold.labelStyle,
        const CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
      );
      expect(bold.labelStyle!.token, isNull);
      expect(bold.labelStyle!.fontSize, isNull);
    });

    test('laid over a step, the role stays and only the weight changes', () {
      for (final size in CoreTagSize.values) {
        final merged = CoreTagStyle.defaultsBySize[size]!.merge(
          CoreTagStyle.defaultsByEmphasis[CoreTagEmphasis.bold],
        );
        expect(merged.labelStyle!.token, _kSizeTable[size]!.role);
        expect(merged.labelStyle!.fontWeight, CoreFontWeight.semiBold);
        expect(merged.minHeight, _kSizeTable[size]!.height);
      }
    });
  });

  group('resting colours — every hue × emphasis', () {
    for (final hue in CoreCategoryColor.values) {
      test('${hue.name} subtle — container, container text, outline', () {
        final style = CoreTagStyle.resting(hue, CoreTagEmphasis.subtle);
        expect(_tokenOf(style.backgroundColor), _name(hue, 'container'));
        expect(_tokenOf(style.foregroundColor), _name(hue, 'onContainer'));
        expect(_tokenOf(style.borderColor), _name(hue, 'outline'));
      });

      test('${hue.name} bold — fill, on-fill, no line', () {
        final style = CoreTagStyle.resting(hue, CoreTagEmphasis.bold);
        expect(_tokenOf(style.backgroundColor), _name(hue, 'fill'));
        expect(_tokenOf(style.foregroundColor), _name(hue, 'onFill'));
        expect(style.borderColor, isNull);
      });
    }

    test('states colours only', () {
      final style = CoreTagStyle.resting(
        CoreCategoryColor.red,
        CoreTagEmphasis.subtle,
      );
      expect(style.minHeight, isNull);
      expect(style.padding, isNull);
      expect(style.borderRadius, isNull);
      expect(style.borderWidth, isNull);
      expect(style.labelStyle, isNull);
    });
  });

  group('CoreTagStyle value semantics', () {
    const full = CoreTagStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
      foregroundColor: CoreColor.token(CoreColors.onPrimary),
      borderColor: CoreColor.token(CoreColors.outline),
      borderWidth: 2,
      borderRadius: CoreBorderRadius.all(8),
      padding: CoreEdgeInsets.all(4),
      minHeight: 30,
      labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
    );

    test('== / hashCode compare every field', () {
      expect(full, full.copyWith());
      expect(full.hashCode, full.copyWith().hashCode);
      final variants = <CoreTagStyle>[
        full.copyWith(backgroundColor: const CoreColor.token(CoreColors.error)),
        full.copyWith(foregroundColor: const CoreColor.token(CoreColors.error)),
        full.copyWith(borderColor: const CoreColor.token(CoreColors.error)),
        full.copyWith(borderWidth: 3),
        full.copyWith(borderRadius: const CoreBorderRadius.all(2)),
        full.copyWith(padding: const CoreEdgeInsets.all(2)),
        full.copyWith(minHeight: 31),
        full.copyWith(
          labelStyle: const CoreTextStyle(fontWeight: CoreFontWeight.regular),
        ),
      ];
      for (final changed in variants) {
        expect(changed, isNot(full));
      }
    });

    test('copyWith keeps unstated fields', () {
      final copy = full.copyWith(minHeight: 40);
      expect(copy.minHeight, 40);
      expect(copy.backgroundColor, full.backgroundColor);
      expect(copy.labelStyle, full.labelStyle);
    });

    test('merge — the other side wins per field, null keeps this side', () {
      const patch = CoreTagStyle(minHeight: 40);
      final merged = full.merge(patch);
      expect(merged.minHeight, 40);
      expect(merged.borderRadius, full.borderRadius);
      expect(full.merge(null), full);
      expect(const CoreTagStyle().merge(full), full);
    });

    test('merge — the label style merges field by field', () {
      const base = CoreTagStyle(
        labelStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
      );
      final merged = base.merge(
        const CoreTagStyle(
          labelStyle: CoreTextStyle(color: CoreColor.token(CoreColors.error)),
        ),
      );
      expect(merged.labelStyle!.token, CoreTextStyles.labelSmall);
      expect(merged.labelStyle!.color, const CoreColor.token(CoreColors.error));
    });
  });

  group('CoreTagTheme', () {
    test('== / hashCode compare every slot, maps by content', () {
      CoreTagTheme build() => const CoreTagTheme(
        style: CoreTagStyle(minHeight: 30),
        colorStyles: {
          CoreCategoryColor.red: CoreTagStyle(minHeight: 22),
        },
        emphasisStyles: {
          CoreTagEmphasis.bold: CoreTagStyle(minHeight: 26),
        },
      );
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
      expect(
        build(),
        isNot(const CoreTagTheme(style: CoreTagStyle(minHeight: 30))),
      );
      expect(
        build(),
        isNot(
          const CoreTagTheme(
            style: CoreTagStyle(minHeight: 30),
            colorStyles: {CoreCategoryColor.red: CoreTagStyle(minHeight: 22)},
          ),
        ),
      );
    });

    test('is a slot on CoreComponentTheme', () {
      const tag = CoreTagTheme(style: CoreTagStyle(minHeight: 30));
      const theme = CoreComponentTheme(tag: tag);
      expect(theme.tag, tag);
      expect(theme, isNot(const CoreComponentTheme()));
      expect(theme.copyWith().tag, tag);
      expect(const CoreComponentTheme().mergeWith(theme).tag, tag);
    });
  });
}
