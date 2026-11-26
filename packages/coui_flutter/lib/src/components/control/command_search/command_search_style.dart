import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedCommandSearch
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `CommandSearch`.
///
/// Widget tree (`command_search.dart` decides which optional seats render):
///
/// ```text
/// Clickable (button semantics · clickableStyle — focus ring, press)
///   └─ AnimatedContainer (height · fill: backgroundColor |
///      disabledBackgroundColor · borderRadius)
///        └─ Stacks
///             ├─ Position.fill — wash (hover / focus / pressed)   // only while washed
///             └─ Padding (padding — directional)
///                  └─ Row
///                       ├─ leading (IconTheme ← leadingIconTheme*)
///                       │    the caller's glyph, or the search glyph
///                       ├─ Gap (contentGapStyle)
///                       ├─ Expanded — hint (Text ← hintTextStyle*)
///                       ├─ Gap (contentGapStyle)
///                       └─ shortcut                       // caller-supplied, optional
/// ```
///
/// Every `*`-marked slot comes in two: rest and `disabled…`. The widget only
/// *selects* between them from its enabled flag, and picks the wash from
/// whether the pointer or the keyboard is on it — it never derives a colour
/// of its own.
class ResolvedCommandSearch {
  /// Paint-ready bundle; every dimension is pre-scaled.
  const ResolvedCommandSearch({
    required this.height,
    required this.padding,
    required this.borderRadius,
    required this.contentGapStyle,
    required this.clickableStyle,
    required this.leadingIconTheme,
    required this.disabledLeadingIconTheme,
    required this.hintTextStyle,
    required this.disabledHintTextStyle,
    required this.backgroundColor,
    required this.disabledBackgroundColor,
    required this.hoverColor,
    required this.focusColor,
    required this.pressedColor,
    required this.duration,
    required this.curve,
  });

  /// Trigger height.
  final double height;

  /// Content insets — directional, so the start inset stays on the side the
  /// text starts from in a right-to-left locale.
  final EdgeInsetsGeometry padding;

  /// Face and focus-ring corner.
  final BorderRadius borderRadius;

  /// Nested gap between the seats — raw-forwarded to `Gap`.
  final CoreGapStyle contentGapStyle;

  /// Nested `Clickable` chrome — raw-forwarded. Its corner is the trigger's.
  final CoreClickableStyle clickableStyle;

  /// Ambient theme for the leading glyph — size from the ladder, colour the
  /// resting ink. `IconThemeData` rather than a `CoreIconStyle` because the
  /// glyph may be the caller's widget, and the only way to size and tint a
  /// widget one does not construct is the ambient theme.
  final IconThemeData leadingIconTheme;

  /// [leadingIconTheme] while disabled — the disabled ink.
  final IconThemeData disabledLeadingIconTheme;

  /// Hint — the ladder's role in the resting ink.
  final TextStyle hintTextStyle;

  /// Hint while disabled.
  final TextStyle disabledHintTextStyle;

  /// Resting face.
  final Color backgroundColor;

  /// Face while disabled.
  final Color disabledBackgroundColor;

  /// Hover wash over the face — the state-layer colour at the hover weight.
  final Color hoverColor;

  /// Focus wash over the face.
  final Color focusColor;

  /// Pressed wash over the face.
  final Color pressedColor;

  /// Fill / wash transition — the composed `Clickable`'s chrome clock, so
  /// the face and its focus ring move on one duration. Already routed
  /// through [resolveMotionDuration].
  final Duration duration;

  /// Shape of that transition.
  final Curve curve;
}

// ═══════════════════════════════════════════════════
// resolveCommandSearch — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCommandSearch] for `CommandSearch`.
///
/// Priority (per field): `commandSearchStyle` >
/// `CoreCommandSearchTheme.style` > `CoreCommandSearchStyle.defaultsBySize`
/// for the size-keyed fields > `CoreCommandSearchStyle.defaultX`.
ResolvedCommandSearch resolveCommandSearch(
  BuildContext context, {
  required CoreCommandSize size,
  CoreCommandSearchStyle? commandSearchStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final searchTheme = theme.coreComponentTheme?.commandSearch;

  final merged = resolveStyleChain(const CoreCommandSearchStyle(), [
    searchTheme?.style,
    commandSearchStyle,
  ]);
  final sizeStyle = CoreCommandSearchStyle.defaultsBySize[size]!;

  // ── Stage1 RESOLVE — Core values ──
  final borderRadius = merged.borderRadius ?? sizeStyle.borderRadius!;
  final leadingIconSlot = sizeStyle.leadingIconStyle!.merge(
    merged.leadingIconStyle,
  );
  final hintSlot = sizeStyle.hintTextStyle!.merge(merged.hintTextStyle);
  final background =
      merged.backgroundColor ?? CoreCommandSearchStyle.defaultBackgroundColor;
  final foreground =
      merged.foregroundColor ?? CoreCommandSearchStyle.defaultForegroundColor;
  final disabledBackground =
      merged.disabledBackgroundColor ??
      CoreCommandSearchStyle.defaultDisabledBackgroundColor;
  final disabledForeground =
      merged.disabledForegroundColor ??
      CoreCommandSearchStyle.defaultDisabledForegroundColor;
  final stateLayerTint =
      merged.stateLayerColor ?? CoreCommandSearchStyle.defaultStateLayerColor;
  final stateLayer =
      merged.stateLayer ?? CoreCommandSearchStyle.defaultStateLayer;
  // A slot colour wins over the shared ink at rest; disabled takes the
  // disabled ink regardless, so a tinted glyph still reads as disabled.
  final leadingTint = leadingIconSlot.color ?? foreground;
  final hintTint = hintSlot.color ?? foreground;

  // ── Stage2 EMIT — colours ──
  final backgroundColor = scheme.resolve(background).toValue();
  final disabledBackgroundColor = scheme.resolve(disabledBackground).toValue();
  final disabledForegroundColor = scheme.resolve(disabledForeground).toValue();
  final leadingColor = scheme.resolve(leadingTint).toValue();
  final hintColor = scheme.resolve(hintTint).toValue();
  final stateLayerColor = scheme.resolve(stateLayerTint).toValue();
  // The wash is the state-layer colour laid over the face at the ramp's
  // weight — one mechanism said three ways (`CoreStateLayer`).
  final hoverColor = stateLayerColor.withValues(alpha: stateLayer.hover);
  final focusColor = stateLayerColor.withValues(alpha: stateLayer.focus);
  final pressedColor = stateLayerColor.withValues(alpha: stateLayer.pressed);

  // ── Stage2 EMIT — text ──
  final hintTextStyle = hintSlot.toValue(color: hintColor, theme: theme);
  final disabledHintTextStyle = hintSlot.toValue(
    color: disabledForegroundColor,
    theme: theme,
  );

  // ── Stage2 EMIT — glyph ──
  // The size is the raw ladder value: `Icon` scales the ambient size itself.
  final leadingIconTheme = IconThemeData(
    size: leadingIconSlot.size,
    color: leadingColor,
  );
  final disabledLeadingIconTheme = IconThemeData(
    size: leadingIconSlot.size,
    color: disabledForegroundColor,
  );

  // ── Stage2 EMIT — dimensions (`* scaling` in the local, return bare) ──
  // The size row's height is drawn by the theme density (it sits on the
  // control ladder); a caller's own height stays as stated.
  final height =
      (merged.height ?? theme.geometry.controlHeight(sizeStyle.height!)) *
      scaling;
  final padding =
      (merged.padding ?? sizeStyle.padding!).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;
  // Scaled with the height so the corner stays the same fraction of the
  // trigger at any size factor.
  final borderRadiusValue =
      borderRadius.toValue(geometry: theme.geometry) * scaling;

  // ── Nested slots — raw-forwarded, the child resolves them ──
  final contentGapStyle = sizeStyle.contentGapStyle!.merge(
    merged.contentGapStyle,
  );
  // The focus ring follows the trigger's corner: the corner seeds the
  // composed `Clickable`'s default, and an explicit `clickableStyle`
  // override still wins over it.
  final clickableStyle = CoreCommandSearchStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // The face's own fill / wash transition rides the composed `Clickable`'s
  // chrome clock — one duration for the ring and the face, read through the
  // child's resolver so its defaults are settled in one place.
  final clickable = resolveClickable(context, clickableStyle: clickableStyle);
  final duration = resolveMotionDuration(context, clickable.duration);
  final curve = clickable.curve;

  return ResolvedCommandSearch(
    height: height,
    padding: padding,
    borderRadius: borderRadiusValue,
    contentGapStyle: contentGapStyle,
    clickableStyle: clickableStyle,
    leadingIconTheme: leadingIconTheme,
    disabledLeadingIconTheme: disabledLeadingIconTheme,
    hintTextStyle: hintTextStyle,
    disabledHintTextStyle: disabledHintTextStyle,
    backgroundColor: backgroundColor,
    disabledBackgroundColor: disabledBackgroundColor,
    hoverColor: hoverColor,
    focusColor: focusColor,
    pressedColor: pressedColor,
    duration: duration,
    curve: curve,
  );
}
