/// CardImage 페이지 — 플레이그라운드와 두 플랫폼이 함께 읽는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `card_image_web.dart` · `card_image_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기는 네트워크 없이 그려야 하므로 사진 자리에 색 면 · 테두리 ·
/// 아이콘으로 만든 그림([CardImageSample])을 넣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/card-image.md`.
const String slug = 'card-image';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. CardImage 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 사진 자리의 그림 한 장 — 가운데 아이콘, 면 색, 아이콘 · 테두리 색.
typedef CardImageSample = ({IconName icon, CoreColorToken fill, CoreColorToken ink});

/// 대표 그림.
const CardImageSample cardImageSunrise = (
  icon: LucideIcons.sun,
  fill: CoreColors.primaryContainer,
  ink: CoreColors.onPrimaryContainer,
);

/// 불러오는 중 자리.
const CardImageSample cardImageLoading = (
  icon: LucideIcons.clock,
  fill: CoreColors.surfaceContainerHigh,
  ink: CoreColors.onSurfaceVariant,
);

/// 불러오지 못한 자리.
const CardImageSample cardImageFailed = (
  icon: LucideIcons.circleAlert,
  fill: CoreColors.errorContainer,
  ink: CoreColors.onErrorContainer,
);

/// 대표 카드의 제목.
const String cardImageTitle = '산 풍경';

/// 대표 카드의 부제.
const String cardImageSubtitle = '해 뜰 무렵 촬영';

/// 대표 그림의 대체 텍스트.
const String cardImageAlt = '해가 뜨는 산';

/// 세로 카드 한 장의 폭.
const double cardImageWidth = CoreSpace.space240;

/// 사용 가이드 · 관련 컴포넌트 장면의 폭.
const double cardImageUsageWidth = CoreSpace.space224;

/// 여러 장을 나란히 놓을 때의 폭.
const double cardImageCompactWidth = CoreSpace.space160;

/// 비율 비교 장면의 폭.
const double cardImageRatioWidth = CoreSpace.space144;

/// 가로 카드에 넣는 정사각 이미지의 한 변.
const double cardImageThumbnailSize = CoreSpace.space80;

/// 대표 이미지 비율.
const double cardImageWideRatio = 16 / 9;

/// 비율 비교 장면 — (제목, 가로 ÷ 세로).
const List<(String, double)> cardImageRatios = [('16:9', cardImageWideRatio), ('4:3', 4 / 3), ('1:1', 1)];

/// 자리 표시 장면 — (그림, 제목).
const List<(CardImageSample, String)> cardImagePlaceholders = [
  (cardImageLoading, '불러오는 중'),
  (cardImageFailed, '불러오지 못함'),
];

/// 상태 장면 — (제목, `onPressed` 를 주는가, `enabled`).
const List<(String, bool, bool?)> cardImageStates = [
  ('누를 수 있음', true, null),
  ('비활성', true, false),
  ('표시용', false, null),
];

/// 가로 배치 — 기본값 그대로.
const CoreCardImageStyle cardImageHorizontalStyle = CoreCardImageStyle(direction: CoreAxis.horizontal);

/// 가로 배치 — 아래 여백을 없애고 글 줄에 위 여백을 준 것.
const CoreCardImageStyle cardImageHorizontalFlushStyle = CoreCardImageStyle(
  direction: CoreAxis.horizontal,
  containerStyle: CoreOutlinedContainerStyle(padding: CoreEdgeInsets.zero),
  contentStyle: CoreBasicStyle(
    padding: CoreEdgeInsets.directional(start: CoreSpace.space14, top: CoreSpace.space14, end: CoreSpace.space10),
  ),
);

/// 테마와 스타일 장면의 덮어쓴 값.
const CoreCardImageStyle cardImageStyledStyle = CoreCardImageStyle(
  containerStyle: CoreOutlinedContainerStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    boxShadow: CoreShadow.none,
  ),
  imageContentGapStyle: CoreGapStyle(size: CoreSpace.space8),
);

/// 속성의 `direction` 이 가로인가.
bool cardImagePreviewHorizontal(Map<String, String> props) =>
    previewEnum(CoreAxis.values, props['direction'], CoreCardImageStyle.defaultDirection) == CoreAxis.horizontal;

/// 속성이 hover 확대를 껐는가.
bool _previewStill(Map<String, String> props) => props['hoverScale'] == '1';

/// 속성 → `cardImageStyle`. 바꾼 값이 없으면 `null`.
CoreCardImageStyle? cardImagePreviewStyle(Map<String, String> props) {
  final horizontal = cardImagePreviewHorizontal(props);
  final still = _previewStill(props);
  if (!horizontal && !still) return null;
  return CoreCardImageStyle(
    direction: horizontal ? CoreAxis.horizontal : null,
    hoverScale: still ? CoreCardImageStyle.defaultNormalScale : null,
  );
}

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'direction': CoreCardImageStyle.defaultDirection.name, 'pressable': 'true', 'subtitle': 'true'},
  controls: [
    DocsPlaygroundChoice(
      label: 'direction',
      prop: 'direction',
      options: [for (final axis in CoreAxis.values) axis.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '누를 수 있음', on: {'pressable': 'true'}),
    const DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
    const DocsPlaygroundFlag(label: '부제', on: {'subtitle': 'true'}),
    const DocsPlaygroundFlag(label: '앞 아이콘', on: {'leading': 'star'}),
    const DocsPlaygroundFlag(label: '뒤 아이콘 바꾸기', on: {'trailing': 'arrow-right'}),
    const DocsPlaygroundFlag(label: '확대 끄기', on: {'hoverScale': '1'}),
  ],
  code: _flutterCode,
  webCode: _webCode,
);

/// Flutter 코드 — 가로 카드는 높이를 정해 주는 `IntrinsicHeight` 로 감싼다.
String _flutterCode(Map<String, String> props, String? label) {
  final card = _cardCode(props, label, web: false);
  if (!cardImagePreviewHorizontal(props)) return card;
  return 'IntrinsicHeight(\n  child: ${card.split('\n').join('\n  ')},\n)';
}

/// Web 코드 — 세로 카드는 부모의 폭을 채우는 `css` 를 함께 적는다.
String _webCode(Map<String, String> props, String? label) => _cardCode(props, label, web: true);

/// 속성 → `CardImage(...)`. 기본값과 같은 것은 적지 않는다.
String _cardCode(Map<String, String> props, String? label, {required bool web}) {
  final horizontal = cardImagePreviewHorizontal(props);
  final still = _previewStill(props);
  final lines = [
    if (horizontal) 'image: thumbnail, // 너비와 높이를 정한 이미지' else 'image: AspectRatioBox(ratio: 16 / 9, child: photo),',
    "title: Text('${label ?? cardImageTitle}'),",
    if (previewFlag(props, 'subtitle')) "subtitle: Text('$cardImageSubtitle'),",
    if (props['leading'] != null) 'leading: Icon(LucideIcons.${docsIconIdentifier(props['leading']!)}),',
    if (props['trailing'] != null) 'trailing: Icon(LucideIcons.${docsIconIdentifier(props['trailing']!)}),',
    if (previewFlag(props, 'pressable')) 'onPressed: openPhoto,',
    if (props['enabled'] == 'false') 'enabled: false,',
    if (horizontal || still) ...[
      'cardImageStyle: CoreCardImageStyle(',
      if (horizontal) '  direction: CoreAxis.horizontal,',
      if (still) '  hoverScale: 1,',
      '),',
    ],
    if (web && !horizontal) "css: Styles(raw: {'width': '100%'}),",
  ];
  return 'CardImage(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
