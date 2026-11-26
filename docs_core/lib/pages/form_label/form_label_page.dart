/// FormLabel 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `form_label_web.dart` · `form_label_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/form-label.md`.
const String slug = 'form-label';

/// 미리보기의 라벨 글자.
const String formLabelPreviewText = '이메일';

/// 직접 만든 필수 표시의 글자 — 플레이그라운드와 장면이 함께 읽는다.
const String formLabelCustomIndicator = '(필수)';

/// 별표를 라벨 글자에 직접 적은 나쁜 예.
const String formLabelTypedAsterisk = '이메일 *';

/// 좁은 자리에서 줄을 바꾸는 긴 라벨.
const String formLabelLongText = '세금 계산서와 청구서를 받을 회사 이메일 주소';

/// 장면의 입력에 보이는 안내 글자.
const String formLabelPlaceholder = 'name@company.com';

/// 장면의 필드 아래 도움말.
const String formLabelDescription = '로그인할 때 씁니다.';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `requiredIndicator` 의 속성 값은 그 표시에 적을 글자다 — 두 플랫폼 빌더와
/// 코드가 `Text(값)` 으로 읽는다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'size': 'md', 'isRequired': 'true'},
  label: formLabelPreviewText,
  controls: [
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: 'isRequired', on: {'isRequired': 'true'}),
    DocsPlaygroundFlag(label: '직접 만든 필수 표시', on: {'requiredIndicator': formLabelCustomIndicator}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _formLabelCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _formLabelSpec;

String _formLabelCode(Map<String, String> props, String? label) {
  final lines = [
    "label: Text('${label ?? formLabelPreviewText}'),",
    if (previewFlag(props, 'isRequired')) 'isRequired: true,',
    if (props['requiredIndicator'] case final indicator?) "requiredIndicator: Text('$indicator'),",
    "size: CoreComponentSize.${props['size'] ?? 'md'},",
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
  ];
  return 'FormLabel(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _formLabelSpec() {
  return DocsSizeSpec(
    columns: const ['size', '라벨 글자', '글자 역할'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreFormLabelStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: size,
          cells: [docsSizeLabel(row.labelStyle), _roleName(row.labelStyle)],
        ),
    ],
  );
}

/// `label-medium` → `labelMedium` — 표는 Dart 에서 쓰는 역할 이름을 적는다.
String _roleName(CoreTextStyle? style) {
  final name = style?.token?.name;
  return name == null ? '–' : docsIconIdentifier(name);
}
