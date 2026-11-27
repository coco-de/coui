/// HoverGallery 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="hover-gallery/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`hover_gallery_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 장면은 그림을 내려받지 않고 색 토큰으로 칠한 면을 항목으로 쓴다. 갤러리는
/// 놓인 폭을 읽어 구간을 나누므로 장면마다 폭을 정한다. 높이는 갤러리의
/// 스타일이 정해, 높이가 정해지지 않은 스크롤 안에서도 같은 크기로 그려진다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'hover_gallery_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _hoverGallery;

/// 장면 이름(`hover-gallery/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'hover-gallery/anatomy': () => _frame(_gallery(3, height: CoreSpace.space160), width: CoreLayout.layout240),
  'hover-gallery/zones': () => _zones(4),
  'hover-gallery/do-few-items': () => _zones(3, width: CoreLayout.layout240),
  'hover-gallery/dont-many-items': () => _zones(12, width: CoreLayout.layout240),
  'hover-gallery/in-card': () => _frame(
    Card(
      media: _gallery(3, height: CoreSpace.space160, borderRadius: CoreBorderRadius.zero),
      body: Text('상품 이름').bodyMedium,
    ),
    width: CoreLayout.layout240,
  ),
  'hover-gallery/related-carousel': () => _frame(
    Carousel(
      transition: const CarouselTransition.sliding(),
      items: [
        for (var index = 0; index < 3; index++)
          SizedBox(width: double.infinity, height: CoreSpace.space112, child: _Item(index, 3)),
      ],
    ),
    width: CoreLayout.layout240,
  ),
  'hover-gallery/related-card-image': () => _frame(
    const CardImage(
      image: SizedBox(width: double.infinity, height: CoreSpace.space88, child: _Fill()),
      title: Text('상품 이름'),
    ),
    width: CoreLayout.layout160,
  ),
  'hover-gallery/related-card': () => const Card(header: Text('상품 이름'), body: Text('설명 한 줄')),
  'hover-gallery/related-dot-indicator': () => const DotIndicator(index: 1, length: 4),
};

Widget _hoverGallery(Map<String, String> props, String? label) {
  final count = hoverGalleryPreviewCount(props);
  return _frame(
    HoverGallery(
      // 항목 수가 바뀌면 처음 상태로 다시 만든다 — 갤러리는 보고 있던 번호를
      // 그대로 들고 있어, 수가 줄면 번호가 범위를 벗어난다.
      key: ValueKey('hover-gallery-$count'),
      itemCount: count,
      itemBuilder: (index) => _Item(index, count),
      hoverGalleryStyle: CoreHoverGalleryStyle(
        height: hoverGalleryPreviewHeight(props),
        borderRadius: CoreBorderRadius.all(hoverGalleryPreviewRadius(props)),
      ),
    ),
  );
}

/// 장면의 틀 — Web 장면의 폭과 맞춘다. 좁은 무대에서는 줄어든다.
Widget _frame(Widget child, {double width = CoreLayout.layout320}) => SizedBox(width: width, child: child);

/// 색 면 항목 [count]개를 가진 갤러리.
Widget _gallery(int count, {required double height, CoreBorderRadius? borderRadius}) => HoverGallery(
  itemCount: count,
  itemBuilder: (index) => _Item(index, count),
  hoverGalleryStyle: CoreHoverGalleryStyle(height: height, borderRadius: borderRadius),
);

/// 갤러리와 그 아래의 가로 구간 — 폭을 항목 수만큼 똑같이 나눈 칸이다.
Widget _zones(int count, {double width = CoreLayout.layout320}) => _frame(
  Column(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space8,
    children: [
      _gallery(count, height: CoreSpace.space120),
      Row(children: [for (var index = 0; index < count; index++) Expanded(child: _ZoneCell(index))]),
    ],
  ),
  width: width,
);

/// 색 토큰으로 칠한 항목 하나. 갤러리가 항목을 자기 크기로 채운다.
class _Item extends StatelessWidget {
  const _Item(this.index, this.count);

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = Text(hoverGalleryItemLabel(index, count)).titleLarge;
    final fill = switch (index % 3) {
      0 => CoreColors.surfaceContainerHighest,
      1 => CoreColors.surfaceContainerHigh,
      _ => CoreColors.surfaceContainer,
    };
    final label = text.onSurface;
    return ColoredBox(
      color: Theme.of(context).colorScheme.resolve(CoreColor.token(fill)).toValue(),
      child: Center(child: label),
    );
  }
}

/// 글자 없이 색만 칠한 면.
class _Fill extends StatelessWidget {
  const _Fill();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.primaryContainer)).toValue(),
  );
}

/// 가로 구간 한 칸.
class _ZoneCell extends StatelessWidget {
  const _ZoneCell(this.index);

  final int index;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.outlineVariant)).toValue(),
      ),
    ),
    // `heightFactor` 가 없으면 높이가 정해진 부모에서 칸이 그 높이를 다 쓴다.
    child: Center(heightFactor: 1, child: Text('${index + 1}').labelSmall.onSurfaceVariant),
  );
}
