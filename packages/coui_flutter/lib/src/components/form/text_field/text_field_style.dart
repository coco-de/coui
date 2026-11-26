import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `TextField`.
///
/// Widget tree (`co_text_field.dart` decides which optional branches
/// render):
///
/// ```text
/// Column (label / field / description|error)
///   ├─ Padding (labelPadding)                       // rendered only when label != null
///   │    └─ FormLabel (label, size, enabled, labelFormLabelStyle)
///   ├─ ConstrainedBox (minHeight / maxHeight / height)
///   │    └─ Container (decoration via WidgetStateProperty<Decoration>,
///   │         foregroundDecoration via [activeDecoration])
///   │         └─ Padding (padding)
///   │              └─ Row (rowSpacing)
///   │                   ├─ IconTheme.merge (leadingIconTheme)
///   │                   │    └─ leading                        // optional
///   │                   ├─ Expanded > EditableText
///   │                   │    (valueTextStyle / placeholderTextStyle /
///   │                   │     cursorColor / cursorWidth / cursorRadius)
///   │                   └─ IconTheme.merge (trailingIconTheme)
///   │                        └─ trailing                       // optional
///   ├─ Padding (descriptionPadding)                 // rendered only when description != null
///   │    └─ Text (description, descriptionTextStyle)
///   └─ Padding (descriptionPadding)                 // rendered only when errorText != null
///        └─ Text (errorText, errorTextStyle)
/// ```
///
/// Field grouping:
///
/// 1. **State-dependent chrome** — [decoration] / [activeDecoration] /
///    [valueTextStyle] / [leadingIconTheme] / [trailingIconTheme]: the
///    widget reads the matching `WidgetStateProperty<T>` and resolves
///    per-state inside its `build` cycle (focused / disabled / error
///    states).
/// 2. **State-independent paint-ready** — [placeholderTextStyle] /
///    [labelFormLabelStyle] / [descriptionTextStyle] / [errorTextStyle] /
///    [cursorColor] / [selectionColor] / [backgroundCursorColor] /
///    [focusBorderColor] resolve once per build.
/// 3. **Layout / dimensional** — [height] /
///    [minHeight] / [maxHeight] / [padding] / [rowSpacing] /
///    [borderWidth] / [activeBorderWidth] / [cursorWidth] / [cursorRadius] /
///    [iconSize] read as plain Flutter types.
class ResolvedTextField {
  /// Creates a [ResolvedTextField].
  const ResolvedTextField({
    required this.decoration,
    required this.activeDecoration,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.valueTextStyle,
    required this.leadingIconTheme,
    required this.trailingIconTheme,
    required this.placeholderTextStyle,
    required this.labelFormLabelStyle,
    required this.descriptionTextStyle,
    required this.affixTextStyle,
    required this.errorTextStyle,
    required this.cursorColor,
    required this.selectionColor,
    required this.backgroundCursorColor,
    required this.focusBorderColor,
    required this.errorBorderColor,
    required this.height,
    required this.minHeight,
    required this.maxHeight,
    required this.padding,
    required this.labelPadding,
    required this.descriptionPadding,
    required this.rowSpacing,
    required this.scrollPadding,
    required this.borderWidth,
    required this.activeBorderWidth,
    required this.cursorWidth,
    required this.cursorHeight,
    required this.cursorRadius,
    required this.iconSize,
    required this.leadingIconStyle,
    required this.trailingIconStyle,
    required this.featureButtonStyle,
    required this.focusOutlineStyle,
    required this.textAlign,
    required this.textAlignVertical,
    required this.crossAxisAlignment,
    required this.fileLabelFontWeight,
    required this.transitionDuration,
  });

  // ── State-dependent chrome (WidgetStateProperty) ────────────

  /// Per-state [BoxDecoration] (background colour + border + border
  /// radius).
  ///
  /// Resolver synthesises this from the variant token table + per-instance
  /// overrides; the widget resolves it per build with the current
  /// [WidgetState] set (focused / disabled).
  final WidgetStateProperty<BoxDecoration> decoration;

  /// Per-state foreground [BoxDecoration] that lays the active boundary
  /// (focused, or the error variant while enabled) over the box — fed to
  /// `Container.foregroundDecoration`. `null` while the field rests, is
  /// disabled, wears `plain`, or has no boundary to widen (the active width
  /// is no wider than the resting one, or the boundary colour is
  /// transparent).
  ///
  /// The resting boundary stays in [decoration] and keeps its place in the
  /// layout; this paints the same colour over it out to [activeBorderWidth],
  /// so the content does not move when the field takes focus.
  final WidgetStateProperty<BoxDecoration?> activeDecoration;

  /// Backdrop blur sigma for the field's own box, `null` when the active
  /// theme states no material or the field paints no fill of its own to
  /// blur behind (an explicit transparent [CoreTextFieldStyle.backgroundColor]
  /// override) — see [decoration].
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Per-state [TextStyle] for the input value — foreground colour
  /// flips on disabled.
  final WidgetStateProperty<TextStyle> valueTextStyle;

  /// Per-state [IconThemeData] for the leading icon slot.
  final WidgetStateProperty<IconThemeData> leadingIconTheme;

  /// Per-state [IconThemeData] for the trailing icon slot.
  final WidgetStateProperty<IconThemeData> trailingIconTheme;

  // ── State-independent paint-ready ────────────────────────────

  /// Paint-ready placeholder [TextStyle].
  final TextStyle placeholderTextStyle;

  /// Nested [CoreFormLabelStyle] slot raw-forwarded to the composed
  /// `FormLabel(formLabelStyle: …)` — carries this field's own
  /// per-instance [CoreTextFieldStyle.labelStyle] override and disabled
  /// tint ([CoreTextFieldStyle.labelDisabledColor]). `FormLabel` owns
  /// the actual per-size typography default (its own `defaultsBySize`);
  /// this field states only the parts `TextField` itself overrides.
  final CoreFormLabelStyle labelFormLabelStyle;

  /// Paint-ready description [TextStyle].
  final TextStyle descriptionTextStyle;

  /// Paint-ready [TextStyle] a `Text` placed in the prefix / suffix slot
  /// wears — the size row's base typography in `affixColor`. Stated
  /// because it was not: a `Text` affix inherited whatever
  /// `DefaultTextStyle` happened to be ambient (the page's), while Web
  /// rendered it at the ICON size, so a unit, a count or a timer read
  /// differently on the two platforms and matched the field on neither.
  final TextStyle affixTextStyle;

  /// Paint-ready error [TextStyle].
  final TextStyle errorTextStyle;

  /// Resolved caret colour — already converted from [CoreColor] (slot
  /// override) or falls back to `ColorScheme.primary`.
  final Color cursorColor;

  /// Resolved text-selection tint — `primary` at 20 % alpha. The widget
  /// applies it only while the field is focused.
  final Color selectionColor;

  /// Resolved idle (floating) cursor colour for `EditableText`
  /// (`outline`).
  final Color backgroundCursorColor;

  /// Resolved focus border colour — surfaced for the legacy `TextField`
  /// widget. The unified `TextField` consumes the focus ring through
  /// [focusOutlineStyle] (which already bakes this colour token).
  final Color focusBorderColor;

  /// Resolved error border colour — already converted. `null` when the
  /// per-instance [CoreTextFieldStyle.errorBorderColor] override is unset
  /// (the per-state [decoration] then falls back to the variant table's
  /// `borderColor`). Surfaced as its own field so consumers / tests can
  /// observe the override path independently of [decoration].
  final Color? errorBorderColor;

  // ── Layout / dimensional ─────────────────────────────────────

  /// Fixed height override (logical px); `null` when unset.
  final double? height;

  /// Minimum height of the box (logical px, scaling applied) — the size
  /// row's control height by default; `null` when a fixed [height] decides
  /// the box instead.
  final double? minHeight;

  /// Max height constraint (logical px); `null` when unset.
  final double? maxHeight;

  /// Effective content padding (paint-ready, scaling pre-applied).
  final EdgeInsets padding;

  /// Padding applied to the label element (paint-ready Flutter
  /// `EdgeInsets`, scaling pre-applied — encoded as bottom-only).
  final EdgeInsets labelPadding;

  /// Padding applied to the description / error helper text element
  /// (paint-ready Flutter `EdgeInsets`, scaling pre-applied — encoded
  /// as top-only).
  final EdgeInsets descriptionPadding;

  /// Native `Row.spacing` between the prefix / input / suffix row
  /// children (logical px).
  final double rowSpacing;

  /// Scroll padding around the input when scrolled into view
  /// (paint-ready Flutter `EdgeInsets`, scaling pre-applied).
  final EdgeInsets scrollPadding;

  /// Border stroke width (logical px); `null` defers to
  /// `CoreStrokeWidth.stroke1`.
  final double? borderWidth;

  /// Width the active boundary is painted out to (logical px, geometry
  /// floor and scaling applied) — what [activeDecoration] draws when it
  /// draws.
  final double activeBorderWidth;

  /// Cursor width (logical px).
  final double cursorWidth;

  /// Optional caret height, with density and text scaling applied.
  final double? cursorHeight;

  /// Paint-ready cursor corner [Radius] — fed straight to
  /// `EditableText.cursorRadius`.
  final Radius cursorRadius;

  /// Effective icon size (logical px, pre-scaling).
  final double iconSize;

  /// Resolved leading icon style (size + slot colour override).
  final CoreIconStyle leadingIconStyle;

  /// Resolved trailing icon style.
  final CoreIconStyle trailingIconStyle;

  /// Nested `CoreButtonStyle` slot for the input-feature affordance
  /// buttons (clear / password toggle) — design default merged with the
  /// per-instance override, raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)`. `Button` resolves
  /// its own chrome (no `scheme.resolve` / scaling here).
  final CoreButtonStyle featureButtonStyle;

  /// Paint-ready focus outline slot — fed straight to
  /// `FocusOutline.focusOutlineStyle`. Carries
  /// `borderColor` / `borderWidth` / `offsetColor` / `align` already
  /// resolved through the design defaults + per-instance override.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// Paint-ready horizontal text alignment — already converted from
  /// [CoreTextFieldStyle.textAlign] (with
  /// [CoreTextFieldStyle.defaultTextAlign] fallback). Fed straight to
  /// `EditableText.textAlign`.
  final TextAlign textAlign;

  /// Paint-ready vertical alignment of the text within the input —
  /// already converted from [CoreTextFieldStyle.textAlignVertical]. Fed
  /// straight to the `Align` y offset.
  final TextAlignVertical textAlignVertical;

  /// Paint-ready cross-axis alignment for the prefix / input / suffix
  /// `Row` — already converted from
  /// [CoreTextFieldStyle.crossAxisAlignment]. Fed straight to
  /// `Row.crossAxisAlignment`.
  final CrossAxisAlignment crossAxisAlignment;

  /// Resolved font weight applied to the file-upload `<input type="file">`
  /// label segment. Flutter consumers read this directly when rendering a
  /// file-picker affordance. Resolved from
  /// [CoreTextFieldStyle.fileLabelFontWeight] with
  /// [CoreTextFieldStyle.defaultFileLabelFontWeight] fallback.
  final int fileLabelFontWeight;

  /// Resolved chrome transition duration. Flutter consumers feed this to
  /// `AnimatedContainer` / `WidgetStateProperty` driven transitions.
  /// Resolved from [CoreTextFieldStyle.transitionDuration] with
  /// [CoreTextFieldStyle.defaultTransitionDuration] fallback.
  final Duration transitionDuration;
}

// ═══════════════════════════════════════════════════
// Resolver — entry points
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTextField] for a `TextField`.
///
/// Merge chain:
///
/// ```text
/// design system default for variant
///   → theme.coreComponentTheme.textField.style
///   → theme.coreComponentTheme.textField.variantStyles[variant]
///   → widget.textFieldStyle
/// ```
///
/// `variant` is [CoreTextFieldVariant.of] — `error` only while [hasError]
/// and [enabled] (`disabled > error`). That gate is box chrome only: the
/// error message style of a disabled field with an error still reads the
/// Theme `variantStyles[error]` row.
ResolvedTextField resolveTextField(
  BuildContext context, {
  required bool hasError,
  required bool enabled,
  required CoreComponentSize size,
  CoreTextFieldVariant? variant,
  bool singleLine = true,
  CoreEdgeInsets scrollPadding = CoreTextFieldContract.defaultScrollPadding,
  CoreTextFieldStyle? textFieldStyle,
  JoinItemData? joinItemData,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final fieldTheme = theme.coreComponentTheme?.textField;
  final scheme = theme.colorScheme;

  // Error axis → semantic variant, with `disabled > error` asked of the
  // Core single source (`CoreTextFieldVariant.showsErrorChrome`) rather
  // than spelled here. The chosen variant keys the chrome table and the
  // Theme row the box chrome reads.
  final showsError = CoreTextFieldVariant.showsErrorChrome(
    hasError: hasError,
    enabled: enabled,
  );
  final effectiveVariant = CoreTextFieldVariant.of(
    hasError: hasError,
    enabled: enabled,
    variant: variant,
  );

  // The error message is content, not box chrome: the widget shows it
  // whenever `errorText` is set, disabled or not. So a disabled field with
  // an error steps its chrome off the Theme `error` row, but the message
  // keeps reading that row — only the row's two message fields join the
  // chain, above the chrome row and below the instance override. Enabled,
  // the whole row is already in the chain as `effectiveVariant`.
  final errorMessageRow = hasError && !showsError
      ? (fieldTheme?.variantStyles?[CoreTextFieldVariant.error])
      : null;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreTextFieldStyle(), [
    fieldTheme?.style,
    fieldTheme?.variantStyles?[effectiveVariant],
    if (errorMessageRow != null)
      CoreTextFieldStyle(
        errorStyle: errorMessageRow.errorStyle,
        errorColor: errorMessageRow.errorColor,
      ),
    textFieldStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final vs = CoreTextFieldStyle.defaultsByVariant[effectiveVariant]!;
  final ss = resolveSizeRow(CoreTextFieldStyle.defaultsBySize, size);
  // A retiring size renders as before; a run with asserts on logs it once
  // (asserts stripped: nothing), so the caller hears before the step goes.
  noticeRetiringSize(
    component: 'TextField',
    size: size,
    retiring: CoreTextFieldContract.retiringSizes,
  );

  // The field draws its own box directly on the native `<input>`/its
  // Flutter twin's `Container` rather than composing `OutlinedContainer`
  // (a wrap would move the framed body to a different element than the
  // one `FocusOutline` rings, offsetting the ring). A glass style's
  // material reaches it the same way it reaches a card — through the
  // content-layer seat, folded into the fill below.
  final material = theme.surfaceFor(
    .content,
    depth: SurfaceDepth.of(context),
  );
  final surfaceOpacity = material?.opacityIn(theme);

  // ─── Resolved nested slot styles ──────────────────────
  // Per-site icon-style override wins on `size`, else the shared
  // `iconStyle` slot, else the per-size default. The resolver-side
  // `iconSize` drives affix layout (icon → input gap).
  final iconSize =
      merged.leadingIconStyle?.size ??
      merged.trailingIconStyle?.size ??
      merged.iconStyle?.size ??
      ss.iconStyle!.size!;

  // Prefix / suffix affix base colour — mirrors the Web resolver's
  // `affixColor` local (`merged.affixColor ?? default`), consumed by
  // `buildIconTheme` below (state-independent — see its doc comment).
  final affixColor = merged.affixColor ?? CoreTextFieldStyle.defaultAffixColor;

  // Size-aware base typography token (`bodyMedium` for xs/sm/md/lg,
  // `bodyLarge` for xl/xl2, each at the role's own line height) — value /
  // placeholder / affix only.
  // Each of those three slots layers its own override on this
  // token-backed base; the role is materialised inside `.toValue(theme:)`
  // so the resolver never reaches for `theme.typography` /
  // `theme.typography` directly (Stage2 EMIT single primitive).
  //
  // Description / error are size-INVARIANT (`bodyXs`, the canvas
  // states the same 12px on every rung) — merged onto their own flat
  // defaults, not `baseTextStyle`, so they stop drifting with the value
  // ladder above them.
  final baseTextStyle = merged.baseTextStyle ?? ss.baseTextStyle!;
  final placeholderCore = baseTextStyle.merge(merged.placeholderStyle);
  final valueCore = baseTextStyle.merge(merged.valueStyle);
  // The helper role steps up on the `lg` rung and above (#5747) — the size
  // row states the role, the instance override layers on top.
  final descriptionCore = CoreTextFieldStyle.defaultDescriptionStyle
      .merge(ss.descriptionStyle)
      .merge(merged.descriptionStyle);
  final errorCore = CoreTextFieldStyle.defaultErrorStyle
      .merge(ss.errorStyle)
      .merge(merged.errorStyle);

  // Label typography is NOT derived from `baseTextStyle` — a composed
  // `FormLabel` owns the label's own per-size ladder (its own
  // `defaultsBySize`, split at a different rung than the value ladder
  // above). `labelStyle` / `labelDisabledColor` are raw-forwarded whole
  // into `FormLabel`'s nested style slot (child-component-composition)
  // rather than merged in here.
  final labelDisabledColor =
      merged.labelDisabledColor ?? CoreTextFieldStyle.defaultLabelDisabledColor;
  final labelFormLabelStyle = CoreFormLabelStyle(
    labelStyle: merged.labelStyle,
    disabledColor: labelDisabledColor,
  );

  final leadingIconStyle = CoreIconStyle(
    size: iconSize,
  ).merge(merged.leadingIconStyle);
  final trailingIconStyle = CoreIconStyle(
    size: iconSize,
  ).merge(merged.trailingIconStyle);

  // Feature affordance (clear / password toggle) button chrome — design
  // default, then the size row's own slot (the row's corner, so the
  // affordance is never rounder than the field around it), then the
  // per-instance override; raw-forwarded to
  // `Button(variant: .plain, buttonStyle: …)`. `Button` resolves its
  // own chrome (no `scheme.resolve` / scaling here).
  final featureButtonStyle = CoreTextFieldStyle.defaultFeatureButtonStyle
      .merge(ss.featureButtonStyle)
      .merge(merged.featureButtonStyle);

  // ─── Resolved state-independent chrome ────────────────
  // Field corner — the per-instance override wins, else the size row's
  // corner (the control height × 0.25, the same value a `Button` of this
  // size takes). The default branch is bent by the active geometry and
  // multiplied by `radiusScaling` here, then bent and `* scaling`ed again
  // where the decoration paints it — a second bend and a radius-axis
  // multiply the Web twin does not make (known, tracked on its own).
  final borderRadius =
      merged.borderRadius ??
      CoreBorderRadius.all(
        theme.geometry.borderRadius(ss.borderRadius!).topLeft *
            theme.radiusScaling,
      );
  final borderWidth = merged.borderWidth;
  // The resting boundary keeps its place in the layout; the active one is
  // painted over the box out to `activeBorderWidth` without taking layout.
  // Both go through the geometry floor, so a preset whose floor lifts the two
  // to one width has nothing to add.
  final restStroke = theme.geometry.stroke(
    borderWidth ?? CoreTextFieldStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final activeStroke = theme.geometry.stroke(
    merged.activeBorderWidth ?? CoreTextFieldStyle.defaultActiveBorderWidth,
    scaling: scaling,
  );
  // The bare `plain` variant keeps its resting boundary in every state; a
  // width that is no wider than the resting one adds nothing to paint (a
  // caller who states a thicker `borderWidth` alone is not thinned on focus).
  final widensActiveBoundary =
      effectiveVariant != CoreTextFieldVariant.plain &&
      activeStroke > restStroke;
  final cursorWidth =
      (merged.cursorWidth ?? CoreTextFieldStyle.defaultCursorWidth) * scaling;
  final cursorHeight = merged.cursorHeight == null
      ? null
      : MediaQuery.textScalerOf(context).scale(merged.cursorHeight! * scaling);
  final cursorRadius = Radius.circular(
    theme.geometry
        .borderRadius(
          merged.cursorRadius ?? CoreTextFieldStyle.defaultCursorRadius,
        )
        .topLeft,
  );
  // The variant's own horizontal inset — `null` on the boxed variants
  // (they keep the size table's inset), `0` on `plain` (no box of its
  // own, so the text starts flush like the label above it). Applied
  // only when the caller states no explicit `padding` override.
  // A one-line field on its row is held at the row's height with the line
  // centred, so the row's vertical padding does not size it
  // (`CoreTextFieldStyle.contentPadding`, shared with Web).
  final sizePadding = CoreTextFieldStyle.contentPadding(
    statedPadding: merged.padding,
    rowPadding: ss.padding!,
    singleLine: singleLine,
    height: merged.height,
    minHeight: merged.minHeight,
  );
  final padding = merged.padding == null && vs.horizontalPadding != null
      ? sizePadding.copyWith(
          left: vs.horizontalPadding,
          right: vs.horizontalPadding,
        )
      : sizePadding;
  // The `lg` rung and above state their own label / helper gaps (#5747);
  // the flat default covers the rest.
  final labelPaddingCore =
      merged.labelPadding ??
      ss.labelPadding ??
      CoreTextFieldStyle.defaultLabelPadding;
  final descriptionPaddingCore =
      merged.descriptionPadding ??
      ss.descriptionPadding ??
      CoreTextFieldStyle.defaultDescriptionPadding;
  final rowSpacing =
      theme.geometry.space(
        merged.rowSpacing ?? CoreTextFieldStyle.defaultRowSpacing,
      ) *
      scaling;
  // Stage2 EMIT — settle the Core alignment enum (Stage1 RESOLVE), then
  // convert to the paint-ready Flutter type here so the widget reads
  // `resolved.X` straight (render-only — no widget-side enum conversion).
  final textAlign = (merged.textAlign ?? CoreTextFieldStyle.defaultTextAlign)
      .toValue();
  final textAlignVertical =
      (merged.textAlignVertical ?? CoreTextFieldStyle.defaultTextAlignVertical)
          .toTextAlignVertical();
  final crossAxisAlignment =
      (merged.crossAxisAlignment ??
              CoreTextFieldStyle.defaultCrossAxisAlignment)
          .toCrossAxisAlignment();

  // Per-instance colour overrides. `backgroundOverrideCore` stays a raw
  // `CoreColor` (not yet resolved) so `buildDecoration` can fold
  // [surfaceOpacity] into it — Stage2 EMIT for the fill runs inside the
  // state builder, once per state. The others convert to Flutter [Color]
  // once here so the state builders below don't re-run `scheme.resolve`.
  final backgroundOverrideCore = merged.backgroundColor;
  final borderOverride = merged.borderColor != null
      ? scheme.resolve(merged.borderColor!).toValue()
      : null;
  final focusBorderOverride = merged.focusBorderColor != null
      ? scheme.resolve(merged.focusBorderColor!).toValue()
      : null;
  // Hover border — the per-instance override, else the variant's own
  // hover step (`outline` → `on-surface`; `error` restates `error`
  // so the pointer never softens a validation border), else the resting
  // border for a variant that states none (`plain`).
  final hoverBorderColor = scheme
      .resolve(
        merged.hoverBorderColor ?? vs.hoverBorderColor ?? vs.borderColor,
      )
      .toValue();
  // Error-border override — wins over [borderOverride] when the field is
  // in error state. Mirrors the Web resolver's
  // `merged.errorBorderColor ?? merged.borderColor` precedence.
  final errorBorderOverride = merged.errorBorderColor != null
      ? scheme.resolve(merged.errorBorderColor!).toValue()
      : null;
  final cursorOverride = merged.cursorColor != null
      ? scheme.resolve(merged.cursorColor!).toValue()
      : null;

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Wrapped in [WidgetStateProperty.resolveWith] below so
  // the widget paint cycle calls them per state without re-running
  // the merge / fallback / conversion chain.

  // A hosting `Join` owns the strip geometry — the ambient per-item radius
  // replaces the field's own so it paints flush seams instead of leaving
  // notches under the join clip. The active boundary lies over the same box,
  // so it takes the same corner.
  final effectiveRadius =
      joinItemData?.borderRadius ??
      (borderRadius.toValue(geometry: theme.geometry) * scaling);

  /// The boundary colour for the given [states] — the ladder `disabled >
  /// focus > hover > rest`, shared by the resting [BoxDecoration] and the
  /// active boundary laid over it, so the two meet in one colour.
  Color buildBorderColor(Set<WidgetState> states) {
    final isDisabled = states.contains(WidgetState.disabled);
    final isFocused = states.contains(WidgetState.focused);
    final isHovered = states.contains(WidgetState.hovered);

    Color borderColor;
    if (isDisabled) {
      // #3469 — was `vs.borderColor` (the enabled colour, unchanged) with
      // no other disabled signal on Flutter at all (unlike Web, which at
      // least dimmed via `opacity-50`) — this field had no visible
      // disabled state whatsoever. `disabledBorderColor` is the same
      // dedicated `CoreColors.disabledOutline` token Web now emits via
      // `disabled:border-*`.
      borderColor = scheme.resolve(vs.disabledBorderColor).toValue();
    } else if (isFocused) {
      borderColor =
          focusBorderOverride ?? scheme.resolve(vs.focusRingColor).toValue();
    } else if (isHovered) {
      // Hover is a border step, not a fill: `disabled > focus > hover >
      // rest`, and error is folded into the variant row rather than being
      // a rung here (its hover border IS its error border).
      borderColor = hoverBorderColor;
    } else {
      borderColor = scheme.resolve(vs.borderColor).toValue();
    }

    if (!isFocused && !isHovered) {
      // Error-border override wins over the generic border override when
      // the field is in error state — mirrors the Web resolver's
      // `merged.errorBorderColor ?? merged.borderColor` precedence.
      final overrideForState = showsError
          ? (errorBorderOverride ?? borderOverride)
          : borderOverride;
      if (overrideForState != null) borderColor = overrideForState;
    }

    // Through the shared helper, like every surface that resolves its own
    // stroke: a material that draws its own edge suppresses the field's
    // hairline so the box doesn't draw a second boundary on top of it.
    return resolveSurfaceStroke(theme, borderColor);
  }

  /// Resolves the [BoxDecoration] for the given [states].
  BoxDecoration buildDecoration(Set<WidgetState> states) {
    final isDisabled = states.contains(WidgetState.disabled);
    final isFocused = states.contains(WidgetState.focused);
    final isHovered = states.contains(WidgetState.hovered);
    final isPressed = states.contains(WidgetState.pressed);

    CoreColor bgCore;

    if (isDisabled) {
      bgCore = vs.disabledBackgroundColor;
    } else if ((isHovered || isPressed) && vs.hoverBackgroundColor != null) {
      // The filled variant has no visible edge to step, so its fill does
      // (#5747); the boxed variants state no hover fill.
      bgCore = vs.hoverBackgroundColor!;
    } else {
      bgCore = vs.backgroundColor;
    }

    if (backgroundOverrideCore != null) bgCore = backgroundOverrideCore;

    // surface:content — fold the material's opacity into the fill before
    // Stage2 EMIT, the same seat every other content-role surface folds
    // it at. A glass style's translucency and dark-mode reactivity land
    // in the one `scheme.resolve(...).toValue()` call.
    var bgColor = scheme
        .resolve(
          surfaceOpacity == null ? bgCore : bgCore.scaleAlpha(surfaceOpacity),
        )
        .toValue();

    // The state layer — the field's own foreground laid over its fill.
    //
    // Gated on the fill actually existing. Seven in-repo compositions hand
    // `TextField` a transparent one (the OTP hidden buffer, TimePicker
    // segments, PhoneInput, ChipInput, Command, FormattedInput,
    // ObjectInput), and a wash over nothing is a grey slab floating on
    // whatever is behind. The OTP buffer is the sharpest case: invisible
    // AND permanently focused while typing, so the focus rung would paint
    // straight across the visible cell row.
    //
    // Read in the order the states outrank each other. A focused field
    // that is then hovered must still change, which is only true if focus
    // sits below pressed and above hover — the ramp's own invariant.
    // The per-instance ramp outranks the variant's — a composing parent
    // (Select) states a pressed-only wash through this slot.
    final layer = merged.stateLayer ?? vs.stateLayer;
    if (layer != null && !isDisabled && bgColor.a > 0) {
      final weight = isPressed
          ? layer.pressed
          : isFocused
          ? layer.focus
          : isHovered
          ? layer.hover
          : null;
      if (weight != null) {
        final overlay = scheme
            .resolve(vs.foregroundColor)
            .toValue()
            .withValues(alpha: weight);
        bgColor = Color.alphaBlend(overlay, bgColor);
      }
    }

    return BoxDecoration(
      color: bgColor,
      // A zero-width `BorderSide` is a hairline in Flutter, one physical
      // pixel wide, not "no border" — a box that states no border (to sit
      // inside a frame that draws it) paints none, as the web's
      // `border-width: 0` does.
      border: restStroke > 0
          ? Border.all(color: buildBorderColor(states), width: restStroke)
          : null,
      borderRadius: effectiveRadius,
    );
  }

  /// Resolves the active boundary laid over the box for the given [states]:
  /// the same colour the resting boundary has, painted out to the active
  /// width. `null` when nothing is added — see [ResolvedTextField
  /// .activeDecoration].
  BoxDecoration? buildActiveDecoration(Set<WidgetState> states) {
    if (!widensActiveBoundary) return null;
    // Focus alone widens the boundary (#5747) — an error edge rests at the
    // resting width and widens only while focused, so the box never looks
    // as if it grew when a validation message appears.
    final isActive =
        !states.contains(WidgetState.disabled) &&
        states.contains(WidgetState.focused);
    if (!isActive) return null;
    final borderColor = buildBorderColor(states);
    // A transparent boundary (a chromeless composition) paints nothing;
    // skipping it also keeps a zero-width resting border from being
    // thickened into a visible one.
    if (borderColor.a == 0) return null;
    return BoxDecoration(
      border: .all(color: borderColor, width: activeStroke),
      borderRadius: effectiveRadius,
    );
  }

  /// Resolves the per-state input value [TextStyle].
  TextStyle buildValueTextStyle(Set<WidgetState> states) {
    final isDisabled = states.contains(WidgetState.disabled);
    Color fgColor;
    if (isDisabled) {
      fgColor = scheme.resolve(vs.disabledForegroundColor).toValue();
    } else {
      fgColor = scheme.resolve(vs.foregroundColor).toValue();
    }
    if (valueCore.color != null) {
      fgColor = scheme.resolve(valueCore.color!).toValue();
    }
    // Stage2 EMIT — `valueCore` carries the size-base token; `.toValue
    // (theme:)` materialises the role then overlays the per-instance
    // value-style fields + resolved foreground colour in one step.
    return valueCore.toValue(color: fgColor, theme: theme);
  }

  /// Resolves the per-state [IconThemeData] for the given prefix / suffix
  /// affix slot style.
  ///
  /// Base colour is [affixColor] (design default `onSurfaceSubtle` or the
  /// `merged.affixColor` override), state-independent — mirrors the Web
  /// resolver's `buildAffixSlotClassName()`, which applies `affixColor`
  /// unconditionally: Tailwind's `disabled:` variant only reaches the
  /// `<input>` element itself (`:disabled` pseudo-class), not the sibling
  /// affix `<span>`, so Web never dims prefix / suffix icons on disable.
  IconThemeData buildIconTheme(
    CoreIconStyle slotStyle,
    Set<WidgetState> states,
  ) {
    var iconColor = scheme.resolve(affixColor).toValue();
    if (slotStyle.color != null) {
      iconColor = scheme.resolve(slotStyle.color!).toValue();
    }
    return IconThemeData(
      size: slotStyle.size ?? iconSize,
      color: iconColor,
    );
  }

  // ─── State-independent paint-ready ────────────────────
  // Each slot carries the size-base typography token; `.toValue(theme:)`
  // materialises the role and overlays the resolved foreground colour +
  // per-instance style fields in a single Stage2 EMIT primitive.
  // A disabled field's placeholder takes the variant's disabled foreground,
  // the same tone as a disabled value (#5747).
  final placeholderColor = placeholderCore.color != null
      ? scheme.resolve(placeholderCore.color!).toValue()
      : scheme
            .resolve(
              enabled ? vs.placeholderColor : vs.disabledForegroundColor,
            )
            .toValue();
  final placeholderTextStyle = placeholderCore.toValue(
    color: placeholderColor,
    theme: theme,
  );

  final descriptionColor = scheme
      .resolve(
        descriptionCore.color ??
            merged.descriptionColor ??
            CoreTextFieldStyle.defaultDescriptionColor,
      )
      .toValue();
  final descriptionTextStyle = descriptionCore.toValue(
    color: descriptionColor,
    theme: theme,
  );

  final errorColor = scheme
      .resolve(
        errorCore.color ??
            merged.errorColor ??
            CoreTextFieldStyle.defaultErrorColor,
      )
      .toValue();
  final errorTextStyle = errorCore.toValue(color: errorColor, theme: theme);
  // Affix text — the same size-base every other text in the field wears,
  // in the affix colour the slot's icons already use. No new Core field:
  // the base is the field's single typography source and `affixColor` is
  // already the slot's stated colour, so this is a pairing, not a value.
  final affixTextStyle = baseTextStyle.toValue(
    color: scheme.resolve(affixColor).toValue(),
    theme: theme,
  );

  final cursorColor =
      cursorOverride ??
      scheme.resolve(CoreTextFieldStyle.defaultCursorColor).toValue();
  // Focus border colour — still surfaced for the legacy `TextField`
  // widget (the unified `TextField` consumes it via [focusOutlineStyle]).
  final focusBorderColor =
      focusBorderOverride ?? scheme.resolve(vs.focusRingColor).toValue();
  // Selection tint + EditableText idle cursor colour — resolved here so
  // the widget reads them straight (no widget-side `colorScheme`). Both
  // route through the Core named defaults (single source — no direct
  // `scheme.<token>`).
  final selectionColor = scheme
      .resolve(
        (merged.selectionColor ?? CoreTextFieldStyle.defaultSelectionColor)
            .scaleAlpha(CoreOpacity.opacity20),
      )
      .toValue();
  final backgroundCursorColor = scheme
      .resolve(
        merged.backgroundCursorColor ??
            CoreTextFieldStyle.defaultBackgroundCursorColor,
      )
      .toValue();
  // Focus ring slot — design default merged with the per-instance
  // override, then the RAW border radius + focus-ring colour token baked
  // on. `FocusOutline` resolves the token + scales the radius itself
  // (so the widget forwards the slot whole — no axis extraction, no
  // paint→domain round-trip, no double-scale).
  //
  // Both baked fields are written *under* the caller's slot. `copyWith`
  // passes any non-null argument through, and neither argument here can
  // be null on its own (`focusRingColor` is a non-nullable variant field,
  // the radius local ends in `?? default`) — so stating them unguarded
  // overwrote whatever the merge above had just carried in, and a
  // `focusOutlineStyle.borderColor` / `.borderRadius` the caller wrote
  // never reached the ring.
  //
  // The guards read the *pre-merge* `merged.focusOutlineStyle`, not the
  // merged slot: `defaultFocusOutlineStyle` already states a non-null
  // `borderColor`, so a post-merge read is never null and the variant
  // tone below it would become unreachable — an invalid field would stop
  // ringing error.
  final focusOutlineStyle = CoreTextFieldStyle.defaultFocusOutlineStyle
      .merge(merged.focusOutlineStyle)
      .copyWith(
        // A hosting `Join` outranks the field's own radius here as it
        // does for the chrome (`effectiveRadius` in the decoration) — in
        // its raw form, since `FocusOutline` scales what it is handed.
        borderRadius:
            merged.focusOutlineStyle?.borderRadius ??
            joinItemData?.coreBorderRadius ??
            borderRadius,
        borderColor:
            merged.focusOutlineStyle?.borderColor ??
            merged.focusBorderColor ??
            vs.focusRingColor,
      );

  // ─── Paint-ready dimensional (Stage2 EMIT — `* scaling` in locals) ──
  // The return literal stays a bare mapping; every fallback / conversion /
  // scaling finishes here so the resolved object only carries final values.
  final resolvedHeight = merged.height == null
      ? null
      : merged.height! * scaling;
  // The box's floor — the size row's control height unless the caller
  // fixes or restates it (`CoreTextFieldStyle.boxMinHeight`, shared with
  // Web). A minimum, so a line taller than the row (large text) or a
  // field that grows still grows past it.
  //
  // The size row's control height moves a rung of the control ladder
  // under the theme density before it becomes the floor. A caller's own
  // height, minimum and cap are not rows of the ladder and stay as stated —
  // moving one of a caller's pair would invert the range it states.
  final rowFloor = ss.minHeight == null
      ? null
      : theme.geometry.controlHeight(ss.minHeight!);
  final boxMinHeight = CoreTextFieldStyle.boxMinHeight(
    height: merged.height,
    minHeight: merged.minHeight,
    maxHeight: merged.maxHeight,
    sizeFloor: rowFloor,
  );
  final resolvedMinHeight = boxMinHeight == null
      ? null
      : boxMinHeight * scaling;
  final resolvedMaxHeight = merged.maxHeight == null
      ? null
      : merged.maxHeight! * scaling;
  final resolvedPadding = padding.toValue(geometry: theme.geometry) * scaling;
  final resolvedLabelPadding =
      labelPaddingCore.toValue(geometry: theme.geometry) * scaling;
  final resolvedDescriptionPadding =
      descriptionPaddingCore.toValue(geometry: theme.geometry) * scaling;
  // Behaviour value in, paint-ready inset out: the scroll-into-view
  // inset arrives from `TextField.scrollPadding` and only gets the unit
  // conversion, the theme density and the size factor here (widgets
  // never scale — `resolver/scaling-and-gap.md` Anti-Pattern C).
  final resolvedScrollPadding =
      scrollPadding.toValue(geometry: theme.geometry) * scaling;
  final resolvedBorderWidth = borderWidth == null ? null : restStroke;
  final resolvedCursorRadius = Radius.circular(cursorRadius.x * scaling);
  final resolvedIconSize = iconSize * scaling;
  final fileLabelFontWeight =
      merged.fileLabelFontWeight ??
      CoreTextFieldStyle.defaultFileLabelFontWeight;
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreTextFieldStyle.defaultTransitionDuration,
  );
  // Gated on the fill, like every other content-role surface on this
  // axis: every state's default token is a solid `surface` colour, so
  // fill-vs-no-fill does not vary by state — only an explicit transparent
  // `backgroundColor` override (applied uniformly above) can turn it off.
  // A material handed to a fill-less box stacks a backdrop pass behind
  // nothing and lights the edge of a box that is not there.
  final idleBackgroundCore = backgroundOverrideCore ?? vs.backgroundColor;
  final idleBackgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? idleBackgroundCore
            : idleBackgroundCore.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  final hasFill = idleBackgroundColor.a > 0;
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheen = hasFill ? resolveSurfaceSheen(theme) : null;

  final decoration = WidgetStateProperty.resolveWith(buildDecoration);
  final activeDecoration = WidgetStateProperty.resolveWith(
    buildActiveDecoration,
  );
  final valueTextStyle = WidgetStateProperty.resolveWith(buildValueTextStyle);
  final leadingIconTheme = WidgetStateProperty.resolveWith(
    (states) => buildIconTheme(leadingIconStyle, states),
  );
  final trailingIconTheme = WidgetStateProperty.resolveWith(
    (states) => buildIconTheme(trailingIconStyle, states),
  );

  // ─── Compose paint-ready resolved object ──────────────
  return ResolvedTextField(
    decoration: decoration,
    activeDecoration: activeDecoration,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    valueTextStyle: valueTextStyle,
    leadingIconTheme: leadingIconTheme,
    trailingIconTheme: trailingIconTheme,
    placeholderTextStyle: placeholderTextStyle,
    labelFormLabelStyle: labelFormLabelStyle,
    descriptionTextStyle: descriptionTextStyle,
    affixTextStyle: affixTextStyle,
    errorTextStyle: errorTextStyle,
    cursorColor: cursorColor,
    selectionColor: selectionColor,
    backgroundCursorColor: backgroundCursorColor,
    focusBorderColor: focusBorderColor,
    errorBorderColor: errorBorderOverride,
    height: resolvedHeight,
    minHeight: resolvedMinHeight,
    maxHeight: resolvedMaxHeight,
    padding: resolvedPadding,
    labelPadding: resolvedLabelPadding,
    descriptionPadding: resolvedDescriptionPadding,
    rowSpacing: rowSpacing,
    scrollPadding: resolvedScrollPadding,
    borderWidth: resolvedBorderWidth,
    activeBorderWidth: activeStroke,
    cursorWidth: cursorWidth,
    cursorHeight: cursorHeight,
    cursorRadius: resolvedCursorRadius,
    iconSize: resolvedIconSize,
    leadingIconStyle: leadingIconStyle,
    trailingIconStyle: trailingIconStyle,
    featureButtonStyle: featureButtonStyle,
    focusOutlineStyle: focusOutlineStyle,
    textAlign: textAlign,
    textAlignVertical: textAlignVertical,
    crossAxisAlignment: crossAxisAlignment,
    fileLabelFontWeight: fileLabelFontWeight,
    transitionDuration: transitionDuration,
  );
}
