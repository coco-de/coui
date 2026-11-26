import 'package:coui_flutter/coui_flutter.dart';

/// A unified cross-platform breadcrumb navigation trail.
///
/// `Breadcrumb` renders a horizontal row of [CoreBreadcrumbItem]s
/// separated by chevron glyphs. The last item is treated as the current
/// location and is rendered as plain (non-interactive) text; every
/// preceding item is an interactive link that invokes [onItemTap] with
/// its zero-based index.
///
/// [enabled] follows the handler (`enabled ?? (onItemTap != null)`): a trail
/// with no handler, or an explicit `enabled: false`, draws every item and
/// separator in the disabled content colour and makes no item interactive.
///
/// Data-driven: pass a [items] list of [CoreBreadcrumbItem]s. Every
/// chrome / dimensional override flows through the single
/// [breadcrumbStyle] field — see [CoreBreadcrumbStyle] for the merge
/// chain.
///
/// Mirrors Web `Breadcrumb` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// Breadcrumb(
///   items: const [
///     CoreBreadcrumbItem(label: 'Home', href: '/'),
///     CoreBreadcrumbItem(label: 'Components', href: '/components'),
///     CoreBreadcrumbItem(
///       label: CoUILocalizations.of(context).breadcrumbLabel,
///     ),
///   ],
///   onItemTap: (i) => navigateTo(i),
/// )
/// ```
class Breadcrumb extends StatefulWidget implements CoreBreadcrumbContract {
  /// Creates a [Breadcrumb].
  const Breadcrumb({
    required this.items,
    this.onItemTap,
    this.enabled,
    this.variant = CoreBreadcrumbVariant.defaultVariant,
    this.breadcrumbStyle,
    super.key,
  });

  @override
  final List<CoreBreadcrumbItem> items;

  @override
  final CoreValueChanged<int>? onItemTap;

  @override
  final bool? enabled;

  @override
  final CoreBreadcrumbStyle? breadcrumbStyle;

  /// The visual variant of the breadcrumb.
  final CoreBreadcrumbVariant variant;

  /// Returns a copy of this [Breadcrumb] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Breadcrumb copyWith({
    Key? key,
    List<CoreBreadcrumbItem>? items,
    CoreValueChanged<int>? onItemTap,
    bool? enabled,
    CoreBreadcrumbVariant? variant,
    CoreBreadcrumbStyle? breadcrumbStyle,
  }) {
    return Breadcrumb(
      key: key ?? this.key,
      items: items ?? this.items,
      onItemTap: onItemTap ?? this.onItemTap,
      enabled: enabled ?? this.enabled,
      variant: variant ?? this.variant,
      breadcrumbStyle: breadcrumbStyle ?? this.breadcrumbStyle,
    );
  }

  @override
  State<Breadcrumb> createState() => _BreadcrumbState();
}

class _BreadcrumbState extends State<Breadcrumb> {
  int? _hoveredIndex;

  bool get _enabled => widget.enabled ?? (widget.onItemTap != null);

  void _handleHoverChanged(int index, {required bool hovering}) {
    setState(() => _hoveredIndex = hovering ? index : null);
  }

  Widget _buildItem({
    required CoreBreadcrumbItem item,
    required int index,
    required bool isCurrent,
    required ResolvedBreadcrumb resolved,
  }) {
    final callback = widget.onItemTap;
    final isInteractive = !isCurrent && _enabled && callback != null;

    final Color color;
    if (isCurrent) {
      color = resolved.currentItemColor;
    } else if (isInteractive && _hoveredIndex == index) {
      color = resolved.itemHoverColor;
    } else {
      color = resolved.itemColor;
    }

    final baseTextStyle = isCurrent
        ? resolved.currentItemBaseTextStyle
        : resolved.itemBaseTextStyle;

    // The inset sits INSIDE the `Clickable`: the focus ring wraps the padded
    // item, and the hit area is the padded item too.
    Widget label = Padding(
      padding: resolved.itemPadding,
      child: AnimatedDefaultTextStyle(
        style: baseTextStyle.copyWith(color: color),
        curve: CoreEasing.move.toValue(),
        duration: resolved.hoverDuration,
        child: Text(item.label),
      ),
    );

    label = Semantics(link: isInteractive, child: label);

    if (!isInteractive) return label;

    // The composed Clickable owns tap / keyboard activation / cursor /
    // press feedback / focus ring (Epic composition — no hand-rolled
    // GestureDetector + MouseRegion). Hover state flows back through
    // `onHover` so the widget only SELECTS between the pre-resolved
    // link / hover colours via `AnimatedDefaultTextStyle` above.
    return Clickable(
      onPressed: () => callback(index),
      onHover: (hovered) => _handleHoverChanged(index, hovering: hovered),
      clickableStyle: resolved.clickableStyle,
      child: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveBreadcrumb(
      context,
      variant: widget.variant,
      enabled: _enabled,
      breadcrumbStyle: widget.breadcrumbStyle,
    );

    final separator = Icon(
      LucideIcons.chevronRight,
      iconStyle: resolved.separatorIconStyle,
    );

    final gap = Gap(gapStyle: resolved.itemSeparatorGapStyle);

    final rowChildren = <Widget>[];
    for (var i = 0; i < widget.items.length; i++) {
      final isCurrent = i == widget.items.length - 1;
      if (i > 0) {
        rowChildren
          ..add(gap)
          ..add(separator)
          ..add(gap);
      }
      rowChildren.add(
        _buildItem(
          item: widget.items[i],
          index: i,
          isCurrent: isCurrent,
          resolved: resolved,
        ),
      );
    }

    // The label was already right; the landmark was missing. Web has
    // emitted `role="navigation"` here all along.
    return CoUISemantics(
      role: .navigation,
      label: CoUILocalizations.of(context).breadcrumbLabel,
      container: true,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(scrollbars: false, dragDevices: {.touch}),
        child: SingleChildScrollView(
          scrollDirection: .horizontal,
          child: Row(
            mainAxisSize: .min,
            children: rowChildren,
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreBreadcrumbStyle] patch into
/// [Breadcrumb.breadcrumbStyle] without hand-reconstructing every field.
/// Mirrors the Web `Breadcrumb.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBreadcrumbStyle.merge` right-side-wins semantics).
extension BreadcrumbStyleChain on Breadcrumb {
  /// Returns a copy of this [Breadcrumb] with [patch] merged into
  /// [breadcrumbStyle] (patch fields win on conflict).
  Breadcrumb withStyle(CoreBreadcrumbStyle patch) => copyWith(
    breadcrumbStyle: (breadcrumbStyle ?? const CoreBreadcrumbStyle()).merge(
      patch,
    ),
  );
}
