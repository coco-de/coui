library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// Scope marker class on the `<details>` root.
///
/// A class and not a generated id on purpose: the marker-suppression
/// rule below is byte-identical for every instance, so scoping it by
/// class keeps the default-path markup id-less. An id that came from
/// `identityHashCode` would also differ between the server render and
/// the client, which is the one thing a component built for static
/// rendering must not do.
const String _kDisclosureScopeClass = 'coui-disclosure';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Disclosure`.
///
/// DOM shape:
///
/// ```text
/// root (<details>)                      // `group` + scope class
///   ├─ summaryRow (<summary>)           // header; the browser's toggle
///   │    ├─ triggerText (<div>)         // title or caller trigger
///   │    ├─ Gap(iconLabelGapStyle)      // nested slot
///   │    └─ chevron (<div>)             // group-open:rotate-180
///   └─ content (<div>)                  // body, shown by the browser
/// ```
///
/// No slot carries an expanded/collapsed branch: `<details>` owns that
/// state, which is what lets this render correctly before hydration and
/// keep working without it.
class ResolvedDisclosure implements WebResolvedChrome {
  /// Creates a [ResolvedDisclosure].
  const ResolvedDisclosure({
    required this.root,
    required this.summaryRow,
    required this.triggerText,
    required this.iconLabelGapStyle,
    required this.chevron,
    required this.content,
    required this.iconStyle,
  });

  /// The `<details>` root — the Tailwind `group` marker scoping the
  /// chevron's `group-open:` rotation, plus the scope class.
  @override
  final WebElementChrome root;

  /// The `<summary>` header row.
  final WebElementChrome summaryRow;

  /// The header text wrapper.
  final WebElementChrome triggerText;

  /// Horizontal gap slot between the header text and the chevron,
  /// forwarded raw to `Gap(gapStyle: …)`.
  final CoreGapStyle iconLabelGapStyle;

  /// The chevron wrapper, carrying the `group-open:` rotation.
  final WebElementChrome chevron;

  /// The body wrapper.
  final WebElementChrome content;

  /// Nested [CoreIconStyle] slot for the chevron glyph.
  final CoreIconStyle iconStyle;
}

/// Paint-ready chrome for Web `DisclosureGroup`.
class ResolvedDisclosureGroup implements WebResolvedChrome {
  /// Creates a [ResolvedDisclosureGroup].
  const ResolvedDisclosureGroup({required this.root});

  /// The stacking `<div>` — column flow plus the resolved item spacing.
  @override
  final WebElementChrome root;
}

/// Scoped CSS text for the `<style>` block in `Disclosure`.
class ResolvedDisclosureRules {
  /// Creates a [ResolvedDisclosureRules].
  const ResolvedDisclosureRules({required this.css});

  /// Raw CSS rule text.
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolvers
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDisclosure] for `Disclosure`.
///
/// Single entry point — applies the merge chain
/// (`CoreDisclosureTheme.style` → `disclosureStyle`) followed by
/// design-system default fallback.
ResolvedDisclosure resolveDisclosure(
  BuildContext context, {
  CoreDisclosureStyle? disclosureStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.disclosure;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDisclosureStyle(), [
    csTheme?.style,
    disclosureStyle,
  ]);

  // ─── Stage1 RESOLVE (Core values) ─────────────────────
  final contentInset =
      merged.contentInset ?? CoreDisclosureStyle.defaultContentInset;
  final iconLabelGapStyle = CoreDisclosureStyle.defaultIconLabelGapStyle.merge(
    merged.iconLabelGapStyle,
  );
  final iconStyle = CoreDisclosureStyle.defaultIconStyle.merge(
    merged.iconStyle,
  );
  final durationMs =
      (merged.duration ?? CoreDisclosureStyle.defaultDuration).inMilliseconds;
  final transitionTiming =
      '${durationMsCss(durationMs)} ${CoreEasing.move.toVarCss()}';
  // Only an explicit override paints a ring here. Left alone, `<summary>`
  // keeps the focus outline the browser already draws — the same bargain
  // the rest of this component makes with the platform, and it keeps the
  // default markup free of ring classes and of the scoped rule a
  // non-class-safe ring would need.
  final ring = _resolveRing(merged.clickableStyle?.focusOutlineStyle);

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  final triggerTextEmit = emitTypography(
    merged.triggerTextStyle,
    CoreDisclosureStyle.defaultTriggerTextStyle,
  );
  final contentTextEmit = emitTypography(
    merged.contentTextStyle,
    CoreDisclosureStyle.defaultContentTextStyle,
  );
  // guard-nested-override: iconColor — the chevron colour override rides
  // the nested CoreIconStyle slot's .color sub-field; the contract has no
  // flat iconColor field (icon chrome → iconStyle slot).
  final chevronColorEmit = emitColor(
    merged.iconStyle?.color,
    CoreDisclosureStyle.defaultIconColor,
    .text,
  );
  // ─── Local builders ───────────────────────────────────

  /// The `<details>` root — `group` scopes the chevron's `group-open:`
  /// rotation to this instance's open state.
  WebElementChrome buildRootChrome() => const .new(
    className: '$_kDisclosureScopeClass group',
  );

  /// The `<summary>` header. `flex` is doing double duty: it lays the
  /// row out *and* it takes the element off `display: list-item`, which
  /// is what draws the native disclosure triangle — we draw our own
  /// chevron, so the triangle has to go. `list-none` covers engines
  /// that keep a marker regardless; the `<style>` rule handles WebKit's
  /// legacy pseudo-element.
  WebElementChrome buildSummaryChrome() => .new(
    className: <String>[
      WebLayout.flexItemsCenterFull,
      'cursor-pointer',
      'select-none',
      'list-none',
      // `outline-none` rides along only when a ring replaces the
      // browser's own. It is unconditional because it is the ring's
      // resting state (`2px solid transparent`): focusing then moves only
      // the outline colour instead of flipping `outline-style`. Forced
      // colours still paint the focused summary — the root rule
      // `.coui-root :focus-visible{outline:2px solid}` outranks it
      // (rules/web/pseudo-state-emit.md).
      if (ring != null) 'outline-none',
      if (ring != null && ring.classSafe) ring.className,
    ].where((cls) => cls.isNotEmpty).join(' '),
    inlineStyles: Styles(raw: {'padding': contentInset.toValue()}),
  );

  /// The header text wrapper — typography role classes plus any
  /// explicit overlay, and `flex:1` so the chevron stays pinned right.
  WebElementChrome buildTriggerTextChrome() => .new(
    className: <String>[
      triggerTextEmit.className,
      WebLayout.minWZero,
    ].where((cls) => cls.isNotEmpty).join(' '),
    inlineStyles: Styles(
      raw: {WebLayout.flex: '1', ...?triggerTextEmit.inline},
    ),
  );

  /// The chevron wrapper. The rotation is pure CSS — `group-open:`
  /// reads the `<details open>` attribute the browser maintains, so the
  /// chevron tracks the section with no script and no state here.
  WebElementChrome buildChevronChrome() => .new(
    className: <String>[
      '${WebLayout.flex} ${WebLayout.itemsCenter} ${WebLayout.shrinkZero}',
      'group-open:rotate-180',
      chevronColorEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' '),
    inlineStyles: Styles(
      raw: {'transition': 'transform $transitionTiming'},
    ),
  );

  /// The body wrapper. Only `padding-top` — the browser decides whether
  /// this subtree renders at all.
  WebElementChrome buildContentChrome() => .new(
    className: contentTextEmit.className,
    inlineStyles: Styles(
      raw: {
        'padding-top': spaceCss(contentInset.top),
        ...?contentTextEmit.inline,
      },
    ),
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedDisclosure(
    root: buildRootChrome(),
    summaryRow: buildSummaryChrome(),
    triggerText: buildTriggerTextChrome(),
    iconLabelGapStyle: iconLabelGapStyle,
    chevron: buildChevronChrome(),
    content: buildContentChrome(),
    iconStyle: iconStyle,
  );
}

/// Resolves [ResolvedDisclosureGroup] for `DisclosureGroup`.
ResolvedDisclosureGroup resolveDisclosureGroup(
  BuildContext context, {
  CoreDisclosureStyle? disclosureStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.disclosure;

  final merged = resolveStyleChain(const CoreDisclosureStyle(), [
    csTheme?.style,
    disclosureStyle,
  ]);

  final itemSpacing =
      merged.itemSpacing ?? CoreDisclosureStyle.defaultItemSpacing;

  WebElementChrome buildRootChrome() => .new(
    className: '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.wFull}',
    inlineStyles: Styles(
      raw: {'gap': spaceCss(itemSpacing)},
    ),
  );

  return ResolvedDisclosureGroup(root: buildRootChrome());
}

/// Resolves the scoped `<style>` text for `Disclosure`.
///
/// Always non-empty: WebKit draws `summary::-webkit-details-marker`
/// independently of `display`, so the triangle has to be dismissed by
/// rule or it renders beside our chevron. That rule is scoped by class,
/// so it is identical for every instance and needs no id. The focus ring
/// joins it only when it cannot ride preset utility classes.
ResolvedDisclosureRules resolveDisclosureRules(
  BuildContext context, {
  required String scopeId,
  CoreDisclosureStyle? disclosureStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.disclosure;
  final merged = resolveStyleChain(const CoreDisclosureStyle(), [
    csTheme?.style,
    disclosureStyle,
  ]);
  final ring = _resolveRing(merged.clickableStyle?.focusOutlineStyle);

  final buffer = StringBuffer()
    ..write(
      '.$_kDisclosureScopeClass > summary::-webkit-details-marker'
      '{display:none;}',
    );
  if (ring != null && !ring.classSafe) {
    buffer.write(
      focusRingScopedRule(
        scopeSelector: '#$scopeId > summary',
        pseudo: .focusVisible,
        ringColor: ring.ringColor,
        offsetColor: ring.offsetColor,
        ringWidth: ring.ringWidth,
        ringOffset: ring.ringOffset,
        ringOpacity: ring.ringOpacity,
      ),
    );
  }
  return ResolvedDisclosureRules(css: buffer.toString());
}

/// The header's focus-ring values, or null when the caller stated none.
///
/// Null is the ordinary case and means "leave the browser's outline
/// alone". When a caller does state one, the derivation matches the
/// `Clickable` reading of the same slot, so a single `clickableStyle`
/// override moves the ring on both platforms — Flutter forwards the slot
/// to the composed `Clickable`, Web paints `<summary>` from it.
///
/// Every value the slot carries is read here rather than back-filled
/// from `CoreClickableStyle`'s defaults: filling a child's defaults
/// field by field is the child's own resolver's job, and doing it here
/// would put a second copy of them in this file.
// guard-nested-override: focusOutlineStyle — the ring override arrives
// through the nested CoreClickableStyle slot's sub-field
// (`merged.clickableStyle?.focusOutlineStyle`); this contract has no flat
// focusOutlineStyle field, so the literal `merged.focusOutlineStyle` the
// guard greps for cannot appear. Reach is covered by
// disclosure_test.dart — 'a partial ring override still paints a ring'.
_DisclosureRing? _resolveRing(CoreFocusOutlineStyle? override) {
  if (override == null) return null;
  // Filling the partial from `CoreClickableStyle`'s own default is
  // normally the child resolver's job, and doing it here would be
  // reaching into a child. There is no child here: Web paints
  // `<summary>` itself instead of composing a `Clickable`, so nothing
  // downstream would ever fill it. Reading the same constant the
  // Clickable resolver reads keeps both platforms on one source —
  // without it a caller who states only a ring colour gets a ring on
  // Flutter and none here.
  final slot = CoreClickableStyle.defaultFocusOutlineStyle.merge(override);
  final ringWidth = slot.borderWidth!;
  final ringOffset = slot.align! - ringWidth;
  final ringColor = slot.borderColor!;
  final offsetColor = slot.offsetColor!;
  const ringOpacity = 1.0;
  final classSafe = focusRingIsClassSafe(
    ringColor: ringColor,
    offsetColor: offsetColor,
    ringOpacity: ringOpacity,
    ringWidth: ringWidth,
    ringOffset: ringOffset,
  );
  return _DisclosureRing(
    classSafe: classSafe,
    // The ring is an outline, so its offset is a real gap and a
    // transparent band needs no class; a painted band is a `box-shadow`
    // layer only the scoped rule draws (`classSafe` is false then).
    className: classSafe
        ? focusRingClassName(
            pseudo: .focusVisible,
            ringColor: ringColor,
            ringWidth: ringWidth,
            ringOffset: ringOffset,
          )
        : '',
    ringColor: ringColor,
    offsetColor: offsetColor,
    ringWidth: ringWidth,
    ringOffset: ringOffset,
    ringOpacity: ringOpacity,
  );
}

class _DisclosureRing {
  const _DisclosureRing({
    required this.classSafe,
    required this.className,
    required this.ringColor,
    required this.offsetColor,
    required this.ringWidth,
    required this.ringOffset,
    required this.ringOpacity,
  });

  final bool classSafe;
  final String className;
  final CoreColor ringColor;
  final CoreColor offsetColor;
  final double ringWidth;
  final double ringOffset;
  final double ringOpacity;
}
