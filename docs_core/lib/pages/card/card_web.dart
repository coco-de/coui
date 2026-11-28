/// Card 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="card/...">` 가 읽는다. 같은 이름의 Flutter 파일(`card_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'card_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _card;

/// 장면 이름(`card/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'card/anatomy': () => _sized(
    Card(
      variant: CoreCardVariant.outlined,
      cardStyle: _expand,
      media: _media(part: 'media'),
      overlay: _overlay(part: 'overlay'),
      header: _part('header', const Text(page.cardDemoHeader)),
      body: _part('body', const Text(page.cardDemoBody)),
      footer: _part('footer', const Text(page.cardDemoFooter).bodySmall.onSurfaceVariant),
    ),
  ),
  'card/media': () => _sized(
    Card(
      variant: CoreCardVariant.outlined,
      cardStyle: _expand,
      media: _media(),
      overlay: _overlay(),
      header: const Text(page.cardDemoHeader),
      body: const Text(page.cardDemoBody),
    ),
  ),
  'card/elevation': () => _sized(
    _stack([
      for (final elevation in CoreCardElevation.values)
        Card(
          variant: CoreCardVariant.outlined,
          cardStyle: CoreCardStyle(elevation: elevation, sizing: CoreCardSizing.expand),
          body: Text(elevation.name),
        ),
    ]),
  ),
  'card/sizing': () => _sized(
    _captionedStack([
      ('intrinsic', const Card(variant: CoreCardVariant.outlined, body: Text('내용 폭'))),
      (
        'expand',
        const Card(
          variant: CoreCardVariant.outlined,
          cardStyle: CoreCardStyle(sizing: CoreCardSizing.expand),
          body: Text('부모 폭'),
        ),
      ),
      (
        'fixed',
        const Card(
          variant: CoreCardVariant.outlined,
          cardStyle: CoreCardStyle(
            sizing: CoreCardSizing.fixed,
            width: CoreLayout.layout240,
            height: CoreSpace.space96,
          ),
          body: Text('240 × 96'),
        ),
      ),
    ]),
  ),
  'card/related-accordion': () => Accordion(
    items: [AccordionItem(title: '배송 안내', content: Text('2~3일 걸려요.'), expanded: true)],
  ),
  'card/related-badge': () => Badge(child: Text('NEW')),
};

Component _card(Map<String, String> props, String? label) {
  final variant = previewEnum(CoreCardVariant.values, props['variant'], CoreCardVariant.defaultVariant);
  final elevation = previewEnum(CoreCardElevation.values, props['elevation'], CoreCardStyle.defaultElevation);
  return Card(
    variant: variant,
    cardStyle: elevation == CoreCardStyle.defaultElevation ? null : CoreCardStyle(elevation: elevation),
    media: previewFlag(props, 'media') ? _media() : null,
    header: Text(label ?? page.cardDemoHeader),
    body: const Text(page.cardDemoBody),
    footer: previewFlag(props, 'footer') ? const Text(page.cardDemoFooter).bodySmall.onSurfaceVariant : null,
    onTap: previewFlag(props, 'onTap') ? () {} : null,
  );
}

const CoreCardStyle _expand = CoreCardStyle(sizing: CoreCardSizing.expand);

/// 미디어 자리 — 그림 파일 대신 색 면과 아이콘.
Component _media({String? part}) => div(
  attributes: part == null ? null : {'data-docs-part': part},
  styles: Styles(
    raw: {
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'height': spaceCss(CoreSpace.space96),
      'background-color': const CoreColor.token(CoreColors.surfaceContainerHigh).toValue(),
    },
  ),
  [Icon(LucideIcons.image)],
);

/// 미디어 위의 배지 — `overlay` 는 여백 없이 붙으므로 여백을 둔 상자로 감싼다.
/// 안쪽 상자는 배지 크기라, 구조 블록의 번호가 배지에 붙는다.
Component _overlay({String? part}) => div(
  styles: Styles(raw: {'padding': spaceCss(CoreSpace.space8)}),
  [
    div(
      attributes: part == null ? null : {'data-docs-part': part},
      styles: Styles(raw: {'width': 'fit-content'}),
      [Badge(variant: CoreBadgeVariant.filled, tone: CoreBadgeTone.primary, child: Text('NEW'))],
    ),
  ],
);

/// 구조 블록이 번호를 붙일 표지.
Component _part(String name, Component child) => div(attributes: {'data-docs-part': name}, [child]);

/// 장면의 카드 폭을 정한 상자.
Component _sized(Component child) => div(
  styles: Styles(raw: {'width': 'min(100%, ${pinnedLengthCss(page.cardDemoWidth)})'}),
  [child],
);

Component _stack(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'flex-start',
      'gap': spaceCss(CoreSpace.space16),
    },
  ),
  children,
);

/// 위에 이름을 단 조각을 세로로 쌓는다.
Component _captionedStack(List<(String, Component)> entries) => _stack([
  for (final (caption, child) in entries)
    div(
      styles: Styles(
        raw: {
          'display': 'flex',
          'flex-direction': 'column',
          'align-items': 'flex-start',
          'gap': spaceCss(CoreSpace.space8),
          'width': '100%',
        },
      ),
      [Text(caption).labelSmall.onSurfaceVariant, child],
    ),
]);
