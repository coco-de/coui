import 'package:coui_flutter/coui_flutter.dart';

/// A unified cross-platform screen-layout scaffold.
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
/// the widget.
///
/// Mirrors Web `Scaffold` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// Scaffold(
///   headers: [
///     AppBar(title: const Text('Dashboard')),
///   ],
///   child: const Center(child: Text('Main content')),
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
class Scaffold extends StatelessWidget implements CoreScaffoldContract<Widget> {
  /// Creates a [Scaffold].
  const Scaffold({
    required this.child,
    this.headers = const [],
    bool? adaptiveAppBarActions,
    this.appBarControlInsets,
    this.footers = const [],
    this.sidebar,
    this.floatingActionButton,
    this.floatingActionButtonLocation = CoreScaffoldFabLocation.defaultLocation,
    this.floatingHeader = false,
    this.floatingFooter = false,
    this.loadingProgress,
    this.loadingProgressIndeterminate = false,
    this.resizeToAvoidBottomInset = true,
    this.mainLandmark = true,
    this.variant = CoreScaffoldVariant.defaultVariant,
    this.scaffoldStyle,
    super.key,
  }) : _adaptiveAppBarActions = adaptiveAppBarActions;

  @override
  final List<Widget> headers;

  final bool? _adaptiveAppBarActions;

  @override
  bool get adaptiveAppBarActions =>
      _adaptiveAppBarActions ??
      CoreScaffoldContract.defaultAdaptiveAppBarActions;

  @override
  final CoreEdgeInsets? appBarControlInsets;

  @override
  final List<Widget> footers;

  @override
  final Widget child;

  @override
  final Widget? sidebar;

  @override
  final Widget? floatingActionButton;

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

  /// Whether the scaffold content should resize to avoid the on-screen
  /// keyboard (IME) — mirrors Material `Scaffold.resizeToAvoidBottomInset`.
  ///
  /// When `true`, the header / body / footer stack (including floating
  /// overlays and the FAB) is padded by
  /// `MediaQuery.viewInsetsOf(context).bottom` so bottom-docked content
  /// (chat input bars, forms) stays visible above the soft keyboard and
  /// IME accessory strips (e.g. hardware-keyboard suggestion toolbars).
  /// The consumed inset is removed from the child `MediaQuery` so nested
  /// scaffolds do not double-apply it.
  ///
  /// Defaults to `true`, matching Material's own default and the Web
  /// twin: browsers resize the visual viewport for the IME with no way to
  /// opt out, so a Flutter default of `false` made the same code lift
  /// content above the keyboard on Web and hide it behind the keyboard on
  /// Flutter. Pass `false` for a screen that wants its content to extend
  /// behind the keyboard (full-bleed media, maps).
  ///
  /// Flutter-only parameter (not on the shared contract) precisely because
  /// Web has no counterpart to expose — the browser already does it.
  final bool resizeToAvoidBottomInset;

  /// Whether this scaffold may emit the `main` landmark for its body.
  ///
  /// Only the outermost scaffold emits it regardless (a nested one stays
  /// silent on its own), so this exists for the case that cannot be
  /// inferred: an outer shell the app knows is not the content region and
  /// wants the landmark to fall through to a scaffold nested inside.
  ///
  /// Flutter-only parameter (not on the shared contract).
  final bool mainLandmark;

  @override
  final CoreScaffoldVariant variant;

  @override
  final CoreScaffoldStyle? scaffoldStyle;

  /// Returns a copy of this [Scaffold] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Scaffold copyWith({
    Key? key,
    List<Widget>? headers,
    bool? adaptiveAppBarActions,
    CoreEdgeInsets? appBarControlInsets,
    List<Widget>? footers,
    Widget? sidebar,
    Widget? floatingActionButton,
    CoreScaffoldFabLocation? floatingActionButtonLocation,
    bool? floatingHeader,
    bool? floatingFooter,
    double? loadingProgress,
    bool? loadingProgressIndeterminate,
    bool? resizeToAvoidBottomInset,
    bool? mainLandmark,
    CoreScaffoldVariant? variant,
    CoreScaffoldStyle? scaffoldStyle,
    Widget? child,
  }) {
    return Scaffold(
      key: key ?? this.key,
      headers: headers ?? this.headers,
      adaptiveAppBarActions: adaptiveAppBarActions ?? _adaptiveAppBarActions,
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
      resizeToAvoidBottomInset:
          resizeToAvoidBottomInset ?? this.resizeToAvoidBottomInset,
      mainLandmark: mainLandmark ?? this.mainLandmark,
      variant: variant ?? this.variant,
      scaffoldStyle: scaffoldStyle ?? this.scaffoldStyle,
      child: child ?? this.child,
    );
  }

  Widget? _adaptiveAppBar(BuildContext context, ResolvedScaffold resolved) {
    final index = headers.indexWhere((header) => header is AppBar);
    if (index < 0) return null;
    final bar = headers[index] as AppBar;
    final media = MediaQuery.of(context);
    final panePadding = appBarControlInsets == null
        ? NavigationPanePadding.maybeOf(context)
        : null;
    final view = panePadding ?? media.viewPadding;
    final insets =
        appBarControlInsets ??
        CoreEdgeInsets.fromLTRB(view.left, view.top, view.right, view.bottom);
    final padding = resolved.appBarRailPadding;
    final left = insets.left > 0;
    final hasRail = CoreScaffoldContract.hasAppBarControlRail(
      insets: insets,
      controlWidth: resolved.appBarRailWidth,
      outerInset: left ? padding.left : padding.right,
    );
    final contentInset = EdgeInsets.only(
      left: hasRail && panePadding == null ? insets.left : media.padding.left,
      right: hasRail && panePadding == null
          ? insets.right
          : media.padding.right,
    );
    final contentMedia = hasRail
        ? media.copyWith(
            padding: media.padding.copyWith(left: 0, right: 0),
            viewPadding: media.viewPadding.copyWith(left: 0, right: 0),
          )
        : media.removePadding(removeLeft: true, removeRight: true);
    final barStyle = resolveAppBar(
      context,
      variant: bar.variant,
      appBarStyle: bar.appBarStyle,
    );
    final label = CoUILocalizations.of(context).navigationLabel;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottom =
            padding.bottom +
            insets.bottom +
            (resizeToAvoidBottomInset ? media.viewInsets.bottom : 0);
        final fits =
            hasRail &&
            constraints.maxHeight >=
                padding.top + bottom + resolved.appBarRailWidth;
        final movedHeaders = [...headers];
        movedHeaders[index] = bar.copyWith(
          actionsAxis: fits ? CoreAxis.vertical : CoreAxis.horizontal,
        );
        final rail = Position(
          top: padding.top,
          left: left ? padding.left : null,
          right: left ? null : padding.right,
          bottom: bottom,
          width: resolved.appBarRailWidth,
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              primary: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: barStyle.spacing,
                children: [
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
                            resolved.appBarRailPopupStyle ??
                            CoreScaffoldStyle.defaultAppBarRailPopupStyle,
                        children: actions,
                      ),
                ],
              ),
            ),
          ),
        );
        return ColoredBox(
          color: resolved.backgroundColor,
          child: Stacks(
            fit: CoreStackFit.expand,
            children: [
              Padding(
                padding: contentInset,
                child: MediaQuery(
                  data: contentMedia,
                  child: copyWith(
                    key: const Key('coui.app-bar-content'),
                    adaptiveAppBarActions: false,
                    headers: movedHeaders,
                  ),
                ),
              ),
              if (fits)
                if (panePadding == null)
                  rail
                else if (ModalRoute.isCurrentOf(context) != false &&
                    TickerMode.valuesOf(context).enabled)
                  _PaneAppBarRail(
                    child: MediaQuery(
                      data: media.copyWith(viewPadding: panePadding),
                      child: Stacks(fit: CoreStackFit.expand, children: [rail]),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  bool get _hasLoading =>
      loadingProgress != null || loadingProgressIndeterminate;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveScaffold(
      context,
      variant: variant,
      scaffoldStyle: scaffoldStyle,
      floatingHeader: floatingHeader,
    );

    final adaptiveInPane =
        _adaptiveAppBarActions == null &&
        NavigationPanePadding.maybeOf(context) != null;
    if (adaptiveAppBarActions || adaptiveInPane) {
      final adaptive = _adaptiveAppBar(context, resolved);
      if (adaptive != null) return adaptive;
    }

    // The material wraps the section from outside rather than living in
    // `_ScaffoldSection`, because that type serves the footer too and the
    // footer is not a surface — Web marks the header alone.
    final headerSection = headers.isEmpty
        ? null
        : !resolved.ownsHeaderMaterial ||
              (floatingHeader &&
                  headers.length == 1 &&
                  headers.single is AppBar)
        ? SafeArea(
            bottom: false,
            child: Column(mainAxisSize: .min, children: headers),
          )
        : _withSurfaceMaterial(
            context,
            resolved,
            _ScaffoldSection(
              backgroundColor: resolved.headerBackgroundColor,
              borderColor: resolved.headerBorderColor,
              borderWidth: resolved.headerBorderWidth,
              applyTopSafeArea: true,
              children: headers,
            ),
          );

    final footerSection = footers.isEmpty
        ? null
        : floatingFooter &&
              footers.length == 1 &&
              footers.single is NavigationBar
        ? footers.single
        : _ScaffoldSection(
            backgroundColor: resolved.footerBackgroundColor,
            children: footers,
          );

    // Body cell — the main content, optionally paired with a sidebar.
    //
    // The `main` landmark wraps the content and not the scaffold root:
    // it is what a screen-reader user jumps to in order to *skip* the
    // header and navigation, so a root that included them would make the
    // jump land where the reader already was. With a sidebar it stays on
    // the content, outside the row — a sidebar is navigation.
    //
    // Only the outermost scaffold emits it. A shell scaffold (app chrome +
    // routed content) with a page scaffold inside is an ordinary
    // composition, and a landmark per scaffold would nest `main` inside
    // `main` — which the framework rejects outright, and which reads to a
    // screen reader as two "main content" regions.
    //
    // Outermost rather than innermost: `main` is the document's dominant
    // content and conventionally *contains* the page heading, the way
    // `<main>` wraps `<h1>` on the web. The outer body already excludes
    // the shell's own header and navigation, so the jump skips the app
    // chrome while still landing on the page's title.
    //
    // `mainLandmark: false` opts a scaffold out for the cases this cannot
    // infer — a shell the app knows is not the content region.
    final bodyIsMainLandmark =
        mainLandmark && !_MainLandmarkScope.existsAbove(context);
    var body = bodyIsMainLandmark
        ? CoUISemantics(
            role: .main,
            label: CoUILocalizations.of(context).mainLabel,
            container: true,
            child: child,
          )
        : child;
    final currentSidebar = sidebar;
    if (currentSidebar != null) {
      body = Row(
        crossAxisAlignment: .stretch,
        children: [
          currentSidebar,
          Expanded(child: body),
        ],
      );
    }

    // The fixed vertical stack — header (non-floating) + body + footer
    // (non-floating).
    final columnChildren = <Widget>[
      if (headerSection != null && !floatingHeader) headerSection,
      Expanded(child: body),
      if (footerSection != null && !floatingFooter) footerSection,
    ];

    Widget content = Column(
      crossAxisAlignment: .stretch,
      children: columnChildren,
    );

    // Floating header / footer overlay above the body.
    if ((headerSection != null && floatingHeader) ||
        (footerSection != null && floatingFooter)) {
      content = Stacks(
        children: [
          content,
          if (headerSection != null && floatingHeader)
            Position(
              top: 0,
              right: 0,
              left: 0,
              child: headerSection,
            ),
          if (footerSection != null && floatingFooter)
            Position(
              right: 0,
              bottom: 0,
              left: 0,
              child: footerSection,
            ),
        ],
      );
    }

    // Loading progress indicator pinned to the very top.
    if (_hasLoading) {
      content = Stacks(
        children: [
          content,
          Position(
            top: 0,
            right: 0,
            left: 0,
            child: Progress(
              value: loadingProgressIndeterminate ? null : loadingProgress,
            ),
          ),
        ],
      );
    }

    // Floating action button overlay.
    final fab = floatingActionButton;
    if (fab != null) {
      content = Stacks(
        children: [
          content,
          Position.fill(
            child: Align(
              alignment: alignmentForFabLocation(
                floatingActionButtonLocation,
              ),
              child: Padding(
                padding: resolved.fabPadding,
                child: fab,
              ),
            ),
          ),
        ],
      );
    }

    // IME(keyboard) inset avoidance — pad the whole stack by the bottom
    // view inset and strip it from the child MediaQuery (Material
    // `resizeToAvoidBottomInset` parity; strip prevents nested scaffolds
    // from double-applying). Plain Padding suffices for smooth motion:
    // the platform reports progressive viewInsets during the IME
    // animation, so the padding follows frame-by-frame.
    //
    // The wrap is gated on the parameter and never on the inset value.
    // Skipping it while the inset is zero would look like a free
    // optimisation and would instead change the tree's depth the moment
    // the keyboard opens, re-inflating everything below and dropping the
    // state of whatever the user was typing into.
    if (resizeToAvoidBottomInset) {
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      content = Padding(
        padding: .only(bottom: bottomInset),
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: content,
        ),
      );
    }

    // Web twin: role="group" + aria-label.
    Widget scaffold = Semantics(
      container: true,
      label: CoUILocalizations.of(context).scaffoldLabel,
      child: ColoredBox(
        color: resolved.backgroundColor,
        // The chrome around the body hears the body scroll from here — a
        // bar that follows the content (`NavigationBar.compact`) is the
        // body's sibling, so only an ancestor of both can tell it. Always
        // in the tree, so chrome that starts following does not change the
        // tree's depth under the body.
        child: ScrollNotificationObserver(child: content),
      ),
    );

    // Publish the landmark downward only when this scaffold actually
    // emitted one — an opted-out scaffold must not stop a page scaffold
    // nested inside it from claiming `main`.
    if (bodyIsMainLandmark) {
      scaffold = _MainLandmarkScope(child: scaffold);
    }

    return scaffold;
  }
}

/// Marks a subtree as already carrying the `main` landmark.
///
/// [Scaffold] publishes it when it emits the landmark, and every scaffold
/// nested inside reads it and stays silent. Without this each scaffold in
/// a shell-plus-page composition would emit its own, nesting `main` inside
/// `main`.
class _MainLandmarkScope extends InheritedWidget {
  const _MainLandmarkScope({required super.child});

  /// Whether an enclosing [Scaffold] already emitted the landmark.
  static bool existsAbove(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MainLandmarkScope>() != null;

  @override
  bool updateShouldNotify(_MainLandmarkScope oldWidget) => false;
}

/// Chain sugar for merging a [CoreScaffoldStyle] patch into
/// [Scaffold.scaffoldStyle] without hand-reconstructing every field.
/// Mirrors the Web `Scaffold.withStyle` extension so both platforms read
/// identically.
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
/// Scaffold(child: Text('Body')).surface
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

/// A stacked header / footer section with its own background and an
/// optional bottom border.
/// Wraps [child] in the active surface style's material, or returns it
/// unchanged when the style states none.
///
/// No `borderRadius`: the header is square, and `SurfaceBlur` already
/// treats a missing radius as zero.
Widget _withSurfaceMaterial(
  BuildContext context,
  ResolvedScaffold resolved,
  Widget child,
) {
  final blur = resolved.surfaceBlur;
  if ((blur == null || blur <= 0) && resolved.surfaceSheen == null) {
    return child;
  }

  return SurfaceBlur(
    surfaceBlur: blur,
    surfaceSaturation: resolved.surfaceSaturation,
    surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
    surfaceSheen: resolved.surfaceSheen,
    // The active material's bend. Every surface that draws the material
    // draws all of it — the frost and the chroma without the bend is a
    // blurred panel, not glass, and the bend is the term the material
    // is named for.
    //
    // Falls back rather than being required: a style that states no
    // refraction leaves this null and the surface simply does not
    // bend, which is how every preset but glass renders.
    refraction: Theme.of(context).surfaceRefraction,
    child: child,
  );
}

class _ScaffoldSection extends StatelessWidget {
  const _ScaffoldSection({
    required this.backgroundColor,
    required this.children,
    this.borderColor,
    this.borderWidth,
    this.applyTopSafeArea = false,
  });

  final Color backgroundColor;
  final Color? borderColor;
  final double? borderWidth;

  /// Whether to inset the section below the system status bar / notch.
  ///
  /// Set for the header section only (Material `AppBar.primary` parity):
  /// without it the first header sits at y=0 and is overlapped by the
  /// status bar on notched devices.
  ///
  /// Nesting is safe. [SafeArea] strips the padding it consumes from the
  /// child [MediaQuery], so a scaffold rendered inside an outer [SafeArea]
  /// (a shell route, a split pane) sees `padding.top == 0` and this becomes
  /// a no-op — the inset is never applied twice.
  ///
  /// Only the top edge is inset. Horizontal insets would pull header
  /// content away from the display cutout in landscape, which reads as
  /// stray side margins rather than a fix; the bottom edge belongs to the
  /// body / footer.
  final bool applyTopSafeArea;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final currentBorderColor = borderColor;
    final currentBorderWidth = borderWidth;
    final BoxBorder? border =
        currentBorderColor != null && currentBorderWidth != null
        ? Border(
            bottom: .new(
              color: currentBorderColor,
              width: currentBorderWidth,
            ),
          )
        : null;

    Widget section = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: children,
    );

    // Inside the DecoratedBox so the section background fills the status
    // bar strip too — otherwise the inset would expose the scaffold
    // background as a mismatched band above the header.
    if (applyTopSafeArea) {
      section = SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: section,
      );
    }

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(color: backgroundColor, border: border),
        child: section,
      ),
    );
  }
}

/// Paints a panel's actions in the screen's already-reserved control strip.
class _PaneAppBarRail extends StatefulWidget {
  const _PaneAppBarRail({required this.child});

  final Widget child;

  @override
  State<_PaneAppBarRail> createState() => _PaneAppBarRailState();
}

class _PaneAppBarRailState extends State<_PaneAppBarRail> {
  final _portal = OverlayPortalController()..show();

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayLocation: OverlayChildLocation.rootOverlay,
    overlayChildBuilder: (_) => widget.child,
    child: const SizedBox.expand(),
  );
}
