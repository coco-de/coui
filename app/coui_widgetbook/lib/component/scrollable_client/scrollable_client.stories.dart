import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'scrollable_client.stories.g.dart';

/// Height of the scrollable viewport in the demo.
const _kViewportHeight = 280.0;

/// Width of a single checkerboard cell.
const _kCellWidth = 96.0;

/// Height of a single checkerboard cell.
const _kCellHeight = 64.0;

/// Default number of checkerboard grid rows.
const _kGridRows = 8;

/// Default number of checkerboard grid columns.
const _kGridColumns = 6;

/// Interactive demo host for [ScrollableClient] stories.
///
/// Renders a checkerboard grid larger than its viewport so dragging or
/// wheel-scrolling through it exercises both scroll axes at once.
class ScrollableClientDemo extends StatelessWidget {
  /// Creates a [ScrollableClientDemo].
  const ScrollableClientDemo({
    super.key,
    this.rows = _kGridRows,
    this.columns = _kGridColumns,
    this.diagonalDragBehavior = CoreDiagonalDragBehavior.free,
  });

  /// Number of checkerboard rows.
  final int rows;

  /// Number of checkerboard columns.
  final int columns;

  /// Diagonal drag behavior of the scrollable client.
  final CoreDiagonalDragBehavior diagonalDragBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: _kViewportHeight,
      child: ScrollableClient(
        diagonalDragBehavior: diagonalDragBehavior,
        builder: (context, offset, viewportSize, child) {
          return Column(
            mainAxisSize: .min,
            children: [
              for (int row = 0; row < rows; row += 1)
                Row(
                  mainAxisSize: .min,
                  children: [
                    for (int col = 0; col < columns; col += 1)
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (row + col).isEven
                              ? theme.colorScheme.surfaceContainer.toValue()
                              : theme.colorScheme.surfaceContainerHigh
                                    .toValue(),
                          border: Border.all(
                            color: theme.colorScheme.outline.toValue(),
                          ),
                        ),
                        width: _kCellWidth,
                        height: _kCellHeight,
                        child: Text('$row,$col'),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Navigation metadata for the ScrollableClient component.
const kComponentMeta = ComponentMeta(name: 'ScrollableClient', path: 'layout');

/// Story metadata for [ScrollableClientDemo].
const kMeta = Meta(ScrollableClientDemo.new);

/// Two-axis checkerboard grid with editable knobs.
final $Default = _Story();
