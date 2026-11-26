library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Countdown`.
///
/// DOM shape:
///
/// ```text
/// root (<span>)         // inline-block, tabular nums, plus the
///                       // `headline-large` / `on-surface` typography
///                       // role + colour token classes from
///                       // `emitTypography`, with optional per-instance
///                       // font / colour overlay inline CSS and the
///                       // always-on digit-fade `transition` rule
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only paint-ready
/// `WebElementChrome` slots. No scalar behavioural metadata (value /
/// min / max) is exposed — those identifiers stay on the widget prop.
/// The `animationDuration` chrome override **is** reflected: it drives
/// the root `transition` rule so a digit swap fades over the resolved
/// duration (Epic #1603 coverage gate — 1:1 with the Flutter
/// `AnimatedSwitcher` fade duration).
class ResolvedCountdown implements WebResolvedChrome {
  /// Creates a [ResolvedCountdown].
  const ResolvedCountdown({required this.root});

  /// Paint-ready chrome for the outer `<span>` — inline-block, tabular
  /// numeric features (`tabular-nums`), plus the `headline-large` /
  /// `on-surface` typography role + colour token classes from
  /// `emitTypography`, plus the inline-CSS bundle for per-instance
  /// overrides (font-size / font-weight / line-height / letter-spacing /
  /// font-family / color) and the always-on digit-fade `transition` rule
  /// driven by `animationDuration`.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCountdown] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.countdown.style
///   → widget.countdownStyle
/// ```
ResolvedCountdown resolveCountdown(
  BuildContext context, {
  CoreCountdownStyle? countdownStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.countdown;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCountdownStyle(), [
    csTheme?.style,
    countdownStyle,
  ]);

  // ─── Stage 1 RESOLVE — typography (CoreTextStyle, composite) ───
  // Fold the flat `fontSize` / `color` overrides into the nested
  // `labelStyle` slot so the flat field wins over the slot (mirrors the
  // Flutter resolver's overlay precedence). A null-only overlay is a
  // no-op (merge overlays non-null fields only).
  final labelOverlay = CoreTextStyle(
    fontSize: merged.fontSize,
    color: merged.color,
  );
  final labelOverride = (merged.labelStyle ?? const CoreTextStyle()).merge(
    labelOverlay,
  );

  // ─── Stage 1 RESOLVE — animation ──────────────────────
  final animationDurationMs =
      (merged.animationDuration ?? CoreCountdownStyle.defaultAnimationDuration)
          .inMilliseconds;

  // ─── Stage 2 EMIT (Web, theme-free) ───────────────────
  // `emitTypography` emits the `headline-large` role class + the
  // `on-surface` token colour class for the design-system default, and
  // routes any per-instance scalar / raw-colour overlay inline. The
  // single canonical typography path — no hand-rolled
  // `text-${typography.headlineLarge}` / `scheme.resolve` (a no-op on
  // Web).
  final typographyEmit = emitTypography(
    labelOverride,
    CoreCountdownStyle.defaultLabelStyle,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture the emit result + duration above — local to the
  // resolver, inaccessible from outside.

  /// Joins non-empty Tailwind class fragments into one className string.
  String joinClasses(List<String> parts) =>
      parts.where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the outer `<span>` Tailwind className — inline-block,
  /// tabular numeric features, plus the typography role + colour token
  /// classes emitted by `emitTypography`.
  String buildRootClassName() => joinClasses([
    '${WebLayout.inlineBlock} tabular-nums',
    typographyEmit.className,
  ]);

  /// Composes the outer `<span>` inline-CSS bundle — any per-instance
  /// typography / raw-colour overlay emitted by `emitTypography`, the
  /// `font-family` override (which `toInlineCss` does not map), plus the
  /// always-on digit-fade `transition` rule driven by `animationDuration`
  /// (mirrors the Flutter `AnimatedSwitcher` fade — Epic #1603 coverage
  /// gate, 1:1 fade duration).
  Styles buildRootInlineStyles() {
    final duration = durationMsCss(animationDurationMs);
    final easing = CoreEasing.move.toVarCss();
    return Styles(
      raw: {
        ...?typographyEmit.inline,
        'transition': 'color $duration $easing, opacity $duration $easing',
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedCountdown(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}
