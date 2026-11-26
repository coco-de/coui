import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Dialog`.
///
/// Widget tree (`dialog.dart` decides which optional branches render):
///
/// ```text
/// (route) ScaleTransition > SurfaceFadeHost > FadeTransition   // barrierColor / transitionDuration / scale*
///   └─ optional SurfaceFadeAdopter    // only under that host (not a full-screen route)
///        └─ optional InjectedCast (panelBoxShadow) >   // rendered only when castOutsideBox
///           optional SurfaceBlur (surfaceBlur)
///             └─ ConstrainedBox (panelMinWidth / panelMaxWidth)
///                  └─ InsetShadow (panelInsetBoxShadow,
///                       radius: panelBorderRadius)
///                       └─ Container (panelBackgroundColor / panelBorderColor /
///                               panelBorderWidth / panelBorderRadius / panelPadding /
///                               panelBoxShadow unless castOutsideBox)
///                            └─ DefaultTextStyle + IconTheme
///                               (panelForegroundColor)
///                                 └─ Column
///                                      ├─ Row (header)             // rendered only when title / leading / trailing present
///                                      │    ├─ leading             // caller-supplied Widget, optional
///                                      │    ├─ Gap (sectionGapStyle) // rendered only when leading != null
///                                      │    ├─ Expanded >
///                                      │    │    DefaultTextStyle
///                                      │    │    (titleTextStyle) >
///                                      │    │    title
///                                      │    ├─ Gap (sectionGapStyle) // rendered only when trailing != null
///                                      │    └─ trailing            // caller-supplied Widget, optional
///                                      ├─ Gap (sectionGapStyle)    // rendered only when content != null
///                                      ├─ Flexible > ClipRect       // clip reaches contentClipMargin past the body
///                                      │    (contentClipMargin) >
///                                      │    SingleChildScrollView > // scrolls a body taller than the room left
///                                      │    DefaultTextStyle
///                                      │    (contentTextStyle) >
///                                      │    content
///                                      ├─ Gap (actionsGapStyle)    // rendered only when actions present
///                                      └─ one of (actionsLayout):
///                                           ├─ Row (actions,        // the list holds a Flexible / Spacer —
///                                           │    spacing:           // either layout
///                                           │    actionSpacing)
///                                           ├─ Wrap (actions,       // end: each action its own width,
///                                           │    spacing:           // wrapping onto actionRunSpacing rows
///                                           │    actionSpacing,     // at the end
///                                           │    runSpacing:
///                                           │    actionRunSpacing)
///                                           └─ DialogActionsStretchLayout
///                                                (actions,
///                                                spacing:           // stretch: an equal share each,
///                                                actionSpacing,     // every line filling its width
///                                                runSpacing:
///                                                actionRunSpacing)
/// ```
///
/// Every field is paint-ready: Flutter framework widgets receive their
/// native type (`Color`, `BorderRadius`, `EdgeInsets`, `TextStyle`,
/// `double`, `Duration`). The inter-slot `Gap` spacers receive the
/// resolved [sectionGapStyle] (head ↔ body) and [actionsGapStyle]
/// (body ↔ actions) slots straight through
/// `Gap(gapStyle: …)` — the parent forwards a raw [CoreGapStyle], and
/// `Gap` self-scales (Epic #2228 group 7 — Gap self-scale).
/// The adjacent action-button gap and the gap between wrapped rows are
/// rendered as native `Wrap.spacing` / `Wrap.runSpacing` — or the stretched
/// row's `spacing` / `runSpacing` under [actionsLayout] — with scaling
/// pre-applied by the resolver (see [actionSpacing], [actionRunSpacing]).
/// The nested action-button slot keeps [CoreButtonStyle] so `co_dialog`
/// forwards it to a `Button` action (asChild pattern, Epic #1302
/// 원칙 8). Panel chrome scaling is pre-applied so the widget does not
/// multiply by `theme.scaling` itself.
///
/// Per Epic #1603 옵션 B 최종: the dialog has no visual variant enum, so
/// the panel colours resolve from the single design-system colour table
/// ([CoreDialogStyle.defaultsByVariant]) with per-instance overrides on
/// top. No scalar semantic metadata is exposed here.
class ResolvedDialog {
  /// Creates a [ResolvedDialog].
  const ResolvedDialog({
    required this.panelBackgroundColor,
    required this.panelForegroundColor,
    required this.panelBorderColor,
    required this.panelBorderWidth,
    required this.panelBorderRadius,
    required this.panelPadding,
    required this.panelMinWidth,
    required this.panelMaxWidth,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.panelBoxShadow,
    required this.panelInsetBoxShadow,
    required this.barrierColor,
    required this.sectionGapStyle,
    required this.actionsGapStyle,
    required this.actionSpacing,
    required this.actionRunSpacing,
    required this.actionsLayout,
    required this.contentClipMargin,
    required this.routePadding,
    required this.transitionDuration,
    required this.scaleAnimationStart,
    required this.scaleAnimationEnd,
    required this.titleTextStyle,
    required this.contentTextStyle,
    required this.actionButtonStyle,
    this.castOutsideBox = false,
  });

  /// Effective panel background fill — override wins over the
  /// design-system `surface` token, with `surfaceOpacity` (when set)
  /// already folded in so the widget paints it as-is.
  final Color panelBackgroundColor;

  /// Panel foreground — [CoreDialogStyle.defaultsByVariant]
  /// `foregroundColor` resolved through the active scheme. The widget sets
  /// it as the panel's inherited text and icon colour, so whatever the
  /// panel holds that states no colour of its own (the leading / trailing
  /// slots) takes it — the Web twin's foreground class on the panel. The
  /// title and body do not read it: each paints its own typography
  /// default's colour ([titleTextStyle], [contentTextStyle]).
  final Color panelForegroundColor;

  /// Effective panel border stroke colour.
  final Color panelBorderColor;

  /// Effective panel border stroke width (logical px, scaling
  /// pre-applied).
  final double panelBorderWidth;

  /// Effective panel border radius (scaling pre-applied) — rounds the
  /// `Container` surface and the `SurfaceBlur` clip.
  final BorderRadius panelBorderRadius;

  /// Effective panel inner content padding (scaling pre-applied).
  final EdgeInsets panelPadding;

  /// Effective panel minimum width (logical px, scaling pre-applied).
  /// The route's room still wins — a narrower route narrows the panel.
  final double panelMinWidth;

  /// Effective panel maximum width (logical px, scaling pre-applied).
  final double panelMaxWidth;

  /// Optional backdrop blur sigma. `null` → no blur.
  final double? surfaceBlur;

  /// Chroma lift riding the same material treatment as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  ///
  /// Rides the same backdrop pass as [surfaceSaturation].
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Paint-ready panel elevation shadow (#3777) — the Modal/Dialog
  /// `shadow-xl` rung (`CoreDialogStyle.defaultPanelBoxShadow`), tinted
  /// by [CoreDialogStyle.shadowBaseColor] and resolved through the
  /// active scheme so it tracks dark mode. Consumed by the panel's
  /// `BoxDecoration.boxShadow`, or by `InjectedCast` where [castOutsideBox].
  final List<BoxShadow> panelBoxShadow;

  /// Whether [panelBoxShadow] is painted outside the box (`InjectedCast`)
  /// rather than by the panel's `BoxDecoration`.
  ///
  /// True where [panelBackgroundColor] is not opaque. A decoration's shadow
  /// is a filled shape behind the box, so it shows through a translucent
  /// fill — on Flutter only, because CSS paints an outer shadow outside the
  /// border box. An opaque fill hides it, and the panel keeps the plain tree.
  final bool castOutsideBox;

  /// Paint-ready claymorphism rim (#3463 pattern, parity with
  /// `Popup`/`Drawer`) derived from the same shadow stack — the active
  /// surface style rewrites both together, so a style-driven panel
  /// keeps a boundary even when the outer shadow itself is suppressed.
  /// Consumed by `InsetShadow.shadows`.
  final List<BoxShadow> panelInsetBoxShadow;

  /// Paint-ready barrier (scrim) colour — the overlay-colour token (or
  /// per-instance override) with [CoreDialogStyle.barrierOpacity] baked
  /// in via `scheme.resolve(...).toValue()`. Consumed by the route's
  /// `barrierColor` (mirrors Web's `color-mix(...)` backdrop).
  final Color barrierColor;

  /// Gap slot between the dialog's head and body — header row / content —
  /// and inside the header row between leading / title / trailing.
  /// Forwarded straight to `Gap(gapStyle: …)` — no manual
  /// `CoreGapStyle(size: …)` reconstruction in the widget body
  /// (Epic #1603 옵션 B nested-slot pattern). `Gap` self-scales, so
  /// the gap size stays in logical px here.
  final CoreGapStyle sectionGapStyle;

  /// Gap slot between the dialog's body and its actions row — the header
  /// row sits this far from the actions when the dialog has no content.
  /// Forwarded straight to `Gap(gapStyle: …)`; `Gap` self-scales, so the
  /// size stays in logical px here.
  final CoreGapStyle actionsGapStyle;

  /// Gap between adjacent actions on one line of the actions row
  /// (logical px, the theme density and scaling pre-applied). Whichever row
  /// [actionsLayout] builds reads it: `Wrap(spacing: …)` under
  /// [CoreDialogActionsLayout.end], the stretched row's `spacing` under
  /// [CoreDialogActionsLayout.stretch], and the `Row(spacing: …)` a list
  /// holding a `Flexible` / `Spacer` keeps — no manual `Gap` interleave.
  final double actionSpacing;

  /// Gap between the lines the actions wrap onto (logical px, the theme
  /// density and scaling pre-applied). Read as `Wrap(runSpacing: …)` under
  /// [CoreDialogActionsLayout.end] and as the stretched row's `runSpacing`
  /// under [CoreDialogActionsLayout.stretch].
  final double actionRunSpacing;

  /// How the actions row spreads its actions —
  /// [CoreDialogActionsLayout.end] lays them out in a `Wrap` at the panel's
  /// end, [CoreDialogActionsLayout.stretch] in the stretched row that gives
  /// each an equal share of the width. A list holding a `Flexible` /
  /// `Spacer` keeps its `Row` under either.
  final CoreDialogActionsLayout actionsLayout;

  /// How far past the body's own box the body keeps painting before the
  /// dialog clips it, on every side (logical px, scaling pre-applied —
  /// the focus outline it reaches for scales the same way). The widget
  /// inflates the body's clip by it.
  final double contentClipMargin;

  /// The room the dialog route leaves around the panel on every side
  /// (logical px, the theme density and scaling pre-applied). Read by the
  /// route (`DialogRoute`), which pads the dialog by it; a full-screen
  /// route ignores it.
  final double routePadding;

  /// Open/close transition duration.
  final Duration transitionDuration;

  /// Panel open-animation start scale.
  final double scaleAnimationStart;

  /// Panel open-animation end scale.
  final double scaleAnimationEnd;

  /// Paint-ready title [TextStyle] — [CoreDialogStyle.defaultTitleStyle]
  /// (`titleLarge` role, `onSurface` colour) merged with the per-instance
  /// `titleStyle` slot and materialised through `.toValue(theme:)`. The
  /// colour is the merged style's own — the default's unless the slot
  /// states one. Passed to `DefaultTextStyle.merge` so the title slot
  /// inherits typography.
  final TextStyle titleTextStyle;

  /// Paint-ready content [TextStyle] — [CoreDialogStyle.defaultContentStyle]
  /// (`bodyMedium` role, `onSurfaceVariant` colour) merged with the
  /// per-instance `contentStyle` slot and materialised through
  /// `.toValue(theme:)`. The colour is the merged style's own — the
  /// default's unless the slot states one — never the panel foreground.
  final TextStyle contentTextStyle;

  /// Nested [CoreButtonStyle] slot — forwarded to a `Button` action by
  /// `co_dialog` (asChild pattern). `null` when the caller supplied no
  /// action-button chrome override.
  final CoreButtonStyle? actionButtonStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDialog] for the given [context].
///
/// Single entry point — reads [CoreDialogTheme] from
/// `Theme.of(context).coreComponentTheme` itself so callers never touch
/// `coreComponentTheme` directly. Used both by `_DialogContent`
/// (panel chrome) and by the `showDialog` barrier builder (which reads
/// only [ResolvedDialog.barrierColor] from the navigator context).
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.dialog.style
///   → widget.dialogStyle
/// ```
ResolvedDialog resolveDialog(
  BuildContext context, {
  CoreDialogStyle? dialogStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final dialogTheme = theme.coreComponentTheme?.dialog;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDialogStyle(), [
    dialogTheme?.style,
    dialogStyle,
  ]);

  // ─── Token table ──────────────────────────────────────
  // The dialog has no visual variant — the design-system colour table is
  // the fallback source for the four panel / backdrop colours (single
  // source of truth, mirrors the Web resolver).
  const variantStyle = CoreDialogStyle.defaultsByVariant;

  // ─── Resolved chrome (paint-ready Flutter values) ─────
  // Surface-level colours resolve to plain Flutter `Color` here through
  // `scheme.resolve(x).toValue()` (Epic #1603 C7 — never `.toValue()`
  // standalone, so the originating token survives dark-mode resolution).
  // `surfaceOpacity` (when set) is folded into the fill here so the
  // widget reads a fully paint-ready background colour.
  //
  // The theme fallback is the second half of the material. The blur
  // below already falls back to the theme, so without this line a
  // preset reached the dialog with a blur and no translucency — and a
  // blur behind an opaque fill is painted and then covered. The panel
  // rendered exactly as before while every structural check passed.
  // 이 표면은 콘텐츠 위에 뜬다. 스타일이 두 재질을 진술하면 그중 떠
  // 있는 쪽을 받고, 하나만 진술하면 그것을 받는다 — 역할을 안 쓰는
  // 프리셋에게 이 축은 공짜다.
  final material = theme.surfaceFor(
    CoreSurfaceRole.functional,
    depth: SurfaceDepth.of(context),
  );
  final surfaceOpacity = merged.surfaceOpacity ?? material?.opacityIn(theme);
  final baseBackgroundColor = scheme
      .resolve(merged.panelBackgroundColor ?? variantStyle.backgroundColor)
      .toValue();
  final panelBackgroundColor = surfaceOpacity == null
      ? baseBackgroundColor
      : baseBackgroundColor.withValues(alpha: surfaceOpacity);
  final panelForegroundColor = scheme
      .resolve(variantStyle.foregroundColor)
      .toValue();
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the component
  // border. This one sat outside the guard because its call was split
  // across lines, not because it was exempt.
  final panelBorderColor = resolveSurfaceStroke(
    theme,
    scheme
        .resolve(merged.panelBorderColor ?? variantStyle.borderColor)
        .toValue(),
    role: CoreSurfaceRole.functional,
  );

  // Scaling is resolved once in this resolver (Epic #1603 C12) — the
  // widget never multiplies by `theme.scaling` itself.
  final panelBorderWidth = theme.geometry.stroke(
    merged.panelBorderWidth ?? CoreDialogStyle.defaultPanelBorderWidth,
    scaling: scaling,
  );
  final panelBorderRadius =
      ((merged.panelBorderRadius ?? CoreDialogStyle.defaultPanelBorderRadius)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final panelPadding =
      ((merged.panelPadding ?? CoreDialogStyle.defaultPanelPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final panelMinWidth =
      (merged.panelMinWidth ?? CoreDialogStyle.defaultPanelMinWidth) * scaling;
  final panelMaxWidth =
      (merged.panelMaxWidth ?? CoreDialogStyle.defaultPanelMaxWidth) * scaling;
  // Paint-ready box shadow (#3777) — shadow base colour flows through
  // the single Core source (`defaultShadowBaseColor` = `shadow` token)
  // and is resolved against the active scheme (mirrors `Popup`/`Drawer`
  // — Anti-Pattern C7: never `.toValue()` standalone on a token colour).
  final shadowBase = scheme
      .resolve(merged.shadowBaseColor ?? CoreDialogStyle.defaultShadowBaseColor)
      .toValue();
  final panelShadowStack =
      merged.panelBoxShadow ?? CoreDialogStyle.defaultPanelBoxShadow;
  final panelBoxShadow = panelShadowStack.toValue(
    base: shadowBase,
    geometry: theme.geometry,
  );
  // Where the cast is painted: behind a fill that is not opaque, a
  // decoration's shadow shows through the panel (see [castOutsideBox]).
  final castOutsideBox = panelBackgroundColor.a < 1;
  // The Web panel already carries the rim — its stack is a scale step
  // routed through `var(--shadow-xl)`, which the active style rewrites.
  final panelInsetBoxShadow = resolveSurfaceRim(
    context,
    stack: panelShadowStack,
  );
  // Section gap slot — design-system default `CoreGapStyle` merged with
  // the per-instance override. `Gap` self-scales, so the gap size
  // stays in logical px here (Epic #2228 group 7 — parent forwards raw,
  // `Gap` applies scaling).
  final sectionGapStyle = CoreDialogStyle.defaultSectionGapStyle.merge(
    merged.sectionGapStyle,
  );
  // Actions gap slot — same raw-forward shape as the section gap above.
  final actionsGapStyle = CoreDialogStyle.defaultActionsGapStyle.merge(
    merged.actionsGapStyle,
  );
  // Action spacing — raw double rendered as native `Row.spacing` by the
  // widget. Resolver applies scaling here (parity with panelPadding /
  // panelBorderWidth / panelMaxWidth — see Epic #1603 C12).
  final actionSpacing =
      theme.geometry.space(
        merged.actionSpacing ?? CoreDialogStyle.defaultActionSpacing,
      ) *
      scaling;
  // Wrapped-row gap — spacing like the gap beside it, so the theme density
  // moves it the same way before the size factor.
  final actionRunSpacing =
      theme.geometry.space(
        merged.actionRunSpacing ?? CoreDialogStyle.defaultActionRunSpacing,
      ) *
      scaling;
  // Actions spread — which row the widget builds; a choice, not a length,
  // so nothing scales it.
  final actionsLayout =
      merged.actionsLayout ?? CoreDialogStyle.defaultActionsLayout;
  // Body clip reach — the focus outline's geometry, not the layout's
  // spacing, so the density does not move it; the size factor scales it
  // the way `FocusOutline` scales the ring it has to clear.
  final contentClipMargin =
      (merged.contentClipMargin ?? CoreDialogStyle.defaultContentClipMargin) *
      scaling;
  // Route padding — the room around the panel. Spacing: the theme density
  // moves it, a stated value too, before the size factor.
  final routePadding =
      theme.geometry.space(
        merged.routePadding ?? CoreDialogStyle.defaultRoutePadding,
      ) *
      scaling;

  // ─── Barrier (scrim) colour — opacity baked in ────────
  // Override wins, else the design-system overlay-colour token; the
  // `barrierOpacity` multiplier is folded in via `scaleAlpha` before
  // resolution so the resolved `Color` carries the right alpha (mirrors
  // Web's `scaleAlpha(barrierOpacity)` → `color-mix(...)`).
  final barrierOpacity =
      merged.barrierOpacity ?? CoreDialogStyle.defaultBarrierOpacity;
  final barrierColor = scheme
      .resolve(
        (merged.barrierColor ?? variantStyle.overlayColor).scaleAlpha(
          barrierOpacity,
        ),
      )
      .toValue();

  // ─── Motion ───────────────────────────────────────────
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreDialogStyle.defaultTransitionDuration,
  );
  final scaleAnimationStart =
      merged.scaleAnimationStart ?? CoreDialogStyle.defaultScaleAnimationStart;
  final scaleAnimationEnd =
      merged.scaleAnimationEnd ?? CoreDialogStyle.defaultScaleAnimationEnd;

  // ─── Paint-ready typography ───────────────────────────
  // EMIT Stage 2 (Flutter) — `style.toValue(theme:)` materialises the
  // token role (`titleLarge` / `bodyMedium`) and resolves its colour
  // through the active scheme. Single primitive — no hand-rolled
  // letterSpacing / lineHeight / fontWeight assembly.
  //
  // Each text slot paints its own default's colour with the slot override
  // merged on top — the title `onSurface`, the body the secondary
  // `onSurfaceVariant` — which is what Web's `emitTypography` emits from
  // the same two defaults. Neither reads the panel foreground: that is a
  // separate field, inherited only by what states no colour, so a change
  // to one default reaches both platforms and leaves the other alone.
  final titleTextStyle = CoreDialogStyle.defaultTitleStyle
      .merge(merged.titleStyle)
      .toValue(theme: theme);
  final contentTextStyle = CoreDialogStyle.defaultContentStyle
      .merge(merged.contentStyle)
      .toValue(theme: theme);

  return ResolvedDialog(
    panelBackgroundColor: panelBackgroundColor,
    panelForegroundColor: panelForegroundColor,
    panelBorderColor: panelBorderColor,
    panelBorderWidth: panelBorderWidth,
    panelBorderRadius: panelBorderRadius,
    panelPadding: panelPadding,
    panelMinWidth: panelMinWidth,
    panelMaxWidth: panelMaxWidth,
    // Falls back to the theme axis, like every other surface does.
    // Without this the preset reached a card and a dock but not a
    // dialog, while the Web twin — which keys off one marker class —
    // reached all three. Same preset, different glass per platform.
    surfaceBlur: merged.surfaceBlur ?? material?.blurRadius,
    surfaceSaturation: material?.saturation,
    surfaceBackdropBrightness: material?.backdropBrightnessIn(theme),
    surfaceSheen: resolveSurfaceSheen(theme, role: CoreSurfaceRole.functional),
    panelBoxShadow: panelBoxShadow,
    castOutsideBox: castOutsideBox,
    panelInsetBoxShadow: panelInsetBoxShadow,
    barrierColor: barrierColor,
    sectionGapStyle: sectionGapStyle,
    actionsGapStyle: actionsGapStyle,
    actionSpacing: actionSpacing,
    actionRunSpacing: actionRunSpacing,
    actionsLayout: actionsLayout,
    contentClipMargin: contentClipMargin,
    routePadding: routePadding,
    transitionDuration: transitionDuration,
    scaleAnimationStart: scaleAnimationStart,
    scaleAnimationEnd: scaleAnimationEnd,
    titleTextStyle: titleTextStyle,
    contentTextStyle: contentTextStyle,
    actionButtonStyle: merged.actionButtonStyle,
  );
}
