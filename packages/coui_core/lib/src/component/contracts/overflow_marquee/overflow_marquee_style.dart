/// Per-instance style for `OverflowMarquee`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `OverflowMarquee` should render.
///
/// Platform-neutral (Epic #1415 option D). Semantic enums (`direction`,
/// `curve`) and behavioural boolean (`pauseOnHover`) stay on the widget.
@immutable
class CoreOverflowMarqueeStyle implements CoreStyle<CoreOverflowMarqueeStyle> {
  /// Creates a [CoreOverflowMarqueeStyle].
  const CoreOverflowMarqueeStyle({
    this.duration,
    this.delayDuration,
    this.step,
    this.fadePortion,
  });

  // ─── Design-system defaults ─────────────────────────────────────

  /// Default one-cycle scroll duration.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.ms3000,
  );

  /// Default delay between cycles.
  static const Duration defaultDelayDuration = Duration(
    milliseconds: CoreDuration.slow,
  );

  /// Default pixel step used to scale speed with content length.
  ///
  /// Geometric constant — not part of the spacing scale.
  static const double defaultStep = 100;

  /// Default edge fade portion (px).
  static const double defaultFadePortion = CoreSpace.space24;

  // ─── Fields ─────────────────────────────────────────────────────

  /// Time for one full scroll cycle override.
  final Duration? duration;

  /// Pause between cycles override.
  final Duration? delayDuration;

  /// Pixel step used to scale speed with content length.
  final double? step;

  /// Length (px) of the edge fade gradient. Zero disables the fade.
  final double? fadePortion;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreOverflowMarqueeStyle merge(CoreOverflowMarqueeStyle? other) {
    if (other == null) return this;
    return CoreOverflowMarqueeStyle(
      duration: other.duration ?? duration,
      delayDuration: other.delayDuration ?? delayDuration,
      step: other.step ?? step,
      fadePortion: other.fadePortion ?? fadePortion,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreOverflowMarqueeStyle copyWith({
    Duration? duration,
    Duration? delayDuration,
    double? step,
    double? fadePortion,
  }) {
    return CoreOverflowMarqueeStyle(
      duration: duration ?? this.duration,
      delayDuration: delayDuration ?? this.delayDuration,
      step: step ?? this.step,
      fadePortion: fadePortion ?? this.fadePortion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreOverflowMarqueeStyle &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          delayDuration == other.delayDuration &&
          step == other.step &&
          fadePortion == other.fadePortion;

  @override
  int get hashCode => Object.hash(duration, delayDuration, step, fadePortion);
}
