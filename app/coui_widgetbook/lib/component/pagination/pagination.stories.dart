import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'pagination.stories.g.dart';

const _kTotalPages = 10;
const _kMaxPages = 5;
const _kAdvancedTotalPages = 20;

/// Interactive demo host for [Pagination] stories.
class PaginationDemo extends StatefulWidget {
  /// Creates a [PaginationDemo].
  const PaginationDemo({
    super.key,
    this.totalPages = _kTotalPages,
    this.maxPages = _kMaxPages,
    this.showSkipToFirstPage = true,
    this.showSkipToLastPage = true,
    this.hidePreviousOnFirstPage = false,
    this.hideNextOnLastPage = false,
  });

  /// Total number of pages.
  final int totalPages;

  /// Maximum number of page buttons shown at once.
  final int maxPages;

  /// Whether the skip-to-first-page button is shown.
  final bool showSkipToFirstPage;

  /// Whether the skip-to-last-page button is shown.
  final bool showSkipToLastPage;

  /// Whether the previous button hides on the first page.
  final bool hidePreviousOnFirstPage;

  /// Whether the next button hides on the last page.
  final bool hideNextOnLastPage;

  @override
  State<PaginationDemo> createState() => _PaginationDemoState();
}

class _PaginationDemoState extends State<PaginationDemo> {
  int _currentPage = 1;

  void handlePageChanged(int page) {
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        spacing: CoreSpace.space24,
        children: [
          Pagination(
            page: _currentPage,
            totalPages: widget.totalPages,
            onPageChanged: handlePageChanged,
            maxPages: widget.maxPages,
            showSkipToFirstPage: widget.showSkipToFirstPage,
            showSkipToLastPage: widget.showSkipToLastPage,
            hidePreviousOnFirstPage: widget.hidePreviousOnFirstPage,
            hideNextOnLastPage: widget.hideNextOnLastPage,
          ),
          Text(
            t.widgetbook.common.page_of(
              current: _currentPage.toString(),
              total: widget.totalPages.toString(),
            ),
          ).medium(),
        ],
      ),
    );
  }
}

/// Navigation metadata for the Pagination component.
const kComponentMeta = ComponentMeta(name: 'Pagination', path: 'navigation');

/// Story metadata for [PaginationDemo].
const kMeta = Meta(PaginationDemo.new);

/// Basic pagination with editable page-count knobs.
final $Default = _Story();

/// Advanced pagination exercising skip / hide button knobs.
final $Advanced = _Story(
  args: _Args(totalPages: IntArg(_kAdvancedTotalPages)),
);
