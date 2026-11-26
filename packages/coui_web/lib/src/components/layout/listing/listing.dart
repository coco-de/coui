import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/layout/listing/listing_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified vertical listing container for CoUI Web.
///
/// Mirrors Flutter `Listing` — holds a sequence of [ListRow]s with an
/// optional thin divider between them.
class Listing extends UiComponent implements CoreListingContract<Component> {
  /// Creates a [Listing].
  const Listing({
    required this.children,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    this.itemBorder,
    this.semanticLabel,
    this.listingStyle,
  }) : super(tag: 'div');

  @override
  final List<Component> children;

  @override
  final bool? itemBorder;

  @override
  final String? semanticLabel;

  @override
  final CoreListingStyle? listingStyle;

  @override
  Listing copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    bool? itemBorder,
    String? semanticLabel,
    CoreListingStyle? listingStyle,
    List<Component>? children,
  }) {
    return Listing(
      key: key ?? this.key,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      itemBorder: itemBorder ?? this.itemBorder,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      listingStyle: listingStyle ?? this.listingStyle,
      children: children ?? this.children,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveListing(
      context,
      itemBorder: itemBorder,
      listingStyle: listingStyle,
    );

    // A nested `Divider` renders between adjacent rows only when the
    // resolver provides a passthrough `dividerStyle` (gated by the merged
    // `itemBorder` toggle) — mirrors the Flutter `Listing` tree 1:1.
    final dividerStyle = resolved.dividerStyle;
    final items = <Component>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && dividerStyle != null) {
        items.add(Divider(dividerStyle: dividerStyle));
      }
      items.add(children[i]);
    }

    final attrs = {...componentAttributes, 'role': 'list'};
    final label = semanticLabel;
    if (label != null) attrs['aria-label'] = label;

    return div(
      items,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: attrs,
      events: events.isEmpty ? null : events,
    );
  }
}

/// Chain sugar for merging a [CoreListingStyle] patch into
/// [Listing.listingStyle] without hand-reconstructing every field. Mirrors
/// the Flutter `Listing.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreListingStyle.merge` right-side-wins semantics).
extension ListingStyleChain on Listing {
  /// Returns a copy of this [Listing] with [patch] merged into
  /// [listingStyle] (patch fields win on conflict).
  Listing withStyle(CoreListingStyle patch) => copyWith(
    listingStyle: (listingStyle ?? const CoreListingStyle()).merge(patch),
  );
}

/// Unified single row inside a [Listing].
///
/// Smart container: auto-applies `grow` to the second [ListCol] when no
/// column has `grow: true`, mirroring CoUI DaisyUI `list-row` behaviour.
class ListRow extends UiComponent implements CoreListRowContract<Component> {
  /// Creates a [ListRow].
  const ListRow({
    required this.children,
    super.key,
    this.listingStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final List<Component> children;

  @override
  final CoreListingStyle? listingStyle;

  @override
  ListRow copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    CoreListingStyle? listingStyle,
    List<Component>? children,
  }) {
    return ListRow(
      key: key ?? this.key,
      listingStyle: listingStyle ?? this.listingStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      children: children ?? this.children,
    );
  }

  @override
  Component build(BuildContext context) {
    final rowChrome = resolveListingRow(context, listingStyle: listingStyle);

    final effective = List.of(children);
    final hasExplicitGrow = effective.any(
      (child) => child is ListCol && child.grow,
    );
    if (!hasExplicitGrow) {
      var colIndex = -1;
      for (var i = 0; i < effective.length; i++) {
        final c = effective[i];
        if (c is ListCol) {
          colIndex++;
          if (colIndex == 1) {
            effective[i] = ListCol(
              grow: true,
              wrap: c.wrap,
              shrink: c.shrink,
              child: c.child,
            );
            break;
          }
        }
      }
    }

    return div(
      effective,
      id: id,
      classes: rootClasses(rowChrome.root.className),
      styles: css != null
          ? Styles.combine([?rowChrome.root.inlineStyles, css!])
          : rowChrome.root.inlineStyles,
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
    );
  }
}

/// Chain sugar for merging a [CoreListingStyle] patch into
/// [ListRow.listingStyle] without hand-reconstructing every field. Mirrors
/// the Flutter `ListRow.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreListingStyle.merge` right-side-wins semantics).
extension ListRowStyleChain on ListRow {
  /// Returns a copy of this [ListRow] with [patch] merged into
  /// [listingStyle] (patch fields win on conflict).
  ListRow withStyle(CoreListingStyle patch) => copyWith(
    listingStyle: (listingStyle ?? const CoreListingStyle()).merge(patch),
  );
}

/// Unified single column inside a [ListRow].
class ListCol extends UiComponent implements CoreListColContract<Component> {
  /// Creates a [ListCol].
  const ListCol({
    required this.child,
    super.key,
    this.grow = false,
    this.wrap = false,
    this.shrink = false,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component child;

  @override
  final bool grow;

  @override
  final bool wrap;

  @override
  final bool shrink;

  @override
  ListCol copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    bool? grow,
    bool? wrap,
    bool? shrink,
    Component? child,
  }) {
    return ListCol(
      key: key ?? this.key,
      grow: grow ?? this.grow,
      wrap: wrap ?? this.wrap,
      shrink: shrink ?? this.shrink,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }

  @override
  Component build(BuildContext context) {
    final colChrome = resolveListingCol(
      grow: grow,
      wrap: wrap,
      shrink: shrink,
    );
    return div(
      [child],
      id: id,
      classes: rootClasses(colChrome.root.className),
      styles: css != null
          ? Styles.combine([?colChrome.root.inlineStyles, css!])
          : colChrome.root.inlineStyles,
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
    );
  }
}
