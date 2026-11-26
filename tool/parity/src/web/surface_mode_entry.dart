/// Entry point compiled into the surface-mode probe's page.
///
/// The probe judges the **shipped** host — the document-level observer that
/// attaches the per-element runtime to every marked surface — so the page
/// carries the real one, not a re-statement of it. A probe that re-implemented
/// the re-binding in page JS would keep passing after the host had drifted
/// away from it.
///
/// Only install and uninstall are exported. Everything the probe asserts is
/// something the host does by itself once it is installed and the document
/// changes, which is the behaviour the probe exists to see.
library;

import 'dart:js_interop';

// The host is deliberately not exported from the barrel: it is an internal
// detail of the Web surface. The probe reaches for the file directly rather
// than widening the public surface to make a test easier.
import 'package:coui_web/src/base/surface_refraction_host.dart';

@JS('couiInstallSurfaceHost')
external set _install(JSFunction value);

@JS('couiUninstallSurfaceHost')
external set _uninstall(JSFunction value);

void main() {
  _install = SurfaceRefractionHost.install.toJS;
  _uninstall = SurfaceRefractionHost.uninstall.toJS;
}
