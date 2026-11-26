/// SSR stub for [LiquidMorphRuntime].
///
/// The server renders the panel already open and unclipped, which is the
/// correct answer rather than a degraded one: a morph is a transition
/// between two states, and the server only ever emits the second one. There
/// is no first frame here to animate away from.
library;

import 'package:coui_core/coui_core.dart';

/// Stub implementation used during SSR.
class LiquidMorphRuntime {
  /// Creates a runtime. Parameters mirror the web implementation so the two
  /// signatures stay interchangeable.
  const LiquidMorphRuntime({required this.elementId});

  /// The id of the panel this would carve.
  final String elementId;

  /// No-op. There is no document here, and no clock to run.
  void start({
    required CoreMorphBlob anchor,
    required CoreMorphBlob panel,
    required CoreMorphSpring spring,
    int resolution = CoreLiquidMorphOutline.defaultResolution,
  }) {}

  /// No-op. Nothing was started.
  void dispose() {}
}
