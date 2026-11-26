import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreToggleGroupStyle defaults', () {
    test('the track and the raised face are the designer tokens', () {
      expect(
        CoreToggleGroupStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainer),
      );
      expect(
        CoreToggleGroupStyle.defaultSelectedColor,
        const CoreColor.token(CoreColors.surfaceRaised),
      );
    });

    test('a group on a floating panel states its track one step higher', () {
      // The time and colour pickers put the group on `surfaceBright`, which
      // equals `surfaceContainer` in Dark — their slot defaults restate the
      // track and nothing else.
      const high = CoreColor.token(CoreColors.surfaceContainerHigh);
      for (final slot in [
        CoreTimePickerStyle.defaultAmPmToggleStyle,
        CoreColorPickerStyle.defaultModeTabsStyle,
      ]) {
        expect(slot, const CoreToggleGroupStyle(backgroundColor: high));
      }
    });

    test('the chosen face carries the smallest shadow step', () {
      expect(CoreToggleGroupStyle.defaultSelectedShadow, CoreShadow.xs);
    });

    test('the md inset is 4 on every side, the segment inset 2 across', () {
      expect(
        CoreToggleGroupStyle.defaultPadding,
        const CoreEdgeInsets.all(CoreSpace.space4),
      );
      expect(
        CoreToggleGroupStyle.defaultItemPadding,
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space2),
      );
    });

    test('the segment corner is the md track corner minus its inset', () {
      expect(
        CoreToggleGroupStyle.defaultItemBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius6),
      );
      expect(
        CoreToggleGroupStyle.defaultBorderRadius.topLeft -
            CoreToggleGroupStyle.defaultPadding.top,
        CoreToggleGroupStyle.defaultItemBorderRadius.topLeft,
      );
    });

    test('the disabled state names its own tokens', () {
      expect(
        CoreToggleGroupStyle.defaultDisabledBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CoreToggleGroupStyle.defaultDisabledSelectedColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      expect(
        CoreToggleGroupStyle.defaultDisabledLabelTextStyle.color,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(
        CoreToggleGroupStyle.defaultDisabledIconStyle.color,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('the hover layer is onSurface at the shared ramp’s hover weight', () {
      expect(
        CoreToggleGroupStyle.defaultStateLayerColor,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(CoreToggleGroupStyle.defaultStateLayer, CoreStateLayer.subtle);
    });

    test('the generic Clickable dimming is off', () {
      expect(CoreToggleGroupStyle.defaultClickableStyle.disabledOpacity, 1);
    });
  });

  group('CoreToggleGroupStyle merge / copyWith / equality', () {
    test('merge takes non-null fields from the other side', () {
      const base = CoreToggleGroupStyle(itemHeight: 32, itemSpacing: 2);
      final merged = base.merge(const CoreToggleGroupStyle(itemHeight: 40));
      expect(merged.itemHeight, 40);
      expect(merged.itemSpacing, 2);
    });

    test('nested slots merge recursively', () {
      const base = CoreToggleGroupStyle(
        iconStyle: CoreIconStyle(size: 16),
      );
      final merged = base.merge(
        const CoreToggleGroupStyle(
          iconStyle: CoreIconStyle(color: CoreColor(0xFF000000)),
        ),
      );
      expect(merged.iconStyle!.size, 16);
      expect(merged.iconStyle!.color, const CoreColor(0xFF000000));
    });

    test('the shadow list takes part in equality and merge', () {
      const a = CoreToggleGroupStyle(selectedShadow: CoreShadow.xs);
      const b = CoreToggleGroupStyle(selectedShadow: CoreShadow.sm);
      expect(a, isNot(b));
      expect(a, const CoreToggleGroupStyle(selectedShadow: CoreShadow.xs));
      expect(
        a.hashCode,
        const CoreToggleGroupStyle(selectedShadow: CoreShadow.xs).hashCode,
      );
      expect(a.merge(b).selectedShadow, CoreShadow.sm);
      expect(a.merge(null), same(a));
    });

    test('every field changes equality', () {
      const base = CoreToggleGroupStyle();
      final variants = <CoreToggleGroupStyle>[
        base.copyWith(backgroundColor: const CoreColor(1)),
        base.copyWith(selectedColor: const CoreColor(1)),
        base.copyWith(disabledBackgroundColor: const CoreColor(1)),
        base.copyWith(disabledSelectedColor: const CoreColor(1)),
        base.copyWith(selectedShadow: CoreShadow.sm),
        base.copyWith(borderRadius: const CoreBorderRadius.all(1)),
        base.copyWith(itemBorderRadius: const CoreBorderRadius.all(1)),
        base.copyWith(padding: const CoreEdgeInsets.all(1)),
        base.copyWith(itemPadding: const CoreEdgeInsets.all(1)),
        base.copyWith(labelPadding: const CoreEdgeInsets.all(1)),
        base.copyWith(itemHeight: 1),
        base.copyWith(itemSpacing: 1),
        base.copyWith(selectedFontWeight: 1),
        base.copyWith(transitionDuration: const Duration(seconds: 1)),
        base.copyWith(stateLayerColor: const CoreColor(1)),
        base.copyWith(stateLayer: CoreStateLayer.subtle),
        base.copyWith(labelTextStyle: const CoreTextStyle(fontSize: 1)),
        base.copyWith(selectedLabelTextStyle: const CoreTextStyle(fontSize: 1)),
        base.copyWith(disabledLabelTextStyle: const CoreTextStyle(fontSize: 1)),
        base.copyWith(iconStyle: const CoreIconStyle(size: 1)),
        base.copyWith(selectedIconStyle: const CoreIconStyle(size: 1)),
        base.copyWith(disabledIconStyle: const CoreIconStyle(size: 1)),
        base.copyWith(
          clickableStyle: const CoreClickableStyle(pressedScale: 1),
        ),
      ];
      for (final v in variants) {
        expect(v, isNot(base), reason: '$v');
      }
    });
  });

  group('CoreToggleGroupItem / Theme', () {
    test('items compare by value, label, icon and showLabel', () {
      const a = CoreToggleGroupItem<String, Object>(value: 'a', label: 'A');
      expect(
        a,
        const CoreToggleGroupItem<String, Object>(value: 'a', label: 'A'),
      );
      expect(
        a,
        isNot(
          const CoreToggleGroupItem<String, Object>(
            value: 'a',
            label: 'A',
            showLabel: false,
          ),
        ),
      );
    });

    test('theme equality follows its style', () {
      const t = CoreToggleGroupTheme(
        style: CoreToggleGroupStyle(itemHeight: 1),
      );
      expect(
        t,
        const CoreToggleGroupTheme(style: CoreToggleGroupStyle(itemHeight: 1)),
      );
      expect(t, isNot(const CoreToggleGroupTheme()));
    });

    test('the component theme carries and merges the slot', () {
      const theme = CoreComponentTheme(
        toggleGroup: CoreToggleGroupTheme(style: CoreToggleGroupStyle()),
      );
      expect(theme.toggleGroup, isNotNull);
      expect(theme.copyWith().toggleGroup, theme.toggleGroup);
    });
  });

  group('CoreToggleGroupStyle size rows', () {
    test('md is the 32 segment of the 40 track — the md control row', () {
      final row = CoreToggleGroupStyle.sizeDefaults(CoreComponentSize.md);
      expect(row.itemHeight, 32);
      expect(row.itemHeight, CoreToggleGroupStyle.defaultItemHeight);
      const inset = CoreToggleGroupStyle.defaultPadding;
      expect(
        inset.top + row.itemHeight! + inset.bottom,
        CoreControlSize.heightMd,
      );
    });

    test('sm is the 26 segment of the 32 track — the sm control row', () {
      final row = CoreToggleGroupStyle.sizeDefaults(CoreComponentSize.sm);
      expect(row.itemHeight, 26);
      expect(row.padding, const CoreEdgeInsets.all(3));
      expect(row.padding!.top + row.itemHeight! + row.padding!.bottom, 32);
      expect(
        row.padding!.top + row.itemHeight! + row.padding!.bottom,
        CoreControlSize.heightSm,
      );
      expect(row.borderRadius, const CoreBorderRadius.all(CoreRadius.radius8));
      expect(row.itemPadding, CoreEdgeInsets.zero);
      // The segment corner is not restated — both rows share it.
      expect(row.itemBorderRadius, isNull);
    });

    test('sm states the labelMedium role only — the state colour stays', () {
      final row = CoreToggleGroupStyle.sizeDefaults(CoreComponentSize.sm);
      for (final label in [
        row.labelTextStyle,
        row.selectedLabelTextStyle,
        row.disabledLabelTextStyle,
      ]) {
        expect(label, const CoreTextStyle.token(CoreTextStyles.labelMedium));
        expect(label!.color, isNull);
      }
      final unchosen = CoreToggleGroupStyle.defaultLabelTextStyle.merge(
        row.labelTextStyle,
      );
      expect(unchosen.token, CoreTextStyles.labelMedium);
      expect(unchosen.color, CoreToggleGroupStyle.defaultLabelTextStyle.color);
    });

    test('a size with no row of its own reads md', () {
      for (final size in [
        CoreComponentSize.xs,
        CoreComponentSize.lg,
        CoreComponentSize.xl,
      ]) {
        expect(CoreToggleGroupStyle.sizeDefaults(size).itemHeight, 32);
      }
    });

    test('two sm segments make the 60 px of a time picker tile', () {
      final row = CoreToggleGroupStyle.sizeDefaults(CoreComponentSize.sm);
      final inset = row.padding!.top;
      const gap = CoreToggleGroupStyle.defaultItemSpacing;
      final cell = row.itemHeight!;
      expect(inset + cell + gap + cell + inset, 60);
      expect(
        inset + cell + gap + cell + inset,
        CoreTimePickerStyle.defaultSegmentHeight,
      );
    });

    test('a floating panel uses sm, the group itself defaults to md', () {
      expect(CoreToggleGroupContract.defaultSize, CoreComponentSize.md);
      expect(
        CoreTimePickerContract.defaultAmPmToggleSize,
        CoreComponentSize.sm,
      );
      expect(CoreColorPickerContract.defaultModeTabsSize, CoreComponentSize.sm);
    });
  });
}
