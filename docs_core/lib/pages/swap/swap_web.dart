/// Swap 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="swap/...">` · `<Card demo>` 가 읽는다. 같은 이름의 Flutter
/// 파일(`swap_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'swap_page.dart';

/// 속성 → Component.
///
/// Swap 은 `checked` 를 스스로 바꾸지 않으므로 빌더가 기억한다. 서버에서 그리는
/// 블록은 처음 모습만 보이고, 브라우저에서 깨어나는 플레이그라운드에서는 눌러
/// 바꿀 수 있다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _SwapPreview(props: props);

/// 장면 이름(`swap/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'swap/faces': () => docsWebDemoRow([
    for (final checked in [false, true])
      _captioned(
        'checked: $checked',
        Swap(checked: checked, offContent: Text('offContent'), onContent: Text('onContent')),
      ),
  ]),
  'swap/sizing': () => _flex(vertical: true, gap: CoreSpace.space12, [
    for (final animation in swapSizingAnimations)
      _captioned(
        'animation: ${animation.name}',
        _flex(gap: CoreSpace.space4, [
          Text('[').onSurfaceVariant,
          Swap(
            animation: animation,
            offContent: Text(swapSizingOffText),
            onContent: Text(swapSizingOnText),
          ),
          Text(']').onSurfaceVariant,
        ]),
      ),
  ]),
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
  'swap/related-switch-field': () => div(styles: Styles(raw: {'width': pinnedLengthCss(240)}), [
    SwitchField(label: '알림 받기', description: '새 댓글이 달리면 알려 드려요.', value: true, onChanged: (_) {}),
  ]),
  'swap/related-collapsible': () => div(styles: Styles(raw: {'width': pinnedLengthCss(192)}), [
    Collapsible(
      trigger: Text('고급 설정'),
      content: Text('접었다 펴는 내용'),
      expanded: true,
      onExpandedChanged: (_) {},
    ),
  ]),
  'swap/related-switcher': () => OutlinedContainer(
    css: Styles(raw: {'width': pinnedLengthCss(192), 'max-width': '100%', 'height': pinnedLengthCss(72)}),
    child: Switcher(
      gestureEnabled: false,
      items: [
        for (final name in ['첫째 뷰', '둘째 뷰', '셋째 뷰']) _flex(fill: true, [Text(name).bodyMedium.onSurface]),
      ],
    ),
  ),
};

/// 가운데에 맞추는 flex 상자. [gap] 은 logical px, [fill] 은 부모 상자를 채운다.
Component _flex(List<Component> children, {bool vertical = false, bool fill = false, double? gap}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': vertical ? 'column' : 'row',
      'align-items': 'center',
      'justify-content': 'center',
      if (gap != null) 'gap': pinnedLengthCss(gap),
      if (fill) ...{'width': '100%', 'height': '100%'},
    },
  ),
  children,
);

/// 위에 이름을 단 장면 조각.
Component _captioned(String caption, Component child) =>
    _flex(vertical: true, gap: CoreSpace.space8, [Text(caption).codeSm.onSurfaceVariant, child]);

/// 속성으로 그리는 Swap — 눌러서 바뀐 `checked` 를 기억한다.
class _SwapPreview extends StatefulComponent {
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
    _checked = swapPreviewChecked(component.props);
  }

  @override
  void didUpdateComponent(covariant _SwapPreview oldComponent) {
    super.didUpdateComponent(oldComponent);
    final next = swapPreviewChecked(component.props);
    if (swapPreviewChecked(oldComponent.props) != next) _checked = next;
  }

  @override
  Component build(BuildContext context) {
    final props = component.props;
    final interactive = swapPreviewInteractive(props);
    final text = swapPreviewTextFace(props);
    return Swap(
      checked: interactive ? _checked : swapPreviewChecked(props),
      animation: swapPreviewAnimation(props),
      offContent: text ? Text(swapPreviewOffText) : const Icon(LucideIcons.menu),
      onContent: text ? Text(swapPreviewOnText) : const Icon(LucideIcons.x),
      onToggle: interactive ? (value) => setState(() => _checked = value) : null,
      attributes: swapPreviewNeedsName(props) ? const {'aria-label': swapPreviewName} : null,
    );
  }
}
