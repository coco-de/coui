/// DotIndicator 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="dot-indicator/...">` ·
/// `<Card demo>` · `<Anatomy>` 가 읽는다. 같은 이름의 Flutter
/// 파일(`dot_indicator_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'dot_indicator_page.dart';

/// 속성 → Component.
///
/// 점 표시는 선택을 기억하지 않으므로 빌더가 현재 번호를 기억한다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _DotIndicatorPreview(props: props);

/// 장면 이름(`dot-indicator/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 현재 점과 나머지 점을 가리키는 속성은 누를 수 있는 점 표시에만 붙는다.
  'dot-indicator/anatomy': () => DotIndicator(
    index: 0,
    length: 4,
    size: CoreDotIndicatorSize.lg,
    onChanged: (_) {},
  ),
  'dot-indicator/sizes': () => _captioned([
    for (final size in CoreDotIndicatorSize.values) (size.name, DotIndicator(index: 1, length: 4, size: size)),
  ]),
  'dot-indicator/directions': () => _captioned([
    for (final direction in CoreAxis.values) (direction.name, DotIndicator(index: 1, length: 4, direction: direction)),
  ]),
  'dot-indicator/active-shape': () => _captioned([
    for (final (name, style) in dotIndicatorShapeSamples)
      (name, DotIndicator(index: 1, length: 4, dotIndicatorStyle: style)),
  ]),
  'dot-indicator/states': () => _captioned([
    ('onChanged 있음', const _DotIndicatorPreview(props: {'length': '4', 'interactive': 'true'})),
    ('표시 전용', DotIndicator(index: 1, length: 4)),
  ]),
  'dot-indicator/do-few': () => DotIndicator(index: 1, length: 4),
  'dot-indicator/dont-many': () => DotIndicator(index: 7, length: 15),
  'dot-indicator/do-shape': () => DotIndicator(index: 1, length: 4, dotIndicatorStyle: dotIndicatorElongatedStyle),
  'dot-indicator/dont-tiny': () => DotIndicator(
    index: 1,
    length: 4,
    onChanged: (_) {},
    dotIndicatorStyle: dotIndicatorTinyStyle,
  ),
  'dot-indicator/related-carousel': () => div(styles: Styles(raw: {'width': '15rem'}), [
    Carousel(
      variant: CoreCarouselVariant.banner,
      items: [
        for (final (title, description) in dotIndicatorCarouselSlides)
          CarouselBanner(thumbnail: Icon(LucideIcons.image), title: Text(title), description: Text(description)),
      ],
    ),
  ]),
  'dot-indicator/related-pagination': () => Pagination(page: 2, totalPages: 3, onPageChanged: (_) {}),
  'dot-indicator/related-steps': () => div(styles: Styles(raw: {'width': '15rem'}), [
    const Steps(vertical: false, currentStep: 1, items: dotIndicatorStepSamples),
  ]),
  'dot-indicator/related-progress': () => div(styles: Styles(raw: {'width': '10rem'}), [
    const Progress(value: 0.6),
  ]),
};

/// 이름표를 단 점 표시들을 나란히 — Flutter 장면과 같은 모양.
Component _captioned(List<(String, Component)> items) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'align-items': 'center',
      'justify-content': 'center',
      'gap': 'var(--coui-space-16) var(--coui-space-32)',
    },
  ),
  [
    for (final (name, indicator) in items)
      div(classes: '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.itemsCenter}', [
        indicator,
        Text(name).labelSmall.onSurfaceVariant,
      ]),
  ],
);

/// 속성으로 그리는 점 표시 — 눌러 옮긴 번호를 기억한다.
///
/// 속성: `size` · `length` 는 위젯 속성 그대로, `index` 는 처음 고를 점,
/// `interactive` 는 `onChanged` 를 줄지, `elongated` 는 현재 점을 길게 할지.
class _DotIndicatorPreview extends StatefulComponent {
  const _DotIndicatorPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_DotIndicatorPreview> createState() => _DotIndicatorPreviewState();
}

class _DotIndicatorPreviewState extends State<_DotIndicatorPreview> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = dotIndicatorPreviewIndex(component.props);
  }

  @override
  void didUpdateComponent(covariant _DotIndicatorPreview oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.props['index'] != component.props['index']) {
      _index = dotIndicatorPreviewIndex(component.props);
    }
    _index = _index.clamp(0, dotIndicatorPreviewCount(component.props) - 1);
  }

  void _handleChanged(int next) => setState(() => _index = next);

  @override
  Component build(BuildContext context) {
    final props = component.props;
    return DotIndicator(
      index: _index,
      length: dotIndicatorPreviewCount(props),
      onChanged: previewFlag(props, 'interactive') ? _handleChanged : null,
      size: previewEnum(CoreDotIndicatorSize.values, props['size'], CoreDotIndicatorSize.defaultSize),
      dotIndicatorStyle: previewFlag(props, 'elongated') ? dotIndicatorElongatedStyle : null,
    );
  }
}
