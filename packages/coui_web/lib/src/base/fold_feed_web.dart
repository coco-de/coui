/// Browser implementation of `WebFoldFeed` — selected by the conditional
/// export in `fold_feed.dart`.
///
/// Reads the Viewport Segments API (`window.viewport.segments`) and the
/// posture media queries. The posture is read from CSS rather than from
/// `navigator.devicePosture`: desktop Chrome answers the media query, and an
/// emulated posture reaches it, while the script object is not there at all
/// (measured on Chrome 158).
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/fold_reading.dart';
import 'package:web/web.dart' as web;

/// The queries whose answer moves when the browser's segments or posture do.
///
/// A count query fires when the count leaves it as well as when it arrives,
/// so the one- and two-segment queries cover a fold that appears, goes, or
/// turns. A resize covers a fold that moves.
const List<String> _kChangeQueries = [
  '(horizontal-viewport-segments: 1)',
  '(horizontal-viewport-segments: 2)',
  '(vertical-viewport-segments: 1)',
  '(vertical-viewport-segments: 2)',
  '(device-posture: folded)',
];

/// `window.viewport`, which `package:web` does not bind.
extension type _Viewport._(JSObject _) implements JSObject {
  external JSArray<web.DOMRect>? get segments;
}

/// Reads the folds the browser reports, and tells [start]'s caller each time
/// they change.
final class WebFoldFeed {
  WebFoldFeed._(this._onChange);

  /// Starts reading, or returns null where the browser reports no viewport
  /// segments to read.
  static WebFoldFeed? start({
    required void Function(CoreFoldLayout layout) onChange,
  }) {
    if (!(web.window as JSObject).has('viewport')) return null;

    return WebFoldFeed._(onChange).._attach();
  }

  final void Function(CoreFoldLayout layout) _onChange;
  final List<void Function()> _detach = [];
  CoreFoldLayout _current = CoreFoldLayout.unmeasured;

  /// The folds as the browser reports them now.
  CoreFoldLayout get current => _current;

  /// Reads the folds the browser reports at this moment, without listening —
  /// for a reader that measures on its own schedule, as the positioning
  /// engine does each time it places a panel. Unmeasured where the browser
  /// reports no viewport segments.
  static CoreFoldLayout read() {
    if (!(web.window as JSObject).has('viewport')) {
      return CoreFoldLayout.unmeasured;
    }
    final viewport = (web.window as JSObject)['viewport'];
    if (viewport == null || !viewport.isA<JSObject>()) {
      return CoreFoldLayout.unmeasured;
    }
    final segments = (viewport as _Viewport).segments?.toDart ?? const [];
    // One part has no neighbour and so no fold, however the device is held:
    // the posture is asked only where it can change the answer.
    final split = segments.length > 1;

    return foldLayoutFromSegments(
      [
        for (final segment in segments)
          CoreViewportRect(
            left: segment.x,
            top: segment.y,
            width: segment.width,
            height: segment.height,
          ),
      ],
      state: foldStateFromPosture(
        folded:
            split && web.window.matchMedia('(device-posture: folded)').matches,
        continuous:
            split &&
            web.window.matchMedia('(device-posture: continuous)').matches,
      ),
    );
  }

  void _handleChange() {
    final next = read();
    if (next == _current) return;
    _current = next;
    _onChange(next);
  }

  void _attach() {
    _current = read();
    final changed = ((web.Event _) => _handleChange()).toJS;
    web.window.addEventListener('resize', changed);
    _detach.add(() => web.window.removeEventListener('resize', changed));
    for (final query in _kChangeQueries) {
      final list = web.window.matchMedia(query)
        ..addEventListener('change', changed);
      _detach.add(() => list.removeEventListener('change', changed));
    }
  }

  /// Stops listening.
  void dispose() {
    for (final detach in _detach) {
      detach();
    }
    _detach.clear();
  }
}
