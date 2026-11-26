/// Per-instance style for `NumberTicker`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `NumberTicker` should render.
///
/// `CoreNumberTickerStyle` carries the animation `duration` chrome
/// field plus the nested text style slot. The display text colour
/// lives inside the [textStyle] slot (`CoreTextStyle.color`).
/// Behavioural fields (`value`, `initialValue`, `formatter`) stay
/// flat on the widget / contract.
///
/// `duration` here is the **value interpolation** animation duration.
///
/// ```text
/// design system default (this class' `static const defaultX`)
///   → CoreNumberTickerTheme.style                   // 프로젝트 공통
///   → parent component slot override
///   → widget.numberTickerStyle                       // 인스턴스별
/// ```
@immutable
class CoreNumberTickerStyle implements CoreStyle<CoreNumberTickerStyle> {
  /// Creates a [CoreNumberTickerStyle].
  const CoreNumberTickerStyle({
    this.duration,
    this.textStyle,
  });

  // ── Phase 6f defaults — single source for both Flutter and Web ─

  /// Default value-interpolation animation duration (500 ms).
  ///
  /// Used by resolvers as the final fallback when neither
  /// `CoreNumberTickerTheme.style.duration` nor
  /// `widget.numberTickerStyle.duration` is set.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.slow,
  );

  /// Default display text style — `titleLarge` typography role (token-
  /// backed, no explicit colour so the formatted child inherits the
  /// ambient foreground). Single source for both Flutter and Web: the
  /// Flutter resolver materialises it via
  /// `defaultTextStyle.merge(override).toValue(theme:)`, the Web resolver
  /// emits the role class via `emitTypography(override, defaultTextStyle)`.
  static const CoreTextStyle defaultTextStyle = CoreTextStyle.token(
    CoreTextStyles.titleLarge,
  );

  // ── Chrome (flat) ────────────────────────────

  /// Value interpolation animation duration override.
  final Duration? duration;

  // ── Slot Styles (nested) ─────────────────────

  /// Text style override (applied to the formatted numeric child).
  ///
  /// Includes the display text colour via `CoreTextStyle.color`.
  final CoreTextStyle? textStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreNumberTickerStyle merge(CoreNumberTickerStyle? other) {
    if (other == null) return this;
    return CoreNumberTickerStyle(
      duration: other.duration ?? duration,
      textStyle: _mergeText(textStyle, other.textStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreNumberTickerStyle copyWith({
    Duration? duration,
    CoreTextStyle? textStyle,
  }) {
    return CoreNumberTickerStyle(
      duration: duration ?? this.duration,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreNumberTickerStyle &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          textStyle == other.textStyle;

  @override
  int get hashCode => Object.hash(duration, textStyle);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
