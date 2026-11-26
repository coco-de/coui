/// TabPane 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `tab_pane_web.dart` · `tab_pane_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성: `variant`(`CoreTabPaneVariant` 의 이름)와 `reorderable` 은 위젯 속성
/// 그대로다. `itemLeading`(탭의 `leading`에 파일 아이콘) · `badge`(첫 탭의 배지
/// 숫자) · `onClose`(모든 탭에 닫기 버튼) · `disabled`(비활성 탭의 처음 자리)는
/// 탭(`CoreTabItem`)에 붙는다. 해석은 두 플랫폼이 같다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/tab-pane.md`.
const String slug = 'tab-pane';

/// `boxed` 미리보기 탭의 라벨.
const List<String> kTabPanePreviewLabels = ['계정', '비밀번호', '알림'];

/// `boxed` 미리보기 탭의 패널 글 — [kTabPanePreviewLabels] 와 같은 순서.
const List<String> kTabPanePreviewContents = ['계정 설정을 관리해요.', '여기에서 비밀번호를 바꿔요.', '받을 알림을 골라요.'];

/// `editorStrip` 미리보기 탭의 라벨(파일 이름).
const List<String> kTabPanePreviewFiles = ['main.dart', 'app.dart', 'theme.dart'];

/// 넘치는 탭 장면의 라벨 — 좁은 폭에 다 들어가지 않는 개수.
const List<String> kTabPaneScrollLabels = ['계정', '비밀번호', '알림', '결제', '연동'];

/// 구조 장면의 라벨. 첫 탭 앞의 파일 아이콘이 뜻을 갖는 이름이다.
const List<String> kTabPaneAnatomyLabels = ['문서', '설정', '알림'];

/// 편집기 탭 줄 장면에서 탭 줄 아래에 호출자가 그리는 본문 글.
const String kTabPaneEditorBody = 'void main() {}';

/// 탭 바 뒤 버튼 장면의 버튼 접근성 이름.
const String kTabPaneAddLabel = '새 파일';

/// 플레이그라운드와 상태 장면의 폭(logical px).
const double kTabPanePreviewWidth = 320;

/// 구조 장면의 폭(logical px) — 번호를 놓을 자리가 남는 폭.
const double kTabPaneAnatomyWidth = 448;

/// 탭 줄 · 슬롯 장면의 폭(logical px).
const double kTabPaneWideWidth = 440;

/// Variant 행 장면의 폭(logical px) — 좁은 무대에 두 탭이 들어가는 폭.
const double kTabPaneVariantRowWidth = 180;

/// 사용 가이드 · 배치 카드 장면의 폭(logical px).
const double kTabPaneCardWidth = 280;

/// 넘치는 탭 장면의 폭(logical px).
const double kTabPaneScrollWidth = 240;

/// 관련 컴포넌트 카드 장면의 폭(logical px).
const double kTabPaneRelatedWidth = 192;

/// 속성의 `variant` — 없거나 모르는 이름이면 계약의 기본값(`boxed`).
CoreTabPaneVariant tabPanePreviewVariant(Map<String, String> props) =>
    previewEnum(CoreTabPaneVariant.values, props['variant'], CoreTabPaneVariant.defaultVariant);

/// [variant] 미리보기 탭의 라벨. 라벨은 서로 달라 순서를 바꿔도 탭을 찾을 수 있다.
List<String> tabPanePreviewLabels(CoreTabPaneVariant variant) => switch (variant) {
  CoreTabPaneVariant.boxed => kTabPanePreviewLabels,
  CoreTabPaneVariant.editorStrip => kTabPanePreviewFiles,
};

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'variant': 'boxed'},
  controls: [
    DocsPlaygroundChoice(label: 'variant', prop: 'variant', options: ['boxed', 'editorStrip'], segmented: true),
    DocsPlaygroundFlag(label: '앞 아이콘', on: {'itemLeading': 'true'}),
    DocsPlaygroundFlag(label: '배지', on: {'badge': '3'}),
    DocsPlaygroundFlag(label: '닫기 버튼', on: {'onClose': 'true'}),
    DocsPlaygroundFlag(label: '비활성 탭', on: {'disabled': '2'}),
    DocsPlaygroundFlag(label: '끌어서 순서 바꾸기', on: {'reorderable': 'true'}),
  ],
  code: _tabPaneCode,
  webCode: _tabPaneWebCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// TabPane 에는 `size` 속성이 없고 `CoreTabPaneStyle` 에는 `defaultsBySize` 가 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _tabPaneCode(Map<String, String> props, String? label) => _tabPaneSnippet(props, _flutterContent);

String _tabPaneWebCode(Map<String, String> props, String? label) => _tabPaneSnippet(props, _webContent);

/// Flutter 의 패널 글 — `space20` 여백 안의 설명 한 줄.
List<String> _flutterContent(String text) => [
  'content: Padding(',
  '  padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),',
  "  child: Text('$text').bodyMedium.onSurfaceVariant,",
  '),',
];

/// Web 의 패널 글 — `space20` 여백 안의 설명 한 줄.
List<String> _webContent(String text) => [
  'content: div(',
  "  [Text('$text').bodyMedium.onSurfaceVariant],",
  r"  classes: 'p-${CoreSpace.scale.space20}',",
  '),',
];

/// 두 플랫폼이 같이 쓰는 생성자 줄 — 패널 글([content])만 다르다. `editorStrip` 은
/// 패널이 없어 두 플랫폼의 코드가 같다.
String _tabPaneSnippet(Map<String, String> props, List<String> Function(String text) content) {
  final variant = tabPanePreviewVariant(props);
  final boxed = variant == CoreTabPaneVariant.boxed;
  final labels = tabPanePreviewLabels(variant);
  final leading = previewFlag(props, 'itemLeading');
  final badge = props['badge'];
  final closable = previewFlag(props, 'onClose');
  final disabled = int.tryParse(props['disabled'] ?? '');
  final reorderable = previewFlag(props, 'reorderable');

  List<String> item(int index) {
    final fields = [
      "label: '${labels[index]}',",
      if (leading) 'leading: Icon(LucideIcons.file),',
      if (index == 0 && badge != null)
        'badge: Badge(variant: CoreBadgeVariant.filled, form: CoreBadgeForm.count, '
            "size: CoreComponentSize.xs, child: Text('$badge')),",
      if (index == disabled) 'enabled: false,',
      if (closable) 'onClose: () => closeTab($index),',
      if (boxed) ...content(kTabPanePreviewContents[index]),
    ];
    if (fields.length == 1) return ["CoreTabItem(label: '${labels[index]}'),"];
    return ['CoreTabItem(', for (final field in fields) '  $field', '),'];
  }

  final constItems = !boxed && !leading && badge == null && !closable;
  final lines = [
    if (!boxed) 'variant: CoreTabPaneVariant.${variant.name},',
    'tabs: ${constItems ? 'const ' : ''}[',
    for (var index = 0; index < labels.length; index++)
      for (final line in item(index)) '  $line',
    '],',
    'selectedIndex: index,',
    'onChanged: (i) => setState(() => index = i),',
    if (reorderable) 'reorderable: true,',
    if (reorderable) 'onReorder: reorderTabs,',
  ];
  return 'TabPane(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
