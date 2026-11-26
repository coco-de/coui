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

/// Paint-ready chrome for Web `Tag`.
///
/// DOM shape:
///
/// ```text
/// root (<span>)
///   └─ child                         // the label, normally a `Text`
/// ```
///
/// `tag.dart` reads the root's `className` + `inlineStyles` straight from
/// `resolved.root` — no merge / fallback / conversion in the widget body.
/// A tag is display only, so there is no scoped `<style>` block: no state
/// layer, no focus ring.
class ResolvedTag implements WebResolvedChrome {
  /// Creates a [ResolvedTag].
  const ResolvedTag({required this.root});

  /// Paint-ready chrome for the outermost `<span>` element.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTag] for the given [context].
///
/// Merge chain:
///
/// ```text
/// defaultsBySize[size] → defaultsByEmphasis[emphasis]
///   → CoreTagStyle.resting(color, emphasis)
///   → theme.coreComponentTheme.tag.style
///   → theme.coreComponentTheme.tag.colorStyles[color]
///   → theme.coreComponentTheme.tag.emphasisStyles[emphasis]
///   → widget.tagStyle
/// ```
///
/// The semantic [color], [emphasis] and [size] are widget props — they
/// pick the rows of the Core tables here. The theme cannot override them
/// (semantic identifiers are widget-only).
ResolvedTag resolveTag(
  BuildContext context, {
  required CoreCategoryColor color,
  required CoreTagEmphasis emphasis,
  required CoreTagSize size,
  CoreTagStyle? tagStyle,
}) {
  final tagTheme = context.theme.coreComponentTheme?.tag;
  final merged = resolveStyleChain(const CoreTagStyle(), [
    tagTheme?.style,
    tagTheme?.colorStyles?[color],
    tagTheme?.emphasisStyles?[emphasis],
    tagStyle,
  ]);
  final chrome = CoreTagStyle.defaultsBySize[size]!
      .merge(CoreTagStyle.defaultsByEmphasis[emphasis])
      .merge(CoreTagStyle.resting(color, emphasis));

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final backgroundColor = merged.backgroundColor ?? chrome.backgroundColor!;
  final foregroundColor = merged.foregroundColor ?? chrome.foregroundColor!;
  // Stated by the hue for `subtle` only; with no colour no border is drawn,
  // at any width.
  final borderColor = merged.borderColor ?? chrome.borderColor;
  final borderWidth = merged.borderWidth ?? CoreTagStyle.defaultBorderWidth;
  final borderRadius = (merged.borderRadius ?? chrome.borderRadius!).toValue();
  final padding = merged.padding ?? chrome.padding!;
  final minHeight = merged.minHeight ?? chrome.minHeight!;
  // Whether this tag paints a fill. The surface material is a statement
  // about a filled box, so a caller-made transparent fill carries no
  // marker. The Flutter twin withholds the material on the same answer.
  final hasFill = surfacePaintsFill(backgroundColor);

  // ─── Stage 2 — EMIT (Web, theme-free) ─────────────────
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    backgroundColor,
    .background,
  );
  final foregroundEmit = emitColor(
    merged.foregroundColor,
    foregroundColor,
    .text,
  );
  final borderEmit = emitColorOrInherit(borderColor, .border);
  // The step's role with the emphasis's weight laid over it (600 for bold)
  // — a `text-{role}` class plus the weight inline.
  final labelEmit = emitTypography(merged.labelStyle, chrome.labelStyle!);

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<span>` Tailwind className.
  ///
  /// The height rides the size scale (`--coui-size-*`) while it is the
  /// step's own value; an override goes inline instead (class XOR inline).
  /// These are the tag's own rows, not control rows, so no density moves
  /// them — the Flutter twin does not move them either.
  String buildRootClassName() {
    final classList = [
      // Centred on both axes and kept on one line: the box is at least the
      // step tall, so a label shorter than it sits in its middle — the
      // Flutter twin's `Row` centres the same way and never wraps.
      '${WebLayout.inlineFlexCenterNoWrap} select-none',
      // States no shadow of its own, so it takes the style's — the Flutter
      // twin reads the same cast. No-op under every style that injects none.
      kControlShadowRestMarker,
      // Marks this element as a component surface — restated here because
      // Tag can't compose `OutlinedContainer` (its root is an inline
      // `<span>`). Only on a tag that paints a fill.
      if (hasFill) ...webSurfaceMarkerFor(.content),
      labelEmit.className,
      if (merged.minHeight == null) 'min-h-${minHeight.tailwindSize}',
      backgroundEmit.className,
      if (merged.labelStyle?.color == null) foregroundEmit.className,
      borderEmit.className,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the root `<span>` inline-CSS bundle — padding, the corner,
  /// the border width where a border colour resolved, an overridden
  /// height, and the inline colour / typography fragments the emit family
  /// produced (raw overrides only).
  Styles buildRootInlineStyles() {
    return Styles(
      raw: {
        // Horizontal only by default: the height is the step's.
        ...padding.toLogicalDeclarations('padding'),
        if (merged.minHeight != null)
          'min-height': '${minHeight / kRemDivisor}rem',
        'border-radius': borderRadius,
        // Only where a border colour resolved — a width with no colour
        // would paint the preflight's default border colour, which the
        // Flutter twin (no colour → no border) never draws. The preflight's
        // `box-sizing: border-box` keeps the line inside the box's height.
        if (borderColor != null) 'border-width': strokeWidthCss(borderWidth),
        if (borderColor != null && hasFill)
          ...surfaceBleedVar(strokeWidthCss(borderWidth)),
        ...?backgroundEmit.inline,
        if (merged.labelStyle?.color == null) ...?foregroundEmit.inline,
        ...?borderEmit.inline,
        ...?labelEmit.inline,
        // The marker's other half — a preset restates this fill at a lower
        // alpha and cannot know which token the tag chose.
        if (hasFill) ...surfaceFillVar(backgroundColor),
      },
    );
  }

  return ResolvedTag(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}
