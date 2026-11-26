/// Per-instance style for `Swap`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Swap` should render.
///
/// `CoreSwapStyle` is **platform-neutral** (Epic #1415 option D /
/// Phase 6f). Chrome / animation overrides flow through the
/// nested-merge chain:
///
/// ```text
/// design system default (this class' `static const defaultX`)
///   → CoreSwapTheme.style                          // 프로젝트 공통
///   → parent component slot override
///   → widget.swapStyle                             // 인스턴스별
/// ```
///
/// Behaviour / semantic fields (`animation` variant enum, `checked`
/// boolean toggle, `onContent` / `offContent` composition slots,
/// `onToggle` callback) stay flat on the widget / contract
/// (Epic #1302 원칙 6/7).
@immutable
class CoreSwapStyle implements CoreStyle<CoreSwapStyle> {
  /// Creates a [CoreSwapStyle].
  const CoreSwapStyle({this.duration, this.textStyle, this.clickableStyle});

  // ─── Design-system defaults (Phase 6f / 6g, Epic #1696 Phase 4) ──
  // Variant-independent defaults live here as `static const`. Flutter
  // and Web resolvers read these directly so both platforms share a
  // single source of truth. Replaces the previous `CoreSwapTokens`
  // holder — Tokens 폐기 + 1:1:1:1 매핑.

  /// Default swap animation duration — `CoreDuration.moderate` (300 ms).
  /// Matches the Material "smooth" transition step. Used by Flutter
  /// `AnimationController.duration` and Web CSS `transition`
  /// duration so the toggle animates identically on both platforms.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// Default body typography role applied to the swap slots'
  /// children. References `CoreTextStyles.bodyMedium` so the scale
  /// is shared with the rest of the design system. Carries the
  /// `CoreColors.onSurface` colour token so the slot is a complete
  /// default (effective only when the child does not set its own
  /// colour).
  ///
  /// Stored as a token-backed `CoreTextStyle.token(...)` so the Web
  /// resolver can recover the token name (`bodyMedium`) for the
  /// `text-${ts.bodyMedium}` Tailwind class fragment. Flutter
  /// materialises the token via `theme.coreTypography.resolve(...)`.
  static const CoreTextStyle defaultTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default nested [CoreClickableStyle] slot for the composed root
  /// `Clickable` — an empty partial: an interactive swap takes the
  /// Clickable's own standard press / focus / cursor chrome as-is.
  /// Named so the resolver's
  /// `defaultClickableStyle.merge(merged.clickableStyle)` forward has a
  /// single-source default.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle();

  /// Animation duration override.
  final Duration? duration;

  /// Body typography role override applied to the swap slots' children.
  /// Text colour is carried via [CoreTextStyle.color] inside this slot
  /// (sb8 — raw `textColor` field removed).
  final CoreTextStyle? textStyle;

  /// Style for the `Clickable` around the swap when it is interactive
  /// (`onToggle != null`) — press scale, durations, focus ring, disabled
  /// opacity. Laid over [defaultClickableStyle] and passed to the
  /// `Clickable` as is; the `Clickable` fills in the rest.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested [textStyle] /
  /// [clickableStyle] are merged recursively so a partial override only
  /// affects the fields it specifies.
  @override
  CoreSwapStyle merge(CoreSwapStyle? other) {
    if (other == null) return this;
    return CoreSwapStyle(
      duration: other.duration ?? duration,
      textStyle: _mergeText(textStyle, other.textStyle),
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreSwapStyle copyWith({
    Duration? duration,
    CoreTextStyle? textStyle,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreSwapStyle(
      duration: duration ?? this.duration,
      textStyle: textStyle ?? this.textStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSwapStyle &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          textStyle == other.textStyle &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(duration, textStyle, clickableStyle);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
