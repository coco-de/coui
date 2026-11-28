/// Card 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="card/...">` 가 읽는다. 같은 이름의 Web 파일(`card_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'card_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _card;

/// 장면 이름(`card/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'card/anatomy': () => _sized(
    Card(
      variant: CoreCardVariant.outlined,
      cardStyle: _expand,
      media: _media(),
      overlay: _overlay(),
      header: const Text(page.cardDemoHeader),
      body: const Text(page.cardDemoBody),
      footer: const Text(page.cardDemoFooter).bodySmall.onSurfaceVariant,
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
  'card/related-accordion': () => const SizedBox(
    width: 180,
    child: Accordion(
      items: [AccordionItem(title: '배송 안내', content: Text('2~3일 걸려요.'), expanded: true)],
    ),
  ),
  'card/related-badge': () => const Badge(child: Text('NEW')),
};

Widget _card(Map<String, String> props, String? label) {
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
Widget _media() => Builder(
  builder: (context) => ColoredBox(
    color: Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.surfaceContainerHigh)).toValue(),
    child: const SizedBox(
      height: CoreSpace.space96,
      child: Center(child: Icon(LucideIcons.image)),
    ),
  ),
);

/// 미디어 위의 배지 — `overlay` 는 여백 없이 붙으므로 여백을 둔 상자로 감싼다.
Widget _overlay() => const Padding(
  padding: EdgeInsets.all(CoreSpace.space8),
  child: Badge(variant: CoreBadgeVariant.filled, tone: CoreBadgeTone.primary, child: Text('NEW')),
);

/// 장면의 카드 폭을 정한 상자.
Widget _sized(Widget child) => SizedBox(width: page.cardDemoWidth, child: child);

Widget _stack(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space16,
  children: children,
);

/// 위에 이름을 단 조각을 세로로 쌓는다.
Widget _captionedStack(List<(String, Widget)> entries) => _stack([
  for (final (caption, child) in entries)
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CoreSpace.space8,
      children: [Text(caption).labelSmall.onSurfaceVariant, child],
    ),
]);
