/// The stroke weight Lucide glyphs are drawn with — one rule, both platforms.
library;

/// Single source of the rendered stroke weight of a Lucide icon.
///
/// Every vendored Lucide glyph is authored with `stroke-width="2"` on a
/// 24-unit grid. Left alone, the rendered stroke is `size × 2 / 24` — it
/// grows in lockstep with the icon, so a 10 icon is hairline-thin and a 32
/// icon is heavier than body text. The rule here replaces that proportion:
///
/// ```text
/// rendered stroke (token px) = max(1.25, tokenSize / 16)
/// ```
///
/// 20 and below hold at 1.25, and from 24 up the stroke follows the size
/// (24 → 1.5, 28 → 1.75, 32 → 2). Sizes off the ladder use the same formula
/// (8 → 1.25, 22 → 1.375).
///
/// ## `tokenSize` is the size before layout scaling
///
/// `tokenSize` is the icon size as the style states it, *before* the
/// resolver multiplies by the theme scaling. The scaled box then scales the
/// stroke with it, so the stroke keeps its proportion to the glyph: token 20
/// on a 1.25× screen draws a 25 px glyph with a 1.5625 px stroke.
///
/// ## Lucide only
///
/// Only icon ids whose prefix is [lucidePrefix] are rewritten. HeroIcons,
/// Radix and Bootstrap bodies are returned untouched — their strokes are
/// authored for their own grids (or are filled paths) and the rule does not
/// describe them.
///
/// ## Not a `CoreStrokeWidth` member
///
/// [minRenderedWidth] and [renderedWidthDivisor] deliberately do not live in
/// `CoreStrokeWidth`, and nothing here reads `CoreStrokeWidth` or the
/// `--coui-stroke-width-*` variables. Surface presets raise that scale (the
/// neo-brutalism preset draws every border at 3 px) and an icon must not
/// thicken with the box around it. The scale also steps in whole pixels and
/// has no rung at 1.25.
abstract final class CoreIconStroke {
  const CoreIconStroke._();

  /// Icon-set prefix the rule applies to (`lucide:home` → `lucide`).
  static const String lucidePrefix = 'lucide';

  /// Smallest rendered stroke, in token px — every size up to 20 draws at
  /// this weight.
  ///
  /// A mark that is not an icon but must read at the icon weight (the
  /// checkbox's indeterminate dash) takes its thickness from this constant
  /// instead of restating the number, so the two cannot be edited apart.
  ///
  /// Not a `CoreStrokeWidth` rung: presets raise that scale and icons must
  /// not follow, and the scale has no 1.25 step.
  static const double minRenderedWidth = 1.25;

  /// Token size per px of stroke once the size exceeds
  /// `minRenderedWidth × renderedWidthDivisor` (20): the stroke is
  /// `tokenSize / renderedWidthDivisor`.
  ///
  /// Not a `CoreStrokeWidth` member, for the same reason as
  /// [minRenderedWidth].
  static const double renderedWidthDivisor = 16;

  /// The stroke every vendored Lucide glyph is authored with. This is the
  /// value [apply] looks for; any other width in a body is left alone.
  static const String _authoredWidth = '2';

  /// Decimal places kept when a width is written into an attribute.
  static const int _fractionDigits = 4;

  /// `10 ^ _fractionDigits`, as an integer so the rounding is exact.
  static const int _fractionScale = 10000;

  /// Matches `stroke-width="2"` / `stroke-width='2'` as a whole attribute.
  ///
  /// The leading whitespace keeps `data-stroke-width` and similar names out
  /// (a look-behind would do it too, but not every browser engine dart2js
  /// targets can build one). Group 1 is that whitespace, group 2 the quote.
  static final RegExp _authoredAttribute = RegExp(
    '(\\s)stroke-width=(["\'])$_authoredWidth\\2',
  );

  /// Trailing zeros of a fraction, trimmed by [formatNumber].
  static final RegExp _trailingZeros = RegExp(r'0+$');

  /// The rendered stroke of an icon drawn at [tokenSize], in token px.
  ///
  /// `max(minRenderedWidth, tokenSize / renderedWidthDivisor)`. [tokenSize]
  /// must be finite and positive; [apply] guards that before calling.
  static double renderedWidth(double tokenSize) {
    assert(
      tokenSize.isFinite && tokenSize > 0,
      'tokenSize must be finite and positive, got $tokenSize',
    );
    final proportional = tokenSize / renderedWidthDivisor;

    return proportional > minRenderedWidth ? proportional : minRenderedWidth;
  }

  /// The SVG `stroke-width` attribute that renders the rule's
  /// [renderedWidth] for an icon of [tokenSize] drawn from a glyph whose
  /// viewBox is [viewBox] units wide.
  ///
  /// The SVG is scaled `tokenSize / viewBox` on its way to the screen, so the
  /// attribute is `renderedWidth(tokenSize) × viewBox / tokenSize`. For the
  /// 24-unit Lucide viewBox that is `max(1.5, 30 / tokenSize)`.
  static double svgStrokeWidth(double tokenSize, {required num viewBox}) {
    assert(
      tokenSize.isFinite && tokenSize > 0,
      'tokenSize must be finite and positive, got $tokenSize',
    );

    return renderedWidth(tokenSize) * viewBox / tokenSize;
  }

  /// Rewrites the authored stroke of a Lucide [body] to the rule's width.
  ///
  /// Returns [body] unchanged unless [prefix] is [lucidePrefix], [tokenSize]
  /// is finite and positive, and [viewBox] is positive. Otherwise every
  /// `stroke-width="2"` attribute (single or double quotes) is replaced by
  /// the value [svgStrokeWidth] gives for [tokenSize] and [viewBox]; widths
  /// other than the authored 2 are not touched.
  ///
  /// The attribute is written through [formatNumber], so the same input
  /// yields the same string on the VM and under dart2js.
  static String apply({
    required String prefix,
    required String body,
    required double tokenSize,
    required num viewBox,
  }) {
    if (prefix != lucidePrefix) return body;
    if (!tokenSize.isFinite || tokenSize <= 0) return body;
    if (!(viewBox > 0)) return body;
    if (!body.contains('stroke-width')) return body;

    final value = formatNumber(svgStrokeWidth(tokenSize, viewBox: viewBox));

    return body.replaceAllMapped(
      _authoredAttribute,
      (match) => '${match[1]}stroke-width=${match[2]}$value${match[2]}',
    );
  }

  /// Writes [value] as an attribute number: at most four decimals, trailing
  /// zeros trimmed (`1.5`, `1.25`, `1.3636`, `3`).
  ///
  /// Rounds on integer arithmetic (half away from zero) instead of
  /// `toStringAsFixed`, whose digit generation is not specified to match
  /// between the VM and dart2js. A non-finite [value] has no attribute form
  /// and is written as `0`.
  static String formatNumber(double value) {
    if (!value.isFinite) return '0';
    final scaled = (value.abs() * _fractionScale).round();
    final whole = scaled ~/ _fractionScale;
    final fraction = scaled % _fractionScale;
    final sign = value < 0 && scaled != 0 ? '-' : '';
    if (fraction == 0) return '$sign$whole';
    final digits = fraction
        .toString()
        .padLeft(_fractionDigits, '0')
        .replaceFirst(_trailingZeros, '');

    return '$sign$whole.$digits';
  }
}
