/// SSR stub for [SurfaceRefractionRuntime].
///
/// On non-web targets there is no document to attach to, so [attach] and
/// [dispose] are no-ops and the surface renders its Tier 1 material.
///
/// That is the correct server answer rather than a degraded one. The
/// displacement map is computed from an element's measured rectangle, so
/// there is nothing to compute before the element exists — and a server
/// that emitted the filter anyway would ship markup referencing a map that
/// was never generated.
library;

import 'package:coui_core/coui_core.dart';

/// Stub implementation used during SSR.
class SurfaceRefractionRuntime {
  /// Creates a runtime. Parameters mirror the web implementation so the
  /// two signatures stay interchangeable.
  SurfaceRefractionRuntime({required this.elementId});

  /// The id of the surface this would attach to.
  final String elementId;

  /// No-op. There is no document here.
  void attach(
    CoreSurfaceRefraction? refraction, {
    CoreSurfaceEdgeBevel? rim,
    CoreSurfaceEdgeBevel? rimInDarkMode,
  }) {}

  /// No-op. Nothing was attached.
  void dispose() {}
}

/// Always false — there is no browser on the server to bend anything for.
///
/// Present so the two implementations expose the same surface and the
/// conditional export stays interchangeable.
bool get webSurfaceRefractionSupported => false;

/// Always zero — nothing is generated without a document.
///
/// Present so the two implementations expose the same surface and the
/// conditional export stays interchangeable.
int get refractionMapCacheSize => 0;

/// No-op. There is no cache to empty.
void resetRefractionMapCache() {}
