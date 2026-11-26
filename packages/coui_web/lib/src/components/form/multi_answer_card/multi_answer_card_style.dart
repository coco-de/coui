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
// ResolvedMultiAnswerCard
// ═══════════════════════════════════════════════════

/// Resolved styling values for Web `MultiAnswerCard`.
///
/// DOM shape:
///
/// ```text
/// Clickable (<div role="button">)   // composed interaction wrapper
///   └─ card (<div>, flex row)       // per-state chrome slot (below)
///        ├─ content (<div>)         // caller-provided answer body
///        ├─ Gap                     // ← checkboxGapStyle
///        └─ Checkbox                // selection mark ← checkboxStyle
/// ```
///
/// The resolver pre-bakes the four mutually-exclusive card chrome
/// states ([root] idle / [hoverRoot] / [selectedRoot] /
/// [disabledRoot]) so
/// `multi_answer_card.dart` only SELECTS one — runtime interaction
/// state never enters the resolver. Cursor / press feedback / focus
/// ring / disabled opacity are owned by the composed `Clickable`
/// (via [clickableStyle]), not by these slots.
///
/// Output of [resolveMultiAnswerCard] — the nested-merge chain
/// (`design system default` → `theme.multiAnswerCard.style` →
/// `widget.multiAnswerCardStyle`) is applied once.
class ResolvedMultiAnswerCard implements WebResolvedChrome {
  /// Creates a [ResolvedMultiAnswerCard].
  const ResolvedMultiAnswerCard({
    required this.root,
    required this.hoverRoot,
    required this.selectedRoot,
    required this.disabledRoot,
    required this.content,
    required this.checkboxGapStyle,
    required this.checkboxStyle,
    required this.checkboxSize,
    required this.clickableStyle,
  });

  /// Paint-ready chrome for the card `<div>` in its idle (unselected,
  /// un-hovered) state — transition className plus the dimensional +
  /// colour inline-CSS bundle.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the card `<div>` while hovered (enabled,
  /// unselected) — [root] with the hover background swapped in.
  final WebElementChrome hoverRoot;

  /// Paint-ready chrome for the card `<div>` while selected — [root] with
  /// the selected background / border colour / border width swapped in.
  /// Selected wins over hovered.
  final WebElementChrome selectedRoot;

  /// Paint-ready chrome for the card `<div>` while disabled (selected or
  /// not) — the dedicated disabled fill / border / text tokens swapped in.
  /// Disabled wins over every other state.
  final WebElementChrome disabledRoot;

  /// Layout of the `<div>` holding the caller's answer body — takes the
  /// row's free width so the checkbox stays on the trailing edge.
  final WebElementChrome content;

  /// Gap between the answer body and the trailing checkbox —
  /// `defaultCheckboxGapStyle` merged with the override, raw-forwarded to
  /// `Gap(gapStyle:)`.
  final CoreGapStyle checkboxGapStyle;

  /// Nested [CoreCheckboxStyle] slot for the composed trailing
  /// `Checkbox` — `defaultCheckboxStyle` merged with the override,
  /// raw-forwarded to `Checkbox(checkboxStyle:)`.
  final CoreCheckboxStyle checkboxStyle;

  /// Size of the composed trailing `Checkbox`.
  final CoreComponentSize checkboxSize;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// `CoreMultiAnswerCardStyle.defaultClickableStyle` merged with the
  /// per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMultiAnswerCard] for the given [context].
///
/// Walks the nested-merge chain (Epic #1302):
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.multiAnswerCard.style
///   → widget.multiAnswerCardStyle
/// ```
ResolvedMultiAnswerCard resolveMultiAnswerCard(
  BuildContext context, {
  CoreMultiAnswerCardStyle? multiAnswerCardStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.multiAnswerCard;

  final merged = resolveStyleChain(const CoreMultiAnswerCardStyle(), [
    csTheme?.style,
    multiAnswerCardStyle,
  ]);

  final backgroundColor =
      merged.backgroundColor ?? CoreMultiAnswerCardStyle.defaultBackgroundColor;
  final selectedBackgroundColor =
      merged.selectedBackgroundColor ??
      CoreMultiAnswerCardStyle.defaultSelectedBackgroundColor;
  final borderColor =
      merged.borderColor ?? CoreMultiAnswerCardStyle.defaultBorderColor;
  final selectedBorderColor =
      merged.selectedBorderColor ??
      CoreMultiAnswerCardStyle.defaultSelectedBorderColor;
  final hoverColor =
      merged.hoverColor ?? CoreMultiAnswerCardStyle.defaultHoverColor;
  final hoverBorderColor =
      merged.hoverBorderColor ??
      CoreMultiAnswerCardStyle.defaultHoverBorderColor;
  final disabledBackgroundColor =
      merged.disabledBackgroundColor ??
      CoreMultiAnswerCardStyle.defaultDisabledBackgroundColor;
  final disabledBorderColor =
      merged.disabledBorderColor ??
      CoreMultiAnswerCardStyle.defaultDisabledBorderColor;
  final borderWidth =
      merged.borderWidth ?? CoreMultiAnswerCardStyle.defaultBorderWidth;
  final selectedBorderWidth =
      merged.selectedBorderWidth ??
      CoreMultiAnswerCardStyle.defaultSelectedBorderWidth;
  final borderRadius =
      (merged.borderRadius ?? CoreMultiAnswerCardStyle.defaultBorderRadius)
          .toValue();
  // Body typography for the caller-supplied child, one emit per card
  // state — the token-backed base role emits `text-body-large
  // text-on-surface` classes and gives the per-instance
  // `bodyTextStyle` override an entry point (explicit overlays go inline).
  // Selected (enabled) takes the medium-weight label role at the same size;
  // disabled takes the dedicated disabled content colour.
  final bodyEmit = emitTypography(
    merged.bodyTextStyle,
    CoreMultiAnswerCardStyle.defaultBodyTextStyle,
  );
  final selectedBodyEmit = emitTypography(
    merged.selectedBodyTextStyle,
    CoreMultiAnswerCardStyle.defaultSelectedBodyTextStyle,
  );
  final disabledBodyEmit = emitTypography(
    merged.disabledBodyTextStyle,
    CoreMultiAnswerCardStyle.defaultDisabledBodyTextStyle,
  );
  // Nested slots — partial defaults merged with the override and
  // raw-forwarded (the composed Gap / Checkbox resolve the rest).
  final checkboxGapStyle = CoreMultiAnswerCardStyle.defaultCheckboxGapStyle
      .merge(merged.checkboxGapStyle);
  final checkboxStyle = CoreMultiAnswerCardStyle.defaultCheckboxStyle.merge(
    merged.checkboxStyle,
  );
  // Size-stability — layout stays completely static across states:
  // the in-flow border is always [borderWidth]; the selected state's
  // extra thickness paints as an inset `box-shadow` (paint-only, no
  // layout participation), so nothing layout-affecting ever animates
  // (animating border-width + compensating padding wobbles — browsers
  // snap border widths to device pixels frame-by-frame). The padding
  // absorbs the thickness difference once so the content sits at the
  // same inset as the Flutter twin (real border + compensated pad).
  //
  // The two halves are summed in CSS, not in Dart. The authored padding
  // is spacing — the Flutter twin bends it through the theme geometry
  // inside `OutlinedContainer` — and rides its spacing variable; the
  // compensation is a stroke difference the twin applies separately
  // (`AnimatedPadding`) and is pinned. Summed in Dart, the two would
  // leave the scale together and neither would follow a density.
  final basePadding = merged.padding ?? CoreMultiAnswerCardStyle.defaultPadding;
  final maxBorderWidth = borderWidth > selectedBorderWidth
      ? borderWidth
      : selectedBorderWidth;
  final borderCompensation = maxBorderWidth - borderWidth;
  String compensated(double side) => borderCompensation == 0
      ? spaceCss(side)
      : 'calc(${spaceCss(side)} + ${pinnedLengthCss(borderCompensation)})';
  final padding =
      '${compensated(basePadding.top)} '
      '${compensated(basePadding.right)} '
      '${compensated(basePadding.bottom)} '
      '${compensated(basePadding.left)}';
  final selectedShadowSpread = selectedBorderWidth > borderWidth
      ? selectedBorderWidth - borderWidth
      : 0.0;
  // Chrome state-transition duration — animates background / border /
  // border-radius under the selected / hover swap. Driven by
  // `merged.transitionDuration` (override) else the design-system
  // default (Epic #1603 chaining gate — override-first emit).
  final transitionDurationMs =
      (merged.transitionDuration ??
              CoreMultiAnswerCardStyle.defaultTransitionDuration)
          .inMilliseconds;
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreMultiAnswerCardStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the card `<div>` Tailwind className for one of the three
  /// states. Cursor / disabled feedback classes are owned by the
  /// composing `Clickable`, so layout, transition and the state's fill
  /// remain.
  ///
  /// The fill is a class, not an inline declaration. The material rule
  /// restates a marked surface's fill through a selector, and an inline
  /// `background-color` out-ranks every selector — so an inline fill kept
  /// this card opaque under a translucent material while its Flutter twin,
  /// composing `OutlinedContainer`, took the share. A raw override still
  /// goes inline, and a raw colour is one the material does not restate.
  ///
  /// Marks the card as a component surface — restated here rather than
  /// composing an `OutlinedContainer` Web widget (a single `<div>`, no
  /// DOM restructure); the Flutter twin composes the primitive.
  /// Unconditional across all three states: every fill (idle /
  /// hover / selected) is a real, opaque design token — no glyph rides
  /// on the fill, only caller-supplied text/content that already
  /// carries its own colour — so there is no fill-less-box risk in
  /// letting a material preset reach any of them.
  String buildRootClassName(CoreColor background, Emit bodyText) => [
    '${WebLayout.flexItemsCenterFull} transition-all',
    bodyText.className,
    emitColor(background, background, .background).className,
    ...webSurfaceMarkerFor(.content),
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Inline CSS for the card `<div>` — colour / border / radius /
  /// padding for one of the pre-baked states. The widget picks a
  /// state slot; state priority matches Flutter parity: `selected`
  /// wins over `hovered` wins over the idle (unselected) base.
  ///
  /// The border-width / padding are state-independent; the selected
  /// state's extra thickness rides an inset `box-shadow` whose spread
  /// animates from 0 (paint-only — the layout never moves during the
  /// transition). The shadow colour tracks the state border colour so
  /// the ring reads as one contiguous border.
  Styles buildRootInlineStyles({
    required CoreColor background,
    required CoreColor border,
    required double shadowSpread,
    required Emit bodyText,
  }) => .new(
    raw: {
      'transition-duration': durationMsCss(transitionDurationMs),
      // Raw overrides only — a token fill rides the state's class above.
      ...?emitColor(background, background, .background).inline,
      'border-color': border.toValue(),
      'border-style': 'solid',
      'border-width': strokeWidthCss(borderWidth),
      ...surfaceBleedVar(strokeWidthCss(borderWidth)),
      'border-radius': borderRadius,
      'padding': padding,
      // The border-thickening inset layer, then the cast the active style
      // contributes to a surface that states none — what the Flutter twin's
      // composed `OutlinedContainer` draws at rest elevation, and what this
      // inline value used to out-rank. `kControlShadowVar` resolves to
      // nothing under every style but the one that boxes surfaces.
      //
      // No rim: a rim decorates a surface that casts its own shadow, and
      // this card states none — the same gate the Flutter twin's container
      // keys `resolveSurfaceRim` on. The inset layer is a border, not a cast.
      'box-shadow':
          'inset 0 0 0 ${shadowSpread / kRemDivisor}rem '
          '${border.toValue()}, $kControlShadowVar',
      ...?bodyText.inline,
      // The other half of the surface marker above.
      ...surfaceFillVar(background),
    },
  );

  return ResolvedMultiAnswerCard(
    root: WebElementChrome(
      className: buildRootClassName(backgroundColor, bodyEmit),
      inlineStyles: buildRootInlineStyles(
        background: backgroundColor,
        border: borderColor,
        shadowSpread: 0,
        bodyText: bodyEmit,
      ),
    ),
    hoverRoot: WebElementChrome(
      className: buildRootClassName(hoverColor, bodyEmit),
      inlineStyles: buildRootInlineStyles(
        background: hoverColor,
        border: hoverBorderColor,
        shadowSpread: 0,
        bodyText: bodyEmit,
      ),
    ),
    selectedRoot: WebElementChrome(
      className: buildRootClassName(selectedBackgroundColor, selectedBodyEmit),
      inlineStyles: buildRootInlineStyles(
        background: selectedBackgroundColor,
        border: selectedBorderColor,
        shadowSpread: selectedShadowSpread,
        bodyText: selectedBodyEmit,
      ),
    ),
    disabledRoot: WebElementChrome(
      className: buildRootClassName(disabledBackgroundColor, disabledBodyEmit),
      inlineStyles: buildRootInlineStyles(
        background: disabledBackgroundColor,
        border: disabledBorderColor,
        shadowSpread: 0,
        bodyText: disabledBodyEmit,
      ),
    ),
    // Takes the row's free width and may shrink below its content's
    // intrinsic width so a long answer wraps instead of pushing the
    // checkbox out (the Flutter twin's `Expanded`).
    content: const WebElementChrome(
      className: '${WebLayout.flex1} ${WebLayout.minWZero}',
    ),
    checkboxGapStyle: checkboxGapStyle,
    checkboxStyle: checkboxStyle,
    checkboxSize: CoreMultiAnswerCardStyle.defaultCheckboxSize,
    clickableStyle: clickableStyle,
  );
}
