/// SSR stub for [SurfaceRefractionHost].
///
/// The server emits no refraction at all: the displacement is generated
/// from a measured element, and there is nothing here to measure. Markup
/// that referenced a filter anyway would point at one nothing had built.
library;

/// Stub implementation used during SSR.
class SurfaceRefractionHost {
  SurfaceRefractionHost._();

  /// No-op. There is no document here.
  static void install() {}

  /// No-op. Nothing was installed.
  static void uninstall() {}
}
