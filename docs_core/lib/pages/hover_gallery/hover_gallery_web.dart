/// HoverGallery 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="hover-gallery/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`hover_gallery_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 장면은 그림을 내려받지 않고 색 토큰으로 칠한 면을 항목으로 쓴다.
///
/// Web 갤러리의 레이어는 모두 절대 위치라 갤러리에는 내용에서 나오는 폭이
/// 없다. 그래서 갤러리는 늘 폭을 정한 틀([_frame]) 안에 둔다. 갤러리는
/// 포인터가 닿은 요소를 기준으로 가로 위치를 읽으므로, 항목([_item])은
/// `pointer-events: none` 으로 두어 안의 글자가 포인터를 받지 않게 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'hover_gallery_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _hoverGallery;

/// 장면 이름(`hover-gallery/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'hover-gallery/anatomy': () => _frame(_gallery(3, height: CoreSpace.space160, marked: true), width: '15rem'),
  'hover-gallery/zones': () => _zones(4),
  'hover-gallery/do-few-items': () => _zones(3, width: '15rem'),
  'hover-gallery/dont-many-items': () => _zones(12, width: '15rem'),
  'hover-gallery/in-card': () => Card(
    media: _frame(
      _gallery(3, height: CoreSpace.space160, borderRadius: CoreBorderRadius.zero),
      width: '15rem',
    ),
    body: Text('상품 이름').bodyMedium,
  ),
  'hover-gallery/related-carousel': () => _frame(
    Carousel(items: [for (var index = 0; index < 3; index++) _item(index, 3, height: '7rem')]),
    width: '15rem',
  ),
  'hover-gallery/related-card-image': () => CardImage(
    image: div(
      styles: Styles(
        raw: {
          'width': '10rem',
          'height': '5.5rem',
          'background-color': const CoreColor.token(CoreColors.primaryContainer).toValue(),
        },
      ),
      [],
    ),
    title: Text('상품 이름'),
  ),
  'hover-gallery/related-card': () => Card(header: Text('상품 이름'), body: Text('설명 한 줄')),
  'hover-gallery/related-dot-indicator': () => DotIndicator(index: 1, length: 4),
};

Component _hoverGallery(Map<String, String> props, String? label) {
  final count = hoverGalleryPreviewCount(props);
  return _frame(
    HoverGallery(
      // 항목 수가 바뀌면 처음 상태로 다시 만든다 — 갤러리는 보고 있던 번호를
      // 그대로 들고 있어, 수가 줄면 보일 항목이 없어진다.
      key: ValueKey('hover-gallery-$count'),
      itemCount: count,
      itemBuilder: (index) => _item(index, count),
      hoverGalleryStyle: CoreHoverGalleryStyle(
        height: hoverGalleryPreviewHeight(props),
        borderRadius: CoreBorderRadius.all(hoverGalleryPreviewRadius(props)),
      ),
    ),
  );
}

/// 폭을 정한 틀 — Flutter 장면의 `SizedBox(width: …)` 자리다. 좁은 무대에서는
/// 줄어든다.
Component _frame(Component child, {String width = '20rem'}) => div(
  styles: Styles(raw: {'width': width, 'max-width': '100%', 'min-width': '0'}),
  [child],
);

/// 색 면 항목 [count]개를 가진 갤러리. [marked] 면 구조 번호가 찾을 표지를
/// 항목에 단다.
Component _gallery(int count, {required double height, CoreBorderRadius? borderRadius, bool marked = false}) =>
    HoverGallery(
      itemCount: count,
      itemBuilder: (index) => _item(index, count, marked: marked),
      hoverGalleryStyle: CoreHoverGalleryStyle(height: height, borderRadius: borderRadius),
    );

/// 색 토큰으로 칠한 항목 하나.
Component _item(int index, int count, {String height = '100%', bool marked = false}) {
  final text = Text(hoverGalleryItemLabel(index, count)).titleLarge;
  final fill = switch (index % 3) {
    0 => CoreColors.surfaceContainerHighest,
    1 => CoreColors.surfaceContainerHigh,
    _ => CoreColors.surfaceContainer,
  };
  final label = text.onSurface;
  return div(
    attributes: marked ? const {'data-docs-part': 'hover-gallery-item'} : null,
    styles: Styles(
      raw: {
        'display': 'flex',
        'align-items': 'center',
        'justify-content': 'center',
        'width': '100%',
        'height': height,
        'pointer-events': 'none',
        'background-color': CoreColor.token(fill).toValue(),
      },
    ),
    [label],
  );
}

/// 갤러리와 그 아래의 가로 구간 — 폭을 항목 수만큼 똑같이 나눈 칸이다.
Component _zones(int count, {String width = '20rem'}) => _frame(
  div(
    styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': 'var(--coui-space-8)'}),
    [
      _gallery(count, height: CoreSpace.space120),
      div(
        styles: Styles(raw: {'display': 'flex'}),
        [
          for (var index = 0; index < count; index++)
            div(
              styles: Styles(
                raw: {
                  'flex': '1 1 0',
                  'min-width': '0',
                  'text-align': 'center',
                  'box-shadow': 'inset 0 0 0 1px ${const CoreColor.token(CoreColors.outlineVariant).toValue()}',
                },
              ),
              [Text('${index + 1}').labelSmall.onSurfaceVariant],
            ),
        ],
      ),
    ],
  ),
  width: width,
);
