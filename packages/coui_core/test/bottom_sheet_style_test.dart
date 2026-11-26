import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreBottomSheetStyle', () {
    test('the panel is the bright surface with two rounded top corners', () {
      expect(
        CoreBottomSheetStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(
        CoreBottomSheetStyle.defaultBorderRadius,
        const CoreBorderRadius.only(
          topLeft: CoreRadius.radius24,
          topRight: CoreRadius.radius24,
        ),
      );
    });

    test('the handle is a 36 x 4 pill with 8 above it', () {
      expect(CoreBottomSheetStyle.defaultHandleWidth, 36);
      expect(CoreBottomSheetStyle.defaultHandleHeight, 4);
      expect(
        CoreBottomSheetStyle.defaultHandleColor,
        const CoreColor.token(CoreColors.outline),
      );
      expect(
        CoreBottomSheetStyle.defaultHandleBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
      expect(
        CoreBottomSheetStyle.defaultHandlePadding,
        const CoreEdgeInsets.only(top: CoreSpace.space8),
      );
    });

    test('the header, the content and the gaps are existing space steps', () {
      expect(
        CoreBottomSheetStyle.defaultHeaderPadding,
        const CoreEdgeInsets.only(
          left: CoreSpace.space20,
          top: CoreSpace.space20,
          right: CoreSpace.space20,
          bottom: CoreSpace.space8,
        ),
      );
      expect(CoreBottomSheetStyle.defaultHeaderSpacing, CoreSpace.space12);
      expect(
        CoreBottomSheetStyle.defaultTitleGapStyle,
        const CoreGapStyle(size: CoreSpace.space8),
      );
      expect(
        CoreBottomSheetStyle.defaultContentPadding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space20,
          vertical: CoreSpace.space8,
        ),
      );
    });

    test('the title and the description read existing roles', () {
      expect(
        CoreBottomSheetStyle.defaultTitleTextStyle,
        const CoreTextStyle.token(
          CoreTextStyles.titleLarge,
          color: CoreColor.token(CoreColors.onSurface),
        ),
      );
      expect(
        CoreBottomSheetStyle.defaultDescriptionTextStyle,
        const CoreTextStyle.token(
          CoreTextStyles.bodyLarge,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      );
    });

    test("the close button is the sm row's 32 square", () {
      expect(CoreBottomSheetStyle.defaultCloseButtonStyle.width, 32);
      expect(CoreBottomSheetStyle.defaultCloseButtonStyle.height, 32);
      expect(
        CoreBottomSheetStyle.defaultCloseButtonStyle.padding,
        CoreEdgeInsets.zero,
      );
    });

    test('the sheet stops at 90 % of the viewport', () {
      expect(CoreBottomSheetStyle.defaultMaxHeightFactor, 0.9);
    });

    test("the footer hairline is the action bar's own line", () {
      expect(
        CoreBottomSheetStyle.defaultFooterDividerColor,
        CoreBottomActionBarStyle.defaultDividerColor,
      );
      expect(
        CoreBottomSheetStyle.defaultFooterDividerWidth,
        CoreBottomActionBarStyle.defaultDividerWidth,
      );
    });

    test('a bar in the footer paints no fill and no hairline of its own', () {
      expect(
        CoreBottomSheetStyle.defaultFooterBarStyle,
        const CoreBottomActionBarStyle(
          backgroundColor: CoreColor.transparent,
          dividerWidth: CoreStrokeWidth.stroke0,
        ),
      );
    });

    test(
      "footerBarThemeStyle: the sheet's statement wins over the project's "
      'bar theme, which fills the rest',
      () {
        const inherited = CoreBottomActionBarTheme(
          style: CoreBottomActionBarStyle(
            backgroundColor: CoreColor.token(CoreColors.surface),
            spacing: 4,
          ),
        );
        final folded = CoreBottomSheetContract.footerBarThemeStyle(
          inherited,
          CoreBottomSheetStyle.defaultFooterBarStyle,
        );
        expect(folded.backgroundColor, CoreColor.transparent);
        expect(folded.dividerWidth, CoreStrokeWidth.stroke0);
        expect(folded.spacing, 4);
        expect(
          CoreBottomSheetContract.footerBarThemeStyle(
            null,
            CoreBottomSheetStyle.defaultFooterBarStyle,
          ),
          CoreBottomSheetStyle.defaultFooterBarStyle,
        );
      },
    );

    test('the contract defaults: handle on, close and divider off', () {
      expect(CoreBottomSheetContract.defaultShowHandle, isTrue);
      expect(CoreBottomSheetContract.defaultShowCloseButton, isFalse);
      expect(CoreBottomSheetContract.defaultShowDivider, isFalse);
    });

    test('merge: stated fields win, the nested slots merge field by field', () {
      const base = CoreBottomSheetStyle(
        handleWidth: 40,
        titleGapStyle: CoreGapStyle(size: 4),
        closeButtonStyle: CoreButtonStyle(width: 40),
      );
      const patch = CoreBottomSheetStyle(
        handleHeight: 6,
        titleGapStyle: CoreGapStyle(crossAxisExtent: 2),
        closeButtonStyle: CoreButtonStyle(height: 40),
      );
      final merged = base.merge(patch);
      expect(merged.handleWidth, 40);
      expect(merged.handleHeight, 6);
      expect(merged.titleGapStyle?.size, 4);
      expect(merged.titleGapStyle?.crossAxisExtent, 2);
      expect(merged.closeButtonStyle?.width, 40);
      expect(merged.closeButtonStyle?.height, 40);
      expect(base.merge(null), same(base));
    });

    test('copyWith and equality cover every field', () {
      const style = CoreBottomSheetStyle(
        backgroundColor: CoreColor.token(CoreColors.surface),
        handleWidth: 30,
        headerSpacing: 4,
      );
      expect(style, style.copyWith());
      expect(style.hashCode, style.copyWith().hashCode);
      expect(style.copyWith(handleWidth: 31), isNot(style));
      expect(style.copyWith(headerSpacing: 5), isNot(style));
      expect(style.copyWith(maxHeightFactor: 0.5), isNot(style));
      expect(
        style.copyWith(
          footerDividerColor: const CoreColor.token(CoreColors.outline),
        ),
        isNot(style),
      );
      expect(style.copyWith(footerDividerWidth: 2), isNot(style));
      expect(
        style.copyWith(
          footerBarStyle: const CoreBottomActionBarStyle(spacing: 2),
        ),
        isNot(style),
      );
    });

    test('merge: the footer bar slot merges field by field', () {
      const base = CoreBottomSheetStyle(
        maxHeightFactor: 0.8,
        footerBarStyle: CoreBottomActionBarStyle(spacing: 2),
      );
      const patch = CoreBottomSheetStyle(
        footerDividerWidth: 2,
        footerBarStyle: CoreBottomActionBarStyle(dividerWidth: 1),
      );
      final merged = base.merge(patch);
      expect(merged.maxHeightFactor, 0.8);
      expect(merged.footerDividerWidth, 2);
      expect(merged.footerBarStyle?.spacing, 2);
      expect(merged.footerBarStyle?.dividerWidth, 1);
    });

    test('the theme carries one slot', () {
      const theme = CoreBottomSheetTheme(style: CoreBottomSheetStyle());
      expect(theme, const CoreBottomSheetTheme(style: CoreBottomSheetStyle()));
      expect(const CoreComponentTheme(bottomSheet: theme).bottomSheet, theme);
    });
  });
}
