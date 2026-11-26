import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/surface_style_scope.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output — AppBar
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `AppBar`.
///
/// DOM shape (`app_bar.dart` decides which optional branches render —
/// the medium variant uses the two-row branch, standard / compact /
/// dense / prominent the single-row branch):
///
/// ```text
/// root (<div>)                              // bar surface — bg / divider / shadow / height
///   ├─ topRow (<div>)                       // medium only — 48px leading + actions row
///   │    ├─ leadingCluster (<div>)          // optional — leading cluster row
///   │    ├─ topRowSpacer (<div>)            // flex-1 filler (mirrors Flutter `Spacer`)
///   │    └─ trailingCluster (<div>)         // optional — trailing action cluster row
///   ├─ leadingCluster (<div>)               // single-row variants — leading cluster row
///   ├─ titleWrapper (<div>)                 // header / title / subtitle column (or `child`)
///   │    └─ titleLine (<div>)               // centred single row only — the one-line title
///   ├─ trailingCluster (<div>)              // single-row variants — trailing cluster row
///   └─ sideAnchor (<span hidden>)           // centred single row only — side measurer anchor
/// ```
///
/// A centred single row (`centerTitle` without `trailingExpanded`) is a
/// three-column grid instead of a flex row: leading · title · trailing in
/// columns 1 · 2 · 3, the side columns held at one width (the wider
/// cluster's) so the title sits on the centre of the whole bar.
///
/// `app_bar.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion in
/// the widget body.
class ResolvedAppBar implements WebResolvedChrome {
  /// Creates a [ResolvedAppBar].
  const ResolvedAppBar({
    required this.root,
    required this.topRow,
    required this.topRowSpacer,
    required this.leadingCluster,
    required this.titleWrapper,
    required this.trailingCluster,
    @Deprecated(
      'Pass railGroup (since 0.190) — the rail column takes the gap as '
      'chrome.',
    )
    required this.railGroupSpacing,
    this.railGroup = const WebElementChrome(className: ''),
    this.actionCapsuleStyle,
    this.titleLine,
    this.sideAnchor,
  });

  /// Paint-ready chrome for the bar root `<div>` — the bar surface.
  /// Single-row (standard / compact / dense / prominent: `flex flex-row items-center` +
  /// inline `gap` and the bar padding — or, for a centred title,
  /// `grid items-center` with the three-column template inline) or two-row
  /// column (medium: `flex flex-col`, padding / gap live on [topRow]
  /// instead). Carries
  /// the background (token class or inline override), the fixed bar
  /// height (`h-size{N}` class for the variant default, inline `rem`
  /// override), the bottom hairline (`border-b` + colour class / inline
  /// + px-fixed `border-bottom-width`) while `showDivider`, and the
  /// elevated `box-shadow` while `elevated`.
  @override
  final WebElementChrome root;

  /// The capsule a liquid-glass bar draws around each run of ungrouped
  /// actions — `null` in every other material, where the actions sit on the
  /// bar itself.
  final CorePopupStyle? actionCapsuleStyle;

  /// Gap between separate action groups when hosted in a side rail.
  @Deprecated(
    'Read railGroup (since 0.190) — the rail column takes the gap as '
    'chrome, so the Scaffold no longer composes it from a string.',
  )
  final String railGroupSpacing;

  /// Paint-ready chrome for the side-rail column that hosts the bar's
  /// action groups — the gap between those groups. The Scaffold lays it
  /// over the rail's own position.
  final WebElementChrome railGroup;

  /// Paint-ready chrome for the medium variant's top row `<div>` —
  /// `flex flex-row items-center w-full box-border shrink-0` plus the
  /// bar padding / cluster gap and the top-row height (`h-size48` class
  /// default, inline `rem` override). Built for every resolve; the
  /// widget renders it only on the medium branch.
  final WebElementChrome topRow;

  /// Paint-ready chrome for the medium top row's `flex-1` filler `<div>`
  /// between the leading and trailing clusters — mirrors the Flutter
  /// twin's `Spacer` so the trailing cluster docks to the end edge even
  /// when the leading cluster is absent.
  final WebElementChrome topRowSpacer;

  /// Paint-ready chrome for the leading cluster `<div>` —
  /// `flex flex-row items-center shrink-0` plus the action spacing,
  /// always emitted inline as `gap` (dimension, single inline
  /// signature).
  final WebElementChrome leadingCluster;

  /// Paint-ready chrome for the title block `<div>` around the
  /// `header` / `title` / `subtitle` column (or the custom `child`).
  /// Vertically centred single-row column (standard / compact / dense /
  /// prominent) or
  /// bottom-aligned large-title block (medium: `justify-end` on the
  /// `flex-1` column). Carries the per-variant title padding (Tailwind
  /// classes for the default, inline override) and — in slot mode — the
  /// title typography (role class + explicit overlay inline) that the
  /// slot `Text`s inherit; a custom `child` keeps its own typography.
  /// `centerTitle` adds `items-center text-center`; a centred single row
  /// places it in the grid's middle column.
  final WebElementChrome titleWrapper;

  /// Paint-ready chrome for the `<div>` around the `title` on a centred
  /// single row — `max-w-full truncate`, so a title longer than the
  /// symmetric room ends in an ellipsis instead of pushing the clusters (the
  /// Flutter twin's one-line `ellipsis`). `null` otherwise, and with a
  /// custom `child`, which owns its own text.
  final WebElementChrome? titleLine;

  /// Paint-ready chrome for the hidden anchor a centred single row mounts
  /// so the client-side measurer can write [kAppBarSideVar] on the root.
  /// No classes — the element is `hidden`, so it is not a grid item. `null`
  /// when the bar is not a centred single row.
  final WebElementChrome? sideAnchor;

  /// Paint-ready chrome for the trailing cluster `<div>` — either
  /// `flex flex-row items-center justify-end flex-1 min-w-0`
  /// (`trailingExpanded`) or `flex flex-row items-center shrink-0`,
  /// plus the action spacing, always emitted inline as `gap`.
  final WebElementChrome trailingCluster;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// CSS custom property the centred bar's side measurer writes on the bar
/// root: the wider of the two clusters, in px.
const String kAppBarSideVar = '--coui-app-bar-side';

/// The centred single row's columns. Both side columns are held at least at
/// [kAppBarSideVar] — the wider cluster — so the room left for the title is
/// symmetric and the title stays on the bar's centre, ending in an ellipsis
/// instead of shifting when it is too long (the Flutter twin's
/// `_CenteredTitleLayout`). The middle column is the title, never wider
/// than that room. Until the measurer writes the variable (the
/// server-rendered first paint) each side falls back to its own
/// `max-content`, which centres a title that fits and shifts one that does
/// not.
const _kCenteredBarColumns =
    'minmax(var($kAppBarSideVar, max-content), 1fr) minmax(0, max-content) '
    'minmax(var($kAppBarSideVar, max-content), 1fr)';

/// Resolves [ResolvedAppBar] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreAppBarStyle.defaultX / defaultsByVariant)
///   → theme.coreComponentTheme.appBar.style
///   → theme.coreComponentTheme.appBar.variantStyles[variant]
///   → widget.appBarStyle
/// ```
///
/// [hasCustomChild] / [trailingExpanded] / [centerTitle] /
/// [showDivider] / [elevated] are per-build flags baked into the
/// matching slot.
ResolvedAppBar resolveAppBar(
  BuildContext context, {
  required CoreAppBarVariant variant,
  required bool hasCustomChild,
  required bool trailingExpanded,
  required bool centerTitle,
  required bool showDivider,
  required bool elevated,
  CoreAppBarStyle? appBarStyle,
}) {
  final appBarTheme = context.theme.coreComponentTheme?.appBar;
  final variantStyle = CoreAppBarStyle.defaultsByVariant[variant]!;
  final isMedium = variant == CoreAppBarVariant.medium;

  final merged = resolveStyleChain(const CoreAppBarStyle(), [
    appBarTheme?.style,
    appBarTheme?.variantStyles?[variant],
    appBarStyle,
  ]);

  final glassChrome =
      (merged.surfaceStyle ?? SurfaceStyleScope.of(context)) ==
      CoreSurfaceStyleId.liquidGlass;

  // A centred single-row title sits on the whole bar, in every material —
  // the grid above places it at the pixel the Flutter twin's
  // `_CenteredTitleLayout` does, with no measuring script. `trailingExpanded`
  // leaves no free width to centre in, and `medium` lays its title in a row
  // of its own.
  final barCentered = centerTitle && !trailingExpanded && !isMedium;

  // ─── RESOLVE (Stage 1) ────────────────────────────────
  final spacing =
      merged.spacing ?? variantStyle.spacing ?? CoreAppBarStyle.defaultSpacing;
  final actionSpacing =
      merged.actionSpacing ??
      variantStyle.actionSpacing ??
      CoreAppBarStyle.defaultActionSpacing;
  final defaultBackgroundColor =
      variantStyle.backgroundColor ?? CoreAppBarStyle.defaultBackgroundColor;
  final dividerWidth =
      merged.dividerWidth ?? CoreAppBarStyle.defaultDividerWidth;
  final elevatedShadow =
      merged.elevatedShadow ?? CoreAppBarStyle.defaultElevatedShadow;

  // ─── EMIT (Stage 2 — Web, theme-free) ─────────────────
  // Backgrounds / padding / typography route through the emit family —
  // token defaults stay on classes (dark-mode / scale reactive), raw
  // overrides go inline. No `scheme.resolve` (a no-op on Web) and no
  // hand-rolled `hasXxxOverride` booleans.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    glassChrome ? CoreColor.transparent : defaultBackgroundColor,
    .background,
  );
  final paddingEmit = emitSpacing(
    merged.padding,
    variantStyle.padding ?? CoreAppBarStyle.defaultPadding,
    prefix: 'p',
    cssProperty: 'padding',
  );
  final titlePaddingEmit = emitSpacing(
    merged.titlePadding,
    variantStyle.titlePadding!,
    prefix: 'p',
    cssProperty: 'padding',
  );
  final titleTypography = emitTypography(
    merged.titleStyle,
    variantStyle.titleStyle!,
  );

  // Heights — size-token `h-{size}` Tailwind class for the default
  // (maps to `var(--coui-size-N)`, so accessibility scaling applies);
  // dropped in favour of an inline `rem` when the caller pins an
  // explicit override (class XOR inline for the same property).
  final heightClass = merged.height == null
      ? 'h-${variantStyle.height!.tailwindSize}'
      : '';
  final heightRem = merged.height == null
      ? null
      : '${merged.height! / kRemDivisor}rem';
  final topRowHeightClass = merged.topRowHeight == null
      ? 'h-${CoreAppBarStyle.defaultTopRowHeight.tailwindSize}'
      : '';
  final topRowHeightRem = merged.topRowHeight == null
      ? null
      : '${merged.topRowHeight! / kRemDivisor}rem';

  // Cluster gaps — dimensions, always emitted inline (single inline
  // signature, no `gap-space{N}` class).
  final spacingCss = spaceCss(spacing);
  final actionSpacingInline = Styles(
    raw: {'gap': spaceCss(actionSpacing)},
  );

  // Bottom hairline — the bare `border-b` class supplies the `solid`
  // style; the width is a dimension so it is always emitted inline via
  // `strokeWidthCss` (px-fixed — token → `var(--coui-stroke-width-N)`,
  // never `rem`, so the hairline does not scale with the root font
  // size). The colour is a colour — the default token class
  // (`border-b-{token}`) is added unless the caller overrides the
  // field, in which case the class is dropped and the inline override
  // wins (the scaffold header-border model).
  final dividerColorClass = merged.dividerColor == null
      ? 'border-b-${CoreAppBarStyle.defaultDividerColor.tailwindColor}'
      : '';
  final dividerColorCss = merged.dividerColor?.toValue();
  final dividerWidthCss = strokeWidthCss(dividerWidth);

  // Elevated cast — routed through `emitShadow` so the default
  // `CoreShadow.sm` stack resolves to the `var(--shadow-sm)` preset
  // variable (a surface style can bend it); an off-scale override
  // bakes a literal stack tinted with the shared shadow token base.
  final boxShadowCss = emitShadow(elevatedShadow, base: kShadowVariableBase);

  // ─── Local builders ───────────────────────────────────

  /// Composes the bar root `<div>` class list — row (standard / compact /
  /// dense / prominent) or column (medium) plus surface / divider chrome.
  String buildRootClassName() {
    final parts = [
      if (!glassChrome &&
          !(merged.backgroundColor != null &&
              (merged.backgroundColor!.opacity == 0 ||
                  (merged.backgroundColor!.isResolved &&
                      merged.backgroundColor!.alpha == 0))))
        ...webSurfaceMarkerFor(
          CoreSurfaceRole.functional,
          surfaceStyle: merged.surfaceStyle,
        ),
      WebLayout.wFull,
      'box-border',
      if (isMedium) ...[
        WebLayout.flex,
        WebLayout.flexCol,
      ] else if (barCentered) ...[
        WebLayout.grid,
        WebLayout.itemsCenter,
      ] else ...[
        WebLayout.flex,
        WebLayout.flexRow,
        WebLayout.itemsCenter,
      ],
      heightClass,
      if (!isMedium) paddingEmit.className,
      backgroundEmit.className,
      if (showDivider && !glassChrome) ...['border-b', dividerColorClass],
    ];
    return parts.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the bar root `<div>` inline bundle — height / padding /
  /// gap overrides, background override, divider width / colour and the
  /// elevated cast.
  Styles? buildRootInlineStyles() {
    final raw = {
      'height': ?heightRem,
      if (!isMedium) ...?paddingEmit.inline,
      if (!isMedium) 'gap': spacingCss,
      if (barCentered) 'grid-template-columns': _kCenteredBarColumns,
      ...?backgroundEmit.inline,
      ...surfaceFillVar(merged.backgroundColor ?? defaultBackgroundColor),
      if (showDivider && !glassChrome) 'border-bottom-width': dividerWidthCss,
      if (showDivider && !glassChrome) 'border-bottom-color': ?dividerColorCss,
      if (elevated && !glassChrome)
        'box-shadow': '$boxShadowCss, $kSurfaceRimVar',
      if (glassChrome) ...{
        'position': 'relative',
        'isolation': 'isolate',
      },
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the medium top row `<div>` chrome — the 48px leading +
  /// actions row that carries the bar padding / cluster gap on the
  /// medium branch.
  WebElementChrome buildTopRowChrome() {
    final parts = [
      WebLayout.flex,
      WebLayout.flexRow,
      WebLayout.itemsCenter,
      WebLayout.wFull,
      'box-border',
      WebLayout.shrinkZero,
      topRowHeightClass,
      paddingEmit.className,
    ];
    final raw = {
      'height': ?topRowHeightRem,
      ...?paddingEmit.inline,
      'gap': spacingCss,
    };
    return WebElementChrome(
      className: parts.where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: Styles(raw: raw),
    );
  }

  /// Composes the leading / trailing cluster `<div>` chrome.
  WebElementChrome buildLeadingClusterChrome() => WebElementChrome(
    className:
        '${WebLayout.flex} ${WebLayout.flexRow} ${WebLayout.itemsCenter} '
        '${WebLayout.shrinkZero}',
    inlineStyles: barCentered
        ? Styles(
            raw: {
              'gap': spaceCss(actionSpacing),
              'grid-column': '1',
              'justify-self': 'start',
            },
          )
        : actionSpacingInline,
  );

  /// Composes the title block `<div>` chrome — see
  /// [ResolvedAppBar.titleWrapper].
  WebElementChrome buildTitleWrapperChrome() {
    final parts = [
      WebLayout.flex,
      WebLayout.flexCol,
      if (isMedium) WebLayout.justifyEnd else WebLayout.justifyCenter,
      if (isMedium || (!trailingExpanded && !barCentered)) WebLayout.flex1,
      WebLayout.minWZero,
      titlePaddingEmit.className,
      // Slot mode inherits the title typography (role class + token
      // colour class); a custom `child` brings its own text styling.
      if (!hasCustomChild) titleTypography.className,
      if (centerTitle) ...[WebLayout.itemsCenter, 'text-center'],
    ];
    final raw = {
      ...?titlePaddingEmit.inline,
      if (!hasCustomChild) ...?titleTypography.inline,
      if (barCentered) 'grid-column': '2',
    };
    return WebElementChrome(
      className: parts.where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: raw.isEmpty ? null : Styles(raw: raw),
    );
  }

  /// Composes the trailing cluster `<div>` chrome.
  WebElementChrome buildTrailingClusterChrome() => WebElementChrome(
    className: trailingExpanded
        ? '${WebLayout.flex} ${WebLayout.flexRow} ${WebLayout.itemsCenter} '
              '${WebLayout.justifyEnd} ${WebLayout.flex1} '
              '${WebLayout.minWZero}'
        : '${WebLayout.flex} ${WebLayout.flexRow} ${WebLayout.itemsCenter} '
              '${WebLayout.shrinkZero}',
    inlineStyles: barCentered
        ? Styles(
            raw: {
              'gap': spaceCss(actionSpacing),
              'grid-column': '3',
              'justify-self': 'end',
            },
          )
        : actionSpacingInline,
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedAppBar(
    // Still filled while the field is in its deprecation window — a caller
    // that reads it keeps the value it had.
    railGroupSpacing: spacingCss,
    railGroup: WebElementChrome(
      className: '',
      inlineStyles: Styles(raw: {'gap': spacingCss}),
    ),
    actionCapsuleStyle: glassChrome
        ? CoreAppBarStyle.glassActionStyle.copyWith(
            surfaceStyle: merged.surfaceStyle ?? CoreSurfaceStyleId.liquidGlass,
            spacing: merged.actionSpacing,
          )
        : null,
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    topRow: buildTopRowChrome(),
    topRowSpacer: const WebElementChrome(className: WebLayout.flex1),
    leadingCluster: buildLeadingClusterChrome(),
    titleWrapper: buildTitleWrapperChrome(),
    titleLine: barCentered && !hasCustomChild
        ? const WebElementChrome(
            className: '${WebLayout.maxWFull} ${WebLayout.truncate}',
          )
        : null,
    sideAnchor: barCentered ? const WebElementChrome(className: '') : null,
    trailingCluster: buildTrailingClusterChrome(),
  );
}
