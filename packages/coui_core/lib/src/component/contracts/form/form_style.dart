/// Per-instance style for `Form`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Form` should render.
///
/// `CoreFormStyle` carries the inter-form-item spacing as a scalar
/// `double?` (native-API spacing — Flutter `Column.spacing`, Web flex
/// `gap` CSS) — both renderers consume raw doubles, so this slot stays
/// scalar rather than the nested `CoreGapStyle` shape used for `Gap`
/// slots. Defaults live as `static const` here so the contract is the
/// single source of truth for Flutter / Web resolvers.
///
/// ```text
/// design system default (CoreFormStyle.defaultRowSpacing)
///   → CoreFormTheme.style                            // 프로젝트 공통
///   → widget.formStyle                               // 인스턴스별
/// ```
@immutable
class CoreFormStyle implements CoreStyle<CoreFormStyle> {
  /// Creates a [CoreFormStyle].
  const CoreFormStyle({this.rowSpacing, this.actionSpacing});

  /// Default inter-item spacing (logical px, pre-scaling) between
  /// adjacent form rows. Flows directly into `Column.spacing` (Flutter)
  /// or flex `gap` CSS (Web). Per-instance override flows through
  /// [rowSpacing] (merged on top of this default).
  static const double defaultRowSpacing = CoreSpace.space24;

  /// Default spacing between `secondaryAction` and `primaryAction` in
  /// the actions row (8 logical px) — the same value
  /// `CoreDialogStyle.defaultActionSpacing` uses for its own
  /// action-button row.
  static const double defaultActionSpacing = CoreSpace.space8;

  /// Inter-item spacing (logical px, pre-scaling) between adjacent form
  /// rows. Flows directly into `Column.spacing` (Flutter) or flex `gap`
  /// CSS (Web) — both are native paint-API arguments that consume raw
  /// doubles, so this slot stays scalar (`double?`). `null` defers to
  /// [defaultRowSpacing].
  final double? rowSpacing;

  /// Spacing between the two action buttons (logical px, pre-scaling).
  /// Same native-paint-API scalar shape as [rowSpacing]. `null` defers
  /// to [defaultActionSpacing].
  final double? actionSpacing;

  @override
  CoreFormStyle merge(CoreFormStyle? other) {
    if (other == null) return this;
    return CoreFormStyle(
      rowSpacing: other.rowSpacing ?? rowSpacing,
      actionSpacing: other.actionSpacing ?? actionSpacing,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreFormStyle copyWith({double? rowSpacing, double? actionSpacing}) => .new(
    rowSpacing: rowSpacing ?? this.rowSpacing,
    actionSpacing: actionSpacing ?? this.actionSpacing,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFormStyle &&
          runtimeType == other.runtimeType &&
          rowSpacing == other.rowSpacing &&
          actionSpacing == other.actionSpacing;

  @override
  int get hashCode => Object.hash(rowSpacing, actionSpacing);
}
