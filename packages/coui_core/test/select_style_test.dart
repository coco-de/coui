// `CoreSelectStyle` after the redesign (Select 코드 인계 통합본 2026-09-08):
// the trigger is a field, the rows are menu rows, and the only chrome
// Select states for itself is the panel, the chevron and the empty state.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kPadH8 = CoreEdgeInsets.symmetric(horizontal: 8);
const _kPadH16 = CoreEdgeInsets.symmetric(horizontal: 16);

void main() {
  group('the trigger is a field', () {
    test('the size ladder maps onto the field rungs, and those are '
        '32 / 40 / 48', () {
      for (final size in CoreSelectSize.values) {
        final field =
            CoreTextFieldStyle.defaultsBySize[size.toComponentSize()]!;
        expect(field.minHeight, isNotNull);
      }
      expect(
        CoreTextFieldStyle
            .defaultsBySize[CoreSelectSize.sm.toComponentSize()]!
            .minHeight,
        CoreControlSize.heightSm,
      );
      expect(
        CoreTextFieldStyle
            .defaultsBySize[CoreSelectSize.md.toComponentSize()]!
            .minHeight,
        CoreControlSize.heightMd,
      );
      expect(
        CoreTextFieldStyle
            .defaultsBySize[CoreSelectSize.lg.toComponentSize()]!
            .minHeight,
        CoreControlSize.heightLg,
      );
      expect(CoreSelectSize.defaultSize, CoreSelectSize.md);
    });

    test('a md select and a md text field share their inset — the reason '
        'the trigger stopped being a button', () {
      final field = CoreTextFieldStyle
          .defaultsBySize[CoreSelectSize.md.toComponentSize()]!
          .padding!;
      // 12, the field ladder's rung. The button ladder's is 16, and the
      // 4px difference is what showed when the two were stacked.
      expect(field.left, CoreSpace.space12);
      expect(field.left, isNot(CoreSpace.space16));
    });

    test('the trigger slot states only what still diverges from the '
        'field — a pressed-only wash; the field itself reads at 14px '
        'body-medium (role line height) on every rung it shares with Select '
        '(2026-09-11 재검토)', () {
      const slot = CoreSelectStyle.defaultTriggerStyle;
      // Restating the field's own default here would be the "flat
      // default equals child default" duplicate `core/style-contract.md`
      // forbids — the field's `sm` / `md` / `lg` rungs already read at
      // 14px body-medium at the role's own line height themselves
      // (`CoreTextFieldStyle.defaultsBySize`), so the slot states nothing
      // for it.
      expect(slot.baseTextStyle, isNull);
      final fieldBase = CoreTextFieldStyle
          .defaultsBySize[CoreComponentSize.md]!
          .baseTextStyle!;
      expect(fieldBase.token, CoreTextStyles.bodyMedium);
      // No line height laid over the role — the role's own 150% stands.
      expect(fieldBase.lineHeight, isNull);
      expect(fieldBase.lineHeightPx, isNull);
      expect(fieldBase.fontSize, isNull);
      expect(fieldBase.fontWeight, isNull);
      expect(slot.stateLayer, isNotNull);
      expect(slot.stateLayer!.hover, 0);
      expect(slot.stateLayer!.focus, 0);
      expect(slot.stateLayer!.pressed, CoreOpacity.pressed);
      // Everything else is the field's — the partial is silent on it.
      expect(
        slot.copyWith(stateLayer: CoreStateLayer.subtle),
        const CoreTextFieldStyle(stateLayer: CoreStateLayer.subtle),
      );
    });

    test('hover is a border step the field states, and error outranks it', () {
      final normal = CoreTextFieldStyle
          .defaultsByVariant[CoreTextFieldVariant.defaultVariant]!;
      final error =
          CoreTextFieldStyle.defaultsByVariant[CoreTextFieldVariant.error]!;
      expect(
        normal.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        normal.hoverBorderColor,
        const CoreColor.token(CoreColors.outline),
      );
      expect(error.hoverBorderColor, error.borderColor);
      expect(error.borderColor, const CoreColor.token(CoreColors.error));
    });

    test('the variant maps onto the field variant, and there is no plain', () {
      expect(
        CoreSelectVariant.defaultVariant.toTextFieldVariant(),
        CoreTextFieldVariant.defaultVariant,
      );
      expect(
        CoreSelectVariant.error.toTextFieldVariant(),
        CoreTextFieldVariant.error,
      );
      expect(
        CoreSelectVariant.filled.toTextFieldVariant(),
        CoreTextFieldVariant.filled,
      );
      expect(CoreSelectVariant.values, hasLength(3));
    });
  });

  group('the rows are menu rows', () {
    test('sm and lg open onto rows as tall as the trigger; the md option '
        'row is 36 under the 40 trigger', () {
      for (final size in CoreSelectSize.values) {
        final row = CoreMenuItemStyle.defaultsBySize[size.toMenuItemSize()]!;
        final field =
            CoreTextFieldStyle.defaultsBySize[size.toComponentSize()]!;
        if (size == CoreSelectSize.md) {
          expect(field.minHeight, CoreSize.size40);
          expect(row.minHeight, CoreSize.size36);
        } else {
          expect(row.minHeight, field.minHeight, reason: '$size');
        }
      }
    });

    test('the option slot states the hosted corner only — the row fills '
        'the rest', () {
      // An option is a row the panel hosts: 6 on every size (the panel
      // corner 12 minus the panel padding 6), not the standalone row
      // ladder. Nothing else diverges.
      expect(
        CoreSelectStyle.defaultOptionStyle,
        const CoreMenuItemStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
        ),
      );
    });

    test('the mark is neutral, not the accent', () {
      expect(
        CoreSelectStyle.defaultSelectedIconColor.token,
        CoreColors.onSurface,
      );
      expect(
        CoreSelectStyle.defaultSelectedIconColor.token,
        isNot(CoreColors.primary),
      );
    });

    test('effectiveOptionStyle tints the mark and hands the row slot '
        'down', () {
      const style = CoreSelectStyle();
      expect(
        style.effectiveOptionStyle.markIconStyle!.color!.token,
        CoreColors.onSurface,
      );

      const stated = CoreSelectStyle(
        optionStyle: CoreMenuItemStyle(padding: _kPadH16),
      );
      expect(stated.effectiveOptionStyle.padding, _kPadH16);
      // The tint survives a stated row slot that says nothing about it.
      expect(
        stated.effectiveOptionStyle.markIconStyle!.color!.token,
        CoreColors.onSurface,
      );
    });
  });

  group('the panel', () {
    test('the trigger fills the inline axis, like every field-trigger '
        'popover', () {
      expect(
        CoreSelectStyle.defaultPopoverStyle.triggerSizing,
        CorePopoverTriggerSizing.expand,
      );
      // The family states one convention — a Select that hugged while its
      // siblings filled would be a different width on each platform.
      for (final sibling in [
        CoreAutocompleteStyle.defaultPopoverStyle,
        CoreDatePickerStyle.defaultPopoverStyle,
        CoreTimePickerStyle.defaultPopoverStyle,
      ]) {
        expect(
          CoreSelectStyle.defaultPopoverStyle.triggerSizing,
          sibling.triggerSizing,
        );
      }
    });

    test(
      'a stated popoverStyle can hand the trigger back to its own width',
      () {
        const hugging = CoreSelectStyle(
          popoverStyle: CorePopoverStyle(triggerSizing: .intrinsic),
        );
        final resolved = CoreSelectStyle.defaultPopoverStyle.merge(
          hugging.popoverStyle,
        );
        expect(resolved.triggerSizing, CorePopoverTriggerSizing.intrinsic);
        // Only the sizing moved: the panel box is still the Select's own.
        expect(resolved.placementOffset, CoreSpace.space4);
      },
    );

    test('inset 6, corner 12, rows 2 apart, 4 below the trigger', () {
      final panel = CoreSelectStyle.defaultPopoverStyle.panelStyle!;
      expect(panel.padding, const CoreEdgeInsets.all(CoreSpace.space6));
      expect(
        panel.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius12),
      );
      expect(panel.spacing, CoreSpace.space2);
      expect(
        CoreSelectStyle.defaultPopoverStyle.placementOffset,
        CoreSpace.space4,
      );
    });

    test('the corner is the option corner plus the inset — concentric at '
        'every size', () {
      final panel = CoreSelectStyle.defaultPopoverStyle.panelStyle!;
      final row = CoreSelectStyle.defaultOptionStyle.borderRadius!.topLeft;
      expect(row, CoreRadius.radius6);
      expect(panel.borderRadius!.topLeft, row + panel.padding!.left);
    });

    test('rows are 2 apart, the menu rhythm', () {
      expect(CoreSelectStyle.defaultOptionSpacing, CoreSpace.space2);
      expect(
        CoreSelectStyle.defaultOptionSpacing,
        CoreMenuStyle.defaultPopupStyle.spacing,
      );
    });
  });

  group('the chevron', () {
    test('14 / 16 / 18 for sm / md / lg — the control icon ladder', () {
      const expected = {
        CoreSelectSize.sm: CoreIconSize.size14,
        CoreSelectSize.md: CoreIconSize.size16,
        CoreSelectSize.lg: CoreIconSize.size18,
      };
      for (final size in CoreSelectSize.values) {
        expect(
          CoreSelectStyle.defaultsBySize[size]!.trailingIconStyle!.size,
          expected[size],
          reason: '$size',
        );
      }
    });

    test('sits on the same size as the TextField suffix seat of its rung', () {
      // The chevron is Select's own glyph (so a caller restyling the
      // trigger's suffix icons does not move it), but its size is the one the
      // field's suffix seat steps through at the same rung.
      for (final size in CoreSelectSize.values) {
        expect(
          CoreSelectStyle.defaultsBySize[size]!.trailingIconStyle!.size,
          CoreTextFieldStyle
              .defaultsBySize[size.toComponentSize()]!
              .iconStyle!
              .size,
          reason: '$size',
        );
      }
    });

    test('every rung states the ladder', () {
      expect(CoreSelectStyle.defaultsBySize.keys, CoreSelectSize.values);
    });
  });

  group('merge / copyWith / ==', () {
    test('null other returns this', () {
      const a = CoreSelectStyle(optionSpacing: 4);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('right-most non-null wins; nested slots merge recursively', () {
      const base = CoreSelectStyle(
        optionsPanelMaxHeight: 200,
        optionStyle: CoreMenuItemStyle(padding: _kPadH8, minHeight: 40),
      );
      const over = CoreSelectStyle(
        optionStyle: CoreMenuItemStyle(padding: _kPadH16),
      );
      final merged = base.merge(over);
      expect(merged.optionsPanelMaxHeight, 200);
      expect(merged.optionStyle!.padding, _kPadH16);
      expect(merged.optionStyle!.minHeight, 40);
    });

    test('copyWith replaces only what is given; == compares every field', () {
      const a = CoreSelectStyle(optionSpacing: 2, optionsPanelMaxHeight: 300);
      final b = a.copyWith(optionSpacing: 4);
      expect(b.optionSpacing, 4);
      expect(b.optionsPanelMaxHeight, 300);
      expect(a == b, isFalse);
      expect(
        a,
        const CoreSelectStyle(optionSpacing: 2, optionsPanelMaxHeight: 300),
      );
    });
  });

  group('CoreSelectTheme', () {
    test('style and variantStyles both pass through', () {
      const theme = CoreSelectTheme(
        style: CoreSelectStyle(optionSpacing: 2),
        variantStyles: {
          CoreSelectVariant.error: CoreSelectStyle(optionSpacing: 4),
        },
      );
      expect(theme.style!.optionSpacing, 2);
      expect(theme.variantStyles![CoreSelectVariant.error]!.optionSpacing, 4);
    });

    test('equality compares the variant map', () {
      const a = CoreSelectTheme(
        variantStyles: {
          CoreSelectVariant.error: CoreSelectStyle(optionSpacing: 4),
        },
      );
      const b = CoreSelectTheme(
        variantStyles: {
          CoreSelectVariant.error: CoreSelectStyle(optionSpacing: 4),
        },
      );
      const c = CoreSelectTheme(
        variantStyles: {
          CoreSelectVariant.error: CoreSelectStyle(optionSpacing: 2),
        },
      );
      expect(a, b);
      expect(a == c, isFalse);
      expect(a.hashCode, b.hashCode);
    });
  });
}
