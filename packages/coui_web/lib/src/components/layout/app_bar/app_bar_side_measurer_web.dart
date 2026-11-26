/// Web implementation of `AppBarSideMeasurer`.
///
/// A centred single-row bar holds its two side columns at one width — the
/// wider cluster's — so the room left for the title is symmetric about the
/// bar's centre. CSS cannot state "the wider of two siblings", so this
/// measures the leading and trailing clusters and writes the larger width
/// to [kAppBarSideVar] on the bar root. The grid template reads it as both
/// side columns' minimum; until it is written (server-rendered first
/// paint) the template falls back to each column's own `max-content`.
///
/// A [web.ResizeObserver] on both clusters keeps the value current when an
/// action, its label or the text scale changes.
library;

import 'dart:js_interop';
import 'dart:math' as math;

import 'package:coui_web/src/components/layout/app_bar/app_bar_style.dart';
import 'package:coui_web/src/util/core_to_css.dart' show measuredLengthCss;
import 'package:web/web.dart' as web;

/// Web orchestrator for one centred bar.
class AppBarSideMeasurer {
  /// Creates an [AppBarSideMeasurer] for the bar whose hidden anchor
  /// element carries [anchorId].
  AppBarSideMeasurer({required this.anchorId});

  /// `id` of the hidden anchor element the bar mounts as a child of its
  /// root; the root is its parent.
  final String anchorId;

  web.HTMLElement? _root;
  web.ResizeObserver? _observer;

  /// Resolves the bar root, observes both clusters and writes the side
  /// width. Idempotent.
  void attach() {
    if (_root != null) return;
    final anchor = web.document.getElementById(anchorId);
    final root = anchor?.parentElement;
    if (root == null) return;
    _root = root as web.HTMLElement;
    _observer = web.ResizeObserver(_handleResize.toJS);
    refresh();
  }

  /// Re-observes the clusters the bar holds now and rewrites the width —
  /// for a rebuild that added or removed a cluster.
  void refresh() {
    final observer = _observer;
    if (observer == null) return;
    observer.disconnect();
    // dart2js rejects tear-offs of external JS interop methods.
    // ignore: unnecessary_lambdas
    _clusters().forEach((cluster) {
      observer.observe(cluster);
    });
    _apply();
  }

  /// Disconnects the observer and clears the written width. Idempotent.
  void dispose() {
    _observer?.disconnect();
    _observer = null;
    _root?.style.removeProperty(kAppBarSideVar);
    _root = null;
  }

  Iterable<web.Element> _clusters() sync* {
    final root = _root;
    if (root == null) return;
    for (final selector in const [
      ':scope > [data-coui-app-bar-leading]',
      ':scope > [data-coui-app-bar-trailing]',
    ]) {
      final element = root.querySelector(selector);
      if (element != null) yield element;
    }
  }

  void _handleResize(JSArray<JSAny?> entries, web.ResizeObserver observer) {
    _apply();
  }

  void _apply() {
    final root = _root;
    if (root == null) return;
    var side = 0.0;
    for (final cluster in _clusters()) {
      side = math.max(side, cluster.getBoundingClientRect().width);
    }
    root.style.setProperty(kAppBarSideVar, measuredLengthCss(side));
  }
}
