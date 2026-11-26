/// Per-instance style for `Mask`.
library;

import 'package:coui_core/src/component/contracts/mask/mask_half.dart';
import 'package:coui_core/src/component/contracts/mask/mask_shape.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Mask` renders.
///
/// `Mask` chrome is behaviour-shaped — both fields describe how the
/// caller-supplied child is clipped rather than visual chrome like
/// padding/color. They still belong on the per-instance Style slot so
/// `CoreMaskTheme` can ship a project default and individual widget
/// instances can override.
///
/// ```text
/// design system default
///   → CoreMaskTheme.style                // 프로젝트 공통
///   → widget.maskStyle                   // 인스턴스별
/// ```
@immutable
class CoreMaskStyle implements CoreStyle<CoreMaskStyle> {
  /// Creates a [CoreMaskStyle].
  const CoreMaskStyle({this.shape, this.half});

  // ─── Design-system defaults ────────────────────
  //
  // Both resolvers previously spelled these as inline `.squircle` /
  // `.none` literals at the end of their own fallback chains — two
  // statements of the same decision, one per platform. Named here so
  // there is one.

  /// Default mask shape — the rounded square. A mask with no shape stated
  /// still has to clip to something, and the squircle is the shape that
  /// reads as "masked" without asserting a specific silhouette.
  static const CoreMaskShape defaultShape = .squircle;

  /// Default half-crop — none, i.e. the whole shape renders. Cropping to
  /// half is what a caller asks for, never what it gets by omission.
  static const CoreMaskHalf defaultHalf = .none;

  /// Mask shape. `null` defers to [defaultShape].
  final CoreMaskShape? shape;

  /// Half-crop. `null` defers to [defaultHalf].
  final CoreMaskHalf? half;

  @override
  CoreMaskStyle merge(CoreMaskStyle? other) {
    if (other == null) return this;
    return CoreMaskStyle(
      shape: other.shape ?? shape,
      half: other.half ?? half,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreMaskStyle copyWith({CoreMaskShape? shape, CoreMaskHalf? half}) =>
      .new(shape: shape ?? this.shape, half: half ?? this.half);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMaskStyle &&
          runtimeType == other.runtimeType &&
          shape == other.shape &&
          half == other.half;

  @override
  int get hashCode => Object.hash(shape, half);
}
