import 'package:coui_core/src/component/contracts/hover_gallery/hover_gallery_style.dart';
import 'package:meta/meta.dart';

/// Hover gallery component theme overrides.
///
/// Per Epic #1302 the visual chrome of every HoverGallery flows
/// through the single [style] field — see [CoreHoverGalleryStyle] for
/// the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreHoverGalleryTheme.style                   // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance hoverGalleryStyle
/// ```
@immutable
class CoreHoverGalleryTheme {
  /// Creates a [CoreHoverGalleryTheme].
  const CoreHoverGalleryTheme({
    this.style,
  });

  /// Project-wide composite style applied to every `HoverGallery`.
  ///
  /// Resolved before any per-instance `widget.hoverGalleryStyle`.
  final CoreHoverGalleryStyle? style;

  @override
  bool operator ==(Object other) {
    return other is CoreHoverGalleryTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
