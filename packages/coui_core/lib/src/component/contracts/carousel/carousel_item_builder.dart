/// Lazy slide-building callbacks for carousel components.
library;

/// Builds one carousel slide on demand.
///
/// - [context]: platform build context. Typed as `Object` because
///   `coui_core` cannot name either framework's context type; cast it to
///   `BuildContext` when the slide needs ambient lookups.
/// - [index]: slide index. On a wrapping carousel this may be negative or
///   greater than the item count — wrap it into range when indexing.
///
/// Returns the platform widget / component for that slide.
typedef CoreCarouselItemBuilder<W> = W Function(Object context, int index);

/// Resolves how long the slide at [index] stays before auto-advancing.
///
/// Returning `null` falls back to the carousel's flat auto-play duration.
typedef CoreCarouselDurationBuilder = Duration? Function(int index);
