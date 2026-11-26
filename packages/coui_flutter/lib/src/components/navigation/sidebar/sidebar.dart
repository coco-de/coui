import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

/// An app's side navigation — a fixed-width column at the reading start of
/// the screen that holds the app's identity, a search trigger, the
/// navigation rows, and at its foot help and the signed-in person.
///
/// The sidebar frames regions; it draws no row of its own. Compose the
/// rows from [SidebarItem], [SidebarSection] and [SidebarGroup], the rail
/// from [SidebarRailItem], and the identity from [SidebarHeader].
///
/// [type] picks the shape — one panel (`standard`), an icon rail beside a
/// panel (`twoPane`), or the rail alone (`collapsed`). A long body scrolls;
/// the top and bottom regions stay put. Up and down arrows move focus
/// between the rows.
///
/// ```dart
/// Sidebar(
///   header: SidebarHeader(title: const Text('나음 병원')),
///   search: SidebarSearch(placeholder: '검색', onPressed: () {}),
///   children: [
///     SidebarItem(
///       leading: const Icon(LucideIcons.house),
///       label: const Text('홈'),
///       selected: true,
///       onPressed: () {},
///     ),
///   ],
/// )
/// ```
class Sidebar extends StatelessWidget implements CoreSidebarContract<Widget> {
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
  });

  @override
  final CoreSidebarType type;

  @override
  final Widget? header;

  @override
  final Widget? search;

  @override
  final Widget? panelTitle;

  @override
  final Widget? panelAction;

  @override
  final Widget? footer;

  @override
  final Widget? help;

  @override
  final Widget? user;

  @override
  final Widget? railHeader;

  @override
  final List<Widget> railItems;

  @override
  final Widget? railFooter;

  @override
  final String? semanticLabel;

  @override
  final CoreSidebarStyle? sidebarStyle;

  @override
  final List<Widget> children;

  /// Returns a copy with the given fields replaced.
  Sidebar copyWith({
    Key? key,
    CoreSidebarType? type,
    Widget? header,
    Widget? search,
    Widget? panelTitle,
    Widget? panelAction,
    Widget? footer,
    Widget? help,
    Widget? user,
    Widget? railHeader,
    List<Widget>? railItems,
    Widget? railFooter,
    String? semanticLabel,
    CoreSidebarStyle? sidebarStyle,
    List<Widget>? children,
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
      children: children ?? this.children,
    );
  }

  Widget _buildRail(ResolvedSidebar resolved) {
    final railHeader = this.railHeader;
    final railFooter = this.railFooter;
    // The rail carries the line only when it is the outermost column — in
    // two-pane the panel beside it meets the page.
    final edged = type == .collapsed;
    return Container(
      width: resolved.railWidth,
      decoration: BoxDecoration(
        color: resolved.railBackgroundColor,
        border: edged
            ? BorderDirectional(
                end: BorderSide(
                  color: resolved.borderColor,
                  width: resolved.borderWidth,
                ),
              )
            : null,
      ),
      padding: resolved.railPadding,
      child: Column(
        spacing: resolved.railSpacing,
        children: [
          if (railHeader != null) ...[
            railHeader,
            Gap(gapStyle: resolved.railHeaderGapStyle),
          ],
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: resolved.railSpacing,
                children: railItems,
              ),
            ),
          ),
          ?railFooter,
        ],
      ),
    );
  }

  Widget _buildPanel(ResolvedSidebar resolved) {
    final header = this.header;
    final search = this.search;
    final panelTitle = this.panelTitle;
    final panelAction = this.panelAction;
    final footer = this.footer;
    final help = this.help;
    final user = this.user;

    final top = <Widget>[
      ?header,
      if (panelTitle != null)
        Padding(
          padding: resolved.panelTitlePadding,
          child: Row(
            spacing: resolved.panelTitleSpacing,
            children: [
              Expanded(
                child: DefaultTextStyle.merge(
                  style: resolved.panelTitleTextStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: Semantics(header: true, child: panelTitle),
                ),
              ),
              if (panelAction != null)
                IconTheme.merge(
                  data: resolved.panelActionIconTheme,
                  child: panelAction,
                ),
            ],
          ),
        ),
      ?search,
    ];
    final bottom = <Widget>[?footer, ?help, ?user];

    return Container(
      width: resolved.panelWidth,
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        border: BorderDirectional(
          end: BorderSide(
            color: resolved.borderColor,
            width: resolved.borderWidth,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          if (top.isNotEmpty)
            Padding(
              padding: resolved.topPadding,
              child: Column(
                crossAxisAlignment: .stretch,
                spacing: resolved.topSpacing,
                children: top,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: resolved.bodyPadding,
              child: Column(
                crossAxisAlignment: .stretch,
                spacing: resolved.bodySpacing,
                children: children,
              ),
            ),
          ),
          if (bottom.isNotEmpty)
            Padding(
              padding: resolved.bottomPadding,
              child: Column(
                crossAxisAlignment: .stretch,
                spacing: resolved.bottomSpacing,
                children: bottom,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSidebar(
      context,
      type: type,
      sidebarStyle: sidebarStyle,
    );
    return CoUISemantics(
      role: CoreSemanticRole.navigation,
      label: semanticLabel,
      child: Shortcuts(
        // Up and down move between the rows the way a menu's arrows do;
        // Tab still walks every focusable part in order.
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
        },
        child: FocusTraversalGroup(
          child: Row(
            crossAxisAlignment: .stretch,
            mainAxisSize: .min,
            children: [
              if (type.hasRail) _buildRail(resolved),
              if (type.hasPanel) _buildPanel(resolved),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreSidebarStyle] patch into
/// [Sidebar.sidebarStyle]. Mirrors the Web extension.
extension SidebarStyleChain on Sidebar {
  /// Returns a copy with [patch] merged into [sidebarStyle] (patch fields
  /// win on conflict).
  Sidebar withStyle(CoreSidebarStyle patch) => copyWith(
    sidebarStyle: (sidebarStyle ?? const CoreSidebarStyle()).merge(patch),
  );
}
