import 'package:coui_core/src/component/contracts/validation_badge/validation_badge_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `ValidationBadge`.
///
/// Holds the project [style] applied to every `ValidationBadge` whose
/// widget-level `style` is null.
///
/// 시각 chrome 은 전부 [style] 슬롯으로만 흐른다 (style-contract.md
/// "CoreXxxTheme — style + variantStyles 슬롯만"). The validation badge
/// has no `variant` enum — its per-state chrome is keyed by the semantic
/// `state` widget prop, not by a theme-overridable variant — so only the
/// [style] slot is exposed (no `variantStyles`).
///
/// Semantic identifiers (`size` / `state`) 는 **widget-only** — Theme 이
/// override 하면 caller 의 `size:` / `state:` 를 짓밟고 Flutter 가 Web 과
/// 갈라지므로 Theme 에 두지 않는다 (이전의 평면 `size` 필드 제거).
///
/// ### Resolve chain.
///
/// ```text
/// design system default for state / size
///   → CoreValidationBadgeTheme.style            // 프로젝트 공통
///   → widget per-instance style
/// ```
@immutable
class CoreValidationBadgeTheme {
  /// Creates a [CoreValidationBadgeTheme].
  const CoreValidationBadgeTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreValidationBadgeStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreValidationBadgeTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
