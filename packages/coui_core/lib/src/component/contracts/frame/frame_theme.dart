import 'package:coui_core/src/component/contracts/frame/frame_style.dart';
import 'package:meta/meta.dart';

/// Project-level overrides for `Frame` defaults.
///
/// Phase 6f migration (Epic #1579 §3, Issue #1594): chrome flat fields
/// (`backgroundColor`, `borderColor`, …) were absorbed into [style] so
/// that the Style class is the single source of truth for every chrome
/// slot. Behavioural / layout / sizing fields stay per-instance on the
/// widget.
///
/// Resolution chain (handled by `resolveFrame` in each platform):
///
/// ```text
/// design system default
///   → CoreFrameTheme.style                            // 프로젝트 공통
///   → parent component slot override
///   → widget.frameStyle                               // 인스턴스별
///   → widget chrome props (backgroundColor, borderColor, …)
/// ```
@immutable
class CoreFrameTheme {
  /// Creates a [CoreFrameTheme].
  const CoreFrameTheme({
    this.style,
  });

  /// Project-wide composite style applied to every `Frame`.
  ///
  /// Resolved before any per-instance `widget.frameStyle`.
  final CoreFrameStyle? style;

  /// Returns a copy with the given fields replaced.
  CoreFrameTheme copyWith({
    CoreFrameStyle? style,
  }) {
    return CoreFrameTheme(
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreFrameTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
