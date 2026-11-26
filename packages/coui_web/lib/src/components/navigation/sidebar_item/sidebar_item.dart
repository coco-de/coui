import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/navigation/sidebar_item/sidebar_item_style.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// One destination in a `Sidebar` for CoUI Web — a glyph, a name, and at
/// its far end an optional unread dot, a count and a trailing glyph.
///
/// The current place ([selected]) draws a raised face and a heavier label
/// and states `aria-current="page"`; hover, focus and press lay a state
/// layer over the row. Every chrome override flows through
/// [sidebarItemStyle].
///
/// ```text
/// CoreSidebarItemStyle.defaultX → defaultsByLevel[level]
///   → CoreSidebarItemTheme.style
///   → CoreSidebarItemTheme.variantStyles[level]
///   → component.sidebarItemStyle
/// ```
class SidebarItem extends UiComponent
    implements CoreSidebarItemContract<Component> {
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
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component label;

  @override
  final Component? leading;

  @override
  final Component? count;

  @override
  final Component? trailing;

  @override
  final bool dot;

  @override
  final CoreSidebarItemLevel level;

  @override
  final bool selected;

  @override
  final bool? enabled;

  @override
  final void Function()? onPressed;

  @override
  final CoreSidebarItemStyle? sidebarItemStyle;

  bool get _effectiveEnabled => enabled ?? (onPressed != null);

  @override
  SidebarItem copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    Component? label,
    Component? leading,
    Component? count,
    Component? trailing,
    bool? dot,
    CoreSidebarItemLevel? level,
    bool? selected,
    bool? enabled,
    void Function()? onPressed,
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
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final enabled = _effectiveEnabled;
    // Disabled outranks selection.
    final current = enabled && selected;
    // Per-instance class the wash rules key on — a class, not the id: the
    // composed `Clickable` claims the id for its own rules whenever a
    // caller overrides the focus ring.
    final scopeClass = elementScopeId(context, prefix: 'co-sidebar-item');
    final resolved = resolveSidebarItem(
      context,
      level: level,
      selected: current,
      enabled: enabled,
      sidebarItemStyle: sidebarItemStyle,
    );
    final rules = resolveSidebarItemRules(
      context,
      scopeClass: scopeClass,
      level: level,
      enabled: enabled,
      sidebarItemStyle: sidebarItemStyle,
    );

    final seats = <Component>[
      if (rules.css.isNotEmpty)
        Component.element(tag: 'style', children: [RawText(rules.css)]),
      Component.element(
        tag: 'div',
        classes: resolved.wash.className,
        styles: resolved.wash.inlineStyles,
        children: const [],
      ),
      if (leading != null)
        IconTheme(
          data: IconThemeData(size: resolved.iconStyle.size),
          child: leading!,
        ),
      Component.element(
        tag: 'div',
        classes: resolved.label.className,
        styles: resolved.label.inlineStyles,
        children: [label],
      ),
      if (dot)
        Component.element(
          tag: 'span',
          classes: resolved.dot.className,
          styles: resolved.dot.inlineStyles,
          attributes: const {'aria-hidden': 'true'},
          children: const [],
        ),
      ?count,
      if (trailing != null)
        Component.element(
          tag: 'div',
          classes: resolved.trailing.className,
          styles: resolved.trailing.inlineStyles,
          children: [
            IconTheme(
              data: IconThemeData(size: resolved.trailingIconStyle.size),
              child: trailing!,
            ),
          ],
        ),
    ];

    return Clickable(
      attributes: {
        if (current) 'aria-current': 'page',
        if (!enabled) 'aria-disabled': 'true',
        ...componentAttributes,
      },
      classes: rootClasses('$scopeClass ${resolved.root.className}'),
      css: Styles.combine([?resolved.root.inlineStyles, ?css]),
      eventHandlers: eventHandlers,
      id: id,
      enabled: enabled,
      onPressed: onPressed,
      clickableStyle: resolved.clickableStyle,
      child: Component.fragment(seats),
    );
  }
}

/// Chain sugar mirroring the Flutter `SidebarItem.withStyle` extension.
extension SidebarItemStyleChain on SidebarItem {
  /// Returns a copy with [patch] merged into [sidebarItemStyle] (patch
  /// fields win on conflict).
  SidebarItem withStyle(CoreSidebarItemStyle patch) => copyWith(
    sidebarItemStyle: (sidebarItemStyle ?? const CoreSidebarItemStyle()).merge(
      patch,
    ),
  );
}
