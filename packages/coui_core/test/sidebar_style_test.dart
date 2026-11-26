import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The Sidebar family's Core styles — the defaults the issue states and the
/// value-type contract (merge · copyWith · == · hashCode) every Style keeps.
void main() {
  group('CoreSidebarStyle', () {
    test('every type states its width, insets and rail face', () {
      for (final type in CoreSidebarType.values) {
        final row = CoreSidebarStyle.defaultsByType[type]!;
        expect(row.panelWidth, isNotNull, reason: type.name);
        expect(row.topPadding, isNotNull, reason: type.name);
        expect(row.bodyPadding, isNotNull, reason: type.name);
        expect(row.railBackgroundColor, isNotNull, reason: type.name);
      }
      expect(
        CoreSidebarStyle.defaultsByType[CoreSidebarType.standard]!.panelWidth,
        CoreLayout.layout248,
      );
      expect(
        CoreSidebarStyle.defaultsByType[CoreSidebarType.twoPane]!.panelWidth,
        CoreLayout.layout240,
      );
      expect(CoreSidebarStyle.defaultRailWidth, CoreSize.size64);
    });

    test('the face is the chrome tier with an outlineVariant edge', () {
      expect(
        CoreSidebarStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
      expect(
        CoreSidebarStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    test('the type decides the rail and the panel', () {
      expect(CoreSidebarType.standard.hasRail, isFalse);
      expect(CoreSidebarType.standard.hasPanel, isTrue);
      expect(CoreSidebarType.twoPane.hasRail, isTrue);
      expect(CoreSidebarType.twoPane.hasPanel, isTrue);
      expect(CoreSidebarType.collapsed.hasRail, isTrue);
      expect(CoreSidebarType.collapsed.hasPanel, isFalse);
    });

    test('merge lets the later style win and keeps the rest', () {
      const base = CoreSidebarStyle(panelWidth: 200, railWidth: 60);
      final merged = base.merge(const CoreSidebarStyle(panelWidth: 300));
      expect(merged.panelWidth, 300);
      expect(merged.railWidth, 60);
      expect(merged, const CoreSidebarStyle(panelWidth: 300, railWidth: 60));
      expect(
        merged.hashCode,
        const CoreSidebarStyle(panelWidth: 300, railWidth: 60).hashCode,
      );
      expect(base.copyWith(railWidth: 1).railWidth, 1);
    });
  });

  group('CoreSidebarItemStyle', () {
    test('an unselected row reads lighter than the current place', () {
      expect(
        CoreSidebarItemStyle.defaultLabelStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(
        CoreSidebarItemStyle.defaultIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(
        CoreSidebarItemStyle.defaultSelectedLabelStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        CoreSidebarItemStyle.defaultSelectedLabelStyle.fontWeight,
        CoreFontWeight.semiBold,
      );
      expect(
        CoreSidebarItemStyle.defaultSelectedBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainer),
      );
    });

    test("a disabled row's trailing glyph reads the ink its label does", () {
      expect(
        CoreSidebarItemStyle.defaultDisabledTrailingIconStyle.color,
        CoreSidebarItemStyle.defaultDisabledLabelStyle.color,
      );
      expect(
        CoreSidebarItemStyle.defaultDisabledTrailingIconStyle.color,
        const CoreColor.token(CoreColors.disabledContent),
      );
      // Merged over the resting trailing glyph, it keeps that glyph's size.
      final disabled = CoreSidebarItemStyle.defaultTrailingIconStyle.merge(
        CoreSidebarItemStyle.defaultDisabledTrailingIconStyle,
      );
      expect(disabled.size, CoreSidebarItemStyle.defaultTrailingIconStyle.size);
      expect(disabled.color, const CoreColor.token(CoreColors.disabledContent));
      // The resting trailing glyph is not the disabled one.
      expect(
        CoreSidebarItemStyle.defaultTrailingIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
    });

    test('the disabled trailing glyph is part of the value', () {
      const base = CoreSidebarItemStyle();
      const withIt = CoreSidebarItemStyle(
        disabledTrailingIconStyle: CoreIconStyle(
          color: CoreColor.token(CoreColors.error),
        ),
      );
      expect(base == withIt, isFalse);
      expect(base.merge(withIt), withIt);
      expect(
        base.copyWith(
          disabledTrailingIconStyle: withIt.disabledTrailingIconStyle,
        ),
        withIt,
      );
      expect(
        withIt.hashCode,
        base
            .copyWith(
              disabledTrailingIconStyle: withIt.disabledTrailingIconStyle,
            )
            .hashCode,
      );
    });

    test('the level picks the height and the role', () {
      final top =
          CoreSidebarItemStyle.defaultsByLevel[CoreSidebarItemLevel.top]!;
      final nested =
          CoreSidebarItemStyle.defaultsByLevel[CoreSidebarItemLevel.nested]!;
      expect(top.minHeight, CoreSize.size36);
      expect(nested.minHeight, CoreSize.size32);
      expect(top.labelStyle!.token, CoreTextStyles.labelLarge);
      expect(nested.labelStyle!.token, CoreTextStyles.labelMedium);
    });

    test('nested slots merge field by field', () {
      const base = CoreSidebarItemStyle(
        iconStyle: CoreIconStyle(size: CoreSize.size18),
      );
      final merged = base.merge(
        const CoreSidebarItemStyle(
          iconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.error)),
        ),
      );
      expect(merged.iconStyle!.size, CoreSize.size18);
      expect(merged.iconStyle!.color, const CoreColor.token(CoreColors.error));
    });
  });

  group('the rest of the family', () {
    test('header variants: plain has no line, card has one', () {
      final plain = CoreSidebarHeaderStyle
          .defaultsByVariant[CoreSidebarHeaderVariant.plain]!;
      final card = CoreSidebarHeaderStyle
          .defaultsByVariant[CoreSidebarHeaderVariant.card]!;
      expect(plain.borderColor, isNull);
      expect(card.borderColor, const CoreColor.token(CoreColors.outlineSubtle));
      expect(card.backgroundColor, const CoreColor.token(CoreColors.surface));
    });

    test('the search trigger, the rail item and the section', () {
      expect(CoreSidebarSearchStyle.defaultMinHeight, CoreSize.size36);
      expect(CoreSidebarRailItemStyle.defaultSize, CoreSize.size40);
      expect(
        CoreSidebarRailItemStyle.defaultIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(
        CoreSidebarSectionStyle.defaultLabelStyle.token,
        CoreTextStyles.labelSmall,
      );
      expect(
        CoreSidebarGroupStyle.defaultChildrenPadding,
        const CoreEdgeInsets.directional(start: CoreSpace.space28),
      );
    });

    test('equality covers every field', () {
      expect(
        const CoreSidebarGroupStyle(treeLineInset: 1),
        isNot(const CoreSidebarGroupStyle(treeLineInset: 2)),
      );
      expect(
        const CoreSidebarSearchStyle(minHeight: 1),
        const CoreSidebarSearchStyle(minHeight: 1),
      );
      expect(
        const CoreSidebarRailItemStyle(dotSize: 1),
        isNot(const CoreSidebarRailItemStyle(dotSize: 2)),
      );
      expect(
        const CoreSidebarSectionStyle(contentSpacing: 1).hashCode,
        const CoreSidebarSectionStyle(contentSpacing: 1).hashCode,
      );
    });

    test('themes compare by value', () {
      expect(
        const CoreSidebarTheme(
          variantStyles: {
            CoreSidebarType.twoPane: CoreSidebarStyle(panelWidth: 1),
          },
        ),
        const CoreSidebarTheme(
          variantStyles: {
            CoreSidebarType.twoPane: CoreSidebarStyle(panelWidth: 1),
          },
        ),
      );
      expect(
        const CoreSidebarItemTheme(style: CoreSidebarItemStyle(dotSize: 1)),
        isNot(
          const CoreSidebarItemTheme(style: CoreSidebarItemStyle(dotSize: 2)),
        ),
      );
    });
  });
}
