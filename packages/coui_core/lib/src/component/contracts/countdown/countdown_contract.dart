/// Platform-independent contract for unified countdown components.
///
/// Defines the interface that all Countdown implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/countdown/countdown_style.dart';

/// Contract for a unified countdown component.
///
/// Displays a numeric value with transition animation when the value
/// changes. The parent component is responsible for updating the
/// value over time.
///
/// Per Epic #1302 chrome / dimensional / animation overrides flow
/// through the single [countdownStyle] field — see
/// [CoreCountdownStyle] for the merge chain.
///
/// Behavioural fields (`value`, `min`, `max`) stay flat on the widget
/// (Epic #1302 원칙 6/7 — semantic / range input). Their cross-platform
/// defaults live as `static const` on this contract so Flutter and Web
/// widget constructors share a single source of truth (`defaultMinValue`
/// / `defaultMaxValue`) — see cautions.md "behaviour default 위치".
///
/// Type parameters:
/// - [W] — platform widget type
///   (Flutter `Widget`, Web `Component`).
abstract interface class CoreCountdownContract<W> {
  // ─── Behaviour defaults (single source for Flutter + Web) ─────────
  // Behaviour values stay flat on the widget; their defaults are
  // anchored here so both platforms reference the same const and
  // silent divergence is impossible.

  /// Default lower bound of the countdown display range.
  static const int defaultMinValue = 0;

  /// Default upper bound of the countdown display range.
  static const int defaultMaxValue = 99;

  /// The countdown value to display.
  ///
  /// Values outside the inclusive `[min, max]` range will be clamped.
  int get value;

  /// Minimum value the countdown can display (inclusive).
  int get min;

  /// Maximum value the countdown can display (inclusive).
  int get max;

  /// Per-instance chrome / dimensional / animation style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreCountdownTheme.style
  ///   → parent component slot override
  ///   → widget.countdownStyle
  /// ```
  CoreCountdownStyle? get countdownStyle;
}
