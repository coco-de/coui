import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform tag — a short label that files something under
/// a category, coloured by one of the category hues.
///
/// Display only: no press, no hover or press state, never focusable. A
/// label a person acts on is a `Chip`; a status is a `Badge`.
///
/// Every chrome / dimensional / nested-slot override flows through the
/// single [tagStyle] (a [CoreTagStyle]). The design axes (`color` /
/// `emphasis` / `size`) and the label (`child`) stay flat on the widget.
///
/// ```text
/// design system default for size × emphasis × hue
///   → CoreTagTheme.style                    // 프로젝트 공통
///   → CoreTagTheme.colorStyles[color]
///   → CoreTagTheme.emphasisStyles[emphasis]
///   → widget.tagStyle                       // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// Tag(color: CoreCategoryColor.blue, child: Text('Design'))
///
/// Tag(
///   color: CoreCategoryColor.green,
///   emphasis: CoreTagEmphasis.bold,
///   size: CoreTagSize.sm,
///   child: Text('New'),
/// )
/// ```
///
/// surface:behind — whatever the tag is set inline against (a sentence,
/// a card, a table row). It draws its own box rather than composing
/// `OutlinedContainer` — the Web twin's root is an inline `<span>`, and
/// wrapping that in `OutlinedContainer`'s `<div>` breaks the inline flow a
/// tag sits in — so the marker is restated here directly, as `Badge`
/// does.
///
/// surface:content — a label-sized part in the content layer, not a
/// floating affordance: no sticky, fixed, or overlay mount on either
/// platform.
class Tag extends StatelessWidget implements CoreTagContract<Widget> {
  /// Creates a [Tag].
  const Tag({
    required this.child,
    super.key,
    this.color = CoreTagContract.defaultColor,
    this.emphasis = CoreTagEmphasis.defaultEmphasis,
    this.size = CoreTagSize.defaultSize,
    this.tagStyle,
  });

  @override
  final CoreCategoryColor color;

  @override
  final CoreTagEmphasis emphasis;

  @override
  final CoreTagSize size;

  @override
  final Widget child;

  /// Per-instance composite style — chrome flat fields plus the nested
  /// `labelStyle` slot. See [CoreTagStyle] for the merge chain.
  @override
  final CoreTagStyle? tagStyle;

  /// Returns a copy of this [Tag] with the given fields replaced. All
  /// fields default to this instance's current value when omitted.
  Tag copyWith({
    Key? key,
    CoreCategoryColor? color,
    CoreTagEmphasis? emphasis,
    CoreTagSize? size,
    CoreTagStyle? tagStyle,
    Widget? child,
  }) {
    return Tag(
      key: key ?? this.key,
      color: color ?? this.color,
      emphasis: emphasis ?? this.emphasis,
      size: size ?? this.size,
      tagStyle: tagStyle ?? this.tagStyle,
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTag(
      context,
      color: color,
      emphasis: emphasis,
      size: size,
      tagStyle: tagStyle,
    );
    final borderRadius = resolved.borderRadius;

    final box = Container(
      // At least the step's height; the label is centred in it by the Row
      // below, which fills that height — a bare child would sit at the top
      // (widget/stack-alignment.md), where Web's `items-center` centres it.
      constraints: resolved.constraints,
      padding: resolved.padding,
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        border: resolved.borderColor != null
            ? Border.all(
                color: resolved.borderColor!,
                width: resolved.borderWidth,
              )
            : null,
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: .min,
        mainAxisAlignment: .center,
        children: [
          DefaultTextStyle.merge(
            style: resolved.labelTextStyle,
            maxLines: 1,
            softWrap: false,
            child: child,
          ),
        ],
      ),
    );

    // The rest of the surface material, around the box — the frost, the
    // chroma, the dimming and the edge light the fill share cannot carry.
    // Wrapped only when the style states something to draw.
    final surfaceBlur = resolved.surfaceBlur;
    final materialBox =
        (surfaceBlur != null && surfaceBlur > 0) ||
            resolved.surfaceSheen != null
        ? SurfaceBlur(
            borderRadius: borderRadius,
            surfaceBlur: surfaceBlur,
            surfaceSaturation: resolved.surfaceSaturation,
            surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
            surfaceSheen: resolved.surfaceSheen,
            refraction: Theme.of(context).surfaceRefraction,
            child: box,
          )
        : box;

    // Cast painted outside the box rather than behind it, so a translucent
    // fill under a style preset does not show it through
    // (cross-platform/api.md "그림자는 두 플랫폼이 다른 곳에 칠한다").
    return InjectedCast(
      shadows: resolved.boxShadow,
      borderRadius: borderRadius,
      child: materialBox,
    );
  }
}

/// Chain sugar for merging a [CoreTagStyle] patch into [Tag.tagStyle]
/// without hand-reconstructing every field. Mirrors the Web
/// `Tag.withStyle` extension so both platforms read identically. The
/// label keeps using the `Text(...).labelSmall...` chain directly — this
/// extension only covers the [CoreTagStyle] chrome slot.
///
/// ```dart
/// Tag(child: Text('Design')).withStyle(
///   CoreTagStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
/// )
/// ```
extension TagStyleChain on Tag {
  /// Returns a copy of this [Tag] with [patch] merged into [tagStyle]
  /// (patch fields win on conflict).
  Tag withStyle(CoreTagStyle patch) =>
      copyWith(tagStyle: (tagStyle ?? const CoreTagStyle()).merge(patch));
}
