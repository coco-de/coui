// Tests for CoreDialogStyle (Epic #1302 — Story #1310 Dialog).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kRadiusSm = CoreBorderRadius.all(4);
const _kRadiusLg = CoreBorderRadius.all(16);
const _kPaddingSm = CoreEdgeInsets.all(16);
const _kPaddingLg = CoreEdgeInsets.all(24);
const double _kBlurNone = 0;
const double _kBlurSoft = 12;
const double _kOpacityFull = 1;
const double _kOpacityMuted = 0.85;

const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kBgSurfaceContainer = CoreColor.token(CoreColors.surfaceContainer);
const _kBarrierScrim = CoreColor.token(CoreColors.scrim);
const _kBarrierOpaque = CoreColor.token(CoreColors.shadow);
// CoreButtonStyle colour fields are now CoreColor? (Epic #1415 Phase 6f).
const _kBgSurfaceClr = CoreColor.token(CoreColors.surface);

const double _kFontTitle = 20;
const double _kFontBody = 14;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightRegular = CoreFontWeight.regular;
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorOnSurfaceVariant = CoreColor.token(CoreColors.onSurfaceVariant);

void main() {
  group('CoreDialogStyle.merge', () {
    test('null other returns this', () {
      const a = CoreDialogStyle(
        panelBackgroundColor: _kBgSurface,
        panelBorderRadius: _kRadiusLg,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreDialogStyle(
        panelBackgroundColor: _kBgSurface,
        panelBorderRadius: _kRadiusSm,
        panelPadding: _kPaddingSm,
        surfaceBlur: _kBlurNone,
        surfaceOpacity: _kOpacityFull,
        barrierColor: _kBarrierScrim,
      );
      const themeStyle = CoreDialogStyle(
        panelBorderRadius: _kRadiusLg,
        panelPadding: _kPaddingLg,
      );
      const widgetStyle = CoreDialogStyle(
        panelBackgroundColor: _kBgSurfaceContainer,
        surfaceBlur: _kBlurSoft,
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.panelBackgroundColor, _kBgSurfaceContainer); // widget
      expect(effective.panelBorderRadius, _kRadiusLg); // theme
      expect(effective.panelPadding, _kPaddingLg); // theme
      expect(effective.surfaceBlur, _kBlurSoft); // widget
      expect(effective.surfaceOpacity, _kOpacityFull);
      expect(effective.barrierColor, _kBarrierScrim);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreDialogStyle(
        panelBorderRadius: _kRadiusSm,
        panelPadding: _kPaddingSm,
      );
      const b = CoreDialogStyle(panelBorderRadius: _kRadiusLg);
      const c = CoreDialogStyle(panelPadding: _kPaddingLg);

      final result = a.merge(b).merge(c);

      expect(result.panelBorderRadius, _kRadiusLg);
      expect(result.panelPadding, _kPaddingLg);
    });

    test('barrier / surfaceOpacity / surfaceBlur merge', () {
      const base = CoreDialogStyle(
        surfaceBlur: _kBlurNone,
        surfaceOpacity: _kOpacityFull,
        barrierColor: _kBarrierScrim,
      );
      const override = CoreDialogStyle(
        surfaceOpacity: _kOpacityMuted,
        barrierColor: _kBarrierOpaque,
      );
      final merged = base.merge(override);
      expect(merged.barrierColor, _kBarrierOpaque);
      expect(merged.surfaceOpacity, _kOpacityMuted);
      expect(merged.surfaceBlur, _kBlurNone);
    });

    test('panelBoxShadow / shadowBaseColor merge (right-most wins, #3777)', () {
      const base = CoreDialogStyle(
        panelBoxShadow: CoreShadow.md,
        shadowBaseColor: _kColorOnSurface,
      );
      const override = CoreDialogStyle(panelBoxShadow: CoreShadow.xl2);
      final merged = base.merge(override);
      expect(merged.panelBoxShadow, CoreShadow.xl2);
      // shadowBaseColor untouched by override → inherits from base.
      expect(merged.shadowBaseColor, _kColorOnSurface);
    });

    test('titleStyle merges recursively (subset override)', () {
      const base = CoreDialogStyle(
        titleStyle: CoreTextStyle(
          fontSize: _kFontTitle,
          fontWeight: _kWeightSemiBold,
          color: _kColorOnSurface,
        ),
      );
      const override = CoreDialogStyle(
        titleStyle: CoreTextStyle(fontWeight: _kWeightRegular),
      );
      final merged = base.merge(override);
      expect(merged.titleStyle?.fontSize, _kFontTitle);
      expect(merged.titleStyle?.fontWeight, _kWeightRegular);
      expect(merged.titleStyle?.color, _kColorOnSurface);
    });

    test('contentStyle merges recursively', () {
      const base = CoreDialogStyle(
        contentStyle: CoreTextStyle(
          fontSize: _kFontBody,
          color: _kColorOnSurfaceVariant,
        ),
      );
      const override = CoreDialogStyle(
        contentStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      final merged = base.merge(override);
      expect(merged.contentStyle?.fontSize, _kFontBody);
      expect(merged.contentStyle?.color, _kColorOnSurface);
    });

    test('actionButtonStyle merges recursively', () {
      const base = CoreDialogStyle(
        actionButtonStyle: CoreButtonStyle(
          backgroundColor: _kBgSurfaceClr,
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      const override = CoreDialogStyle(
        actionButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 24),
        ),
      );
      final merged = base.merge(override);
      expect(
        merged.actionButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 24),
      );
      expect(merged.actionButtonStyle?.backgroundColor, _kBgSurfaceClr);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreDialogStyle();
      const override = CoreDialogStyle(
        titleStyle: CoreTextStyle(
          fontSize: _kFontTitle,
          color: _kColorOnSurface,
        ),
      );
      final merged = base.merge(override);
      expect(merged.titleStyle?.fontSize, _kFontTitle);
      expect(merged.titleStyle?.color, _kColorOnSurface);
    });
  });

  group('CoreDialogStyle equality', () {
    test('same fields → equal', () {
      const a = CoreDialogStyle(
        panelBackgroundColor: _kBgSurface,
        panelBorderRadius: _kRadiusLg,
        panelPadding: _kPaddingLg,
      );
      const b = CoreDialogStyle(
        panelBackgroundColor: _kBgSurface,
        panelBorderRadius: _kRadiusLg,
        panelPadding: _kPaddingLg,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different barrierColor → not equal', () {
      const a = CoreDialogStyle(barrierColor: _kBarrierScrim);
      const b = CoreDialogStyle(barrierColor: _kBarrierOpaque);
      expect(a, isNot(equals(b)));
    });

    test('different titleStyle → not equal', () {
      const a = CoreDialogStyle(
        titleStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      const b = CoreDialogStyle(
        titleStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      expect(a, isNot(equals(b)));
    });

    test('different panelBoxShadow → not equal (#3777)', () {
      const a = CoreDialogStyle(panelBoxShadow: CoreShadow.xl);
      const b = CoreDialogStyle(panelBoxShadow: CoreShadow.md);
      expect(a, isNot(equals(b)));
    });

    test('same panelBoxShadow (different list identity) → equal (#3777)', () {
      // CoreShadow.xl is the same const list both times, but a
      // hand-built equivalent list must also compare equal — this is
      // exactly what the axis-composition "value equality" rule
      // requires for a field an axis can rewrite.
      const a = CoreDialogStyle(panelBoxShadow: CoreShadow.xl);
      const b = CoreDialogStyle(
        panelBoxShadow: [
          (
            offsetX: 0,
            offsetY: 24,
            blurRadius: 64,
            spreadRadius: 0,
            opacity: 0.125,
            inset: false,
          ),
        ],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreDialogStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreDialogStyle(
        panelBackgroundColor: _kBgSurface,
        panelBorderRadius: _kRadiusLg,
        panelPadding: _kPaddingLg,
      );
      final copy = base.copyWith(panelPadding: _kPaddingSm);
      expect(copy.panelBackgroundColor, _kBgSurface);
      expect(copy.panelBorderRadius, _kRadiusLg);
      expect(copy.panelPadding, _kPaddingSm);
    });

    test('panelBoxShadow override, shadowBaseColor preserved (#3777)', () {
      const base = CoreDialogStyle(
        panelBoxShadow: CoreShadow.xl,
        shadowBaseColor: _kColorOnSurface,
      );
      final copy = base.copyWith(panelBoxShadow: CoreShadow.xl2);
      expect(copy.panelBoxShadow, CoreShadow.xl2);
      expect(copy.shadowBaseColor, _kColorOnSurface);
    });

    test('preserves nested styles when not specified', () {
      const base = CoreDialogStyle(
        titleStyle: CoreTextStyle(fontSize: _kFontTitle),
        actionButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      final copy = base.copyWith(panelBorderRadius: _kRadiusSm);
      expect(copy.panelBorderRadius, _kRadiusSm);
      expect(copy.titleStyle?.fontSize, _kFontTitle);
      expect(
        copy.actionButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
    });
  });

  group('CoreDialogStyle design-system defaults (#3777)', () {
    test(
      'defaultPanelBoxShadow is the canonical Modal/Dialog shadow-xl rung',
      () {
        // The Shadow Token Specification's usage table maps Modal/Dialog
        // to shadow-xl — asserting equality with `CoreShadow.xl` (not a
        // restated literal) keeps this test tied to that single source,
        // matching `CoreShadow.xl`'s own doc comment ("Modal, Dialog").
        expect(CoreDialogStyle.defaultPanelBoxShadow, CoreShadow.xl);
      },
    );

    test('defaultShadowBaseColor is the shadow palette token', () {
      expect(
        CoreDialogStyle.defaultShadowBaseColor,
        const CoreColor.token(CoreColors.shadow),
      );
    });

    test('an unconfigured style defers to the design-system shadow', () {
      const style = CoreDialogStyle();
      final resolvedShadow =
          style.panelBoxShadow ?? CoreDialogStyle.defaultPanelBoxShadow;
      final resolvedTint =
          style.shadowBaseColor ?? CoreDialogStyle.defaultShadowBaseColor;
      expect(resolvedShadow, CoreShadow.xl);
      expect(resolvedTint, const CoreColor.token(CoreColors.shadow));
    });
  });

  group('CoreDialogStyle colour defaults', () {
    test('the panel is the raised face with the quiet line', () {
      expect(
        CoreDialogStyle.defaultPanelBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(
        CoreDialogStyle.defaultPanelBorderColor,
        const CoreColor.token(CoreColors.outlineSubtle),
      );
      expect(
        CoreDialogStyle.defaultsByVariant.backgroundColor,
        CoreDialogStyle.defaultPanelBackgroundColor,
      );
      expect(
        CoreDialogStyle.defaultsByVariant.borderColor,
        CoreDialogStyle.defaultPanelBorderColor,
      );
    });

    test('the barrier is the scrim token at the scrim strength', () {
      expect(
        CoreDialogStyle.defaultBarrierColor,
        const CoreColor.token(CoreColors.scrim),
      );
      expect(
        CoreDialogStyle.defaultsByVariant.overlayColor,
        CoreDialogStyle.defaultBarrierColor,
      );
      expect(CoreDialogStyle.defaultBarrierOpacity, CoreOpacity.scrim);
    });
  });

  group('CoreDialogStyle panel layout defaults', () {
    test('padding is 24 above and on both sides, 20 below', () {
      expect(
        CoreDialogStyle.defaultPanelPadding,
        const CoreEdgeInsets.only(
          top: CoreSpace.space24,
          left: CoreSpace.space24,
          right: CoreSpace.space24,
          bottom: CoreSpace.space20,
        ),
      );
    });

    test('max width is the 560 layout token', () {
      expect(CoreDialogStyle.defaultPanelMaxWidth, CoreLayout.layout560);
      expect(CoreDialogStyle.defaultPanelMaxWidth, 560);
    });

    test('min width is the 280 layout token', () {
      expect(CoreDialogStyle.defaultPanelMinWidth, CoreLayout.layout280);
      expect(CoreDialogStyle.defaultPanelMinWidth, 280);
    });

    test('panelMinWidth takes part in merge, copyWith and equality', () {
      const a = CoreDialogStyle(panelMinWidth: 300);
      expect(const CoreDialogStyle().merge(a).panelMinWidth, 300);
      expect(a.merge(const CoreDialogStyle()).panelMinWidth, 300);
      expect(const CoreDialogStyle().copyWith(panelMinWidth: 300), a);
      expect(a == const CoreDialogStyle(panelMinWidth: 320), isFalse);
      expect(a.hashCode == const CoreDialogStyle().hashCode, isFalse);
    });

    test('head-to-body gap is 14 and body-to-actions gap is 20', () {
      expect(
        CoreDialogStyle.defaultSectionGapStyle,
        const CoreGapStyle(size: CoreSpace.space14),
      );
      expect(
        CoreDialogStyle.defaultActionsGapStyle,
        const CoreGapStyle(size: CoreSpace.space20),
      );
    });

    test('title is titleLarge and body is bodyMedium', () {
      expect(
        CoreDialogStyle.defaultTitleStyle.token,
        CoreTextStyles.titleLarge,
      );
      expect(
        CoreDialogStyle.defaultContentStyle.token,
        CoreTextStyles.bodyMedium,
      );
    });
  });

  group('CoreDialogStyle.actionsGapStyle', () {
    test('merges recursively, right-most size wins, unset inherits', () {
      const base = CoreDialogStyle(
        actionsGapStyle: CoreGapStyle(size: CoreSpace.space24),
      );
      expect(
        base
            .merge(
              const CoreDialogStyle(
                actionsGapStyle: CoreGapStyle(size: CoreSpace.space8),
              ),
            )
            .actionsGapStyle,
        const CoreGapStyle(size: CoreSpace.space8),
      );
      expect(
        base.merge(const CoreDialogStyle()).actionsGapStyle,
        const CoreGapStyle(size: CoreSpace.space24),
      );
      expect(const CoreDialogStyle().actionsGapStyle, isNull);
    });

    test('takes part in copyWith, equality and the hash', () {
      const a = CoreDialogStyle(
        actionsGapStyle: CoreGapStyle(size: CoreSpace.space24),
      );
      const b = CoreDialogStyle(
        actionsGapStyle: CoreGapStyle(size: CoreSpace.space8),
      );
      expect(
        const CoreDialogStyle().copyWith(
          actionsGapStyle: const CoreGapStyle(size: CoreSpace.space24),
        ),
        a,
      );
      expect(a.copyWith(actionSpacing: 4).actionsGapStyle, a.actionsGapStyle);
      expect(a == b, isFalse);
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('is independent of sectionGapStyle', () {
      const style = CoreDialogStyle(
        sectionGapStyle: CoreGapStyle(size: CoreSpace.space4),
      );
      expect(style.actionsGapStyle, isNull);
      expect(
        const CoreDialogStyle(
          actionsGapStyle: CoreGapStyle(size: CoreSpace.space4),
        ).sectionGapStyle,
        isNull,
      );
    });
  });

  group('CoreDialogStyle.routePadding', () {
    test('merges right-most wins, falls back to the default when unset', () {
      const base = CoreDialogStyle(routePadding: CoreSpace.space24);
      expect(
        base.merge(const CoreDialogStyle(routePadding: CoreSpace.space8)),
        const CoreDialogStyle(routePadding: CoreSpace.space8),
      );
      expect(base.merge(const CoreDialogStyle()).routePadding, 24);
      expect(const CoreDialogStyle().routePadding, isNull);
      expect(CoreDialogStyle.defaultRoutePadding, CoreSpace.space16);
    });

    test('takes part in copyWith, equality and the hash', () {
      const a = CoreDialogStyle(routePadding: CoreSpace.space24);
      expect(const CoreDialogStyle().copyWith(routePadding: 24), a);
      expect(a.copyWith(actionSpacing: 4).routePadding, 24);
      expect(
        a == const CoreDialogStyle(routePadding: CoreSpace.space8),
        isFalse,
      );
      expect(
        a.hashCode,
        isNot(const CoreDialogStyle(routePadding: CoreSpace.space8).hashCode),
      );
    });
  });

  group('CoreDialogStyle.actionsLayout', () {
    test('defaults to end — the row at the panel end, as before', () {
      expect(const CoreDialogStyle().actionsLayout, isNull);
      expect(CoreDialogStyle.defaultActionsLayout, CoreDialogActionsLayout.end);
    });

    test('merges right-most wins, unset inherits', () {
      const base = CoreDialogStyle(
        actionsLayout: CoreDialogActionsLayout.stretch,
      );
      expect(
        base.merge(const CoreDialogStyle()).actionsLayout,
        CoreDialogActionsLayout.stretch,
      );
      expect(
        base
            .merge(
              const CoreDialogStyle(actionsLayout: CoreDialogActionsLayout.end),
            )
            .actionsLayout,
        CoreDialogActionsLayout.end,
      );
      expect(
        const CoreDialogStyle().merge(base).actionsLayout,
        CoreDialogActionsLayout.stretch,
      );
    });

    test('takes part in copyWith, equality and the hash', () {
      const a = CoreDialogStyle(actionsLayout: CoreDialogActionsLayout.stretch);
      const b = CoreDialogStyle(actionsLayout: CoreDialogActionsLayout.end);
      expect(
        const CoreDialogStyle().copyWith(
          actionsLayout: CoreDialogActionsLayout.stretch,
        ),
        a,
      );
      expect(
        a.copyWith(actionSpacing: 4).actionsLayout,
        CoreDialogActionsLayout.stretch,
      );
      expect(a == b, isFalse);
      expect(a == const CoreDialogStyle(), isFalse);
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('is independent of the gaps around and between the actions', () {
      const style = CoreDialogStyle(
        actionsLayout: CoreDialogActionsLayout.stretch,
      );
      expect(style.actionSpacing, isNull);
      expect(style.actionRunSpacing, isNull);
      expect(style.actionsGapStyle, isNull);
    });
  });

  group('CoreDialogTheme', () {
    test('style passes through', () {
      const style = CoreDialogStyle(panelPadding: _kPaddingLg);
      const theme = CoreDialogTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreDialogTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreDialogTheme(
        style: CoreDialogStyle(panelPadding: _kPaddingLg),
      );
      const b = CoreDialogTheme(
        style: CoreDialogStyle(panelPadding: _kPaddingLg),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  // The two lengths the scrolling body and the wrapping actions read. Both
  // resolvers chain `merged.x ?? default`, so each has to survive every step
  // of the value semantics or a stated value stops reaching the screen.
  group('CoreDialogStyle body scroll + wrapping actions', () {
    test('a wrapped row sits as far below as two actions sit apart', () {
      expect(
        CoreDialogStyle.defaultActionRunSpacing,
        CoreDialogStyle.defaultActionSpacing,
      );
    });

    test('the body clip reaches exactly as far as the focus outline', () {
      expect(
        CoreDialogStyle.defaultContentClipMargin,
        CoreFocusOutlineStyle.defaultAlign,
      );
      // ...and stays inside the default gaps and padding around the body,
      // so nothing it keeps paints over the title or the actions.
      expect(
        CoreDialogStyle.defaultContentClipMargin,
        lessThanOrEqualTo(CoreDialogStyle.defaultSectionGapStyle.size!),
      );
      expect(
        CoreDialogStyle.defaultContentClipMargin,
        lessThanOrEqualTo(CoreDialogStyle.defaultActionsGapStyle.size!),
      );
    });

    test('merge: the other side wins, null keeps this side', () {
      const base = CoreDialogStyle(
        actionRunSpacing: CoreSpace.space4,
        contentClipMargin: CoreSpace.space2,
      );
      final over = base.merge(
        const CoreDialogStyle(
          actionRunSpacing: CoreSpace.space12,
          contentClipMargin: CoreSpace.space8,
        ),
      );
      expect(over.actionRunSpacing, CoreSpace.space12);
      expect(over.contentClipMargin, CoreSpace.space8);

      final kept = base.merge(const CoreDialogStyle());
      expect(kept.actionRunSpacing, CoreSpace.space4);
      expect(kept.contentClipMargin, CoreSpace.space2);
    });

    test('copyWith carries and replaces them', () {
      const base = CoreDialogStyle(
        actionRunSpacing: CoreSpace.space4,
        contentClipMargin: CoreSpace.space2,
      );
      expect(base.copyWith().actionRunSpacing, CoreSpace.space4);
      expect(base.copyWith().contentClipMargin, CoreSpace.space2);
      expect(
        base.copyWith(actionRunSpacing: CoreSpace.space12).actionRunSpacing,
        CoreSpace.space12,
      );
      expect(
        base.copyWith(contentClipMargin: CoreSpace.space8).contentClipMargin,
        CoreSpace.space8,
      );
    });

    test('== and hashCode see them', () {
      const a = CoreDialogStyle(actionRunSpacing: CoreSpace.space4);
      const b = CoreDialogStyle(contentClipMargin: CoreSpace.space4);
      expect(a, const CoreDialogStyle(actionRunSpacing: CoreSpace.space4));
      expect(
        a.hashCode,
        const CoreDialogStyle(actionRunSpacing: CoreSpace.space4).hashCode,
      );
      expect(a, isNot(const CoreDialogStyle()));
      expect(b, isNot(const CoreDialogStyle()));
      expect(a, isNot(b));
    });
  });
}
