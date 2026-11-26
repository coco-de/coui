/// Per-instance style for `OptionList`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how an `OptionList` renders.
///
/// ```text
/// CoreOptionListStyle.default*
///   → CoreOptionListTheme.style                      // project-wide
///   → widget.optionListStyle                         // per-instance
/// ```
@immutable
class CoreOptionListStyle implements CoreStyle<CoreOptionListStyle> {
  /// Creates a [CoreOptionListStyle].
  const CoreOptionListStyle({this.spacing});

  /// Space between two rows (logical px, pre-scaling). `null` →
  /// [defaultSpacing].
  final double? spacing;

  /// Eight between two cards — each row draws its own border, so the rows
  /// stand apart rather than touching.
  static const double defaultSpacing = CoreSpace.space8;

  /// Merges [other] on top of this style — every field [other] states wins.
  @override
  CoreOptionListStyle merge(CoreOptionListStyle? other) {
    if (other == null) return this;
    return CoreOptionListStyle(spacing: other.spacing ?? spacing);
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreOptionListStyle copyWith({double? spacing}) =>
      CoreOptionListStyle(spacing: spacing ?? this.spacing);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreOptionListStyle &&
          runtimeType == other.runtimeType &&
          spacing == other.spacing;

  @override
  int get hashCode => spacing.hashCode;
}
