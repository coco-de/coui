/// Theme data for Disclosure customization.
library;

import 'package:coui_core/src/component/contracts/disclosure/disclosure_style.dart';
import 'package:meta/meta.dart';

/// Theme overrides for `Disclosure` and `DisclosureGroup`.
///
/// All chrome lives inside the composite [style] field — see
/// [CoreDisclosureStyle]. The merge chain is:
///
/// ```text
/// design system default (CoreDisclosureStyle.defaultX)
///   → CoreDisclosureTheme.style
///   → parent component slot override
///   → widget.disclosureStyle
/// ```
@immutable
class CoreDisclosureTheme {
  /// Creates a [CoreDisclosureTheme].
  const CoreDisclosureTheme({this.style});

  /// Project-wide composite style applied to every `Disclosure`.
  ///
  /// Resolved before any per-instance `widget.disclosureStyle`.
  final CoreDisclosureStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDisclosureTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
