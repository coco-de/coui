/// Carousel 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `carousel_web.dart` · `carousel_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 슬라이드는 그림 대신 색 토큰으로 칠한 면이나 `CarouselBanner` 다. 두
/// 플랫폼이 같은 글을 쓰도록 슬라이드의 글은 이 파일에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/carousel.md`.
const String slug = 'carousel';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// `Carousel.size` 는 `CoreCarouselSize`(점 크기)라 `CoreComponentSize` 의
/// 크기 행이 없다. 크기는 본문의 장면과 표로 보인다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 색 슬라이드의 장 수.
const int carouselSlideCount = 3;

/// 색 슬라이드에 적는 글.
String carouselSlideLabel(int index) => '슬라이드 ${index + 1}';

/// 배너 슬라이드의 제목과 보조 문구. 좁은 무대에서도 한 줄에 들어가 모든
/// 장의 높이가 같도록 짧게 둔다.
const List<(String, String)> carouselBannerSamples = [
  ('신간 안내', '새 책 3권'),
  ('독서 모임', '토요일 10시'),
  ('회원 할인', '묶음 20%'),
];

/// 속성의 `fraction` → 슬라이드 폭의 비율. 없거나 0 이하 · 1 초과면 1.
double carouselPreviewFraction(Map<String, String> props) {
  final fraction = double.tryParse(props['fraction'] ?? '');
  return fraction != null && fraction > 0 && fraction <= 1 ? fraction : 1;
}

/// 속성 묶음마다 다른 키. 속성이 바뀌면 캐러셀을 처음 상태로 다시 만든다 —
/// Flutter 캐러셀은 실행 중에 `autoPlay` 를 켜도 바로 돌기 시작하지 않는다.
String carouselPreviewKey(Map<String, String> props) =>
    [for (final key in props.keys.toList()..sort()) '$key=${props[key]}'].join(';');

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'variant': CoreCarouselVariant.defaultVariant.name,
    'transition': CoreCarouselTransitionMode.sliding.name,
    'fraction': '1',
    'size': CoreCarouselSize.defaultSize.name,
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreCarouselVariant.values) variant.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'transition',
      prop: 'transition',
      options: [CoreCarouselTransitionMode.sliding.name, CoreCarouselTransitionMode.fading.name],
      segmented: true,
    ),
    const DocsPlaygroundChoice(label: '슬라이드 폭 비율', prop: 'fraction', options: ['1', '0.8'], segmented: true),
    DocsPlaygroundChoice(
      label: 'size (점 크기)',
      prop: 'size',
      options: [for (final size in CoreCarouselSize.values) size.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '점 숨기기', on: {'showIndicators': 'false'}),
    const DocsPlaygroundFlag(label: '자동 재생', on: {'autoPlay': 'true'}),
  ],
  code: _carouselCode,
  webCode: _carouselWebCode,
);

String _carouselCode(Map<String, String> props, String? label) => _carouselSnippet(props, web: false);

String _carouselWebCode(Map<String, String> props, String? label) => _carouselSnippet(props, web: true);

/// 속성 → 코드. 기본값과 같은 값은 적지 않는다. Flutter 는 `transition` 이
/// 필수라 늘 적고, Web 은 기본값(sliding)이면 적지 않는다.
String _carouselSnippet(Map<String, String> props, {required bool web}) {
  final variant = previewEnum(CoreCarouselVariant.values, props['variant'], CoreCarouselVariant.defaultVariant);
  final mode = previewEnum(CoreCarouselTransitionMode.values, props['transition'], CoreCarouselTransitionMode.sliding);
  final size = previewEnum(CoreCarouselSize.values, props['size'], CoreCarouselSize.defaultSize);
  final fraction = carouselPreviewFraction(props);
  final lines = [
    if (!web)
      'transition: CarouselTransition.${mode.name}(),'
    else if (mode == CoreCarouselTransitionMode.fading)
      'transition: CoreCarouselTransition.fading(),',
    if (variant != CoreCarouselVariant.defaultVariant) 'variant: CoreCarouselVariant.${variant.name},',
    if (size != CoreCarouselSize.defaultSize) 'size: CoreCarouselSize.${size.name},',
    if (fraction != 1) 'sizeConstraint: CoreCarouselSizeConstraint.fractional($fraction),',
    if (!previewFlag(props, 'showIndicators', fallback: true)) 'showIndicators: false,',
    if (previewFlag(props, 'autoPlay')) ...['autoPlay: true,', 'waitOnStart: true,'],
    'items: ${variant == CoreCarouselVariant.banner ? 'banners' : 'slides'},',
  ];
  return 'Carousel(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
