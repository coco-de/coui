import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/menu/menu/menu_glide_scope.dart';
import 'package:coui_web/src/util/element_scope.dart';

/// One interactive row of a menu — the surface `Menu`, `DropdownMenu`,
/// `ContextMenu`, `Menubar` and `Select` all place, drawn once here so the
/// five agree.
///
/// Anatomy, start to end: `[ mark ] [ leading ] [ label / description ]
/// [ shortcut | chevron ] [ trailing ]`, one
/// [CoreMenuItemStyle.contentGapStyle] between each seat. A [description]
/// makes the row grow past its minimum height and top-aligns the two
/// lines; [hasSubmenu] draws the chevron where the [shortcut] would sit.
///
/// Drawn as `Clickable` + `Text` + `Icon` + `Gap`, not as a `Button`: a
/// menu row's accessibility contract is different in kind — a disabled
/// row stays reachable by keyboard (inert, `aria-disabled`) and the role
/// is `menuitem`, not `button`. The row paints its own state layer, the
/// way `Command`'s rows do: the foreground washed over the fill at
/// [CoreMenuItemStyle.stateLayer]'s hover / focus / pressed weight.
///
/// ```dart
/// MenuItem(
///   label: const Text('Rename'),
///   shortcut: const Text('F2'),
///   leading: const Icon(LucideIcons.pencil),
///   onPressed: () {},
/// )
/// ```
///
/// The role and the tab stop are the enclosing menu's to state — it owns
/// roving focus and knows whether a row is a plain command, a checkbox or
/// a radio — and it states them through this component's `attributes`
/// passthrough. Standing alone, the row announces the generic
/// `menuitem`, which is what it is.
///
/// The Flutter `MenuItem` shares the same parameter names and order.
class MenuItem extends UiComponent implements CoreMenuItemContract<Component> {
  /// Creates a [MenuItem].
  const MenuItem({
    required this.label,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    this.size = CoreMenuItemSize.defaultSize,
    this.tone = CoreMenuItemTone.defaultTone,
    this.description,
    this.shortcut,
    this.leading,
    this.trailing,
    this.mark,
    this.reserveMark = false,
    this.hasSubmenu = false,
    this.selected = false,
    this.enabled,
    this.onPressed,
    this.menuItemStyle,
  }) : super(tag: 'div');

  @override
  final Component label;

  @override
  final CoreMenuItemSize size;

  @override
  final CoreMenuItemTone tone;

  @override
  final Component? description;

  @override
  final Component? shortcut;

  @override
  final Component? leading;

  @override
  final Component? trailing;

  @override
  final Component? mark;

  @override
  final bool reserveMark;

  @override
  final bool hasSubmenu;

  @override
  final bool selected;

  @override
  final bool? enabled;

  @override
  final void Function()? onPressed;

  @override
  final CoreMenuItemStyle? menuItemStyle;

  /// Whether the row accepts activation — the kit-wide rule: an explicit
  /// [enabled] wins, otherwise the presence of a handler decides.
  bool get _effectiveEnabled => enabled ?? (onPressed != null);

  @override
  MenuItem copyWith({
    Component? label,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    CoreMenuItemSize? size,
    CoreMenuItemTone? tone,
    Component? description,
    Component? shortcut,
    Component? leading,
    Component? trailing,
    Component? mark,
    bool? reserveMark,
    bool? hasSubmenu,
    bool? selected,
    bool? enabled,
    void Function()? onPressed,
    CoreMenuItemStyle? menuItemStyle,
  }) => MenuItem(
    label: label ?? this.label,
    attributes: attributes ?? componentAttributes,
    classes: classes ?? this.classes,
    css: css ?? this.css,
    eventHandlers: eventHandlers ?? this.eventHandlers,
    id: id ?? this.id,
    key: key ?? this.key,
    size: size ?? this.size,
    tone: tone ?? this.tone,
    description: description ?? this.description,
    shortcut: shortcut ?? this.shortcut,
    leading: leading ?? this.leading,
    trailing: trailing ?? this.trailing,
    mark: mark ?? this.mark,
    reserveMark: reserveMark ?? this.reserveMark,
    hasSubmenu: hasSubmenu ?? this.hasSubmenu,
    selected: selected ?? this.selected,
    enabled: enabled ?? this.enabled,
    onPressed: onPressed ?? this.onPressed,
    menuItemStyle: menuItemStyle ?? this.menuItemStyle,
  );

  @override
  Component build(BuildContext context) {
    final enabled = _effectiveEnabled;
    // Per-instance class the wash rules key on. A class rather than the
    // element id because the composed `Clickable` claims the id for its
    // own scoped rules whenever a caller overrides the focus ring.
    final scopeClass = elementScopeId(context, prefix: 'co-menu-item');
    final resolved = resolveMenuItem(
      context,
      scopeClass: scopeClass,
      size: size,
      tone: tone,
      selected: selected,
      enabled: enabled,
      reserveMark: reserveMark,
      menuItemStyle: menuItemStyle,
    );
    final rules = resolveMenuItemRules(
      context,
      scopeClass: scopeClass,
      tone: tone,
      selected: selected,
      enabled: enabled,
      // A row in a menu a finger may glide over also answers to the mark the
      // lit row carries; any other row keeps the rules it always had.
      glide: MenuGlideScope.maybeOf(context) != null,
      menuItemStyle: menuItemStyle,
    );

    final gap = Gap(gapStyle: resolved.contentGapStyle);
    // The chevron and the shortcut share one seat: a row that opens a
    // submenu has no shortcut to show, and showing both would put two
    // different promises in the same place.
    final trailingHint = hasSubmenu
        ? Icon(LucideIcons.chevronRight, iconStyle: resolved.chevronIconStyle)
        : (shortcut == null
              ? null
              : Component.element(
                  tag: 'div',
                  classes: resolved.shortcut.className,
                  styles: resolved.shortcut.inlineStyles,
                  children: [shortcut!],
                ));

    final seats = <Component>[
      if (rules.css.isNotEmpty)
        Component.element(tag: 'style', children: [RawText(rules.css)]),
      Component.element(
        tag: 'div',
        classes: resolved.wash.className,
        styles: resolved.wash.inlineStyles,
        children: const [],
      ),
      if (mark != null || reserveMark) ...[
        Component.element(
          tag: 'div',
          classes: resolved.markSeat.className,
          styles: resolved.markSeat.inlineStyles,
          children: [
            if (mark != null)
              IconTheme(
                data: IconThemeData(size: resolved.markIconStyle.size),
                child: mark!,
              ),
          ],
        ),
        gap,
      ],
      if (leading != null) ...[
        IconTheme(
          data: IconThemeData(size: resolved.leadingIconStyle.size),
          child: leading!,
        ),
        gap,
      ],
      Component.element(
        tag: 'div',
        classes: resolved.textColumn.className,
        styles: resolved.textColumn.inlineStyles,
        children: [
          Component.element(
            tag: 'div',
            classes: resolved.label.className,
            styles: resolved.label.inlineStyles,
            children: [label],
          ),
          if (description != null) ...[
            Gap(gapStyle: resolved.labelDescriptionGapStyle),
            Component.element(
              tag: 'div',
              classes: resolved.description.className,
              styles: resolved.description.inlineStyles,
              children: [description!],
            ),
          ],
        ],
      ),
      if (trailingHint != null) ...[gap, trailingHint],
      if (trailing != null) ...[gap, trailing!],
    ];

    return Clickable(
      attributes: {
        'role': CoreSemanticRole.menuItem.ariaRole,
        if (selected) 'aria-current': 'true',
        if (hasSubmenu) 'aria-haspopup': CoreSemanticRole.menu.ariaRole,
        if (!enabled) 'aria-disabled': 'true',
        // A disabled row keeps its tab stop: WAI-ARIA's menu pattern
        // keeps it reachable so a keyboard user can land on it and hear
        // why it does nothing. `Clickable` drops the stop when disabled
        // (right for a button), so the row states it back.
        if (!enabled) 'tabindex': '0',
        ...componentAttributes,
      },
      classes: rootClasses(resolved.root.className),
      // The row's own chrome rides in on `css`: `Clickable` composes its
      // resolved styles first and the caller's `css` after, so passing
      // the row box here is what puts the height, insets, fill and corner
      // over the generic clickable box instead of under it.
      css: Styles.combine([
        ?resolved.root.inlineStyles,
        ?this.css,
      ]),
      eventHandlers: eventHandlers,
      id: id,
      enabled: enabled,
      onPressed: onPressed,
      semanticsButton: false,
      clickableStyle: resolved.clickableStyle,
      child: Component.fragment(seats),
    );
  }
}

/// Chain sugar for merging a [CoreMenuItemStyle] patch into
/// [MenuItem.menuItemStyle] without hand-reconstructing every field.
/// Mirrors the Flutter `MenuItem.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMenuItemStyle.merge` right-side-wins semantics).
extension MenuItemStyleChain on MenuItem {
  /// Sets the background paint and preserves the other style fields.
  MenuItem backgroundColor(CoreColor value) =>
      withStyle(CoreMenuItemStyle(backgroundColor: value));

  /// Returns a copy of this [MenuItem] with [patch] merged into
  /// [menuItemStyle] (patch fields win on conflict).
  MenuItem withStyle(CoreMenuItemStyle patch) => copyWith(
    menuItemStyle: (menuItemStyle ?? const CoreMenuItemStyle()).merge(patch),
  );
}
