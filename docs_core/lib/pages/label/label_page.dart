/// Label 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `label_web.dart` · `label_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/label.md`.
const String slug = 'label';

/// 미리보기의 라벨 글자.
const String labelPreviewText = '이메일';

/// 별표를 라벨 글자에 직접 적은 나쁜 예.
const String labelTypedAsterisk = '이메일 *';

/// 토글 옆에 놓는 라벨 글자.
const String labelToggleText = '알림 받기';

/// 장면의 입력에 보이는 안내 글자.
const String labelPlaceholder = '이메일 주소 입력';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `icon` 의 속성 값은 아이콘의 Lucide 이름이다 — 두 플랫폼 빌더와 코드가 같은
/// 이름을 읽는다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'icon': 'mail', 'isRequired': 'true'},
  label: labelPreviewText,
  controls: [
    DocsPlaygroundFlag(label: '앞 아이콘', on: {'icon': 'mail'}),
    DocsPlaygroundFlag(label: '필수 표시', on: {'isRequired': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'disabled': 'true'}),
  ],
  code: _labelCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

String _labelCode(Map<String, String> props, String? label) {
  final lines = [
    "text: '${label ?? labelPreviewText}',",
    if (props['icon'] case final icon?) 'icon: Icon(LucideIcons.${docsIconIdentifier(icon)}),',
    if (previewFlag(props, 'isRequired')) 'isRequired: true,',
    if (previewFlag(props, 'disabled')) 'disabled: true,',
  ];
  return 'Label(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
