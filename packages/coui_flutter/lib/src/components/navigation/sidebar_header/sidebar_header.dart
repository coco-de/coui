import 'package:coui_flutter/coui_flutter.dart';

/// The identity row of a [Sidebar] — a workspace with its logo at the top,
/// or the signed-in person with their avatar at the foot.
///
/// With [onPressed] the whole row opens a switcher; without it the row only
/// shows. `card` lifts the row onto a bordered `surface` tile.
///
/// ```dart
/// SidebarHeader(
///   leading: Avatar(initials: 'HY'),
///   title: const Text('나음 병원'),
///   subtitle: const Text('본원 · 관리자'),
///   trailing: const Icon(LucideIcons.chevronsUpDown),
///   onPressed: () {},
/// )
/// ```
class SidebarHeader extends StatefulWidget
    implements CoreSidebarHeaderContract<Widget> {
  /// Creates a [SidebarHeader].
  const SidebarHeader({
    required this.title,
    super.key,
    this.variant = CoreSidebarHeaderVariant.defaultVariant,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onPressed,
    this.sidebarHeaderStyle,
  });

  @override
  final CoreSidebarHeaderVariant variant;

  @override
  final Widget? leading;

  @override
  final Widget title;

  @override
  final Widget? subtitle;

  @override
  final Widget? trailing;

  @override
  final VoidCallback? onPressed;

  @override
  final CoreSidebarHeaderStyle? sidebarHeaderStyle;

  /// Returns a copy with the given fields replaced.
  SidebarHeader copyWith({
    Key? key,
    CoreSidebarHeaderVariant? variant,
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onPressed,
    CoreSidebarHeaderStyle? sidebarHeaderStyle,
  }) {
    return SidebarHeader(
      key: key ?? this.key,
      variant: variant ?? this.variant,
      leading: leading ?? this.leading,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      trailing: trailing ?? this.trailing,
      onPressed: onPressed ?? this.onPressed,
      sidebarHeaderStyle: sidebarHeaderStyle ?? this.sidebarHeaderStyle,
    );
  }

  @override
  State<SidebarHeader> createState() => _SidebarHeaderState();
}

class _SidebarHeaderState extends State<SidebarHeader> {
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
    final resolved = resolveSidebarHeader(
      context,
      variant: widget.variant,
      sidebarHeaderStyle: widget.sidebarHeaderStyle,
    );
    final pressable = widget.onPressed != null;
    final wash = !pressable
        ? null
        : _pressed
        ? resolved.pressedWashColor
        : _focused
        ? resolved.focusWashColor
        : _hovered
        ? resolved.hoverWashColor
        : null;

    final leading = widget.leading;
    final subtitle = widget.subtitle;
    final trailing = widget.trailing;
    final row = Row(
      spacing: resolved.contentSpacing,
      children: [
        ?leading,
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              DefaultTextStyle.merge(
                style: resolved.titleTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: widget.title,
              ),
              if (subtitle != null)
                DefaultTextStyle.merge(
                  style: resolved.subtitleTextStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: subtitle,
                ),
            ],
          ),
        ),
        if (trailing != null)
          IconTheme.merge(data: resolved.trailingIconTheme, child: trailing),
      ],
    );

    final borderColor = resolved.borderColor;
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        borderRadius: resolved.borderRadius,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor, width: resolved.borderWidth),
      ),
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

    if (!pressable) return box;
    return MergeSemantics(
      child: Clickable(
        onPressed: widget.onPressed,
        onHover: _handleHover,
        onFocus: _handleFocus,
        onPressedChange: _handlePressedChange,
        clickableStyle: resolved.clickableStyle,
        child: box,
      ),
    );
  }
}

/// Chain sugar for merging a [CoreSidebarHeaderStyle] patch into
/// [SidebarHeader.sidebarHeaderStyle]. Mirrors the Web extension.
extension SidebarHeaderStyleChain on SidebarHeader {
  /// Sets the background paint and preserves the other style fields.
  SidebarHeader backgroundColor(CoreColor value) =>
      withStyle(CoreSidebarHeaderStyle(backgroundColor: value));

  /// Returns a copy with [patch] merged into [sidebarHeaderStyle] (patch
  /// fields win on conflict).
  SidebarHeader withStyle(CoreSidebarHeaderStyle patch) => copyWith(
    sidebarHeaderStyle: (sidebarHeaderStyle ?? const CoreSidebarHeaderStyle())
        .merge(patch),
  );
}
