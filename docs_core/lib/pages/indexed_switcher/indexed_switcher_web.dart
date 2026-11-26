/// IndexedSwitcher 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="indexed-switcher/...">` · `<Card demo>` 가 읽는다. 같은
/// 이름의 Flutter 파일(`indexed_switcher_flutter.dart`)과 컴포넌트 · 속성 ·
/// 장면 이름이 같아야 한다.
///
/// 장면은 멈춘 그림이라 전환이 돌지 않는다. `fade-through` 장면은 전환의 네
/// 순간을 화면 칸의 진하기로 그린 그림이고, 나머지 장면의 화면 전환 부분은
/// 실제 IndexedSwitcher · Switcher 다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'indexed_switcher_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _indexedSwitcher;

/// 장면 이름(`indexed-switcher/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'indexed-switcher/fade-through': () => _wrap([
    for (final frame in kIndexedSwitcherFadeFrames) _fadeFrame(frame),
  ]),
  'indexed-switcher/sizing': () => _wrap([
    for (final (index, caption) in kIndexedSwitcherSizingCaptions.indexed)
      _captioned(
        caption,
        div(styles: Styles(raw: {'width': 'fit-content'}), [
          OutlinedContainer(
            containerStyle: const CoreOutlinedContainerStyle(
              borderStyle: CoreOutlinedContainerBorderStyle.dashed,
              padding: CoreEdgeInsets.all(CoreSpace.space8),
            ),
            child: IndexedSwitcher(
              index: index,
              children: [
                _screen(kIndexedSwitcherSmallScreen, width: 96, height: 48),
                _screen(kIndexedSwitcherLargeScreen, width: 176, height: 112),
              ],
            ),
          ),
        ]),
      ),
  ]),
  'indexed-switcher/with-navigation-bar': () => div(styles: Styles(raw: {'width': '14rem'}), [
    OutlinedContainer(
      child: div(styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column'}), [
        div(styles: Styles(raw: {'height': '7rem'}), [
          IndexedSwitcher(index: 1, children: [for (final name in kIndexedSwitcherScreenNames) _fill(name)]),
        ]),
        _navigationBar(selected: 1),
      ]),
    ),
  ]),
  'indexed-switcher/with-tabs': () => div(
    styles: Styles(
      raw: {'width': '14rem', 'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space8)},
    ),
    [
      Tabs.labels(labels: kIndexedSwitcherScreenNames, selectedIndex: 1, onChanged: (_) {}, expand: true),
      OutlinedContainer(
        containerStyle: const CoreOutlinedContainerStyle(height: 96),
        child: IndexedSwitcher(index: 1, children: [for (final name in kIndexedSwitcherScreenNames) _fill(name)]),
      ),
    ],
  ),
  'indexed-switcher/related-switcher': () => OutlinedContainer(
    containerStyle: const CoreOutlinedContainerStyle(width: 176, height: 72),
    child: Switcher(
      gestureEnabled: false,
      items: [for (final name in kIndexedSwitcherStepNames) _fill(name)],
    ),
  ),
  'indexed-switcher/related-navigation-bar': () =>
      div(styles: Styles(raw: {'width': '12rem'}), [_navigationBar(selected: 0)]),
  'indexed-switcher/related-tabs': () => div(styles: Styles(raw: {'width': '13rem'}), [
    Tabs.labels(labels: kIndexedSwitcherScreenNames, selectedIndex: 0, onChanged: (_) {}, expand: true),
  ]),
};

Component _indexedSwitcher(Map<String, String> props, String? label) => OutlinedContainer(
  containerStyle: const CoreOutlinedContainerStyle(width: 240, height: 144),
  child: IndexedSwitcher(
    index: indexedSwitcherPreviewIndex(props),
    indexedSwitcherStyle: indexedSwitcherPreviewStyle(props),
    children: [for (final name in kIndexedSwitcherScreenNames) _CountedScreen(name: name)],
  ),
);

/// 누른 횟수를 자기 상태로 세는 화면 — 다른 화면에 다녀와도 숫자가 남는다.
class _CountedScreen extends StatefulComponent {
  const _CountedScreen({required this.name});

  final String name;

  @override
  State<_CountedScreen> createState() => _CountedScreenState();
}

class _CountedScreenState extends State<_CountedScreen> {
  int _count = 0;

  @override
  Component build(BuildContext context) => div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'align-items': 'center',
        'justify-content': 'center',
        'gap': spaceCss(CoreSpace.space12),
        'height': '100%',
      },
    ),
    [
      Text('${component.name} 화면').titleSmall.onSurface,
      Button(
        variant: CoreButtonVariant.outline,
        size: CoreComponentSize.sm,
        onPressed: () => setState(() => _count++),
        child: Text('누른 횟수 $_count'),
      ),
    ],
  );
}

/// 가운데에 놓는 flex 선언.
const Map<String, String> _centered = {'display': 'flex', 'align-items': 'center', 'justify-content': 'center'};

/// 정해진 크기의 화면 칸. [width] · [height] 는 logical px.
Component _screen(String name, {required double width, required double height}) => OutlinedContainer(
  containerStyle: CoreOutlinedContainerStyle(width: width, height: height),
  css: Styles(raw: _centered),
  child: Text(name).labelLarge.onSurface,
);

/// 주어진 높이를 채우는 화면.
Component _fill(String name) => div(styles: Styles(raw: {..._centered, 'height': '100%'}), [
  Text('$name 화면').titleSmall.onSurface,
]);

/// 전환의 한 순간 — 칸 안의 글자만 진하기를 바꾼다.
Component _fadeFrame((String, String, double) frame) {
  final (caption, screen, opacity) = frame;
  return div(
    styles: Styles(
      raw: {
        'width': '7.5rem',
        'display': 'flex',
        'flex-direction': 'column',
        'align-items': 'center',
        'gap': spaceCss(CoreSpace.space8),
        'text-align': 'center',
      },
    ),
    [
      OutlinedContainer(
        containerStyle: const CoreOutlinedContainerStyle(width: 120, height: 72),
        css: Styles(raw: _centered),
        child: span(styles: Styles(raw: {'opacity': '$opacity'}), [Text(screen).titleSmall.onSurface]),
      ),
      Text(caption).labelSmall.onSurfaceVariant,
    ],
  );
}

Component _navigationBar({required int selected}) => NavigationBar(
  mode: CoreNavigationBarMode.bar,
  selectedIndex: selected,
  onSelected: (_) {},
  labelMode: CoreNavigationLabelMode.all,
  items: const [
    CoreNavigationBarItem.destination(icon: Icon(LucideIcons.house), label: '홈'),
    CoreNavigationBarItem.destination(icon: Icon(LucideIcons.search), label: '검색'),
    CoreNavigationBarItem.destination(icon: Icon(LucideIcons.settings), label: '설정'),
  ],
);

/// 옆으로 놓고, 좁으면 줄을 바꾸는 장면.
Component _wrap(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': spaceCss(CoreSpace.space16),
    },
  ),
  children,
);

/// 위에 이름을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'flex-start',
      'gap': spaceCss(CoreSpace.space8),
    },
  ),
  [Text(caption).labelSmall.onSurfaceVariant, child],
);
