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

/// Paint-ready chrome for Web `StepItem`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                         // flex row, centred, full width
///   ├─ Icon (status glyph, iconStyle)
///   ├─ Gap (iconTitleGapStyle)
///   ├─ title (<span>)                  // flex-1, one line, ellipsis
///   ├─ Gap (titleTrailingGapStyle)     // when trailing
///   └─ trailing (<span>)               // when trailing, keeps its width
/// ```
///
/// `step_item.dart` reads each slot's `className` + `inlineStyles` straight
/// from `resolved.<slot>` — no merge / fallback / conversion in the widget
/// body. The glyph and the two gaps are composed `Icon` / `Gap`s fed the
/// nested slots raw; they resolve their own size and colour.
class ResolvedStepItem implements WebResolvedChrome {
  /// Creates a [ResolvedStepItem].
  const ResolvedStepItem({
    required this.root,
    required this.title,
    required this.trailing,
    required this.iconStyle,
    required this.iconTitleGapStyle,
    required this.titleTrailingGapStyle,
  });

  /// Paint-ready chrome for the row `<div>` — `flex items-center w-full`,
  /// the minimum height and the padding inline.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the title `<span>` — takes the space left, one
  /// line with an ellipsis; the role + status colour.
  final WebElementChrome title;

  /// Paint-ready chrome for the trailing-note `<span>` — keeps its width;
  /// the role + status colour.
  final WebElementChrome trailing;

  /// Nested [CoreIconStyle] slot — forwarded to the status glyph's
  /// `Icon(iconStyle: …)`: the size and the status colour.
  final CoreIconStyle iconStyle;

  /// Nested [CoreGapStyle] slot — forwarded to the `Gap` between the glyph
  /// and the title.
  final CoreGapStyle iconTitleGapStyle;

  /// Nested [CoreGapStyle] slot — forwarded to the `Gap` between the title
  /// and the trailing note.
  final CoreGapStyle titleTrailingGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStepItem] for the given [context].
///
/// Merge chain (the same as the Flutter twin):
///
/// ```text
/// CoreStepItemStyle.default* + defaultsByStatus[status]   // defaults
///   → theme.coreComponentTheme.stepItem.style
///   → theme.coreComponentTheme.stepItem.statusStyles[status]
///   → stepItemStyle
/// ```
ResolvedStepItem resolveStepItem(
  BuildContext context, {
  required CoreStepStatus status,
  CoreStepItemStyle? stepItemStyle,
}) {
  final stepItemTheme = context.theme.coreComponentTheme?.stepItem;

  // ─── Merge chain ──────────────────────────────────────
  // The status comes straight from the widget — the theme only answers how
  // each status looks (render-only.md (c)).
  final merged = resolveStyleChain(const CoreStepItemStyle(), [
    stepItemTheme?.style,
    stepItemTheme?.statusStyles?[status],
    stepItemStyle,
  ]);

  // The status row — what this status paints (the glyph, the title and
  // the trailing note's colours).
  final chrome = CoreStepItemStyle.defaultsByStatus[status]!;

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final iconStyle = CoreStepItemStyle.defaultIconStyle
      .merge(chrome.iconStyle)
      .merge(merged.iconStyle);
  final iconTitleGapStyle = CoreStepItemStyle.defaultIconTitleGapStyle.merge(
    merged.iconTitleGapStyle,
  );
  final titleTrailingGapStyle = CoreStepItemStyle.defaultTitleTrailingGapStyle
      .merge(merged.titleTrailingGapStyle);
  final minHeight = merged.minHeight ?? CoreStepItemStyle.defaultMinHeight;
  final padding = merged.padding ?? CoreStepItemStyle.defaultPadding;

  // ─── Stage 2 — EMIT ───────────────────────────────────
  // Typography + colour through the emit family: the role stays a class,
  // a token colour a class, a raw override inline.
  final titleEmit = emitTypography(
    merged.titleStyle,
    CoreStepItemStyle.defaultTitleStyle.merge(chrome.titleStyle),
  );
  final trailingEmit = emitTypography(
    merged.trailingStyle,
    CoreStepItemStyle.defaultTrailingStyle.merge(chrome.trailingStyle),
  );

  // ─── Local builders ───────────────────────────────────

  /// The row's inline geometry. The minimum height is the row's own (not
  /// a control-ladder rung, so no `--coui-control-height-*` variable); the
  /// padding rides the spacing variables, so density moves it.
  Styles buildRootInlineStyles() => Styles(
    raw: {
      'min-height': '${minHeight / kRemDivisor}rem',
      ...padding.toLogicalDeclarations('padding'),
    },
  );

  /// The title `<span>`: takes the space left, one line with an ellipsis,
  /// plus the title role + status colour classes.
  String buildTitleClassName() => <String>[
    '${WebLayout.flex1} ${WebLayout.minWZero} ${WebLayout.truncate}',
    titleEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// The title's typography / colour overlays that came from a raw
  /// override (token values stay on classes and contribute nothing here).
  Styles? buildTitleInlineStyles() {
    final raw = titleEmit.inline;
    return raw == null || raw.isEmpty ? null : Styles(raw: raw);
  }

  /// The trailing `<span>`: keeps its width on one line, plus the trailing
  /// role + status colour classes.
  String buildTrailingClassName() => <String>[
    '${WebLayout.shrinkZero} ${WebLayout.whitespaceNowrap}',
    trailingEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// The trailing note's raw-override typography / colour overlays.
  Styles? buildTrailingInlineStyles() {
    final raw = trailingEmit.inline;
    return raw == null || raw.isEmpty ? null : Styles(raw: raw);
  }

  return ResolvedStepItem(
    root: WebElementChrome(
      className: WebLayout.flexItemsCenterFull,
      inlineStyles: buildRootInlineStyles(),
    ),
    title: WebElementChrome(
      className: buildTitleClassName(),
      inlineStyles: buildTitleInlineStyles(),
    ),
    trailing: WebElementChrome(
      className: buildTrailingClassName(),
      inlineStyles: buildTrailingInlineStyles(),
    ),
    iconStyle: iconStyle,
    iconTitleGapStyle: iconTitleGapStyle,
    titleTrailingGapStyle: titleTrailingGapStyle,
  );
}
