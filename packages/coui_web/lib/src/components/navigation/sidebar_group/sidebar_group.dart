import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/navigation/sidebar_group/sidebar_group_style.dart';
import 'package:coui_web/src/components/navigation/sidebar_item/sidebar_item.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// A `Sidebar` row for CoUI Web that folds a run of nested rows under it.
///
/// The group draws its own row — a [SidebarItem] with [leading], [label]
/// and a chevron at its end, stating `aria-expanded` — and below it, while
/// open, the [children] indented behind a thin line. Activating the row
/// opens or closes the group.
///
/// Open state is the caller's when [expanded] is set and the group's own
/// otherwise, starting at [initiallyExpanded].
class SidebarGroup extends UiStatefulComponent
    implements CoreSidebarGroupContract<Component> {
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
    super.id,
    super.classes,
    super.css,
    super.attributes,
  });

  @override
  final Component label;

  @override
  final Component? leading;

  @override
  final List<Component> children;

  @override
  final bool? expanded;

  @override
  final bool initiallyExpanded;

  @override
  final CoreValueChanged<bool>? onExpandedChanged;

  @override
  final CoreSidebarGroupStyle? sidebarGroupStyle;

  /// Returns a copy with the given fields replaced.
  SidebarGroup copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    Component? label,
    Component? leading,
    List<Component>? children,
    bool? expanded,
    bool? initiallyExpanded,
    CoreValueChanged<bool>? onExpandedChanged,
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
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      children: children ?? this.children,
    );
  }

  @override
  State<SidebarGroup> createState() => _SidebarGroupState();
}

/// Chain sugar mirroring the Flutter `SidebarGroup.withStyle` extension.
extension SidebarGroupStyleChain on SidebarGroup {
  /// Returns a copy with [patch] merged into [sidebarGroupStyle] (patch
  /// fields win on conflict).
  SidebarGroup withStyle(CoreSidebarGroupStyle patch) => copyWith(
    sidebarGroupStyle: (sidebarGroupStyle ?? const CoreSidebarGroupStyle())
        .merge(patch),
  );
}

class _SidebarGroupState extends State<SidebarGroup> {
  late bool _expanded = component.expanded ?? component.initiallyExpanded;

  bool get _effectiveExpanded => component.expanded ?? _expanded;

  void _handleToggle() {
    final next = !_effectiveExpanded;
    if (component.expanded == null) setState(() => _expanded = next);
    component.onExpandedChanged?.call(next);
  }

  @override
  Component build(BuildContext context) {
    final expanded = _effectiveExpanded;
    final resolved = resolveSidebarGroup(
      context,
      expanded: expanded,
      sidebarGroupStyle: component.sidebarGroupStyle,
    );
    return Component.element(
      tag: 'div',
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?component.css]),
      attributes: component.componentAttributes,
      children: [
        SidebarItem(
          leading: component.leading,
          label: component.label,
          trailing: Icon(
            expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
            iconStyle: resolved.chevronIconStyle,
          ),
          attributes: {'aria-expanded': expanded ? 'true' : 'false'},
          onPressed: _handleToggle,
          sidebarItemStyle: resolved.itemStyle,
        ),
        Component.element(
          tag: 'div',
          classes: resolved.collapse.className,
          styles: resolved.collapse.inlineStyles,
          // A closed group's rows are out of reach for the keyboard and
          // for assistive technology, as on the Flutter twin.
          attributes: expanded ? null : const {'inert': ''},
          children: [
            Component.element(
              tag: 'div',
              classes: resolved.clip.className,
              children: [
                Component.element(
                  tag: 'div',
                  classes: resolved.nested.className,
                  styles: resolved.nested.inlineStyles,
                  children: [
                    Component.element(
                      tag: 'div',
                      classes: resolved.line.className,
                      styles: resolved.line.inlineStyles,
                      attributes: const {'aria-hidden': 'true'},
                      children: const [],
                    ),
                    ...component.children,
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
