/// SSR-safe stub for the clock and the frames `MockupFoldable` moves on.
///
/// There are no frames on the server, so a fold is not animated there: the
/// device is drawn at the angle it was given. The browser implementation
/// lives in `mockup_foldable_motion_web.dart`.
library;

/// Whether this host draws frames. Without a document it does not, and a
/// move must be a jump or it would never arrive.
const bool kMockupFoldHasFrames = false;

/// Stub — no frames without a DOM; the request is never answered.
void Function() requestMockupFoldFrame(void Function() callback) => () {};

/// Stub — no clock without a DOM.
Duration mockupFoldClock() => Duration.zero;
