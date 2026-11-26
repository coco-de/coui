/// The moments a drag speaks to assistive technology.
library;

import 'package:coui_core/src/drag/core_drag_id.dart';

/// A drag transition worth announcing.
///
/// Four, and no more. The engine reports movement every frame, and speaking
/// it would bury these four under a stream of "moving" — a screen reader
/// user would hear the noise and miss the target changes. Each value maps
/// to one localized sentence the platform adapter supplies, so the meaning
/// is shared while the words stay translatable.
enum CoreDragAnnouncement {
  /// A session earned activation — the item is now being carried.
  pickedUp,

  /// The drag entered a drop target.
  enteredTarget,

  /// The drag was released over a target, or over nothing.
  dropped,

  /// The drag ended without a drop (dismissed, cancelled, item removed).
  cancelled;

  @override
  String toString() => 'CoreDragAnnouncement.$name';
}

/// The announcement policy both drag scopes share.
///
/// The *rule* about which transitions speak lives here, not in the
/// adapters: Flutter and Web each hold one end of the same drag, and two
/// hand-written conditions ("did the target change?") are exactly how the
/// two ends start saying different things about the same session.
abstract final class CoreDragAnnouncements {
  /// What an over-target change should say, or null when it says nothing.
  ///
  /// Entering a target speaks; leaving one does not — the next entry says
  /// where the drag is, and "left the bin" is not actionable. Re-resolving
  /// the same target is silent too: the engine reports every over-change,
  /// and repeating the sentence would turn a hold-still drag into a
  /// stutter.
  static CoreDragAnnouncement? overChanged({
    required CoreDragId? from,
    required CoreDragId? to,
  }) => to == null || to == from ? null : .enteredTarget;
}
