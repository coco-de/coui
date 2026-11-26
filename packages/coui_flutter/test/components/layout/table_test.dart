import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

List<CoreTableRowData<Widget>> _rows() => [
  CoreTableRowData.header(
    cells: [CoreTableCellData(child: const material.Text('Header'))],
  ),
  CoreTableRowData(
    cells: [CoreTableCellData(child: const material.Text('Cell'))],
  ),
];

void main() {
  group('Table', () {
    testWidgets('renders header and body cells', (tester) async {
      await tester.pumpWidget(_buildApp(Table(rows: _rows())));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Cell'), findsOneWidget);
    });

    testWidgets(
      'frozenCellBackgroundColor override reaches a frozen body cell',
      (tester) async {
        const overrideColor = Color(0xFFAA00AA);
        await tester.pumpWidget(
          _buildApp(
            Table(
              rows: _rows(),
              frozenCells: const CoreFrozenTableData(
                frozenColumns: [CoreTableRef(0)],
              ),
              tableStyle: const CoreTableStyle(
                frozenCellBackgroundColor: CoreColor(0xFFAA00AA),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final container = tester.widget<material.Container>(
          find
              .ancestor(
                of: find.text('Cell'),
                matching: find.byType(material.Container),
              )
              .first,
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, equals(overrideColor));
      },
    );

    testWidgets(
      'a cell outside the frozen range does not receive the frozen tint',
      (tester) async {
        const overrideColor = Color(0xFFAA00AA);
        await tester.pumpWidget(
          _buildApp(
            Table(
              rows: _rows(),
              // No row/column is frozen — the override must not apply.
              tableStyle: const CoreTableStyle(
                frozenCellBackgroundColor: CoreColor(0xFFAA00AA),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final container = tester.widget<material.Container>(
          find
              .ancestor(
                of: find.text('Cell'),
                matching: find.byType(material.Container),
              )
              .first,
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, isNot(equals(overrideColor)));
      },
    );

    testWidgets(
      'exposes a table > row > columnheader/cell semantics tree',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_buildApp(Table(rows: _rows())));
        final _ = await tester.pumpAndSettle();

        final tableNode = tester.getSemantics(find.byType(TableLayoutWidget));
        expect(tableNode.role, SemanticsRole.table);

        final rowNodes = <SemanticsNode>[];
        tableNode.visitChildren((child) {
          rowNodes.add(child);
          return true;
        });
        expect(rowNodes, hasLength(2));
        expect(rowNodes.every((row) => row.role == .row), isTrue);

        final headerRowCells = <SemanticsNode>[];
        rowNodes[0].visitChildren((child) {
          headerRowCells.add(child);
          return true;
        });
        expect(headerRowCells, hasLength(1));
        expect(headerRowCells.single.role, SemanticsRole.columnHeader);

        final bodyRowCells = <SemanticsNode>[];
        rowNodes[1].visitChildren((child) {
          bodyRowCells.add(child);
          return true;
        });
        expect(bodyRowCells, hasLength(1));
        expect(bodyRowCells.single.role, SemanticsRole.cell);

        handle.dispose();
      },
    );
  });

  group('Table outer box and cell metrics', () {
    // The nearest DecoratedBox above the layout is the outer box; the cells'
    // own boxes sit below it.
    BoxDecoration outerBox(WidgetTester tester, Type layout) {
      final box = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byType(layout),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return box.decoration as BoxDecoration;
    }

    EdgeInsets outerInset(WidgetTester tester, Type layout) {
      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.byType(layout),
              matching: find.byType(Padding),
            )
            .first,
      );
      return padding.padding.resolve(TextDirection.ltr);
    }

    testWidgets('a default Table paints no outer box', (tester) async {
      await tester.pumpWidget(_buildApp(Table(rows: _rows())));
      await tester.pumpAndSettle();

      expect(outerBox(tester, TableLayoutWidget).border, isNull);
      expect(outerInset(tester, TableLayoutWidget), EdgeInsets.zero);
    });

    testWidgets('outerBorderWidth draws the box in the separator colour', (
      tester,
    ) async {
      late ResolvedTable resolved;
      const style = CoreTableStyle(outerBorderWidth: 1);
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              resolved = resolveTable(context, tableStyle: style);
              return Table(rows: _rows(), tableStyle: style);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final border = outerBox(tester, TableLayoutWidget).border! as Border;
      expect(border.top.width, 1);
      expect(border.top.color, resolved.borderColor);
      expect(outerInset(tester, TableLayoutWidget), const EdgeInsets.all(1));
    });

    testWidgets('the row separators read borderWidth, not outerBorderWidth', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Table(
            rows: [..._rows(), ..._rows().skip(1)],
            tableStyle: const CoreTableStyle(borderWidth: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(outerBox(tester, TableLayoutWidget).border, isNull);
      final headerCell = tester.widget<material.Container>(
        find
            .ancestor(
              of: find.text('Header'),
              matching: find.byType(material.Container),
            )
            .first,
      );
      final decoration = headerCell.decoration! as BoxDecoration;
      expect((decoration.border! as Border).bottom.width, 3);
    });

    testWidgets('a default ResizableTable paints no outer box', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          ResizableTable(
            rows: _rows(),
            controller: ResizableTableController(
              defaultColumnWidth: 100,
              defaultRowHeight: 40,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(outerBox(tester, TableLayoutWidget).border, isNull);
      expect(outerInset(tester, TableLayoutWidget), EdgeInsets.zero);
    });

    testWidgets('ResizableTable draws the box when outerBorderWidth is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          ResizableTable(
            rows: _rows(),
            controller: ResizableTableController(
              defaultColumnWidth: 100,
              defaultRowHeight: 40,
            ),
            tableStyle: const CoreTableStyle(outerBorderWidth: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final border = outerBox(tester, TableLayoutWidget).border! as Border;
      expect(border.top.width, 2);
      expect(outerInset(tester, TableLayoutWidget), const EdgeInsets.all(2));
    });

    testWidgets('header text is 13 / 500 and body text is 14 / 500', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(Table(rows: _rows())));
      await tester.pumpAndSettle();

      TextStyle styleOf(String text) => tester
          .widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text(text),
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          )
          .style;

      expect(styleOf('Header').fontSize, 13);
      expect(styleOf('Header').fontWeight, FontWeight.w500);
      expect(styleOf('Cell').fontSize, 14);
      expect(styleOf('Cell').fontWeight, FontWeight.w500);
    });

    testWidgets(
      'a header cell is 38.2 tall and a body cell 43.6, up to the whole pixel '
      'the grid track rounds to',
      (tester) async {
        await tester.pumpWidget(_buildApp(Table(rows: _rows())));
        await tester.pumpAndSettle();

        double cellHeight(String text) => tester
            .getSize(
              find
                  .ancestor(
                    of: find.text(text),
                    matching: find.byType(material.Container),
                  )
                  .first,
            )
            .height;

        // 10 + 13 * 1.4 + 10 and 12 + 14 * 1.4 + 12; the grid track rounds
        // the intrinsic extent up to a whole pixel.
        expect(cellHeight('Header'), inInclusiveRange(38.2, 39));
        expect(cellHeight('Cell'), inInclusiveRange(43.6, 44));
      },
    );

    testWidgets('the header foreground chain ends at the default ink', (
      tester,
    ) async {
      late ResolvedTable plain;
      late ResolvedTable flat;
      late ResolvedTable slot;
      late Color expectedDefault;
      const flatColor = CoreColor(0xFF112233);
      const slotColor = CoreColor(0xFF445566);
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              plain = resolveTable(context);
              flat = resolveTable(
                context,
                tableStyle: const CoreTableStyle(foregroundColor: flatColor),
              );
              slot = resolveTable(
                context,
                tableStyle: const CoreTableStyle(
                  foregroundColor: flatColor,
                  headerTextStyle: CoreTextStyle(color: slotColor),
                ),
              );
              expectedDefault = Theme.of(context).colorScheme
                  .resolve(CoreTableStyle.defaultHeaderTextStyle.color!)
                  .toValue();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(plain.headerForegroundColor, expectedDefault);
      expect(flat.headerForegroundColor, const Color(0xFF112233));
      expect(slot.headerForegroundColor, const Color(0xFF445566));
      expect(
        plain.headerDisabledForegroundColor,
        plain.cellDisabledForegroundColor,
      );
    });

    testWidgets('cells pad 4 on each side', (tester) async {
      await tester.pumpWidget(_buildApp(Table(rows: _rows())));
      await tester.pumpAndSettle();

      EdgeInsets padding(String text) =>
          tester
                  .widget<material.Container>(
                    find
                        .ancestor(
                          of: find.text(text),
                          matching: find.byType(material.Container),
                        )
                        .first,
                  )
                  .padding!
              as EdgeInsets;

      expect(
        padding('Header'),
        const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      );
      expect(
        padding('Cell'),
        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      );
    });
  });

  group('Table colour slots, read back in each mode', () {
    const semantic = CouiSemanticColors.from(CouiColorPresets.source);
    final modes = <String, CoreColorScheme>{
      'light': semantic.light,
      'dark': semantic.dark,
      'high-contrast light': semantic.highContrastLight,
      'high-contrast dark': semantic.highContrastDark,
    };

    Future<(ThemeData, ResolvedTable)> resolveIn(
      WidgetTester tester,
      CoreColorScheme scheme,
      CoreBrightness brightness, {
      CoreTableStyle? tableStyle,
    }) async {
      late ThemeData theme;
      late ResolvedTable resolved;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData(colorScheme: scheme.resolved(brightness)),
          home: Builder(
            builder: (context) {
              theme = Theme.of(context);
              resolved = resolveTable(context, tableStyle: tableStyle);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      return (theme, resolved);
    }

    for (final MapEntry(key: name, value: scheme) in modes.entries) {
      final brightness = name.contains('dark')
          ? CoreBrightness.dark
          : CoreBrightness.light;

      testWidgets('$name: hairline separators, clear header, wash and fill', (
        tester,
      ) async {
        final (theme, resolved) = await resolveIn(tester, scheme, brightness);
        Color slot(CoreColor c) => theme.colorScheme.resolve(c).toValue();

        expect(
          resolved.borderColor,
          slot(const CoreColor.token(CoreColors.outlineVariant)),
        );
        expect(resolved.headerBackgroundColor.a, 0);
        expect(
          resolved.footerBackgroundColor,
          slot(const CoreColor.token(CoreColors.surfaceContainer)),
        );
        expect(
          resolved.headerForegroundColor,
          slot(const CoreColor.token(CoreColors.onSurfaceSubtle)),
        );
        expect(
          resolved.rowHoverColor,
          slot(
            const CoreColor.token(
              CoreColors.onSurface,
              opacity: CoreOpacity.hover,
            ),
          ),
        );
        final selected = slot(
          const CoreColor.token(CoreColors.surfaceContainerHigh),
        );
        expect(resolved.rowSelectedColor, selected);
        expect(resolved.rowSelectedColor.a, 1);
      });

      testWidgets('$name: a frozen clear header falls to the frozen base', (
        tester,
      ) async {
        final (theme, resolved) = await resolveIn(tester, scheme, brightness);
        final surface = theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.surface))
            .toValue();

        expect(resolved.headerBackgroundColor.a, 0);
        expect(resolved.frozenHeaderBackgroundColor, surface);
        expect(resolved.frozenHeaderBackgroundColor.a, 1);
      });
    }

    testWidgets('a header with its own fill keeps it when frozen', (
      tester,
    ) async {
      const fill = CoreColor(0xFF123456);
      final (_, resolved) = await resolveIn(
        tester,
        semantic.light,
        CoreBrightness.light,
        tableStyle: const CoreTableStyle(headerBackgroundColor: fill),
      );

      expect(resolved.headerBackgroundColor, const Color(0xFF123456));
      expect(resolved.frozenHeaderBackgroundColor, const Color(0xFF123456));
    });

    testWidgets('a frozen header cell paints the frozen base, not clear', (
      tester,
    ) async {
      const frozen = Color(0xFFAA00AA);
      await tester.pumpWidget(
        _buildApp(
          Table(
            rows: _rows(),
            frozenCells: const CoreFrozenTableData(
              frozenRows: [CoreTableRef(0)],
            ),
            tableStyle: const CoreTableStyle(
              frozenCellBackgroundColor: CoreColor(0xFFAA00AA),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      BoxDecoration decorationOf(String text) =>
          tester
                  .widget<material.Container>(
                    find
                        .ancestor(
                          of: find.text(text),
                          matching: find.byType(material.Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;

      expect(decorationOf('Header').color, frozen);
      // The body row is not frozen: it keeps painting nothing of its own.
      expect(decorationOf('Cell').color, isNot(frozen));
    });

    testWidgets('an unfrozen header cell paints nothing', (tester) async {
      await tester.pumpWidget(_buildApp(Table(rows: _rows())));
      await tester.pumpAndSettle();

      final header =
          tester
                  .widget<material.Container>(
                    find
                        .ancestor(
                          of: find.text('Header'),
                          matching: find.byType(material.Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(header.color!.a, 0);
    });
  });
}
