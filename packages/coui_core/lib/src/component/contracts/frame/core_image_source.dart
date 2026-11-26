import 'package:coui_core/src/component/alignment.dart';
import 'package:meta/meta.dart';

/// How a background image should be sized inside the frame's box.
///
/// Maps to:
/// - Flutter: `BoxFit`.
/// - Web: CSS `background-size`.
/// - Figma: Image fill "Fill / Fit / Crop / Tile".
enum CoreImageFit {
  /// Cover the entire box, cropping if necessary.
  cover,

  /// Contain inside the box, letter-boxing if necessary.
  contain,

  /// Stretch to fill the box (may distort).
  fill,

  /// Image's intrinsic size — no scaling.
  none,

  /// Scale down only when larger than the box.
  scaleDown,
}

/// Platform-independent background image used by
/// `CoreFrameContract.backgroundImage`.
///
/// Maps to:
/// - Flutter: `DecorationImage(image: NetworkImage/AssetImage, fit:,
///   alignment:)`.
/// - Web: `background-image: url(...)` + `background-size` +
///   `background-position`.
/// - Figma: Image fill on a Frame.
@immutable
class CoreImageSource {
  /// Creates a [CoreImageSource] from a network URL.
  const CoreImageSource.network(
    this.url, {
    this.fit = CoreImageFit.cover,
    this.alignment = CoreAlignment.center,
  }) : asset = null;

  /// Creates a [CoreImageSource] from a Flutter asset path.
  /// Web ignores [asset] (no Flutter asset bundle); use
  /// [CoreImageSource.network] or a build step that emits the asset
  /// to a public URL.
  const CoreImageSource.asset(
    this.asset, {
    this.fit = CoreImageFit.cover,
    this.alignment = CoreAlignment.center,
  }) : url = null;

  /// Network URL.
  final String? url;

  /// Flutter asset path (Web ignores).
  final String? asset;

  /// How the image is sized inside the box.
  final CoreImageFit fit;

  /// Image anchor inside the box.
  final CoreAlignment alignment;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreImageSource &&
        other.url == url &&
        other.asset == asset &&
        other.fit == fit &&
        other.alignment == alignment;
  }

  @override
  int get hashCode => Object.hash(url, asset, fit, alignment);
}
