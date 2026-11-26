import 'package:coui_core/src/component/contracts/responsive_row_column/responsive_row_column_style.dart';
import 'package:meta/meta.dart';

/// Theme-level overrides for `ResponsiveRowColumn` shared across
/// platforms.
///
/// `ResponsiveRowColumn` has no variant enum, so the theme carries a
/// single [style] slot — no `variantStyles` map
/// (`core/style-contract.md`, "variant enum 이 아예 없는 컴포넌트만
/// `variantStyles` 를 생략").
@immutable
class CoreResponsiveRowColumnTheme {
  /// Creates a [CoreResponsiveRowColumnTheme].
  const CoreResponsiveRowColumnTheme({this.style});

  /// Project-wide composite style applied to every
  /// `ResponsiveRowColumn`.
  ///
  /// Resolved before any per-instance
  /// `widget.responsiveRowColumnStyle`.
  final CoreResponsiveRowColumnStyle? style;

  /// Returns a copy with the given fields replaced.
  CoreResponsiveRowColumnTheme copyWith({
    CoreResponsiveRowColumnStyle? style,
  }) {
    return CoreResponsiveRowColumnTheme(style: style ?? this.style);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreResponsiveRowColumnTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
