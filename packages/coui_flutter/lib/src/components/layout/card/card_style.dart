library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Card`.
///
/// Widget tree (`co_card` decides which optional branches render):
///
/// ```text
/// {sizing wrapper: IntrinsicWidth | SizedBox | none}
///   └─ optional _CardInteractiveWrapper (when onTap != null)
///        └─ optional DecoratedBox (when boxShadowOverride != null)
///             └─ OutlinedContainer (containerStyle)
///                  └─ DefaultTextStyle.merge (bodyTextStyle)
///                       └─ child | _CardSlotLayout
///                            (media | header | body | footer | overlay)
/// ```
///
/// Inside `_CardSlotLayout`, header → body and body → footer
/// spacers are rendered via the unified `Gap` widget (Epic #1603
/// 옵션 B 최종 — raw `SizedBox(height: …)` chrome is forbidden).
///
/// Field grouping:
///
/// 1. **Child-component contract slots** — `containerStyle:
///    CoreOutlinedContainerStyle` for the surface, `headerTextStyle` /
///    `bodyTextStyle: TextStyle` for typography, `headerBodyGapStyle`
///    / `bodyFooterGapStyle: CoreGapStyle` for the inter-slot spacers.
/// 2. **Interactive surface values** — `interactive*` fields read by
///    `_CardInteractiveWrapper`'s hover animation.
/// 3. **Caller-supplied shadow override** — `boxShadowOverride`
///    surfaces `CoreCardStyle.boxShadow` because
///    `OutlinedContainer` only exposes elevation; the widget wraps
///    the surface in a `DecoratedBox` when the override is non-null.
class ResolvedCard {
  /// Creates a [ResolvedCard].
  const ResolvedCard({
    required this.containerStyle,
    required this.bodyTextStyle,
    required this.headerTextStyle,
    required this.padding,
    required this.headerBodyGapStyle,
    required this.bodyFooterGapStyle,
    required this.width,
    required this.height,
    required this.boxShadowOverride,
    required this.hoverShadows,
    required this.interactiveBorderRadius,
    required this.interactiveDuration,
    required this.overlayInset,
    required this.clickableStyle,
  });

  /// [CoreOutlinedContainerStyle] for the `OutlinedContainer` surface
  /// — `OutlinedContainer`'s contract input. Background / border /
  /// radius / elevation / padding / clip / duration are all merged and
  /// expressed as `coui_core` domain types so the receiving widget
  /// runs its own colour / radius resolution once.
  final CoreOutlinedContainerStyle containerStyle;

  /// Paint-ready `TextStyle` for the body slot — passed to
  /// `DefaultTextStyle.merge` so the body widget inherits typography
  /// + foreground colour.
  final TextStyle bodyTextStyle;

  /// Paint-ready `TextStyle` for the header slot — same composition as
  /// [bodyTextStyle] on the header's own `titleMedium` role.
  final TextStyle headerTextStyle;

  /// Effective padding (scaling pre-applied) — `co_card` applies this
  /// either through [containerStyle] (when the caller supplies a custom
  /// `child`) or inside `_CardSlotLayout` (when slots are used).
  final EdgeInsets padding;

  /// Nested [CoreGapStyle] for the header → body spacer — forwarded
  /// straight to `Gap(gapStyle: …)` inside `_CardSlotLayout`. The
  /// slot is **not** pre-scaled here; `Gap` applies `theme.scaling`
  /// itself in its own resolver, so the forwarded slot stays in
  /// pre-scaling units (avoids double-scaling under non-default text
  /// scaler).
  final CoreGapStyle headerBodyGapStyle;

  /// Nested [CoreGapStyle] for the body → footer spacer — forwarded
  /// straight to `Gap(gapStyle: …)` inside `_CardSlotLayout`. Same
  /// scaling contract as [headerBodyGapStyle] (Gap self-scales — the
  /// resolver does not pre-multiply by `theme.scaling`).
  final CoreGapStyle bodyFooterGapStyle;

  /// Resolved width: `null` for intrinsic, `double.infinity` for
  /// `expand`, finite for `fixed`.
  final double? width;

  /// Resolved height: same shape as [width].
  final double? height;

  /// Caller-supplied box-shadow override (resolved to Flutter
  /// [BoxShadow] list). `null` when the caller did not override —
  /// the surface's `elevation` then drives the shadow inside
  /// `OutlinedContainer`.
  final List<BoxShadow>? boxShadowOverride;

  /// Hover-state shadow stack — the `hoverElevation` token's shadow
  /// list (mirrors Web `hover:shadow-{sm|md|lg}`). Paint-ready: the
  /// resolver runs the shared elevation → BoxShadow mapping
  /// (`CoreOutlinedContainerElevation.toValue`) so the widget
  /// passes the list straight to `BoxDecoration.boxShadow`.
  final List<BoxShadow> hoverShadows;

  /// Border radius used by the interactive wrapper's animated shadow.
  final BorderRadius interactiveBorderRadius;

  /// Hover shadow animation duration.
  final Duration interactiveDuration;

  /// Effective inset (scaling pre-applied) for the absolutely-positioned
  /// overlay slot inside the media wrapper. `co_card` renders the
  /// overlay only when `overlay != null`, and applies this inset on all
  /// four sides (Epic #2210 RULE E coverage — `overlayInset` is reflected
  /// here).
  final double overlayInset;

  /// Nested [CoreClickableStyle] slot for the composed per-card
  /// `Clickable` (tappable cards only) — `CoreCardStyle.defaultClickableStyle`
  /// (press-shrink OFF) merged with the per-instance override, raw-forwarded
  /// to `Clickable(clickableStyle:)`. The Clickable's own resolver fills
  /// the remaining defaults.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCard] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (+ defaultsByVariant for variant chrome)
///   → theme.coreComponentTheme.card.style
///   → theme.coreComponentTheme.card.variantStyles[variant]
///   → widget.cardStyle
/// ```
ResolvedCard resolveCard(
  BuildContext context, {
  required CoreCardVariant variant,
  required bool mediaPresent,
  CoreCardStyle? cardStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final cardTheme = theme.coreComponentTheme?.card;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCardStyle(), [
    cardTheme?.style,
    cardTheme?.variantStyles?[variant],
    cardStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final variantStyle = CoreCardStyle.defaultsByVariant[variant]!;

  // ─── Resolved chrome (domain types for OutlinedContainer) ─
  // `OutlinedContainer` accepts `CoreOutlinedContainerStyle` — its
  // contract input runs the final `scheme.resolve` / `.toValue()` step
  // itself. Pass `CoreColor` / `CoreBorderRadius` through as-is.
  // Scaling is applied widget-side (OutlinedContainer handles it),
  // so the resolver leaves `CoreEdgeInsets` / `borderWidth` in
  // pre-scaling units to match the contract.
  final coreCardPadding = merged.padding ?? CoreCardStyle.defaultPadding;
  // Border radius is resolved here once (override else design-system
  // default) and reused by both the `OutlinedContainer` surface and
  // the interactive wrapper's animated shadow — a single resolution
  // point so the resting corner and the hover-shadow corner never drift
  // (Epic #1603 C5/C6 — no second container-radius fallback).
  final coreBorderRadius =
      merged.borderRadius ?? CoreCardStyle.defaultBorderRadius;
  final elevation = merged.elevation ?? CoreCardStyle.defaultElevation;
  final sizing = merged.sizing ?? CoreCardStyle.defaultSizing;
  final clipMode = merged.clipBehavior ?? CoreCardStyle.defaultClipBehavior;
  // `CoreCardStyle.clipBehavior` is a `CoreClipMode`; `OutlinedContainer`
  // accepts `CoreClipBehavior`. Map between the two — media presence
  // upgrades `none` to `antiAlias` so images respect the rounded
  // corner.
  final CoreClipBehavior effectiveClip = clipMode == .none && mediaPresent
      ? .antiAlias
      : clipMode.toClipBehavior();

  final containerStyle = CoreOutlinedContainerStyle(
    // The card's material is the container's: raw-forwarded, so the
    // composed surface draws (or drops) glass by the one rule every
    // surface shares rather than a second copy of it here.
    surfaceStyle: merged.surfaceStyle,
    backgroundColor: merged.backgroundColor ?? variantStyle.backgroundColor,
    borderColor: merged.borderColor ?? variantStyle.borderColor,
    borderRadius: coreBorderRadius,
    borderWidth: merged.borderWidth ?? variantStyle.borderWidth,
    elevation: elevation.toOutlinedContainerElevation(),
    // Forwarded only for an *explicit empty* override — the caller's way
    // of stating "no shadow, not even the active style's ambient cast"
    // (`explicitShadow == null && coreShadow.isEmpty` is exactly what
    // `OutlinedContainer` reads to fall back to `controlShadow`; a null
    // here would still fall through, so the suppression has to travel as
    // a real (if empty) list). Web's `Card` gates the same marker off
    // `merged.boxShadow == null` for the identical reason — without this
    // the two platforms disagree on whether "no shadow" ever really
    // means none under a style whose signature is an ambient cast
    // (neo-brutalism), and the disagreement is invisible until such a
    // style is active. A *non-empty* override is left alone here — it
    // keeps painting through `boxShadowOverride` below, unchanged.
    boxShadow: merged.boxShadow != null && merged.boxShadow!.isEmpty
        ? const <CoreShadowLayer>[]
        : null,
    padding: coreCardPadding,
    // Glassmorphism — forwarded raw to the `OutlinedContainer` surface,
    // which renders the backdrop blur (Flutter `BackdropFilter` / Web
    // `backdrop-filter`). `null` = opaque (design-system default).
    surfaceOpacity: merged.surfaceOpacity,
    surfaceBlur: merged.surfaceBlur,
    duration:
        merged.chromeAnimationDuration ??
        CoreCardStyle.defaultChromeAnimationDuration,
    clipBehavior: effectiveClip,
  );

  // Shadow base colour — reused by the caller override and the hover
  // interactive shadow.
  final shadowBase = scheme
      .resolve(merged.shadowBaseColor ?? CoreCardStyle.defaultShadowBaseColor)
      .toValue();

  // `merged.boxShadow` is a caller override — wrap the surface in a
  // `DecoratedBox` so the override paints on top of the container's
  // elevation. Resolver completes the `CoreColor → Color` conversion
  // here so the widget reads paint-ready `BoxShadow`s.
  final boxShadowOverride = merged.boxShadow?.toValue(
    base: shadowBase,
    geometry: theme.geometry,
  );

  // ─── Typography (paint-ready TextStyle for DefaultTextStyle.merge) ─
  // EMIT Stage 2 (Flutter) — Core-level merge (default + per-instance
  // override) then a single `style.toValue(theme:)` that materialises the
  // token role AND resolves its colour through the active scheme. The
  // token-backed default already carries `color: onSurface`, so no `color:`
  // override is needed — the slot's own colour tracks dark mode. Single
  // primitive; no `materialiseCoreText` / `.copyWith(color: scheme.resolve)`
  // hand-assembly.
  final bodyTextStyleCore = CoreCardStyle.defaultBodyTextStyle.merge(
    merged.bodyTextStyle,
  );
  final headerTextStyleCore = CoreCardStyle.defaultHeaderTextStyle.merge(
    merged.headerTextStyle,
  );
  final bodyTextStyle = bodyTextStyleCore.toValue(theme: theme);
  final headerTextStyle = headerTextStyleCore.toValue(theme: theme);

  // ─── Sizing ───────────────────────────────────────────
  final double? width;
  final double? height;
  switch (sizing) {
    case .intrinsic:
      width = null;
      height = null;
    case .expand:
      width = .infinity;
      height = null;
    case .fixed:
      width = merged.width;
      height = merged.height;
  }

  // ─── Layout gaps (nested CoreGapStyle slots forwarded to Gap) ─
  // Merge the design-system default `CoreGapStyle` with the
  // per-instance override and forward the merged slot raw. `Gap`'s
  // own resolver multiplies `size` by `theme.scaling`, so pre-applying
  // scaling here would double-scale under non-default text scaler
  // (Epic #1603 옵션 B — parent forwards raw nested style slots).
  final headerBodyGapStyle = CoreCardStyle.defaultHeaderBodyGapStyle.merge(
    merged.headerBodyGapStyle,
  );
  final bodyFooterGapStyle = CoreCardStyle.defaultBodyFooterGapStyle.merge(
    merged.bodyFooterGapStyle,
  );
  // Scaling boundary (Epic #1603 C12 — single materialise per surface):
  //   • `containerStyle.padding` keeps `coreCardPadding` as a *pre-scaling*
  //     `CoreEdgeInsets` because `OutlinedContainer` applies
  //     `theme.scaling` itself — that surface owns its own scale step.
  //   • `slotLayoutPadding` is the *post-scaling* `EdgeInsets` used by
  //     `_CardSlotLayout`, which is a plain `Padding` with no self-scale.
  // `co_card` swaps `containerStyle.padding` to `CoreEdgeInsets.zero`
  // whenever the slot layout runs (slots + no custom `child`), so the
  // two padding paths are mutually exclusive — `coreCardPadding` is
  // materialised through exactly one of them and never double-applied.

  // ─── Interactive hover shadow (paint-ready Flutter values) ─
  // Hover-shadow animation duration is its own field, distinct from
  // the chrome-transition duration above — callers tune each
  // independently. The shadow itself is the `hoverElevation` token's
  // shadow stack (mirrors Web's `hover:${tailwindShadowClass}`).
  final hoverShadowAnimationDuration = resolveMotionDuration(
    context,
    merged.hoverShadowAnimationDuration ??
        CoreCardStyle.defaultHoverShadowAnimationDuration,
  );
  final hoverElevation =
      merged.hoverElevation ?? CoreCardStyle.defaultHoverElevation;
  // `CoreOutlinedContainerElevation.toValue` is the shared
  // elevation → `List<BoxShadow>` adapter (matches Web `shadow-sm/md/lg`).
  // Reuse it so the hover shadow is a single source with the resting
  // elevation shadow rendered by `OutlinedContainer`.
  final hoverShadows = hoverElevation.toOutlinedContainerElevation().toValue(
    base: shadowBase,
    geometry: theme.geometry,
  );
  // Interactive wrapper's animated-shadow corner — reuses the single
  // resolved `coreBorderRadius` (override else `defaultBorderRadius`) so
  // the hover-shadow corner exactly matches the resting surface corner.
  // No independent container-radius fallback (Epic #1603 C5/C6 —
  // radius resolves once).
  //
  // `* scaling` here mirrors `OutlinedContainer`'s own radius resolution
  // (`outlined_container_style.dart`: `_resolveBorderRadius(...) * scaling`)
  // — the size factor is applied *after* the geometry bend in both places.
  // Without it, this wrapper's shadow-clip radius stays at the unscaled
  // geometry value while the surface it wraps renders at `* scaling`
  // (e.g. radius8 → 12 under a 1.5x app scale). The two nested rounded
  // shapes then disagree exactly at the curve — straight edges still line
  // up (a radius mismatch has no effect there), but the corner shows a
  // visible seam where the larger-radius surface corner doesn't nest
  // inside the smaller-radius shadow-clip corner (found via good-teacher
  // issue #1511 — a corner-only "shadow colour poking out" artifact on a
  // small-radius Card under non-1.0 scaling). Regression test:
  // test/components/card_shadow_radius_scaling_test.dart.
  final interactiveBorderRadius =
      coreBorderRadius.toValue(geometry: theme.geometry) * scaling;

  // ─── Paint-ready dimensional locals (scaling applied here, not in the
  //     return literal — chaining position gate: return = bare mapping +
  //     `* scaling` only on these dimensional locals).
  final slotLayoutPadding =
      coreCardPadding.toValue(geometry: theme.geometry) * scaling;
  final overlayInset =
      (merged.overlayInset ?? CoreCardStyle.defaultOverlayInset) * scaling;

  // Nested Clickable slot — partial default (press-shrink off for the
  // large card surface) merged with the override, raw-forwarded (the
  // Clickable's own resolver fills the rest).
  final clickableStyle = CoreCardStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  return ResolvedCard(
    containerStyle: containerStyle,
    bodyTextStyle: bodyTextStyle,
    headerTextStyle: headerTextStyle,
    padding: slotLayoutPadding,
    headerBodyGapStyle: headerBodyGapStyle,
    bodyFooterGapStyle: bodyFooterGapStyle,
    width: width,
    height: height,
    boxShadowOverride: boxShadowOverride,
    hoverShadows: hoverShadows,
    interactiveBorderRadius: interactiveBorderRadius,
    interactiveDuration: hoverShadowAnimationDuration,
    overlayInset: overlayInset,
    clickableStyle: clickableStyle,
  );
}
