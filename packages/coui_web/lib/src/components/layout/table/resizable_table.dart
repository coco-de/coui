import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/layout/table/resizable_table_controller.dart';
import 'package:coui_web/src/components/layout/table/table_style.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified resizable table for Web.
///
/// Extends [Table][1] semantics with drag-based column/row resizing via a
/// [ResizableTableController]. Drag handles are rendered as absolutely
/// positioned overlays on the right/bottom edge of each cell.
///
/// [1]: co_table.dart
///
/// surface:content — same face as [Table][1], which shares its resolver.
class ResizableTable extends UiStatefulComponent
    implements CoreResizableTableContract<Component> {
  /// Creates a [ResizableTable].
  const ResizableTable({
    required this.rows,
    required this.controller,
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
    this.columnResizeMode = CoreTableCellResizeMode.reallocate,
    this.rowResizeMode = CoreTableCellResizeMode.expand,
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
  final ResizableTableController controller;

  @override
  final CoreTableCellResizeMode columnResizeMode;

  @override
  final CoreTableCellResizeMode rowResizeMode;

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

  /// Returns a copy of this [ResizableTable] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  ResizableTable copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    List<CoreTableRowData<Component>>? rows,
    ResizableTableController? controller,
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
    CoreTableCellResizeMode? columnResizeMode,
    CoreTableCellResizeMode? rowResizeMode,
    CoreFrozenTableData? frozenCells,
    double? horizontalOffset,
    double? verticalOffset,
    CoreTableTheme? theme,
    CoreClipMode? clipBehavior,
    CoreTableStyle? tableStyle,
  }) {
    return ResizableTable(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      rows: rows ?? this.rows,
      controller: controller ?? this.controller,
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
      columnResizeMode: columnResizeMode ?? this.columnResizeMode,
      rowResizeMode: rowResizeMode ?? this.rowResizeMode,
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
  State<ResizableTable> createState() => _ResizableTableState();
}

/// Per-cell resizer slot — index into the flat resizer descriptors list
/// plus the original column/row target so the widget can wire
/// mouseenter / mouseleave / mousedown to the right axis target.
class _ResizerSlot {
  const _ResizerSlot({
    required this.index,
    required this.vertical,
    required this.target,
  });

  final int index;
  final bool vertical;
  final int target;
}

class _ResizableTableState extends State<ResizableTable> {
  int? _hoveredRow;
  int? _hoveredColumn;
  int? _hoveredResizerColumn;
  int? _hoveredResizerRow;
  int? _draggingColumn;
  int? _draggingRow;
  double _dragOriginX = 0;
  double _dragOriginY = 0;

  @override
  void initState() {
    super.initState();
    component.controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  void _startColumnDrag(int column, double clientX, Object downEvent) {
    final controller = component.controller;
    _draggingColumn = column;
    _dragOriginX = clientX;
    final isExpand = component.columnResizeMode == .expand;
    final minLeft = controller.getColumnMinWidth(column) ?? 0.0;
    final startWidth = controller.getColumnWidth(column);
    final totalColumns = _flatten(component.rows).columns;
    final snapshotSizes = List.generate(
      totalColumns,
      controller.getColumnWidth,
    );
    final snapshotMins = List.generate(
      totalColumns,
      (i) => controller.getColumnMinWidth(i) ?? 0.0,
    );
    final snapshotMaxes = List.generate(
      totalColumns,
      controller.getColumnMaxWidth,
    );
    registerDragListeners(
      onMove: (event) {
        final clientX = _readClientX(event);
        if (clientX == null) return;
        final dx = clientX - _dragOriginX;
        if (isExpand) {
          final next = startWidth + dx;
          if (next < minLeft) return;
          controller..resizeColumn(column, next);
          return;
        }
        final resizer = CoreTrackResizer(
          sizes: snapshotSizes,
          minSizes: snapshotMins,
          maxSizes: snapshotMaxes,
        );
        if (!resizer.dragDivider(column, dx)) return;
        for (var i = 0; i < totalColumns; i++) {
          controller.resizeColumn(i, resizer.sizeAt(i));
        }
      },
      onUp: (_) => setState(() => _draggingColumn = null),
      downEvent: downEvent,
    );
    setState(() {});
  }

  void _startRowDrag(int row, double clientY, Object downEvent) {
    final controller = component.controller;
    _draggingRow = row;
    _dragOriginY = clientY;
    final isExpand = component.rowResizeMode == .expand;
    final minTop = controller.getRowMinHeight(row) ?? 0.0;
    final startHeight = controller.getRowHeight(row);
    final totalRows = _flatten(component.rows).rows;
    final snapshotSizes = List.generate(totalRows, controller.getRowHeight);
    final snapshotMins = List.generate(
      totalRows,
      (i) => controller.getRowMinHeight(i) ?? 0.0,
    );
    final snapshotMaxes = List.generate(totalRows, controller.getRowMaxHeight);
    registerDragListeners(
      onMove: (event) {
        final clientY = _readClientY(event);
        if (clientY == null) return;
        final dy = clientY - _dragOriginY;
        if (isExpand) {
          final next = startHeight + dy;
          if (next < minTop) return;
          controller..resizeRow(row, next);
          return;
        }
        final resizer = CoreTrackResizer(
          sizes: snapshotSizes,
          minSizes: snapshotMins,
          maxSizes: snapshotMaxes,
        );
        if (!resizer.dragDivider(row, dy)) return;
        for (var i = 0; i < totalRows; i++) {
          controller.resizeRow(i, resizer.sizeAt(i));
        }
      },
      onUp: (_) => setState(() => _draggingRow = null),
      downEvent: downEvent,
    );
    setState(() {});
  }

  double? _readClientX(Object event) => mouseClientX(event);

  double? _readClientY(Object event) => mouseClientY(event);

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
  void didUpdateComponent(covariant ResizableTable oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.controller != component.controller) {
      oldComponent.controller.removeListener(_handleControllerChanged);
      component.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    component.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // Web flattens every clip mode except `none` to `overflow: hidden`.
    final clip = component.clipBehavior != .none;

    final shape = _flatten(component.rows);
    final controller = component.controller;

    // Resizable tables use fixed-px tracks for every column and row so that
    // dragging a resizer only affects the adjacent track (expand mode). The
    // table's total size is sum(columns) × sum(rows); callers should size
    // the container accordingly or rely on horizontal scroll.
    final columnTracks = List.generate(
      shape.columns,
      (i) => '${controller.getColumnWidth(i) / kRemDivisor}rem',
    );
    final rowTracks = List.generate(
      shape.rows,
      (i) => '${controller.getRowHeight(i) / kRemDivisor}rem',
    );

    final showColumn = component.columnResizeMode != .none;
    final showRow = component.rowResizeMode != .none;
    final columnExpand = component.columnResizeMode == .expand;
    final rowExpand = component.rowResizeMode == .expand;

    // Pre-flatten cell descriptors + per-cell resizer descriptors in
    // the exact DOM order the widget emits them. `cellResizerSlots[i]`
    // lists every resizer that hangs inside cell `i`.
    final cellDescriptors = <CoreTableCellDescriptor>[];
    final resizerDescriptors = <CoreTableResizerDescriptor>[];
    final cellChildren = <Component>[];
    final cellEvents = <Map<String, void Function(Object)>>[];
    final cellResizerSlots = <List<_ResizerSlot>>[];
    // Cell count per row — lets the DOM-building pass below slice the flat
    // per-cell lists back into per-row `role="row"` groups.
    final rowCellCounts = <int>[];

    // Body-row parity counter for zebra-stripe (`rowAlternateBackgroundColor`).
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
        final columnTarget = columnIndex + cell.columnSpan - 1;
        final rowTarget = rowIndex + cell.rowSpan - 1;
        final isLastRow = rowIndex == component.rows.length - 1;

        cellDescriptors.add((
          rowKind: row.kind,
          selected: selected,
          hovered: isHovered,
          enabled: cell.enabled,
          clickable: cell.onPressed != null,
          isLastRow: isLastRow,
          bodyRowEven: bodyRowEven,
          columnSpan: cell.columnSpan,
          rowSpan: cell.rowSpan,
          frozenLeft: null,
          frozenTop: null,
          positionRelative: true,
        ));

        final canResizeColumn =
            showColumn && (columnExpand || columnTarget < shape.columns - 1);
        final canResizeRow =
            showRow && (rowExpand || rowTarget < shape.rows - 1);

        final slots = <_ResizerSlot>[];
        if (canResizeColumn) {
          resizerDescriptors.add((
            vertical: true,
            hovered: _hoveredResizerColumn == columnTarget,
            dragging: _draggingColumn == columnTarget,
          ));
          slots.add(
            _ResizerSlot(
              index: resizerDescriptors.length - 1,
              vertical: true,
              target: columnTarget,
            ),
          );
        }
        if (canResizeRow) {
          resizerDescriptors.add((
            vertical: false,
            hovered: _hoveredResizerRow == rowTarget,
            dragging: _draggingRow == rowTarget,
          ));
          slots.add(
            _ResizerSlot(
              index: resizerDescriptors.length - 1,
              vertical: false,
              target: rowTarget,
            ),
          );
        }
        cellResizerSlots.add(slots);

        cellChildren.add(cell.child);
        cellEvents.add({
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
      useRowBackgroundFallback: false,
      cells: cellDescriptors,
      disableScrollViewport: true,
      resizers: resizerDescriptors,
      widgetTheme: component.theme,
      tableStyle: component.tableStyle,
    );

    // Reconstruct per-cell DOM (attaching the resizer chrome captured
    // above to the correct target), grouped into `role="row"` wrappers so
    // screen readers get a real table/row/cell tree instead of a flat
    // list of `<div>`s — `display: contents` keeps the wrapper out of CSS
    // Grid track placement (its children lay out exactly as if they were
    // direct grid children) while still grouping them in the
    // accessibility tree.
    final rowElements = <Component>[];
    var cellCursor = 0;
    for (var r = 0; r < component.rows.length; r++) {
      final row = component.rows[r];
      final rowCellCount = rowCellCounts[r];
      final rowChildren = <Component>[];
      for (var j = 0; j < rowCellCount; j++) {
        final i = cellCursor + j;
        final descriptor = cellDescriptors[i];
        final slots = cellResizerSlots[i];
        final cellContent = [cellChildren[i]];
        for (final slot in slots) {
          final resizerChrome = resolved.resizers[slot.index];
          cellContent.add(
            div(
              const [],
              classes: resizerChrome.className,
              styles: resizerChrome.inlineStyles,
              events: {
                'mouseenter': (event) {
                  if (slot.vertical) {
                    setState(() => _hoveredResizerColumn = slot.target);
                  } else {
                    setState(() => _hoveredResizerRow = slot.target);
                  }
                },
                'mouseleave': (event) {
                  if (slot.vertical) {
                    if (_hoveredResizerColumn == slot.target) {
                      setState(() => _hoveredResizerColumn = null);
                    }
                  } else {
                    if (_hoveredResizerRow == slot.target) {
                      setState(() => _hoveredResizerRow = null);
                    }
                  }
                },
                // Trigger on pointerdown because the drag listeners are
                // pointer events — on touch devices the compatibility
                // mousedown fires after the gesture's pointerup and would
                // leak them.
                'pointerdown': (event) {
                  preventDefault(event);
                  if (slot.vertical) {
                    final x = _readClientX(event);
                    if (x != null) _startColumnDrag(slot.target, x, event);
                  } else {
                    final y = _readClientY(event);
                    if (y != null) _startRowDrag(slot.target, y, event);
                  }
                },
              },
            ),
          );
        }

        final cellAttributes = {
          'role': row.kind == .header ? 'columnheader' : 'cell',
          if (descriptor.columnSpan > 1)
            'aria-colspan': '${descriptor.columnSpan}',
          if (descriptor.rowSpan > 1) 'aria-rowspan': '${descriptor.rowSpan}',
        };
        rowChildren.add(
          div(
            cellContent,
            classes: resolved.cells[i].className,
            styles: resolved.cells[i].inlineStyles,
            attributes: cellAttributes,
            events: cellEvents[i],
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

    // No internal scroll wrapper: scrolling is the caller's responsibility
    // (matches shadcn_flutter's ResizableTable). Expand mode just grows the
    // grid; parent layout decides whether to scroll, clip, or fit.
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

/// Chain sugar mirroring the Flutter `ResizableTable.withStyle` extension —
/// merges a [CoreTableStyle] patch into [ResizableTable.tableStyle] via the
/// existing [ResizableTable.copyWith].
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
/// ResizableTable(rows: rows, controller: controller).radius4.surface
/// ```
extension ResizableTableStyleChain on ResizableTable {
  /// Returns a copy of this [ResizableTable] with [patch] merged into
  /// [tableStyle] (patch fields win on conflict).
  ResizableTable withStyle(CoreTableStyle patch) => copyWith(
    tableStyle: (tableStyle ?? const CoreTableStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  ResizableTable get radius0 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  ResizableTable get radius2 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  ResizableTable get radius4 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  ResizableTable get radius6 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  ResizableTable get radius8 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  ResizableTable get radius10 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  ResizableTable get radius12 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  ResizableTable get radius14 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  ResizableTable get radius16 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  ResizableTable get radius20 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  ResizableTable get radius24 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  ResizableTable get radius28 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  ResizableTable get radius32 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  ResizableTable get radius36 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  ResizableTable get radius40 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  ResizableTable get radius48 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  ResizableTable get radius56 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  ResizableTable get radius64 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  ResizableTable get radius9999 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  ResizableTable get primary => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  ResizableTable get secondary => withStyle(
    const CoreTableStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  ResizableTable get tertiary => withStyle(
    const CoreTableStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  ResizableTable get surface => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  ResizableTable get surfaceContainer => withStyle(
    const CoreTableStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  ResizableTable get error => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  ResizableTable get success => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  ResizableTable get warning => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  ResizableTable get info => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  ResizableTable get outline => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  ResizableTable get transparent => withStyle(
    const CoreTableStyle(backgroundColor: .transparent),
  );
}
