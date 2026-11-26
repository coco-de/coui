/// CommandSearch 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `command_search_web.dart` · `command_search_flutter.dart` 가 그린다.
/// 미리보기의 글자 · 폭 · 속성 해석은 이 파일 한 곳에 둔다 — 두 플랫폼의
/// 그림과 코드가 같은 값을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/command-search.md`.
const String slug = 'command-search';

/// 미리보기가 `shortcut` 자리의 `Kbd` 에 보이는 키.
const String kCommandSearchKeys = '⌘K';

/// 안내 글을 바꾼 미리보기의 글.
const String kCommandSearchCustomHint = '일정 검색';

/// 말줄임을 보이는 긴 안내 글.
const String kCommandSearchLongHint = '프로젝트 · 문서 · 설정에서 찾을 말을 입력해 주세요';

/// 상태 장면의 짧은 안내 글.
const String kCommandSearchShortHint = '검색';

/// 앱 바 장면의 메뉴 버튼 이름(Web 의 `aria-label`).
const String kCommandSearchMenuName = '메뉴';

/// 트리거 하나를 보일 때의 폭(logical px) — 트리거는 폭을 스스로 정하지 않는다.
const double kCommandSearchWidth = 280;

/// 구조 그림의 폭(logical px).
const double kCommandSearchAnatomyWidth = 320;

/// 카드처럼 좁은 칸에 놓는 폭(logical px).
const double kCommandSearchCardWidth = 220;

/// 말줄임 장면의 폭(logical px).
const double kCommandSearchNarrowWidth = 200;

/// 앱 바 장면의 폭(logical px).
const double kCommandSearchBarWidth = 448;

/// 속성의 `size` — 없거나 모르는 값은 위젯의 기본값.
CoreCommandSize commandSearchPreviewSize(Map<String, String> props) =>
    previewEnum(CoreCommandSize.values, props['size'], CoreCommandSize.defaultSize);

/// 속성의 `width`(logical px) — 없으면 [kCommandSearchWidth].
///
/// `width` 는 위젯의 속성이 아니라 미리보기의 손잡이다.
double commandSearchPreviewWidth(Map<String, String> props) =>
    double.tryParse(props['width'] ?? '') ?? kCommandSearchWidth;

/// 속성이 트리거를 흰 면(`surface`) 위에 놓으라고 하는가.
///
/// 트리거의 면은 `surfaceContainer` 이고 테두리가 없어, 같은 색의 면에서는
/// 상자가 보이지 않는다. `backdrop` 은 위젯의 속성이 아니라 미리보기의
/// 손잡이다.
bool commandSearchPreviewOnSurface(Map<String, String> props) => props['backdrop'] == 'surface';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// variant 가 없으므로 크기, 세 칸(안내 글 · 앞 아이콘 · 단축키), 비활성을
/// 바꾼다. 미리보기의 트리거는 눌러도 아무것도 열지 않는다 — 코드의
/// `openCommandPalette` 는 앱의 함수다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'size': 'md', 'shortcut': kCommandSearchKeys},
  controls: [
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['sm', 'md', 'lg'], segmented: true),
    DocsPlaygroundFlag(label: '안내 글 바꾸기', on: {'hint': kCommandSearchCustomHint}),
    DocsPlaygroundFlag(label: '앞 아이콘 바꾸기', on: {'leading': 'calendar'}),
    DocsPlaygroundFlag(label: '단축키', on: {'shortcut': kCommandSearchKeys}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _commandSearchCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// `CommandSearch` 의 크기는 `Command` 와 같은 `CoreCommandSize` 세 단계다.
DocsSizeSpec Function()? get sizeSpec => _commandSearchSizeSpec;

String _commandSearchCode(Map<String, String> props, String? label) {
  final hint = props['hint'];
  final leading = props['leading'];
  final shortcut = props['shortcut'];
  final lines = [
    'size: CoreCommandSize.${commandSearchPreviewSize(props).name},',
    if (hint != null) "hint: '$hint',",
    if (leading != null) 'leading: Icon(LucideIcons.${docsIconIdentifier(leading)}),',
    if (shortcut != null) "shortcut: const Kbd(keys: ['$shortcut']),",
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onPressed: openCommandPalette,',
  ];
  return 'CommandSearch(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _commandSearchSizeSpec() {
  return DocsSizeSpec(
    columns: const ['size', '높이 · 모서리', '여백 시작 · 끝', '칸 사이', '앞 아이콘', '안내 글'],
    rows: [
      for (final size in CoreCommandSize.values)
        if (CoreCommandSearchStyle.defaultsBySize[size] case final row?)
          DocsSizeSpecRow(
            size: size.toComponentSize(),
            cells: [
              '${docsSizeNumber(row.height)} · ${docsSizeNumber(row.borderRadius?.topLeft)}',
              '${docsSizeNumber(row.padding?.start)} · ${docsSizeNumber(row.padding?.end)}',
              docsSizeNumber(row.contentGapStyle?.size),
              docsSizeNumber(row.leadingIconStyle?.size),
              docsSizeLabel(row.hintTextStyle),
            ],
          ),
    ],
  );
}
