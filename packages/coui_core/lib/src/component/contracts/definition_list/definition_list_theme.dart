/// Theme overrides for the unified DefinitionList component.
library;

import 'package:coui_core/src/component/contracts/definition_list/definition_list_style.dart';
import 'package:meta/meta.dart';

/// Project-level style overrides for a unified DefinitionList.
///
/// All gap / typography overrides flow through the composite [style]
/// slot — there are no flat chrome fields.
@immutable
class CoreDefinitionListTheme {
  /// Creates a [CoreDefinitionListTheme].
  const CoreDefinitionListTheme({this.style});

  /// Project-wide composite style applied to every `DefinitionList`.
  ///
  /// Resolved before any per-instance `widget.definitionListStyle`.
  final CoreDefinitionListStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreDefinitionListTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
