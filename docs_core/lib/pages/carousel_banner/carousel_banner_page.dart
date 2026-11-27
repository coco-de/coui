/// CarouselBanner 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `carousel_banner_web.dart` · `carousel_banner_flutter.dart` 가
/// 그린다. 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/carousel-banner.md`.
const String slug = 'carousel-banner';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. CarouselBanner 의 크기는 `CoreComponentSize` 가 아니라
/// `CoreCarouselBannerSize` 라, 크기는 문서의 장면과 표가 보여 준다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 미리보기와 코드가 함께 쓰는 제목. 플레이그라운드 무대의 높이는 정해져
/// 있어, 좁은 폭에서도 한 줄에 놓이게 짧게 둔다.
const String carouselBannerSampleTitle = '여름 세일';

/// 미리보기와 코드가 함께 쓰는 보조 문구.
const String carouselBannerSampleDescription = '전 품목 30% 할인';

/// 줄바꿈 장면의 긴 제목.
const String carouselBannerLongTitle = '이번 주말까지만 열리는 여름 정기 할인';

/// 줄바꿈 장면의 긴 보조 문구.
const String carouselBannerLongDescription = '장바구니에 담은 모든 상품에 회원 추가 할인이 적용됩니다.';

/// 캐러셀 장면의 슬라이드(제목, 보조 문구). Flutter 의 Carousel 은 지금
/// 슬라이드의 높이를 모든 슬라이드에 주므로, 글을 모두 한 줄 길이로 둔다.
const List<(String, String)> carouselBannerSampleSlides = [
  (carouselBannerSampleTitle, carouselBannerSampleDescription),
  ('신간 입고', '새 책 세 권'),
  ('회원 혜택', '묶음 20% 할인'),
];

/// 구조 장면의 띠 폭.
const double carouselBannerAnatomyWidth = 288;

/// 장면의 보통 폭.
const double carouselBannerDemoWidth = 320;

/// 글이 줄바꿈되는 모습을 보이는 좁은 폭.
const double carouselBannerNarrowWidth = 256;

/// 관련 컴포넌트 카드 안 장면의 폭.
const double carouselBannerRelatedWidth = 240;

/// 값이 정해지는 순서의 단계 — 뒤로 갈수록 우선한다. 두 플랫폼 장면이 함께 읽는다.
const List<String> carouselBannerThemeOrder = ['디자인 시스템 기본값', '테마 carouselBanner.style', '인스턴스 carouselBannerStyle'];

// 크기 선택지는 Core 의 enum 에서 읽는다. `onTap` 은 처음부터 켠다 — Web 은
// 누를 수 있는 띠에 폭 클래스를 더해 두 플랫폼의 코드가 다르다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'size': CoreCarouselBannerSize.defaultSize.name,
    'thumbnail': 'true',
    'description': 'true',
    'tappable': 'true',
  },
  label: carouselBannerSampleTitle,
  controls: [
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in CoreCarouselBannerSize.values) size.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '썸네일', on: {'thumbnail': 'true'}),
    const DocsPlaygroundFlag(label: '보조 문구', on: {'description': 'true'}),
    const DocsPlaygroundFlag(label: '누를 수 있음(onTap)', on: {'tappable': 'true'}),
  ],
  code: _carouselBannerCode,
  webCode: _carouselBannerWebCode,
);

String _carouselBannerCode(Map<String, String> props, String? label) => _carouselBannerSnippet(props, label);

String _carouselBannerWebCode(Map<String, String> props, String? label) =>
    _carouselBannerSnippet(props, label, web: true);

/// 속성 → 코드. 기본값과 같은 속성은 적지 않는다. Web 의 누를 수 있는 띠는
/// 부모 폭을 채우도록 `classes` 를 더한다.
String _carouselBannerSnippet(Map<String, String> props, String? label, {bool web = false}) {
  String quoted(String value) => "'${value.replaceAll("'", r"\'")}'";
  final size = previewEnum(CoreCarouselBannerSize.values, props['size'], CoreCarouselBannerSize.defaultSize);
  final tappable = previewFlag(props, 'tappable');
  final lines = [
    if (size != CoreCarouselBannerSize.defaultSize) 'size: CoreCarouselBannerSize.${size.name},',
    if (previewFlag(props, 'thumbnail')) 'thumbnail: Icon(LucideIcons.image),',
    'title: Text(${quoted(label ?? carouselBannerSampleTitle)}),',
    if (previewFlag(props, 'description')) 'description: Text(${quoted(carouselBannerSampleDescription)}),',
    if (tappable) 'onTap: openSale,',
    if (web && tappable) "classes: 'w-full',",
  ];
  return 'CarouselBanner(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
