/// Swap 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="swap/...">` · `<Card demo>` 가 읽는다. 같은 이름의 Web
/// 파일(`swap_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'swap_page.dart';

/// 속성 → Widget.
///
/// Swap 은 `checked` 를 스스로 바꾸지 않으므로 빌더가 기억한다 — Web 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _SwapPreview(props: props);

/// 장면 이름(`swap/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'swap/faces': () => docsFlutterDemoRow([
    for (final checked in [false, true])
      _captioned(
        'checked: $checked',
        Swap(checked: checked, offContent: Text('offContent'), onContent: Text('onContent')),
      ),
  ]),
  'swap/sizing': () => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space12,
    children: [
      for (final animation in swapSizingAnimations)
        _captioned(
          'animation: ${animation.name}',
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: CoreSpace.space4,
            children: [
              Text('[').onSurfaceVariant,
              Swap(
                animation: animation,
                offContent: Text(swapSizingOffText),
                onContent: Text(swapSizingOnText),
              ),
              Text(']').onSurfaceVariant,
            ],
          ),
        ),
    ],
  ),
  'swap/do-symmetric-rotate': () => const Swap(
    checked: true,
    animation: CoreSwapAnimation.rotate,
    offContent: Icon(LucideIcons.menu),
    onContent: Icon(LucideIcons.x),
  ),
  'swap/dont-rotate-text': () => Swap(
    checked: true,
    animation: CoreSwapAnimation.rotate,
    offContent: Text('재생'),
    onContent: Text('일시정지'),
  ),
  'swap/do-setting-toggle': () => Toggle(value: true, onChanged: (_) {}, label: '알림 받기'),
  'swap/dont-setting-swap': () =>
      Swap(checked: true, offContent: Text('알림 꺼짐'), onContent: Text('알림 켜짐'), onToggle: (_) {}),
  'swap/related-toggle': () => Toggle(value: true, onChanged: (_) {}, label: '알림 받기'),
  'swap/related-switch-field': () => SizedBox(
    width: 240,
    child: SwitchField(label: '알림 받기', description: '새 댓글이 달리면 알려 드려요.', value: true, onChanged: (_) {}),
  ),
  'swap/related-collapsible': () => SizedBox(
    width: 192,
    child: Collapsible(
      trigger: Text('고급 설정'),
      content: Text('접었다 펴는 내용'),
      expanded: true,
      onExpandedChanged: (_) {},
    ),
  ),
  'swap/related-switcher': () => SizedBox(
    width: 192,
    height: 72,
    child: OutlinedContainer(
      child: Switcher(
        gestureEnabled: false,
        items: [
          for (final name in ['첫째 뷰', '둘째 뷰', '셋째 뷰']) Center(child: Text(name).bodyMedium.onSurface),
        ],
      ),
    ),
  ),
};

/// 위에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space8,
  children: [Text(caption).codeSm.onSurfaceVariant, child],
);

/// 속성으로 그리는 Swap — 눌러서 바뀐 `checked` 를 기억한다.
class _SwapPreview extends StatefulWidget {
  const _SwapPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_SwapPreview> createState() => _SwapPreviewState();
}

class _SwapPreviewState extends State<_SwapPreview> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checked = swapPreviewChecked(widget.props);
  }

  @override
  void didUpdateWidget(covariant _SwapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = swapPreviewChecked(widget.props);
    if (swapPreviewChecked(oldWidget.props) != next) _checked = next;
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final interactive = swapPreviewInteractive(props);
    final text = swapPreviewTextFace(props);
    final swap = Swap(
      checked: interactive ? _checked : swapPreviewChecked(props),
      animation: swapPreviewAnimation(props),
      offContent: text ? Text(swapPreviewOffText) : const Icon(LucideIcons.menu),
      onContent: text ? Text(swapPreviewOnText) : const Icon(LucideIcons.x),
      onToggle: interactive ? (value) => setState(() => _checked = value) : null,
    );
    if (!swapPreviewNeedsName(props)) return swap;
    // 누를 수 있는 Swap 은 시맨틱 노드가 둘이라, 이름과 동작을 `MergeSemantics` 로 합친다.
    return MergeSemantics(
      child: Semantics(label: swapPreviewName, child: swap),
    );
  }
}
