import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedValidatorHint
// ═══════════════════════════════════════════════════

/// Resolver output for [ValidatorHint].
///
/// Single struct that the widget reads — every chrome / typography
/// override has had the nested-merge chain applied plus the
/// `CoreValidatorHintStyle.defaultX` static const fallback,
/// `defaultsByType` per-type accent, and Flutter type conversion:
///
/// ```text
/// CoreValidatorHintStyle.defaultX        // design system default
///   → theme.coreComponentTheme.validatorHint.style
///   → widget.validatorHintStyle
/// ```
class ResolvedValidatorHint {
  /// Creates a [ResolvedValidatorHint].
  const ResolvedValidatorHint({
    required this.messageTextStyle,
    required this.accentColor,
    required this.iconStyle,
    required this.iconLabelGapStyle,
  });

  /// Effective text style applied to the message content.
  final TextStyle messageTextStyle;

  /// Effective accent colour (resolved Flutter `Color`) applied to the
  /// message text and the caller-supplied-icon ambient `IconTheme`.
  final Color accentColor;

  /// Effective leading icon style with the per-type accent token baked
  /// in — passed whole to `Icon`, which self-resolves the colour /
  /// size. No widget-side `CoreColor` round-trip.
  final CoreIconStyle iconStyle;

  /// Nested [CoreGapStyle] slot forwarded to the `Gap` widget
  /// rendered between the icon and the message label. Merged with
  /// [CoreValidatorHintStyle.defaultIconLabelGapStyle]. `Gap`
  /// self-scales, so this slot carries raw (pre-scaling) values.
  final CoreGapStyle iconLabelGapStyle;
}

// ═══════════════════════════════════════════════════
// resolveValidatorHint — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedValidatorHint] for the given [context] and
/// [type].
///
/// Walks the nested-merge chain, applies the per-type accent from
/// `CoreValidatorHintStyle.defaultsByType`, and the
/// `CoreValidatorHintStyle.defaultX` static const fallback so the
/// widget reads only fully-resolved Flutter-typed values.
ResolvedValidatorHint resolveValidatorHint(
  BuildContext context, {
  required CoreValidatorHintType type,
  CoreValidatorHintStyle? validatorHintStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final hintTheme = theme.coreComponentTheme?.validatorHint;

  // 2-stage merge chain — theme.style → widget.validatorHintStyle.
  final merged = resolveStyleChain(const CoreValidatorHintStyle(), [
    hintTheme?.style,
    validatorHintStyle,
  ]);

  // Per-type accent — defaultsByType is the single source of truth. The
  // accent resolves to a Flutter colour for the message text + the
  // caller-icon ambient IconTheme; the leading icon slot below takes the
  // same accent unresolved so `Icon` resolves it itself — no
  // widget-side `CoreColor(...toARGB32())` round-trip.
  final typeChrome = CoreValidatorHintStyle.defaultsByType[type]!;
  final accentColor = scheme
      .resolve(merged.accentColor ?? typeChrome.accentColor)
      .toValue();

  // Message label typography — EMIT Stage 2 (Flutter): the token-backed
  // bodyXs role default merged with any per-instance override,
  // materialised through the single toValue-with-theme primitive. The
  // colour override forces the resolved accent (per-type or override),
  // so the message text always tracks the accent regardless of the
  // overlay's own colour. Single source of truth — the role lives in
  // the default message text style, not a hardcoded bodyXs
  // typography lookup.
  final messageTextStyle = CoreValidatorHintStyle.defaultMessageTextStyle
      .merge(merged.messageTextStyle)
      .toValue(color: accentColor, theme: theme);

  // Nested `CoreGapStyle` slot — merge the design-system default with
  // the per-instance override and forward the resulting slot straight
  // to the `Gap` widget. `Gap` self-scales, so we forward raw
  // (pre-scaling) values.
  final iconLabelGapStyle = CoreValidatorHintStyle.defaultIconLabelGapStyle
      .merge(merged.iconLabelGapStyle);

  // Nested CoreIconStyle slot — the widget passes it whole to the Icon
  // child, whose own resolver applies the scheme resolution plus theme
  // scaling. The per-type accent is layered last so it wins over both
  // the default icon colour AND any caller-supplied `iconStyle.color`
  // (matching the old widget-side colour override) — colour has its
  // own dedicated flat entry point (`accentColor`), so `iconStyle.color`
  // is not the override path for this colour.
  // guard-nested-override: color — accent wins over caller
  // `iconStyle.color` (and, above, over `messageTextStyle.color`);
  // override via `accentColor` instead.
  final iconStyle = CoreValidatorHintStyle.defaultIconStyle
      .merge(merged.iconStyle)
      .merge(
        CoreIconStyle(color: merged.accentColor ?? typeChrome.accentColor),
      );

  return ResolvedValidatorHint(
    messageTextStyle: messageTextStyle,
    accentColor: accentColor,
    iconStyle: iconStyle,
    iconLabelGapStyle: iconLabelGapStyle,
  );
}

/// Maps a [CoreValidatorHintType] to its default leading Lucide icon.
IconName coValidatorHintDefaultIcon(CoreValidatorHintType type) {
  return switch (type) {
    .error => LucideIcons.circleAlert,
    .warning => LucideIcons.triangleAlert,
    .info => LucideIcons.info,
    .success => LucideIcons.circleCheckBig,
    // The unfilled twin of `success`'s mark — in a checklist the two share
    // one column and only the glyph changes as a rule is met, so the pair
    // has to share a silhouette.
    .neutral => LucideIcons.circleDashed,
  };
}
