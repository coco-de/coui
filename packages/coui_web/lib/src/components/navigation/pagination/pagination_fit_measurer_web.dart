/// Web implementation of [PaginationFitMeasurer].
///
/// The probe `<div>` holds one invisible copy of the pagination row per
/// compaction step, widest first, each at its max-content width. The
/// width the row is given is the content box of the nearest ancestor
/// whose width does not come from its content — the Web twin of the
/// Flutter row's incoming max width. The measurer reports the first copy
/// no wider than that (the last one when none is), and re-measures
/// whenever the container or a copy resizes.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Sub-pixel slack for the fit check — layout widths are fractional and a
/// row that fits exactly must not flicker between two steps.
const double _kFitTolerance = 0.5;

/// Web measurer for a single `Pagination` row.
class PaginationFitMeasurer {
  /// Creates a [PaginationFitMeasurer].
  PaginationFitMeasurer({required this.probeId, required this.onStep});

  /// `id` of the probe `<div>` holding the measuring copies.
  final String probeId;

  /// Receives the step to show.
  final void Function(int step) onStep;

  web.ResizeObserver? _observer;

  /// (Re)observes the container and every copy, then measures. Safe to
  /// call after every build — the copies are replaced when the ladder
  /// changes.
  void sync() {
    _observer?.disconnect();
    final probe = web.document.getElementById(probeId);
    final container = _container(probe);
    if (probe == null || container == null) return;
    final observer = web.ResizeObserver(_handleResize.toJS)..observe(container);
    final rows = probe.children;
    for (var i = 0; i < rows.length; i++) {
      observer.observe(rows.item(i)!);
    }
    _observer = observer;
    _measure(probe, container);
  }

  /// Disconnects the observer. Idempotent.
  void dispose() {
    _observer?.disconnect();
    _observer = null;
  }

  void _handleResize(JSArray<web.ResizeObserverEntry> entries, JSAny _) {
    final probe = web.document.getElementById(probeId);
    final container = _container(probe);
    if (probe == null || container == null) return;
    _measure(probe, container);
  }

  /// The box whose width the row may take.
  ///
  /// Starts at the row's parent and climbs past every box that sizes to
  /// its content — `display: contents` / inline wrappers, shrink-to-fit
  /// boxes (inline-block, floated, absolutely positioned) and flex / grid
  /// items, which shrink-wrap the row they hold and would otherwise
  /// report the row's current width back as the width it is allowed.
  static web.Element? _container(web.Element? probe) {
    var element = probe?.parentElement?.parentElement;
    while (element != null) {
      final style = web.window.getComputedStyle(element);
      final parent = element.parentElement;
      final parentDisplay = parent == null
          ? ''
          : web.window.getComputedStyle(parent).display;
      final shrinkWraps =
          style.display == 'contents' ||
          style.display.startsWith('inline') ||
          style.position == 'absolute' ||
          style.position == 'fixed' ||
          style.float != 'none' ||
          parentDisplay.contains('flex') ||
          parentDisplay.contains('grid');
      if (!shrinkWraps || parent == null) return element;
      element = parent;
    }
    return null;
  }

  void _measure(web.Element probe, web.Element container) {
    final style = web.window.getComputedStyle(container);
    final available =
        container.clientWidth -
        (double.tryParse(style.paddingLeft.replaceAll('px', '')) ?? 0) -
        (double.tryParse(style.paddingRight.replaceAll('px', '')) ?? 0);
    final rows = probe.children;
    if (rows.length == 0) return;
    for (var i = 0; i < rows.length; i++) {
      final width = rows.item(i)!.getBoundingClientRect().width;
      if (width <= available + _kFitTolerance) {
        onStep(i);
        return;
      }
    }
    onStep(rows.length - 1);
  }
}
