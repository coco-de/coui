// TextArea states no `stateLayer` — hover rides the border alone
// (`CoreTextAreaVariantStyle.hoverBorderColor`), the same border-only model
// TextField's boxed variants use. This file pins TextArea's half of the
// state-model tokens: hover is perceptible on the border, and the disabled
// trio does not change with the error row. `text_field_state_change_
// perceptibility_test.dart` / `text_field_disabled_fill_test.dart` pin the
// same for TextField.
//
// The failure being pinned is not "wrong colour" but "no colour change at
// all": a hover border that equals the resting one is the literal absence
// of a state, and a disabled row that keeps the error's tone is the literal
// absence of `disabled > error`.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

/// Below this a state is invisible up to rounding, which is the same bug as
/// being exactly invisible. Matches the floor `text_field_state_change_
/// perceptibility_test.dart` and Button's own equivalent check use.
const double _perceptibleFloor = 1.02;

Map<String, CoreColorScheme> _schemes() {
  const source = CouiColorPresets.source;
  return {
    'light': source.light(),
    'dark': source.dark(),
    'high-contrast light': source.highContrastLight(),
    'high-contrast dark': source.highContrastDark(),
  };
}

int _argb(CoreColorScheme scheme, CoreColor color) =>
    scheme.resolve(color).argb | 0xFF000000;

CoreTextAreaVariantStyle _row(CoreTextAreaVariant variant) =>
    CoreTextAreaStyle.defaultsByVariant[variant]!;

void main() {
  group('a TextArea hover border is perceptible (no wash to fall back on)', () {
    for (final variant in CoreTextAreaVariant.values) {
      final vs = _row(variant);
      final hoverBorder = vs.hoverBorderColor ?? vs.borderColor;

      if (hoverBorder == vs.borderColor) {
        // The error row intentionally restates its resting border on
        // hover — the pointer does not soften a validation border. Pin
        // it explicitly so a future edit that accidentally drops a real
        // hover step doesn't read as "this is fine, like error".
        test('${variant.name} — hover intentionally restates the resting '
            'border', () {
          expect(hoverBorder, vs.borderColor);
        });
        continue;
      }

      test('${variant.name} — hover border is perceptibly different from '
          'the resting border, in every mode', () {
        _schemes().forEach((mode, scheme) {
          final rest = _argb(scheme, vs.borderColor);
          final hovered = _argb(scheme, hoverBorder);
          final delta = _contrast(rest, hovered);

          expect(
            delta,
            greaterThanOrEqualTo(_perceptibleFloor),
            reason:
                '$mode / ${variant.name} — the hover border lands on '
                '${delta.toStringAsFixed(4)} against the resting one, '
                'which is a state that draws nothing',
          );
        });
      });
    }
  });

  group('every TextArea variant states a disabled fill of its own', () {
    for (final variant in CoreTextAreaVariant.values) {
      test('${variant.name} — the fill is the disabled token', () {
        expect(
          _row(variant).disabledBackgroundColor,
          // The filled variant's disabled fill is the lowest container
          // tone (#5747); every other variant takes `disabledContainer`.
          CoreColor.token(
            variant == CoreTextAreaVariant.filled
                ? CoreColors.surfaceContainerLow
                : CoreColors.disabledContainer,
          ),
        );
      });

      test('${variant.name} — and it differs from the enabled fill', () {
        final row = _row(variant);
        expect(row.disabledBackgroundColor, isNot(row.backgroundColor));
      });

      test('${variant.name} — all three disabled slots carry tokens', () {
        final row = _row(variant);
        expect(row.disabledBackgroundColor.token, isNotNull);
        expect(row.disabledForegroundColor.token, isNotNull);
        expect(row.disabledBorderColor.token, isNotNull);
      });
    }
  });

  group('disabled outranks error — the disabled trio is variant-invariant', () {
    // Mirrors `text_field_disabled_fill_test.dart`'s equivalent group —
    // same shape, same bug class. A stale error border only survives
    // into the disabled paint if the error row states different disabled
    // tokens than the normal row does; it does not.
    final normal = _row(CoreTextAreaVariant.defaultVariant);
    final error = _row(CoreTextAreaVariant.error);

    test('disabledBackgroundColor is the same token on error as on normal', () {
      expect(error.disabledBackgroundColor, normal.disabledBackgroundColor);
    });

    test('disabledForegroundColor is the same token on error as on normal', () {
      expect(error.disabledForegroundColor, normal.disabledForegroundColor);
    });

    test('disabledBorderColor is the same token on error as on normal — '
        'the border does not stay error-red once disabled', () {
      expect(error.disabledBorderColor, normal.disabledBorderColor);
      expect(error.disabledBorderColor, isNot(error.borderColor));
    });
  });

  // The footer gap is a nested slot like the label / description gaps, so
  // the failure that matters is the one value types make silent: a field
  // missing from `merge` / `copyWith` / `==` never reaches the gap, and one
  // missing from `==` / `hashCode` lets an override arrive without the
  // area rebuilding.
  group('footerGapStyle', () {
    const gap16 = CoreGapStyle(size: CoreSpace.space16);
    const gap20 = CoreGapStyle(size: CoreSpace.space20);

    test('defaults to 12 — space12', () {
      expect(CoreTextAreaStyle.defaultFooterGapStyle.size, CoreSpace.space12);
    });

    test('is unset on a fresh style, so the default applies downstream', () {
      expect(const CoreTextAreaStyle().footerGapStyle, isNull);
    });

    test('merge takes the override and keeps a base the override leaves', () {
      const base = CoreTextAreaStyle(footerGapStyle: gap16);

      expect(
        base
            .merge(const CoreTextAreaStyle(footerGapStyle: gap20))
            .footerGapStyle,
        gap20,
      );
      expect(base.merge(const CoreTextAreaStyle()).footerGapStyle, gap16);
      expect(
        const CoreTextAreaStyle()
            .merge(const CoreTextAreaStyle(footerGapStyle: gap16))
            .footerGapStyle,
        gap16,
      );
    });

    test('merge folds the two slots field by field', () {
      // Recursive like the other gap slots: a colour-only override keeps
      // the base's size rather than replacing the whole slot.
      const colourOnly = CoreGapStyle(
        color: CoreColor.token(CoreColors.outline),
      );
      final merged = const CoreTextAreaStyle(
        footerGapStyle: gap16,
      ).merge(const CoreTextAreaStyle(footerGapStyle: colourOnly));

      expect(merged.footerGapStyle?.size, CoreSpace.space16);
      expect(merged.footerGapStyle?.color, colourOnly.color);
    });

    test('copyWith writes it and keeps it when omitted', () {
      const base = CoreTextAreaStyle(footerGapStyle: gap16);

      expect(base.copyWith(footerGapStyle: gap20).footerGapStyle, gap20);
      expect(base.copyWith(rowSpacing: 4).footerGapStyle, gap16);
    });

    test('== and hashCode see it', () {
      const a = CoreTextAreaStyle(footerGapStyle: gap16);

      expect(a, const CoreTextAreaStyle(footerGapStyle: gap16));
      expect(
        a.hashCode,
        const CoreTextAreaStyle(footerGapStyle: gap16).hashCode,
      );
      expect(a, isNot(const CoreTextAreaStyle(footerGapStyle: gap20)));
      expect(a, isNot(const CoreTextAreaStyle()));
    });
  });
}
