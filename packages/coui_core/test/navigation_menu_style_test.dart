import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreNavigationMenuStyle defaults', () {
    test('triggers sit 2 apart and the label and chevron 4 apart', () {
      expect(CoreNavigationMenuStyle.defaultTriggerSpacing, CoreSpace.space2);
      expect(
        CoreNavigationMenuStyle.defaultTriggerButtonStyle.iconLabelGapStyle,
        const CoreGapStyle(size: CoreSpace.space4),
      );
    });

    test('a trigger without a dropdown is inset 12 / 8, symmetric', () {
      expect(
        CoreNavigationMenuStyle.defaultTriggerButtonStyle.padding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space12,
          vertical: CoreSpace.space8,
        ),
      );
      expect(
        CoreNavigationMenuStyle
            .defaultTriggerButtonStyle
            .padding!
            .isDirectional,
        isFalse,
      );
    });

    test(
      'a trigger with a dropdown is inset 12 at the start, 8 at the end',
      () {
        const padding =
            CoreNavigationMenuStyle.defaultContentTriggerButtonStyle;

        expect(
          padding.padding,
          const CoreEdgeInsets.directional(
            start: CoreSpace.space12,
            end: CoreSpace.space8,
            top: CoreSpace.space8,
            bottom: CoreSpace.space8,
          ),
        );
        // The two horizontal values differ because of what they are — a
        // disclosure mark at the end — so the inset follows the reading order.
        expect(padding.padding!.isDirectional, isTrue);
      },
    );

    test('the hover fill and the open fill are the same surface step', () {
      const hover = CoreNavigationMenuStyle.defaultTriggerHoverColor;

      expect(
        hover,
        const CoreColor.token(
          CoreColors.surfaceContainer,
          fallbacks: [CoreColors.surfaceContainerHigh],
        ),
      );
      expect(
        CoreNavigationMenuStyle.defaultTriggerButtonStyle.hoverBackgroundColor,
        hover,
      );
      expect(
        CoreNavigationMenuStyle.defaultOpenTriggerButtonStyle.backgroundColor,
        hover,
      );
    });

    test('the chevron recedes behind the label', () {
      expect(
        CoreNavigationMenuStyle.defaultChevronIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    test('the dropdown is corner 12, the panel role', () {
      expect(
        CoreNavigationMenuStyle.defaultPanelStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
      expect(CoreRadiusRole.panel, 12);
    });
  });

  group('CoreNavigationMenuStyle slots', () {
    const content = CoreButtonStyle(
      padding: CoreEdgeInsets.all(CoreSpace.space4),
    );
    const open = CoreButtonStyle(
      backgroundColor: CoreColor.token(CoreColors.primaryContainer),
    );
    const style = CoreNavigationMenuStyle(
      contentTriggerButtonStyle: content,
      openTriggerButtonStyle: open,
    );

    test('merge keeps and overlays the two slots', () {
      expect(style.merge(null), style);
      expect(
        const CoreNavigationMenuStyle().merge(style).contentTriggerButtonStyle,
        content,
      );

      const other = CoreNavigationMenuStyle(
        contentTriggerButtonStyle: CoreButtonStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        ),
      );
      final merged = style.merge(other);

      // Recursive: the other's radius lands and this one's inset stays.
      expect(merged.contentTriggerButtonStyle!.padding, content.padding);
      expect(
        merged.contentTriggerButtonStyle!.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      expect(merged.openTriggerButtonStyle, open);
    });

    test('copyWith carries them', () {
      expect(
        style.copyWith(triggerSpacing: 3).contentTriggerButtonStyle,
        content,
      );
      expect(style.copyWith(triggerSpacing: 3).openTriggerButtonStyle, open);
      expect(
        const CoreNavigationMenuStyle()
            .copyWith(
              contentTriggerButtonStyle: content,
            )
            .contentTriggerButtonStyle,
        content,
      );
    });

    test('they are part of equality and hashing', () {
      const same = CoreNavigationMenuStyle(
        contentTriggerButtonStyle: content,
        openTriggerButtonStyle: open,
      );

      expect(style, same);
      expect(style.hashCode, same.hashCode);
      expect(
        style,
        isNot(
          const CoreNavigationMenuStyle(contentTriggerButtonStyle: content),
        ),
      );
      expect(
        style,
        isNot(const CoreNavigationMenuStyle(openTriggerButtonStyle: open)),
      );
    });
  });
}
