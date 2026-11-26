import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/navigation/sidebar_rail_item/sidebar_rail_item_style.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// One destination in a `Sidebar`'s icon rail for CoUI Web — a glyph alone
/// in a square.
///
/// It has no visible label: [label] is its accessible name and its tooltip.
/// The current place ([selected]) draws a raised face and states
/// `aria-current="page"`.
class SidebarRailItem extends UiComponent
    implements CoreSidebarRailItemContract<Component> {
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
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component icon;

  @override
  final String label;

  @override
  final bool dot;

  @override
  final bool selected;

  @override
  final bool? enabled;

  @override
  final void Function()? onPressed;

  @override
  final CoreSidebarRailItemStyle? sidebarRailItemStyle;

  bool get _effectiveEnabled => enabled ?? (onPressed != null);

  @override
  SidebarRailItem copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    Component? icon,
    String? label,
    bool? dot,
    bool? selected,
    bool? enabled,
    void Function()? onPressed,
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
    final current = enabled && selected;
    final scopeClass = elementScopeId(context, prefix: 'co-sidebar-rail-item');
    final resolved = resolveSidebarRailItem(
      context,
      selected: current,
      enabled: enabled,
      sidebarRailItemStyle: sidebarRailItemStyle,
    );
    final rules = resolveSidebarRailItemRules(
      context,
      scopeClass: scopeClass,
      enabled: enabled,
      sidebarRailItemStyle: sidebarRailItemStyle,
    );

    return Tooltip(
      message: label,
      position: CoreTooltipPosition.right,
      child: Clickable(
        attributes: {
          'aria-label': label,
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
        child: Component.fragment([
          if (rules.css.isNotEmpty)
            Component.element(tag: 'style', children: [RawText(rules.css)]),
          Component.element(
            tag: 'div',
            classes: resolved.wash.className,
            styles: resolved.wash.inlineStyles,
            children: const [],
          ),
          IconTheme(
            data: IconThemeData(size: resolved.iconStyle.size),
            child: icon,
          ),
          if (dot)
            Component.element(
              tag: 'span',
              classes: resolved.dot.className,
              styles: resolved.dot.inlineStyles,
              attributes: const {'aria-hidden': 'true'},
              children: const [],
            ),
        ]),
      ),
    );
  }
}

/// Chain sugar mirroring the Flutter `SidebarRailItem.withStyle` extension.
extension SidebarRailItemStyleChain on SidebarRailItem {
  /// Returns a copy with [patch] merged into [sidebarRailItemStyle] (patch
  /// fields win on conflict).
  SidebarRailItem withStyle(CoreSidebarRailItemStyle patch) => copyWith(
    sidebarRailItemStyle:
        (sidebarRailItemStyle ?? const CoreSidebarRailItemStyle()).merge(
          patch,
        ),
  );
}
