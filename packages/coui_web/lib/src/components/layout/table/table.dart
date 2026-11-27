import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/layout/table/table_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified table component for Web.
///
/// Renders a CSS Grid of [CoreTableRowData] / [CoreTableCellData] with
/// [CoreTableSize] column/row sizing. Supports rowSpan / columnSpan,
/// hover and selection states via CSS, and optional frozen cells.
///
/// surface:behind — whatever the table lands on. It paints no fill of its
/// own by default, so a parent's surface — or the page itself — shows
/// through until a caller opts one in via [tableStyle], and only then does
/// the grid carry the surface marker. The same answer the Flutter twin
/// declares.
///
/// surface:content — a face in the content layer alongside cards and body
/// panels. A sticky header rides inside the table's own scroll container
/// rather than floating over unrelated page content, so it does not earn
/// the functional role.
class Table extends UiStatefulComponent
    implements CoreTableContract<Component> {
  /// Creates a [Table].
  const Table({
    required this.rows,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.defaultColumnWidth = const CoreFlexTableSize(),
    this.defaultRowHeight = const CoreIntrinsicTableSize(),
    this.columnWidths,
    this.rowHeights,
    this.frozenCells,
    this.horizontalOffset,
    this.verticalOffset,
    this.theme,
    this.clipBehavior = CoreClipMode.hardEdge,
    this.tableStyle,
  });

  @override
  final List<CoreTableRowData<Component>> rows;

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

  /// Widget-level theme override.
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
    UiMouseEventHandler? onClick,
    List<CoreTableRowData<Component>>? rows,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
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
      onClick: onClick ?? this.onClick,
      rows: rows ?? this.rows,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
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
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.addRole('table');
  }

  @override
  State<Table> createState() => _TableState();
}

class _TableState extends State<Table> {
  int? _hoveredRow;
  int? _hoveredColumn;

  _TableShape _flatten(List<CoreTableRowData<Component>> rows) {
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
  Component build(BuildContext context) {
    // Web flattens every clip mode except `none` to `overflow: hidden`.
    final clip = component.clipBehavior != .none;

    final shape = _flatten(component.rows);

    final columnTracks = [
      for (var i = 0; i < shape.columns; i++)
        coreTableSizeToCssTrack(
          component.columnWidths?[i] ?? component.defaultColumnWidth,
        ),
    ];
    final rowTracks = [
      for (var i = 0; i < shape.rows; i++)
        coreTableSizeToCssTrack(
          component.rowHeights?[i] ?? component.defaultRowHeight,
        ),
    ];

    // Precompute pixel offsets for frozen columns/rows so sticky cells know
    // where to anchor within the scroll container. Only fixed-size tracks
    // contribute meaningful offsets; flex/intrinsic tracks collapse to 0
    // because we don't know their pixel width at build time.
    double? trackToPx(CoreTableSize size) =>
        size is CoreFixedTableSize ? size.value : null;
    final columnPxOffsets = <int, double>{};
    final rowPxOffsets = <int, double>{};
    if (component.frozenCells != null) {
      var acc = 0.0;
      for (var i = 0; i < shape.columns; i++) {
        final frozen = component.frozenCells!.testColumn(i, 1);
        if (frozen) columnPxOffsets[i] = acc;
        final w =
            trackToPx(
              component.columnWidths?[i] ?? component.defaultColumnWidth,
            ) ??
            0.0;
        acc += w;
      }
      acc = 0.0;
      for (var i = 0; i < shape.rows; i++) {
        final frozen = component.frozenCells!.testRow(i, 1);
        if (frozen) rowPxOffsets[i] = acc;
        final h =
            trackToPx(
              component.rowHeights?[i] ?? component.defaultRowHeight,
            ) ??
            0.0;
        acc += h;
      }
    }

    // Flatten cell descriptors in the same order the widget emits them.
    final descriptors = <CoreTableCellDescriptor>[];
    final cellWidgets = <Component>[];
    final cellEventsList = <Map<String, void Function(Object)>>[];
    // Cell count per row — lets the second (DOM-building) pass below slice
    // the flat descriptor/widget lists back into per-row groups without
    // re-deriving row boundaries.
    final rowCellCounts = <int>[];
    // Body-row parity counter for zebra-stripe (`rowAlternateBackgroundColor`).
    // Counts body rows only so header / footer don't perturb the stripe.
    var bodyRowCursor = 0;
    for (var r = 0; r < component.rows.length; r++) {
      final row = component.rows[r];
      final bodyRowEven = row.kind == .body && bodyRowCursor.isEven;
      if (row.kind == .body) bodyRowCursor++;
      var columnCursor = 0;
      for (final cell in row.cells) {
        final columnIndex = columnCursor;
        final rowIndex = r;
        final isHovered =
            cell.enabled &&
            ((cell.rowHover && _hoveredRow == rowIndex) ||
                (cell.columnHover && _hoveredColumn == columnIndex));
        final selected = row.selected || cell.selected;

        final frozenLeft = columnPxOffsets[columnIndex];
        final frozenTop = rowPxOffsets[rowIndex];
        final isLastRow = rowIndex == component.rows.length - 1;

        descriptors.add((
          rowKind: row.kind,
          selected: selected,
          hovered: isHovered,
          enabled: cell.enabled,
          clickable: cell.onPressed != null,
          isLastRow: isLastRow,
          bodyRowEven: bodyRowEven,
          columnSpan: cell.columnSpan,
          rowSpan: cell.rowSpan,
          frozenLeft: frozenLeft,
          frozenTop: frozenTop,
          positionRelative: false,
        ));
        cellWidgets.add(cell.child);
        cellEventsList.add({
          'mouseenter': (event) {
            if (cell.enabled) {
              setState(() {
                _hoveredRow = rowIndex;
                _hoveredColumn = columnIndex;
              });
            }
          },
          'mouseleave': (event) {
            setState(() {
              _hoveredRow = null;
              _hoveredColumn = null;
            });
          },
          if (cell.onPressed != null && cell.enabled)
            'click': (event) => cell.onPressed!(),
        });
        columnCursor += cell.columnSpan;
      }
      rowCellCounts.add(row.cells.length);
    }

    final resolved = resolveTable(
      context,
      columnTemplate: columnTracks.join(' '),
      rowTemplate: rowTracks.join(' '),
      clipBehavior: clip,
      useRowBackgroundFallback: true,
      cells: descriptors,
      horizontalOffset: component.horizontalOffset,
      verticalOffset: component.verticalOffset,
      widgetTheme: component.theme,
      tableStyle: component.tableStyle,
    );

    // Group flat cells back into `role="row"` wrappers so screen readers
    // get a real table/row/cell tree instead of a flat list of `<div>`s —
    // `display: contents` keeps the wrapper out of CSS Grid track
    // placement (its children lay out exactly as if they were direct
    // grid children) while still grouping them in the accessibility tree.
    final rowElements = <Component>[];
    var cellCursor = 0;
    for (var r = 0; r < component.rows.length; r++) {
      final row = component.rows[r];
      final rowCellCount = rowCellCounts[r];
      final rowChildren = <Component>[];
      for (var i = 0; i < rowCellCount; i++) {
        final flatIndex = cellCursor + i;
        final descriptor = descriptors[flatIndex];
        final cellAttributes = {
          'role': row.kind == .header ? 'columnheader' : 'cell',
          if (descriptor.columnSpan > 1)
            'aria-colspan': '${descriptor.columnSpan}',
          if (descriptor.rowSpan > 1) 'aria-rowspan': '${descriptor.rowSpan}',
        };
        rowChildren.add(
          div(
            [cellWidgets[flatIndex]],
            classes: resolved.cells[flatIndex].className,
            styles: resolved.cells[flatIndex].inlineStyles,
            attributes: cellAttributes,
            events: cellEventsList[flatIndex],
          ),
        );
      }
      cellCursor += rowCellCount;
      rowElements.add(
        div(
          rowChildren,
          styles: kTableRowGroupStyles,
          attributes: const {'role': 'row'},
        ),
      );
    }

    return div(
      rowElements,
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}

class _TableShape {
  const _TableShape({required this.rows, required this.columns});
  final int rows;
  final int columns;
}

/// Chain sugar mirroring the Flutter `Table.withStyle` extension —
/// merges a [CoreTableStyle] patch into [Table.tableStyle] via the
/// existing [Table.copyWith].
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
  /// Sets the border color.
  Table borderColor(CoreColor value) =>
      withStyle(CoreTableStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  Table borderWidth(double value) =>
      withStyle(CoreTableStyle(borderWidth: value));

  /// Sets the content foreground color.
  Table foregroundColor(CoreColor value) =>
      withStyle(CoreTableStyle(foregroundColor: value));

  /// Sets the background paint and preserves the other style fields.
  Table backgroundColor(CoreColor value) =>
      withStyle(CoreTableStyle(backgroundColor: value));

  /// Returns a copy of this [Table] with [patch] merged into
  /// [tableStyle] (patch fields win on conflict).
  Table withStyle(CoreTableStyle patch) =>
      copyWith(tableStyle: (tableStyle ?? const CoreTableStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  Table get radius0 => withStyle(
    const CoreTableStyle(borderRadius: CoreBorderRadius.zero),
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
