import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/layout/responsive_grid/render_grid.dart';
import 'package:flutter/widgets.dart';

/// Cell wrapper inside a `ResponsiveGrid` that claims multiple
/// columns and/or rows via `colSpan` / `rowSpan`.
///
/// Example:
/// ```dart
/// ResponsiveGrid(
///   columns: 4,
///   children: [
///     GridItem(colSpan: 2, child: Text('Spans 2 cols')),
///     Text('Cell'),
///     Text('Cell'),
///   ],
/// )
/// ```
class GridItem extends StatelessWidget implements CoreGridItemContract<Widget> {
  /// Creates a [GridItem].
  const GridItem({
    required this.child,
    this.colSpan,
    this.rowSpan,
    super.key,
  }) : assert(
         colSpan == null || colSpan >= 1,
         'colSpan must be >= 1 when provided',
       ),
       assert(
         rowSpan == null || rowSpan >= 1,
         'rowSpan must be >= 1 when provided',
       );

  @override
  final Widget child;

  @override
  final int? colSpan;

  @override
  final int? rowSpan;

  @override
  Widget build(BuildContext context) {
    return GridItemParentData(
      colSpan: colSpan ?? 1,
      rowSpan: rowSpan ?? 1,
      child: child,
    );
  }
}
