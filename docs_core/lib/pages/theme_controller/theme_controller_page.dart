/// ThemeController 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `theme_controller_web.dart` · `theme_controller_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/theme-controller.md`.
const String slug = 'theme-controller';

/// 미리보기 · 코드가 함께 쓰는 테마 — 이름과 팔레트 색.
///
/// 색은 `primaryColor` · `secondaryColor` · `accentColor` · `neutralColor` 순서의
/// RGB 다. 미리보기는 앞에서부터 속성 `colors` 만큼만 넘긴다.
const List<(String, List<(int, int, int)>)> themeControllerPreviewPalettes = [
  ('오션', [(14, 165, 233), (99, 102, 241), (6, 182, 212), (100, 116, 139)]),
  ('숲', [(34, 197, 94), (132, 204, 22), (20, 184, 166), (120, 113, 108)]),
  ('선셋', [(249, 115, 22), (239, 68, 68), (234, 179, 8), (115, 115, 115)]),
];

/// 플레이그라운드와 잠금 장면에서 하나만 잠그는 테마의 이름.
const String themeControllerLockedName = '숲';

/// 긴 이름 장면의 테마 이름.
const String themeControllerLongName = '미드나이트 오로라';

/// 상태 장면의 열 — 제목, 선택 여부, 활성 여부.
const List<(String, bool, bool)> themeControllerStateColumns = [
  ('기본', false, true),
  ('선택', true, true),
  ('비활성', false, false),
  ('비활성 · 선택', true, false),
];

/// 라이트 / 다크 두 가지만 고르는 장면(쓰지 말아야 할 예)의 테마.
const List<CoreThemeOption> themeControllerLightDarkThemes = [
  CoreThemeOption(
    name: '라이트',
    primaryColor: CoreColor.fromRGB(255, 255, 255),
    secondaryColor: CoreColor.fromRGB(228, 228, 231),
  ),
  CoreThemeOption(
    name: '다크',
    primaryColor: CoreColor.fromRGB(24, 24, 27),
    secondaryColor: CoreColor.fromRGB(63, 63, 70),
  ),
];

/// 속성 `colors` · `count` · `locked` 로 만드는 테마 목록.
///
/// `colors` 는 테마마다 넘기는 색 수(1 ~ 4, 기본 2), `count` 는 앞에서부터 보이는
/// 테마 수(기본 전부), `locked` 는 그 하나만 잠그는 테마의 이름이다.
List<CoreThemeOption> themeControllerPreviewOptions(Map<String, String> props) {
  final colors = _previewColorCount(props);
  final count = int.tryParse(props['count'] ?? '') ?? themeControllerPreviewPalettes.length;
  return [
    for (final (name, palette) in themeControllerPreviewPalettes.take(count))
      themeControllerOption(name, palette.take(colors).toList(), enabled: props['locked'] != name),
  ];
}

/// 팔레트 장면 — 색이 1 ~ 4개인 테마와, 테마 토큰 색을 쓴 테마.
List<CoreThemeOption> themeControllerPaletteThemes() {
  final palette = themeControllerPreviewPalettes.first.$2;
  return [
    for (var count = 1; count <= palette.length; count++)
      themeControllerOption('$count색', palette.take(count).toList()),
    const CoreThemeOption(
      name: '모노',
      primaryColor: CoreColor.token(CoreColors.onSurface),
      secondaryColor: CoreColor.token(CoreColors.outlineVariant),
    ),
  ];
}

/// RGB 목록(1 ~ 4개)으로 테마 하나를 만든다.
CoreThemeOption themeControllerOption(String name, List<(int, int, int)> colors, {bool enabled = true}) {
  CoreColor? at(int index) => index < colors.length ? _rgb(colors[index]) : null;
  return CoreThemeOption(
    name: name,
    primaryColor: _rgb(colors.first),
    secondaryColor: at(1),
    accentColor: at(2),
    neutralColor: at(3),
    enabled: enabled,
  );
}

CoreColor _rgb((int, int, int) color) => CoreColor.fromRGB(color.$1, color.$2, color.$3);

int _previewColorCount(Map<String, String> props) => (int.tryParse(props['colors'] ?? '') ?? 2).clamp(1, 4);

/// 플레이그라운드.
///
/// 처음 테마 수는 2 다 — 두 플랫폼을 나란히 볼 때 좁은 칸에서도 한 줄에 놓인다.
/// 3 으로 바꾸면 칸 폭에 따라 다음 줄로 넘어간다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'size': 'md', 'colors': '2', 'count': '2'},
  controls: [
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['sm', 'md', 'lg'], segmented: true),
    DocsPlaygroundChoice(label: '팔레트 색 수', prop: 'colors', options: ['1', '2', '3', '4'], segmented: true),
    DocsPlaygroundChoice(label: '테마 수', prop: 'count', options: ['2', '3'], segmented: true),
    DocsPlaygroundFlag(label: '숲 잠금', on: {'locked': themeControllerLockedName}),
    DocsPlaygroundFlag(label: '전체 비활성', on: {'enabled': 'false'}),
  ],
  code: _themeControllerCode,
);

/// 크기 표. 값은 `CoreThemeControllerStyle.defaultsBySize` 의 행에서 읽는다.
DocsSizeSpec Function()? get sizeSpec => _themeControllerSpec;

/// 팔레트 색을 넘기는 필드 이름 — 앞에서부터.
const List<String> _colorFields = ['primaryColor', 'secondaryColor', 'accentColor', 'neutralColor'];

String _themeControllerCode(Map<String, String> props, String? label) {
  final size = props['size'] ?? 'md';
  final colors = _previewColorCount(props);
  final count = int.tryParse(props['count'] ?? '') ?? themeControllerPreviewPalettes.length;
  final lines = [
    'selectedTheme: selected,',
    'onThemeChanged: (name) => setState(() => selected = name),',
    if (size != 'md') 'size: CoreThemeControllerSize.$size,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'themes: const [',
    for (final (name, palette) in themeControllerPreviewPalettes.take(count)) ...[
      '  CoreThemeOption(',
      "    name: '$name',",
      for (final (index, color) in palette.take(colors).indexed)
        '    ${_colorFields[index]}: CoreColor.fromRGB(${color.$1}, ${color.$2}, ${color.$3}),',
      if (props['locked'] == name) '    enabled: false,',
      '  ),',
    ],
    '],',
  ];
  return 'ThemeController(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _themeControllerSpec() {
  return DocsSizeSpec(
    columns: const ['size', '버튼 · 모서리', '팔레트 원', '스와치 사이', '원과 이름 사이', '이름 글자'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreThemeControllerStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: CoreComponentSize.values.byName(size.name),
          cells: [
            '${docsSizeNumber(row.buttonSize)} · ${docsSizeNumber(row.buttonRadius?.topLeft)}',
            docsSizeNumber(row.previewSize),
            docsSizeNumber(row.buttonSpacing),
            docsSizeNumber(row.labelGapStyle?.size),
            docsSizeLabel(row.labelStyle),
          ],
        ),
    ],
  );
}
