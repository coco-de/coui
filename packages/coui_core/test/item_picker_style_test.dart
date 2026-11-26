import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreItemPickerStyle redesign (#5831)', () {
    test('the panel is a floating face: bright fill, quiet line, corner 12, '
        'the strong cast', () {
      expect(
        CoreItemPickerStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(
        CoreItemPickerStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreItemPickerStyle.defaultHoverBorderColor,
        const CoreColor.token(CoreColors.outline),
      );
      expect(
        CoreItemPickerStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
      expect(
        CoreItemPickerStyle.defaultElevation,
        CoreOutlinedContainerElevation.strong,
      );
    });

    test('the list is inset 6; rows are 8 padded with corner 8', () {
      expect(
        CoreItemPickerStyle.defaultItemsPadding,
        const CoreEdgeInsets.all(CoreSpace.space6),
      );
      expect(
        CoreItemPickerStyle.defaultOptionPadding,
        const CoreEdgeInsets.all(CoreSpace.space8),
      );
      expect(
        CoreItemPickerStyle.defaultOptionBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.control),
      );
    });

    test('rows read in bodyMedium', () {
      for (final style in [
        CoreItemPickerStyle.defaultOptionTextStyle,
        CoreItemPickerStyle.defaultSelectedTextStyle,
        CoreItemPickerStyle.defaultOptionHoverTextStyle,
      ]) {
        expect(style.token, CoreTextStyles.bodyMedium);
      }
    });

    test('the section label is labelSmall in onSurfaceSubtle, inset '
        '6 / 4 / 8 so its left edge meets the rows at 14 (#5884)', () {
      const label = CoreItemPickerStyle.defaultTitleTextStyle;
      expect(label.token, CoreTextStyles.labelSmall);
      expect(label.color, const CoreColor.token(CoreColors.onSurfaceSubtle));
      // The role's own weight — no overlay.
      expect(label.fontWeight, isNull);
      expect(
        CoreItemPickerStyle.defaultTitlePadding,
        const CoreEdgeInsets.only(
          left: CoreSpace.space8,
          top: CoreSpace.space6,
          right: CoreSpace.space8,
          bottom: CoreSpace.space4,
        ),
      );
      // The list inset and the label's side inset share one column.
      expect(
        CoreItemPickerStyle.defaultItemsPadding.left +
            CoreItemPickerStyle.defaultTitlePadding.left,
        CoreItemPickerStyle.defaultItemsPadding.left +
            CoreItemPickerStyle.defaultOptionPadding.left,
      );
    });

    test('the selection is the check alone, in primary; no fill', () {
      expect(CoreItemPickerStyle.defaultSelectedColor, CoreColor.transparent);
      expect(
        CoreItemPickerStyle.defaultCheckColor,
        const CoreColor.token(CoreColors.primary),
      );
    });

    test('the search is the bare field inset 14, with a quiet 16 glyph', () {
      expect(
        CoreItemPickerStyle.defaultSearchFieldStyle.padding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space14,
          vertical: CoreSpace.space8,
        ),
      );
      expect(CoreItemPickerStyle.defaultSearchIconStyle.size, 16);
      expect(
        CoreItemPickerStyle.defaultSearchIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(
        CoreItemPickerStyle.defaultDisabledSearchIconColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('the new fields take part in merge / copyWith / ==', () {
      // The disabled foreground is a value-typed field: a state that only it
      // changes must still compare unequal, or a disabled repaint is skipped.
      const base = CoreItemPickerStyle();
      const disabled = CoreItemPickerStyle(
        disabledForegroundColor: CoreColor(0xFF0A0B0C),
      );
      expect(base == disabled, isFalse);
      expect(base.hashCode == disabled.hashCode, isFalse);
      expect(
        base.merge(disabled).disabledForegroundColor,
        const CoreColor(0xFF0A0B0C),
      );
      expect(
        disabled.copyWith().disabledForegroundColor,
        const CoreColor(0xFF0A0B0C),
      );
      expect(
        CoreItemPickerStyle.defaultDisabledForegroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );

      const style = CoreItemPickerStyle(
        elevation: CoreOutlinedContainerElevation.soft,
        checkColor: CoreColor(0xFF010203),
        searchIconStyle: CoreIconStyle(size: 11),
        searchDividerStyle: CoreDividerStyle(thickness: 3),
      );
      const other = CoreItemPickerStyle(
        searchIconStyle: CoreIconStyle(size: 12),
      );

      expect(const CoreItemPickerStyle().merge(style), style);
      expect(style.merge(other).searchIconStyle?.size, 12);
      expect(style.merge(other).searchDividerStyle?.thickness, 3);
      expect(style.merge(other).elevation, CoreOutlinedContainerElevation.soft);
      expect(style.copyWith(), style);
      expect(style.copyWith().hashCode, style.hashCode);
      expect(
        style,
        isNot(style.copyWith(elevation: CoreOutlinedContainerElevation.none)),
      );
      expect(style, isNot(style.copyWith(checkColor: const CoreColor(1))));
    });
  });
}
