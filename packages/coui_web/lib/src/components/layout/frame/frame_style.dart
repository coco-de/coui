import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/dashed_overlay.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Frame`.
///
/// DOM shape:
///
/// ```text
/// root (<tag>)                                 // outer frame container (div / section / …)
///   └─ child | …children                       // caller-supplied content
/// ```
///
/// `co_frame.dart` reads `resolved.root.className` + `inlineStyles`
/// straight into `Component.element(...)` — no merge / fallback /
/// conversion in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
///
/// `Frame` does not host any child unified widget, so no nested
/// `CoreXxxStyle` slot is forwarded — the resolver collapses every
/// chrome value into the single [root] [WebElementChrome] pair.
class ResolvedFrame implements WebResolvedChrome {
  /// Creates a [ResolvedFrame].
  const ResolvedFrame({
    required this.root,
    required this.dashOverlay,
    required this.dashRect,
  });

  /// Paint-ready chrome for the outer frame element — full Tailwind
  /// className plus the inline-CSS bundle composed by the closure-local
  /// builders inside [resolveFrame].
  @override
  final WebElementChrome root;

  /// Dashed/dotted-border `<svg>` overlay — carries the border colour
  /// as a text-colour class (the `<rect>` strokes with `currentColor`);
  /// the frame's arbitrary content keeps its own inherited colour.
  /// `null` when the border isn't dashed/dotted (design-optional slot —
  /// the widget mounts the overlay only when non-null, collapsing the
  /// old separate `dashPatterned` bool into this slot's own nullness).
  final WebElementChrome? dashOverlay;

  /// The overlay's `<rect>` — geometry / stroke pattern as CSS
  /// properties (shared `dashed_overlay.dart` chrome). `null` alongside
  /// [dashOverlay].
  final WebElementChrome? dashRect;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFrame] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.frame.style
///   → widget.frameStyle
///   → widget chrome props (backgroundColor, borderColor, …)
/// ```
///
/// The contract is intentionally flat (Figma 1:1 inspect mapping), so
/// every chrome-shaping widget param feeds in here and the resolver
/// folds them into the `root` [WebElementChrome] (className + inline
/// styles) once.
ResolvedFrame resolveFrame(
  BuildContext context, {
  required CoreClipBehavior clipBehavior,
  CoreColor? backgroundColor,
  CoreColor? borderColor,
  double? borderWidth,
  CoreFrameBorderStyle? borderStyle,
  CoreBorderRadius? borderRadius,
  CoreEdgeInsets? padding,
  CoreFrameElevation? elevation,
  Duration? duration,
  CoreFrameStyle? frameStyle,
  CoreFrameDirection? direction,
  double? gap,
  CoreMainAxisAlignment? mainAxisAlignment,
  CoreCrossAxisAlignment? crossAxisAlignment,
  CoreAlignment? alignment,
  double? width,
  double? height,
  double? minWidth,
  double? minHeight,
  double? maxWidth,
  double? maxHeight,
  int? flex,
  CoreFlexFit? fit,
  CoreEdgeInsets? margin,
  CoreGradient? gradient,
  CoreImageSource? backgroundImage,
  List<CoreShadowLayer>? boxShadow,
  List<CoreShadowLayer>? innerShadow,
  double? layerBlur,
  double? backdropBlur,
  double? opacity,
  String? transform,
  CoreAlignment? transformAlignment,
  CoreCursor? cursor,
}) {
  final frameTheme = context.theme.coreComponentTheme?.frame;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreFrameStyle(), [
    frameTheme?.style,
    frameStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly). Widget-level flat props win over the style chain so
  // the Figma "Inspect" surface stays 1:1.
  final effectiveBackground = (backgroundColor ?? merged.backgroundColor)
      ?.toValue();
  final effectiveBorderColor = (borderColor ?? merged.borderColor)?.toValue();
  final effectiveBorderWidth = borderWidth ?? merged.borderWidth;
  final effectiveBorderStyle =
      borderStyle ?? merged.borderStyle ?? CoreFrameStyle.defaultBorderStyle;
  final effectiveBorderRadius = borderRadius ?? merged.borderRadius;
  // A border renders only when the caller supplies a colour — the same
  // opt-in gate as the Flutter widget (`resolvedBorderColor != null`),
  // so a plain Frame stays borderless on both platforms.
  // Dashed/dotted borders render through the SVG overlay — the CSS
  // `border-style` pattern is engine-defined (differs per browser) and
  // untunable, while the overlay carries the Core dash tokens.
  final dashPatterned =
      effectiveBorderColor != null &&
      (effectiveBorderStyle == .dashed || effectiveBorderStyle == .dotted);
  final drawsSolidBorder =
      effectiveBorderColor != null &&
      !dashPatterned &&
      effectiveBorderStyle != .none;
  final dashLength = merged.dashLength ?? CoreFrameStyle.defaultDashLength;
  final dashSpacing = merged.dashSpacing ?? CoreFrameStyle.defaultDashSpacing;
  final effectivePadding = padding ?? merged.padding;
  final effectiveElevation =
      elevation ?? merged.elevation ?? CoreFrameStyle.defaultElevation;
  // The default is the constructor's omitted-value sentinel, as on
  // Flutter. An explicitly different flat policy still wins over style.
  final effectiveClip = clipBehavior == CoreFrameStyle.defaultClipBehavior
      ? (merged.clipBehavior ?? clipBehavior)
      : clipBehavior;
  final effectiveDurationMs =
      (duration ?? merged.duration ?? CoreFrameStyle.defaultDuration)
          .inMilliseconds;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer element's Tailwind className — flex/wrap
  /// layout, border style + default border-colour token (when no
  /// inline override), and the elevation shadow preset. Per-instance
  /// overrides (gradients, blurs, transforms, explicit colours) ship
  /// via inline CSS through [buildRootInlineStyles].
  String buildRootClassName() {
    final classes = <String>[];

    // Flex / wrap layout class (Tailwind).
    if (direction != null) {
      classes.add(_directionClass(direction));
      // Children that did not opt into flex keep their intrinsic size
      // — Flutter `Row` / `Column` lay out non-`Flexible` children at
      // their natural extent and overflow a too-narrow parent rather
      // than squeezing them. CSS flex items default to
      // `flex-shrink: 1`, so without this a long label wraps and an
      // icon collapses to 0px on Web only. A child `Frame` that sets
      // `flex` emits its own inline `flex-shrink`, which beats this
      // class rule. `wrap` is excluded: Flutter `Wrap` hands each child
      // the run width as its max constraint, so text there does wrap.
      if (direction != .wrap) {
        classes.add(_kChildrenNoShrinkClass);
      }
    }

    // Border — emitted only when the caller opted in with a colour
    // (drawsSolidBorder / dashPatterned both carry that gate).
    if (dashPatterned) {
      // Dash pattern lives on the SVG overlay — anchor it here.
      classes.add(WebLayout.relative);
    } else if (drawsSolidBorder) {
      classes.add('border');
    }

    // Elevation preset (Tailwind shadow utility). Caller-provided
    // [boxShadow] inline overrides the preset.
    if (boxShadow == null) {
      classes.add(switch (effectiveElevation) {
        .none => 'shadow-none',
        .soft => 'shadow-sm',
        .medium => 'shadow-md',
        .strong => 'shadow-lg',
      });
    }

    return classes.join(' ');
  }

  /// Composes the outer element's inline-CSS bundle — per-instance
  /// overrides and fields that have no Tailwind equivalent (gradients,
  /// images, blurs, transforms, etc.).
  Styles buildRootInlineStyles() {
    final raw = <String, String>{
      if (direction != null)
        ..._buildLayout(
          direction: direction,
          gap: gap,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
        ),
    };

    if (alignment != null && direction == null) {
      // Non-flex 9-grid alignment for a single child. CSS grid is the
      // closest analogue to Flutter `Align`.
      raw['display'] = WebLayout.grid;
      raw['place-items'] = _alignmentToPlaceItems(alignment);
    }

    if (width != null) raw['width'] = '${width / kRemDivisor}rem';
    if (height != null) raw['height'] = '${height / kRemDivisor}rem';
    if (minWidth != null) raw['min-width'] = '${minWidth / kRemDivisor}rem';
    if (minHeight != null) {
      raw['min-height'] = '${minHeight / kRemDivisor}rem';
    }
    if (maxWidth != null) raw['max-width'] = '${maxWidth / kRemDivisor}rem';
    if (maxHeight != null) {
      raw['max-height'] = '${maxHeight / kRemDivisor}rem';
    }

    if (flex != null) {
      final fitMode = fit ?? .loose;
      raw['flex-grow'] = '$flex';
      raw['flex-shrink'] = fitMode == .tight ? '0' : '1';
      raw['flex-basis'] = fitMode == .tight ? '0' : 'auto';
    }

    // A dashed / dotted border is drawn by the overlay, but its box is the
    // solid border's box: the Flutter twin keeps `Border.all(width)` in
    // layout with its style switched off and strokes the dashes over it, so
    // the frame is `2 × width` larger on each axis than a borderless one.
    // The width is reserved as padding rather than as a transparent CSS
    // border: the root clips its content (`overflow: hidden`) at its padding
    // box, and the overlay — pulled out over a CSS border — would be clipped
    // away with it, leaving the dashes invisible. With the space in the
    // padding the padding box *is* the border box, the overlay's
    // `inset: 0` covers exactly the box the dashes are stroked in, and the
    // clip passes them.
    final dashReserve = dashPatterned && effectiveBorderWidth != null
        ? strokeWidthCss(effectiveBorderWidth)
        : null;
    if (effectivePadding != null || dashReserve != null) {
      raw['padding'] = _paddingPlus(effectivePadding, dashReserve);
    }
    if (margin != null) raw['margin'] = margin.toValue();

    // CSS lists the front layer first; Native paints the image over its
    // lower fill. Keep each typed value whole: URLs and gradients contain
    // commas of their own.
    final backgroundLayers = [
      if (backgroundImage != null) _imageSourceToCss(backgroundImage),
      if (gradient != null) gradient.toValue(),
    ];
    if (backgroundLayers.isNotEmpty) {
      raw['background-image'] = backgroundLayers.join(', ');
    }
    if (backgroundImage != null) {
      // The gradient keeps its original CSS initial placement. A single
      // image value would repeat onto the gradient and change its fill.
      raw['background-size'] = [
        _imageFitToCss(backgroundImage.fit),
        if (gradient != null) 'auto',
      ].join(', ');
      raw['background-position'] = [
        _alignmentToCss(backgroundImage.alignment),
        if (gradient != null) '0% 0%',
      ].join(', ');
      raw['background-repeat'] = [
        'no-repeat',
        if (gradient != null) 'repeat',
      ].join(', ');
    }
    // Native deliberately excludes solid color when a gradient exists.
    if (gradient == null && effectiveBackground != null) {
      raw['background-color'] = effectiveBackground;
    }

    if (effectiveBorderColor != null && drawsSolidBorder) {
      raw['border-color'] = effectiveBorderColor;
      if (effectiveBorderWidth != null) {
        raw['border-width'] = strokeWidthCss(effectiveBorderWidth);
      }
    }
    if (effectiveBorderRadius != null) {
      raw['border-radius'] = effectiveBorderRadius.toValue();
    }

    // Shadow base tint — single-source `merged.shadowBaseColor ??
    // CoreFrameStyle.defaultShadowBaseColor`. `.toValue()` emits
    // `rgb(var(--coui-shadow))` (theme-free; CSS resolves the token at
    // runtime — no `scheme.resolve`, a Web no-op).
    final shadowBaseColor =
        (merged.shadowBaseColor ?? CoreFrameStyle.defaultShadowBaseColor)
            .toValue();
    if (boxShadow != null) {
      raw['box-shadow'] = emitShadow(boxShadow, base: shadowBaseColor);
    }
    if (innerShadow != null) {
      final innerCss = emitShadow(innerShadow, base: shadowBaseColor);
      final existing = raw['box-shadow'];
      raw['box-shadow'] = existing == null ? innerCss : '$existing, $innerCss';
    }
    if (layerBlur != null && layerBlur > 0) {
      raw['filter'] = 'blur(${layerBlur / kRemDivisor}rem)';
    }
    if (backdropBlur != null && backdropBlur > 0) {
      raw['backdrop-filter'] = 'blur(${backdropBlur / kRemDivisor}rem)';
    }

    if (opacity != null && opacity < 1.0) {
      raw['opacity'] = '$opacity';
    }
    if (transform != null) {
      raw['transform'] = transform;
    }
    if (transformAlignment != null) {
      raw['transform-origin'] = _alignmentToCss(transformAlignment);
    }

    if (cursor != null) {
      raw['cursor'] = _cursorToCss(cursor);
    }

    raw['overflow'] = switch (effectiveClip) {
      .none => 'visible',
      .hardEdge || .antiAlias || .antiAliasWithSaveLayer => WebLayout.hidden,
    };

    if (effectiveDurationMs > 0) {
      // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
      final d = durationMsCss(effectiveDurationMs);
      final e = CoreEasing.move.toVarCss();
      raw['transition'] =
          'background-color $d $e, '
          'border-color $d $e, '
          'border-width $d $e, '
          'border-radius $d $e, '
          'box-shadow $d $e, '
          'opacity $d $e, '
          'transform $d $e, '
          'width $d $e, '
          'height $d $e';
    }

    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  // Dash overlay colour — the caller's border colour rides the `<svg>`
  // as inline `color`; the `<rect>` strokes with `currentColor`. The
  // overlay only renders when [dashPatterned] (colour supplied), so no
  // fallback colour path exists.
  final dashOverlayClassName = dashedOverlaySvgClassName();
  final dashOverlayStyles = effectiveBorderColor == null
      ? dashedOverlaySvgStyles()
      : Styles.combine([
          dashedOverlaySvgStyles(),
          Styles(raw: {'color': effectiveBorderColor}),
        ]);

  return ResolvedFrame(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    dashOverlay: dashPatterned
        ? WebElementChrome(
            className: dashOverlayClassName,
            inlineStyles: dashOverlayStyles,
          )
        : null,
    dashRect: dashPatterned
        ? WebElementChrome(
            className: '',
            inlineStyles: dashedOverlayRectStyles(
              // Same value as the solid-border path above
              // (`strokeWidthCss(effectiveBorderWidth)` at the
              // `border-width` emit) — a dashed border is still
              // stroke-axis-bound, so it must ride the same
              // `--coui-stroke-width-N` variable rather than a literal
              // the neo-brutalism `strokeFloor` preset can't reach.
              strokeWidth: strokeWidthCss(
                effectiveBorderWidth ?? CoreDashedBorder.strokeWidth,
              ),
              dashLength: dashLength,
              dashGap: dashSpacing,
              radius: effectiveBorderRadius?.topLeft ?? 0,
              dotted: effectiveBorderStyle == .dotted,
            ),
          )
        : null,
  );
}

// ═══════════════════════════════════════════════════
// File-private helpers (small pure functions, short signatures)
// ═══════════════════════════════════════════════════

/// The CSS `padding` shorthand for [padding] with [extra] (a CSS length)
/// added to every side; [extra] alone when there is no padding.
///
/// Each side is a `calc()` so a token side (`var(--coui-space-N)`) and the
/// stroke width (`var(--coui-stroke-width-N)`) both stay variables the
/// designer overrides and the presets reach. With no [extra] this is the
/// plain shorthand, byte-identical to what a frame without a dashed border
/// emits.
String _paddingPlus(CoreEdgeInsets? padding, String? extra) {
  if (extra == null) return padding!.toValue();
  if (padding == null) return extra;
  if (padding.isDirectional) {
    // Same rule as `toValue()`: a directional value has no physical
    // shorthand, and flattening it would be right in one locale and wrong
    // in the other.
    throw ArgumentError(
      'A frame with a dashed border needs physical padding: the border '
      'width is added to each physical side.',
    );
  }
  String side(double v) => 'calc(${spaceCss(v)} + $extra)';

  return '${side(padding.top)} ${side(padding.right)} '
      '${side(padding.bottom)} ${side(padding.left)}';
}

/// Half-open percentage divisor for `CoreAlignment` → CSS percentage.
/// Not a design token — pure unit conversion `[-1..1]` → `[0..100]`.
const _kAlignmentToPercent = 100;

/// Direct-child `flex-shrink: 0` on a row / column frame — structural
/// layout vocabulary (no design value), emitted as a Tailwind
/// child-selector variant so it reaches caller-supplied children
/// without the widget touching them. Bare text nodes are anonymous
/// flex items and cannot be selected; CoUI `Text` renders a `<span>`.
const _kChildrenNoShrinkClass = '[&>*]:shrink-0';

/// Builds the flex layout rules (display / flex-direction / wrap / gap
/// / main / cross alignment) for the [direction] flex parent.
Map<String, String> _buildLayout({
  required CoreFrameDirection direction,
  double? gap,
  CoreMainAxisAlignment? mainAxisAlignment,
  CoreCrossAxisAlignment? crossAxisAlignment,
}) {
  return {
    'display': 'flex',
    'flex-direction': switch (direction) {
      .row || .wrap => 'row',
      .rowReverse => 'row-reverse',
      .column => 'column',
      .columnReverse => 'column-reverse',
    },
    if (direction == .wrap) WebLayout.flexWrap: 'wrap',
    if (gap != null) 'gap': spaceCss(gap),
    if (mainAxisAlignment != null)
      'justify-content': _mainAlignToCss(mainAxisAlignment),
    if (crossAxisAlignment != null)
      'align-items': _crossAlignToCss(crossAxisAlignment),
  };
}

/// Maps [CoreFrameDirection] to the Tailwind flex utility prefix.
String _directionClass(CoreFrameDirection d) => switch (d) {
  .row || .rowReverse || .column || .columnReverse => WebLayout.flex,
  .wrap => '${WebLayout.flex} ${WebLayout.flexWrap}',
};

/// Maps [CoreMainAxisAlignment] to the CSS `justify-content` value.
String _mainAlignToCss(CoreMainAxisAlignment a) => switch (a) {
  .start => 'flex-start',
  .end => 'flex-end',
  .center => 'center',
  .spaceBetween => 'space-between',
  .spaceAround => 'space-around',
  .spaceEvenly => 'space-evenly',
};

/// Maps [CoreCrossAxisAlignment] to the CSS `align-items` value.
String _crossAlignToCss(CoreCrossAxisAlignment a) => switch (a) {
  .start => 'flex-start',
  .end => 'flex-end',
  .center => 'center',
  .stretch => 'stretch',
  .baseline => 'baseline',
};

/// Maps [CoreAlignment] to a `<x>% <y>%` percentage pair (background /
/// transform-origin etc.).
String _alignmentToCss(CoreAlignment a) {
  final x = ((a.x + 1) / 2 * _kAlignmentToPercent).clamp(
    0,
    _kAlignmentToPercent,
  );
  final y = ((a.y + 1) / 2 * _kAlignmentToPercent).clamp(
    0,
    _kAlignmentToPercent,
  );
  // Keep whole-percent anchors concise without quantizing authored
  // fractional coordinates. The existing normalized-domain clamp stays.
  String percentage(num value) =>
      '${value == value.toInt() ? value.toInt() : value}%';
  return '${percentage(x)} ${percentage(y)}';
}

/// Maps [CoreAlignment] to the CSS `place-items` keyword pair.
String _alignmentToPlaceItems(CoreAlignment a) {
  final yLabel = a.y < 0 ? 'start' : (a.y > 0 ? 'end' : 'center');
  final xLabel = a.x < 0 ? 'start' : (a.x > 0 ? 'end' : 'center');
  return '$yLabel $xLabel';
}

/// Maps [CoreImageFit] to the CSS `background-size` value.
String _imageFitToCss(CoreImageFit fit) => switch (fit) {
  .cover => 'cover',
  .contain || .scaleDown => 'contain',
  .fill => '100% 100%',
  .none => 'auto',
};

/// Empty CSS `url()` fallback — only reached if both
/// [CoreImageSource.url] and [CoreImageSource.asset] are null, which the
/// named constructors make impossible.
const _kEmptyImageUrl = '';

/// Maps [CoreImageSource] to the CSS `url(...)` value. One of
/// [CoreImageSource.url] / [CoreImageSource.asset] is always set by the
/// named constructors.
String _imageSourceToCss(CoreImageSource s) {
  final url = s.url ?? s.asset ?? _kEmptyImageUrl;
  return 'url("$url")';
}

/// Maps [CoreCursor] to the CSS `cursor` keyword.
String _cursorToCss(CoreCursor c) => switch (c) {
  .basic => 'auto',
  .pointer => 'pointer',
  .text => 'text',
  .grab => 'grab',
  .grabbing => 'grabbing',
  .forbidden => 'not-allowed',
  .resizeColumn => 'col-resize',
  .resizeRow => 'row-resize',
};
