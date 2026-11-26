/// NavigationBar 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `navigation_bar_web.dart` · `navigation_bar_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 크기 축이 없어 크기 표는 없다 — 밀도는 `mode` 가 정한다.
///
/// 속성은 위젯 생성자의 이름을 그대로 쓴다 — `mode` · `labelMode` ·
/// `indicator` · `selectionMark`(각 enum 의 이름). `labelMode` · `indicator` 의
/// `default` 는 넘기지 않는다는 뜻이다. 그 밖에 `badge`(둘째 목적지의 개수) ·
/// `showDot`(셋째 목적지의 알림 점) · `disabled`(비활성 목적지의 번호) ·
/// `icons=false`(라벨만 있는 글자 탭) · `surfaceStyle=liquidGlass` 를 읽는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/navigation-bar.md`.
const String slug = 'navigation-bar';

/// 미리보기 · 코드가 함께 쓰는 목적지 — 라벨, 아이콘, 코드에 적는 아이콘 이름.
const List<(String, IconName, String)> navigationBarPreviewItems = [
  ('홈', LucideIcons.house, 'LucideIcons.house'),
  ('편지함', LucideIcons.inbox, 'LucideIcons.inbox'),
  ('알림', LucideIcons.bell, 'LucideIcons.bell'),
];

/// 둘째 목적지의 개수 배지에 적는 숫자.
const String navigationBarPreviewCount = '3';

/// `footer` 장면에 두는 글.
const String navigationBarPreviewFooter = '내 계정';

/// 리퀴드 글래스를 한 인스턴스에만 켜는 덮어쓰기.
const CoreNavigationBarStyle navigationBarPreviewGlassStyle = CoreNavigationBarStyle(
  surfaceStyle: CoreSurfaceStyleId.liquidGlass,
);

/// 상태 장면의 첫 묶음 — 라벨, 아이콘, 활성 여부. 첫 칸이 선택된 곳이다.
const List<(String, IconName, bool)> navigationBarStateItems = [
  ('선택', LucideIcons.house, true),
  ('기본', LucideIcons.inbox, true),
  ('비활성', LucideIcons.bell, false),
];

/// 상태 장면의 둘째 묶음 — 선택된 첫 칸이 비활성이다.
const List<(String, IconName, bool)> navigationBarDisabledSelectedItems = [
  ('선택·비활성', LucideIcons.house, false),
  ('기본', LucideIcons.inbox, true),
];

/// 상태 장면에서 color 바 한 줄의 폭(logical px).
const double navigationBarStateBarWidth = CoreLayout.layout240;

/// 글자 탭 장면의 목적지 라벨.
const List<String> navigationBarTextTabLabels = ['홈', '지도', '채팅', '내 정보'];

/// 긴 라벨을 보이는 "하지 마세요" 장면의 목적지 — 라벨, 아이콘.
const List<(String, IconName)> navigationBarLongItems = [
  ('나의 홈 화면 보기', LucideIcons.house),
  ('받은 편지함과 보관함', LucideIcons.inbox),
  ('확인하지 않은 알림', LucideIcons.bell),
];

/// `badge-footer` 장면의 레일 높이(logical px). 높이를 정해 줘야 `footer` 가 아래 끝에 선다.
const double navigationBarFooterSceneHeight = 352;

/// 배치 장면 화면 틀의 폭(logical px).
const double navigationBarPlacementWidth = CoreLayout.layout240;

/// 배치 장면 화면 틀의 높이(logical px). 세 목적지의 레일이 스크롤 없이 선다.
const double navigationBarPlacementHeight = CoreLayout.layout240;

/// 속성의 `mode` — 없거나 모르는 값은 기본값 bar.
CoreNavigationBarMode navigationBarPreviewMode(Map<String, String> props) =>
    previewEnum(CoreNavigationBarMode.values, props['mode'], CoreNavigationBarMode.defaultMode);

/// 속성의 `labelMode` — 없거나 `default` 면 `null`(모드의 기본값). 글자 탭은
/// 라벨이 목적지의 전부라 `all` 로 둔다.
CoreNavigationLabelMode? navigationBarPreviewLabelMode(Map<String, String> props) {
  if (!previewFlag(props, 'icons', fallback: true)) return CoreNavigationLabelMode.all;
  for (final value in CoreNavigationLabelMode.values) {
    if (value.name == props['labelMode']) return value;
  }
  return null;
}

/// 속성의 `indicator` — 없거나 `default` 면 `null`(모드의 기본값).
CoreNavigationSelectionIndicator? navigationBarPreviewIndicator(Map<String, String> props) {
  for (final value in CoreNavigationSelectionIndicator.values) {
    if (value.name == props['indicator']) return value;
  }
  return null;
}

/// 속성의 `selectionMark` — 없으면 점을 그리지 않는다.
CoreNavigationSelectionMark navigationBarPreviewSelectionMark(Map<String, String> props) => previewEnum(
  CoreNavigationSelectionMark.values,
  props['selectionMark'],
  CoreNavigationSelectionMark.defaultSelectionMark,
);

/// 플레이그라운드.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'mode': 'bar'},
  controls: [
    DocsPlaygroundChoice(label: 'mode', prop: 'mode', options: ['bar', 'rail'], segmented: true),
    DocsPlaygroundChoice(label: 'labelMode', prop: 'labelMode', options: ['default', 'all', 'selected', 'none']),
    DocsPlaygroundChoice(label: 'indicator', prop: 'indicator', options: ['default', 'fill', 'color'], segmented: true),
    DocsPlaygroundFlag(label: '개수 배지', on: {'badge': navigationBarPreviewCount}),
    DocsPlaygroundFlag(label: '알림 점', on: {'showDot': 'true'}),
    DocsPlaygroundFlag(label: '선택 점', on: {'selectionMark': 'dot'}),
    DocsPlaygroundFlag(label: '글자 탭', on: {'icons': 'false'}),
    DocsPlaygroundFlag(label: '비활성 목적지', on: {'disabled': '2'}),
    DocsPlaygroundFlag(label: '리퀴드 글래스', on: {'surfaceStyle': 'liquidGlass'}),
  ],
  code: _navigationBarCode,
);

/// 크기 표. `NavigationBar` 는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _navigationBarCode(Map<String, String> props, String? label) {
  final mode = navigationBarPreviewMode(props);
  final labelMode = navigationBarPreviewLabelMode(props);
  final indicator = navigationBarPreviewIndicator(props);
  final selectionMark = navigationBarPreviewSelectionMark(props);

  final lines = [
    if (mode != CoreNavigationBarMode.defaultMode) 'mode: CoreNavigationBarMode.${mode.name},',
    'selectedIndex: index,',
    'onSelected: (value) => setState(() => index = value),',
    if (labelMode != null) 'labelMode: CoreNavigationLabelMode.${labelMode.name},',
    if (indicator != null) 'indicator: CoreNavigationSelectionIndicator.${indicator.name},',
    if (selectionMark != CoreNavigationSelectionMark.defaultSelectionMark)
      'selectionMark: CoreNavigationSelectionMark.${selectionMark.name},',
    if (props['surfaceStyle'] == 'liquidGlass') ...[
      'navigationBarStyle: const CoreNavigationBarStyle(',
      '  surfaceStyle: CoreSurfaceStyleId.liquidGlass,',
      '),',
    ],
    'items: const [',
    for (var index = 0; index < navigationBarPreviewItems.length; index++)
      for (final line in _navigationBarItemCode(props, index)) '  $line',
    '],',
  ];
  return 'NavigationBar(\n${lines.map((line) => '  $line').join('\n')}\n)';
}

List<String> _navigationBarItemCode(Map<String, String> props, int index) {
  final (text, _, iconCode) = navigationBarPreviewItems[index];
  final count = props['badge'];
  final fields = [
    if (previewFlag(props, 'icons', fallback: true)) 'icon: Icon($iconCode),',
    "label: '$text',",
    if (index == 1 && count != null) ...[
      'badge: Badge(',
      '  form: CoreBadgeForm.count,',
      '  tone: CoreBadgeTone.info,',
      '  variant: CoreBadgeVariant.filled,',
      '  size: CoreComponentSize.xs,',
      "  child: Text('$count'),",
      '),',
    ],
    if (index == 2 && previewFlag(props, 'showDot')) 'showDot: true,',
    if (int.tryParse(props['disabled'] ?? '') == index) 'enabled: false,',
  ];
  return [
    'CoreNavigationBarItem.destination(',
    for (final field in fields) '  $field',
    '),',
  ];
}
