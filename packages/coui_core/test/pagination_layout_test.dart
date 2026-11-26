import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

List<CorePaginationEntry> _entries(CorePaginationCompaction compaction) =>
    CorePaginationLayout.entries(
      page: 5,
      totalPages: 10,
      maxPages: 3,
      showSkipToFirstPage: true,
      showSkipToLastPage: true,
      hidePreviousOnFirstPage: false,
      hideNextOnLastPage: false,
      showLabel: true,
      compaction: compaction,
    );

String _describe(List<CorePaginationEntry> entries) => entries
    .map(
      (entry) => switch (entry) {
        CorePaginationNavigationEntry(:final direction, :final showsLabel) =>
          '${direction.name}${showsLabel ? '+label' : ''}',
        CorePaginationPageEntry(:final page, :final active) =>
          active ? '[$page]' : '$page',
        CorePaginationEllipsisEntry(:final targetPage) => '…$targetPage',
      },
    )
    .join(' ');

void main() {
  group('CorePaginationLayout', () {
    test('each step gives up one more thing, labels first', () {
      expect(
        _describe(_entries(.none)),
        'previous+label 1 …3 4 [5] 6 …7 10 next+label',
      );
      expect(
        _describe(_entries(.iconOnlyNavigation)),
        'previous 1 …3 4 [5] 6 …7 10 next',
      );
      expect(
        _describe(_entries(.withoutEdgePages)),
        'previous …3 4 [5] 6 …7 next',
      );
      expect(_describe(_entries(.currentPageOnly)), 'previous …4 [5] …6 next');
      expect(_describe(_entries(.withoutEllipses)), 'previous [5] next');
    });

    test('the ladder leaves out steps that change nothing', () {
      final ladder = CorePaginationLayout.ladder(
        page: 2,
        totalPages: 3,
        maxPages: 3,
        showSkipToFirstPage: true,
        showSkipToLastPage: true,
        hidePreviousOnFirstPage: false,
        hideNextOnLastPage: false,
        showLabel: false,
      );
      // No labels to drop and no edge pages. "…1 [2] …3" is as wide as
      // "1 2 3", so the window step is skipped for the one that drops
      // the ellipses.
      expect(ladder, [
        CorePaginationCompaction.none,
        CorePaginationCompaction.withoutEllipses,
      ]);
    });

    test('a single page has nothing to give up', () {
      final ladder = CorePaginationLayout.ladder(
        page: 1,
        totalPages: 1,
        maxPages: 3,
        showSkipToFirstPage: true,
        showSkipToLastPage: true,
        hidePreviousOnFirstPage: false,
        hideNextOnLastPage: false,
        showLabel: false,
      );
      expect(ladder, [CorePaginationCompaction.none]);
    });
  });
}
