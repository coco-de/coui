import 'dart:js_interop';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/infra/outlined_container/refraction_map_web.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_vars.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:web/web.dart' as web;

/// DOM clock/gesture adapter for the same navigation springs used by Flutter.
/// Only the indicator is painted per frame; destinations keep their DOM/focus.
class GlassNavigationRuntime {
  /// Drives the bar whose root element carries [elementId].
  GlassNavigationRuntime({
    required this.elementId,
    required this.onMaterialChanged,
    required this.onPreviewChanged,
    required this.onActiveChanged,
  });

  /// The bar's root element's id; the selection and the lens are found
  /// beside it as `<id>-selection` and `<id>-lens`.
  final String elementId;

  /// Called when the page's surface style or direction changes.
  final void Function() onMaterialChanged;

  /// Called with the destination the lens is over while it is up, or null.
  final void Function(int?) onPreviewChanged;

  /// Called when the moving glass selection starts or stops being drawn.
  final void Function(bool) onActiveChanged;
  CoreGlassNavigationMotion? _motion;
  web.HTMLElement? _root;
  late web.HTMLElement _rest;
  late web.HTMLElement _lens;
  SurfaceRefractionRuntime? _optics;
  web.ResizeObserver? _resize;
  web.MutationObserver? _theme;
  late web.MediaQueryList _reduce;
  final _listeners = <(web.EventTarget, String, JSFunction, bool)>[];
  int? _frame;
  double? _lastTime;
  bool _disposed = false;
  bool _active = false;
  bool _materialActive = false;
  int? _selected;
  List<bool> _enabled = [];
  void Function(int)? _onSelected;
  int? _pointer;
  double _downX = 0;
  double _downY = 0;
  double _grab = 0;
  double? _preview;
  bool _dragged = false;
  bool _suppressClick = false;
  double _firstX = 0;
  double _top = 0;
  double _width = 0;
  double _height = 0;
  double _stride = 0;
  bool _rtl = false;
  bool _uniform = true;

  /// The scale the bar was last drawn at (see [_applySwell]). The boxes
  /// [_measure] reads are drawn through it, so it divides them back to the
  /// laid-out lengths the lens is placed in.
  double _drawnScale = 1;

  /// The point the bar was last drawn grown from, in px from its border
  /// box's start along the axis.
  double _drawnOrigin = 0;

  /// Whether the destinations run down a column (the rail) rather than
  /// along a row (the bar). The lens travels that axis; everything measured
  /// along it — the stride, the pointer, the fit — follows.
  bool _vertical = false;
  final _opticalPasses = <(web.Element, double, double)>[];
  int _waited = 0;
  int? _lastPreview;

  void _publishPreview(int? value) {
    if (_lastPreview == value) return;
    _lastPreview = value;
    onPreviewChanged(value);
  }

  /// States what the bar draws: whether the glass selection is on, the axis,
  /// the selected and enabled destinations, and where a committed drag goes.
  void update({
    required bool active,
    required bool vertical,
    required int? selectedIndex,
    required List<bool> enabled,
    required void Function(int)? onSelected,
  }) {
    final changed =
        _selected != selectedIndex ||
        _active != active ||
        _vertical != vertical ||
        _enabled.length != enabled.length ||
        Iterable<int>.generate(
          enabled.length,
        ).any((i) => i >= _enabled.length || _enabled[i] != enabled[i]);
    _active = active;
    _vertical = vertical;
    _selected = selectedIndex;
    _enabled = List.of(enabled);
    _onSelected = onSelected;
    _motion ??= CoreGlassNavigationMotion(selectedIndex?.toDouble() ?? 0);
    if (changed || onSelected == null) _cancel();
    _wake();
  }

  void _listen(
    web.EventTarget target,
    String type,
    void Function(web.Event) callback, {
    bool capture = false,
  }) {
    final listener = callback.toJS;
    target.addEventListener(type, listener, capture.toJS);
    _listeners.add((target, type, listener, capture));
  }

  bool _attach() {
    final root = web.document.getElementById(elementId);
    final rest = web.document.getElementById('$elementId-selection');
    final lens = web.document.getElementById('$elementId-lens');
    if (root == null ||
        rest == null ||
        lens == null ||
        !root.isA<web.HTMLElement>() ||
        !rest.isA<web.HTMLElement>() ||
        !lens.isA<web.HTMLElement>()) {
      return false;
    }
    _root = root as web.HTMLElement;
    _rest = rest as web.HTMLElement;
    _lens = lens as web.HTMLElement;
    _reduce = web.window.matchMedia('(prefers-reduced-motion: reduce)');
    _listen(_reduce, 'change', (_) => _wake());
    _listen(root, 'pointerdown', _down);
    _listen(web.document, 'pointermove', _move);
    _listen(web.document, 'pointerup', _up);
    _listen(web.document, 'pointercancel', (e) {
      if (e.isA<web.PointerEvent>() &&
          (e as web.PointerEvent).pointerId == _pointer) {
        _cancel();
      }
    });
    _listen(web.window, 'blur', (_) => _cancel());
    _listen(root, 'click', (e) {
      if (!_suppressClick ||
          (e.isA<web.MouseEvent>() && (e as web.MouseEvent).detail == 0)) {
        return;
      }
      _suppressClick = false;
      e
        ..preventDefault()
        ..stopImmediatePropagation();
    }, capture: true);
    _resize = web.ResizeObserver(
      ((JSAny entries, JSAny observer) {
        _measure();
        _wake();
      }).toJS,
    )..observe(root);
    _theme =
        web.MutationObserver(
          ((JSAny records, JSAny observer) {
            onMaterialChanged();
            _wake();
          }).toJS,
        )..observe(
          web.document.documentElement!,
          web.MutationObserverInit(
            attributes: true,
            attributeFilter: [
              'data-coui-style',
              'dir',
              'class',
            ].map((v) => v.toJS).toList().toJS,
          ),
        );
    _measure();
    return true;
  }

  void _measure() {
    final root = _root;
    if (root == null) return;
    final items = root.querySelectorAll('[data-coui-nav-index]');
    if (items.length == 0) return;
    final box = root.getBoundingClientRect();
    final first = (items.item(0)! as web.Element).getBoundingClientRect();
    final style = web.window.getComputedStyle(root);
    _rtl = style.direction == 'rtl';
    // The boxes are read as they are drawn, through the bar's swell and its
    // compact form; the lens is laid out inside the bar, before both.
    final drawn = _drawnScale * _compaction(style);
    _width = first.width / drawn;
    _height = first.height / drawn;
    _firstX = (first.left - box.left) / drawn - root.clientLeft;
    _top = (first.top - box.top) / drawn - root.clientTop;
    // One destination's length along the axis, and the distance from one
    // destination to the next.
    final cell = _vertical ? _height : _width;
    if (items.length < 2) {
      _stride = cell;
    } else {
      final second = (items.item(1)! as web.Element).getBoundingClientRect();
      _stride =
          (_vertical ? second.top - first.top : second.left - first.left)
              .abs() /
          drawn;
    }
    // The lens moves over equal cells that are all in view: a row or a
    // column that needs to scroll keeps its resting selection.
    _uniform =
        _width > 0 &&
        _height > 0 &&
        cell + _stride * (items.length - 1) <=
            (_vertical ? root.clientHeight : root.clientWidth) + 1;
    for (var i = 1; i < items.length; i++) {
      final box = (items.item(i)! as web.Element).getBoundingClientRect();
      if ((box.width / drawn - _width).abs() > 1 ||
          (box.height / drawn - _height).abs() > 1) {
        _uniform = false;
      }
    }
    // These are already measured CSS pixels, including accessibility scale.
    // Convert through the live rem size instead of scaling them a second time.
    final rootFont =
        double.tryParse(
          web.window
              .getComputedStyle(web.document.documentElement!)
              .fontSize
              .replaceFirst('px', ''),
        ) ??
        kRemDivisor;
    // The offset across the axis is laid out; the offset along it is the
    // transform the frame clock writes (see `_tick`).
    for (final node in [_rest, _lens]) {
      node.style.width = '${_width / rootFont}rem';
      node.style.height = '${_height / rootFont}rem';
      node.style.top = _vertical ? '0' : '${_top / rootFont}rem';
      node.style.left = _vertical ? '${_firstX / rootFont}rem' : '0';
    }
  }

  /// Where the pointer falls along the axis, in destinations — 0 at the
  /// first destination's centre, 1 at the second's. A row counts from its
  /// start edge, which is the right-hand one in a right-to-left document; a
  /// column counts from the top in either.
  double _position(double clientX, double clientY) {
    // The pointer is read on the bar as it is laid out, before its swell —
    // the swell is drawn only, as on Flutter. The drawn box starts
    // `origin × (1 − scale)` from where the laid-out one does.
    //
    // The compact form is not undone the same way: a compact bar is where
    // the finger finds it, so the pointer is taken back through that scale
    // to the lengths the lens is laid out in. The compact form lies outside
    // the swell, so the swell's shift is counted after it.
    final root = _root!;
    final box = root.getBoundingClientRect();
    final compact = _compaction(web.window.getComputedStyle(root));
    final shift = _drawnOrigin * (1 - _drawnScale);
    if (_vertical) {
      final physical =
          (clientY - box.top) / compact +
          shift -
          root.clientTop -
          _top -
          _height / 2;
      return physical / _stride;
    }
    final physical =
        (clientX - box.left) / compact +
        shift -
        root.clientLeft -
        _firstX -
        _width / 2;
    return physical / _stride * (_rtl ? -1 : 1);
  }

  /// The factor the bar's compact form draws it at on this frame — `1` for
  /// a bar at its resting size — read off the transform the resolver states
  /// (`navigationCompactTransformCss`), so a bar part-way between the two
  /// sizes answers with where it is. The swell is not in it: that is the
  /// `scale` property, which [_applySwell] writes and [_drawnScale] holds.
  double _compaction(web.CSSStyleDeclaration style) {
    final transform = style.transform;
    if (!transform.startsWith('matrix(')) return 1;
    final scale = double.tryParse(
      transform.substring('matrix('.length).split(',').first.trim(),
    );

    return scale == null || scale <= 0 ? 1 : scale;
  }

  void _down(web.Event event) {
    if (!event.isA<web.PointerEvent>()) return;
    final raw = event as web.PointerEvent;
    if (!(_root?.classList.contains('coui-navigation-glass-active') ?? false) ||
        _onSelected == null ||
        _pointer != null ||
        !raw.isPrimary ||
        raw.button != 0) {
      return;
    }
    _measure();
    if (!_uniform || _stride <= 0 || _enabled.isEmpty) return;
    _suppressClick = false;
    final x = mouseClientX(raw)!;
    final y = mouseClientY(raw)!;
    final position = _position(x, y);
    final index = position.round().clamp(0, _enabled.length - 1);
    if (!_enabled[index]) return;
    _pointer = raw.pointerId;
    _downX = x;
    _downY = y;
    _grab = position - index;
    _preview = index.toDouble();
    _dragged = false;
    _motion!.moveTo(_preview!, held: true);
    _wake();
  }

  void _move(web.Event event) {
    if (!event.isA<web.PointerEvent>()) return;
    final raw = event as web.PointerEvent;
    if (raw.pointerId != _pointer) return;
    final x = mouseClientX(raw)!;
    final y = mouseClientY(raw)!;
    final dx = (x - _downX).abs();
    final dy = (y - _downY).abs();
    // A drag across the axis belongs to the page (a scroll, a swipe); only
    // travel along the axis moves the lens.
    final along = _vertical ? dy : dx;
    final across = _vertical ? dx : dy;
    if (!_dragged && across > 8 && across > along) {
      _cancel();
      return;
    }
    if (!_dragged && along < 8) return;
    _dragged = true;
    final position = _position(x, y) - _grab;
    final bounded = position.clamp(0.0, _enabled.length - 1.0);
    final excess = position - bounded;
    _preview = bounded + .22 * excess / (excess.abs() + .55);
    _motion!.moveTo(_preview!, held: true);
    _wake();
  }

  void _up(web.Event event) {
    if (!event.isA<web.PointerEvent>()) return;
    if ((event as web.PointerEvent).pointerId != _pointer) return;
    final dragged = _dragged;
    final candidate = _preview?.round().clamp(0, _enabled.length - 1);
    _cancel();
    if (!dragged) return; // A tap/keyboard activation belongs to Clickable.
    _suppressClick = true;
    if (candidate != null && _enabled[candidate] && candidate != _selected) {
      _onSelected?.call(candidate);
    }
  }

  void _cancel() {
    _pointer = null;
    _preview = null;
    _dragged = false;
    _motion?.release(_selected?.toDouble() ?? 0);
    _wake();
  }

  void _wake() {
    if (_disposed || _frame != null) return;
    _frame = web.window.requestAnimationFrame(_tick.toJS);
  }

  void _tick(double now) {
    _frame = null;
    if (_disposed) return;
    if (_root == null && !_attach()) {
      if (++_waited < 30) _wake();
      return;
    }
    final root = _root!;
    _measure();
    final active =
        _active &&
        _uniform &&
        web.window
                .getComputedStyle(root)
                .getPropertyValue('--coui-navigation-material')
                .trim() ==
            'liquidGlass';
    root.classList.toggle('coui-navigation-glass-active', active);
    root.classList.toggle(
      'coui-navigation-glass-vertical',
      active && _vertical,
    );
    if (_materialActive && !active) _cancel();
    if (_materialActive != active) onActiveChanged(active);
    _materialActive = active;
    if (!active) {
      _publishPreview(null);
      _optics?.dispose();
      _optics = null;
      _opticalPasses.clear();
      _lastTime = null;
      _applySwell(1, 0);
      return;
    }
    _measure();
    final motion = _motion!
      ..configure(
        reduced:
            _reduce.matches ||
            web.window
                    .getComputedStyle(root)
                    .getPropertyValue('--coui-navigation-duration')
                    .trim() ==
                '0',
        itemExtent: _stride,
      );
    if (_lastTime != null) motion.advance((now - _lastTime!) / 1000);
    _lastTime = now;
    final valid =
        _preview != null ||
        (_selected != null &&
            _selected! >= 0 &&
            _selected! < _enabled.length &&
            _enabled[_selected!]);
    _publishPreview(
      motion.activation > 0 || _pointer != null
          ? motion.position.value.round()
          : null,
    );
    final lift = motion.activation;
    final energy = motion.energy * lift;
    // Pressure expands the lens; travel squashes it along the axis and
    // bulges it across — the same numbers the Flutter twin sizes its lens
    // with, on whichever axis the destinations run.
    final squash = 1 + .06 * lift - .10 * energy;
    final bulge = 1 + .18 * lift + .18 * energy;
    // A row runs from its start edge; a column runs down in either
    // direction.
    final sign = !_vertical && _rtl ? -1 : 1;
    final travel = sign * motion.position.value * _stride;
    final transform = _vertical
        ? 'translate3d(0, ${_top + travel}px, 0) scale($bulge, $squash)'
        : 'translate3d(${_firstX + travel}px, 0, 0) scale($squash, $bulge)';
    _rest.style.transform = transform;
    _lens.style.transform = transform;
    _rest.style.opacity = valid ? '${1 - lift}' : '0';
    _lens.style.opacity = valid ? '$lift' : '0';
    final direction = motion.direction * sign;
    _lens.style.setProperty(
      '--coui-navigation-light-angle',
      '${145 - 10 * direction}deg',
    );
    if (_optics == null && _width > 0 && _height > 0) {
      _optics = SurfaceRefractionRuntime(elementId: '$elementId-lens')
        ..attach(CoreNavigationBarStyle.glassSelectionRefraction);
    }
    _activateOptics(1 - (1 - lift) * (1 - lift));
    _applySwell(motion.barScale, motion.position.value);
    if (!motion.isSettled) {
      _wake();
    } else {
      _lastTime = null;
    }
  }

  /// Draws the whole bar at the motion's swell, about the point
  /// `CoreGlassNavigationMotion.barSwellOrigin` mirrors from the lens at
  /// [lensPosition] — the capsule, the lens and the destinations together, as
  /// the Flutter twin's transform does.
  ///
  /// The individual `scale` property, so a `transform` the page gives the bar
  /// is kept. At rest both properties are removed and the bar carries none of
  /// this.
  void _applySwell(double scale, double lensPosition) {
    final root = _root;
    if (root == null) return;
    _drawnScale = scale;
    if (scale == 1) {
      root.style
        ..removeProperty('scale')
        ..removeProperty('transform-origin')
        ..removeProperty(kNavigationSwellVar)
        ..removeProperty(kNavigationSwellOriginVar);
      return;
    }
    // The lens's centre in the bar's border box, as laid out — the same
    // place the lens's own transform puts it.
    final sign = !_vertical && _rtl ? -1 : 1;
    final centre = _vertical
        ? root.clientTop + _top + _height / 2 + lensPosition * _stride
        : root.clientLeft +
              _firstX +
              _width / 2 +
              sign * lensPosition * _stride;
    final length = (_vertical ? root.offsetHeight : root.offsetWidth)
        .toDouble();
    final origin = length > 0
        ? CoreGlassNavigationMotion.barSwellOrigin(centre / length)
        : .5;
    _drawnOrigin = origin * length;
    root.style
      ..setProperty('scale', '$scale')
      ..setProperty(
        'transform-origin',
        _vertical ? '50% ${origin * 100}%' : '${origin * 100}% 50%',
      )
      // The same two numbers for the bar's compact transform, which is
      // stated about its own point and has to allow for this origin
      // (`navigationCompactTransformCss`).
      ..setProperty(kNavigationSwellVar, '$scale')
      ..setProperty(kNavigationSwellOriginVar, '${origin * 100}%');
  }

  // Maps stay cached at the base geometry. Only displacement amplitudes
  // change per frame, matching Flutter's activation without canvas readback.
  void _activateOptics(double activation) {
    final filter = web.document.getElementById(
      refractionFilterId('$elementId-lens'),
    );
    if (filter == null) return;
    final nodes = filter.querySelectorAll('feDisplacementMap');
    if (nodes.length == 0) return;
    if (_opticalPasses.isEmpty || _opticalPasses.first.$1 != nodes.item(0)) {
      _opticalPasses.clear();
      for (var i = 0; i < nodes.length; i++) {
        final node = nodes.item(i)! as web.Element;
        final result = node.getAttribute('result') ?? '';
        final channel = result.length == 2 && result.startsWith('d')
            ? int.tryParse(result.substring(1))
            : null;
        final spread = channel == null
            ? 0.0
            : (1 - channel) *
                  CoreSurfaceRefraction.dispersionUnit *
                  CoreNavigationBarStyle.glassSelectionRefraction.dispersion;
        final base = double.parse(node.getAttribute('scale')!) / (1 + spread);
        _opticalPasses.add((node, base, spread));
      }
    }
    for (final (node, base, spread) in _opticalPasses) {
      final scale = base * activation * (1 + spread * activation);
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
  }

  /// Stops the clock, puts the bar back at rest and lets go of every listener
  /// and observer it attached.
  void dispose() {
    _disposed = true;
    if (_frame != null) web.window.cancelAnimationFrame(_frame!);
    _applySwell(1, 0);
    for (final (target, type, callback, capture) in _listeners) {
      target.removeEventListener(type, callback, capture.toJS);
    }
    _listeners.clear();
    _resize?.disconnect();
    _theme?.disconnect();
    _optics?.dispose();
  }
}
