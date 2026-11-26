/// Per-instance style for `StageContainer`.
library;

import 'package:coui_core/src/component/contracts/stage_container/core_stage_breakpoint.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `StageContainer` should render.
///
/// `CoreStageContainerStyle` carries layout / dimensional flat fields.
/// Behavioural / content fields (`builder`) stay flat on the widget /
/// contract.
///
/// ```text
/// design system default
///   → CoreStageContainerTheme (legacy flat fields)
///   → CoreStageContainerTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.stageContainerStyle                          // 인스턴스별
/// ```
@immutable
class CoreStageContainerStyle implements CoreStyle<CoreStageContainerStyle> {
  /// Creates a [CoreStageContainerStyle].
  const CoreStageContainerStyle({
    this.breakpoint,
    this.padding,
  });

  /// Design-system default base padding. Left / right are the minimum
  /// horizontal insets — the breakpoint redistribution adds to them. Matches
  /// the legacy `StageContainer` horizontal inset so migrated callers render
  /// identically.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space72,
  );

  /// Design-system default breakpoint strategy — the shared staged ladder
  /// [CoreStageBreakpoint.defaultBreakpoints]. Both resolvers fall back to
  /// this constant (rather than reaching for the `CoreStageBreakpoint`
  /// namespace directly) so the component's default has one name.
  static const CoreStageBreakpoint defaultBreakpoint =
      CoreStageBreakpoint.defaultBreakpoints;

  /// Breakpoint strategy override.
  final CoreStageBreakpoint? breakpoint;

  /// Base padding. Left / right are the minimum horizontal insets — the
  /// breakpoint redistribution adds to them.
  final CoreEdgeInsets? padding;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreStageContainerStyle merge(CoreStageContainerStyle? other) {
    if (other == null) return this;
    return CoreStageContainerStyle(
      breakpoint: other.breakpoint ?? breakpoint,
      padding: other.padding ?? padding,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreStageContainerStyle copyWith({
    CoreStageBreakpoint? breakpoint,
    CoreEdgeInsets? padding,
  }) {
    return CoreStageContainerStyle(
      breakpoint: breakpoint ?? this.breakpoint,
      padding: padding ?? this.padding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStageContainerStyle &&
          runtimeType == other.runtimeType &&
          breakpoint == other.breakpoint &&
          padding == other.padding;

  @override
  int get hashCode => Object.hash(
    breakpoint,
    padding,
  );
}
