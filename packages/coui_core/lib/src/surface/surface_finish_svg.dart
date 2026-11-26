/// The SVG a stylesheet points a glass surface's `backdrop-filter` at to draw
/// the frost and the body shade.
///
/// Split out from the stylesheet that uses it for the reason the refraction
/// filter is: this half is a pure function of a few numbers and a data URI —
/// no DOM, no canvas, no `dart:js_interop` — so a test on any platform can
/// hold the markup to the vectors both seats are tested against.
///
/// ## Why a data URI and not an element in the page
///
/// Neither filter depends on the element it is applied to: the frost mixes a
/// blur of the backdrop with the backdrop, and the shade multiplies each
/// pixel by a function of its own luminance. Nothing about the box enters, so
/// the same document serves every surface and can live in the stylesheet. A
/// filter in the page would need a host element the server render does not
/// have; a reference to a filter that is not there is skipped by Chromium
/// (the rest of the list still draws), which would make a missing host a
/// silent loss of the term. A data URI is carried by the rule that uses it,
/// so the sheet and its filters cannot come apart.
///
/// ## Where the list is drawn
///
/// Only Chromium composites an SVG filter named in `backdrop-filter`. Safari
/// accepts the value and then draws nothing for the whole list, the surface's
/// own blur and saturation included (measured in Safari 27.0: `blur(10px)
/// saturate(2)` changes every pixel of a pane, the same list with either
/// document named in it changes none). Left in the list there, the frost and
/// the shade would cost the glass its blur, so the stylesheet takes the two
/// terms out of the list for such a browser — for WebKit from the first paint
/// by a feature query, for the others once the browser build has said which
/// browser it is — and the glass keeps the blur, the saturation and the
/// brightness the list has without them. The two terms are drawn by Chromium
/// only.
library;

import 'package:coui_core/src/surface/surface_body_shade.dart';

/// The id of the one filter in each document, which is the fragment the URL
/// ends in.
const String _kFilterId = 'f';

/// The opening of the one filter in each document: the whole box, in sRGB.
const String _kFilterOpen =
    '<filter id="$_kFilterId" x="0%" y="0%" width="100%" '
    'height="100%" color-interpolation-filters="sRGB">';

/// A number, with no more digits than the filters can tell apart and no
/// trailing zeros.
///
/// 8-bit intermediates cannot hold more than four decimals of anything, and
/// a shorter string is a shorter stylesheet: the document is repeated in
/// every rule that states it.
String _number(double value) {
  final text = value.toStringAsFixed(4);
  if (!text.contains('.')) return text;
  var end = text.length;
  while (text[end - 1] == '0') {
    end--;
  }
  if (text[end - 1] == '.') end--;

  return text.substring(0, end);
}

/// The frost: [sigma] is the cloud's Gaussian, [opacity] the share of the
/// cloud over the backdrop the list has built so far.
///
/// `SourceGraphic` is the backdrop at this point of the `backdrop-filter`
/// list, so the cloud is blurred from whatever precedes it and mixed back
/// over the same pixels: `opacity · cloud + (1 − opacity) · source`, the
/// `arithmetic` composite with `k2 = opacity` and `k3 = 1 − opacity`.
///
/// `color-interpolation-filters="sRGB"` is load-bearing and is the default's
/// opposite: the default, `linearRGB`, converts the backdrop to linear light
/// before the filter's arithmetic, while the Flutter pass blends the sRGB
/// values as stored. Both filters state the colour space they mean; for the
/// body shade the difference was measured, and white lands 36 levels higher
/// in linear light than the formula says.
String surfaceFrostFilterMarkup({
  required double sigma,
  required double opacity,
}) => [
  '<svg xmlns="http://www.w3.org/2000/svg">',
  _kFilterOpen,
  '<feGaussianBlur in="SourceGraphic" stdDeviation="${_number(sigma)}" ',
  'result="cloud"/>',
  '<feComposite in="cloud" in2="SourceGraphic" operator="arithmetic" ',
  'k1="0" k2="${_number(opacity)}" k3="${_number(1 - opacity)}" k4="0"/>',
  '</filter></svg>',
].join();

/// The body shade: every pixel multiplied by `1 − strength · luma²`.
///
/// A luminance image (the weights `CoreSurfaceBodyShade` states, copied to all
/// three channels), squared and scaled by a gamma transfer
/// (`amplitude · luma² + offset` with a negative amplitude), and multiplied
/// into the source by the `arithmetic` composite with only `k1` set.
///
/// The alpha row of the luminance matrix passes alpha through, so a
/// translucent backdrop stays as translucent as it was; the backdrop is
/// opaque in practice and the factor image then has alpha 1 everywhere.
String surfaceBodyShadeFilterMarkup({required double strength}) {
  final row =
      '${_number(CoreSurfaceBodyShade.lumaRed)} '
      '${_number(CoreSurfaceBodyShade.lumaGreen)} '
      '${_number(CoreSurfaceBodyShade.lumaBlue)} 0 0';
  final transfer =
      'type="gamma" amplitude="${_number(-strength)}" exponent="2" offset="1"';

  return [
    '<svg xmlns="http://www.w3.org/2000/svg">',
    _kFilterOpen,
    '<feColorMatrix in="SourceGraphic" type="matrix" ',
    'values="$row $row $row 0 0 0 1 0" result="luma"/>',
    '<feComponentTransfer in="luma" result="factor">',
    '<feFuncR $transfer/><feFuncG $transfer/><feFuncB $transfer/>',
    '</feComponentTransfer>',
    '<feComposite in="SourceGraphic" in2="factor" operator="arithmetic" ',
    'k1="1" k2="0" k3="0" k4="0"/>',
    '</filter></svg>',
  ].join();
}

/// [markup] as a CSS `url()` a `backdrop-filter` list can hold.
///
/// Percent-encoded down to the unreserved set, which keeps the three
/// characters that would otherwise end the value early out of it: `"` closes
/// the CSS string, `'` closes the JavaScript string the stylesheet is
/// injected through (an unescaped single-quoted literal — one stray quote
/// takes the whole injection down), and `#` would start the fragment too
/// soon. The fragment that names the filter is appended after the encoding.
String surfaceFinishFilterUrl(String markup) {
  final encoded = StringBuffer();
  for (final unit in markup.codeUnits) {
    final unreserved =
        (unit >= 0x30 && unit <= 0x39) ||
        (unit >= 0x41 && unit <= 0x5A) ||
        (unit >= 0x61 && unit <= 0x7A) ||
        unit == 0x2D ||
        unit == 0x2E ||
        unit == 0x5F ||
        unit == 0x7E;
    if (unreserved) {
      encoded.writeCharCode(unit);
    } else {
      encoded
        ..write('%')
        ..write(unit.toRadixString(16).toUpperCase().padLeft(2, '0'));
    }
  }

  return 'url("data:image/svg+xml,$encoded#$_kFilterId")';
}
