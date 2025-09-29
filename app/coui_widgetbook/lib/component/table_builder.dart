import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class _DemoItem {
  const _DemoItem({
    required this.id,
    required this.title,
    required this.author,
  });
  final int id;
  final String title;
  final String author;
}

/// TableBuilder 유즈케이스
@UseCase(
  name: 'default',
  type: TableBuilder,
  path: '[Component]',
)
Widget buildTableBuilderDefaultUseCase(BuildContext context) {
  final width = context.knobs.double.slider(
    initialValue: 720,
    label: 'tableWidth',
    max: 1400,
    min: 320,
  );
  final showNumber = context.knobs.boolean(
    initialValue: true,
    label: 'showNumber',
  );
  final showCheckbox = context.knobs.boolean(label: 'showCheckbox');

  final items = List<_DemoItem>.generate(
    20,
    (i) => _DemoItem(
      author: '저자 ${i + 1}',
      id: i + 1,
      title: '도서 #${i + 1}',
    ),
  );

  final columns = <TableColumnDef<_DemoItem>>[
    TableColumnDef<_DemoItem>(
      cellBuilder: (context, item) =>
          Text(item.title, overflow: TextOverflow.ellipsis),
      headerText: '제목',
      width: 280,
    ),
    TableColumnDef<_DemoItem>(
      cellBuilder: (context, item) =>
          Text(item.author, overflow: TextOverflow.ellipsis),
      headerText: '저자',
      width: 200,
    ),
  ];

  return Padding(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      height: 440,
      child: TableBuilder<_DemoItem>(
        columns: columns,
        items: items,
        showCheckboxColumn: showCheckbox,
        showNumberColumn: showNumber,
        tableWidth: width,
      ),
    ),
  );
}
