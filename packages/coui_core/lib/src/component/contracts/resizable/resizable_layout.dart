/// Pane geometry for a resizable split — the one seat where a declared
/// pane list becomes the numbers both platforms lay out, announce and drag
/// against.
library;

import 'dart:math' as math;

import 'package:coui_core/src/component/contracts/resizable/resizable_contract.dart';
import 'package:meta/meta.dart';

/// The container, expressed as the ratio the pane sizes add up to.
///
/// `minSize` / `maxSize` are fractions of this same whole, which is the
/// only reason a pane's declared floor is comparable to a pane's size at
/// all. Sizes that do not add up to it make the two incomparable: the
/// layout divides by their total while everything else reads them as
/// fractions of the container, so a pane rendered at half the width
/// announces whatever fraction it happened to be declared as.
const _kWholeContainer = 1.0;

/// Resolved pane geometry: sizes that fill the container together with the
/// bounds they satisfy.
///
/// Three invariants hold for every instance, and everything else in this
/// file exists to establish them:
///
/// 1. `minSizes[i] <= sizes[i] <= maxSizes[i]` for every pane.
/// 2. `sizes` sums to the whole container.
/// 3. `minSizes[i] <= maxSizes[i]`, and the bound set is satisfiable
///    (`sum(minSizes) <= 1 <= sum(maxSizes)`).
///
/// Together they are what makes a divider's announced position land inside
/// its announced range: [dividerRange] intersects the two adjacent panes'
/// bounds, and (1)+(3) put the current size inside that intersection by
/// construction rather than by a defensive clamp at the announce site. A
/// clamp there would have to lie — it would read out a position the layout
/// is not drawing — and when the intersection came out inverted it did not
/// even get that far: `num.clamp` asserts `lowerLimit <= upperLimit`, so
/// the whole widget threw instead of rendering.
///
/// (2) is what makes the announced percentage the rendered one. The layout
/// divides each size by their total, so sizes that add up to `0.6` render
/// a `0.3` pane at half the container while the same `0.3` is announced as
/// 30%.
@immutable
class CoreResizableLayout {
  const CoreResizableLayout._({
    required this.sizes,
    required this.minSizes,
    required this.maxSizes,
  });

  /// Pane sizes as fractions of the container, in pane order. Sums to the
  /// whole container.
  final List<double> sizes;

  /// The floor each entry of [sizes] respects, in pane order. Equal to the
  /// pane's declared `minSize` unless the declared floors could not fit in
  /// the container together.
  final List<double> minSizes;

  /// The ceiling each entry of [sizes] respects, in pane order. Equal to
  /// the pane's declared `maxSize` unless the declared ceilings could not
  /// fill the container together.
  final List<double> maxSizes;

  /// Resolves the geometry declared by [panes].
  ///
  /// The declared numbers are treated as intent, not as truth: a pane list
  /// is a hand-written literal, so its ratios can miss the whole container
  /// and its bounds can contradict each other or the space available. This
  /// turns whatever was declared into the nearest geometry that satisfies
  /// the invariants above, in four steps:
  ///
  /// 1. Each pane's bounds are pulled into `[0, 1]`, and a ceiling below
  ///    its own floor is raised to meet it — a floor is a statement about
  ///    content staying usable, a ceiling is a statement about restraint,
  ///    and only the first one breaks something when it loses.
  /// 2. Floors that together exceed the container are scaled down by one
  ///    shared factor, ceilings that together cannot fill it are scaled up
  ///    the same way. Impossible bounds have to give somewhere; scaling
  ///    keeps every pane's declared share of the pressure.
  /// 3. The declared ratios are normalised to the whole container (or, if
  ///    they carry no information at all, replaced by an even split).
  /// 4. Each size is clamped into its bounds and the residual that clamping
  ///    created is handed back to the panes proportionally to the room they
  ///    have left. One pass places all of it: after step 2 the room across
  ///    all panes covers any residual clamping can produce, so no pane is
  ///    pushed back out of its bounds.
  static CoreResizableLayout resolve<W>(
    List<CoreResizablePaneData<W>> panes,
  ) {
    if (panes.isEmpty) {
      return const CoreResizableLayout._(
        sizes: [],
        minSizes: [],
        maxSizes: [],
      );
    }

    final floors = [
      for (final pane in panes) _intoWhole(pane.minSize ?? 0),
    ];
    final ceilings = [
      for (int i = 0; i < panes.length; i++)
        math.max(floors[i], _intoWhole(panes[i].maxSize ?? _kWholeContainer)),
    ];

    final satisfiableFloors = _satisfiableFloors(floors);
    final satisfiableCeilings = _satisfiableCeilings(ceilings);

    return CoreResizableLayout._(
      sizes: _fit(
        _seedSizes(panes),
        satisfiableFloors,
        satisfiableCeilings,
      ),
      minSizes: satisfiableFloors,
      maxSizes: satisfiableCeilings,
    );
  }

  /// Whether [before] and [after] declare the same pane geometry — the same
  /// pane count and the same `initialSize` / `minSize` / `maxSize` on every
  /// pane.
  ///
  /// A rebuild that swaps only pane *content* leaves the geometry alone, so
  /// the sizes a user has already dragged to survive it. A rebuild that
  /// changes any declared ratio or bound is a new declaration, and
  /// re-resolving on it is what keeps the invariants true past the first
  /// frame: sizes resolved once at mount go on satisfying the bounds of a
  /// pane list that no longer exists, which is the same inverted-range,
  /// frozen-divider state resolving was supposed to remove.
  static bool declaresSameGeometry<W>(
    List<CoreResizablePaneData<W>> before,
    List<CoreResizablePaneData<W>> after,
  ) {
    if (identical(before, after)) return true;
    if (before.length != after.length) return false;
    for (var i = 0; i < before.length; i++) {
      if (before[i].initialSize != after[i].initialSize ||
          before[i].minSize != after[i].minSize ||
          before[i].maxSize != after[i].maxSize) {
        return false;
      }
    }
    return true;
  }

  /// The reachable `[min, max]` for the divider at [dividerIndex] — the
  /// ratio of its left (or top) pane — together with where it currently
  /// sits.
  ///
  /// The range is the intersection of the left pane's own bounds with what
  /// the right pane's bounds leave it, since moving a divider spends one
  /// pane's space on the other. This is the single description of where a
  /// divider may go: pointer drag, keyboard step and the announced
  /// `min`/`max` all read it, so a screen reader cannot name a bound the
  /// drag does not enforce.
  ({double min, double max, double now}) dividerRange(int dividerIndex) {
    final leftIndex = dividerIndex;
    final rightIndex = dividerIndex + 1;
    final pairTotal = sizes[leftIndex] + sizes[rightIndex];
    final min = math.max(
      minSizes[leftIndex],
      pairTotal - maxSizes[rightIndex],
    );
    final max = math.min(
      maxSizes[leftIndex],
      pairTotal - minSizes[rightIndex],
    );

    return (
      min: min,
      // The satisfiable bounds already put `min` at or below `max`; folding
      // is the last line of defence, because the alternative to a degenerate
      // range here is not a wrong number — it is `num.clamp` asserting and
      // the component failing to build.
      max: math.max(min, max),
      now: sizes[leftIndex],
    );
  }

  /// The layout after moving the divider at [dividerIndex] by [deltaRatio]
  /// of the container, or `null` when the divider is already against that
  /// end of [dividerRange] and nothing would change.
  ///
  /// The move spends the delta between the two adjacent panes, so their
  /// combined size — and with it the total across all panes — is preserved
  /// by construction. Clamping to the range rather than refusing a move
  /// that leaves it is what lets a divider reach its bound exactly, and is
  /// the reason a step smaller than the distance back into a legal range
  /// can no longer be rejected forever.
  ///
  /// A `null` return is the signal not to emit a resize: it means the
  /// divider did not move, not that the caller passed something invalid.
  CoreResizableLayout? moveDivider(int dividerIndex, double deltaRatio) {
    if (!deltaRatio.isFinite) return null;
    final range = dividerRange(dividerIndex);
    final left = math.min(
      range.max,
      math.max(range.min, range.now + deltaRatio),
    );
    if (left == range.now) return null;

    final leftIndex = dividerIndex;
    final rightIndex = dividerIndex + 1;
    final pairTotal = sizes[leftIndex] + sizes[rightIndex];

    return CoreResizableLayout._(
      sizes: [
        for (int i = 0; i < sizes.length; i++)
          if (i == leftIndex)
            left
          else if (i == rightIndex)
            pairTotal - left
          else
            sizes[i],
      ],
      minSizes: minSizes,
      maxSizes: maxSizes,
    );
  }

  /// A declared bound pulled into the container it is a fraction of. A
  /// non-finite bound carries no information, so it reads as no bound.
  static double _intoWhole(double value) {
    if (!value.isFinite) return 0;
    return math.min(_kWholeContainer, math.max(0, value));
  }

  static double _total(List<double> values) =>
      values.fold<double>(0, (sum, value) => sum + value);

  /// Floors that can be satisfied together. Floors asking for more than the
  /// container has are scaled by one shared factor rather than dropped —
  /// every pane keeps its declared share of the space that does exist,
  /// where dropping would hand one pane everything it asked for and the
  /// rest nothing.
  static List<double> _satisfiableFloors(List<double> declared) {
    final total = _total(declared);
    if (total <= _kWholeContainer) return declared;
    return [for (final floor in declared) floor / total];
  }

  /// Ceilings that can fill the container together.
  static List<double> _satisfiableCeilings(List<double> declared) {
    final total = _total(declared);
    if (total >= _kWholeContainer) return declared;
    // Every pane declared a zero ceiling: there is nothing to scale, and no
    // set of sizes fills the container. Dropping the ceilings leaves a
    // laid-out split; honouring them leaves an empty one.
    if (total <= 0) return [for (final _ in declared) _kWholeContainer];
    return [for (final ceiling in declared) ceiling / total];
  }

  /// The declared ratios as fractions of the whole container.
  static List<double> _seedSizes<W>(List<CoreResizablePaneData<W>> panes) {
    final declared = [
      for (final pane in panes)
        if (pane.initialSize.isFinite && pane.initialSize > 0)
          pane.initialSize
        else
          0.0,
    ];
    final total = _total(declared);
    if (total <= 0) {
      final even = _kWholeContainer / panes.length;
      return [for (final _ in panes) even];
    }
    return [for (final size in declared) size / total];
  }

  /// [seeds] clamped into `[floors, ceilings]`, with whatever clamping
  /// added or removed handed back proportionally to the room each pane has
  /// left in that direction.
  static List<double> _fit(
    List<double> seeds,
    List<double> floors,
    List<double> ceilings,
  ) {
    final clamped = [
      for (int i = 0; i < seeds.length; i++)
        math.min(ceilings[i], math.max(floors[i], seeds[i])),
    ];
    final residual = _kWholeContainer - _total(clamped);
    if (residual == 0) return clamped;

    // Room to grow when the residual is positive, room to give back when it
    // is negative. Both totals cover the residual because the bounds are
    // satisfiable, so distributing proportionally lands every pane inside
    // its own room and one pass is enough.
    final room = [
      for (int i = 0; i < clamped.length; i++)
        if (residual > 0) ceilings[i] - clamped[i] else clamped[i] - floors[i],
    ];
    final roomTotal = _total(room);
    if (roomTotal <= 0) return clamped;

    return [
      for (int i = 0; i < clamped.length; i++)
        math.min(
          ceilings[i],
          math.max(
            floors[i],
            clamped[i] + residual * room[i] / roomTotal,
          ),
        ),
    ];
  }
}
