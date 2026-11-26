import 'package:coui_core/src/motion/motion_token.dart';

/// Pre-configured spring configurations for M3 Expressive motion.
abstract final class CoreSpringConfig {
  const CoreSpringConfig._();

  /// Gentle spring for subtle movements.
  static const gentle = SpringMotion(dampingRatio: 0.8, stiffness: 200);

  /// Standard spring for most interactions.
  static const standard = SpringMotion(dampingRatio: 0.7, stiffness: 300);

  /// Bouncy spring for playful effects.
  static const bouncy = SpringMotion(dampingRatio: 0.5, stiffness: 400);

  /// Snappy spring for quick responses.
  static const snappy = SpringMotion(dampingRatio: 0.9, stiffness: 500);

  /// Stiff spring for minimal oscillation.
  static const stiff = SpringMotion(dampingRatio: 1, stiffness: 600);
}
