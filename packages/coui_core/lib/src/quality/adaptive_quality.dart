import 'package:coui_core/src/quality/frame_budget.dart';
import 'package:coui_core/src/quality/quality_governor.dart';
import 'package:coui_core/src/quality/quality_tier.dart';
import 'package:coui_core/src/quality/quality_tuning.dart';
import 'package:meta/meta.dart';

/// What an app states about adaptive quality — the same object on both
/// platforms (`CoUIApp.adaptiveQuality`, `CoUIWeb.adaptiveQuality`).
///
/// **Off unless stated.** An app that passes none renders every surface at the
/// [CoreQualityTier.full] its style states, and no frame is measured. This is
/// the opt-in the feature ships as: it changes how the material looks, so the
/// choice to let a measurement do that belongs to the app.
///
/// What it can state:
///
/// * [forced] — a tier, held; nothing is measured. For an app that decides by
///   its own means (a device class, a user setting).
/// * [initialQuality] — the tier an earlier session settled on, so a repeat
///   launch skips the warm-up and its dropped frames. Persisting it is the
///   app's: it learns the tier from [onQualityChanged] and hands it back here.
/// * [lowest] — the tier it never wants to go below.
/// * [allowStepUp] — whether a tier given up may be taken back.
/// * [targetFrameRate] — the rate the app means to run at when that is not the
///   display's (a 60 fps app on a 120 Hz panel).
/// * [tuning] — the numbers the governor decides by.
/// * [onQualityChanged] — called after a change of tier has been applied, with
///   the measurement it was made on.
///
/// Accessibility outranks all of it: a reduce-transparency preference is the
/// lowest tier whatever is stated here, and the governor does not measure
/// while it holds.
@immutable
class CoreAdaptiveQuality {
  /// Creates the statement; every omitted term is the default.
  const CoreAdaptiveQuality({
    this.forced,
    this.initialQuality,
    this.lowest,
    this.allowStepUp = true,
    this.targetFrameRate,
    this.tuning = const CoreQualityTuning(),
    this.onQualityChanged,
  });

  /// The tier to hold, or null to let the governor decide.
  ///
  /// Wins over [initialQuality].
  final CoreQualityTier? forced;

  /// The tier to start at, skipping the warm-up, or null to run it.
  final CoreQualityTier? initialQuality;

  /// The lowest tier the governor may go to, or null for the ladder's last.
  final CoreQualityTier? lowest;

  /// Whether the governor may take a tier it gave up back. Defaults to true.
  ///
  /// **Designer-judgement value (디자이너 판단 값):** on, because a transient
  /// cost — a heavy route, a thermal spike that passes — should not cost the
  /// look for the rest of the session. The alternative is a ratchet that only
  /// falls, which never flickers and never recovers.
  final bool allowStepUp;

  /// The frame rate the app runs at when it is not the display's, in Hz, or
  /// null for the display's own.
  final double? targetFrameRate;

  /// The numbers the governor decides by.
  final CoreQualityTuning tuning;

  /// Called after the tier has changed, on the thread that builds widgets.
  ///
  /// Only for a change of tier. The measurement the decision was made on is in
  /// the argument, which is what an app logs to see why.
  final void Function(CoreQualityChange change)? onQualityChanged;

  /// The tiers a governor steps between for surfaces that draw [drawable]:
  /// the ladder's reachable rungs, down to [lowest].
  List<CoreQualityTier> rungs(
    Set<CoreQualityEffect> drawable, {
    CoreQualityLadder ladder = CoreQualityLadder.standard,
  }) {
    final reachable = ladder.reachable(drawable);
    if (lowest case final floor?) {
      final limit = ladder.indexOf(floor);
      if (limit >= 0) {
        return [
          for (final tier in reachable)
            if (ladder.indexOf(tier) <= limit) tier,
        ];
      }
    }

    return reachable;
  }

  /// The tier the surfaces are drawn at before anything is measured:
  /// [forced], else [initialQuality], else the top.
  ///
  /// A tier the rungs have none for starts at the greatest one that is not
  /// above it — the one that looks the same.
  CoreQualityTier startTier(
    Set<CoreQualityEffect> drawable, {
    CoreQualityLadder ladder = CoreQualityLadder.standard,
  }) {
    final wanted = forced ?? initialQuality;
    final available = rungs(drawable, ladder: ladder);
    if (wanted == null) return available.first;
    final limit = ladder.indexOf(wanted);
    var found = available.first;
    for (final tier in available) {
      if (ladder.indexOf(tier) <= limit) found = tier;
    }

    return found;
  }

  /// The frame budget in microseconds: [targetFrameRate] when stated, else
  /// the display's [displayRefreshRate] (null when the platform reports none).
  int budgetMicros(double? displayRefreshRate) =>
      CoreFrameBudget.microsFor(targetFrameRate ?? displayRefreshRate);

  /// The governor this statement asks for, or null when none runs: a tier is
  /// [forced], or there is only one rung to be on.
  ///
  /// [onChange] is the seat's: it applies the change and then calls
  /// [onQualityChanged].
  CoreQualityGovernor? governor({
    required Set<CoreQualityEffect> drawable,
    required CoreFrameMetric metric,
    required int budgetMicros,
    required void Function(CoreQualityChange change) onChange,
    CoreQualityLadder ladder = CoreQualityLadder.standard,
  }) {
    if (forced != null) return null;
    final steps = rungs(drawable, ladder: ladder);
    if (steps.length < 2) return null;

    return CoreQualityGovernor(
      rungs: steps,
      metric: metric,
      budgetMicros: budgetMicros,
      initial: initialQuality,
      allowStepUp: allowStepUp,
      tuning: tuning,
      ladder: ladder,
      onChange: onChange,
    );
  }

  /// Whether [other] asks for the same thing — everything but the callback,
  /// which a seat reads when it calls rather than when it configures.
  ///
  /// A seat reconfigures its governor when the terms change. An app that
  /// writes its callback inline builds a new closure on every rebuild, and
  /// treating that as a change would restart the warm-up each time the parent
  /// rebuilds.
  bool sameTerms(CoreAdaptiveQuality? other) =>
      other != null &&
      forced == other.forced &&
      initialQuality == other.initialQuality &&
      lowest == other.lowest &&
      allowStepUp == other.allowStepUp &&
      targetFrameRate == other.targetFrameRate &&
      tuning == other.tuning;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAdaptiveQuality &&
          forced == other.forced &&
          initialQuality == other.initialQuality &&
          lowest == other.lowest &&
          allowStepUp == other.allowStepUp &&
          targetFrameRate == other.targetFrameRate &&
          tuning == other.tuning &&
          onQualityChanged == other.onQualityChanged;

  @override
  int get hashCode => Object.hash(
    forced,
    initialQuality,
    lowest,
    allowStepUp,
    targetFrameRate,
    tuning,
    onQualityChanged,
  );
}
