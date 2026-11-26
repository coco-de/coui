/// TextArea 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `text_area_web.dart` · `text_area_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/text-area.md`.
const String slug = 'text-area';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 크기 선택지는 `sm` 부터다 — `xs` 는 예고 중이다
/// (`CoreTextAreaContract.retiringSizes`). `error` variant 는 고르지 않는다 —
/// `errorText` 를 주면 켜진다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {
    'variant': 'defaultVariant',
    'size': 'md',
    'label': '문의 내용',
    'placeholder': '궁금한 점을 적어 주세요',
  },
  controls: [
    DocsPlaygroundChoice(label: 'variant', prop: 'variant', options: ['defaultVariant', 'filled'], segmented: true),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: ['sm', 'md', 'lg', 'xl', 'xl2'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '도움말', on: {'description': '답변은 이메일로 보내 드립니다.'}),
    DocsPlaygroundFlag(label: '글자 수', on: {'maxLength': '200'}),
    DocsPlaygroundFlag(label: 'footer', on: {'footer': 'send'}),
    DocsPlaygroundFlag(label: '오류', on: {'errorText': '10자 이상 입력해 주세요.'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _textAreaCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _textAreaSpec;

String _textAreaCode(Map<String, String> props, String? label) {
  String? quoted(String key) => props[key] == null ? null : "'${props[key]}'";
  final lines = [
    if (props['variant'] != null && props['variant'] != 'defaultVariant')
      'variant: CoreTextAreaVariant.${props['variant']},',
    "size: CoreComponentSize.${props['size'] ?? 'md'},",
    if (quoted('label') case final v?) 'label: $v,',
    if (quoted('placeholder') case final v?) 'placeholder: $v,',
    if (quoted('description') case final v?) 'description: $v,',
    if (quoted('errorText') case final v?) 'errorText: $v,',
    if (props['maxLength'] case final max?) ...['maxLength: $max,', 'showCounter: true,'],
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setMessage,',
    if (props['footer'] != null) "footer: Button(size: .sm, onPressed: send, child: Text('보내기')),",
  ];
  return 'TextArea(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _textAreaSpec() {
  return DocsSizeSpec(
    columns: const ['size', '처음 높이', '안쪽 여백 · 모서리', '값 글자'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreTextAreaStyle.defaultsBySize.entries)
        if (!CoreTextAreaContract.retiringSizes.any((retirement) => retirement.size == size))
          DocsSizeSpecRow(
            size: size,
            cells: [
              docsSizeNumber(row.initialHeight),
              '${docsSizeNumber(row.padding?.left)} · ${docsSizeNumber(row.borderRadius?.topLeft)}',
              docsSizeNumber(docsSizeResolve(row.baseTextStyle)?.fontSize),
            ],
          ),
    ],
  );
}
