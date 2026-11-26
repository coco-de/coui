/// Cross-platform contract for unified refresh-trigger components.
library;

import 'package:coui_core/src/component/contracts/refresh_trigger/refresh_trigger_direction.dart';
import 'package:coui_core/src/component/contracts/refresh_trigger/refresh_trigger_stage.dart';
import 'package:coui_core/src/component/contracts/refresh_trigger/refresh_trigger_style.dart';

/// Contract for a unified pull-to-refresh trigger.
///
/// Wraps scrollable [child] content and shows a stage-driven
/// indicator. Per Epic #1415 Phase 6f, every indicator chrome /
/// dimensional / animation override flows through the single
/// [refreshTriggerStyle] field — see [CoreRefreshTriggerStyle] for the
/// merge chain. The behaviour fields (`stage`, `direction`, `reverse`,
/// `minExtent`, `maxExtent`, `onRefresh`) and the indicator label
/// strings stay flat on the contract.
///
/// Type parameters:
/// - [W] — Widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreRefreshTriggerContract<W> {
  /// The scrollable content wrapped by the refresh trigger.
  W get child;

  /// The current lifecycle stage of the trigger.
  ///
  /// On Flutter the stage is also driven internally by the pull
  /// gesture; supplying it explicitly forces a controlled stage. On
  /// Web (no native pull gesture) the stage is always controlled.
  CoreRefreshStage get stage;

  /// The axis along which the pull gesture is detected. Defaults to
  /// [CoreRefreshDirection.vertical].
  CoreRefreshDirection get direction;

  /// Whether the gesture / indicator originates from the opposite
  /// edge (bottom-up / right-to-left). Defaults to `false`.
  bool get reverse;

  /// Label shown in the `idle` stage. When `null`, the widget falls
  /// back to the active platform localizations value so the default
  /// reflects the active locale.
  String? get pullText;

  /// Label shown in the `pulling` stage once the pull has crossed
  /// the [minExtent] threshold. When `null`, falls back to the active
  /// localizations value.
  String? get releaseText;

  /// Label shown in the `refreshing` stage. When `null`, falls back
  /// to the active localizations value.
  String? get refreshingText;

  /// Label shown in the `completed` stage. When `null`, falls back to
  /// the active localizations value.
  String? get completedText;

  /// Minimum pull extent (logical px) required to trigger a refresh.
  /// Flutter pull gesture threshold; ignored on Web.
  double get minExtent;

  /// Maximum allowed pull extent (logical px). Flutter pull gesture
  /// cap; ignored on Web.
  double get maxExtent;

  /// Async callback invoked when a refresh is triggered. Flutter
  /// drives this from the pull gesture; on Web the host calls
  /// `onRefresh` and updates [stage] itself.
  Future<void> Function()? get onRefresh;

  /// Per-instance indicator style covering chrome + dimensional +
  /// animation overrides plus the nested label style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreRefreshTriggerStyle.defaultX)
  ///   → CoreRefreshTriggerTheme.style
  ///   → parent component slot override
  ///   → widget.refreshTriggerStyle
  /// ```
  ///
  /// Named [refreshTriggerStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreRefreshTriggerStyle? get refreshTriggerStyle;
}
