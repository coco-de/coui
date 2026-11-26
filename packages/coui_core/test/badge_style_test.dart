// Tests for the Badge contract set — `CoreBadgeTone` / `CoreBadgeVariant` /
// `CoreBadgeForm` / `CoreBadgeContract` defaults, `CoreBadgeStyle` and its
// three tables, `CoreBadgeToneStyle`, and `CoreBadgeTheme`.
//
// The expected tables below are written out by hand from the design spec
// (display §1-2 colours, §1-3 sizes) rather than read back from the
// constants, so a value moved in the source has to be moved here too —
// the pin is the decision, not a copy of whatever the code holds today.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kFontLabel = 14;
const double _kFontTitle = 18;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightRegular = CoreFontWeight.regular;
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorTokenSurface = CoreColor.token(CoreColors.surface);
const _kColorTokenPrimary = CoreColor.token(CoreColors.primary);
const _kPaddingSmall = CoreEdgeInsets.all(8);
const _kPaddingMedium = CoreEdgeInsets.symmetric(horizontal: 12, vertical: 4);
const _kPaddingLarge = CoreEdgeInsets.symmetric(horizontal: 12, vertical: 6);
const double _kIconSize = 16;

/// One step of the size table (display §1-3), as the spec states it.
typedef _SizeRow = ({
  double height,
  CoreTextStyleToken role,
  double roleFontSize,
  double horizontalPadding,
  double gap,
  double labelRadius,
  double icon,
  double dot,
  double leadingDot,
});

const Map<CoreComponentSize, _SizeRow> _kSizeTable = {
  CoreComponentSize.xs: (
    height: 18,
    role: CoreTextStyles.labelXs,
    roleFontSize: 11,
    horizontalPadding: 6,
    gap: 4,
    labelRadius: 4,
    icon: 10,
    dot: 4,
    leadingDot: 4,
  ),
  CoreComponentSize.sm: (
    height: 20,
    role: CoreTextStyles.labelXs,
    roleFontSize: 11,
    horizontalPadding: 6,
    gap: 4,
    labelRadius: 4,
    icon: 12,
    dot: 6,
    leadingDot: 4,
  ),
  CoreComponentSize.md: (
    height: 24,
    role: CoreTextStyles.labelSmall,
    roleFontSize: 12,
    horizontalPadding: 8,
    gap: 4,
    labelRadius: 6,
    icon: 14,
    dot: 8,
    leadingDot: 6,
  ),
  CoreComponentSize.lg: (
    height: 28,
    role: CoreTextStyles.labelMedium,
    roleFontSize: 13,
    horizontalPadding: 10,
    gap: 4,
    labelRadius: 6,
    icon: 16,
    dot: 12,
    leadingDot: 6,
  ),
  CoreComponentSize.xl: (
    height: 32,
    role: CoreTextStyles.labelLarge,
    roleFontSize: 14,
    horizontalPadding: 12,
    gap: 6,
    labelRadius: 8,
    icon: 16,
    dot: 16,
    leadingDot: 6,
  ),
  CoreComponentSize.xl2: (
    height: 36,
    role: CoreTextStyles.labelXl,
    roleFontSize: 15,
    horizontalPadding: 12,
    gap: 6,
    labelRadius: 8,
    icon: 18,
    dot: 16,
    leadingDot: 8,
  ),
};

/// The colour table (display §1-2): per tone, filled fill / text, tonal
/// fill / text, outlined line / text, and the dot.
const Map<CoreBadgeTone, CoreBadgeToneStyle> _kToneTable = {
  CoreBadgeTone.neutral: CoreBadgeToneStyle(
    filledBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHighest),
    filledForegroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
    tonalBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
    tonalForegroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
    outlinedBorderColor: CoreColor.token(CoreColors.outline),
    outlinedForegroundColor: CoreColor.token(CoreColors.onSurface),
    dotColor: CoreColor.token(CoreColors.outline),
  ),
  CoreBadgeTone.primary: CoreBadgeToneStyle(
    filledBackgroundColor: CoreColor.token(CoreColors.primary),
    filledForegroundColor: CoreColor.token(CoreColors.onPrimary),
    tonalBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
    tonalForegroundColor: CoreColor.token(CoreColors.onPrimaryContainer),
    outlinedBorderColor: CoreColor.token(CoreColors.primary),
    outlinedForegroundColor: CoreColor.token(CoreColors.primaryText),
    dotColor: CoreColor.token(CoreColors.primary),
  ),
  CoreBadgeTone.info: CoreBadgeToneStyle(
    filledBackgroundColor: CoreColor.token(CoreColors.info),
    filledForegroundColor: CoreColor.token(CoreColors.onInfo),
    tonalBackgroundColor: CoreColor.token(CoreColors.infoContainer),
    tonalForegroundColor: CoreColor.token(CoreColors.onInfoContainer),
    outlinedBorderColor: CoreColor.token(CoreColors.info),
    outlinedForegroundColor: CoreColor.token(CoreColors.onInfoContainer),
    outlinedMarkColor: CoreColor.token(CoreColors.info),
    dotColor: CoreColor.token(CoreColors.info),
  ),
  CoreBadgeTone.success: CoreBadgeToneStyle(
    filledBackgroundColor: CoreColor.token(CoreColors.success),
    filledForegroundColor: CoreColor.token(CoreColors.onSuccess),
    tonalBackgroundColor: CoreColor.token(CoreColors.successContainer),
    tonalForegroundColor: CoreColor.token(CoreColors.onSuccessContainer),
    outlinedBorderColor: CoreColor.token(CoreColors.success),
    outlinedForegroundColor: CoreColor.token(CoreColors.onSuccessContainer),
    outlinedMarkColor: CoreColor.token(CoreColors.success),
    dotColor: CoreColor.token(CoreColors.success),
  ),
  CoreBadgeTone.warning: CoreBadgeToneStyle(
    filledBackgroundColor: CoreColor.token(CoreColors.warning),
    filledForegroundColor: CoreColor.token(CoreColors.onWarning),
    tonalBackgroundColor: CoreColor.token(CoreColors.warningContainer),
    tonalForegroundColor: CoreColor.token(CoreColors.onWarningContainer),
    outlinedBorderColor: CoreColor.token(CoreColors.warning),
    outlinedForegroundColor: CoreColor.token(CoreColors.onWarningContainer),
    outlinedMarkColor: CoreColor.token(CoreColors.warning),
    dotColor: CoreColor.token(CoreColors.warning),
  ),
  CoreBadgeTone.destructive: CoreBadgeToneStyle(
    filledBackgroundColor: CoreColor.token(CoreColors.error),
    filledForegroundColor: CoreColor.token(CoreColors.onError),
    tonalBackgroundColor: CoreColor.token(CoreColors.errorContainer),
    tonalForegroundColor: CoreColor.token(CoreColors.onErrorContainer),
    outlinedBorderColor: CoreColor.token(CoreColors.error),
    outlinedForegroundColor: CoreColor.token(CoreColors.onErrorContainer),
    outlinedMarkColor: CoreColor.token(CoreColors.error),
    dotColor: CoreColor.token(CoreColors.error),
  ),
};

/// A style with every field set, so a field left out of `merge` /
/// `copyWith` / `==` / `hashCode` shows up as a difference.
const CoreBadgeStyle _kFull = CoreBadgeStyle(
  backgroundColor: CoreColor.token(CoreColors.primary),
  foregroundColor: CoreColor.token(CoreColors.onPrimary),
  borderColor: CoreColor.token(CoreColors.outline),
  borderWidth: 1,
  borderRadius: CoreBorderRadius.all(4),
  padding: CoreEdgeInsets.symmetric(horizontal: 8),
  minHeight: 24,
  iconLabelGapStyle: CoreGapStyle(size: 4),
  transitionDuration: Duration(milliseconds: 150),
  labelStyle: CoreTextStyle(fontWeight: 600),
  iconStyle: CoreIconStyle(size: 14),
  focusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 2),
  dotSize: 8,
  leadingDotSize: 6,
  stateLayer: CoreStateLayer.standard,
);

/// For every field: [_kFull] with that one field set to a different value.
/// The record names the field so a failure says which one leaked.
final List<(String, CoreBadgeStyle)> _kOneFieldChanged = [
  (
    'backgroundColor',
    _kFull.copyWith(backgroundColor: const CoreColor.token(CoreColors.info)),
  ),
  (
    'foregroundColor',
    _kFull.copyWith(foregroundColor: const CoreColor.token(CoreColors.onInfo)),
  ),
  (
    'borderColor',
    _kFull.copyWith(borderColor: const CoreColor.token(CoreColors.error)),
  ),
  ('borderWidth', _kFull.copyWith(borderWidth: 2)),
  (
    'borderRadius',
    _kFull.copyWith(borderRadius: const CoreBorderRadius.all(8)),
  ),
  (
    'padding',
    _kFull.copyWith(padding: const CoreEdgeInsets.symmetric(horizontal: 12)),
  ),
  ('minHeight', _kFull.copyWith(minHeight: 32)),
  (
    'iconLabelGapStyle',
    _kFull.copyWith(iconLabelGapStyle: const CoreGapStyle(size: 6)),
  ),
  (
    'transitionDuration',
    _kFull.copyWith(transitionDuration: const Duration(milliseconds: 200)),
  ),
  (
    'labelStyle',
    _kFull.copyWith(labelStyle: const CoreTextStyle(fontWeight: 700)),
  ),
  ('iconStyle', _kFull.copyWith(iconStyle: const CoreIconStyle(size: 16))),
  (
    'focusOutlineStyle',
    _kFull.copyWith(
      focusOutlineStyle: const CoreFocusOutlineStyle(borderWidth: 3),
    ),
  ),
  ('dotSize', _kFull.copyWith(dotSize: 12)),
  ('leadingDotSize', _kFull.copyWith(leadingDotSize: 8)),
  ('stateLayer', _kFull.copyWith(stateLayer: CoreStateLayer.strong)),
];

/// The three tables merged in the order both resolvers merge them: the
/// step's row, the form's row over it, the tone's resting colours for the
/// variant on top.
///
/// A copy of the merge order, not a call into either resolver — what it
/// pins is how the tables compose. What a resolver actually draws is read
/// back by each platform's own resolver tests.
CoreBadgeStyle _base({
  required CoreComponentSize size,
  required CoreBadgeForm form,
  required CoreBadgeTone tone,
  required CoreBadgeVariant variant,
}) {
  return CoreBadgeStyle.defaultsBySize[size]!
      .merge(CoreBadgeStyle.defaultsByForm[form])
      .merge(
        CoreBadgeStyle.defaultsByTone[tone]!.restingStyleFor(variant, form),
      );
}

void main() {
  group('the three design axes', () {
    test('CoreBadgeTone — six meanings, neutral by default', () {
      expect(CoreBadgeTone.values, [
        CoreBadgeTone.neutral,
        CoreBadgeTone.primary,
        CoreBadgeTone.info,
        CoreBadgeTone.success,
        CoreBadgeTone.warning,
        CoreBadgeTone.destructive,
      ]);
      expect(CoreBadgeTone.defaultTone, CoreBadgeTone.neutral);
    });

    test('CoreBadgeVariant — three strengths and nothing else, tonal by '
        'default', () {
      // The old colour-and-strength values (primary / secondary / outline /
      // destructive) are gone: this list is the whole enum.
      expect(CoreBadgeVariant.values, [
        CoreBadgeVariant.filled,
        CoreBadgeVariant.tonal,
        CoreBadgeVariant.outlined,
      ]);
      expect(CoreBadgeVariant.defaultVariant, CoreBadgeVariant.tonal);
    });

    test('CoreBadgeForm — a word, a number or nothing, label by default', () {
      expect(CoreBadgeForm.values, [
        CoreBadgeForm.label,
        CoreBadgeForm.count,
        CoreBadgeForm.dot,
      ]);
      expect(CoreBadgeForm.defaultForm, CoreBadgeForm.label);
    });

    test('CoreBadgeContract defaults — md, no leading dot', () {
      expect(CoreBadgeContract.defaultSize, CoreComponentSize.md);
      expect(CoreBadgeContract.defaultShowDot, isFalse);
    });
  });

  group('CoreBadgeStyle scalar defaults', () {
    test('the pill corner is the full radius', () {
      expect(
        CoreBadgeStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    test('the line is one stroke', () {
      expect(CoreBadgeStyle.defaultBorderWidth, CoreStrokeWidth.stroke1);
    });

    test('the outlined fill paints nothing', () {
      expect(
        CoreBadgeStyle.defaultOutlinedBackgroundColor,
        const CoreColor.token(
          CoreColors.surface,
          opacity: CoreOpacity.opacity0,
        ),
      );
      expect(CoreBadgeStyle.defaultOutlinedBackgroundColor.opacity, 0);
    });

    test('the state layer is the standard 8 / 8 / 16', () {
      expect(CoreBadgeStyle.defaultStateLayer, CoreStateLayer.standard);
      expect(CoreBadgeStyle.defaultStateLayer.hover, 0.08);
      expect(CoreBadgeStyle.defaultStateLayer.pressed, 0.16);
    });

    test('the transition is the fast duration', () {
      expect(
        CoreBadgeStyle.defaultTransitionDuration,
        const Duration(milliseconds: CoreDuration.fast),
      );
    });
  });

  group('CoreBadgeStyle.defaultsBySize — the size table', () {
    for (final entry in _kSizeTable.entries) {
      final size = entry.key;
      final spec = entry.value;
      test('${size.name} — ${spec.height} tall, ${spec.role.name}', () {
        final row = CoreBadgeStyle.defaultsBySize[size]!;

        expect(row.minHeight, spec.height);
        expect(
          row.padding,
          CoreEdgeInsets.symmetric(horizontal: spec.horizontalPadding),
        );
        expect(row.iconLabelGapStyle, CoreGapStyle(size: spec.gap));
        expect(row.borderRadius, CoreBorderRadius.all(spec.labelRadius));
        expect(row.labelStyle, CoreTextStyle.token(spec.role));
        expect(row.iconStyle, CoreIconStyle(size: spec.icon));
        expect(row.dotSize, spec.dot);
        expect(row.leadingDotSize, spec.leadingDot);
      });
    }

    test('states no vertical padding — the height is the step', () {
      for (final entry in CoreBadgeStyle.defaultsBySize.entries) {
        final padding = entry.value.padding!;
        expect(padding.top, 0, reason: entry.key.name);
        expect(padding.bottom, 0, reason: entry.key.name);
      }
    });

    test('the label corner is a quarter of the height, taken down to the '
        'radius ladder', () {
      for (final entry in CoreBadgeStyle.defaultsBySize.entries) {
        final quarter = entry.value.minHeight! / 4;
        final onLadder = CoreRadius.steps.lastWhere((s) => s <= quarter);
        expect(
          entry.value.borderRadius,
          CoreBorderRadius.all(onLadder),
          reason: '${entry.key.name}: ${entry.value.minHeight} / 4 = $quarter',
        );
      }
    });

    test("states the role and no weight — the weight is the form's", () {
      for (final entry in CoreBadgeStyle.defaultsBySize.entries) {
        expect(entry.value.labelStyle!.fontWeight, isNull, reason: '$entry');
        expect(entry.value.labelStyle!.fontSize, isNull, reason: '$entry');
      }
    });

    test("states no colours — those are the tone's", () {
      for (final entry in CoreBadgeStyle.defaultsBySize.entries) {
        final row = entry.value;
        expect(row.backgroundColor, isNull, reason: entry.key.name);
        expect(row.foregroundColor, isNull, reason: entry.key.name);
        expect(row.borderColor, isNull, reason: entry.key.name);
      }
    });
  });

  group('CoreBadgeStyle.defaultsByForm', () {
    test('covers every form', () {
      expect(
        CoreBadgeStyle.defaultsByForm.keys,
        unorderedEquals(CoreBadgeForm.values),
      );
    });

    test("label — the role's weight, the step's corner", () {
      expect(
        CoreBadgeStyle.defaultsByForm[CoreBadgeForm.label],
        const CoreBadgeStyle(),
      );
    });

    test('count — the figure at 600, the pill', () {
      expect(
        CoreBadgeStyle.defaultsByForm[CoreBadgeForm.count],
        const CoreBadgeStyle(
          labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
          borderRadius: CoreBadgeStyle.defaultBorderRadius,
        ),
      );
    });

    test('dot — the pill, nothing else', () {
      expect(
        CoreBadgeStyle.defaultsByForm[CoreBadgeForm.dot],
        const CoreBadgeStyle(borderRadius: CoreBadgeStyle.defaultBorderRadius),
      );
    });
  });

  group(
    'the label a step draws — role from the size, weight from the form',
    () {
      final weights = {
        CoreBadgeForm.label: CoreFontWeight.medium,
        CoreBadgeForm.count: CoreFontWeight.semiBold,
      };
      for (final sizeEntry in _kSizeTable.entries) {
        for (final formEntry in weights.entries) {
          final size = sizeEntry.key;
          final form = formEntry.key;
          test('${size.name} ${form.name} — '
              '${sizeEntry.value.roleFontSize} / ${formEntry.value}', () {
            final merged = CoreBadgeStyle.defaultsBySize[size]!.labelStyle!
                .merge(
                  CoreBadgeStyle.defaultsByForm[form]!.labelStyle,
                );

            // The token survives the weight overlay, so the role's tracking
            // and line height still come with it.
            expect(merged.token, sizeEntry.value.role);
            expect(
              merged.fontWeight ??
                  CoreTypography.coui.resolve(merged).fontWeight,
              formEntry.value,
            );
            expect(
              CoreTypography.coui.resolve(merged).fontSize,
              sizeEntry.value.roleFontSize,
            );
          });
        }
      }
    },
  );

  group('CoreBadgeStyle.defaultsByTone — the colour table', () {
    test('has one row per tone', () {
      expect(
        CoreBadgeStyle.defaultsByTone.keys,
        unorderedEquals(CoreBadgeTone.values),
      );
    });

    for (final entry in _kToneTable.entries) {
      test("${entry.key.name} reads the spec's slots", () {
        expect(CoreBadgeStyle.defaultsByTone[entry.key], entry.value);
      });
    }
  });

  group('CoreBadgeToneStyle.restingStyleFor', () {
    for (final toneEntry in CoreBadgeStyle.defaultsByTone.entries) {
      final tone = toneEntry.key;
      final row = toneEntry.value;

      for (final variant in CoreBadgeVariant.values) {
        for (final form in CoreBadgeForm.values) {
          test('${tone.name} × ${variant.name} × ${form.name}', () {
            final expected = switch ((form, variant)) {
              (CoreBadgeForm.dot, _) => CoreBadgeStyle(
                backgroundColor: row.dotColor,
              ),
              (_, CoreBadgeVariant.filled) => CoreBadgeStyle(
                backgroundColor: row.filledBackgroundColor,
                foregroundColor: row.filledForegroundColor,
              ),
              (_, CoreBadgeVariant.tonal) => CoreBadgeStyle(
                backgroundColor: row.tonalBackgroundColor,
                foregroundColor: row.tonalForegroundColor,
              ),
              (_, CoreBadgeVariant.outlined) => CoreBadgeStyle(
                backgroundColor: CoreBadgeStyle.defaultOutlinedBackgroundColor,
                foregroundColor: row.outlinedForegroundColor,
                borderColor: row.outlinedBorderColor,
                iconStyle: row.outlinedMarkColor == null
                    ? null
                    : CoreIconStyle(color: row.outlinedMarkColor),
                leadingDotColor: row.outlinedMarkColor,
              ),
            };

            // Whole-style equality: the resting style states colours and
            // nothing else, so a dimension leaking in here fails too.
            expect(row.restingStyleFor(variant, form), expected);
          });
        }
      }

      test('${tone.name} — a dot is the same whatever the variant', () {
        final dots = {
          for (final variant in CoreBadgeVariant.values)
            row.restingStyleFor(variant, CoreBadgeForm.dot),
        };
        expect(dots, hasLength(1));
      });

      test('${tone.name} — a word and a number wear the same colours', () {
        for (final variant in CoreBadgeVariant.values) {
          expect(
            row.restingStyleFor(variant, CoreBadgeForm.count),
            row.restingStyleFor(variant, CoreBadgeForm.label),
            reason: variant.name,
          );
        }
      });

      test('${tone.name} — only outlined states a border', () {
        for (final variant in CoreBadgeVariant.values) {
          for (final form in CoreBadgeForm.values) {
            expect(
              row.restingStyleFor(variant, form).borderColor != null,
              variant == CoreBadgeVariant.outlined && form != CoreBadgeForm.dot,
              reason: '${variant.name} × ${form.name}',
            );
          }
        }
      });
    }
  });

  group('the three tables merge size, then form, then tone', () {
    test("the default badge is a 24px neutral tonal label at the role's "
        'weight', () {
      final base = _base(
        size: CoreBadgeContract.defaultSize,
        form: CoreBadgeForm.defaultForm,
        tone: CoreBadgeTone.defaultTone,
        variant: CoreBadgeVariant.defaultVariant,
      );

      expect(base.minHeight, 24);
      expect(base.borderRadius, const CoreBorderRadius.all(CoreRadius.radius6));
      expect(
        base.labelStyle,
        const CoreTextStyle.token(CoreTextStyles.labelSmall),
      );
      expect(
        base.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      expect(
        base.foregroundColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(base.borderColor, isNull);
    });

    test("a count takes the pill over the step's corner", () {
      for (final size in _kSizeTable.keys) {
        final base = _base(
          size: size,
          form: CoreBadgeForm.count,
          tone: CoreBadgeTone.info,
          variant: CoreBadgeVariant.filled,
        );
        expect(
          base.borderRadius,
          CoreBadgeStyle.defaultBorderRadius,
          reason: size.name,
        );
        expect(base.labelStyle!.fontWeight, CoreFontWeight.semiBold);
        expect(base.backgroundColor, const CoreColor.token(CoreColors.info));
      }
    });

    test("a dot is the pill in its tone's dot colour", () {
      final base = _base(
        size: CoreComponentSize.xs,
        form: CoreBadgeForm.dot,
        tone: CoreBadgeTone.neutral,
        variant: CoreBadgeVariant.outlined,
      );
      expect(base.dotSize, 4);
      expect(base.borderRadius, CoreBadgeStyle.defaultBorderRadius);
      expect(base.backgroundColor, const CoreColor.token(CoreColors.outline));
      expect(base.borderColor, isNull);
    });

    test('an outlined label is a line round a transparent fill', () {
      final base = _base(
        size: CoreComponentSize.md,
        form: CoreBadgeForm.label,
        tone: CoreBadgeTone.destructive,
        variant: CoreBadgeVariant.outlined,
      );
      expect(
        base.backgroundColor,
        CoreBadgeStyle.defaultOutlinedBackgroundColor,
      );
      expect(base.borderColor, const CoreColor.token(CoreColors.error));
      expect(
        base.foregroundColor,
        const CoreColor.token(CoreColors.onErrorContainer),
      );
    });
  });

  group('CoreBadgeStyle', () {
    test('null other returns this on merge', () {
      const a = CoreBadgeStyle(backgroundColor: _kColorTokenPrimary);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreBadgeStyle(
        backgroundColor: _kColorTokenSurface,
        padding: _kPaddingSmall,
        labelStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          fontWeight: _kWeightRegular,
          color: _kColorOnSurface,
        ),
      );
      const themeStyle = CoreBadgeStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      const widgetStyle = CoreBadgeStyle(padding: _kPaddingMedium);

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.backgroundColor, _kColorTokenSurface);
      expect(effective.labelStyle?.fontSize, _kFontLabel);
      expect(effective.labelStyle?.fontWeight, _kWeightSemiBold);
      expect(effective.labelStyle?.color, _kColorOnSurface);
      expect(effective.padding, _kPaddingMedium);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreBadgeStyle(padding: _kPaddingSmall);
      const b = CoreBadgeStyle(padding: _kPaddingMedium);
      const c = CoreBadgeStyle(padding: _kPaddingLarge);
      final result = a.merge(b).merge(c);
      expect(result.padding, _kPaddingLarge);
    });

    test('iconStyle / labelStyle merge recursively', () {
      const base = CoreBadgeStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
        iconStyle: CoreIconStyle(size: _kIconSize),
      );
      const override = CoreBadgeStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontTitle);
      expect(merged.iconStyle?.size, _kIconSize);
    });

    test('equality + copyWith preserves nested', () {
      const a = CoreBadgeStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
        iconStyle: CoreIconStyle(size: _kIconSize),
      );
      const b = CoreBadgeStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
        iconStyle: CoreIconStyle(size: _kIconSize),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(padding: _kPaddingMedium);
      expect(copy.padding, _kPaddingMedium);
      expect(copy.labelStyle?.fontSize, _kFontLabel);
      expect(copy.iconStyle?.size, _kIconSize);
    });
  });

  group('CoreBadgeStyle — every field takes part', () {
    test('a full style is equal to a copy of itself, hash included', () {
      final copy = _kFull.copyWith();
      expect(copy, _kFull);
      expect(copy.hashCode, _kFull.hashCode);
    });

    test('an empty style merges to the other side, both ways', () {
      expect(const CoreBadgeStyle().merge(_kFull), _kFull);
      expect(_kFull.merge(const CoreBadgeStyle()), _kFull);
    });

    for (final (field, changed) in _kOneFieldChanged) {
      test('$field — copyWith sets it, == and hashCode see it, merge '
          'carries it', () {
        expect(changed, isNot(_kFull), reason: '== ignores $field');
        expect(
          changed.hashCode,
          isNot(_kFull.hashCode),
          reason: 'hashCode ignores $field',
        );
        // Merging the changed style over the full one must land on it —
        // a field merge drops would leave the full style's value.
        expect(_kFull.merge(changed), changed, reason: 'merge drops $field');
        // And the full style over the changed one lands back on the full.
        expect(changed.merge(_kFull), _kFull, reason: 'merge drops $field');
      });
    }

    test('the three v2 fields override singly through merge', () {
      const base = CoreBadgeStyle(
        minHeight: 18,
        leadingDotSize: 4,
        stateLayer: CoreStateLayer.standard,
      );
      final merged = base.merge(
        const CoreBadgeStyle(
          minHeight: 20,
          leadingDotSize: 6,
          stateLayer: CoreStateLayer.strong,
        ),
      );
      expect(merged.minHeight, 20);
      expect(merged.leadingDotSize, 6);
      expect(merged.stateLayer, CoreStateLayer.strong);

      final untouched = base.merge(const CoreBadgeStyle(dotSize: 8));
      expect(untouched.minHeight, 18);
      expect(untouched.leadingDotSize, 4);
      expect(untouched.stateLayer, CoreStateLayer.standard);
    });
  });

  group('CoreBadgeToneStyle equality', () {
    const row = CoreBadgeToneStyle(
      filledBackgroundColor: CoreColor.token(CoreColors.info),
      filledForegroundColor: CoreColor.token(CoreColors.onInfo),
      tonalBackgroundColor: CoreColor.token(CoreColors.infoContainer),
      tonalForegroundColor: CoreColor.token(CoreColors.onInfoContainer),
      outlinedBorderColor: CoreColor.token(CoreColors.info),
      outlinedForegroundColor: CoreColor.token(CoreColors.onInfoContainer),
      outlinedMarkColor: CoreColor.token(CoreColors.info),
      dotColor: CoreColor.token(CoreColors.info),
    );
    const other = CoreColor.token(CoreColors.error);

    CoreBadgeToneStyle withField(String field) => CoreBadgeToneStyle(
      filledBackgroundColor: field == 'filledBackgroundColor'
          ? other
          : row.filledBackgroundColor,
      filledForegroundColor: field == 'filledForegroundColor'
          ? other
          : row.filledForegroundColor,
      tonalBackgroundColor: field == 'tonalBackgroundColor'
          ? other
          : row.tonalBackgroundColor,
      tonalForegroundColor: field == 'tonalForegroundColor'
          ? other
          : row.tonalForegroundColor,
      outlinedBorderColor: field == 'outlinedBorderColor'
          ? other
          : row.outlinedBorderColor,
      outlinedForegroundColor: field == 'outlinedForegroundColor'
          ? other
          : row.outlinedForegroundColor,
      outlinedMarkColor: field == 'outlinedMarkColor'
          ? other
          : row.outlinedMarkColor,
      dotColor: field == 'dotColor' ? other : row.dotColor,
    );

    test('two rows with the same colours are equal and hash alike', () {
      final same = withField('');
      expect(same, row);
      expect(same.hashCode, row.hashCode);
    });

    for (final field in [
      'filledBackgroundColor',
      'filledForegroundColor',
      'tonalBackgroundColor',
      'tonalForegroundColor',
      'outlinedBorderColor',
      'outlinedForegroundColor',
      'outlinedMarkColor',
      'dotColor',
    ]) {
      test('$field takes part in == and hashCode', () {
        final changed = withField(field);
        expect(changed, isNot(row));
        expect(changed.hashCode, isNot(row.hashCode));
      });
    }
  });

  group('CoreBadgeTheme', () {
    const style = CoreBadgeStyle(backgroundColor: _kColorTokenPrimary);
    const info = CoreBadgeStyle(minHeight: 20);
    const warning = CoreBadgeStyle(minHeight: 32);
    const filled = CoreBadgeStyle(borderWidth: 2);

    test('passes its slots through', () {
      const theme = CoreBadgeTheme(
        style: style,
        toneStyles: {CoreBadgeTone.info: info},
        variantStyles: {CoreBadgeVariant.filled: filled},
      );
      expect(theme.style, style);
      expect(theme.toneStyles![CoreBadgeTone.info], info);
      expect(theme.variantStyles![CoreBadgeVariant.filled], filled);
    });

    test('equal maps make equal themes, whatever the entry order', () {
      const a = CoreBadgeTheme(
        style: style,
        toneStyles: {CoreBadgeTone.info: info, CoreBadgeTone.warning: warning},
        variantStyles: {CoreBadgeVariant.filled: filled},
      );
      const b = CoreBadgeTheme(
        style: style,
        toneStyles: {CoreBadgeTone.warning: warning, CoreBadgeTone.info: info},
        variantStyles: {CoreBadgeVariant.filled: filled},
      );
      // Two distinct map objects — `==` has to compare entries, not
      // identity, and the hash has to ignore the order.
      expect(identical(a.toneStyles, b.toneStyles), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('toneStyles takes part in == and hashCode', () {
      const a = CoreBadgeTheme(toneStyles: {CoreBadgeTone.info: info});
      const b = CoreBadgeTheme(toneStyles: {CoreBadgeTone.info: warning});
      const c = CoreBadgeTheme(toneStyles: {CoreBadgeTone.warning: info});
      const none = CoreBadgeTheme();
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
      expect(a, isNot(c));
      expect(a.hashCode, isNot(c.hashCode));
      expect(a, isNot(none));
    });

    test('variantStyles takes part in == and hashCode', () {
      const a = CoreBadgeTheme(
        variantStyles: {CoreBadgeVariant.filled: filled},
      );
      const b = CoreBadgeTheme(
        variantStyles: {CoreBadgeVariant.outlined: filled},
      );
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('style takes part in == and hashCode', () {
      const a = CoreBadgeTheme(style: style);
      const b = CoreBadgeTheme(style: info);
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  // `defaultsBySize[size]!` is a Map lookup, not a `switch`, so Dart's
  // exhaustiveness checker never sees it: adding a `CoreComponentSize`
  // member compiles clean and only crashes the first time a resolver looks
  // it up. This group is the net — it fails the moment a member is added
  // without a matching entry, before any `!` ever gets a chance to throw at
  // runtime.
  group('CoreBadgeStyle.defaultsBySize coverage', () {
    test('covers every CoreComponentSize member', () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreBadgeStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreComponentSize.${size.name} — '
              'every `defaultsBySize[size]!` lookup in the resolvers '
              'assumes full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreComponentSize member', () {
      // Guards the other direction: a stale entry left behind after a
      // member is removed from CoreComponentSize.
      expect(
        CoreBadgeStyle.defaultsBySize.length,
        CoreComponentSize.values.length,
      );
    });
  });
}
