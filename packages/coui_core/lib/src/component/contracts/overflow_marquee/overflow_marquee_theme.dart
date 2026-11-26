/// Theme overrides for the unified OverflowMarquee component.
library;

import 'package:coui_core/src/component/contracts/overflow_marquee/overflow_marquee_style.dart';
import 'package:meta/meta.dart';

/// Project-level defaults for `OverflowMarquee`.
///
/// All chrome flows through the composite [style] slot — Theme carries
/// only `{style}` (style-contract.md "CoreXxxTheme — style +
/// variantStyles 슬롯만"; no `variantStyles` since the component has no
/// variant enum). Semantic enums (`direction`, `curve`) and the
/// behavioural boolean (`pauseOnHover`) are **widget-only** — Theme does
/// not override them, so the caller's `direction:` / `curve:` /
/// `pauseOnHover:` is never silently stomped.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreOverflowMarqueeTheme.style            // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance overflowMarqueeStyle
/// ```
///
@immutable
class CoreOverflowMarqueeTheme {
  /// Creates a [CoreOverflowMarqueeTheme].
  const CoreOverflowMarqueeTheme({this.style});

  /// Project-wide composite style applied to every `OverflowMarquee`.
  ///
  /// Resolved before any per-instance `widget.overflowMarqueeStyle`.
  /// Carries only dimensional / timing chrome.
  final CoreOverflowMarqueeStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreOverflowMarqueeTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
