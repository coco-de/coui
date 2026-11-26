import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/main_landmark_scope.dart';
import 'package:coui_web/src/base/surface_style_builder.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/progress/progress.dart';
import 'package:coui_web/src/components/layout/app_bar/app_bar.dart';
import 'package:coui_web/src/components/layout/app_bar/app_bar_style.dart';
import 'package:coui_web/src/components/layout/bar_action/bar_action.dart';
import 'package:coui_web/src/components/layout/scaffold/scaffold_control_insets.dart';
import 'package:coui_web/src/components/layout/scaffold/scaffold_style.dart';
import 'package:coui_web/src/components/layout/toolbar_group/toolbar_group.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// A unified cross-platform screen-layout scaffold for CoUI Web.
///
/// `Scaffold` provides the fundamental structure for a screen —
/// stacked header sections, a main content area and stacked footer
/// sections — plus an optional [sidebar], an optional
/// [floatingActionButton] and an optional loading-progress indicator.
///
/// Every chrome / dimensional override flows through the single
/// [scaffoldStyle] field — see [CoreScaffoldStyle] for the merge chain.
/// The semantic / behaviour fields (`headers` / `footers` / `child` /
/// `sidebar` / `variant` / `floatingActionButton` /
/// `floatingActionButtonLocation` / `floatingHeader` / `floatingFooter`
/// / `loadingProgress` / `loadingProgressIndeterminate`) stay flat on
/// the component.
///
/// Mirrors Flutter `Scaffold` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// Scaffold(
///   headers: [
///     AppBar(title: const Text('Dashboard')),
///   ],
///   child: div([const Text('Main content')]),
///   footers: [
///     AppBar(title: const Text('Status bar')),
///   ],
/// )
/// ```
///
/// surface:behind — the page surface itself, and its floating header / footer sections
/// have the body scrolling under them.
///
/// surface:functional — the page surface, whose header and footer sections
/// float over the body.
class Scaffold extends UiComponent implements CoreScaffoldContract<Component> {
  /// Creates a [Scaffold].
  const Scaffold({
    required this.child,
    super.key,
    this.headers = const [],
    this.adaptiveAppBarActions =
        CoreScaffoldContract.defaultAdaptiveAppBarActions,
    this.appBarControlInsets,
    this.footers = const [],
    this.sidebar,
    this.floatingActionButton,
    this.floatingActionButtonLocation = CoreScaffoldFabLocation.defaultLocation,
    this.floatingHeader = false,
    this.floatingFooter = false,
    this.loadingProgress,
    this.loadingProgressIndeterminate = false,
    this.mainLandmark = true,
    this.variant = CoreScaffoldVariant.defaultVariant,
    this.scaffoldStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final List<Component> headers;

  @override
  final bool adaptiveAppBarActions;

  @override
  final CoreEdgeInsets? appBarControlInsets;

  @override
  final List<Component> footers;

  @override
  final Component child;

  @override
  final Component? sidebar;

  @override
  final Component? floatingActionButton;

  @override
  final CoreScaffoldFabLocation floatingActionButtonLocation;

  @override
  final bool floatingHeader;

  @override
  final bool floatingFooter;

  @override
  final double? loadingProgress;

  @override
  final bool loadingProgressIndeterminate;

  /// Whether this scaffold may emit the `main` landmark for its body.
  ///
  /// Only the outermost scaffold emits it regardless (a nested one stays
  /// silent on its own), so this exists for the case that cannot be
  /// inferred: an outer shell the app knows is not the content region and
  /// wants the landmark to fall through to a scaffold nested inside.
  final bool mainLandmark;

  @override
  final CoreScaffoldVariant variant;

  @override
  final CoreScaffoldStyle? scaffoldStyle;

  @override
  Scaffold copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    List<Component>? headers,
    bool? adaptiveAppBarActions,
    CoreEdgeInsets? appBarControlInsets,
    List<Component>? footers,
    Component? sidebar,
    Component? floatingActionButton,
    CoreScaffoldFabLocation? floatingActionButtonLocation,
    bool? floatingHeader,
    bool? floatingFooter,
    double? loadingProgress,
    bool? loadingProgressIndeterminate,
    bool? mainLandmark,
    CoreScaffoldVariant? variant,
    CoreScaffoldStyle? scaffoldStyle,
    Component? child,
  }) {
    return Scaffold(
      key: key ?? this.key,
      headers: headers ?? this.headers,
      adaptiveAppBarActions:
          adaptiveAppBarActions ?? this.adaptiveAppBarActions,
      appBarControlInsets: appBarControlInsets ?? this.appBarControlInsets,
      footers: footers ?? this.footers,
      sidebar: sidebar ?? this.sidebar,
      floatingActionButton: floatingActionButton ?? this.floatingActionButton,
      floatingActionButtonLocation:
          floatingActionButtonLocation ?? this.floatingActionButtonLocation,
      floatingHeader: floatingHeader ?? this.floatingHeader,
      floatingFooter: floatingFooter ?? this.floatingFooter,
      loadingProgress: loadingProgress ?? this.loadingProgress,
      loadingProgressIndeterminate:
          loadingProgressIndeterminate ?? this.loadingProgressIndeterminate,
      mainLandmark: mainLandmark ?? this.mainLandmark,
      variant: variant ?? this.variant,
      scaffoldStyle: scaffoldStyle ?? this.scaffoldStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }

  Component? _adaptiveAppBar(
    BuildContext context,
    ResolvedScaffoldAppBarRail rail,
  ) {
    final index = headers.indexWhere((entry) => entry is AppBar);
    if (index < 0) return null;
    final bar = headers[index] as AppBar;
    final railChrome = rail.rail;
    final movedHeaders = [...headers];
    movedHeaders[index] = bar.copyWith(
      actionsAxis: railChrome != null ? CoreAxis.vertical : CoreAxis.horizontal,
    );
    final barStyle = resolveAppBar(
      context,
      variant: bar.variant,
      appBarStyle: bar.appBarStyle,
      hasCustomChild: bar.child != null,
      trailingExpanded: bar.trailingExpanded,
      centerTitle: bar.centerTitle,
      showDivider: bar.showDivider,
      elevated: bar.elevated,
    );
    final label = CouiLocalizations.of(context).navigationLabel;
    return div(
      [
        div(
          [
            copyWith(
              key: const Key('coui.app-bar-content'),
              adaptiveAppBarActions: false,
              headers: movedHeaders,
            ),
          ],
          classes: rail.content.className,
          styles: rail.content.inlineStyles,
        ),
        if (railChrome != null)
          div(
            [
              for (final actions in [bar.leading, bar.trailing])
                if (actions.any(
                  (action) => BarAction.axisBehaviorOf(
                    action,
                  ).allows(CoreAxis.vertical),
                ))
                  ToolbarGroup(
                    ariaLabel: label,
                    direction: CoreAxis.vertical,
                    popupStyle:
                        barStyle.actionCapsuleStyle ??
                        rail.popupStyle ??
                        CoreScaffoldStyle.defaultAppBarRailPopupStyle,
                    children: actions,
                  ),
            ],
            attributes: const {'data-coui-app-bar-rail': ''},
            classes: railChrome.className,
            styles: Styles.combine([
              ?railChrome.inlineStyles,
              ?barStyle.railGroup.inlineStyles,
            ]),
          ),
      ],
      styles: const Styles(
        raw: {'position': 'relative', 'height': '100%', 'min-height': '0'},
      ),
    );
  }

  bool get _hasLoading =>
      loadingProgress != null || loadingProgressIndeterminate;

  @override
  Component build(BuildContext context) => SurfaceStyleBuilder(
    builder: (context) {
      if (!adaptiveAppBarActions) return _buildScaffold(context);
      return ScaffoldControlInsets(
        builder: (context, insets, availableHeight) => _buildScaffold(
          context,
          controlInsets: appBarControlInsets ?? insets,
          availableHeight: availableHeight,
        ),
      );
    },
  );

  Component _buildScaffold(
    BuildContext context, {
    CoreEdgeInsets? controlInsets,
    double availableHeight = double.infinity,
  }) {
    final currentSidebar = sidebar;
    final hasSidebar = currentSidebar != null;
    final resolved = resolveScaffold(
      context,
      variant: variant,
      hasSidebar: hasSidebar,
      floatingHeader: floatingHeader,
      floatingFooter: floatingFooter,
      fabLocation: floatingActionButtonLocation,
      footerIsNavigationBar:
          footers.length == 1 && footers.single is NavigationBar,
      controlInsets: controlInsets,
      availableHeight: availableHeight,
      scaffoldStyle: scaffoldStyle,
    );

    if (resolved.appBarRail case final rail?) {
      final adaptive = _adaptiveAppBar(context, rail);
      if (adaptive != null) return adaptive;
    }

    final headerSection = headers.isEmpty
        ? null
        : div(
            headers,
            classes: resolved.header.className,
            styles: resolved.header.inlineStyles,
          );

    final footerSection = footers.isEmpty
        ? null
        : div(
            footers,
            classes: resolved.footer.className,
            styles: resolved.footer.inlineStyles,
          );

    // Body cell — the main content, optionally paired with a sidebar.
    //
    // The `main` landmark goes here rather than on the root: it is what
    // a screen-reader user jumps to in order to *skip* the header and
    // navigation, so a root that included them would make the jump land
    // where the reader already was.
    //
    // With a sidebar it goes on the inner cell, not the row that holds
    // both — the sidebar is navigation, not content.
    // Only the outermost scaffold emits it. A shell scaffold (app chrome +
    // routed content) with a page scaffold inside is an ordinary
    // composition, and a landmark per scaffold would nest `main` inside
    // `main` — invalid HTML, and it reads to a screen reader as two "main
    // content" regions.
    //
    // Outermost rather than innermost: `main` is the document's dominant
    // content and conventionally *contains* the page heading, the way
    // `<main>` wraps `<h1>`. The outer body already excludes the shell's
    // own header and navigation, so the jump skips the app chrome while
    // still landing on the page's title.
    //
    // `mainLandmark: false` opts a scaffold out for the case this cannot
    // infer — a shell the app knows is not the content region.
    final bodyIsMainLandmark =
        mainLandmark && !MainLandmarkScope.existsAbove(context);
    final mainAttrs = bodyIsMainLandmark
        ? {
            'role': CoreSemanticRole.main.ariaRole,
            'aria-label': CouiLocalizations.of(context).mainLabel,
          }
        : const <String, String>{};
    final Component body = hasSidebar
        ? div(
            [
              currentSidebar,
              div(
                [child],
                classes: resolved.bodyInner.className,
                styles: resolved.bodyInner.inlineStyles,
                attributes: mainAttrs,
              ),
            ],
            classes: resolved.body.className,
            styles: resolved.body.inlineStyles,
          )
        : div(
            [child],
            classes: resolved.body.className,
            styles: resolved.body.inlineStyles,
            attributes: mainAttrs,
          );

    final rootChildren = [
      // Loading progress indicator pinned to the very top.
      if (_hasLoading)
        div(
          [
            Progress(
              value: loadingProgressIndeterminate ? null : loadingProgress,
            ),
          ],
          classes: resolved.loadingProgress.className,
          styles: resolved.loadingProgress.inlineStyles,
        ),
      ?headerSection,
      body,
      ?footerSection,
      // Floating action button overlay.
      if (floatingActionButton != null)
        div(
          [floatingActionButton!],
          classes: resolved.fab.className,
          styles: resolved.fab.inlineStyles,
        ),
    ];

    final root = div(
      rootChildren,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: {
        'data-coui-scaffold': '',
        ...componentAttributes,
        'role': 'group',
        'aria-label': CouiLocalizations.of(context).scaffoldLabel,
      },
      events: events.isEmpty ? null : events,
    );

    // Publish the landmark downward only when this scaffold actually
    // emitted one — an opted-out scaffold must not stop a page scaffold
    // nested inside it from claiming `main`.
    return bodyIsMainLandmark ? MainLandmarkScope(child: root) : root;
  }
}

/// Chain sugar mirroring the Flutter `Scaffold.withStyle` extension —
/// merges a [CoreScaffoldStyle] patch into [Scaffold.scaffoldStyle] via
/// the existing [Scaffold.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreScaffoldStyle.merge` right-side-wins semantics).
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
/// sets [CoreScaffoldStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with design)
/// is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Scaffold(child: text('Body')).surface
/// ```
extension ScaffoldStyleChain on Scaffold {
  /// Returns a copy of this [Scaffold] with [patch] merged into
  /// [scaffoldStyle] (patch fields win on conflict).
  Scaffold withStyle(CoreScaffoldStyle patch) => copyWith(
    scaffoldStyle: (scaffoldStyle ?? const CoreScaffoldStyle()).merge(patch),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Scaffold get primary => withStyle(
    const CoreScaffoldStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Scaffold get secondary => withStyle(
    const CoreScaffoldStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Scaffold get tertiary => withStyle(
    const CoreScaffoldStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Scaffold get surface => withStyle(
    const CoreScaffoldStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Scaffold get surfaceContainer => withStyle(
    const CoreScaffoldStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Scaffold get error => withStyle(
    const CoreScaffoldStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Scaffold get success => withStyle(
    const CoreScaffoldStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Scaffold get warning => withStyle(
    const CoreScaffoldStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Scaffold get info => withStyle(
    const CoreScaffoldStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Scaffold get outline => withStyle(
    const CoreScaffoldStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Scaffold get transparent => withStyle(
    const CoreScaffoldStyle(backgroundColor: .transparent),
  );
}
