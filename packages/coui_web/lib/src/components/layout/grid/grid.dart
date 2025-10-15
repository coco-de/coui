import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A responsive grid layout component.
///
/// Example:
/// ```dart
/// Grid(
///   columns: 3,
///   gap: 4,
///   children: [
///     div(child: text('Item 1')),
///     div(child: text('Item 2')),
///     div(child: text('Item 3')),
///   ],
/// )
/// ```
class Grid extends UiComponent {
  /// Creates a Grid component.
  Grid({
    super.key,
    required List<Component> children,
    this.columns = _defaultColumns,
    this.gap = _defaultGapSize,
    this.responsive = true,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(children);

  /// Number of columns.
  final int columns;

  /// Gap size.
  final int gap;

  /// Whether to use responsive breakpoints.
  final bool responsive;

  static const _defaultColumns = 12;

  static const _defaultGapSize = 4;

  static const _divValue = 'div';

  @override
  Grid copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    int? columns,
    int? gap,
    bool? responsive,
    Key? key,
  }) {
    return Grid(
      key: key ?? this.key,
      children: children ?? this.children,
      columns: columns ?? this.columns,
      gap: gap ?? this.gap,
      responsive: responsive ?? this.responsive,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return div(
      children: children,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass {
    final gridClass = 'grid';
    final columnsClass = responsive
        ? _getResponsiveColumns
        : 'grid-cols-$columns';
    final gapClass = 'gap-$gap';

    return '$gridClass $columnsClass $gapClass';
  }

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  String get _getResponsiveColumns {
    // Responsive grid: 1 col on mobile, 2 on tablet, specified on desktop
    return 'grid-cols-1 md:grid-cols-2 lg:grid-cols-$columns';
  }
}

/// A grid item component with optional span.
class GridItem extends UiComponent {
  /// Creates a GridItem component.
  const GridItem({
    super.key,
    Component? child,
    this.colSpan,
    this.rowSpan,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null, child: child);

  /// Column span.
  final int? colSpan;

  /// Row span.
  final int? rowSpan;

  static const _divValue = 'div';

  @override
  GridItem copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    int? colSpan,
    int? rowSpan,
    Key? key,
  }) {
    return GridItem(
      key: key ?? this.key,
      child: child ?? this.child,
      colSpan: colSpan ?? this.colSpan,
      rowSpan: rowSpan ?? this.rowSpan,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return div(
      child: child,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass {
    final colSpanClass = colSpan == null ? '' : 'col-span-$colSpan';
    final rowSpanClass = rowSpan == null ? '' : 'row-span-$rowSpan';

    return '$colSpanClass $rowSpanClass'.trim();
  }

  String _buildClasses() {
    final classList = <String>[];

    if (baseClass.isNotEmpty) {
      classList.add(baseClass);
    }

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
