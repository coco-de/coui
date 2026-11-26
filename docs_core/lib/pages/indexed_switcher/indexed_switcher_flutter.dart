/// IndexedSwitcher 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="indexed-switcher/...">` · `<Card demo>` 가 읽는다. 같은
/// 이름의 Web 파일(`indexed_switcher_web.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
///
/// 장면은 멈춘 그림이라 전환이 돌지 않는다. `fade-through` 장면은 전환의 네
/// 순간을 화면 칸의 진하기로 그린 그림이고, 나머지 장면의 화면 전환 부분은
/// 실제 IndexedSwitcher · Switcher 다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'indexed_switcher_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _indexedSwitcher;

/// 장면 이름(`indexed-switcher/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'indexed-switcher/fade-through': () => _wrap([
    for (final frame in kIndexedSwitcherFadeFrames) _fadeFrame(frame),
  ]),
  'indexed-switcher/sizing': () => _wrap([
    for (final (index, caption) in kIndexedSwitcherSizingCaptions.indexed)
      _captioned(
        caption,
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
      ),
  ]),
  'indexed-switcher/with-navigation-bar': () => SizedBox(
    width: 224,
    child: OutlinedContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 112,
            child: IndexedSwitcher(index: 1, children: [for (final name in kIndexedSwitcherScreenNames) _fill(name)]),
          ),
          _navigationBar(selected: 1),
        ],
      ),
    ),
  ),
  'indexed-switcher/with-tabs': () => SizedBox(
    width: 224,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CoreSpace.space8,
      children: [
        Tabs.labels(labels: kIndexedSwitcherScreenNames, selectedIndex: 1, onChanged: (_) {}, expand: true),
        OutlinedContainer(
          containerStyle: const CoreOutlinedContainerStyle(height: 96),
          child: IndexedSwitcher(index: 1, children: [for (final name in kIndexedSwitcherScreenNames) _fill(name)]),
        ),
      ],
    ),
  ),
  'indexed-switcher/related-switcher': () => SizedBox(
    width: 176,
    height: 72,
    child: OutlinedContainer(
      containerStyle: const CoreOutlinedContainerStyle(width: 176, height: 72),
      child: Switcher(
        gestureEnabled: false,
        items: [for (final name in kIndexedSwitcherStepNames) _fill(name)],
      ),
    ),
  ),
  'indexed-switcher/related-navigation-bar': () => SizedBox(width: 192, child: _navigationBar(selected: 0)),
  'indexed-switcher/related-tabs': () => SizedBox(
    // 라벨 세 칸을 채우는 탭 바는 192 에 들어가지 않는다.
    width: 208,
    child: Tabs.labels(labels: kIndexedSwitcherScreenNames, selectedIndex: 0, onChanged: (_) {}, expand: true),
  ),
};

Widget _indexedSwitcher(Map<String, String> props, String? label) => OutlinedContainer(
  containerStyle: const CoreOutlinedContainerStyle(width: 240, height: 144),
  child: IndexedSwitcher(
    index: indexedSwitcherPreviewIndex(props),
    indexedSwitcherStyle: indexedSwitcherPreviewStyle(props),
    children: [for (final name in kIndexedSwitcherScreenNames) _CountedScreen(name: name)],
  ),
);

/// 누른 횟수를 자기 상태로 세는 화면 — 다른 화면에 다녀와도 숫자가 남는다.
class _CountedScreen extends StatefulWidget {
  const _CountedScreen({required this.name});

  final String name;

  @override
  State<_CountedScreen> createState() => _CountedScreenState();
}

class _CountedScreenState extends State<_CountedScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space12,
      children: [
        Text('${widget.name} 화면').titleSmall.onSurface,
        Button(
          variant: CoreButtonVariant.outline,
          size: CoreComponentSize.sm,
          onPressed: () => setState(() => _count++),
          child: Text('누른 횟수 $_count'),
        ),
      ],
    ),
  );
}

/// 정해진 크기의 화면 칸. [width] · [height] 는 logical px.
Widget _screen(String name, {required double width, required double height}) => OutlinedContainer(
  containerStyle: CoreOutlinedContainerStyle(width: width, height: height),
  child: Center(child: Text(name).labelLarge.onSurface),
);

/// 주어진 높이를 채우는 화면.
Widget _fill(String name) => Center(child: Text('$name 화면').titleSmall.onSurface);

/// 전환의 한 순간 — 칸 안의 글자만 진하기를 바꾼다.
Widget _fadeFrame((String, String, double) frame) {
  final (caption, screen, opacity) = frame;
  return SizedBox(
    width: 120,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space8,
      children: [
        OutlinedContainer(
          containerStyle: const CoreOutlinedContainerStyle(width: 120, height: 72),
          child: Center(
            child: Opacity(opacity: opacity, child: Text(screen).titleSmall.onSurface),
          ),
        ),
        Text(caption, textAlign: TextAlign.center).labelSmall.onSurfaceVariant,
      ],
    ),
  );
}

Widget _navigationBar({required int selected}) => NavigationBar(
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
Widget _wrap(List<Widget> children) => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space16,
  runSpacing: CoreSpace.space16,
  children: children,
);

/// 위에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space8,
  children: [Text(caption).labelSmall.onSurfaceVariant, child],
);
