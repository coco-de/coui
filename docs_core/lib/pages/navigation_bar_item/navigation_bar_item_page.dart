/// NavigationBarItem 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `navigation_bar_item_web.dart` · `navigation_bar_item_flutter.dart` 가
/// 그린다. 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 위젯 생성자의 이름을 그대로 쓴다 — `mode` · `indicator` ·
/// `selectionMark` · `labelMode`(각 enum 의 이름) · `selected` · `enabled` ·
/// `showDot`, 그리고 개수 배지에 적을 글 `badge`.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/navigation-bar-item.md`.
const String slug = 'navigation-bar-item';

/// 미리보기 · 코드가 함께 쓰는 목적지 이름.
const String navigationBarItemPreviewLabel = '받은편지함';

/// 이름 자리 장면에 쓰는 짧은 이름.
const String navigationBarItemShortLabel = '설정';

/// 긴 이름 장면의 이름.
const String navigationBarItemLongLabel = '확인하지 않은 받은편지함과 보관함';

/// 개수 배지에 적는 숫자.
const String navigationBarItemPreviewCount = '3';

/// 긴 이름 장면의 개수.
const String navigationBarItemLongCount = '12';

/// 목록 장면의 줄 — 이름, 아이콘, 활성 여부. 첫 줄이 지금 있는 곳이다.
const List<(String, IconName, bool)> navigationBarItemListRows = [
  (navigationBarItemPreviewLabel, LucideIcons.inbox, true),
  ('알림', LucideIcons.bell, true),
  (navigationBarItemShortLabel, LucideIcons.settings, true),
  ('관리자', LucideIcons.lock, false),
];

/// 상태 장면의 줄 — 이름, 선택 여부, 활성 여부.
const List<(String, bool, bool)> navigationBarItemStateRows = [
  ('기본', false, true),
  ('선택', true, true),
  ('비활성', false, false),
  ('선택 · 비활성', true, false),
];

/// 속성의 `mode` — 없거나 모르는 값은 단독 항목의 기본값
/// (`CoreNavigationBarItemContract.defaultMode`, 사이드바 줄).
CoreNavigationBarMode navigationBarItemMode(Map<String, String> props) =>
    previewEnum(CoreNavigationBarMode.values, props['mode'], CoreNavigationBarItemContract.defaultMode);

/// [mode] 의 항목이 hover · 포커스 · 눌림 색을 섞는 바탕색 — 그 모드의
/// 내비게이션 바 바탕이다. 미리보기는 항목을 이 색의 판 위에 놓는다.
CoreColor navigationBarItemFace(CoreNavigationBarMode mode) =>
    CoreNavigationBarStyle.defaultsByMode[mode]!.backgroundColor ??
    CoreNavigationBarStyle.defaultsByVariant[CoreNavigationBarVariant.defaultVariant]!.backgroundColor;

/// 미리보기 판의 폭(logical px) — 사이드바 줄은 240, 이름을 아이콘 아래에
/// 쌓는 바 · 레일 목적지는 바 칸의 상한인 96.
double navigationBarItemPreviewWidth(CoreNavigationBarMode mode) =>
    mode.isSidebar ? CoreLayout.layout240 : CoreSize.size96;

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'mode': 'sidebar', 'selected': 'true'},
  label: navigationBarItemPreviewLabel,
  controls: [
    DocsPlaygroundChoice(label: 'mode', prop: 'mode', options: ['sidebar', 'rail', 'bar'], segmented: true),
    DocsPlaygroundFlag(label: '선택', on: {'selected': 'true'}),
    DocsPlaygroundFlag(label: '개수 배지', on: {'badge': navigationBarItemPreviewCount}),
    DocsPlaygroundFlag(label: '알림 점', on: {'showDot': 'true'}),
    DocsPlaygroundFlag(label: '이름 숨김', on: {'labelMode': 'none'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _navigationBarItemCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// NavigationBarItem 에는 `size` 파라미터가 없다 — 치수는 `mode` 가 고르는
/// `CoreNavigationBarStyle` 의 기본값이다.
DocsSizeSpec Function()? get sizeSpec => null;

String _navigationBarItemCode(Map<String, String> props, String? label) {
  final mode = navigationBarItemMode(props);
  final count = props['badge'];
  final lines = [
    // 기본값은 적지 않는다.
    if (mode != CoreNavigationBarItemContract.defaultMode) 'mode: CoreNavigationBarMode.${mode.name},',
    'icon: Icon(LucideIcons.inbox),',
    "label: '${label ?? navigationBarItemPreviewLabel}',",
    if (count != null) ...[
      'badge: Badge(',
      '  form: CoreBadgeForm.count,',
      '  tone: CoreBadgeTone.info,',
      '  variant: CoreBadgeVariant.filled,',
      '  size: CoreComponentSize.xs,',
      "  child: Text('$count'),",
      '),',
    ],
    if (previewFlag(props, 'showDot')) 'showDot: true,',
    if (props['labelMode'] case final labelMode?) 'labelMode: CoreNavigationLabelMode.$labelMode,',
    if (previewFlag(props, 'selected')) 'selected: true,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onPressed: openInbox,',
  ];
  return 'NavigationBarItem(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
