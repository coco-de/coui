/// Style helpers for `FormField` (Web).
///
/// Encapsulates the `CoreFormFieldStyle` nested-merge chain (design
/// default → `CoreFormFieldTheme.style` → `widget.formFieldStyle`), so
/// `co_form_field.dart` reads only [ResolvedFormField] and never
/// touches the merge chain or `coreComponentTheme` directly.
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
// ResolvedFormField
// ═══════════════════════════════════════════════════

/// Resolver output for `FormField` (Web).
///
/// DOM shape:
///
/// ```text
/// root (<div>)                       // form-field stack
///   ├─ label (<label>)               // optional caller-supplied label
///   │    ├─ caller label text
///   │    ├─ Gap (requiredIndicatorGapStyle)  // when required
///   │    └─ required (<span>)        // optional `*` indicator
///   ├─ Gap (labelInputGapStyle)    // when label present
///   ├─ caller-provided child input
///   ├─ Gap (labelInputGapStyle)    // when description / error present
///   ├─ description (<p>)             // optional description
///   └─ error (<p>)                   // optional error message
/// ```
///
/// Both gap-style slots are forwarded as nested [CoreGapStyle] slots to
/// `Gap` children that the widget interleaves between rows. The
/// receiving `Gap` runs its own resolve step, so each slot is the
/// merged design-system default + per-instance override in pre-scaling
/// units.
///
/// Single struct that the widget reads — every chrome / typography
/// override has had the nested-merge chain applied:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.formField.style
///   → widget.formFieldStyle
/// ```
class ResolvedFormField implements WebResolvedChrome {
  /// Creates a [ResolvedFormField].
  const ResolvedFormField({
    required this.root,
    required this.formLabelStyle,
    required this.description,
    required this.validatorHintStyle,
    required this.labelInputGapStyle,
    required this.counter,
    required this.labelActionGapStyle,
    required this.footerGapStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` form-field stack —
  /// composed Tailwind className (`flex flex-col w-full`) and inline-CSS
  /// bundle carrying the `pointer-events: none` declaration when the
  /// field is disabled. Inter-row spacing is rendered via interleaved
  /// `Gap` children using [labelInputGapStyle], not via CSS `gap`.
  @override
  final WebElementChrome root;

  /// Nested [CoreFormLabelStyle] slot — raw-forwarded to the composed
  /// `FormLabel` (its own resolver fills defaults; the disabled-state
  /// overlay is already merged when the field is disabled). `null` when
  /// enabled with no per-instance override.
  final CoreFormLabelStyle? formLabelStyle;

  /// Paint-ready chrome for the optional description `<p>` — typography
  /// role (`bodySmall`) + semantic content colour from the
  /// [emitTypography] result plus any explicit inline overlay.
  final WebElementChrome description;

  /// Paint-ready chrome for the counter `<span>` — typography role +
  /// semantic colour, same shape as [description].
  final WebElementChrome counter;

  /// Nested [CoreGapStyle] slot for the label↔action gap — the floor on
  /// their separation, since the row pushes the two apart.
  final CoreGapStyle labelActionGapStyle;

  /// Nested [CoreGapStyle] slot for the footer's message↔counter gap.
  final CoreGapStyle footerGapStyle;

  /// Nested [CoreValidatorHintStyle] slot — raw-forwarded to the
  /// composed error `ValidatorHint` (its own resolver fills the
  /// error-type accent / icon defaults).
  final CoreValidatorHintStyle validatorHintStyle;

  /// Nested [CoreGapStyle] slot for the gap between the label, the
  /// input child, and the helper / error row — forwarded straight to
  /// `Gap(gapStyle: …)`. The receiving widget owns scaling.
  final CoreGapStyle labelInputGapStyle;
}

/// Resolves [ResolvedFormField] for a `FormField` (Web).
///
/// Walks the nested-merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.formField.style
///   → widget.formFieldStyle
/// ```
///
/// The [enabled] flag picks between the enabled / disabled label
/// typography slot and travels with the pre-computed root + label chrome
/// so the `pointer-events: none` and `cursor: not-allowed` declarations
/// can be composed up-front. Every colour / typography value routes
/// through the emit family (`emitColor` / `emitTypography`) — a single
/// class-XOR-inline decision per design value. No `scheme.resolve`
/// (a no-op on Web) and no direct `cs.<token>` / `ts.<role>` reference.
ResolvedFormField resolveFormField(
  BuildContext context, {
  required bool enabled,
  CoreFormFieldStyle? formFieldStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.formField;

  final merged = resolveStyleChain(const CoreFormFieldStyle(), [
    coreTheme?.style,
    formFieldStyle,
  ]);

  // Nested `CoreGapStyle` slots — merge the design-system default with
  // the per-instance override and forward raw (pre-scaling) to `Gap`,
  // which runs its own resolve / scaling step.
  final labelInputGapStyle = CoreFormFieldStyle.defaultLabelInputGapStyle.merge(
    merged.labelInputGapStyle,
  );

  // ─── Nested FormLabel slot (raw-forward) ─────────────
  // The composed `FormLabel` owns the label + required-`*` chrome and
  // fills its own defaults; FormField only overlays its disabled-state
  // divergence (muted label colour) before forwarding.
  final formLabelStyle = enabled
      ? merged.formLabelStyle
      : CoreFormFieldStyle.defaultDisabledFormLabelStyle
            .merge(merged.disabledFormLabelStyle)
            .merge(merged.formLabelStyle);

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  final descriptionEmit = emitTypography(
    merged.descriptionTextStyle,
    CoreFormFieldStyle.defaultDescriptionTextStyle,
  );
  final counterEmit = emitTypography(
    merged.counterTextStyle,
    CoreFormFieldStyle.defaultCounterTextStyle,
  );
  final labelActionGapStyle = CoreFormFieldStyle.defaultLabelActionGapStyle
      .merge(merged.labelActionGapStyle);
  final footerGapStyle = CoreFormFieldStyle.defaultFooterGapStyle.merge(
    merged.footerGapStyle,
  );
  // Nested ValidatorHint slot (raw-forward) — historic bodySmall role
  // partial merged with the per-instance override; the ValidatorHint's
  // own resolver fills the error-type accent and the rest.
  final validatorHintStyle = CoreFormFieldStyle.defaultErrorValidatorHintStyle
      .merge(merged.errorValidatorHintStyle)
      .merge(merged.validatorHintStyle);

  // ─── Local builders ───────────────────────────────────

  /// Composes the form-field `<div>` Tailwind className — `flex flex-col
  /// w-full` stack. Spacing is rendered via interleaved `Gap` children
  /// using the nested [CoreGapStyle] slots, so no `gap-*` class is
  /// composed here.
  String buildRootClassName() => WebLayout.flexColFull;

  /// Composes the form-field `<div>` inline CSS — the disabled
  /// `pointer-events: none` declaration. Returns `null` when nothing
  /// needs inlining.
  Styles? buildRootInlineStyles() {
    if (enabled) return null;
    return const Styles(raw: {'pointer-events': 'none'});
  }

  /// Composes the description `<p>` Tailwind className — typography role
  /// + semantic colour class from [descriptionEmit].
  String buildDescriptionClassName() => descriptionEmit.className;

  /// Composes the description `<p>` inline CSS — any explicit typography
  /// overlay [emitTypography] emits inline. Returns `null` when nothing
  /// needs inlining.
  Styles? buildDescriptionInlineStyles() {
    final raw = descriptionEmit.inline;
    return raw == null || raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the counter `<span>` className — same emit family as the
  /// description, so the two stay one decision.
  String buildCounterClassName() => counterEmit.className;

  /// Composes the counter `<span>` inline CSS. Returns `null` when
  /// nothing needs inlining.
  Styles? buildCounterInlineStyles() {
    final raw = counterEmit.inline;
    return raw == null || raw.isEmpty ? null : Styles(raw: raw);
  }

  return ResolvedFormField(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    formLabelStyle: formLabelStyle,
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    validatorHintStyle: validatorHintStyle,
    labelInputGapStyle: labelInputGapStyle,
    counter: WebElementChrome(
      className: buildCounterClassName(),
      inlineStyles: buildCounterInlineStyles(),
    ),
    labelActionGapStyle: labelActionGapStyle,
    footerGapStyle: footerGapStyle,
  );
}
