import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// ResolvedValidatorHint
// ═══════════════════════════════════════════════════

/// Resolver output for `ValidatorHint` (Web).
///
/// DOM shape:
///
/// ```text
/// root (<p>)                       // flex row, accent text colour
///   ├─ icon (<span>)                // leading severity icon wrapper
///   │    └─ Icon (default or caller-provided)
///   └─ message Component (optional)
/// ```
///
/// All chrome slots are paint-ready ([WebElementChrome]) — `co_validator_hint`
/// reads `resolved.<slot>.className` / `resolved.<slot>.inlineStyles`
/// straight off without invoking any top-level builder.
///
/// ```text
/// CoreValidatorHintStyle.defaultX        // design system default
///   → theme.coreComponentTheme.validatorHint.style
///   → component.validatorHintStyle
/// ```
class ResolvedValidatorHint implements WebResolvedChrome {
  /// Creates a [ResolvedValidatorHint].
  const ResolvedValidatorHint({
    required this.root,
    required this.icon,
    required this.iconStyle,
  });

  /// Paint-ready chrome for the outermost `<p>` row — composed
  /// `flex flex-row items-start text-<typography>` className plus the
  /// accent colour + optional nested typography overrides bundled as
  /// inline CSS.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the leading-icon `<span>` wrapper —
  /// Inline-end margin gap, inline-flex layout, shrink-0.
  final WebElementChrome icon;

  /// Effective leading icon style — raw forward to `Icon`. The
  /// per-type accent colour is already folded into `color` here, so the
  /// widget forwards this slot straight to `Icon` with no further
  /// composition.
  final CoreIconStyle iconStyle;
}

// ═══════════════════════════════════════════════════
// resolveValidatorHint — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedValidatorHint] for the given [context] and
/// [type].
ResolvedValidatorHint resolveValidatorHint(
  BuildContext context, {
  required CoreValidatorHintType type,
  CoreValidatorHintStyle? validatorHintStyle,
}) {
  final hintTheme = context.theme.coreComponentTheme?.validatorHint;

  // 2-stage merge chain — theme.style → component.validatorHintStyle.
  final merged = resolveStyleChain(const CoreValidatorHintStyle(), [
    hintTheme?.style,
    validatorHintStyle,
  ]);

  // Per-type accent — defaultsByType is the single source of truth.
  final typeChrome = CoreValidatorHintStyle.defaultsByType[type]!;
  final accentColor = merged.accentColor ?? typeChrome.accentColor;
  // Nested `CoreGapStyle` slot — merge the design-system default with
  // the per-instance override and extract `size` for the inline
  // `margin-inline-end` declaration. Mirrors the Flutter resolver which
  // forwards the slot to `Gap`.
  final iconLabelGapStyle = CoreValidatorHintStyle.defaultIconLabelGapStyle
      .merge(merged.iconLabelGapStyle);
  final iconLabelGap = iconLabelGapStyle.size!;
  final iconLabelGapCss = spaceCss(iconLabelGap);

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Message label typography + accent colour route through the single
  // `emitTypography` entry point. The token-backed `bodyXs` role
  // default merges with any per-instance overlay, then the accent colour
  // (per-type / override) is layered on top as the text colour — it wins
  // over any colour the overlay carried, matching the historical
  // "accent drives the message text" behaviour. A token-bound accent
  // emits a `text-{token}` colour class (dark-mode reactive); explicit
  // scalar overlays (font-size / weight / …) emit inline. No
  // `scheme.resolve` (a no-op on Web).
  final messageOverlay = (merged.messageTextStyle ?? const CoreTextStyle())
      .copyWith(color: accentColor);
  final labelEmit = emitTypography(
    messageOverlay,
    CoreValidatorHintStyle.defaultMessageTextStyle,
  );
  // Fold the per-type accent colour into the icon slot so the widget
  // forwards `resolved.iconStyle` straight to `Icon` (the accent wins
  // over any per-instance icon colour, matching the historical
  // `iconStyle.copyWith(color: accentColor)` in the widget body).
  // guard-nested-override: color — accent wins over caller
  // `iconStyle.color` (and, above, over `messageTextStyle.color`);
  // override via `accentColor` instead.
  final iconStyle = CoreValidatorHintStyle.defaultIconStyle
      .merge(merged.iconStyle)
      .copyWith(color: accentColor);

  // ─── Local builders ───────────────────────────────────

  /// Composes the validator-hint root `<p>` Tailwind className.
  /// `inline-flex flex-row items-center` lays out the icon + message as a row,
  /// while the emit-family classes bind the message text to the active
  /// body-xs typography role + accent colour token.
  String buildRootClassName() => [
    WebLayout.inlineFlex,
    WebLayout.flexRow,
    // Centre the severity icon on the message line box — start
    // alignment pinned the icon to the line-box top, reading visibly
    // higher than the text ink (mirrors the Flutter Row alignment).
    WebLayout.itemsCenter,
    labelEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Builds the validator-hint root inline CSS — any raw typography /
  /// accent overlay produced by the emit family (token values stay on
  /// classes and contribute nothing here). Returns `null` when empty.
  Styles? buildRootInlineStyles() {
    final raw = {...?labelEmit.inline};
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Inline CSS for the leading-icon wrapper — inline-end margin governed by
  /// the resolved icon gap.
  Styles buildIconInlineStyles() => .new(
    raw: {
      'margin-inline-end': iconLabelGapCss,
      'display': 'inline-flex',
      'flex-shrink': '0',
    },
  );

  return ResolvedValidatorHint(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    icon: WebElementChrome(
      className: '',
      inlineStyles: buildIconInlineStyles(),
    ),
    iconStyle: iconStyle,
  );
}

/// Maps a [CoreValidatorHintType] to its default leading Lucide icon.
IconName coValidatorHintDefaultIcon(CoreValidatorHintType type) {
  return switch (type) {
    .error => LucideIcons.circleAlert,
    .warning => LucideIcons.triangleAlert,
    .info => LucideIcons.info,
    .success => LucideIcons.circleCheckBig,
    // The unfilled twin of `success`'s mark — in a checklist the two share
    // one column and only the glyph changes as a rule is met, so the pair
    // has to share a silhouette.
    .neutral => LucideIcons.circleDashed,
  };
}
