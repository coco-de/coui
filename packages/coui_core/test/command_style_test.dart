// Tests for CoreCommandStyle (Phase 6g — Command unification).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kRadiusSm = CoreBorderRadius.all(4);
const _kRadiusLg = CoreBorderRadius.all(16);

const _kPadSm = CoreEdgeInsets.all(4);
const _kPadLg = CoreEdgeInsets.all(12);

const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kBorderOutline = CoreColor.token(CoreColors.outline);
const _kHighlightTertiary = CoreColor.token(CoreColors.surfaceContainer);
const _kForegroundOnTertiary = CoreColor.token(CoreColors.onTertiary);
const _kItemTextStyle = CoreTextStyle(color: _kForegroundOnTertiary);

const Duration _kAnim100 = Duration(milliseconds: 100);
const Duration _kAnim200 = Duration(milliseconds: 200);

const _kLabelStyle = CoreTextStyle(fontSize: 13);
const _kHeadingStyle = CoreTextStyle(fontSize: 12);

void main() {
  test(
    'fullscreen back glyph delegates size to Button and retains variant ink',
    () {
      expect(CoreCommandStyle.defaultBackIconStyle.size, isNull);
      expect(
        CoreCommandStyle.defaultBackIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      for (final row in CoreCommandStyle.defaultsBySize.values) {
        expect(row.backIconStyle?.size, isNull);
      }
    },
  );

  group('CoreCommandStyle.merge', () {
    test('null other returns this', () {
      const a = CoreCommandStyle(
        backgroundColor: _kBgSurface,
        borderRadius: _kRadiusSm,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreCommandStyle(
        backgroundColor: _kBgSurface,
        borderColor: _kBorderOutline,
        borderRadius: _kRadiusSm,
        itemPadding: _kPadSm,
      );
      const themeStyle = CoreCommandStyle(
        borderRadius: _kRadiusLg,
        itemHighlightColor: _kHighlightTertiary,
      );
      const widgetStyle = CoreCommandStyle(
        itemPadding: _kPadLg,
        highlightDuration: _kAnim200,
      );

      final merged = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(merged.backgroundColor, _kBgSurface);
      expect(merged.borderColor, _kBorderOutline);
      expect(merged.borderRadius, _kRadiusLg);
      expect(merged.itemPadding, _kPadLg);
      expect(merged.itemHighlightColor, _kHighlightTertiary);
      expect(merged.highlightDuration, _kAnim200);
    });

    test('nested text styles merge recursively', () {
      const base = CoreCommandStyle(labelStyle: _kLabelStyle);
      const over = CoreCommandStyle(headingStyle: _kHeadingStyle);

      final merged = base.merge(over);

      expect(merged.labelStyle, _kLabelStyle);
      expect(merged.headingStyle, _kHeadingStyle);
    });
  });

  group('CoreCommandStyle typography defaults', () {
    test('the shortcut hint is the bodyXs role in the sans face', () {
      const style = CoreCommandStyle.defaultShortcutStyle;
      expect(style.token, CoreTextStyles.bodyXs);
      expect(style.fontFamily, isNull);
      expect(style.color, const CoreColor.token(CoreColors.onSurfaceVariant));
    });

    test('the row description is bodyXs (12 Regular)', () {
      const style = CoreCommandStyle.defaultOverlineStyle;
      expect(style.token, CoreTextStyles.bodyXs);
      expect(style.fontWeight, isNull, reason: "the weight is the role's");
    });

    // The confirmed ink retains the recorded dark highlighted pressed
    // exception at 4.19:1. The contrast guard checks for net-new violations;
    // it does not certify that every state clears 4.5:1.
    test('the description and the shortcut retain the ink covered by the '
        'existing contrast baseline', () {
      const variant = CoreColor.token(CoreColors.onSurfaceVariant);
      expect(CoreCommandStyle.defaultOverlineStyle.color, variant);
      expect(CoreCommandStyle.defaultShortcutStyle.color, variant);
    });

    test('the two-line title is a Regular body role, not a title role', () {
      expect(
        CoreCommandStyle.defaultItemTitleStyle.token,
        CoreTextStyles.bodyMedium,
      );
    });

    // Each rung states the row's text in roles — never a bare fontSize — so
    // the tracking and the line box come with the size.
    test('each size rung reads the roles the designer states', () {
      final sm = CoreCommandStyle.defaultsBySize[CoreCommandSize.sm]!;
      final md = CoreCommandStyle.defaultsBySize[CoreCommandSize.md]!;
      final lg = CoreCommandStyle.defaultsBySize[CoreCommandSize.lg]!;

      expect(sm.labelStyle?.token, CoreTextStyles.bodySmall);
      expect(sm.itemTitleStyle?.token, CoreTextStyles.bodySmall);
      expect(sm.overlineStyle?.token, CoreTextStyles.bodyXs);

      expect(md.labelStyle?.token, CoreTextStyles.bodyMedium);
      expect(md.itemTitleStyle?.token, CoreTextStyles.bodyMedium);
      expect(md.overlineStyle?.token, CoreTextStyles.bodyXs);

      expect(lg.labelStyle?.token, CoreTextStyles.bodyMedium);
      expect(lg.itemTitleStyle?.token, CoreTextStyles.bodyMedium);
      expect(lg.overlineStyle?.token, CoreTextStyles.bodyXs);

      for (final rung in [sm, md, lg]) {
        expect(rung.itemTitleStyle?.fontSize, isNull);
        expect(rung.overlineStyle?.fontSize, isNull);
        // The colour comes from the field-level default, not the rung.
        expect(rung.overlineStyle?.color, isNull);
      }
    });

    test('the group heading is the labelXs role at its own weight (11 '
        'Medium), subtle', () {
      const style = CoreCommandStyle.defaultHeadingStyle;
      expect(style.token, CoreTextStyles.labelXs);
      expect(style.fontWeight, isNull, reason: "the weight is the role's");
      expect(style.fontSize, isNull);
      expect(style.color, const CoreColor.token(CoreColors.onSurfaceSubtle));
    });
  });

  group('CoreCommandStyle.copyWith', () {
    test('overrides only supplied fields', () {
      const a = CoreCommandStyle(
        backgroundColor: _kBgSurface,
        itemTextStyle: _kItemTextStyle,
        highlightDuration: _kAnim100,
      );

      final b = a.copyWith(highlightDuration: _kAnim200);

      expect(b.backgroundColor, _kBgSurface);
      expect(b.itemTextStyle, _kItemTextStyle);
      expect(b.itemTextStyle?.color, _kForegroundOnTertiary);
      expect(b.highlightDuration, _kAnim200);
    });
  });

  group('CoreCommandStyle equality', () {
    test('equal field sets compare equal', () {
      const a = CoreCommandStyle(
        backgroundColor: _kBgSurface,
        borderRadius: _kRadiusSm,
      );
      const b = CoreCommandStyle(
        backgroundColor: _kBgSurface,
        borderRadius: _kRadiusSm,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different field sets compare unequal', () {
      const a = CoreCommandStyle(borderRadius: _kRadiusSm);
      const b = CoreCommandStyle(borderRadius: _kRadiusLg);
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreCommandStyle design-system defaults', () {
    test('static const defaults are platform-neutral domain types', () {
      expect(
        CoreCommandStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(
        CoreCommandStyle.defaultFooterBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(
        CoreCommandStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineSubtle),
      );
      expect(
        CoreCommandStyle
            .defaultsByPresentation[CoreCommandPresentation.inline]!
            .borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreCommandStyle
            .defaultsByPresentation[CoreCommandPresentation.dialog]!
            .borderColor,
        const CoreColor.token(CoreColors.outlineSubtle),
      );
      expect(
        CoreCommandStyle
            .defaultsByPresentation[CoreCommandPresentation.fullscreen]!
            .backgroundColor,
        isNull,
        reason: 'fullscreen reads the shared fill — it states none of its own',
      );
      expect(
        CoreCommandStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius12),
      );
      expect(
        CoreCommandStyle.defaultItemHighlightColor,
        const CoreColor.token(CoreColors.surfaceContainer),
      );
      expect(
        CoreCommandStyle.defaultItemBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
        reason: 'the highlight, hover and pressed fills share one 8 corner',
      );
      expect(
        CoreCommandStyle.defaultHighlightDuration,
        const Duration(milliseconds: CoreDuration.ms150),
      );
    });

    test('the row glyph is on-surface-variant at rest and on-surface on the '
        'active row', () {
      expect(
        CoreCommandStyle.defaultItemIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreCommandStyle.defaultItemActiveIconStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        CoreCommandStyle.defaultPlaceholderColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
        reason: 'the search glyph',
      );
    });

    test('the footer hint is on-surface-subtle; the overline and the shortcut '
        'stay on-surface-variant', () {
      expect(
        CoreCommandStyle.defaultFooterStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(
        CoreCommandStyle.defaultOverlineStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreCommandStyle.defaultShortcutStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    test('the overline, the shortcut and the footer hint are the bodyXs role '
        'on every rung; the heading is the labelXs role', () {
      expect(
        CoreCommandStyle.defaultOverlineStyle.token,
        CoreTextStyles.bodyXs,
      );
      expect(
        CoreCommandStyle.defaultShortcutStyle.token,
        CoreTextStyles.bodyXs,
      );
      expect(CoreCommandStyle.defaultFooterStyle.token, CoreTextStyles.bodyXs);
      expect(
        CoreCommandStyle.defaultHeadingStyle.token,
        CoreTextStyles.labelXs,
      );
      for (final style in [
        CoreCommandStyle.defaultOverlineStyle,
        CoreCommandStyle.defaultShortcutStyle,
        CoreCommandStyle.defaultFooterStyle,
        CoreCommandStyle.defaultHeadingStyle,
      ]) {
        // Roles only — no size, weight or tracking laid over them.
        expect(style.fontSize, isNull);
        expect(style.fontWeight, isNull);
        expect(style.letterSpacing, isNull);
      }
      for (final size in CoreCommandSize.values) {
        expect(
          CoreCommandStyle.defaultsBySize[size]!.overlineStyle!.token,
          CoreTextStyles.bodyXs,
          reason: '$size',
        );
      }
    });

    test('the list is inset 8 on every shape with a 2 gap', () {
      expect(CoreCommandStyle.defaultListPadding, const CoreEdgeInsets.all(8));
      for (final p in CoreCommandPresentation.values) {
        expect(
          CoreCommandStyle.defaultsByPresentation[p]!.listPadding,
          const CoreEdgeInsets.all(8),
          reason: '$p',
        );
      }
      expect(CoreCommandStyle.defaultListSpacing, CoreSpace.space2);
    });

    test('search and row insets, gaps and the heading on every rung', () {
      const rows = {
        CoreCommandSize.sm: (10.0, 4.0, 8.0),
        CoreCommandSize.md: (10.0, 8.0, 12.0),
        CoreCommandSize.lg: (12.0, 10.0, 16.0),
      };
      for (final MapEntry(key: size, value: (h, v, headingEnd))
          in rows.entries) {
        final r = CoreCommandStyle.defaultsBySize[size]!;
        expect(
          r.searchPadding,
          const CoreEdgeInsets.symmetric(horizontal: 12),
          reason: '$size',
        );
        expect(r.searchGapStyle!.size, 10, reason: '$size');
        expect(
          r.itemPadding,
          CoreEdgeInsets.symmetric(horizontal: h, vertical: v),
          reason: '$size',
        );
        expect(r.itemGapStyle!.size, 10, reason: '$size');
        expect(
          r.headingPadding,
          CoreEdgeInsets.directional(
            start: 10,
            top: 6,
            end: headingEnd,
            bottom: 6,
          ),
          reason: '$size',
        );
      }
    });

    test('scope chips carry no border and an 8 corner', () {
      expect(CoreCommandStyle.defaultScopeChipStyle.borderWidth, 0);
      expect(
        CoreCommandStyle.defaultScopeChipStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
    });
  });

  group('CoreCommandVariant', () {
    test('defaultVariant is standard', () {
      expect(CoreCommandVariant.defaultVariant, CoreCommandVariant.standard);
    });
  });

  group('CoreCommandItem / CoreCommandGroup', () {
    test('items compare by value', () {
      const a = CoreCommandItem<int>(value: 'a', label: 'A');
      const b = CoreCommandItem<int>(value: 'a', label: 'A');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('groups compare by heading and items', () {
      const g1 = CoreCommandGroup<int>(
        items: [CoreCommandItem(value: 'a', label: 'A')],
        heading: 'G',
      );
      const g2 = CoreCommandGroup<int>(
        items: [CoreCommandItem(value: 'a', label: 'A')],
        heading: 'G',
      );
      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
    });

    test('item defaults to enabled', () {
      const item = CoreCommandItem<int>(value: 'a', label: 'A');
      expect(item.enabled, isTrue);
    });
  });

  group('CoreCommandTheme', () {
    test('equality by style', () {
      const t1 = CoreCommandTheme(
        style: CoreCommandStyle(borderRadius: _kRadiusSm),
      );
      const t2 = CoreCommandTheme(
        style: CoreCommandStyle(borderRadius: _kRadiusSm),
      );
      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
    });
  });
}
