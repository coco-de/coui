import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/surface_style_scope.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output — Scaffold
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Scaffold`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                              // outer scaffold container
///   ├─ loadingProgress (<div>)              // optional, absolute top progress wrapper
///   ├─ header (<div>) (× n)                 // shared chrome — one per `headers` entry
///   ├─ body (<div>)                         // body cell wrapper
///   │    └─ bodyInner (<div>)               // inner content wrapper (sidebar mode)
///   ├─ footer (<div>) (× m)                 // shared chrome — one per `footers` entry
///   └─ fab (<div>)                          // optional FAB wrapper
/// ```
///
/// All slot chromes are non-null — `co_scaffold` decides which optional
/// branches actually render based on instance state. The `header` /
/// `footer` slots carry the SHARED chrome (every section in
/// `headers` / `footers` shares the same chrome bundle since the
/// `floatingHeader` / `floatingFooter` flag applies to all of them).
class ResolvedScaffold implements WebResolvedChrome {
  /// Creates a [ResolvedScaffold].
  const ResolvedScaffold({
    required this.root,
    required this.loadingProgress,
    required this.header,
    required this.footer,
    required this.body,
    required this.bodyInner,
    required this.fab,
    this.appBarRail,
  });

  /// Paint-ready chrome for the scaffold root `<div>` —
  /// `min-h-screen flex flex-col relative` + optional `bg-${surface}`
  /// (suppressed when an inline body background override is supplied).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the loading-progress wrapper `<div>` —
  /// `absolute top-0 left-0 right-0 z-20` (sticky/fixed-header layer).
  /// `co_scaffold` skips emitting when neither `loadingProgress` nor
  /// `loadingProgressIndeterminate` is set.
  final WebElementChrome loadingProgress;

  /// Paint-ready chrome for each header section `<div>` —
  /// `flex flex-col w-full box-border border-b` plus optional
  /// `sticky top-0 z-20` when `floatingHeader`. The bottom-border width
  /// (a dimension) is always emitted inline as `border-bottom-width`
  /// (the bare `border-b` class supplies the `solid` style). The
  /// bottom-border colour (`border-b-{token}`) and background
  /// (`bg-{surface}`) flow through default token classes, each dropped
  /// in favour of an inline `border-bottom-color` / `background-color`
  /// only when overridden.
  final WebElementChrome header;

  /// Paint-ready chrome for each footer section `<div>` —
  /// `flex flex-col w-full box-border` plus optional
  /// `sticky bottom-0 z-20` when `floatingFooter`, and either
  /// `bg-${surface}` (when no override) or an inline `background-color`.
  final WebElementChrome footer;

  /// Paint-ready chrome for the body wrapper `<div>` — either
  /// `flex-1 flex flex-col min-w-0` (no sidebar) or
  /// `flex flex-1 min-h-0` (with sidebar, hosting `sidebar` +
  /// `bodyInner` as a row).
  final WebElementChrome body;

  /// Paint-ready chrome for the inner content wrapper `<div>` —
  /// `flex-1 flex flex-col min-w-0` (used as the sidebar-mode inner
  /// wrapper inside `body`).
  final WebElementChrome bodyInner;

  /// Paint-ready chrome for the FAB wrapper `<div>` — inline
  /// `position: absolute` plus the resolved FAB padding inset for the
  /// requested [CoreScaffoldFabLocation]. `co_scaffold` skips emitting
  /// when `floatingActionButton == null`.
  final WebElementChrome fab;

  /// The adaptive app-bar rail — `null` when the measured safe area has no
  /// room for one (or nothing was measured), so the bar renders as usual.
  final ResolvedScaffoldAppBarRail? appBarRail;
}

/// Paint-ready chrome for the adaptive app-bar rail of a `Scaffold`.
///
/// Exists only when the device reports a right safe-area inset wide enough
/// to seat the bar's actions (`CoreScaffoldContract.hasAppBarControlRail`).
///
/// ```text
/// (relative wrapper)
///   ├─ content                      // the bar, padded clear of the inset
///   └─ rail?                        // absolute column in the inset
/// ```
///
/// Every length is a browser CSS pixel — the measured safe area, the rail
/// width with the text scale already applied, and the edge clearances the
/// fit test adds to them — so all of it is emitted as measured lengths.
class ResolvedScaffoldAppBarRail {
  /// Creates a [ResolvedScaffoldAppBarRail].
  const ResolvedScaffoldAppBarRail({
    required this.content,
    this.rail,
    this.popupStyle,
  });

  /// The bar's wrapper — padded clear of the side safe area.
  final WebElementChrome content;

  /// The column the actions move into — `null` when the viewport is too
  /// short to hold it, so the actions stay on the bar.
  final WebElementChrome? rail;

  /// Optional capsule material and chrome unique to the vertical rail.
  final CorePopupStyle? popupStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — Scaffold entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedScaffold] for the given [context].
///
/// Merge chain (3-stage):
///
/// ```text
/// design-system default (per variant)
///   → theme.coreComponentTheme.scaffold.style
///   → theme.coreComponentTheme.scaffold.variantStyles[variant]
///   → widget.scaffoldStyle
/// ```
///
/// [hasSidebar] / [floatingHeader] / [floatingFooter] /
/// [fabLocation] are per-build flags baked into the matching slot.
/// [footerIsNavigationBar] says the footer is one `NavigationBar` and
/// nothing else — floating, that bar is the whole footer and the section
/// around it paints no face of its own.
///
/// [controlInsets] is the measured safe area (browser CSS pixels) and
/// [availableHeight] the viewport height; together they decide whether
/// [ResolvedScaffold.appBarRail] exists and whether its column fits.
ResolvedScaffold resolveScaffold(
  BuildContext context, {
  required CoreScaffoldVariant variant,
  required bool hasSidebar,
  required bool floatingHeader,
  required bool floatingFooter,
  required CoreScaffoldFabLocation fabLocation,
  bool footerIsNavigationBar = false,
  CoreEdgeInsets? controlInsets,
  double availableHeight = double.infinity,
  CoreScaffoldStyle? scaffoldStyle,
}) {
  final scaffoldTheme = context.theme.coreComponentTheme?.scaffold;
  final chrome = CoreScaffoldStyle.defaultsByVariant[variant]!;

  // 3-stage merge chain — theme.style → theme.variantStyles → component.
  final merged = resolveStyleChain(const CoreScaffoldStyle(), [
    scaffoldTheme?.style,
    scaffoldTheme?.variantStyles?[variant],
    scaffoldStyle,
  ]);

  final clearFloatingHeader =
      floatingHeader &&
      SurfaceStyleScope.of(context) == CoreSurfaceStyleId.liquidGlass &&
      merged.headerBackgroundColor == null;

  // A navigation bar that floats is the whole footer: it paints its own
  // face — edge to edge when docked in style, a detached capsule under a
  // floating one — and the body shows around it. The Flutter twin lays that
  // bar over the body with no section around it, so the section here keeps
  // its place and paints nothing; a face behind a capsule would be a band
  // the capsule sits on instead of the content it floats over.
  final bareFooter = floatingFooter && footerIsNavigationBar;

  // ─── Resolved chrome values ───────────────────────────
  final fabPadding = merged.fabPadding ?? CoreScaffoldStyle.defaultFabPadding;

  // ─── EMIT Stage 2 (Web, theme-free) — backgrounds ─────
  // Every background routes through the emit family — token defaults
  // (the per-variant `bg-{surface}` class) stay on classes (dark-mode
  // reactive), raw overrides go inline. No `scheme.resolve` (a no-op on
  // Web) and no hand-rolled `if (override != null)` branches.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    chrome.backgroundColor,
    .background,
  );
  final headerBackgroundEmit = emitColor(
    merged.headerBackgroundColor,
    chrome.headerBackgroundColor,
    .background,
  );
  final footerBackgroundEmit = emitColor(
    merged.footerBackgroundColor,
    chrome.footerBackgroundColor,
    .background,
  );

  // Header bottom-border colour — colour category. Default token class
  // (`border-b-{token}`) when no override, inline `border-bottom-color`
  // override otherwise (the `card` colour model). Bottom-specific class
  // prefix (`border-b-`) so `emitColor`'s all-side `border-` target does
  // not apply; the token name / inline value are taken straight off the
  // Core colour (`.toValue()` → token → `var(--coui-X)`, no
  // `scheme.resolve` no-op).
  final headerBorderColorCss = merged.headerBorderColor?.toValue();
  // Header bottom-border width — dimension category. Single inline
  // signature: `strokeWidthCss` is always emitted (no class-drop branch —
  // mirrors the Flutter resolver, which always applies
  // `merged.headerBorderWidth ?? default`). Fixed px (token →
  // `var(--coui-stroke-width-N)`, else `<px>px`) — never `rem`, so the
  // border thickness does not scale with the root font size.
  final headerBorderWidthCss = strokeWidthCss(
    merged.headerBorderWidth ?? CoreScaffoldStyle.defaultHeaderBorderWidth,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the scaffold root `<div>` chrome — full-viewport vertical
  /// flex layout with a relative positioning context for the loading
  /// progress / FAB overlays. The surface token class (carrying the
  /// per-variant default background) is suppressed when an inline
  /// background override is supplied — the `card` colour model.
  WebElementChrome buildRootChrome() {
    final parts = [
      // Flutter Scaffold 는 부모의 가용 영역을 채운다(제약 기반) —
      // 같은 의미로 가로는 w-full, 세로는 부모 기준 min-h-full.
      // (min-h-screen 은 뷰포트 기준이라 embed/부모가 더 작으면
      // footer 가 잘리고, w-full 이 없으면 센터링 flex 아래서
      // content 폭으로 쪼그라들어 Flutter 와 갈라진다. 화면 전체
      // 높이는 앱 루트(CoUIWeb 등)가 소유한다.)
      WebLayout.wFull,
      'min-h-full',
      WebLayout.flex,
      WebLayout.flexCol,
      WebLayout.relative,
      backgroundEmit.className,
    ];
    return WebElementChrome(
      className: parts.where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: backgroundEmit.inline == null
          ? null
          : Styles(raw: backgroundEmit.inline),
    );
  }

  /// Composes the loading-progress wrapper `<div>` chrome.
  WebElementChrome buildLoadingProgressChrome() => .new(
    className:
        '${WebLayout.absolute} ${WebLayout.topZero} ${WebLayout.leftZero} '
        '${WebLayout.rightZero} z-${CoreZIndex.scale.z20}',
  );

  /// Composes the header section `<div>` chrome (shared across all
  /// `headers` entries).
  ///
  /// The bare `border-b` class supplies the bottom border's
  /// `solid` style; the width is a dimension so its `rem` is always
  /// emitted inline (single inline signature — mirrors the Flutter
  /// resolver, which always applies `merged.headerBorderWidth ??
  /// default`). Bottom-border colour and the background are colours —
  /// the default token class (`border-b-{token}` / `bg-{surface}`) is
  /// added unless the caller overrides the field, in which case the
  /// class is dropped and the inline override wins (the `card` colour
  /// model).
  WebElementChrome buildHeaderChrome() {
    final parts = [
      WebLayout.flex,
      WebLayout.flexCol,
      WebLayout.wFull,
      'box-border',
      // Border style only — `border-b` sets `border-bottom-style: solid`
      // (the width is overridden inline below).
      if (!clearFloatingHeader) 'border-b',
      if (floatingHeader)
        '${WebLayout.sticky} ${WebLayout.topZero} z-${CoreZIndex.scale.z20}',
    ];
    if (!clearFloatingHeader && merged.headerBorderColor == null) {
      parts.add(
        'border-b-${CoreScaffoldStyle.defaultHeaderBorderColor.tailwindColor}',
      );
    }
    final headerBackgroundClass = headerBackgroundEmit.className;
    if (!clearFloatingHeader && headerBackgroundClass.isNotEmpty) {
      parts.add(headerBackgroundClass);
    }
    // Surface hook — the app bar is a surface, so a material preset
    // reaches it the same way it reaches a card. An opaque app bar above
    // translucent panels reads as the preset being broken.
    if (!clearFloatingHeader) {
      parts.addAll(webSurfaceMarkerFor(CoreSurfaceRole.functional));
    }
    final raw = {
      // Dimension — always inline (fixed px, never rem).
      'border-bottom-width': clearFloatingHeader ? '0' : headerBorderWidthCss,
      // The band reaches over the hairline on the bottom edge only — a header
      // that clears its border has no line to reach over.
      if (!clearFloatingHeader) ...surfaceBleedBottomVar(headerBorderWidthCss),
      if (clearFloatingHeader) 'background-color': 'transparent',
      // Colours — inline only when overridden (class carries the default).
      'border-bottom-color': ?headerBorderColorCss,
      ...?headerBackgroundEmit.inline,
      ...surfaceFillVar(
        merged.headerBackgroundColor ?? chrome.headerBackgroundColor,
      ),
    };
    return WebElementChrome(
      className: parts.where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: Styles(raw: raw),
    );
  }

  /// Composes the footer section `<div>` chrome (shared across all
  /// `footers` entries). Background follows the `card` colour model —
  /// the per-variant default `bg-{surface}` token class unless the
  /// caller overrides `footerBackgroundColor` (then inline wins).
  WebElementChrome buildFooterChrome() {
    final parts = [
      WebLayout.flex,
      WebLayout.flexCol,
      WebLayout.wFull,
      'box-border',
      if (floatingFooter)
        '${WebLayout.sticky} ${WebLayout.bottomZero} z-${CoreZIndex.scale.z20}',
      if (!bareFooter) footerBackgroundEmit.className,
    ];
    return WebElementChrome(
      className: parts.where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: bareFooter || footerBackgroundEmit.inline == null
          ? null
          : Styles(raw: footerBackgroundEmit.inline),
    );
  }

  /// Composes the body wrapper `<div>` chrome.
  WebElementChrome buildBodyChrome() {
    const innerClass =
        '${WebLayout.flex1} ${WebLayout.flex} ${WebLayout.flexCol} '
        '${WebLayout.minWZero}';
    return WebElementChrome(
      className: hasSidebar
          ? '${WebLayout.flex} ${WebLayout.flex1} ${WebLayout.minHZero}'
          : innerClass,
    );
  }

  /// Composes the inner content wrapper `<div>` chrome (sidebar mode).
  WebElementChrome buildBodyInnerChrome() => const .new(
    className:
        '${WebLayout.flex1} ${WebLayout.flex} ${WebLayout.flexCol} '
        '${WebLayout.minWZero}',
  );

  /// Composes the FAB wrapper `<div>` chrome.
  ///
  /// The offsets are the sides of `fabPadding`, a `CoreEdgeInsets` the
  /// Flutter twin converts through the theme geometry — a density moves
  /// them there, so they ride `spaceCss` here even though they land on
  /// position properties.
  WebElementChrome buildFabChrome() {
    final raw = {
      'position': 'absolute',
      'bottom': spaceCss(fabPadding.bottom),
    };
    switch (fabLocation) {
      case .endFloat:
        raw['right'] = spaceCss(fabPadding.right);
      case .startFloat:
        raw['left'] = spaceCss(fabPadding.left);
      case .centerFloat:
        raw['left'] = '50%';
        raw['transform'] = 'translateX(-50%)';
    }
    return WebElementChrome(
      className: '',
      inlineStyles: Styles(raw: raw),
    );
  }

  ResolvedScaffoldAppBarRail? buildAppBarRail() {
    final insets = controlInsets;
    if (insets == null) return null;
    final padding =
        merged.appBarRailPadding ?? CoreScaffoldStyle.defaultAppBarRailPadding;
    final railWidth =
        CoreToolbarGroupContract.glassVerticalActionMinSize *
        context.theme.textScaling;
    final left = insets.left > 0;
    final outerInset = left ? padding.left : padding.right;
    final contentInset = left ? insets.left : insets.right;
    if (!CoreScaffoldContract.hasAppBarControlRail(
      insets: insets,
      controlWidth: railWidth,
      outerInset: outerInset,
    )) {
      return null;
    }
    final fits =
        availableHeight >=
        padding.top + padding.bottom + insets.bottom + railWidth;
    return ResolvedScaffoldAppBarRail(
      popupStyle: merged.appBarRailPopupStyle,
      content: WebElementChrome(
        className: '',
        inlineStyles: Styles(
          raw: {
            // The safe area the rail occupies — not spacing, so the density
            // axis leaves it alone (the Flutter twin does the same).
            (left ? 'padding-left' : 'padding-right'): pinnedLengthCss(
              contentInset,
            ),
            'height': '100%',
            'box-sizing': 'border-box',
          },
        ),
      ),
      rail: fits
          ? WebElementChrome(
              className: '',
              inlineStyles: Styles(
                raw: {
                  'position': 'absolute',
                  'top': measuredLengthCss(padding.top),
                  (left ? 'left' : 'right'): measuredLengthCss(outerInset),
                  'bottom': measuredLengthCss(padding.bottom + insets.bottom),
                  'width': measuredLengthCss(railWidth),
                  'display': 'flex',
                  'flex-direction': 'column',
                  'align-items': 'stretch',
                  'overflow-y': 'auto',
                  'scrollbar-width': 'none',
                  'z-index': '${CoreZIndex.z10}',
                },
              ),
            )
          : null,
    );
  }

  return ResolvedScaffold(
    appBarRail: buildAppBarRail(),
    root: buildRootChrome(),
    loadingProgress: buildLoadingProgressChrome(),
    header: buildHeaderChrome(),
    footer: buildFooterChrome(),
    body: buildBodyChrome(),
    bodyInner: buildBodyInnerChrome(),
    fab: buildFabChrome(),
  );
}
