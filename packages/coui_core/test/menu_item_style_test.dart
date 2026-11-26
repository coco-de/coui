// CoreMenuItemStyle — the row's own contract (Button · Menu 개편 §6-3),
// and the bridge the menu hands each row through.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kPadH8 = CoreEdgeInsets.symmetric(horizontal: 8);
const _kPadH16 = CoreEdgeInsets.symmetric(horizontal: 16);
const _kRadius4 = CoreBorderRadius.all(CoreRadius.radius4);

/// The four modes a colour slot is read in.
final List<(String, CoreColorScheme)> _kModes = [
  ('light', CouiColorPresets.source.light()),
  ('dark', CouiColorPresets.source.dark()),
  ('high-contrast light', CouiColorPresets.source.highContrastLight()),
  ('high-contrast dark', CouiColorPresets.source.highContrastDark()),
];

/// `color` as each mode paints it, so a slot assertion reads the pixel the
/// default produces and not only the token it names.
void _expectSameInEveryMode(CoreColor? actual, CoreColorToken expected) {
  for (final (mode, scheme) in _kModes) {
    expect(
      scheme.resolve(actual!).argb,
      scheme.resolve(CoreColor.token(expected)).argb,
      reason: mode,
    );
  }
}

void main() {
  group('size ladder', () {
    test('three rungs — 32 / 36 / 48', () {
      expect(
        CoreMenuItemStyle.defaultsBySize[CoreMenuItemSize.sm]!.minHeight,
        CoreControlSize.heightSm,
      );
      expect(
        CoreMenuItemStyle.defaultsBySize[CoreMenuItemSize.md]!.minHeight,
        CoreSize.size36,
      );
      expect(
        CoreMenuItemStyle.defaultsBySize[CoreMenuItemSize.lg]!.minHeight,
        CoreControlSize.heightLg,
      );
      expect(CoreMenuItemSize.defaultSize, CoreMenuItemSize.sm);
    });

    test('md is 10/8 insets, gap 10, leading 18, label labelLarge', () {
      final md = CoreMenuItemStyle.defaultsBySize[CoreMenuItemSize.md]!;
      expect(
        md.padding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space10,
          vertical: CoreSpace.space8,
        ),
      );
      expect(md.contentGapStyle!.size, CoreSpace.space10);
      expect(md.leadingIconStyle!.size, CoreIconSize.size18);
      expect(md.labelStyle!.token, CoreTextStyles.labelLarge);
    });

    test('insets · gap · leading icon per rung — 8/6 · 10/8 · 16/12', () {
      const rows = {
        CoreMenuItemSize.sm: (
          h: CoreSpace.space8,
          v: CoreSpace.space6,
          gap: CoreSpace.space8,
          icon: CoreIconSize.size16,
        ),
        CoreMenuItemSize.md: (
          h: CoreSpace.space10,
          v: CoreSpace.space8,
          gap: CoreSpace.space10,
          icon: CoreIconSize.size18,
        ),
        CoreMenuItemSize.lg: (
          h: CoreSpace.space16,
          v: CoreSpace.space12,
          gap: CoreSpace.space12,
          icon: CoreIconSize.size24,
        ),
      };
      for (final entry in rows.entries) {
        final row = CoreMenuItemStyle.defaultsBySize[entry.key]!;
        expect(
          row.padding,
          CoreEdgeInsets.symmetric(
            horizontal: entry.value.h,
            vertical: entry.value.v,
          ),
          reason: '${entry.key} insets',
        );
        expect(row.contentGapStyle!.size, entry.value.gap);
        expect(row.leadingIconStyle!.size, entry.value.icon);
      }
    });

    test('label and secondary text read roles — label · body · body', () {
      const roles = {
        CoreMenuItemSize.sm: (
          label: CoreTextStyles.labelLarge,
          description: CoreTextStyles.bodyXs,
          shortcut: CoreTextStyles.bodyXs,
        ),
        CoreMenuItemSize.md: (
          label: CoreTextStyles.labelLarge,
          description: CoreTextStyles.bodySmall,
          shortcut: CoreTextStyles.bodyXs,
        ),
        CoreMenuItemSize.lg: (
          label: CoreTextStyles.labelXl,
          description: CoreTextStyles.bodyMedium,
          shortcut: CoreTextStyles.bodySmall,
        ),
      };
      for (final entry in roles.entries) {
        final row = CoreMenuItemStyle.defaultsBySize[entry.key]!;
        expect(row.labelStyle!.token, entry.value.label);
        expect(row.descriptionStyle!.token, entry.value.description);
        expect(row.shortcutTextStyle!.token, entry.value.shortcut);
        // The role sets the size; no row overlays a bare font size.
        expect(row.descriptionStyle!.fontSize, isNull);
        expect(row.shortcutTextStyle!.fontSize, isNull);
      }
    });

    test('every rung states the same field set', () {
      for (final row in CoreMenuItemStyle.defaultsBySize.values) {
        expect(row.minHeight, isNotNull);
        expect(row.padding, isNotNull);
        expect(row.contentGapStyle, isNotNull);
        expect(row.leadingIconStyle, isNotNull);
        expect(row.labelStyle, isNotNull);
        expect(row.descriptionStyle, isNotNull);
        expect(row.shortcutTextStyle, isNotNull);
      }
      expect(
        CoreMenuItemStyle.defaultsBySize.keys,
        CoreMenuItemSize.values,
      );
    });

    test('rungs ascend', () {
      final heights = CoreMenuItemSize.values
          .map((s) => CoreMenuItemStyle.defaultsBySize[s]!.minHeight!)
          .toList();
      expect(heights, [32.0, 36.0, 48.0]);
    });

    test('maps onto the shared size rung a composed child takes', () {
      expect(CoreMenuItemSize.sm.toComponentSize(), CoreComponentSize.sm);
      expect(CoreMenuItemSize.md.toComponentSize(), CoreComponentSize.md);
      expect(CoreMenuItemSize.lg.toComponentSize(), CoreComponentSize.lg);
    });
  });

  group('tone', () {
    test('moves the foreground only', () {
      final neutral =
          CoreMenuItemStyle.defaultsByTone[CoreMenuItemTone.neutral]!;
      final critical =
          CoreMenuItemStyle.defaultsByTone[CoreMenuItemTone.critical]!;
      expect(neutral.foregroundColor!.token, CoreColors.onSurface);
      expect(critical.foregroundColor!.token, CoreColors.error);
      // No wash / fill of its own — the ramp stays one.
      expect(critical.stateLayer, isNull);
      expect(critical.backgroundColor, isNull);
      expect(critical.selectedBackgroundColor, isNull);
      expect(CoreMenuItemTone.defaultTone, CoreMenuItemTone.neutral);
    });
  });

  group('axis-free defaults', () {
    test('mark and chevron are a 16 optical band', () {
      expect(CoreMenuItemStyle.defaultMarkIconStyle.size, CoreIconSize.size16);
      expect(
        CoreMenuItemStyle.defaultChevronIconStyle.size,
        CoreIconSize.size16,
      );
    });

    test('a standalone row corner is 8 · 8 · 12', () {
      expect(
        [
          for (final size in CoreMenuItemSize.values)
            CoreMenuItemStyle.defaultsBySize[size]!.borderRadius,
        ],
        const [
          CoreBorderRadius.all(CoreRadius.radius8),
          CoreBorderRadius.all(CoreRadius.radius8),
          CoreBorderRadius.all(CoreRadius.radius12),
        ],
      );
    });

    test('the wash is 8 / 8 / 12 — pressed is the light-surface weight', () {
      const wash = CoreMenuItemStyle.defaultStateLayer;
      expect(wash.hover, CoreOpacity.opacity8);
      expect(wash.focus, CoreOpacity.opacity8);
      expect(wash.pressed, CoreOpacity.pressed);
      expect(wash.pressed, CoreOpacity.opacity12);
      // The shared ramp is untouched: Checkbox, Radio and Toggle read it.
      expect(CoreStateLayer.standard.pressed, CoreOpacity.opacity16);
      expect(wash, isNot(CoreStateLayer.standard));
    });

    test('selected is primary / onPrimary, disabled is disabledContent', () {
      expect(
        CoreMenuItemStyle.defaultSelectedBackgroundColor.token,
        CoreColors.primary,
      );
      expect(
        CoreMenuItemStyle.defaultSelectedForegroundColor.token,
        CoreColors.onPrimary,
      );
      expect(
        CoreMenuItemStyle.defaultDisabledForegroundColor.token,
        CoreColors.disabledContent,
      );
      expect(
        CoreMenuItemStyle.defaultBackgroundColor,
        CoreColor.transparent,
      );
    });
  });

  group('colours as each mode paints them', () {
    test('the disabled foreground is the disabledContent slot', () {
      _expectSameInEveryMode(
        CoreMenuItemStyle.defaultDisabledForegroundColor,
        CoreColors.disabledContent,
      );
      for (final (mode, scheme) in _kModes) {
        expect(
          scheme.resolve(CoreMenuItemStyle.defaultDisabledForegroundColor).argb,
          isNot(
            scheme.resolve(const CoreColor.token(CoreColors.onSurface)).argb,
          ),
          reason: mode,
        );
      }
    });

    test(
      'the group title is onSurfaceSubtle at the labelSmall role (Medium)',
      () {
        const title = CoreMenuStyle.defaultLabelTextStyle;
        expect(title.token, CoreTextStyles.labelSmall);
        // The role states the weight; the slot writes none over it.
        expect(title.fontWeight, isNull);
        _expectSameInEveryMode(title.color, CoreColors.onSurfaceSubtle);
      },
    );
  });

  group('critical tone states a fill for its active state', () {
    const critical = CoreMenuItemTone.critical;
    const neutral = CoreMenuItemTone.neutral;
    final row = CoreMenuItemStyle.defaultsByTone[critical]!;

    test('hover, focus and press fill with errorContainer', () {
      expect(row.hoverBackgroundColor!.token, CoreColors.errorContainer);
      expect(row.pressedBackgroundColor!.token, CoreColors.errorContainer);
      // The inks do not change with the fill (designer decision 2026-11-05,
      // #6012): no active ink is stated, so every seat keeps its resting
      // colour and the label stays `error`.
      expect(row.activeForegroundColor, isNull);
      expect(row.foregroundColor!.token, CoreColors.error);
    });

    test('the neutral tone states none — it is washed', () {
      final neutralRow = CoreMenuItemStyle.defaultsByTone[neutral]!;
      expect(neutralRow.hoverBackgroundColor, isNull);
      expect(neutralRow.pressedBackgroundColor, isNull);
      expect(neutralRow.activeForegroundColor, isNull);
    });

    test(
      'the resting ink on the fill, as each mode paints it, is readable',
      () {
        for (final (mode, scheme) in _kModes) {
          final ratio = CoreContrast.ratio(
            scheme.resolve(row.foregroundColor!),
            scheme.resolve(row.hoverBackgroundColor!),
          );
          // `error` on the light `errorContainer` is the lowest pair (4.55).
          expect(ratio, greaterThanOrEqualTo(4.5), reason: mode);
        }
      },
    );

    test('the fill differs from the resting fill in every mode', () {
      for (final (mode, scheme) in _kModes) {
        expect(
          scheme.resolve(row.hoverBackgroundColor!).argb,
          isNot(scheme.resolve(CoreMenuItemStyle.defaultBackgroundColor).argb),
          reason: mode,
        );
      }
    });

    test('the three fields take part in merge, copyWith, == and hashCode', () {
      const a = CoreMenuItemStyle(
        hoverBackgroundColor: CoreColor.token(CoreColors.errorContainer),
        pressedBackgroundColor: CoreColor.token(CoreColors.errorContainer),
        activeForegroundColor: CoreColor.token(CoreColors.onErrorContainer),
      );
      const patch = CoreMenuItemStyle(
        hoverBackgroundColor: CoreColor.token(CoreColors.surface),
      );
      final merged = a.merge(patch);
      expect(merged.hoverBackgroundColor!.token, CoreColors.surface);
      expect(merged.pressedBackgroundColor!.token, CoreColors.errorContainer);
      expect(merged.activeForegroundColor!.token, CoreColors.onErrorContainer);

      final copy = a.copyWith(
        activeForegroundColor: const CoreColor.token(CoreColors.onSurface),
      );
      expect(copy.activeForegroundColor!.token, CoreColors.onSurface);
      expect(copy.hoverBackgroundColor, a.hoverBackgroundColor);
      expect(a == copy, isFalse);
      expect(a.hashCode, isNot(copy.hashCode));

      for (final other in [
        a.copyWith(
          hoverBackgroundColor: const CoreColor.token(CoreColors.surface),
        ),
        a.copyWith(
          pressedBackgroundColor: const CoreColor.token(CoreColors.surface),
        ),
      ]) {
        expect(a == other, isFalse);
        expect(a.hashCode, isNot(other.hashCode));
      }
    });
  });

  group('merge / copyWith / ==', () {
    test('null other returns this', () {
      const a = CoreMenuItemStyle(padding: _kPadH8);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('right-most non-null wins; nested slots merge recursively', () {
      const base = CoreMenuItemStyle(
        padding: _kPadH8,
        borderRadius: _kRadius4,
        leadingIconStyle: CoreIconStyle(size: 20),
      );
      const over = CoreMenuItemStyle(
        padding: _kPadH16,
        leadingIconStyle: CoreIconStyle(
          color: CoreColor.token(CoreColors.error),
        ),
      );
      final merged = base.merge(over);
      expect(merged.padding, _kPadH16);
      expect(merged.borderRadius, _kRadius4);
      // The colour-only override keeps the base size.
      expect(merged.leadingIconStyle!.size, 20);
      expect(merged.leadingIconStyle!.color!.token, CoreColors.error);
    });

    test('copyWith replaces only what is given; == compares every field', () {
      const a = CoreMenuItemStyle(minHeight: 40, padding: _kPadH8);
      final b = a.copyWith(minHeight: 48);
      expect(b.minHeight, 48);
      expect(b.padding, _kPadH8);
      expect(a, const CoreMenuItemStyle(minHeight: 40, padding: _kPadH8));
      expect(a == b, isFalse);
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  group('CoreMenuStyle bridges', () {
    test('effectiveItemStyle hands the row slot down over its default', () {
      // Nothing stated → the empty partial (the row resolver fills it).
      expect(
        const CoreMenuStyle().effectiveItemStyle,
        CoreMenuStyle.defaultItemStyle,
      );

      const stated = CoreMenuStyle(
        itemStyle: CoreMenuItemStyle(padding: _kPadH16),
      );
      expect(stated.effectiveItemStyle.padding, _kPadH16);
    });

    test('itemStyle merges recursively through CoreMenuStyle.merge', () {
      const base = CoreMenuStyle(
        itemStyle: CoreMenuItemStyle(padding: _kPadH8, minHeight: 40),
      );
      const over = CoreMenuStyle(
        itemStyle: CoreMenuItemStyle(padding: _kPadH16),
      );
      final merged = base.merge(over);
      expect(merged.itemStyle!.padding, _kPadH16);
      expect(merged.itemStyle!.minHeight, 40);
    });

    test('the panel is content-driven between layout/240 and layout/280', () {
      expect(CoreMenuStyle.defaultPopupStyle.minWidth, CoreLayout.layout240);
      expect(CoreMenuStyle.defaultPopupStyle.maxWidth, CoreLayout.layout280);
      expect(CoreLayout.layout280, 280.0);
      // The inline submenu draws no box and states no ceiling.
      expect(CoreMenuStyle.defaultSubmenuPopupStyle.maxWidth, double.infinity);
    });
  });

  group('CorePopupStyle.maxWidth', () {
    test('unbounded by default, merges like any scalar', () {
      expect(CorePopupStyle.defaultMaxWidth, double.infinity);
      const a = CorePopupStyle(maxWidth: 280);
      expect(a.merge(const CorePopupStyle()).maxWidth, 280);
      expect(a.merge(const CorePopupStyle(maxWidth: 320)).maxWidth, 320);
      expect(a.copyWith(maxWidth: 400).maxWidth, 400);
      expect(a == const CorePopupStyle(maxWidth: 280), isTrue);
      expect(a == const CorePopupStyle(maxWidth: 320), isFalse);
    });
  });

  group('CoreMenuItem data', () {
    test('carries description and tone on interactive entries', () {
      const a = CoreMenuItem<Object>.action(
        'Delete',
        description: 'Cannot be undone',
        tone: CoreMenuItemTone.critical,
      );
      expect(a.description, 'Cannot be undone');
      expect(a.tone, CoreMenuItemTone.critical);
      const c = CoreMenuItem<Object>.checkbox('Show grid');
      expect(c.tone, CoreMenuItemTone.neutral);
      expect(c.description, isNull);
      const d = CoreMenuItem<Object>.divider();
      expect(d.tone, CoreMenuItemTone.neutral);
    });
  });
}
