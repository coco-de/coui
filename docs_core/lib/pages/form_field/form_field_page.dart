/// FormField 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `form_field_web.dart` · `form_field_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/form-field.md`.
const String slug = 'form-field';

/// 플레이그라운드의 라벨.
const String formFieldPreviewLabel = '닉네임';

/// 플레이그라운드 입력의 안내 글자.
const String formFieldPreviewPlaceholder = '닉네임을 입력하세요';

/// 속성에 안내 글자가 없는 미리보기(크기 표)의 안내 글자.
const String formFieldPreviewFallbackPlaceholder = '입력하세요';

/// 플레이그라운드의 도움말.
const String formFieldPreviewDescription = '다른 사용자에게 보이는 이름입니다.';

/// 플레이그라운드의 오류 문구.
const String formFieldPreviewError = '이미 쓰고 있는 이름입니다. 다른 이름을 입력하세요.';

/// 플레이그라운드의 글자 수 — FormField 는 세지 않으므로 고정 문구다.
const String formFieldPreviewCounter = '0 / 20';

/// 라벨 줄 끝에 놓는 버튼의 글자.
const String formFieldPreviewAction = '작성 안내';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `labelAction` 은 위젯 슬롯이라 속성으로는 켜고 끄기만 한다 — 켜면 두 플랫폼
/// 빌더와 코드가 같은 `plain` 버튼을 넣는다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {
    'size': 'md',
    'label': formFieldPreviewLabel,
    'placeholder': formFieldPreviewPlaceholder,
    'required': 'true',
    'description': formFieldPreviewDescription,
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '필수', on: {'required': 'true'}),
    DocsPlaygroundFlag(label: '도움말', on: {'description': formFieldPreviewDescription}),
    DocsPlaygroundFlag(label: '오류', on: {'error': formFieldPreviewError}),
    DocsPlaygroundFlag(label: '글자 수', on: {'counterText': formFieldPreviewCounter}),
    DocsPlaygroundFlag(label: '라벨 옆 동작', on: {'labelAction': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _formFieldCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// FormField 는 자기 크기 행이 없다. `size` 를 라벨을 그리는 FormLabel 에 그대로
/// 넘기므로 표는 `CoreFormLabelStyle.defaultsBySize` 에서 읽는다.
DocsSizeSpec Function()? get sizeSpec => _formFieldSpec;

String _formFieldCode(Map<String, String> props, String? label) {
  String? quoted(String key) => props[key] == null ? null : "'${props[key]}'";
  final placeholder = props['placeholder'] ?? formFieldPreviewFallbackPlaceholder;
  final lines = [
    "size: CoreComponentSize.${props['size'] ?? 'md'},",
    if (quoted('label') case final v?) 'label: $v,',
    if (previewFlag(props, 'required')) 'required: true,',
    if (previewFlag(props, 'labelAction')) ...[
      'labelAction: Button(',
      '  variant: CoreButtonVariant.plain,',
      '  size: CoreComponentSize.sm,',
      '  onPressed: showNicknameGuide,',
      "  child: Text('$formFieldPreviewAction'),",
      '),',
    ],
    if (quoted('description') case final v?) 'description: $v,',
    if (quoted('error') case final v?) 'error: $v,',
    if (quoted('counterText') case final v?) 'counterText: $v,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'child: TextField(',
    "  placeholder: Text('$placeholder'),",
    '  onChanged: setNickname,',
    '),',
  ];
  return 'FormField(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _formFieldSpec() {
  return DocsSizeSpec(
    columns: const ['size', '라벨 글자 역할', '라벨 글자'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreFormLabelStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: size,
          cells: [
            _roleName(row.labelStyle),
            docsSizeLabel(row.labelStyle),
          ],
        ),
    ],
  );
}

/// `label-medium` → `labelMedium` — 표는 Dart 에서 쓰는 역할 이름을 적는다.
String _roleName(CoreTextStyle? style) {
  final name = style?.token?.name;
  return name == null ? '–' : docsIconIdentifier(name);
}
