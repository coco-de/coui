import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/navigation/sidebar_header/sidebar_header_style.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// The identity row of a `Sidebar` for CoUI Web — a workspace with its logo
/// at the top, or the signed-in person with their avatar at the foot.
///
/// With [onPressed] the whole row opens a switcher; without it the row only
/// shows. `card` lifts the row onto a bordered `surface` tile.
class SidebarHeader extends UiComponent
    implements CoreSidebarHeaderContract<Component> {
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
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final CoreSidebarHeaderVariant variant;

  @override
  final Component? leading;

  @override
  final Component title;

  @override
  final Component? subtitle;

  @override
  final Component? trailing;

  @override
  final void Function()? onPressed;

  @override
  final CoreSidebarHeaderStyle? sidebarHeaderStyle;

  @override
  SidebarHeader copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    CoreSidebarHeaderVariant? variant,
    Component? leading,
    Component? title,
    Component? subtitle,
    Component? trailing,
    void Function()? onPressed,
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
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final pressable = onPressed != null;
    final scopeClass = elementScopeId(context, prefix: 'co-sidebar-header');
    final resolved = resolveSidebarHeader(
      context,
      variant: variant,
      sidebarHeaderStyle: sidebarHeaderStyle,
    );
    final rules = resolveSidebarHeaderRules(
      context,
      scopeClass: scopeClass,
      variant: variant,
      pressable: pressable,
      sidebarHeaderStyle: sidebarHeaderStyle,
    );

    final seats = <Component>[
      if (rules.css.isNotEmpty)
        Component.element(tag: 'style', children: [RawText(rules.css)]),
      if (pressable)
        Component.element(
          tag: 'div',
          classes: resolved.wash.className,
          styles: resolved.wash.inlineStyles,
          // The interaction wash is paint, not content.
          attributes: const {'aria-hidden': 'true'},
          children: const [],
        ),
      ?leading,
      Component.element(
        tag: 'div',
        classes: resolved.text.className,
        styles: resolved.text.inlineStyles,
        children: [
          Component.element(
            tag: 'div',
            classes: resolved.title.className,
            styles: resolved.title.inlineStyles,
            children: [title],
          ),
          if (subtitle != null)
            Component.element(
              tag: 'div',
              classes: resolved.subtitle.className,
              styles: resolved.subtitle.inlineStyles,
              children: [subtitle!],
            ),
        ],
      ),
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

    if (!pressable) {
      return Component.element(
        tag: 'div',
        id: id,
        classes: rootClasses(resolved.root.className),
        styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
        attributes: componentAttributes,
        events: events.isEmpty ? null : events,
        children: seats,
      );
    }
    return Clickable(
      attributes: componentAttributes,
      classes: rootClasses('$scopeClass ${resolved.root.className}'),
      css: Styles.combine([?resolved.root.inlineStyles, ?css]),
      eventHandlers: eventHandlers,
      id: id,
      onPressed: onPressed,
      clickableStyle: resolved.clickableStyle,
      child: Component.fragment(seats),
    );
  }
}

/// Chain sugar mirroring the Flutter `SidebarHeader.withStyle` extension.
extension SidebarHeaderStyleChain on SidebarHeader {
  /// Returns a copy with [patch] merged into [sidebarHeaderStyle] (patch
  /// fields win on conflict).
  SidebarHeader withStyle(CoreSidebarHeaderStyle patch) => copyWith(
    sidebarHeaderStyle: (sidebarHeaderStyle ?? const CoreSidebarHeaderStyle())
        .merge(patch),
  );
}
