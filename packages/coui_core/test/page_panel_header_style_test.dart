import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CorePageHeaderStyle', () {
    test('the text lines are role tokens, not sizes', () {
      expect(
        CorePageHeaderStyle.defaultEyebrowTextStyle,
        const CoreTextStyle.token(
          CoreTextStyles.labelXl,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      );
      expect(
        CorePageHeaderStyle.defaultTitleTextStyle,
        const CoreTextStyle.token(
          CoreTextStyles.headlineMedium,
          color: CoreColor.token(CoreColors.onSurface),
        ),
      );
      expect(
        CorePageHeaderStyle.defaultDescriptionTextStyle,
        const CoreTextStyle.token(
          CoreTextStyles.bodyMedium,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      );
    });

    test('the spacing and the narrowest title', () {
      expect(CorePageHeaderStyle.defaultTextSpacing, CoreSpace.space4);
      expect(CorePageHeaderStyle.defaultTextActionsSpacing, CoreSpace.space16);
      expect(CorePageHeaderStyle.defaultActionSpacing, CoreSpace.space8);
      expect(CorePageHeaderStyle.defaultMinTextWidth, CoreLayout.layout160);
      expect(CorePageHeaderContract.defaultHeadingLevel, 1);
    });

    test('merge: stated fields win, text styles merge field by field', () {
      const base = CorePageHeaderStyle(
        titleTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
        textSpacing: CoreSpace.space2,
        minTextWidth: CoreLayout.layout320,
      );
      final merged = base.merge(
        const CorePageHeaderStyle(
          titleTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.medium),
          actionSpacing: CoreSpace.space12,
        ),
      );
      expect(
        merged.titleTextStyle?.color,
        const CoreColor.token(CoreColors.primary),
      );
      expect(merged.titleTextStyle?.fontWeight, CoreFontWeight.medium);
      expect(merged.textSpacing, CoreSpace.space2);
      expect(merged.actionSpacing, CoreSpace.space12);
      expect(merged.minTextWidth, CoreLayout.layout320);
      expect(base.merge(null), same(base));
    });

    test(
      'merge: when both sides state a field, the patch wins — every field',
      () {
        const base = CorePageHeaderStyle(
          eyebrowTextStyle: CoreTextStyle(fontSize: 1),
          titleTextStyle: CoreTextStyle(fontSize: 1),
          descriptionTextStyle: CoreTextStyle(fontSize: 1),
          textSpacing: 1,
          textActionsSpacing: 1,
          actionSpacing: 1,
          minTextWidth: 1,
        );
        const patch = CorePageHeaderStyle(
          eyebrowTextStyle: CoreTextStyle(fontSize: 2),
          titleTextStyle: CoreTextStyle(fontSize: 2),
          descriptionTextStyle: CoreTextStyle(fontSize: 2),
          textSpacing: 2,
          textActionsSpacing: 2,
          actionSpacing: 2,
          minTextWidth: 2,
        );
        expect(base.merge(patch), patch);
      },
    );

    test('copyWith, == and hashCode carry every field', () {
      const plain = CorePageHeaderStyle();
      final changes = [
        plain.copyWith(eyebrowTextStyle: const CoreTextStyle(fontSize: 1)),
        plain.copyWith(titleTextStyle: const CoreTextStyle(fontSize: 1)),
        plain.copyWith(descriptionTextStyle: const CoreTextStyle(fontSize: 1)),
        plain.copyWith(textSpacing: 1),
        plain.copyWith(textActionsSpacing: 1),
        plain.copyWith(actionSpacing: 1),
        plain.copyWith(minTextWidth: 1),
      ];
      for (final (i, changed) in changes.indexed) {
        expect(changed, isNot(plain), reason: 'field $i');
        expect(changed.hashCode, isNot(plain.hashCode), reason: 'field $i');
        for (final (j, other) in changes.indexed) {
          if (i != j) expect(changed, isNot(other), reason: 'fields $i / $j');
        }
      }
      expect(plain.copyWith(textSpacing: 1), plain.copyWith(textSpacing: 1));
    });
  });

  group('CorePanelHeaderStyle', () {
    test('the title is a role token, the row sits on space8', () {
      expect(
        CorePanelHeaderStyle.defaultTitleTextStyle,
        const CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.onSurface),
        ),
      );
      expect(
        CorePanelHeaderStyle.defaultPadding,
        const CoreEdgeInsets.only(bottom: CoreSpace.space8),
      );
      expect(CorePanelHeaderStyle.defaultTitleActionSpacing, CoreSpace.space8);
      expect(CorePanelHeaderStyle.defaultMinTitleWidth, CoreSize.size128);
      expect(CorePanelHeaderContract.defaultHeadingLevel, 2);
    });

    test('merge: stated fields win, the title style merges field by field', () {
      const base = CorePanelHeaderStyle(
        titleTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
        padding: CoreEdgeInsets.all(CoreSpace.space4),
      );
      final merged = base.merge(
        const CorePanelHeaderStyle(
          titleTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.medium),
          minTitleWidth: CoreSize.size96,
        ),
      );
      expect(
        merged.titleTextStyle?.color,
        const CoreColor.token(CoreColors.primary),
      );
      expect(merged.titleTextStyle?.fontWeight, CoreFontWeight.medium);
      expect(merged.padding, const CoreEdgeInsets.all(CoreSpace.space4));
      expect(merged.minTitleWidth, CoreSize.size96);
      expect(base.merge(null), same(base));
    });

    test(
      'merge: when both sides state a field, the patch wins — every field',
      () {
        const base = CorePanelHeaderStyle(
          titleTextStyle: CoreTextStyle(fontSize: 1),
          padding: CoreEdgeInsets.all(1),
          titleActionSpacing: 1,
          minTitleWidth: 1,
        );
        const patch = CorePanelHeaderStyle(
          titleTextStyle: CoreTextStyle(fontSize: 2),
          padding: CoreEdgeInsets.all(2),
          titleActionSpacing: 2,
          minTitleWidth: 2,
        );
        expect(base.merge(patch), patch);
      },
    );

    test('copyWith, == and hashCode carry every field', () {
      const plain = CorePanelHeaderStyle();
      final changes = [
        plain.copyWith(titleTextStyle: const CoreTextStyle(fontSize: 1)),
        plain.copyWith(padding: const CoreEdgeInsets.all(1)),
        plain.copyWith(titleActionSpacing: 1),
        plain.copyWith(minTitleWidth: 1),
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

  test('a heading depth maps to its element and back', () {
    for (var level = 1; level <= 6; level++) {
      expect(CoreTextBlockElement.heading(level).headingLevel, level);
    }
    // Out of range lands on the nearest heading instead of throwing.
    expect(CoreTextBlockElement.heading(0), CoreTextBlockElement.h1);
    expect(CoreTextBlockElement.heading(7), CoreTextBlockElement.h6);
  });

  test('both themes ride on CoreComponentTheme', () {
    const page = CorePageHeaderTheme(
      style: CorePageHeaderStyle(textSpacing: 1),
    );
    const panel = CorePanelHeaderTheme(
      style: CorePanelHeaderStyle(minTitleWidth: 1),
    );
    const theme = CoreComponentTheme(pageHeader: page, panelHeader: panel);
    expect(theme.pageHeader, page);
    expect(theme.panelHeader, panel);
    expect(theme, isNot(const CoreComponentTheme(pageHeader: page)));
    expect(theme.copyWith().pageHeader, page);
    expect(
      const CoreComponentTheme().mergeWith(theme).panelHeader,
      panel,
    );
  });
}
