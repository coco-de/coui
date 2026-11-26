import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:meta/meta.dart';

/// Clickable component theme overrides.
///
/// Provides project-level chrome / dimensional / animation defaults
/// for `Clickable`, read via the inherited theme.
///
/// `Clickable` has no visual variant, so the theme carries only the
/// single composite [style] field — there is no `variantStyles` map.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreClickableStyle static const)
///   → CoreClickableTheme.style                      // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance clickableStyle
/// ```
@immutable
class CoreClickableTheme {
  /// Creates a [CoreClickableTheme].
  const CoreClickableTheme({this.style});

  /// Project-wide composite style applied to every `Clickable`.
  ///
  /// Resolved before any per-instance `widget.clickableStyle`.
  final CoreClickableStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreClickableTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
