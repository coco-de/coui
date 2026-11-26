/// Platform-independent contract for unified hover gallery components.
///
/// Defines the interface that all HoverGallery implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/hover_gallery/hover_gallery_style.dart';

/// Contract for a unified hover gallery component.
///
/// Displays a container of images where the visible image
/// changes based on horizontal hover position.
///
/// Supports two modes:
/// - [imageUrls]: simple URL list (component handles rendering + fit).
/// - [itemCount] + custom builder: custom widget per index.
///
/// Per Epic #1302 chrome / dimensional / animation overrides flow
/// through the single [hoverGalleryStyle] field — see
/// [CoreHoverGalleryStyle] for the merge chain.
abstract interface class CoreHoverGalleryContract {
  /// Image URLs to display. Component creates img internally.
  List<String>? get imageUrls;

  /// Number of items (for builder mode).
  int? get itemCount;

  /// Per-instance chrome / dimensional / animation style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreHoverGalleryTheme.style
  ///   → parent component slot override
  ///   → widget.hoverGalleryStyle
  /// ```
  CoreHoverGalleryStyle? get hoverGalleryStyle;
}
