import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform aspect-ratio container — direct equivalent
/// of Flutter's `AspectRatio` widget. Forces the wrapper's intrinsic
/// width-to-height to match [ratio] and lays the [child] out inside
/// the resulting box.
///
/// ```dart
/// AspectRatioBox(
///   ratio: 16 / 9,
///   child: Image.network('https://example.com/image.jpg'),
/// )
/// ```
class AspectRatioBox extends StatelessWidget
    implements CoreAspectRatioBoxContract<Widget> {
  /// Creates a [AspectRatioBox].
  const AspectRatioBox({
    required this.child,
    required this.ratio,
    super.key,
  });

  /// Width-to-height ratio (`width / height`). Must be a finite
  /// positive value. Non-positive / `NaN` values fall back to the
  /// surrounding
  /// `CoreComponentTheme.aspectRatioBox.style.defaultRatio`, then to
  /// the design-system default `1.0`.
  @override
  final double ratio;

  /// Child laid out inside the ratio-constrained wrapper.
  @override
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAspectRatioBox(context, ratio: ratio);
    return AspectRatio(
      aspectRatio: resolved.ratio,
      child: child,
    );
  }
}
