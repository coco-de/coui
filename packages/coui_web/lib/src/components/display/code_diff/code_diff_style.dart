import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `CodeDiff`.
///
/// DOM shape:
///
/// ```text
/// root — OutlinedContainer(containerStyle)   // outer bordered box — composed, not hand-rolled
///   └─ rowsWrapper (<div>)                   // flex-column layout for the row list
///        └─ rows[i].root (<div>)*            // per-line flex row (one entry per CoreCodeDiffLine)
///             ├─ rows[i].lineNumber (<div>)  // co_code_diff renders only when
///             │                              //   showLineNumbers && line.lineNumber != null
///             ├─ rows[i].prefix (<span>)     // `+ ` / `- ` / `  ` marker
///             └─ rows[i].text (<div>)        // diff text cell
/// ```
///
/// The outer box is composed from `OutlinedContainer` rather than a
/// hand-drawn `<div>` (`core/style-contract.md`'s child-component-
/// composition rule) — [containerStyle] carries the background /
/// border / radius chrome as `coui_core` domain types, raw-forwarded
/// to `OutlinedContainer(containerStyle: …)`; that component's own
/// resolver runs colour / radius resolution, the surface-material
/// wiring, and the "no shadow of its own → take the active style's
/// injected control-shadow" fallback exactly once.
///
/// The resolver otherwise carries only:
/// * Cat 2 — the nested `CoreOutlinedContainerStyle` slot
///   ([containerStyle]) plus the [rowsWrapper] structural chrome.
/// * Cat B — `List<ResolvedCodeDiffRow>` per-line item chromes (each
///   row is fully paint-ready — the type-specific band face, the prefix
///   and gutter ink and the body text style overrides are baked into
///   each row's `inlineStyles` at resolve time so `co_code_diff`
///   iterates the list without re-running merge or per-state selection).
///
/// No scalar metadata (the band and ink colours, `bodyTextStyle`) is
/// exposed — those source values are consumed by the resolver and baked
/// into the per-row paint-ready slots.
class ResolvedCodeDiff {
  /// Creates a [ResolvedCodeDiff].
  const ResolvedCodeDiff({
    required this.containerStyle,
    required this.rowsWrapper,
    required this.rows,
  });

  /// Nested [CoreOutlinedContainerStyle] for the composed outer box —
  /// raw-forwarded straight to `OutlinedContainer(containerStyle: …)`;
  /// that widget's own resolver owns border / radius / background /
  /// shadow emit (no className / inlineStyles assembly here).
  final CoreOutlinedContainerStyle containerStyle;

  /// Paint-ready chrome for the row-list wrapper `<div>` — the flex-
  /// column layout that arranges [rows] inside the composed
  /// `OutlinedContainer`'s `child` slot.
  final WebElementChrome rowsWrapper;

  /// Paint-ready chrome per diff line — one entry per source
  /// `CoreCodeDiffLine`. Each entry's `root` / `lineNumber` / `prefix`
  /// / `text` carries the line-type tint, foreground colour, and any
  /// `bodyTextStyle` / `gutterTextStyle` overrides baked into
  /// `inlineStyles` so `co_code_diff` simply renders one row per entry.
  final List<ResolvedCodeDiffRow> rows;
}

/// Per-line paint-ready chrome bundle for a single diff row.
///
/// Carries the four DOM slots that make up one row, with the
/// type-specific band face / prefix and gutter ink / body-text-style
/// overrides baked into each slot's `inlineStyles`. Layout / typography
/// classes stay stable across rows; only the colour values change with
/// [CoreCodeDiffLineType].
class ResolvedCodeDiffRow implements WebResolvedChrome {
  /// Creates a [ResolvedCodeDiffRow].
  const ResolvedCodeDiffRow({
    required this.root,
    required this.lineNumber,
    required this.prefix,
    required this.text,
  });

  /// Paint-ready chrome for the per-row container `<div>` — start-aligned
  /// flex row className + inline box-sizing / padding + per-state row tint
  /// (`background-color`, the opaque band face of an added / removed row).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the line-number gutter cell `<div>` —
  /// gutter typography className + inline CSS for width, padding, the
  /// per-row-type number colour (the band's ink on a band, the gutter
  /// colour on a plain row) and any `gutterTextStyle` override.
  ///
  /// `co_code_diff` renders this slot only when
  /// `widget.showLineNumbers && line.lineNumber != null`.
  final WebElementChrome lineNumber;

  /// Paint-ready chrome for the prefix `<span>` — bold marker
  /// className + inline CSS for the per-state foreground colour (the
  /// band's ink on a band) and any `bodyTextStyle` overrides.
  final WebElementChrome prefix;

  /// Paint-ready chrome for the diff text cell `<div>` — flex-1
  /// wrapping cell className + inline CSS for the body ink (the same on
  /// every row) and any `bodyTextStyle` overrides.
  final WebElementChrome text;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCodeDiff] for the given [context].
///
/// Single entry point — `co_code_diff.dart` must not call
/// `context.theme.coreComponentTheme.codeDiff` directly nor invoke
/// `CoreCodeDiffStyle.merge(...)` outside this function.
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreCodeDiffStyle.defaultX)
///   → theme.coreComponentTheme.codeDiff.style
///   → widget.codeDiffStyle
/// ```
ResolvedCodeDiff resolveCodeDiff(
  BuildContext context, {
  required List<CoreCodeDiffLine> lines,
  CoreCodeDiffStyle? codeDiffStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.codeDiff;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCodeDiffStyle(), [
    coreTheme?.style,
    codeDiffStyle,
  ]);

  // ─── Resolved chrome values (merged override → default) ─
  // Every chrome / dimensional / colour / typography value reads
  // `merged.X ?? CoreCodeDiffStyle.defaultX` — the override wins and the
  // design-system default is the fallback (1:1:1:1 chaining contract).

  // Outer chrome — composed via `OutlinedContainer` rather than a
  // hand-drawn box (core/style-contract.md — 합성 = 재구현 금지).
  // Background / border / radius stay `coui_core` domain types,
  // raw-forwarded to `OutlinedContainer(containerStyle: …)`; that
  // component's own resolver runs colour / radius resolution, the
  // surface-material wiring, and the "no shadow of its own" fallback
  // exactly once.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor:
        merged.surfaceColor ?? CoreCodeDiffStyle.defaultSurfaceColor,
    borderColor: merged.outlineColor ?? CoreCodeDiffStyle.defaultOutlineColor,
    borderRadius: merged.cornerRadius ?? CoreCodeDiffStyle.defaultCornerRadius,
    borderWidth: merged.borderWidth ?? CoreCodeDiffStyle.defaultBorderWidth,
  );

  final addedBackground =
      merged.addedBackgroundColor ??
      CoreCodeDiffStyle.defaultAddedBackgroundColor;
  final addedForeground =
      merged.addedForegroundColor ??
      CoreCodeDiffStyle.defaultAddedForegroundColor;
  final removedBackground =
      merged.removedBackgroundColor ??
      CoreCodeDiffStyle.defaultRemovedBackgroundColor;
  final removedForeground =
      merged.removedForegroundColor ??
      CoreCodeDiffStyle.defaultRemovedForegroundColor;
  // sb8 — the body ink lives inside the nested `unchangedTextStyle.color`
  // slot, and every row's diff text reads it.
  final bodyInk =
      merged.unchangedTextStyle?.color ??
      CoreCodeDiffStyle.defaultUnchangedTextStyle.color!;
  final lineNumberPlainColor =
      merged.lineNumberColor ?? CoreCodeDiffStyle.defaultLineNumberColor;
  final linePadding =
      (merged.linePadding ?? CoreCodeDiffStyle.defaultLinePadding).toValue();
  // Logical longhands when the value is directional — the default gap sits
  // on the side the code runs toward (the end side), so the physical
  // `padding` shorthand, which throws on a directional value by
  // construction, would put it on the wrong edge in a right-to-left locale.
  // A symmetric caller override still comes back as the one-line shorthand.
  final lineNumberPadding =
      (merged.lineNumberPadding ?? CoreCodeDiffStyle.defaultLineNumberPadding)
          .toLogicalDeclarations('padding');
  final lineNumberWidth =
      merged.lineNumberWidth ?? CoreCodeDiffStyle.defaultLineNumberWidth;
  final bodyTypography =
      merged.bodyTypography ?? CoreCodeDiffStyle.defaultBodyTypography;
  final gutterTypography =
      merged.gutterTypography ?? CoreCodeDiffStyle.defaultGutterTypography;
  final prefixFontWeight =
      merged.prefixFontWeight ?? CoreCodeDiffStyle.defaultPrefixFontWeight;
  final bodyTextStyle = merged.bodyTextStyle;
  final gutterTextStyle = merged.gutterTextStyle;

  // Per-state row bands: an added / removed row is a solid face (opaque,
  // no alpha); an unchanged row is fully transparent so the surface bg from
  // the outer container shows through.
  final addedRowBackground = addedBackground.toValue();
  final removedRowBackground = removedBackground.toValue();
  // Per-state ink of the prefix and the gutter number: the band's own
  // foreground on a band. Web emits the token reference directly as an rgb
  // CSS-variable, which the browser resolves at runtime so dark mode tracks.
  // A scheme resolve would be a no-op on Web.
  final addedInk = addedForeground.toValue();
  final removedInk = removedForeground.toValue();
  // The body ink: the diff text of every row, and an unchanged row's blank
  // prefix. A band recolours the prefix and the number, never the code.
  final bodyTextColor = bodyInk.toValue();
  // Gutter number on a plain row (opaque — hierarchy is the token chosen).
  final lineNumberPlainInk = lineNumberPlainColor.toValue();

  // ─── Local builders ───────────────────────────────────

  /// Composes the row-list wrapper `<div>` Tailwind className — vertical
  /// column layout for [ResolvedCodeDiff.rows], nested inside the
  /// composed `OutlinedContainer`'s `child` slot.
  String buildRowsWrapperClassName() =>
      '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.wFull}';

  /// Composes the per-row container `<div>` Tailwind className — flex row
  /// whose cells all start at the row's top edge. Not baseline-aligned:
  /// the 12px gutter and the 13px body sit in separate 21px line boxes
  /// whose baselines are a fraction of a pixel apart, and aligning those
  /// baselines would shift one cell down by that fraction and grow every
  /// row past 21px. Start-aligned, each cell's line box is the row's
  /// first 21px, as on Flutter.
  String buildRowClassName() =>
      '${WebLayout.flex} ${WebLayout.flexRow} '
      '${WebLayout.itemsStart} ${WebLayout.wFull}';

  /// Composes the per-row container inline CSS — `linePadding`
  /// shorthand from the line padding token, plus the per-state row tint
  /// (`background-color`: the opaque band face of an added / removed row).
  ///
  /// `box-sizing: border-box` keeps the row's inset inside its `w-full`
  /// width, as the Flutter row's padding is inside its width. coui_web ships
  /// without Tailwind's preflight, so a consumer app's row is content-box by
  /// default and 100% width plus the 12px insets overflows the container by
  /// 24px.
  Styles buildRowInlineStyles(CoreCodeDiffLineType type) {
    final raw = <String, String>{};
    raw['box-sizing'] = 'border-box';
    raw['padding'] = linePadding;
    raw['background-color'] = switch (type) {
      .added => addedRowBackground,
      .removed => removedRowBackground,
      .unchanged => 'transparent',
    };
    return Styles(raw: raw);
  }

  /// Composes the line-number gutter cell `<div>` Tailwind className —
  /// gutter typography role (typography exception) + end-edge alignment
  /// (`text-end`, so the number follows the reading direction like the
  /// directional padding beside it) + `shrink-0`.
  String buildLineNumberClassName() {
    return '${WebLayout.shrinkZero} text-end '
        'text-${gutterTypography.tailwindTypographyRole}';
  }

  /// Composes the line-number gutter cell inline CSS — resolved `width`
  /// (the cell's *total* width), `lineNumberPadding` declarations, the
  /// per-row-type number colour (the band's ink on a band, the plain gutter
  /// colour on an unchanged row — opaque in both) and any `gutterTextStyle`
  /// override.
  ///
  /// `box-sizing: border-box` makes `width` the total width with the
  /// padding inside it, as the Flutter cell is (a `SizedBox` around the
  /// padded text). coui_web ships without Tailwind's preflight, so a
  /// consumer app's cells are content-box by default and the gap would be
  /// added on top of the width — pushing the code past x = 52.
  Styles buildLineNumberInlineStyles(CoreCodeDiffLineType type) {
    final raw = <String, String>{};
    raw['width'] = '${lineNumberWidth / kRemDivisor}rem';
    raw['box-sizing'] = 'border-box';
    raw.addAll(lineNumberPadding);
    raw['color'] = switch (type) {
      .added => addedInk,
      .removed => removedInk,
      .unchanged => lineNumberPlainInk,
    };
    if (gutterTextStyle != null) {
      raw.addAll(gutterTextStyle.toInlineCss());
    }
    return Styles(raw: raw);
  }

  /// Composes the prefix `<span>` Tailwind className — bold marker,
  /// preserves whitespace so the two-character prefix maintains its
  /// width. Body typography role + font weight ride the token classes
  /// (typography exception).
  String buildPrefixClassName() {
    return '${WebLayout.shrinkZero} ${WebLayout.whitespacePre} '
        'text-${bodyTypography.tailwindTypographyRole} '
        'font-${prefixFontWeight.tailwindFontWeight}';
  }

  /// Composes the prefix `<span>` inline CSS — per-state foreground
  /// colour (the band's ink on a band, the body ink on an unchanged row) +
  /// any `bodyTextStyle` overrides.
  Styles buildPrefixInlineStyles(CoreCodeDiffLineType type) {
    final raw = <String, String>{};
    raw['color'] = switch (type) {
      .added => addedInk,
      .removed => removedInk,
      .unchanged => bodyTextColor,
    };
    if (bodyTextStyle != null) {
      raw.addAll(bodyTextStyle.toInlineCss());
    }
    return Styles(raw: raw);
  }

  /// Composes the diff text cell `<div>` Tailwind className — flex-1
  /// wrapping cell + body typography role (typography exception).
  String buildTextClassName() {
    return '${WebLayout.flex1} ${WebLayout.minWZero} '
        '${WebLayout.whitespacePreWrap} '
        'text-${bodyTypography.tailwindTypographyRole}';
  }

  /// Composes the diff text cell `<div>` inline CSS — the body ink (the same
  /// on every row: a band never recolours code) + any `bodyTextStyle`
  /// overrides.
  Styles buildTextInlineStyles() {
    final raw = <String, String>{};
    raw['color'] = bodyTextColor;
    if (bodyTextStyle != null) {
      raw.addAll(bodyTextStyle.toInlineCss());
    }
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  final rowClassName = buildRowClassName();
  final lineNumberClassName = buildLineNumberClassName();
  final prefixClassName = buildPrefixClassName();
  final textClassName = buildTextClassName();
  final textInlineStyles = buildTextInlineStyles();

  final rows = <ResolvedCodeDiffRow>[
    for (final line in lines)
      ResolvedCodeDiffRow(
        root: WebElementChrome(
          className: rowClassName,
          inlineStyles: buildRowInlineStyles(line.type),
        ),
        lineNumber: WebElementChrome(
          className: lineNumberClassName,
          inlineStyles: buildLineNumberInlineStyles(line.type),
        ),
        prefix: WebElementChrome(
          className: prefixClassName,
          inlineStyles: buildPrefixInlineStyles(line.type),
        ),
        text: WebElementChrome(
          className: textClassName,
          inlineStyles: textInlineStyles,
        ),
      ),
  ];

  return ResolvedCodeDiff(
    containerStyle: containerStyle,
    rowsWrapper: WebElementChrome(className: buildRowsWrapperClassName()),
    rows: rows,
  );
}
