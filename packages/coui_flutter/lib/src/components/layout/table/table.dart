import 'package:coui_flutter/coui_flutter.dart';

/// Unified table component for Flutter.
///
/// Renders a grid of cells from [rows] with flexible column/row sizing,
/// optional row/column span, hover/selection states, and optional frozen
/// cells. Columns and rows accept [CoreTableSize] (`CoreFlexTableSize`,
/// `CoreFixedTableSize`, `CoreIntrinsicTableSize`).
///
/// Example:
/// ```dart
/// Table(
///   rows: [
///     CoreTableRowData.header(cells: [
///       CoreTableCellData(child: Text('Name')),
///       CoreTableCellData(child: Text('Email')),
///     ]),
///     CoreTableRowData(cells: [
///       CoreTableCellData(child: Text('Ada')),
///       CoreTableCellData(child: Text('ada@example.com')),
///     ]),
///   ],
/// )
/// ```
///
/// surface:behind — whatever the table lands on. It paints no fill of its
/// own by default (see the comment on its `DecoratedBox` below), so a
/// parent's surface — or the page itself — shows through until a caller
/// opts one in via [tableStyle].
///
/// surface:content — a face in the content layer alongside cards and body
/// panels. A sticky header rides inside the table's own scroll container
/// rather than floating over unrelated page content, so it does not earn
/// the functional role.
class Table extends StatefulWidget implements CoreTableContract<Widget> {
  /// Creates a [Table].
  const Table({
    required this.rows,
    this.defaultColumnWidth = const CoreFlexTableSize(),
    this.defaultRowHeight = const CoreIntrinsicTableSize(),
    this.columnWidths,
    this.rowHeights,
    this.frozenCells,
    this.horizontalOffset,
    this.verticalOffset,
    this.theme,
    this.clipBehavior = CoreClipMode.hardEdge,
    super.key,
    this.tableStyle,
  });

  @override
  final List<CoreTableRowData<Widget>> rows;

  @override
  final CoreTableSize defaultColumnWidth;

  @override
  final CoreTableSize defaultRowHeight;

  @override
  final Map<int, CoreTableSize>? columnWidths;

  @override
  final Map<int, CoreTableSize>? rowHeights;

  @override
  final CoreFrozenTableData? frozenCells;

  @override
  final double? horizontalOffset;

  @override
  final double? verticalOffset;

  /// Widget-level theme override (takes precedence over CoreComponentTheme).
  final CoreTableTheme? theme;

  @override
  final CoreClipMode clipBehavior;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `headerTextStyle` / `cellTextStyle` slots. See [CoreTableStyle]
  /// for the merge chain.
  @override
  final CoreTableStyle? tableStyle;

  /// Returns a copy of this [Table] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Table copyWith({
    Key? key,
    List<CoreTableRowData<Widget>>? rows,
    CoreTableSize? defaultColumnWidth,
    CoreTableSize? defaultRowHeight,
    Map<int, CoreTableSize>? columnWidths,
    Map<int, CoreTableSize>? rowHeights,
    CoreFrozenTableData? frozenCells,
    double? horizontalOffset,
    double? verticalOffset,
    CoreTableTheme? theme,
    CoreClipMode? clipBehavior,
    CoreTableStyle? tableStyle,
  }) {
    return Table(
      key: key ?? this.key,
      rows: rows ?? this.rows,
      defaultColumnWidth: defaultColumnWidth ?? this.defaultColumnWidth,
      defaultRowHeight: defaultRowHeight ?? this.defaultRowHeight,
      columnWidths: columnWidths ?? this.columnWidths,
      rowHeights: rowHeights ?? this.rowHeights,
      frozenCells: frozenCells ?? this.frozenCells,
      horizontalOffset: horizontalOffset ?? this.horizontalOffset,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      theme: theme ?? this.theme,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      tableStyle: tableStyle ?? this.tableStyle,
    );
  }

  @override
  State<Table> createState() => _TableState();
}

class _TableState extends State<Table> {
  final _hoveredCellNotifier = ValueNotifier<_HoveredCell?>(null);

  _TableShape _flatten(List<CoreTableRowData<Widget>> rows) {
    var maxCol = 0;
    for (final row in rows) {
      var c = 0;
      for (final cell in row.cells) {
        c += cell.columnSpan;
      }
      if (c > maxCol) maxCol = c;
    }
    return _TableShape(rows: rows.length, columns: maxCol);
  }

  @override
  void dispose() {
    _hoveredCellNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTable(
      context,
      widgetTheme: widget.theme,
      tableStyle: widget.tableStyle,
    );

    final size = _flatten(widget.rows);
    final viewportSize =
        resolved.viewportWidth != null && resolved.viewportHeight != null
        ? Size(resolved.viewportWidth!, resolved.viewportHeight!)
        : null;

    final children = <Widget>[];
    // Body-row parity counter for zebra-stripe
    // (`rowAlternateBackgroundColor`) — counts body rows only so header /
    // footer don't perturb the stripe.
    var bodyRowCursor = 0;
    for (var r = 0; r < widget.rows.length; r++) {
      final row = widget.rows[r];
      final bodyRowEven = row.kind == .body && bodyRowCursor.isEven;
      if (row.kind == .body) bodyRowCursor++;
      var columnCursor = 0;
      for (var ci = 0; ci < row.cells.length; ci++) {
        final cell = row.cells[ci];
        // Mirrors the Web resolver's `hasFrozenLeft || hasFrozenTop`
        // (`d.frozenLeft != null || d.frozenTop != null`) 1:1 — a cell is
        // frozen when either its row or its column is pinned.
        final isFrozen =
            (widget.frozenCells?.testColumn(columnCursor, cell.columnSpan) ??
                false) ||
            (widget.frozenCells?.testRow(r, cell.rowSpan) ?? false);
        children.add(
          TableLayoutCell(
            column: columnCursor,
            row: r,
            columnSpan: cell.columnSpan,
            rowSpan: cell.rowSpan,
            // `container: true` forces a distinct semantics-tree boundary
            // per cell (regardless of what `cell.child` itself does),
            // which `RenderTableLayoutBox.assembleSemanticsNode` then
            // groups by row — see table_layout_render.dart.
            child: Semantics(
              container: true,
              role: row.kind == .header ? .columnHeader : .cell,
              child: _TableCell(
                row: r,
                column: columnCursor,
                cell: cell,
                rowKind: row.kind,
                rowSelected: row.selected,
                bodyRowEven: bodyRowEven,
                isFrozen: isFrozen,
                isLastRow: r == widget.rows.length - 1,
                style: resolved,
                hoveredCellNotifier: _hoveredCellNotifier,
              ),
            ),
          ),
        );
        columnCursor += cell.columnSpan;
      }
    }

    final clip = widget.clipBehavior.toValue();
    final layout = TableLayoutWidget(
      width: (index) =>
          widget.columnWidths?[index] ?? widget.defaultColumnWidth,
      height: (index) => widget.rowHeights?[index] ?? widget.defaultRowHeight,
      clipBehavior: clip,
      frozenColumn: widget.frozenCells?.testColumn,
      frozenRow: widget.frozenCells?.testRow,
      horizontalOffset: widget.horizontalOffset,
      verticalOffset: widget.verticalOffset,
      viewportSize: viewportSize,
      children: children,
    );

    // Inner clip radius insets every corner by the outer border width,
    // preserving any per-corner asymmetry (no single-corner reach-in).
    final innerRadius =
        resolved.borderRadius - .circular(resolved.outerBorderWidth);

    // Painted outside the box rather than behind it. A table states no
    // fill of its own on purpose — that is what lets it read on whatever
    // surface it lands on — so `BoxDecoration.boxShadow` would fill a
    // rounded rect under it with nothing painting over it, and a style
    // whose cast is opaque and hard-edged turns the whole body into a
    // solid block. CSS clips an outer shadow to outside the border box,
    // so the Web twin never did.
    final decoratedBody = DecoratedBox(
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        // `Border.all(width: 0)` paints a hairline, so a table with no
        // outer box states no border at all.
        border: resolved.outerBorderWidth > 0
            ? Border.all(
                color: resolved.borderColor,
                width: resolved.outerBorderWidth,
              )
            : null,
        borderRadius: resolved.borderRadius,
      ),
      child: Padding(
        padding: .all(resolved.outerBorderWidth),
        child: ClipRRect(
          borderRadius: innerRadius,
          clipBehavior: clip,
          child: SizedBox(
            width: size.columns > 0 ? null : 0,
            height: size.rows > 0 ? null : 0,
            child: layout,
          ),
        ),
      ),
    );

    // Wrapped in the same backdrop-pass widget every other surface reaches
    // through — only instantiated once the table actually paints a fill
    // (`resolveTable` gates `surfaceBlur`/`surfaceSheen` on it), so a
    // table with no background never pays for a pass it draws nothing
    // over.
    final blur = resolved.surfaceBlur;
    final sheen = resolved.surfaceSheen;
    final body = (blur == null || blur <= 0) && sheen == null
        ? decoratedBody
        : SurfaceBlur(
            borderRadius: resolved.borderRadius,
            surfaceBlur: blur,
            surfaceSaturation: resolved.surfaceSaturation,
            surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
            surfaceSheen: sheen,
            refraction: Theme.of(context).surfaceRefraction,
            child: decoratedBody,
          );

    return InjectedCast(
      shadows: resolved.boxShadow,
      borderRadius: resolved.borderRadius,
      child: body,
    );
  }
}

class _TableShape {
  const _TableShape({required this.rows, required this.columns});
  final int rows;
  final int columns;
}

/// Single rendered cell with hover/selection state tracking.
class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.row,
    required this.column,
    required this.cell,
    required this.rowKind,
    required this.rowSelected,
    required this.bodyRowEven,
    required this.isFrozen,
    required this.isLastRow,
    required this.style,
    required this.hoveredCellNotifier,
  });

  final int row;
  final int column;
  final CoreTableCellData<Widget> cell;
  final CoreTableRowKind rowKind;
  final bool rowSelected;
  final bool bodyRowEven;
  final bool isFrozen;
  final bool isLastRow;
  final ResolvedTable style;
  final ValueNotifier<_HoveredCell?> hoveredCellNotifier;

  @override
  Widget build(BuildContext context) {
    final currentCell = _HoveredCell(
      column: column,
      row: row,
      columnSpan: cell.columnSpan,
      rowSpan: cell.rowSpan,
    );

    final selected = rowSelected || cell.selected;

    // Body rows fall back to the table background colour (opaque by default
    // via `ThemeData.fromCore`) instead of transparent so frozen cells can
    // cover scrolling content without bleed-through. Callers can still force
    // transparency via `CoreTableTheme.backgroundColor = transparent`.
    final rowBaseColor = switch (rowKind) {
      .header =>
        isFrozen
            ? style.frozenHeaderBackgroundColor
            : style.headerBackgroundColor,
      .footer => style.footerBackgroundColor,
      // Even body rows pick up the zebra-stripe override (when set) as
      // their base background; else a frozen cell picks up the explicit
      // frozen tint (when set); odd/unfrozen rows (and all rows when no
      // override is set) fall back to the explicit row / table
      // background or transparent. Hover / selection still layer on top
      // below. Mirrors the Web resolver's `bgOverride` fallback chain
      // 1:1 (zebra → frozen → row/table background).
      .body =>
        (bodyRowEven ? style.rowAlternateBackgroundColor : null) ??
            (isFrozen ? style.frozenCellBackgroundColor : null) ??
            style.rowBackgroundColor ??
            style.backgroundColor ??
            Colors.transparent,
    };

    return MouseRegion(
      onEnter: (_) {
        if (cell.enabled) hoveredCellNotifier.value = currentCell;
      },
      onExit: (_) {
        if (hoveredCellNotifier.value == currentCell) {
          hoveredCellNotifier.value = null;
        }
      },
      cursor: cell.onPressed != null && cell.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: ValueListenableBuilder<_HoveredCell?>(
        valueListenable: hoveredCellNotifier,
        builder: (context, hovered, _) {
          final isHovered =
              hovered != null &&
              cell.enabled &&
              hovered.intersects(
                currentCell,
                columnHover: cell.columnHover,
                rowHover: cell.rowHover,
              );

          final background = selected
              ? style.rowSelectedColor
              : isHovered
              ? style.rowHoverColor
              : rowBaseColor;

          final border = isLastRow
              ? null
              : Border(
                  bottom: .new(
                    color: style.borderColor,
                    width: style.borderWidth,
                  ),
                );

          // Paint-ready cell text style — header / body branch already
          // folds the `labelMedium` (header) / `labelLarge` (body) typography
          // role and any per-instance slot override in the resolver. The
          // widget only binds the state-resolved foreground colour; it is
          // render-only (no typography or `CoreColor → Color` resolution
          // here).
          final textStyle = rowKind == .header
              ? style.headerTextStyle
              : style.cellTextStyle;

          // Per-cell padding branch — header vs body / footer.
          final effectivePadding = rowKind == .header
              ? style.headerCellPadding
              : style.bodyCellPadding;

          // Row min-height — header reads `headerHeight`, body / footer
          // read `rowHeight`. `null` lets the grid track sizing drive the
          // natural height (no constraint applied).
          final minRowHeight = rowKind == .header
              ? style.headerHeight
              : style.rowHeight;

          Widget content = Container(
            alignment: Alignment.centerLeft,
            padding: effectivePadding,
            decoration: BoxDecoration(color: background, border: border),
            constraints: minRowHeight != null
                ? BoxConstraints(minHeight: minRowHeight)
                : null,
            child: DefaultTextStyle.merge(
              style: textStyle.copyWith(
                color: rowKind == .header
                    ? (cell.enabled
                          ? style.headerForegroundColor
                          : style.headerDisabledForegroundColor)
                    : (cell.enabled
                          ? style.cellForegroundColor
                          : style.cellDisabledForegroundColor),
              ),
              child: cell.child,
            ),
          );

          if (cell.onPressed != null && cell.enabled) {
            content = GestureDetector(
              onTap: cell.onPressed,
              behavior: .opaque,
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }
}

class _HoveredCell {
  const _HoveredCell({
    required this.column,
    required this.row,
    required this.columnSpan,
    required this.rowSpan,
  });

  final int column;
  final int row;
  final int columnSpan;
  final int rowSpan;

  bool intersects(
    _HoveredCell other, {
    required bool columnHover,
    required bool rowHover,
  }) {
    if (rowHover && _overlapsRow(other)) return true;
    if (columnHover && _overlapsColumn(other)) return true;
    return _equals(other);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _HoveredCell && _equals(other);

  bool _overlapsRow(_HoveredCell other) =>
      row < other.row + other.rowSpan && other.row < row + rowSpan;

  bool _overlapsColumn(_HoveredCell other) =>
      column < other.column + other.columnSpan &&
      other.column < column + columnSpan;

  bool _equals(_HoveredCell other) =>
      column == other.column &&
      row == other.row &&
      columnSpan == other.columnSpan &&
      rowSpan == other.rowSpan;

  @override
  int get hashCode => Object.hash(column, row, columnSpan, rowSpan);
}

/// Chain sugar for merging a [CoreTableStyle] patch into
/// [Table.tableStyle] without hand-reconstructing every field. Mirrors
/// the Web `Table.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTableStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreTableStyle.borderRadius] and `.primary` sets
/// [CoreTableStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Table(rows: rows).radius4.surface
/// ```
extension TableStyleChain on Table {
  /// Sets the background paint and preserves the other style fields.
  Table backgroundColor(CoreColor value) =>
      withStyle(CoreTableStyle(backgroundColor: value));

  /// Returns a copy of this [Table] with [patch] merged into
  /// [tableStyle] (patch fields win on conflict).
  Table withStyle(CoreTableStyle patch) =>
      copyWith(tableStyle: (tableStyle ?? const CoreTableStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Table get radius0 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Table get radius2 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Table get radius4 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Table get radius6 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Table get radius8 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Table get radius10 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Table get radius12 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Table get radius14 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Table get radius16 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Table get radius20 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Table get radius24 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Table get radius28 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Table get radius32 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Table get radius36 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Table get radius40 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Table get radius48 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Table get radius56 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Table get radius64 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Table get radius9999 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Table get primary => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Table get secondary => withStyle(
    const CoreTableStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Table get tertiary => withStyle(
    const CoreTableStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Table get surface => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Table get surfaceContainer => withStyle(
    const CoreTableStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Table get error => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Table get success => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Table get warning => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Table get info => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Table get outline => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Table get transparent =>
      withStyle(const CoreTableStyle(backgroundColor: .transparent));
}
