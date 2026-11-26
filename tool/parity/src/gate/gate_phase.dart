// #3619 — the PR-gate rollout phase. `ci.yaml`'s `parity-gate` job (#3618)
// reads this to decide, per comparison signal, whether a failure blocks
// the merge (`required`) or is advisory-only
// (`continue-on-error: true` for that step).
//
// A phase widens what's required only after the *prior* phase's own
// 2-week false-positive rate is measured ≤2% — never by default, and
// never by editing this file alone. Bumping [GatePhase.current] is a
// decision that belongs in the issue tracking the promotion (#3619), with
// the measured rate recorded there, not a routine code change.

/// Which signals block the merge at the current rollout stage.
enum GatePhase {
  /// #3618 — everything advisory. The whole job runs with
  /// `continue-on-error: true`; its exit code is data (2-week
  /// false-positive measurement), not a gate.
  a('a'),

  /// #3619 promotion 1 — PropertyDiff (1st signal) becomes required;
  /// PixelDiff stays advisory.
  ///
  /// Property first because it's a discrete/exact comparison — no
  /// antialiasing or sub-pixel noise, so it is not flaky the way pixel
  /// comparisons structurally are (issue #3619 body: "속성을 먼저 켜는
  /// 이유").
  b('b'),

  /// #3619 promotion 2 — PixelDiff (regression + cross-platform parity)
  /// also becomes required, registered as a GitHub required status
  /// check so the merge button itself is disabled on failure.
  ///
  /// ⚠️ Still blocked on more than a 2-week Phase B soak, but no longer on
  /// a dimension mismatch: #3657 found (and fixed) that an earlier real
  /// capture of Button (`button-primary-light-defaultStyle`, via
  /// `flutter_capture_test.dart` + `capture_web.dart`) produced 116×40 vs
  /// 80×40 because the two captures rendered different label text, not
  /// because of a rasterizer or measurement-methodology difference — with
  /// both platforms sourced from the same preview-registry entry, the
  /// pair now lands on an identical 80×40. Promoting to Phase C still
  /// requires #3619's own real-capture threshold calibration (unrelated
  /// to that fix) to land first; promoting on an uncalibrated
  /// `kParityThreshold`/`kRegressionThreshold` (`../diff/pixel_diff.dart`)
  /// would gate merges on a guessed number, not a measured false-positive
  /// rate.
  c('c');

  const GatePhase(this.wireName);

  /// CI env var value / `--phase=` CLI value.
  final String wireName;

  /// The phase `ci.yaml`'s `parity-gate` job actually runs at until a
  /// promotion decision (recorded in #3619's issue thread with the
  /// measured false-positive rate) bumps it. Not derived from anything —
  /// this is the rollout's single source of truth, by design a manual
  /// step (see the enum doc comment).
  static const GatePhase current = GatePhase.a;

  static GatePhase? tryParse(String raw) {
    for (final phase in GatePhase.values) {
      if (phase.wireName == raw) return phase;
    }
    return null;
  }

  /// Whether a PropertyDiff failure should block the gate at this phase.
  bool get requiresProperty => this != GatePhase.a;

  /// Whether a PixelDiff failure (regression or cross-platform parity)
  /// should block the gate at this phase.
  bool get requiresPixel => this == GatePhase.c;
}
