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

/// Paint-ready chrome for Web `Kbd`.
///
/// DOM shape:
///
/// ```text
/// root (<span>)                        // inline-flex row container; owns the gap
///   ├─ keyCap (<span>)                 // per-key rounded box, edged if it paints one
///   ├─ keyCap (<span>)                 // next key
///   └─ keyCap (<span>)                 // …
/// ```
///
/// `kbd.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only
/// `WebElementChrome` slots (paint-ready chrome). The `keyCap` bundle is
/// reused across every key — the only per-key variable is the rendered
/// text, not the chrome.
class ResolvedKbd implements WebResolvedChrome {
  /// Creates a [ResolvedKbd].
  const ResolvedKbd({
    required this.root,
    required this.keyCap,
  });

  /// Paint-ready chrome for the outer `<span>` container — inline-flex
  /// row that lays out the keys. The space between adjacent keys is the
  /// row's `gap`, so it holds whatever the keys are.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for a single key cap `<span>` — typography +
  /// border + background className plus padding / radius / optional
  /// font-size inline CSS. The same bundle is reused for every key —
  /// the only per-key variable is the rendered text, not the chrome.
  /// Never shrinks, so a combination keeps its line instead of squeezing
  /// the glyphs.
  final WebElementChrome keyCap;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedKbd] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.kbd.style
///   → widget.kbdStyle
/// ```
ResolvedKbd resolveKbd(
  BuildContext context, {
  CoreKbdStyle? kbdStyle,
}) {
  final kbdTheme = context.theme.coreComponentTheme?.kbd;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreKbdStyle(), [
    kbdTheme?.style,
    kbdStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final keyMinSize = merged.keyMinSize ?? CoreKbdStyle.defaultKeyMinSize;
  final keyPadding = merged.keyPadding ?? CoreKbdStyle.defaultKeyPadding;
  final keyRadius = merged.keyRadius ?? CoreKbdStyle.defaultKeyRadius;
  // Flat key↔key spacing — N-sibling 균등 분포 (Key, Key, Key) 패턴.
  // Web emits CSS `gap` on the flex row container (parity with Flutter
  // `Row.spacing`); the keys carry no margin of their own, so the gap holds
  // for any number of them.
  final keySpacing =
      merged.keySeparatorSpacing ?? CoreKbdStyle.defaultKeySeparatorSpacing;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Every colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value. Token-bound
  // values (design-system defaults AND token overrides) emit Tailwind
  // classes so they stay dark-mode reactive; raw / transparent overrides
  // go inline. No `scheme.resolve` (a no-op on Web) and no hand-rolled
  // `text-${...token!.name}` role-class construction.
  // surface:content — the background token the key cap fills with, read
  // before it resolves to a CSS string so `surfaceFillVar` can see its
  // token reference.
  final keyBackgroundColorCore =
      merged.keyBackgroundColor ?? CoreKbdStyle.defaultKeyBackgroundColor;
  // Whether a key cap paints a fill. The surface material is a statement
  // about a filled box: handed to a transparent cap it frosts a backdrop
  // behind nothing and clears the stroke that is the cap's only edge. The
  // Flutter twin withholds the material on the same answer.
  final hasFill = surfacePaintsFill(keyBackgroundColorCore);
  final keyBackgroundEmit = emitColor(
    merged.keyBackgroundColor,
    CoreKbdStyle.defaultKeyBackgroundColor,
    .background,
  );
  final keyBorderEmit = emitColor(
    merged.keyBorderColor,
    CoreKbdStyle.defaultKeyBorderColor,
    .border,
  );
  // A border that paints nothing takes no part in the key cap: no `border`
  // width class and a width of 0, so the cap's box is the one the Flutter
  // twin draws (`Border.all` insets the box by `width` even in a colour
  // nobody can see — and on this platform the `border-width` below is drawn
  // wherever a reset sets `border-style: solid`, as the docs site's does).
  //
  // The answer is [CoreColor.paintsNothing], judged on the colour alone. It
  // is not `isTransparent`, which means "carries no token" on this platform
  // (no Tailwind class exists for it) and is true of every raw colour, an
  // opaque raw rim included. The Flutter twin reads the same from the
  // resolved alpha: a token colour is hidden by an opacity of 0, a raw one by
  // an alpha byte of 0 or an opacity of 0.
  final keyBorderColor =
      merged.keyBorderColor ?? CoreKbdStyle.defaultKeyBorderColor;
  final keyBorderInvisible = keyBorderColor.paintsNothing;
  final keyBordered = !keyBorderInvisible;
  // Always inline (matches Command's `borderWidth` — radius/padding/gap/
  // size stay inline per the resolver signature guard). A hidden border
  // takes 0, the fold the Flutter resolver applies to the authored colour.
  final keyBorderWidth = keyBorderInvisible
      ? 0.0
      : merged.keyBorderWidth ?? CoreKbdStyle.defaultKeyBorderWidth;
  // The key states its own shadow (none by default), so the active surface
  // style bends a stack stated there (`--shadow-*` re-pointing) instead of
  // contributing its injected cast — which is why the cast marker is not on
  // the key cap.
  final keyShadow = merged.keyShadow ?? CoreKbdStyle.defaultKeyShadow;
  // Label typography — `emitTypography` merges the default
  // role with any per-instance overlay, emitting a `text-{role}` class
  // for a pure role (+ token colour class) or the explicit scalar
  // overlay inline. Single canonical path; no manual role-class build.
  final keyTypographyEmit = emitTypography(
    merged.keyTextStyle,
    CoreKbdStyle.defaultKeyTextStyle,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the outer container `<span>` Tailwind className —
  /// inline-flex row that lays out the keys on one line.
  String buildRootClassName() => WebLayout.inlineFlexRowItemsCenter;

  /// The gap between adjacent keys — on the row, not on each key, so the
  /// space belongs to the layout rather than to a glyph between the keys.
  Styles buildRootInlineStyles() => .new(raw: {'gap': spaceCss(keySpacing)});

  /// Composes the per-key `<span>` Tailwind className — typography role
  /// ([keyTypographyEmit]) + border + background tokens (from the
  /// [emitColor] results, token values only; raw overrides go inline).
  String buildKeyClassName() {
    return <String>[
      WebLayout.inlineFlex,
      // A key never narrows: the cap's `min-width` floor already switches off
      // flex's automatic minimum, so without this a host that is itself a
      // shrinkable flex item (`min-width: 0`) squeezes the cap down to 18px
      // and clips its glyph.
      WebLayout.shrinkZero,
      // Marks this element as a component surface — restated here
      // because Kbd can't compose `OutlinedContainer` (each key cap's
      // Web root is a fixed `<span>`, #4358). Only on a cap that paints a
      // fill ([hasFill]).
      if (hasFill) ...webSurfaceMarkerFor(.content),
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      if (keyBordered) 'border',
      keyBorderEmit.className,
      keyBackgroundEmit.className,
      keyTypographyEmit.className,
    ].where((c) => c.isNotEmpty).join(' ');
  }

  // The minimum constrains the padded interior; the border grows the cap
  // around it, as Flutter's Container grows its ConstrainedBox child.
  final keyMinExtentCss =
      'calc(${keyMinSize / kRemDivisor}rem + '
      '${strokeWidthCss(keyBorderWidth)} * 2)';

  /// Composes the per-key `<span>` inline CSS — padding + border-radius
  /// plus the emit-family inline fragments (raw colour overrides + the
  /// explicit typography overlay only — token values stay on classes).
  Styles buildKeyInlineStyles() => .new(
    raw: {
      'box-sizing': 'border-box',
      'min-width': keyMinExtentCss,
      'min-height': keyMinExtentCss,
      'padding': keyPadding.toValue(),
      'border-radius': keyRadius.toValue(),
      'border-width': strokeWidthCss(keyBorderWidth),
      if (hasFill) ...surfaceBleedVar(strokeWidthCss(keyBorderWidth)),
      // On the key cap, not on the row that holds the keys — the cap is the
      // surface, the row is layout, so `Ctrl + C` shows one shadow per key.
      //
      // The surface style's inset rim rides the same declaration: the key's
      // fill is a surface of its own, which is what the rim belongs on, and a
      // surface that casts a shadow names it beside that shadow. Only when the
      // key casts — a rim decorates a raised surface, it does not raise a flat
      // one.
      if (keyShadow.isNotEmpty)
        'box-shadow':
            '${emitShadow(keyShadow, base: kShadowVariableBase)}, '
            '$kSurfaceRimVar',
      ...?keyBackgroundEmit.inline,
      ...?keyBorderEmit.inline,
      ...?keyTypographyEmit.inline,
      // The marker's other half — a preset restates this fill at a
      // lower alpha and cannot know which token the key cap chose.
      if (hasFill) ...surfaceFillVar(keyBackgroundColorCore),
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedKbd(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    keyCap: WebElementChrome(
      className: buildKeyClassName(),
      inlineStyles: buildKeyInlineStyles(),
    ),
  );
}
