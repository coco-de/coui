/// CategoryBreakdown 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="category-breakdown/...">` 와 카드가 읽는다. 같은 이름의
/// Flutter 파일(`category_breakdown_flutter.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'category_breakdown_page.dart' as page;

/// 속성 → Component.
///
/// `variant` · `count` · `rawValue` · `colors` 를 읽는다. 도넛에는 합계를
/// 가운데에 넣는다.
WebPropPreviewBuilder? get propPreview => _categoryBreakdown;

/// 장면 이름(`category-breakdown/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 블록이 장면을 상자 하나에 더 담고 그 상자의 폭은 내용이 정하므로
  // 폭을 정한다. 좁은 화면에서도 좌우에 번호 자리가 남게 화면 폭에서 여백을 뺀다.
  'category-breakdown/anatomy': () => _anatomyFrame(
    page.categoryBreakdownDemoWidth,
    CategoryBreakdown(
      semanticLabel: page.categoryBreakdownDemoLabel,
      items: page.categoryBreakdownDemoItems.sublist(0, 2),
    ),
  ),
  'category-breakdown/anatomy-donut': () => _anatomyFrame(
    page.categoryBreakdownWideDonutWidth,
    _donut(page.categoryBreakdownDemoItems.sublist(0, 3)),
  ),
  'category-breakdown/rounding': () => _sized(
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
  'category-breakdown/placement-wrap': () => _sized(
    page.categoryBreakdownWrapWidth,
    const CategoryBreakdown(
      semanticLabel: page.categoryBreakdownDemoLabel,
      items: page.categoryBreakdownWrapItems,
    ),
  ),
  'category-breakdown/placement-legend': () => _stack([
    _captioned(
      '넓은 상자',
      _sized(page.categoryBreakdownWideDonutWidth, _donut(page.categoryBreakdownDemoItems.sublist(0, 3))),
    ),
    _captioned(
      '좁은 상자',
      _sized(page.categoryBreakdownNarrowDonutWidth, _donut(page.categoryBreakdownDemoItems.sublist(0, 3))),
    ),
  ]),
  'category-breakdown/styled': () => _sized(
    page.categoryBreakdownDemoWidth,
    const CategoryBreakdown(
      semanticLabel: page.categoryBreakdownDemoLabel,
      items: page.categoryBreakdownDemoItems,
      categoryBreakdownStyle: page.categoryBreakdownDemoStyle,
    ),
  ),
  'category-breakdown/related-trend-chart': () => _sized(
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
  'category-breakdown/related-progress': () => _sized(CoreSpace.space192, const Progress(value: 0.55)),
  'category-breakdown/related-stat': () => const Stat(label: '총 문의', value: '234', unit: '건'),
};

Component _categoryBreakdown(Map<String, String> props, String? label) {
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
Component _donut(List<CoreCategoryBreakdownItem> items, {String? centerText}) => CategoryBreakdown(
  variant: CoreCategoryBreakdownVariant.donut,
  semanticLabel: page.categoryBreakdownDemoLabel,
  center: Text(centerText ?? page.categoryBreakdownTotal(items)).titleMedium.semiBold,
  items: items,
);

/// 구조 장면의 폭 — [width] 이하이고, 좁은 화면에서는 화면 폭에서 번호 자리를 뺀다.
/// 위 여백은 범례가 아래로 내려가 장면이 길어져도 도넛 위의 번호가 무대 선에
/// 걸치지 않게 하는 자리다.
Component _anatomyFrame(double width, Component child) => div(
  styles: Styles(
    raw: {
      'width': 'min(${pinnedLengthCss(width)}, calc(100vw - ${pinnedLengthCss(CoreSpace.space128)}))',
      'padding-top': spaceCss(CoreSpace.space12),
    },
  ),
  [child],
);

/// 폭을 [width] 로 정한 상자 — 무대가 더 좁으면 무대 폭을 따른다.
Component _sized(double width, Component child) => div(
  styles: Styles(raw: {'width': 'min(100%, ${pinnedLengthCss(width)})'}),
  [child],
);

/// 이름을 단 장면을 위에서 아래로 쌓는다.
Component _stack(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': spaceCss(CoreSpace.space32),
      'width': '100%',
    },
  ),
  children,
);

/// 장면 위에 이름을 적는다. 폭은 가장 넓은 도넛 장면까지다.
Component _captioned(String caption, Component child) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': spaceCss(CoreSpace.space8),
      'width': 'min(100%, ${pinnedLengthCss(page.categoryBreakdownWideDonutWidth)})',
    },
  ),
  [Text(caption).labelSmall.onSurfaceVariant, child],
);
