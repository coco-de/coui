import 'package:coui_core/src/icon/icon_name.dart';
import 'package:coui_core/src/icon/lucide_icons.dart';

/// Where one step of a process stands.
///
/// Read by `Steps` (on every item, explicitly through `CoreStepData.status`
/// or derived from `currentStep`) and by `StepItem` (one row of a
/// `Steps(variant: list)`). One enum for both, so a step reads the same
/// word whether it is a numbered circle or a list row.
///
/// A state of its own rather than a position: the old model drew a step
/// only from its index against `currentStep`, which can say "done",
/// "here" and "not yet" but not "stopped here" — a step that ran and
/// failed has no index that means it.
///
/// What each status draws (its glyph, and on a numbered indicator its fill
/// and mark) is answered here, once, so the two platforms cannot pick
/// different glyphs for the same step.
enum CoreStepStatus {
  /// Finished.
  done,

  /// The step in progress — at most one per process is usual, but nothing
  /// enforces it.
  current,

  /// Not reached yet.
  todo,

  /// Ran and stopped — the process cannot go past it until it is retried.
  failed;

  /// Default status of a standalone `StepItem` — the resting state of a
  /// step nobody has reached, so a row with no status stated reads as the
  /// quietest one. The Flutter / Web constructors reference this so the
  /// default cannot silently diverge.
  static const CoreStepStatus defaultStatus = todo;

  /// The status a step at [index] shows.
  ///
  /// An item's own [status] wins; without one the step is placed by its
  /// position against [currentStep] — before it is done, at it is current,
  /// after it is to do. Items that state a status and items that do not can
  /// share one list, and each falls back on its own.
  ///
  /// Both platforms decide every item through this one function, so a
  /// half-stated list cannot render differently on Flutter and on the Web.
  static CoreStepStatus effective({
    required int index,
    required int currentStep,
    CoreStepStatus? status,
  }) {
    if (status != null) return status;
    if (index < currentStep) return done;
    if (index == currentStep) return current;
    return todo;
  }

  /// The glyph a list row (`StepItem`) draws for this status — one closed
  /// circle family, so the four read as one set at a glance and differ by
  /// their mark: a check, a dot, nothing, a cross.
  ///
  /// The colour is not here — it is a style value
  /// (`CoreStepItemStyle.defaultsByStatus`). The glyph is the status's
  /// identity, not a chrome choice, so it has no override slot.
  IconName get glyph => switch (this) {
    done => LucideIcons.circleCheck,
    current => LucideIcons.circleDot,
    todo => LucideIcons.circle,
    failed => LucideIcons.circleX,
  };

  /// The mark a numbered indicator draws instead of its number, or `null`
  /// when it shows the number.
  ///
  /// A finished step and a failed one have nothing left to count — the
  /// check and the cross say what happened to them. A current or upcoming
  /// step keeps its position number.
  IconName? get indicatorGlyph => switch (this) {
    done => LucideIcons.check,
    failed => LucideIcons.x,
    current || todo => null,
  };
}
