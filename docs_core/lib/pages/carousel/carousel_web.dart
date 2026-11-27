/// Carousel 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="carousel/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`carousel_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 장면은 자동 재생을 켜지 않는다. 슬라이드는 그림을 내려받지 않고 색 토큰으로
/// 칠한 면과 `CarouselBanner` 로 그린다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'carousel_page.dart'
    show carouselBannerSamples, carouselPreviewFraction, carouselPreviewKey, carouselSlideCount, carouselSlideLabel;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _carousel;

/// 장면 이름(`carousel/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 이전 · 다음 버튼은 포인터를 올려야 보이므로 이 그림에서만 늘 보이게
  // 한다. `wrap: false` 는 첫 장 앞에 복제 장을 만들지 않아, 번호가 보이는 첫
  // 장을 가리킨다.
  'carousel/anatomy': () => div(
    attributes: const {'data-docs-part': 'carousel-anatomy'},
    // 구조 무대의 대상 상자는 내용 폭을 따르므로 `100%` 로는 좁아지지 않는다 —
    // 좁은 화면에서는 화면 폭에서 문서 여백을 뺀 값이 상한이다.
    styles: Styles(raw: {'width': 'min(20rem, calc(100vw - 8rem))', 'max-width': '100%'}),
    [
      Component.element(
        tag: 'style',
        children: [RawText('[data-docs-part=carousel-anatomy] div:has(> button){opacity:1 !important}')],
      ),
      Carousel(wrap: false, items: _slides()),
    ],
  ),
  'carousel/sizes': () => docsWebDemoRow([
    for (final size in CoreCarouselSize.values)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'align-items': 'center',
            'gap': 'var(--coui-space-8)',
            'width': '10rem',
          },
        ),
        [
          _frame(
            Carousel(
              size: size,
              items: _slides(height: '7rem'),
            ),
            width: '10rem',
          ),
          code([Component.text(size.name)]),
        ],
      ),
  ]),
  'carousel/peek': () => div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--coui-space-8)',
        'width': '20rem',
        'max-width': '100%',
      },
    ),
    [
      for (final alignment in const [CoreCarouselAlignment.center, CoreCarouselAlignment.start]) ...[
        Carousel(
          alignment: alignment,
          sizeConstraint: const CoreCarouselSizeConstraint.fractional(0.8),
          transition: const CoreCarouselTransition.sliding(gap: CoreSpace.space12),
          showIndicators: false,
          items: _slides(height: '6rem'),
        ),
        code([Component.text('alignment: ${alignment.name}')]),
      ],
    ],
  ),
  'carousel/vertical': () => _frame(
    Carousel(
      direction: CoreAxis.vertical,
      css: Styles(raw: {'height': '10rem'}),
      // Web 세로 방향의 버튼 여백은 `top` · `bottom` 을 읽는다.
      carouselStyle: const CoreCarouselStyle(navInset: CoreEdgeInsets.symmetric(vertical: CoreSpace.space16)),
      items: _slides(),
    ),
  ),
  'carousel/do-cue': () => _frame(Carousel(variant: CoreCarouselVariant.banner, items: _banners())),
  'carousel/dont-no-cue': () => _frame(
    Carousel(variant: CoreCarouselVariant.banner, showIndicators: false, items: _banners()),
  ),
  'carousel/related-carousel-banner': () => _frame(
    CarouselBanner(thumbnail: Icon(LucideIcons.bell), title: Text('알림 설정'), description: Text('새 소식 받기')),
    width: '15rem',
  ),
  'carousel/related-dot-indicator': () => DotIndicator(index: 1, length: 4),
  'carousel/related-hover-gallery': () => _frame(
    HoverGallery(
      itemCount: carouselSlideCount,
      itemBuilder: (index) => _slide(index, height: '7rem'),
      hoverGalleryStyle: const CoreHoverGalleryStyle(height: 112),
    ),
    width: '10rem',
  ),
};

Component _carousel(Map<String, String> props, String? label) {
  final variant = previewEnum(CoreCarouselVariant.values, props['variant'], CoreCarouselVariant.defaultVariant);
  final mode = previewEnum(CoreCarouselTransitionMode.values, props['transition'], CoreCarouselTransitionMode.sliding);
  final autoPlay = previewFlag(props, 'autoPlay');
  return _frame(
    Carousel(
      key: ValueKey(carouselPreviewKey(props)),
      transition: mode == CoreCarouselTransitionMode.fading
          ? const CoreCarouselTransition.fading()
          : const CoreCarouselTransition.sliding(),
      variant: variant,
      size: previewEnum(CoreCarouselSize.values, props['size'], CoreCarouselSize.defaultSize),
      sizeConstraint: CoreCarouselSizeConstraint.fractional(carouselPreviewFraction(props)),
      showIndicators: previewFlag(props, 'showIndicators', fallback: true),
      autoPlay: autoPlay,
      waitOnStart: autoPlay,
      items: variant == CoreCarouselVariant.banner ? _banners() : _slides(),
    ),
  );
}

/// 장면의 틀 — Flutter 장면의 `SizedBox(width: …)` 자리다. 좁은 무대에서는
/// 줄어든다.
Component _frame(Component child, {String width = '20rem'}) => div(
  styles: Styles(raw: {'width': width, 'max-width': '100%', 'min-width': '0'}),
  [child],
);

/// 색 토큰으로 칠한 슬라이드 한 장.
Component _slide(int index, {String height = '10rem'}) {
  final text = Text(carouselSlideLabel(index)).titleMedium;
  final fill = switch (index % carouselSlideCount) {
    0 => CoreColors.surfaceContainerHighest,
    1 => CoreColors.surfaceContainerHigh,
    _ => CoreColors.surfaceContainer,
  };
  final label = text.onSurface;
  return div(
    attributes: const {'data-docs-part': 'slide'},
    styles: Styles(
      raw: {
        'display': 'flex',
        'align-items': 'center',
        'justify-content': 'center',
        'height': height,
        'background-color': CoreColor.token(fill).toValue(),
      },
    ),
    [label],
  );
}

List<Component> _slides({String height = '10rem'}) => [
  for (var index = 0; index < carouselSlideCount; index++) _slide(index, height: height),
];

List<Component> _banners() => [
  for (final (title, body) in carouselBannerSamples)
    CarouselBanner(thumbnail: Icon(LucideIcons.image), title: Text(title), description: Text(body)),
];
