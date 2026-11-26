library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `TextArea`.
///
/// Widget tree (`co_text_area.dart` decides which optional branches
/// render):
///
/// ```text
/// Column (label / field / description|error)
///   ├─ FormLabel (label, labelFormLabelStyle)       // rendered only when label != null
///   ├─ Gap (labelGapStyle)                        // rendered only when label != null
///   ├─ SizedBox (width / height — wraps drag handle stack)
///   │    └─ Stack
///   │         ├─ FocusOutline
///   │         │    └─ Container (decoration: WidgetStateProperty<Decoration>,
///   │         │         foregroundDecoration: [activeDecoration])
///   │         │         └─ Padding (padding)
///   │         │              └─ Row (rowSpacing)                          // the text row
///   │         │                   ├─ IconTheme.merge (leadingIconTheme)
///   │         │                   │    └─ prefix                            // optional
///   │         │                   ├─ Expanded > EditableText
///   │         │                   │    (valueTextStyle / placeholderTextStyle /
///   │         │                   │     cursorColor / cursorWidth / cursorRadius)
///   │         │                   └─ IconTheme.merge (trailingIconTheme)
///   │         │                        └─ suffix                            // optional
///   │         └─ Positioned (dragHandleOffset / dragHandleSize)             // resize affordance
///   │
///   │    with a footer, the padded box holds a Column around that row:
///   │         └─ Padding (padding)
///   │              └─ Column
///   │                   ├─ Stack                // only when expandable
///   │                   │    ├─ text row        // the text gestures
///   │                   │    └─ Positioned      // the drag handle
///   │                   ├─ Gap (footerGapStyle)
///   │                   └─ footer               // caller-supplied
///   ├─ Gap (descriptionGapStyle)           // rendered only when description != null || errorText != null
///   ├─ Text (description, descriptionTextStyle)   // rendered only when description != null && errorText == null
///   └─ Text (errorText, errorTextStyle)           // rendered only when errorText != null
/// ```
class ResolvedTextArea {
  /// Creates a [ResolvedTextArea].
  const ResolvedTextArea({
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
    required this.counterTextStyle,
    required this.errorTextStyle,
    required this.cursorColor,
    required this.selectionColor,
    required this.backgroundCursorColor,
    required this.dragHandleColor,
    required this.focusBorderColor,
    required this.errorBorderColor,
    required this.borderRadius,
    required this.initialHeight,
    required this.initialWidth,
    required this.minHeight,
    required this.minWidth,
    required this.maxHeight,
    required this.maxWidth,
    required this.padding,
    required this.labelGapStyle,
    required this.descriptionGapStyle,
    required this.footerGapStyle,
    required this.counterGapStyle,
    required this.rowSpacing,
    required this.scrollPadding,
    required this.dragHandlePadding,
    required this.dragHandleOffset,
    required this.dragHandleSize,
    required this.borderWidth,
    required this.activeBorderWidth,
    required this.cursorWidth,
    required this.cursorRadius,
    required this.iconSize,
    required this.leadingIconStyle,
    required this.trailingIconStyle,
    required this.focusOutlineStyle,
    required this.textAlign,
    required this.textAlignVertical,
    required this.transitionDuration,
  });

  // ── State-dependent chrome (WidgetStateProperty) ────────────

  /// Per-state [BoxDecoration] (background colour + border + border
  /// radius).
  final WidgetStateProperty<BoxDecoration> decoration;

  /// Per-state foreground [BoxDecoration] that lays the active boundary
  /// (focused, or the error variant while enabled) over the box — fed to
  /// `Container.foregroundDecoration`. `null` while the area rests, is
  /// disabled, or has no boundary to widen (the active width is no wider
  /// than the resting one, or the boundary colour is transparent).
  ///
  /// The resting boundary stays in [decoration] and keeps its place in the
  /// layout; this paints the same colour over it out to [activeBorderWidth],
  /// so the text does not move (nor the box grow, when its height follows
  /// its rows) when the area takes focus. Same rule as the `TextField`
  /// twin's `activeDecoration`.
  final WidgetStateProperty<BoxDecoration?> activeDecoration;

  /// Backdrop blur sigma for the area's own box, `null` when the active
  /// theme states no material or the area paints no fill of its own to
  /// blur behind (an explicit transparent [CoreTextAreaStyle.backgroundColor]
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

  /// [IconThemeData] for the leading icon slot. The affix colour does not
  /// change with state, so every state resolves to the same theme.
  final WidgetStateProperty<IconThemeData> leadingIconTheme;

  /// [IconThemeData] for the trailing icon slot — see [leadingIconTheme].
  final WidgetStateProperty<IconThemeData> trailingIconTheme;

  // ── State-independent paint-ready ────────────────────────────

  /// Paint-ready placeholder [TextStyle].
  final TextStyle placeholderTextStyle;

  /// Nested [CoreFormLabelStyle] slot raw-forwarded to the composed
  /// `FormLabel(formLabelStyle: …)` — carries this field's per-instance
  /// [CoreTextAreaStyle.labelStyle] override, its disabled-label tint
  /// ([CoreTextAreaStyle.labelDisabledColor]) and the required-asterisk
  /// colour. The enabled label colour is `FormLabel`'s own default.
  ///
  /// **`FormLabel` owns the actual per-size typography default** (its own
  /// `defaultsBySize`: the 13px rung on `xs`/`sm`/`md`, the 14px rung on
  /// `lg`/`xl`/`xl2`); this field states only the parts `TextArea` itself
  /// overrides, so the role arrives from the child rather than being
  /// restated here. The `TextField` twin forwards the same slot the same
  /// way, and the Web twin forwards it to the same composed component.
  ///
  /// Stage1 RESOLVE only — no Stage2 EMIT here, because `FormLabel`'s own
  /// resolver materialises the role and runs `scheme.resolve` on the
  /// colours (resolving them here would force a `CoreColor(…toARGB32())`
  /// round-trip at the call site).
  final CoreFormLabelStyle labelFormLabelStyle;

  /// Paint-ready description [TextStyle].
  final TextStyle descriptionTextStyle;

  /// Paint-ready character-count [TextStyle] (#5747) — the helper row's
  /// trailing `n / max`.
  final TextStyle counterTextStyle;

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

  /// Resolved resize drag-handle colour (`onSurface`).
  final Color dragHandleColor;

  /// Resolved focus border colour — surfaced for the legacy `TextArea`
  /// widget. The unified `TextArea` consumes the focus ring through
  /// [focusOutlineStyle].
  final Color focusBorderColor;

  /// Resolved error border colour — already converted from [CoreColor]
  /// (slot override) or falls back to the focus / variant border colour
  /// when the caller doesn't pin the error stroke.
  final Color errorBorderColor;

  // ── Layout / dimensional ─────────────────────────────────────

  /// Effective border radius. Style override > the size row's corner
  /// (`CoreTextAreaStyle.defaultsBySize[size].borderRadius` — the
  /// `TextField` corner of the same size).
  final CoreBorderRadius borderRadius;

  /// Initial textarea height (logical px).
  final double initialHeight;

  /// Initial textarea width (logical px). `double.infinity` when the
  /// widget should fill the available width.
  final double initialWidth;

  /// Min height constraint when resizable (logical px).
  final double minHeight;

  /// Min width constraint when resizable (logical px).
  final double minWidth;

  /// Max height constraint (logical px). Unbounded resolves to
  /// `double.infinity` (`CoreTextAreaStyle.defaultMaxHeight`), the same
  /// sentinel [initialWidth] carries — so the widget clamps against it
  /// without restating the fallback.
  final double maxHeight;

  /// Max width constraint (logical px). Unbounded resolves to
  /// `double.infinity` (`CoreTextAreaStyle.defaultMaxWidth`).
  final double maxWidth;

  /// Paint-ready content padding — converted from the merged
  /// [CoreEdgeInsets] (slot override or per-size default) in the
  /// resolver, so the widget consumes it directly (render-only).
  final EdgeInsets padding;

  /// 1-off spacer slot between the label (sibling 1) and the field
  /// (sibling 2) — forwarded raw to `Gap(gapStyle:)` so `Gap`'s
  /// own resolver folds in scaling and design defaults.
  final CoreGapStyle labelGapStyle;

  /// 1-off spacer slot between the field (sibling 1) and the
  /// description / error helper text (sibling 2) — forwarded raw to
  /// `Gap(gapStyle:)` so `Gap`'s own resolver folds in scaling
  /// and design defaults.
  final CoreGapStyle descriptionGapStyle;

  /// 1-off spacer slot between the text row (sibling 1) and the footer
  /// (sibling 2), inside the padded box — forwarded raw to
  /// `Gap(gapStyle:)` so `Gap`'s own resolver folds in scaling and design
  /// defaults. Rendered only when the area has a footer.
  final CoreGapStyle footerGapStyle;

  /// Spacer between the helper line and the character count —
  /// raw-forwarded to `Gap(gapStyle:)`.
  final CoreGapStyle counterGapStyle;

  /// Spacing between the prefix / input / suffix row children
  /// (logical px, density and `theme.scaling` pre-applied) — fed to
  /// Flutter `Row.spacing`.
  final double rowSpacing;

  /// Scroll padding around the input when scrolled into view.
  final EdgeInsets scrollPadding;

  /// Padding inside the resize drag-handle hit area.
  final EdgeInsets dragHandlePadding;

  /// Offset (logical px) of the resize drag handle from the bottom-right
  /// corner. Negative pulls inward.
  final double dragHandleOffset;

  /// Size (logical px) of the square resize drag handle hit area.
  final double dragHandleSize;

  /// Border stroke width (logical px, geometry floor and scaling applied);
  /// `null` defers to `CoreStrokeWidth.stroke1`.
  final double? borderWidth;

  /// Width the active boundary is painted out to (logical px, geometry
  /// floor and scaling applied) — what [activeDecoration] draws when it
  /// draws.
  final double activeBorderWidth;

  /// Cursor width (logical px).
  final double cursorWidth;

  /// Paint-ready cursor corner [Radius] — fed straight to
  /// `EditableText.cursorRadius`.
  final Radius cursorRadius;

  /// Effective icon size (logical px, pre-scaling).
  final double iconSize;

  /// Resolved leading icon style (size + slot colour override).
  final CoreIconStyle leadingIconStyle;

  /// Resolved trailing icon style.
  final CoreIconStyle trailingIconStyle;

  /// Paint-ready focus outline slot — fed straight to
  /// `FocusOutline.focusOutlineStyle`.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// Paint-ready horizontal text alignment — converted from the merged
  /// [CoreTextAlign] in the resolver so the widget reads it directly.
  final TextAlign textAlign;

  /// Paint-ready vertical text alignment — converted from the merged
  /// [CoreVerticalAlign] in the resolver. The widget reads
  /// `textAlignVertical.y` for the inner `Align`.
  final TextAlignVertical textAlignVertical;

  /// Colour-transition duration for border / focus state changes.
  final Duration transitionDuration;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTextArea] for a `TextArea`.
///
/// Merge chain:
///
/// ```text
/// design system default (normal or error)
///   → theme.coreComponentTheme.textArea.style
///   → theme.coreComponentTheme.textArea.variantStyles[showsError]
///   → widget.textAreaStyle
/// ```
///
/// `showsError` is [CoreTextFieldVariant.showsErrorChrome] — [hasError]
/// and [enabled] (`disabled > error`). That gate is box chrome only: the
/// error message style of a disabled area with an error still reads the
/// `true` entry of the Theme `variantStyles`.
ResolvedTextArea resolveTextArea(
  BuildContext context, {
  required bool hasError,
  required CoreComponentSize size,
  bool enabled = true,
  CoreTextAreaVariant? variant,
  CoreEdgeInsets scrollPadding = CoreTextAreaContract.defaultScrollPadding,
  CoreTextAreaStyle? textAreaStyle,
}) {
  final theme = Theme.of(context);
  final areaTheme = theme.coreComponentTheme?.textArea;
  final scheme = theme.colorScheme;

  // `disabled > error`, asked of the Core single source
  // (`CoreTextFieldVariant.showsErrorChrome`) rather than spelled here. It
  // keys the Theme row the box chrome reads and the variant table below.
  final showsError = CoreTextFieldVariant.showsErrorChrome(
    hasError: hasError,
    enabled: enabled,
  );

  // The error message is content, not box chrome: the widget shows it
  // whenever `errorText` is set, disabled or not. So a disabled area with
  // an error steps its chrome off the Theme `true` row, but the message
  // keeps reading that row — only the row's two message fields join the
  // chain, above the chrome row and below the instance override. Enabled,
  // the whole row is already in the chain as `showsError`.
  final errorMessageRow = hasError && !showsError
      ? (areaTheme?.variantStyles?[true])
      : null;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreTextAreaStyle(), [
    areaTheme?.style,
    areaTheme?.variantStyles?[showsError],
    if (errorMessageRow != null)
      CoreTextAreaStyle(
        errorStyle: errorMessageRow.errorStyle,
        errorTextColor: errorMessageRow.errorTextColor,
      ),
    textAreaStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  // Variant chrome selected via the contract's `defaultsByVariant` holder
  // (single subscript — no ternary over the two named constants).
  final vs =
      CoreTextAreaStyle.defaultsByVariant[CoreTextAreaVariant.of(
        hasError: hasError,
        enabled: enabled,
        variant: variant,
      )]!;
  final ss = resolveSizeRow(CoreTextAreaStyle.defaultsBySize, size);
  // A retiring size renders as before; a run with asserts on logs it once
  // (asserts stripped: nothing), so the caller hears before the step goes.
  noticeRetiringSize(
    component: 'TextArea',
    size: size,
    retiring: CoreTextAreaContract.retiringSizes,
  );

  // The area draws its own box directly on the native `<textarea>`/its
  // Flutter twin's `Container` rather than composing `OutlinedContainer`
  // (a wrap would move the framed body to a different element than the
  // one `FocusOutline` rings, offsetting the ring — and the resize drag
  // handle is positioned against this same box). A glass style's material
  // reaches it the same way it reaches a card — through the content-layer
  // seat, folded into the fill below.
  final material = theme.surfaceFor(.content, depth: SurfaceDepth.of(context));
  final surfaceOpacity = material?.opacityIn(theme);

  // ─── Resolved nested slot styles ──────────────────────
  // Nested CoreIconStyle slot — design-system per-size default merged
  // with the per-instance override. Size used for the resolver-side
  // affix layout (icon → input gap), then forwarded raw to `Icon`.
  final iconStyleSlot = ss.iconStyle!.merge(merged.iconStyle);
  final iconSize = iconStyleSlot.size!;

  // Base typography role — the per-size `baseTextStyle` token (or the
  // caller override). Token-backed, so each slot below merges its own
  // override on top and materialises through `.toValue(theme:, color:)`
  // in one step (no manual `typography.resolve` metric extraction).
  final baseRole = merged.baseTextStyle ?? ss.baseTextStyle!;
  final placeholderCore = baseRole.merge(merged.placeholderStyle);
  final valueCore = baseRole.merge(merged.valueStyle);
  // Description / error are size-INVARIANT (`bodyXs` on every rung) —
  // merged onto the flat `defaultDescriptionStyle`, not the per-size
  // `baseRole`, which would carry them to the 14 / 15px body roles at lg/xl.
  // The Web resolver reads them the same way, so the helper text holds one
  // size across both platforms.
  // The `lg` rung and above state their own helper role (#5747).
  final descriptionCore = CoreTextAreaStyle.defaultDescriptionStyle
      .merge(ss.descriptionStyle)
      .merge(merged.descriptionStyle);
  final errorCore = CoreTextAreaStyle.defaultDescriptionStyle
      .merge(ss.descriptionStyle)
      .merge(merged.errorStyle);

  final leadingIconStyle = CoreIconStyle(size: iconSize);
  final trailingIconStyle = CoreIconStyle(size: iconSize);

  // ─── Resolved state-independent chrome ────────────────
  // Area corner — the per-instance override wins, else the size row's
  // corner (the `TextField` corner of the same size step; the area's own
  // height is set by its rows, not by the control ladder).
  final borderRadius = merged.borderRadius ?? ss.borderRadius!;
  final borderWidth = merged.borderWidth;
  final effectiveRadius = borderRadius.toValue(geometry: theme.geometry);
  final cursorWidth =
      merged.cursorWidth ?? CoreTextAreaStyle.defaultCursorWidth;
  final cursorRadius = Radius.circular(
    theme.geometry
        .borderRadius(
          merged.cursorRadius ?? CoreTextAreaStyle.defaultCursorRadius,
        )
        .topLeft,
  );
  // Paint-ready content padding — Stage2 EMIT in the local so the widget
  // reads `resolved.padding` directly (render-only). No `* scaling` to
  // preserve the existing visual (the widget consumed `.toValue()` with
  // no scaling).
  final padding = (merged.padding ?? ss.padding!).toValue(
    geometry: theme.geometry,
  );
  // Nested CoreGapStyle slot — raw forward to `Gap` (no parent-side
  // scaling, no inline construction). The default slot is merged onto
  // the per-instance override so a caller override (size / colour /
  // crossAxisExtent) reaches the rendered gap while unset fields fall
  // back to the design-system default.
  final labelGapStyle = CoreTextAreaStyle.defaultLabelGapStyle
      .merge(ss.labelGapStyle)
      .merge(merged.labelGapStyle);
  final descriptionGapStyle = CoreTextAreaStyle.defaultDescriptionGapStyle
      .merge(ss.descriptionGapStyle)
      .merge(merged.descriptionGapStyle);
  final footerGapStyle = CoreTextAreaStyle.defaultFooterGapStyle.merge(
    merged.footerGapStyle,
  );
  final counterGapStyle = CoreTextAreaStyle.defaultCounterGapStyle.merge(
    merged.counterGapStyle,
  );
  final rowSpacing = merged.rowSpacing ?? CoreTextAreaStyle.defaultRowSpacing;
  final dragHandlePaddingCore =
      merged.dragHandlePadding ?? CoreTextAreaStyle.defaultDragHandlePadding;
  final scaling = theme.scaling;
  // The resting boundary keeps its place in the layout; the active one is
  // painted over the box out to `activeBorderWidth` without taking layout.
  // Both go through the geometry floor (as the `TextField` twin's do), so a
  // preset whose floor lifts the two to one width has nothing to add.
  final restStroke = theme.geometry.stroke(
    borderWidth ?? CoreTextAreaStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final activeStroke = theme.geometry.stroke(
    merged.activeBorderWidth ?? CoreTextAreaStyle.defaultActiveBorderWidth,
    scaling: scaling,
  );
  // A width that is no wider than the resting one adds nothing to paint (a
  // caller who states a thicker `borderWidth` alone is not thinned on focus).
  final widensActiveBoundary = activeStroke > restStroke;
  // Behaviour value in, paint-ready inset out: the scroll-into-view
  // inset arrives from `TextArea.scrollPadding` and only gets the unit
  // conversion, the theme density and the size factor here (widgets
  // never scale — `resolver/scaling-and-gap.md` Anti-Pattern C).
  final resolvedScrollPadding =
      scrollPadding.toValue(geometry: theme.geometry) * scaling;
  final dragHandlePadding =
      (dragHandlePaddingCore.toValue(geometry: theme.geometry)) * scaling;
  // `Row.spacing` between prefix / input / suffix — the density's rung,
  // then the size factor, as `TextField` does for the same row.
  final rowSpacingValue = theme.geometry.space(rowSpacing) * scaling;
  final dragHandleOffset =
      (merged.dragHandleOffset ?? CoreTextAreaStyle.defaultDragHandleOffset) *
      scaling;
  final dragHandleSize =
      (merged.dragHandleSize ?? CoreTextAreaStyle.defaultDragHandleSize) *
      scaling;
  final initialHeight =
      merged.initialHeight ??
      ss.initialHeight ??
      CoreTextAreaStyle.defaultInitialHeight;
  final initialWidth =
      merged.initialWidth ?? CoreTextAreaStyle.defaultInitialWidth;
  final minHeight = merged.minHeight ?? CoreTextAreaStyle.defaultMinHeight;
  final minWidth = merged.minWidth ?? CoreTextAreaStyle.defaultMinWidth;
  final maxHeight = merged.maxHeight ?? CoreTextAreaStyle.defaultMaxHeight;
  final maxWidth = merged.maxWidth ?? CoreTextAreaStyle.defaultMaxWidth;
  // Paint-ready text alignment — Stage2 EMIT in the local so the widget
  // reads the converted `TextAlign` / `TextAlignVertical` directly.
  final textAlign = (merged.textAlign ?? CoreTextAreaStyle.defaultTextAlign)
      .toValue();
  final textAlignVertical =
      (merged.textAlignVertical ?? CoreTextAreaStyle.defaultTextAlignVertical)
          .toTextAlignVertical();
  // Focus outline — design-default slot merged with the per-instance
  // override. Every field is non-null after the merge.
  // Focus ring slot — design default + per-instance override, then the
  // RAW border radius + the focus-ring colour token forwarded whole.
  // `borderWidth` is left untouched — the merge above already carries
  // `CoreFocusOutlineStyle.defaultBorderWidth` (or the per-instance
  // override) forward. `ringOpacity` is also left untouched on the
  // forwarded slot — `FocusOutline`'s own resolver applies it via
  // `CoreColor.scaleAlpha` exactly once (baking it in here too would
  // double-apply it). `FocusOutline` resolves the token + scales the
  // radius (so the widget forwards the slot whole — no
  // `CoreColor(x.toARGB32())` round-trip, no axis extraction).
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
  // tone below it would become unreachable — an invalid text area would
  // stop ringing error.
  final focusOutlineStyle = CoreTextAreaStyle.defaultFocusOutlineStyle
      .merge(merged.focusOutlineStyle)
      .copyWith(
        borderRadius: merged.focusOutlineStyle?.borderRadius ?? borderRadius,
        borderColor:
            merged.focusOutlineStyle?.borderColor ??
            merged.focusBorderColor ??
            vs.focusRingColor,
      );

  // Per-instance colour overrides. `backgroundOverrideCore` stays a raw
  // `CoreColor` (not yet resolved) so `buildDecoration` can fold
  // [surfaceOpacity] into it. The others convert to Flutter [Color] once
  // here so the state builders below don't re-run `scheme.resolve`.
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
  // border for a variant that states none. Mirrors
  // `text_field_style.dart`'s identical `hoverBorderColor` local.
  final hoverBorderColor = scheme
      .resolve(
        merged.hoverBorderColor ?? vs.hoverBorderColor ?? vs.borderColor,
      )
      .toValue();
  final errorBorderOverride = merged.errorBorderColor != null
      ? scheme.resolve(merged.errorBorderColor!).toValue()
      : null;
  final cursorOverride = merged.cursorColor != null
      ? scheme.resolve(merged.cursorColor!).toValue()
      : null;
  // Prefix / suffix glyph colour — one value in every state, the twin of
  // the `TextField` resolver's `affixColor` local and of the Web
  // resolver's affix-slot text class (both read `affixColor ??
  // defaultAffixColor`). A glyph that annotates the value does not change
  // with the area's state; the value text and the boundary are what say
  // "disabled".
  final affixColor = scheme
      .resolve(merged.affixColor ?? CoreTextAreaStyle.defaultAffixColor)
      .toValue();
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreTextAreaStyle.defaultTransitionDuration,
  );

  // ─── Local builders ───────────────────────────────────

  /// The boundary colour for the given [states] — the ladder `disabled >
  /// focus > hover > rest`, shared by the resting [BoxDecoration] and the
  /// active boundary laid over it, so the two meet in one colour.
  Color buildBorderColor(Set<WidgetState> states) {
    final isDisabled = states.contains(WidgetState.disabled);
    final isFocused = states.contains(WidgetState.focused);
    final isHovered = states.contains(WidgetState.hovered);

    Color borderColor;
    if (isDisabled) {
      // #3469 — dedicated disabled border token, mirrors text_field's
      // identical fix (was `vs.borderColor`, the enabled colour unchanged).
      borderColor = scheme.resolve(vs.disabledBorderColor).toValue();
    } else if (isFocused) {
      borderColor =
          focusBorderOverride ?? scheme.resolve(vs.focusRingColor).toValue();
    } else if (isHovered) {
      // Hover is a border step, not a fill — mirrors text_field's
      // identical `disabled > focus > hover > rest` precedence.
      borderColor = hoverBorderColor;
    } else {
      borderColor = scheme.resolve(vs.borderColor).toValue();
    }

    if (!isFocused && !isHovered && borderOverride != null) {
      borderColor = borderOverride;
    }

    // Through the shared helper, like every surface that resolves its own
    // stroke: a material that draws its own edge suppresses the area's
    // hairline so the box doesn't draw a second boundary on top of it.
    return resolveSurfaceStroke(theme, borderColor);
  }

  /// Resolves the [BoxDecoration] for the given [states].
  BoxDecoration buildDecoration(Set<WidgetState> states) {
    final isDisabled = states.contains(WidgetState.disabled);
    final isHovered =
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.pressed);

    // The filled variant steps its fill under the pointer (#5747); the
    // boxed variants state no hover fill.
    final bgCore =
        backgroundOverrideCore ??
        (isDisabled
            ? vs.disabledBackgroundColor
            : (isHovered ? vs.hoverBackgroundColor : null) ??
                  vs.backgroundColor);

    // surface:content — fold the material's opacity into the fill before
    // Stage2 EMIT, the same seat every other content-role surface folds
    // it at.
    final bgColor = scheme
        .resolve(
          surfaceOpacity == null ? bgCore : bgCore.scaleAlpha(surfaceOpacity),
        )
        .toValue();

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
  /// width. `null` when nothing is added — see [ResolvedTextArea
  /// .activeDecoration].
  BoxDecoration? buildActiveDecoration(Set<WidgetState> states) {
    if (!widensActiveBoundary) return null;
    // Focus alone widens the boundary (#5747), as on `TextField`.
    final isActive =
        !states.contains(WidgetState.disabled) &&
        states.contains(WidgetState.focused);
    if (!isActive) return null;
    final borderColor = buildBorderColor(states);
    // A transparent boundary paints nothing; skipping it also keeps a
    // zero-width resting border from being thickened into a visible one.
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
    return valueCore.toValue(color: fgColor, theme: theme);
  }

  /// Resolves the [IconThemeData] for the given slot style — the affix
  /// colour unless the slot states its own.
  IconThemeData buildIconTheme(CoreIconStyle slotStyle) {
    final iconColor = slotStyle.color != null
        ? scheme.resolve(slotStyle.color!).toValue()
        : affixColor;
    return IconThemeData(
      size: slotStyle.size ?? iconSize,
      color: iconColor,
    );
  }

  // ─── State-independent paint-ready ────────────────────
  // Each slot's typography role (the per-size base role + the slot
  // override) is materialised + coloured in one step via
  // `.toValue(theme:, color:)` — no `theme.typography.<role>` hardcode.
  // A disabled area's placeholder takes the disabled foreground (#5747).
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

  // The label's ROLE is not stated here. `FormLabel` owns the per-size
  // ladder (`CoreFormLabelStyle.defaultsBySize` — the 13px rung on
  // `xs`/`sm`/`md`, the 14px rung on `lg`/`xl`/`xl2`) and this component
  // composes it, so restating a role would be the container reaching into
  // the child's defaults. A role derived from `baseRole` would be the BODY
  // role of the value text — `lg` and up at `bodyMedium`, right size and
  // wrong family — and a flat label role would hold one role at every rung;
  // either splits the same label across Flutter, Web and the canvas.
  //
  // The label's COLOUR is not stated here either: the enabled colour is
  // `FormLabel`'s own default, so a label reads the same beside a
  // `TextField`, and the variant's value-text `foregroundColor` does not
  // reach it. What TextArea does state travels as the
  // caller's `labelStyle` (raw-forwarded whole, so any role / colour /
  // weight the caller wrote wins over the child's rung), the disabled
  // tint and the required mark — the same shape the `TextField` resolver
  // forwards.
  final labelFormLabelStyle = CoreFormLabelStyle(
    labelStyle: merged.labelStyle,
    disabledColor:
        merged.labelDisabledColor ??
        CoreTextAreaStyle.defaultLabelDisabledColor,
    requiredColor:
        merged.requiredMarkColor ?? CoreTextAreaStyle.defaultRequiredMarkColor,
  );

  final descriptionColor = scheme
      .resolve(
        descriptionCore.color ??
            merged.helperTextColor ??
            CoreTextAreaStyle.defaultHelperTextColor,
      )
      .toValue();
  final descriptionTextStyle = descriptionCore.toValue(
    color: descriptionColor,
    theme: theme,
  );

  // Character count (#5747) — the counter default, then the size row's
  // helper role, then the instance override.
  final counterCore = CoreTextAreaStyle.defaultCounterStyle
      .merge(ss.descriptionStyle)
      .merge(merged.counterStyle);
  final counterTextStyle = counterCore.toValue(
    color: scheme
        .resolve(
          counterCore.color ?? CoreTextAreaStyle.defaultCounterStyle.color!,
        )
        .toValue(),
    theme: theme,
  );

  final errorColor = scheme
      .resolve(
        errorCore.color ??
            merged.errorTextColor ??
            CoreTextAreaStyle.defaultErrorTextColor,
      )
      .toValue();
  final errorTextStyle = errorCore.toValue(color: errorColor, theme: theme);

  final cursorColor =
      cursorOverride ??
      scheme.resolve(CoreTextAreaStyle.defaultCursorColor).toValue();
  final focusBorderColor =
      focusBorderOverride ?? scheme.resolve(vs.focusRingColor).toValue();
  // Selection tint, idle cursor + drag-handle colour — each routed through
  // the Core single-source default token (no direct widget-side
  // `colorScheme` token reach).
  final selectionColor = scheme
      .resolve(
        merged.selectionColor ?? CoreTextAreaStyle.defaultSelectionColor,
      )
      .toValue()
      .withValues(alpha: CoreOpacity.opacity20);
  final backgroundCursorColor = scheme
      .resolve(
        merged.backgroundCursorColor ??
            CoreTextAreaStyle.defaultBackgroundCursorColor,
      )
      .toValue();
  final dragHandleColor = scheme
      .resolve(
        merged.dragHandleColor ?? CoreTextAreaStyle.defaultDragHandleColor,
      )
      .toValue();
  // Error border colour — mirrors Web pattern: errorBorderColor override
  // wins when in error variant, else falls back to borderColor override,
  // else the variant's own borderColor token.
  final errorBorderColor =
      errorBorderOverride ??
      borderOverride ??
      scheme.resolve(vs.borderColor).toValue();

  // Gated on the fill, like every other content-role surface on this
  // axis: every state's default token is a solid `surface` colour, so
  // fill-vs-no-fill does not vary by state — only an explicit transparent
  // `backgroundColor` override (applied uniformly above) can turn it off.
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

  final resolvedBorderWidth = borderWidth == null ? null : restStroke;

  // ─── Compose paint-ready resolved object ──────────────
  return ResolvedTextArea(
    decoration: WidgetStateProperty.resolveWith(buildDecoration),
    activeDecoration: WidgetStateProperty.resolveWith(buildActiveDecoration),
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    valueTextStyle: WidgetStateProperty.resolveWith(buildValueTextStyle),
    leadingIconTheme: WidgetStateProperty.all(
      buildIconTheme(leadingIconStyle),
    ),
    trailingIconTheme: WidgetStateProperty.all(
      buildIconTheme(trailingIconStyle),
    ),
    placeholderTextStyle: placeholderTextStyle,
    labelFormLabelStyle: labelFormLabelStyle,
    descriptionTextStyle: descriptionTextStyle,
    counterTextStyle: counterTextStyle,
    errorTextStyle: errorTextStyle,
    cursorColor: cursorColor,
    selectionColor: selectionColor,
    backgroundCursorColor: backgroundCursorColor,
    dragHandleColor: dragHandleColor,
    focusBorderColor: focusBorderColor,
    errorBorderColor: errorBorderColor,
    borderRadius: borderRadius,
    initialHeight: initialHeight,
    initialWidth: initialWidth,
    minHeight: minHeight,
    minWidth: minWidth,
    maxHeight: maxHeight,
    maxWidth: maxWidth,
    padding: padding,
    labelGapStyle: labelGapStyle,
    descriptionGapStyle: descriptionGapStyle,
    footerGapStyle: footerGapStyle,
    counterGapStyle: counterGapStyle,
    rowSpacing: rowSpacingValue,
    scrollPadding: resolvedScrollPadding,
    dragHandlePadding: dragHandlePadding,
    dragHandleOffset: dragHandleOffset,
    dragHandleSize: dragHandleSize,
    borderWidth: resolvedBorderWidth,
    activeBorderWidth: activeStroke,
    cursorWidth: cursorWidth,
    cursorRadius: cursorRadius,
    iconSize: iconSize,
    leadingIconStyle: leadingIconStyle,
    trailingIconStyle: trailingIconStyle,
    focusOutlineStyle: focusOutlineStyle,
    textAlign: textAlign,
    textAlignVertical: textAlignVertical,
    transitionDuration: transitionDuration,
  );
}
