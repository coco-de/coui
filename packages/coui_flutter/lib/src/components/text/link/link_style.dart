import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedLink
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Link`.
///
/// Widget tree (`link.dart` is render-only — it reads these fields
/// without re-running any typography / fontWeight / `?? chrome`
/// decision):
///
/// ```text
/// Clickable (onPressed / cursor / keyboard / focus ring,
///            reports hover · focus · press)
///   └─ AnimatedDefaultTextStyle (labelStyle | interactionLabelStyle,
///        │                       transitionDuration)
///        └─ Semantics (button + link)
///             └─ child | Text(href)
/// ```
///
/// Which of the two label styles the widget passes is the one decision it
/// keeps: whether the link is hovered, focused or pressed right now is
/// detected by the widget (state DETECTION is native to each platform),
/// while what each state looks like is resolved here.
///
/// The inline form (`Link.inlineSpan`) is not a widget tree — it is a
/// single `TextSpan` that reads [spanTextStyle] and inherits everything
/// else from the paragraph it sits in:
///
/// ```text
/// TextSpan (spanTextStyle, TapGestureRecognizer → onPressed)
///   └─ text | children                        // leaf spans get the
///                                              //   same recognizer
/// ```
///
/// Every link chrome / animation override has had the nested merge chain
/// applied plus the `CoreLinkStyle.defaultX` static const fallback and
/// Flutter type conversion. The label typography token is materialised
/// against the active theme, the per-instance label override merged on
/// top, the resolved foreground colour applied, and the underline
/// decoration (colour + style) baked in — so each label style is a fully
/// paint-ready Flutter [TextStyle].
class ResolvedLink {
  /// Creates a [ResolvedLink].
  const ResolvedLink({
    required this.labelStyle,
    required this.interactionLabelStyle,
    required this.spanTextStyle,
    required this.transitionDuration,
    required this.clickableStyle,
    required this.iconTheme,
    required this.iconLabelGapStyle,
  });

  /// Paint-ready label [TextStyle] at rest — typography token
  /// materialised, per-instance label override merged, foreground colour
  /// applied, and the underline decoration (colour + solid style) baked in
  /// when the widget's `underline` flag is set. The widget passes this
  /// straight to `AnimatedDefaultTextStyle.style` while the link is idle.
  final TextStyle labelStyle;

  /// Paint-ready label [TextStyle] while the link is hovered, pressed or
  /// focused — [labelStyle] with the interaction decoration
  /// (`CoreLinkStyle.interactionTextDecoration`) applied. Equal to
  /// [labelStyle] for a link that is always underlined, which has nothing
  /// to reveal.
  final TextStyle interactionLabelStyle;

  /// Paint-ready partial [TextStyle] for the inline form — the resolved
  /// foreground colour and an always-on underline, plus only the fields
  /// the caller set explicitly on `CoreLinkStyle.labelStyle`. The
  /// typography role is deliberately absent: an inline link takes size /
  /// weight / leading from the paragraph around it, so it reads as part of
  /// that text rather than a label island.
  final TextStyle spanTextStyle;

  /// Resolved colour-transition duration for hover / focus feedback —
  /// forwarded to `AnimatedDefaultTextStyle.duration`.
  final Duration transitionDuration;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// `CoreLinkStyle.defaultClickableStyle` (pins `pressedScale: 1.0`;
  /// inline link text must not press-shrink) merged with the
  /// per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;

  /// The ambient icon theme for the `leading` / `trailing` icons — the
  /// slot's size and, unless the slot states one, the link's text colour.
  final IconThemeData iconTheme;

  /// Nested [CoreGapStyle] between the label and an icon — raw-forwarded
  /// to the `Gap`, which scales it.
  final CoreGapStyle iconLabelGapStyle;
}

// ═══════════════════════════════════════════════════
// resolveLink — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedLink] for the given [context].
///
/// Merge chain:
///
/// ```text
/// CoreLinkStyle.defaultsByVariant[variant], CoreLinkStyle.defaultX
///   → theme.coreComponentTheme.link.style
///   → theme.coreComponentTheme.link.variantStyles[variant]
///   → widget.linkStyle
/// ```
///
/// All typography materialisation and `?? chrome` fallback decisions live
/// here (`link.dart` is render-only). [underline] is the widget's semantic
/// flag that makes the underline permanent; the inline form is always
/// underlined whatever it is, so it never reads the flag.
ResolvedLink resolveLink(
  BuildContext context, {
  required CoreLinkVariant variant,
  bool underline = false,
  CoreLinkStyle? linkStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final linkTheme = theme.coreComponentTheme?.link;

  // ─── Merge chain — design default → theme → variant → instance ───
  final merged = resolveStyleChain(const CoreLinkStyle(), [
    linkTheme?.style,
    linkTheme?.variantStyles?[variant],
    linkStyle,
  ]);
  final variantStyle = CoreLinkStyle.defaultsByVariant[variant]!;

  // ─── Resolved chrome (merged 사용자 의도 → static const default) ───
  // The text colour the caller states, if any — the nested `labelStyle`
  // colour is more specific than the flat `color`, as on Web. The underline
  // follows it unless the caller states an underline colour of its own, so
  // recolouring a link never leaves its underline behind in the old tone.
  final statedColor = merged.labelStyle?.color ?? merged.color;
  final colorCore = statedColor ?? variantStyle.color!;
  final underlineColorCore =
      merged.underlineColor ?? statedColor ?? variantStyle.underlineColor!;
  final interactionDecoration =
      (merged.interactionTextDecoration ??
              CoreLinkStyle.defaultInteractionTextDecoration)
          .toValue();
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreLinkStyle.defaultTransitionDuration,
  );

  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreLinkStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  final color = scheme.resolve(colorCore).toValue();
  final underlineColor = scheme.resolve(underlineColorCore).toValue();

  // ─── Label typography (paint-ready TextStyle) ───
  // Materialise the label typography token against the active theme, layer
  // the per-instance label override on top, then convert to a Flutter
  // `TextStyle` with the resolved foreground colour applied. The underline
  // is the font's own — no thickness or offset is stated, so Flutter draws
  // the same line the Web `from-font` underline does.
  final labelStyleCore = theme.typography
      .resolve(CoreLinkStyle.defaultLabelStyle)
      .merge(merged.labelStyle);
  // `theme:` pins the CoUI font stack. Without it an unnamed family is left
  // to be inherited, and this style *replaces* the ambient one
  // (`AnimatedDefaultTextStyle`) — nothing is left to inherit, so the label
  // fell to the system font.
  final baseLabelStyle = labelStyleCore.toValue(theme: theme, color: color);

  final labelStyle = baseLabelStyle.copyWith(
    decoration: underline ? .underline : .none,
    decorationColor: underlineColor,
    decorationStyle: .solid,
  );
  final interactionLabelStyle = baseLabelStyle.copyWith(
    decoration: underline ? .underline : interactionDecoration,
    decorationColor: underlineColor,
    decorationStyle: .solid,
  );

  // ─── Inline-span style (partial TextStyle) ───
  // Same colour and underline colour as the widget label, but always
  // underlined and with the typography role dropped — only explicit
  // per-instance overlay fields ride along, so the span inherits the
  // surrounding paragraph's ramp.
  final spanTextStyle = (merged.labelStyle ?? const CoreTextStyle())
      .toOverlayValue(color: color)
      .copyWith(
        decoration: .underline,
        decorationColor: underlineColor,
        decorationStyle: .solid,
      );

  // ─── Icon slots ───
  // The icons follow the text colour the way the underline does, unless the
  // caller states an icon colour of its own. The size is raw: `Icon` scales
  // it on its own side.
  final iconStyle = CoreLinkStyle.defaultIconStyle.merge(merged.iconStyle);
  final iconColor = iconStyle.color == null
      ? color
      : scheme.resolve(iconStyle.color!).toValue();
  final iconTheme = IconThemeData(size: iconStyle.size, color: iconColor);
  final iconLabelGapStyle = CoreLinkStyle.defaultIconLabelGapStyle.merge(
    merged.iconLabelGapStyle,
  );

  return ResolvedLink(
    iconTheme: iconTheme,
    iconLabelGapStyle: iconLabelGapStyle,
    labelStyle: labelStyle,
    interactionLabelStyle: interactionLabelStyle,
    spanTextStyle: spanTextStyle,
    transitionDuration: transitionDuration,
    clickableStyle: clickableStyle,
  );
}
