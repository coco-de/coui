import 'package:coui_core/src/component/contracts/dot_indicator/dot_indicator_style.dart';
import 'package:meta/meta.dart';

/// Dot indicator component theme overrides.
///
/// Holds the project [style] applied to every `DotIndicator` whose
/// widget-level `dotIndicatorStyle` is null.
///
/// 시각 chrome 은 전부 [style] 슬롯으로만 흐른다
/// (style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만").
/// Semantic identifier (`direction` / `size`) 는 **widget-only** — Theme 이
/// override 하면 caller 의 `direction:` / `size:` 를 짓밟고 Flutter 가 Web 과
/// 갈라지므로 Theme 에 두지 않는다. DotIndicator 는 chrome variant 가
/// 없어 `variantStyles` 슬롯을 노출하지 않는다. size 별 기본값은
/// `CoreDotIndicatorStyle.defaultsBySize` 가 단일 출처다.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreDotIndicatorTheme.style                   // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance dotIndicatorStyle
/// ```
@immutable
class CoreDotIndicatorTheme {
  /// Creates a [CoreDotIndicatorTheme].
  const CoreDotIndicatorTheme({this.style});

  /// Project-wide composite style applied to every `DotIndicator`.
  ///
  /// Resolved before any per-instance `widget.dotIndicatorStyle`.
  final CoreDotIndicatorStyle? style;

  @override
  bool operator ==(Object other) {
    return other is CoreDotIndicatorTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
