// A resting OTP cell steps to a hover border one notch past its
// `outlineVariant` edge. The Core contract owns the whole ladder
// `disabled > error > focus > hover > rest`'s hover rung: the default tone,
// the error variant's restatement, and the field's place in the value
// semantics (`merge` / `copyWith` / `==` / `hashCode`) — the resolvers on
// both platforms read nothing else, so a field that fell out of any of them
// would stop reaching the screen without a single compile error.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kOnSurface = CoreColor.token(CoreColors.onSurface);
const _kOutline = CoreColor.token(CoreColors.outline);
const _kOutlineVariant = CoreColor.token(CoreColors.outlineVariant);
const _kError = CoreColor.token(CoreColors.error);
const _kTertiary = CoreColor.token(CoreColors.tertiary);
const _kPrimary = CoreColor.token(CoreColors.primary);

void main() {
  group('CoreInputOtpStyle hover border — defaults', () {
    test('a resting cell hovers to outline', () {
      expect(CoreInputOtpStyle.defaultHoverBorderColor, _kOutline);
    });

    test('the hover tone is a step past the resting edge, not the same', () {
      expect(CoreInputOtpStyle.defaultBorderColor, _kOutlineVariant);
      expect(
        CoreInputOtpStyle.defaultHoverBorderColor,
        isNot(CoreInputOtpStyle.defaultBorderColor),
      );
    });

    test('the error variant restates error for hover, resting and focus', () {
      final error =
          CoreInputOtpStyle.defaultsByVariant[CoreInputOtpVariant.error]!;
      expect(error.borderColor, _kError);
      expect(error.hoverBorderColor, _kError);
      expect(error.focusBorderColor, _kError);
    });

    test('the error variant never softens to the ordinary hover tone', () {
      final error =
          CoreInputOtpStyle.defaultsByVariant[CoreInputOtpVariant.error]!;
      expect(
        error.hoverBorderColor,
        isNot(CoreInputOtpStyle.defaultHoverBorderColor),
      );
    });

    test('the ordinary variant states no hover of its own, so the resolver '
        'falls through to defaultHoverBorderColor', () {
      final ordinary = CoreInputOtpStyle
          .defaultsByVariant[CoreInputOtpVariant.defaultVariant]!;
      expect(ordinary.hoverBorderColor, isNull);
    });
  });

  group('CoreInputOtpStyle hover border — value semantics', () {
    test('merge: the other side wins, null keeps this side', () {
      const base = CoreInputOtpStyle(hoverBorderColor: _kTertiary);

      expect(
        base.merge(const CoreInputOtpStyle(hoverBorderColor: _kPrimary)),
        const CoreInputOtpStyle(hoverBorderColor: _kPrimary),
      );
      expect(base.merge(const CoreInputOtpStyle()), base);
      expect(
        const CoreInputOtpStyle().merge(base).hoverBorderColor,
        _kTertiary,
      );
    });

    test('merge keeps the hover tone next to a border override', () {
      final merged = const CoreInputOtpStyle(
        hoverBorderColor: _kTertiary,
      ).merge(const CoreInputOtpStyle(borderColor: _kError));

      expect(merged.hoverBorderColor, _kTertiary);
      expect(merged.borderColor, _kError);
    });

    test('copyWith carries and replaces the hover tone', () {
      const base = CoreInputOtpStyle(hoverBorderColor: _kTertiary);

      expect(base.copyWith(borderColor: _kError).hoverBorderColor, _kTertiary);
      expect(
        base.copyWith(hoverBorderColor: _kPrimary).hoverBorderColor,
        _kPrimary,
      );
    });

    test('== and hashCode see the hover tone', () {
      const a = CoreInputOtpStyle(hoverBorderColor: _kTertiary);
      const same = CoreInputOtpStyle(hoverBorderColor: _kTertiary);
      const other = CoreInputOtpStyle(hoverBorderColor: _kPrimary);

      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(other));
      expect(a.hashCode, isNot(other.hashCode));
      expect(a, isNot(const CoreInputOtpStyle()));
    });
  });

  // A cell that is not square — `cellHeight` beside `cellSize`. Both
  // resolvers read the chain `cellHeight ?? cellSize ?? defaultCellHeight`,
  // so the field has to survive every step of the value semantics or a
  // restated height stops reaching the screen.
  group('CoreInputOtpStyle cellHeight', () {
    // #6464: the resting cell is a 44 × 52 box, taller than wide.
    test('the resting cell is 44 wide and 52 tall', () {
      expect(CoreInputOtpStyle.defaultCellSize, 44);
      expect(CoreInputOtpStyle.defaultCellHeight, 52);
      expect(CoreInputOtpStyle.defaultHeight, 52);
    });

    test('merge: the other side wins, null keeps this side', () {
      const base = CoreInputOtpStyle(cellHeight: CoreSize.size48);
      expect(
        base
            .merge(const CoreInputOtpStyle(cellHeight: CoreSize.size56))
            .cellHeight,
        CoreSize.size56,
      );
      expect(base.merge(const CoreInputOtpStyle()).cellHeight, CoreSize.size48);
    });

    test('copyWith carries and replaces it', () {
      const base = CoreInputOtpStyle(cellHeight: CoreSize.size48);
      expect(base.copyWith().cellHeight, CoreSize.size48);
      expect(
        base.copyWith(cellHeight: CoreSize.size56).cellHeight,
        CoreSize.size56,
      );
    });

    test('== and hashCode see it', () {
      const a = CoreInputOtpStyle(cellHeight: CoreSize.size48);
      const same = CoreInputOtpStyle(cellHeight: CoreSize.size48);
      const other = CoreInputOtpStyle(cellHeight: CoreSize.size56);

      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(other));
      expect(a, isNot(const CoreInputOtpStyle()));
    });
  });

  group('CoreInputOtpStyle.defaultsBySize', () {
    final md = CoreInputOtpStyle.defaultsBySize[CoreInputOtpSize.md];
    final lg = CoreInputOtpStyle.defaultsBySize[CoreInputOtpSize.lg];

    test('the default size is md', () {
      expect(CoreInputOtpSize.defaultSize, CoreInputOtpSize.md);
    });

    // Both resolvers read `defaultsBySize[size]!` — a missing row is a crash
    // at render, and the shared completeness test only walks
    // `CoreComponentSize` maps.
    test('every size has a row', () {
      expect(
        CoreInputOtpStyle.defaultsBySize.keys.toSet(),
        CoreInputOtpSize.values.toSet(),
      );
    });

    // An empty md row is what keeps the default field drawn as it was before
    // the axis: every field falls through to the `default*` constants.
    test('md states nothing — the default field is unchanged', () {
      expect(md, const CoreInputOtpStyle());
    });

    test('lg states a 56 × 64 cell and a 64 row floor', () {
      expect(lg!.cellSize, CoreSize.size56);
      expect(lg.cellHeight, CoreSize.size64);
      expect(lg.height, CoreSize.size64);
    });

    test('lg corner is 14, on the radius ladder', () {
      expect(lg!.borderRadius, const CoreBorderRadius.all(CoreRadius.radius14));
      expect(CoreRadius.steps, contains(CoreRadius.radius14));
    });

    test('lg caret is 24 tall', () {
      expect(lg!.caretHeight, CoreSize.size24);
    });

    test('lg digit composes to headlineSmall, semi-bold, onSurface', () {
      final digit = CoreInputOtpStyle.defaultTextStyle.merge(lg!.textStyle);
      expect(digit.token, CoreTextStyles.headlineSmall);
      expect(CoreTypography.coui.headlineSmall.fontSize, 24);
      expect(digit.fontWeight, CoreFontWeight.semiBold);
      expect(digit.color, _kOnSurface);
      expect(digit.fontSize, isNull);
    });

    // Colours, the dot, the separator and the error line do not vary by
    // size (#6464).
    test('lg states no colour, dot, separator or error line', () {
      expect(lg!.backgroundColor, isNull);
      expect(lg.borderColor, isNull);
      expect(lg.filledBackgroundColor, isNull);
      expect(lg.filledBorderColor, isNull);
      expect(lg.hoverBorderColor, isNull);
      expect(lg.focusBackgroundColor, isNull);
      expect(lg.focusBorderColor, isNull);
      expect(lg.caretColor, isNull);
      expect(lg.borderWidth, isNull);
      expect(lg.obscuredDotSize, isNull);
      expect(lg.separatorColor, isNull);
      expect(lg.cellSpacing, isNull);
      expect(lg.errorTextPadding, isNull);
      expect(lg.errorValidatorHintStyle, isNull);
    });
  });

  // #6464 — the redesign's table, one row per assertion.
  group('CoreInputOtpStyle #6464 defaults', () {
    test('md cell corner is 10', () {
      expect(
        CoreInputOtpStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius10),
      );
    });

    test("md digit is titleMedium — 18, the role's own semi-bold", () {
      const digit = CoreInputOtpStyle.defaultTextStyle;
      expect(digit.token, CoreTextStyles.titleMedium);
      expect(digit.fontSize, isNull);
      expect(digit.fontWeight, isNull);
      expect(CoreTypography.coui.titleMedium.fontSize, 18);
      expect(
        CoreTypography.coui.titleMedium.fontWeight,
        CoreFontWeight.semiBold,
      );
      expect(digit.color, _kOnSurface);
    });

    test('an empty cell is surfaceContainerLow on outlineVariant', () {
      expect(
        CoreInputOtpStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
      expect(CoreInputOtpStyle.defaultBorderColor, _kOutlineVariant);
    });

    test('a filled cell is surface on outline', () {
      expect(
        CoreInputOtpStyle.defaultFilledBackgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(CoreInputOtpStyle.defaultFilledBorderColor, _kOutline);
    });

    test('the active cell keeps its fill and takes an outline edge', () {
      expect(
        CoreInputOtpStyle.defaultFocusBackgroundColor,
        CoreInputOtpStyle.defaultBackgroundColor,
      );
      expect(CoreInputOtpStyle.defaultFocusBorderColor, _kOutline);
      expect(CoreInputOtpStyle.defaultFocusBorderColor, isNot(_kPrimary));
      final ordinary = CoreInputOtpStyle
          .defaultsByVariant[CoreInputOtpVariant.defaultVariant]!;
      expect(ordinary.focusBorderColor, isNull);
    });

    test('the caret is 2 × 20 in primary, error on the error variant', () {
      expect(CoreInputOtpStyle.defaultCaretWidth, 2);
      expect(CoreInputOtpStyle.defaultCaretHeight, 20);
      expect(CoreInputOtpStyle.defaultCaretColor, _kPrimary);
      expect(CoreInputOtpStyle.defaultErrorVariantStyle.caretColor, _kError);
    });

    test('the separator is an 8 × 2 outline bar with round ends', () {
      expect(CoreInputOtpStyle.defaultSeparatorWidth, 8);
      expect(CoreInputOtpStyle.defaultSeparatorThickness, 2);
      expect(CoreInputOtpStyle.defaultSeparatorColor, _kOutline);
      expect(
        CoreInputOtpStyle.defaultSeparatorBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    test('the hidden dot is 10', () {
      expect(CoreInputOtpStyle.defaultObscuredDotSize, 10);
    });

    test('the error line is a ValidatorHint with a 14 glyph', () {
      expect(
        CoreInputOtpStyle.defaultErrorValidatorHintStyle.iconStyle?.size,
        14,
      );
      expect(
        const CoreInputOtpStyle().resolveErrorValidatorHintStyle(),
        CoreInputOtpStyle.defaultErrorValidatorHintStyle,
      );
    });

    test('the error variant restates error on the filled border too', () {
      expect(
        CoreInputOtpStyle.defaultErrorVariantStyle.filledBorderColor,
        _kError,
      );
    });

    test('the deprecated errorTextStyle still reaches the hint', () {
      const legacy = CoreTextStyle.token(
        CoreTextStyles.bodySmall,
        color: _kTertiary,
      );
      final hint = const CoreInputOtpStyle(
        errorTextStyle: legacy,
      ).resolveErrorValidatorHintStyle();
      expect(hint.messageTextStyle, legacy);
      expect(hint.accentColor, _kTertiary);
      expect(hint.iconStyle?.size, 14);
      // The nested slot wins over the deprecated field.
      final both = const CoreInputOtpStyle(
        errorTextStyle: legacy,
        errorValidatorHintStyle: CoreValidatorHintStyle(accentColor: _kPrimary),
      ).resolveErrorValidatorHintStyle();
      expect(both.accentColor, _kPrimary);
    });

    test('the new fields survive merge, copyWith and ==', () {
      const a = CoreInputOtpStyle(
        filledBackgroundColor: _kTertiary,
        filledBorderColor: _kTertiary,
        caretColor: _kTertiary,
        caretWidth: 3,
        caretHeight: 30,
        caretBorderRadius: CoreBorderRadius.zero,
        separatorColor: _kTertiary,
        separatorWidth: 12,
        separatorThickness: 3,
        separatorBorderRadius: CoreBorderRadius.zero,
        errorValidatorHintStyle: CoreValidatorHintStyle(
          accentColor: _kTertiary,
        ),
      );
      expect(const CoreInputOtpStyle().merge(a), a);
      expect(a.copyWith(), a);
      expect(a.hashCode, a.copyWith().hashCode);
      for (final other in [
        a.copyWith(filledBackgroundColor: _kPrimary),
        a.copyWith(filledBorderColor: _kPrimary),
        a.copyWith(caretColor: _kPrimary),
        a.copyWith(caretWidth: 4),
        a.copyWith(caretHeight: 31),
        a.copyWith(caretBorderRadius: const CoreBorderRadius.all(2)),
        a.copyWith(separatorColor: _kPrimary),
        a.copyWith(separatorWidth: 13),
        a.copyWith(separatorThickness: 4),
        a.copyWith(separatorBorderRadius: const CoreBorderRadius.all(2)),
        a.copyWith(
          errorValidatorHintStyle: const CoreValidatorHintStyle(
            accentColor: _kPrimary,
          ),
        ),
      ]) {
        expect(other, isNot(a));
      }
    });
  });

  group('CoreInputOtpStyle.chainHeadFor', () {
    final lg = CoreInputOtpStyle.defaultsBySize[CoreInputOtpSize.lg];

    // The variant row lies over the size row, so the error variant's
    // `error` borders survive `lg`'s own colours at rest, under the
    // pointer and on the active cell.
    test('the error variant keeps its error borders on lg', () {
      final head = CoreInputOtpStyle.chainHeadFor(
        CoreInputOtpSize.lg,
        CoreInputOtpVariant.error,
      );
      const error = CoreColor.token(CoreColors.error);
      expect(head.borderColor, error);
      expect(head.filledBorderColor, error);
      expect(head.hoverBorderColor, error);
      expect(head.focusBorderColor, error);
      expect(head.caretColor, error);
      // The lg corner, cell and caret are untouched by the variant.
      expect(head.cellSize, CoreSize.size56);
      expect(head.caretHeight, CoreSize.size24);
      expect(head.borderRadius, lg!.borderRadius);
    });

    test('the default variant leaves the lg row as it is', () {
      expect(
        CoreInputOtpStyle.chainHeadFor(
          CoreInputOtpSize.lg,
          CoreInputOtpVariant.defaultVariant,
        ),
        lg,
      );
    });

    test('md with the error variant is the error row alone', () {
      expect(
        CoreInputOtpStyle.chainHeadFor(
          CoreInputOtpSize.md,
          CoreInputOtpVariant.error,
        ),
        CoreInputOtpStyle.defaultErrorVariantStyle,
      );
    });

    // A caller's style sits above the size row in the chain: restating a
    // field over the row keeps the caller's value and the row's others.
    test('a style merged over the lg row wins field by field', () {
      final merged = lg!.merge(
        const CoreInputOtpStyle(cellSize: CoreSize.size48),
      );
      expect(merged.cellSize, CoreSize.size48);
      expect(merged.borderRadius, lg.borderRadius);
      expect(merged.textStyle, lg.textStyle);
    });
  });

  test('the contract fixes the behaviour defaults both widgets read', () {
    expect(CoreInputOtpContract.defaultLength, 6);
    expect(CoreInputOtpContract.defaultSeparatorInterval, 3);
  });
}
