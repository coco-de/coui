import 'package:coui_core/src/component/contracts/countdown/countdown_style.dart';
import 'package:meta/meta.dart';

/// Countdown component theme overrides.
///
/// Carries the project-wide composite [style] that applies to every
/// `Countdown`. Per-instance overrides come from
/// `widget.countdownStyle`.
///
/// Phase 6f single source — all chrome / dimensional defaults live on
/// `CoreCountdownStyle.defaultX` static const fields; this theme only
/// holds the project-level [style] override.
///
/// ### Resolve chain.
///
/// ```text
/// CoreCountdownStyle.defaultX (static const, single source)
///   → CoreCountdownTheme.style                      // 프로젝트 공통
///   → widget.countdownStyle                         // 인스턴스별
/// ```
@immutable
class CoreCountdownTheme {
  /// Creates a [CoreCountdownTheme].
  const CoreCountdownTheme({this.style});

  /// Project-wide composite style applied to every `Countdown`.
  ///
  /// Resolved before any per-instance `widget.countdownStyle`.
  final CoreCountdownStyle? style;

  @override
  bool operator ==(Object other) {
    return other is CoreCountdownTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
