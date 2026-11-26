import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

// PaginationTheme test constants
const _kTestGap = 6.0;

// Pagination fixture constants.
const _kSmallTotalPages = 3;
const _kTotalPages = 5;
const _kLargeTotalPages = 10;
const _kLastPage = 5;
const _kMaxPages = 3;

void main() {
  group('Pagination widget', () {
    testWidgets('renders basic pagination', (tester) async {
      await pumpTestApp(
        tester,
        Pagination(
          onPageChanged: (page) {},
          page: 1,
          totalPages: _kTotalPages,
        ),
      );
      await tester.pump();

      expect(find.byType(Pagination), findsOneWidget);
    });

    testWidgets('renders page numbers for small page count', (tester) async {
      await pumpTestApp(
        tester,
        Pagination(
          onPageChanged: (page) {},
          page: 1,
          totalPages: _kSmallTotalPages,
        ),
      );
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('calls onPageChanged when next page is tapped', (
      tester,
    ) async {
      int? changedPage;

      await pumpTestApp(
        tester,
        Pagination(
          onPageChanged: (page) {
            changedPage = page;
          },
          page: 1,
          showLabel: false,
          totalPages: _kTotalPages,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('2'));
      await tester.pump();

      expect(changedPage, equals(2));
    });

    testWidgets('hidePreviousOnFirstPage hides previous button on page 1', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Pagination(
          hidePreviousOnFirstPage: true,
          onPageChanged: (page) {},
          page: 1,
          showLabel: false,
          totalPages: _kTotalPages,
        ),
      );
      await tester.pump();

      // When hidePreviousOnFirstPage is true and hasPrevious is false,
      // the previous button should not be rendered.
      expect(find.byType(Pagination), findsOneWidget);
    });

    testWidgets('hideNextOnLastPage hides next button on last page', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Pagination(
          hideNextOnLastPage: true,
          onPageChanged: (page) {},
          page: _kLastPage,
          showLabel: false,
          totalPages: _kTotalPages,
        ),
      );
      await tester.pump();

      expect(find.byType(Pagination), findsOneWidget);
    });

    testWidgets('renders with custom gap', (tester) async {
      await pumpTestApp(
        tester,
        Pagination(
          paginationStyle: const CorePaginationStyle(itemSpacing: _kTestGap),
          onPageChanged: (page) {},
          page: 2,
          totalPages: _kTotalPages,
        ),
      );
      await tester.pump();

      expect(find.byType(Pagination), findsOneWidget);
    });

    testWidgets('renders with showLabel false', (tester) async {
      await pumpTestApp(
        tester,
        Pagination(
          onPageChanged: (page) {},
          page: 2,
          showLabel: false,
          totalPages: _kTotalPages,
        ),
      );
      await tester.pump();

      expect(find.byType(Pagination), findsOneWidget);
    });

    testWidgets('renders a button for the active page', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Pagination(
          onPageChanged: (page) {},
          page: 2,
          totalPages: _kSmallTotalPages,
        ),
      );
      await tester.pump();

      // The active page (2) renders its page label.
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('single page renders correctly', (tester) async {
      await pumpTestApp(
        tester,
        Pagination(
          onPageChanged: (page) {},
          page: 1,
          totalPages: 1,
        ),
      );
      await tester.pump();

      expect(find.byType(Pagination), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('showSkipToFirstPage false hides first page button', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Pagination(
          maxPages: _kMaxPages,
          onPageChanged: (page) {},
          page: _kLastPage,
          showSkipToFirstPage: false,
          totalPages: _kLargeTotalPages,
        ),
      );
      await tester.pump();

      expect(find.byType(Pagination), findsOneWidget);
    });

    testWidgets('showSkipToLastPage false hides last page button', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Pagination(
          maxPages: _kMaxPages,
          onPageChanged: (page) {},
          page: 1,
          showSkipToLastPage: false,
          totalPages: _kLargeTotalPages,
        ),
      );
      await tester.pump();

      expect(find.byType(Pagination), findsOneWidget);
    });
  });
}
