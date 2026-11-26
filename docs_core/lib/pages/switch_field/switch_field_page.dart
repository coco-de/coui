/// SwitchField 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `switch_field_web.dart` · `switch_field_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/switch-field.md`.
const String slug = 'switch-field';

/// 미리보기 · 코드가 함께 쓰는 라벨.
const String switchFieldPreviewLabel = '알림 받기';

/// 미리보기 · 코드가 함께 쓰는 설명 — 설명 플래그를 켰을 때의 값과 같다.
const String switchFieldPreviewDescription = '새 댓글이 달리면 알려 드려요.';

/// 상태 장면의 행 — 라벨, 켜짐, 활성.
const List<(String, bool, bool)> switchFieldStateRows = [
  ('꺼짐', false, true),
  ('켜짐', true, true),
  ('비활성', false, false),
  ('비활성 · 켜짐', true, false),
];

/// 설정 목록 장면의 행 — 라벨, 설명, 켜짐.
const List<(String, String, bool)> switchFieldSettingsRows = [
  ('다크 모드', '어두운 테마로 화면을 그립니다.', true),
  ('푸시 알림', '새 메시지와 업데이트를 알려 드려요.', false),
  ('자동 저장', '바꾼 내용을 바로 저장합니다.', true),
];

/// 크기 장면의 크기 — 안쪽 Toggle 의 크기 행 순서(작은 크기부터).
///
/// 스위치 필드는 `size` 를 안쪽 Toggle 에 그대로 넘기므로, 고를 수 있는
/// 크기는 Toggle 의 크기 행이다.
List<CoreComponentSize> get switchFieldSceneSizes => CoreToggleStyle.defaultsBySize.keys.toList();

/// 크기 장면의 라벨 — 스위치 필드의 기본 크기에는 "기본" 을 붙인다.
String switchFieldSizeLabel(CoreComponentSize size) =>
    size == CoreSwitchFieldStyle.defaultSize ? '${size.name} · 기본' : size.name;

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 스위치 필드에는 variant 가 없고 크기는 위젯 속성이 아니라
/// `switchFieldStyle.size` 다. 그래서 컨트롤은 위젯 속성인 켜짐 · 설명 ·
/// 비활성이다. 처음 값은 켜짐 — 트랙이 `primary` 라 무대에서 뚜렷하다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'value': 'true', 'description': switchFieldPreviewDescription},
  label: switchFieldPreviewLabel,
  controls: [
    DocsPlaygroundFlag(label: '켜짐', on: {'value': 'true'}),
    DocsPlaygroundFlag(label: '설명', on: {'description': switchFieldPreviewDescription}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _switchFieldCode,
);

/// 크기 표. SwitchField 는 자기 크기 행이 없다 — `CoreSwitchFieldStyle` 에
/// `defaultsBySize` 가 없고, `size` 는 안쪽 Toggle 에 그대로 넘어간다.
/// 크기마다의 치수는 Toggle 페이지의 크기 표가 보인다.
DocsSizeSpec Function()? get sizeSpec => null;

String _switchFieldCode(Map<String, String> props, String? label) {
  String quoted(String value) => "'${value.replaceAll("'", r"\'")}'";
  final lines = [
    'label: ${quoted(label ?? switchFieldPreviewLabel)},',
    if (props['description'] case final description?) 'description: ${quoted(description)},',
    'value: ${previewFlag(props, 'value')},',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setNotify,',
  ];
  return 'SwitchField(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
