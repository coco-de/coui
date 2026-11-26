import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

/// The identity scale — "do not shrink". Not a design token: it is the
/// absence of the press shrink, the value a style whose engage signal is
/// a shift pins [ResolvedButton.pressedScale] to.
const double _kNoPressShrink = 1;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Button`.
///
/// Widget tree (`co_button.dart` decides which optional branches render):
///
/// ```text
/// ConstrainedBox (height / minWidth / maxWidth)
///   └─ Clickable (decoration, textStyle, leadingIconTheme,
///                mouseCursor, padding as WidgetStateProperty<T>)
///        └─ InjectedCast (boxShadow)              // when the style hands a cast
///             └─ SurfaceBlur (surfaceBlur / surfaceSaturation /
///                  surfaceBackdropBrightness / surfaceSheen)
///                                                 // a filled button, under a material
///                  └─ IntrinsicWidth > IntrinsicHeight > Row
///                       ├─ leading                // caller-supplied Widget, optional
///                       ├─ Gap (iconLabelGapStyle)  // only when leading != null
///                       ├─ Expanded > Align > child
///                       ├─ Gap (iconLabelGapStyle)  // only when trailing != null
///                       └─ IconTheme.merge (trailingIconTheme)
///                            └─ trailing          // caller-supplied Widget, optional
/// ```
///
/// Field grouping:
///
/// 1. **State-dependent chrome** — [WidgetStateProperty]\<T\>; the
///    paint cycle resolves per-state without re-running the merge.
/// 2. **State-independent chrome** — plain Flutter types
///    ([BorderRadius], [EdgeInsets], `double`, [Duration]) read as-is.
/// 3. **Nested style slots** — [CoreTextStyle] kept as the
///    `coui_core` type so the widget composes it with the ambient
///    typography context via `DefaultTextStyle.merge`.
class ResolvedButton {
  /// Creates a [ResolvedButton].
  const ResolvedButton({
    required this.decoration,
    required this.textStyle,
    required this.leadingIconTheme,
    required this.trailingIconTheme,
    required this.labelStyle,
    required this.height,
    required this.width,
    required this.minWidth,
    required this.maxWidth,
    required this.padding,
    required this.iconLabelGapStyle,
    required this.borderRadius,
    required this.borderWidth,
    required this.dashedBorder,
    required this.dashedBorderColor,
    required this.dashLength,
    required this.dashSpacing,
    required this.animationDuration,
    required this.disableHoverEffect,
    required this.focusOutlineStyle,
    required this.pressedTranslateOffset,
    required this.castHideDuration,
    required this.pressedScale,
    required this.boxShadow,
    required this.reverseCastMotion,
    required this.shapedBorderRadius,
    required this.curve,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
  });

  // ── State-dependent chrome (WidgetStateProperty) ────────────

  /// Per-state [BoxDecoration] (background colour, border, radius).
  ///
  /// Resolver builds this from the variant token table + per-instance
  /// override; the widget passes it to `Clickable.decoration` so
  /// hovered / focused / disabled / selected states pick the right
  /// value at paint time.
  final WidgetStateProperty<Decoration> decoration;

  /// Per-state label [TextStyle] (foreground colour).
  final WidgetStateProperty<TextStyle> textStyle;

  /// Per-state leading icon [IconThemeData] (size + colour).
  ///
  /// `IconThemeData` (Flutter framework type) rather than
  /// [CoreIconStyle] because `Button.leading` is an arbitrary
  /// [Widget] supplied by the caller — the resolver cannot pass
  /// [CoreIconStyle] to "the icon" directly. The widget paints the
  /// leading slot inside `IconTheme.merge(data: ..., child: leading)`
  /// so any [Icon] / [Icon] descendant inherits the right size and
  /// colour via Flutter's ambient-icon-theme path.
  ///
  /// Stateless overlay components (e.g. `Alert`) that instantiate
  /// `Icon` themselves expose `CoreIconStyle` directly instead —
  /// the value-type matches the child's contract, no `IconTheme.merge`
  /// needed. The choice is dictated by the child-widget transport
  /// mechanism, not by state-dependence.
  final WidgetStateProperty<IconThemeData> leadingIconTheme;

  /// Per-state trailing icon [IconThemeData] (size + colour) — see
  /// [leadingIconTheme] for the rationale.
  final WidgetStateProperty<IconThemeData> trailingIconTheme;

  // ── Nested style slots (CoreXxxStyle) ───────────────────────

  /// Resolved label text style (typography + per-instance override,
  /// no colour — colour flows through [textStyle] per state).
  ///
  /// Kept as [CoreTextStyle] (not Flutter [TextStyle]) so the widget
  /// can layer it onto the ambient typography context via
  /// `DefaultTextStyle.merge`. Mirrors the Web side's
  /// `ResolvedButton.labelStyle: CoreTextStyle?`.
  final CoreTextStyle labelStyle;

  // ── State-independent chrome (plain values) ─────────────────

  /// Effective fixed minimum height (logical px) — from the size
  /// variant default.
  final double height;

  /// Effective fixed width (logical px). `null` lets the button hug
  /// its content; `double.infinity` for `expanded` (layout intent —
  /// kept nullable because `null` carries the "hug content" signal).
  final double? width;

  /// Effective min width constraint (logical px). `null` defers to 0.
  ///
  /// Carries the shape for `square` / `circle`: those two say equal
  /// width and height, so the resolver floors this at [height] unless
  /// the caller states a width of their own.
  final double? minWidth;

  /// Effective max width constraint (logical px). `null` defers to
  /// `double.infinity`.
  final double? maxWidth;

  /// Effective padding (logical px, pre-scaling).
  final EdgeInsets padding;

  /// Nested [CoreGapStyle] slot for the gap between leading/trailing
  /// icon and label — forwarded straight to `Gap(gapStyle: …)`. The
  /// receiving `Gap` runs its own resolve step (which applies
  /// `theme.scaling`), so this slot is the merged design-system default
  /// + per-instance override in pre-scaling units.
  final CoreGapStyle iconLabelGapStyle;

  /// Effective border radius — the widget applies a circle override
  /// at paint time when `shape == .circle`.
  final BorderRadius borderRadius;

  /// Effective border stroke width (logical px).
  final double borderWidth;

  /// Whether the border is rendered as a dashed stroke.
  final bool dashedBorder;

  /// Resolved dashed border colour (already converted from
  /// [CoreColor] to [Color]).
  final Color dashedBorderColor;

  /// Dash segment length for the dashed-border wrapper (raw logical
  /// px — this resolver's dimensional convention, matching height /
  /// width raw-forward).
  final double dashLength;

  /// Gap between dash segments (raw logical px).
  final double dashSpacing;

  /// Effective animation duration for chrome state transitions.
  final Duration animationDuration;

  /// The shape the chrome change takes over time.
  ///
  /// Paired with the duration beside it rather than left to the framework.
  /// Flutter's implicit animations default to `Curves.linear` and the Web
  /// twin's CSS transition does not — same length, different shape, so
  /// side by side one pane slides at a constant rate while the other eases
  /// in and out. Both platforms name the same `CoreEasing` alias instead.
  final Curve curve;

  /// Whether the hover visual effect is suppressed.
  final bool disableHoverEffect;

  /// Nested [CoreFocusOutlineStyle] slot — the design-system default
  /// merged with the per-instance override. The widget forwards this
  /// to the focus-outline paint surface (e.g. `FocusOutline` /
  /// `Clickable`) so per-instance / theme overrides reach the focus
  /// ring instead of being silently dropped. Mirrors the Web
  /// resolver's `focusOutlineSlot` 1:1.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// How far the button travels while engaged — raw-forwarded to
  /// `Clickable.pressedTranslate` (pre-scaling; `Clickable`'s own
  /// resolver applies `theme.scaling`, per the self-scaling-child rule).
  /// "Engaged" is press on every platform and, when `Clickable` is asked
  /// via `engageOnHover`, hover too — a pointer on desktop, a touch's
  /// only path on mobile, with no platform branch in `co_button.dart`.
  ///
  /// Sourced from the *active style's* `shadowOffsetAdd` — not from any
  /// particular shadow's own layer geometry — so [CoreOffset.zero]
  /// whenever either the button has no shadow to hide, or the style
  /// states no diagonal-offset vocabulary at all. Applies uniformly to a
  /// plain control's *injected* `controlShadow` and to a composing
  /// component's own stated `boxShadow` (`Fab`'s elevation) alike —
  /// under neo-brutalism, both retreat by the same style-defined
  /// distance on engage.
  final CoreOffset pressedTranslateOffset;

  /// The shared clock for the engage-squash pair — the shadow hide
  /// (`co_button.dart`'s `InjectedCast.duration`) and the travel
  /// (`pressedTranslateOffset`, ridden through `Clickable`'s own
  /// `pressDuration` override) run on this one value so a change to
  /// either literal cannot desync them, mirroring the Web twin's single
  /// `transition` declaration (`ThemeConfig._controlShadowPressRule`)
  /// shared by both its `:hover` and `:active` branches.
  ///
  /// Routed through [resolveMotionDuration] here — not a bare
  /// `CoreDuration.ms50` literal — because `co_button.dart` reads this
  /// value directly rather than re-deriving it, so the reduced-motion
  /// answer has to be baked in at resolve time for both consumers to see
  /// it. `Clickable`'s own resolver applies the same wrap to whatever
  /// `pressDuration` it receives, so a caller relying on
  /// `CoreClickableStyle.defaultPressDuration` instead of this field
  /// still collapses to zero under reduced motion.
  final Duration castHideDuration;

  /// The scale the button shrinks to while pressed — handed to
  /// `Clickable.pressedScale`, which animates it on [castHideDuration].
  ///
  /// Already `1.0` when [pressedTranslateOffset] is non-zero: a style
  /// that says "pressed" by moving a casting control into its shadow
  /// does not also shrink it, so the two affordances never compound.
  /// The Web twin reaches the same answer through
  /// `--coui-control-press-shrink`, which that style zeroes and a
  /// non-casting button restores — the gate lives in values there
  /// because Web does not know the style at resolve time.
  final double pressedScale;

  /// The button's resting drop shadow — state-independent (the engaged
  /// hide-and-travel is a separate wrapper in `co_button.dart`, synced
  /// to [pressedTranslateOffset] on the same clock as `Clickable`'s
  /// translate, rather than living inside [decoration]'s own
  /// `AnimatedContainer`, which runs on [animationDuration] — a
  /// different, unrelated duration. Pairing the hide with the travel
  /// requires one shared clock; splitting them across two was the
  /// bug (`#4082` follow-up) — and the same requirement is why hover and
  /// press resolve into the one `engaged` value `co_button.dart` reads,
  /// rather than each animating this pair independently.
  final List<BoxShadow>? boxShadow;

  /// Whether [boxShadow] should be *hidden* at rest and shown while
  /// engaged, the mirror of the default hide-on-engage polarity —
  /// `true` exactly when [CoreButtonStyle.castMotion] resolved to
  /// [CoreCastMotion.reverse] on a button whose cast is the style's own
  /// injected one (never on an authored [CoreButtonStyle.boxShadow] —
  /// see the resolver's `isReverseInjected`).
  ///
  /// `co_button.dart` reads this to flip the sign on the visibility
  /// formula it already runs off `hasSignatureShadow` / `engaged`; the
  /// travel direction itself is already baked into
  /// [pressedTranslateOffset] by the resolver, so this field only ever
  /// touches the InjectedCast `visible` half of the pair.
  final bool reverseCastMotion;

  /// Effective border radius the button actually paints — the
  /// rectangle/square [borderRadius], overridden for the `circle` shape
  /// and, outranking both, an ambient `Join`'s strip radius. Exposed
  /// separately from [borderRadius] so the shadow wrapper's own
  /// decoration can match the painted silhouette exactly; [borderRadius]
  /// itself stays the unshaped value `DashedContainer` deliberately
  /// wants (circle buttons are not expected to carry a dashed border).
  final BorderRadius shapedBorderRadius;

  // ── Surface material (the part the fill share cannot carry) ──

  /// Backdrop blur sigma behind the box, or `null` when the active style
  /// states no material, when this button paints no fill at rest, or when
  /// it sits inside another surface (the nested token drops the pass).
  ///
  /// The Web twin gets the same frost from the style rule its surface
  /// marker selects; without this the button frosted on one platform and
  /// only faded on the other.
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through the box, or null.
  final double? surfaceBackdropBrightness;

  /// Edge light along the box's contour, or null.
  final ResolvedSurfaceSheen? surfaceSheen;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Takes a drawn border's own dimensions back out of [padding]'s
/// **vertical** insets.
///
/// `Container` adds them on top, so handing it the authored padding makes
/// the control `2 × borderWidth` bigger than its size token. Deflating
/// first means the sum lands back on the token.
///
/// Only the vertical axis, because only the vertical axis is wrong. The
/// Web twin pins the size token as a fixed height, so `box-sizing:
/// border-box` makes a thicker border eat inward and the outer height
/// never moves — but its width is `auto`, where the border adds to the
/// used size exactly as Flutter's does. Deflating both axes would trade
/// one divergence for another: the height would come into line while the
/// width, which already agreed, stopped agreeing. Measured — a bordered
/// button was 2px wider than an unbordered one on both platforms before
/// this, and has to stay that way.
///
/// Clamped at zero per side rather than allowed to go negative: a border
/// thicker than the padding it sits in is a legitimate thing to ask for
/// (an icon-shape button pads by nothing at all), and the answer there is
/// "no room left", not a negative inset the framework would assert on.
/// The control still cannot fall under its token — `ConstrainedBox` holds
/// the floor.
EdgeInsets _deflateForBorder(
  EdgeInsets padding, {
  required double borderWidth,
  required bool drawnInEveryState,
}) {
  if (!drawnInEveryState || borderWidth <= 0) return padding;

  double take(double side) => math.max(0, side - borderWidth);

  return padding.copyWith(
    top: take(padding.top),
    bottom: take(padding.bottom),
  );
}

/// Resolves [ResolvedButton] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (per variant)
///   → theme.coreComponentTheme.button.style
///   → theme.coreComponentTheme.button.variantStyles[variant]
///   → widget.buttonStyle
///   → size / variant token table fallback
/// ```
ResolvedButton resolveButton(
  BuildContext context, {
  required CoreButtonVariant variant,
  required CoreComponentSize size,
  required CoreButtonShape shape,
  CoreSurfaceRole role = .defaultRole,
  CoreButtonStyle? buttonStyle,
  JoinItemData? joinItemData,
}) {
  final theme = Theme.of(context);
  final buttonTheme = theme.coreComponentTheme?.button;
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreButtonStyle(), [
    buttonTheme?.style,
    buttonTheme?.variantStyles?[variant],
    buttonStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final vs = CoreButtonStyle.defaultsByVariant[variant]!;
  final ss = CoreButtonStyle.defaultsBySize[size]!;

  // Whether this button paints a fill at rest. Two things hang on it — the
  // style's injected cast below, and the surface material here — and both
  // for the same reason: each is a statement about a filled box, and a
  // variant whose resting fill is transparent (ghost / plain / menu /
  // menubar / fixed) has no box to make translucent, frost behind or
  // light the edge of.
  final hasFill =
      scheme.resolve(merged.backgroundColor ?? vs.backgroundColor).toValue().a >
      0;

  // Surface material at [role] — the same seat every composing surface
  // (Card, Popup, …) reaches via `resolveOutlinedContainer`. Button can't
  // compose that primitive (its root already resolves hover × focus ×
  // disabled × selected as a `WidgetStateProperty`, and Web's twin is the
  // native `<button>` element itself — see #4348/#4360), so it reads the
  // same seat here, at this button's ambient nesting depth, and draws all
  // of it: the share folded into whichever background token each state
  // resolves to below, and the frost, chroma, dimming, edge light and bend
  // around the box ([ResolvedButton.surfaceBlur] and its siblings). `role`
  // defaults to `content` (see [CoreButtonContract.role]) — a plain button
  // has no evidence that it floats, so it takes the same layer every other
  // content-layer face does.
  //
  // Withheld from a button that paints no fill at rest, on both platforms:
  // the Web twin carries the surface marker only when the same fill paints.
  // Handed one anyway, such a button frosts a backdrop behind nothing and
  // draws a squared edge band around a box that is not there.
  final material = hasFill
      ? theme.surfaceFor(role, depth: SurfaceDepth.of(context))
      : null;
  final surfaceOpacity = material?.opacityIn(theme);

  /// Folds the active material's opacity into [color] — the same
  /// `token.scaleAlpha(material.opacityIn(theme))` step
  /// `resolveOutlinedContainer` runs on its own background token. Applied
  /// uniformly to whichever background token a state resolves to (idle /
  /// hover / selected / focused / disabled alike, plus the per-instance
  /// override below), mirroring how the material scales a static
  /// surface's one fill. Identity (`surfaceOpacity == null`) under every
  /// style that states no material.
  CoreColor materialFill(CoreColor color) =>
      surfaceOpacity == null ? color : color.scaleAlpha(surfaceOpacity);

  /// Suppresses a border stroke's colour (never its width) when the active
  /// material draws its own edge — the one rule every surface that resolves
  /// its own stroke goes through ([resolveSurfaceStroke]), so a button and
  /// the card beside it cannot disagree about it. Only on a button that
  /// takes the material: one that rests unfilled keeps its stroke, as its
  /// Web twin does — it carries no surface marker for the style rule to
  /// clear. `null` in, `null` out, so a state with no border stays
  /// borderless instead of gaining a transparent one to paint.
  Color? suppressBorder(Color? color) => color == null || material == null
      ? color
      : resolveSurfaceStroke(theme, color, role: role);

  // The rest of the material — the part `materialFill` cannot carry. A
  // nested button (inside another surface) gets the nested token, whose
  // backdrop pass is dropped and whose edge stays, the way every nested
  // surface's is.
  final surfaceBlur = material?.blurRadius;
  final surfaceSaturation = material?.saturation;
  final surfaceBackdropBrightness = material?.backdropBrightnessIn(theme);
  final surfaceSheen = material == null
      ? null
      : resolveSurfaceSheen(theme, role: role);

  // ─── Resolved nested slot styles ──────────────────────
  // Icon size — `CoreButtonStyle.iconSizeFor` is the one place the order
  // lives: a glyph beside a label reads the size row's
  // `leadingIconStyle`, a `square` / `circle` button's glyph (no label to
  // sit beside) reads the row's `iconShapeIconStyle`, and what the caller
  // or theme stated on the slot wins over either row.
  final iconShaped = shape != .rectangle;
  final iconSize = CoreButtonStyle.iconSizeFor(
    size: size,
    iconShaped: iconShaped,
    iconShapeOverride: merged.iconShapeIconStyle,
    leadingOverride: merged.leadingIconStyle,
    trailingOverride: merged.trailingIconStyle,
  );
  // The instance's own shape-glyph statement (size and colour) — only a
  // shaped button reads it, and it rides last in the slot merges below so
  // it outranks a slot statement, the order `iconSizeFor` gives the size.
  final iconShapeOverride = iconShaped ? merged.iconShapeIconStyle : null;

  // Label text style — EMIT Stage 2 (Flutter). The size-keyed role
  // (token-backed), the variant's weight, and the theme / per-instance
  // `labelStyle` overlay, in the order `CoreButtonStyle.labelStyleFor`
  // gives them (the Web twin calls the same function), materialised via
  // the single-primitive `style.toValue(theme:)` path. Colour is dropped
  // here (passed `color: null`) because the label colour flows through
  // [buildTextStyle] per state; the per-instance colour override is
  // tracked separately as [labelColorOverride] so the per-state builder
  // can apply it after the variant token. Mirrors the badge reference.
  final labelCore = CoreButtonStyle.labelStyleFor(
    size: size,
    variantLabelStyle: vs.labelStyle,
    labelStyle: merged.labelStyle,
  );
  final labelTextStyle = labelCore.toValue(theme: theme);
  // Per-instance label colour override — `foregroundColor` (flat) else
  // the nested `labelStyle.color`. Resolved once so the per-state
  // builder doesn't re-run `scheme.resolve`.
  final labelColorCore = merged.foregroundColor ?? merged.labelStyle?.color;
  final labelColorOverride = labelColorCore == null
      ? null
      : scheme.resolve(labelColorCore).toValue();

  // Icon styles — baseline iconSize + foreground, merged with per-slot
  // override.
  final baseIconColor = merged.foregroundColor;
  final leadingIconStyle = CoreIconStyle(
    size: iconSize,
    color: baseIconColor,
  ).merge(merged.leadingIconStyle).merge(iconShapeOverride);
  final trailingIconStyle = CoreIconStyle(
    size: iconSize,
    color: baseIconColor,
  ).merge(merged.trailingIconStyle).merge(iconShapeOverride);
  // The colour a caller pinned on each slot — a shaped button's own glyph
  // statement outranks the slot's, like the size does.
  final leadingExplicitColor =
      iconShapeOverride?.color ?? merged.leadingIconStyle?.color;
  final trailingExplicitColor =
      iconShapeOverride?.color ?? merged.trailingIconStyle?.color;

  // ─── Resolved state-independent chrome ────────────────
  // Rectangle / square border radius — the per-instance override wins,
  // else `CoreButtonStyle.borderRadiusForSize`: the variant's own
  // `radius` when it states one, else the size row's corner (the control
  // height × 0.25). The precedence lives in Core, not here, so the Web
  // resolver cannot read it in a different order.
  final borderRadius =
      (merged.borderRadius ??
              CoreButtonStyle.borderRadiusForSize(
                size: size,
                variantRadius: vs.radius,
              ))
          .toValue(geometry: theme.geometry) *
      scaling;
  // No `scaling:` here, and that is the rule rather than an omission:
  // scale what Web emits in `rem`, leave what it emits in `px`. Height,
  // padding and radius all land as rem on the Web side and follow the
  // root font, so the size factor has to move them here too or the
  // platforms drift. `border-width` is emitted through `strokeWidthCss` as
  // fixed px precisely so a hairline stays a hairline — multiplying it
  // here would make Flutter's border thicker than Web's under a larger
  // size factor.
  // `button_border_box_size_test.dart` states the same thing from the
  // other side.
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? vs.borderWidth,
  );
  // Shape `.circle` overrides the rectangle/square radius above — circle
  // is a layout primitive expressed as a pill radius (per-instance
  // `circleBorderRadius` override → design-system default pill). An
  // ambient `Join` then outranks both: it owns the strip geometry, so its
  // per-item radius replaces the button's own to paint flush seams
  // (and join-radius outer corners) instead of leaving notches under the
  // join clip. State-independent — hoisted out of the per-state
  // `buildDecoration` closure below so [ResolvedButton.shapedBorderRadius]
  // can expose the same value the decoration paints.
  final shapedRadius = shape == .circle
      ? (merged.circleBorderRadius ?? CoreButtonStyle.defaultCircleBorderRadius)
            .toValue(geometry: theme.geometry)
      : borderRadius;
  final effectiveRadius = joinItemData?.borderRadius ?? shapedRadius;
  // Padding for the `square` / `circle` shapes collapses to the
  // icon-shape padding — the per-instance override else the
  // design-system default of zero — so the button reads as a tight icon
  // container, mirroring the Web resolver. The `rectangle` shape keeps
  // the per-instance override, else `CoreButtonStyle.paddingFor` — the
  // size ladder with the variant's inline override (`plain` sits
  // flush) applied in Core so both platforms derive it identically.
  //
  // A directional inset (start / end) resolves against the ambient reading
  // direction here, so the button keeps handing the widget a physical
  // `EdgeInsets` — the type every reader of [ResolvedButton.padding]
  // already has. Symmetric insets are direction-invariant, so for them
  // `resolve` returns the same value `toValue` did.
  final padding =
      (shape == .rectangle
              ? (merged.padding ??
                    CoreButtonStyle.paddingFor(
                      size: size,
                      paddingInline: vs.paddingInline,
                    ))
              : (merged.iconShapePadding ??
                    CoreButtonStyle.defaultIconShapePadding))
          .toGeometry(geometry: theme.geometry)
          .resolve(Directionality.maybeOf(context) ?? .ltr) *
      scaling;
  // Gap between leading icon / label / trailing icon. Nested
  // [CoreGapStyle] slot — merge the size-keyed default with the
  // per-instance override and forward raw (pre-scaling) to `Gap`,
  // which runs its own resolve / scaling step (Epic #1603 C12 — single
  // materialise, scaling owned by the receiving widget).
  final iconLabelGapStyle = ss.iconLabelGapStyle!.merge(
    merged.iconLabelGapStyle,
  );
  // Effective core border radius — the focus ring's radius, so the ring
  // hugs the corners the chrome actually paints. Same precedence as
  // [effectiveRadius] above: an ambient `Join` outranks the shape (its
  // seam corners are square, and a ring rounded there would sit on a
  // box that is not), and `circle` collapses to the pill radius.
  //
  // The join's *raw* radius, never its paint-ready `borderRadius`:
  // `FocusOutline` applies geometry and `* scaling` to whatever it is
  // handed, so the already-scaled value would come out scaled twice.
  final effectiveBorderRadiusCore =
      joinItemData?.coreBorderRadius ??
      (shape == .circle
          ? (merged.circleBorderRadius ??
                CoreButtonStyle.defaultCircleBorderRadius)
          : (merged.borderRadius ??
                CoreButtonStyle.borderRadiusForSize(
                  size: size,
                  variantRadius: vs.radius,
                )));
  // Single slot — design-system default merged with the per-instance
  // override. Every field is non-null after the merge, mirroring the
  // Web resolver's `focusOutlineSlot`. The effective border radius is
  // injected so the focus ring matches the button shape (mirrors the
  // `clickable_style.dart` resolver), since `FocusOutline` reads the
  // radius from the nested `focusOutlineStyle`.
  final focusOutlineStyle = CoreButtonStyle.defaultFocusOutlineStyle
      .merge(vs.focusOutlineStyle)
      .merge(merged.focusOutlineStyle)
      .copyWith(
        borderRadius:
            merged.focusOutlineStyle?.borderRadius ?? effectiveBorderRadiusCore,
      );
  // The size row's height moves a rung of the control ladder under the
  // theme density (the row's corner follows it inside `toValue` above). A
  // caller's explicit height is not a row of the ladder — composites
  // size affordance buttons with it — so it stays as stated.
  final height =
      (merged.height ?? theme.geometry.controlHeight(ss.height!)) * scaling;
  final animationDuration = resolveMotionDuration(
    context,
    merged.animationDuration ?? CoreButtonStyle.defaultAnimationDuration,
  );
  final dashedBorder =
      merged.dashedBorder ?? CoreButtonStyle.defaultDashedBorder;
  final dashedBorderColor = scheme
      .resolve(
        merged.dashedBorderColor ?? CoreButtonStyle.defaultDashedBorderColor,
      )
      .toValue();
  // Unscaled for the same reason as `borderWidth` above — these are the
  // dash pattern of that stroke, and a dash that grew while the stroke
  // it dashes did not would change the border's rhythm under a larger
  // size factor.
  final dashLength = merged.dashLength ?? CoreButtonStyle.defaultDashLength;
  final dashSpacing = merged.dashSpacing ?? CoreButtonStyle.defaultDashSpacing;
  final disableHoverEffect =
      merged.disableHoverEffect ?? CoreButtonStyle.defaultDisableHoverEffect;
  // Drop shadow / elevation. Composing components (e.g. `Fab`) set
  // `buttonStyle.boxShadow` to give an otherwise-plain button a floating
  // elevation; a plain button authors none. Always routed through
  // `theme.geometry.shadow(...)` — not gated on `merged.boxShadow != null`
  // — so a surface style whose identity is "every control casts a
  // shadow" (`controlShadow`, neo-brutalism) can contribute one to a
  // control that authors nothing. Every other preset's `controlShadow` is
  // empty, so this stays empty there, byte-identical to the old
  // null-shadow path. Tinted by the `CoreColors.shadow` token base,
  // mirroring the other shadow resolvers.
  final shadowBase = scheme
      .resolve(const CoreColor.token(CoreColors.shadow))
      .toValue();
  // A control that authors nothing takes the style's injected cast; one
  // that states its own (Fab's elevation) bends that instead. Read here
  // rather than substituted inside `geometry.shadow`, so the set of
  // things this style boxes is stated by the components that want it —
  // which is also how the Web twin reaches it (`kControlShadowVar`).
  final authoredShadow = merged.boxShadow ?? const <CoreShadowLayer>[];
  // A cast is the shadow *of a filled box*. A variant with no fill
  // (ghost / plain) has no box to throw one, so the cast
  // detaches and reads as a free-floating black smear beside the label
  // rather than as depth — which is what it did, until this was looked
  // at rendered. The unit tests could not see it: they assert the cast
  // is present, and present is exactly what was wrong.
  //
  // A caller who states a shadow on a transparent button still gets it.
  // This only withholds the one the *style* injects, which the button
  // never asked for.
  //
  // What this button wants its cast to *do*, and it is asked *after*
  // an explicitly stated shadow. A control that was handed a shadow was
  // handed it on purpose — the axis withholds the cast the *style*
  // injects, never one the caller wrote down. That is the precedence
  // the fill gate already set: a stated shadow on a transparent button
  // survives, because withholding it would take away the one thing
  // distinguishing the control that asked for it.
  //
  // A caller wanting no shadow at all already has a way to say so —
  // state none. Letting this value overrule a stated one would make two
  // fields of the same style object contradict, with one winning
  // silently.
  //
  // `noShadow` and `reverse` are the two values honourable without the
  // engage plumbing needing anything extra from the shadow itself —
  // `noShadow` because "never casts" needs no trigger, `reverse` because
  // it still throws the same injected cast, just on the other half of
  // the pair. `defaultMotion` is what every button already did.
  final castMotion = merged.castMotion ?? CoreButtonStyle.defaultCastMotion;
  // Reverse only reaches the cast a *style* injects — see
  // [CoreCastMotion.reverse]. An authored shadow takes the
  // `authoredShadow.isNotEmpty` branch below regardless of `castMotion`,
  // so this is false whenever there is one, and `co_button.dart` falls
  // back to [CoreCastMotion.defaultMotion]'s hide-and-travel for it —
  // the same precedence [CoreCastMotion.noShadow] already gets.
  final isReverseInjected = authoredShadow.isEmpty && castMotion == .reverse;
  final List<CoreShadowLayer> resolvedShadowLayers;
  if (authoredShadow.isNotEmpty) {
    resolvedShadowLayers = theme.geometry.shadow(authoredShadow);
  } else if (castMotion == .noShadow) {
    resolvedShadowLayers = const [];
  } else {
    // The contributed cast takes the brightness's strength alone; the
    // authored stack above takes it inside the full bend.
    resolvedShadowLayers = hasFill
        ? theme.geometry.strengthen(theme.geometry.controlShadow)
        : const [];
  }
  final boxShadow = resolvedShadowLayers.isEmpty
      ? null
      : resolvedShadowLayers.map((l) => l.toValue(shadowBase)).toList();
  // The engage-squash affordance (shadow hides, button travels into the
  // space it vacates on press *or* hover — see
  // [ResolvedButton.pressedTranslateOffset] and `co_button.dart`'s
  // `engaged` value) applies to *any* button that resolves to a
  // non-empty shadow, under any style that states
  // [CoreSurfaceGeometryConstraint.shadowOffsetAdd] — the style's own
  // "how far do I throw a shadow" vocabulary, not each button's own
  // per-layer offset. Two buttons under neo-brutalism (`Button`'s
  // injected `controlShadow` and `Fab`'s own stated elevation) travel by
  // the *same* style-defined distance rather than each button's exact
  // (and differently-blurred, multi-layer) cast — the retreat is a
  // statement about the *style*, not a literal undo of each shadow's
  // geometry. A style with no such vocabulary (every preset except
  // neo-brutalism) leaves every button's engage feedback exactly as
  // before (`CoreOffset.zero`, scale-shrink still carries the signal).
  // This is also the one condition Web can evaluate identically without
  // knowing which style is active at *resolve* time — `shadowOffsetAdd`
  // rides the same `--coui-control-shadow-offset-x/y` custom property
  // Web already emits per style, scoped to a marker any shadow-bearing
  // button carries (`kControlShadowPressMarker`) — so both platforms
  // scope the affordance the same way.
  //
  // [isReverseInjected] negates the diagonal rather than picking a
  // second style vocabulary — the reference's own `reverseBoxShadowX/Y`
  // tokens are the negated `boxShadowX/Y`, not an independent pair, so
  // the mirror lives here instead of asking every style to author a
  // second offset nobody but this value would read.
  final shadowOffsetAdd = theme.geometry.shadowOffsetAdd;
  final pressedTranslateOffset =
      resolvedShadowLayers.isEmpty || shadowOffsetAdd == null
      ? CoreOffset.zero
      : isReverseInjected
      ? CoreOffset(-shadowOffsetAdd.dx, -shadowOffsetAdd.dy)
      : CoreOffset(shadowOffsetAdd.dx, shadowOffsetAdd.dy);
  // See [ResolvedButton.castHideDuration] — one reduced-motion-aware
  // clock shared by the shadow-hide and the travel.
  final castHideDuration = resolveMotionDuration(
    context,
    merged.castHideDuration ?? CoreButtonStyle.defaultCastHideDuration,
  );
  // The press shrink — see [ResolvedButton.pressedScale]. Pinned to the
  // identity (no shrink) when the style's shift carries the engage
  // signal instead (DDR-1), so the widget hands `Clickable` one value
  // rather than re-deriving the gate.
  final pressedScale = pressedTranslateOffset != CoreOffset.zero
      ? _kNoPressShrink
      : merged.pressedScale ?? CoreButtonStyle.defaultPressedScale;

  // Per-instance colour overrides — converted to Flutter [Color] once
  // so the state builders below don't re-run `scheme.resolve`.
  final backgroundOverride = merged.backgroundColor != null
      ? scheme.resolve(materialFill(merged.backgroundColor!)).toValue()
      : null;
  final borderColorOverride = merged.borderColor != null
      ? scheme.resolve(merged.borderColor!).toValue()
      : null;
  // Per-instance hover overrides — mirror the idle overrides for the
  // hovered / focused state so hover chrome is per-instance settable
  // (previously variant-locked). `null` → fall through to the idle
  // override, else the variant hover token.
  final hoverBackgroundOverride = merged.hoverBackgroundColor != null
      ? scheme.resolve(materialFill(merged.hoverBackgroundColor!)).toValue()
      : null;
  final hoverForegroundOverride = merged.hoverForegroundColor != null
      ? scheme.resolve(merged.hoverForegroundColor!).toValue()
      : null;
  final hoverBorderColorOverride = merged.hoverBorderColor != null
      ? scheme.resolve(merged.hoverBorderColor!).toValue()
      : null;

  // Flutter's `Container` adds `decoration.padding` — which for a
  // `BoxDecoration` is the border's own dimensions — on top of whatever
  // padding it is handed. So a bordered control comes out
  // `2 × borderWidth` taller than the size token says, and the
  // `ConstrainedBox` below cannot pull it back — it states the token as a
  // minimum, and a floor does not cap. The Web twin has no such growth —
  // it pins the token as a fixed height and `box-sizing: border-box`
  // makes the border eat inward — so the same button rendered from the
  // same tokens is a different height on the two platforms.
  //
  // Measured at the medium size: content plus padding comes to 38, so
  // every pixel of border past the first pushes the control off its own
  // 40 token — 42 at two, 46 at four. This is not a property of any one
  // surface style; those numbers are from no style at all, with the
  // width handed in per instance. A style carrying a stroke floor just
  // makes it the default rather than something a caller opts into.
  //
  // Taking the border back out of the padding restores the token as the
  // outer size, which is also what the widget already claims a few
  // hundred lines down: every variant at a given size reads as the same
  // visual unit. It did not hold — a bordered variant stood taller than
  // its unbordered sibling in the same row.
  //
  // Nothing shipping moves: the drawn widths today are zero and one, and
  // both already land on the token — 38 plus a single-pixel border on
  // each side is the token exactly. This engages only where the control
  // was already growing past it.
  final borderInsetPadding = _deflateForBorder(
    padding,
    borderWidth: borderWidth,
    // Only when the border is drawn in *every* state. The width is one
    // value but the colour is per-state and may be absent in some of
    // them (a caller can hand a width to a variant that names no border
    // colour), and `Container` adds nothing for a state that draws no
    // border. Subtracting unconditionally would shrink those states
    // instead — a control that changes size on hover, which is worse
    // than one that is uniformly too big. Hover and selected fall back
    // to the idle colour, so the idle and disabled slots are what decide
    // it; an explicit override applies to every state that reads one.
    drawnInEveryState:
        borderColorOverride != null ||
        (vs.borderColor != null && vs.disabledBorderColor != null),
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Wrapped in [WidgetStateProperty.resolveWith] below so
  // the widget paint cycle calls them per state without re-running
  // the merge / fallback / conversion chain. Colour resolution flows
  // through `scheme.resolve(...).toValue()`.

  /// Resolves the [BoxDecoration] for the given [states].
  ///
  /// Reads per-state variant tokens, lets per-instance background /
  /// border overrides win, and applies the `circle` shape's pill
  /// radius at paint time (the resolver's [borderRadius] still holds
  /// the rectangle/square value).
  BoxDecoration buildDecoration(Set<WidgetState> states) {
    final isDisabled = states.contains(WidgetState.disabled);
    final isHovered = states.contains(WidgetState.hovered);
    final isPressed = states.contains(WidgetState.pressed);
    final isSelected =
        vs.useSelectedState && states.contains(WidgetState.selected);
    // Focus borrows hover's colours only where a variant opts in
    // (`useFocusedAsHover`: the two menu rows). Everywhere else a focused
    // button wears its resting look and the focus ring is the indicator —
    // there is no focus wash, because 8% of the label colour is a change
    // too small to be the thing that tells a keyboard user where they are.
    final isFocused =
        vs.useFocusedAsHover && states.contains(WidgetState.focused);

    Color bgColor;
    Color? border;

    if (isDisabled) {
      bgColor = scheme
          .resolve(materialFill(vs.disabledBackgroundColor))
          .toValue();
      border = vs.disabledBorderColor != null
          ? scheme.resolve(vs.disabledBorderColor!).toValue()
          : null;
    } else if (isSelected && vs.selectedBackgroundColor != null) {
      bgColor = scheme
          .resolve(materialFill(vs.selectedBackgroundColor!))
          .toValue();
      final selBorder = vs.selectedBorderColor ?? vs.borderColor;
      border = selBorder != null ? scheme.resolve(selBorder).toValue() : null;
    } else if (isPressed) {
      // Checked before `isHovered` — Flutter reports both simultaneously
      // true while a pointer is held down on a hovered target. Falls
      // through to the hover value on any field the variant does not
      // populate (see `CoreButtonVariantStyle`'s "=== Pressed ===" doc),
      // so a variant that never sets these paints identically to before
      // this state existed.
      bgColor = scheme
          .resolve(
            materialFill(
              vs.pressedBackgroundColor ?? vs.hoverBackgroundColor,
            ),
          )
          .toValue();
      final pressBorder =
          vs.pressedBorderColor ?? vs.hoverBorderColor ?? vs.borderColor;
      border = pressBorder != null
          ? scheme.resolve(pressBorder).toValue()
          : null;
    } else if (isHovered || isFocused) {
      if (isFocused && vs.focusedBackgroundColor != null) {
        bgColor = scheme
            .resolve(materialFill(vs.focusedBackgroundColor!))
            .toValue();
      } else {
        bgColor = scheme
            .resolve(materialFill(vs.hoverBackgroundColor))
            .toValue();
      }
      final hovBorder = vs.hoverBorderColor ?? vs.borderColor;
      border = hovBorder != null ? scheme.resolve(hovBorder).toValue() : null;
    } else {
      bgColor = scheme.resolve(materialFill(vs.backgroundColor)).toValue();
      border = vs.borderColor != null
          ? scheme.resolve(vs.borderColor!).toValue()
          : null;
    }
    // The state layer, applied once for whichever state is active rather
    // than repeated inside each branch. It always composites over the
    // RESTING fill, never over the branch's own result — the variants that
    // use it leave their plain hover/pressed colours equal to rest and let
    // this carry the whole state change, so blending over the branch value
    // would either double-apply or blend against the wrong base.
    //
    // Pressed outranks hover, and a focused button has no weight of its own
    // (see `isFocused` above) — focus plus hover is just hover, so the
    // overlay does not move when focus arrives.
    if (!isDisabled && !(isSelected && vs.selectedBackgroundColor != null)) {
      // One ramp, read in the order the states outrank each other. The
      // ramp's `focus` weight is not read here: a ramp states all three, and
      // `Button` draws the two that are a change of the button itself.
      // The instance's ramp wins over the variant's — a `plain` button on
      // a coloured surface states one because its label is pinned there.
      final layer = merged.stateLayer ?? vs.stateLayer;
      final double? stateLayerOpacity;
      if (layer == null) {
        stateLayerOpacity = null;
      } else if (isPressed) {
        stateLayerOpacity = layer.pressed;
      } else if (isHovered) {
        stateLayerOpacity = layer.hover;
      } else {
        stateLayerOpacity = null;
      }

      if (stateLayerOpacity != null) {
        // Tinted with the colour the label rests in — the instance's
        // `foregroundColor` when it states one — so the wash matches the
        // label it sits under. The Web twin mixes the same colour.
        bgColor = Color.alphaBlend(
          scheme
              .resolve(merged.foregroundColor ?? vs.foregroundColor)
              .toValue()
              .withValues(alpha: stateLayerOpacity),
          scheme.resolve(materialFill(vs.backgroundColor)).toValue(),
        );
      }
    }

    // Per-instance overrides win. Pressed / hovered / focused all prefer
    // the hover-specific override — no dedicated pressed instance
    // override exists (`CoreButtonStyle` mirrors only hover, not
    // pressed); other states use the idle override.
    if (isPressed || isHovered || isFocused) {
      bgColor = hoverBackgroundOverride ?? backgroundOverride ?? bgColor;
      border = hoverBorderColorOverride ?? borderColorOverride ?? border;
    } else {
      if (backgroundOverride != null) bgColor = backgroundOverride;
      if (borderColorOverride != null) border = borderColorOverride;
    }

    // After the overrides, not before: a material that draws its own edge
    // clears a stroke the caller stated as well as the variant's — the Web
    // twin's rule clears the inline override with `!important`, and every
    // `OutlinedContainer` surface suppresses the merged colour the same
    // way. Before the overrides, a stated border survived on this platform
    // alone.
    border = suppressBorder(border);

    // Fully-transparent backgrounds (ghost / plain idle) borrow the
    // HOVER target's RGB so the implicit hover transition interpolates
    // alpha only. `transparent` is alpha-0 BLACK — a straight
    // `Color.lerp` from it passes through a dark translucent mid-frame
    // that reads as the button background blinking on every hover
    // enter / exit (CSS interpolates premultiplied, so the Web twin
    // never showed it).
    if (bgColor.a == 0) {
      final hoverTarget =
          hoverBackgroundOverride ??
          backgroundOverride ??
          scheme.resolve(materialFill(vs.hoverBackgroundColor)).toValue();
      bgColor = hoverTarget.withValues(alpha: 0);
    }

    return BoxDecoration(
      color: bgColor,
      border: border != null ? .all(color: border, width: borderWidth) : null,
      borderRadius: effectiveRadius,
      // No `boxShadow` here — the resting/hidden-while-engaged shadow is a
      // separate wrapper in `co_button.dart` (`resolved.boxShadow` +
      // `resolved.pressedTranslateOffset`), synced to `Clickable`'s
      // translate on the same clock. This `AnimatedContainer` runs on
      // `resolved.animationDuration` (the hover/focus/selected transition
      // speed) — a shadow that hides here would animate on that clock
      // instead of the engage clock it is paired with.
    );
  }

  /// Resolves the per-state label [TextStyle] (foreground colour), keeping
  /// the typography from [labelStyle].
  TextStyle buildTextStyle(Set<WidgetState> states) {
    final isDisabled = states.contains(WidgetState.disabled);
    final isHovered = states.contains(WidgetState.hovered);
    final isPressed = states.contains(WidgetState.pressed);
    final isSelected =
        vs.useSelectedState && states.contains(WidgetState.selected);

    Color fgColor;

    if (isDisabled) {
      fgColor = scheme.resolve(vs.disabledForegroundColor).toValue();
    } else if (isSelected && vs.selectedForegroundColor != null) {
      // Selected wins over hover (mirrors `buildDecoration`'s selected
      // background precedence) — the contrasting label colour on the
      // selected fill.
      fgColor = scheme.resolve(vs.selectedForegroundColor!).toValue();
    } else if (isPressed) {
      // Checked before `isHovered` for the same reason as
      // `buildDecoration` — falls through to hover, then idle, on any
      // field the variant does not populate.
      fgColor = scheme
          .resolve(
            vs.pressedForegroundColor ??
                vs.hoverForegroundColor ??
                vs.foregroundColor,
          )
          .toValue();
    } else if (isHovered) {
      fgColor = scheme
          .resolve(vs.hoverForegroundColor ?? vs.foregroundColor)
          .toValue();
    } else {
      fgColor = scheme.resolve(vs.foregroundColor).toValue();
    }

    // Per-instance label colour wins. In the pressed / hovered state the
    // hover foreground override (else the label colour) wins — no
    // dedicated pressed instance override exists; other states use the
    // label colour. [labelColorOverride] was resolved once above.
    if (isPressed || isHovered) {
      fgColor = hoverForegroundOverride ?? labelColorOverride ?? fgColor;
    } else if (labelColorOverride != null) {
      fgColor = labelColorOverride;
    }

    // Typography (fontSize / fontWeight / letterSpacing / height) is the
    // pre-materialised [labelTextStyle] base; only the per-state colour is
    // overlaid. Focus is not a state of the label: it keeps the resting
    // colour and the ring says where focus is.
    return labelTextStyle.copyWith(color: fgColor);
  }

  /// Resolves the per-state [IconThemeData] for the given slot style
  /// (leading or trailing).
  IconThemeData buildIconTheme(
    CoreIconStyle slotStyle,
    CoreColor? explicitSlotColor,
    Set<WidgetState> states,
  ) {
    final isDisabled = states.contains(WidgetState.disabled);
    final isHovered = states.contains(WidgetState.hovered);
    final isPressed = states.contains(WidgetState.pressed);
    final isSelected =
        vs.useSelectedState && states.contains(WidgetState.selected);

    Color iconColor;
    if (isDisabled) {
      iconColor = scheme
          .resolve(vs.disabledIconColor ?? vs.disabledForegroundColor)
          .toValue();
    } else if (isSelected && vs.selectedForegroundColor != null) {
      // Selected leading/trailing icon follows the selected foreground
      // (contrast on the selected fill) — mirrors `buildTextStyle`.
      iconColor = scheme.resolve(vs.selectedForegroundColor!).toValue();
    } else if (isPressed) {
      // Checked before `isHovered` for the same reason as
      // `buildDecoration`. No dedicated pressed instance override
      // exists, so the per-instance slot still reads
      // `merged.hoverForegroundColor` (mirrors the hover branch below).
      iconColor = scheme
          .resolve(
            merged.hoverForegroundColor ??
                vs.pressedIconColor ??
                vs.pressedForegroundColor ??
                vs.hoverIconColor ??
                vs.hoverForegroundColor ??
                vs.foregroundColor,
          )
          .toValue();
    } else if (isHovered) {
      // Icon chrome flows through the slot style + foreground — the
      // hovered icon follows the per-instance `hoverForegroundColor`
      // override (else the variant hover icon / foreground tokens).
      iconColor = scheme
          .resolve(
            merged.hoverForegroundColor ??
                vs.hoverIconColor ??
                vs.hoverForegroundColor ??
                vs.foregroundColor,
          )
          .toValue();
    } else {
      // Per-instance foreground wins over the variant tokens — mirrors
      // `buildTextStyle`'s label-colour precedence so a `foregroundColor`
      // override recolours icons and text together.
      iconColor = scheme
          .resolve(merged.foregroundColor ?? vs.iconColor ?? vs.foregroundColor)
          .toValue();
    }

    // Only a colour the caller explicitly set on the per-slot icon
    // style pins the glyph across states. The slot's baseline colour is
    // derived from `foregroundColor` (see `baseIconColor`) — pinning
    // that too would freeze hover recolouring for any button with a
    // foreground override.
    if (explicitSlotColor != null) {
      iconColor = scheme.resolve(explicitSlotColor).toValue();
    }

    return IconThemeData(
      size: slotStyle.size ?? iconSize,
      color: iconColor,
    );
  }

  // ─── Compose paint-ready resolved object ──────────────
  return ResolvedButton(
    // The same alias the Web twin names for this element's CSS
    // transition. Chrome moving between states is `move`; a curve
    // stated on one platform and defaulted on the other is the
    // divergence nothing renders differently enough to notice until
    // the two are put side by side.
    curve: CoreEasing.move.toValue(),
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    decoration: WidgetStateProperty.resolveWith(buildDecoration),
    textStyle: WidgetStateProperty.resolveWith(buildTextStyle),
    leadingIconTheme: WidgetStateProperty.resolveWith(
      (states) =>
          buildIconTheme(leadingIconStyle, leadingExplicitColor, states),
    ),
    trailingIconTheme: WidgetStateProperty.resolveWith(
      (states) =>
          buildIconTheme(trailingIconStyle, trailingExplicitColor, states),
    ),
    labelStyle: labelCore,
    height: height,
    width: merged.width,
    // `square` / `circle` mean equal width and height — the enum's own
    // words. Flutter only ever forced the height, so the same code that
    // renders 32×32 on Web (`aspect-square`) rendered 20×32 here: as
    // wide as whatever the icon happened to be. Stated as a floor on
    // the same value the height uses, so the two axes cannot drift.
    //
    // A caller's own `minWidth` still wins — an explicit number is a
    // narrower statement than a shape, and the shape is what it falls
    // back to.
    minWidth: merged.minWidth ?? (shape == .rectangle ? null : height),
    maxWidth: merged.maxWidth,
    padding: borderInsetPadding,
    iconLabelGapStyle: iconLabelGapStyle,
    borderRadius: borderRadius,
    borderWidth: borderWidth,
    dashedBorder: dashedBorder,
    dashedBorderColor: dashedBorderColor,
    dashLength: dashLength,
    dashSpacing: dashSpacing,
    animationDuration: animationDuration,
    disableHoverEffect: disableHoverEffect,
    focusOutlineStyle: focusOutlineStyle,
    pressedTranslateOffset: pressedTranslateOffset,
    castHideDuration: castHideDuration,
    pressedScale: pressedScale,
    boxShadow: boxShadow,
    reverseCastMotion: isReverseInjected,
    shapedBorderRadius: effectiveRadius,
  );
}
