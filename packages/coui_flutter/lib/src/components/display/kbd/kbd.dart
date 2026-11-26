import 'package:coui_flutter/coui_flutter.dart';

/// Keyboard key display component.
///
/// Renders one or more keyboard keys side by side, in the order given. Each
/// key is a rounded box with label-xs text in the body family (not mono —
/// the mono family lacks some modifier glyphs such as ⌘ and ⌥) on a filled
/// cap with a subtle hairline border and no shadow of its own — a border takes
/// no room while its colour is transparent, and a shadow is drawn where a style
/// states one; the boxes sit `keySeparatorSpacing` apart and nothing is drawn
/// between them. A shortcut written inside a sentence is
/// text such as "Ctrl+S", not a [Kbd].
///
/// One [Kbd] is one combination and is announced as **one** name — the keys
/// joined by a space ("Ctrl S"), never one fragment per key. An icon key is
/// announced only when it is named through [label].
///
/// Chrome / dimensional / text-style overrides flow through the single
/// [kbdStyle] slot per Epic #1302.
///
/// ```dart
/// Kbd(keys: ['Ctrl', 'C'])
/// Kbd.single(keyText: '⌘')
/// Kbd.icon(keyContent: Icon(LucideIcons.cornerDownLeft), label: 'Enter')
/// ```
///
/// surface:behind — whatever a key sits inline against (a sentence, a
/// shortcut list). Each key cap draws its own box rather than composing
/// `OutlinedContainer` — the Web twin's key-cap root is a fixed
/// `<span>`, and wrapping that in `OutlinedContainer`'s `<div>` breaks
/// the inline flow a key is meant to sit in (#4358) — so the marker is
/// restated on the key cap directly.
///
/// surface:content — a label-sized chip in the content layer, not a
/// floating affordance: no sticky, fixed, or overlay mount on either
/// platform.
class Kbd extends StatelessWidget implements CoreKbdContract<Widget> {
  /// Creates a [Kbd].
  const Kbd({
    required this.keys,
    super.key,
    this.kbdStyle,
  }) : keyContent = null,
       label = null;

  /// Creates a [Kbd] with a single key.
  Kbd.single({
    required String keyText,
    super.key,
    this.kbdStyle,
  }) : keys = [keyText],
       keyContent = null,
       label = null;

  /// Creates a [Kbd] with a single widget key (canonically an `Icon`
  /// glyph — identical on both platforms where a symbol text glyph
  /// would fall to per-platform font fallback).
  ///
  /// [label] is the key's accessible name; without it the glyph is silent.
  const Kbd.icon({
    required Widget this.keyContent,
    super.key,
    this.label,
    this.kbdStyle,
  }) : keys = const [];

  @override
  final List<String> keys;

  @override
  final Widget? keyContent;

  @override
  final String? label;

  @override
  final CoreKbdStyle? kbdStyle;

  /// Returns a copy of this [Kbd] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ///
  /// [keyContent] is not overridable here — it is mutually exclusive
  /// with [keys] (mirrors the Web `Kbd.copyWith`); when this instance
  /// already carries [keyContent] the copy stays a `Kbd.icon`.
  Kbd copyWith({Key? key, List<String>? keys, CoreKbdStyle? kbdStyle}) {
    final content = keyContent;
    if (content != null) {
      return Kbd.icon(
        key: key ?? this.key,
        keyContent: content,
        label: label,
        kbdStyle: kbdStyle ?? this.kbdStyle,
      );
    }
    return Kbd(
      key: key ?? this.key,
      keys: keys ?? this.keys,
      kbdStyle: kbdStyle ?? this.kbdStyle,
    );
  }

  /// A single key chip — InjectedCast(shadow) over an optional
  /// SurfaceBlur(material) over InsetShadow(rim) over Container(border) +
  /// ConstrainedBox(min) + Center(factor: 1): the min-square floor with a
  /// centred glyph.
  ///
  /// The shadow is painted by [InjectedCast] rather than the
  /// `BoxDecoration`: the fill can be translucent under a glass material,
  /// and `BoxDecoration.boxShadow` would draw the shadow behind it, through
  /// the fill — CSS paints an outer `box-shadow` outside the border box only.
  ///
  /// `Container` (not `DecoratedBox`) so the border adds to the box —
  /// matching Web, where the key cap is content-box and a drawn border
  /// grows the chip past `min-height` (a `DecoratedBox` paints the
  /// border inside the child extent, leaving the Flutter chip shorter by
  /// the border's width on each side). A transparent border has width 0
  /// by then (see `resolveKbd`), so it grows nothing. No `alignment:` on
  /// the Container — an aligned Container expands to fill bounded
  /// constraints, which stretched the chip to the parent's full height.
  Widget _buildKeyBox(
    BuildContext context,
    ResolvedKbd resolved,
    Widget child,
  ) {
    final cap = InsetShadow(
      shadows: resolved.keyRim,
      radius: resolved.keyRadius,
      child: Container(
        decoration: BoxDecoration(
          color: resolved.keyBackgroundColor,
          border: Border.all(
            color: resolved.keyBorderColor,
            width: resolved.keyBorderWidth,
          ),
          borderRadius: resolved.keyRadius,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: resolved.keyMinSize,
            minHeight: resolved.keyMinSize,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Padding(padding: resolved.keyPadding, child: child),
          ),
        ),
      ),
    );

    // The rest of the surface material, around the cap. The fill share is
    // already folded into the key fill; this adds what a fill cannot carry
    // — the frost, the chroma, the dimming, the edge light and the bend —
    // the way the Web twin's key-cap marker gets them from the style rule.
    // Inside the cast so the cast keeps painting outside the box; wrapped
    // only when the style states something to draw, so every other style
    // keeps the tree it had.
    final surfaceBlur = resolved.surfaceBlur;
    final materialCap =
        (surfaceBlur != null && surfaceBlur > 0) ||
            resolved.surfaceSheen != null
        ? SurfaceBlur(
            borderRadius: resolved.keyRadius,
            surfaceBlur: surfaceBlur,
            surfaceSaturation: resolved.surfaceSaturation,
            surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
            surfaceSheen: resolved.surfaceSheen,
            refraction: Theme.of(context).surfaceRefraction,
            child: cap,
          )
        : cap;

    return InjectedCast(
      shadows: resolved.keyShadow,
      borderRadius: resolved.keyRadius,
      child: materialCap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveKbd(context, kbdStyle: kbdStyle);

    final content = keyContent;
    if (content != null) {
      return _named(_buildKeyBox(context, resolved, content), label);
    }

    return _named(
      Row(
        mainAxisSize: .min,
        spacing: resolved.keySeparatorSpacing,
        children: [
          for (final keyText in keys)
            _buildKeyBox(
              context,
              resolved,
              Text(keyText, style: resolved.keyTextStyle),
            ),
        ],
      ),
      keys.join(' '),
    );
  }

  /// The combination as one accessible name. The key boxes beneath it stay
  /// out of the tree — a reader gets "Ctrl S", not "Ctrl", "S" — and a null
  /// or empty [name] adds nothing, so an unnamed icon key is as silent as
  /// the glyph alone.
  Widget _named(Widget child, String? name) {
    if (name == null || name.isEmpty) return child;
    return Semantics(label: name, excludeSemantics: true, child: child);
  }
}

/// Chain sugar for merging a [CoreKbdStyle] patch into [Kbd.kbdStyle]
/// without hand-reconstructing every field. Mirrors the Web
/// `Kbd.withStyle` extension so both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreKbdStyle.merge` right-side-wins semantics).
extension KbdStyleChain on Kbd {
  /// Returns a copy of this [Kbd] with [patch] merged into [kbdStyle]
  /// (patch fields win on conflict).
  Kbd withStyle(CoreKbdStyle patch) =>
      copyWith(kbdStyle: (kbdStyle ?? const CoreKbdStyle()).merge(patch));
}
