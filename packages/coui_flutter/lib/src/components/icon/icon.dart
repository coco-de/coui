import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Cross-platform icon widget using Iconify SVG data.
///
/// Renders icons from any Iconify-supported icon set (Lucide, Radix,
/// Bootstrap, HeroIcons, etc.) using SVG data fetched via [IconResolver].
///
/// All visual customisation flows through [iconStyle] (`CoreIconStyle`).
/// The merge chain (left → right, right wins on each non-null field):
///
/// ```text
/// theme.icon.style
///   → parent slot (e.g. CoreButtonStyle.leadingIconStyle)
///   → widget.iconStyle
///   → ambient IconTheme
///   → design-system default (24px / colorScheme.onSurface.toValue())
/// ```
///
/// ## Stroke
///
/// There is no stroke field on [iconStyle]: the weight of a Lucide glyph is a
/// function of its size, not a style input. Every vendored Lucide glyph is
/// authored with `stroke-width="2"`, which would grow the stroke in lockstep
/// with the icon (`size ÷ 12`); the resolver rewrites it through
/// `CoreIconStroke` so it renders at `max(1.25, tokenSize ÷ 16)` token px
/// (20 and below hold at 1.25, 24 → 1.5, 32 → 2). `tokenSize` is the size the
/// style states, before the theme scaling — the scaled box then scales the
/// stroke with it, so token 20 on a 1.25× screen draws a 25 px glyph with a
/// 1.56 px stroke.
///
/// The rule applies to every `lucide:` icon, bundled or fetched from the
/// Iconify API. HeroIcons, Radix and Bootstrap glyphs are drawn as authored.
/// It reads neither `CoreStrokeWidth` nor `--coui-stroke-width-*`: a surface
/// preset raises those (neo-brutalism draws borders at 3 px) and an icon must
/// not thicken with the box around it.
///
/// The icon scales its own box, so the size handed to it (through
/// [iconStyle] or an ambient `IconTheme`) is read as a token size, and the
/// stroke rule reads it as one. A size the caller already multiplied by the
/// theme scaling is multiplied again by the icon, and the rule then reads
/// the multiplied size — a component forwards the token size as stated.
///
/// ```dart
/// Icon(LucideIcons.house)
/// Icon(LucideIcons.heart, iconStyle: CoreIconStyle(size: 20))
/// Icon(
///   LucideIcons.triangleAlert,
///   iconStyle: CoreIconStyle(size: 16, color: scheme.error.toValue()),
/// )
/// ```
class Icon extends StatefulWidget implements CoreIconContract {
  /// Creates a [Icon].
  const Icon(
    this.icon, {
    super.key,
    this.iconStyle,
  });

  /// The icon to display.
  @override
  final IconName icon;

  /// Per-instance icon style. See class doc for the resolve chain.
  @override
  final CoreIconStyle? iconStyle;

  /// Returns a copy of this [Icon] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Icon copyWith({
    Key? key,
    IconName? icon,
    CoreIconStyle? iconStyle,
  }) {
    return Icon(
      icon ?? this.icon,
      key: key ?? this.key,
      iconStyle: iconStyle ?? this.iconStyle,
    );
  }

  @override
  State<Icon> createState() => _IconState();
}

class _IconState extends State<Icon> {
  IconSvgData? _data;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  void _resolve() {
    final data = IconResolver.instance.get(widget.icon.id);
    if (data != null) {
      _data = data;
      return;
    }
    _data = null;
    unawaited(
      IconResolver.instance.preload([widget.icon.id]).then((_) {
        if (!mounted) return;
        setState(() {
          _data = IconResolver.instance.get(widget.icon.id);
        });
      }),
    );
  }

  @override
  void didUpdateWidget(Icon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.icon.id != widget.icon.id) {
      _resolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The resolver owns the theme / IconTheme / colorScheme reads and builds
    // the finished SVG; the widget only keeps the glyph data it has loaded
    // and paints the result.
    final resolved = resolveIcon(
      context,
      icon: widget.icon,
      data: _data,
      widgetStyle: widget.iconStyle,
    );

    final svgString = resolved.svgString;
    if (svgString == null) {
      return SizedBox.square(dimension: resolved.size);
    }

    // SvgPicture derives its width from the glyph's aspect ratio even when
    // both dimensions are supplied. Keep the declared box, as the placeholder
    // does, and let the SVG fit its authored geometry inside that box.
    return SizedBox.square(
      dimension: resolved.size,
      child: SvgPicture.string(
        svgString,
        width: resolved.size,
        height: resolved.size,
        colorFilter: ColorFilter.mode(resolved.color, .srcIn),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreIconStyle] patch into
/// [Icon.iconStyle] without hand-reconstructing every field. Mirrors
/// the Web `Icon.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreIconStyle.merge` right-side-wins semantics).
extension IconStyleChain on Icon {
  /// Returns a copy of this [Icon] with [patch] merged into
  /// [iconStyle] (patch fields win on conflict).
  Icon withStyle(CoreIconStyle patch) =>
      copyWith(iconStyle: (iconStyle ?? const CoreIconStyle()).merge(patch));
}
