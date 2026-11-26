import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// CSS px-per-rem root font-size — matches `html { font-size: 16px }`.
/// Conversion sentinel for translating logical-pixel token values into
/// rem inside inline `Styles(raw:)`.

/// Paint-ready chrome for an `<iconify-icon>` element.
///
/// `<iconify-icon>` renders its SVG at the element font size (default
/// 1em), so `width` / `height` / `font-size` all carry [size] — SVG and
/// box stay 1:1, matching Flutter's pixel sizing.
///
/// The colour goes through [emitColorOrInherit]: a token colour is a
/// `text-{token}` class, a raw colour is an inline `color`, and a `null`
/// colour emits neither so the glyph inherits `currentColor`. Spelling a
/// raw colour as a class (`text-#FF0000`) produces no CSS at all, which
/// is how a caller's colour used to vanish on Web while Flutter painted
/// it.
///
/// A bundled icon renders as an inline `<svg>` instead ([inlineSvg]):
/// that element also takes the box `<iconify-icon>` gives its own host —
/// inline-block, dropped `0.125em` below the baseline — so the two sit
/// the same in a line of text.
WebElementChrome iconElementChrome({
  required double size,
  CoreColor? color,
  bool inlineSvg = false,
}) {
  final colour = emitColorOrInherit(color, ColorTarget.text);

  return WebElementChrome(
    className: colour.className,
    inlineStyles: Styles(
      raw: {
        if (inlineSvg) ...{
          'display': 'inline-block',
          'vertical-align': '-0.125em',
        },
        'width': '${size / kRemDivisor}rem',
        'height': '${size / kRemDivisor}rem',
        'font-size': '${size / kRemDivisor}rem',
        ...?colour.inline,
      },
    ),
  );
}

/// Resolves the effective icon style for a `Icon` (Web).
///
/// Encapsulates the full resolution chain so `co_icon.dart` never
/// reads `coreComponentTheme` or the ambient [IconTheme] directly:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.icon.style
///   → widget.iconStyle
///   (+ nearest IconTheme as size / colour fallback)
/// ```
///
/// Returns the size, color, bundled glyph and unbundled stroke attributes
/// using the
/// ambient [IconTheme] size as the size fallback so the caller does not have
/// to handle `null`. `color` may still be `null` — meaning "inherit
/// `currentColor`". It stays a [CoreColor] rather than a string so a raw
/// colour keeps its value until [iconElementChrome] decides class vs
/// inline.
///
/// `bundled` is the glyph CoUI ships for [icon] ([CoreBundledIcons]) with its
/// Lucide stroke already rewritten to the icon stroke rule
/// (`CoreIconStroke.apply`), so the widget only lays the finished markup
/// into the `<svg>`. It is `null` for an icon outside the bundle, which the
/// widget hands to `<iconify-icon>` instead. The rewrite touches a `lucide:`
/// body only; any other prefix comes back unchanged.
///
/// `size` is the token size, which is also the size the rule that draws a
/// Lucide glyph's stroke (`CoreIconStroke`) is stated against: the rule
/// takes the size before any layout scaling, and Web has no scaling step
/// between the style and the box (it is `size / 16` rem), so the two are the
/// same number here.
///
/// Colour asymmetry vs Flutter (intentional, value-preserving): with no
/// override and no ambient colour the Web resolver leaves `color` null so
/// the `<iconify-icon>` inherits `currentColor` from the CSS cascade — the
/// platform-native colour-inheritance mechanism. It does
/// **not** force [CoreIconStyle.defaultColor] (the Flutter `onSurface`
/// fallback): hard-coding `text-on-surface` would override colour
/// inheritance for icons composed inside coloured parents
/// (button / chip / label / …). The cascade converges on `onSurface`
/// at the document root, so the two platforms still match.
({
  double size,
  CoreColor? color,
  IconSvgData? bundled,
  Map<String, String> strokeAttributes,
})
resolveIconStyle(
  BuildContext context, {
  required IconName icon,
  required CoreIconStyle? widgetStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.icon;
  final ambient = IconTheme.maybeOf(context);

  final merged = (coreTheme?.style ?? const CoreIconStyle()).merge(widgetStyle);

  final size = merged.size ?? ambient?.size ?? CoreIconStyle.defaultSize;
  final color = merged.color ?? ambient?.color;

  final glyph = CoreBundledIcons.icons[icon.id];
  final bundled = glyph == null
      ? null
      : IconSvgData(
          body: CoreIconStroke.apply(
            prefix: icon.prefix,
            body: glyph.body,
            tokenSize: size,
            viewBox: glyph.width,
          ),
          width: glyph.width,
          height: glyph.height,
        );

  return (
    size: size,
    color: color,
    bundled: bundled,
    // Unit-viewBox ratio: the external adapter multiplies by the canonical
    // glyph's actual grid, then writes the same four-decimal SVG number.
    strokeAttributes: {
      'prefix': icon.prefix,
      if (size.isFinite && size > 0)
        'ratio': CoreIconStroke.svgStrokeWidth(size, viewBox: 1).toString(),
    },
  );
}
