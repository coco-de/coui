/// Popup 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `popup_web.dart` · `popup_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// `Popup` 은 놓은 자리에 그대로 그려지는 패널 상자라 무대에 실제 위젯을
/// 놓는다. 속성은 둘이다: `padding`(`content` · `list` — Core 의 안쪽 여백
/// 두 값)과 `direction`(`CoreAxis` 의 이름). 두 플랫폼 빌더와 코드가 같은
/// 뜻으로 읽도록 해석과 미리보기의 글자는 이 파일에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/popup.md`.
const String slug = 'popup';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'padding': 'content', 'direction': 'vertical'},
  controls: [
    DocsPlaygroundChoice(label: '안쪽 여백', prop: 'padding', options: ['content', 'list'], segmented: true),
    DocsPlaygroundChoice(label: 'direction', prop: 'direction', options: ['vertical', 'horizontal'], segmented: true),
  ],
  code: _popupCode,
);

/// 크기 표. Popup 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 미리보기의 패널에 놓는 버튼 — (코드의 콜백 이름, 글자).
const List<(String, String)> popupDemoActions = [('rename', '이름 바꾸기'), ('copy', '복사'), ('remove', '삭제')];

/// 장면의 목록 패널에 놓는 행의 글자.
const List<String> popupDemoRows = ['프로필', '설정', '로그아웃'];

/// 자유 형식 내용 장면의 제목.
const String popupDemoNoticeTitle = '알림을 받을까요?';

/// 자유 형식 내용 장면의 설명.
const String popupDemoNoticeBody = '새 댓글이 달리면 알려 드려요.';

/// 자유 형식 내용 장면의 버튼 글자.
const String popupDemoNoticeAction = '알림 켜기';

/// 목록을 담는 패널의 스타일 — 안쪽 여백만 목록 값으로 바꾼다.
const CorePopupStyle popupDemoListStyle = CorePopupStyle(padding: CorePopupStyle.defaultListPadding);

/// 속성의 `direction` → 자식을 놓는 방향. 없거나 모르는 값은 세로.
CoreAxis popupPreviewDirection(Map<String, String> props) =>
    previewEnum(CoreAxis.values, props['direction'], CoreAxis.vertical);

/// 속성의 `padding` → 패널 스타일. `list` 만 목록 여백이고, 나머지는 스타일을
/// 주지 않아 기본값(내용 여백)으로 그린다.
CorePopupStyle? popupPreviewStyle(Map<String, String> props) => props['padding'] == 'list' ? popupDemoListStyle : null;

String _popupCode(Map<String, String> props, String? label) {
  final lines = [
    if (popupPreviewDirection(props) == CoreAxis.horizontal) 'direction: CoreAxis.horizontal,',
    if (popupPreviewStyle(props) != null) ...[
      'popupStyle: CorePopupStyle(',
      '  padding: CorePopupStyle.defaultListPadding,',
      '),',
    ],
    'children: [',
    for (final (callback, text) in popupDemoActions) ...[
      '  Button(',
      '    variant: CoreButtonVariant.ghost,',
      '    size: CoreComponentSize.sm,',
      '    onPressed: $callback,',
      "    child: Text('$text'),",
      '  ),',
    ],
    '],',
  ];
  return 'Popup(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
