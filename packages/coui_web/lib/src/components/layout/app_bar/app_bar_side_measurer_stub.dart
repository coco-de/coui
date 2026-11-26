/// SSR / non-web stub of `AppBarSideMeasurer` — never touches the DOM.
library;

/// No-op stand-in for the web measurer.
class AppBarSideMeasurer {
  /// Creates an [AppBarSideMeasurer].
  ///
  /// Mirrors the web implementation's signature; ignored off the web.
  const AppBarSideMeasurer({required this.anchorId});

  /// `id` of the bar's hidden anchor element — unused off the web.
  final String anchorId;

  /// No-op on non-web platforms.
  void attach() {}

  /// No-op on non-web platforms.
  void refresh() {}

  /// No-op on non-web platforms.
  void dispose() {}
}
