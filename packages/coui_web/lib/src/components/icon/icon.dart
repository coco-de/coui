import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/icon/icon_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform icon component for CoUI Web.
///
/// Renders icons from any Iconify-supported icon set (Lucide, Radix,
/// Bootstrap, HeroIcons, …) via the `<iconify-icon>` web component.
///
/// An icon CoUI ships in the package — every icon a CoUI component draws
/// ([CoreBundledIcons]) — renders as an inline `<svg>` instead: no script
/// and no request to the Iconify API, so it shows in server-rendered
/// markup, offline and behind a strict CSP, the way the Flutter twin
/// draws the same bundle with no network.
///
/// All visual customisation flows through [iconStyle] (`CoreIconStyle`).
/// The merge chain (left → right, right wins on each non-null field):
///
/// ```text
/// theme.icon.style
///   → parent slot (e.g. CoreButtonStyle.leadingIconStyle)
///   → widget.style
///   → ambient IconTheme
///   → design-system default (24px / inherit `currentColor`)
/// ```
///
/// ```dart
/// Icon(LucideIcons.house)
/// Icon(LucideIcons.heart, iconStyle: CoreIconStyle(size: 20))
/// Icon(
///   LucideIcons.triangleAlert,
///   iconStyle: CoreIconStyle(
///     size: 16, color: context.theme.colorScheme.error,
///   ),
/// )
/// ```
///
/// ## Lucide stroke
///
/// A Lucide glyph is authored with `stroke-width="2"` on a 24-unit grid, so
/// left alone its stroke would grow with the icon. A Lucide icon is
/// instead drawn at `CoreIconStroke.renderedWidth` of its token size — 1.25
/// up to size 20, then `size / 16` — by rewriting that attribute in the
/// inline `<svg>` or a per-instance copy of Iconify's canonical data. Other
/// icon sets are not touched. The rule never reads
/// `CoreStrokeWidth` or `--coui-stroke-width-*`: a surface preset raises that
/// scale for borders, and an icon must not thicken with it.
///
/// Add [iconScript] to your page `<head>` for icons outside the bundle.
class Icon extends UiComponent implements CoreIconContract {
  /// Creates a [Icon].
  const Icon(
    this.icon, {
    this.iconStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'iconify-icon');

  @override
  final IconName icon;

  /// Per-instance icon style. See class doc for resolve chain.
  @override
  final CoreIconStyle? iconStyle;
  @override
  Icon copyWith({
    IconName? icon,
    CoreIconStyle? iconStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return Icon(
      icon ?? this.icon,
      key: key ?? this.key,
      iconStyle: iconStyle ?? this.iconStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    // Single entry point — `resolveIconStyle` encapsulates the
    // theme.icon.style → widget.iconStyle merge, the ambient IconTheme
    // fallback and the bundled glyph (Lucide stroke already applied) in
    // `icon_style.dart`.
    final resolved = resolveIconStyle(
      context,
      icon: icon,
      widgetStyle: iconStyle,
    );
    final bundled = resolved.bundled;
    final chrome = iconElementChrome(
      size: resolved.size,
      color: resolved.color,
      inlineSvg: bundled != null,
    );
    if (bundled != null) {
      return _buildBundled(bundled, chrome);
    }

    final hostAttributes = componentAttributes;
    // HTML attribute names are case-insensitive. Supplying either dimension
    // intentionally delegates the other one to Iconify's aspect-ratio logic.
    final hasCustomDimensions = hostAttributes.keys.any(
      (name) => const ['width', 'height'].contains(name.toLowerCase()),
    );
    return Component.element(
      key: key,
      tag: 'iconify-icon',
      id: id,
      classes: mergeClasses(chrome.className, classes),
      styles: Styles.combine([?chrome.inlineStyles, ?this.css]),
      attributes: {
        'icon': icon.id,
        if (!hasCustomDimensions) ...{'width': '1em', 'height': '1em'},
        ...hostAttributes,
      },
      events: this.events,
      // Iconify renders no light-DOM slot. This empty companion changes no
      // layout or accessibility and observes only its own parent. Its external
      // runtime uses Iconify's loader/cache, including local registrations,
      // then supplies a normalized copy through the public icon-data API.
      children: [
        Component.element(
          tag: 'coui-iconify-stroke',
          attributes: resolved.strokeAttributes,
          children: const [],
        ),
      ],
    );
  }

  /// The bundled icon as the `<svg>` `<iconify-icon>` would render into
  /// its shadow root — the same chrome on the element itself and a
  /// viewBox at the icon's native size.
  ///
  /// [data] is the glyph `resolveIconStyle` returns, its body already
  /// carrying the Lucide stroke rule.
  Component _buildBundled(IconSvgData data, WebElementChrome chrome) {
    return Component.element(
      key: key,
      tag: 'svg',
      id: id,
      classes: mergeClasses(chrome.className, classes),
      styles: Styles.combine([?chrome.inlineStyles, ?this.css]),
      attributes: {
        'xmlns': 'http://www.w3.org/2000/svg',
        'viewBox': '0 0 ${data.width} ${data.height}',
        // No role and no name of its own, like the `<iconify-icon>` path
        // and the Flutter twin — a caller names it through `attributes`.
        'focusable': 'false',
        'data-icon': icon.id,
        ...componentAttributes,
      },
      events: this.events,
      children: [RawText(data.body)],
    );
  }
}

/// Chain sugar for merging a [CoreIconStyle] patch into
/// [Icon.iconStyle] without hand-reconstructing every field. Mirrors
/// the Flutter `Icon.withStyle` extension so both platforms read
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

/// Returns a `<script>` component that loads the Iconify web component.
///
/// Add this to your page `<head>` for the fallback mode to work.
///
/// By default the script comes from the public jsDelivr CDN at [version].
/// A page that may not reach a third-party origin — a strict CSP, an
/// offline build — mirrors the file and passes its own [src], which wins
/// over [version]. The companion [normalizerSrc] is a same-origin package
/// asset served by Jaspr; mirror it too if your asset paths differ. Both are
/// external scripts: no inline script or event handler is required by CSP.
Component iconScript({
  String version = '2.1.0',
  String? src,
  String normalizerSrc = 'packages/coui_web/iconify_stroke.js',
}) {
  return Component.fragment([
    Component.element(
      tag: 'script',
      attributes: {
        'src':
            src ??
            'https://cdn.jsdelivr.net/npm/iconify-icon@$version/dist/iconify-icon.min.js',
      },
      children: const [],
    ),
    Component.element(
      tag: 'script',
      attributes: {'src': normalizerSrc},
      children: const [],
    ),
  ]);
}
