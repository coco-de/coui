/// HoverCard 페이지 — 플레이그라운드와 미리보기가 같이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `hover_card_web.dart` · `hover_card_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 글자는 아래 상수 한 곳에 둔다 — 두 플랫폼의 그림과
/// 플레이그라운드의 코드가 같은 글자를 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/hover-card.md`.
const String slug = 'hover-card';

/// 속성 미리보기의 트리거 글자 — 태그가 `label` 을 주지 않을 때.
const String demoTrigger = '@coui';

/// 속성 미리보기의 카드 글.
const String demoBody = '크로스 플랫폼 UI 디자인 시스템.';

/// 폭 상한에서 줄을 바꾸는 긴 카드 글.
const String demoLongBody = 'Web과 Flutter에서 같은 이름의 API로 같은 화면을 만드는 UI 컴포넌트 모음이에요. 글이 길면 카드의 폭 상한에서 줄을 바꿔요.';

/// 실제 `HoverCard` 로 감싼 버튼의 글자 — 플레이그라운드에만 있다.
const String demoOpener = '올려 보기';

/// 프로필 미리 보기의 트리거 글자.
const String demoMention = '@hong';

/// 프로필 아바타의 머리글자.
const String demoProfileInitials = 'HG';

/// 프로필의 이름.
const String demoProfileName = '홍길동';

/// 프로필의 소개 줄.
const String demoProfileRole = '@hong · 프로덕트 디자이너';

/// 프로필의 숫자 줄.
const String demoProfileStats = '팔로워 128 · 팔로잉 64';

/// 링크 미리 보기의 트리거 글자이자 카드 제목.
const String demoLinkTitle = '설치 안내';

/// 링크 미리 보기의 요약.
const String demoLinkSummary = '패키지를 추가하고 앱 루트에 테마를 연결하는 방법을 설명해요.';

/// 설정 아이콘 트리거의 이름 — 피할 예.
const String demoSettingsName = '계정 설정';

/// 카드에만 둔 행동 — 피할 예.
const String demoOnlyAction = '계정 삭제';

/// 폼을 담은 카드의 트리거 글자 — 피할 예.
const String demoFormTrigger = '메모 남기기';

/// 폼을 담은 카드의 입력 라벨.
const String demoFormLabel = '메모';

/// 폼을 담은 카드의 저장 버튼.
const String demoFormSave = '저장';

/// 방향 장면의 카드 글.
const String demoSideBody = '카드';

/// 방향 장면이 보이는 네 방향.
const List<CorePopoverPlacement> demoSides = [
  CorePopoverPlacement.top,
  CorePopoverPlacement.bottom,
  CorePopoverPlacement.left,
  CorePopoverPlacement.right,
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 카드 그림 아래에
/// 실제 `HoverCard` 로 감싼 버튼을 둔다. 플레이그라운드만 켠다: 사이트의 다른
/// 무대는 브라우저에서 깨어나지 않아 그 버튼에 포인터를 올려도 열리지 않는다.
/// `long` 은 카드 글을 고르는 손잡이다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'placement': 'bottom', 'opener': 'true'},
  label: demoTrigger,
  controls: [
    DocsPlaygroundChoice(
      label: 'placement',
      prop: 'placement',
      options: ['top', 'bottom', 'left', 'right'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '긴 내용', on: {'long': 'true'}),
    DocsPlaygroundFlag(label: '바로 열기 (openDelay)', on: {'openDelay': '0'}),
  ],
  code: _hoverCardCode,
);

/// 크기 표. HoverCard 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `placement` — 없거나 모르는 값은 `bottom`.
CorePopoverPlacement demoPlacementOf(Map<String, String> props) =>
    previewEnum(CorePopoverPlacement.values, props['placement'], CorePopoverPlacement.bottom);

/// 속성이 고른 카드 글 — `long` 이면 긴 글.
String demoBodyOf(Map<String, String> props) => previewFlag(props, 'long') ? demoLongBody : demoBody;

/// 속성이 고른 `openDelay`(밀리초). 없으면 `null` — 컴포넌트의 기본값을 쓴다.
Duration? demoOpenDelayOf(Map<String, String> props) {
  final ms = int.tryParse(props['openDelay'] ?? '');
  return ms == null ? null : Duration(milliseconds: ms);
}

/// 카드가 트리거의 위나 아래에 놓이는가.
bool demoIsVertical(CorePopoverPlacement placement) =>
    placement.name.startsWith('top') || placement.name.startsWith('bottom');

/// 카드가 트리거보다 먼저(위 · 왼쪽) 놓이는가.
bool demoPanelFirst(CorePopoverPlacement placement) =>
    placement.name.startsWith('top') || placement.name.startsWith('left');

String _hoverCardCode(Map<String, String> props, String? label) {
  final placement = demoPlacementOf(props);
  final openDelay = demoOpenDelayOf(props);
  final lines = [
    if (placement != CorePopoverPlacement.bottom) 'placement: CorePopoverPlacement.${placement.name},',
    if (openDelay != null)
      openDelay == Duration.zero
          ? 'openDelay: Duration.zero,'
          : 'openDelay: Duration(milliseconds: ${openDelay.inMilliseconds}),',
    'trigger: Button(',
    '  variant: CoreButtonVariant.ghost,',
    '  onPressed: openProfile,',
    "  child: Text('${label ?? demoTrigger}'),",
    '),',
    "content: Text('${demoBodyOf(props)}').bodySmall.onSurface,",
  ];
  return 'HoverCard(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
