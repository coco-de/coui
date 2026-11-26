import 'package:coui_core/src/component/contracts/stage_container/core_stage_breakpoint.dart';
import 'package:coui_core/src/component/contracts/stage_container/stage_container_style.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';

/// Builder invoked by a StageContainer on every viewport measurement.
///
/// - [context]: platform build context.
/// - [padding]: resolved per-axis padding (left/top/right/bottom in px) —
///   already folded widget default + breakpoint-driven remaining width
///   redistribution.
/// - Returns the platform widget / component to render inside the stage.
typedef CoreStageContainerBuilder<W> =
    W Function(
      Object context,
      CoreEdgeInsets padding,
    );

/// Platform-independent contract for a `StageContainer`.
///
/// A stage container measures its parent viewport width and resolves a
/// per-axis padding so its child always sits on one of the configured
/// breakpoint rungs. Wider viewports split the overflow into equal left +
/// right padding, and narrower viewports zero out the horizontal padding so
/// the content can use the full width.
///
/// Type parameters:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreStageContainerContract<W> {
  /// Breakpoint strategy. Determines the min / max content width for any
  /// given viewport width.
  CoreStageBreakpoint get breakpoint;

  /// Base padding applied regardless of breakpoint. Left / right are the
  /// *minimum* horizontal insets; extra space from the breakpoint
  /// redistribution is added on top. Top / bottom pass through unchanged.
  CoreEdgeInsets get padding;

  /// Called on every viewport measurement with the resolved padding.
  CoreStageContainerBuilder<W> get builder;

  /// Per-instance layout / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreStageContainerTheme (legacy flat fields)
  ///   → CoreStageContainerTheme.style
  ///   → parent component slot override
  ///   → widget.stageContainerStyle
  /// ```
  CoreStageContainerStyle? get stageContainerStyle;
}
