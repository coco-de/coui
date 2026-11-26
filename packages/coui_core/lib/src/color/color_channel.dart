/// Single-RGB-channel constants.
///
/// Bridges normalised `Color` channel values (0.0–1.0, used by Flutter's
/// post-0.21 `Color.r/g/b/a`) to the legacy 8-bit ARGB representation
/// (0–255 / `0xff` mask) used by `Color.fromARGB` and CSS rgba strings.
///
/// File-local magic constants in `co_card_image.dart` etc. read from
/// these tokens so the conversion math stays traceable to a named
/// constant.
library;

/// Single-RGB-channel constants.
abstract final class CoreColorChannel {
  const CoreColorChannel._();

  /// Maximum value of a single 8-bit RGB channel (0–255).
  ///
  /// Multiply a normalised 0.0–1.0 channel value by this and `.round()`
  /// to get the legacy 0–255 integer.
  static const double max = _byteMax + 0.0;

  /// Bitmask isolating one 8-bit channel from a 32-bit ARGB int.
  static const int mask = _byteMax;

  /// The 8-bit channel boundary — 255 (`0xff`). Shared single source for
  /// both [max] (as a double for normalisation) and [mask] (as the ARGB
  /// extraction bitmask), so the two never drift apart.
  static const int _byteMax = 0xff;
}
