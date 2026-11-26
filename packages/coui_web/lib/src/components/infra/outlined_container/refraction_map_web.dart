/// Web implementation of [SurfaceRefractionRuntime].
///
/// Builds the displacement map a surface's edge bending needs, wires it
/// into an SVG filter, and points the surface's `backdrop-filter` at it.
/// A `ResizeObserver` rebuilds the map when the surface's box changes,
/// because the map is computed from that box — as it is laid out, whatever
/// transform it is drawn through.
///
/// ## Two things here are load-bearing and easy to get wrong
///
/// **The filter is appended to whatever the stylesheet already put on the
/// surface, never substituted for it.** Substituting removes the Tier 1
/// blur, and the difference that follows is mostly the blur leaving — a
/// large, confident number containing no displacement at all.
///
/// **The map's neutral value is 128, not 0.** `feDisplacementMap` reads a
/// channel and subtracts a half, so a map of zeroes shifts every pixel by
/// half the scale. A surface built on that bends everywhere, including the
/// flat interior it is supposed to leave alone.
library;

import 'dart:js_interop';
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:web/web.dart' as web;

/// Whether this browser draws an SVG filter named in `backdrop-filter`.
///
/// Blink does. WebKit accepts `url(#filter)` in the list — the query below is
/// true there — and then draws nothing for a list that names a filter: a
/// surface keeps the layer it was first drawn with while the reference is
/// appended to it, and is a tinted rectangle once the browser builds the layer
/// again (hidden and shown, or its node inserted again). The user agent
/// decides, from the one answer Core states and Flutter Web reads as well; the
/// query only confirms that this Blink still accepts the value.
final bool _rendersSvgBackdrop =
    surfaceRefractionBrowserSupported(web.window.navigator.userAgent) &&
    web.CSS.supports('backdrop-filter', 'url("#coui-refraction-probe")');

/// Whether a surface here may be bent at all.
///
/// Where it may not, the surface keeps the material its stylesheet states —
/// the blur, the lift and the rim — and nothing is appended to it.
bool get webSurfaceRefractionSupported => _rendersSvgBackdrop;

/// Generated maps, keyed by the geometry they were generated for.
///
/// Shared across surfaces on purpose — two panels of the same size and
/// bezel need the same map, and generating it twice costs a canvas
/// readback each time. The key carries every input the generator reads;
/// leaving one out would answer with a map built for different geometry.
final Map<String, String> _mapCache = {};

/// Drives one surface's refraction.
class SurfaceRefractionRuntime {
  /// Creates a runtime bound to the element carrying [elementId].
  SurfaceRefractionRuntime({required this.elementId});

  /// The id of the surface this attaches to.
  final String elementId;

  web.ResizeObserver? _observer;
  web.Element? _filterHost;
  String? _baseFilter;
  CoreSurfaceRefraction? _refraction;
  CoreSurfaceEdgeBevel? _rim;
  CoreSurfaceEdgeBevel? _rimInDarkMode;
  bool _hasFilterBinding = false;
  bool _hasRimBinding = false;
  bool _hasRimDarkBinding = false;

  String get _filterId => refractionFilterId(elementId);

  /// Attaches what depends on the element's own rectangle — the bending,
  /// when [refraction] is stated, and the rim's sweep, when [rim] draws
  /// one — and keeps both in step with its size.
  ///
  /// Both ride one observer because both are functions of the same
  /// measurement; two observers would be two chances to read a stale
  /// rectangle on the same frame.
  ///
  /// [rimInDarkMode] is the same rim lit from the direction the dark palette
  /// states, when that is another. This cannot re-measure when the palette
  /// changes — a theme switch writes an attribute and rebuilds nothing — so
  /// both sweeps are written once and the stylesheet's dark rules pick. A
  /// second light beside no first means nothing and is ignored.
  void attach(
    CoreSurfaceRefraction? refraction, {
    CoreSurfaceEdgeBevel? rim,
    CoreSurfaceEdgeBevel? rimInDarkMode,
  }) {
    final element = web.document.getElementById(elementId);
    if (element == null) return;

    // A browser that cannot draw the filter is not asked to: appending the
    // reference there would take the surface's own blur with it.
    _refraction = webSurfaceRefractionSupported ? refraction : null;
    _rim = rim != null && rim.drawsRim ? rim : null;
    _rimInDarkMode = _rim != null && (rimInDarkMode?.drawsRim ?? false)
        ? rimInDarkMode
        : null;
    if (_refraction == null && _rim == null) return;

    if (_refraction != null) {
      // Read once. Reading it again after we have written to it would fold
      // our own filter into the base and stack a second copy on every
      // resize.
      //
      // A panel that is fading states its list in a custom property
      // ([kWebSurfacePassVar]), and `backdrop-filter` reads it from there. The
      // list it computes to *now* is the list at this point of the fade — a
      // blur of nothing, when the panel has only just appeared — and written
      // inline it would outrank the stylesheet for good, so the surface would
      // stay at that blur for as long as it is open. The reference is the
      // list itself, and moves with the fade. A caller who states a filter of
      // their own on the element keeps it, as they always did: it outranks
      // the stylesheet, and is the base.
      final computed = web.window.getComputedStyle(element);
      final statesOwn = (element as web.HTMLElement).style
          .getPropertyValue('backdrop-filter')
          .isNotEmpty;
      final fades =
          !statesOwn &&
          computed.getPropertyValue(kWebSurfacePassVar).trim().isNotEmpty;
      _baseFilter ??= fades
          ? 'var($kWebSurfacePassVar)'
          : computed.getPropertyValue('backdrop-filter');
    }
    _apply(element);

    _observer = web.ResizeObserver(
      (JSAny entries, JSAny observer) {
        final current = web.document.getElementById(elementId);
        if (current != null) _apply(current);
      }.toJS,
    )..observe(element);
  }

  /// Detaches and removes what it added. Idempotent.
  void dispose() {
    _observer?.disconnect();
    _observer = null;
    _filterHost?.remove();
    _filterHost = null;

    final hadFilter = _hasFilterBinding;
    final hadRim = _hasRimBinding;
    final hadRimDark = _hasRimDarkBinding;
    _hasFilterBinding = false;
    _hasRimBinding = false;
    _hasRimDarkBinding = false;
    final element = web.document.getElementById(elementId);
    if (element == null) return;

    final style = (element as web.HTMLElement).style;
    if (hadRim) style.removeProperty(kWebSurfaceRimSweepVar);
    if (hadRimDark) style.removeProperty(kWebSurfaceRimSweepDarkVar);
    final base = _baseFilter;
    if (hadFilter && base != null) style.setProperty('backdrop-filter', base);
  }

  void _ensureFilterHost() {
    if (_filterHost != null) return;

    final svg =
        web.document.createElementNS('http://www.w3.org/2000/svg', 'svg')
          ..setAttribute('width', '0')
          ..setAttribute('height', '0')
          ..setAttribute('aria-hidden', 'true')
          ..setAttribute('style', 'position:absolute');
    web.document.body?.append(svg);
    _filterHost = svg;
  }

  void _apply(web.Element element) {
    // The box as it is laid out, not as it is drawn. The filter runs in the
    // surface's own coordinate space, so a transform on the surface or above
    // it — a press swell, a compact scale, an opening motion — changes what
    // the surface covers on screen and nothing about the map it needs. Read
    // off the drawn rectangle, a surface resized while it is drawn smaller
    // gets a map that stops short of its far edges.
    final box = element as web.HTMLElement;
    final width = box.offsetWidth;
    final height = box.offsetHeight;
    if (width <= 0 || height <= 0) return;

    final radius = _radiusOf(element);

    final rim = _rim;
    if (rim != null) {
      _hasRimBinding = true;
      // The stops are Core's for this exact box — the same call the Flutter
      // painter makes with the same three numbers.
      String sweepOf(CoreSurfaceEdgeBevel lit) => surfaceEdgeRimSweepCss(
        lit,
        width: width.toDouble(),
        height: height.toDouble(),
        radius: radius,
      );
      final style = box.style
        ..setProperty(kWebSurfaceRimSweepVar, sweepOf(rim));
      final dark = _rimInDarkMode;
      if (dark != null) {
        _hasRimDarkBinding = true;
        style.setProperty(kWebSurfaceRimSweepDarkVar, sweepOf(dark));
      }
    }

    final refraction = _refraction;
    // Hidden/unmeasured surfaces wait on ResizeObserver without creating an
    // empty SVG host whose mutation would schedule another attachment.
    if (refraction != null) _ensureFilterHost();
    final host = _filterHost;
    if (refraction == null || host == null) return;

    final band = (width < height ? width : height) * refraction.bezel;
    final peak = refraction.peakDisplacement(bandPx: band);
    // Every input the generator reads. A key missing one answers with a map
    // built for different optics, and the surface bends by the wrong amount
    // with nothing in the output to say why.
    final key = refractionMapKey(
      width: width,
      height: height,
      radius: radius,
      refraction: refraction,
    );
    final map = _mapCache[key] ??= _buildMap(
      width: width,
      height: height,
      radius: radius,
      refraction: refraction,
    );
    // The dome, as its own map: a function of the box alone, so two
    // surfaces of one size share it whatever their corners.
    final corner = math.sqrt(
      ((width * width) + (height * height)) / 4,
    );
    final lensPeak = refraction.lensPeak(cornerPx: corner);
    final lensMap = lensPeak <= 0
        ? null
        : _mapCache[lensMapKey(
            width: width,
            height: height,
            refraction: refraction,
          )] ??= _buildLensMap(
            width: width,
            height: height,
            refraction: refraction,
          );

    host.innerHTML = buildRefractionFilterMarkup(
      filterId: _filterId,
      map: map,
      width: width,
      height: height,
      peak: peak,
      dispersion: refraction.dispersion,
      lensMap: lensMap,
      lensPeak: lensPeak,
    ).toJS;

    // Appended, never substituted — see the note at the top of this file.
    final base = _baseFilter ?? '';
    final next = base.isEmpty ? 'url(#$_filterId)' : '$base url(#$_filterId)';
    box.style.setProperty('backdrop-filter', next);
    _hasFilterBinding = true;
  }

  double _radiusOf(web.Element element) {
    final raw = web.window
        .getComputedStyle(element)
        .getPropertyValue('border-top-left-radius');

    return double.tryParse(raw.replaceAll('px', '').trim()) ?? 0;
  }

  /// Signed-distance field of the surface's rounded rectangle, with each
  /// pixel's displacement written into R and G as a ratio of the peak.
  ///
  /// The optics are not decided here. `displacementAt` is Core's, and the
  /// Flutter shader mirrors the same arithmetic — this file only turns the
  /// result into a texture a browser filter can read.
  String _buildMap({
    required int width,
    required int height,
    required double radius,
    required CoreSurfaceRefraction refraction,
  }) {
    final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement
      ..width = width
      ..height = height;
    final context = canvas.context2D;
    final image = context.createImageData(width.toJS, height).data.toDart
      ..setAll(
        0,
        surfaceRefractionDisplacementMap(
          width: width,
          height: height,
          radius: radius,
          refraction: refraction,
        ),
      );

    context.putImageData(
      web.ImageData(image.toJS, width),
      0,
      0,
    );

    return canvas.toDataURL('image/png');
  }

  /// The dome's displacement, per axis, as a ratio of [refraction]'s lens
  /// peak on this box.
  ///
  /// `lensDisplacement` is Core's and the Flutter shader mirrors its one
  /// line; this only lays it out as a texture. Per axis in R and G, so the
  /// filter scales a sample's *x* and *y* toward the centre by the same
  /// fraction — a uniform magnification with no seam.
  String _buildLensMap({
    required int width,
    required int height,
    required CoreSurfaceRefraction refraction,
  }) {
    final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement
      ..width = width
      ..height = height;
    final context = canvas.context2D;
    final image = context.createImageData(width.toJS, height).data.toDart
      ..setAll(
        0,
        surfaceRefractionDisplacementMap(
          width: width,
          height: height,
          radius: 0,
          refraction: refraction,
          lens: true,
        ),
      );

    context.putImageData(
      web.ImageData(image.toJS, width),
      0,
      0,
    );

    return canvas.toDataURL('image/png');
  }
}

/// Whether anything has been generated yet — read by the cache test.
int get refractionMapCacheSize => _mapCache.length;

/// Empties the cache. For tests that need a known starting point.
void resetRefractionMapCache() => _mapCache.clear();
