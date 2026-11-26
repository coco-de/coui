import 'package:coui_core/src/component/contracts/progress/progress_style.dart';
import 'package:meta/meta.dart';

/// Radial progress component theme overrides.
///
/// Holds the project [style] applied to every `RadialProgress` whose
/// widget-level `radialProgressStyle` is null — see
/// [CoreRadialProgressStyle] for the merge chain. 모든 시각 chrome 은
/// 단일 [style] 슬롯으로만 흐른다 (style-contract.md "CoreXxxTheme —
/// style + variantStyles 슬롯만"; radial has no variants, so only
/// [style]).
///
/// ### Resolve chain.
///
/// ```text
/// CoreRadialProgressStyle.defaultX (static const)
///   → CoreRadialProgressTheme.style                // 프로젝트 공통
///   → parent component slot override
///   → widget.radialProgressStyle                   // 인스턴스별
/// ```
@immutable
class CoreRadialProgressTheme {
  /// Creates a [CoreRadialProgressTheme].
  const CoreRadialProgressTheme({this.style});

  /// Project-wide radial progress composite style.
  ///
  /// Resolved before any per-instance `widget.radialProgressStyle`.
  final CoreRadialProgressStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRadialProgressTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
