import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'responsive_grid.stories.g.dart';

// ResponsiveGrid widgetbook constants.
const _kItemCount = 5;
const _kCardStyle = CoreCardStyle(
  padding: CoreEdgeInsets.all(CoreSpace.space16),
);
const _kDefaultColumns = 3;
const _kSpanColumns = 4;
const _kPlainFillerCount = 2;
const _kTrailingFillerCount = 3;

/// Builds a filler grid cell shared by the plain cells in the spanning
/// story.
Widget _buildFillerCell() =>
    Card(cardStyle: _kCardStyle, child: const Text('Cell').bodyMedium);

/// Knob input for [ResponsiveGrid] stories.
class ResponsiveGridInput {
  /// Creates a [ResponsiveGridInput].
  const ResponsiveGridInput({
    this.columns = _kDefaultColumns,
    this.spanning = false,
  });

  /// Column count at the widest breakpoint.
  final int columns;

  /// Whether the grid demonstrates col/row spanning items.
  final bool spanning;
}

/// Navigation metadata for the ResponsiveGrid component.
const kComponentMeta = ComponentMeta(name: 'ResponsiveGrid', path: 'layout');

/// Story metadata for [ResponsiveGrid].
const kMeta = Meta(ResponsiveGrid.new, argsType: ResponsiveGridInput.new);

/// Default builder mapping [ResponsiveGridInput] args to a [ResponsiveGrid].
final ResponsiveGridDefaults defaults = _Defaults(
  builder: (context, args) => args.spanning
      ? ResponsiveGrid(
          columns: _kSpanColumns,
          cellSpacing: CoreSpace.space16,
          responsive: false,
          children: [
            GridItem(
              colSpan: 2,
              child: Card(
                cardStyle: _kCardStyle,
                child: const Text('Spans 2 cols').bodyMedium,
              ),
            ),
            for (int i = 0; i < _kPlainFillerCount; i += 1) _buildFillerCell(),
            GridItem(
              rowSpan: 2,
              child: Card(
                cardStyle: _kCardStyle,
                child: const Text('Spans 2 rows').bodyMedium,
              ),
            ),
            for (int i = 0; i < _kTrailingFillerCount; i += 1)
              _buildFillerCell(),
          ],
        )
      : ResponsiveGrid(
          columns: args.columns,
          cellSpacing: CoreSpace.space16,
          children: [
            for (int i = 1; i <= _kItemCount; i += 1)
              Card(cardStyle: _kCardStyle, child: Text('Item $i').bodyMedium),
          ],
        ),
);

/// Responsive card grid with a column-count knob.
final $Default = _Story();

/// Fixed grid demonstrating column and row spans.
final $SpanningItems = _Story(
  name: 'Spanning Items',
  args: _Args(spanning: BoolArg(true)),
);
