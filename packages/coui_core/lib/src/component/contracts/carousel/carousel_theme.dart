import 'package:coui_core/src/component/contracts/carousel/carousel_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for carousel components.
///
/// Holds the project [style] applied to every `Carousel` whose
/// widget-level `carouselStyle` is null.
///
/// 시각 chrome 은 전부 [style] 슬롯으로만 흐른다
/// (style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만").
/// Semantic / behaviour identifiers (`autoPlay` / `showIndicators` /
/// `showNavigation` / `duration` / `wrap` / `pauseOnHover` /
/// `autoplaySpeed` / `speed`) 는 **widget-only** — Theme 이 override
/// 하면 caller 의 widget prop 을 짓밟고 Flutter 가 Web (이미 무시) 과
/// 갈라지므로 Theme 에 두지 않는다. Carousel 은 variant enum 이 없어
/// `variantStyles` 슬롯은 노출하지 않는다 ([style] 만).
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreCarouselTheme.style                    // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance carouselStyle
/// ```
@immutable
class CoreCarouselTheme {
  /// Creates a [CoreCarouselTheme].
  const CoreCarouselTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreCarouselStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCarouselTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
