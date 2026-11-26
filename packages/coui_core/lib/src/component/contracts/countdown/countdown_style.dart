/// Per-instance style for `Countdown`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Countdown` should render.
///
/// `CoreCountdownStyle` carries chrome / dimensional flat fields
/// plus the nested label text slot. Behavioural fields (`value` —
/// the total countdown `Duration`) stay flat on the widget /
/// contract (Epic #1302 원칙 6/7 — semantic input).
///
/// `animationDuration` here is the **fade / digit-transition**
/// duration, NOT the total countdown length. Total length is a
/// semantic widget parameter, not chrome.
///
/// ```text
/// design system default
///   → CoreCountdownTheme.style                      // 프로젝트 공통
///   → parent component slot override
///   → widget.countdownStyle                         // 인스턴스별
/// ```
@immutable
class CoreCountdownStyle implements CoreStyle<CoreCountdownStyle> {
  /// Creates a [CoreCountdownStyle].
  const CoreCountdownStyle({
    this.fontSize,
    this.color,
    this.animationDuration,
    this.labelStyle,
  });

  // ─── Design-system defaults (Phase 6f single source) ──────────────
  // Variant-independent defaults live as static const here so that the
  // Flutter / Web resolvers reference the same canonical values.

  /// Fade / digit transition duration default (150 ms).
  static const Duration defaultAnimationDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default label text style — token-backed reference to the
  /// `headlineLarge` slot with the `onSurface` text colour layered on.
  /// Web emits `text-headline-large` from `token.name`; Flutter
  /// resolves the slot through `theme.coreTypography.resolve(...)` then
  /// applies the `color` overlay. Single source for both platforms'
  /// resting display style.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.headlineLarge,
    color: CoreColor.token(CoreColors.onSurface),
  );

  // ── Chrome (flat) ────────────────────────────

  /// Display font size override (logical px).
  ///
  /// No `default*`, and it must not get one. Both resolvers fold this
  /// flat field into an overlay that merges ON TOP of
  /// [defaultLabelStyle] ⊕ [labelStyle], so whatever sits here outranks
  /// both — and the resting font size is already stated, by the
  /// `headlineLarge` role inside [defaultLabelStyle]. A `static const`
  /// would therefore (a) make the [labelStyle] slot's own `fontSize`
  /// unreachable and (b) replace a token role with a raw scalar, which
  /// on Flutter also drops out of the text-scaling axis the role is
  /// materialised through. The resolvers rely on the overlay being
  /// null-only to stay a no-op; on Web a non-null one turns
  /// `emitTypography` from "role class, no inline" into a permanent
  /// inline `font-size` that beats the class.
  final double? fontSize;

  /// Display text colour override.
  ///
  /// No `default*` — same overlay position as [fontSize], and the
  /// resting colour is likewise already stated: `onSurface`, inside
  /// [defaultLabelStyle]. A default here would win over
  /// `labelStyle.color`, inverting the documented precedence, and would
  /// emit a standing inline `color` on Web where only the token class
  /// renders today.
  final CoreColor? color;

  /// Digit transition / fade animation duration override.
  ///
  /// **NOT** the total countdown length — that is a semantic widget
  /// parameter (see contract `value`).
  final Duration? animationDuration;

  // ── Slot Styles (nested) ─────────────────────

  /// Label text style override (applied to the numeric child).
  final CoreTextStyle? labelStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreCountdownStyle merge(CoreCountdownStyle? other) {
    if (other == null) return this;
    return CoreCountdownStyle(
      fontSize: other.fontSize ?? fontSize,
      color: other.color ?? color,
      animationDuration: other.animationDuration ?? animationDuration,
      labelStyle: _mergeText(labelStyle, other.labelStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreCountdownStyle copyWith({
    double? fontSize,
    CoreColor? color,
    Duration? animationDuration,
    CoreTextStyle? labelStyle,
  }) {
    return CoreCountdownStyle(
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      animationDuration: animationDuration ?? this.animationDuration,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCountdownStyle &&
          runtimeType == other.runtimeType &&
          fontSize == other.fontSize &&
          color == other.color &&
          animationDuration == other.animationDuration &&
          labelStyle == other.labelStyle;

  @override
  int get hashCode =>
      Object.hash(fontSize, color, animationDuration, labelStyle);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
