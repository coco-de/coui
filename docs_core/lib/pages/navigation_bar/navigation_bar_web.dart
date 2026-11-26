/// NavigationBar 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="navigation-bar/...">` 와 카드가 읽는다. 같은 이름의 Flutter
/// 파일(`navigation_bar_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'navigation_bar_page.dart';

/// 속성 → Component.
///
/// 선택은 눌러야 바뀌므로 빌더가 고른 번호를 기억한다. 서버에서 그리는 블록에서는
/// 처음 선택만 보이고, 브라우저에서 깨어나는 플레이그라운드에서는 눌러 바꿀 수 있다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _NavigationBarPreview(props: props);

/// 장면 이름(`navigation-bar/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'navigation-bar/anatomy': _anatomy,
  'navigation-bar/states': _states,
  'navigation-bar/badge-footer': _badgeFooter,
  'navigation-bar/text-tabs': () => _framed('20rem', _textTabs()),
  'navigation-bar/glass': () => _row([
    _framed('18rem', _glassBar()),
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
      _labelled(compact.name, _framed('18rem', _glassBar(compact: compact))),
  ]),
  'navigation-bar/do-short': () => _framed(
    '17rem',
    NavigationBar(selectedIndex: 0, onSelected: (_) {}, items: _destinations()),
  ),
  'navigation-bar/dont-long': () => _framed(
    '17rem',
    NavigationBar(
      selectedIndex: 0,
      onSelected: (_) {},
      items: [
        for (final (text, glyph) in navigationBarLongItems)
          CoreNavigationBarItem.destination(icon: Icon(glyph), label: text),
      ],
    ),
  ),
  'navigation-bar/placement-bottom': () => _screenFrame('column', [
    _screenBody(),
    NavigationBar(selectedIndex: 0, onSelected: (_) {}, items: _destinations()),
  ]),
  // Web 의 늘어난 레일은 `alignment` 를 따르므로 `start` 를 줘야 Flutter 처럼 위에 모인다.
  'navigation-bar/placement-rail': () => _screenFrame('row', [
    NavigationBar(
      mode: CoreNavigationBarMode.rail,
      alignment: CoreNavigationAlignment.start,
      selectedIndex: 0,
      onSelected: (_) {},
      items: _destinations(),
    ),
    _screenBody(),
  ]),
  'navigation-bar/related-item': () => _framed(
    pinnedLengthCss(CoreSize.size96),
    NavigationBarItem(
      mode: CoreNavigationBarMode.rail,
      icon: Icon(LucideIcons.inbox),
      label: navigationBarPreviewItems[1].$1,
      selected: true,
      onPressed: () {},
    ),
  ),
};

CoreNavigationBarItem<Component> _destination(
  int index, {
  bool icon = true,
  Component? badge,
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

List<CoreNavigationBarItem<Component>> _destinations() => [
  for (var index = 0; index < navigationBarPreviewItems.length; index++) _destination(index),
];

Component _countBadge([String count = navigationBarPreviewCount]) => Badge(
  form: CoreBadgeForm.count,
  tone: CoreBadgeTone.info,
  variant: CoreBadgeVariant.filled,
  size: CoreComponentSize.xs,
  child: Text(count),
);

/// 폭을 정한 자리 — 가로 바는 부모의 폭을 채운다.
Component _framed(String width, Component child) => div(styles: Styles(raw: {'width': width, 'max-width': '100%'}), [
  child,
]);

/// 장면 여러 개를 가운데로 모아 나란히 놓는다. 좁으면 줄을 바꾼다.
Component _row(List<Component> children, {String align = 'center', double gap = CoreSpace.space24}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': align,
      'gap': spaceCss(gap),
      'max-width': '100%',
    },
  ),
  children,
);

Component _column(List<Component> children, {double gap = CoreSpace.space8}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': spaceCss(gap),
      'max-width': '100%',
    },
  ),
  children,
);

Component _labelled(String name, Component child) => _column([Text(name).labelSmall.onSurfaceVariant, child]);

/// `data-docs-part` 는 구조 번호가 이 자리를 찾는 표지다.
Component _anatomyPart(String name, Component child) =>
    span(attributes: {'data-docs-part': name}, classes: WebLayout.inlineFlex, [child]);

Component _anatomy() => _framed(
  '26rem',
  NavigationBar(
    selectedIndex: 0,
    onSelected: (_) {},
    header: _anatomyPart('header', Icon(LucideIcons.atom)),
    footer: _anatomyPart('footer', Text(navigationBarPreviewFooter).labelSmall.onSurfaceVariant),
    items: [
      _destination(0),
      _destination(1, badge: _anatomyPart('badge', _countBadge())),
      _destination(2),
    ],
  ),
);

Component _stateNavigation(List<(String, IconName, bool)> rows, CoreNavigationBarMode mode) => NavigationBar(
  mode: mode,
  selectedIndex: 0,
  onSelected: (_) {},
  items: [
    for (final (text, glyph, enabled) in rows)
      CoreNavigationBarItem.destination(icon: Icon(glyph), label: text, enabled: enabled),
  ],
);

/// 상태 장면 — fill 은 레일, color 는 바. 선택 · 기본 · 비활성 · 선택된 비활성을
/// 보인다. hover · 눌림 · 포커스는 브라우저가 포인터나 키보드 없이 켤 수 없어
/// 표의 설명으로 대신한다.
Component _states() => _row(align: 'flex-start', gap: CoreSpace.space32, [
  _labelled(
    'fill · 레일',
    _row(align: 'flex-start', gap: CoreSpace.space16, [
      _stateNavigation(navigationBarStateItems, CoreNavigationBarMode.rail),
      _stateNavigation(navigationBarDisabledSelectedItems, CoreNavigationBarMode.rail),
    ]),
  ),
  _labelled(
    'color · 바',
    _column(gap: CoreSpace.space12, [
      _framed(
        pinnedLengthCss(navigationBarStateBarWidth),
        _stateNavigation(navigationBarStateItems, CoreNavigationBarMode.bar),
      ),
      _framed(
        pinnedLengthCss(navigationBarStateBarWidth),
        _stateNavigation(navigationBarDisabledSelectedItems, CoreNavigationBarMode.bar),
      ),
    ]),
  ),
]);

/// 높이를 정한 자리의 레일 — `header` 는 위 끝, `footer` 는 아래 끝에 선다.
Component _badgeFooter() => div(
  styles: Styles(raw: {'display': 'flex', 'height': pinnedLengthCss(navigationBarFooterSceneHeight)}),
  [
    NavigationBar(
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
  ],
);

Component _textTabs() => NavigationBar(
  selectedIndex: 0,
  onSelected: (_) {},
  selectionMark: CoreNavigationSelectionMark.dot,
  labelMode: CoreNavigationLabelMode.all,
  items: [for (final text in navigationBarTextTabLabels) CoreNavigationBarItem.destination(label: text)],
);

Component _glassBar({CoreNavigationCompact compact = CoreNavigationCompact.never}) => NavigationBar(
  selectedIndex: 0,
  onSelected: (_) {},
  compact: compact,
  navigationBarStyle: navigationBarPreviewGlassStyle,
  items: _destinations(),
);

/// 배치 장면의 화면 틀.
Component _screenFrame(String direction, List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': direction,
      'box-sizing': 'border-box',
      'width': pinnedLengthCss(navigationBarPlacementWidth),
      'max-width': '100%',
      'height': pinnedLengthCss(navigationBarPlacementHeight),
      'overflow': 'hidden',
      'border':
          '${strokeWidthCss(CoreStrokeWidth.stroke1)} solid '
          '${const CoreColor.token(CoreColors.outlineVariant).toValue()}',
      'border-radius': CoreBorderRadius.all(CoreRadiusRole.panel).toValue(),
    },
  ),
  children,
);

Component _screenBody() => div(
  styles: Styles(
    raw: {
      'flex': '1',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'min-width': '0',
      'min-height': '0',
    },
  ),
  [Text('화면 내용').bodySmall.onSurfaceVariant],
);

/// 속성으로 그리는 내비게이션 바 — 눌러 고른 목적지를 기억한다.
class _NavigationBarPreview extends StatefulComponent {
  const _NavigationBarPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_NavigationBarPreview> createState() => _NavigationBarPreviewState();
}

class _NavigationBarPreviewState extends State<_NavigationBarPreview> {
  int _selected = 0;

  void _handleSelected(int next) => setState(() => _selected = next);

  @override
  Component build(BuildContext context) {
    final props = component.props;
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
    return mode == CoreNavigationBarMode.bar ? _framed('20rem', navigation) : navigation;
  }
}
