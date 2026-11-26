/// Style slot single entry point for `Diff`.
///
/// [ResolvedDiff] implements [WebResolvedChrome] and every chrome field is
/// a paint-ready [WebElementChrome] slot. The per-frame `--co-diff-pos` CSS
/// variable is baked into `root.inlineStyles` by the single [resolveDiff]
/// entry point (runtime `currentPosition` flows in as a resolver argument).
/// Runtime tuning values consumed by widget state init / event handlers
/// (`initialPosition`, `keyboardStep`, `keyboardPageStep`) are NOT carried
/// on the resolved chrome — they are behavioural identifiers read by the
/// stateful position seed / keyboard handler, exposed via the separate
/// [resolveDiffTuning] entry point.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Diff`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                          // relative, aspect-ratio, no clip
///   ├─ clip (<div>)                     // absolute inset-0, overflow-hidden, rounded
///   │    ├─ afterLayer (<div>)          // absolute inset-0, holds widget.after
///   │    ├─ beforeLayer (<div>)         // absolute inset-0, clip-path reveals left
///   │    ├─ resizer (<div>)             // the split line, pointer-events-none
///   │    ├─ beforeLabelHost (<div>)     // top-left chip, optional
///   │    ├─ afterLabelHost (<div>)      // top-right chip, optional
///   │    └─ edge (<div>)                // inset frame edge, optional
///   └─ handleStrip (<div>)              // full-height grab area, interactive only
///        └─ handleHost (FocusOutline)   // the ring, scales while held
///             └─ handleDisc (<div>)     // the round handle
///                  └─ Icon              // handleIconStyle
/// ```
///
/// The handle sits outside [clip] so its disc and ring are whole at both
/// ends of the frame.
///
/// All slot chromes are non-null — `diff.dart` reads
/// `resolved.<slot>.className` / `resolved.<slot>.inlineStyles` straight
/// off, and decides which optional slots render from the widget's own
/// props (`interactive`, the labels) and from [edge] (null when the edge
/// width is zero, a value the resolver settles).
class ResolvedDiff implements WebResolvedChrome {
  /// Creates a [ResolvedDiff].
  const ResolvedDiff({
    required this.root,
    required this.clip,
    required this.afterLayer,
    required this.beforeLayer,
    required this.resizer,
    required this.beforeLabelHost,
    required this.afterLabelHost,
    required this.edge,
    required this.handleStrip,
    required this.handleHost,
    required this.handleDisc,
    required this.handleIconStyle,
    required this.labelBadgeStyle,
    required this.focusOutlineStyle,
  });

  /// Paint-ready chrome for the outer comparison-frame `<div>` — relative
  /// position, full width, select-none, the browser's own focus outline
  /// off (the ring is the handle's), plus `aspect-ratio` and the per-frame
  /// `--co-diff-pos` variable inline.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the clipping layer — fills the root, clips
  /// everything it holds to the frame's rounded shape.
  final WebElementChrome clip;

  /// Paint-ready chrome for the bottom (after-content) layer `<div>` —
  /// `absolute inset-0`. Its child is `widget.after`.
  final WebElementChrome afterLayer;

  /// Paint-ready chrome for the top (before-content) layer `<div>` —
  /// `absolute inset-0` plus a `clip-path` that reads `--co-diff-pos` to
  /// reveal only the left side.
  final WebElementChrome beforeLayer;

  /// Paint-ready chrome for the split line — absolute column on the
  /// split, colour class (or inline) plus width and cast inline. It takes
  /// no pointer: the strip does.
  final WebElementChrome resizer;

  /// Paint-ready chrome for the `before` label's host — absolute, in from
  /// the top-left corner by the label inset, no pointer.
  final WebElementChrome beforeLabelHost;

  /// Paint-ready chrome for the `after` label's host — absolute, in from
  /// the top-right corner by the label inset, no pointer.
  final WebElementChrome afterLabelHost;

  /// Paint-ready chrome for the frame edge — an inset overlay that draws
  /// the border over the content without taking room. `null` when the
  /// edge width is zero.
  final WebElementChrome? edge;

  /// Paint-ready chrome for the handle's strip — absolute full-height
  /// column on the split. Publishes the handle's three casts, the held
  /// scale and the clock as custom properties for the shared `ThemeConfig`
  /// rule.
  final WebElementChrome handleStrip;

  /// Paint-ready chrome for the `FocusOutline` host that wraps the disc —
  /// exactly the disc's box, so the ring wraps the disc.
  final WebElementChrome handleHost;

  /// Paint-ready chrome for the handle disc — fill, edge and radius; its
  /// cast comes from the shared rule, by marker.
  final WebElementChrome handleDisc;

  /// Raw-forwarded glyph style for the handle's `Icon` (the icon resolver
  /// does its own scaling).
  final CoreIconStyle handleIconStyle;

  /// Raw-forwarded style for each label's `Badge`.
  final CoreBadgeStyle labelBadgeStyle;

  /// Raw-forwarded focus ring for the handle's `FocusOutline`.
  final CoreFocusOutlineStyle focusOutlineStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDiff] for `Diff`.
///
/// Merge chain:
///
/// ```text
/// CoreDiffStyle.defaultX
///   → CoreDiffTheme.style                           // 프로젝트 공통
///   → component.diffStyle                           // 인스턴스별
/// ```
///
/// Token colours emit as classes (dark-mode reactive); raw / arbitrary
/// overrides emit inline. Border radius is always inline
/// (`(merged ?? default).toValue()`) — never a `rounded-*` class.
///
/// [currentPosition] is the per-frame split position (`[0, 1]`) — the
/// resolver bakes it into `root.inlineStyles` as `--co-diff-pos` so the
/// before layer's clip-path, the line and the handle strip all pick it up.
/// Pass `null` on the first build (before any drag or key state) — the
/// resolver falls back to the same merged `initialPosition` seed that
/// [resolveDiffTuning] exposes to the widget (identical merge chain +
/// clamp) automatically.
ResolvedDiff resolveDiff(
  BuildContext context, {
  required double? currentPosition,
  CoreDiffStyle? diffStyle,
}) {
  final compTheme = context.theme.coreComponentTheme?.diff;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDiffStyle(), [
    compTheme?.style,
    diffStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final borderRadius =
      (merged.borderRadius ?? CoreDiffStyle.defaultBorderRadius).toValue();

  // Frame edge.
  final borderWidth = merged.borderWidth ?? CoreDiffStyle.defaultBorderWidth;
  final borderColor = emitColor(
    merged.borderColor,
    CoreDiffStyle.defaultBorderColor,
    .border,
  );

  // Split line — colour through the emit family, width inline, cast
  // through `emitShadow` so a scale step reads `var(--shadow-<step>)` and
  // the surface style / dark strength reach it.
  final resizerColor = emitColor(
    merged.resizerColor,
    CoreDiffStyle.defaultResizerColor,
    .background,
  );
  final resizerWidthPx =
      merged.resizerWidth ?? CoreDiffStyle.defaultResizerWidth;
  final resizerWidthCss = '${resizerWidthPx / kRemDivisor}rem';
  final resizerShadow = emitShadow(
    merged.resizerShadow ?? CoreDiffStyle.defaultResizerShadow,
    base: kShadowVariableBase,
  );

  // Handle.
  final handleSizePx = merged.handleSize ?? CoreDiffStyle.defaultHandleSize;
  final handleHitPx =
      merged.handleHitSize ?? CoreDiffStyle.defaultHandleHitSize;
  final handleColor = emitColor(
    merged.handleColor,
    CoreDiffStyle.defaultHandleColor,
    .background,
  );
  final handleBorderColor = emitColor(
    merged.handleBorderColor,
    CoreDiffStyle.defaultHandleBorderColor,
    .border,
  );
  final handleBorderWidth =
      merged.handleBorderWidth ?? CoreDiffStyle.defaultHandleBorderWidth;
  final handleShadow = emitShadow(
    merged.handleShadow ?? CoreDiffStyle.defaultHandleShadow,
    base: kShadowVariableBase,
  );
  final handleHoverShadow = emitShadow(
    merged.handleHoverShadow ?? CoreDiffStyle.defaultHandleHoverShadow,
    base: kShadowVariableBase,
  );
  final handlePressedShadow = emitShadow(
    merged.handlePressedShadow ?? CoreDiffStyle.defaultHandlePressedShadow,
    base: kShadowVariableBase,
  );
  final handlePressedScale =
      merged.handlePressedScale ?? CoreDiffStyle.defaultHandlePressedScale;
  final handleDuration = durationMsCss(
    (merged.handleTransitionDuration ??
            CoreDiffStyle.defaultHandleTransitionDuration)
        .inMilliseconds,
  );

  // Nested slots — raw-forwarded, the child resolvers emit their own.
  final handleIconStyle = CoreDiffStyle.defaultHandleIconStyle.merge(
    merged.handleIconStyle,
  );
  final labelBadgeStyle = CoreDiffStyle.defaultLabelBadgeStyle.merge(
    merged.labelBadgeStyle,
  );
  final focusOutlineStyle = CoreDiffStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );

  // Label placement.
  final labelInset = merged.labelInset ?? CoreDiffStyle.defaultLabelInset;

  // Geometry.
  final aspectRatio = merged.aspectRatio ?? CoreDiffStyle.defaultAspectRatio;

  // Per-frame effective split position consumed by the chrome CSS
  // variable. Caller passes null on the first build (no drag yet) so we
  // fall back to the same `initialPosition` seed that [resolveDiffTuning]
  // exposes to the widget; both the chrome and the widget state stay in
  // sync (identical merge chain + clamp).
  final initialPosition =
      (merged.initialPosition ?? CoreDiffStyle.defaultInitialPosition).clamp(
        0.0,
        1.0,
      );
  final clampedPosition = (currentPosition ?? initialPosition).clamp(0.0, 1.0);

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer container `<div>` Tailwind className — relative
  /// position so children can absolutely position, full width, select-none
  /// for the drag interaction, `outline-none` because the root takes focus
  /// but the ring belongs to the handle.
  String buildRootClassName() =>
      '${WebLayout.relative} ${WebLayout.wFull} select-none outline-none';

  /// Composes the outer container `<div>` inline CSS — `aspect-ratio`
  /// (always inline because Tailwind would require an arbitrary value) and
  /// the per-frame `--co-diff-pos` CSS variable.
  Styles buildRootInlineStyles() => .new(
    raw: {
      'aspect-ratio': '$aspectRatio',
      '--co-diff-pos': '${clampedPosition * kPercentScale}%',
    },
  );

  /// Composes the clipping layer's className — fills the root and clips.
  String buildClipClassName() =>
      '${WebLayout.absoluteFull} ${WebLayout.overflowHidden}';

  /// Composes the clipping layer's inline CSS — the rounded shape.
  Styles buildClipInlineStyles() => .new(raw: {'border-radius': borderRadius});

  /// Composes the split line's Tailwind className — absolute, top to
  /// bottom, no pointer, the emit-family background class (empty when the
  /// colour goes inline).
  String buildResizerClassName() => <String>[
    '${WebLayout.absolute} ${WebLayout.topZero} ${WebLayout.bottomZero}',
    'pointer-events-none',
    if (resizerColor.className.isNotEmpty) resizerColor.className,
  ].join(' ');

  /// Composes the split line's inline CSS — on the split via the shared CSS
  /// variable, the resolved width, the cast, and the emit-family colour
  /// inline when the override is arbitrary.
  Styles buildResizerInlineStyles() => .new(
    raw: {
      'left': 'var(--co-diff-pos)',
      'transform': 'translateX(-50%)',
      'width': resizerWidthCss,
      'box-shadow': resizerShadow,
      ...?resizerColor.inline,
    },
  );

  /// Composes a label host's className — absolute, flex, no pointer. The
  /// badge is inline-level: in a block host it would sit on the host's text
  /// baseline and land below the label inset.
  const labelHostClassName =
      '${WebLayout.absolute} ${WebLayout.flex} pointer-events-none';

  /// Composes the before-layer `<div>` inline CSS — `clip-path` reads the
  /// shared CSS variable to reveal only the portion left of the current
  /// split position.
  Styles buildBeforeLayerInlineStyles() => const .new(
    raw: {'clip-path': 'inset(0 calc(100% - var(--co-diff-pos)) 0 0)'},
  );

  /// Composes the frame edge's className — an overlay that fills the clip
  /// and takes no pointer, plus the emit-family border colour class.
  String buildEdgeClassName() => <String>[
    '${WebLayout.absoluteFull} pointer-events-none',
    if (borderColor.className.isNotEmpty) borderColor.className,
  ].join(' ');

  /// Composes the frame edge's inline CSS — the border drawn inside the
  /// box (`border-box`, so it takes from the overlay and never from the
  /// frame), the rounded shape, and the emit-family colour inline when the
  /// override is arbitrary.
  Styles buildEdgeInlineStyles() => .new(
    raw: {
      'box-sizing': 'border-box',
      'border-style': 'solid',
      'border-width': strokeWidthCss(borderWidth),
      'border-radius': borderRadius,
      ...?borderColor.inline,
    },
  );

  /// Composes the handle strip's className — the full-height column on the
  /// split, the disc centred in it, the column-resize cursor, and the
  /// marker the shared rule's hover reads.
  String buildHandleStripClassName() => <String>[
    '${WebLayout.absolute} ${WebLayout.topZero} ${WebLayout.bottomZero}',
    '${WebLayout.flex} ${WebLayout.itemsCenter} ${WebLayout.justifyCenter}',
    'cursor-col-resize',
    kDiffHandleStripMarker,
  ].join(' ');

  /// Composes the handle strip's inline CSS — on the split, the grab
  /// width, `touch-action: pan-y` (a vertical swipe stays the page's while
  /// a horizontal one reaches the pointer events), and the custom
  /// properties the shared rule reads. The width is a size like the disc's,
  /// not a gap, so it is pinned: a spacing variable would let density move
  /// the grab area, which Flutter keeps as authored.
  Styles buildHandleStripInlineStyles() => .new(
    raw: {
      'left': 'var(--co-diff-pos)',
      'transform': 'translateX(-50%)',
      'width': pinnedLengthCss(handleHitPx),
      'touch-action': 'pan-y',
      kDiffHandleShadowVar: handleShadow,
      kDiffHandleHoverShadowVar: handleHoverShadow,
      kDiffHandlePressedShadowVar: handlePressedShadow,
      kDiffHandlePressedScaleVar: '$handlePressedScale',
      kDiffHandleDurationVar: handleDuration,
    },
  );

  /// Composes the focus-ring host's inline CSS — exactly the disc's box.
  Styles buildHandleHostInlineStyles() => .new(
    raw: {
      'width': '${handleSizePx / kRemDivisor}rem',
      'height': '${handleSizePx / kRemDivisor}rem',
      'flex': 'none',
    },
  );

  /// Composes the handle disc's className — fills the host, centres the
  /// glyph, the emit-family fill / edge classes, and the marker whose cast
  /// the shared rule states.
  String buildHandleDiscClassName() => <String>[
    '${WebLayout.wFull} ${WebLayout.hFull}',
    '${WebLayout.flex} ${WebLayout.itemsCenter} ${WebLayout.justifyCenter}',
    kDiffHandleDiscMarker,
    if (handleColor.className.isNotEmpty) handleColor.className,
    if (handleBorderColor.className.isNotEmpty) handleBorderColor.className,
  ].join(' ');

  /// Composes the handle disc's inline CSS — a circle (`50%`, the Flutter
  /// twin's `BoxShape.circle`: the handle is round by definition, so there
  /// is no radius field to state), the edge drawn inside, and the emit-family
  /// colours inline for arbitrary overrides.
  Styles buildHandleDiscInlineStyles() => .new(
    raw: {
      'box-sizing': 'border-box',
      'border-style': 'solid',
      'border-width': strokeWidthCss(handleBorderWidth),
      'border-radius': '50%',
      ...?handleColor.inline,
      ...?handleBorderColor.inline,
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedDiff(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    clip: WebElementChrome(
      className: buildClipClassName(),
      inlineStyles: buildClipInlineStyles(),
    ),
    afterLayer: const WebElementChrome(className: WebLayout.absoluteFull),
    beforeLayer: WebElementChrome(
      className: WebLayout.absoluteFull,
      inlineStyles: buildBeforeLayerInlineStyles(),
    ),
    resizer: WebElementChrome(
      className: buildResizerClassName(),
      inlineStyles: buildResizerInlineStyles(),
    ),
    beforeLabelHost: WebElementChrome(
      className: labelHostClassName,
      inlineStyles: .new(
        raw: {
          'top': spaceCss(labelInset.top),
          'left': spaceCss(labelInset.left),
        },
      ),
    ),
    afterLabelHost: WebElementChrome(
      className: labelHostClassName,
      inlineStyles: .new(
        raw: {
          'top': spaceCss(labelInset.top),
          'right': spaceCss(labelInset.right),
        },
      ),
    ),
    edge: borderWidth > 0
        ? WebElementChrome(
            className: buildEdgeClassName(),
            inlineStyles: buildEdgeInlineStyles(),
          )
        : null,
    handleStrip: WebElementChrome(
      className: buildHandleStripClassName(),
      inlineStyles: buildHandleStripInlineStyles(),
    ),
    handleHost: WebElementChrome(
      className: kDiffHandleMarker,
      inlineStyles: buildHandleHostInlineStyles(),
    ),
    handleDisc: WebElementChrome(
      className: buildHandleDiscClassName(),
      inlineStyles: buildHandleDiscInlineStyles(),
    ),
    handleIconStyle: handleIconStyle,
    labelBadgeStyle: labelBadgeStyle,
    focusOutlineStyle: focusOutlineStyle,
  );
}

/// Resolves the behavioural runtime-tuning seeds for `Diff` — the
/// effective initial split position (`[0, 1]`, widget state seed), the
/// arrow-key step and the Page Up / Page Down step (`[0, 1]` units,
/// keyboard handler), consumed by the stateful position seed / keyboard
/// handler (between builds), not paint chrome.
///
/// Walks the same merge chain as [resolveDiff]
/// (design-system default → `CoreDiffTheme.style` → `widget.diffStyle`),
/// with identical fallback + clamp so the resolved chrome's `--co-diff-pos`
/// first-build seed and the widget's `_position` seed stay in sync. Kept as
/// a separate entry point so [ResolvedDiff] stays pure paint-ready chrome.
({double initialPosition, double keyboardStep, double keyboardPageStep})
resolveDiffTuning(
  BuildContext context, {
  CoreDiffStyle? diffStyle,
}) {
  final compTheme = context.theme.coreComponentTheme?.diff;
  final merged = resolveStyleChain(const CoreDiffStyle(), [
    compTheme?.style,
    diffStyle,
  ]);
  return (
    initialPosition:
        (merged.initialPosition ?? CoreDiffStyle.defaultInitialPosition).clamp(
          0.0,
          1.0,
        ),
    keyboardStep: merged.keyboardStep ?? CoreDiffStyle.defaultKeyboardStep,
    keyboardPageStep:
        merged.keyboardPageStep ?? CoreDiffStyle.defaultKeyboardPageStep,
  );
}
