/// Per-instance style for `FocusOutline`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/component/host_derived.dart';
import 'package:coui_core/src/effect/focus_ring.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `FocusOutline` should render.
///
/// `CoreFocusOutlineStyle` carries chrome / dimensional flat
/// fields. Behavioural / semantic fields (`child`, `focused`,
/// `shape`) stay flat on the widget (Epic #1302 원칙 6/7).
///
/// ```text
/// design system default
///   → CoreFocusOutlineTheme (legacy flat fields)
///   → CoreFocusOutlineTheme.style                   // 프로젝트 공통
///   → parent component slot override
///   → widget.focusOutlineStyle                      // 인스턴스별
/// ```
@immutable
class CoreFocusOutlineStyle implements CoreStyle<CoreFocusOutlineStyle> {
  /// Creates a [CoreFocusOutlineStyle].
  const CoreFocusOutlineStyle({
    this.align,
    this.borderRadius,
    this.circleBorderRadius,
    this.borderColor,
    this.borderWidth,
    this.offsetColor,
    this.duration,
    this.ringOpacity,
  });

  /// Distance from the child's edge to the ring's outer edge
  /// (logical px, pre-scaling).
  final double? align;

  /// Border radius override (rectangle shape only).
  ///
  /// **No `defaultBorderRadius`, deliberately — the right value belongs
  /// to whatever this ring is drawn around, so no constant can hold
  /// it.** Hosts inject their own resolved radius into this slot
  /// (`Button` passes `focusOutlineStyle?.borderRadius ?? <its own
  /// resolved radius>`; the subfocus infra passes its focus-ring
  /// radius), and a host that wants square ring corners simply leaves it
  /// null: Flutter's ring-radius helper returns `.zero` on null, and Web
  /// spreads `'border-radius': ?radius` so the rectangle arm emits no
  /// property at all. A constant would round every focus ring in the
  /// kit — including the ones deliberately drawn around square children
  /// — and would be the wrong number for each host besides (a button's
  /// corner differs per size, `radius6` to `radius16`; cards are
  /// `radius16`). Contrast
  /// [circleBorderRadius], which *does* have a default: the circle shape
  /// has one correct radius (full pill) regardless of host.
  ///
  /// `@hostDerived` tells the Figma reader this is "value comes from the
  /// host", not "nothing is drawn" — otherwise it exports the field as an
  /// absence and the canvas is asked to show square corners.
  @hostDerived
  final CoreBorderRadius? borderRadius;

  /// Border radius override applied when the focus outline `shape` is
  /// circle. Defaults to [defaultCircleBorderRadius] (all-9999 token)
  /// so the ring follows a full pill; designers can override to tune the
  /// circular ring curvature.
  final CoreBorderRadius? circleBorderRadius;

  /// Ring colour override.
  final CoreColor? borderColor;

  /// Ring width override (logical px, pre-scaling).
  final double? borderWidth;

  /// Colour of the gap band between the child's edge and the ring's
  /// inner edge. `null` → [defaultOffsetColor] (transparent: the gap
  /// shows whatever is behind the child).
  ///
  /// The band is painted only outside the child, never behind it, so a
  /// translucent child body does not show it through. A host whose
  /// background is unknown states `CoreFocusRing.opaqueOffsetColor`
  /// here to turn the band on.
  final CoreColor? offsetColor;

  /// Animation duration for the focus ring fade transition.
  final Duration? duration;

  /// Opacity multiplier for the focus ring. `null` uses
  /// [defaultRingOpacity]. `FocusOutline` applies it with
  /// `CoreColor.scaleAlpha` on top of whichever `borderColor` is in effect
  /// (the default or an override), so setting `ringOpacity` alone,
  /// without touching `borderColor`, dims the ring on both platforms.
  final double? ringOpacity;

  /// Default offset between the child's edge and the ring's outer edge.
  ///
  /// `ringOffset (2px)` + `ringWidth (2px)` = 4px total outer extension:
  /// a 2px gap next to the child, then the 2px ring.
  static const double defaultAlign =
      CoreFocusRing.ringOffset + CoreFocusRing.ringWidth;

  /// Default ring width (2px).
  static const double defaultBorderWidth = CoreFocusRing.ringWidth;

  /// Default focus-ring opacity multiplier (no-op — `1.0`).
  /// `FocusOutline`'s own resolver is the single place that applies this
  /// multiplier (via `CoreColor.scaleAlpha`) on top of the resolved
  /// `borderColor` — the multiplier is deliberately *not* also baked
  /// into [defaultBorderColor], so it is applied exactly once regardless
  /// of whether the default or an override colour is in effect.
  static const double defaultRingOpacity = CoreFocusRing.ringOpacity;

  /// Default ring colour — the dedicated `focusRing` slot, at full
  /// opacity. The focus-ring opacity multiplier ([ringOpacity] /
  /// [defaultRingOpacity]) is applied on top of this by `FocusOutline`'s
  /// own resolver, not baked in here — see [defaultRingOpacity].
  static const CoreColor defaultBorderColor = CoreFocusRing.ringColor;

  /// Default gap band colour — transparent, so the gap between the child
  /// and the ring shows the background behind the child.
  ///
  /// An opaque band on a known background is a second outline glued to
  /// the control, and the wrong colour on any container that is not
  /// `surface`. Only hosts whose background is unknown opt in, with
  /// `CoreFocusRing.opaqueOffsetColor` — see that constant for why.
  static const CoreColor defaultOffsetColor = CoreFocusRing.ringOffsetColor;

  /// Default fade/scale animation duration (150ms — Web/Flutter parity).
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default border radius used when the focus outline `shape` is
  /// circle — any radius ≥ half the longest edge produces a circle.
  /// `CoreBorderRadius.toValue()` emits `var(--coui-radius-9999)` for
  /// the all-9999 token so designer overrides flow through.
  static const CoreBorderRadius defaultCircleBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreFocusOutlineStyle merge(CoreFocusOutlineStyle? other) {
    if (other == null) return this;
    return CoreFocusOutlineStyle(
      align: other.align ?? align,
      borderRadius: other.borderRadius ?? borderRadius,
      circleBorderRadius: other.circleBorderRadius ?? circleBorderRadius,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      offsetColor: other.offsetColor ?? offsetColor,
      duration: other.duration ?? duration,
      ringOpacity: other.ringOpacity ?? ringOpacity,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreFocusOutlineStyle copyWith({
    double? align,
    CoreBorderRadius? borderRadius,
    CoreBorderRadius? circleBorderRadius,
    CoreColor? borderColor,
    double? borderWidth,
    CoreColor? offsetColor,
    Duration? duration,
    double? ringOpacity,
  }) {
    return CoreFocusOutlineStyle(
      align: align ?? this.align,
      borderRadius: borderRadius ?? this.borderRadius,
      circleBorderRadius: circleBorderRadius ?? this.circleBorderRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      offsetColor: offsetColor ?? this.offsetColor,
      duration: duration ?? this.duration,
      ringOpacity: ringOpacity ?? this.ringOpacity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFocusOutlineStyle &&
          runtimeType == other.runtimeType &&
          align == other.align &&
          borderRadius == other.borderRadius &&
          circleBorderRadius == other.circleBorderRadius &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          offsetColor == other.offsetColor &&
          duration == other.duration &&
          ringOpacity == other.ringOpacity;

  @override
  int get hashCode => Object.hash(
    align,
    borderRadius,
    circleBorderRadius,
    borderColor,
    borderWidth,
    offsetColor,
    duration,
    ringOpacity,
  );
}
