/// CarouselBanner 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="carousel-banner/...">`
/// 가 읽는다. 같은 이름의 Web 파일(`carousel_banner_web.dart`)과 컴포넌트 ·
/// 속성 · 장면 이름이 같아야 한다.
///
/// 띠는 폭의 한계가 있는 부모가 필요해, 장면은 폭을 정한 상자에 넣는다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
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

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _carouselBanner;

/// 장면 이름(`carousel-banner/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'carousel-banner/anatomy': () => const SizedBox(
    width: carouselBannerAnatomyWidth,
    child: CarouselBanner(
      size: CoreCarouselBannerSize.md,
      thumbnail: Icon(LucideIcons.image),
      title: Text(carouselBannerSampleTitle),
      description: Text(carouselBannerSampleDescription),
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
  'carousel-banner/do-short': () => SizedBox(width: carouselBannerDemoWidth, child: _sample()),
  'carousel-banner/dont-long': () => const SizedBox(
    width: carouselBannerNarrowWidth,
    child: CarouselBanner(
      thumbnail: Icon(LucideIcons.image),
      title: Text(carouselBannerLongTitle),
      description: Text(carouselBannerLongDescription),
    ),
  ),
  'carousel-banner/do-whole-tap': () => SizedBox(width: carouselBannerDemoWidth, child: _sample(tappable: true)),
  'carousel-banner/dont-button-inside': () => SizedBox(
    width: carouselBannerDemoWidth,
    child: CarouselBanner(
      thumbnail: const Icon(LucideIcons.image),
      title: const Text(carouselBannerSampleTitle),
      description: Button(
        variant: CoreButtonVariant.outline,
        size: CoreComponentSize.sm,
        onPressed: () {},
        child: const Text('쿠폰 받기'),
      ),
      onTap: () {},
    ),
  ),
  'carousel-banner/in-carousel': () => SizedBox(
    width: carouselBannerDemoWidth,
    child: Carousel(
      transition: const CoreCarouselTransition.sliding(),
      variant: CoreCarouselVariant.banner,
      items: _slides(),
    ),
  ),
  'carousel-banner/theme-order': () => Text(carouselBannerThemeOrder.join(' → ')),
  'carousel-banner/related-carousel': () => SizedBox(
    width: carouselBannerRelatedWidth,
    child: Carousel(
      transition: const CoreCarouselTransition.sliding(),
      variant: CoreCarouselVariant.banner,
      items: _slides(),
    ),
  ),
  'carousel-banner/related-card': () => SizedBox(
    width: carouselBannerRelatedWidth,
    child: Card(
      variant: CoreCardVariant.outlined,
      header: const Text(carouselBannerSampleTitle).titleSmall,
      body: const Text(carouselBannerSampleDescription).bodySmall.onSurfaceVariant,
    ),
  ),
  'carousel-banner/related-banner': () => const SizedBox(
    width: carouselBannerRelatedWidth,
    child: Banner(message: Text('새벽 2시에 점검이 있어요')),
  ),
};

Widget _carouselBanner(Map<String, String> props, String? label) => CarouselBanner(
  size: previewEnum(CoreCarouselBannerSize.values, props['size'], CoreCarouselBannerSize.defaultSize),
  thumbnail: previewFlag(props, 'thumbnail') ? const Icon(LucideIcons.image) : null,
  title: Text(label ?? carouselBannerSampleTitle),
  description: previewFlag(props, 'description') ? const Text(carouselBannerSampleDescription) : null,
  onTap: previewFlag(props, 'tappable') ? () {} : null,
);

/// 장면이 함께 쓰는 기본 띠.
Widget _sample({bool tappable = false}) => CarouselBanner(
  thumbnail: const Icon(LucideIcons.image),
  title: const Text(carouselBannerSampleTitle),
  description: const Text(carouselBannerSampleDescription),
  onTap: tappable ? () {} : null,
);

/// 캐러셀 장면의 띠들.
List<Widget> _slides() => [
  for (final (title, description) in carouselBannerSampleSlides)
    CarouselBanner(thumbnail: const Icon(LucideIcons.image), title: Text(title), description: Text(description)),
];

/// 그림 자리 — 네트워크 없이 그리는 색 면. 썸네일 상자의 크기를 채운다.
Widget _picture() => Builder(
  builder: (context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.resolve(const CoreColor.token(CoreColors.primary)).toValue(),
            scheme.resolve(const CoreColor.token(CoreColors.tertiary)).toValue(),
          ],
        ),
      ),
    );
  },
);

/// 폭을 정한 세로 묶음.
Widget _column(double width, List<Widget> children) => SizedBox(
  width: width,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CoreSpace.space8,
    children: children,
  ),
);
