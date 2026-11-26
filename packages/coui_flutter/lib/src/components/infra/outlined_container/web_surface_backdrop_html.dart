import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

// A CSS parser accepting url() is not proof of backdrop displacement: Safari
// and Firefox accept it but fail the shipped optical pixel probes. Keep their
// Flutter material until their compositor can pass the same probes. Chromium
// derivatives use the measured path (iOS Chrome uses WebKit, not Chromium).
// Which user agents those are is Core's one answer, which the Jaspr components
// read as well.
final bool _supported =
    surfaceRefractionBrowserSupported(web.window.navigator.userAgent) &&
    web.CSS.supports('backdrop-filter', 'url("#coui-refraction-probe")');

/// Whether this browser has the SVG backdrop compositor verified by CoUI.
bool get webSurfaceRefractionSupported => _supported;

int _nextId = 0;
const _kMapCacheCapacity = 64;
final _maps = LinkedHashMap<String, String>();

String _map({
  required String key,
  required int width,
  required int height,
  required double radius,
  required CoreSurfaceRefraction refraction,
  bool lens = false,
}) {
  final cached = _maps.remove(key);
  if (cached != null) {
    _maps[key] = cached;
    return cached;
  }
  final canvas = web.HTMLCanvasElement()
    ..width = width
    ..height = height;
  final context = canvas.context2D;
  final image = context.createImageData(width.toJS, height);
  image.data.toDart.setAll(
    0,
    surfaceRefractionDisplacementMap(
      width: width,
      height: height,
      radius: radius,
      refraction: refraction,
      lens: lens,
    ),
  );
  context.putImageData(image, 0, 0);
  final result = canvas.toDataURL('image/png');
  if (_maps.length >= _kMapCacheCapacity) _maps.remove(_maps.keys.first);
  _maps[key] = result;
  return result;
}

/// Samples the already composited Flutter canvas through a transparent HTML
/// platform view. Flutter owns placement, transforms and clipping; the browser
/// owns backdrop sampling. No screenshot, texture readback or second clock is
/// needed as a lens moves. The child remains Flutter content above the filter.
class WebSurfaceBackdrop extends StatefulWidget {
  const WebSurfaceBackdrop({
    required this.refraction,
    required this.borderRadius,
    required this.child,
    this.background,
    this.blur = 0,
    this.saturation = 1,
    this.brightness = 1,
    this.activation = 1,
    this.mapSize,
    super.key,
  });

  final CoreSurfaceRefraction refraction;
  final BorderRadius borderRadius;
  final Widget child;

  /// Flutter paints the material before the browser samples its refraction.
  /// It also preserves blur if a future engine cannot expose the anchor.
  final Widget? background;

  /// The browser uses the same material chain as DOM Web once composed.
  final double blur;
  final double saturation;
  final double brightness;
  final double activation;

  /// Stable base geometry for a deforming lens. Only primitive extents and
  /// displacement amplitudes change per frame; its maps are not regenerated.
  final Size? mapSize;

  @override
  State<WebSurfaceBackdrop> createState() => _WebSurfaceBackdropState();
}

class _WebSurfaceBackdropState extends State<WebSurfaceBackdrop> {
  final _id = 'coui-flutter-glass-${_nextId++}';
  web.HTMLElement? _element;
  web.HTMLElement? _projection;
  web.Element? _host;
  web.Element? _clipHost;
  web.MutationObserver? _sceneObserver;
  web.ResizeObserver? _resizeObserver;
  web.Node? _observedRoot;
  String? _clipGeometry;
  String? _geometry;
  Size _size = Size.zero;
  Size _paintSize = Size.zero;
  bool _disposed = false;
  bool _ready = false;
  bool _wantedReady = false;
  final _passes = <(web.Element, double, double)>[];
  final _images = <web.Element>[];
  Set<web.Node> _ancestors = {};

  void _clear() {
    _sceneObserver?.disconnect();
    _sceneObserver = null;
    _resizeObserver?.disconnect();
    _resizeObserver = null;
    _observedRoot = null;
    _projection?.remove();
    _projection = null;
    _host?.remove();
    _host = null;
    _clipHost?.remove();
    _clipHost = null;
    _clipGeometry = null;
    _paintSize = Size.zero;
    _element = null;
    _geometry = null;
    _passes.clear();
    _images.clear();
    _ancestors = {};
    _ready = false;
    _wantedReady = false;
  }

  void _handleElementCreated(Object object) {
    if (_disposed) return;
    final element = _element = object as web.HTMLElement;
    element.setAttribute('aria-hidden', 'true');
    element.setAttribute('data-coui-flutter-refraction-anchor', _id);
    element.style.cssText =
        'width:100%;height:100%;pointer-events:none;background:transparent;';
    final projection = _projection = web.HTMLDivElement();
    projection.setAttribute('aria-hidden', 'true');
    projection.setAttribute('data-coui-flutter-refraction', _id);
    projection.style.cssText =
        'position:absolute;pointer-events:none;background:transparent;';
    _resizeObserver = web.ResizeObserver(
      ((JSAny entries, JSAny observer) => _project()).toJS,
    )..observe(element);
    _sync();
    _project();
  }

  void _sync() {
    final element = _projection;
    final size = _paintSize.isEmpty ? _size : _paintSize;
    if (element == null || size.isEmpty) return;
    final base = widget.mapSize ?? _size;
    final width = math.max(1, base.width.round());
    final height = math.max(1, base.height.round());
    final radius = math.min(
      widget.borderRadius.topLeft.x,
      math.min(width, height) / 2,
    );
    final profile = widget.refraction;
    final key = refractionMapKey(
      width: width,
      height: height,
      radius: radius,
      refraction: profile,
    );
    final lensKey = lensMapKey(
      width: width,
      height: height,
      refraction: profile,
    );
    if (_geometry != '$key:$lensKey:${profile.dispersion}') {
      _geometry = '$key:$lensKey:${profile.dispersion}';
      final host = _host ??=
          web.document.createElementNS(
              'http://www.w3.org/2000/svg',
              'svg',
            )
            ..setAttribute('width', '0')
            ..setAttribute('height', '0')
            ..setAttribute('aria-hidden', 'true')
            ..setAttribute('data-coui-flutter-refraction-resource', _id)
            ..setAttribute('style', 'position:absolute;pointer-events:none');
      final corner = math.sqrt((width * width + height * height) / 4);
      host.innerHTML = buildRefractionFilterMarkup(
        filterId: refractionFilterId(_id),
        map: _map(
          key: key,
          width: width,
          height: height,
          radius: radius,
          refraction: profile,
        ),
        width: width,
        height: height,
        peak: profile.peakDisplacement(
          bandPx: math.min(width, height) * profile.bezel,
        ),
        dispersion: profile.dispersion,
        lensMap: profile.lens <= 0
            ? null
            : _map(
                key: lensKey,
                width: width,
                height: height,
                radius: 0,
                refraction: profile,
                lens: true,
              ),
        lensPeak: profile.lensPeak(cornerPx: corner),
      ).toJS;
      _images.clear();
      final images = host.querySelectorAll('feImage');
      for (var i = 0; i < images.length; i++) {
        _images.add(images.item(i)! as web.Element);
      }
      _passes.clear();
      final passes = host.querySelectorAll('feDisplacementMap');
      for (var i = 0; i < passes.length; i++) {
        final node = passes.item(i)! as web.Element;
        final result = node.getAttribute('result') ?? '';
        final channel = result.length == 2 && result.startsWith('d')
            ? int.tryParse(result.substring(1))
            : null;
        final spread = channel == null
            ? 0.0
            : (1 - channel) *
                  CoreSurfaceRefraction.dispersionUnit *
                  profile.dispersion;
        _passes.add((
          node,
          double.parse(node.getAttribute('scale')!) / (1 + spread),
          spread,
        ));
      }
    }

    for (final image in _images) {
      image.setAttribute('width', '${size.width}');
      image.setAttribute('height', '${size.height}');
    }
    final activation = widget.activation.clamp(0.0, 1.0);
    final growth = math.min(size.width, size.height) / math.min(width, height);
    for (final (node, peak, spread) in _passes) {
      final scale = peak * growth * activation * (1 + spread * activation);
      node.setAttribute(
        'scale',
        '$scale',
      );
      final correction = node.nextElementSibling;
      if (correction?.tagName == 'feOffset') {
        final offset = scale * kSurfaceRefractionMapNeutralBias;
        correction!
          ..setAttribute('dx', '$offset')
          ..setAttribute('dy', '$offset');
      }
    }
    final materialScale = size.shortestSide / _size.shortestSide;
    final material = [
      if (_ready && widget.blur > 0) 'blur(${widget.blur * materialScale}px)',
      if (_ready && widget.saturation != 1) 'saturate(${widget.saturation})',
      if (_ready && widget.brightness != 1) 'brightness(${widget.brightness})',
      'url("#${refractionFilterId(_id)}")',
    ].join(' ');
    element.style
      ..width = '${size.width}px'
      ..height = '${size.height}px'
      ..setProperty('backdrop-filter', material);
  }

  void _handleReady(bool value) {
    if (_wantedReady == value) return;
    _wantedReady = value;
    // DOM projection is resolved after the engine commits its scene. Switch
    // the material owner in the next Flutter frame: browser material + optics
    // together, or the existing Flutter blur when projection is unavailable.
    scheduleMicrotask(() {
      if (mounted && _ready != _wantedReady) {
        setState(() => _ready = _wantedReady);
      }
    });
  }

  /// A platform view's ancestor clip-path establishes a CSS backdrop root.
  /// Sampling inside that root sees transparent black, not Flutter's canvas.
  /// Keep the view as an engine-owned placement anchor, then put our optical
  /// plane beside its outer mutator, at the same paint position in the scene.
  /// Reapply all clips on the plane itself, where they cannot block sampling.
  /// No engine node or style is changed. Its DOM commit triggers this observer
  /// before browser paint, so scrolling/retained layers need no extra ticker.
  void _project() {
    final anchor = _element;
    final plane = _projection;
    if (_disposed || anchor == null || plane == null) return;
    web.Node? current = anchor;
    web.Element? sibling;
    web.HTMLElement? scene;
    final clips = <web.HTMLElement>[];
    final ancestors = <web.Node>{};
    var opacity = 1.0;
    while (current != null) {
      ancestors.add(current);
      if (current.isA<web.HTMLElement>()) {
        final element = current as web.HTMLElement;
        if (element.tagName == 'FLT-SCENE') {
          scene = element;
          break;
        }
        sibling = element;
        final style = web.window.getComputedStyle(element);
        opacity *= double.tryParse(style.opacity) ?? 1;
        if (style.clipPath != 'none') clips.add(element);
      }
      final element = current.isA<web.Element>()
          ? current as web.Element
          : null;
      current = element?.assignedSlot ?? current.parentNode;
    }
    _ancestors = ancestors;
    if (scene == null || sibling == null || !anchor.isConnected) {
      plane.style.visibility = 'hidden';
      _handleReady(false);
      return;
    }
    final root = scene.getRootNode();
    if (_observedRoot != root) {
      _sceneObserver?.disconnect();
      _observedRoot = root;
      _sceneObserver =
          web.MutationObserver(
            ((
                  JSArray<web.MutationRecord> records,
                  web.MutationObserver observer,
                ) {
                  final relevant = records.toDart.any((record) {
                    if (_opticalNode(record.target)) return false;
                    if (record.type != 'childList') {
                      return _ancestors.contains(record.target);
                    }
                    for (var i = 0; i < record.addedNodes.length; i++) {
                      if (!_opticalNode(record.addedNodes.item(i)!))
                        return true;
                    }
                    for (var i = 0; i < record.removedNodes.length; i++) {
                      if (!_opticalNode(record.removedNodes.item(i)!))
                        return true;
                    }
                    return false;
                  });
                  if (relevant) _project();
                })
                .toJS,
          )..observe(
            root,
            web.MutationObserverInit(
              childList: true,
              attributes: true,
              attributeFilter: ['style'.toJS].toJS,
              subtree: true,
            ),
          );
    }
    final rect = anchor.getBoundingClientRect();
    final origin = scene.getBoundingClientRect();
    final sceneScaleX = scene.clientWidth > 0
        ? origin.width / scene.clientWidth
        : 1.0;
    final sceneScaleY = scene.clientHeight > 0
        ? origin.height / scene.clientHeight
        : 1.0;
    final left = (rect.left - origin.left) / sceneScaleX;
    final top = (rect.top - origin.top) / sceneScaleY;
    if (rect.width <= 0 || rect.height <= 0) {
      plane.style.visibility = 'hidden';
      _handleReady(false);
      return;
    }
    _paintSize = Size(rect.width / sceneScaleX, rect.height / sceneScaleY);
    _sync();
    final scaleX = _paintSize.width / _size.width;
    final scaleY = _paintSize.height / _size.height;
    final corners = widget.borderRadius;
    final ownRadius =
        '${corners.topLeft.x}px ${corners.topRight.x}px '
        '${corners.bottomRight.x}px ${corners.bottomLeft.x}px / '
        '${corners.topLeft.y}px ${corners.topRight.y}px '
        '${corners.bottomRight.y}px ${corners.bottomLeft.y}px';
    final ownPath = _clipPath(
      'rect(0px ${_size.width}px ${_size.height}px 0px round $ownRadius)',
      0,
      0,
      scaleX: scaleX,
      scaleY: scaleY,
    )!;
    final pathSet = <String>{};
    for (final clip in clips) {
      final style = web.window.getComputedStyle(clip);
      final bounds = clip.getBoundingClientRect();
      final path = _clipPath(
        clip.style.clipPath,
        (rect.left - bounds.left) / sceneScaleX,
        (rect.top - bounds.top) / sceneScaleY,
        scaleX: clip.clientWidth > 0
            ? bounds.width / clip.clientWidth / sceneScaleX
            : 1,
        scaleY: clip.clientHeight > 0
            ? bounds.height / clip.clientHeight / sceneScaleY
            : 1,
        containedSize: _paintSize,
      );
      // Unsupported/perspective clips keep the existing Flutter material.
      // Drawing optics outside the clip would be a visual regression.
      if (path == null || !_axisAligned(style.transform)) {
        plane.style.visibility = 'hidden';
        _handleReady(false);
        return;
      }
      if (path.isNotEmpty && path != ownPath) pathSet.add(path);
    }
    final paths = pathSet.toList();
    // Keep ordinary unclipped panes on CSS's exact rounded-rectangle path,
    // as DOM Web does. Only genuinely intersecting ancestor clips need SVG;
    // repeating the same rounded mask changes its edge antialiasing.
    plane.style.borderRadius =
        '${corners.topLeft.x * scaleX}px ${corners.topRight.x * scaleX}px '
        '${corners.bottomRight.x * scaleX}px ${corners.bottomLeft.x * scaleX}px / '
        '${corners.topLeft.y * scaleY}px ${corners.topRight.y * scaleY}px '
        '${corners.bottomRight.y * scaleY}px ${corners.bottomLeft.y * scaleY}px';
    final geometry = paths.join();
    if (paths.isEmpty) {
      _clipGeometry = geometry;
      _clipHost?.remove();
      _clipHost = null;
      plane.style.clipPath = 'none';
    } else if (_clipGeometry != geometry) {
      _clipGeometry = geometry;
      final host = _clipHost ??=
          web.document.createElementNS(
              'http://www.w3.org/2000/svg',
              'svg',
            )
            ..setAttribute('width', '0')
            ..setAttribute('height', '0')
            ..setAttribute('aria-hidden', 'true')
            ..setAttribute('data-coui-flutter-refraction-resource', _id)
            ..setAttribute('style', 'position:absolute;pointer-events:none');
      final markup = StringBuffer();
      for (var i = 0; i < paths.length; i++) {
        final path = i == 0
            ? paths[i]
            : paths[i].replaceFirst(
                '<path ',
                '<path clip-path="url(#$_id-clip-${i - 1})" ',
              );
        markup.write(
          '<clipPath id="$_id-clip-$i" clipPathUnits="userSpaceOnUse">'
          '$path</clipPath>',
        );
      }
      host.innerHTML = markup.toString().toJS;
      plane.style.clipPath = paths.isEmpty
          ? 'none'
          : 'url("#$_id-clip-${paths.length - 1}")';
    }
    plane.style
      ..left = '${left}px'
      ..top = '${top}px'
      ..opacity = '$opacity'
      ..visibility = 'visible';
    if (sibling.nextSibling != plane) {
      scene.insertBefore(plane, sibling.nextSibling);
    }
    // Resource definitions must be siblings, not descendants of the element
    // they filter/clip: Chromium otherwise treats the reference as circular.
    for (final host in [_host, _clipHost]) {
      if (host != null && host.parentNode != scene) scene.append(host);
    }
    _handleReady(true);
  }

  bool _opticalNode(web.Node node) {
    final element = node.isA<web.Element>()
        ? node as web.Element
        : node.parentElement;
    return element?.closest(
          '[data-coui-flutter-refraction],'
          '[data-coui-flutter-refraction-resource]',
        ) !=
        null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported || widget.activation <= 0) {
      _clear();
      return widget.child;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        _sync();
        return Stack(
          fit: StackFit.passthrough,
          children: [
            if (widget.background != null)
              Positioned.fill(
                child: _ready ? const SizedBox.expand() : widget.background!,
              ),
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: HtmlElementView.fromTagName(
                    tagName: 'div',
                    onElementCreated: _handleElementCreated,
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _clear();
    super.dispose();
  }
}

// Flutter 3.47 emits rect(... round ...) for rectangular mutators. Turn them
// into local SVG paths so nested rounded clips intersect without creating any
// ancestor backdrop roots. Arbitrary path/perspective clips retain material.
bool _axisAligned(String transform) {
  if (transform == 'none') return true;
  final match = RegExp(r'^matrix\(([^)]+)\)$').firstMatch(transform);
  final values = match?[1]
      ?.split(',')
      .map((v) => double.tryParse(v.trim()))
      .toList();
  return values != null &&
      values.length == 6 &&
      values[0] != null &&
      values[0]! > 0 &&
      values[1] == 0 &&
      values[2] == 0 &&
      values[3] != null &&
      values[3]! > 0;
}

String? _clipPath(
  String css,
  double offsetX,
  double offsetY, {
  double scaleX = 1,
  double scaleY = 1,
  Size? containedSize,
}) {
  final match = RegExp(r'^rect\(([^)]+)\)$').firstMatch(css);
  if (match == null) return null;
  final parts = match[1]!.split(' round ');
  List<double>? numbers(String value) {
    final result = <double>[];
    for (final word in value.trim().split(RegExp(r'\s+'))) {
      final number = double.tryParse(word.replaceAll('px', ''));
      if (number == null) return null;
      result.add(number);
    }
    return result;
  }

  final bounds = numbers(parts.first);
  if (bounds == null || bounds.length != 4) return null;
  final top = bounds[0] * scaleY - offsetY;
  final right = bounds[1] * scaleX - offsetX;
  final bottom = bounds[2] * scaleY - offsetY;
  final left = bounds[3] * scaleX - offsetX;
  List<double>? corners(String value) {
    final raw = numbers(value);
    return switch (raw?.length) {
      1 => List.filled(4, raw![0]),
      2 => [raw![0], raw[1], raw[0], raw[1]],
      3 => [raw![0], raw[1], raw[2], raw[1]],
      4 => raw,
      _ => null,
    };
  }

  final radii = parts.length == 1 ? ['0'] : parts[1].split('/');
  final x = corners(radii.first);
  final y = corners(radii.last);
  if (x == null || y == null) return null;
  for (var i = 0; i < 4; i++) {
    x[i] *= scaleX;
    y[i] *= scaleY;
  }
  if (containedSize != null &&
      x.every((radius) => radius == 0) &&
      y.every((radius) => radius == 0) &&
      left <= 0 &&
      top <= 0 &&
      right >= containedSize.width &&
      bottom >= containedSize.height) {
    return '';
  }
  var scale = 1.0;
  for (final (extent, sum) in [
    (right - left, x[0] + x[1]),
    (right - left, x[2] + x[3]),
    (bottom - top, y[0] + y[3]),
    (bottom - top, y[1] + y[2]),
  ]) {
    if (sum > 0) scale = math.min(scale, extent / sum);
  }
  for (var i = 0; i < 4; i++) {
    x[i] *= scale;
    y[i] *= scale;
  }
  return '<path d="M ${left + x[0]} $top H ${right - x[1]} '
      'A ${x[1]} ${y[1]} 0 0 1 $right ${top + y[1]} '
      'V ${bottom - y[2]} A ${x[2]} ${y[2]} 0 0 1 ${right - x[2]} $bottom '
      'H ${left + x[3]} A ${x[3]} ${y[3]} 0 0 1 $left ${bottom - y[3]} '
      'V ${top + y[0]} A ${x[0]} ${y[0]} 0 0 1 ${left + x[0]} $top Z"/>';
}
