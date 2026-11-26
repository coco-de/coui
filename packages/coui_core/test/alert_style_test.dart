// Tests for CoreAlertStyle's defaults — the stacked panel's named
// constants, and the per-layout rows the resolvers read under the chain.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('defaults', () {
    test('padding is 12 down and 12 trailing, 16 leading', () {
      expect(
        CoreAlertStyle.defaultPadding,
        const CoreEdgeInsets.directional(
          start: 16,
          top: 12,
          end: 12,
          bottom: 12,
        ),
      );
    });

    test('the floor is 64', () {
      expect(CoreAlertStyle.defaultMinHeight, 64);
    });

    test('the glyph is 18', () {
      expect(CoreAlertStyle.defaultIconStyle.size, 18);
    });

    test('the title is labelLarge at 600 on onSurface', () {
      expect(CoreAlertStyle.defaultTitleStyle.token, CoreTextStyles.labelLarge);
      expect(
        CoreAlertStyle.defaultTitleStyle.fontWeight,
        CoreFontWeight.semiBold,
      );
    });

    test('the description is bodySmall', () {
      expect(
        CoreAlertStyle.defaultDescriptionStyle.token,
        CoreTextStyles.bodySmall,
      );
    });

    test('every tone fills with an opaque container token', () {
      for (final variant in CoreAlertVariant.values) {
        final v = CoreAlertStyle.defaultsByVariant[variant]!;
        expect(v.backgroundColor.opacity, 1, reason: variant.name);
      }
    });
  });

  group('layouts', () {
    test('the default layout is the stacked panel', () {
      expect(CoreAlertLayout.defaultLayout, CoreAlertLayout.stacked);
    });

    test('every layout row answers all six measurements', () {
      // The resolvers read `row.X!` under the merge chain. A row that left
      // one out would throw on that layout only — and only for a caller
      // that did not override the field, which is most of them.
      for (final layout in CoreAlertLayout.values) {
        final row = CoreAlertStyle.defaultsByLayout[layout];
        expect(row, isNotNull, reason: layout.name);
        expect(row!.padding, isNotNull, reason: '${layout.name} padding');
        expect(row.minHeight, isNotNull, reason: '${layout.name} floor');
        expect(
          row.iconContentGapStyle?.size,
          isNotNull,
          reason: '${layout.name} gap',
        );
        expect(row.iconStyle?.size, isNotNull, reason: '${layout.name} glyph');
        expect(row.titleStyle?.token, isNotNull, reason: '${layout.name} role');
        expect(row.titleColor, isNotNull, reason: '${layout.name} colour');
      }
    });

    test('the stacked row is the named defaults, not a second copy', () {
      // The named `default*` constants are what docs, the Figma exporter
      // and every caller read as "the alert". If the stacked row stated its
      // own values they could drift apart with nothing failing.
      final row = CoreAlertStyle.defaultsByLayout[CoreAlertLayout.stacked]!;
      expect(row.padding, CoreAlertStyle.defaultPadding);
      expect(row.minHeight, CoreAlertStyle.defaultMinHeight);
      expect(
        row.iconContentGapStyle,
        CoreAlertStyle.defaultIconContentGapStyle,
      );
      expect(row.iconStyle, CoreAlertStyle.defaultIconStyle);
      expect(row.titleStyle, CoreAlertStyle.defaultTitleStyle);
      expect(row.titleColor, CoreAlertStyle.defaultTitleColor);
    });

    test('the inline strip: 10 / 14 padding, gap 10, glyph 16, no floor', () {
      final row = CoreAlertStyle.defaultsByLayout[CoreAlertLayout.inline]!;
      expect(
        row.padding,
        const CoreEdgeInsets.symmetric(vertical: 10, horizontal: 14),
      );
      expect(row.minHeight, 0);
      expect(row.iconContentGapStyle?.size, 10);
      expect(row.iconStyle?.size, 16);
    });

    test(
      'the layout states the title cap once: free stacked, one line inline',
      () {
        // Both resolvers read this rather than restating the number, so the
        // one place to change it is here.
        expect(CoreAlertLayout.stacked.titleMaxLines, isNull);
        expect(CoreAlertLayout.inline.titleMaxLines, 1);
      },
    );

    test('the inline title is one body line in on-surface-variant', () {
      // One voice per line: the leading badge or glyph carries the
      // emphasis, so the title reads as the body text it stands in for.
      final row = CoreAlertStyle.defaultsByLayout[CoreAlertLayout.inline]!;
      expect(row.titleStyle?.token, CoreTextStyles.bodySmall);
      expect(row.titleStyle?.fontWeight, isNull);
      expect(
        row.titleColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });
  });

  group('colours', () {
    test('the description reads on-surface-variant on every tone', () {
      for (final variant in CoreAlertVariant.values) {
        expect(
          CoreAlertStyle.defaultsByVariant[variant]!.descriptionColor,
          const CoreColor.token(CoreColors.onSurfaceVariant),
          reason: variant.name,
        );
      }
    });

    test('the glyph keeps the tone', () {
      const glyphs = {
        CoreAlertVariant.info: CoreColors.onInfoContainer,
        CoreAlertVariant.success: CoreColors.onSuccessContainer,
        CoreAlertVariant.warning: CoreColors.onWarningContainer,
        CoreAlertVariant.destructive: CoreColors.onErrorContainer,
      };
      for (final MapEntry(key: variant, value: token) in glyphs.entries) {
        expect(
          CoreAlertStyle.defaultsByVariant[variant]!.iconColor,
          CoreColor.token(token),
          reason: variant.name,
        );
      }
    });
  });
}
