import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedMenuItem
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `MenuItem`.
///
/// Widget tree (`menu_item.dart` decides which optional seats render):
///
/// ```text
/// CoUISemantics (role menuItem · selected · enabled)
///   └─ Clickable (clickableStyle — focus ring, press feedback)
///        └─ AnimatedContainer (minHeight · fill: backgroundColor |
///           selectedBackgroundColor | hoverFillColor / pressedFillColor ·
///           borderRadius)
///             └─ Stacks
///                  ├─ Position.fill — wash (hover / focus / pressed,
///                  │    rest or selected ramp)          // only while washed
///                  └─ Padding (padding)
///                       └─ Row
///                            ├─ mark (IconTheme ← markIconTheme*)
///                            │    or the reserved column (markSlotWidth)
///                            ├─ Gap (contentGapStyle)
///                            ├─ leading (IconTheme ← leadingIconTheme*)
///                            ├─ Gap (contentGapStyle)
///                            ├─ Expanded
///                            │    └─ Column
///                            │         ├─ label (DefaultTextStyle ← labelTextStyle*)
///                            │         ├─ Gap (labelDescriptionGapStyle)
///                            │         └─ description (← descriptionTextStyle*)
///                            ├─ Gap (contentGapStyle)
///                            ├─ shortcut (← shortcutTextStyle*)
///                            │    or Icon chevron (chevronIconStyle*)
///                            ├─ Gap (contentGapStyle)
///                            └─ trailing
/// ```
///
/// Every `*`-marked slot comes in four: rest, `selected…`, `disabled…`,
/// `active…`. The widget only *selects* between them from the row's
/// `selected` / `enabled` flags and from whether the pointer or the keyboard
/// is on it — it never derives a colour of its own. The wash is a select
/// too: the six wash colours are the foreground (rest ramp) or the selected
/// foreground (selected ramp) at the state layer's weight, and the widget
/// picks one by hover / focus / press. A tone that states an active fill
/// (`critical`) takes no wash: its `hoverFillColor` / `pressedFillColor` are
/// non-null and replace the resting fill, and its `active…` bundles carry the
/// ink chosen for that fill. For a tone without one, the `active…` bundles
/// are the rest bundles.
class ResolvedMenuItem {
  /// Paint-ready bundle; every dimension is pre-scaled.
  const ResolvedMenuItem({
    required this.minHeight,
    required this.padding,
    required this.borderRadius,
    required this.markSlotWidth,
    required this.contentGapStyle,
    required this.labelDescriptionGapStyle,
    required this.clickableStyle,
    required this.leadingIconTheme,
    required this.selectedLeadingIconTheme,
    required this.disabledLeadingIconTheme,
    required this.markIconTheme,
    required this.selectedMarkIconTheme,
    required this.disabledMarkIconTheme,
    required this.chevronIconStyle,
    required this.selectedChevronIconStyle,
    required this.disabledChevronIconStyle,
    required this.activeLeadingIconTheme,
    required this.activeMarkIconTheme,
    required this.activeChevronIconStyle,
    required this.labelTextStyle,
    required this.selectedLabelTextStyle,
    required this.disabledLabelTextStyle,
    required this.descriptionTextStyle,
    required this.selectedDescriptionTextStyle,
    required this.disabledDescriptionTextStyle,
    required this.shortcutTextStyle,
    required this.selectedShortcutTextStyle,
    required this.disabledShortcutTextStyle,
    required this.activeLabelTextStyle,
    required this.activeDescriptionTextStyle,
    required this.activeShortcutTextStyle,
    required this.backgroundColor,
    required this.selectedBackgroundColor,
    required this.hoverFillColor,
    required this.pressedFillColor,
    required this.hoverColor,
    required this.focusColor,
    required this.pressedColor,
    required this.selectedHoverColor,
    required this.selectedFocusColor,
    required this.selectedPressedColor,
    required this.duration,
    required this.curve,
  });

  /// Row height floor. A description line grows past it.
  final double minHeight;

  /// Content insets.
  final EdgeInsets padding;

  /// Highlight and focus-ring corner.
  final BorderRadius borderRadius;

  /// Width the mark column keeps while `reserveMark` holds and no mark is
  /// drawn — the mark glyph's own footprint, so the labels of a toggle
  /// group stay aligned whether or not each row is on.
  final double markSlotWidth;

  /// Nested gap between the seats — raw-forwarded to `Gap`.
  final CoreGapStyle contentGapStyle;

  /// Nested gap between the label and its description — raw-forwarded.
  final CoreGapStyle labelDescriptionGapStyle;

  /// Nested `Clickable` chrome — raw-forwarded. Its corner is the row's.
  final CoreClickableStyle clickableStyle;

  /// Ambient theme for the caller-supplied leading glyph — size from the
  /// ladder, colour the resting foreground. `IconThemeData` rather than a
  /// `CoreIconStyle` because the glyph is the caller's widget: the only
  /// way to tint a widget one does not construct is the ambient theme
  /// (`Button` forwards its leading / trailing the same way).
  final IconThemeData leadingIconTheme;

  /// [leadingIconTheme] while selected — the selected foreground.
  final IconThemeData selectedLeadingIconTheme;

  /// [leadingIconTheme] while disabled — the disabled foreground.
  final IconThemeData disabledLeadingIconTheme;

  /// Ambient theme for the caller-supplied mark glyph (the toggle check /
  /// dot) — 16 on every size, resting foreground.
  final IconThemeData markIconTheme;

  /// [markIconTheme] while selected.
  final IconThemeData selectedMarkIconTheme;

  /// [markIconTheme] while disabled.
  final IconThemeData disabledMarkIconTheme;

  /// [leadingIconTheme] while hovered, focused or pressed — the tone's
  /// active foreground, or the resting one when the tone states none.
  final IconThemeData activeLeadingIconTheme;

  /// [markIconTheme] while hovered, focused or pressed.
  final IconThemeData activeMarkIconTheme;

  /// [chevronIconStyle] while hovered, focused or pressed.
  final CoreIconStyle activeChevronIconStyle;

  /// Submenu chevron — the row draws this `Icon` itself, so the slot
  /// raw-forwards a `CoreIconStyle` (the icon self-resolves and scales).
  final CoreIconStyle chevronIconStyle;

  /// [chevronIconStyle] while selected.
  final CoreIconStyle selectedChevronIconStyle;

  /// [chevronIconStyle] while disabled.
  final CoreIconStyle disabledChevronIconStyle;

  /// Label — the ladder's role in the tone's foreground.
  final TextStyle labelTextStyle;

  /// Label while selected.
  final TextStyle selectedLabelTextStyle;

  /// Label while disabled.
  final TextStyle disabledLabelTextStyle;

  /// Label while hovered, focused or pressed.
  final TextStyle activeLabelTextStyle;

  /// Description while hovered, focused or pressed.
  final TextStyle activeDescriptionTextStyle;

  /// Shortcut hint while hovered, focused or pressed.
  final TextStyle activeShortcutTextStyle;

  /// Description line — the ladder's quieter role and colour.
  final TextStyle descriptionTextStyle;

  /// Description while selected — reads in the selected foreground so it
  /// stays legible over the selected fill.
  final TextStyle selectedDescriptionTextStyle;

  /// Description while disabled.
  final TextStyle disabledDescriptionTextStyle;

  /// Shortcut hint.
  final TextStyle shortcutTextStyle;

  /// Shortcut hint while selected.
  final TextStyle selectedShortcutTextStyle;

  /// Shortcut hint while disabled.
  final TextStyle disabledShortcutTextStyle;

  /// Resting fill — transparent by default; the panel is the surface.
  final Color backgroundColor;

  /// Fill while selected.
  final Color selectedBackgroundColor;

  /// Fill while hovered or keyboard-focused, for a tone whose active state is
  /// a fill. `null` → the row is washed instead ([hoverColor] /
  /// [focusColor]) and keeps [backgroundColor].
  final Color? hoverFillColor;

  /// Fill while pressed, for a tone whose active state is a fill. `null`
  /// exactly when [hoverFillColor] is.
  final Color? pressedFillColor;

  /// Hover wash over the resting fill — the foreground at the state
  /// layer's hover weight.
  final Color hoverColor;

  /// Focus wash over the resting fill.
  final Color focusColor;

  /// Pressed wash over the resting fill.
  final Color pressedColor;

  /// Hover wash over the selected fill — the selected foreground at the
  /// same weight, so the ramp reads identically on both fills.
  final Color selectedHoverColor;

  /// Focus wash over the selected fill.
  final Color selectedFocusColor;

  /// Pressed wash over the selected fill.
  final Color selectedPressedColor;

  /// Fill / wash transition — the composed `Clickable`'s chrome clock, so
  /// the row and its focus ring move on one duration. Already routed
  /// through [resolveMotionDuration].
  final Duration duration;

  /// Shape of that transition.
  final Curve curve;
}

// ═══════════════════════════════════════════════════
// resolveMenuItem — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMenuItem] for `MenuItem`.
///
/// Priority (per field): `menuItemStyle` > `CoreMenuItemTheme.style` >
/// the axis table the field belongs to
/// (`CoreMenuItemStyle.defaultsBySize[size]` / `defaultsByTone[tone]`) >
/// `CoreMenuItemStyle.defaultX`.
ResolvedMenuItem resolveMenuItem(
  BuildContext context, {
  required CoreMenuItemSize size,
  required CoreMenuItemTone tone,
  CoreMenuItemStyle? menuItemStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final menuItemTheme = theme.coreComponentTheme?.menuItem;

  final merged = resolveStyleChain(const CoreMenuItemStyle(), [
    menuItemTheme?.style,
    menuItemStyle,
  ]);
  final sizeStyle = CoreMenuItemStyle.defaultsBySize[size]!;
  final toneStyle = CoreMenuItemStyle.defaultsByTone[tone]!;

  // ── Stage1 RESOLVE — Core values ──
  // Row corner — the per-instance override wins (a hosting panel states its
  // row corner through its nested row slot), else the size row's corner.
  final borderRadius = merged.borderRadius ?? sizeStyle.borderRadius!;
  final leadingIconSlot = sizeStyle.leadingIconStyle!.merge(
    merged.leadingIconStyle,
  );
  final markIconSlot = CoreMenuItemStyle.defaultMarkIconStyle.merge(
    merged.markIconStyle,
  );
  final chevronIconSlot = CoreMenuItemStyle.defaultChevronIconStyle.merge(
    merged.chevronIconStyle,
  );
  final labelSlot = sizeStyle.labelStyle!.merge(merged.labelStyle);
  final descriptionSlot = sizeStyle.descriptionStyle!.merge(
    merged.descriptionStyle,
  );
  final shortcutSlot = sizeStyle.shortcutTextStyle!.merge(
    merged.shortcutTextStyle,
  );
  final background =
      merged.backgroundColor ?? CoreMenuItemStyle.defaultBackgroundColor;
  final foreground = merged.foregroundColor ?? toneStyle.foregroundColor!;
  final selectedBackground =
      merged.selectedBackgroundColor ??
      CoreMenuItemStyle.defaultSelectedBackgroundColor;
  final selectedForeground =
      merged.selectedForegroundColor ??
      CoreMenuItemStyle.defaultSelectedForegroundColor;
  final disabledForeground =
      merged.disabledForegroundColor ??
      CoreMenuItemStyle.defaultDisabledForegroundColor;
  final stateLayer = merged.stateLayer ?? CoreMenuItemStyle.defaultStateLayer;
  // A tone whose active state is a fill (`critical`) replaces the wash: the
  // fill and the ink chosen for it come from the same row. Pressed falls back
  // to the hover fill; the ink falls back to the resting foreground.
  final hoverFill =
      merged.hoverBackgroundColor ?? toneStyle.hoverBackgroundColor;
  final pressedFill = hoverFill == null
      ? null
      : (merged.pressedBackgroundColor ??
            toneStyle.pressedBackgroundColor ??
            hoverFill);
  // The ink a tone states for its fill. `null` keeps every ink at rest: the
  // label and the glyphs on the resting foreground, the description and the
  // shortcut on their muted colour.
  final activeForeground = hoverFill == null
      ? null
      : (merged.activeForegroundColor ?? toneStyle.activeForegroundColor);

  // ── Stage2 EMIT — colours ──
  final backgroundColor = scheme.resolve(background).toValue();
  final foregroundColor = scheme.resolve(foreground).toValue();
  final selectedBackgroundColor = scheme.resolve(selectedBackground).toValue();
  final selectedForegroundColor = scheme.resolve(selectedForeground).toValue();
  final disabledForegroundColor = scheme.resolve(disabledForeground).toValue();
  final hoverFillColor = hoverFill == null
      ? null
      : scheme.resolve(hoverFill).toValue();
  final pressedFillColor = pressedFill == null
      ? null
      : scheme.resolve(pressedFill).toValue();
  final activeForegroundColor = activeForeground == null
      ? foregroundColor
      : scheme.resolve(activeForeground).toValue();
  // The wash is the foreground laid over the fill at the ramp's weight —
  // one mechanism said three ways (`CoreStateLayer`), never a fill fade.
  final hoverColor = foregroundColor.withValues(alpha: stateLayer.hover);
  final focusColor = foregroundColor.withValues(alpha: stateLayer.focus);
  final pressedColor = foregroundColor.withValues(alpha: stateLayer.pressed);
  final selectedHoverColor = selectedForegroundColor.withValues(
    alpha: stateLayer.hover,
  );
  final selectedFocusColor = selectedForegroundColor.withValues(
    alpha: stateLayer.focus,
  );
  final selectedPressedColor = selectedForegroundColor.withValues(
    alpha: stateLayer.pressed,
  );

  // ── Stage2 EMIT — text (role + per-state colour) ──
  // The label's colour is the foreground in every state; the description
  // and shortcut keep their own muted colour at rest and take the
  // selected / disabled foreground otherwise, so they stay legible over
  // the selected fill and read as disabled with the label.
  final labelTextStyle = labelSlot.toValue(
    color: foregroundColor,
    theme: theme,
  );
  final selectedLabelTextStyle = labelSlot.toValue(
    color: selectedForegroundColor,
    theme: theme,
  );
  final disabledLabelTextStyle = labelSlot.toValue(
    color: disabledForegroundColor,
    theme: theme,
  );
  final activeLabelTextStyle = labelSlot.toValue(
    color: activeForegroundColor,
    theme: theme,
  );
  final descriptionTextStyle = descriptionSlot.toValue(theme: theme);
  final selectedDescriptionTextStyle = descriptionSlot.toValue(
    color: selectedForegroundColor,
    theme: theme,
  );
  final disabledDescriptionTextStyle = descriptionSlot.toValue(
    color: disabledForegroundColor,
    theme: theme,
  );
  // The description and the shortcut keep their muted resting colour unless
  // the tone states an active ink, which they take with the label.
  final activeDescriptionTextStyle = activeForeground == null
      ? descriptionTextStyle
      : descriptionSlot.toValue(color: activeForegroundColor, theme: theme);
  final shortcutTextStyle = shortcutSlot.toValue(theme: theme);
  final activeShortcutTextStyle = activeForeground == null
      ? shortcutTextStyle
      : shortcutSlot.toValue(color: activeForegroundColor, theme: theme);
  final selectedShortcutTextStyle = shortcutSlot.toValue(
    color: selectedForegroundColor,
    theme: theme,
  );
  final disabledShortcutTextStyle = shortcutSlot.toValue(
    color: disabledForegroundColor,
    theme: theme,
  );

  // ── Stage2 EMIT — glyphs ──
  // Caller-supplied glyphs (leading, mark) are tinted through the ambient
  // `IconTheme`; its size is the raw ladder value because `Icon` scales
  // the ambient size itself. The chevron is the row's own `Icon`, so it
  // takes a `CoreIconStyle` and self-resolves.
  final leadingIconTheme = IconThemeData(
    size: leadingIconSlot.size,
    color: foregroundColor,
  );
  final selectedLeadingIconTheme = IconThemeData(
    size: leadingIconSlot.size,
    color: selectedForegroundColor,
  );
  final disabledLeadingIconTheme = IconThemeData(
    size: leadingIconSlot.size,
    color: disabledForegroundColor,
  );
  final markIconTheme = IconThemeData(
    size: markIconSlot.size,
    color: foregroundColor,
  );
  final selectedMarkIconTheme = IconThemeData(
    size: markIconSlot.size,
    color: selectedForegroundColor,
  );
  final disabledMarkIconTheme = IconThemeData(
    size: markIconSlot.size,
    color: disabledForegroundColor,
  );
  final activeLeadingIconTheme = IconThemeData(
    size: leadingIconSlot.size,
    color: activeForegroundColor,
  );
  final activeMarkIconTheme = IconThemeData(
    size: markIconSlot.size,
    color: activeForegroundColor,
  );
  final chevronIconStyle = chevronIconSlot.merge(
    CoreIconStyle(color: foreground),
  );
  final selectedChevronIconStyle = chevronIconSlot.merge(
    CoreIconStyle(color: selectedForeground),
  );
  final disabledChevronIconStyle = chevronIconSlot.merge(
    CoreIconStyle(color: disabledForeground),
  );
  final activeChevronIconStyle = activeForeground == null
      ? chevronIconStyle
      : chevronIconSlot.merge(CoreIconStyle(color: activeForeground));

  // ── Stage2 EMIT — dimensions (`* scaling` in the local, return bare) ──
  // The size row's height is drawn by the theme density, which leaves a
  // height off the control ladder (the 36 `md` row) as authored; a caller's
  // own minimum stays as stated.
  final minHeight =
      (merged.minHeight ?? theme.geometry.controlHeight(sizeStyle.minHeight!)) *
      scaling;
  final padding =
      (merged.padding ?? sizeStyle.padding!).toValue(geometry: theme.geometry) *
      scaling;
  // Scaled with the height so the corner stays the same fraction of the
  // row at any size factor.
  final borderRadiusValue =
      borderRadius.toValue(geometry: theme.geometry) * scaling;
  // The reserved mark column is exactly the glyph's footprint, scaled the
  // way `Icon` scales it, so a row that draws its mark and a row that
  // reserves the seat put their labels on the same x.
  final markSlotWidth = markIconSlot.size! * scaling;

  // ── Nested slots — raw-forwarded, the child resolves them ──
  final contentGapStyle = sizeStyle.contentGapStyle!.merge(
    merged.contentGapStyle,
  );
  final labelDescriptionGapStyle = CoreMenuItemStyle
      .defaultLabelDescriptionGapStyle
      .merge(merged.labelDescriptionGapStyle);
  // The focus ring follows the row's corner: the row radius seeds the
  // composed `Clickable`'s default, and an explicit `clickableStyle`
  // override still wins over it.
  final clickableStyle = CoreMenuItemStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // The row's own fill / wash transition rides the composed `Clickable`'s
  // chrome clock — one duration for the ring and the row, read through
  // the child's resolver so its defaults are settled in one place
  // (`DropdownMenu` reads its panel through `resolvePopup` the same way).
  final clickable = resolveClickable(context, clickableStyle: clickableStyle);
  final duration = resolveMotionDuration(context, clickable.duration);
  final curve = clickable.curve;

  return ResolvedMenuItem(
    minHeight: minHeight,
    padding: padding,
    borderRadius: borderRadiusValue,
    markSlotWidth: markSlotWidth,
    contentGapStyle: contentGapStyle,
    labelDescriptionGapStyle: labelDescriptionGapStyle,
    clickableStyle: clickableStyle,
    leadingIconTheme: leadingIconTheme,
    selectedLeadingIconTheme: selectedLeadingIconTheme,
    disabledLeadingIconTheme: disabledLeadingIconTheme,
    markIconTheme: markIconTheme,
    selectedMarkIconTheme: selectedMarkIconTheme,
    disabledMarkIconTheme: disabledMarkIconTheme,
    chevronIconStyle: chevronIconStyle,
    selectedChevronIconStyle: selectedChevronIconStyle,
    disabledChevronIconStyle: disabledChevronIconStyle,
    activeLeadingIconTheme: activeLeadingIconTheme,
    activeMarkIconTheme: activeMarkIconTheme,
    activeChevronIconStyle: activeChevronIconStyle,
    labelTextStyle: labelTextStyle,
    selectedLabelTextStyle: selectedLabelTextStyle,
    disabledLabelTextStyle: disabledLabelTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    selectedDescriptionTextStyle: selectedDescriptionTextStyle,
    disabledDescriptionTextStyle: disabledDescriptionTextStyle,
    shortcutTextStyle: shortcutTextStyle,
    selectedShortcutTextStyle: selectedShortcutTextStyle,
    disabledShortcutTextStyle: disabledShortcutTextStyle,
    activeLabelTextStyle: activeLabelTextStyle,
    activeDescriptionTextStyle: activeDescriptionTextStyle,
    activeShortcutTextStyle: activeShortcutTextStyle,
    backgroundColor: backgroundColor,
    selectedBackgroundColor: selectedBackgroundColor,
    hoverFillColor: hoverFillColor,
    pressedFillColor: pressedFillColor,
    hoverColor: hoverColor,
    focusColor: focusColor,
    pressedColor: pressedColor,
    selectedHoverColor: selectedHoverColor,
    selectedFocusColor: selectedFocusColor,
    selectedPressedColor: selectedPressedColor,
    duration: duration,
    curve: curve,
  );
}
