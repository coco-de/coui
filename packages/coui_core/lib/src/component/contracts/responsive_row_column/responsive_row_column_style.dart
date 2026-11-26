/// Per-instance style for `ResponsiveRowColumn`.
library;

import 'package:coui_core/src/component/contracts/frame/core_cross_axis_alignment.dart';
import 'package:coui_core/src/component/contracts/frame/core_main_axis_alignment.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing the spacing and alignment of a
/// `ResponsiveRowColumn`'s children.
///
/// `ResponsiveRowColumn` flips its layout direction (`Row` ↔ `Column`)
/// at `CoreResponsiveRowColumnContract.switchAt`, so every field here
/// is *direction-relative*: [mainAxisAlignment] always means "along
/// whichever axis is currently the main axis" (horizontal when
/// rendered as a `Row`, vertical when rendered as a `Column`), and
/// [crossAxisAlignment] always means the perpendicular axis.
///
/// All chrome for `ResponsiveRowColumn` flows through this single Style
/// slot (`core/style-contract.md`, widget chrome 단일 진입점) — the
/// widget/contract expose no flat chrome params alongside it.
///
/// ```text
/// design system default
///   → CoreResponsiveRowColumnTheme.style   // 프로젝트 공통
///   → widget.responsiveRowColumnStyle      // 인스턴스별
/// ```
@immutable
class CoreResponsiveRowColumnStyle
    implements CoreStyle<CoreResponsiveRowColumnStyle> {
  /// Creates a [CoreResponsiveRowColumnStyle].
  const CoreResponsiveRowColumnStyle({
    this.spacing,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
  });

  /// Default spacing between children — `CoreSpace.space8`.
  static const double defaultSpacing = CoreSpace.space8;

  /// Default main-axis alignment — packs children to the start of
  /// whichever axis is currently the main axis, matching Flutter's
  /// native `Row`/`Column` default.
  static const CoreMainAxisAlignment defaultMainAxisAlignment = .start;

  /// Default cross-axis alignment — centres children on whichever axis
  /// is currently the cross axis, matching Flutter's native
  /// `Row`/`Column` default.
  static const CoreCrossAxisAlignment defaultCrossAxisAlignment = .center;

  /// Evenly-distributed spacing between children (logical px at 1.0
  /// scaling). This is N-sibling spacing — it flows through the
  /// platform-native `Row`/`Column`/`Flex.spacing` API (Flutter) or a
  /// `gap-*` utility (Web), not a 1-off `CoreGapStyle` slot
  /// (`resolver/scaling-and-gap.md`).
  final double? spacing;

  /// Main-axis alignment — see the class doc for the direction-relative
  /// meaning.
  final CoreMainAxisAlignment? mainAxisAlignment;

  /// Cross-axis alignment — see the class doc for the direction-relative
  /// meaning.
  final CoreCrossAxisAlignment? crossAxisAlignment;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreResponsiveRowColumnStyle merge(CoreResponsiveRowColumnStyle? other) {
    if (other == null) return this;
    return CoreResponsiveRowColumnStyle(
      spacing: other.spacing ?? spacing,
      mainAxisAlignment: other.mainAxisAlignment ?? mainAxisAlignment,
      crossAxisAlignment: other.crossAxisAlignment ?? crossAxisAlignment,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreResponsiveRowColumnStyle copyWith({
    double? spacing,
    CoreMainAxisAlignment? mainAxisAlignment,
    CoreCrossAxisAlignment? crossAxisAlignment,
  }) {
    return CoreResponsiveRowColumnStyle(
      spacing: spacing ?? this.spacing,
      mainAxisAlignment: mainAxisAlignment ?? this.mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment ?? this.crossAxisAlignment,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreResponsiveRowColumnStyle &&
          runtimeType == other.runtimeType &&
          spacing == other.spacing &&
          mainAxisAlignment == other.mainAxisAlignment &&
          crossAxisAlignment == other.crossAxisAlignment;

  @override
  int get hashCode =>
      Object.hash(spacing, mainAxisAlignment, crossAxisAlignment);
}
