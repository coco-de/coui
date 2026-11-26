import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `ValidationBadge`.
///
/// DOM shape:
///
/// ```text
/// root (<span role="status">)         // inline-flex chip container
///   ├─ Icon                         // state icon (chrome owned by Icon)
///   └─ label (<span>)                 // truncated label text
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [iconStyle] is forwarded to the state icon via
///   `Icon(iconStyle: …)`.
///
/// No scalar metadata (size / iconSize / glyph) is exposed — the
/// semantic `state` and `size` props live on the widget, and the glyph
/// selection switch lives in `co_validation_badge` (mirrors
/// `Alert` variant → icon).
class ResolvedValidationBadge implements WebResolvedChrome {
  /// Creates a [ResolvedValidationBadge].
  const ResolvedValidationBadge({
    required this.root,
    required this.label,
    required this.iconStyle,
  });

  /// Paint-ready chrome for the outer `<span role="status">` chip —
  /// inline-flex layout + padding + gap + radius + typography + per-
  /// state colour classes; inline CSS only when the user overrode
  /// the default colour for the current state.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the inner label `<span>` — `truncate`
  /// className. Foreground colour is inherited from the root.
  final WebElementChrome label;

  /// Nested [CoreIconStyle] slot — forwarded to `Icon(iconStyle: …)`
  /// for the state icon. Carries the resolved icon size pulled from
  /// `CoreValidationBadgeStyle.defaultsBySize[size].iconSize`.
  final CoreIconStyle iconStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedValidationBadge] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (per size)
///   → theme.coreComponentTheme.validationBadge.style
///   → widget.validationBadgeStyle
/// ```
///
/// The semantic [state] and [size] are widget props — they thread
/// through to pick the per-state colour triplet here. The theme
/// cannot override them (Epic #1603 옵션 B 최종 — semantic identifiers
/// stay on the widget).
ResolvedValidationBadge resolveValidationBadge(
  BuildContext context, {
  required CoreValidationState state,
  required CoreValidationBadgeSize size,
  CoreValidationBadgeStyle? validationBadgeStyle,
  int? labelMaxLines,
  CoreTextOverflow? labelOverflow,
}) {
  final coreTheme = context.theme.coreComponentTheme?.validationBadge;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreValidationBadgeStyle(), [
    coreTheme?.style,
    validationBadgeStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final tokens = CoreValidationBadgeStyle.defaultsBySize[size]!;
  // Per-state design-system default colour triplet — the Core single
  // source (`defaultsByState`) shared 1:1 with the Flutter resolver. Each
  // surface is a token-bound `CoreColor` so `emitColor` emits a Tailwind
  // token class (dark-mode reactive); a raw caller override goes inline.
  final stateDefaults = CoreValidationBadgeStyle.defaultsByState[state]!;

  // Nested CoreGapStyle slot — merge the per-size default with the
  // per-instance override, then extract `.size` for the inline `gap`
  // (`spaceCss` — a step names its variable, an off-scale override is a
  // literal rather than a variable that does not exist). Mirrors the
  // Flutter resolver's `iconLabelGapStyle` merge.
  final iconLabelGapStyle = tokens.iconLabelGapStyle.merge(
    merged.iconLabelGapStyle,
  );
  final gap = spaceCss(iconLabelGapStyle.size!);

  // ─── Resolved chrome values ───────────────────────────
  // Per-state colour overrides (caller wins; null → the design-system
  // token default takes over inside `emitColor`).
  // sb8 — per-state foreground colour now lives inside the nested
  // `xxxLabelTextStyle.color` slot.
  // `labelBaseStyle` is the Core per-state label default (colour only —
  // the role rides the per-size token it is merged onto below), so the
  // label slot reads its own `default…LabelTextStyle` rather than
  // re-deriving the colour from the state triplet.
  final (
    bgOverride,
    labelOverride,
    labelBaseStyle,
    borderOverride,
  ) = switch (state) {
    .pending => (
      merged.pendingBackgroundColor,
      merged.pendingLabelTextStyle,
      CoreValidationBadgeStyle.defaultPendingLabelTextStyle,
      merged.pendingBorderColor,
    ),
    .valid => (
      merged.validBackgroundColor,
      merged.validLabelTextStyle,
      CoreValidationBadgeStyle.defaultValidLabelTextStyle,
      merged.validBorderColor,
    ),
    .invalid => (
      merged.invalidBackgroundColor,
      merged.invalidLabelTextStyle,
      CoreValidationBadgeStyle.defaultInvalidLabelTextStyle,
      merged.invalidBorderColor,
    ),
  };

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Each colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value. Token-bound bases
  // (the per-state default triplet) emit Tailwind classes (dark-mode
  // reactive); raw caller overrides go inline. No `scheme.resolve` (a
  // no-op on Web) and no hand-rolled `surface-container` token strings.
  // surface:content — the background token this chip fills with, read
  // before it resolves to a CSS string so `surfaceFillVar` can see its
  // token reference.
  final backgroundColorCore = bgOverride ?? stateDefaults.backgroundColor;
  // Whether this state paints a fill. The surface material is a statement
  // about a filled box: handed to a transparent chip it frosts a backdrop
  // behind nothing and clears the stroke that is the chip's only edge. The
  // Flutter twin withholds the material on the same answer.
  final hasFill = surfacePaintsFill(backgroundColorCore);
  final backgroundEmit = emitColor(
    bgOverride,
    stateDefaults.backgroundColor,
    .background,
  );
  final borderEmit = emitColor(
    borderOverride,
    stateDefaults.borderColor,
    .border,
  );
  // Label typography + colour. The per-size role token
  // (`labelMedium` / `bodySmall`) carries the per-state label default
  // ([labelBaseStyle], whose colour is the same
  // `default…ForegroundColor` const the state triplet reads) so the label
  // class also tints the text; the caller's `xxxLabelTextStyle` overlay
  // (incl. its own colour) wins via merge. `emitTypography` emits the role
  // + token colour on classes and any scalar / raw overlay inline.
  final labelDefault = tokens.labelStyle.merge(labelBaseStyle);
  final labelEmit = emitTypography(labelOverride, labelDefault);

  // Icon style slot — base `size` pulled from the per-size token table,
  // then the per-instance `iconStyle` override merged on top (sb #2305 —
  // honours the nested `CoreValidationBadgeStyle.iconStyle` slot, 1:1:1:1
  // with Flutter). Forwarded to `Icon(iconStyle: …)`; the icon colour
  // inherits from the root chip so no `color` is set here.
  final iconStyle = CoreIconStyle(
    size: tokens.iconSize,
  ).merge(merged.iconStyle);

  // Padding / border-radius for the chip — always emitted inline (single
  // inline signature). Synthesised here (local vars) so the builders read
  // a single source.
  final padding =
      '${spaceCss(tokens.verticalPadding)} '
      '${spaceCss(tokens.horizontalPadding)}';
  final borderRadius = CoreBorderRadius.all(tokens.borderRadius).toValue();
  final borderWidth = strokeWidthCss(
    merged.borderWidth ?? CoreValidationBadgeStyle.defaultBorderWidth,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer `<span>` chip Tailwind className —
  /// inline-flex layout + the label typography / colour classes
  /// ([labelEmit]) + per-state background / border colour classes (from
  /// the [emitColor] results, token values only). Padding / gap / radius
  /// flow inline via [buildRootInlineStyles] (single inline signature).
  String buildRootClassName() {
    return <String>[
      WebLayout.inlineFlex,
      WebLayout.itemsCenter,
      // Clamp to the available width so an over-long label truncates
      // (ellipsis, via the label's `truncate`) instead of growing past
      // the container — matches Flutter's `Flexible` label which clamps
      // to the parent and ellipsises.
      WebLayout.maxWFull,
      'border',
      // Marks this element as a component surface — restated here
      // because ValidationBadge can't compose `OutlinedContainer` (its
      // Web root is a fixed `<span>`, #4358). Only while the state paints
      // a fill ([hasFill]).
      if (hasFill) ...webSurfaceMarkerFor(.content),
      labelEmit.className,
      backgroundEmit.className,
      borderEmit.className,
    ].where((c) => c.isNotEmpty).join(' ');
  }

  /// Composes the outer `<span>` chip inline CSS.
  ///
  /// Padding / gap / radius are **always** emitted inline (single inline
  /// signature) from the per-size `defaultsBySize` token table — the gap
  /// flows through the nested [CoreGapStyle] slot ([iconLabelGapStyle]) so
  /// the per-instance override is honoured. The size-default spacing flows
  /// through the `--coui-space-N` / `--coui-radius-N` CSS variables so
  /// browser accessibility scaling still applies. The per-state colour /
  /// typography fragments from the emit family are appended only when the
  /// caller supplied a raw override (token values stay on classes).
  Styles buildRootInlineStyles() {
    final raw = {
      'height': '${tokens.height / kRemDivisor}rem',
      'padding': padding,
      'gap': gap,
      'border-radius': borderRadius,
      'border-width': borderWidth,
      ...?backgroundEmit.inline,
      ...?borderEmit.inline,
      ...?labelEmit.inline,
      // The marker's other half — a preset restates this fill at a
      // lower alpha and cannot know which token the chip chose. The tint's
      // own alpha goes out beside the triplet, so a 10% tint stays 10% of
      // the share rather than becoming the share.
      if (hasFill) ...surfaceFillVar(backgroundColorCore),
    };
    return Styles(raw: raw);
  }

  /// Composes the inner label `<span>` Tailwind className —
  /// truncation only; colour / typography inherit from the root.
  /// The default clamp is the `truncate` utility, which also pins
  /// `white-space: nowrap`. A caller-stated clamp arrives as inline CSS
  /// on the `Text` instead, and `nowrap` would pin that to one line
  /// however many the caller asked for — so the utility steps aside.
  String buildLabelClassName() => labelMaxLines == null && labelOverflow == null
      ? '${WebLayout.minWZero} ${WebLayout.truncate}'
      : WebLayout.minWZero;

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedValidationBadge(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    label: WebElementChrome(className: buildLabelClassName()),
    iconStyle: iconStyle,
  );
}
