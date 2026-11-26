library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Validated`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                     // flex column wrapper
///   ├─ field (<div>)               // co_validated renders only when child != null
///   ├─ Gap(fieldMessageGapStyle)  // co_validated renders only when message != null && state != pending
///   └─ message (<p>)               // co_validated renders only when message != null && state != pending
/// ```
///
/// All slot chromes are non-null — `co_validated` decides whether to
/// render the field / message based on instance state.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome). The
///   per-state validation ring is emitted as inline CSS on [field]
///   (`box-shadow` + `border-radius`).
/// * Cat 2 — nested [CoreGapStyle] slot ([fieldMessageGapStyle]) forwarded
///   straight to the `Gap(gapStyle: …)` widget that separates the
///   field from the message.
///
/// No scalar metadata (state / ring colour / etc.) is exposed —
/// the semantic [CoreValidationState] stays on the widget prop.
class ResolvedValidated implements WebResolvedChrome {
  /// Creates a [ResolvedValidated].
  const ResolvedValidated({
    required this.root,
    required this.validatorHintStyle,
    required this.fieldMessageGapStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` flex column wrapper.
  /// Layout chrome is state-independent so the resolver pre-computes
  /// the `flex flex-col` className once; `inlineStyles` is `null`
  /// because the wrapper carries no per-instance dimensional override
  /// (the field → message gap is rendered by a dedicated `Gap`
  /// child via [fieldMessageGapStyle]).
  @override
  final WebElementChrome root;

  /// Nested [CoreValidatorHintStyle] slot — raw-forwarded to the
  /// composed message `ValidatorHint`.
  final CoreValidatorHintStyle validatorHintStyle;

  /// Nested [CoreGapStyle] for the field → message spacer — forwarded
  /// to `Gap(gapStyle: …)`. `co_validated` renders the gap only when
  /// both `child != null` and `message != null && state != pending`.
  final CoreGapStyle fieldMessageGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedValidated] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.validated.style
///   → widget.validatedStyle
/// ```
///
/// The semantic [state] is a widget prop — the widget propagates it to
/// the wrapped field (ambient scope), whose own error variant draws the
/// border / focus ring; the resolver only settles the message chrome.
ResolvedValidated resolveValidated(
  BuildContext context, {
  CoreValidatedStyle? validatedStyle,
}) {
  final validatedTheme = context.theme.coreComponentTheme?.validated;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreValidatedStyle(), [
    validatedTheme?.style,
    validatedStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finishes its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  // Nested ValidatorHint slot (raw-forward) — bodySmall role partial
  // merged with the per-instance override.
  final validatorHintStyle = CoreValidatedStyle.defaultValidatorHintStyle.merge(
    merged.validatorHintStyle,
  );
  // Merge the design-system default `CoreGapStyle` with the
  // per-instance override — the resolved slot is forwarded straight
  // to `Gap(gapStyle: …)` by `co_validated`.
  final fieldMessageGapStyle = CoreValidatedStyle.defaultFieldMessageGapStyle
      .merge(merged.fieldMessageGapStyle);

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<div>` Tailwind className — `flex flex-col`
  /// stacks the field wrapper above the message row.
  String buildRootClassName() => '${WebLayout.flex} ${WebLayout.flexCol}';

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedValidated(
    root: WebElementChrome(className: buildRootClassName()),
    validatorHintStyle: validatorHintStyle,
    fieldMessageGapStyle: fieldMessageGapStyle,
  );
}
