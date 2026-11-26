/// TextField 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `text_field_web.dart` · `text_field_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/text-field.md`.
const String slug = 'text-field';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {
    'variant': 'defaultVariant',
    'size': 'md',
    'label': '이메일',
    'placeholder': '이메일을 입력하세요',
    'description': '업무용 이메일을 권장합니다.',
  },
  controls: [
    DocsPlaygroundChoice(label: 'variant', prop: 'variant', options: ['defaultVariant', 'filled', 'plain']),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: ['sm', 'md', 'lg', 'xl', 'xl2'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '도움말', on: {'description': '업무용 이메일을 권장합니다.'}),
    DocsPlaygroundFlag(label: '오류', on: {'errorText': '이메일 형식이 아닙니다.'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _textFieldCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _textFieldSpec;

String _textFieldCode(Map<String, String> props, String? label) {
  String? quoted(String key) => props[key] == null ? null : "'${props[key]}'";
  final lines = [
    if (props['variant'] != null && props['variant'] != 'defaultVariant')
      'variant: CoreTextFieldVariant.${props['variant']},',
    "size: CoreComponentSize.${props['size'] ?? 'md'},",
    if (quoted('label') case final v?) 'label: $v,',
    if (quoted('placeholder') case final v?) 'placeholder: Text($v),',
    if (quoted('description') case final v?) 'description: $v,',
    if (quoted('errorText') case final v?) 'errorText: $v,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setEmail,',
  ];
  return 'TextField(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _textFieldSpec() {
  return DocsSizeSpec(
    columns: const ['size', '높이 · 좌우 여백', '글자', '같은 높이의 Button'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreTextFieldStyle.defaultsBySize.entries)
        if (!CoreTextFieldContract.retiringSizes.any((retirement) => retirement.size == size))
          DocsSizeSpecRow(
            size: size,
            cells: [
              '${docsSizeNumber(row.minHeight)} · ${docsSizeNumber(row.padding?.left)}',
              docsSizeNumber(docsSizeResolve(row.baseTextStyle)?.fontSize),
              size.name,
            ],
          ),
    ],
  );
}
