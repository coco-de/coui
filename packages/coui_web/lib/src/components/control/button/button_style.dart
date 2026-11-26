import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/dashed_overlay.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Chrome clock published by a button whose transitions are switched off.
///
/// Not a design token — the zero here is "do not interpolate", the CSS
/// spelling of dropping Flutter's `AnimatedContainer` for a `Container`.
/// A `0s` clock leaves the shared rule's property list intact, so the
/// press pair (written by the same declaration on its own clock) keeps
/// moving exactly as it does on Flutter, where `disableTransition` never
/// reached that wrapper either.
const String _kNoTransitionClock = '0s';

/// The identity scale — "do not shrink". Not a design token: it is the
/// absence of the press shrink, mirroring the Flutter resolver's pin.
const double _kNoPressShrink = 1;

/// The on value of the style gate `kControlPressShrinkVar` — the factor
/// the shrink is multiplied by when the style lets it through. Not a
/// design token: a boolean spelled as the number CSS `calc()` can use.
const String _kPressShrinkOn = '1';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Button`.
///
/// DOM shape:
///
/// ```text
/// root (<button>)
///   └─ IconTheme (leadingIconStyle)              // no DOM — sizes / tints bare Icons in leading + child
///        └─ content (<span>)                     // co_button skips the wrapper when both leading and trailing are null — child renders directly
///             ├─ leading                         // caller-supplied Component, optional
///             ├─ Gap (iconLabelGapStyle)         // rendered only when leading != null
///             ├─ child
///             ├─ Gap (iconLabelGapStyle)         // rendered only when trailing != null
///             └─ IconTheme (trailingIconStyle)   // no DOM
///                  └─ trailing                   // caller-supplied Component, optional
/// ```
///
/// Per Epic #1603 (옵션 B 최종, single inline signature) every chrome
/// value (border radius / padding / border width / colour) is emitted
/// **inline** through `(merged.X ?? <variant|size|default>).toValue()` /
/// `rem` — no class-drop branch decides between a Tailwind
/// utility and an inline rule for radius / padding / size. Only
/// pseudo-state (`hover:` / `focus-visible:` / `disabled:` /
/// `aria-selected:`), colour-token (`bg-…` / `text-…` / `border-…`),
/// and structural (`inline-flex` / `items-center` / `aspect-square` /
/// `w-full`) classes remain on the className surface.
///
/// The icon ↔ label gap is rendered as an explicit `Gap(gapStyle: …)`
/// between leading / child / trailing (matching the Flutter widget) —
/// the nested [iconLabelGapStyle] slot is forwarded raw (pre-scaling)
/// to `Gap`, which runs its own resolve / scaling step. No inline
/// `gap` CSS leaks onto the content wrapper.
///
/// `co_button.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body.
class ResolvedButton implements WebResolvedChrome {
  /// Creates a [ResolvedButton].
  const ResolvedButton({
    required this.root,
    required this.content,
    required this.expandedLabel,
    required this.iconLabelGapStyle,
    required this.leadingIconStyle,
    required this.trailingIconStyle,
    required this.dashOverlay,
    required this.dashRect,
  });

  /// Paint-ready chrome for the root `<button>` element.
  @override
  final WebElementChrome root;

  /// Dashed-border `<svg>` overlay — carries the dash colour as a
  /// text-colour class or inline `color` (the `<rect>` strokes with
  /// `currentColor`), so the button's own foreground / hover classes
  /// stay untouched. `null` when `dashedBorder` is false — the widget
  /// mounts the overlay only when non-null (folds the old separate
  /// `dashPatterned` bool into this slot's own nullness).
  final WebElementChrome? dashOverlay;

  /// The overlay's `<rect>` — geometry / stroke pattern as CSS
  /// properties (shared `dashed_overlay.dart` chrome). `null` alongside
  /// [dashOverlay].
  final WebElementChrome? dashRect;

  /// Paint-ready chrome for the content wrapper `<span>` element.
  /// Always non-null — `co_button` decides whether to render the
  /// wrapper based on `leading` / `trailing` presence.
  final WebElementChrome content;

  /// Paint-ready layout chrome for the optional expanded-label `<span>`
  /// wrapper (`flex-1 min-w-0`). `co_button` emits the wrapper only when
  /// `expanded` is set — the layout class lives here, not in the widget
  /// (render-only).
  final WebElementChrome expandedLabel;

  /// Nested [CoreGapStyle] slot — passed to `Gap(gapStyle: …)` on
  /// either side of the child between the leading / trailing slots.
  /// Carries the merged size-default + design-system default +
  /// per-instance override (raw, pre-scaling — the receiving `Gap`
  /// runs its own resolve step). Mirrors the Flutter resolver's
  /// `iconLabelGapStyle` slot 1:1.
  final CoreGapStyle iconLabelGapStyle;

  /// Nested [CoreIconStyle] slot — the ambient icon theme `co_button`
  /// hands the leading slot **and the child** (an icon-only button's glyph
  /// is its child), mirroring the Flutter `leadingIconTheme` that wraps the
  /// whole content. Size is always set (slot override, else the
  /// size-keyed default); colour only when the caller pinned one on the
  /// slot — otherwise the glyph inherits the per-state foreground.
  final CoreIconStyle leadingIconStyle;

  /// Nested [CoreIconStyle] slot — the ambient icon theme for the trailing
  /// slot, mirroring the Flutter `trailingIconTheme`. Same size / colour
  /// rules as [leadingIconStyle].
  final CoreIconStyle trailingIconStyle;
}

/// Scoped CSS text for `<style>` block in `Button`.
///
/// Non-empty only when a per-instance / theme override needs a
/// pseudo-state value that no preset Tailwind class can express:
/// * a focus ring whose colour / opacity / geometry moves off the
///   Tailwind `outline-*` vocabulary (raw override colour, sub-1
///   `ringOpacity`, off-scale width / offset), and
/// * a RAW (token-less) `hover:` background / foreground / border
///   override colour.
///
/// `resolveButton` drops the matching utility classes in the same
/// condition (class XOR rule), and the instance gets `#scopeId:...`
/// rules instead. Empty on the default path (pure utility classes).
class ResolvedButtonRules {
  /// Creates a [ResolvedButtonRules].
  const ResolvedButtonRules({required this.css});

  /// Raw CSS rule text — empty on the default (class-safe) path.
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedButton] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (per variant)
///   → theme.coreComponentTheme.button.style
///   → theme.coreComponentTheme.button.variantStyles[variant]
///   → widget.buttonStyle
/// ```
///
/// [disableTransition] mirrors the Flutter widget's flag, which collapses
/// its chrome `AnimatedContainer` to a plain `Container`: the chrome
/// group snaps, and the press pair — a separate wrapper on its own clock
/// there — keeps moving. Web reaches the same split by publishing a `0s`
/// chrome clock, since the press half is written by the shared rule the
/// control does not own (see [kControlChromeDurationVar]).
///
/// [enableFeedback] mirrors the Flutter widget's flag of the same name:
/// `false` withholds the press shrink (`CoreButtonStyle.pressedScale`)
/// the way `Clickable` withholds it there.
ResolvedButton resolveButton(
  BuildContext context, {
  required CoreButtonVariant variant,
  required CoreComponentSize size,
  required CoreButtonShape shape,
  required bool expanded,
  CoreSurfaceRole role = .defaultRole,
  bool disableTransition = false,
  bool enableFeedback = CoreButtonContract.defaultEnableFeedback,
  CoreButtonStyle? buttonStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.button;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreButtonStyle(), [
    csTheme?.style,
    csTheme?.variantStyles?[variant],
    buttonStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final variantStyle = CoreButtonStyle.defaultsByVariant[variant]!;
  final sizeStyle = CoreButtonStyle.defaultsBySize[size]!;

  // Whether this button paints a fill at rest. Two things hang on it — the
  // style's injected cast and the surface material — and both for the same
  // reason: each is a statement about a filled box. The Flutter twin gates
  // both on the same answer.
  //
  // Absent two ways: the opacity multiplier zeroed (ghost, menu, menubar),
  // or a raw colour whose own alpha is zero (the `transparent` sentinel
  // that plain / fixed use) — the one predicate every surface that
  // redraws its own box asks.
  final hasFill = surfacePaintsFill(
    merged.backgroundColor ?? variantStyle.backgroundColor,
  );

  // ─── Resolved chrome values (single inline signature) ──
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly). Border radius / padding / size are always emitted inline
  // via `.toValue()` / rem — no class-drop branch.

  // Border radius — rectangle / square use the per-instance override
  // else `CoreButtonStyle.borderRadiusForSize` (variant's own `radius`
  // when it states one, else the size row's corner — the control height
  // × 0.25); circle uses the per-instance `circleBorderRadius` override
  // else the design-system pill default. Both are emitted inline
  // (`(merged.X ?? default).toValue()`). The dashed-border overlay below
  // reads the same rectangle corner, so it follows the size too.
  final rectangleBorderRadiusCore =
      merged.borderRadius ??
      CoreButtonStyle.borderRadiusForSize(
        size: size,
        variantRadius: variantStyle.radius,
      );
  final rectangleBorderRadius = rectangleBorderRadiusCore.toValue();
  final circleBorderRadius =
      (merged.circleBorderRadius ?? CoreButtonStyle.defaultCircleBorderRadius)
          .toValue();
  final borderRadius = shape == .circle
      ? circleBorderRadius
      : rectangleBorderRadius;

  // Padding — `rectangle` uses the per-instance override else
  // `CoreButtonStyle.paddingFor` (the size ladder with the variant's
  // inline override — `plain` sits flush — applied in Core);
  // `square` / `circle` use the per-instance `iconShapePadding` override
  // else the design-system zero default. Always inline
  // (`(merged.X ?? default).toValue()`).
  //
  // Declarations rather than one shorthand: a directional inset (start /
  // end) has no `padding` shorthand, so it emits the logical longhands and
  // the browser mirrors them with `dir`. A symmetric inset still emits the
  // one-line shorthand it always did.
  final paddingDeclarations = shape == .rectangle
      ? (merged.padding ??
                CoreButtonStyle.paddingFor(
                  size: size,
                  paddingInline: variantStyle.paddingInline,
                ))
            .toLogicalDeclarations('padding')
      : (merged.iconShapePadding ?? CoreButtonStyle.defaultIconShapePadding)
            .toLogicalDeclarations('padding');

  final borderWidth = merged.borderWidth ?? variantStyle.borderWidth;
  final dashedBorder =
      merged.dashedBorder ?? CoreButtonStyle.defaultDashedBorder;
  final dashedBorderColor =
      merged.dashedBorderColor ?? CoreButtonStyle.defaultDashedBorderColor;
  // Dashed borders render through the SVG overlay — the CSS
  // `border-style: dashed` pattern is engine-defined (differs per
  // browser) and untunable, while the overlay carries the Core dash
  // tokens.
  final dashLength = merged.dashLength ?? CoreButtonStyle.defaultDashLength;
  final dashSpacing = merged.dashSpacing ?? CoreButtonStyle.defaultDashSpacing;
  final animationDuration =
      (merged.animationDuration ?? CoreButtonStyle.defaultAnimationDuration)
          .inMilliseconds;
  final disableHoverEffect =
      merged.disableHoverEffect ?? CoreButtonStyle.defaultDisableHoverEffect;
  // The engage-squash pair's clock — see [kControlEngageDurationVar] /
  // `ThemeConfig._controlShadowPressRule`'s doc comment (#4407).
  final castHideDuration =
      (merged.castHideDuration ?? CoreButtonStyle.defaultCastHideDuration)
          .inMilliseconds;
  // The press shrink — `CoreButtonStyle.pressedScale`, the value the
  // Flutter twin hands `Clickable.pressedScale`. Whether this control
  // shrinks at all is decided here (feedback on, a factor other than the
  // identity); whether the *active style* lets it is decided by the
  // shared rule through `kControlPressShrinkVar`, since this resolver
  // never sees the style (see `ThemeConfig._controlPressScaleRule`).
  final pressedScale =
      merged.pressedScale ?? CoreButtonStyle.defaultPressedScale;
  final pressShrinks = enableFeedback && pressedScale != _kNoPressShrink;

  // Nested `CoreGapStyle` slot — merge the size-keyed default with the
  // per-instance override and forward raw (pre-scaling) to the
  // `Gap(gapStyle: …)` widgets `co_button` interleaves between
  // leading / child / trailing. The receiving `Gap` runs its own
  // resolve / scaling step (Epic #1603 C12 — single materialise,
  // scaling owned by the receiving widget). Mirrors the Flutter
  // resolver's `iconLabelGapStyle` slot 1:1 — no inline `gap` CSS
  // leaks onto the content wrapper.
  final iconLabelGapStyle = sizeStyle.iconLabelGapStyle!.merge(
    merged.iconLabelGapStyle,
  );

  // Single slot — design default merged with the per-instance override.
  // Every field is non-null after the merge. The ring is an outline: when
  // it stays on the outline scale with a token colour (`ringClassSafe`)
  // it rides the `focus-visible:outline-*` utility classes below; a raw
  // override colour, a sub-1 `ringOpacity`, or an off-scale width / offset
  // has no class and paints via the scoped `#scopeId:focus-visible` rule
  // from `resolveButtonRules` instead (which also honours the
  // `ringOpacity` the class path cannot express). The gap band is not
  // part of that split — see `focusBand` below.
  // Focus-ring override rides the nested focus-outline slot (base → variant
  // default → per-instance merge) — not a flat merged.ringOpacity.
  // guard-nested-override: ringOpacity
  final focusOutlineSlot = CoreButtonStyle.defaultFocusOutlineStyle
      .merge(variantStyle.focusOutlineStyle)
      .merge(merged.focusOutlineStyle);
  final focusRingWidth = focusOutlineSlot.borderWidth!;
  final focusRingOffset = focusOutlineSlot.align! - focusRingWidth;
  final focusRingColor = focusOutlineSlot.borderColor!;
  final focusRingOffsetColor = focusOutlineSlot.offsetColor!;
  final focusRingOpacity =
      focusOutlineSlot.ringOpacity ?? CoreFocusOutlineStyle.defaultRingOpacity;
  final ringClassSafe = focusRingOutlineIsClassSafe(
    ringColor: focusRingColor,
    ringOpacity: focusRingOpacity,
    ringWidth: focusRingWidth,
    ringOffset: focusRingOffset,
  );
  // The band is exactly as wide as the gap the outline leaves, in the
  // same unit — so it reads the value the outline offset resolves to on
  // whichever path paints the ring, rather than a second derivation that
  // could drift from it (at a non-16px root, or under a stroke floor).
  final focusBandGap = ringClassSafe
      ? focusRingClassOffsetCss(focusRingOffset)
      : focusRingGeometryCss(
          ringWidth: focusRingWidth,
          ringOffset: focusRingOffset,
        ).offset;
  // The gap band — transparent by default, painted only where the
  // composing component states a band (its background is unknown: a
  // floating Fab, a carousel arrow over a slide, a close button on an
  // inverse-surface toast). It is a `box-shadow` layer, which this
  // button's unconditional inline rest shadow would outrank from any
  // class or scoped rule, so it travels as a value on `kFocusBandVar`
  // for the shared `ThemeConfig` rule gated on `kFocusBandMarker`.
  final focusBand = focusBandPaints(focusRingOffsetColor)
      ? focusBandShadow(offsetColor: focusRingOffsetColor, gap: focusBandGap)
      : null;
  // The same band at zero alpha, same colour channels — leads the resting
  // `box-shadow` of a band-on button so rest and focus carry the same
  // layer count. `box-shadow` interpolates layer by index; without this
  // the band would pair with the first cast layer and the cast would
  // swing into the band on the engage clock. With it only the band's
  // alpha moves, the way the Flutter twin fades the band's opacity and
  // leaves the cast alone.
  final focusBandRest = focusBand == null
      ? null
      : focusBandShadow(
          offsetColor: focusRingOffsetColor.scaleAlpha(0),
          gap: focusBandGap,
        );

  // Label typography — EMIT Stage 2 (Web). The size-keyed role
  // (token-backed), the variant's weight and any theme / per-instance
  // `labelStyle` overlay come together in the order
  // `CoreButtonStyle.labelStyleFor` gives them — the same function the
  // Flutter twin calls, so a composer that states only a role (`Calendar`'s
  // day cells) does not wear the variant's weight on one platform and not
  // the other. `emitTypography` then emits a `text-{role}` class for the
  // role plus any explicit scalar overlay (the variant's `font-weight`
  // among them) inline. The label colour normally flows through the
  // variant `text-` classes / `foregroundColor` override below;
  // `emitTypography` only emits a colour when the caller sets one
  // explicitly on `labelStyle` (an explicit per-instance override, mirrors
  // the badge reference).
  final labelEmit = emitTypography(
    null,
    CoreButtonStyle.labelStyleFor(
      size: size,
      variantLabelStyle: variantStyle.labelStyle,
      labelStyle: merged.labelStyle,
    ),
  );

  // Icon styles — the ambient icon theme `co_button` hands its content,
  // mirroring the Flutter `leadingIconTheme` / `trailingIconTheme`. Size:
  // [CoreButtonStyle.iconSizeFor] picks it, the function the Flutter
  // resolver calls too. Colour: only a colour the caller explicitly set on
  // the slot pins the glyph — otherwise the glyph keeps `currentColor`,
  // which is the button's own per-state foreground (idle / hover / pressed /
  // selected / disabled, all already emitted as classes or scoped rules
  // above). Every variant's icon tokens equal its foreground tokens
  // (`button_style_test.dart` fixes that invariant), so inheriting the
  // foreground paints exactly the variant icon colour the Flutter twin
  // resolves per state.
  //
  // `iconSizeFor` is the one place the order lives: a glyph beside a label
  // reads the size row's `leadingIconStyle`, a `square` / `circle` button's
  // glyph (no label to sit beside) reads the row's `iconShapeIconStyle`, and
  // what the caller or theme stated on the slot wins over either row.
  final iconShaped = shape != .rectangle;
  final iconSize = CoreButtonStyle.iconSizeFor(
    size: size,
    iconShaped: iconShaped,
    iconShapeOverride: merged.iconShapeIconStyle,
    leadingOverride: merged.leadingIconStyle,
    trailingOverride: merged.trailingIconStyle,
  );
  // The instance's own shape-glyph statement — only a shaped button reads
  // it, and it rides last in the slot merges below so it outranks a slot
  // statement, the order `iconSizeFor` gives the size.
  final iconShapeOverride = iconShaped ? merged.iconShapeIconStyle : null;
  final leadingIconStyle = CoreIconStyle(
    size: iconSize,
  ).merge(merged.leadingIconStyle).merge(iconShapeOverride);
  final trailingIconStyle = CoreIconStyle(
    size: iconSize,
  ).merge(merged.trailingIconStyle).merge(iconShapeOverride);

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the root `<button>` Tailwind className.
  ///
  /// Stacks base layout classes, variant-state colour classes
  /// ([_buildVariantClasses]), size-token height class, and the
  /// `aspect-square` structural class for `square` / `circle` shapes.
  /// Border radius / padding live inline (single inline signature).
  String buildRootClassName() {
    final classList = [
      // Marks this element as a component surface at [role] — the same
      // hook `OutlinedContainer` carries, restated here because Button
      // can't compose that primitive (see `resolveButton`'s doc). The
      // style rule it selects restates the fill at the material's share
      // and frosts, bends and edges the box.
      //
      // Only on a button that paints a fill at rest. Handed the material, a
      // ghost / plain button is frosted behind nothing and edged
      // around a box that is not there — a hover wash is a state, not a
      // box.
      if (hasFill) ...webSurfaceMarkerFor(role),
      if (dashedBorder) WebLayout.relative,
      WebLayout.inlineFlexCenter,
      // Clamp the inline-flex button to its parent's width so it shrinks
      // to a narrow pane instead of growing past it (Flutter clamps via
      // its parent `ConstrainedBox`/`SizedBox` constraints; the Web
      // inline-flex box has no such cap without this). `max-width: 100%`
      // only caps width — it does not clip, so the focus ring (an outline
      // painted outside the box) is unaffected.
      WebLayout.maxWFull,
      labelEmit.className,
      // No `transition-*` utility here, deliberately. The button's whole
      // transition — both the chrome group and the press pair — is one
      // declaration in the shared `kControlShadowPressMarker` rule, and a
      // Tailwind utility next to it would be a second equally-specific
      // declaration of the same shorthand: whichever the stylesheet
      // happens to emit last wins outright and resets the other's
      // `transition-property`. The clock this button wants travels as a
      // value instead — the `kControlChromeDurationVar` custom property
      // in the inline bundle below.
      //
      // The ring's resting state — `outline: 2px solid transparent`,
      // unconditional, so focusing only moves the outline's colour (and
      // geometry off the default) and the ring fades on the shared rule's
      // `outline-color` clock. A focus-prefixed `outline-none` would flip
      // `outline-style` on focus instead, starting the colour transition
      // from the text colour.
      'outline-none',
      // The ring rides utility classes only on the class-safe path; a raw
      // override colour / sub-1 opacity / off-scale width drops them (the
      // scoped rule paints the ring instead).
      if (ringClassSafe)
        focusRingClassName(
          pseudo: .focusVisible,
          ringColor: focusRingColor,
          ringWidth: focusRingWidth,
          ringOffset: focusRingOffset,
        ),
      // A painted gap band opts into the shared band rule; its value is
      // published inline below.
      if (focusBand != null) kFocusBandMarker,
      // Cursor parity with Flutter `Clickable` (click while enabled,
      // forbidden while disabled). The native `disabled` attribute already
      // blocks activation + `:hover`, so `cursor-not-allowed` is shown
      // instead of `pointer-events-none` (which would suppress the cursor).
      'cursor-pointer',
      'disabled:cursor-not-allowed',
      // Press-squash affordance hook — carried unconditionally, but that
      // is not the same as the affordance applying unconditionally. The
      // marker is also this button's sole `transition` declaration (the
      // chrome group rides it), so withholding it would cost a button
      // its chrome easing, not just its press travel. Which buttons
      // actually travel is decided where the shadow is — the inline
      // bundle below zeroes the offset variables for a button that casts
      // nothing, since it has no vacated space to move into. That split
      // is deliberate: the marker says "this control participates", the
      // values say "by this much". Do not re-gate the marker itself.
      //
      // Both shadow origins qualify equally — the injected
      // `--coui-control-shadow` and a caller-stated one (`Fab`'s
      // elevation) — mirroring the Flutter resolver, which likewise
      // asks whether a shadow resolved at all rather than which of the
      // two it came from. The marker alone does nothing; see
      // `kControlShadowPressMarker`'s doc comment for why the effect
      // itself is a style-scoped rule, not a class-level one.
      kControlShadowPressMarker,
      // Press-shrink hook — only when this control shrinks at all, so a
      // button with feedback off or a `pressedScale` of `1.0` gains no
      // rule. The factor rides `kControlPressScaleVar` inline below; the
      // rule itself writes the standalone `scale` property on `:active`
      // only, so the rest render is untouched. Carried by an `<a>` the
      // same as by a `<button>` — the class does not depend on the tag.
      if (pressShrinks) kControlPressScaleMarker,
      _buildVariantClasses(
        variantStyle,
        disableHoverEffect: disableHoverEffect,
        backgroundOverride: merged.backgroundColor,
        foregroundOverride: merged.foregroundColor,
        borderOverride: merged.borderColor,
        hoverBackgroundOverride: merged.hoverBackgroundColor,
        hoverForegroundOverride: merged.hoverForegroundColor,
        hoverBorderColorOverride: merged.hoverBorderColor,
      ),
    ];

    // Height — size-token `h-{size}` Tailwind class (maps to
    // `var(--coui-size-N)`). Dropped when the caller pins an explicit
    // `height` override (then the inline `min-height` rem rule wins). Kept
    // as a class because height is a dimensional size token, not radius
    // / padding (signature gate only forbids radius / padding classes).
    if (merged.height == null) {
      // The control row's own variable, so a density re-points the row
      // (`--coui-control-height-*`) and not every 40px icon with it.
      classList.add('h-${sizeStyle.height!.tailwindControlHeight}');
    }

    // Shape — `square` / `circle` force a 1:1 aspect ratio so the
    // button collapses to a tight icon container. Radius / padding for
    // these shapes are emitted inline above, so only the structural
    // `aspect-square` class remains here.
    if (shape != .rectangle) classList.add(WebLayout.aspectSquare);

    if (expanded) classList.add(WebLayout.wFull);

    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the root `<button>` inline-CSS bundle.
  ///
  /// Emits border radius and padding inline (single inline signature),
  /// typography overrides, colour
  /// overrides for background / foreground / border, the resolved border
  /// (width / colour / dashed style), dimensional caps, and the
  /// animation duration override.
  Styles buildRootInlineStyles() {
    final raw = {
      // Border radius — always inline (`(merged ?? default).toValue()`).
      'border-radius': borderRadius,
      // Padding — always inline (size-default / icon-shape / override).
      ...paddingDeclarations,
      // Border width — resolved (variant / override) value, always
      // inline.
      'border-width': strokeWidthCss(borderWidth),
      // The line's width, so a material's edge band reaches the outside of
      // the border instead of one border inside it.
      if (hasFill) ...surfaceBleedVar(strokeWidthCss(borderWidth)),
      // Chrome transition clock — read by the shared
      // `kControlShadowPressMarker` rule, which owns the button's only
      // `transition` declaration. Radius / padding / border width above
      // are inline values that would otherwise snap to their new number
      // the instant `shape` / `size` / `variant` changes, while the
      // Flutter twin eases the same set through one `AnimatedContainer`.
      // `durationMsCss` keeps a token-step duration on the
      // `--coui-duration-*` variable, which is how the reduced-motion
      // media query reaches this.
      kControlChromeDurationVar: disableTransition
          ? _kNoTransitionClock
          : durationMsCss(animationDuration),
      // Engage-squash clock override — read by the same shared rule's
      // press pair (`translate` / `box-shadow`, #4407). Published
      // unconditionally (not gated on `disableTransition` — the pair's
      // own trigger, `:hover`/`:active`, is what decides whether it ever
      // runs, not this button's chrome-transition toggle) so a caller
      // that overrides `CoreButtonStyle.castHideDuration` reaches Web the
      // same way it already reaches Flutter's `resolveButton`. Token-step
      // values route through `durationMsCss`, keeping the override inside
      // reach of `@media (prefers-reduced-motion:reduce)`.
      kControlEngageDurationVar: durationMsCss(castHideDuration),
    };

    // Typography overlay — explicit scalar overrides (font size / weight
    // / line-height / letter-spacing) emitted inline by `emitTypography`
    // alongside the `text-{role}` class composed onto the className. The
    // role itself stays on the class (dark-mode / scale reactive); only
    // the per-instance scalar overlay (and an explicit override colour, if
    // the caller set one) lands inline here.
    final labelInline = labelEmit.inline;
    if (labelInline != null) {
      raw.addAll(labelInline);
    }

    // Background / foreground colour overrides — raw (non-token) values
    // only. Token overrides emit as classes in `_buildVariantClasses`:
    // an inline `color` / `background-color` would beat the `hover:*`
    // pseudo classes on specificity and freeze hover recolouring (the
    // single-emit rule's class-XOR-inline split).
    if (merged.backgroundColor != null &&
        merged.backgroundColor!.token == null) {
      raw['background-color'] = merged.backgroundColor!.toValue();
    }
    if (merged.foregroundColor != null &&
        merged.foregroundColor!.token == null) {
      raw['color'] = merged.foregroundColor!.toValue();
    }

    // Border chrome — solid by default, switches to dashed when
    // `dashedBorder` is true. Border width / dashed colour are non-null
    // on the resolved layer (resolver folded in the variant /
    // design-system fallback).
    if (!dashedBorder && merged.borderColor != null) {
      raw['border-color'] = merged.borderColor!.toValue();
    }

    // Dimensional overrides.
    if (merged.width != null) {
      raw['width'] = '${merged.width! / kRemDivisor}rem';
    }
    // Height override is a MINIMUM, mirroring the Flutter button's
    // `ConstrainedBox(minHeight: height, maxHeight: infinity)` — a row grows
    // past it for taller content, and `height: 0` drops the floor so the
    // padding + content drive the height. Emitting a fixed `height` here
    // instead shrank `height: 0` rows below their padding on Web only
    // (cross-platform divergence with the Flutter min-height).
    // A caller's own height is not a row of the control ladder: it stays
    // as stated under any density, as on Flutter. Only the size row's
    // height (the `h-control*` class above) moves.
    if (merged.height != null) {
      raw['min-height'] = '${merged.height! / kRemDivisor}rem';
    }
    if (merged.minWidth != null) {
      raw['min-width'] = '${merged.minWidth! / kRemDivisor}rem';
    }
    if (merged.maxWidth != null) {
      raw['max-width'] = '${merged.maxWidth! / kRemDivisor}rem';
    }

    // Drop shadow / elevation. Composing components (e.g. `Fab`) set
    // `buttonStyle.boxShadow` for a floating elevation on an otherwise-
    // plain button; a plain button authors none. Routed through
    // `emitShadow` (not the raw list-to-CSS conversion) so a token-
    // matched override resolves through `var(--shadow-{key})` and stays
    // reactive to a surface-style override — mirrors every other
    // shadow-bearing resolver (Card, Popup, OutlinedContainer, …), which
    // this one alone was bypassing. When the caller states none,
    // `kControlShadowVar` takes over — it resolves to nothing for every
    // style except neo-brutalism, whose `controlShadow` gives a plain
    // button its signature cast without this resolver knowing the style
    // exists.
    // A cast is the shadow *of a filled box*. A variant with no fill
    // (ghost / plain) has no box to throw one, so the cast
    // detaches and reads as a free-floating black smear beside the label
    // rather than as depth. A caller who states a shadow on a transparent
    // button still gets it — this withholds only the one the *style*
    // injects, which the button never asked for. Mirrors the Flutter twin.
    // (`hasFill` is read once at the top of the resolver; the material
    // marker is gated on the same answer.)
    //
    // What this button wants its cast to *do*. `noShadow` withholds the
    // cast and its paired travel outright. `reverse` keeps the same
    // injected cast the style throws but hides it at rest instead of at
    // engage, and travels the opposite diagonal — the mirror of
    // `defaultMotion`, which is what every button already did.
    final castMotion = merged.castMotion ?? CoreButtonStyle.defaultCastMotion;
    final castsNever = castMotion == .noShadow;
    // A stated shadow outranks the motion axis — see the resolver-level
    // comment on `castsNever`. The axis withholds/redirects only what the
    // *style* injects, never what the caller wrote down: a control
    // handed its own shadow already casts at rest, so `reverse` has
    // nothing to invert there and this stays `false`. Mirrors the
    // Flutter resolver's `isReverseInjected`.
    final isReverseInjected =
        merged.boxShadow == null && castMotion == .reverse;
    final String restShadow;
    if (merged.boxShadow != null) {
      restShadow = emitShadow(
        merged.boxShadow!,
        base: const CoreColor.token(CoreColors.shadow).toValue(),
      );
    } else if (castsNever) {
      restShadow = 'none';
    } else if (isReverseInjected) {
      // No cast at rest — the same-shape, zero-alpha twin of the
      // injected cast (`kControlShadowGhostVar`) rather than the literal
      // `none`, so the transition to the full-alpha value at engage
      // stays a pure colour interpolation instead of risking a
      // mismatched-layer-count flash (`process/verify.md` §7-24).
      restShadow = hasFill ? kControlShadowGhostVar : 'none';
    } else {
      restShadow = hasFill ? kControlShadowVar : 'none';
    }
    // A band-on button leads its resting shadow with the zero-alpha band
    // (see `focusBandRest`); the cast itself stays on the list-safe twin
    // below, which the shared focus rule composes under the painted band.
    final restBox = focusBandRest == null
        ? restShadow
        : restShadow == 'none'
        ? focusBandRest
        : '$focusBandRest, $restShadow';
    raw['box-shadow'] = restBox;
    // Duplicated into a variable, not just a property, so
    // `_controlShadowPressRule`'s `:active` rule has something to fall
    // back to under a style with no press-squash vocabulary — see that
    // rule's doc comment for why a second selector-scoped rule per style
    // is not an option here.
    raw['--coui-button-rest-shadow'] = restBox;
    // A list-item-safe twin of the value above. `none` is only valid as
    // an *entire* `box-shadow` property value — `<shadow>#` excludes it
    // as one item in a comma-separated list — so a control with nothing
    // to cast cannot hand its literal `'none'` to
    // `ThemeConfig._controlFocusBandRule`, which composes the control's
    // rest shadow as the trailing layer under the focus gap band.
    // Composing `none` there does not drop just that layer; it makes the
    // whole `var()` substitution invalid at computed-value time, which
    // resolves the *entire* declaration to `box-shadow`'s initial value —
    // `none` again, this time swallowing the band too.
    // `0 0 #0000` is the same "renders nothing, still a valid layer"
    // token [kControlShadowVar]'s own root default already uses.
    raw['--coui-button-rest-shadow-layer'] = restShadow == 'none'
        ? '0 0 #0000'
        : restShadow;
    // The gap band, when this button paints one — read by
    // `ThemeConfig._controlFocusBandRule` on `:focus-visible` (the class
    // that gates that rule is composed above). Absent otherwise, so a
    // band-less button's focus leaves its `box-shadow` untouched.
    if (focusBand != null) raw[kFocusBandVar] = focusBand;
    // The travel half of the press-squash, gated on the same answer the
    // line above just computed. The affordance is a *pair* — the cast
    // hides and the control moves into the space it vacated — so a
    // button that casts nothing has nothing to move into, and the
    // reference this style is drawn from agrees: its `noShadow` variant
    // carries no translate at all, while its `reverse` variant (no cast
    // at rest, one on hover) travels *backwards*. The rule is not "a
    // cast exists" but "the cast changes, and the travel matches that
    // change" — and here it does not change (`none` at rest, `none`
    // pressed), so the distance is zero.
    //
    // Written as a value rather than by withholding
    // `kControlShadowPressMarker`, because that marker also carries the
    // button's *only* `transition` declaration (the chrome group —
    // radius / padding / border / colours). Dropping it would leave
    // these variants snapping while every other button eases. Speaking
    // through values is what the global rule is built for: it reads
    // `var(--coui-control-shadow-offset-x/y)`, and an inline custom
    // property outranks the style-scoped block that publishes them for
    // this element alone. Under every style but neo-brutalism those
    // variables are already `0px`, so this writes what was there.
    //
    // `--coui-control-shadow-press` needs no such override: it resolves
    // to `none`, which is what this button's rest shadow already is.
    // Read from the same two facts the rest shadow above is built from,
    // not from the string it produced: a comparison against `'none'`
    // would stop firing the day `emitShadow` spells "nothing" any other
    // way, and a press affordance that quietly stops being suppressed is
    // invisible until someone holds a pointer down. This mirrors the
    // Flutter twin's `resolvedShadowLayers.isEmpty` condition term for
    // term — a stated-but-empty list counts as stating nothing there,
    // so it counts as nothing here too.
    final castsNothing =
        (merged.boxShadow?.isEmpty ?? true) && (castsNever || !hasFill);
    // `reverse`'s engage half — grows the cast instead of hiding it, and
    // travels the opposite diagonal from `defaultMotion`. Both overrides
    // below are this element's *own* inline declarations for the exact
    // custom properties `ThemeConfig._controlShadowPressRule` (global)
    // reads at `:hover`/`:active`, so they outrank the inherited
    // style-scoped values regardless of specificity — a `reverse` button
    // diverges from a `defaultMotion` sibling under the identical style
    // without either of them needing a second, style-scoped rule (that
    // would out-rank the specificity floor `kControlShadowPressMarker`'s
    // doc comment explains). Mutually exclusive with `castsNothing` —
    // the former needs `!hasFill`, this needs `hasFill`.
    final reverseEngaged = isReverseInjected && hasFill;
    if (reverseEngaged) {
      raw['--coui-control-shadow-press'] = 'var(--coui-control-shadow, none)';
    }
    // A single write for each property either way — computed as a
    // nullable local first rather than assigned from two separately
    // gated `if` blocks, so the property is only ever set in one place
    // in the text even though `castsNothing` and `reverseEngaged` reach
    // it from different reasons. `null` (neither condition) leaves the
    // inherited style-scoped value untouched.
    final offsetOverrideX = castsNothing
        ? '0px'
        : reverseEngaged
        ? 'var(--coui-control-shadow-offset-x-reverse, 0px)'
        : null;
    final offsetOverrideY = castsNothing
        ? '0px'
        : reverseEngaged
        ? 'var(--coui-control-shadow-offset-y-reverse, 0px)'
        : null;
    if (offsetOverrideX != null) {
      raw['--coui-control-shadow-offset-x'] = offsetOverrideX;
    }
    if (offsetOverrideY != null) {
      raw['--coui-control-shadow-offset-y'] = offsetOverrideY;
    }
    // The press shrink's factor, and — for a control that casts nothing —
    // the style gate restored. A style whose engage signal is the travel
    // stands the shrink down (`kControlPressShrinkVar: 0`); this control
    // has no shadow to travel into (its offsets were just zeroed above),
    // so without the shrink it would show no press at all. That is the
    // Flutter resolver's own condition: the shrink is pinned only when
    // the travel is non-zero.
    if (pressShrinks) {
      raw[kControlPressScaleVar] = '$pressedScale';
      if (castsNothing) raw[kControlPressShrinkVar] = _kPressShrinkOn;
    }

    return Styles(raw: raw);
  }

  /// Composes the content-wrapper `<span>` Tailwind className.
  ///
  /// Emits `flex items-center`. The gap between leading icon / label /
  /// trailing icon is rendered as explicit `Gap` widgets by
  /// `co_button.dart` (matching the Flutter widget), so no inline
  /// `gap` CSS lives on this wrapper.
  String buildContentClassName() =>
      expanded ? WebLayout.flexFullItemsCenter : WebLayout.flexItemsCenter;

  // Layout for the expanded-label `<span>` wrapper — emitted by
  // `co_button` only when `expanded`. Render-only: the layout vocabulary
  // lives in the resolver, not the widget. `text-start` pins the label to
  // the leading edge (mirroring the Flutter button's
  // `Expanded(Align(alignment: centerStart))`) so it never inherits an
  // ancestor's `text-align: center` (e.g. a centered preview / surface) —
  // the Flutter side is immune via the explicit `Align`, so the Web label
  // must be too (menu rows otherwise read centered on Web only).
  String buildExpandedLabelClassName() =>
      '${WebLayout.flex1} ${WebLayout.minWZero} text-start';

  // ─── Compose paint-ready chrome ───────────────────────
  // Dash overlay colour — the resolved dash colour re-emitted through
  // the `.text` target (token → `text-*` class, raw → inline `color`),
  // riding the `<svg>` so the `<rect>`'s `currentColor` stroke picks it
  // up without touching the button's own foreground classes.
  final dashTextEmit = dashedBorder
      ? emitColor(dashedBorderColor, dashedBorderColor, .text)
      : null;
  final dashOverlayClassName = [
    dashedOverlaySvgClassName(),
    ?dashTextEmit?.className,
  ].where((cls) => cls.isNotEmpty).join(' ');
  final dashTextInline = dashTextEmit?.inline;
  final dashOverlayStyles = dashTextInline == null
      ? dashedOverlaySvgStyles()
      : Styles.combine([
          dashedOverlaySvgStyles(),
          Styles(raw: dashTextInline),
        ]);

  return ResolvedButton(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    content: WebElementChrome(
      className: buildContentClassName(),
    ),
    expandedLabel: WebElementChrome(
      className: buildExpandedLabelClassName(),
    ),
    iconLabelGapStyle: iconLabelGapStyle,
    leadingIconStyle: leadingIconStyle,
    trailingIconStyle: trailingIconStyle,
    dashOverlay: dashedBorder
        ? WebElementChrome(
            className: dashOverlayClassName,
            inlineStyles: dashOverlayStyles,
          )
        : null,
    dashRect: dashedBorder
        ? WebElementChrome(
            className: '',
            inlineStyles: dashedOverlayRectStyles(
              // Same value as the solid-border path above
              // (`strokeWidthCss(borderWidth)` at the `border-width`
              // emit) — a dashed border is still stroke-axis-bound, so
              // it must ride the same `--coui-stroke-width-N` variable
              // rather than a literal the neo-brutalism `strokeFloor`
              // preset can't reach.
              strokeWidth: strokeWidthCss(borderWidth),
              dashLength: dashLength,
              dashGap: dashSpacing,
              radius: rectangleBorderRadiusCore.topLeft,
            ),
          )
        : null,
  );
}

// ═══════════════════════════════════════════════════
// File-private helpers (small pure functions, short signatures)
// ═══════════════════════════════════════════════════

/// Builds the variant-state colour Tailwind classes (normal / hover /
/// disabled / selected / focused) from a [CoreButtonVariantStyle] table
/// entry.
///
/// `*Override` arguments are non-null when the caller (resolver) is
/// emitting an inline-CSS override for that colour slot — the helper
/// then skips the corresponding default Tailwind class so the inline
/// override wins. The `entry.backgroundColor` etc. fields carry the
/// design-system default tokens (per-variant); transparent sentinels
/// are detected via `isTransparent` and omitted entirely (no
/// `bg-transparent` class emitted).
///
/// Every background class is paired with same-scope [surfaceFillClasses]
/// companions — the marker classes [resolveButton] adds to the root are
/// inert without them (a content-role material rule reads
/// [kWebSurfaceFillVar] and the token's own alpha beside it, not the `bg-*`
/// class directly). A pseudo-state's companions carry their alpha even when
/// it is 1, so a translucent rest fill cannot leak into an opaque state.
///
/// When [disableHoverEffect] is `true` every `hover:` class is skipped
/// so the button stays visually static under the pointer (mirrors the
/// Flutter `Clickable.disableHoverEffect`). The selected / focused
/// states are gated on `entry.useSelectedState` / `entry.useFocusedAsHover`
/// so they only emit for variants that opt in (mirrors the Flutter
/// resolver's `vs.useSelectedState` / `vs.useFocusedAsHover` checks).
String _buildVariantClasses(
  CoreButtonVariantStyle entry, {
  required bool disableHoverEffect,
  CoreColor? backgroundOverride,
  CoreColor? foregroundOverride,
  CoreColor? borderOverride,
  CoreColor? hoverBackgroundOverride,
  CoreColor? hoverForegroundOverride,
  CoreColor? hoverBorderColorOverride,
}) {
  final classes = <String>[];

  // Normal background — the variant token unless overridden; a
  // token-backed override emits as a class here (raw overrides go
  // inline in the caller).
  if (backgroundOverride == null) {
    if (!entry.backgroundColor.isTransparent) {
      classes
        ..add('bg-${entry.backgroundColor.tailwindColor}')
        ..addAll(surfaceFillClasses(entry.backgroundColor));
    }
  } else if (backgroundOverride.token != null) {
    classes
      ..add('bg-${backgroundOverride.tailwindColor}')
      ..addAll(surfaceFillClasses(backgroundOverride));
  }

  // Normal foreground — the variant token unless overridden; a
  // token-backed override emits as a class here so `hover:text-*`
  // keeps winning on hover (raw overrides go inline in the caller).
  if (foregroundOverride == null) {
    if (entry.foregroundColor.isTransparent) {
      classes.add('text-white');
    } else {
      classes.add('text-${entry.foregroundColor.tailwindColor}');
    }
  } else if (foregroundOverride.token != null) {
    classes.add('text-${foregroundOverride.tailwindColor}');
  }

  // Normal border — skip when user override present.
  if (borderOverride == null && entry.borderColor != null) {
    classes.add('border border-${entry.borderColor!.tailwindColor}');
  }

  // Hover states — suppressed entirely when `disableHoverEffect`.
  if (!disableHoverEffect) {
    // Hover background — per-instance override wins (emitted as a
    // `hover:` class since CSS `:hover` can't be driven inline), else
    // the variant hover token (dropped when an idle override is inline).
    // A RAW (token-less) override has no class — it paints via the scoped
    // `#scope:hover{...}` rule from `resolveButtonRules`, so the default
    // is still suppressed (the override supersedes it) but no class emits.
    if (hoverBackgroundOverride != null) {
      if (hoverBackgroundOverride.token != null) {
        classes
          ..add('hover:bg-${hoverBackgroundOverride.tailwindColor}')
          ..addAll(
            surfaceFillClasses(hoverBackgroundOverride, pseudo: 'hover:'),
          );
      }
    } else if (backgroundOverride == null &&
        !entry.hoverBackgroundColor.isTransparent) {
      classes
        ..add('hover:bg-${entry.hoverBackgroundColor.tailwindColor}')
        ..addAll(
          surfaceFillClasses(entry.hoverBackgroundColor, pseudo: 'hover:'),
        );
    }

    // Hover foreground — per-instance override wins (raw → scoped rule).
    if (hoverForegroundOverride != null) {
      if (hoverForegroundOverride.token != null) {
        classes.add('hover:text-${hoverForegroundOverride.tailwindColor}');
      }
    } else if (foregroundOverride == null &&
        entry.hoverForegroundColor != null) {
      classes.add('hover:text-${entry.hoverForegroundColor!.tailwindColor}');
    }

    // Hover border — per-instance override wins (raw → scoped rule).
    if (hoverBorderColorOverride != null) {
      if (hoverBorderColorOverride.token != null) {
        classes.add('hover:border-${hoverBorderColorOverride.tailwindColor}');
      }
    } else if (borderOverride == null && entry.hoverBorderColor != null) {
      classes.add(
        entry.hoverBorderColor!.isTransparent
            ? 'hover:border-transparent'
            : 'hover:border-${entry.hoverBorderColor!.tailwindColor}',
      );
    }

    // Pressed states. `:active` matches whenever `:hover` also does — a
    // pointer held down on a hovered element satisfies both — so a
    // variant that leaves these unset needs no `active:` class at all;
    // the sibling `hover:*` class keeps painting, which is the same
    // "pressed reads as hover" fallback the Flutter resolver gets from
    // `vs.pressedX ?? vs.hoverX` (mirrored here by simply not emitting
    // anything, rather than restating the hover value). When a variant
    // does populate a pressed slot (`destructive` today), Tailwind's
    // `active` > `hover` variant sort order gives the emitted
    // `active:*` class the later, winning source position at equal
    // specificity — the same convention every `hover:bg-X active:bg-Y`
    // Tailwind button already relies on.
    if (backgroundOverride == null && entry.pressedBackgroundColor != null) {
      classes
        ..add(
          'active:bg-${entry.pressedBackgroundColor!.tailwindColor}',
        )
        ..addAll(
          surfaceFillClasses(entry.pressedBackgroundColor!, pseudo: 'active:'),
        );
    }
    if (foregroundOverride == null && entry.pressedForegroundColor != null) {
      classes.add(
        'active:text-${entry.pressedForegroundColor!.tailwindColor}',
      );
    }
    if (borderOverride == null && entry.pressedBorderColor != null) {
      classes.add(
        entry.pressedBorderColor!.isTransparent
            ? 'active:border-transparent'
            : 'active:border-${entry.pressedBorderColor!.tailwindColor}',
      );
    }

    // Focus is not a state of the fill. A focused button keeps its resting
    // look and the focus ring (`resolveButton`) says where focus is, so no
    // `focus-visible:` colour class is emitted here — the Flutter resolver
    // paints the same. The rows that fold focus into hover do it on purpose
    // through `focus:bg-*` below (`useFocusedAsHover`: the two menu rows).
  }

  // Disabled background.
  if (backgroundOverride == null &&
      !entry.disabledBackgroundColor.isTransparent) {
    classes
      ..add('disabled:bg-${entry.disabledBackgroundColor.tailwindColor}')
      ..addAll(
        surfaceFillClasses(entry.disabledBackgroundColor, pseudo: 'disabled:'),
      );
  }

  // Disabled foreground — a disabled control takes the disabled ink over a
  // token-backed per-instance foreground too, as the Flutter resolver does
  // (its disabled branch precedes the override). A RAW override paints
  // inline, which no class can beat, so it keeps the old behaviour.
  if ((foregroundOverride == null || foregroundOverride.token != null) &&
      !entry.disabledForegroundColor.isTransparent) {
    classes.add('disabled:text-${entry.disabledForegroundColor.tailwindColor}');
  }

  // Disabled border.
  if (borderOverride == null && entry.disabledBorderColor != null) {
    classes.add('disabled:border-${entry.disabledBorderColor!.tailwindColor}');
  }

  // Selected background / foreground / border (e.g. card / active menu
  // item) — only when the variant opts into the selected state.
  if (entry.useSelectedState) {
    if (entry.selectedBackgroundColor != null) {
      classes
        ..add(
          'aria-selected:bg-${entry.selectedBackgroundColor!.tailwindColor}',
        )
        ..addAll(
          surfaceFillClasses(
            entry.selectedBackgroundColor!,
            pseudo: 'aria-selected:',
          ),
        );
    }
    if (entry.selectedForegroundColor != null) {
      classes.add(
        'aria-selected:text-${entry.selectedForegroundColor!.tailwindColor}',
      );
    }
    if (entry.selectedBorderColor != null) {
      classes.add(
        'aria-selected:border-${entry.selectedBorderColor!.tailwindColor}',
      );
    }
  }

  // Focused background (e.g. menu) — only when the variant treats focus
  // as hover.
  // Focus folds into hover on these rows, so a token-backed per-instance
  // fill states the focused fill too (hover first, else idle) — the Flutter
  // resolver paints the same (`hoverBackgroundOverride ?? backgroundOverride`
  // on a focused button). Left to the variant's own focused fill, a
  // focused button would beat its stated fill: `focus:` utilities sort
  // after the plain and `hover:` ones.
  if (entry.useFocusedAsHover && entry.focusedBackgroundColor != null) {
    final stated = hoverBackgroundOverride ?? backgroundOverride;
    final focusFill = stated != null && stated.token != null
        ? stated
        : entry.focusedBackgroundColor!;
    classes
      ..add('focus:bg-${focusFill.tailwindColor}')
      ..addAll(surfaceFillClasses(focusFill, pseudo: 'focus:'));
  }

  return classes.join(' ');
}

/// Resolves the scoped `<style>` rules for a `Button` whose pseudo-state
/// chrome moves off the preset Tailwind classes — see
/// [ResolvedButtonRules]. Returns empty CSS on the default path
/// ([resolveButton] keeps the utility classes in that case: class XOR
/// rule).
///
/// The merge chain mirrors [resolveButton] exactly (`variant` threads
/// through), so the class-drop conditions and the scoped rules always see
/// the same resolved values.
ResolvedButtonRules resolveButtonRules(
  BuildContext context, {
  required String scopeId,
  required CoreButtonVariant variant,
  CoreButtonStyle? buttonStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.button;
  final merged = resolveStyleChain(const CoreButtonStyle(), [
    csTheme?.style,
    csTheme?.variantStyles?[variant],
    buttonStyle,
  ]);
  final variantStyle = CoreButtonStyle.defaultsByVariant[variant]!;

  final selector = '#$scopeId';
  final buffer = StringBuffer();

  // Focus ring — scoped when the outline leaves the class vocabulary.
  // Merge chain mirrors `resolveButton`'s `focusOutlineSlot` exactly
  // (base → variant default → per-instance) so the class-drop condition
  // there and the scoped rule here always agree on the same value.
  final slot = CoreButtonStyle.defaultFocusOutlineStyle
      .merge(variantStyle.focusOutlineStyle)
      .merge(merged.focusOutlineStyle);
  final ringWidth = slot.borderWidth!;
  final ringOffset = slot.align! - ringWidth;
  final ringColor = slot.borderColor!;
  final ringOpacity =
      slot.ringOpacity ?? CoreFocusOutlineStyle.defaultRingOpacity;
  if (!focusRingOutlineIsClassSafe(
    ringColor: ringColor,
    ringOpacity: ringOpacity,
    ringWidth: ringWidth,
    ringOffset: ringOffset,
  )) {
    buffer.write(
      focusRingScopedRule(
        scopeSelector: selector,
        pseudo: .focusVisible,
        ringColor: ringColor,
        // The band never rides this rule: the button's unconditional
        // inline rest `box-shadow` would outrank it. `resolveButton`
        // publishes it on `kFocusBandVar` for the shared `ThemeConfig`
        // rule instead, on both paths — so this rule states the outline
        // alone.
        offsetColor: CoreColor.transparent,
        ringWidth: ringWidth,
        ringOffset: ringOffset,
        ringOpacity: ringOpacity,
      ),
    );
  }

  // Hover colour overrides — a RAW (token-less) override has no `hover:`
  // class, so it paints via a scoped `#scope:hover{...}` rule.
  // Suppressed when the hover effect is disabled (mirrors the class path
  // in `_buildVariantClasses`).
  final disableHoverEffect =
      merged.disableHoverEffect ?? CoreButtonStyle.defaultDisableHoverEffect;
  if (!disableHoverEffect) {
    _writeRawHoverRule(
      buffer,
      merged.hoverBackgroundColor,
      .background,
      selector,
    );
    _writeRawHoverRule(buffer, merged.hoverForegroundColor, .text, selector);
    _writeRawHoverRule(buffer, merged.hoverBorderColor, .border, selector);

    // State-layer overlay (`stateLayer` on `CoreButtonVariantStyle`) —
    // `secondary`/`outline`/`ghost` composite a `foregroundColor`-tinted
    // wash over the resting fill rather than diluting the fill itself. Web
    // EMIT is theme-free (no build-time RGB to blend,
    // → `resolver/resolver-pattern.md`), so the
    // browser blends at paint time via `color-mix()` on the same two token
    // inputs Flutter's `Color.alphaBlend` composites. Skipped when the
    // instance overrides the fill (resting or hover): the base the wash
    // composites over would then be the caller's, not the variant's.
    //
    // The base colour's own `opacity` rides along as a CSS alpha suffix
    // (`rgb(var(--coui-X) / N%)`) rather than a bare `rgb(var(--coui-X))`
    // — `ghost`'s resting fill is fully transparent (opacity 0), and
    // `color-mix()` only reproduces that "translucent wash over whatever's
    // behind the page" look if the base operand's own alpha is carried
    // into the mix (a 0-alpha base contributes none of its own colour, so
    // the result reduces to the overlay colour at the overlay's opacity —
    // exactly the plain-translucent-paint case `outline`'s fully opaque
    // base doesn't need). Omitting it silently painted `ghost`'s hover as a
    // near-opaque grey instead of a 3% wash.
    //
    // Hover and pressed are the two weights a button draws; focus has none
    // (the ring is its indicator).
    //
    // The instance's ramp wins over the variant's, and the wash is tinted
    // with the colour the label rests in — the instance's
    // `foregroundColor` when it states one, as Flutter's `alphaBlend`
    // reads it. A `plain` button on a coloured surface (a banner or toast
    // action) states both: its label is pinned to the surface colour, so
    // the wash is the only hover cue it has. The tint drops its own
    // opacity (`withOpacity(1)`) because the ramp states the weight —
    // Flutter's `withValues(alpha:)` replaces it the same way. A fill
    // override still skips the wash: the rule could not know the base it
    // would composite over.
    final layer = merged.stateLayer ?? variantStyle.stateLayer;
    final hoverOpacity = layer?.hover;
    final pressedOpacity = layer?.pressed;
    if (layer != null &&
        merged.backgroundColor == null &&
        merged.hoverBackgroundColor == null) {
      final bgToken = variantStyle.backgroundColor.token?.name;
      final tint = (merged.foregroundColor ?? variantStyle.foregroundColor)
          .withOpacity(1)
          .toValue();
      final String base;
      if (bgToken != null) {
        final bgOpacityPct = (variantStyle.backgroundColor.opacity * 100)
            .round();
        base = 'rgb(var(--coui-$bgToken) / $bgOpacityPct%)';
      } else {
        // `plain`'s resting fill is the token-less transparent sentinel —
        // a 0-alpha base, which `color-mix()` reduces to the tint at the
        // ramp's weight, as `ghost`'s 0 % token base does above.
        base = variantStyle.backgroundColor.toValue();
      }
      if (hoverOpacity != null) {
        buffer.write(
          '$selector:hover{background-color:'
          'color-mix(in srgb, $tint '
          '${(hoverOpacity * 100).round()}%, $base)'
          ' !important;}',
        );
      }
      // Written after `:hover` so it wins on equal specificity while the
      // pointer is held down — pressed outranks hover, as Flutter states
      // explicitly. Here it is the cascade that states it, so the ORDER
      // of these two writes is load-bearing.
      if (pressedOpacity != null) {
        buffer.write(
          '$selector:active{background-color:'
          'color-mix(in srgb, $tint '
          '${(pressedOpacity * 100).round()}%, $base)'
          ' !important;}',
        );
      }
    }
  }

  return ResolvedButtonRules(css: buffer.toString());
}

/// Writes a `#scope:hover{...}` rule for a RAW (token-less) hover colour
/// [override] on [target] into [buffer]. No-op for a null or token-bound
/// override (the token path rides a `hover:` utility class in
/// `_buildVariantClasses`).
void _writeRawHoverRule(
  StringBuffer buffer,
  CoreColor? override,
  ColorTarget target,
  String selector,
) {
  if (override == null || override.token != null) return;
  buffer.write(
    emitPseudoColor(
      override,
      override,
      target,
      pseudo: .hover,
      scopeSelector: selector,
    ).rule,
  );
}
