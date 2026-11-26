import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'listing.stories.g.dart';

/// Knob input for [Listing] stories.
class ListingInput {
  /// Creates a [ListingInput].
  const ListingInput({
    this.itemBorder = true,
    this.columnSizing = false,
  });

  /// Whether rows draw a separating border.
  final bool itemBorder;

  /// Whether the column-sizing showcase (shrink / grow / wrap cols)
  /// is shown instead of the plain rows.
  final bool columnSizing;
}

/// Navigation metadata for the Listing component.
const kComponentMeta = ComponentMeta(name: 'Listing', path: 'layout');

/// Story metadata for [Listing].
const kMeta = Meta(Listing.new, argsType: ListingInput.new);

/// Default builder mapping [ListingInput] args to a [Listing].
final ListingDefaults defaults = _Defaults(
  builder: (context, args) => Listing(
    itemBorder: args.itemBorder,
    children: args.columnSizing ? _columnSizingRows() : _defaultRows(),
  ),
);

/// Plain three-column rows with editable knobs.
final $Default = _Story();

/// Rows with explicit column sizing (shrink icon, growing wrapped
/// title, shrink caption).
final $ColumnSizing = _Story(
  name: 'Column Sizing',
  args: _Args(columnSizing: BoolArg(true)),
);

/// Wraps [value] in body-medium, on-surface text for a list cell.
Widget _listingCellLabel(String value) => Text(value).bodyMedium().onSurface();

/// Wraps [value] in body-small, on-surface-variant text for a caption cell.
Widget _listingCellCaption(String value) =>
    Text(value).bodySmall().onSurfaceVariant();

/// Wraps [icon] in a small leading icon for a list cell.
Widget _listingLeadingIcon(IconName icon) =>
    Icon(icon, iconStyle: const CoreIconStyle(size: CoreSpace.space20));

/// Builds the plain three-column rows.
List<Widget> _defaultRows() => [
  ListRow(
    children: [
      ListCol(child: _listingCellLabel('Alice')),
      ListCol(child: _listingCellLabel('alice@example.com')),
      ListCol(child: _listingCellLabel('Admin')),
    ],
  ),
  ListRow(
    children: [
      ListCol(child: _listingCellLabel('Bob')),
      ListCol(child: _listingCellLabel('bob@example.com')),
      ListCol(child: _listingCellLabel('Member')),
    ],
  ),
  ListRow(
    children: [
      ListCol(child: _listingCellLabel('Cam')),
      ListCol(child: _listingCellLabel('cam@example.com')),
      ListCol(child: _listingCellLabel('Viewer')),
    ],
  ),
];

/// Builds the column-sizing showcase rows.
List<Widget> _columnSizingRows() => [
  ListRow(
    children: [
      ListCol(
        shrink: true,
        child: _listingLeadingIcon(LucideIcons.bell),
      ),
      ListCol(
        grow: true,
        wrap: true,
        child: _listingCellLabel(
          'Quarterly planning review with the design team',
        ),
      ),
      ListCol(shrink: true, child: _listingCellCaption('Today')),
    ],
  ),
  ListRow(
    children: [
      ListCol(
        shrink: true,
        child: _listingLeadingIcon(LucideIcons.mail),
      ),
      ListCol(
        grow: true,
        wrap: true,
        child: _listingCellLabel(
          'New comment on your latest pull request',
        ),
      ),
      ListCol(shrink: true, child: _listingCellCaption('Yesterday')),
    ],
  ),
];
