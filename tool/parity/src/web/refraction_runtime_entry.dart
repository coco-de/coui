/// Entry point compiled into the refraction runtime probe's page.
///
/// Exists so the probe can judge the **shipped** runtime. A probe that
/// re-implemented the displacement map in page JS would be measuring its own
/// copy, and the copy would keep passing after the runtime it stands for had
/// drifted away from it — which is the failure the promotion of that probe is
/// meant to close.
///
/// Attaching hands the caller its own detach function rather than filing the
/// runtime in a registry here. A registry would be a second place where a
/// surface's lifetime is tracked, and the shipped component already tracks it;
/// this way the page holds exactly one handle per surface and `dispose` is
/// reachable without inventing a lookup.
library;

import 'dart:js_interop';

import 'package:coui_core/coui_core.dart';
// The runtime is deliberately not exported from the barrel: it is an internal
// detail of the Web surface. The probe reaches for the file directly rather
// than widening the public surface to make a test easier.
import 'package:coui_web/src/components/infra/outlined_container/refraction_map_web.dart';

@JS('couiAttachRefraction')
external set _attach(JSFunction value);

@JS('couiRefractionCacheSize')
external set _cacheSize(JSFunction value);

@JS('couiResetRefractionCache')
external set _resetCache(JSFunction value);

void main() {
  _attach = ((String id, double bezel) {
    final runtime = SurfaceRefractionRuntime(elementId: id)
      ..attach(CoreSurfaceRefraction(bezel: bezel));

    return runtime.dispose.toJS;
  }).toJS;

  _cacheSize = (() => refractionMapCacheSize).toJS;
  _resetCache = resetRefractionMapCache.toJS;
}
