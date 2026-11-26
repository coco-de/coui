/// How content overflowing the bounds of a layout box should be clipped.
///
/// Mirrors Flutter's `Clip` enum so a single contract value produces the
/// same overflow behaviour on Flutter and Web.
enum CoreClipBehavior {
  /// No clipping — children may paint outside the box. Equivalent to
  /// CSS `overflow: visible`.
  none,

  /// Hard rectangular clip. Default for box layouts.
  /// Equivalent to CSS `overflow: hidden`.
  hardEdge,

  /// Antialiased clip — same hard edge but with subpixel smoothing.
  /// Web treats this the same as [hardEdge].
  antiAlias,

  /// Antialiased clip + an offscreen save layer. Used by Flutter when
  /// shadows interact with the clip boundary; Web has no equivalent
  /// concept and treats this the same as [hardEdge].
  antiAliasWithSaveLayer,
}
