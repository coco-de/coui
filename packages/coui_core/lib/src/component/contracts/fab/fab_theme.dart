import 'package:coui_core/src/component/contracts/fab/fab_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Fab`.
///
/// The visual chrome of every `Fab` flows through the single [style]
/// field — see [CoreFabStyle] for the merge chain.
///
/// 시각 chrome 은 전부 [style] 슬롯으로만 흐른다 (style-contract.md
/// "CoreXxxTheme — style + variantStyles 슬롯만"; FAB 는 variant 가
/// 없어 [style] 하나뿐). Semantic identifier `size` 는 **widget-only** —
/// Theme 이 override 하면 caller 의 `size:` 를 짓밟고 Flutter 가 Web
/// (이미 무시) 과 갈라지므로 Theme 에 두지 않는다.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreFabStyle.defaultX / defaultsBySize)
///   → CoreFabTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance fabStyle
/// ```
@immutable
class CoreFabTheme {
  /// Creates a [CoreFabTheme].
  const CoreFabTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreFabStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFabTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
