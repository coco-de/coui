/// Switcher 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="switcher/...">` ·
/// `<Card demo>` 가 읽는다. 같은 이름의 Flutter 파일(`switcher_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 웹의 Switcher 는 부모 상자를 채우므로(`h-full w-full`), 모든 장면은 폭과
/// 높이를 정한 창 안에 둔다. 장면은 정지 그림이라 `Switcher` 의 끌기를 끈다
/// — `index` 를 고정한 채 끌리면 아래 글자 · 컨트롤과 화면이 어긋난다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'switcher_page.dart';

/// 속성 → Component.
///
/// 끌어서 넘기면 화면이 바뀌므로 빌더가 지금 번호를 기억하고 창 아래에 적는다.
/// 서버에서 그리는 블록에서는 처음 화면만 보이고, 브라우저에서 깨어나는
/// 플레이그라운드에서는 `index` 를 바꾸거나 끌어 넘길 수 있다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _SwitcherPreview(props: props);

/// 장면 이름(`switcher/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'switcher/index': _indexScene,
  'switcher/placement-sized': () => _frame(Switcher(gestureEnabled: false, items: _views())),
  'switcher/placement-buttons': _buttonsScene,
  'switcher/related-indexed-switcher': () => _frame(
    IndexedSwitcher(children: _views()),
    width: kSwitcherSampleWidth,
    height: kSwitcherSampleHeight,
  ),
  'switcher/related-swap': () => const Swap(onContent: Icon(LucideIcons.sun), offContent: Icon(LucideIcons.moon)),
};

/// 폭과 높이를 정한 테두리 창 — 창 밖은 잘린다.
Component _frame(Component child, {double width = kSwitcherPreviewWidth, double height = kSwitcherPreviewHeight}) =>
    OutlinedContainer(
      // 플레이그라운드의 '나란히' 칸처럼 자리가 창보다 좁으면 자리를 따른다 —
      // Flutter 의 SizedBox 도 부모의 최대 폭을 넘지 않는다.
      css: Styles(raw: {'width': switcherRem(width), 'max-width': '100%', 'height': switcherRem(height)}),
      child: child,
    );

/// 창을 채우고 내용을 가운데에 놓는 화면.
List<Component> _views() => [
  for (final (name, caption) in kSwitcherPreviewViews)
    div(
      styles: Styles(
        raw: {
          'display': 'flex',
          'flex-direction': 'column',
          'align-items': 'center',
          'justify-content': 'center',
          'gap': 'var(--coui-space-4)',
          'height': '100%',
        },
      ),
      [
        Text(name).titleMedium.onSurface,
        Text(caption).bodySmall.onSurfaceVariant,
      ],
    ),
];

/// 위에서 아래로 쌓는 묶음. [fill] 이면 자리의 폭을 채워 안의 창이 자리에
/// 맞춰 줄 수 있게 한다.
Component _column(List<Component> children, {bool fill = false}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': 'var(--coui-space-8)',
      if (fill) ...{'width': '100%', 'min-width': '0'},
    },
  ),
  children,
);

/// `index` 마다 보이는 화면.
Component _indexScene() => docsWebDemoRow([
  for (var index = 0; index < kSwitcherPreviewViews.length; index++)
    _column([
      _frame(
        Switcher(index: index, gestureEnabled: false, items: _views()),
        width: kSwitcherSampleWidth,
        height: kSwitcherSampleHeight,
      ),
      Text('index: $index').codeSm.onSurfaceVariant,
    ]),
]);

/// 창 아래의 선택 컨트롤로 `index` 를 정하는 배치.
Component _buttonsScene() => _column([
  _frame(Switcher(index: 1, gestureEnabled: false, items: _views())),
  ToggleGroup<int>(
    size: CoreComponentSize.sm,
    value: 1,
    onChanged: (_) {},
    items: [
      for (final (index, (name, _)) in kSwitcherPreviewViews.indexed) CoreToggleGroupItem(value: index, label: name),
    ],
  ),
]);

/// 속성으로 그리는 Switcher — 끌어서 바뀐 번호를 기억한다.
class _SwitcherPreview extends StatefulComponent {
  const _SwitcherPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_SwitcherPreview> createState() => _SwitcherPreviewState();
}

class _SwitcherPreviewState extends State<_SwitcherPreview> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = switcherPreviewIndex(component.props);
  }

  @override
  void didUpdateComponent(covariant _SwitcherPreview oldComponent) {
    super.didUpdateComponent(oldComponent);
    // 방향이나 끌기만 바뀌면 지금 화면을 그대로 둔다.
    if (oldComponent.props['index'] != component.props['index']) {
      _index = switcherPreviewIndex(component.props);
    }
  }

  void _handleIndexChanged(int index) => setState(() => _index = index);

  @override
  Component build(BuildContext context) {
    final props = component.props;
    return _column([
      _frame(
        Switcher(
          index: _index,
          direction: switcherPreviewDirection(props),
          gestureEnabled: switcherPreviewGestureEnabled(props),
          onIndexChanged: _handleIndexChanged,
          items: _views(),
        ),
      ),
      Text('index: $_index').codeSm.onSurfaceVariant,
    ], fill: true);
  }
}
