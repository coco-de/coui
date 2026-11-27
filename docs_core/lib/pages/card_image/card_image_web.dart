/// CardImage 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="card-image/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`card_image_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Web 의 카드는 내용 폭을 따르고, `AspectRatioBox` 는 자기 폭이 없다. 그래서
/// 세로 카드는 폭을 정한 상자 안에 두고 `css` 로 그 폭을 채운다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import '../page_kit_web.dart';
import 'card_image_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _cardImage;

/// 장면 이름(`card-image/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — `data-docs-part` 는 번호가 부분을 찾는 표시다.
  'card-image/anatomy': () => _box(
    page.cardImageWidth,
    CardImage(
      image: div(attributes: const {'data-docs-part': 'image'}, [_wide(page.cardImageSunrise)]),
      leading: span(attributes: const {'data-docs-part': 'leading'}, [Icon(LucideIcons.star)]),
      title: Text(page.cardImageTitle),
      subtitle: span(attributes: const {'data-docs-part': 'subtitle'}, [Text(page.cardImageSubtitle)]),
      css: _fill,
    ),
  ),
  'card-image/image-ratios': () => docsWebDemoRow([
    for (final (caption, ratio) in page.cardImageRatios)
      _box(
        page.cardImageRatioWidth,
        CardImage(
          image: _wide(page.cardImageSunrise, ratio: ratio),
          title: Text(caption),
          css: _fill,
        ),
      ),
  ]),
  'card-image/placeholders': () => docsWebDemoRow([
    for (final (sample, caption) in page.cardImagePlaceholders)
      _box(page.cardImageCompactWidth, CardImage(image: _wide(sample), title: Text(caption), css: _fill)),
  ]),
  'card-image/states': () => docsWebDemoRow([
    for (final (caption, pressable, enabled) in page.cardImageStates)
      _box(
        page.cardImageCompactWidth,
        CardImage(
          image: _wide(page.cardImageSunrise),
          title: Text(caption),
          onPressed: pressable ? () {} : null,
          enabled: enabled,
          css: _fill,
        ),
      ),
  ]),
  'card-image/horizontal': () => div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'align-items': 'center',
        'gap': spaceCss(CoreSpace.space16),
        'max-width': '100%',
      },
    ),
    [
      CardImage(
        image: _thumbnail(page.cardImageSunrise),
        title: Text('기본 여백'),
        subtitle: Text(page.cardImageSubtitle),
        cardImageStyle: page.cardImageHorizontalStyle,
      ),
      CardImage(
        image: _thumbnail(page.cardImageSunrise),
        title: Text('여백 조정'),
        subtitle: Text(page.cardImageSubtitle),
        cardImageStyle: page.cardImageHorizontalFlushStyle,
      ),
    ],
  ),
  'card-image/styled': () => docsWebDemoRow([
    _box(
      page.cardImageCompactWidth,
      CardImage(image: _wide(page.cardImageSunrise), title: Text('기본값'), css: _fill),
    ),
    _box(
      page.cardImageCompactWidth,
      CardImage(
        image: _wide(page.cardImageSunrise),
        title: Text('덮어쓴 값'),
        cardImageStyle: page.cardImageStyledStyle,
        css: _fill,
      ),
    ),
  ]),
  'card-image/a11y-name': () => _box(
    page.cardImageWidth,
    CardImage(
      image: AspectRatioBox(
        ratio: page.cardImageWideRatio,
        child: _art(page.cardImageSunrise, attributes: const {'role': 'img', 'aria-label': page.cardImageAlt}),
      ),
      title: Text(page.cardImageTitle),
      onPressed: () {},
      css: _fill,
    ),
  ),
  'card-image/do-action': () => _box(
    page.cardImageUsageWidth,
    CardImage(
      image: _wide(page.cardImageSunrise),
      title: Text(page.cardImageTitle),
      subtitle: Text('사진 크게 보기'),
      onPressed: () {},
      css: _fill,
    ),
  ),
  'card-image/dont-inner-button': () => _box(
    page.cardImageUsageWidth,
    CardImage(
      image: _wide(page.cardImageSunrise),
      title: Text(page.cardImageTitle),
      trailing: Button(
        variant: CoreButtonVariant.outline,
        size: CoreComponentSize.sm,
        onPressed: () {},
        child: Text('저장'),
      ),
      onPressed: () {},
      css: _fill,
    ),
  ),
  'card-image/do-disabled': () => _box(
    page.cardImageUsageWidth,
    CardImage(
      image: _wide(page.cardImageSunrise),
      title: Text('보관한 사진'),
      subtitle: Text('지금은 열 수 없어요'),
      onPressed: () {},
      enabled: false,
      css: _fill,
    ),
  ),
  'card-image/dont-disabled': () => _box(
    page.cardImageUsageWidth,
    CardImage(
      image: _wide(page.cardImageSunrise),
      title: Text('보관한 사진'),
      subtitle: Text('지금은 열 수 없어요'),
      enabled: false,
      css: _fill,
    ),
  ),
  'card-image/related-card': () => _box(
    page.cardImageUsageWidth,
    Card(header: Text('주문 안내'), body: Text('머리글과 본문을 직접 채웁니다.')),
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
  'card-image/related-avatar': () => Avatar(initials: 'KS'),
};

Component _cardImage(Map<String, String> props, String? label) {
  final horizontal = page.cardImagePreviewHorizontal(props);
  final card = CardImage(
    image: horizontal ? _thumbnail(page.cardImageSunrise) : _wide(page.cardImageSunrise),
    title: Text(label ?? page.cardImageTitle),
    subtitle: previewFlag(props, 'subtitle') ? Text(page.cardImageSubtitle) : null,
    leading: docsWebIcon(props['leading']),
    trailing: docsWebIcon(props['trailing']),
    onPressed: previewFlag(props, 'pressable') ? () {} : null,
    enabled: props['enabled'] == 'false' ? false : null,
    cardImageStyle: page.cardImagePreviewStyle(props),
    css: horizontal ? null : _fill,
  );
  return horizontal ? card : _box(page.cardImageWidth, card);
}

/// 카드가 둘레 상자의 폭을 채우게 하는 `css`.
final Styles _fill = Styles(raw: {'width': '100%'});

/// 폭을 정한 상자. 무대가 더 좁으면 무대 폭을 넘지 않는다.
Component _box(double width, Component child) => div(
  styles: Styles(raw: {'width': pinnedLengthCss(width), 'max-width': '100%'}),
  [child],
);

/// 폭을 채우고 비율을 지키는 그림.
Component _wide(page.CardImageSample sample, {double ratio = page.cardImageWideRatio}) =>
    AspectRatioBox(ratio: ratio, child: _art(sample));

/// 너비와 높이를 정한 정사각 그림.
Component _thumbnail(page.CardImageSample sample) => div(
  styles: Styles(
    raw: {
      'width': pinnedLengthCss(page.cardImageThumbnailSize),
      'height': pinnedLengthCss(page.cardImageThumbnailSize),
    },
  ),
  [_art(sample)],
);

/// 사진 자리의 그림 — 색 면 안에 테두리를 두르고 아이콘을 놓는다. 안쪽
/// 테두리가 있어 hover 확대가 눈에 보인다.
Component _art(page.CardImageSample sample, {Map<String, String>? attributes}) {
  final ink = CoreColor.token(sample.ink);
  return div(
    attributes: attributes,
    styles: Styles(
      raw: {
        'box-sizing': 'border-box',
        'width': '100%',
        'height': '100%',
        'padding': spaceCss(CoreSpace.space12),
        'background-color': CoreColor.token(sample.fill).toValue(),
      },
    ),
    [
      div(
        styles: Styles(
          raw: {
            'box-sizing': 'border-box',
            'display': 'flex',
            'align-items': 'center',
            'justify-content': 'center',
            'width': '100%',
            'height': '100%',
            'border': '${strokeWidthCss(CoreStrokeWidth.stroke2)} solid ${ink.toValue()}',
            'border-radius': const CoreBorderRadius.all(CoreRadius.radius12).toValue(),
          },
        ),
        [
          Icon(
            sample.icon,
            iconStyle: CoreIconStyle(size: CoreIconSize.size24, color: ink),
          ),
        ],
      ),
    ],
  );
}
