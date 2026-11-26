import 'dart:math' as math;

/// Frame-rate independent Liquid Glass motion shared by Web and Flutter.
class CoreGlassNavigationMotion {
  /// Starts at the selected destination, in logical item coordinates.
  CoreGlassNavigationMotion(double initialPosition) {
    position = CoreGlassSpring(initialPosition);
    target = initialPosition;
  }

  static const _tracking = _SpringParameters(
    stiffness: 1800,
    damping: 85,
  );
  static const _settling = _SpringParameters(
    stiffness: 520,
    damping: 36,
  );
  static const _material = _SpringParameters(
    stiffness: 520,
    damping: 38,
  );
  static const _deformation = _SpringParameters(
    stiffness: 420,
    damping: 27,
  );

  /// How much bigger the whole bar is drawn while its lens is up, as a share
  /// of its size on both axes: `.03` is 3 %. The capsule, the lens and the
  /// destinations take it together, about [barSwellOrigin].
  ///
  /// Designer judgement, taken from the reference glass tab bar the motion
  /// was measured against.
  static const double barSwell = .03;

  /// Where the bar grows from, `0` to `1`: `0` grows it evenly about its
  /// middle, `1` leans the growth fully toward the lens, so the side the lens
  /// is on grows the most. Designer judgement, as [barSwell].
  static const double barSwellGrip = .75;

  /// The swell while the lens is up: a little under critical, so it arrives
  /// without a visible bounce.
  static const _swellRising = _SpringParameters(stiffness: 320, damping: 24);

  /// The swell once the lens is down: the same stiffness with less damping, so
  /// the bar dips once past its size as it settles.
  static const _swellFalling = _SpringParameters(stiffness: 320, damping: 17);

  /// Rendered position and velocity, independent of the pointer target.
  late final CoreGlassSpring position;

  /// Activation of the raised optical lens.
  final lift = CoreGlassSpring(0);

  /// Elastic deformation driven by rendered speed and acceleration.
  final bubble = CoreGlassSpring(0);

  /// The whole bar's swell: `0` at rest, toward [barSwell] while the lens is
  /// up — see [barScale].
  final swell = CoreGlassSpring(0);

  /// Destination the position spring is currently following.
  late double target;

  /// Whether a primary pointer currently holds this track.
  bool pressed = false;

  /// Whether accessibility or an explicit zero duration disables motion.
  bool reducedMotion = false;

  /// Physical distance between adjacent destination centers.
  double pixelsPerItem = 1;
  double _previousSpeed = 0;

  /// Clamped lens activation for painting.
  double get activation => lift.value.clamp(0.0, 1.0);

  /// Bounded deformation, including a small settling rebound.
  double get energy => bubble.value.clamp(-.12, 1.0);

  /// Signed rendered velocity for directional highlights.
  double get direction =>
      (position.velocity * pixelsPerItem / 900).clamp(-1.0, 1.0);

  /// The scale the whole bar is drawn at: `1` at rest.
  double get barScale => 1 + swell.value;

  /// Where along the bar it grows from, `0` to `1` from one end, for a lens
  /// whose centre is at [lensFraction] of the bar's length from the same end.
  ///
  /// The lens's place is mirrored about the middle and pulled toward it by
  /// [barSwellGrip]: a lens near one end puts the point near the other, so the
  /// end the lens is on moves out the most. Mirroring makes the answer the
  /// same from either end, so a platform may measure from whichever end it
  /// lays out from.
  static double barSwellOrigin(double lensFraction) =>
      .5 + (.5 - lensFraction.clamp(0.0, 1.0)) * barSwellGrip;

  /// Updates platform geometry and snaps when motion is disabled.
  void configure({required bool reduced, required double itemExtent}) {
    pixelsPerItem = itemExtent;
    if (reducedMotion == reduced) return;
    reducedMotion = reduced;
    if (reduced) _snap();
  }

  /// Retargets without changing the rendered position or velocity.
  void moveTo(double value, {required bool held}) {
    target = value;
    pressed = held;
    if (reducedMotion) {
      _snap();
    }
  }

  /// Releases to the host-owned selection while preserving momentum.
  void release(double value) {
    // Keep the rendered velocity when switching spring stiffness. Replacing it
    // with the pointer velocity (including zero) would break motion continuity.
    moveTo(value, held: false);
  }

  void _snap() {
    position.snap(target);
    lift.snap(0);
    bubble.snap(0);
    swell.snap(0);
    _previousSpeed = 0;
  }

  /// Advances a platform clock by a finite duration in seconds.
  void advance(double seconds) {
    if (reducedMotion || !seconds.isFinite || seconds <= 0) return;
    // Fixed maximum substeps keep the coupled material response consistent at
    // 60/120 Hz and after dropped frames. A long background pause simply settles.
    if (seconds > .5) {
      position.snap(target);
      lift.snap(pressed ? 1 : 0);
      bubble.snap(0);
      swell.snap(pressed ? barSwell : 0);
      _previousSpeed = 0;
    } else {
      final steps = (seconds / (1 / 120)).ceil();
      final dt = seconds / steps;
      for (var step = 0; step < steps; step++) {
        position._advance(dt, target, pressed ? _tracking : _settling);
        final speed = (position.velocity * pixelsPerItem).abs();
        // Braking is not another inflation impulse. Shape follows rendered
        // speed, with a small boost only when that speed is increasing.
        final acceleration = math.max(0, (speed - _previousSpeed) / dt);
        _previousSpeed = speed;
        final energy =
            .78 * speed / (speed + 650) +
            .22 * acceleration / (acceleration + 10000);
        bubble._advance(dt, energy, _deformation);
        final moving = !position.isAt(target);
        // The lens is up while it is held and while it is still travelling;
        // the bar swells for exactly as long.
        final up = pressed || moving;
        lift._advance(dt, up ? 1 : 0, _material);
        swell._advance(
          dt,
          up ? barSwell : 0,
          up ? _swellRising : _swellFalling,
        );
      }
    }
    if (position.isAt(target) &&
        bubble.isAt(0) &&
        lift.isAt(pressed ? 1 : 0) &&
        swell.isAt(pressed ? barSwell : 0)) {
      position.snap(target);
      bubble.snap(0);
      lift.snap(pressed ? 1 : 0);
      swell.snap(pressed ? barSwell : 0);
    }
  }

  /// Whether a platform clock can stop until the next input.
  bool get isSettled =>
      position.isAt(target) &&
      bubble.isAt(0) &&
      lift.isAt(pressed && !reducedMotion ? 1 : 0) &&
      swell.isAt(pressed && !reducedMotion ? barSwell : 0);
}

class _SpringParameters {
  const _SpringParameters({required this.stiffness, required this.damping});
  final double stiffness;
  final double damping;
}

/// Spring state shared by both renderers. Retargeting preserves velocity.
class CoreGlassSpring {
  /// Starts a stationary spring at [value].
  CoreGlassSpring(this.value);

  /// Current spring position.
  double value;

  /// Current velocity in position units per second.
  double velocity = 0;

  /// Whether displacement and velocity are below the resting tolerance.
  bool isAt(double target) =>
      (value - target).abs() < .0005 && velocity.abs() < .005;

  /// Sets the position and clears velocity.
  void snap(double target) {
    value = target;
    velocity = 0;
  }

  void _advance(double dt, double target, _SpringParameters spring) {
    if (isAt(target)) {
      snap(target);
      return;
    }
    final offset = value - target;
    final decayRate = spring.damping / 2;
    final discriminant = decayRate * decayRate - spring.stiffness;
    if (discriminant > 0) {
      final root = math.sqrt(discriminant);
      final r1 = -decayRate + root;
      final r2 = -decayRate - root;
      final a = (velocity - r2 * offset) / (r1 - r2);
      final b = offset - a;
      final first = a * math.exp(r1 * dt);
      final second = b * math.exp(r2 * dt);
      value = target + first + second;
      velocity = r1 * first + r2 * second;
    } else if (discriminant < 0) {
      final frequency = math.sqrt(-discriminant);
      final b = (velocity + decayRate * offset) / frequency;
      final cosine = math.cos(frequency * dt);
      final sine = math.sin(frequency * dt);
      final wave = offset * cosine + b * sine;
      final decay = math.exp(-decayRate * dt);
      value = target + decay * wave;
      velocity =
          decay * (frequency * (b * cosine - offset * sine) - decayRate * wave);
    } else {
      final b = velocity + decayRate * offset;
      final wave = offset + b * dt;
      final decay = math.exp(-decayRate * dt);
      value = target + decay * wave;
      velocity = decay * (b - decayRate * wave);
    }
  }
}
