/// Theme data for `Autocomplete` customisation.
library;

import 'package:coui_core/src/component/contracts/autocomplete/autocomplete_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Autocomplete`.
///
/// All chrome / dimensional overrides flow through the single [style]
/// slot. The behaviour default `mode` is NOT a Theme slot — it lives on
/// the widget (`CoreAutocompleteMode.defaultMode`); Theme carries
/// `{style}` only.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreAutocompleteTheme.style                // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance autocompleteStyle
/// ```
@immutable
class CoreAutocompleteTheme {
  /// Creates a [CoreAutocompleteTheme].
  const CoreAutocompleteTheme({this.style});

  /// Project-wide composite style applied to every `Autocomplete`.
  final CoreAutocompleteStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAutocompleteTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
