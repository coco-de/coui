/// Shared cross-variant style for `Mockup*` components.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:meta/meta.dart';

/// Immutable style describing the shared chrome surface used by every
/// mockup variant (Browser, Code, Device).
///
/// `CoreMockupStyle` is the cross-variant style slot — the per-variant
/// `CoreMockupBrowserStyle` / `CoreMockupCodeStyle` /
/// `CoreMockupDeviceStyle` keep their own variant-specific defaults and
/// chrome fields. The shared style is
/// folded into each variant's resolve chain as the lowest priority
/// override layer so a single project theme can recolour every mockup
/// frame at once.
///
/// ```text
/// design system default (CoreMockupXxxStyle.defaultX)
///   → CoreMockupTheme.style              // cross-variant shared
///   → CoreMockupXxxTheme.style           // per-variant override
///   → widget.mockupXxxStyle              // 인스턴스별
/// ```
///
/// All fields default to `null` — each variant supplies its own
/// design-system fallback when the cross-variant slot leaves a field
/// unset. The [frameColor] is only consumed by the Device variant; the
/// Browser / Code resolvers simply ignore it.
///
/// **No `default*` on this class, deliberately — the defaults live on
/// the variants.** This class is the shared *override* layer, and
/// its nulls are what let each variant's own default through: Flutter
/// folds a non-null `CoreMockupTheme.style` into a seed
/// `CoreMockupXxxStyle` slotted ABOVE the variant's `const` base
/// (unset fields stay null, so the variant default still wins), and Web
/// does the same or reads it as the middle rung of
/// `merged.X ?? mkStyle?.X ?? CoreMockupXxxStyle.defaultX` — either way a
/// non-null value here makes the variant default unreachable. On Device
/// the [frameColor] arrives as a stated `railColor`, which makes the body
/// that solid instead of its default rail gradient
/// (`CoreMockupDeviceStyle.resolveBodyGradient`);
/// `CoreMockupDeviceStyle.defaultRailColor` is only that solid's colour.
///
/// A single constant also could not be correct for variants that
/// disagree on every field it would have to cover: [borderRadius] is
/// `radius8` on Code, `radius14` on Browser,
/// and `radius24` on Device (phone — the tablet body is `radius16`);
/// [backgroundColor] is `surfaceContainerLow` on both Code and Browser (its
/// window body), and `surface` on Device (its screen);
/// [borderColor] is `outlineVariant` on Browser and a mode-invariant
/// hardware rim colour on Device, and neither it nor [frameColor] is
/// consumed by every variant. Whatever value were chosen would be
/// forwarded into every seed and would permanently replace every
/// per-variant default with it.
@immutable
class CoreMockupStyle implements CoreStyle<CoreMockupStyle> {
  /// Creates a [CoreMockupStyle].
  const CoreMockupStyle({
    this.backgroundColor,
    this.borderColor,
    this.frameColor,
    this.borderRadius,
  });

  /// Background color for the mockup content area. When null, each variant
  /// uses its own default (`surfaceContainerLow` on Code and on the
  /// Browser's window body, `surface` on the Device screen).
  ///
  /// **Deliberately has no `default*` — absence is the design.**
  final CoreColor? backgroundColor;

  /// Border / outline color of the mockup frame. When null, each bordered
  /// variant uses its own default: `outlineVariant` on Browser, and on
  /// Device a hardware rim colour that stays the same in light and dark
  /// mode. Code has no border.
  ///
  /// Code has no border field, so a constant here would be dead for it.
  /// **Deliberately has no `default*` — absence is the design.**
  final CoreColor? borderColor;

  /// Frame fill color for the mockup outer shell (Device variant only —
  /// its body).
  ///
  /// Browser / Code ignore this field. When null, Device paints its default
  /// rail gradient; a stated color makes the Device body that solid
  /// (`CoreMockupDeviceStyle.resolveBodyGradient`).
  /// **Deliberately has no `default*` — absence is the design.**
  final CoreColor? frameColor;

  /// Border radius override for the outer frame. When null, each variant
  /// uses its own default — `radius8` (Code), `radius14` (Browser),
  /// `radius24` / `radius16` (Device phone / tablet).
  ///
  /// **Deliberately has no `default*` — absence is the design.**
  final CoreBorderRadius? borderRadius;

  @override
  CoreMockupStyle merge(CoreMockupStyle? other) {
    if (other == null) return this;
    return CoreMockupStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      frameColor: other.frameColor ?? frameColor,
      borderRadius: other.borderRadius ?? borderRadius,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreMockupStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreColor? frameColor,
    CoreBorderRadius? borderRadius,
  }) => .new(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    frameColor: frameColor ?? this.frameColor,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMockupStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          frameColor == other.frameColor &&
          borderRadius == other.borderRadius;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    frameColor,
    borderRadius,
  );
}
