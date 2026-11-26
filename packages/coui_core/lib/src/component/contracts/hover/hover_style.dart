/// Per-instance style for `Hover`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Hover` should render.
///
/// `CoreHoverStyle` carries the per-instance visual-effect chrome
/// (scale / fade / brighten factors, the `shadow` effect's box-shadow
/// stack, and the effect transition duration) plus the hover-state
/// timing defaults (wait / show / min durations). The widget retains
/// the `effect` enum + `onHover` callbacks — those are behaviour, not
/// style.
///
/// ```text
/// design system default (CoreHoverStyle.defaultX)
///   → CoreHoverTheme.style                      // 프로젝트 공통
///   → widget timing parameters                  // 인스턴스별 (wait/show/min)
///   → widget.hoverStyle                         // 인스턴스별 (full chrome)
/// ```
@immutable
class CoreHoverStyle implements CoreStyle<CoreHoverStyle> {
  /// Creates a [CoreHoverStyle].
  const CoreHoverStyle({
    this.scaleUpFactor,
    this.scaleDownFactor,
    this.fadeOpacity,
    this.brightenFactor,
    this.shadowBoxShadow,
    this.shadowBaseColor,
    this.effectDuration,
    this.waitDuration,
    this.showDuration,
    this.minDuration,
  });

  // ═══════════════════════════════════════════════════
  // 1. Defaults — single
  // ═══════════════════════════════════════════════════
  //
  // Design-system defaults applied by `resolveHover` when neither
  // the theme nor the per-instance Style sets the matching prop. Each
  // const here is paired one-to-one with a prop on `CoreHoverStyle` —
  // the resolver does `merged.X ?? CoreHoverStyle.defaultX`. Single
  // source of truth shared by Flutter and Web.

  /// Default scale factor applied for the `scaleUp` effect (1.05).
  ///
  /// Mirrors the legacy Web `hover:scale-105` class.
  static const double defaultScaleUpFactor = 1.05;

  /// Default scale factor applied for the `scaleDown` effect (0.95).
  ///
  /// Mirrors the legacy Web `hover:scale-95` class.
  static const double defaultScaleDownFactor = 0.95;

  /// Default opacity applied for the `fade` effect (0.8).
  ///
  /// Mirrors the legacy Web `hover:opacity-80` class.
  static const double defaultFadeOpacity = CoreOpacity.opacity80;

  /// Default brightness multiplier applied for the `brighten` effect
  /// (1.1).
  ///
  /// Mirrors the legacy Web `hover:brightness-110` class.
  static const double defaultBrightenFactor = 1.1;

  /// Default drop-shadow stack applied for the `shadow` effect.
  ///
  /// Uses the same large shadow the Popover / Tooltip overlays and the
  /// legacy Web `hover:shadow-lg` class share, so Flutter and Web can
  /// only diverge via an explicit per-instance override. Each layer's
  /// base colour is resolved through `colorScheme.shadow` at render
  /// time on both platforms.
  static const List<CoreShadowLayer> defaultShadowBoxShadow = CoreShadow.lg;

  /// Default base colour each [defaultShadowBoxShadow] layer is tinted
  /// with — the M3 `shadow` token.
  ///
  /// Resolved through the colour scheme on both platforms
  /// (`scheme.resolve(...).toValue()` on Flutter, `colorScheme.shadow`
  /// → CSS on Web) so the `shadow` effect honours the active theme's
  /// shadow colour. Mirrors the legacy `colorScheme.shadow` lookup.
  static const CoreColor defaultShadowBaseColor = CoreColor.token(
    CoreColors.shadow,
  );

  /// Default transition duration for the hover visual effect
  /// (200 ms).
  ///
  /// Mirrors the legacy Web `duration-200` class.
  static const Duration defaultEffectDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default delay before the hover state is reported active (500 ms).
  ///
  /// The pointer must rest over the child for this long before
  /// `onHover(true)` fires.
  static const Duration defaultWaitDuration = Duration(
    milliseconds: CoreDuration.slow,
  );

  /// Default delay before the hover state is reported inactive after
  /// the pointer leaves (200 ms).
  static const Duration defaultShowDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default minimum duration the hover state stays active once
  /// reported, even if the pointer leaves quickly (0 ms).
  static const Duration defaultMinDuration = .zero;

  // ═══════════════════════════════════════════════════
  // 2. Props — visual effect chrome
  // ═══════════════════════════════════════════════════

  /// Scale factor applied for the `scaleUp` effect override. `null`
  /// defers to [defaultScaleUpFactor].
  final double? scaleUpFactor;

  /// Scale factor applied for the `scaleDown` effect override. `null`
  /// defers to [defaultScaleDownFactor].
  final double? scaleDownFactor;

  /// Opacity applied for the `fade` effect override. `null` defers to
  /// [defaultFadeOpacity].
  final double? fadeOpacity;

  /// Brightness multiplier applied for the `brighten` effect override.
  /// `null` defers to [defaultBrightenFactor].
  final double? brightenFactor;

  /// Drop-shadow stack applied for the `shadow` effect override.
  /// `null` defers to [defaultShadowBoxShadow].
  final List<CoreShadowLayer>? shadowBoxShadow;

  /// Base colour the `shadow` effect's layers are tinted with override.
  /// `null` defers to [defaultShadowBaseColor].
  final CoreColor? shadowBaseColor;

  /// Transition duration for the hover visual effect override. `null`
  /// defers to [defaultEffectDuration].
  final Duration? effectDuration;

  // ═══════════════════════════════════════════════════
  // 3. Props — timing
  // ═══════════════════════════════════════════════════

  /// Delay before the hover state is reported as active override.
  /// `null` defers to [defaultWaitDuration].
  final Duration? waitDuration;

  /// Delay before the hover state is reported as inactive after the
  /// pointer leaves override. `null` defers to [defaultShowDuration].
  final Duration? showDuration;

  /// Minimum duration the hover state stays active once reported
  /// override. `null` defers to [defaultMinDuration].
  final Duration? minDuration;

  /// Returns a copy with non-null fields from [other] overriding the
  /// matching fields here.
  @override
  CoreHoverStyle merge(CoreHoverStyle? other) {
    if (other == null) return this;
    return CoreHoverStyle(
      scaleUpFactor: other.scaleUpFactor ?? scaleUpFactor,
      scaleDownFactor: other.scaleDownFactor ?? scaleDownFactor,
      fadeOpacity: other.fadeOpacity ?? fadeOpacity,
      brightenFactor: other.brightenFactor ?? brightenFactor,
      shadowBoxShadow: other.shadowBoxShadow ?? shadowBoxShadow,
      shadowBaseColor: other.shadowBaseColor ?? shadowBaseColor,
      effectDuration: other.effectDuration ?? effectDuration,
      waitDuration: other.waitDuration ?? waitDuration,
      showDuration: other.showDuration ?? showDuration,
      minDuration: other.minDuration ?? minDuration,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreHoverStyle copyWith({
    double? scaleUpFactor,
    double? scaleDownFactor,
    double? fadeOpacity,
    double? brightenFactor,
    List<CoreShadowLayer>? shadowBoxShadow,
    CoreColor? shadowBaseColor,
    Duration? effectDuration,
    Duration? waitDuration,
    Duration? showDuration,
    Duration? minDuration,
  }) {
    return CoreHoverStyle(
      scaleUpFactor: scaleUpFactor ?? this.scaleUpFactor,
      scaleDownFactor: scaleDownFactor ?? this.scaleDownFactor,
      fadeOpacity: fadeOpacity ?? this.fadeOpacity,
      brightenFactor: brightenFactor ?? this.brightenFactor,
      shadowBoxShadow: shadowBoxShadow ?? this.shadowBoxShadow,
      shadowBaseColor: shadowBaseColor ?? this.shadowBaseColor,
      effectDuration: effectDuration ?? this.effectDuration,
      waitDuration: waitDuration ?? this.waitDuration,
      showDuration: showDuration ?? this.showDuration,
      minDuration: minDuration ?? this.minDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreHoverStyle &&
          runtimeType == other.runtimeType &&
          scaleUpFactor == other.scaleUpFactor &&
          scaleDownFactor == other.scaleDownFactor &&
          fadeOpacity == other.fadeOpacity &&
          brightenFactor == other.brightenFactor &&
          _shadowEq(shadowBoxShadow, other.shadowBoxShadow) &&
          shadowBaseColor == other.shadowBaseColor &&
          effectDuration == other.effectDuration &&
          waitDuration == other.waitDuration &&
          showDuration == other.showDuration &&
          minDuration == other.minDuration;

  @override
  int get hashCode => Object.hash(
    scaleUpFactor,
    scaleDownFactor,
    fadeOpacity,
    brightenFactor,
    shadowBoxShadow == null ? null : Object.hashAll(shadowBoxShadow!),
    shadowBaseColor,
    effectDuration,
    waitDuration,
    showDuration,
    minDuration,
  );

  static bool _shadowEq(
    List<CoreShadowLayer>? a,
    List<CoreShadowLayer>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
