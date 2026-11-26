/// Per-instance style for `HoverGallery`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `HoverGallery` should render.
///
/// `CoreHoverGalleryStyle` carries chrome / dimensional /
/// animation flat fields. Behavioural / content fields (`imageUrls`,
/// `itemCount`, `itemBuilder`, `fit`) stay flat on the widget
/// (Epic #1302 원칙 6/7).
///
/// All Phase 6f design-system defaults live as `static const` on this
/// class — see [defaultHeight], [defaultBorderRadius],
/// [defaultAnimationDuration]. HoverGallery has no `variant` enum so
/// there is no `defaultsByVariant` map.
///
/// ```text
/// design system default (CoreHoverGalleryStyle.defaultX)
///   → CoreHoverGalleryTheme.style                   // 프로젝트 공통
///   → parent component slot override
///   → widget.hoverGalleryStyle                      // 인스턴스별
/// ```
@immutable
class CoreHoverGalleryStyle implements CoreStyle<CoreHoverGalleryStyle> {
  /// Creates a [CoreHoverGalleryStyle].
  const CoreHoverGalleryStyle({
    this.height,
    this.borderRadius,
    this.animationDuration,
  });

  // ─── Design-system defaults (Phase 6f option D) ──

  /// Default container height in logical px (pre-scaling).
  static const double defaultHeight = 300;

  /// Default container corner radius (pre-scaling).
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius16,
  );

  /// Default image-transition animation duration.
  static const Duration defaultAnimationDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  // ─── Fields ──

  /// Container height override (logical px, pre-scaling).
  final double? height;

  /// Container border radius override (pre-scaling).
  final CoreBorderRadius? borderRadius;

  /// Image transition animation duration override.
  final Duration? animationDuration;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreHoverGalleryStyle merge(CoreHoverGalleryStyle? other) {
    if (other == null) return this;
    return CoreHoverGalleryStyle(
      height: other.height ?? height,
      borderRadius: other.borderRadius ?? borderRadius,
      animationDuration: other.animationDuration ?? animationDuration,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreHoverGalleryStyle copyWith({
    double? height,
    CoreBorderRadius? borderRadius,
    Duration? animationDuration,
  }) {
    return CoreHoverGalleryStyle(
      height: height ?? this.height,
      borderRadius: borderRadius ?? this.borderRadius,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreHoverGalleryStyle &&
          runtimeType == other.runtimeType &&
          height == other.height &&
          borderRadius == other.borderRadius &&
          animationDuration == other.animationDuration;

  @override
  int get hashCode => Object.hash(height, borderRadius, animationDuration);
}
