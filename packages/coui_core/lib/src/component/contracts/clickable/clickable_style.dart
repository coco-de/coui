/// Per-instance style for `Clickable`.
library;

import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/window_panel/core_title_bar_drag.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Clickable` should render.
///
/// `Clickable` is an interaction wrapper — it owns cursor, focus
/// ring, press feedback and keyboard activation, but it has no visual
/// variant. Every chrome decision flows through this single style
/// slot.
///
/// Behavioural / semantic fields (`child`, `enabled`, `focusOutline`,
/// `enableFeedback`, callbacks) stay flat on the widget; only visual
/// chrome lives here.
///
/// ```text
/// design system default (static const)
///   → CoreClickableTheme.style                      // 프로젝트 공통
///   → parent component slot override
///   → widget.clickableStyle                         // 인스턴스별
/// ```
@immutable
class CoreClickableStyle implements CoreStyle<CoreClickableStyle> {
  /// Creates a [CoreClickableStyle].
  const CoreClickableStyle({
    this.borderRadius,
    this.focusOutlineStyle,
    this.pressedScale,
    this.pressedTranslate,
    this.pressedBoxShadow,
    this.disabledOpacity,
    this.duration,
    this.pressDuration,
  });

  // ─── Design-system defaults (Phase 6f option D) ───────────────────
  // `Clickable` has no visual variant, so every default is a plain
  // static const here — there is no `defaultsByVariant` map.

  /// Default focus-ring corner radius (matches the legacy
  /// `Clickable` fallback of `CoreRadius.radius4`).
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius4,
  );

  /// Default focus-outline style — fully filled slot the resolver
  /// uses as the base before merging the per-instance
  /// [focusOutlineStyle] override on top. Single slot pairs 1:1 with
  /// the instance field above.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(
        align: CoreFocusOutlineStyle.defaultAlign,
        borderColor: CoreFocusOutlineStyle.defaultBorderColor,
        borderWidth: CoreFocusOutlineStyle.defaultBorderWidth,
        offsetColor: CoreFocusOutlineStyle.defaultOffsetColor,
      );

  /// Default scale applied while the clickable is pressed. `1.0`
  /// disables the press-shrink feedback.
  static const double defaultPressedScale = 0.97;

  /// Default offset the control travels while pressed. Zero leaves the
  /// control where it is, so a style that does not state a shift gets
  /// none — the press reads as the shrink from [defaultPressedScale].
  static const CoreOffset defaultPressedTranslate = .zero;

  /// Default opacity applied while the clickable is disabled.
  ///
  /// This is the one disabled treatment still expressed as a multiplier
  /// rather than a `disabledContent` / `disabledContainer` /
  /// `disabledOutline` token, and deliberately so for now.
  ///
  /// `Clickable` dims an arbitrary caller subtree, not a known set of text
  /// and chrome, so no single foreground token describes it — the child may
  /// be an image or custom painting that a colour cannot mute. More
  /// importantly, roughly two thirds of the components built on `Clickable`
  /// currently carry no disabled colours of their own and rely on this
  /// multiplier as their only disabled affordance; dropping it here would
  /// silently make "disabled" look identical to "enabled" for them.
  ///
  /// The reverse problem is real too: components that *do* define disabled
  /// colours (button, chip, checkbox, toggle, switch_field, …) get this
  /// multiplier applied on top of them, which is exactly the unpredictable
  /// contrast that dedicated tokens exist to avoid. Fixing that needs
  /// per-consumer disabled tokens plus a visual pass over each one, so it
  /// is tracked separately rather than changed blind here.
  static const double defaultDisabledOpacity = CoreOpacity.opacity50;

  /// Default container transition duration (150ms — hover / state
  /// transitions).
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default press-feedback transition duration (100ms — the scale
  /// shrink/restore). Unifies the legacy Flutter 50ms transform
  /// duration and the Web 100ms `duration-100`.
  static const Duration defaultPressDuration = Duration(
    milliseconds: CoreDuration.instant,
  );

  // ─── Fields ───────────────────────────────────────────────────────

  /// Focus-ring corner radius override.
  final CoreBorderRadius? borderRadius;

  /// Focus-outline style override — ring colour, width, offset and offset
  /// background. `null` (or any unset field) defers to
  /// [defaultFocusOutlineStyle].
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Pressed-state scale override. `1.0` disables the feedback.
  final double? pressedScale;

  /// How far the control moves while pressed.
  ///
  /// A shift rather than a shrink: a style whose whole idea is that a
  /// control sits above the page — a hard shadow cast down and to one
  /// side — says "pressed" by moving the control into that shadow, and
  /// scaling it instead reads as a different gesture entirely.
  ///
  /// Null leaves the control where it is, which is the default. Stated
  /// together with [pressedBoxShadow] it is the whole of the effect: the
  /// control travels the distance the shadow loses.
  final CoreOffset? pressedTranslate;

  /// The shadow the control casts while pressed.
  ///
  /// Null keeps the resting shadow, so a control that never states one is
  /// untouched. A style that raises its surfaces states the smaller stack
  /// here; the pair with [pressedTranslate] is what makes a press read as
  /// the surface going down rather than as it changing size.
  ///
  /// Deliberately without a `default*`, and it cannot have one: the null
  /// test decides whether the press-shadow exists at all. Flutter wraps
  /// the child in an `AnimatedContainer` carrying a `BoxDecoration` only
  /// when this is set, and Web emits the press-shadow custom property and
  /// its transition only then. A default would put that wrapper — and a
  /// shadow that overrides whatever the caller's own subtree draws —
  /// under every `Clickable` in the kit, which is most interactive
  /// components.
  final List<CoreShadowLayer>? pressedBoxShadow;

  /// Disabled-state opacity override.
  final double? disabledOpacity;

  /// Container transition duration override.
  final Duration? duration;

  /// Press-feedback transition duration override.
  final Duration? pressDuration;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreClickableStyle merge(CoreClickableStyle? other) {
    if (other == null) return this;
    return CoreClickableStyle(
      borderRadius: other.borderRadius ?? borderRadius,
      focusOutlineStyle: _mergeFocusOutline(
        focusOutlineStyle,
        other.focusOutlineStyle,
      ),
      pressedScale: other.pressedScale ?? pressedScale,
      pressedTranslate: other.pressedTranslate ?? pressedTranslate,
      pressedBoxShadow: other.pressedBoxShadow ?? pressedBoxShadow,
      disabledOpacity: other.disabledOpacity ?? disabledOpacity,
      duration: other.duration ?? duration,
      pressDuration: other.pressDuration ?? pressDuration,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreClickableStyle copyWith({
    CoreBorderRadius? borderRadius,
    CoreFocusOutlineStyle? focusOutlineStyle,
    double? pressedScale,
    CoreOffset? pressedTranslate,
    List<CoreShadowLayer>? pressedBoxShadow,
    double? disabledOpacity,
    Duration? duration,
    Duration? pressDuration,
  }) {
    return CoreClickableStyle(
      borderRadius: borderRadius ?? this.borderRadius,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      pressedScale: pressedScale ?? this.pressedScale,
      pressedTranslate: pressedTranslate ?? this.pressedTranslate,
      pressedBoxShadow: pressedBoxShadow ?? this.pressedBoxShadow,
      disabledOpacity: disabledOpacity ?? this.disabledOpacity,
      duration: duration ?? this.duration,
      pressDuration: pressDuration ?? this.pressDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreClickableStyle &&
          runtimeType == other.runtimeType &&
          borderRadius == other.borderRadius &&
          focusOutlineStyle == other.focusOutlineStyle &&
          pressedScale == other.pressedScale &&
          pressedTranslate == other.pressedTranslate &&
          _sameShadow(pressedBoxShadow, other.pressedBoxShadow) &&
          disabledOpacity == other.disabledOpacity &&
          duration == other.duration &&
          pressDuration == other.pressDuration;

  @override
  int get hashCode => Object.hashAll([
    borderRadius,
    focusOutlineStyle,
    pressedScale,
    pressedTranslate,
    ...?pressedBoxShadow,
    disabledOpacity,
    duration,
    pressDuration,
  ]);

  /// Layer-wise comparison — a shadow stack is a list, and two equal
  /// stacks built separately are different objects.
  static bool _sameShadow(
    List<CoreShadowLayer>? a,
    List<CoreShadowLayer>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  static CoreFocusOutlineStyle? _mergeFocusOutline(
    CoreFocusOutlineStyle? base,
    CoreFocusOutlineStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
