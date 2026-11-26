import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/frame/frame_style.dart'
    show coreMainAxisAlignmentToFlutter;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Chip`.
///
/// Widget tree (`co_chip` decides which optional slots render):
///
/// ```text
/// Clickable (tap / keyboard / cursor / focus ring / press feedback)
///   │                                          // composed only when onTap != null
///   └─ InjectedCast (boxShadow / castHideDuration / reverseCastMotion)
///        └─ OutlinedContainer (containerStyle)   // composed chip surface — bg / border / radius / padding
///             └─ Row (mainAxisSize.min)
///                  ├─ IconTheme (leadingIconColor / leadingIconSize)   // leading != null
///                  │    └─ leading                                     // caller Widget
///                  ├─ Gap (iconLabelGapStyle)                        // leading != null
///                  ├─ Text (prefixLabelTextStyle)                     // prefixLabel != null — one line, never shrinks
///                  ├─ Gap (iconLabelGapStyle)                        // prefixLabel != null && labelWidget != null
///                  ├─ Flexible > label | child                        // labelWidget != null
///                  ├─ Gap (iconLabelGapStyle) + IconTheme (trailing*) // trailing != null
///                  └─ Gap (iconLabelGapStyle) +
///                       Button(ghost, closeButtonStyle)
///                       └─ Icon (closeIconStyle)  // onRemove != null
/// ```
///
/// Field grouping:
///
/// 1. **Composed chip surface** — [containerStyle] carries background /
///    border / radius / padding as `coui_core` domain types straight to
///    `OutlinedContainer`, which runs the state-resolved colour's final
///    `scheme.resolve(...).toValue()` step itself (mirrors the Web
///    resolver's class / inline CSS branch, so the widget never re-runs
///    state colour selection). [castBorderRadius] mirrors that surface's
///    own (unscaled) radius for the separate `InjectedCast` shadow layer.
/// 2. **State-independent chrome** — plain Flutter / `coui_core` domain
///    types (`double`, [Duration]).
/// 3. **Nested slot styles** — [closeButtonStyle] forwarded to the
///    nested `Button`; the leading / trailing icon colours are
///    pre-resolved into [leadingIconColor] / [trailingIconColor] and the
///    close icon into [closeIconStyle] (slot colour override else
///    foreground) so the widget forwards them straight to `IconTheme` /
///    `CoreIconStyle`.
class ResolvedChip {
  /// Creates a [ResolvedChip].
  const ResolvedChip({
    required this.containerStyle,
    required this.hoverContainerStyle,
    required this.focusContainerStyle,
    required this.pressedContainerStyle,
    required this.castBorderRadius,
    required this.minHeight,
    required this.contentAlignment,
    required this.iconLabelGapStyle,
    required this.labelTextStyle,
    required this.prefixLabelTextStyle,
    required this.leadingIconSize,
    required this.trailingIconSize,
    required this.closeIconStyle,
    required this.foregroundColor,
    required this.leadingIconColor,
    required this.trailingIconColor,
    required this.closeButtonStyle,
    required this.clickableStyle,
    required this.boxShadow,
    required this.castHideDuration,
    required this.reverseCastMotion,
    required this.transitionDuration,
  });

  /// [CoreOutlinedContainerStyle] for the composed `OutlinedContainer`
  /// chip surface — background / border / radius / padding are merged
  /// and expressed as `coui_core` domain types so the receiving widget
  /// runs its own colour / radius resolution once (mirrors `Card`'s
  /// `containerStyle`). Always carries an explicit empty `boxShadow`
  /// override — the chip's own press/hover cast ([boxShadow] /
  /// [castHideDuration] / [reverseCastMotion] below, painted by
  /// `InjectedCast` as a *separate* composition layer) is what draws
  /// the chip's shadow, so the primitive itself must draw none of its
  /// own or the two would double up.
  final CoreOutlinedContainerStyle containerStyle;

  /// Box chrome while the pointer is over the chip.
  final CoreOutlinedContainerStyle hoverContainerStyle;

  /// Box chrome while the chip holds keyboard focus.
  final CoreOutlinedContainerStyle focusContainerStyle;

  /// Box chrome while the chip is held down.
  final CoreOutlinedContainerStyle pressedContainerStyle;

  /// Materialised border radius mirroring the composed surface's own
  /// (unscaled — matches `OutlinedContainer`'s own radius handling,
  /// which does not multiply by `theme.scaling`) — consumed by
  /// `InjectedCast` / `_PressableChip` so the cast's rounded shape
  /// tracks the chip's corner exactly.
  final BorderRadius castBorderRadius;

  /// Chip height floor (scaled) — the size tier's ladder value, so the
  /// chip matches the control beside it rather than its own label line.
  final double minHeight;

  /// Main-axis placement of the content row when the chip is drawn wider
  /// than its content — `Row.mainAxisAlignment`.
  final MainAxisAlignment contentAlignment;

  /// Nested [CoreGapStyle] forwarded straight to `Gap(gapStyle: …)`
  /// for the leading↔label / label↔trailing / label↔close spacers.
  /// `Gap` self-applies `theme.scaling`, so the resolver passes this
  /// through without multiplying.
  final CoreGapStyle iconLabelGapStyle;

  /// Paint-ready label [TextStyle] — the size row's label typography role
  /// (`labelSmall` / `labelMedium` / `labelLarge`, semi-bold) with the
  /// per-instance `labelStyle` slot (font-size / weight / spacing /
  /// height) layered on, bound to the state-resolved foreground colour.
  /// Forwarded straight to `Text(style: …)` by the widget. Font scaling
  /// is delegated to Flutter's `MediaQuery.textScaler`, so this style is
  /// not multiplied by `theme.scaling`.
  final TextStyle labelTextStyle;

  /// Paint-ready [TextStyle] for the key in front of the label
  /// (`prefixLabel`) — the size row's key role (`labelXs` / `labelSmall` /
  /// `labelMedium`, the role's own weight) with the per-instance
  /// `prefixLabelStyle` slot layered on, bound to the key's state-resolved
  /// colour: [CoreChipColorStyle.unselectedPrefixFg] on a resting chip, the
  /// label's own colour once selected or disabled. Not multiplied by
  /// `theme.scaling`, for the same reason as [labelTextStyle].
  final TextStyle prefixLabelTextStyle;

  /// Leading icon size (logical px, pre-scaling).
  final double leadingIconSize;

  /// Trailing icon size (logical px, pre-scaling).
  final double trailingIconSize;

  /// Close-button (X) icon style — forwarded straight to
  /// `Icon(iconStyle: …)` by the widget. Carries the size slot
  /// (pre-scaling; `Icon`'s own resolver applies `theme.scaling`).
  final CoreIconStyle closeIconStyle;

  /// Paint-ready foreground (label) colour (state + override resolved).
  final Color foregroundColor;

  /// Paint-ready leading icon colour — slot colour override else
  /// [foregroundColor].
  final Color leadingIconColor;

  /// Paint-ready trailing icon colour — slot colour override else
  /// [foregroundColor].
  final Color trailingIconColor;

  /// Per-instance close button slot override (forwarded to nested Button).
  final CoreButtonStyle? closeButtonStyle;

  /// Nested [CoreClickableStyle] slot for the `Clickable` the widget
  /// composes around a tappable (`onTap != null`) chip —
  /// `CoreChipStyle.defaultClickableStyle` with the face's corner (so the
  /// focus ring follows the size row's corner, or the pill's) merged with
  /// the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)` (the Clickable's own resolver fills
  /// the rest).
  final CoreClickableStyle clickableStyle;

  /// The active surface style's injected cast, or empty under a
  /// style that injects none.
  ///
  /// Painted by `co_chip.dart`'s `InjectedCast` as a composition layer
  /// *separate* from the composed `OutlinedContainer` surface — that
  /// primitive's own [containerStyle] carries an explicit empty
  /// `boxShadow` override so it draws none of its own. Empty under
  /// every style that casts nothing, so the widget paints it
  /// unconditionally.
  final List<BoxShadow> boxShadow;

  /// The clock `co_chip.dart`'s `InjectedCast.duration` hides [boxShadow]
  /// on while pressed/hovered — kept deliberately apart from the chip's
  /// chrome-transition speed (now [containerStyle]'s own `duration`) the
  /// same way the Button resolver keeps its own `castHideDuration` apart
  /// from `animationDuration`: hiding a shadow on the chrome clock would
  /// lag the travel it is paired with.
  ///
  /// Already routed through [resolveMotionDuration] — collapses to
  /// [Duration.zero] under reduced motion (`core/design-tokens.md`'s
  /// transition tier), mirroring the Web twin's shared
  /// `ThemeConfig._controlShadowPressRule` clock.
  final Duration castHideDuration;

  /// Whether [boxShadow] should be hidden at rest and shown while
  /// engaged instead of the default hide-on-engage — `true` exactly
  /// when [CoreChipStyle.castMotion] resolved to [CoreCastMotion.reverse]
  /// (Chip has no authored-shadow slot, so unlike `Button` this is a
  /// direct read of `castMotion`, not gated on one).
  ///
  /// `co_chip.dart` reads this to flip the `InjectedCast.visible`
  /// formula; the travel direction is already baked into
  /// [CoreClickableStyle.pressedTranslate] on [clickableStyle] by the
  /// resolver below.
  final bool reverseCastMotion;

  /// The chip's chrome-transition clock (hover/selected background /
  /// border / radius speed) — the same value forwarded into
  /// [containerStyle]'s own `duration`, exposed here directly so a
  /// caller does not have to reach into the nested style to read it.
  /// Already routed through [resolveMotionDuration] — collapses to
  /// [Duration.zero] under reduced motion, independently of
  /// [castHideDuration] (`core/design-tokens.md`'s transition tier: this
  /// is a different clock from the press/hover cast's).
  final Duration transitionDuration;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedChip] for the given [context].
///
/// Single public entry point — the nested-merge chain
/// (`defaultsBySize` → `defaultsByShape` → `theme.style` →
/// `widget.chipStyle`) plus the per-variant colour table and the state
/// colour selection (`selected` / `enabled` / `seedColor`) are applied once
/// here. The per-state / per-slot colour resolution lives in the
/// file-private `_resolveChip*` helpers below so the widget stays
/// render-only.
///
/// ```text
/// design system default (defaultsBySize[size] → defaultsByShape[shape])
///   → CoreChipTheme.style
///   → CoreChipTheme.colorStyles[chipColor]
///   → CoreChipTheme.variantStyles[variant]
///   → widget.chipStyle
///     → per-colour table (defaultsByColor) / seedColor
/// ```
///
/// `chipColor` / `variant` / `size` / `shape` are widget props — the theme
/// cannot override them (render-only.md "semantic identifiers are
/// widget-only"). They thread through to pick the per-size default entry,
/// the per-shape corner, the per-colour table row and the unselected fill
/// here.
///
/// [shape] defaults to [CoreChipShape.defaultShape], so a caller that
/// predates the shape axis resolves the corner it always did.
ResolvedChip resolveChip(
  BuildContext context, {
  required CoreChipColor chipColor,
  required CoreChipVariant variant,
  required CoreChipSize size,
  required bool selected,
  required CoreChipEmphasis emphasis,
  required bool enabled,
  CoreChipShape shape = CoreChipShape.defaultShape,
  CoreColor? seedColor,
  CoreChipStyle? chipStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final chipTheme = theme.coreComponentTheme?.chip;

  // Merge chain head — an empty `CoreChipStyle()` with the per-size
  // design-system default folded in, then the shape's row over it (matches
  // the Web chip resolver's head). `rounded` states nothing there and keeps
  // the size row's corner; `pill` states the full corner. The theme +
  // per-instance overrides then win over both, so a stated `borderRadius`
  // draws every shape with that corner.
  final sizeDefault = CoreChipStyle.defaultsBySize[size]!;
  final merged = resolveStyleChain(
    const CoreChipStyle()
        .merge(sizeDefault)
        .merge(CoreChipStyle.defaultsByShape[shape]),
    [
      chipTheme?.style,
      chipTheme?.colorStyles?[chipColor],
      chipTheme?.variantStyles?[variant],
      chipStyle,
    ],
  );

  // ─── State colour resolution (custom-seed | variant table) ─────
  // Mirrors the Web resolver's class / inline-CSS branch: the
  // `selected` / `enabled` / `seedColor` state picks the base colours,
  // then the per-instance override (`merged.backgroundColor` etc.) wins.
  // Resolved to tagged [CoreColor]s (via `scheme.resolve`) so the nested
  // close `Icon` can forward a [CoreColor] slot (C8); each is converted
  // to a Flutter [Color] once below via `.toValue()` (Epic #1603 C7).
  // The fill an unselected, enabled chip wears at `filled` — one grey for
  // every colour, and the border mirrors it (no outline), the way a selected
  // chip's border mirrors its own fill. Meaningless for a selected or a
  // disabled chip, which ignore `variant`.
  final filledFill = scheme.resolve(
    merged.filledUnselectedBackgroundColor ??
        CoreChipStyle.defaultFilledUnselectedBackgroundColor,
  );
  final filled = variant == .filled;
  final CoreColor bgBase;
  final CoreColor fgBase;
  final CoreColor borderBase;
  // The key in front of the label (`prefixLabel`). Only a resting chip
  // gives it an ink of its own (`CoreChipColorStyle.unselectedPrefixFg` —
  // quieter than the high label, the same as the low one); selected and
  // disabled chips draw it in the label's colour.
  final CoreColor prefixBase;
  // A custom seed speaks only when the chip is selected: an unselected
  // chip states no colour, so an enabled one falls through to the
  // neutral table row below like every other colour (a raw seed cannot
  // promise contrast on the surface behind it, either).
  if (chipColor == .custom && seedColor != null && (selected || !enabled)) {
    final seed = scheme.resolve(seedColor);
    if (!enabled) {
      // Disabled drops the seed entirely. Two rows, like the table
      // below (see its comment for why the selected row's border is
      // stated as transparent rather than as the fill colour).
      bgBase = scheme.resolve(
        selected
            ? merged.customDisabledBackgroundColor ??
                  CoreChipStyle.defaultCustomDisabledBackgroundColor
            : merged.customDisabledUnselectedBackgroundColor ??
                  CoreChipStyle.defaultCustomDisabledUnselectedBackgroundColor,
      );
      fgBase = scheme.resolve(
        merged.customDisabledForegroundColor ??
            CoreChipStyle.defaultCustomDisabledForegroundColor,
      );
      borderBase = scheme.resolve(
        selected
            ? merged.disabledSelectedBorderColor ??
                  CoreChipStyle.defaultDisabledSelectedBorderColor
            : merged.customDisabledBorderColor ??
                  CoreChipStyle.defaultCustomDisabledBorderColor,
      );
    } else if (selected && emphasis == .low) {
      // A raw seed has no container token to tint from — see
      // `CoreChipStyle.defaultCustomLowSelectedBackgroundColor`.
      bgBase = scheme.resolve(
        merged.customLowSelectedBackgroundColor ??
            CoreChipStyle.defaultCustomLowSelectedBackgroundColor,
      );
      fgBase = scheme.resolve(
        merged.customLowSelectedForegroundColor ??
            CoreChipStyle.defaultCustomLowSelectedForegroundColor,
      );
      borderBase = bgBase;
    } else {
      // Selected + high — the only row left in this block.
      bgBase = seed;
      // The label is the seed's own on-colour — chosen in Core from the
      // unresolved seed (a token keeps its pairing, a raw colour is
      // measured), so the Web resolver reaches the same answer. Routed
      // through `scheme.resolve` — a raw (non-token) colour passes through
      // unchanged.
      fgBase = scheme.resolve(
        merged.customSelectedForegroundColor ??
            CoreChipStyle.defaultCustomSelectedForegroundColorFor(seedColor),
      );
      borderBase = seed;
    }
    // Selected or disabled — the only states this block is entered for.
    prefixBase = fgBase;
  } else {
    final colorStyle =
        CoreChipStyle.defaultsByColor[chipColor] ??
        CoreChipStyle.defaultsByColor[CoreChipColor.neutral]!;
    if (!enabled) {
      // Two disabled rows: selected keeps a filled container with a
      // transparent border (`defaultDisabledSelectedBorderColor` — see
      // its doc comment: the composed `OutlinedContainer` collapses a
      // transparent border's width out of layout, so this reads as "no
      // border" rather than "border == fill"), unselected sits on the
      // surface behind a hairline. Branching on `selected` here is what
      // lets a disabled palette still show which chip was picked.
      bgBase = scheme.resolve(
        selected ? colorStyle.disabledSelectedBg : colorStyle.disabledBg,
      );
      fgBase = scheme.resolve(colorStyle.disabledFg);
      borderBase = scheme.resolve(
        selected
            ? merged.disabledSelectedBorderColor ??
                  CoreChipStyle.defaultDisabledSelectedBorderColor
            : colorStyle.disabledBorderColor,
      );
      prefixBase = fgBase;
    } else if (selected) {
      // Selected border mirrors the selected background (Web parity:
      // `border-${colorStyle.selectedBg}`), at either volume.
      final fill = emphasis == .low
          ? colorStyle.lowSelectedBg
          : colorStyle.selectedBg;
      bgBase = scheme.resolve(fill);
      fgBase = scheme.resolve(
        emphasis == .low ? colorStyle.lowSelectedFg : colorStyle.selectedFg,
      );
      borderBase = scheme.resolve(fill);
      prefixBase = fgBase;
    } else {
      // An unselected chip states no colour: the label is neutral at either
      // volume (darker at high) on a quiet hairline. `filled` swaps the
      // transparent fill and the hairline for the grey fill and its mirror.
      bgBase = filled ? filledFill : scheme.resolve(colorStyle.unselectedBg);
      fgBase = scheme.resolve(
        emphasis == .low
            ? merged.lowUnselectedForegroundColor ?? colorStyle.lowUnselectedFg
            : colorStyle.unselectedFg,
      );
      borderBase = filled
          ? filledFill
          : scheme.resolve(
              emphasis == .low
                  ? merged.lowUnselectedBorderColor ??
                        CoreChipStyle.defaultLowUnselectedBorderColor
                  : colorStyle.borderColor,
            );
      prefixBase = scheme.resolve(colorStyle.unselectedPrefixFg);
    }
  }

  // Per-instance colour overrides win across every state — resolved to
  // tagged [CoreColor]s.
  final backgroundCore = merged.backgroundColor != null
      ? scheme.resolve(merged.backgroundColor!)
      : bgBase;
  final foregroundCore = merged.foregroundColor != null
      ? scheme.resolve(merged.foregroundColor!)
      : fgBase;
  final borderCore = merged.borderColor != null
      ? scheme.resolve(merged.borderColor!)
      : borderBase;

  // ─── Nested slot colours (C8 — slot colour override else foreground) ─
  final labelSlotColor = merged.labelStyle?.color;
  final labelCore = labelSlotColor != null
      ? scheme.resolve(labelSlotColor)
      : foregroundCore;
  final leadingSlotColor = merged.leadingIconStyle?.color;
  final leadingIconCore = leadingSlotColor != null
      ? scheme.resolve(leadingSlotColor)
      : foregroundCore;
  final trailingSlotColor = merged.trailingIconStyle?.color;
  final trailingIconCore = trailingSlotColor != null
      ? scheme.resolve(trailingSlotColor)
      : foregroundCore;
  // The key follows the label's precedence: its own slot colour, else the
  // `foregroundColor` escape hatch (which wins across every state for the
  // label, so it does for the key too), else its state base.
  final prefixSlotColor = merged.prefixLabelStyle?.color;
  final prefixCore = prefixSlotColor != null
      ? scheme.resolve(prefixSlotColor)
      : merged.foregroundColor != null
      ? foregroundCore
      : prefixBase;

  // ─── Paint-ready Flutter colours (single `.toValue()` per surface) ──
  // `backgroundCore` / `borderCore` are forwarded raw to the composed
  // `OutlinedContainer` (via `containerStyle` below) instead of being
  // materialised here — that widget runs its own `scheme.resolve(...)
  // .toValue()` step.
  final foregroundColor = foregroundCore.toValue();
  final labelColor = labelCore.toValue();
  final leadingIconColor = leadingIconCore.toValue();
  final trailingIconColor = trailingIconCore.toValue();
  final prefixColor = prefixCore.toValue();

  // ─── Label typography (paint-ready TextStyle) ──────────────────────
  // Single-primitive conversion: the ladder's base role default merged
  // with the per-instance label slot (the size row's own role —
  // `labelSmall` / `labelMedium` / `labelLarge` — plus any caller overrides
  // for weight / spacing / height), then materialised in one step — the
  // conversion resolves the token role and binds the
  // state-resolved foreground colour. Font scaling is handled by Flutter's
  // MediaQuery textScaler, so the role font size flows through without
  // scaling (mirrors the Badge reference resolver).
  final labelTextStyle = CoreChipStyle.defaultLabelStyle
      .merge(merged.labelStyle)
      .toValue(color: labelColor, theme: theme);
  // The key's role is the size row's (`merged.prefixLabelStyle` carries it
  // through the chain head) over the ladder's base role — same single step
  // as the label.
  final prefixLabelTextStyle = CoreChipStyle.defaultPrefixLabelStyle
      .merge(merged.prefixLabelStyle)
      .toValue(color: prefixColor, theme: theme);

  // Close-button chrome — bind the chip foreground as the button's
  // idle foreground base so the X glyph tracks the chip colours, while
  // hover / per-instance overrides (`hoverForegroundColor` etc.) keep
  // flowing through Button's own per-state engine. The X `Icon` carries
  // no explicit colour — it inherits Button's per-state `IconTheme`, so
  // hover recolours it (Web parity: `hover:text-*` via `currentColor`).
  final closeButtonStyle = CoreChipStyle.defaultCloseButtonStyle
      .merge(CoreButtonStyle(foregroundColor: foregroundCore))
      .merge(sizeDefault.closeButtonStyle)
      .merge(merged.closeButtonStyle);

  // ─── Outer chrome — composed `OutlinedContainer` contract input.
  // Background / border / radius / padding are merged and expressed as
  // `coui_core` domain types so the receiving widget runs its own
  // colour / radius resolution once (mirrors `Card`'s `containerStyle`).
  // `boxShadow` is an explicit empty override — the chip's own
  // press/hover cast (`InjectedCast`, driven by [ResolvedChip.boxShadow]
  // / [ResolvedChip.castHideDuration] / [ResolvedChip.reverseCastMotion]
  // below) is a *separate* composition layer, so the primitive itself
  // must draw no shadow of its own or the two would double up.
  // `clipBehavior: .none` leaves the surface unclipped, as an
  // `AnimatedContainer` does by default.
  // See [ResolvedChip.transitionDuration] — resolved once here (through
  // reduced-motion) rather than left to `OutlinedContainer`'s own
  // internal `resolveMotionDuration` call so a caller of this resolver
  // can read the chip's chrome-transition clock directly, the same way
  // [castHideDuration] below is exposed rather than left buried in a
  // nested slot. Re-running `resolveMotionDuration` on an
  // already-honoured value inside `OutlinedContainer` is a no-op either
  // way (idempotent).
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreChipStyle.defaultTransitionDuration,
  );
  // ─── State layer ──────────────────────────────────────
  // The chip's own foreground over its own fill, at three weights. Every
  // state a chip can be in wears a different ground — selected, low
  // emphasis, unselected, custom — so the wash is composed from whatever
  // this chip actually resolved to rather than from one shared surface.
  //
  // Pre-baked as four container styles and SELECTED by the widget, the
  // shape `widget/render-only.md` names for mutually exclusive states.
  // The four are exclusive under strongest-wins, so this is O(4), not the
  // O(2ⁿ) that pushed `button`/`text_field` to lazy closures.
  final stateLayer = merged.stateLayer ?? CoreChipStyle.defaultStateLayer;
  CoreColor washedFill(double weight) {
    final over = foregroundCore.argb;
    final base = backgroundCore.argb;
    // Premultiplied over an already-resolved base, so a chip with no fill
    // of its own washes toward its own ink over whatever is behind it —
    // the alpha survives instead of being flattened to the page.
    final baseAlpha = ((base >> 24) & 0xFF) / 255.0;
    final outAlpha = weight + baseAlpha * (1 - weight);
    if (outAlpha <= 0) return backgroundCore;
    int channel(int shift) {
      final o = (over >> shift) & 0xFF;
      final b = (base >> shift) & 0xFF;
      return ((o * weight + b * baseAlpha * (1 - weight)) / outAlpha)
          .round()
          .clamp(0, 255);
    }

    return CoreColor(
      ((outAlpha * 255).round() << 24) |
          (channel(16) << 16) |
          (channel(8) << 8) |
          channel(0),
    );
  }

  // The face's corner — the caller's own, else the shape's: the size row's
  // (6 · 8 · 10) for `rounded`, the full corner for `pill`. The full corner
  // is not halved here: a rounded rect whose corners outgrow the box is
  // painted with them scaled down to half its short side, so the ends stay
  // half circles however tall the chip grows (the same clamp that makes
  // `Avatar` a disc). Resolved once so the face, the state washes, the cast
  // beneath it and the focus ring all follow the same corner.
  final borderRadius = merged.borderRadius ?? sizeDefault.borderRadius!;
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundCore,
    borderColor: borderCore,
    borderRadius: borderRadius,
    borderWidth: merged.borderWidth ?? CoreChipStyle.defaultBorderWidth,
    boxShadow: const [],
    padding: merged.padding ?? CoreEdgeInsets.zero,
    duration: transitionDuration,
    clipBehavior: .none,
  );
  CoreOutlinedContainerStyle washedContainer(double weight) =>
      CoreOutlinedContainerStyle(
        backgroundColor: washedFill(weight),
        borderColor: borderCore,
        borderRadius: borderRadius,
        borderWidth: merged.borderWidth ?? CoreChipStyle.defaultBorderWidth,
        boxShadow: const [],
        padding: merged.padding ?? CoreEdgeInsets.zero,
        duration: transitionDuration,
        clipBehavior: .none,
      );
  final hoverContainerStyle = washedContainer(stateLayer.hover);
  final focusContainerStyle = washedContainer(stateLayer.focus);
  final pressedContainerStyle = washedContainer(stateLayer.pressed);
  // Materialised radius mirroring the composed surface's own (unscaled
  // — matches `OutlinedContainer`'s own radius handling, which does not
  // multiply by `theme.scaling`) — consumed by `InjectedCast` /
  // `_PressableChip` so the cast's rounded shape tracks the chip's
  // corner exactly.
  final castBorderRadius = borderRadius.toValue(geometry: theme.geometry);
  // Every size row states the floor; `0` is the no-floor fallback for a
  // caller who passes a style with neither (same shape as `padding`).
  final minHeight = (merged.minHeight ?? 0) * scaling;
  final contentAlignment = coreMainAxisAlignmentToFlutter(
    merged.contentAlignment ?? CoreChipStyle.defaultContentAlignment,
  );
  // See [ResolvedChip.castHideDuration].
  final castHideDuration = resolveMotionDuration(
    context,
    merged.castHideDuration ?? CoreChipStyle.defaultCastHideDuration,
  );
  final leadingIconSize = (merged.leadingIconStyle?.size ?? 0) * scaling;
  final trailingIconSize = (merged.trailingIconStyle?.size ?? 0) * scaling;
  // Raw forward — `Icon`'s own resolver applies `theme.scaling`.
  final closeIconStyle = merged.closeIconStyle ?? const CoreIconStyle();
  // Nested CoreGapStyle slot — merge the per-size default with the
  // per-instance override and forward raw (pre-scaling) to Gap,
  // which runs its own scaling step. sizeDefault is already folded
  // into merged via the chain head; the explicit merge here matches
  // the Badge pattern and keeps the slot null-safe.
  final iconLabelGapStyle = sizeDefault.iconLabelGapStyle!.merge(
    merged.iconLabelGapStyle,
  );
  // The style injects its cast into surfaces that state no shadow of
  // their own — empty under every style that injects none.
  // What this chip wants its cast to *do*. `noShadow` withholds the
  // cast and its paired travel outright; `reverse` keeps the same
  // injected cast but hides it at rest instead of at engage (Chip has
  // no authored-shadow slot to check, unlike Button, so this reads
  // `castMotion` directly).
  final castMotion = merged.castMotion ?? CoreChipStyle.defaultCastMotion;
  final reverseCastMotion = castMotion == .reverse;
  final boxShadow = castMotion == .noShadow
      ? const <BoxShadow>[]
      : resolveInjectedCast(theme);

  // How far a press travels: exactly the distance the style throws its
  // cast, so the chip lands in the space its own shadow was occupying.
  // [reverseCastMotion] negates the diagonal rather than adding a second
  // style vocabulary — mirrors the button resolver's `isReverseInjected`
  // branch.
  //
  // Gated on the chip actually carrying a cast. A style that throws
  // nothing has no space to sink into, and a control that slid anyway
  // would be moving for no reason the screen can explain.
  //
  // Derived here rather than stated in `CoreChipStyle.defaultClickableStyle`
  // because that is a compile-time const while this distance belongs to
  // whichever style is active — known only at resolve time. Same
  // derivation as the button resolver, and Web scopes it the same way
  // (`kControlShadowPressMarker` over the offset custom property), so
  // the two platforms decide it on the same input.
  final shadowOffsetAdd = theme.geometry.shadowOffsetAdd;
  final pressedTranslate = boxShadow.isEmpty || shadowOffsetAdd == null
      ? CoreOffset.zero
      : reverseCastMotion
      ? CoreOffset(-shadowOffsetAdd.dx, -shadowOffsetAdd.dy)
      : CoreOffset(shadowOffsetAdd.dx, shadowOffsetAdd.dy);

  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest). The
  // travel goes on last so a caller that states its own keeps it.
  //
  // `pressedScale` follows the same DDR-1 the button resolver applies:
  // pinned to `1.0` when this chip has a signature shadow to shift into
  // (a simultaneous shrink would compound with that shift and read as a
  // different gesture than the Web `:hover, :active` twin, which has no
  // scale step at all). A caller's own `pressedScale` override still
  // wins — this only supplies the pin when nothing was said, the same
  // fallback shape `pressedTranslate` already uses on the line below.
  final clickableStyle = CoreChipStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle)
      .copyWith(
        pressedScale:
            merged.clickableStyle?.pressedScale ??
            (pressedTranslate != .zero ? 1.0 : null),
        pressedTranslate:
            merged.clickableStyle?.pressedTranslate ?? pressedTranslate,
      );

  return ResolvedChip(
    containerStyle: containerStyle,
    hoverContainerStyle: hoverContainerStyle,
    focusContainerStyle: focusContainerStyle,
    pressedContainerStyle: pressedContainerStyle,
    castBorderRadius: castBorderRadius,
    minHeight: minHeight,
    contentAlignment: contentAlignment,
    iconLabelGapStyle: iconLabelGapStyle,
    labelTextStyle: labelTextStyle,
    prefixLabelTextStyle: prefixLabelTextStyle,
    leadingIconSize: leadingIconSize,
    trailingIconSize: trailingIconSize,
    closeIconStyle: closeIconStyle,
    foregroundColor: foregroundColor,
    leadingIconColor: leadingIconColor,
    trailingIconColor: trailingIconColor,
    closeButtonStyle: closeButtonStyle,
    clickableStyle: clickableStyle,
    boxShadow: boxShadow,
    castHideDuration: castHideDuration,
    reverseCastMotion: reverseCastMotion,
    transitionDuration: transitionDuration,
  );
}
