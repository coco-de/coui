/// Theme data for Form and FormField components.
library;

import 'package:coui_core/src/component/contracts/form/form_field_style.dart';
import 'package:coui_core/src/component/contracts/form/form_style.dart';
import 'package:meta/meta.dart';

/// Theme for form container.
///
/// Resolution chain (handled by `resolveForm` in Flutter / equivalent
/// on Web):
///
/// ```text
/// design system default (CoreFormStyle.defaultRowSpacing)
///   → CoreFormTheme.style                            // 프로젝트 공통
///   → widget.formStyle                               // 인스턴스별
/// ```
@immutable
class CoreFormTheme {
  /// Creates a [CoreFormTheme].
  const CoreFormTheme({this.style});

  /// Project-wide composite style applied to every `Form`.
  ///
  /// Resolved before any per-instance `widget.formStyle`.
  final CoreFormStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreFormTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}

/// Theme for form field wrapper.
///
/// Phase 6f migration (Epic #1579 §3, Issue #1594): chrome flat fields
/// (`gap`, `labelColor`, …) were absorbed into [style] so that
/// [CoreFormFieldStyle] is the single source of truth for every chrome
/// slot. The legacy `labelStyle` field had no Style counterpart and no
/// usage sites — removed as dead code.
///
/// Resolution chain (handled by `resolveFormField` in each platform):
///
/// ```text
/// design system default
///   → CoreFormFieldTheme.style                      // 프로젝트 공통
///   → parent component slot override
///   → widget.formFieldStyle                         // 인스턴스별
/// ```
@immutable
class CoreFormFieldTheme {
  /// Creates a [CoreFormFieldTheme].
  const CoreFormFieldTheme({
    this.style,
  });

  /// Project-wide composite style applied to every `FormField`.
  ///
  /// Resolved before any per-instance `widget.formFieldStyle`.
  final CoreFormFieldStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreFormFieldTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
