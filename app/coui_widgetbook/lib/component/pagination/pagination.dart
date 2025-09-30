import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Pagination] use case.
@UseCase(
  name: 'default',
  type: coui.Pagination,
)
Widget buildPaginationDefaultUseCase(BuildContext context) {
  return coui.Pagination(
    onPageChanged: (page) {
      // ignore: avoid_print
      print('Page changed to: $page');
    },
    page: context.knobs.int.slider(
      initialValue: 1,
      label: 'current page',
      max: 10,
      min: 1,
    ),
    totalPages: context.knobs.int.slider(
      initialValue: 10,
      label: 'total pages',
      max: 20,
      min: 1,
    ),
  );
}

/// A [coui.Pagination] with max pages use case.
@UseCase(
  name: 'with max pages',
  type: coui.Pagination,
)
Widget buildPaginationWithMaxPagesUseCase(BuildContext context) {
  return coui.Pagination(
    maxPages: context.knobs.int.slider(
      initialValue: 5,
      label: 'max visible pages',
      max: 10,
      min: 3,
    ),
    onPageChanged: (page) {
      // ignore: avoid_print
      print('Page: $page');
    },
    page: 5,
    totalPages: 20,
  );
}

/// A [coui.Pagination] with skip buttons use case.
@UseCase(
  name: 'with skip buttons',
  type: coui.Pagination,
)
Widget buildPaginationWithSkipButtonsUseCase(BuildContext context) {
  return coui.Pagination(
    onPageChanged: (page) {
      // ignore: avoid_print
      print('Page: $page');
    },
    page: context.knobs.int.slider(
      initialValue: 5,
      label: 'page',
      max: 15,
      min: 1,
    ),
    showSkipToFirstPage: context.knobs.boolean(
      initialValue: true,
      label: 'show first',
    ),
    showSkipToLastPage: context.knobs.boolean(
      initialValue: true,
      label: 'show last',
    ),
    totalPages: 15,
  );
}

/// A [coui.Pagination] with hide on boundary use case.
@UseCase(
  name: 'hide on boundary',
  type: coui.Pagination,
)
Widget buildPaginationHideOnBoundaryUseCase(BuildContext context) {
  return coui.Pagination(
    hideNextOnLastPage: true,
    hidePreviousOnFirstPage: true,
    onPageChanged: (page) {
      // ignore: avoid_print
      print('Page: $page');
    },
    page: context.knobs.int.slider(
      initialValue: 1,
      label: 'page',
      max: 10,
      min: 1,
    ),
    totalPages: 10,
  );
}
