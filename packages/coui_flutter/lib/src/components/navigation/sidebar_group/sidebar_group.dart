import 'package:coui_flutter/coui_flutter.dart';

/// A [Sidebar] row that folds a run of nested rows under it.
///
/// The group draws its own row — a [SidebarItem] with [leading], [label]
/// and a chevron at its end — and below it, while open, the [children]
/// indented behind a thin line. Activating the row opens or closes the
/// group.
///
/// Open state is the caller's when [expanded] is set and the group's own
/// otherwise, starting at [initiallyExpanded].
///
/// ```dart
/// SidebarGroup(
///   leading: const Icon(LucideIcons.folder),
///   label: const Text('프로젝트'),
///   children: [
///     SidebarItem(
///       level: CoreSidebarItemLevel.nested,
///       label: const Text('디자인 시스템'),
///       onPressed: () {},
///     ),
///   ],
/// )
/// ```
class SidebarGroup extends StatefulWidget
    implements CoreSidebarGroupContract<Widget> {
  /// Creates a [SidebarGroup].
  const SidebarGroup({
    required this.label,
    required this.children,
    super.key,
    this.leading,
    this.expanded,
    this.initiallyExpanded = CoreSidebarGroupContract.defaultInitiallyExpanded,
    this.onExpandedChanged,
    this.sidebarGroupStyle,
  });

  @override
  final Widget label;

  @override
  final Widget? leading;

  @override
  final List<Widget> children;

  @override
  final bool? expanded;

  @override
  final bool initiallyExpanded;

  @override
  final ValueChanged<bool>? onExpandedChanged;

  @override
  final CoreSidebarGroupStyle? sidebarGroupStyle;

  /// Returns a copy with the given fields replaced.
  SidebarGroup copyWith({
    Key? key,
    Widget? label,
    Widget? leading,
    List<Widget>? children,
    bool? expanded,
    bool? initiallyExpanded,
    ValueChanged<bool>? onExpandedChanged,
    CoreSidebarGroupStyle? sidebarGroupStyle,
  }) {
    return SidebarGroup(
      key: key ?? this.key,
      label: label ?? this.label,
      leading: leading ?? this.leading,
      expanded: expanded ?? this.expanded,
      initiallyExpanded: initiallyExpanded ?? this.initiallyExpanded,
      onExpandedChanged: onExpandedChanged ?? this.onExpandedChanged,
      sidebarGroupStyle: sidebarGroupStyle ?? this.sidebarGroupStyle,
      children: children ?? this.children,
    );
  }

  @override
  State<SidebarGroup> createState() => _SidebarGroupState();
}

class _SidebarGroupState extends State<SidebarGroup> {
  late bool _expanded = widget.expanded ?? widget.initiallyExpanded;

  bool get _effectiveExpanded => widget.expanded ?? _expanded;

  void _handleToggle() {
    final next = !_effectiveExpanded;
    if (widget.expanded == null) setState(() => _expanded = next);
    widget.onExpandedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSidebarGroup(
      context,
      sidebarGroupStyle: widget.sidebarGroupStyle,
    );
    final expanded = _effectiveExpanded;

    final row = CoUISemantics(
      expanded: expanded,
      child: SidebarItem(
        leading: widget.leading,
        label: widget.label,
        trailing: Icon(
          expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
          iconStyle: resolved.chevronIconStyle,
        ),
        onPressed: _handleToggle,
        sidebarItemStyle: resolved.itemStyle,
      ),
    );

    final nested = Stacks(
      children: [
        PositionedDirectional(
          start: resolved.treeLineInset,
          top: 0,
          bottom: 0,
          width: resolved.treeLineWidth,
          child: ColoredBox(color: resolved.treeLineColor),
        ),
        Padding(
          padding: resolved.childrenPadding,
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: resolved.childrenSpacing,
            children: widget.children,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      spacing: expanded ? resolved.childrenSpacing : 0,
      children: [
        row,
        ClipRect(
          child: AnimatedSize(
            duration: resolved.duration,
            curve: CoreEasing.move.toValue(),
            alignment: AlignmentDirectional.topStart,
            child: expanded ? nested : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}

/// Chain sugar for merging a [CoreSidebarGroupStyle] patch into
/// [SidebarGroup.sidebarGroupStyle]. Mirrors the Web extension.
extension SidebarGroupStyleChain on SidebarGroup {
  /// Returns a copy with [patch] merged into [sidebarGroupStyle] (patch
  /// fields win on conflict).
  SidebarGroup withStyle(CoreSidebarGroupStyle patch) => copyWith(
    sidebarGroupStyle: (sidebarGroupStyle ?? const CoreSidebarGroupStyle())
        .merge(patch),
  );
}
