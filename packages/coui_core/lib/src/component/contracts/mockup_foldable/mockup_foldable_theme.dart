import 'package:coui_core/src/component/contracts/mockup_foldable/mockup_foldable_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `MockupFoldable`.
///
/// Every value flows through the single [style] slot — see
/// [CoreMockupFoldableStyle] for what it states. The two faces are
/// `MockupDevice`s, so a project recolours them through
/// `style.innerDeviceStyle` / `style.coverDeviceStyle`.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreMockupFoldableTheme.style                // 프로젝트 공통
///   → widget per-instance mockupFoldableStyle
/// ```
@immutable
class CoreMockupFoldableTheme {
  /// Creates a [CoreMockupFoldableTheme].
  const CoreMockupFoldableTheme({this.style});

  /// Project-wide style applied to every `MockupFoldable`.
  ///
  /// Resolved before any per-instance `widget.mockupFoldableStyle`.
  final CoreMockupFoldableStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMockupFoldableTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
