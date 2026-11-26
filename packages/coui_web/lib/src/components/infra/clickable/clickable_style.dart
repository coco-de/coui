import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Clickable`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="button">)
///   ├─ rules (<style>)                     // only when resolveClickableRules is non-empty
///   └─ child (caller-supplied Component, optional)
/// ```
///
/// `clickable.dart` reads `resolved.root.className` +
/// `resolved.root.inlineStyles` straight through — no merge / fallback
/// / conversion in the widget body.
///
/// Press / focus state DETECTION is browser-native — `:active` and
/// `:focus-visible` pseudo-classes on the className surface. The
/// resolver never receives interaction state as an argument (a
/// `pressed:` / `focused:` parameter has no Web expression the browser
/// can own, and Dart-side re-render for press/focus is the documented
/// Web anti-pattern: SSR-dead until hydration and a focus ring that
/// flashes on mouse click). The one exception is keyboard press: the
/// browser attaches `:active` on Space/Enter only to a native
/// `<button>`, never to this element's `<div role="button">` (#4421),
/// so `clickable.dart` drives [kClickableKeyPressedMarker] by hand —
/// still a direct DOM class toggle, not `setState`, so it stays clear
/// of the anti-pattern above.
class ResolvedClickable implements WebResolvedChrome {
  /// Creates a [ResolvedClickable].
  const ResolvedClickable({required this.root});

  /// Paint-ready chrome for the root `<div role="button">` element.
  @override
  final WebElementChrome root;
}

/// Paint-ready focus-ring chrome for an element that is not a `Clickable`
/// box — an `<a href>`.
///
/// ```text
/// root (<a href>)                       // outline-none + the ring utilities
///                                       //   + the corner radius, as a class
///                                       //   unless the style states its own
/// ```
class ResolvedClickableRing implements WebResolvedChrome {
  /// Creates a [ResolvedClickableRing].
  const ResolvedClickableRing({required this.root});

  /// The ring chrome to merge onto the element. Carries no layout.
  @override
  final WebElementChrome root;
}

/// Scoped CSS text for `<style>` block in `Clickable`.
///
/// Non-empty only when a per-instance / theme override moves a
/// pseudo-state value (press scale / durations / focus ring) off the
/// design-system default — preset Tailwind utilities can no longer
/// express the value, so the instance gets `#scopeId:active` /
/// `#scopeId:focus-visible` rules instead (the default utility classes
/// are dropped by [resolveClickable] in the same condition: class XOR
/// rule).
class ResolvedClickableRules {
  /// Creates a [ResolvedClickableRules].
  const ResolvedClickableRules({required this.css});

  /// Raw CSS rule text — empty when the design-system defaults apply
  /// (the default path is pure utility classes).
  final String css;
}

/// Resolved behavior timings for `Clickable`. No DOM chrome — widget
/// behavior helper only.
class ResolvedClickableTiming {
  /// Creates a [ResolvedClickableTiming].
  const ResolvedClickableTiming({
    required this.pressDurationMs,
    required this.durationMs,
  });

  /// How long the keyboard-activation press pulse (Enter — no
  /// observable down/up pair to hold, see [resolveClickable]'s doc)
  /// keeps [kClickableKeyPressedMarker] on before clearing it again.
  /// Rides the same `pressDuration` token the pointer press pair and
  /// the Space keydown/keyup hold already animate over, so the pulse
  /// cannot drift out of sync with either if that token changes.
  final int pressDurationMs;

  /// The chrome clock — the `duration` the focus ring's outline colour
  /// (and its gap band, when one paints) moves on. A composing row that
  /// paints its own fill / wash reads it here so the row and its ring
  /// move on one duration (the Flutter twin reads
  /// `resolveClickable(...).duration` the same way).
  final int durationMs;
}

// ═══════════════════════════════════════════════════
// Resolver — entry points
// ═══════════════════════════════════════════════════

/// Merged chrome values shared by [resolveClickable] and
/// [resolveClickableRules] so both entry points fold the identical
/// chain once per call.
typedef _ClickableValues = ({
  CoreBorderRadius borderRadius,
  // The corner radius only when the chain states one — [emitRadius] splits
  // class from inline on exactly that, never on the resolved value.
  CoreBorderRadius? statedBorderRadius,
  double pressedScale,
  CoreOffset pressedTranslate,
  String? pressedBoxShadowCss,
  double disabledOpacity,
  int durationMs,
  int pressDurationMs,
  double ringWidth,
  double ringOffset,
  CoreColor ringColor,
  CoreColor ringOffsetColor,
  bool pseudoOverridden,
});

_ClickableValues _resolveClickableValues(
  BuildContext context,
  CoreClickableStyle? clickableStyle,
) {
  final csTheme = context.theme.coreComponentTheme?.clickable;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreClickableStyle(), [
    csTheme?.style,
    clickableStyle,
  ]);

  // ─── Stage 1 RESOLVE ──────────────────────────────────
  final borderRadius =
      merged.borderRadius ?? CoreClickableStyle.defaultBorderRadius;
  final pressedScale =
      merged.pressedScale ?? CoreClickableStyle.defaultPressedScale;
  final pressedTranslate =
      merged.pressedTranslate ?? CoreClickableStyle.defaultPressedTranslate;
  // A raw (non-token) tint can arrive here — a surface style states the
  // press shadow, and nothing makes that a palette token. It rides a
  // custom property rather than a class, so any colour survives; this is
  // the same reason the press scale rides one.
  final pressedBoxShadowCss = merged.pressedBoxShadow == null
      ? null
      : emitShadow(
          merged.pressedBoxShadow!,
          base: const CoreColor.token(CoreColors.shadow).toValue(),
        );
  final disabledOpacity =
      merged.disabledOpacity ?? CoreClickableStyle.defaultDisabledOpacity;
  final durationMs =
      (merged.duration ?? CoreClickableStyle.defaultDuration).inMilliseconds;
  final pressDurationMs =
      (merged.pressDuration ?? CoreClickableStyle.defaultPressDuration)
          .inMilliseconds;

  // Single slot — design default merged with the per-instance
  // override. Every field is non-null after the merge.
  final focusOutlineSlot = CoreClickableStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );
  final ringWidth = focusOutlineSlot.borderWidth!;
  final ringOffset = focusOutlineSlot.align! - ringWidth;
  // NOTE: `focusOutlineSlot.ringOpacity` is not applied — `ringColor` is
  // emitted as a Tailwind `outline-<token>` class below, which carries no
  // alpha channel. No visible effect today since `ringOpacity` is always
  // `1.0` design-system-wide.
  final ringColor = focusOutlineSlot.borderColor!;
  // The gap band — transparent by default, so it never reaches a class
  // (a transparent colour has no token to name one). A band that paints
  // differs from the default and so takes the scoped rule below.
  final ringOffsetColor = focusOutlineSlot.offsetColor!;

  // Class XOR scoped-rule pivot for the FOCUS-RING pseudo bundle
  // (`:focus-visible` ring + its transition timings): these can only
  // ride preset utility classes while they sit on the design-system
  // default. Any deviation switches the ring bundle to the scoped `#id`
  // rules so class and rule never fight over the same property. The
  // press-shrink is NOT part of this pivot — it always rides the global
  // `.coui-clickable-press:active(:hover)` rule with the per-instance
  // scale on the `--coui-press-scale` custom property (so any
  // `pressedScale` override needs no scoped rule).
  const defaultSlot = CoreClickableStyle.defaultFocusOutlineStyle;
  final pseudoOverridden =
      durationMs != CoreClickableStyle.defaultDuration.inMilliseconds ||
      pressDurationMs !=
          CoreClickableStyle.defaultPressDuration.inMilliseconds ||
      ringWidth != defaultSlot.borderWidth ||
      focusOutlineSlot.align != defaultSlot.align ||
      ringColor != defaultSlot.borderColor ||
      ringOffsetColor != defaultSlot.offsetColor;

  return (
    borderRadius: borderRadius,
    statedBorderRadius: merged.borderRadius,
    pressedScale: pressedScale,
    pressedTranslate: pressedTranslate,
    pressedBoxShadowCss: pressedBoxShadowCss,
    disabledOpacity: disabledOpacity,
    durationMs: durationMs,
    pressDurationMs: pressDurationMs,
    ringWidth: ringWidth,
    ringOffset: ringOffset,
    ringColor: ringColor,
    ringOffsetColor: ringOffsetColor,
    pseudoOverridden: pseudoOverridden,
  );
}

/// The `:focus-visible` ring utilities — one function for every element that
/// draws a `Clickable`'s ring, the `Clickable` box ([resolveClickable]) and
/// a bare element that is not a box ([resolveClickableRing]), so the two
/// cannot draw different rings.
///
/// Only valid on the default path (`!pseudoOverridden`): that path is
/// class-safe by construction — every value equals the design-system
/// default, a token colour on the outline scale with no painted band. A
/// value off it cannot ride a preset class and takes the scoped rules of
/// [resolveClickableRules] instead (class XOR rule).
String _focusRingClass(_ClickableValues values) => focusRingClassName(
  pseudo: .focusVisible,
  ringColor: values.ringColor,
  ringWidth: values.ringWidth,
  ringOffset: values.ringOffset,
);

/// Resolves [ResolvedClickable] for the given [context] + build-time
/// semantic state.
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreClickableStyle static const)
///   → theme.coreComponentTheme.clickable.style
///   → widget.clickableStyle
/// ```
ResolvedClickable resolveClickable(
  BuildContext context, {
  required bool enabled,
  required bool focusOutline,
  required bool enableFeedback,
  CoreClickableStyle? clickableStyle,
}) {
  final values = _resolveClickableValues(context, clickableStyle);

  // Any stated press chrome counts, not only the shrink. Asking about
  // the scale alone would drop a style that turns the shrink off and
  // says the press with a shift instead — which is exactly what a style
  // built on a hard cast shadow does.
  final statesPress =
      values.pressedScale != 1.0 ||
      values.pressedTranslate != .zero ||
      values.pressedBoxShadowCss != null;
  final pressFeedback = enabled && enableFeedback && statesPress;
  final ringVisible = enabled && focusOutline;

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<div role="button">` Tailwind className.
  ///
  /// The wrapper is `inline-flex` so it tracks the child's size exactly
  /// (mirroring Flutter's passthrough sizing) and so the focus-ring is
  /// painted outside the box without affecting layout. `select-none`
  /// keeps repeated clicks from selecting child text. The browser's
  /// native focus outline is always replaced — the ring utilities are
  /// the CoUI focus affordance (or nothing when [focusOutline] is off).
  String buildRootClassName() {
    final classList = [
      WebLayout.inlineFlex,
      // Clamp to the parent's width — Flutter constraints always bound
      // the child, so an over-wide child wraps/clamps instead of
      // overflowing the pane (clamp-vs-grow parity).
      WebLayout.maxWFull,
      'select-none',
      if (enabled) 'cursor-pointer' else 'cursor-not-allowed',
      // Unconditional (not `focus-visible:`): the transparent outline
      // is the ring's resting state, so focusing only moves its colour —
      // flipping outline-style on focus instead would start the colour
      // transition from currentColor, flashing a text-coloured border on
      // every focus.
      'outline-none',
      // Press-shrink opt-in: the global `.coui-clickable-press` rule
      // mounted once at the `CoUIWeb` root scales the element on
      // `:active` — additionally gated on `:hover` for hover-capable
      // pointers so dragging the press off the element releases it,
      // matching Flutter's `onTapCancel`. The scale factor rides the
      // `--coui-press-scale` inline custom property set below.
      if (pressFeedback) 'coui-clickable-press',
      // Opt-in, because the rule it turns on writes `box-shadow`
      // outright: an element with a resting shadow and no press shadow
      // would otherwise lose it the moment it is pressed.
      if (pressFeedback && values.pressedBoxShadowCss != null)
        'coui-clickable-press-shadow',
      if (!values.pseudoOverridden) ...[
        // Tailwind's `transition` names `outline-color` here (the
        // `ThemeConfig` `transitionProperty` config), so the ring fades
        // on the same clock as the press.
        if (pressFeedback || ringVisible)
          'transition duration-${values.pressDurationMs}',
        if (ringVisible) _focusRingClass(values),
      ],
    ];
    return classList.join(' ');
  }

  /// Composes the root inline-CSS bundle — non-pseudo chrome only
  /// (corner radius for the ring, disabled opacity, and the press-scale
  /// factor consumed by the global `.coui-clickable-press` rule).
  ///
  /// `transition-timing-function` is always inline (never left to the
  /// `transition` utility class's Tailwind-default curve) so the default
  /// path and the scoped-rule override path in [resolveClickableRules]
  /// converge on the same [CoreEasing.move] curve — an inline
  /// declaration outranks any class regardless of specificity, so this is
  /// the one write that has to happen whichever path is active. Without
  /// it the default path rode Tailwind's own `cubic-bezier(0.4,0,0.2,1)`
  /// while the override path hardcoded `ease` (transform) / `ease-in-out`
  /// (box-shadow) — three different curves for the same press/focus
  /// transition depending only on whether a caller had customized
  /// anything.
  Styles buildRootInlineStyles() => .new(
    raw: {
      'border-radius': values.borderRadius.toValue(),
      if (pressFeedback || ringVisible)
        'transition-timing-function': CoreEasing.move.toVarCss(),
      if (!enabled) 'opacity': '${values.disabledOpacity}',
      if (pressFeedback) '--coui-press-scale': '${values.pressedScale}',
      // Logical pixels, so a press travels the same distance whatever the
      // control's size. Both axes are written together — a half-set pair
      // would leave the other axis on whatever an ancestor last set.
      if (pressFeedback && values.pressedTranslate != .zero) ...{
        '--coui-press-x': '${values.pressedTranslate.dx / kRemDivisor}rem',
        '--coui-press-y': '${values.pressedTranslate.dy / kRemDivisor}rem',
      },
      if (pressFeedback && values.pressedBoxShadowCss != null)
        '--coui-press-shadow': values.pressedBoxShadowCss!,
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedClickable(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

/// Resolves [ResolvedClickableRing] — the focus ring of a `Clickable`
/// drawn on an element that is *not* a `Clickable` box.
///
/// A navigating link is a real `<a href>`, and navigation belongs to an
/// anchor — it cannot be the `<div role="button">` a `Clickable` renders,
/// and it must stay an inline box so the ring and the text wrap together.
/// This gives that anchor the ring the composed `Clickable` would have
/// drawn: the same width, gap, colour and corner radius, read from the
/// same [CoreClickableStyle] chain. No layout class, no cursor, no press
/// feedback — the anchor owns its own box and behaviour.
///
/// The ring's fade is not here. The element may fade other properties on
/// the same `transition` (a link fades its colour too), and a property
/// list cannot be split across a class and an inline declaration — so the
/// host writes its own `transition`, naming `outline-color` on the clock
/// [resolveClickableTiming] returns as `durationMs`.
///
/// On a path where the style moves a ring value off the design-system
/// default the class here is absent and the ring comes from
/// [resolveClickableRules] instead (same arguments, `enabled: true`,
/// `focusOutline: true`, `enableFeedback: false`), mounted under the
/// element's id exactly as `Clickable` does.
ResolvedClickableRing resolveClickableRing(
  BuildContext context, {
  CoreClickableStyle? clickableStyle,
}) {
  final values = _resolveClickableValues(context, clickableStyle);
  // The ring follows the element's corners. A token radius rides a class, so
  // a stylesheet the caller gives the element (a pill, a card) still wins
  // over it; only a radius the style states itself goes inline.
  final radius = emitRadius(
    values.statedBorderRadius,
    CoreClickableStyle.defaultBorderRadius,
  );

  return ResolvedClickableRing(
    root: WebElementChrome(
      className: [
        // The transparent outline is the ring's resting state — see the
        // same class in [resolveClickable].
        'outline-none',
        radius.className,
        if (!values.pseudoOverridden) _focusRingClass(values),
      ].where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: radius.inline == null ? null : Styles(raw: radius.inline),
    ),
  );
}

/// Resolves the scoped pseudo-state rules for a `Clickable` whose
/// press / focus chrome deviates from the design-system default (see
/// [ResolvedClickableRules]). Returns empty CSS on the default path.
ResolvedClickableRules resolveClickableRules(
  BuildContext context, {
  required String scopeId,
  required bool enabled,
  required bool focusOutline,
  required bool enableFeedback,
  CoreClickableStyle? clickableStyle,
}) {
  final values = _resolveClickableValues(context, clickableStyle);
  if (!values.pseudoOverridden) return const ResolvedClickableRules(css: '');

  final pressFeedback = enabled && enableFeedback && values.pressedScale != 1.0;
  final ringVisible = enabled && focusOutline;
  if (!pressFeedback && !ringVisible) {
    return const ResolvedClickableRules(css: '');
  }

  // Only the transition timing + focus ring ride scoped rules now — the
  // press-shrink transform itself is applied by the global
  // `.coui-clickable-press` rule (scale on `--coui-press-scale`), so a
  // custom `pressedScale` needs no `#id:active` rule; this scoped
  // block exists only when a ring / timing override is present.
  //
  // Both entries state the same [CoreEasing.move] curve as the
  // inline `transition-timing-function` [resolveClickable] always writes
  // (see that resolver's `buildRootInlineStyles` doc) — the inline write
  // wins in practice, but this rule is read on its own by anyone
  // auditing scoped CSS, so it states the true value rather than the
  // `ease` / `ease-in-out` mismatch it used to hardcode.
  final standardEasing = CoreEasing.move.toVarCss();
  final buffer = StringBuffer()
    ..write(
      '#$scopeId{transition:'
      'transform ${values.pressDurationMs}ms $standardEasing, '
      'outline-color ${values.durationMs}ms $standardEasing, '
      'box-shadow ${values.durationMs}ms $standardEasing;}',
    );
  if (ringVisible) {
    // Outline ring (+ the gap band as a box-shadow layer when it paints)
    // — shared with every scoped ring via the single
    // `focusRingScopedRule` emitter, the same geometry the default
    // path's `outline-*` utilities produce. Colours emit theme-free
    // (`token → rgb(var(--coui-X))`), resolved by the browser at runtime.
    buffer.write(
      focusRingScopedRule(
        scopeSelector: '#$scopeId',
        pseudo: .focusVisible,
        ringColor: values.ringColor,
        offsetColor: values.ringOffsetColor,
        ringWidth: values.ringWidth,
        ringOffset: values.ringOffset,
        ringOpacity: 1,
      ),
    );
  }
  return ResolvedClickableRules(css: buffer.toString());
}

/// Resolves [ResolvedClickableTiming] for the given [context] +
/// [clickableStyle] — the one raw value `clickable.dart`'s Enter-key
/// handler needs outside [resolveClickable]'s paint-ready chrome
/// (category E, `web/web-specifics.md`: behavior timing, no DOM
/// chrome). Shares the same merge chain as [resolveClickable] /
/// [resolveClickableRules] via [_resolveClickableValues], so a
/// `pressDuration` override lands in the pulse the same build it lands
/// in the pointer/Space press pair.
ResolvedClickableTiming resolveClickableTiming(
  BuildContext context, {
  CoreClickableStyle? clickableStyle,
}) {
  final values = _resolveClickableValues(context, clickableStyle);
  return ResolvedClickableTiming(
    pressDurationMs: values.pressDurationMs,
    durationMs: values.durationMs,
  );
}
