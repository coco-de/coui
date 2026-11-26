/// Switcher 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="switcher/...">` ·
/// `<Card demo>` 가 읽는다. 같은 이름의 Web 파일(`switcher_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Web 과 같은 그림이 나오도록 모든 장면은 폭과 높이를 정한 창 안에 둔다.
/// 장면은 정지 그림이라 `Switcher` 의 끌기를 끈다 — `index` 를 고정한 채
/// 끌리면 아래 글자 · 컨트롤과 화면이 어긋난다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'switcher_page.dart';

/// 속성 → Widget.
///
/// 끌어서 넘기면 화면이 바뀌므로 빌더가 지금 번호를 기억하고 창 아래에 적는다
/// — Web 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _SwitcherPreview(props: props);

/// 장면 이름(`switcher/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
Widget _frame(Widget child, {double width = kSwitcherPreviewWidth, double height = kSwitcherPreviewHeight}) => SizedBox(
  width: width,
  height: height,
  child: OutlinedContainer(child: child),
);

/// 창을 채우고 내용을 가운데에 놓는 화면.
List<Widget> _views() => [
  for (final (name, caption) in kSwitcherPreviewViews)
    Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space4,
        children: [
          Text(name).titleMedium.onSurface,
          Text(caption).bodySmall.onSurfaceVariant,
        ],
      ),
    ),
];

/// 위에서 아래로 쌓는 묶음.
Widget _column(List<Widget> children) =>
    Column(mainAxisSize: MainAxisSize.min, spacing: CoreSpace.space8, children: children);

/// `index` 마다 보이는 화면.
Widget _indexScene() => docsFlutterDemoRow([
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
Widget _buttonsScene() => _column([
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
class _SwitcherPreview extends StatefulWidget {
  const _SwitcherPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_SwitcherPreview> createState() => _SwitcherPreviewState();
}

class _SwitcherPreviewState extends State<_SwitcherPreview> {
  late int _index = switcherPreviewIndex(widget.props);

  @override
  void didUpdateWidget(covariant _SwitcherPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 방향이나 끌기만 바뀌면 지금 화면을 그대로 둔다.
    if (oldWidget.props['index'] != widget.props['index']) {
      _index = switcherPreviewIndex(widget.props);
    }
  }

  void _handleIndexChanged(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
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
    ]);
  }
}
