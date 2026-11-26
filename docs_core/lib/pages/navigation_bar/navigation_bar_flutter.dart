/// NavigationBar 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="navigation-bar/...">` 와 카드가 읽는다. 같은 이름의 Web 파일
/// (`navigation_bar_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'navigation_bar_page.dart';

/// 속성 → Widget.
///
/// 선택은 눌러야 바뀌므로 빌더가 고른 번호를 기억한다 — Web 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _NavigationBarPreview(props: props);

/// 장면 이름(`navigation-bar/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'navigation-bar/anatomy': _anatomy,
  'navigation-bar/states': _states,
  'navigation-bar/badge-footer': _badgeFooter,
  'navigation-bar/text-tabs': () => _framed(320, _textTabs()),
  'navigation-bar/glass': () => _row([
    _framed(288, _glassBar()),
    NavigationBar(
      mode: CoreNavigationBarMode.rail,
      selectedIndex: 0,
      onSelected: (_) {},
      navigationBarStyle: navigationBarPreviewGlassStyle,
      items: _destinations(),
    ),
  ]),
  'navigation-bar/compact': () => _row([
    for (final compact in const [CoreNavigationCompact.never, CoreNavigationCompact.always])
      _labelled(compact.name, _framed(288, _glassBar(compact: compact))),
  ]),
  'navigation-bar/do-short': () => _framed(
    272,
    NavigationBar(selectedIndex: 0, onSelected: (_) {}, items: _destinations()),
  ),
  'navigation-bar/dont-long': () => _framed(
    272,
    NavigationBar(
      selectedIndex: 0,
      onSelected: (_) {},
      items: [
        for (final (text, glyph) in navigationBarLongItems)
          CoreNavigationBarItem.destination(icon: Icon(glyph), label: text),
      ],
    ),
  ),
  'navigation-bar/placement-bottom': () => _screenFrame(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _screenBody()),
        NavigationBar(selectedIndex: 0, onSelected: (_) {}, items: _destinations()),
      ],
    ),
  ),
  // Web 과 같은 `alignment` 를 준다 — Web 의 늘어난 레일은 `start` 여야 위에 모인다.
  'navigation-bar/placement-rail': () => _screenFrame(
    Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NavigationBar(
          mode: CoreNavigationBarMode.rail,
          alignment: CoreNavigationAlignment.start,
          selectedIndex: 0,
          onSelected: (_) {},
          items: _destinations(),
        ),
        Expanded(child: _screenBody()),
      ],
    ),
  ),
  'navigation-bar/related-item': () => SizedBox(
    width: CoreSize.size96,
    child: NavigationBarItem(
      mode: CoreNavigationBarMode.rail,
      icon: Icon(LucideIcons.inbox),
      label: navigationBarPreviewItems[1].$1,
      selected: true,
      onPressed: () {},
    ),
  ),
};

CoreNavigationBarItem<Widget> _destination(
  int index, {
  bool icon = true,
  Widget? badge,
  bool showDot = false,
  bool enabled = true,
}) {
  final (text, glyph, _) = navigationBarPreviewItems[index];
  return CoreNavigationBarItem.destination(
    icon: icon ? Icon(glyph) : null,
    label: text,
    badge: badge,
    showDot: showDot,
    enabled: enabled,
  );
}

List<CoreNavigationBarItem<Widget>> _destinations() => [
  for (var index = 0; index < navigationBarPreviewItems.length; index++) _destination(index),
];

Widget _countBadge([String count = navigationBarPreviewCount]) => Badge(
  form: CoreBadgeForm.count,
  tone: CoreBadgeTone.info,
  variant: CoreBadgeVariant.filled,
  size: CoreComponentSize.xs,
  child: Text(count),
);

/// 폭을 정한 자리 — 가로 바는 부모의 폭을 채운다. 무대가 좁으면 무대 폭을 따른다.
Widget _framed(double width, Widget child) => ConstrainedBox(
  constraints: BoxConstraints(maxWidth: width),
  child: SizedBox(width: double.infinity, child: child),
);

/// 장면 여러 개를 가운데로 모아 나란히 놓는다. 좁으면 줄을 바꾼다.
Widget _row(
  List<Widget> children, {
  WrapCrossAlignment align = WrapCrossAlignment.center,
  double gap = CoreSpace.space24,
}) => Wrap(
  alignment: WrapAlignment.center,
  crossAxisAlignment: align,
  spacing: gap,
  runSpacing: gap,
  children: children,
);

Widget _column(List<Widget> children, {double gap = CoreSpace.space8}) =>
    Column(mainAxisSize: MainAxisSize.min, spacing: gap, children: children);

Widget _labelled(String name, Widget child) => _column([Text(name).labelSmall.onSurfaceVariant, child]);

Widget _anatomy() => _framed(
  416,
  NavigationBar(
    selectedIndex: 0,
    onSelected: (_) {},
    header: Icon(LucideIcons.atom),
    footer: Text(navigationBarPreviewFooter).labelSmall.onSurfaceVariant,
    items: [
      _destination(0),
      _destination(1, badge: _countBadge()),
      _destination(2),
    ],
  ),
);

Widget _stateNavigation(List<(String, IconName, bool)> rows, CoreNavigationBarMode mode) => NavigationBar(
  mode: mode,
  selectedIndex: 0,
  onSelected: (_) {},
  items: [
    for (final (text, glyph, enabled) in rows)
      CoreNavigationBarItem.destination(icon: Icon(glyph), label: text, enabled: enabled),
  ],
);

/// 상태 장면 — Web 과 같은 두 묶음.
Widget _states() => _row(align: WrapCrossAlignment.start, gap: CoreSpace.space32, [
  _labelled(
    'fill · 레일',
    _row(align: WrapCrossAlignment.start, gap: CoreSpace.space16, [
      _stateNavigation(navigationBarStateItems, CoreNavigationBarMode.rail),
      _stateNavigation(navigationBarDisabledSelectedItems, CoreNavigationBarMode.rail),
    ]),
  ),
  _labelled(
    'color · 바',
    _column(gap: CoreSpace.space12, [
      _framed(navigationBarStateBarWidth, _stateNavigation(navigationBarStateItems, CoreNavigationBarMode.bar)),
      _framed(
        navigationBarStateBarWidth,
        _stateNavigation(navigationBarDisabledSelectedItems, CoreNavigationBarMode.bar),
      ),
    ]),
  ),
]);

/// 높이를 정한 자리의 레일 — `header` 는 위 끝, `footer` 는 아래 끝에 선다.
Widget _badgeFooter() => SizedBox(
  height: navigationBarFooterSceneHeight,
  child: NavigationBar(
    mode: CoreNavigationBarMode.rail,
    alignment: CoreNavigationAlignment.start,
    selectedIndex: 0,
    onSelected: (_) {},
    header: Icon(LucideIcons.atom),
    footer: Text(navigationBarPreviewFooter).labelSmall.onSurfaceVariant,
    items: [
      _destination(0),
      _destination(1, badge: _countBadge()),
      _destination(2, showDot: true),
    ],
  ),
);

Widget _textTabs() => NavigationBar(
  selectedIndex: 0,
  onSelected: (_) {},
  selectionMark: CoreNavigationSelectionMark.dot,
  labelMode: CoreNavigationLabelMode.all,
  items: [for (final text in navigationBarTextTabLabels) CoreNavigationBarItem.destination(label: text)],
);

Widget _glassBar({CoreNavigationCompact compact = CoreNavigationCompact.never}) => NavigationBar(
  selectedIndex: 0,
  onSelected: (_) {},
  compact: compact,
  navigationBarStyle: navigationBarPreviewGlassStyle,
  items: _destinations(),
);

/// 배치 장면의 화면 틀.
Widget _screenFrame(Widget child) => Builder(
  builder: (context) {
    final radius = BorderRadius.circular(CoreRadiusRole.panel);
    final line = Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.outlineVariant)).toValue();
    return _framed(
      navigationBarPlacementWidth,
      SizedBox(
        height: navigationBarPlacementHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: line),
            borderRadius: radius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(CoreStrokeWidth.stroke1),
            child: ClipRRect(borderRadius: radius, child: child),
          ),
        ),
      ),
    );
  },
);

Widget _screenBody() => Center(child: Text('화면 내용').bodySmall.onSurfaceVariant);

/// 속성으로 그리는 내비게이션 바 — 눌러 고른 목적지를 기억한다. 속성은 Web 과 같다.
class _NavigationBarPreview extends StatefulWidget {
  const _NavigationBarPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_NavigationBarPreview> createState() => _NavigationBarPreviewState();
}

class _NavigationBarPreviewState extends State<_NavigationBarPreview> {
  int _selected = 0;

  void _handleSelected(int next) => setState(() => _selected = next);

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final mode = navigationBarPreviewMode(props);
    final icons = previewFlag(props, 'icons', fallback: true);
    final count = props['badge'];
    final disabled = int.tryParse(props['disabled'] ?? '');
    final navigation = NavigationBar(
      mode: mode,
      selectedIndex: _selected,
      onSelected: _handleSelected,
      labelMode: navigationBarPreviewLabelMode(props),
      indicator: navigationBarPreviewIndicator(props),
      selectionMark: navigationBarPreviewSelectionMark(props),
      navigationBarStyle: props['surfaceStyle'] == 'liquidGlass' ? navigationBarPreviewGlassStyle : null,
      items: [
        for (var index = 0; index < navigationBarPreviewItems.length; index++)
          _destination(
            index,
            icon: icons,
            badge: index == 1 && count != null ? _countBadge(count) : null,
            showDot: index == 2 && previewFlag(props, 'showDot'),
            enabled: index != disabled,
          ),
      ],
    );
    // 가로 바는 채울 폭이 있어야 목적지가 나뉜 모양이 보인다.
    return mode == CoreNavigationBarMode.bar ? _framed(320, navigation) : navigation;
  }
}
