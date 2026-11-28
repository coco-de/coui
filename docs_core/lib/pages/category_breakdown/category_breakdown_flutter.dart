/// CategoryBreakdown 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="category-breakdown/...">` 와 카드가 읽는다. 같은 이름의 Web
/// 파일(`category_breakdown_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'category_breakdown_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _categoryBreakdown;

/// 장면 이름(`category-breakdown/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'category-breakdown/anatomy': () => _framed(
    page.categoryBreakdownDemoWidth,
    CategoryBreakdown(
      semanticLabel: page.categoryBreakdownDemoLabel,
      items: page.categoryBreakdownDemoItems.sublist(0, 2),
    ),
  ),
  'category-breakdown/anatomy-donut': () => _framed(
    page.categoryBreakdownWideDonutWidth,
    _donut(page.categoryBreakdownDemoItems.sublist(0, 3)),
  ),
  'category-breakdown/rounding': () => _framed(
    page.categoryBreakdownDemoWidth,
    const CategoryBreakdown(semanticLabel: '접수 경로별 분포', items: page.categoryBreakdownThirdItems),
  ),
  'category-breakdown/states': () => _stack([
    _captioned(
      '항목 없음 · empty',
      CategoryBreakdown(
        semanticLabel: page.categoryBreakdownDemoLabel,
        items: const [],
        empty: const Text('이번 달에는 문의가 없어요').bodyMedium.onSurfaceVariant,
      ),
    ),
    _captioned(
      '값이 0 인 항목',
      const CategoryBreakdown(
        semanticLabel: page.categoryBreakdownDemoLabel,
        items: page.categoryBreakdownZeroItems,
      ),
    ),
    _captioned('항목 하나 · donut', _donut(page.categoryBreakdownDemoItems.sublist(0, 1))),
  ]),
  'category-breakdown/do-bar': () => const CategoryBreakdown(
    semanticLabel: page.categoryBreakdownDemoLabel,
    items: page.categoryBreakdownLongItems,
  ),
  'category-breakdown/dont-mixed': () => const CategoryBreakdown(
    semanticLabel: page.categoryBreakdownDemoLabel,
    items: page.categoryBreakdownMixedItems,
  ),
  'category-breakdown/do-grouped': () => const CategoryBreakdown(
    semanticLabel: page.categoryBreakdownDemoLabel,
    items: page.categoryBreakdownDemoItems,
  ),
  'category-breakdown/dont-many': () => const CategoryBreakdown(
    semanticLabel: page.categoryBreakdownDemoLabel,
    items: page.categoryBreakdownManyItems,
  ),
  'category-breakdown/do-short-center': () => _donut(page.categoryBreakdownDemoItems.sublist(0, 3)),
  'category-breakdown/dont-long-center': () => _donut(
    page.categoryBreakdownDemoItems.sublist(0, 3),
    centerText: '이번 달에 접수한 전체 문의 222건',
  ),
  'category-breakdown/placement-wrap': () => _framed(
    page.categoryBreakdownWrapWidth,
    const CategoryBreakdown(
      semanticLabel: page.categoryBreakdownDemoLabel,
      items: page.categoryBreakdownWrapItems,
    ),
  ),
  'category-breakdown/placement-legend': () => _stack([
    _captioned(
      '넓은 상자',
      _framed(page.categoryBreakdownWideDonutWidth, _donut(page.categoryBreakdownDemoItems.sublist(0, 3))),
    ),
    _captioned(
      '좁은 상자',
      _framed(page.categoryBreakdownNarrowDonutWidth, _donut(page.categoryBreakdownDemoItems.sublist(0, 3))),
    ),
  ]),
  'category-breakdown/styled': () => _framed(
    page.categoryBreakdownDemoWidth,
    const CategoryBreakdown(
      semanticLabel: page.categoryBreakdownDemoLabel,
      items: page.categoryBreakdownDemoItems,
      categoryBreakdownStyle: page.categoryBreakdownDemoStyle,
    ),
  ),
  'category-breakdown/related-trend-chart': () => _framed(
    CoreSpace.space256,
    TrendChart(
      semanticLabel: '월별 문의 추이',
      points: [
        CoreTrendPoint(date: DateTime(2026, 6), value: 180, label: '6월', valueLabel: '180건'),
        CoreTrendPoint(date: DateTime(2026, 7), value: 210, label: '7월', valueLabel: '210건'),
        CoreTrendPoint(date: DateTime(2026, 8), value: 196, label: '8월', valueLabel: '196건'),
        CoreTrendPoint(date: DateTime(2026, 9), value: 234, label: '9월', valueLabel: '234건'),
      ],
    ),
  ),
  'category-breakdown/related-progress': () => const SizedBox(width: CoreSpace.space192, child: Progress(value: 0.55)),
  'category-breakdown/related-stat': () => const Stat(label: '총 문의', value: '234', unit: '건'),
};

Widget _categoryBreakdown(Map<String, String> props, String? label) {
  final variant = previewEnum(
    CoreCategoryBreakdownVariant.values,
    props['variant'],
    CoreCategoryBreakdownVariant.defaultVariant,
  );
  final items = page.categoryBreakdownPropItems(props);
  return CategoryBreakdown(
    variant: variant,
    semanticLabel: page.categoryBreakdownDemoLabel,
    center: variant == CoreCategoryBreakdownVariant.donut
        ? Text(page.categoryBreakdownTotal(items)).titleMedium.semiBold
        : null,
    items: items,
    categoryBreakdownStyle: page.categoryBreakdownPropStyle(props),
  );
}

/// 가운데에 글을 넣은 도넛. [centerText] 가 없으면 항목의 합계를 적는다.
Widget _donut(List<CoreCategoryBreakdownItem> items, {String? centerText}) => CategoryBreakdown(
  variant: CoreCategoryBreakdownVariant.donut,
  semanticLabel: page.categoryBreakdownDemoLabel,
  center: Text(centerText ?? page.categoryBreakdownTotal(items)).titleMedium.semiBold,
  items: items,
);

/// 폭의 상한을 [maxWidth] 로 둔다. CategoryBreakdown 은 받은 폭을 채우므로
/// 상한이 그대로 장면의 폭이 된다.
Widget _framed(double maxWidth, Widget child) => ConstrainedBox(
  constraints: BoxConstraints(maxWidth: maxWidth),
  child: child,
);

/// 이름을 단 장면을 위에서 아래로 쌓는다.
Widget _stack(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space32,
  children: children,
);

/// 장면 위에 이름을 적는다. 폭은 가장 넓은 도넛 장면까지다.
Widget _captioned(String caption, Widget child) => _framed(
  page.categoryBreakdownWideDonutWidth,
  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space8,
    children: [Text(caption).labelSmall.onSurfaceVariant, child],
  ),
);
