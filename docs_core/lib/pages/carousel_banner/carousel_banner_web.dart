/// CarouselBanner 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="carousel-banner/...">`
/// 가 읽는다. 같은 이름의 Flutter 파일(`carousel_banner_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Web 의 누를 수 있는 띠는 가장 바깥 상자가 내용 폭을 따를 수 있어, 장면은
/// 누를 수 있는 띠에 `classes: 'w-full'` 을 준다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'carousel_banner_page.dart'
    show
        carouselBannerAnatomyWidth,
        carouselBannerDemoWidth,
        carouselBannerLongDescription,
        carouselBannerLongTitle,
        carouselBannerNarrowWidth,
        carouselBannerRelatedWidth,
        carouselBannerSampleDescription,
        carouselBannerSampleSlides,
        carouselBannerSampleTitle,
        carouselBannerThemeOrder;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _carouselBanner;

/// 장면 이름(`carousel-banner/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 번호가 띠 자체를 가리키도록 감싸는 상자 없이 폭을 띠에 준다.
  'carousel-banner/anatomy': () => CarouselBanner(
    size: CoreCarouselBannerSize.md,
    thumbnail: const Icon(LucideIcons.image),
    title: span(attributes: const {'data-docs-part': 'title'}, [const Text(carouselBannerSampleTitle)]),
    description: span(
      attributes: const {'data-docs-part': 'description'},
      [const Text(carouselBannerSampleDescription)],
    ),
    // 구조 무대의 대상 상자는 내용 폭을 따르므로 `100%` 로는 좁아지지 않는다 —
    // 좁은 화면에서는 화면 폭에서 문서 여백을 뺀 값이 상한이다.
    css: Styles(
      raw: {'width': 'min(${carouselBannerAnatomyWidth / 16}rem, calc(100vw - 8rem))', 'max-width': '100%'},
    ),
  ),
  'carousel-banner/sizes': () => _column(carouselBannerDemoWidth, [
    for (final size in CoreCarouselBannerSize.values) ...[
      Text(size.name).labelSmall.onSurfaceVariant,
      CarouselBanner(
        size: size,
        thumbnail: const Icon(LucideIcons.image),
        title: const Text(carouselBannerSampleTitle),
        description: const Text(carouselBannerSampleDescription),
      ),
    ],
  ]),
  'carousel-banner/wrapping': () => _column(carouselBannerNarrowWidth, [
    _sample(),
    const CarouselBanner(
      thumbnail: Icon(LucideIcons.image),
      title: Text(carouselBannerLongTitle),
      description: Text(carouselBannerLongDescription),
    ),
  ]),
  'carousel-banner/thumbnail': () => _column(carouselBannerDemoWidth, [
    const CarouselBanner(
      thumbnail: Icon(LucideIcons.image),
      title: Text('아이콘'),
      description: Text('가운데에 놓입니다'),
    ),
    CarouselBanner(thumbnail: _picture(), title: const Text('그림 자리'), description: const Text('색 면으로 대신했습니다')),
    const CarouselBanner(title: Text('썸네일 없음'), description: Text('글이 폭을 다 씁니다')),
  ]),
  'carousel-banner/states': () => _column(carouselBannerDemoWidth, [
    const Text('표시 전용').labelSmall.onSurfaceVariant,
    _sample(),
    const Text('누를 수 있음 — onTap').labelSmall.onSurfaceVariant,
    _sample(tappable: true),
  ]),
  'carousel-banner/do-short': () => _frame(carouselBannerDemoWidth, _sample()),
  'carousel-banner/dont-long': () => _frame(
    carouselBannerNarrowWidth,
    const CarouselBanner(
      thumbnail: Icon(LucideIcons.image),
      title: Text(carouselBannerLongTitle),
      description: Text(carouselBannerLongDescription),
    ),
  ),
  'carousel-banner/do-whole-tap': () => _frame(carouselBannerDemoWidth, _sample(tappable: true)),
  'carousel-banner/dont-button-inside': () => _frame(
    carouselBannerDemoWidth,
    CarouselBanner(
      thumbnail: const Icon(LucideIcons.image),
      title: const Text(carouselBannerSampleTitle),
      description: Button(
        variant: CoreButtonVariant.outline,
        size: CoreComponentSize.sm,
        onPressed: () {},
        child: const Text('쿠폰 받기'),
      ),
      onTap: () {},
      classes: 'w-full',
    ),
  ),
  'carousel-banner/in-carousel': () => _frame(
    carouselBannerDemoWidth,
    Carousel(variant: CoreCarouselVariant.banner, items: _slides()),
  ),
  'carousel-banner/theme-order': () => div(classes: 'docs-demo-order', [
    const Text('적용 순서 · 뒤로 갈수록 우선합니다').labelMedium.onSurfaceVariant,
    ol([
      for (final (index, step) in carouselBannerThemeOrder.indexed)
        li(classes: index == carouselBannerThemeOrder.length - 1 ? 'is-strong' : null, [
          span([Component.text('${index + 1}')]),
          Component.text(step),
        ]),
    ]),
  ]),
  'carousel-banner/related-carousel': () => _frame(
    carouselBannerRelatedWidth,
    Carousel(variant: CoreCarouselVariant.banner, items: _slides()),
  ),
  'carousel-banner/related-card': () => _frame(
    carouselBannerRelatedWidth,
    Card(
      variant: CoreCardVariant.outlined,
      header: const Text(carouselBannerSampleTitle).titleSmall,
      body: const Text(carouselBannerSampleDescription).bodySmall.onSurfaceVariant,
    ),
  ),
  'carousel-banner/related-banner': () => _frame(
    carouselBannerRelatedWidth,
    const Banner(message: Text('새벽 2시에 점검이 있어요')),
  ),
};

Component _carouselBanner(Map<String, String> props, String? label) {
  final tappable = previewFlag(props, 'tappable');
  return CarouselBanner(
    size: previewEnum(CoreCarouselBannerSize.values, props['size'], CoreCarouselBannerSize.defaultSize),
    thumbnail: previewFlag(props, 'thumbnail') ? const Icon(LucideIcons.image) : null,
    title: Text(label ?? carouselBannerSampleTitle),
    description: previewFlag(props, 'description') ? const Text(carouselBannerSampleDescription) : null,
    onTap: tappable ? () {} : null,
    classes: tappable ? 'w-full' : null,
  );
}

/// 장면이 함께 쓰는 기본 띠.
Component _sample({bool tappable = false}) => CarouselBanner(
  thumbnail: const Icon(LucideIcons.image),
  title: const Text(carouselBannerSampleTitle),
  description: const Text(carouselBannerSampleDescription),
  onTap: tappable ? () {} : null,
  classes: tappable ? 'w-full' : null,
);

/// 캐러셀 장면의 띠들.
List<Component> _slides() => [
  for (final (title, description) in carouselBannerSampleSlides)
    CarouselBanner(thumbnail: const Icon(LucideIcons.image), title: Text(title), description: Text(description)),
];

/// 그림 자리 — 네트워크 없이 그리는 색 면. 썸네일 상자의 크기를 채운다.
Component _picture() => div(
  styles: Styles(
    raw: {
      'width': '100%',
      'height': '100%',
      'background': 'linear-gradient(135deg, rgb(var(--coui-primary)), rgb(var(--coui-tertiary)))',
    },
  ),
  [],
);

/// 폭을 정한 틀. 좁은 무대에서는 무대 폭까지만 늘어난다.
Component _frame(double width, Component child) => div(
  styles: Styles(raw: {'width': '100%', 'max-width': '${width / 16}rem'}),
  [child],
);

/// 폭을 정한 세로 묶음.
Component _column(double width, List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': 'var(--coui-space-8)',
      'width': '100%',
      'max-width': '${width / 16}rem',
    },
  ),
  children,
);
