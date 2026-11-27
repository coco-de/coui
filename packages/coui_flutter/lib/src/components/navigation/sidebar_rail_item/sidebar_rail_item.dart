import 'package:coui_flutter/coui_flutter.dart';

/// One destination in a [Sidebar]'s icon rail — a glyph alone in a square.
///
/// It has no visible label: [label] is its accessible name and its tooltip.
/// The current place ([selected]) draws a raised face; hover, focus and
/// press lay a state layer over it.
///
/// ```dart
/// SidebarRailItem(
///   icon: const Icon(LucideIcons.layoutGrid),
///   label: '대시보드',
///   selected: true,
///   onPressed: () {},
/// )
/// ```
class SidebarRailItem extends StatefulWidget
    implements CoreSidebarRailItemContract<Widget> {
  /// Creates a [SidebarRailItem].
  const SidebarRailItem({
    required this.icon,
    required this.label,
    super.key,
    this.dot = false,
    this.selected = false,
    this.enabled,
    this.onPressed,
    this.sidebarRailItemStyle,
  });

  @override
  final Widget icon;

  @override
  final String label;

  @override
  final bool dot;

  @override
  final bool selected;

  @override
  final bool? enabled;

  @override
  final VoidCallback? onPressed;

  @override
  final CoreSidebarRailItemStyle? sidebarRailItemStyle;

  /// Returns a copy with the given fields replaced.
  SidebarRailItem copyWith({
    Key? key,
    Widget? icon,
    String? label,
    bool? dot,
    bool? selected,
    bool? enabled,
    VoidCallback? onPressed,
    CoreSidebarRailItemStyle? sidebarRailItemStyle,
  }) {
    return SidebarRailItem(
      key: key ?? this.key,
      icon: icon ?? this.icon,
      label: label ?? this.label,
      dot: dot ?? this.dot,
      selected: selected ?? this.selected,
      enabled: enabled ?? this.enabled,
      onPressed: onPressed ?? this.onPressed,
      sidebarRailItemStyle: sidebarRailItemStyle ?? this.sidebarRailItemStyle,
    );
  }

  @override
  State<SidebarRailItem> createState() => _SidebarRailItemState();
}

class _SidebarRailItemState extends State<SidebarRailItem> {
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
    final resolved = resolveSidebarRailItem(
      context,
      sidebarRailItemStyle: widget.sidebarRailItemStyle,
    );
    final enabled = widget.enabled ?? widget.onPressed != null;
    final selected = enabled && widget.selected;
    final iconTheme = !enabled
        ? resolved.disabledIconTheme
        : selected
        ? resolved.selectedIconTheme
        : resolved.iconTheme;
    final wash = !enabled
        ? null
        : _pressed
        ? resolved.pressedWashColor
        : _focused
        ? resolved.focusWashColor
        : _hovered
        ? resolved.hoverWashColor
        : null;

    final box = AnimatedContainer(
      width: resolved.size,
      height: resolved.size,
      decoration: BoxDecoration(
        color: selected
            ? resolved.selectedBackgroundColor
            : resolved.backgroundColor,
        borderRadius: resolved.borderRadius,
      ),
      duration: resolved.duration,
      curve: resolved.curve,
      child: Stacks(
        alignment: .center,
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
          IconTheme.merge(data: iconTheme, child: widget.icon),
          if (widget.dot)
            Position(
              top: resolved.dotSize,
              right: resolved.dotSize,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: resolved.dotColor,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(dimension: resolved.dotSize),
                ),
              ),
            ),
        ],
      ),
    );

    return Tooltip(
      message: widget.label,
      position: .right,
      // The tooltip restates the destination's name; handing the same text
      // in as the bubble keeps it from being announced twice.
      tooltipChild: Text(widget.label),
      // The pointer-target floor — zero where the box is already large
      // enough, which the rail's 40 square is at every scale.
      child: TouchTarget(
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
            child: Semantics(label: widget.label, child: box),
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreSidebarRailItemStyle] patch into
/// [SidebarRailItem.sidebarRailItemStyle]. Mirrors the Web extension.
extension SidebarRailItemStyleChain on SidebarRailItem {
  /// Sets the background paint and preserves the other style fields.
  SidebarRailItem backgroundColor(CoreColor value) =>
      withStyle(CoreSidebarRailItemStyle(backgroundColor: value));

  /// Returns a copy with [patch] merged into [sidebarRailItemStyle] (patch
  /// fields win on conflict).
  SidebarRailItem withStyle(CoreSidebarRailItemStyle patch) => copyWith(
    sidebarRailItemStyle:
        (sidebarRailItemStyle ?? const CoreSidebarRailItemStyle()).merge(
          patch,
        ),
  );
}
