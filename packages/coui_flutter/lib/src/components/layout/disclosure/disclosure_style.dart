import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Disclosure] / [DisclosureGroup].
class ResolvedDisclosure {
  /// Creates a [ResolvedDisclosure].
  const ResolvedDisclosure({
    required this.contentInset,
    required this.iconLabelGapStyle,
    required this.itemSpacing,
    required this.duration,
    required this.curve,
    required this.iconStyle,
    required this.triggerTextStyle,
    required this.contentTextStyle,
    required this.clickableStyle,
  });

  /// Inner inset around the header row and the body.
  final EdgeInsets contentInset;

  /// Horizontal gap slot between the header text and the chevron.
  /// Forwarded straight to `Gap(gapStyle: …)` — raw, pre-scaling, since
  /// the receiving `Gap` runs its own resolve/scaling step.
  final CoreGapStyle iconLabelGapStyle;

  /// Vertical distance between siblings in a [DisclosureGroup].
  final double itemSpacing;

  /// Chevron rotation duration, already passed through the
  /// reduced-motion seat.
  final Duration duration;

  /// Chevron rotation curve.
  ///
  /// Stated rather than left to Flutter's implicit default, which is
  /// linear while the Web twin's CSS transition is ease-in-out — same
  /// duration, different shape, and side by side that reads as one pane
  /// being broken.
  final Curve curve;

  /// Nested [CoreIconStyle] slot for the chevron glyph, forwarded
  /// straight to `Icon(iconStyle: …)`.
  final CoreIconStyle iconStyle;

  /// Paint-ready header [TextStyle].
  final TextStyle triggerTextStyle;

  /// Paint-ready body [TextStyle].
  final TextStyle contentTextStyle;

  /// Nested [CoreClickableStyle] slot for the composed header
  /// `Clickable`, raw-forwarded so the Clickable's own resolver fills
  /// the remaining chrome.
  final CoreClickableStyle clickableStyle;
}

/// Resolves [ResolvedDisclosure] for [Disclosure] / [DisclosureGroup].
///
/// Single entry point — applies the merge chain
/// (`CoreDisclosureTheme.style` → `disclosureStyle`) followed by
/// design-system default fallback. Stage1 RESOLVE + Stage2 EMIT run in
/// local vars; the `return` is a bare mapping.
ResolvedDisclosure resolveDisclosure(
  BuildContext context, {
  CoreDisclosureStyle? disclosureStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.disclosure;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDisclosureStyle(), [
    coreTheme?.style,
    disclosureStyle,
  ]);

  // ─── Stage1 RESOLVE (Core values) ─────────────────────
  final contentInset =
      ((merged.contentInset ?? CoreDisclosureStyle.defaultContentInset).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final itemSpacing =
      theme.geometry.space(
        merged.itemSpacing ?? CoreDisclosureStyle.defaultItemSpacing,
      ) *
      scaling;
  // Nested icon slot — design-system default merged with the
  // per-instance override, raw-forwarded (no `* scaling`; the receiving
  // `Icon` runs its own step). Colour falls back to the single-source
  // named default only when the per-instance override is absent, which
  // is the same path Web takes.
  // guard-nested-override: iconColor — reaches here via the nested
  // `iconStyle.color` sub-field rather than a bare top-level reference.
  final iconStyle = CoreDisclosureStyle.defaultIconStyle
      .merge(merged.iconStyle)
      .copyWith(
        color: merged.iconStyle?.color ?? CoreDisclosureStyle.defaultIconColor,
      );
  final iconLabelGapStyle = CoreDisclosureStyle.defaultIconLabelGapStyle.merge(
    merged.iconLabelGapStyle,
  );
  final clickableStyle = CoreDisclosureStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );
  final duration = resolveMotionDuration(
    context,
    merged.duration ?? CoreDisclosureStyle.defaultDuration,
  );
  final triggerTextCore = CoreDisclosureStyle.defaultTriggerTextStyle.merge(
    merged.triggerTextStyle,
  );
  final contentTextCore = CoreDisclosureStyle.defaultContentTextStyle.merge(
    merged.contentTextStyle,
  );

  // ─── Stage2 EMIT (Flutter, theme-aware) ───────────────
  final triggerTextStyle = triggerTextCore.toValue(theme: theme);
  final contentTextStyle = contentTextCore.toValue(theme: theme);
  final curve = CoreEasing.move.toValue();

  // ─── RETURN = bare mapping ────────────────────────────
  return ResolvedDisclosure(
    contentInset: contentInset,
    iconLabelGapStyle: iconLabelGapStyle,
    itemSpacing: itemSpacing,
    duration: duration,
    curve: curve,
    iconStyle: iconStyle,
    triggerTextStyle: triggerTextStyle,
    contentTextStyle: contentTextStyle,
    clickableStyle: clickableStyle,
  );
}
