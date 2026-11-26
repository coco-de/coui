import 'package:coui_core/src/component/contracts/avatar/avatar_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for avatar components.
///
/// All 시각 chrome (including composite-layout insets such as
/// `badgeInset`) flows through the single [style] slot — see
/// [CoreAvatarStyle] for the merge chain. The semantic identifiers
/// (`size`, `shape`) are **widget-only**: the Theme cannot override them
/// (a semantic-identifier theme override would stomp the caller's `size:`
/// / `shape:` and split Flutter from Web), so only the [style] slot lives
/// here (style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만").
/// There is no per-shape slot: a `style.borderRadius` set here wins over
/// both shapes' corners, so a project that sets one draws every avatar —
/// disc and tile alike — with it.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreAvatarTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance avatarStyle
/// ```
@immutable
class CoreAvatarTheme {
  /// Creates a [CoreAvatarTheme].
  const CoreAvatarTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreAvatarStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAvatarTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
