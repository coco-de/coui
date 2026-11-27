import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/navigation/sidebar/sidebar_style.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// An app's side navigation for CoUI Web — a fixed-width column at the
/// reading start of the screen that holds the app's identity, a search
/// trigger, the navigation rows, and at its foot help and the signed-in
/// person.
///
/// The sidebar frames regions; it draws no row of its own. Compose the rows
/// from `SidebarItem`, `SidebarSection` and `SidebarGroup`, the rail from
/// `SidebarRailItem`, and the identity from `SidebarHeader`.
///
/// [type] picks the shape — one panel (`standard`), an icon rail beside a
/// panel (`twoPane`), or the rail alone (`collapsed`). A long body scrolls;
/// the top and bottom regions stay put. Up and down arrows move focus
/// between the rows.
class Sidebar extends UiComponent implements CoreSidebarContract<Component> {
  /// Creates a [Sidebar].
  const Sidebar({
    super.key,
    this.type = CoreSidebarType.defaultType,
    this.header,
    this.search,
    this.panelTitle,
    this.panelAction,
    this.footer,
    this.help,
    this.user,
    this.railHeader,
    this.railItems = const [],
    this.railFooter,
    this.semanticLabel,
    this.sidebarStyle,
    this.children = const [],
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'nav');

  @override
  final CoreSidebarType type;

  @override
  final Component? header;

  @override
  final Component? search;

  @override
  final Component? panelTitle;

  @override
  final Component? panelAction;

  @override
  final Component? footer;

  @override
  final Component? help;

  @override
  final Component? user;

  @override
  final Component? railHeader;

  @override
  final List<Component> railItems;

  @override
  final Component? railFooter;

  @override
  final String? semanticLabel;

  @override
  final CoreSidebarStyle? sidebarStyle;

  @override
  final List<Component> children;

  @override
  Sidebar copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    CoreSidebarType? type,
    Component? header,
    Component? search,
    Component? panelTitle,
    Component? panelAction,
    Component? footer,
    Component? help,
    Component? user,
    Component? railHeader,
    List<Component>? railItems,
    Component? railFooter,
    String? semanticLabel,
    CoreSidebarStyle? sidebarStyle,
    List<Component>? children,
  }) {
    return Sidebar(
      key: key ?? this.key,
      type: type ?? this.type,
      header: header ?? this.header,
      search: search ?? this.search,
      panelTitle: panelTitle ?? this.panelTitle,
      panelAction: panelAction ?? this.panelAction,
      footer: footer ?? this.footer,
      help: help ?? this.help,
      user: user ?? this.user,
      railHeader: railHeader ?? this.railHeader,
      railItems: railItems ?? this.railItems,
      railFooter: railFooter ?? this.railFooter,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      sidebarStyle: sidebarStyle ?? this.sidebarStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers,
      children: children ?? this.children,
    );
  }

  /// Moves focus to the next or previous row on the up and down arrows —
  /// the Flutter twin binds the same two keys to its focus traversal.
  static void _handleKeyDown(web.KeyboardEvent event) {
    if (event.defaultPrevented) return;
    final int delta;
    switch (event.key) {
      case 'ArrowDown':
        delta = 1;
      case 'ArrowUp':
        delta = -1;
      default:
        return;
    }
    if (event.currentTarget case final web.HTMLElement root) {
      final rows = root.querySelectorAll(
        '[role="button"]:not([aria-disabled="true"]):not([inert] *)',
      );
      if (rows.length == 0) return;
      var current = -1;
      for (var i = 0; i < rows.length; i++) {
        if (rows.item(i) == web.document.activeElement) {
          current = i;
          break;
        }
      }
      if (current == -1) return;
      event.preventDefault();
      final next = (current + delta).clamp(0, rows.length - 1);
      if (rows.item(next) case final web.HTMLElement target) {
        target.focus();
      }
    }
  }

  Component _element(WebElementChrome slot, List<Component> children) =>
      Component.element(
        tag: 'div',
        classes: slot.className,
        styles: slot.inlineStyles,
        children: children,
      );

  @override
  Component build(BuildContext context) {
    final resolved = resolveSidebar(
      context,
      type: type,
      sidebarStyle: sidebarStyle,
    );

    Component? rail;
    if (type.hasRail) {
      rail = _element(
        resolved.rail,
        [
          if (railHeader != null) ...[
            railHeader!,
            Gap(gapStyle: resolved.railHeaderGapStyle),
          ],
          _element(
            resolved.railItems,
            railItems,
          ),
          ?railFooter,
        ],
      );
    }

    Component? panel;
    if (type.hasPanel) {
      final top = <Component>[
        ?header,
        if (panelTitle != null)
          _element(
            resolved.panelTitleRow,
            [
              // A real heading element — the panel's title outlines its rows.
              Component.element(
                tag: 'h2',
                classes: resolved.panelTitle.className,
                styles: resolved.panelTitle.inlineStyles,
                children: [panelTitle!],
              ),
              if (panelAction != null)
                _element(
                  resolved.panelAction,
                  [
                    IconTheme(
                      data: IconThemeData(
                        size: resolved.panelActionIconStyle.size,
                      ),
                      child: panelAction!,
                    ),
                  ],
                ),
            ],
          ),
        ?search,
      ];
      final bottom = <Component>[?footer, ?help, ?user];
      panel = _element(
        resolved.panel,
        [
          if (top.isNotEmpty)
            _element(
              resolved.top,
              top,
            ),
          _element(
            resolved.body,
            children,
          ),
          if (bottom.isNotEmpty)
            _element(
              resolved.bottom,
              bottom,
            ),
        ],
      );
    }

    return Component.element(
      tag: 'nav',
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: {
        'aria-label': ?semanticLabel,
        ...componentAttributes,
      },
      events: {
        ...events,
        'keydown': EventHandlers.chain(
          events['keydown'],
          EventHandlers.createKeyboardEventHandler(_handleKeyDown),
        ),
      },
      children: [?rail, ?panel],
    );
  }
}

/// Chain sugar mirroring the Flutter `Sidebar.withStyle` extension.
extension SidebarStyleChain on Sidebar {
  /// Sets the background paint and preserves the other style fields.
  Sidebar backgroundColor(CoreColor value) =>
      withStyle(CoreSidebarStyle(backgroundColor: value));

  /// Returns a copy with [patch] merged into [sidebarStyle] (patch fields
  /// win on conflict).
  Sidebar withStyle(CoreSidebarStyle patch) => copyWith(
    sidebarStyle: (sidebarStyle ?? const CoreSidebarStyle()).merge(patch),
  );
}
