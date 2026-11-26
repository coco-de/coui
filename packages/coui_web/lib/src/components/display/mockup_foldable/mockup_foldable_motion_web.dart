/// Web implementation of the clock and the frames `MockupFoldable` moves on.
///
/// Selected by the conditional export in `mockup_foldable_motion.dart` for
/// browser builds, so `mockup_foldable.dart` carries no `package:web` import.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Whether this host draws frames. A browser does.
const bool kMockupFoldHasFrames = true;

/// Asks the browser for [callback] on its next frame
/// (`requestAnimationFrame`) and returns the function that withdraws the
/// request. A fold draws one step per frame.
void Function() requestMockupFoldFrame(void Function() callback) {
  final id = web.window.requestAnimationFrame(((double _) => callback()).toJS);

  return () => web.window.cancelAnimationFrame(id);
}

/// The browser's monotonic clock (`performance.now()`), the one
/// `requestAnimationFrame` timestamps are in.
Duration mockupFoldClock() =>
    Duration(microseconds: (web.window.performance.now() * 1000).round());
