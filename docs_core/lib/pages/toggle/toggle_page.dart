/// Toggle 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `toggle_web.dart` · `toggle_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/toggle.md`.
const String slug = 'toggle';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// variant 는 하나(`defaultVariant`)뿐이라 컨트롤이 없다. 크기 선택지는
/// 크기 행이 있는 sm 부터다 — `xs` 는 예고 중이고 `sm` 으로 그려진다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'value': 'true', 'size': 'md'},
  label: '알림 받기',
  controls: [
    DocsPlaygroundFlag(label: '켜짐', on: {'value': 'true'}),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: ['sm', 'md', 'lg', 'xl', 'xl2'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _toggleCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _toggleSpec;

String _toggleCode(Map<String, String> props, String? label) {
  final lines = [
    'value: ${previewFlag(props, 'value')},',
    "size: CoreComponentSize.${props['size'] ?? 'md'},",
    if (label != null) "label: '$label',",
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setNotify,',
  ];
  return 'Toggle(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _toggleSpec() {
  return DocsSizeSpec(
    columns: const ['size', '트랙 (너비 × 높이)', '썸 · 이동 거리', '트랙과 라벨 간격', '라벨'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreToggleStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: size,
          cells: [
            '${docsSizeNumber(row.trackWidth)} × ${docsSizeNumber(row.trackHeight)}',
            '${docsSizeNumber(row.thumbSize)} · ${docsSizeNumber(row.thumbOffset)}',
            docsSizeNumber(row.iconLabelGapStyle?.size),
            docsSizeLabel(row.labelStyle),
          ],
        ),
    ],
  );
}
