/// RadioGroup 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `radio_group_web.dart` · `radio_group_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/radio-group.md`.
const String slug = 'radio-group';

/// 미리보기 · 코드가 함께 쓰는 선택지 — 값과 라벨.
const List<(String, String)> radioGroupPreviewOptions = [
  ('basic', 'Basic'),
  ('pro', 'Pro'),
  ('team', 'Team'),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'variant': 'defaultVariant', 'orientation': 'vertical', 'size': 'md', 'value': 'pro'},
  controls: [
    DocsPlaygroundChoice(label: 'variant', prop: 'variant', options: ['defaultVariant', 'card'], segmented: true),
    DocsPlaygroundChoice(
      label: 'orientation',
      prop: 'orientation',
      options: ['vertical', 'horizontal'],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _radioGroupCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// 기본 variant 의 크기 층이다 — `card` 는 그 위에 타일 행을 덮는다
/// (`CoreRadioGroupStyle.sizeDefaultsFor`).
DocsSizeSpec Function()? get sizeSpec => _radioGroupSpec;

String _radioGroupCode(Map<String, String> props, String? label) {
  final variant = props['variant'] ?? 'defaultVariant';
  final orientation = props['orientation'] ?? 'vertical';
  final lines = [
    "value: '${props['value'] ?? 'pro'}',",
    if (variant != 'defaultVariant') 'variant: CoreRadioGroupVariant.$variant,',
    if (orientation != 'vertical') 'orientation: CoreRadioGroupOrientation.$orientation,',
    "size: CoreComponentSize.${props['size'] ?? 'md'},",
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setPlan,',
    'options: [',
    for (final (value, label) in radioGroupPreviewOptions) "  (value: '$value', label: '$label'),",
    '],',
  ];
  return 'RadioGroup(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _radioGroupSpec() {
  return DocsSizeSpec(
    columns: const ['size', '인디케이터', '링 (쉴 때 · 선택)', '라벨까지 · 항목 사이', '라벨 · 설명 글자'],
    rows: [
      for (final size in CoreRadioGroupStyle.defaultsBySize.keys)
        if (CoreRadioGroupStyle.sizeDefaultsFor(CoreRadioGroupVariant.defaultVariant, size) case final row)
          DocsSizeSpecRow(
            size: size,
            cells: [
              docsSizeNumber(row.indicatorSize),
              '${docsSizeNumber(row.indicatorBorderWidth)} · ${docsSizeNumber(row.selectedIndicatorBorderWidth)}',
              '${docsSizeNumber(row.indicatorLabelGapStyle?.size)} · ${docsSizeNumber(row.itemSpacing)}',
              '${docsSizeNumber(row.labelStyle?.fontSize)} · ${docsSizeLabel(row.descriptionStyle)}',
            ],
          ),
    ],
  );
}
