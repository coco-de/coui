/// NavigationMenu 페이지 — 플레이그라운드와 미리보기가 같이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `navigation_menu_web.dart` · `navigation_menu_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 글자와 항목은 아래 상수 한 곳에 둔다 — 두 플랫폼의 그림과
/// 플레이그라운드의 코드가 같은 항목을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/navigation-menu.md`.
const String slug = 'navigation-menu';

/// 미리보기의 항목 하나 — `body` 가 있으면 패널을 여는 항목, `href` 가 있으면
/// 링크 항목, 둘 다 없으면 동작 항목이다.
typedef DemoMenuItem = ({String label, String? body, String? href});

/// 첫 번째 패널 항목의 라벨.
const String demoProducts = '제품';

/// 첫 번째 패널 항목의 패널 글.
const String demoProductsBody = '웹 앱과 모바일 앱을 만들어요.';

/// 두 번째 패널 항목의 라벨.
const String demoSolutions = '솔루션';

/// 두 번째 패널 항목의 패널 글.
const String demoSolutionsBody = '팀 규모에 맞는 구성을 골라요.';

/// 동작 항목의 라벨.
const String demoPricing = '요금제';

/// 링크 항목의 라벨.
const String demoDocs = '문서';

/// 링크 항목의 주소 — 정적 미리보기의 링크는 눌리므로 실재하는 페이지를 쓴다.
const String demoDocsHref = '/components/navigation-menu';

/// 구조 그림의 패널에 담는 줄 — 제목과 설명.
const List<(String, String)> demoRichEntries = [
  ('웹 앱', '최신 웹 경험을 만들어요'),
  ('모바일 앱', 'iOS와 Android 네이티브 앱'),
];

/// 패널 항목 둘과 동작 항목 하나.
const List<DemoMenuItem> demoBasicItems = [
  (label: demoProducts, body: demoProductsBody, href: null),
  (label: demoSolutions, body: demoSolutionsBody, href: null),
  (label: demoPricing, body: null, href: null),
];

/// 세 가지 항목 종류를 하나씩 — 패널 · 링크 · 동작.
const List<DemoMenuItem> demoKindItems = [
  (label: demoProducts, body: demoProductsBody, href: null),
  (label: demoDocs, body: null, href: demoDocsHref),
  (label: demoPricing, body: null, href: null),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 열린 모습의 그림
/// 아래에 실제 `NavigationMenu` 를 둔다. 플레이그라운드만 켠다: 사이트의 다른
/// 무대는 브라우저에서 깨어나지 않아 항목을 눌러도 아무것도 열리지 않는다.
/// `action` 은 동작 항목(`onTap`)을 더하는 손잡이다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'triggerSpacing': '2', 'menuOffset': '4', 'action': 'true', 'opener': 'true'},
  controls: [
    DocsPlaygroundChoice(label: 'triggerSpacing', prop: 'triggerSpacing', options: ['2', '8'], segmented: true),
    DocsPlaygroundChoice(label: 'menuOffset', prop: 'menuOffset', options: ['4', '12'], segmented: true),
    DocsPlaygroundFlag(label: '동작 항목 (onTap)', on: {'action': 'true'}),
  ],
  code: _navigationMenuCode,
);

/// 크기 표. NavigationMenu 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성이 고른 항목 — 패널 항목 둘, `action` 이 켜지면 동작 항목을 더한다.
List<DemoMenuItem> demoItemsOf(Map<String, String> props) => [
  demoBasicItems[0],
  demoBasicItems[1],
  if (previewFlag(props, 'action')) demoBasicItems[2],
];

/// 속성 `triggerSpacing` — `8` 이 아니면 기본값.
double demoTriggerSpacingOf(Map<String, String> props) =>
    props['triggerSpacing'] == '8' ? CoreSpace.space8 : CoreNavigationMenuStyle.defaultTriggerSpacing;

/// 속성 `menuOffset` — `12` 가 아니면 기본값.
double demoMenuOffsetOf(Map<String, String> props) =>
    props['menuOffset'] == '12' ? CoreSpace.space12 : CoreNavigationMenuStyle.defaultMenuOffset;

/// 속성이 고른 `navigationMenuStyle` — 기본값뿐이면 `null`.
CoreNavigationMenuStyle? demoStyleOf(Map<String, String> props) {
  final spacing = demoTriggerSpacingOf(props);
  final offset = demoMenuOffsetOf(props);
  final spacingChanged = spacing != CoreNavigationMenuStyle.defaultTriggerSpacing;
  final offsetChanged = offset != CoreNavigationMenuStyle.defaultMenuOffset;
  if (!spacingChanged && !offsetChanged) return null;
  return CoreNavigationMenuStyle(
    triggerSpacing: spacingChanged ? spacing : null,
    menuOffset: offsetChanged ? offset : null,
  );
}

String _navigationMenuCode(Map<String, String> props, String? label) {
  final spacingChanged = demoTriggerSpacingOf(props) != CoreNavigationMenuStyle.defaultTriggerSpacing;
  final offsetChanged = demoMenuOffsetOf(props) != CoreNavigationMenuStyle.defaultMenuOffset;
  final lines = [
    'items: [',
    for (final item in demoItemsOf(props)) ..._itemCode(item),
    '],',
    if (spacingChanged || offsetChanged) ...[
      'navigationMenuStyle: CoreNavigationMenuStyle(',
      if (spacingChanged) '  triggerSpacing: CoreSpace.space8,',
      if (offsetChanged) '  menuOffset: CoreSpace.space12,',
      '),',
    ],
  ];
  return 'NavigationMenu(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

List<String> _itemCode(DemoMenuItem item) {
  final body = item.body;
  if (body == null) return ["  CoreNavigationMenuItem(label: '${item.label}', onTap: openPricing),"];
  return [
    '  CoreNavigationMenuItem(',
    "    label: '${item.label}',",
    "    content: Text('$body').bodyMedium,",
    '  ),',
  ];
}
