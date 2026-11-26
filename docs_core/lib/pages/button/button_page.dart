/// Button 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `button_web.dart` · `button_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/button.md`.
const String slug = 'button';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'variant': 'primary', 'size': 'lg', 'shape': 'rectangle', 'leading': 'plus'},
  label: '저장하기',
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: ['primary', 'secondary', 'tonal', 'outline', 'ghost', 'plain', 'destructive'],
    ),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'shape',
      prop: 'shape',
      options: ['rectangle', 'square', 'circle'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: 'leading 아이콘', on: {'leading': 'plus'}),
    DocsPlaygroundFlag(label: 'trailing 아이콘', on: {'trailing': 'arrow-right'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _buttonCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _buttonSpec;

String _buttonCode(Map<String, String> props, String? label) {
  final shape = props['shape'] ?? 'rectangle';
  final iconOnly = shape != 'rectangle';
  final lines = [
    "variant: CoreButtonVariant.${props['variant'] ?? 'primary'},",
    "size: CoreComponentSize.${props['size'] ?? 'md'},",
    if (iconOnly) 'shape: CoreButtonShape.$shape,',
    if (!iconOnly && props['leading'] != null) 'leading: Icon(LucideIcons.${docsIconIdentifier(props['leading']!)}),',
    if (!iconOnly && props['trailing'] != null)
      'trailing: Icon(LucideIcons.${docsIconIdentifier(props['trailing']!)}),',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onPressed: save,',
    if (iconOnly)
      'child: Icon(LucideIcons.${docsIconIdentifier(props['icon'] ?? 'plus')}),'
    else
      "child: Text('${label ?? '버튼'}'),",
  ];
  return 'Button(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _buttonSpec() {
  return DocsSizeSpec(
    columns: const ['size', '높이 · 좌우 여백', '아이콘', '라벨 · 모서리'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreButtonStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: size,
          cells: [
            '${docsSizeNumber(row.height)} · ${docsSizeNumber(row.padding?.left)}',
            docsSizeNumber(row.leadingIconStyle?.size),
            '${docsSizeLabel(row.labelStyle)} · ${docsSizeNumber(row.borderRadius?.topLeft)}',
          ],
        ),
    ],
  );
}
