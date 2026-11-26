import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Single-entry-point resolver
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `FileInput`.
///
/// Widget tree (`co_file_input.dart` renders this top-to-bottom):
///
/// ```text
/// DropTarget (OS file drop: enter / exit / done)
///   └─ Clickable (clickableStyle)          // owns tap / cursor / focus ring
///      └─ AnimatedContainer (background{Idle|DragActive}, borderRadius)
///         └─ CustomPaint (_DashedBorderPainter: border{Idle|Hover|DragOver|
///            │            Disabled}, borderWidth, borderRadius)
///            └─ Padding (padding)
///                 └─ Column (spacing: itemSpacing)
///                      ├─ icon | Icon(iconStyle{Enabled|Disabled})
///                      ├─ Text(label, labelTextStyle{Enabled|Disabled})
///                      ├─ Button.outline(browse)
///                      ├─ Text(hint, hintTextStyle{Enabled|Disabled})
///                      └─ file rows: Icon(fileIconStyle{Enabled|
///                         Disabled}) + Text(fileTextStyle{Enabled|Disabled})
///                         + save Button(plain, saveButtonStyle)*
/// ```
///
/// The widget is **render-only**: every colour / typography value is baked
/// here per state, and the build only selects by the runtime `enabled` /
/// `isHovered` / `isDragOver` flags and renders. Icon-slot colours stay `CoreColor`
/// token+opacity references (the sibling `Icon` resolves them, so dark
/// mode tracks and there is no paint→domain round-trip); text / border /
/// background colours are paint-ready Flutter [Color]s.
///
/// Dimensional values are raw logical px (pre-scaling); scaling is
/// applied at use site (or self-applied by `Icon`).
class ResolvedFileInput {
  /// Creates a [ResolvedFileInput].
  const ResolvedFileInput({
    required this.borderRadius,
    required this.padding,
    required this.borderWidth,
    required this.dashLength,
    required this.dashSpacing,
    required this.itemSpacing,
    required this.textSpacing,
    required this.actionSpacing,
    required this.iconBoxSize,
    required this.iconBoxColorIdle,
    required this.iconBoxColorDragActive,
    required this.iconBoxColorDisabled,
    required this.iconBoxBorderRadius,
    required this.fileItemSpacing,
    required this.transitionDuration,
    required this.surfaceBlurIdle,
    required this.surfaceSaturationIdle,
    required this.surfaceBackdropBrightnessIdle,
    required this.surfaceSheenIdle,
    required this.surfaceBlurDragActive,
    required this.surfaceSaturationDragActive,
    required this.surfaceBackdropBrightnessDragActive,
    required this.surfaceSheenDragActive,
    required this.backgroundColorIdle,
    required this.backgroundColorDragActive,
    required this.backgroundColorDisabled,
    required this.borderColorIdle,
    required this.borderColorHover,
    required this.borderColorDragOver,
    required this.borderColorDisabled,
    required this.iconStyleEnabled,
    required this.iconStyleDragActive,
    required this.iconStyleDisabled,
    required this.labelTextStyleEnabled,
    required this.labelTextStyleDisabled,
    required this.hintTextStyleEnabled,
    required this.hintTextStyleDisabled,
    required this.fileIconStyleEnabled,
    required this.fileIconStyleDisabled,
    required this.fileTextStyleEnabled,
    required this.fileTextStyleDisabled,
    required this.clickableStyle,
    required this.saveButtonStyle,
    required this.curve,
  });

  /// Effective outer border radius (pre-scaling — the widget applies
  /// `theme.scaling` at use site).
  final BorderRadius borderRadius;

  /// Effective inner padding (logical px, pre-scaling).
  final EdgeInsets padding;

  /// Effective outer border stroke width (logical px, pre-scaling).
  final double borderWidth;

  /// Dash segment length of the dashed border (raw logical px —
  /// pre-scaling, matching this resolver's use-site scaling model).
  final double dashLength;

  /// Gap between dash segments (raw logical px — pre-scaling).
  final double dashSpacing;

  /// Effective spacing between vertical elements (logical px, pre-scaling).
  final double itemSpacing;

  /// Effective spacing between the title and the hint (logical px,
  /// pre-scaling).
  final double textSpacing;

  /// Effective spacing between the text block and the action buttons
  /// (logical px, pre-scaling).
  final double actionSpacing;

  /// Effective edge of the circular icon box (logical px, scaled).
  final double iconBoxSize;

  /// Icon box fill — enabled, no drag over the zone.
  final Color iconBoxColorIdle;

  /// Icon box fill — enabled + drag-over.
  final Color iconBoxColorDragActive;

  /// Icon-box fill — disabled (the `disabledContainer` token).
  final Color iconBoxColorDisabled;

  /// Effective icon box corner radius (a circle by default).
  final BorderRadius iconBoxBorderRadius;

  /// Effective spacing (and bottom margin) between selected file items
  /// (logical px, pre-scaling).
  final double fileItemSpacing;

  /// Effective hover / focus colour crossfade duration for the
  /// drop-zone container.
  final Duration transitionDuration;

  /// The shape the chrome change takes over time.
  ///
  /// Paired with the duration beside it rather than left to the framework.
  /// Flutter's implicit animations default to `Curves.linear` and the Web
  /// twin's CSS transition does not — same length, different shape, so
  /// side by side one pane slides at a constant rate while the other eases
  /// in and out. Both platforms name the same `CoreEasing` alias instead.
  final Curve curve;

  /// Backdrop blur sigma for the idle-state fill, `null` when the active
  /// theme states no material or the idle state paints no fill of its
  /// own to blur behind (the drop zone's designed-in default) — see
  /// [backgroundColorIdle].
  final double? surfaceBlurIdle;

  /// Chroma lift riding the same backdrop pass as [surfaceBlurIdle].
  final double? surfaceSaturationIdle;

  /// How far the active style dims what shows through the idle-state
  /// fill, or null for no material.
  final double? surfaceBackdropBrightnessIdle;

  /// Edge light riding the same material treatment as [surfaceBlurIdle].
  final ResolvedSurfaceSheen? surfaceSheenIdle;

  /// Backdrop blur sigma for the drag-active fill — see
  /// [backgroundColorDragActive]. Unlike the idle pair, this one states a
  /// fill by design, so it is `null` only when the active theme states no
  /// material.
  final double? surfaceBlurDragActive;

  /// Chroma lift riding the same backdrop pass as [surfaceBlurDragActive].
  final double? surfaceSaturationDragActive;

  /// How far the active style dims what shows through the drag-active
  /// fill, or null for no material.
  final double? surfaceBackdropBrightnessDragActive;

  /// Edge light riding the same material treatment as
  /// [surfaceBlurDragActive].
  final ResolvedSurfaceSheen? surfaceSheenDragActive;

  /// Container background fill — idle (override else transparent).
  final Color backgroundColorIdle;

  /// Container background fill — enabled + drag-over (override else the
  /// `primary` tint at 5 % alpha).
  final Color backgroundColorDragActive;

  /// Zone fill — disabled (the `disabledContainer` token, opaque; the
  /// disabled zone takes no material).
  final Color backgroundColorDisabled;

  /// Dashed border colour — enabled, no drag, pointer elsewhere (the
  /// override else the `outline` edge colour).
  final Color borderColorIdle;

  /// Dashed border colour — enabled, pointer over the zone, no drag (the
  /// override else the `onSurface` hover tone). Drag-over and disabled
  /// outrank it, so the widget picks this only on the idle rung.
  final Color borderColorHover;

  /// Border colour — enabled + drag-over (`primary`; the painter strokes
  /// it solid, not dashed).
  final Color borderColorDragOver;

  /// Dashed border colour — disabled (the `disabledOutline` token).
  final Color borderColorDisabled;

  /// Upload-icon slot — enabled state. Carries the raw icon size and the
  /// override colour else the `onSurfaceVariant` token at 40 % opacity.
  /// Forwarded straight to `Icon(iconStyle: …)`, which resolves the
  /// token + scales the size.
  final CoreIconStyle iconStyleEnabled;

  /// Upload-icon slot — disabled state. As [iconStyleEnabled] but always
  /// the `disabledContent` token (the disabled tone
  /// ignores the per-instance icon-colour override, matching the prior
  /// widget behaviour).
  final CoreIconStyle iconStyleDisabled;

  /// Upload-icon slot — enabled while a file is dragged over the zone.
  /// Same as [iconStyleEnabled] but wears `dragActiveIconColor` (`primary`).
  final CoreIconStyle iconStyleDragActive;

  /// Primary label [TextStyle] — enabled state. Base typography + the
  /// per-instance override colour else the `onSurfaceVariant` content tone.
  final TextStyle labelTextStyleEnabled;

  /// Primary label [TextStyle] — disabled state (the `disabledContent` token).
  final TextStyle labelTextStyleDisabled;

  /// Hint [TextStyle] — enabled state (override colour else content @ 60 %).
  final TextStyle hintTextStyleEnabled;

  /// Hint [TextStyle] — disabled state (the `disabledContent` token).
  final TextStyle hintTextStyleDisabled;

  /// Selected-file row icon slot — enabled state. The merged file-icon
  /// slot with the `onSurfaceVariant` token at 60 % opacity baked on.
  final CoreIconStyle fileIconStyleEnabled;

  /// Selected-file row icon slot — disabled state (the `disabledContent`
  /// token).
  final CoreIconStyle fileIconStyleDisabled;

  /// Selected-file row label [TextStyle] — enabled state (content @ 80 %).
  final TextStyle fileTextStyleEnabled;

  /// Selected-file row label [TextStyle] — disabled state (the
  /// `disabledContent` token).
  final TextStyle fileTextStyleDisabled;

  /// Nested style for the composed drop-zone `Clickable` — raw-forwarded
  /// (the Clickable's own resolver fills the rest).
  final CoreClickableStyle clickableStyle;

  /// Nested style for the per-file save affordance's composed `Button` —
  /// `CoreFileInputStyle.defaultSaveButtonStyle` merged with the
  /// per-instance override, raw-forwarded to `Button(buttonStyle:)`.
  final CoreButtonStyle saveButtonStyle;
}

/// Resolves [ResolvedFileInput] for the given [context].
///
/// ```text
/// design system default (CoreFileInputStyle.default*)
///   → CoreFileInputTheme.style
///   → widget.fileInputStyle
/// ```
ResolvedFileInput resolveFileInput(
  BuildContext context, {
  CoreFileInputStyle? fileInputStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final csTheme = theme.coreComponentTheme?.fileInput;

  final merged = resolveStyleChain(const CoreFileInputStyle(), [
    csTheme?.style,
    fileInputStyle,
  ]);

  // The drop-zone draws its own box directly (the `AnimatedContainer` in
  // `file_input.dart`) rather than composing `OutlinedContainer`, so a
  // glass style's material reaches it the same way it reaches a card —
  // through the content-layer seat, folded into whichever fill is active
  // below. Idle states no fill by design (the dashed border alone reads
  // as a drop zone); drag-active always states one — so the two branches
  // are gated independently, each on its own resolved alpha.
  final material = theme.surfaceFor(.content, depth: SurfaceDepth.of(context));
  final surfaceOpacity = material?.opacityIn(theme);

  // ─── Stage 1 RESOLVE — dimensional / duration (local vars) ──
  final borderRadius =
      (merged.borderRadius ?? CoreFileInputStyle.defaultBorderRadius).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  final padding =
      (merged.padding ?? CoreFileInputStyle.defaultPadding).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  final iconSize =
      merged.iconStyle?.size ?? CoreFileInputStyle.defaultIconStyle.size!;
  // Stroke geometry stays unscaled — Web emits `border-width` as fixed
  // px (`strokeWidthCss`) while height / padding / radius land as rem,
  // so the size factor moves those and must not move this. The dash pattern
  // follows the stroke it dashes.
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreFileInputStyle.defaultBorderWidth,
  );
  final dashLength = merged.dashLength ?? CoreFileInputStyle.defaultDashLength;
  final dashSpacing =
      merged.dashSpacing ?? CoreFileInputStyle.defaultDashSpacing;
  final itemSpacing =
      theme.geometry.space(
        merged.itemSpacing ?? CoreFileInputStyle.defaultItemSpacing,
      ) *
      scaling;
  final textSpacing =
      theme.geometry.space(
        merged.textSpacing ?? CoreFileInputStyle.defaultTextSpacing,
      ) *
      scaling;
  final actionSpacing =
      theme.geometry.space(
        merged.actionSpacing ?? CoreFileInputStyle.defaultActionSpacing,
      ) *
      scaling;
  final iconBoxSize =
      (merged.iconBoxSize ?? CoreFileInputStyle.defaultIconBoxSize) * scaling;
  final iconBoxBorderRadius =
      (merged.iconBoxBorderRadius ??
              CoreFileInputStyle.defaultIconBoxBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final fileItemSpacing =
      theme.geometry.space(
        merged.fileItemSpacing ?? CoreFileInputStyle.defaultFileItemSpacing,
      ) *
      scaling;
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreFileInputStyle.defaultTransitionDuration,
  );

  // ─── Stage 1 RESOLVE — colours (CoreColor, scalar fallback) ──
  // Every per-state tone routes through a `CoreFileInputStyle.default*`
  // token (dark-mode reactive); the border / background idle tones honour
  // the per-instance override before falling back to the default token.
  final contentColorCore =
      merged.contentColor ?? CoreFileInputStyle.defaultContentColor;
  final disabledContentColorCore =
      merged.disabledContentColor ??
      CoreFileInputStyle.defaultDisabledContentColor;
  final hintColorCore = merged.hintColor ?? CoreFileInputStyle.defaultHintColor;
  final fileNameColorCore =
      merged.fileNameColor ?? CoreFileInputStyle.defaultFileNameColor;
  final borderColorIdleCore =
      merged.borderColor ?? CoreFileInputStyle.defaultBorderColor;
  // Disabled border is its own token (`disabledOutline`); a per-instance
  // idle `borderColor` does not leak into the disabled state.
  final borderColorDisabledCore =
      merged.disabledBorderColor ??
      CoreFileInputStyle.defaultDisabledBorderColor;
  final hoverBorderColorCore =
      merged.hoverBorderColor ?? CoreFileInputStyle.defaultHoverBorderColor;
  final dragOverBorderColorCore =
      merged.dragOverBorderColor ??
      CoreFileInputStyle.defaultDragOverBorderColor;
  final dragActiveBackgroundCore =
      merged.dragActiveBackgroundColor ??
      merged.backgroundColor ??
      CoreFileInputStyle.defaultDragActiveBackgroundColor;
  final backgroundIdleCore = merged.backgroundColor;
  final iconBoxColorIdle = scheme
      .resolve(merged.iconBoxColor ?? CoreFileInputStyle.defaultIconBoxColor)
      .toValue();
  final iconBoxColorDragActive = scheme
      .resolve(
        merged.dragActiveIconBoxColor ??
            CoreFileInputStyle.defaultDragActiveIconBoxColor,
      )
      .toValue();
  final iconBoxColorDisabled = scheme
      .resolve(
        merged.disabledIconBoxColor ??
            CoreFileInputStyle.defaultDisabledIconBoxColor,
      )
      .toValue();
  final backgroundColorDisabled = scheme
      .resolve(
        merged.disabledBackgroundColor ??
            CoreFileInputStyle.defaultDisabledBackgroundColor,
      )
      .toValue();
  final subtleIconColorCore =
      merged.subtleIconColor ?? CoreFileInputStyle.defaultSubtleIconColor;
  final fileIconColorCore =
      merged.fileIconColor ?? CoreFileInputStyle.defaultFileIconColor;

  // ─── Stage 1 RESOLVE — typography (CoreTextStyle, composite) ──
  final labelTextStyleCore = CoreFileInputStyle.defaultLabelTextStyle.merge(
    merged.labelTextStyle,
  );
  final hintTextStyleCore = CoreFileInputStyle.defaultHintTextStyle.merge(
    merged.hintTextStyle,
  );
  final fileTextStyleCore = CoreFileInputStyle.defaultFileTextStyle.merge(
    merged.fileTextStyle,
  );
  // Whether the per-instance text override carries an explicit colour —
  // when it does, it wins over the per-state tone (prior widget
  // behaviour: `style.color ?? stateColor`).
  final hasLabelColorOverride = merged.labelTextStyle?.color != null;
  final hasHintColorOverride = merged.hintTextStyle?.color != null;

  // ─── Stage 2 EMIT (Flutter) — colour = .resolve.toValue ─────
  final contentColor = scheme.resolve(contentColorCore).toValue();
  final disabledContentColor = scheme
      .resolve(disabledContentColorCore)
      .toValue();
  final hintColor = scheme.resolve(hintColorCore).toValue();
  final fileNameColor = scheme.resolve(fileNameColorCore).toValue();
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the drop
  // zone's dashed hairline so it doesn't draw a second boundary on top
  // of the material's own.
  final borderColorIdle = resolveSurfaceStroke(
    theme,
    scheme.resolve(borderColorIdleCore).toValue(),
  );
  final borderColorHover = resolveSurfaceStroke(
    theme,
    scheme.resolve(hoverBorderColorCore).toValue(),
  );
  final borderColorDisabled = resolveSurfaceStroke(
    theme,
    scheme.resolve(borderColorDisabledCore).toValue(),
  );
  final borderColorDragOver = resolveSurfaceStroke(
    theme,
    scheme.resolve(dragOverBorderColorCore).toValue(),
  );
  // surface:content — drag-active always states a fill by design, so the
  // material folds in unconditionally.
  final backgroundColorDragActive = scheme
      .resolve(
        surfaceOpacity == null
            ? dragActiveBackgroundCore
            : dragActiveBackgroundCore.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  // Idle states no fill of its own by design (the dashed border alone
  // reads as a drop zone) — the material only has something to make
  // translucent once a caller opts into a background, mirroring Table
  // (#4359).
  final backgroundColorIdle = backgroundIdleCore == null
      ? CoreColor.transparent.toValue()
      : scheme
            .resolve(
              surfaceOpacity == null
                  ? backgroundIdleCore
                  : backgroundIdleCore.scaleAlpha(surfaceOpacity),
            )
            .toValue();
  final hasFillIdle = backgroundColorIdle.a > 0;
  final surfaceBlurIdle = hasFillIdle ? material?.blurRadius : null;
  final surfaceSaturationIdle = hasFillIdle ? material?.saturation : null;
  final surfaceBackdropBrightnessIdle = hasFillIdle
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheenIdle = hasFillIdle ? resolveSurfaceSheen(theme) : null;
  final hasFillDragActive = backgroundColorDragActive.a > 0;
  final surfaceBlurDragActive = hasFillDragActive ? material?.blurRadius : null;
  final surfaceSaturationDragActive = hasFillDragActive
      ? material?.saturation
      : null;
  final surfaceBackdropBrightnessDragActive = hasFillDragActive
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheenDragActive = hasFillDragActive
      ? resolveSurfaceSheen(theme)
      : null;

  // Upload-icon slots — enabled keeps the per-instance icon-colour
  // override, disabled always wears the disabled content tone.
  final iconStyleEnabled = CoreIconStyle(
    size: iconSize,
    color: merged.iconStyle?.color ?? subtleIconColorCore,
  );
  final iconStyleDragActive = CoreIconStyle(
    size: iconSize,
    color:
        merged.iconStyle?.color ??
        merged.dragActiveIconColor ??
        CoreFileInputStyle.defaultDragActiveIconColor,
  );
  final iconStyleDisabled = CoreIconStyle(
    size: iconSize,
    color: disabledContentColorCore,
  );
  // File-row icon slots — merged design-system default + per-state tone.
  final fileIconStyleBase = CoreFileInputStyle.defaultFileIconStyle.merge(
    merged.fileIconStyle,
  );
  final fileIconStyleEnabled = fileIconStyleBase.merge(
    CoreIconStyle(color: fileIconColorCore),
  );
  final fileIconStyleDisabled = fileIconStyleBase.merge(
    CoreIconStyle(color: disabledContentColorCore),
  );

  // ─── Stage 2 EMIT (Flutter) — typography = .toValue(theme:, color:) ──
  // The `color:` override forces the per-state tone when the per-instance
  // override carries none; when it does carry one, pass `null` so the
  // override colour (materialised in the merged style) wins.
  final labelTextStyleEnabled = labelTextStyleCore.toValue(
    color: hasLabelColorOverride ? null : contentColor,
    theme: theme,
  );
  final labelTextStyleDisabled = labelTextStyleCore.toValue(
    color: hasLabelColorOverride ? null : disabledContentColor,
    theme: theme,
  );
  final hintTextStyleEnabled = hintTextStyleCore.toValue(
    color: hasHintColorOverride ? null : hintColor,
    theme: theme,
  );
  final hintTextStyleDisabled = hintTextStyleCore.toValue(
    color: hasHintColorOverride ? null : disabledContentColor,
    theme: theme,
  );
  final fileTextStyleEnabled = fileTextStyleCore.toValue(
    color: fileNameColor,
    theme: theme,
  );
  final fileTextStyleDisabled = fileTextStyleCore.toValue(
    color: disabledContentColor,
    theme: theme,
  );
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreFileInputStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );
  // Nested save-affordance button slot — the design-system default always
  // applies (the affordance is the input's own), so the override merges on
  // top rather than replacing it.
  final saveButtonStyle = CoreFileInputStyle.defaultSaveButtonStyle.merge(
    merged.saveButtonStyle,
  );

  return ResolvedFileInput(
    borderRadius: borderRadius,
    padding: padding,
    borderWidth: borderWidth,
    dashLength: dashLength,
    dashSpacing: dashSpacing,
    itemSpacing: itemSpacing,
    textSpacing: textSpacing,
    actionSpacing: actionSpacing,
    iconBoxSize: iconBoxSize,
    iconBoxColorIdle: iconBoxColorIdle,
    iconBoxColorDragActive: iconBoxColorDragActive,
    iconBoxColorDisabled: iconBoxColorDisabled,
    iconBoxBorderRadius: iconBoxBorderRadius,
    fileItemSpacing: fileItemSpacing,
    transitionDuration: transitionDuration,
    surfaceBlurIdle: surfaceBlurIdle,
    surfaceSaturationIdle: surfaceSaturationIdle,
    surfaceBackdropBrightnessIdle: surfaceBackdropBrightnessIdle,
    surfaceSheenIdle: surfaceSheenIdle,
    surfaceBlurDragActive: surfaceBlurDragActive,
    surfaceSaturationDragActive: surfaceSaturationDragActive,
    surfaceBackdropBrightnessDragActive: surfaceBackdropBrightnessDragActive,
    surfaceSheenDragActive: surfaceSheenDragActive,
    backgroundColorIdle: backgroundColorIdle,
    backgroundColorDragActive: backgroundColorDragActive,
    backgroundColorDisabled: backgroundColorDisabled,
    borderColorIdle: borderColorIdle,
    borderColorHover: borderColorHover,
    borderColorDragOver: borderColorDragOver,
    borderColorDisabled: borderColorDisabled,
    iconStyleEnabled: iconStyleEnabled,
    iconStyleDragActive: iconStyleDragActive,
    iconStyleDisabled: iconStyleDisabled,
    labelTextStyleEnabled: labelTextStyleEnabled,
    labelTextStyleDisabled: labelTextStyleDisabled,
    hintTextStyleEnabled: hintTextStyleEnabled,
    hintTextStyleDisabled: hintTextStyleDisabled,
    fileIconStyleEnabled: fileIconStyleEnabled,
    fileIconStyleDisabled: fileIconStyleDisabled,
    fileTextStyleEnabled: fileTextStyleEnabled,
    fileTextStyleDisabled: fileTextStyleDisabled,
    clickableStyle: clickableStyle,
    saveButtonStyle: saveButtonStyle,
    // The same alias the Web twin names for this element's CSS
    // transition. Chrome moving between states is `move`; a curve
    // stated on one platform and defaulted on the other is the
    // divergence nothing renders differently enough to notice until
    // the two are put side by side.
    curve: CoreEasing.move.toValue(),
  );
}
