import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/theme_context.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `StarRating`.
///
/// DOM shape:
///
/// ```text
/// FocusOutline (composed component — one ring around the whole group)
///   └─ root (<div role="slider" tabindex>)
///        ├─ stars (<div>)                              // pointer + hover surface
///        │    └─ Star (<svg>) × maxInt                 // filled / half / empty
///        ├─ Gap + value (<span>)                       // showValue only
///        ├─ Gap + count (<span>)                       // showCount only
///        └─ hiddenInput (<input type="hidden">)        // only when name != null
/// ```
///
/// Per-star paint values flow through the `star` slot's inline-CSS
/// bundle: `width` / `height` carry the resolved star size (rem);
/// `--coui-star-active` / `--coui-star-inactive` CSS custom properties
/// carry the resolved active / inactive fill colours (CoreColor → CSS
/// token string via theme-free `.toValue()` → `rgb(var(--coui-X))`).
///
/// `Star` paints every star `<svg>` with the same
/// `resolved.star` chrome and uses `fill="var(--coui-star-active)"` /
/// `fill="var(--coui-star-inactive)"` in the SVG markup so per-state
/// branching (full / half / empty) stays in the widget without
/// re-running any merge.
class ResolvedStarRating implements WebResolvedChrome {
  /// Creates a [ResolvedStarRating].
  const ResolvedStarRating({
    required this.root,
    required this.stars,
    required this.star,
    required this.starFill,
    required this.value,
    required this.count,
    required this.valueGapStyle,
    required this.focusOutlineStyle,
  });

  /// Paint-ready chrome for the stars box — the flex run of stars along
  /// [CoreAxis], with the star gap and the pointer cursor. Pointer and
  /// hover events attach here so the ratio maps over the stars only, not
  /// over the value / count text beside them.
  final WebElementChrome stars;

  /// Paint-ready chrome for the value text ("4.5").
  final WebElementChrome value;

  /// Paint-ready chrome for the count text ("(128)").
  final WebElementChrome count;

  /// Gap between the stars and the value / count text, raw-forwarded to
  /// `Gap`.
  final CoreGapStyle valueGapStyle;

  /// Keyboard focus ring around the whole group, forwarded to the
  /// composed `FocusOutline`.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// Paint-ready chrome for the outermost `<div role="slider">` element.
  ///
  /// The focusable element: an inline flex row holding the stars box and
  /// the optional value / count text. It draws no ring of its own
  /// (`outline-none`) — the composed `FocusOutline` around it does.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for each star `<svg>` element.
  ///
  /// Carries inline `width` / `height` (resolved star size, rem) plus
  /// the `--coui-star-active` / `--coui-star-inactive` CSS custom
  /// properties consumed by the SVG `<path fill="var(--coui-star-*)">`
  /// markup. All stars share the same chrome — `Star` decides
  /// fill paths from per-index state without re-querying tokens.
  final WebElementChrome star;

  /// Paint-ready chrome for the active-fill `clipPath` `<rect>` — the
  /// transition that sweeps the fill when the rating value changes
  /// (mirrors the Flutter `AnimatedValueBuilder` value lerp, same
  /// `CoreDuration` token).
  ///
  /// Which property sweeps depends on the axis, because a vertical star
  /// fills bottom-up: horizontally the widget animates the clip rect's
  /// `width`, vertically it animates a `scaleY` anchored at the rect's
  /// bottom edge (hence the `transform-box` / `transform-origin` rules
  /// carried here — an SVG transform without them would pivot around the
  /// viewBox origin instead of the star).
  final WebElementChrome starFill;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStarRating] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.starRating.style
///   → widget.starRatingStyle
/// ```
///
/// [isInteractive] reflects per-render state (`enabled && onChanged !=
/// null`) so the root chrome's `cursor` flips between `pointer` and
/// `default`. [enabled] alone drives the active/disabled-active colour
/// swap so a controlled-but-disabled rating still looks disabled.
///
/// [direction] is the axis the stars sit on. It picks the root's flex
/// direction and, because a vertical star fills bottom-up rather than
/// left-to-right, also picks which property the fill sweep transitions
/// (see [ResolvedStarRating.starFill]).
ResolvedStarRating resolveStarRating(
  BuildContext context, {
  required bool isInteractive,
  required bool enabled,
  CoreAxis direction = .horizontal,
  CoreComponentSize size = CoreStarRatingStyle.defaultSize,
  CoreStarRatingStyle? starRatingStyle,
}) {
  final srTheme = context.theme.coreComponentTheme?.starRating;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreStarRatingStyle(), [
    srTheme?.style,
    starRatingStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Every value finishes its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly). Colour EMIT is theme-free — `CoreColor.toValue()` emits the
  // token name (`rgb(var(--coui-X))`) and the browser resolves it at
  // runtime (no `scheme.resolve` — Web's scheme is identity).
  final animationDuration =
      (merged.animationDuration ?? CoreStarRatingStyle.defaultAnimationDuration)
          .inMilliseconds;
  final sizeRow = resolveSizeRow(CoreStarRatingStyle.defaultsBySize, size);
  final starSize = merged.starSize ?? sizeRow.starSize!;
  final starSpacing = merged.starSpacing ?? sizeRow.starSpacing!;
  // Active colour — instance override > disabled token > active token.
  // Caller-provided overrides win whether the widget is enabled or
  // disabled (so a disabled colour override applies through the
  // dedicated `disabledActiveColor` field).
  final activeColor =
      (enabled
              ? (merged.activeColor ?? CoreStarRatingStyle.defaultActiveColor)
              : (merged.disabledActiveColor ??
                    CoreStarRatingStyle.defaultDisabledActiveColor))
          .toValue();
  final inactiveColor =
      (enabled
              ? (merged.backgroundColor ??
                    CoreStarRatingStyle.defaultBackgroundColor)
              : (merged.disabledBackgroundColor ??
                    CoreStarRatingStyle.defaultDisabledBackgroundColor))
          .toValue();
  // Value / count text — the size row's role, then the per-instance
  // override; disabled swaps the ink for the disabled token.
  final valueEmit = emitTypography(
    enabled
        ? merged.valueStyle
        : (merged.valueStyle ?? const CoreTextStyle()).copyWith(
            color: CoreStarRatingStyle.defaultDisabledTextColor,
          ),
    sizeRow.valueStyle!,
  );
  final countEmit = emitTypography(
    enabled
        ? merged.countStyle
        : (merged.countStyle ?? const CoreTextStyle()).copyWith(
            color: CoreStarRatingStyle.defaultDisabledTextColor,
          ),
    sizeRow.countStyle!,
  );
  final valueGapStyle = CoreStarRatingStyle.defaultValueGapStyle.merge(
    merged.valueGapStyle,
  );
  final focusOutlineStyle = merged.focusRingStyle;

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the root `<div role="slider">` Tailwind className — the
  /// inline flex row. `outline-none` suppresses the browser's native
  /// focus ring so the composed `FocusOutline` is the single indicator.
  String buildRootClassName() =>
      '${WebLayout.inlineFlexItemsCenter} outline-none';

  /// Composes the stars box Tailwind className — the run of stars.
  /// Vertical stacks them; `items-center` keeps them aligned on the cross
  /// axis either way, mirroring the Flutter `Flex(direction:)`.
  String buildStarsClassName() => direction == .vertical
      ? '${WebLayout.inlineFlex} ${WebLayout.flexCol} ${WebLayout.itemsCenter}'
      : WebLayout.inlineFlexItemsCenter;

  /// Composes the stars box inline-CSS bundle — gap between stars and the
  /// cursor state (driven by [isInteractive]).
  Styles buildStarsInlineStyles() => .new(
    raw: {
      'gap': spaceCss(starSpacing),
      'cursor': isInteractive ? 'pointer' : 'default',
    },
  );

  /// Composes the per-star `<svg>` inline-CSS bundle — explicit
  /// `width`/`height` plus the `--coui-star-active` / `--coui-star-inactive`
  /// CSS custom properties referenced by the SVG `<path fill=...>`
  /// markup inside `Star`.
  Styles buildStarInlineStyles() => .new(
    raw: {
      'width': '${starSize / kRemDivisor}rem',
      'height': '${starSize / kRemDivisor}rem',
      '--coui-star-active': activeColor,
      '--coui-star-inactive': inactiveColor,
    },
  );

  /// Composes the active-fill `clipPath` `<rect>` inline-CSS bundle.
  ///
  /// Horizontal sweeps `width`; vertical sweeps a bottom-anchored
  /// `scaleY`, so the transitioned property and the transform anchor
  /// both follow the axis.
  Styles buildStarFillInlineStyles() => .new(
    raw: direction == .vertical
        ? {
            'transform-box': 'fill-box',
            'transform-origin': 'bottom',
            'transition': 'transform ${animationDuration}ms',
          }
        : {'transition': 'width ${animationDuration}ms'},
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedStarRating(
    root: WebElementChrome(className: buildRootClassName()),
    stars: WebElementChrome(
      className: buildStarsClassName(),
      inlineStyles: buildStarsInlineStyles(),
    ),
    value: WebElementChrome(
      className: valueEmit.className,
      inlineStyles: valueEmit.inline == null
          ? null
          : Styles(raw: valueEmit.inline),
    ),
    count: WebElementChrome(
      className: countEmit.className,
      inlineStyles: countEmit.inline == null
          ? null
          : Styles(raw: countEmit.inline),
    ),
    valueGapStyle: valueGapStyle,
    focusOutlineStyle: focusOutlineStyle,
    star: WebElementChrome(
      className: '',
      inlineStyles: buildStarInlineStyles(),
    ),
    starFill: WebElementChrome(
      className: '',
      inlineStyles: buildStarFillInlineStyles(),
    ),
  );
}
