/// CardImage 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="card-image/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`card_image_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 세로 카드는 폭을 정한 부모 안에 둔다. 가로 카드는 받은 높이를 모두 채우므로
/// `IntrinsicHeight` 로 감싸 내용 높이에 맞춘다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import '../page_kit_flutter.dart';
import 'card_image_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _cardImage;

/// 장면 이름(`card-image/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'card-image/anatomy': () => _box(
    page.cardImageWidth,
    CardImage(
      image: _wide(page.cardImageSunrise),
      leading: Icon(LucideIcons.star),
      title: const Text(page.cardImageTitle),
      subtitle: const Text(page.cardImageSubtitle),
    ),
  ),
  'card-image/image-ratios': () => docsFlutterDemoRow([
    for (final (caption, ratio) in page.cardImageRatios)
      _box(
        page.cardImageRatioWidth,
        CardImage(
          image: _wide(page.cardImageSunrise, ratio: ratio),
          title: Text(caption),
        ),
      ),
  ]),
  'card-image/placeholders': () => docsFlutterDemoRow([
    for (final (sample, caption) in page.cardImagePlaceholders)
      _box(page.cardImageCompactWidth, CardImage(image: _wide(sample), title: Text(caption))),
  ]),
  'card-image/states': () => docsFlutterDemoRow([
    for (final (caption, pressable, enabled) in page.cardImageStates)
      _box(
        page.cardImageCompactWidth,
        CardImage(
          image: _wide(page.cardImageSunrise),
          title: Text(caption),
          onPressed: pressable ? () {} : null,
          enabled: enabled,
        ),
      ),
  ]),
  'card-image/horizontal': () => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IntrinsicHeight(
        child: CardImage(
          image: _thumbnail(page.cardImageSunrise),
          title: const Text('기본 여백'),
          subtitle: const Text(page.cardImageSubtitle),
          cardImageStyle: page.cardImageHorizontalStyle,
        ),
      ),
      const Gap.space16(),
      IntrinsicHeight(
        child: CardImage(
          image: _thumbnail(page.cardImageSunrise),
          title: const Text('여백 조정'),
          subtitle: const Text(page.cardImageSubtitle),
          cardImageStyle: page.cardImageHorizontalFlushStyle,
        ),
      ),
    ],
  ),
  'card-image/styled': () => docsFlutterDemoRow([
    _box(page.cardImageCompactWidth, CardImage(image: _wide(page.cardImageSunrise), title: const Text('기본값'))),
    _box(
      page.cardImageCompactWidth,
      CardImage(
        image: _wide(page.cardImageSunrise),
        title: const Text('덮어쓴 값'),
        cardImageStyle: page.cardImageStyledStyle,
      ),
    ),
  ]),
  'card-image/a11y-name': () => _box(
    page.cardImageWidth,
    CardImage(
      image: AspectRatioBox(
        ratio: page.cardImageWideRatio,
        child: Semantics(label: page.cardImageAlt, image: true, child: _art(page.cardImageSunrise)),
      ),
      title: const Text(page.cardImageTitle),
      onPressed: () {},
    ),
  ),
  'card-image/do-action': () => _box(
    page.cardImageUsageWidth,
    CardImage(
      image: _wide(page.cardImageSunrise),
      title: const Text(page.cardImageTitle),
      subtitle: const Text('사진 크게 보기'),
      onPressed: () {},
    ),
  ),
  'card-image/dont-inner-button': () => _box(
    page.cardImageUsageWidth,
    CardImage(
      image: _wide(page.cardImageSunrise),
      title: const Text(page.cardImageTitle),
      trailing: Button(
        variant: CoreButtonVariant.outline,
        size: CoreComponentSize.sm,
        onPressed: () {},
        child: const Text('저장'),
      ),
      onPressed: () {},
    ),
  ),
  'card-image/do-disabled': () => _box(
    page.cardImageUsageWidth,
    CardImage(
      image: _wide(page.cardImageSunrise),
      title: const Text('보관한 사진'),
      subtitle: const Text('지금은 열 수 없어요'),
      onPressed: () {},
      enabled: false,
    ),
  ),
  'card-image/dont-disabled': () => _box(
    page.cardImageUsageWidth,
    CardImage(
      image: _wide(page.cardImageSunrise),
      title: const Text('보관한 사진'),
      subtitle: const Text('지금은 열 수 없어요'),
      enabled: false,
    ),
  ),
  'card-image/related-card': () => _box(
    page.cardImageUsageWidth,
    const Card(header: Text('주문 안내'), body: Text('머리글과 본문을 직접 채웁니다.')),
  ),
  'card-image/related-aspect-ratio-box': () => _box(page.cardImageCompactWidth, _wide(page.cardImageSunrise)),
  'card-image/related-description-card': () => _box(
    page.cardImageUsageWidth,
    const DescriptionCard(
      rows: [
        DescriptionRow(label: '촬영지', value: '지리산'),
        DescriptionRow(label: '촬영일', value: '10월 3일'),
      ],
    ),
  ),
  'card-image/related-avatar': () => const Avatar(initials: 'KS'),
};

Widget _cardImage(Map<String, String> props, String? label) {
  final horizontal = page.cardImagePreviewHorizontal(props);
  final card = CardImage(
    image: horizontal ? _thumbnail(page.cardImageSunrise) : _wide(page.cardImageSunrise),
    title: Text(label ?? page.cardImageTitle),
    subtitle: previewFlag(props, 'subtitle') ? const Text(page.cardImageSubtitle) : null,
    leading: docsFlutterIcon(props['leading']),
    trailing: docsFlutterIcon(props['trailing']),
    onPressed: previewFlag(props, 'pressable') ? () {} : null,
    enabled: props['enabled'] == 'false' ? false : null,
    cardImageStyle: page.cardImagePreviewStyle(props),
  );
  return horizontal ? IntrinsicHeight(child: card) : _box(page.cardImageWidth, card);
}

/// 폭을 정한 상자. 부모가 더 좁으면 부모 폭을 따른다.
Widget _box(double width, Widget child) => SizedBox(width: width, child: child);

/// 폭을 채우고 비율을 지키는 그림.
Widget _wide(page.CardImageSample sample, {double ratio = page.cardImageWideRatio}) =>
    AspectRatioBox(ratio: ratio, child: _art(sample));

/// 너비와 높이를 정한 정사각 그림.
Widget _thumbnail(page.CardImageSample sample) =>
    SizedBox.square(dimension: page.cardImageThumbnailSize, child: _art(sample));

/// 사진 자리의 그림 — 색 면 안에 테두리를 두르고 아이콘을 놓는다. 안쪽
/// 테두리가 있어 hover 확대가 눈에 보인다.
Widget _art(page.CardImageSample sample) => Builder(
  builder: (context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = CoreColor.token(sample.ink);
    return ColoredBox(
      color: scheme.resolve(CoreColor.token(sample.fill)).toValue(),
      child: Padding(
        padding: const EdgeInsets.all(CoreSpace.space12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.resolve(ink).toValue(), width: CoreStrokeWidth.stroke2),
            borderRadius: const BorderRadius.all(Radius.circular(CoreRadius.radius12)),
          ),
          child: Center(
            child: Icon(
              sample.icon,
              iconStyle: CoreIconStyle(size: CoreIconSize.size24, color: ink),
            ),
          ),
        ),
      ),
    );
  },
);
