/// The SVG a refracting surface's `backdrop-filter` points at.
///
/// Split out from the runtime that builds the map because this half is a
/// pure function of five numbers and a data URI — no DOM, no canvas, no
/// `dart:js_interop`. The runtime beside it is none of those things and
/// cannot be loaded off the browser at all, so anything left in there is
/// unreachable from a test.
///
/// That mattered immediately. The channel-splitting matrices below had a
/// bug that turned every glass surface on the page bright green, and it was
/// found by looking at a screenshot rather than by anything that could have
/// failed.
library;

import 'package:coui_core/src/surface/surface_refraction.dart';

/// An 8-bit PNG's neutral 128/255 is slightly above SVG's exact 0.5.
/// Cancel its sampling offset so changing bezel/strength does not translate
/// the flat interior. Colour-transfer corrections alone quantize back to 128
/// in 8-bit filter intermediates. Native floating-point shaders have no bias.
const double kSurfaceRefractionMapNeutralBias = 1 / 510;

String _neutralOffset(double scale, String result) =>
    '<feOffset in="$result" '
    'dx="${scale * kSurfaceRefractionMapNeutralBias}" '
    'dy="${scale * kSurfaceRefractionMapNeutralBias}" result="$result"/>';

/// Builds the filter for one surface.
///
/// [map] is the displacement image as a data URI. [peak] is the largest
/// displacement that image encodes, in pixels: each channel holds a *ratio*
/// of it, which is what lets one baked map serve three passes at different
/// strengths — the whole dispersion mechanism here.
///
/// Without dispersion this is a single displacement pass. With it, the same
/// map is applied three times a little further apart and one channel is kept
/// from each, because short wavelengths bend further through glass than long
/// ones and that separation is what fringes a thick edge.
///
/// [lensMap] is the dome's displacement image and [lensPeak] the largest
/// displacement *it* encodes. When there is one, it runs first as its own
/// pass over the source, and the band's passes read from that result rather
/// than from the source — so a rim-shifted sample lands in the lensed image
/// at its shifted place. The Flutter shader reads in the same order, and
/// the parity test pins its transcription of it. The lens never disperses:
/// it is one image on both platforms, and only the rim's travel spreads.
String buildRefractionFilterMarkup({
  required String filterId,
  required String map,
  required int width,
  required int height,
  required double peak,
  required double dispersion,
  String? lensMap,
  double lensPeak = 0,
}) {
  // The map's encoding uses half the channel range on each side of neutral,
  // so the scale is twice the peak it has to reproduce.
  final scale = peak * 2;
  final buffer = StringBuffer()
    ..write(
      '<filter id="$filterId" x="0%" y="0%" width="100%" height="100%" '
      'filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" '
      'color-interpolation-filters="sRGB">',
    )
    ..write(
      '<feImage href="$map" preserveAspectRatio="none" result="map" '
      'x="0" y="0" width="$width" height="$height"/>',
    );

  var source = 'SourceGraphic';
  if (lensMap != null && lensPeak > 0) {
    buffer
      ..write(
        '<feImage href="$lensMap" preserveAspectRatio="none" result="lens" '
        'x="0" y="0" width="$width" height="$height"/>',
      )
      ..write(
        '<feDisplacementMap in="SourceGraphic" in2="lens" '
        'scale="${lensPeak * 2}" '
        'xChannelSelector="R" yChannelSelector="G" result="lensed"/>',
      )
      ..write(_neutralOffset(lensPeak * 2, 'lensed'));
    source = 'lensed';
  }

  if (dispersion <= 0) {
    buffer
      ..write(
        '<feDisplacementMap in="$source" in2="map" scale="$scale" '
        'xChannelSelector="R" yChannelSelector="G" result="band"/>',
      )
      ..write(_neutralOffset(scale, 'band'))
      ..write('</filter>');

    return buffer.toString();
  }

  // Blue travels most and red least, which is the order of their wavelengths.
  const unit = CoreSurfaceRefraction.dispersionUnit;
  const spread = [1 + unit, 1.0, 1 - unit];
  for (var i = 0; i < 3; i++) {
    final factor = 1 + ((spread[i] - 1) * dispersion);
    buffer
      ..write(
        '<feDisplacementMap in="$source" in2="map" '
        'scale="${scale * factor}" '
        'xChannelSelector="R" yChannelSelector="G" result="d$i"/>',
      )
      ..write(_neutralOffset(scale * factor, 'd$i'))
      // Keep this pass' own channel, drop the other two, and force alpha
      // to one.
      //
      // The alpha is the part that is not obvious. Filter results are
      // *premultiplied*, so an intermediate with alpha zero has had its
      // colour multiplied away — the channel this pass exists to contribute
      // is gone before the sum below ever sees it. Measured: zeroing alpha
      // on the red and blue passes left only the green one with any colour,
      // and every glass surface on the page rendered bright green.
      //
      // One is the right constant rather than a workaround: the input here
      // is a backdrop, which is opaque by construction. A filter fed
      // something translucent would have to carry the alpha instead.
      ..write(
        '<feColorMatrix in="d$i" type="matrix" result="c$i" values="'
        '${i == 0 ? '1 0 0 0 0' : '0 0 0 0 0'} '
        '${i == 1 ? '0 1 0 0 0' : '0 0 0 0 0'} '
        '${i == 2 ? '0 0 1 0 0' : '0 0 0 0 0'} '
        '0 0 0 0 1"/>',
      );
  }

  // Summed, not composited. `feComposite` with `arithmetic` and both terms
  // at one is the only operator that *adds* two results; every other one
  // combines them by alpha, and the last pass would cover the first two.
  buffer
    ..write(
      '<feComposite in="c0" in2="c1" operator="arithmetic" '
      'k1="0" k2="1" k3="1" k4="0" result="rg"/>',
    )
    ..write(
      '<feComposite in="rg" in2="c2" operator="arithmetic" '
      'k1="0" k2="1" k3="1" k4="0"/>',
    )
    ..write('</filter>');

  return buffer.toString();
}

/// What every refraction filter id starts with.
///
/// Its own name because something other than the runtime has to recognise a
/// refraction in a `backdrop-filter` list: the document-level host asks
/// whether a surface already carries one before it attaches a second, and
/// "carries any `url()`" is not that question, because the stylesheet puts
/// filters of its own (the frost, the body shade) in the same list.
const String kRefractionFilterIdPrefix = 'coui-refraction-';

/// The filter element id for the surface carrying [elementId].
///
/// Shared so the runtime that writes the markup and the one that points a
/// `backdrop-filter` at it cannot disagree about the name.
String refractionFilterId(String elementId) =>
    '$kRefractionFilterIdPrefix$elementId';

/// Every input the generated map depends on, as a cache key.
///
/// A key missing one of these answers with a map built for different optics,
/// and the surface bends by the wrong amount with nothing in the output to
/// say why. `dispersion` is deliberately absent: it rides the filter's
/// scales, not the map's pixels. The model is present: two requests that
/// differ in nothing else bake different profiles into the same box.
String refractionMapKey({
  required int width,
  required int height,
  required double radius,
  required CoreSurfaceRefraction refraction,
}) =>
    '$width:$height:$radius:${refraction.bezel}:'
    '${refraction.strength}:${refraction.refractiveIndex}:'
    '${refraction.model.name}';

/// The lens map's cache key. Fewer inputs than the band's, because the
/// dome is a function of the box and the lens alone — no bezel, no corner.
String lensMapKey({
  required int width,
  required int height,
  required CoreSurfaceRefraction refraction,
}) => 'lens:$width:$height:${refraction.lens}';
