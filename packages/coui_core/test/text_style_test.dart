// Tests for the unified CoreTextStyle (Epic #1302 Phase 1).
// CoreTextStyle now mirrors Flutter's TextStyle — a single class
// covering both typography spec (all fields populated) and Layer-2
// override (any subset).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kFontSizeBody = 14;
const double _kFontSizeXl = 20;

const int _kWeightRegular = CoreFontWeight.regular;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightBold = CoreFontWeight.bold;

const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorError = CoreColor.token(CoreColors.error);

const double _kLineHeightTight = 1.2;
const double _kLineHeightLoose = 1.6;

void main() {
  group('CoreTextStyle.merge', () {
    test('null other returns this', () {
      const a = CoreTextStyle(
        fontSize: _kFontSizeBody,
        color: _kColorOnSurface,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('non-null fields in other override receiver', () {
      const base = CoreTextStyle(
        fontSize: _kFontSizeBody,
        fontWeight: _kWeightRegular,
        color: _kColorOnSurface,
      );
      const override = CoreTextStyle(
        fontWeight: _kWeightBold,
        color: _kColorError,
      );
      final merged = base.merge(override);
      expect(merged.fontSize, _kFontSizeBody);
      expect(merged.fontWeight, _kWeightBold);
      expect(merged.color, _kColorError);
    });

    test('chain — typography spec → theme → widget', () {
      const spec = CoreTextStyle(
        fontSize: _kFontSizeBody,
        lineHeight: _kLineHeightTight,
        fontWeight: _kWeightRegular,
        color: _kColorOnSurface,
      );
      const themeOverride = CoreTextStyle(
        fontWeight: _kWeightSemiBold,
      );
      const widgetOverride = CoreTextStyle(
        color: _kColorPrimary,
      );

      final effective = spec.merge(themeOverride).merge(widgetOverride);

      expect(effective.fontSize, _kFontSizeBody);
      expect(effective.fontWeight, _kWeightSemiBold);
      expect(effective.color, _kColorPrimary);
      expect(effective.lineHeight, _kLineHeightTight);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreTextStyle(fontSize: _kFontSizeXl);
      const b = CoreTextStyle(
        fontSize: _kFontSizeBody,
        fontWeight: _kWeightRegular,
      );
      const c = CoreTextStyle(fontWeight: _kWeightBold);

      final result = a.merge(b).merge(c);

      expect(result.fontSize, _kFontSizeBody);
      expect(result.fontWeight, _kWeightBold);
    });

    test('lineHeight + letterSpacing carry through', () {
      const base = CoreTextStyle(
        fontSize: _kFontSizeBody,
        lineHeight: _kLineHeightTight,
      );
      const override = CoreTextStyle(lineHeight: _kLineHeightLoose);
      final merged = base.merge(override);
      expect(merged.lineHeight, _kLineHeightLoose);
    });
  });

  group('CoreTextStyle equality', () {
    test('same fields → equal', () {
      const a = CoreTextStyle(
        fontSize: _kFontSizeBody,
        fontWeight: _kWeightSemiBold,
        color: _kColorPrimary,
      );
      const b = CoreTextStyle(
        fontSize: _kFontSizeBody,
        fontWeight: _kWeightSemiBold,
        color: _kColorPrimary,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different fontWeight → not equal', () {
      const a = CoreTextStyle(fontWeight: _kWeightRegular);
      const b = CoreTextStyle(fontWeight: _kWeightBold);
      expect(a, isNot(equals(b)));
    });

    test('different color → not equal', () {
      const a = CoreTextStyle(color: _kColorPrimary);
      const b = CoreTextStyle(color: _kColorError);
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreTextStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreTextStyle(
        fontSize: _kFontSizeBody,
        fontWeight: _kWeightRegular,
        color: _kColorOnSurface,
      );
      final copy = base.copyWith(fontWeight: _kWeightBold);
      expect(copy.fontSize, _kFontSizeBody);
      expect(copy.fontWeight, _kWeightBold);
      expect(copy.color, _kColorOnSurface);
    });
  });

  group('CoreTextStyle.scale', () {
    test('scales fontSize, leaves em letterSpacing / lineHeight invariant', () {
      const base = CoreTextStyle(
        fontSize: _kFontSizeBody,
        lineHeight: _kLineHeightTight,
        fontWeight: _kWeightSemiBold,
        letterSpacing: 0.5,
      );
      final scaled = base.scale(2);
      expect(scaled.fontSize, _kFontSizeBody * 2);
      // letterSpacing (em ratio) and lineHeight (unitless multiplier) are
      // scale-invariant — they track the scaled fontSize at conversion time,
      // so scaling them here would double-apply the factor.
      expect(scaled.letterSpacing, 0.5);
      expect(scaled.fontWeight, _kWeightSemiBold);
      expect(scaled.lineHeight, _kLineHeightTight);
    });
  });

  group('CoreTextStyle.toCss', () {
    test('omits null fields', () {
      const partial = CoreTextStyle(
        fontSize: _kFontSizeBody,
        fontWeight: _kWeightSemiBold,
      );
      final css = partial.toCss();
      expect(css.contains('font-weight: $_kWeightSemiBold'), isTrue);
      expect(css.contains('font-size: ${_kFontSizeBody}px'), isTrue);
      expect(css.contains('line-height'), isFalse);
      expect(css.contains('letter-spacing'), isFalse);
    });
  });

  // ─── Fixed line box ─────────────────────────────────────────────────────
  //
  // `lineHeightPx` and `lineHeight` are two spellings of one value, so the
  // later statement is the one drawn. If a multiplier overlay could not
  // displace a pixel box, a component that set 1.4 over a code role would be
  // silently ignored.
  group('CoreTextStyle.lineHeightPx', () {
    const code = CoreTextStyle(
      fontSize: 12,
      lineHeightPx: CoreLineBox.px21,
    );

    test('a multiplier overlay replaces the box', () {
      final merged = code.merge(const CoreTextStyle(lineHeight: 1.4));
      expect(merged.lineHeight, 1.4);
      expect(merged.lineHeightPx, isNull);
      final copied = code.copyWith(lineHeight: 1.4);
      expect(copied.lineHeight, 1.4);
      expect(copied.lineHeightPx, isNull);
    });

    test('a box overlay wins over a base multiplier', () {
      const body = CoreTextStyle(fontSize: 14, lineHeight: 1.5);
      final merged = body.merge(const CoreTextStyle(lineHeightPx: 20));
      expect(merged.lineHeightPx, 20);
      expect(body.copyWith(lineHeightPx: 20).lineHeightPx, 20);
    });

    test('an overlay that states neither keeps the box', () {
      expect(
        code.merge(const CoreTextStyle(fontWeight: 500)).lineHeightPx,
        CoreLineBox.px21,
      );
      expect(code.copyWith(fontSize: 13).lineHeightPx, CoreLineBox.px21);
    });

    test('a token style carries no box of its own', () {
      expect(
        const CoreTextStyle.token(CoreTextStyles.codeSm).lineHeightPx,
        isNull,
      );
    });

    // A length, not a ratio: it grows with the glyphs it boxes.
    test('scale multiplies the box', () {
      expect(code.scale(2).lineHeightPx, 42);
    });

    test('takes part in equality', () {
      expect(code, isNot(const CoreTextStyle(fontSize: 12)));
      expect(
        code,
        const CoreTextStyle(fontSize: 12, lineHeightPx: CoreLineBox.px21),
      );
      expect(
        code.hashCode,
        const CoreTextStyle(
          fontSize: 12,
          lineHeightPx: CoreLineBox.px21,
        ).hashCode,
      );
    });

    test('toCss writes the box as a length', () {
      expect(code.toCss(), contains('line-height: 21.0px'));
      expect(
        const CoreTextStyle(lineHeight: 1.4, lineHeightPx: 21).toCss(),
        isNot(contains('line-height: 1.4')),
      );
    });
  });

  // ─── A later role replaces the earlier role's size and line box ─────────
  //
  // A role fixes how large its text is and how tall its line is. An overlay
  // on that measure (`lineHeight: 1.4` over `bodyMedium`) belongs to the role
  // it was laid over, so a different role stated later is the newer statement
  // and the earlier measure does not follow it. Left in place, the stale
  // overlay is applied over the new role at render time: a `codeMd` stated
  // over the text-field ladder's 140% `bodyMedium` lost its fixed 21px line
  // box and drew 18.2px. Weight, family, tracking and colour are laid over
  // whichever role is drawn, so they stay.
  group('CoreTextStyle.merge — a later role replaces the earlier measure', () {
    const body = CoreTextStyle.token(CoreTextStyles.bodyMedium);
    const code = CoreTextStyle.token(CoreTextStyles.codeMd);

    test("the earlier role's line-height overlay does not follow", () {
      final ladder = body.copyWith(lineHeight: CoreLineHeight.h140);
      final merged = ladder.merge(code);
      expect(merged.token, CoreTextStyles.codeMd);
      expect(merged.lineHeight, isNull);
      expect(merged.lineHeightPx, isNull);
    });

    test('nor does its size or its fixed line box', () {
      final sized = body.copyWith(fontSize: 18, lineHeightPx: CoreLineBox.px21);
      final merged = sized.merge(code);
      expect(merged.token, CoreTextStyles.codeMd);
      expect(merged.fontSize, isNull);
      expect(merged.lineHeightPx, isNull);
    });

    // A selected label states a semibold emphasis over its role; a variant
    // that draws the label in a larger role keeps the emphasis.
    test("weight, family, tracking and colour are not the role's measure", () {
      final earlier =
          const CoreTextStyle.token(
            CoreTextStyles.bodyMedium,
            color: _kColorPrimary,
          ).copyWith(
            fontWeight: _kWeightSemiBold,
            fontFamily: CoreFontFamily.sans,
            letterSpacing: -0.02,
          );
      final merged = earlier.merge(code);
      expect(merged.token, CoreTextStyles.codeMd);
      expect(merged.fontWeight, _kWeightSemiBold);
      expect(merged.fontFamily, CoreFontFamily.sans);
      expect(merged.letterSpacing, -0.02);
      expect(merged.color, _kColorPrimary);
    });

    test('what the later style states itself still lands on its role', () {
      final ladder = body.copyWith(lineHeight: CoreLineHeight.h140);
      final merged = ladder.merge(
        code.copyWith(fontWeight: _kWeightSemiBold, lineHeight: 1.2),
      );
      expect(merged.token, CoreTextStyles.codeMd);
      expect(merged.fontWeight, _kWeightSemiBold);
      expect(merged.lineHeight, 1.2);
    });

    test('stating the same role again keeps what was laid over it', () {
      final bold = body.copyWith(fontWeight: _kWeightBold);
      final merged = bold.merge(body);
      expect(merged.fontWeight, _kWeightBold);
    });

    test('an overlay with no role of its own still lands on the role', () {
      final ladder = body.copyWith(lineHeight: CoreLineHeight.h140);
      final merged = ladder.merge(const CoreTextStyle(fontWeight: 500));
      expect(merged.token, CoreTextStyles.bodyMedium);
      expect(merged.lineHeight, CoreLineHeight.h140);
      expect(merged.fontWeight, 500);
    });

    test('a role stated over a style with no role keeps the raw fields', () {
      const raw = CoreTextStyle(fontSize: 18, lineHeight: 1.2);
      final merged = raw.merge(code);
      expect(merged.token, CoreTextStyles.codeMd);
      expect(merged.fontSize, 18);
      expect(merged.lineHeight, 1.2);
    });

    test('the same result through a chain of three', () {
      final ladder = body.copyWith(lineHeight: CoreLineHeight.h140);
      final merged = ladder
          .merge(code)
          .merge(const CoreTextStyle(color: _kColorError));
      expect(merged.token, CoreTextStyles.codeMd);
      expect(merged.lineHeight, isNull);
      expect(merged.color, _kColorError);
    });
  });
}
