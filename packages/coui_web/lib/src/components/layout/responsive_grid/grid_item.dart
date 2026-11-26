import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/responsive_grid/responsive_grid_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Cell wrapper inside a `ResponsiveGrid` that claims multiple
/// columns and/or rows via `colSpan` / `rowSpan`.
///
/// Example:
/// ```dart
/// ResponsiveGrid(
///   columns: 4,
///   children: [
///     GridItem(colSpan: 2, child: Text('Wide')),
///     Text('Cell'),
///   ],
/// )
/// ```
class GridItem extends UiComponent implements CoreGridItemContract<Component> {
  /// Creates a [GridItem].
  GridItem({
    super.key,
    this.colSpan,
    this.rowSpan,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
    required this.child,
  }) : assert(
         colSpan == null || colSpan >= 1,
         'colSpan must be >= 1 when provided',
       ),
       assert(
         rowSpan == null || rowSpan >= 1,
         'rowSpan must be >= 1 when provided',
       ),
       super(tag: 'div');

  @override
  final Component child;

  @override
  final int? colSpan;

  @override
  final int? rowSpan;
  @override
  GridItem copyWith({
    Key? key,
    int? colSpan,
    int? rowSpan,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Component? child,
  }) {
    return GridItem(
      key: key ?? this.key,
      colSpan: colSpan ?? this.colSpan,
      rowSpan: rowSpan ?? this.rowSpan,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveGridItem(colSpan: colSpan, rowSpan: rowSpan);
    return div(
      [child],
      id: id,
      classes: classes,
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
    );
  }
}
