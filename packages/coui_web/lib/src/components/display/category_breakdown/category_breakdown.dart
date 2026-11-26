import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/display/category_breakdown/category_breakdown_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform category breakdown for CoUI Web — each
/// category's share of a total, drawn as horizontal bars (default) or a
/// donut with a legend.
///
/// Every row reads label, value and share together, so no category is
/// told apart by colour alone. Uses [CoreCategoryBreakdownContract] from
/// `coui_core`, so the Flutter `CategoryBreakdown` takes the same named
/// properties. Rendering is plain DOM + inline SVG — no chart library.
///
/// Example:
/// ```dart
/// CategoryBreakdown(
///   semanticLabel: '문의 유형별 분포',
///   items: const [
///     CoreCategoryBreakdownItem(label: '결제', value: 128, valueLabel: '128건'),
///     CoreCategoryBreakdownItem(label: '배송', value: 61, valueLabel: '61건'),
///   ],
/// )
/// ```
class CategoryBreakdown extends UiComponent
    implements CoreCategoryBreakdownContract<Component> {
  /// Creates a [CategoryBreakdown].
  const CategoryBreakdown({
    required this.items,
    this.variant = CoreCategoryBreakdownVariant.defaultVariant,
    this.center,
    this.empty,
    this.semanticLabel,
    this.categoryBreakdownStyle,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.tag = 'div',
  });

  @override
  final CoreCategoryBreakdownVariant variant;

  @override
  final List<CoreCategoryBreakdownItem> items;

  @override
  final Component? center;

  @override
  final Component? empty;

  @override
  final String? semanticLabel;

  @override
  final CoreCategoryBreakdownStyle? categoryBreakdownStyle;

  @override
  Component build(BuildContext context) {
    final resolved = resolveCategoryBreakdown(
      context,
      variant: variant,
      items: items,
      categoryBreakdownStyle: categoryBreakdownStyle,
    );
    final series = resolved.series;
    if (series.isEmpty) return empty ?? const Component.fragment([]);

    final isBar = variant == CoreCategoryBreakdownVariant.bar;
    return div(
      isBar
          ? [
              for (var i = 0; i < items.length; i++)
                div(
                  [
                    _texts(resolved, resolved.texts, i),
                    div(
                      [
                        div(
                          const [],
                          classes: resolved.fills[i].className,
                          styles: resolved.fills[i].inlineStyles,
                        ),
                      ],
                      classes: resolved.track.className,
                      styles: resolved.track.inlineStyles,
                      attributes: const {'aria-hidden': 'true'},
                    ),
                  ],
                  classes: resolved.row.className,
                  styles: resolved.row.inlineStyles,
                  attributes: {
                    'role': 'listitem',
                    'aria-label': series.rowLabels[i],
                  },
                ),
            ]
          : [_donut(resolved), _legend(resolved)],
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: {
        ...componentAttributes,
        if (isBar) 'role': 'list' else 'role': 'group',
        'aria-label': ?semanticLabel,
      },
      events: this.events,
    );
  }

  Component _texts(
    ResolvedCategoryBreakdown resolved,
    WebElementChrome chrome,
    int i,
  ) => div(
    [
      span(
        [Text(items[i].label)],
        classes: resolved.label.className,
        styles: resolved.label.inlineStyles,
      ),
      span(
        [
          span(
            [Text(resolved.series.valueLabels[i])],
            classes: resolved.value.className,
            styles: resolved.value.inlineStyles,
          ),
          span(
            [Text(resolved.series.percentLabels[i])],
            classes: resolved.percent.className,
            styles: resolved.percent.inlineStyles,
          ),
        ],
        classes: resolved.trailing.className,
        styles: resolved.trailing.inlineStyles,
      ),
    ],
    classes: chrome.className,
    styles: chrome.inlineStyles,
    attributes: const {'aria-hidden': 'true'},
  );

  Component _donut(ResolvedCategoryBreakdown resolved) {
    final series = resolved.series;
    return div(
      [
        Component.element(
          tag: 'svg',
          classes: resolved.donutSvg.className,
          styles: resolved.donutSvg.inlineStyles,
          attributes: const {'viewBox': '0 0 100 100', 'aria-hidden': 'true'},
          children: [
            // Arcs start at the top and run clockwise, as on Flutter.
            Component.element(
              tag: 'g',
              attributes: const {'transform': 'rotate(-90 50 50)'},
              children: [
                for (var i = 0; i < items.length; i++)
                  Component.element(
                    tag: 'circle',
                    classes: resolved.arcs[i].className,
                    styles: resolved.arcs[i].inlineStyles,
                    attributes: {
                      'cx': '50',
                      'cy': '50',
                      'r': series.ringRadius,
                      'fill': 'none',
                      'stroke': 'currentColor',
                    },
                  ),
              ],
            ),
          ],
        ),
        if (center case final currentCenter?)
          div(
            [currentCenter],
            classes: resolved.donutCenter.className,
            styles: resolved.donutCenter.inlineStyles,
          ),
      ],
      classes: resolved.donut.className,
      styles: resolved.donut.inlineStyles,
    );
  }

  Component _legend(ResolvedCategoryBreakdown resolved) => div(
    [
      for (var i = 0; i < items.length; i++)
        div(
          [
            span(
              const [],
              classes: resolved.swatches[i].className,
              styles: resolved.swatches[i].inlineStyles,
              attributes: const {'aria-hidden': 'true'},
            ),
            _texts(resolved, resolved.legendTexts, i),
          ],
          classes: resolved.legendRow.className,
          styles: resolved.legendRow.inlineStyles,
          attributes: {
            'role': 'listitem',
            'aria-label': resolved.series.rowLabels[i],
          },
        ),
    ],
    classes: resolved.legend.className,
    styles: resolved.legend.inlineStyles,
    attributes: const {'role': 'list'},
  );

  @override
  CategoryBreakdown copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? tag,
    CoreCategoryBreakdownVariant? variant,
    List<CoreCategoryBreakdownItem>? items,
    Component? center,
    Component? empty,
    String? semanticLabel,
    CoreCategoryBreakdownStyle? categoryBreakdownStyle,
  }) {
    return CategoryBreakdown(
      key: key ?? this.key,
      variant: variant ?? this.variant,
      items: items ?? this.items,
      center: center ?? this.center,
      empty: empty ?? this.empty,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      categoryBreakdownStyle:
          categoryBreakdownStyle ?? this.categoryBreakdownStyle,
      attributes: attributes ?? componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }
}

/// Chain sugar mirroring the Flutter `CategoryBreakdown.withStyle`
/// extension.
extension CategoryBreakdownStyleChain on CategoryBreakdown {
  /// Returns a copy with [patch] merged into [categoryBreakdownStyle]
  /// (patch fields win on conflict).
  CategoryBreakdown withStyle(CoreCategoryBreakdownStyle patch) => copyWith(
    categoryBreakdownStyle:
        (categoryBreakdownStyle ?? const CoreCategoryBreakdownStyle()).merge(
          patch,
        ),
  );
}
