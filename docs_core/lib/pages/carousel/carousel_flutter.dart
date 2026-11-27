/// Carousel 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="carousel/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`carousel_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 장면은 자동 재생을 켜지 않는다. 슬라이드는 그림을 내려받지 않고 색 토큰으로
/// 칠한 면과 `CarouselBanner` 로 그린다. 장면마다 폭을 정하고 슬라이드마다
/// 높이를 정해, 높이가 정해지지 않은 스크롤 안에서도 같은 크기로 그려진다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'carousel_page.dart'
    show carouselBannerSamples, carouselPreviewFraction, carouselPreviewKey, carouselSlideCount, carouselSlideLabel;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _carousel;

/// 장면 이름(`carousel/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'carousel/anatomy': () => _frame(
    Carousel(wrap: false, transition: const CarouselTransition.sliding(), items: _slides()),
  ),
  'carousel/sizes': () => docsFlutterDemoRow([
    for (final size in CoreCarouselSize.values)
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space8,
        children: [
          SizedBox(
            width: CoreLayout.layout160,
            child: Carousel(size: size, transition: const CarouselTransition.sliding(), items: _slides(height: 112)),
          ),
          Text(size.name).codeSm.onSurfaceVariant,
        ],
      ),
  ]),
  'carousel/peek': () => _frame(
    Column(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space8,
      children: [
        for (final alignment in const [CoreCarouselAlignment.center, CoreCarouselAlignment.start]) ...[
          Carousel(
            alignment: alignment,
            sizeConstraint: const CoreCarouselSizeConstraint.fractional(0.8),
            transition: const CarouselTransition.sliding(gap: CoreSpace.space12),
            showIndicators: false,
            items: _slides(height: 96),
          ),
          Text('alignment: ${alignment.name}').codeSm.onSurfaceVariant,
        ],
      ],
    ),
  ),
  'carousel/vertical': () => SizedBox(
    width: CoreLayout.layout320,
    height: CoreLayout.layout160,
    child: Carousel(
      direction: CoreAxis.vertical,
      transition: const CarouselTransition.sliding(),
      items: _slides(),
    ),
  ),
  'carousel/do-cue': () => _frame(
    Carousel(variant: CoreCarouselVariant.banner, transition: const CarouselTransition.sliding(), items: _banners()),
  ),
  'carousel/dont-no-cue': () => _frame(
    Carousel(
      variant: CoreCarouselVariant.banner,
      transition: const CarouselTransition.sliding(),
      showIndicators: false,
      items: _banners(),
    ),
  ),
  'carousel/related-carousel-banner': () => const SizedBox(
    width: CoreLayout.layout240,
    child: CarouselBanner(thumbnail: Icon(LucideIcons.bell), title: Text('알림 설정'), description: Text('새 소식 받기')),
  ),
  'carousel/related-dot-indicator': () => const DotIndicator(index: 1, length: 4),
  'carousel/related-hover-gallery': () => SizedBox(
    width: CoreLayout.layout160,
    child: HoverGallery(
      itemCount: carouselSlideCount,
      itemBuilder: (index) => _Slide(index, height: 112),
      hoverGalleryStyle: const CoreHoverGalleryStyle(height: 112),
    ),
  ),
};

Widget _carousel(Map<String, String> props, String? label) {
  final variant = previewEnum(CoreCarouselVariant.values, props['variant'], CoreCarouselVariant.defaultVariant);
  final mode = previewEnum(CoreCarouselTransitionMode.values, props['transition'], CoreCarouselTransitionMode.sliding);
  final autoPlay = previewFlag(props, 'autoPlay');
  Widget carousel() => Carousel(
    key: ValueKey(carouselPreviewKey(props)),
    transition: mode == CoreCarouselTransitionMode.fading
        ? const CarouselTransition.fading()
        : const CarouselTransition.sliding(),
    variant: variant,
    size: previewEnum(CoreCarouselSize.values, props['size'], CoreCarouselSize.defaultSize),
    sizeConstraint: CoreCarouselSizeConstraint.fractional(carouselPreviewFraction(props)),
    showIndicators: previewFlag(props, 'showIndicators', fallback: true),
    autoPlay: autoPlay,
    waitOnStart: autoPlay,
    items: variant == CoreCarouselVariant.banner ? _banners() : _slides(),
  );
  // 문서 사이트가 Flutter 칸을 숨기면 너비가 0 이 된다. `sliding` 캐러셀은 그때
  // 레이아웃에서 예외를 던지므로 만들지 않는다.
  return _frame(
    LayoutBuilder(builder: (context, constraints) => constraints.maxWidth > 0 ? carousel() : const SizedBox.shrink()),
  );
}

/// 장면의 틀 — Web 장면의 폭(20rem)과 같다. 좁은 무대에서는 줄어든다.
Widget _frame(Widget child) => SizedBox(width: CoreLayout.layout320, child: child);

List<Widget> _slides({double height = CoreLayout.layout160}) => [
  for (var index = 0; index < carouselSlideCount; index++) _Slide(index, height: height),
];

List<Widget> _banners() => [
  for (final (title, body) in carouselBannerSamples)
    CarouselBanner(thumbnail: const Icon(LucideIcons.image), title: Text(title), description: Text(body)),
];

/// 색 토큰으로 칠한 슬라이드 한 장. 높이를 정해 두어 캐러셀이 현재 장에서
/// 높이를 잡는다.
class _Slide extends StatelessWidget {
  const _Slide(this.index, {required this.height});

  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    final text = Text(carouselSlideLabel(index)).titleMedium;
    final fill = switch (index % carouselSlideCount) {
      0 => CoreColors.surfaceContainerHighest,
      1 => CoreColors.surfaceContainerHigh,
      _ => CoreColors.surfaceContainer,
    };
    final label = text.onSurface;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.resolve(CoreColor.token(fill)).toValue(),
        child: Center(child: label),
      ),
    );
  }
}
