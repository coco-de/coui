/// Platform-independent contract for the loading announcement region.
///
/// `LoadingRegion` wraps an area whose content has not arrived yet and
/// announces "loading" for that area **once**. The skeletons inside it read
/// that they are inside a region and stay silent, so ten placeholders are
/// one announcement rather than ten.
///
/// It draws nothing of its own — there is no chrome to style, so the
/// contract has no `Style` slot.
library;

/// Contract for a region that announces its content is still loading.
///
/// Type parameters:
/// - [W] - platform widget type
///   (Flutter `Widget`, Web `Component`).
abstract interface class CoreLoadingRegionContract<W> {
  /// The area that is loading — usually the skeletons standing in for its
  /// content. It is hidden from assistive technology while the region
  /// speaks for it.
  W get child;

  /// What the region announces.
  ///
  /// `null` reads the active locale's loading label at render time. Pass a
  /// sentence that names what is loading ("Loading orders") when the area
  /// is one of several on screen — it is app content, so it comes from the
  /// caller rather than from the kit's localizations.
  String? get semanticLabel;
}
