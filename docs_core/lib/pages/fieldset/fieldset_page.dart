/// Fieldset 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `fieldset_web.dart` · `fieldset_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/fieldset.md`.
const String slug = 'fieldset';

/// 미리보기 · 코드가 함께 쓰는 범례.
const String fieldsetPreviewLegend = '계정';

/// 미리보기 · 코드가 함께 쓰는 설명 — 설명 플래그를 켰을 때의 값과 같다.
const String fieldsetPreviewDescription = '로그인에 쓰는 정보예요.';

/// 미리보기 · 코드가 함께 쓰는 필드 — placeholder 글자와 코드의 콜백 이름.
const List<(String, String)> fieldsetPreviewFields = [
  ('이름', 'setName'),
  ('이메일', 'setEmail'),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// variant 의 선택지는 Core 의 enum 에서, 크기의 선택지는 크기 행에서
/// 읽는다 — 크기 표와 같은 목록이 된다. 태그의 `label` 은 범례 글자다.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: const {'variant': 'filled', 'size': 'md', 'description': fieldsetPreviewDescription},
  label: fieldsetPreviewLegend,
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreFieldsetVariant.values) variant.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in CoreFieldsetStyle.defaultsBySize.keys) size.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '설명', on: {'description': fieldsetPreviewDescription}),
    const DocsPlaygroundFlag(label: '범례 끄기', on: {'legend': 'false'}),
    const DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _fieldsetCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// Fieldset 의 크기 행은 범례 글자 하나만 정한다.
DocsSizeSpec Function()? get sizeSpec => _fieldsetSpec;

String _fieldsetCode(Map<String, String> props, String? label) {
  String quoted(String value) => "'${value.replaceAll("'", r"\'")}'";
  final variant = props['variant'] ?? CoreFieldsetVariant.defaultVariant.name;
  final size = props['size'] ?? CoreFieldsetStyle.defaultSize.name;
  final lines = [
    if (variant != CoreFieldsetVariant.defaultVariant.name) 'variant: CoreFieldsetVariant.$variant,',
    if (size != CoreFieldsetStyle.defaultSize.name) 'size: CoreComponentSize.$size,',
    if (previewFlag(props, 'legend', fallback: true)) 'legend: Text(${quoted(label ?? fieldsetPreviewLegend)}),',
    if (props['description'] case final description?) 'description: Text(${quoted(description)}),',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'children: [',
    for (final (placeholder, onChanged) in fieldsetPreviewFields)
      '  TextField(placeholder: Text(${quoted(placeholder)}), onChanged: $onChanged),',
    '],',
  ];
  return 'Fieldset(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _fieldsetSpec() {
  return DocsSizeSpec(
    columns: const ['size', '범례 글자 역할', '범례 글자'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreFieldsetStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: size,
          cells: [
            _roleName(row.legendTextStyle),
            docsSizeLabel(row.legendTextStyle),
          ],
        ),
    ],
  );
}

/// `title-small` → `titleSmall` — 표는 Dart 에서 쓰는 역할 이름을 적는다.
String _roleName(CoreTextStyle? style) {
  final name = style?.token?.name;
  return name == null ? '–' : docsIconIdentifier(name);
}
