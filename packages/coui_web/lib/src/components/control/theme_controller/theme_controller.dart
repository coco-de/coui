import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/control/theme_controller/theme_controller_style.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// A unified cross-platform theme picker for CoUI Web.
///
/// `ThemeController` renders a wrapping grid of selectable theme
/// swatches. Each swatch previews the theme's palette colours and
/// reports the picked theme name through [onThemeChanged].
///
/// Every chrome / dimensional override flows through the single
/// [themeControllerStyle] field — see [CoreThemeControllerStyle] for
/// the merge chain. The semantic / behaviour fields (`themes` /
/// `selectedTheme` / `onThemeChanged` / `size` / `enabled`) stay flat on the
/// component.
///
/// Mirrors Flutter `ThemeController` 1:1 — same parameter names, same
/// semantics.
///
/// Each swatch button is a bare ring around its palette: no body, and no
/// ring at rest. A hovered or pressed swatch grows a light ring, the
/// selected one wears the strong ring and its label turns to the strong
/// ink; the selection is also announced through `aria-pressed`, so it
/// does not depend on colour.
///
/// surface:content — a wrapping grid of swatches that sits in the page
/// flow, not something mounted over content. The swatch buttons draw no
/// fill, so a surface material reaches none of them.
///
/// ```dart
/// ThemeController(
///   selectedTheme: _theme,
///   onThemeChanged: (name) => setState(() => _theme = name),
///   themes: const [
///     CoreThemeOption(
///       name: 'Ocean',
///       primaryColor: CoreColor.fromRGB(14, 165, 233),
///     ),
///     CoreThemeOption(
///       name: 'Forest',
///       primaryColor: CoreColor.fromRGB(34, 197, 94),
///     ),
///   ],
/// )
/// ```
class ThemeController extends UiComponent
    implements CoreThemeControllerContract {
  /// Creates a [ThemeController].
  const ThemeController({
    required this.themes,
    required this.onThemeChanged,
    super.key,
    this.selectedTheme,
    this.size = CoreThemeControllerSize.defaultSize,
    this.enabled = true,
    this.themeControllerStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final List<CoreThemeOption> themes;

  @override
  final String? selectedTheme;

  @override
  final CoreValueChanged<String> onThemeChanged;

  @override
  final CoreThemeControllerSize size;

  @override
  final bool enabled;

  @override
  final CoreThemeControllerStyle? themeControllerStyle;

  @override
  ThemeController copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    List<CoreThemeOption>? themes,
    CoreValueChanged<String>? onThemeChanged,
    String? selectedTheme,
    CoreThemeControllerSize? size,
    bool? enabled,
    CoreThemeControllerStyle? themeControllerStyle,
  }) {
    return ThemeController(
      key: key ?? this.key,
      themes: themes ?? this.themes,
      onThemeChanged: onThemeChanged ?? this.onThemeChanged,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      size: size ?? this.size,
      enabled: enabled ?? this.enabled,
      themeControllerStyle: themeControllerStyle ?? this.themeControllerStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1601
    // PoC — `WebResolvedChrome` contract). `co_*` reads the paint-
    // ready strings directly from each slot.
    final resolved = resolveThemeController(
      context,
      size: size,
      themeControllerStyle: themeControllerStyle,
    );
    // The hover ring and the pressed palette are pseudo-state looks with
    // no preset class — one scoped `<style>` for the whole grid.
    final rules = resolveThemeControllerRules(
      context,
      size: size,
      themeControllerStyle: themeControllerStyle,
    );

    return div(
      [
        // `<style>` is `display: none`, so it never takes a flex slot.
        if (rules.css.isNotEmpty)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        for (final option in themes)
          _buildSwatch(option: option, resolved: resolved, rules: rules),
      ],
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
    );
  }

  Component _buildSwatch({
    required CoreThemeOption option,
    required ResolvedThemeController resolved,
    required ResolvedThemeControllerRules rules,
  }) {
    final selected = option.name == selectedTheme;
    // The group lock and the per-theme lock compose: either one greys
    // the swatch. Their scopes differ (a read-only form vs a theme a
    // plan does not include), which is why both exist.
    final swatchEnabled = enabled && option.enabled;
    final buttonChrome = swatchEnabled
        ? (selected ? resolved.selectedButton : resolved.unselectedButton)
        : (selected
              ? resolved.disabledSelectedButton
              : resolved.disabledButton);
    final segmentChrome = swatchEnabled
        ? resolved.segment
        : resolved.disabledSegment;
    final labelChrome = !swatchEnabled
        ? resolved.disabledLabel
        : selected
        ? resolved.selectedLabel
        : resolved.label;
    // Only an enabled swatch reacts to the pointer; only an unselected one
    // grows the ring (the selected one already wears the strong ring).
    final buttonClasses = [
      buttonChrome.className,
      if (swatchEnabled) rules.pressClass,
      if (swatchEnabled && !selected) rules.ringClass,
    ].where((c) => c.isNotEmpty).join(' ');
    final previewColors = [
      option.primaryColor,
      ?option.secondaryColor,
      ?option.accentColor,
      ?option.neutralColor,
    ];

    // Web twin of the Flutter swatch: the composed Clickable owns tap /
    // keyboard activation / cursor / press feedback / focus ring (no
    // hand-rolled role="button" div + click handler). The Clickable's
    // default `role="button"` stands; the inner <div> carries only the
    // swatch chrome. The palette is one circle divided evenly among the
    // colours the option carries — the colour is the only per-iteration
    // rule the widget adds, and only while enabled: a locked swatch
    // discards its palette (the resolver bakes the disabled fill in).
    final button = Clickable(
      onPressed: () => onThemeChanged(option.name),
      enabled: swatchEnabled,
      attributes: {
        'aria-label': option.name,
        'aria-pressed': '$selected',
        if (!swatchEnabled) 'aria-disabled': 'true',
      },
      clickableStyle: resolved.clickableStyle,
      child: div(
        [
          div(
            [
              for (final color in previewColors)
                div(
                  const [],
                  classes: segmentChrome.className,
                  styles: swatchEnabled
                      ? Styles(raw: {'background-color': color.toValue()})
                      : segmentChrome.inlineStyles,
                ),
            ],
            classes: resolved.preview.className,
            styles: resolved.preview.inlineStyles,
          ),
        ],
        classes: buttonClasses,
        styles: buttonChrome.inlineStyles,
      ),
    );

    return div(
      [
        button,
        Gap(gapStyle: resolved.labelGapStyle),
        div(
          [Text(option.name)],
          classes: labelChrome.className,
          styles: labelChrome.inlineStyles,
        ),
      ],
      classes: resolved.swatch.className,
      styles: resolved.swatch.inlineStyles,
    );
  }
}

/// Chain sugar mirroring the Flutter `ThemeController.withStyle`
/// extension — merges a [CoreThemeControllerStyle] patch into
/// [ThemeController.themeControllerStyle] via the existing
/// [ThemeController.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreThemeControllerStyle.merge` right-side-wins semantics).
extension ThemeControllerStyleChain on ThemeController {
  /// Returns a copy of this [ThemeController] with [patch] merged into
  /// [themeControllerStyle] (patch fields win on conflict).
  ThemeController withStyle(CoreThemeControllerStyle patch) => copyWith(
    themeControllerStyle:
        (themeControllerStyle ?? const CoreThemeControllerStyle()).merge(
          patch,
        ),
  );
}
