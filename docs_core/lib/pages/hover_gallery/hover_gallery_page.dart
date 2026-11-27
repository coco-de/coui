/// HoverGallery 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `hover_gallery_web.dart` · `hover_gallery_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 항목은 그림을 내려받지 않고 색 토큰으로 칠한 면이다. 면마다 번호를 적어
/// 지금 어느 항목이 보이는지 알 수 있게 한다. 속성은 셋이다: `count`(항목 수),
/// `height`(갤러리 높이), `radius`(모서리 반지름).
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/hover-gallery.md`.
const String slug = 'hover-gallery';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'count': '3', 'height': '200', 'radius': '16'},
  controls: [
    DocsPlaygroundChoice(label: '항목 수', prop: 'count', options: ['3', '4', '5'], segmented: true),
    DocsPlaygroundChoice(label: 'height', prop: 'height', options: ['160', '200', '300'], segmented: true),
    DocsPlaygroundChoice(label: 'borderRadius', prop: 'radius', options: ['0', '8', '16', '32'], segmented: true),
  ],
  code: _hoverGalleryCode,
  webCode: _hoverGalleryWebCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// HoverGallery 는 크기 단계(`CoreComponentSize`)가 없고 높이를
/// `CoreHoverGalleryStyle.height` 숫자 하나로 정한다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `count` → 항목 수. 없거나 1보다 작으면 3.
int hoverGalleryPreviewCount(Map<String, String> props) {
  final count = int.tryParse(props['count'] ?? '');
  return count != null && count > 0 ? count : 3;
}

/// 속성의 `height` → 갤러리 높이(logical px). 없거나 0 이하면 기본값.
double hoverGalleryPreviewHeight(Map<String, String> props) {
  final height = double.tryParse(props['height'] ?? '');
  return height != null && height > 0 ? height : CoreHoverGalleryStyle.defaultHeight;
}

/// 속성의 `radius` → 모서리 반지름(logical px). 없거나 음수면 기본값.
double hoverGalleryPreviewRadius(Map<String, String> props) {
  final radius = double.tryParse(props['radius'] ?? '');
  return radius != null && radius >= 0 ? radius : CoreHoverGalleryStyle.defaultBorderRadius.topLeft;
}

/// 색 면 항목에 적는 글 — `1 / 3`.
String hoverGalleryItemLabel(int index, int count) => '${index + 1} / $count';

String _hoverGalleryCode(Map<String, String> props, String? label) {
  final count = hoverGalleryPreviewCount(props);
  return _hoverGallerySnippet(props, [
    'itemBuilder: (index) => Center(',
    "  child: Text('\${index + 1} / $count'),",
    '),',
  ]);
}

/// Web 은 항목의 크기를 직접 채우고 포인터를 받지 않게 해야 해서 코드가 다르다.
String _hoverGalleryWebCode(Map<String, String> props, String? label) {
  final count = hoverGalleryPreviewCount(props);
  return _hoverGallerySnippet(props, [
    'itemBuilder: (index) => div(',
    "  classes: 'flex items-center justify-center w-full h-full',",
    "  styles: Styles(raw: {'pointer-events': 'none'}),",
    "  [Text('\${index + 1} / $count')],",
    '),',
  ]);
}

/// 속성 → 코드. 항목을 그리는 줄([builder])만 플랫폼마다 다르다. 기본값과
/// 같은 값은 적지 않는다.
String _hoverGallerySnippet(Map<String, String> props, List<String> builder) {
  final height = hoverGalleryPreviewHeight(props);
  final radius = hoverGalleryPreviewRadius(props);
  final style = [
    if (height != CoreHoverGalleryStyle.defaultHeight) 'height: ${_spaceLiteral(height)},',
    if (radius != CoreHoverGalleryStyle.defaultBorderRadius.topLeft)
      'borderRadius: CoreBorderRadius.all(CoreRadius.radius${radius.toInt()}),',
  ];
  final lines = [
    'itemCount: ${hoverGalleryPreviewCount(props)},',
    ...builder,
    if (style.isNotEmpty) ...[
      'hoverGalleryStyle: CoreHoverGalleryStyle(',
      for (final line in style) '  $line',
      '),',
    ],
  ];
  return 'HoverGallery(\n${lines.map((line) => '  $line').join('\n')}\n)';
}

/// `CoreSpace` 단계면 토큰 이름으로, 아니면 숫자로 적는다.
String _spaceLiteral(double value) =>
    CoreSpace.steps.contains(value) ? 'CoreSpace.space${value.toInt()}' : docsSizeNumber(value);
