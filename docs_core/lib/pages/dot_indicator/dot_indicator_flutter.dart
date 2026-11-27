/// DotIndicator 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="dot-indicator/...">` ·
/// `<Card demo>` · `<Anatomy>` 가 읽는다. 같은 이름의 Web
/// 파일(`dot_indicator_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'dot_indicator_page.dart';

/// 속성 → Widget.
///
/// 점 표시는 선택을 기억하지 않으므로 빌더가 현재 번호를 기억한다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _DotIndicatorPreview(props: props);

/// 장면 이름(`dot-indicator/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
  'dot-indicator/states': () => _captioned(const [
    ('onChanged 있음', _DotIndicatorPreview(props: {'length': '4', 'interactive': 'true'})),
    ('표시 전용', DotIndicator(index: 1, length: 4)),
  ]),
  'dot-indicator/do-few': () => const DotIndicator(index: 1, length: 4),
  'dot-indicator/dont-many': () => const DotIndicator(index: 7, length: 15),
  'dot-indicator/do-shape': () => const DotIndicator(
    index: 1,
    length: 4,
    dotIndicatorStyle: dotIndicatorElongatedStyle,
  ),
  'dot-indicator/dont-tiny': () => DotIndicator(
    index: 1,
    length: 4,
    onChanged: (_) {},
    dotIndicatorStyle: dotIndicatorTinyStyle,
  ),
  'dot-indicator/related-carousel': () => SizedBox(
    width: CoreLayout.layout240,
    child: Carousel(
      transition: const CoreCarouselTransition.sliding(),
      variant: CoreCarouselVariant.banner,
      items: [
        for (final (title, description) in dotIndicatorCarouselSlides)
          CarouselBanner(thumbnail: const Icon(LucideIcons.image), title: Text(title), description: Text(description)),
      ],
    ),
  ),
  'dot-indicator/related-pagination': () => Pagination(page: 2, totalPages: 3, onPageChanged: (_) {}),
  'dot-indicator/related-steps': () => const SizedBox(
    width: CoreLayout.layout240,
    child: Steps(vertical: false, currentStep: 1, items: dotIndicatorStepSamples),
  ),
  'dot-indicator/related-progress': () => const SizedBox(width: CoreSpace.space160, child: Progress(value: 0.6)),
};

/// 이름표를 단 점 표시들을 나란히 — Web 장면과 같은 모양.
Widget _captioned(List<(String, Widget)> items) => Wrap(
  alignment: WrapAlignment.center,
  crossAxisAlignment: WrapCrossAlignment.center,
  spacing: CoreSpace.space32,
  runSpacing: CoreSpace.space16,
  children: [
    for (final (name, indicator) in items)
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [indicator, Text(name).labelSmall.onSurfaceVariant],
      ),
  ],
);

/// 속성으로 그리는 점 표시 — 눌러 옮긴 번호를 기억한다.
///
/// 속성: `size` · `length` 는 위젯 속성 그대로, `index` 는 처음 고를 점,
/// `interactive` 는 `onChanged` 를 줄지, `elongated` 는 현재 점을 길게 할지.
class _DotIndicatorPreview extends StatefulWidget {
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
    _index = dotIndicatorPreviewIndex(widget.props);
  }

  @override
  void didUpdateWidget(covariant _DotIndicatorPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.props['index'] != widget.props['index']) {
      _index = dotIndicatorPreviewIndex(widget.props);
    }
    _index = _index.clamp(0, dotIndicatorPreviewCount(widget.props) - 1);
  }

  void _handleChanged(int next) => setState(() => _index = next);

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    return DotIndicator(
      index: _index,
      length: dotIndicatorPreviewCount(props),
      onChanged: previewFlag(props, 'interactive') ? _handleChanged : null,
      size: previewEnum(CoreDotIndicatorSize.values, props['size'], CoreDotIndicatorSize.defaultSize),
      dotIndicatorStyle: previewFlag(props, 'elongated') ? dotIndicatorElongatedStyle : null,
    );
  }
}
