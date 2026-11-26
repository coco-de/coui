import 'dart:async';
import 'dart:ui';

import 'package:coui_flutter/src/components/infra/outlined_container/web_surface_backdrop.dart'
    show webSurfaceRefractionSupported;
import 'package:flutter/foundation.dart';

/// Bundled by `coui_flutter`'s own pubspec, so a consuming app needs no
/// registration of its own — a surface that asks for refraction must not
/// depend on the app having remembered to list an asset it never wrote.
const kSurfaceRefractionShaderAsset =
    'packages/coui_flutter/shaders/surface_refraction.frag';

/// The compiled refraction program, held once for the whole process.
///
/// ## Why one holder rather than a load per surface
///
/// `FragmentProgram.fromAsset` answers with a future even when the engine
/// already holds the program, so a surface that asks in its own `initState`
/// always paints its first frame before the answer arrives: Tier 1 for one
/// frame, then the bend snaps in. On a screen that mounts a panel that
/// flash is the panel's first impression; on a list it is every card, as
/// it scrolls into view. Measured on Impeller before this holder existed —
/// see `refraction_sampling_probe_test.dart`, P4.
///
/// Held here, a surface that mounts after the program has arrived reads it
/// synchronously and bends on the frame it mounts. What makes it arrive
/// first is the app root's warm-up: `CoUIApp` asks the moment it knows the
/// active style bends anything, which is the Flutter seat for what the Web
/// twin does at document level (`SurfaceRefractionHost`).
///
/// ## What null means
///
/// Not asked for, still loading, unable to run on this engine, and failed
/// to load all read as null, and all render the same way on purpose: the
/// surface keeps the rest of its material and simply does not bend.
/// A failure is remembered so it is not retried on every rebuild — a
/// missing asset would otherwise become a load loop that never succeeds.
abstract final class SurfaceRefractionProgram {
  static FragmentProgram? _program;
  static Future<FragmentProgram?>? _inFlight;
  static bool _failed = false;

  /// The program, once it has arrived.
  ///
  /// A surface reads this in its `initState`; non-null there means the
  /// first frame bends.
  static FragmentProgram? get loaded => _program;

  /// Whether this process can draw a bend at all — the native engine's shader
  /// filters, or the browser backend Flutter Web draws one with.
  ///
  /// The question the quality governor asks before it counts the bend among
  /// the things it can give up: a rung that stops drawing what this engine
  /// never drew would cost a window and a cooldown to change nothing.
  static bool get supported =>
      debugIsShaderFilterSupported() || webSurfaceRefractionSupported;

  /// Loads the program where the engine can run it, once per process.
  ///
  /// Completes with the program, or with null where it cannot be had —
  /// an engine without shader filters, a missing or malformed asset.
  /// Every caller after the first shares the same load, so it is safe to
  /// ask from the app root and from every surface alike.
  ///
  /// `isShaderFilterSupported` is the runtime query, not a platform check:
  /// it reports whether Impeller is on, and an embedder can turn that off
  /// on a platform that usually has it. On Flutter Web it is a literal
  /// `false`, which is why this never asks for the asset there — that SDK
  /// defines `ImageFilter.shader` as an unconditional throw.
  static Future<FragmentProgram?> warmUp() {
    final ready = _program;
    if (ready != null) return Future.value(ready);
    if (_failed || !debugIsShaderFilterSupported()) return Future.value(null);

    return _inFlight ??= _load();
  }

  static Future<FragmentProgram?> _load() async {
    try {
      final program = await debugLoad(kSurfaceRefractionShaderAsset);
      _program = program;

      return program;
    } on Object {
      // Swallowed on purpose. The surface already draws correctly without
      // the bend, so a bad asset should cost the bend and nothing else.
      _failed = true;

      return null;
    } finally {
      _inFlight = null;
    }
  }

  /// The asset loader, replaceable so a test can count and fail loads.
  @visibleForTesting
  static Future<FragmentProgram> Function(String asset) debugLoad =
      FragmentProgram.fromAsset;

  /// The capability query, replaceable so a test can exercise the load on
  /// an engine that answers `false` (every `flutter_tester` run does).
  @visibleForTesting
  static bool Function() debugIsShaderFilterSupported = () =>
      ImageFilter.isShaderFilterSupported;

  /// Forgets everything, so tests start from an unloaded process.
  @visibleForTesting
  static void debugReset() {
    _program = null;
    _inFlight = null;
    _failed = false;
  }
}
