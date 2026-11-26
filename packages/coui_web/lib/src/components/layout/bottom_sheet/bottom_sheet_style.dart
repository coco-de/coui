import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// CSS variable the content measurer writes on the footer's area — `1`
/// while more content lies below the visible part, `0` once it ends in view.
/// The footer hairline reads it as its opacity, falling back to `0`.
const String kBottomSheetMoreBelowVar = '--co-bottom-sheet-more-below';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `BottomSheet`.
///
/// DOM shape (`bottom_sheet.dart` decides which optional branches render):
///
/// ```text
/// root (<div>)                         // surface fill · rounded top corners ·
///   │                                  //   flex column
///   ├─ handleRow (<div>)               // optional — the handle's inset
///   │    └─ handle (<div>)             //   the bar
///   ├─ header (<div>)                  // the header's inset · column
///   │    ├─ titleRow (<div>)           //   one row, centred across
///   │    │    ├─ title (<div>)         //   ambient title text
///   │    │    └─ close button          //   optional — composed `Button`
///   │    ├─ Gap                        //   optional — with the description
///   │    └─ description (<div>)        //   optional — ambient text
///   ├─ Divider                         // optional
///   └─ body (<div>)                    // optional — shrinkable column
///        ├─ contentArea (<div>)        //   optional — scroll viewport with
///        │    └─ content               //     the content's inset
///        └─ footerArea (<div>)         //   optional — pinned, relative
///             ├─ footer                //     the caller's own, under the
///             │                        //     sheet's bar theme
///             └─ footerDivider (<div>) //     hairline; opacity is
///                                      //     `var(--co-bottom-sheet-more-below, 0)`
/// ```
///
/// The root stops at `maxHeightFactor` of the viewport's height; the body
/// and the viewport may shrink below their content, so a taller content
/// scrolls inside the viewport while the footer stays pinned.
///
/// The sheet draws no border and no shadow of its own — the surface
/// material the active style states rides the marker on the root.
class ResolvedBottomSheet implements WebResolvedChrome {
  /// Creates a [ResolvedBottomSheet].
  const ResolvedBottomSheet({
    required this.root,
    required this.handleRow,
    required this.handle,
    required this.header,
    required this.titleRow,
    required this.title,
    required this.description,
    required this.contentArea,
    required this.body,
    required this.footerArea,
    required this.footerDivider,
    required this.footerBarStyle,
    required this.titleGapStyle,
    required this.closeButtonStyle,
    required this.dividerStyle,
  });

  /// The panel — the surface fill, the two rounded top corners and the
  /// column.
  @override
  final WebElementChrome root;

  /// The handle's row — its inset, with the bar centred.
  final WebElementChrome handleRow;

  /// The handle bar — its size, colour and pill corners.
  final WebElementChrome handle;

  /// The header's column — its inset.
  final WebElementChrome header;

  /// The row of the title and the close button, centred across.
  final WebElementChrome titleRow;

  /// The title's wrapper — ambient text style, filling the row's room.
  final WebElementChrome title;

  /// The description's wrapper — ambient text style.
  final WebElementChrome description;

  /// The content's scroll viewport — its inset, shrinkable, scrolling
  /// vertically.
  final WebElementChrome contentArea;

  /// The column holding the content viewport and the footer — shrinkable,
  /// so the root's height ceiling reaches the viewport.
  final WebElementChrome body;

  /// The footer's area — pinned, the positioning box of the hairline.
  final WebElementChrome footerArea;

  /// The hairline over the footer's top edge. Its opacity is the measured
  /// state: `0` at rest, `1` while more content lies below.
  final WebElementChrome footerDivider;

  /// The `BottomActionBar` theme style installed around the footer — the
  /// surrounding bar theme with the sheet's `footerBarStyle` folded in,
  /// raw-forwarded to the bar's own resolver.
  final CoreBottomActionBarStyle footerBarStyle;

  /// Gap between the title row and the description, raw-forwarded to `Gap`.
  final CoreGapStyle titleGapStyle;

  /// Chrome of the composed close `Button`, raw-forwarded.
  final CoreButtonStyle closeButtonStyle;

  /// Chrome of the composed `Divider`, raw-forwarded.
  final CoreDividerStyle? dividerStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves the chrome of a Web `BottomSheet`.
///
/// ```text
/// CoreBottomSheetStyle.default*
///   → CoreBottomSheetTheme.style
///   → widget.bottomSheetStyle
/// ```
ResolvedBottomSheet resolveBottomSheet(
  BuildContext context, {
  CoreBottomSheetStyle? bottomSheetStyle,
}) {
  final merged = resolveStyleChain(const CoreBottomSheetStyle(), [
    context.theme.coreComponentTheme?.bottomSheet?.style,
    bottomSheetStyle,
  ]);

  // ─── RESOLVE (Stage 1) ────────────────────────────────
  final backgroundColor =
      merged.backgroundColor ?? CoreBottomSheetStyle.defaultBackgroundColor;
  final handleWidth =
      merged.handleWidth ?? CoreBottomSheetStyle.defaultHandleWidth;
  final handleHeight =
      merged.handleHeight ?? CoreBottomSheetStyle.defaultHandleHeight;
  final handlePadding =
      merged.handlePadding ?? CoreBottomSheetStyle.defaultHandlePadding;
  final headerPadding =
      merged.headerPadding ?? CoreBottomSheetStyle.defaultHeaderPadding;
  final headerSpacing =
      merged.headerSpacing ?? CoreBottomSheetStyle.defaultHeaderSpacing;
  final contentPadding =
      merged.contentPadding ?? CoreBottomSheetStyle.defaultContentPadding;
  final titleGapStyle = CoreBottomSheetStyle.defaultTitleGapStyle.merge(
    merged.titleGapStyle,
  );
  final closeButtonStyle = CoreBottomSheetStyle.defaultCloseButtonStyle.merge(
    merged.closeButtonStyle,
  );
  final maxHeightFactor =
      merged.maxHeightFactor ?? CoreBottomSheetStyle.defaultMaxHeightFactor;
  final footerDividerWidth =
      merged.footerDividerWidth ??
      CoreBottomSheetStyle.defaultFooterDividerWidth;
  final footerBarStyle = CoreBottomSheetContract.footerBarThemeStyle(
    context.theme.coreComponentTheme?.bottomActionBar,
    CoreBottomSheetStyle.defaultFooterBarStyle.merge(merged.footerBarStyle),
  );

  // ─── EMIT (Stage 2 — Web, theme-free) ─────────────────
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    CoreBottomSheetStyle.defaultBackgroundColor,
    .background,
  );
  final radiusEmit = emitRadius(
    merged.borderRadius,
    CoreBottomSheetStyle.defaultBorderRadius,
  );
  final handleColorEmit = emitColor(
    merged.handleColor,
    CoreBottomSheetStyle.defaultHandleColor,
    .background,
  );
  final handleRadiusEmit = emitRadius(
    merged.handleBorderRadius,
    CoreBottomSheetStyle.defaultHandleBorderRadius,
  );
  final footerDividerEmit = emitColor(
    merged.footerDividerColor,
    CoreBottomSheetStyle.defaultFooterDividerColor,
    .background,
  );
  final titleEmit = emitTypography(
    merged.titleTextStyle,
    CoreBottomSheetStyle.defaultTitleTextStyle,
  );
  final descriptionEmit = emitTypography(
    merged.descriptionTextStyle,
    CoreBottomSheetStyle.defaultDescriptionTextStyle,
  );

  // A fill that paints nothing is not a surface — it takes neither the
  // marker nor the published fill, as `AppBar` does.
  final isSurface = surfacePaintsFill(backgroundColor);

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<div>` class list — the surface marker, the column,
  /// and the fill and corner classes (empty when an override goes inline).
  String buildRootClassName() {
    final parts = [
      if (isSurface) ...webSurfaceMarkerFor(CoreSurfaceRole.functional),
      WebLayout.wFull,
      'box-border',
      WebLayout.flex,
      WebLayout.flexCol,
      backgroundEmit.className,
      radiusEmit.className,
    ];
    return parts.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the root `<div>` inline bundle — any raw fill or corner
  /// override, and the published fill the surface material reads.
  Styles buildRootInlineStyles() => Styles(
    raw: {
      ...?backgroundEmit.inline,
      ...?radiusEmit.inline,
      if (isSurface) ...surfaceFillVar(backgroundColor),
      // The viewport's height, not the parent's: a sheet placed where the
      // height is unbounded still stops, so the content can scroll. `dvh`
      // follows the visible viewport as a phone's browser chrome slides.
      'max-height': '${_percentOf(maxHeightFactor)}dvh',
    },
  );

  /// Composes a typography wrapper's chrome — the role and colour classes
  /// and any stated overlay inline, installed as the ambient text style.
  WebElementChrome buildTextChrome(
    Emit emit, {
    String extraClassName = '',
  }) => WebElementChrome(
    className: [
      emit.className,
      extraClassName,
    ].where((cls) => cls.isNotEmpty).join(' '),
    inlineStyles: switch (emit.inline) {
      final inline? => Styles(raw: inline),
      _ => null,
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedBottomSheet(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    handleRow: WebElementChrome(
      className: [WebLayout.flex, 'justify-center'].join(' '),
      inlineStyles: Styles(raw: handlePadding.toLogicalDeclarations('padding')),
    ),
    handle: WebElementChrome(
      className: [
        'shrink-0',
        handleColorEmit.className,
        handleRadiusEmit.className,
      ].where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: Styles(
        raw: {
          'width': pinnedLengthCss(handleWidth),
          'height': pinnedLengthCss(handleHeight),
          ...?handleColorEmit.inline,
          ...?handleRadiusEmit.inline,
        },
      ),
    ),
    header: WebElementChrome(
      className: [WebLayout.flex, WebLayout.flexCol].join(' '),
      inlineStyles: Styles(raw: headerPadding.toLogicalDeclarations('padding')),
    ),
    titleRow: WebElementChrome(
      className: WebLayout.flexRowItemsCenter,
      inlineStyles: Styles(raw: {'gap': spaceCss(headerSpacing)}),
    ),
    title: buildTextChrome(titleEmit, extraClassName: 'min-w-0 flex-1'),
    description: buildTextChrome(descriptionEmit),
    contentArea: WebElementChrome(
      className: ['min-h-0', 'overflow-y-auto'].join(' '),
      inlineStyles: Styles(
        raw: contentPadding.toLogicalDeclarations('padding'),
      ),
    ),
    body: WebElementChrome(
      className: [WebLayout.flex, WebLayout.flexCol, 'min-h-0'].join(' '),
    ),
    footerArea: WebElementChrome(
      className: ['relative', WebLayout.shrinkZero].join(' '),
    ),
    footerDivider: WebElementChrome(
      className: [
        'absolute',
        'inset-x-0',
        'top-0',
        'pointer-events-none',
        footerDividerEmit.className,
      ].where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: Styles(
        raw: {
          // A zero width draws nothing, as Flutter's `BorderSide.none`.
          'height': strokeWidthCss(footerDividerWidth),
          // The two state values — rest `0`, more below `1` — as the
          // variable's fallback and the measurer's write.
          'opacity': 'var($kBottomSheetMoreBelowVar, 0)',
          ...?footerDividerEmit.inline,
        },
      ),
    ),
    footerBarStyle: footerBarStyle,
    titleGapStyle: titleGapStyle,
    closeButtonStyle: closeButtonStyle,
    dividerStyle: merged.dividerStyle,
  );
}

/// `0.9` → `90`, without a trailing `.0` for whole percentages. Rounded to
/// three decimals first: `0.9 * 100` is `90.00000000000001` in binary.
String _percentOf(double factor) {
  final percent = double.parse((factor * 100).toStringAsFixed(3));
  return percent == percent.truncateToDouble()
      ? percent.toInt().toString()
      : percent.toString();
}
