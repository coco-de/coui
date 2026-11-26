import 'package:coui_flutter/coui_flutter.dart';

/// One destination in a [Sidebar] — a glyph, a name, and at its far end an
/// optional unread dot, a count and a trailing glyph.
///
/// The current place ([selected]) draws a raised face and a heavier label;
/// hover, focus and press lay a state layer over the row. Every chrome
/// override flows through [sidebarItemStyle].
///
/// ```text
/// CoreSidebarItemStyle.defaultX → defaultsByLevel[level]
///   → CoreSidebarItemTheme.style
///   → CoreSidebarItemTheme.variantStyles[level]
///   → widget.sidebarItemStyle
/// ```
///
/// ```dart
/// SidebarItem(
///   leading: const Icon(LucideIcons.inbox),
///   label: const Text('받은 편지함'),
///   count: Badge(form: CoreBadgeForm.count, child: const Text('3')),
///   selected: true,
///   onPressed: () {},
/// )
/// ```
class SidebarItem extends StatefulWidget
    implements CoreSidebarItemContract<Widget> {
  /// Creates a [SidebarItem].
  const SidebarItem({
    required this.label,
    super.key,
    this.leading,
    this.count,
    this.trailing,
    this.dot = false,
    this.level = CoreSidebarItemLevel.defaultLevel,
    this.selected = false,
    this.enabled,
    this.onPressed,
    this.sidebarItemStyle,
  });

  @override
  final Widget label;

  @override
  final Widget? leading;

  @override
  final Widget? count;

  @override
  final Widget? trailing;

  @override
  final bool dot;

  @override
  final CoreSidebarItemLevel level;

  @override
  final bool selected;

  @override
  final bool? enabled;

  @override
  final VoidCallback? onPressed;

  @override
  final CoreSidebarItemStyle? sidebarItemStyle;

  /// Returns a copy with the given fields replaced.
  SidebarItem copyWith({
    Key? key,
    Widget? label,
    Widget? leading,
    Widget? count,
    Widget? trailing,
    bool? dot,
    CoreSidebarItemLevel? level,
    bool? selected,
    bool? enabled,
    VoidCallback? onPressed,
    CoreSidebarItemStyle? sidebarItemStyle,
  }) {
    return SidebarItem(
      key: key ?? this.key,
      label: label ?? this.label,
      leading: leading ?? this.leading,
      count: count ?? this.count,
      trailing: trailing ?? this.trailing,
      dot: dot ?? this.dot,
      level: level ?? this.level,
      selected: selected ?? this.selected,
      enabled: enabled ?? this.enabled,
      onPressed: onPressed ?? this.onPressed,
      sidebarItemStyle: sidebarItemStyle ?? this.sidebarItemStyle,
    );
  }

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  void _handleHover(bool hovered) {
    if (_hovered == hovered) return;
    setState(() => _hovered = hovered);
  }

  void _handleFocus(bool focused) {
    if (_focused == focused) return;
    setState(() => _focused = focused);
  }

  void _handlePressedChange(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSidebarItem(
      context,
      level: widget.level,
      sidebarItemStyle: widget.sidebarItemStyle,
    );
    final enabled = widget.enabled ?? widget.onPressed != null;
    // Disabled outranks selection.
    final selected = enabled && widget.selected;

    final iconTheme = !enabled
        ? resolved.disabledIconTheme
        : selected
        ? resolved.selectedIconTheme
        : resolved.iconTheme;
    final trailingIconTheme = enabled
        ? resolved.trailingIconTheme
        : resolved.disabledTrailingIconTheme;
    final labelTextStyle = !enabled
        ? resolved.disabledLabelTextStyle
        : selected
        ? resolved.selectedLabelTextStyle
        : resolved.labelTextStyle;
    final wash = !enabled
        ? null
        : _pressed
        ? resolved.pressedWashColor
        : _focused
        ? resolved.focusWashColor
        : _hovered
        ? resolved.hoverWashColor
        : null;

    final leading = widget.leading;
    final count = widget.count;
    final trailing = widget.trailing;
    final row = Row(
      spacing: resolved.contentSpacing,
      children: [
        if (leading != null) IconTheme.merge(data: iconTheme, child: leading),
        Expanded(
          child: DefaultTextStyle.merge(
            style: labelTextStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: widget.label,
          ),
        ),
        if (widget.dot)
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: resolved.dotColor,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: resolved.dotSize),
            ),
          ),
        ?count,
        if (trailing != null)
          IconTheme.merge(data: trailingIconTheme, child: trailing),
      ],
    );

    final box = AnimatedContainer(
      constraints: BoxConstraints(minHeight: resolved.minHeight),
      decoration: BoxDecoration(
        color: selected
            ? resolved.selectedBackgroundColor
            : resolved.backgroundColor,
        borderRadius: resolved.borderRadius,
      ),
      duration: resolved.duration,
      curve: resolved.curve,
      // The row's height is the level's, not the content's: the content is
      // centred in it the way Web's `items-center` centres it
      // (widget/stack-alignment.md).
      child: Stacks(
        alignment: .centerStart,
        children: [
          if (wash != null)
            Position.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: wash,
                  borderRadius: resolved.borderRadius,
                ),
              ),
            ),
          Padding(padding: resolved.padding, child: row),
        ],
      ),
    );

    // The pointer-target floor — zero where the row is already tall enough,
    // which both levels are.
    return TouchTarget(
      child: MergeSemantics(
        child: Clickable(
          onPressed: enabled ? widget.onPressed : null,
          onHover: _handleHover,
          onFocus: _handleFocus,
          onPressedChange: _handlePressedChange,
          enabled: enabled,
          semanticsSelected: selected,
          semanticsEnabled: enabled,
          clickableStyle: resolved.clickableStyle,
          child: box,
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreSidebarItemStyle] patch into
/// [SidebarItem.sidebarItemStyle]. Mirrors the Web extension.
extension SidebarItemStyleChain on SidebarItem {
  /// Returns a copy with [patch] merged into [sidebarItemStyle] (patch
  /// fields win on conflict).
  SidebarItem withStyle(CoreSidebarItemStyle patch) => copyWith(
    sidebarItemStyle: (sidebarItemStyle ?? const CoreSidebarItemStyle()).merge(
      patch,
    ),
  );
}
