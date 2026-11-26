// Tests for CorePhoneInputStyle (Epic #1663 — phone_input 1:1:1:1).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CorePhoneInputStyle.merge', () {
    test('null other returns this', () {
      const a = CorePhoneInputStyle(height: 40);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('right-most non-null wins on each field', () {
      const a = CorePhoneInputStyle(height: 40, popupMaxWidth: 200);
      const b = CorePhoneInputStyle(height: 48);
      const c = CorePhoneInputStyle(popupMaxWidth: 300);

      final result = a.merge(b).merge(c);

      expect(result.height, 48);
      expect(result.popupMaxWidth, 300);
    });
  });

  group('CorePhoneInputStyle dimensional fields', () {
    test('merge propagates non-null dimensional fields', () {
      const base = CorePhoneInputStyle(
        height: 40,
        borderWidth: 1,
        dropdownItemGapStyle: CoreGapStyle(size: 8),
        popupMaxWidth: 248,
        popupMaxHeight: 248,
        popoverTopOffset: 4,
        chevronIconStyle: CoreIconStyle(size: 12),
        flagSize: 16,
        dropdownFlagSize: 16,
        disabledOpacity: 0.5,
      );
      const override = CorePhoneInputStyle(
        height: 48,
        popupMaxWidth: 320,
        chevronIconStyle: CoreIconStyle(size: 16),
      );

      final merged = base.merge(override);

      expect(merged.height, 48);
      expect(merged.borderWidth, 1);
      expect(merged.dropdownItemGapStyle, const CoreGapStyle(size: 8));
      expect(merged.popupMaxWidth, 320);
      expect(merged.popupMaxHeight, 248);
      expect(merged.popoverTopOffset, 4);
      expect(merged.chevronIconStyle?.size, 16);
      expect(merged.flagSize, 16);
      expect(merged.dropdownFlagSize, 16);
      expect(merged.disabledOpacity, 0.5);
    });

    test(
      'merge propagates non-null typed (EdgeInsets / BorderRadius) fields',
      () {
        const base = CorePhoneInputStyle(
          selectorPadding: CoreEdgeInsets.symmetric(horizontal: 12),
          dropdownItemPadding: CoreEdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          popupBorderRadius: CoreBorderRadius.all(8),
        );
        const override = CorePhoneInputStyle(
          selectorPadding: CoreEdgeInsets.symmetric(horizontal: 16),
          popupBorderRadius: CoreBorderRadius.all(12),
        );

        final merged = base.merge(override);

        expect(
          merged.selectorPadding,
          const CoreEdgeInsets.symmetric(horizontal: 16),
        );
        expect(
          merged.dropdownItemPadding,
          const CoreEdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
        expect(merged.popupBorderRadius, const CoreBorderRadius.all(12));
      },
    );

    test('copyWith replaces dimensional fields', () {
      const base = CorePhoneInputStyle(
        height: 40,
        borderWidth: 1,
        dropdownItemGapStyle: CoreGapStyle(size: 8),
        popupMaxWidth: 248,
        chevronIconStyle: CoreIconStyle(size: 12),
        flagSize: 16,
        dropdownFlagSize: 16,
        disabledOpacity: 0.5,
      );
      final next = base.copyWith(
        height: 56,
        chevronIconStyle: const CoreIconStyle(size: 20),
        disabledOpacity: 0.4,
      );

      expect(next.height, 56);
      expect(next.borderWidth, 1);
      expect(next.dropdownItemGapStyle, const CoreGapStyle(size: 8));
      expect(next.popupMaxWidth, 248);
      expect(next.chevronIconStyle?.size, 20);
      expect(next.flagSize, 16);
      expect(next.dropdownFlagSize, 16);
      expect(next.disabledOpacity, 0.4);
    });

    test('the country list draws the flag at the selector step', () {
      expect(
        CorePhoneInputStyle.defaultDropdownFlagSize,
        CorePhoneInputStyle.defaultFlagSize,
      );
    });

    test('copyWith replaces typed (EdgeInsets / BorderRadius) fields', () {
      const base = CorePhoneInputStyle(
        selectorPadding: CoreEdgeInsets.symmetric(horizontal: 12),
        dropdownItemPadding: CoreEdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        popupBorderRadius: CoreBorderRadius.all(8),
      );
      final next = base.copyWith(
        selectorPadding: const CoreEdgeInsets.symmetric(horizontal: 20),
        popupBorderRadius: const CoreBorderRadius.all(16),
      );

      expect(
        next.selectorPadding,
        const CoreEdgeInsets.symmetric(horizontal: 20),
      );
      expect(
        next.dropdownItemPadding,
        const CoreEdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );
      expect(next.popupBorderRadius, const CoreBorderRadius.all(16));
    });

    test('equality and hashCode cover dimensional fields', () {
      const a = CorePhoneInputStyle(
        height: 40,
        popupMaxWidth: 248,
        chevronIconStyle: CoreIconStyle(size: 12),
        disabledOpacity: 0.5,
        popupBorderRadius: CoreBorderRadius.all(8),
      );
      const b = CorePhoneInputStyle(
        height: 40,
        popupMaxWidth: 248,
        chevronIconStyle: CoreIconStyle(size: 12),
        disabledOpacity: 0.5,
        popupBorderRadius: CoreBorderRadius.all(8),
      );
      const c = CorePhoneInputStyle(
        height: 48,
        popupMaxWidth: 248,
        chevronIconStyle: CoreIconStyle(size: 12),
        disabledOpacity: 0.5,
        popupBorderRadius: CoreBorderRadius.all(8),
      );
      const d = CorePhoneInputStyle(
        height: 40,
        popupMaxWidth: 248,
        chevronIconStyle: CoreIconStyle(size: 12),
        disabledOpacity: 0.5,
        popupBorderRadius: CoreBorderRadius.all(12),
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });
  });
  group('CorePhoneInputStyle border steps', () {
    const hoverRaw = CoreColor(0xFF00FF00);

    test(
      'the resting border is outline-variant and the hover step is outline',
      () {
        expect(
          CorePhoneInputStyle.defaultBorderColor,
          const CoreColor.token(CoreColors.outlineVariant),
        );
        expect(
          CorePhoneInputStyle.defaultHoverBorderColor,
          const CoreColor.token(CoreColors.outline),
        );
        // The divider keeps its own, quieter edge — it is not the box's border.
        expect(
          CorePhoneInputStyle.defaultSeparatorColor,
          const CoreColor.token(CoreColors.outlineVariant),
        );
      },
    );

    test(
      'hoverBorderColor is its own field, apart from the hover background',
      () {
        const style = CorePhoneInputStyle(hoverBorderColor: hoverRaw);
        expect(style.hoverBorderColor, hoverRaw);
        expect(style.hoverColor, isNull);
        expect(style.borderColor, isNull);
        expect(style.focusBorderColor, isNull);
      },
    );

    test(
      'merge — the right-most hoverBorderColor wins, null keeps the base',
      () {
        const base = CorePhoneInputStyle(
          hoverBorderColor: CoreColor.token(CoreColors.primary),
        );
        expect(
          base
              .merge(const CorePhoneInputStyle(hoverBorderColor: hoverRaw))
              .hoverBorderColor,
          hoverRaw,
        );
        expect(
          base.merge(const CorePhoneInputStyle(height: 48)).hoverBorderColor,
          const CoreColor.token(CoreColors.primary),
        );
      },
    );

    test(
      'copyWith replaces hoverBorderColor and leaves it alone otherwise',
      () {
        const base = CorePhoneInputStyle(hoverBorderColor: hoverRaw);
        expect(
          base
              .copyWith(
                hoverBorderColor: const CoreColor.token(CoreColors.primary),
              )
              .hoverBorderColor,
          const CoreColor.token(CoreColors.primary),
        );
        expect(base.copyWith(height: 48).hoverBorderColor, hoverRaw);
      },
    );

    test('equality and hashCode cover hoverBorderColor', () {
      const a = CorePhoneInputStyle(hoverBorderColor: hoverRaw);
      const b = CorePhoneInputStyle(hoverBorderColor: hoverRaw);
      const c = CorePhoneInputStyle(
        hoverBorderColor: CoreColor.token(CoreColors.primary),
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(a.hashCode, isNot(c.hashCode));
    });

    // A zero-width Flutter border is a hairline, not nothing: the field's
    // `onSurface` hover step would draw a second line inside the outer
    // container's one boundary unless the chromeless style silences it.
    test('the chromeless inner field states no hover border of its own', () {
      const chromeless = CorePhoneInputStyle.chromelessFieldStyle;
      expect(chromeless.hoverBorderColor, CoreColor.transparent);
      expect(chromeless.borderColor, CoreColor.transparent);
      expect(chromeless.focusBorderColor, CoreColor.transparent);
      // The number field is the chromeless style (at the dial code's size);
      // the country search is the item picker's bare field instead.
      expect(
        CorePhoneInputStyle.defaultNumberFieldStyle.borderColor,
        CoreColor.transparent,
      );
      expect(
        CorePhoneInputStyle.defaultSearchFieldStyle,
        CoreItemPickerStyle.defaultSearchFieldStyle,
      );
    });

    // With zero padding the caret sits on the field's own left edge, and a
    // browser clips an `<input>`'s content to its rounded box. A corner left
    // to the size row's default is a pill around a one-line field.
    test('the chromeless inner field states a square corner', () {
      expect(
        CorePhoneInputStyle.chromelessFieldStyle.borderRadius,
        CoreBorderRadius.zero,
      );
      expect(
        CorePhoneInputStyle.defaultNumberFieldStyle.borderRadius,
        CoreBorderRadius.zero,
      );
    });
  });

  group('CorePhoneInputStyle.placeholderFieldStyle', () {
    test('states only the placeholder colour, so it overlays cleanly', () {
      const color = CoreColor(0xFF00FF00);
      final overlay = CorePhoneInputStyle.placeholderFieldStyle(color);

      expect(overlay.placeholderStyle?.color, color);
      expect(
        overlay,
        const CoreTextFieldStyle(
          placeholderStyle: CoreTextStyle(color: color),
        ),
      );
      // Laid over the chromeless field, the chrome survives.
      final number = CorePhoneInputStyle.chromelessFieldStyle.merge(overlay);
      expect(number.placeholderStyle?.color, color);
      expect(
        number.borderWidth,
        CorePhoneInputStyle.chromelessFieldStyle.borderWidth,
      );
    });
  });

  group('CorePhoneInputStyle redesign (#5831)', () {
    test('the box is the lg row with the panel corner', () {
      expect(CorePhoneInputStyle.defaultHeight, CoreControlSize.heightLg);
      expect(
        CorePhoneInputStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
    });

    test('disabled states its own fill, edge and placeholder tokens', () {
      expect(
        CorePhoneInputStyle.defaultDisabledBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CorePhoneInputStyle.defaultDisabledBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        CorePhoneInputStyle.defaultDisabledPlaceholderColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(
        CorePhoneInputStyle.defaultDisabledDialCodeColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('the selector insets 14 / 10 by reading order; the flag is 14 with '
        'the part corner; the hairline is 20', () {
      expect(
        CorePhoneInputStyle.defaultSelectorPadding,
        const CoreEdgeInsets.directional(
          start: CoreSpace.space14,
          end: CoreSpace.space10,
        ),
      );
      expect(CorePhoneInputStyle.defaultFlagSize, CoreSize.size14);
      expect(
        CorePhoneInputStyle.defaultFlagBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.part),
      );
      expect(CorePhoneInputStyle.defaultSeparatorHeight, CoreSize.size20);
      expect(
        CorePhoneInputStyle.defaultFlagGapStyle.size,
        CoreSpace.space6,
      );
    });

    test('the country panel states the item picker panel', () {
      expect(
        CorePhoneInputStyle.defaultDropdownListPadding,
        CoreItemPickerStyle.defaultItemsPadding,
      );
      expect(
        CorePhoneInputStyle.defaultDropdownItemPadding,
        CoreItemPickerStyle.defaultOptionPadding,
      );
      expect(
        CorePhoneInputStyle.defaultDropdownItemBorderRadius,
        CoreItemPickerStyle.defaultOptionBorderRadius,
      );
      expect(
        CorePhoneInputStyle.defaultDropdownCheckIconStyle.color,
        CoreItemPickerStyle.defaultCheckColor,
      );
      expect(
        CorePhoneInputStyle.defaultSearchIconStyle,
        CoreItemPickerStyle.defaultSearchIconStyle,
      );
      expect(
        CorePhoneInputStyle.defaultPopoverStyle.panelStyle?.borderColor,
        CoreItemPickerStyle.defaultBorderColor,
      );
    });

    test('the new fields take part in merge / copyWith / ==', () {
      const style = CorePhoneInputStyle(
        flagBorderRadius: CoreBorderRadius.zero,
        separatorHeight: 7,
        disabledBackgroundColor: CoreColor(0xFF010203),
        disabledBorderColor: CoreColor(0xFF040506),
        disabledPlaceholderColor: CoreColor(0xFF070809),
        dropdownListPadding: CoreEdgeInsets.zero,
        dropdownItemBorderRadius: CoreBorderRadius.zero,
        dropdownCheckIconStyle: CoreIconStyle(size: 9),
        searchIconStyle: CoreIconStyle(size: 11),
      );
      const other = CorePhoneInputStyle(separatorHeight: 8);

      expect(const CorePhoneInputStyle().merge(style), style);
      expect(style.merge(other).separatorHeight, 8);
      expect(style.merge(other).flagBorderRadius, CoreBorderRadius.zero);
      expect(style.merge(other).searchIconStyle?.size, 11);
      expect(style.copyWith(), style);
      expect(style.copyWith().hashCode, style.hashCode);
      expect(style, isNot(style.copyWith(separatorHeight: 9)));
      expect(
        style,
        isNot(style.copyWith(searchIconStyle: const CoreIconStyle())),
      );
    });
  });
}
