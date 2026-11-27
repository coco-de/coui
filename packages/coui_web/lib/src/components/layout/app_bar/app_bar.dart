import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/surface_style_builder.dart';
import 'package:coui_web/src/base/surface_style_scope.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/app_bar/app_bar_side_measurer.dart';
import 'package:coui_web/src/components/layout/app_bar/app_bar_style.dart';
import 'package:coui_web/src/components/layout/bar_action/bar_action.dart';
import 'package:coui_web/src/components/layout/toolbar_group/toolbar_group.dart';
import 'package:coui_web/src/components/layout/toolbar_group/toolbar_group_internal.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// A unified cross-platform application bar for CoUI Web.
///
/// `AppBar` lays out a leading cluster, a centre area (`title` /
/// `header` / `subtitle`, or a custom `child`) and a trailing cluster —
/// as a single row (standard / compact / dense / prominent) or as a 48px
/// top row above a bottom-aligned large title (medium).
///
/// Every chrome / dimensional override flows through the single
/// [appBarStyle] field — see [CoreAppBarStyle] for the merge chain. The
/// semantic / behaviour fields ([variant] / [trailingExpanded] /
/// [centerTitle] / [showDivider] / [elevated] / [actionsAxis]) and the
/// composition slots stay flat on the component.
///
/// Mirrors Flutter `AppBar` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// AppBar(
///   leading: [Button(variant: .plain, child: Icon(LucideIcons.arrowLeft))],
///   title: const Text('Dashboard'),
///   trailing: [Button(variant: .plain, child: Icon(LucideIcons.settings))],
/// )
/// ```
///
/// surface:behind — floating app chrome sits above scrolling page content.
/// surface:functional — the bar groups navigation and actions above the page.
class AppBar extends UiComponent implements CoreAppBarContract<Component> {
  /// Creates a [AppBar].
  const AppBar({
    super.key,
    this.title,
    this.header,
    this.subtitle,
    this.child,
    this.leading = const [],
    this.trailing = const [],
    this.trailingExpanded = CoreAppBarContract.defaultTrailingExpanded,
    this.variant = CoreAppBarVariant.defaultVariant,
    this.centerTitle = CoreAppBarContract.defaultCenterTitle,
    this.showDivider = CoreAppBarContract.defaultShowDivider,
    this.elevated = CoreAppBarContract.defaultElevated,
    this.actionsAxis = CoreAppBarContract.defaultActionsAxis,
    this.appBarStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : assert(
         child == null || title == null,
         'Cannot provide both child and title',
       ),
       super(tag: 'div');

  /// The primary title content of the bar.
  @override
  final Component? title;

  /// Secondary content placed above the [title].
  @override
  final Component? header;

  /// Secondary content placed below the [title].
  @override
  final Component? subtitle;

  /// Custom centre content — overrides [title] / [header] / [subtitle].
  @override
  final Component? child;

  /// Components in the leading (start) cluster.
  @override
  final List<Component> leading;

  /// Components in the trailing (end) cluster.
  @override
  final List<Component> trailing;

  /// Whether the trailing cluster expands to fill remaining space.
  @override
  final bool trailingExpanded;

  /// Bar shape variant (standard / compact / medium / dense / prominent).
  @override
  final CoreAppBarVariant variant;

  /// Whether the title is centred instead of start-aligned.
  @override
  final bool centerTitle;

  /// Whether the bottom hairline divider is drawn.
  @override
  final bool showDivider;

  /// Whether the elevated drop shadow is drawn.
  @override
  final bool elevated;

  /// Where the bar's actions stand: in the bar's row (the default), or in
  /// a column beside the content.
  ///
  /// Under `vertical` the bar draws only the [leading] and [trailing]
  /// actions marked `BarAction(axisBehavior: horizontalOnly)`; a
  /// `ToolbarGroup(direction: vertical)` given the same two lists draws the
  /// rest. Enable Scaffold.adaptiveAppBarActions to let the scaffold
  /// detect a reserved right strip and host the column automatically.
  @override
  final CoreAxis actionsAxis;

  /// Per-instance chrome / dimensional style.
  @override
  final CoreAppBarStyle? appBarStyle;

  @override
  AppBar copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    Component? title,
    Component? header,
    Component? subtitle,
    List<Component>? leading,
    List<Component>? trailing,
    bool? trailingExpanded,
    CoreAppBarVariant? variant,
    bool? centerTitle,
    bool? showDivider,
    bool? elevated,
    CoreAxis? actionsAxis,
    CoreAppBarStyle? appBarStyle,
    Component? child,
  }) {
    return AppBar(
      key: key ?? this.key,
      title: title ?? this.title,
      header: header ?? this.header,
      subtitle: subtitle ?? this.subtitle,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      trailingExpanded: trailingExpanded ?? this.trailingExpanded,
      variant: variant ?? this.variant,
      centerTitle: centerTitle ?? this.centerTitle,
      showDivider: showDivider ?? this.showDivider,
      elevated: elevated ?? this.elevated,
      actionsAxis: actionsAxis ?? this.actionsAxis,
      appBarStyle: appBarStyle ?? this.appBarStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }

  @override
  Component build(BuildContext context) => SurfaceStyleBuilder(
    appBarScrollEdges: true,
    builder: _buildBar,
  );

  Component _buildBar(BuildContext context) {
    final currentChild = child;
    final resolved = resolveAppBar(
      context,
      variant: variant,
      hasCustomChild: currentChild != null,
      trailingExpanded: trailingExpanded,
      centerTitle: centerTitle,
      showDivider: showDivider,
      elevated: elevated,
      appBarStyle: appBarStyle,
    );

    final glass = resolved.actionCapsuleStyle != null;

    final titleLine = resolved.titleLine;
    final titleBlock = div(
      currentChild != null
          ? [currentChild]
          : [
              ?header,
              if (title case final title?)
                if (titleLine == null)
                  title
                else
                  div([title], classes: titleLine.className),
              ?subtitle,
            ],
      classes: resolved.titleWrapper.className,
      styles: resolved.titleWrapper.inlineStyles,
    );

    List<Component> cluster(List<Component> actions) {
      if (!glass) return actions;
      final groups = <Component>[];
      var pending = <Component>[];
      void flush() {
        if (pending.isEmpty) return;
        groups.add(
          ToolbarGroupSurface(
            popupStyle: resolved.actionCapsuleStyle,
            attributes: const {'data-coui-app-bar-actions': ''},
            children: pending,
          ),
        );
        pending = <Component>[];
      }

      for (final marked in actions) {
        final action = BarAction.actionOf(marked);
        if (action is ToolbarGroup) {
          flush();
          if (action.children.isNotEmpty) groups.add(action);
        } else {
          pending.add(action);
        }
      }
      flush();
      return groups;
    }

    // Once the actions stand in a column beside the content the bar keeps
    // only the ones that may not leave its row.
    List<Component> kept(List<Component> actions) {
      final result = <Component>[];
      for (final marked in actions) {
        if (CoreAppBarContract.keepsAction(
          BarAction.axisBehaviorOf(marked),
          actionsAxis: actionsAxis,
        )) {
          result.add(marked);
          continue;
        }
        final action = BarAction.actionOf(marked);
        if (action is ToolbarGroup) {
          final retained = kept(action.children);
          if (retained.isNotEmpty) {
            result.add(
              ToolbarGroup(
                key: action.key,
                ariaLabel: action.ariaLabel,
                direction: action.direction,
                popupStyle: action.popupStyle,
                children: retained,
              ),
            );
          }
        }
      }
      return result;
    }

    final barLeading = kept(leading);
    final barTrailing = kept(trailing);

    final leadingCluster = barLeading.isEmpty
        ? null
        : div(
            cluster(barLeading),
            classes: resolved.leadingCluster.className,
            attributes: const {'data-coui-app-bar-leading': ''},
            styles: resolved.leadingCluster.inlineStyles,
          );

    final trailingCluster = barTrailing.isEmpty
        ? null
        : div(
            cluster(barTrailing),
            classes: resolved.trailingCluster.className,
            attributes: const {'data-coui-app-bar-trailing': ''},
            styles: resolved.trailingCluster.inlineStyles,
          );

    final rootChildren = switch (variant) {
      // Two-row branch — 48px top row (leading / spacer / actions)
      // above the bottom-aligned large-title block.
      .medium => [
        div(
          [
            ?leadingCluster,
            div(const [], classes: resolved.topRowSpacer.className),
            ?trailingCluster,
          ],
          classes: resolved.topRow.className,
          styles: resolved.topRow.inlineStyles,
        ),
        titleBlock,
      ],
      // Single-row branch. A centred row also mounts the side measurer's
      // hidden anchor — `hidden` keeps it out of the grid.
      .standard || .compact || .dense || .prominent => [
        ?leadingCluster,
        titleBlock,
        ?trailingCluster,
        if (resolved.sideAnchor != null) const _AppBarSideSync(),
      ],
    };

    Component bar = div(
      [
        if (glass)
          const div(
            [],
            attributes: {
              'aria-hidden': 'true',
              'data-coui-app-bar-edge': '',
            },
            styles: Styles(
              raw: {
                'position': 'absolute',
                'inset': '0',
                'z-index': '-1',
                'pointer-events': 'none',
                'background':
                    'linear-gradient(to bottom, rgb(var(--coui-surface)), '
                    'transparent)',
                'opacity': 'var(--coui-app-bar-edge-opacity, 0)',
              },
            ),
          ),
        ...rootChildren,
      ],
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: {
        if (glass) ...{
          'data-coui-app-bar-glass': '',
          'data-coui-app-bar-edge-distance':
              '${CoreAppBarStyle.glassScrollEdgeDistance}',
        },
        ...componentAttributes,
      },
      events: events.isEmpty ? null : events,
    );
    if (glass) {
      bar = SurfaceStyleScope(
        surfaceStyle: resolved.actionCapsuleStyle!.surfaceStyle!,
        child: bar,
      );
    }
    return bar;
  }
}

/// Chain sugar mirroring the Flutter `AppBar.withStyle` extension —
/// merges a [CoreAppBarStyle] patch into [AppBar.appBarStyle] via the
/// existing [AppBar.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreAppBarStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreColors` primitive — the
/// getter *name* is the token name, so `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on. That
/// fixed name-to-value mapping is what makes a short getter safe to
/// reuse across components — a curated nickname (`.rounded`, `.compact`)
/// would silently map to a different value per component, but a
/// primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreAppBarStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with design)
/// is a follow-up once more components adopt this pattern.
///
/// ```dart
/// AppBar(title: text('Dashboard')).surface
/// ```
extension AppBarStyleChain on AppBar {
  /// Sets the content padding.
  AppBar contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreAppBarStyle(padding: value));

  /// Sets the background paint and preserves the other style fields.
  AppBar backgroundColor(CoreColor value) =>
      withStyle(CoreAppBarStyle(backgroundColor: value));

  /// Returns a copy of this [AppBar] with [patch] merged into
  /// [appBarStyle] (patch fields win on conflict).
  AppBar withStyle(CoreAppBarStyle patch) => copyWith(
    appBarStyle: (appBarStyle ?? const CoreAppBarStyle()).merge(patch),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  AppBar get primary => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  AppBar get secondary => withStyle(
    const CoreAppBarStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  AppBar get tertiary => withStyle(
    const CoreAppBarStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  AppBar get surface => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  AppBar get surfaceContainer => withStyle(
    const CoreAppBarStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  AppBar get error => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  AppBar get success => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  AppBar get warning => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  AppBar get info => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  AppBar get outline => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  AppBar get transparent => withStyle(
    const CoreAppBarStyle(backgroundColor: .transparent),
  );
}

var _appBarSideSyncCounter = 0;

/// Hidden anchor a centred single-row bar mounts as a child of its root.
/// On the client it attaches an [AppBarSideMeasurer] that writes the wider
/// cluster's width to the root (see `kAppBarSideVar`); on the server it is
/// an inert `hidden` element.
class _AppBarSideSync extends StatefulComponent {
  const _AppBarSideSync();

  @override
  State<_AppBarSideSync> createState() => _AppBarSideSyncState();
}

class _AppBarSideSyncState extends State<_AppBarSideSync> {
  late final String _anchorId = 'co-app-bar-side-${_appBarSideSyncCounter++}';
  AppBarSideMeasurer? _measurer;

  @override
  void dispose() {
    _measurer?.dispose();
    _measurer = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    if (kIsWeb) {
      scheduleMicrotask(() {
        if (!mounted) return;
        if (_measurer == null) {
          _measurer = AppBarSideMeasurer(anchorId: _anchorId)..attach();
        } else {
          _measurer!.refresh();
        }
      });
    }
    return Component.element(
      tag: 'span',
      id: _anchorId,
      attributes: const {'hidden': '', 'aria-hidden': 'true'},
    );
  }
}
