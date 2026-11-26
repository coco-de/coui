/// Standard component size scale.
///
/// Used across all component types for consistent sizing.
enum CoreComponentSize {
  /// Extra small.
  xs,

  /// Small.
  sm,

  /// Medium (default).
  md,

  /// Large.
  lg,

  /// Extra large.
  xl,

  /// 2x extra large (#3880 — Epic K axis 6, six-step ladder confirmed by
  /// five independent specs: button/checkbox/input/switch/radio).
  xl2,
}

/// The row [table] states for [size], or the nearest stated size below it.
///
/// [CoreComponentSize] is shared by the whole kit, but not every component
/// is drawn at every step of it — a design can state five sizes and mean
/// five. Badge does: the library states no `xl2` for it (an open epic-k
/// axis-6 decision), and that is a decision, not an omission. TextArea
/// used to as well, before its own ladder was extended to the full six
/// tiers (2026-09-11).
///
/// A bare `table[size]!` turned that decision into a crash. The size
/// parameter accepts the whole enum, the analyser sees nothing wrong, and
/// the null-check fires at render — with no message, in whatever screen the
/// caller happened to build. Measured on both platforms before this
/// existed: `Badge(size: .xl2)` and `TextArea(size: .xl2)` each threw
/// `Null check operator used on a null value`.
///
/// So the unstated size renders at the nearest stated one, and an assert
/// says so in debug. The two halves are the point: a release build shows a
/// slightly-wrong size rather than a blank screen, and the developer who
/// wrote it hears about it the first time they run.
///
/// Downward, not nearest-in-either-direction: a component that stops at
/// `xl` stops because the larger step was not designed, so `xl` is what its
/// author last decided. Reaching upward would render a size the table
/// states for a *smaller* request, which is a worse guess.
///
/// Throws if [table] is empty — there is no nearest anything, and a caller
/// who reaches this with nothing to fall back on has a table that failed to
/// build rather than a size that was not designed.
T resolveSizeRow<T extends Object>(
  Map<CoreComponentSize, T> table,
  CoreComponentSize size,
) {
  final exact = table[size];
  if (exact != null) return exact;

  assert(
    table.isNotEmpty,
    'resolveSizeRow was handed an empty size table — nothing to fall back '
    'to. The table failed to build; this is not a missing size.',
  );

  // Declaration order is the ladder, so walking the index down walks the
  // sizes down.
  for (var i = size.index - 1; i >= 0; i--) {
    final smaller = table[CoreComponentSize.values[i]];
    if (smaller != null) {
      assert(
        false,
        'This component states no ${size.name} — it is drawn at '
        '${CoreComponentSize.values[i].name} and below. Rendering at '
        '${CoreComponentSize.values[i].name}; pass a stated size to say '
        'what you meant.',
      );
      return smaller;
    }
  }

  // Nothing below it either — the request is smaller than everything
  // stated, so take the smallest there is. Walked rather than reduced:
  // `reduce` infers its combiner from `T extends Object` and then refuses
  // the concrete `MapEntry<_, T>` it is handed at the call site.
  for (final candidate in CoreComponentSize.values) {
    final smallest = table[candidate];
    if (smallest != null) {
      assert(
        false,
        'This component states no ${size.name} — its smallest is '
        '${candidate.name}. Rendering at ${candidate.name}.',
      );
      return smallest;
    }
  }

  // Unreachable: the emptiness assert above already fired, and a non-empty
  // table has some member of the enum as a key.
  throw StateError('size table has no entry for any CoreComponentSize');
}
