/// Which buttons a `Pagination` row draws, and how it gives them up when
/// the row is wider than the space it is laid out in.
///
/// Both platforms read this one table, so a Flutter row and a Web row of
/// the same configuration shed the same buttons in the same order — only
/// the measuring differs (a render object on Flutter, a DOM measurer on
/// Web).
library;

import 'package:meta/meta.dart';

/// A step down the row's compaction ladder.
///
/// Steps are cumulative: each one keeps everything the previous step
/// already gave up. The order is the order the row gives things up in —
/// the labels first (an icon still says "previous" / "next", and the
/// label text stays the button's accessible name), then the edge
/// shortcuts, then the page window, then the ellipses.
enum CorePaginationCompaction {
  /// Everything the widget's configuration asks for.
  none,

  /// Previous / next show only their chevron.
  iconOnlyNavigation,

  /// The skip-to-first / skip-to-last page buttons are dropped.
  withoutEdgePages,

  /// Only the current page number is shown.
  currentPageOnly,

  /// The ellipsis buttons are dropped too — previous, current, next.
  withoutEllipses,
}

/// Which way a previous / next button goes.
enum CorePaginationDirection {
  /// Towards page 1.
  previous,

  /// Towards the last page.
  next,
}

/// One button in a pagination row.
@immutable
sealed class CorePaginationEntry {
  const CorePaginationEntry();
}

/// A previous / next button.
final class CorePaginationNavigationEntry extends CorePaginationEntry {
  /// Creates a [CorePaginationNavigationEntry].
  const CorePaginationNavigationEntry({
    required this.direction,
    required this.enabled,
    required this.targetPage,
    required this.showsLabel,
  });

  /// Which way the button goes.
  final CorePaginationDirection direction;

  /// Whether there is a page in that direction.
  final bool enabled;

  /// The page the button moves to.
  final int targetPage;

  /// Whether the label text is drawn next to the chevron. When `false`
  /// the label is still the button's accessible name.
  final bool showsLabel;

  @override
  bool operator ==(Object other) =>
      other is CorePaginationNavigationEntry &&
      other.direction == direction &&
      other.enabled == enabled &&
      other.targetPage == targetPage &&
      other.showsLabel == showsLabel;

  @override
  int get hashCode => Object.hash(direction, enabled, targetPage, showsLabel);
}

/// A page-number button.
final class CorePaginationPageEntry extends CorePaginationEntry {
  /// Creates a [CorePaginationPageEntry].
  const CorePaginationPageEntry({required this.page, required this.active});

  /// The one-based page number.
  final int page;

  /// Whether this is the current page.
  final bool active;

  @override
  bool operator ==(Object other) =>
      other is CorePaginationPageEntry &&
      other.page == page &&
      other.active == active;

  @override
  int get hashCode => Object.hash(page, active);
}

/// An ellipsis button standing in for a hidden range of pages.
final class CorePaginationEllipsisEntry extends CorePaginationEntry {
  /// Creates a [CorePaginationEllipsisEntry].
  const CorePaginationEllipsisEntry({
    required this.leading,
    required this.targetPage,
  });

  /// Whether the hidden range is before the shown window.
  final bool leading;

  /// The page the ellipsis jumps to — the nearest hidden page.
  final int targetPage;

  @override
  bool operator ==(Object other) =>
      other is CorePaginationEllipsisEntry &&
      other.leading == leading &&
      other.targetPage == targetPage;

  @override
  int get hashCode => Object.hash(leading, targetPage);
}

/// The row a `Pagination` draws at each compaction step.
abstract final class CorePaginationLayout {
  /// The buttons of a row at [compaction], in reading order.
  static List<CorePaginationEntry> entries({
    required int page,
    required int totalPages,
    required int maxPages,
    required bool showSkipToFirstPage,
    required bool showSkipToLastPage,
    required bool hidePreviousOnFirstPage,
    required bool hideNextOnLastPage,
    required bool showLabel,
    CorePaginationCompaction compaction = CorePaginationCompaction.none,
  }) {
    final step = compaction.index;
    final showsLabel =
        showLabel && step < CorePaginationCompaction.iconOnlyNavigation.index;
    final edgePages = step < CorePaginationCompaction.withoutEdgePages.index;
    final windowSize = step < CorePaginationCompaction.currentPageOnly.index
        ? maxPages
        : 1;
    final ellipses = step < CorePaginationCompaction.withoutEllipses.index;

    final hasPrevious = page > 1;
    final hasNext = page < totalPages;

    final firstShown = _firstShownPage(page, totalPages, windowSize);
    final lastShown = _lastShownPage(page, totalPages, windowSize);

    return [
      if (!hidePreviousOnFirstPage || hasPrevious)
        CorePaginationNavigationEntry(
          direction: CorePaginationDirection.previous,
          enabled: hasPrevious,
          targetPage: page - 1,
          showsLabel: showsLabel,
        ),
      if (ellipses && firstShown > 1) ...[
        if (edgePages && showSkipToFirstPage && firstShown - 1 > 1)
          CorePaginationPageEntry(page: 1, active: page == 1),
        CorePaginationEllipsisEntry(leading: true, targetPage: firstShown - 1),
      ],
      for (final p in _window(page, totalPages, windowSize))
        CorePaginationPageEntry(page: p, active: p == page),
      if (ellipses && lastShown < totalPages) ...[
        CorePaginationEllipsisEntry(leading: false, targetPage: lastShown + 1),
        if (edgePages && showSkipToLastPage && lastShown + 1 < totalPages)
          CorePaginationPageEntry(page: totalPages, active: page == totalPages),
      ],
      if (!hideNextOnLastPage || hasNext)
        CorePaginationNavigationEntry(
          direction: CorePaginationDirection.next,
          enabled: hasNext,
          targetPage: page + 1,
          showsLabel: showsLabel,
        ),
    ];
  }

  /// The compaction steps that actually change this row, starting with
  /// [CorePaginationCompaction.none].
  ///
  /// A step is listed only when it is narrower than the one before it:
  /// it draws fewer buttons, or it drops the labels. Every other button
  /// is the same square box, so a step that only trades buttons — three
  /// pages for "… current …" — is left out, and so is one that changes
  /// nothing (a row without labels has nothing to give up at
  /// [CorePaginationCompaction.iconOnlyNavigation]).
  static List<CorePaginationCompaction> ladder({
    required int page,
    required int totalPages,
    required int maxPages,
    required bool showSkipToFirstPage,
    required bool showSkipToLastPage,
    required bool hidePreviousOnFirstPage,
    required bool hideNextOnLastPage,
    required bool showLabel,
  }) {
    final steps = <CorePaginationCompaction>[];
    List<CorePaginationEntry>? previous;
    for (final compaction in CorePaginationCompaction.values) {
      final current = entries(
        page: page,
        totalPages: totalPages,
        maxPages: maxPages,
        showSkipToFirstPage: showSkipToFirstPage,
        showSkipToLastPage: showSkipToLastPage,
        hidePreviousOnFirstPage: hidePreviousOnFirstPage,
        hideNextOnLastPage: hideNextOnLastPage,
        showLabel: showLabel,
        compaction: compaction,
      );
      if (previous == null || _narrower(current, than: previous)) {
        steps.add(compaction);
        previous = current;
      }
    }
    return steps;
  }

  static bool _narrower(
    List<CorePaginationEntry> entries, {
    required List<CorePaginationEntry> than,
  }) {
    if (entries.length != than.length) return entries.length < than.length;
    return _showsLabels(than) && !_showsLabels(entries);
  }

  static bool _showsLabels(List<CorePaginationEntry> entries) => entries.any(
    (entry) => entry is CorePaginationNavigationEntry && entry.showsLabel,
  );

  static Iterable<int> _window(int page, int totalPages, int size) sync* {
    if (totalPages <= size) {
      yield* List.generate(totalPages, (index) => index + 1);
    } else {
      final start = page - size ~/ 2;
      final end = page + size ~/ 2;
      if (start < 1) {
        yield* List.generate(size, (index) => index + 1);
      } else if (end > totalPages) {
        yield* List.generate(size, (index) => totalPages - size + index + 1);
      } else {
        yield* List.generate(size, (index) => start + index);
      }
    }
  }

  static int _firstShownPage(int page, int totalPages, int size) {
    if (totalPages <= size) return 1;
    final start = page - size ~/ 2;
    return start < 1 ? 1 : start;
  }

  static int _lastShownPage(int page, int totalPages, int size) {
    if (totalPages <= size) return totalPages;
    final end = page + size ~/ 2;
    return end > totalPages ? totalPages : end;
  }
}
