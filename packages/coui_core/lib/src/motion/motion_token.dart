import 'package:meta/meta.dart';

/// Sealed class hierarchy for design-system-specific motion tokens.
///
/// - [CssTransitionMotion]: CoUI Web CSS transitions (duration + easing).
/// - [SpringMotion]: M3E spring physics (dampingRatio + stiffness).
/// - [GlassPhysicsMotion]: Liquid Glass spring + specular response.
@immutable
sealed class CoreMotionToken {
  const CoreMotionToken();

  /// Serializes this motion token to a JSON-compatible map. The `type`
  /// discriminator identifies the variant.
  Map<String, dynamic> toJson();
}

/// CoUI Web CSS transition motion (duration + cubic-bezier easing).
@immutable
class CssTransitionMotion extends CoreMotionToken {
  /// Creates a [CssTransitionMotion] with the given duration and easing.
  const CssTransitionMotion({
    required this.durationMs,
    this.easing = 'ease',
  });

  /// Duration in milliseconds.
  final int durationMs;

  /// CSS easing function name or cubic-bezier value.
  final String easing;

  /// Generates a CSS `transition` value for a given property.
  String toCss(String property) {
    return '$property ${durationMs}ms $easing';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CssTransitionMotion &&
          durationMs == other.durationMs &&
          easing == other.easing;

  @override
  int get hashCode => Object.hash(durationMs, easing);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'cssTransition',
    'durationMs': durationMs,
    'easing': easing,
  };

  @override
  String toString() => 'CssTransition(${durationMs}ms, $easing)';
}

/// M3E Spring physics motion (dampingRatio + stiffness).
@immutable
class SpringMotion extends CoreMotionToken {
  /// Creates a [SpringMotion] from spring physics parameters.
  const SpringMotion({
    required this.dampingRatio,
    required this.stiffness,
    this.mass = 1.0,
  });

  /// Damping ratio (0=undamped, 1=critically damped, >1=overdamped).
  final double dampingRatio;

  /// Spring stiffness in N/m.
  final double stiffness;

  /// Mass in kg.
  final double mass;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpringMotion &&
          dampingRatio == other.dampingRatio &&
          stiffness == other.stiffness &&
          mass == other.mass;

  @override
  int get hashCode => Object.hash(dampingRatio, stiffness, mass);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'spring',
    'dampingRatio': dampingRatio,
    'stiffness': stiffness,
    'mass': mass,
  };

  @override
  String toString() =>
      'Spring(damping: $dampingRatio, stiffness: $stiffness, mass: $mass)';
}

/// Liquid Glass physics motion (spring + specular response).
@immutable
class GlassPhysicsMotion extends CoreMotionToken {
  /// Creates a [GlassPhysicsMotion] combining a spring with specular response.
  const GlassPhysicsMotion({
    required this.spring,
    required this.specularResponse,
  });

  /// Underlying spring configuration.
  final SpringMotion spring;

  /// Specular highlight response factor (0.0-1.0).
  final double specularResponse;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassPhysicsMotion &&
          spring == other.spring &&
          specularResponse == other.specularResponse;

  @override
  int get hashCode => Object.hash(spring, specularResponse);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'glassPhysics',
    'spring': spring.toJson(),
    'specularResponse': specularResponse,
  };

  @override
  String toString() =>
      'GlassPhysics(spring: $spring, specular: $specularResponse)';
}
