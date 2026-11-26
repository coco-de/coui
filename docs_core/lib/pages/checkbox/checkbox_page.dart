/// Checkbox 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `checkbox_web.dart` · `checkbox_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/checkbox.md`.
const String slug = 'checkbox';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 값은 `checked` 하나가 세 상태(`true` · `false` · `null`)를 나른다 — 그래서
/// 값 컨트롤의 선택지가 Dart 값 그대로다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'checked': 'true', 'size': 'md'},
  label: '약관에 동의합니다',
  controls: [
    DocsPlaygroundChoice(label: 'checked', prop: 'checked', options: ['true', 'false', 'null'], segmented: true),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '설명', on: {'description': '필수 항목입니다.'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _checkboxCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _checkboxSpec;

String _checkboxCode(Map<String, String> props, String? label) {
  final checked = props['checked'] ?? 'false';
  final lines = [
    'checked: $checked,',
    if (checked == 'null') 'tristate: true,',
    "size: CoreComponentSize.${props['size'] ?? 'md'},",
    "label: '${label ?? '동의합니다'}',",
    if (props['description'] case final description?) "description: '$description',",
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setAgreed,',
  ];
  return 'Checkbox(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _checkboxSpec() {
  return DocsSizeSpec(
    columns: const ['size', '박스', '체크 · 가로줄', '박스와 라벨 간격', '라벨 · 설명 글자'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreCheckboxStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: size,
          cells: [
            docsSizeNumber(row.boxSize),
            '${docsSizeNumber(row.checkmarkSize)} · ${docsSizeNumber(row.indeterminateLength)}',
            docsSizeNumber(row.indicatorLabelGapStyle?.size),
            '${docsSizeNumber(row.labelStyle?.fontSize)} · ${docsSizeNumber(row.descriptionStyle?.fontSize)}',
          ],
        ),
    ],
  );
}
