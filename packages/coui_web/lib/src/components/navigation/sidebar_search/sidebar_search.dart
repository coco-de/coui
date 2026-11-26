import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/kbd/kbd.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/navigation/sidebar_search/sidebar_search_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// A field-shaped trigger for the app's search at the top of a `Sidebar`
/// for CoUI Web — a search glyph, a placeholder, and the shortcut as a
/// composed [Kbd].
///
/// It is a button, not an input: pressing it hands off to the search
/// surface the app owns. The placeholder is its accessible name.
class SidebarSearch extends UiComponent
    implements CoreSidebarSearchContract<Component> {
  /// Creates a [SidebarSearch].
  const SidebarSearch({
    required this.placeholder,
    super.key,
    this.shortcut,
    this.onPressed,
    this.sidebarSearchStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final String placeholder;

  @override
  final List<String>? shortcut;

  @override
  final void Function()? onPressed;

  @override
  final CoreSidebarSearchStyle? sidebarSearchStyle;

  @override
  SidebarSearch copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? placeholder,
    List<String>? shortcut,
    void Function()? onPressed,
    CoreSidebarSearchStyle? sidebarSearchStyle,
  }) {
    return SidebarSearch(
      key: key ?? this.key,
      placeholder: placeholder ?? this.placeholder,
      shortcut: shortcut ?? this.shortcut,
      onPressed: onPressed ?? this.onPressed,
      sidebarSearchStyle: sidebarSearchStyle ?? this.sidebarSearchStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final enabled = onPressed != null;
    final scopeClass = elementScopeId(context, prefix: 'co-sidebar-search');
    final resolved = resolveSidebarSearch(
      context,
      sidebarSearchStyle: sidebarSearchStyle,
    );
    final rules = resolveSidebarSearchRules(
      context,
      scopeClass: scopeClass,
      enabled: enabled,
      sidebarSearchStyle: sidebarSearchStyle,
    );
    final keys = shortcut;

    return Clickable(
      attributes: {
        'aria-label': placeholder,
        if (keys != null && keys.isNotEmpty)
          'aria-keyshortcuts': keys.join('+'),
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
        Icon(LucideIcons.search, iconStyle: resolved.iconStyle),
        Component.element(
          tag: 'div',
          classes: resolved.placeholder.className,
          styles: resolved.placeholder.inlineStyles,
          attributes: const {'aria-hidden': 'true'},
          children: [Text(placeholder)],
        ),
        if (keys != null && keys.isNotEmpty)
          Kbd(
            keys: keys,
            kbdStyle: resolved.kbdStyle,
            attributes: const {'aria-hidden': 'true'},
          ),
      ]),
    );
  }
}

/// Chain sugar mirroring the Flutter `SidebarSearch.withStyle` extension.
extension SidebarSearchStyleChain on SidebarSearch {
  /// Returns a copy with [patch] merged into [sidebarSearchStyle] (patch
  /// fields win on conflict).
  SidebarSearch withStyle(CoreSidebarSearchStyle patch) => copyWith(
    sidebarSearchStyle: (sidebarSearchStyle ?? const CoreSidebarSearchStyle())
        .merge(patch),
  );
}
