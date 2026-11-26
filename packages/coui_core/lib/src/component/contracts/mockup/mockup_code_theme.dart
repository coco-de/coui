import 'package:coui_core/src/component/contracts/mockup/mockup_code_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `MockupCode`.
///
/// All fields flow through [style] — introduced fresh per Epic
/// #1302 원칙 7. The shared `CoreMockupTheme.style` applies cross-variant
/// defaults (background / border) for project-wide mockup recolouring.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreMockupTheme.style (shared cross-variant)
///   → CoreMockupCodeTheme.style                      // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance mockupCodeStyle
/// ```
@immutable
class CoreMockupCodeTheme {
  /// Creates a [CoreMockupCodeTheme].
  const CoreMockupCodeTheme({this.style});

  /// Project-wide composite style applied to every `MockupCode`.
  ///
  /// Resolved before any per-instance `widget.mockupCodeStyle`.
  final CoreMockupCodeStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMockupCodeTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
