import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  summaryAndLayoutTests();
  group('CoreBottomActionBarStyle', () {
    test('the surface and the hairline read existing colour slots', () {
      expect(
        CoreBottomActionBarStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(
        CoreBottomActionBarStyle.defaultDividerColor,
        const CoreColor.token(
          CoreColors.outlineVariant,
          fallbacks: [CoreColors.outline],
        ),
      );
      // The same hairline as the AppBar's bottom edge.
      expect(
        CoreBottomActionBarStyle.defaultDividerColor,
        CoreAppBarStyle.defaultDividerColor,
      );
      expect(
        CoreBottomActionBarStyle.defaultDividerWidth,
        CoreStrokeWidth.stroke1,
      );
    });

    test('the inset and the spacing are existing space steps', () {
      expect(
        CoreBottomActionBarStyle.defaultPadding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space20,
          vertical: CoreSpace.space12,
        ),
      );
      expect(CoreBottomActionBarStyle.defaultSpacing, CoreSpace.space8);
    });

    test('the note is a role token, centred', () {
      expect(
        CoreBottomActionBarStyle.defaultDescriptionTextStyle,
        const CoreTextStyle.token(
          CoreTextStyles.bodySmall,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      );
      expect(
        CoreBottomActionBarStyle.defaultDescriptionTextAlign,
        CoreTextAlign.center,
      );
    });

    test('merge: stated fields win, the note style merges field by field', () {
      const base = CoreBottomActionBarStyle(
        descriptionTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
        spacing: CoreSpace.space4,
        dividerWidth: CoreStrokeWidth.stroke2,
      );
      final merged = base.merge(
        const CoreBottomActionBarStyle(
          descriptionTextStyle: CoreTextStyle(
            fontWeight: CoreFontWeight.medium,
          ),
          padding: CoreEdgeInsets.all(CoreSpace.space16),
        ),
      );
      expect(
        merged.descriptionTextStyle?.color,
        const CoreColor.token(CoreColors.primary),
      );
      expect(merged.descriptionTextStyle?.fontWeight, CoreFontWeight.medium);
      expect(merged.spacing, CoreSpace.space4);
      expect(merged.dividerWidth, CoreStrokeWidth.stroke2);
      expect(merged.padding, const CoreEdgeInsets.all(CoreSpace.space16));
      expect(base.merge(null), same(base));
    });

    test(
      'merge: when both sides state a field, the patch wins — every field',
      () {
        const base = CoreBottomActionBarStyle(
          backgroundColor: CoreColor.token(CoreColors.surface),
          padding: CoreEdgeInsets.all(1),
          spacing: 1,
          dividerColor: CoreColor.token(CoreColors.outline),
          dividerWidth: 1,
          descriptionTextStyle: CoreTextStyle(fontSize: 1),
          descriptionTextAlign: CoreTextAlign.start,
        );
        const patch = CoreBottomActionBarStyle(
          backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
          padding: CoreEdgeInsets.all(2),
          spacing: 2,
          dividerColor: CoreColor.token(CoreColors.outlineVariant),
          dividerWidth: 2,
          descriptionTextStyle: CoreTextStyle(fontSize: 2),
          descriptionTextAlign: CoreTextAlign.end,
        );
        expect(base.merge(patch), patch);
      },
    );

    test('copyWith, == and hashCode carry every field', () {
      const plain = CoreBottomActionBarStyle();
      final changes = [
        plain.copyWith(
          backgroundColor: const CoreColor.token(CoreColors.primary),
        ),
        plain.copyWith(padding: const CoreEdgeInsets.all(1)),
        plain.copyWith(spacing: 1),
        plain.copyWith(
          dividerColor: const CoreColor.token(CoreColors.primary),
        ),
        plain.copyWith(dividerWidth: 1),
        plain.copyWith(descriptionTextStyle: const CoreTextStyle(fontSize: 1)),
        plain.copyWith(descriptionTextAlign: CoreTextAlign.end),
      ];
      for (final (i, changed) in changes.indexed) {
        expect(changed, isNot(plain), reason: 'field $i');
        expect(changed.hashCode, isNot(plain.hashCode), reason: 'field $i');
        for (final (j, other) in changes.indexed) {
          if (i != j) expect(changed, isNot(other), reason: 'fields $i / $j');
        }
      }
    });
  });

  group('the contract and the layout', () {
    test('the bar is vertical and draws its hairline by default', () {
      expect(
        CoreBottomActionBarLayout.defaultLayout,
        CoreBottomActionBarLayout.vertical,
      );
      expect(CoreBottomActionBarContract.defaultShowDivider, isTrue);
    });

    test('vertical is the first member (the canvas default)', () {
      expect(
        CoreBottomActionBarLayout.values.first,
        CoreBottomActionBarLayout.vertical,
      );
      expect(CoreBottomActionBarLayout.values, hasLength(6));
    });
  });

  test('the theme rides on CoreComponentTheme', () {
    const bar = CoreBottomActionBarTheme(
      style: CoreBottomActionBarStyle(spacing: 1),
    );
    const theme = CoreComponentTheme(bottomActionBar: bar);
    expect(theme.bottomActionBar, bar);
    expect(theme, isNot(const CoreComponentTheme()));
    expect(theme.copyWith().bottomActionBar, bar);
    expect(const CoreComponentTheme().mergeWith(theme).bottomActionBar, bar);
    expect(
      bar,
      const CoreBottomActionBarTheme(
        style: CoreBottomActionBarStyle(spacing: 1),
      ),
    );
    expect(bar.hashCode, isNot(const CoreBottomActionBarTheme().hashCode));
  });
}

void summaryAndLayoutTests() {
  group('CoreBottomActionBarStyle summary', () {
    test('the caption is bodySmall in onSurfaceVariant, the figure titleMedium '
        'in onSurface', () {
      expect(
        CoreBottomActionBarStyle.defaultSummaryLabelTextStyle,
        const CoreTextStyle.token(
          CoreTextStyles.bodySmall,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      );
      expect(
        CoreBottomActionBarStyle.defaultSummaryValueTextStyle,
        const CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.onSurface),
        ),
      );
    });

    test(
      'the summary fields take part in merge / copyWith / == / hashCode',
      () {
        const base = CoreBottomActionBarStyle();
        const label = CoreBottomActionBarStyle(
          summaryLabelTextStyle: CoreTextStyle(fontSize: 11),
        );
        const value = CoreBottomActionBarStyle(
          summaryValueTextStyle: CoreTextStyle(fontSize: 19),
        );

        expect(base == label, isFalse);
        expect(base == value, isFalse);
        expect(base.hashCode == label.hashCode, isFalse);
        expect(base.merge(label).summaryLabelTextStyle?.fontSize, 11);
        expect(base.merge(value).summaryValueTextStyle?.fontSize, 19);
        expect(label.copyWith().summaryLabelTextStyle?.fontSize, 11);
        expect(value.copyWith().summaryValueTextStyle?.fontSize, 19);
      },
    );

    test('the layout axis carries the row arrangements', () {
      expect(CoreBottomActionBarLayout.values, [
        CoreBottomActionBarLayout.vertical,
        CoreBottomActionBarLayout.horizontal,
        CoreBottomActionBarLayout.weighted,
        CoreBottomActionBarLayout.icon,
        CoreBottomActionBarLayout.summary,
        CoreBottomActionBarLayout.summaryCompact,
      ]);
      expect(
        CoreBottomActionBarLayout.defaultLayout,
        CoreBottomActionBarLayout.vertical,
      );
    });
  });
}
