# Table Examples

This document contains example code for the table component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class TableExample1 extends StatefulWidget {
  const TableExample1({super.key});

  @override
  State<TableExample1> createState() => _TableExample1State();
}

class _TableExample1State extends State<TableExample1> {
  TableCell buildHeaderCell(String text, [bool alignRight = false]) {
    return TableCell(
      child: Container(
        alignment: alignRight ? Alignment.centerRight : null,
        padding: const EdgeInsets.all(8),
        child: Text(text).baseContent().semiBold(),
      ),
    );
  }

  TableCell buildCell(String text, [bool alignRight = false]) {
    return TableCell(
      child: Container(
        alignment: alignRight ? Alignment.centerRight : null,
        padding: const EdgeInsets.all(8),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      rows: [
        TableRow(
          cells: [
            buildHeaderCell(t.docs.components.table.invoice),
            buildHeaderCell(t.docs.components.table.status),
            buildHeaderCell(t.docs.components.table.method),
            buildHeaderCell(t.docs.components.table.amount, true),
          ],
        ),
        TableRow(
          cells: [
            buildCell('INV001'),
            buildCell(t.docs.components.table.paid),
            buildCell(t.docs.components.table.credit_card),
            buildCell('\$250.00', true),
          ],
        ),
        TableRow(
          cells: [
            buildCell('INV002'),
            buildCell(t.docs.components.table.pending),
            buildCell(t.docs.components.table.paypal),
            buildCell('\$150.00', true),
          ],
        ),
        TableRow(
          cells: [
            buildCell('INV003'),
            buildCell(t.docs.components.table.unpaid),
            buildCell(t.docs.components.table.bank_transfer),
            buildCell('\$350.00', true),
          ],
        ),
        TableRow(
          cells: [
            buildCell('INV004'),
            buildCell(t.docs.components.table.paid),
            buildCell(t.docs.components.table.credit_card),
            buildCell('\$450.00', true),
          ],
        ),
        TableRow(
          cells: [
            buildCell('INV005'),
            buildCell(t.docs.components.table.paid),
            buildCell(t.docs.components.table.paypal),
            buildCell('\$550.00', true),
          ],
        ),
        TableRow(
          cells: [
            buildCell('INV006'),
            buildCell(t.docs.components.table.pending),
            buildCell(t.docs.components.table.bank_transfer),
            buildCell('\$200.00', true),
          ],
        ),
        TableRow(
          cells: [
            buildCell('INV007'),
            buildCell(t.docs.components.table.unpaid),
            buildCell(t.docs.components.table.credit_card),
            buildCell('\$300.00', true),
          ],
        ),
        TableFooter(
          cells: [
            TableCell(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Text(t.docs.components.table.total),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: const Text('\$2,300.00').semiBold(),
                      ),
                    ),
                  ],
                ),
              ),
              columnSpan: 4,
            ),
          ],
        ),
      ],
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class TableExample2 extends StatefulWidget {
  const TableExample2({super.key});

  @override
  State<TableExample2> createState() => _TableExample2State();
}

class _TableExample2State extends State<TableExample2> {
  TableCell buildCell(String text, [bool alignRight = false]) {
    final theme = Theme.of(context);
    return TableCell(
      child: Container(
        alignment: alignRight ? Alignment.topRight : null,
        padding: const EdgeInsets.all(8),
        child: Text(text),
      ),
      theme: TableCellTheme(
        border: WidgetStatePropertyAll(
          Border.all(
            color: theme.colorScheme.neutral,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
      ),
    );
  }

  final ResizableTableController controller = ResizableTableController(
    defaultColumnWidth: 150,
    defaultHeightConstraint: const ConstrainedTableSize(min: 40),
    defaultRowHeight: 40,
    defaultWidthConstraint: const ConstrainedTableSize(min: 80),
  );

  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      child: ResizableTable(
        controller: controller,
        rows: [
          TableHeader(
            cells: [
              buildCell(t.docs.components.table.invoice),
              buildCell(t.docs.components.table.status),
              buildCell(t.docs.components.table.method),
              buildCell(t.docs.components.table.amount, true),
            ],
          ),
          TableRow(
            cells: [
              buildCell('INV001'),
              buildCell(t.docs.components.table.paid),
              buildCell(t.docs.components.table.credit_card),
              buildCell('\$250.00', true),
            ],
          ),
          TableRow(
            cells: [
              buildCell('INV002'),
              buildCell(t.docs.components.table.pending),
              buildCell(t.docs.components.table.paypal),
              buildCell('\$150.00', true),
            ],
          ),
          TableRow(
            cells: [
              buildCell('INV003'),
              buildCell(t.docs.components.table.unpaid),
              buildCell(t.docs.components.table.bank_transfer),
              buildCell('\$350.00', true),
            ],
          ),
          TableRow(
            cells: [
              buildCell('INV004'),
              buildCell(t.docs.components.table.paid),
              buildCell(t.docs.components.table.credit_card),
              buildCell('\$450.00', true),
            ],
          ),
          TableRow(
            cells: [
              buildCell('INV005'),
              buildCell(t.docs.components.table.paid),
              buildCell(t.docs.components.table.paypal),
              buildCell('\$550.00', true),
            ],
          ),
          TableRow(
            cells: [
              buildCell('INV006'),
              buildCell(t.docs.components.table.pending),
              buildCell(t.docs.components.table.bank_transfer),
              buildCell('\$200.00', true),
            ],
          ),
          TableRow(
            cells: [
              buildCell('INV007'),
              buildCell(t.docs.components.table.unpaid),
              buildCell(t.docs.components.table.credit_card),
              buildCell('\$300.00', true),
            ],
          ),
          TableRow(
            cells: [
              buildCell('INV008'),
              buildCell(t.docs.components.table.paid),
              buildCell(t.docs.components.table.credit_card),
              buildCell('\$250.00', true),
            ],
          ),
          TableRow(
            cells: [
              buildCell('INV009'),
              buildCell(t.docs.components.table.pending),
              buildCell(t.docs.components.table.paypal),
              buildCell('\$150.00', true),
            ],
          ),
          TableRow(
            cells: [
              buildCell('INV010'),
              buildCell(t.docs.components.table.unpaid),
              buildCell(t.docs.components.table.bank_transfer),
              buildCell('\$350.00', true),
            ],
          ),
        ],
      ),
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class TableExample3 extends StatefulWidget {
  const TableExample3({super.key});

  @override
  State<TableExample3> createState() => _TableExample3State();
}

class _TableExample3State extends State<TableExample3> {
  TableCell buildCell(String text, [bool alignRight = false]) {
    final theme = Theme.of(context);
    return TableCell(
      child: Container(
        alignment: alignRight ? Alignment.topRight : null,
        padding: const EdgeInsets.all(8),
        child: Text(text),
      ),
      theme: TableCellTheme(
        border: WidgetStatePropertyAll(
          Border.all(
            color: theme.colorScheme.neutral,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        overscroll: false,
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SizedBox(
        height: 400,
        child: OutlinedContainer(
          child: ScrollableClient(
            builder: (context, offset, viewportSize, child) {
              return Table(
                defaultColumnWidth: const FixedTableSize(150),
                defaultRowHeight: const FixedTableSize(40),
                frozenCells: const FrozenTableData(
                  frozenColumns: [TableRef(0), TableRef(2)],
                  frozenRows: [TableRef(0), TableRef(3)],
                ),
                horizontalOffset: offset.dx,
                rows: [
                  TableHeader(
                    cells: [
                      buildCell(t.docs.components.table.invoice),
                      buildCell(t.docs.components.table.status),
                      buildCell(t.docs.components.table.method),
                      buildCell(t.docs.components.table.amount, true),
                      buildCell('Verification'),
                      buildCell('Last Updated'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV001'),
                      buildCell(t.docs.components.table.paid),
                      buildCell(t.docs.components.table.credit_card),
                      buildCell('\$250.00', true),
                      buildCell('Verified'),
                      buildCell('2 hours ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV002'),
                      buildCell(t.docs.components.table.pending),
                      buildCell(t.docs.components.table.paypal),
                      buildCell('\$150.00', true),
                      buildCell('Pending'),
                      buildCell('1 day ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV003'),
                      buildCell(t.docs.components.table.unpaid),
                      buildCell(t.docs.components.table.bank_transfer),
                      buildCell('\$350.00', true),
                      buildCell('Unverified'),
                      buildCell('1 week ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV004'),
                      buildCell(t.docs.components.table.paid),
                      buildCell(t.docs.components.table.credit_card),
                      buildCell('\$450.00', true),
                      buildCell('Verified'),
                      buildCell('2 weeks ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV005'),
                      buildCell(t.docs.components.table.paid),
                      buildCell(t.docs.components.table.paypal),
                      buildCell('\$550.00', true),
                      buildCell('Verified'),
                      buildCell('3 weeks ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV006'),
                      buildCell(t.docs.components.table.pending),
                      buildCell(t.docs.components.table.bank_transfer),
                      buildCell('\$200.00', true),
                      buildCell('Pending'),
                      buildCell('1 month ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV007'),
                      buildCell(t.docs.components.table.unpaid),
                      buildCell(t.docs.components.table.credit_card),
                      buildCell('\$300.00', true),
                      buildCell('Unverified'),
                      buildCell('1 year ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV008'),
                      buildCell(t.docs.components.table.paid),
                      buildCell(t.docs.components.table.credit_card),
                      buildCell('\$250.00', true),
                      buildCell('Verified'),
                      buildCell('2 hours ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV009'),
                      buildCell(t.docs.components.table.pending),
                      buildCell(t.docs.components.table.paypal),
                      buildCell('\$150.00', true),
                      buildCell('Pending'),
                      buildCell('1 day ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV010'),
                      buildCell(t.docs.components.table.unpaid),
                      buildCell(t.docs.components.table.bank_transfer),
                      buildCell('\$350.00', true),
                      buildCell('Unverified'),
                      buildCell('1 week ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV011'),
                      buildCell(t.docs.components.table.paid),
                      buildCell(t.docs.components.table.credit_card),
                      buildCell('\$450.00', true),
                      buildCell('Verified'),
                      buildCell('2 weeks ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV012'),
                      buildCell(t.docs.components.table.paid),
                      buildCell(t.docs.components.table.paypal),
                      buildCell('\$550.00', true),
                      buildCell('Verified'),
                      buildCell('3 weeks ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV013'),
                      buildCell(t.docs.components.table.pending),
                      buildCell(t.docs.components.table.bank_transfer),
                      buildCell('\$200.00', true),
                      buildCell('Pending'),
                      buildCell('1 month ago'),
                    ],
                  ),
                  TableRow(
                    cells: [
                      buildCell('INV014'),
                      buildCell(t.docs.components.table.unpaid),
                      buildCell(t.docs.components.table.credit_card),
                      buildCell('\$300.00', true),
                      buildCell('Unverified'),
                      buildCell('1 year ago'),
                    ],
                  ),
                ],
                verticalOffset: offset.dy,
                viewportSize: viewportSize,
              );
            },
            diagonalDragBehavior: DiagonalDragBehavior.free,
          ),
        ),
      ),
    );
  }
}

```

