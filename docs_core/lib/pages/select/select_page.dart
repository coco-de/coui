/// Select 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `select_web.dart` · `select_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/select.md`.
const String slug = 'select';

/// 미리보기 · 코드가 함께 쓰는 선택지 — 값과 라벨.
const List<(String, String)> selectPreviewItems = [
  ('fruit', '과일'),
  ('vegetable', '채소'),
  ('meat', '육류'),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `error` variant 는 고르지 않는다 — `errorText` 를 주면 켜진다(TextField 와
/// 같다). 그래서 variant 선택지는 둘이고 오류는 켜고 끄는 컨트롤이다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {
    'variant': 'defaultVariant',
    'size': 'md',
    'label': '카테고리',
    'placeholder': '카테고리를 선택하세요',
  },
  controls: [
    DocsPlaygroundChoice(label: 'variant', prop: 'variant', options: ['defaultVariant', 'filled'], segmented: true),
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['sm', 'md', 'lg'], segmented: true),
    DocsPlaygroundFlag(label: '선택됨', on: {'value': 'fruit'}),
    DocsPlaygroundFlag(label: '도움말', on: {'description': '하나만 고를 수 있습니다.'}),
    DocsPlaygroundFlag(label: '오류', on: {'errorText': '카테고리를 선택해 주세요.'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _selectCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// Select 의 크기는 자기 사다리(`CoreSelectSize`: sm · md · lg)다. 트리거는
/// 같은 이름의 TextField 행을, 옵션 행은 같은 이름의 MenuItem 행을 쓴다 —
/// 그래서 각 열을 그 행에서 읽는다.
DocsSizeSpec Function()? get sizeSpec => _selectSpec;

String _selectCode(Map<String, String> props, String? label) {
  String? quoted(String key) => props[key] == null ? null : "'${props[key]}'";
  final lines = [
    if (props['variant'] != null && props['variant'] != 'defaultVariant')
      'variant: CoreSelectVariant.${props['variant']},',
    "size: CoreSelectSize.${props['size'] ?? 'md'},",
    if (quoted('label') case final v?) 'label: $v,',
    if (quoted('placeholder') case final v?) 'placeholder: $v,',
    if (quoted('value') case final v?) 'value: $v,',
    if (quoted('description') case final v?) 'description: $v,',
    if (quoted('errorText') case final v?) 'errorText: $v,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setCategory,',
    'items: [',
    for (final (value, text) in selectPreviewItems) "  CoreSelectItem(value: '$value', label: '$text'),",
    '],',
  ];
  return 'Select<String>(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _selectSpec() {
  return DocsSizeSpec(
    columns: const ['size', '트리거 높이 · 좌우 여백', '꺾쇠', '옵션 행 높이'],
    rows: [
      for (final size in CoreSelectSize.values)
        if ((
              CoreTextFieldStyle.defaultsBySize[size.toComponentSize()]!,
              CoreMenuItemStyle.defaultsBySize[size.toMenuItemSize()]!,
            )
            case (final trigger, final option))
          DocsSizeSpecRow(
            size: size.toComponentSize(),
            cells: [
              '${docsSizeNumber(trigger.minHeight)} · ${docsSizeNumber(trigger.padding?.left)}',
              docsSizeNumber(CoreSelectStyle.defaultsBySize[size]!.trailingIconStyle?.size),
              docsSizeNumber(option.minHeight),
            ],
          ),
    ],
  );
}
