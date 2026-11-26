/// Theme data for `Fieldset` customisation.
library;

import 'package:coui_core/src/component/contracts/fieldset/fieldset_style.dart';
import 'package:coui_core/src/component/contracts/fieldset/fieldset_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for fieldset components.
///
/// Per Epic #1302 the project-wide chrome / dimensional / nested-slot
/// styles flow through the composite [style] field, with [variantStyles]
/// on top of it for a single variant — see [CoreFieldsetStyle] for the
/// merge chain.
///
/// Example:
/// ```dart
/// CoreComponentTheme(
///   fieldset: CoreFieldsetTheme(
///     style: CoreFieldsetStyle(
///       padding: CoreEdgeInsets.all(CoreSpace.space16),
///       fieldSpacing: CoreSpace.space12,
///     ),
///     variantStyles: {
///       CoreFieldsetVariant.plain: CoreFieldsetStyle(
///         fieldSpacing: CoreSpace.space24,
///       ),
///     },
///   ),
/// )
/// ```
@immutable
class CoreFieldsetTheme {
  /// Creates a [CoreFieldsetTheme].
  const CoreFieldsetTheme({this.style, this.variantStyles});

  /// Project-wide composite style applied to every `Fieldset`.
  ///
  /// Resolved before any per-instance `widget.fieldsetStyle`.
  final CoreFieldsetStyle? style;

  /// Project-wide composite style applied to the `Fieldset`s of one
  /// variant, merged on top of [style].
  final Map<CoreFieldsetVariant, CoreFieldsetStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFieldsetTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _variantStylesEqual(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(
    style,
    variantStyles == null
        ? null
        : Object.hashAllUnordered(
            variantStyles!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
  );

  static bool _variantStylesEqual(
    Map<CoreFieldsetVariant, CoreFieldsetStyle>? a,
    Map<CoreFieldsetVariant, CoreFieldsetStyle>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
