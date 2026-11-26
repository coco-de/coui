/// Platform-independent contract for the unified Mask component.
library;

import 'package:coui_core/src/component/contracts/mask/mask_half.dart';
import 'package:coui_core/src/component/contracts/mask/mask_shape.dart';

/// Contract for a unified mask container.
///
/// Crops the [child] to the given [shape], optionally keeping only one half.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreMaskContract<W> {
  /// Content clipped by the mask.
  W get child;

  /// Mask shape.
  CoreMaskShape get shape;

  /// Optional half-crop on top of [shape].
  CoreMaskHalf get half;
}
