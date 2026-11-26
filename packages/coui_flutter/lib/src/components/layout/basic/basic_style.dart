import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Basic].
///
/// ```text
/// ResolvedBasic
///   ├─ leadingAlignment / trailingAlignment / titleAlignment /
///   │  subtitleAlignment / contentAlignment   // AlignmentGeometry
///   ├─ titleContentGapStyle   (CoreGapStyle)  // horizontal — leading↔body / body↔trailing
///   ├─ leadingTitleGapStyle   (CoreGapStyle)  // vertical — title block ↔ content
///   ├─ titleSubtitleGapStyle  (CoreGapStyle)  // vertical — title ↔ subtitle
///   ├─ mainAxisAlignment      (MainAxisAlignment)
///   ├─ padding                (EdgeInsetsGeometry)
///   └─ titleTextStyle / subtitleTextStyle / contentTextStyle  // paint-ready TextStyle?
/// ```
///
/// The three gap-style slots are pre-scaling — the inner `Gap`
/// widgets self-resolve and self-scale, matching Epic #2228's
/// 4-principle (parent components forward the raw `CoreGapStyle`).
///
/// The three slot text styles are paint-ready Flutter `TextStyle`s
/// (typography role materialised + colour resolved through the active
/// scheme + per-instance overlay applied) — non-null only when
/// `forceTextStyle == true`. `co_basic.dart` wraps the slot child in
/// `DefaultTextStyle.merge(style: …)` when the value is non-null and
/// renders the raw child otherwise (render-only — no typography
/// assembly in the widget).
class ResolvedBasic {
  /// Creates a [ResolvedBasic].
  const ResolvedBasic({
    required this.leadingAlignment,
    required this.trailingAlignment,
    required this.titleAlignment,
    required this.subtitleAlignment,
    required this.contentAlignment,
    required this.titleContentGapStyle,
    required this.leadingTitleGapStyle,
    required this.titleSubtitleGapStyle,
    required this.mainAxisAlignment,
    required this.padding,
    required this.trailingGapStyle,
    required this.trailingIconStyle,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.contentTextStyle,
    this.trailingTextStyle,
  });

  /// Alignment of the leading slot inside its cell.
  final AlignmentGeometry leadingAlignment;

  /// Alignment of the trailing slot inside its cell.
  final AlignmentGeometry trailingAlignment;

  /// Alignment of the title slot inside its cell.
  final AlignmentGeometry titleAlignment;

  /// Alignment of the subtitle slot inside its cell.
  final AlignmentGeometry subtitleAlignment;

  /// Alignment of the content slot inside its cell.
  final AlignmentGeometry contentAlignment;

  /// Nested [CoreGapStyle] slot for the horizontal gap between
  /// `leading` / body / `trailing` — forwarded straight to
  /// `Gap(gapStyle: …)`. `Gap` runs its own resolve / scaling step.
  final CoreGapStyle titleContentGapStyle;

  /// Nested [CoreGapStyle] slot for the vertical gap between the
  /// title+subtitle block and the `content` row — forwarded straight
  /// to `Gap(gapStyle: …)`.
  final CoreGapStyle leadingTitleGapStyle;

  /// Nested [CoreGapStyle] slot for the vertical gap between the
  /// `title` and `subtitle` rows — forwarded straight to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle titleSubtitleGapStyle;

  /// Outer row main-axis alignment.
  final MainAxisAlignment mainAxisAlignment;

  /// Outer padding wrapper.
  final EdgeInsetsGeometry padding;

  /// Paint-ready title slot text style — `null` when `forceTextStyle`
  /// is false (slot renders with the caller's own styling). Non-null
  /// value is the design-system title role + colour + weight merged
  /// with the per-instance `titleTextStyle` override.
  final TextStyle? titleTextStyle;

  /// Paint-ready subtitle slot text style — `null` when `forceTextStyle`
  /// is false. Non-null value is the muted `body-small` role merged with
  /// the per-instance `subtitleTextStyle` override.
  final TextStyle? subtitleTextStyle;

  /// Paint-ready content slot text style — `null` when `forceTextStyle`
  /// is false. Non-null value is the `body-small` role merged with the
  /// per-instance `contentTextStyle` override.
  final TextStyle? contentTextStyle;

  /// Nested [CoreGapStyle] slot for the gap between the trailing value
  /// text and the trailing icon — forwarded straight to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle trailingGapStyle;

  /// Paint-ready trailing value text style — `null` when
  /// `forceTextStyle` is false.
  final TextStyle? trailingTextStyle;

  /// Nested [CoreIconStyle] slot for the built-in trailing chevron —
  /// forwarded straight to `Icon(iconStyle: …)`.
  final CoreIconStyle trailingIconStyle;
}

/// Converts a [CoreBasicAlignment] preset into a Flutter [AlignmentGeometry].
AlignmentGeometry alignmentFromCoreBasicAlignment(CoreBasicAlignment value) {
  switch (value) {
    case .topStart:
      return .topLeft;
    case .topCenter:
      return .topCenter;
    case .topEnd:
      return Alignment.topRight;
    case .centerStart:
      return Alignment.centerLeft;
    case .center:
      return Alignment.center;
    case .centerEnd:
      return Alignment.centerRight;
    case .bottomStart:
      return Alignment.bottomLeft;
    case .bottomCenter:
      return Alignment.bottomCenter;
    case .bottomEnd:
      return Alignment.bottomRight;
  }
}

/// Converts a [CoreBasicMainAxisAlignment] preset into a Flutter
/// [MainAxisAlignment].
MainAxisAlignment mainAxisAlignmentFromCore(CoreBasicMainAxisAlignment value) {
  switch (value) {
    case .start:
      return .start;
    case .end:
      return .end;
    case .center:
      return .center;
    case .spaceBetween:
      return .spaceBetween;
    case .spaceAround:
      return .spaceAround;
    case .spaceEvenly:
      return .spaceEvenly;
  }
}

/// Resolves [ResolvedBasic] for [Basic].
///
/// Merge chain (per-field): `widget.basicStyle` > `CoreBasicTheme.style`
/// > design-system default (`CoreBasicStyle.defaultX`).
///
/// [forceTextStyle] controls whether the title / subtitle / content slot
/// text styles are materialised. When `true`, each slot's design-system
/// `CoreTextStyle` default (role + colour + weight) is merged with the
/// per-instance override and converted to a paint-ready Flutter
/// `TextStyle` via the single `toValue(theme:)` primitive (badge resolver
/// model — typography role materialised + colour scheme-resolved). When
/// `false`, the three slot text styles stay `null` and `co_basic.dart`
/// renders each slot with the caller's own styling (legacy `BasicLayout`
/// parity).
ResolvedBasic resolveBasic(
  BuildContext context, {
  required bool forceTextStyle,
  CoreBasicStyle? basicStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.basic;

  final merged = resolveStyleChain(const CoreBasicStyle(), [
    coreTheme?.style,
    basicStyle,
  ]);

  final resolvedLeading =
      merged.leadingAlignment ?? CoreBasicStyle.defaultLeadingAlignment;
  final resolvedTrailing =
      merged.trailingAlignment ?? CoreBasicStyle.defaultTrailingAlignment;
  final resolvedTitle =
      merged.titleAlignment ?? CoreBasicStyle.defaultTitleAlignment;
  final resolvedSubtitle =
      merged.subtitleAlignment ?? CoreBasicStyle.defaultSubtitleAlignment;
  final resolvedContent =
      merged.contentAlignment ?? CoreBasicStyle.defaultContentAlignment;
  final resolvedMainAxis =
      merged.mainAxisAlignment ?? CoreBasicStyle.defaultMainAxisAlignment;
  // `toGeometry`, not `toValue`: a composing parent may state a padding that
  // follows the reading direction (`CardImage`'s text row), which has no
  // fixed left/right until the ambient `Directionality` resolves it.
  final resolvedPadding =
      (merged.padding ?? CoreBasicStyle.defaultPadding).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;

  // ─── Nested gap-style slots (pre-scaling — Gap self-scales) ──
  final titleContentGapStyle = CoreBasicStyle.defaultTitleContentGapStyle.merge(
    merged.titleContentGapStyle,
  );
  final leadingTitleGapStyle = CoreBasicStyle.defaultLeadingTitleGapStyle.merge(
    merged.leadingTitleGapStyle,
  );
  final titleSubtitleGapStyle = CoreBasicStyle.defaultTitleSubtitleGapStyle
      .merge(merged.titleSubtitleGapStyle);

  // ─── Paint-ready slot text styles (only when forceTextStyle) ──
  // Single `default.merge(override).toValue(theme:)` primitive per slot:
  // the token-backed default carries the role + colour + weight, the
  // per-instance override overlays, and `toValue(theme:)` materialises
  // the role and resolves the colour through the active scheme so dark
  // mode tracks. `null` when `forceTextStyle == false` — the widget then
  // renders the slot child unstyled (legacy `BasicLayout` parity).
  final titleTextStyle = forceTextStyle
      ? CoreBasicStyle.defaultTitleTextStyle
            .merge(merged.titleTextStyle)
            .toValue(theme: theme)
      : null;
  final subtitleTextStyle = forceTextStyle
      ? CoreBasicStyle.defaultSubtitleTextStyle
            .merge(merged.subtitleTextStyle)
            .toValue(theme: theme)
      : null;
  final contentTextStyle = forceTextStyle
      ? CoreBasicStyle.defaultContentTextStyle
            .merge(merged.contentTextStyle)
            .toValue(theme: theme)
      : null;

  final trailingGapStyle = CoreBasicStyle.defaultTrailingGapStyle.merge(
    merged.trailingGapStyle,
  );
  final trailingIconStyle = CoreBasicStyle.defaultTrailingIconStyle.merge(
    merged.trailingIconStyle,
  );
  final trailingTextStyle = forceTextStyle
      ? CoreBasicStyle.defaultTrailingTextStyle
            .merge(merged.trailingTextStyle)
            .toValue(theme: theme)
      : null;

  return ResolvedBasic(
    leadingAlignment: alignmentFromCoreBasicAlignment(resolvedLeading),
    trailingAlignment: alignmentFromCoreBasicAlignment(resolvedTrailing),
    titleAlignment: alignmentFromCoreBasicAlignment(resolvedTitle),
    subtitleAlignment: alignmentFromCoreBasicAlignment(resolvedSubtitle),
    contentAlignment: alignmentFromCoreBasicAlignment(resolvedContent),
    titleContentGapStyle: titleContentGapStyle,
    leadingTitleGapStyle: leadingTitleGapStyle,
    titleSubtitleGapStyle: titleSubtitleGapStyle,
    mainAxisAlignment: mainAxisAlignmentFromCore(resolvedMainAxis),
    padding: resolvedPadding,
    titleTextStyle: titleTextStyle,
    subtitleTextStyle: subtitleTextStyle,
    contentTextStyle: contentTextStyle,
    trailingGapStyle: trailingGapStyle,
    trailingTextStyle: trailingTextStyle,
    trailingIconStyle: trailingIconStyle,
  );
}
