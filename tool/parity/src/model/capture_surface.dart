// #3665 — the capture-available-width contract: the single answer to "how
// wide is the box a captured component renders inside", both platforms'
// harnesses read.
//
// Before this constant existed, `web_capture_backend.dart`'s
// `data-parity-key` wrapper declared `display:inline-block` and no width —
// an indefinite (shrink-to-fit) containing block. A `w-full` Tailwind
// descendant's percentage width has nothing definite to resolve against in
// that case and computes to 0 (confirmed empirically against
// `divider`/`progress`/`slider` — all three are container-driven `w-full`
// roots). Flutter's side of the same coupling was never a bug: `flutter_
// test`'s default `TestFlutterView` already renders those same
// container-driven widgets at a logical width that happens to equal this
// number today — not a coincidence this constant was chosen to match, but
// the reverse: `flutter_capture_test.dart` pins that *implicit* default to
// this named constant so a future Flutter SDK default change is a visible
// break instead of a silent capture-size drift.

/// The available width (CSS px on Web, logical px on Flutter) an ancestor
/// gives a captured component.
///
/// - **Web** (`web_capture_backend.dart`): the `data-parity-key` wrapper
///   resolves a `w-full` descendant's percentage width against this value.
/// - **Flutter** (`packages/coui_flutter/test/parity/capture_surface_test.dart`,
///   which mirrors this constant under its own name — a Flutter package
///   cannot `import` a file living outside its own package tree, so the
///   two copies are kept in sync by `capture_surface_test.dart`'s own
///   `dart test` re-reading both source files, the same "declare a literal,
///   verify it doesn't drift with a grep test" pattern
///   `surface_marker_registry.dart` already uses for a cross-package
///   literal): `tester.view.physicalSize.width / tester.view.devicePixelRatio`
///   is asserted equal to this value, pinning `flutter_test`'s own default
///   view size to the same contract rather than leaving the coupling
///   implicit.
///
/// `int`, not `double` — every real consumer needs a definite whole pixel
/// count: Puppeteer's `DeviceViewport`/the CDP `setDeviceMetricsOverride`
/// call it wraps rejects non-integer device metrics, and the CSS this
/// value drives (`width: ${kCaptureAvailableWidthPx}px`) reads as a plain
/// pixel integer rather than the redundant `800.0px` a `double` would
/// stringify to.
const int kCaptureAvailableWidthPx = 800;

/// [kCaptureAvailableWidthPx] as a ready-to-emit CSS `width` value —
/// avoids every call site re-deriving the same `'${…}px'` interpolation
/// (and re-deciding whether it needs a unit) independently.
const String kCaptureAvailableWidthCss = '${kCaptureAvailableWidthPx}px';
