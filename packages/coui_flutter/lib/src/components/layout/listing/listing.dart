import 'package:coui_flutter/coui_flutter.dart';

/// Unified vertical listing container for Flutter.
///
/// Holds a sequence of [ListRow]s and optionally draws a thin divider
/// between them. Theme + design-system defaults flow through
/// [CoreComponentTheme.listing] → design defaults.
class Listing extends StatelessWidget implements CoreListingContract<Widget> {
  /// Creates a [Listing].
  const Listing({
    required this.children,
    super.key,
    this.itemBorder,
    this.semanticLabel,
    this.listingStyle,
  });

  @override
  final List<Widget> children;

  @override
  final bool? itemBorder;

  @override
  final String? semanticLabel;

  @override
  final CoreListingStyle? listingStyle;

  /// Returns a copy of this [Listing] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Listing copyWith({
    Key? key,
    bool? itemBorder,
    String? semanticLabel,
    CoreListingStyle? listingStyle,
    List<Widget>? children,
  }) {
    return Listing(
      key: key ?? this.key,
      itemBorder: itemBorder ?? this.itemBorder,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      listingStyle: listingStyle ?? this.listingStyle,
      children: children ?? this.children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveListing(
      context,
      itemBorder: itemBorder,
      listingStyle: listingStyle,
    );

    final content = Column(
      mainAxisSize: .min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 && resolved.itemBorder)
            Divider(dividerStyle: resolved.dividerStyle),
          children[i],
        ],
      ],
    );

    final label = semanticLabel;
    if (label == null) return content;
    return Semantics(container: true, label: label, child: content);
  }
}

/// Chain sugar for merging a [CoreListingStyle] patch into
/// [Listing.listingStyle] without hand-reconstructing every field. Mirrors
/// the Web `Listing.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreListingStyle.merge` right-side-wins semantics).
extension ListingStyleChain on Listing {
  /// Sets the content padding.
  Listing contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreListingStyle(padding: value));

  /// Returns a copy of this [Listing] with [patch] merged into
  /// [listingStyle] (patch fields win on conflict).
  Listing withStyle(CoreListingStyle patch) => copyWith(
    listingStyle: (listingStyle ?? const CoreListingStyle()).merge(patch),
  );
}

/// Unified single row inside a [Listing].
///
/// Smart container: auto-expands the second [ListCol] when no column is
/// marked `grow: true`, matching CoUI's DaisyUI `list-row` behaviour.
class ListRow extends StatelessWidget implements CoreListRowContract<Widget> {
  /// Creates a [ListRow].
  const ListRow({
    required this.children,
    super.key,
    this.listingStyle,
  });

  @override
  final List<Widget> children;

  @override
  final CoreListingStyle? listingStyle;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveListing(context, listingStyle: listingStyle);

    final hasExplicitGrow = children.any(
      (child) => child is ListCol && child.grow,
    );

    var listColIndex = -1;
    final effectiveChildren = <Widget>[];

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      if (child is ListCol) {
        listColIndex++;
        if (!hasExplicitGrow && listColIndex == 1) {
          effectiveChildren.add(
            ListCol(
              grow: true,
              wrap: child.wrap,
              shrink: child.shrink,
              child: child.child,
            ),
          );
          continue;
        }
      }
      effectiveChildren.add(child);
    }

    return Padding(
      padding: resolved.rowPadding,
      child: Row(
        children: [
          for (var i = 0; i < effectiveChildren.length; i++) ...[
            if (i > 0) SizedBox(width: resolved.colSpacing),
            effectiveChildren[i],
          ],
        ],
      ),
    );
  }
}

/// Chain sugar for merging a [CoreListingStyle] patch into
/// [ListRow.listingStyle] without hand-reconstructing every field. Mirrors
/// the Web `ListRow.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreListingStyle.merge` right-side-wins semantics).
extension ListRowStyleChain on ListRow {
  /// Sets the content padding.
  ListRow contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreListingStyle(padding: value));

  /// Returns a copy of this [ListRow] with [patch] merged into
  /// [listingStyle] (patch fields win on conflict).
  ListRow withStyle(CoreListingStyle patch) => .new(
    listingStyle: (listingStyle ?? const CoreListingStyle()).merge(patch),
    children: children,
  );
}

/// Unified column inside a [ListRow].
///
/// [grow] — expand to fill available horizontal space.
/// [wrap] — allow the column to wrap onto the next line.
/// [shrink] — refuse to shrink below intrinsic size.
class ListCol extends StatelessWidget implements CoreListColContract<Widget> {
  /// Creates a [ListCol].
  const ListCol({
    required this.child,
    super.key,
    this.grow = false,
    this.wrap = false,
    this.shrink = false,
  });

  @override
  final Widget child;

  @override
  final bool grow;

  @override
  final bool wrap;

  @override
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    var rendered = child;
    if (shrink) {
      rendered = IntrinsicWidth(child: rendered);
    }
    if (grow) {
      // A growing cell already has bounded width and can wrap its contents.
      // Expanded(Flexible(...)) would write FlexParentData twice.
      return Expanded(child: rendered);
    }
    if (wrap) {
      // Allow text / children to soft-wrap inside a row.
      rendered = Flexible(
        child: rendered,
      );
    }
    return rendered;
  }
}
