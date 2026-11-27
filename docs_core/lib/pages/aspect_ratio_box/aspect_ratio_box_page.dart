/// AspectRatioBox 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `aspect_ratio_box_web.dart` · `aspect_ratio_box_flutter.dart` 가
/// 그린다. 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// AspectRatioBox 는 스스로 아무것도 칠하지 않는다 — 미리보기는 늘 폭을 정한
/// 부모 안에 상자를 두고, 상자의 모양이 보이도록 색을 채운 Card 를 담는다.
/// 속성은 둘이다: `ratio`(`16/9` 처럼 `너비/높이`, [aspectRatioBoxRatios] 의
/// 이름)와 `parentWidth`(상자를 감싼 부모의 폭, logical px — 상자의 속성이
/// 아니다). 두 플랫폼 빌더와 코드가 같은 뜻으로 읽도록 해석은 이 파일의
/// [aspectRatioBoxPreviewRatio] · [aspectRatioBoxPreviewParentWidth] 한 곳에
/// 둔다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/aspect-ratio-box.md`.
const String slug = 'aspect-ratio-box';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: const {'ratio': '16/9', 'parentWidth': '136'},
  controls: [
    DocsPlaygroundChoice(label: 'ratio', prop: 'ratio', options: [...aspectRatioBoxRatios.keys], segmented: true),
    DocsPlaygroundChoice(
      label: '부모 폭',
      prop: 'parentWidth',
      options: [for (final width in aspectRatioBoxParentWidths) '$width'],
      segmented: true,
    ),
  ],
  code: _aspectRatioBoxCode,
  webCode: _aspectRatioBoxWebCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// 상자에는 크기 단계(`CoreComponentSize`)가 없다 — 크기는 부모와 비율이
/// 정한다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 비율 이름(`너비/높이`) → 비율. 플레이그라운드의 선택지이자 `ratios` 장면의
/// 순서다.
const Map<String, double> aspectRatioBoxRatios = {'16/9': 16 / 9, '4/3': 4 / 3, '1/1': 1, '3/4': 3 / 4};

/// 플레이그라운드가 고르는 부모 폭(logical px). 가장 긴 상자(`3/4`, 넓은 쪽
/// 폭)도 사이트의 Flutter 미리보기 판 높이 안에 들어가는 값이다.
const List<int> aspectRatioBoxParentWidths = [96, 136];

/// `aspect-ratio-box/widths` 장면의 부모 폭(logical px). 비율은 `16/9` 하나다.
const List<double> aspectRatioBoxSceneWidths = [96, 160, 240];

/// `aspect-ratio-box/fallback` 장면의 쓸 수 없는 `ratio` 값 — 상자에 적는
/// 이름과 값. 두 플랫폼 장면이 함께 읽는다.
const List<(String, double)> aspectRatioBoxSceneInvalidRatios = [
  ('0', 0),
  ('-1', -1),
  ('NaN', double.nan),
  ('∞', double.infinity),
];

/// 속성의 `ratio` → [aspectRatioBoxRatios] 의 이름. 없거나 모르는 값은 첫 비율.
String aspectRatioBoxPreviewRatio(Map<String, String> props) {
  final name = props['ratio'];
  return name != null && aspectRatioBoxRatios.containsKey(name) ? name : aspectRatioBoxRatios.keys.first;
}

/// 속성의 `parentWidth` → 부모 폭. 없거나 모르는 값은 넓은 쪽.
int aspectRatioBoxPreviewParentWidth(Map<String, String> props) {
  final width = int.tryParse(props['parentWidth'] ?? '');
  return width != null && aspectRatioBoxParentWidths.contains(width) ? width : aspectRatioBoxParentWidths.last;
}

/// 비율 이름 → 상자에 적는 글. `16/9` → `16 : 9`.
String aspectRatioBoxRatioLabel(String name) => name.replaceAll('/', ' : ');

/// [width] 인 상자에 적는 `너비 × 높이`. 높이는 [ratio] 에서 나온다.
String aspectRatioBoxSizeLabel(double width, double ratio) => '${width.round()} × ${(width / ratio).round()}';

String _aspectRatioBoxCode(Map<String, String> props, String? label) {
  final name = aspectRatioBoxPreviewRatio(props);
  return '''
SizedBox(
  width: ${aspectRatioBoxPreviewParentWidth(props)},
  child: AspectRatioBox(
    ratio: ${_ratioExpression(name)},
    child: Card(
      cardStyle: const CoreCardStyle(
        backgroundColor: CoreColor.token(CoreColors.primaryContainer),
        padding: CoreEdgeInsets.zero,
      ),
      child: Center(child: Text(${_quotedText(name, label)}).titleSmall.onPrimaryContainer),
    ),
  ),
)''';
}

/// Web 은 부모가 `div` 이고, 가운데 정렬도 `Center` 가 아니라 flex 클래스다.
String _aspectRatioBoxWebCode(Map<String, String> props, String? label) {
  final name = aspectRatioBoxPreviewRatio(props);
  return '''
div(
  styles: Styles(raw: {'width': '${aspectRatioBoxPreviewParentWidth(props)}px'}),
  [
    AspectRatioBox(
      ratio: ${_ratioExpression(name)},
      child: Card(
        cardStyle: const CoreCardStyle(
          backgroundColor: CoreColor.token(CoreColors.primaryContainer),
          padding: CoreEdgeInsets.zero,
        ),
        child: div(
          classes: 'flex h-full items-center justify-center',
          [Text(${_quotedText(name, label)}).titleSmall.onPrimaryContainer],
        ),
      ),
    ),
  ],
)''';
}

/// 비율 이름 → 코드에 적는 Dart 식. `16/9` → `16 / 9`, `1/1` → `1`.
String _ratioExpression(String name) => name == '1/1' ? '1' : name.replaceAll('/', ' / ');

/// 상자에 적는 글의 Dart 문자열.
String _quotedText(String name, String? label) =>
    "'${(label ?? aspectRatioBoxRatioLabel(name)).replaceAll("'", r"\'")}'";
