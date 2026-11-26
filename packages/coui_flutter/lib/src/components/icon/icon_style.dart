import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Icon`.
///
/// Widget tree (`icon.dart` decides which branch renders):
///
/// ```text
/// SvgPicture.string (svgString, width / height = size,
///                    colorFilter = ColorFilter.mode(color, srcIn))
///   └─ (while the glyph data loads: svgString is null)
///        SizedBox.square (dimension = size)
/// ```
///
/// `Icon` is a leaf component — it paints the glyph itself rather than
/// delegating to a child CoUI widget, so [ResolvedIcon] carries plain
/// Flutter paint-ready values (`double` / `Color` / `String`) instead of
/// nested `CoreXxxStyle` slots. [size] and [color] are non-null: the resolver
/// folds the merge chain, the ambient [IconTheme], and the
/// [CoreIconStyle.defaultColor] fallback so the widget never handles `null`.
///
/// ## Stroke
///
/// A Lucide glyph's stroke is rewritten from the glyph's authored weight to
/// the icon stroke rule (`CoreIconStroke`) when the resolver builds
/// [svgString]. The rule is a function of the size *before* the theme
/// scaling, so the resolver reads it there and hands the widget the finished
/// SVG: the widget lays the box out at [size] and paints the string, nothing
/// else. The scaled box then scales the stroke with it.
///
/// The rule is stated in token px so a glyph keeps one weight on every device
/// (a phone's 1.25× scaling is a screen-wide magnification, not a different
/// icon size).
class ResolvedIcon {
  /// Creates a [ResolvedIcon].
  const ResolvedIcon({
    required this.size,
    required this.color,
    required this.svgString,
  });

  /// Effective icon size in logical pixels (square width / height), theme
  /// scaling applied.
  ///
  /// Merge chain → ambient [IconTheme] size → [CoreIconStyle.defaultSize],
  /// times the theme scaling.
  final double size;

  /// Effective icon colour — already converted from [CoreColor] to a
  /// Flutter [Color] through `scheme.resolve(...).toValue()`.
  ///
  /// Merge chain colour → ambient [IconTheme] colour →
  /// [CoreIconStyle.defaultColor]. The widget feeds it to
  /// `ColorFilter.mode(color, srcIn)`.
  final Color color;

  /// The finished SVG document the widget paints: the glyph body with its
  /// Lucide stroke rewritten (`CoreIconStroke.apply`), its ids made unique
  /// (`replaceIDs`) and its box set to [size] (`buildSvgString`).
  ///
  /// `null` while the glyph data has not loaded — the widget then reserves
  /// the [size] square and paints nothing.
  final String? svgString;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedIcon] for the given [context].
///
/// Single entry point — reads [CoreIconTheme] from
/// `Theme.of(context).coreComponentTheme` and the ambient [IconTheme] itself
/// so `icon.dart` never touches `coreComponentTheme` / `IconTheme` /
/// `colorScheme` directly, and builds the SVG string from the glyph [data]
/// the widget has loaded for [icon] (`null` while it has not).
///
/// Merge chain (mirrors the Web `resolveIconStyle` precedence so the two
/// platforms pick the same size / colour):
///
/// ```text
/// design-system default (CoreIconStyle.defaultSize / .defaultColor)
///   → theme.coreComponentTheme.icon.style
///   → widget.iconStyle
///   (+ ambient IconTheme as the size / colour fallback)
/// ```
ResolvedIcon resolveIcon(
  BuildContext context, {
  required IconName icon,
  required IconSvgData? data,
  required CoreIconStyle? widgetStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final iconTheme = theme.coreComponentTheme?.icon;
  final scheme = theme.colorScheme;
  final ambient = IconTheme.of(context);

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreIconStyle(), [
    iconTheme?.style,
    widgetStyle,
  ]);

  // ─── Resolved paint-ready values ──────────────────────
  // Size — merge chain wins, else the ambient `IconTheme` size, else the
  // design-system default. `tokenSize` is that choice before the scaling:
  // the stroke rule reads it, because the rule is stated in token px.
  // `* scaling` is Stage2 EMIT (produces the paint-ready scaled value), so
  // it stays in the local var, not the return literal.
  final tokenSize = merged.size ?? ambient.size ?? CoreIconStyle.defaultSize;
  final size = tokenSize * scaling;

  // Colour — the colour decision is a CoreColor that may still be an
  // unresolved token, so it routes through the scheme resolve step before
  // conversion. A raw argb read would surface transparent black for
  // unresolved tokens, and a standalone conversion would pin the
  // light-mode value and ignore dark mode (#1601). Precedence: merge-chain
  // colour → ambient IconTheme colour → the design-system default
  // (`CoreIconStyle.defaultColor` = onSurface token) — the single Core
  // source so the platform resolver never reads `scheme.onSurface`
  // directly. `scheme.resolve(...)` materialises the token for the active
  // brightness. Matches the Web resolver's colour-then-ambient fallback
  // precedence.
  final mergedColor = merged.color;
  final color = mergedColor != null
      ? scheme.resolve(mergedColor).toValue()
      : (ambient.color ?? scheme.resolve(CoreIconStyle.defaultColor).toValue());

  // SVG document — the stroke rule is fed the token size (the glyph's own
  // viewBox width is what it divides by), then ids are made unique and the
  // box is set to the scaled size. Without the glyph data there is nothing
  // to paint yet.
  final svgString = data == null
      ? null
      : buildSvgString(
          body: replaceIDs(
            CoreIconStroke.apply(
              prefix: icon.prefix,
              body: data.body,
              tokenSize: tokenSize,
              viewBox: data.width,
            ),
          ),
          width: data.width,
          height: data.height,
          size: size,
        );

  return ResolvedIcon(
    size: size,
    color: color,
    svgString: svgString,
  );
}
