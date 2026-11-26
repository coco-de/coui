/// Tabs 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="tabs/...">` 가 읽는다. 같은 이름의 Web 파일(`tabs_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'tabs_page.dart' show kTabsPreviewLabels;

/// 속성 → Widget.
///
/// 탭은 눌러야 바뀌므로 빌더가 선택과 닫힌 탭을 기억한다 — Web 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _TabsPreview(props: props);

/// 장면 이름(`tabs/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'tabs/anatomy': () => Tabs(
    tabs: [
      CoreTabItem(label: 'main.dart', badge: _countBadge('2'), onClose: () {}),
      CoreTabItem(label: 'app.dart', onClose: () {}),
      CoreTabItem(label: 'theme.dart', onClose: () {}),
    ],
    selectedIndex: 1,
    onChanged: (_) {},
  ),
  'tabs/states': _tabsStates,
  'tabs/badge': () => Tabs(
    tabs: [
      CoreTabItem(label: '받은편지함', badge: _countBadge('3')),
      const CoreTabItem(label: '보낸편지함'),
      const CoreTabItem(label: '임시보관함'),
    ],
    selectedIndex: 0,
    onChanged: (_) {},
  ),
  'tabs/closable': () => Tabs(
    tabs: [
      for (final file in const ['main.dart', 'app.dart', 'theme.dart']) CoreTabItem(label: file, onClose: () {}),
    ],
    selectedIndex: 0,
    onChanged: (_) {},
  ),
  'tabs/scrollable': () => SizedBox(
    width: 240,
    child: Tabs.labels(
      labels: const ['계정 및 개인정보 설정', '알림 및 접근성 환경설정', '결제 수단'],
      selectedIndex: 0,
      scrollable: true,
      onChanged: (_) {},
    ),
  ),
  'tabs/do-short-labels': () => _labels(const ['개요', '리뷰', '사양']),
  'tabs/dont-long-labels': () => _labels(const ['제품 개요 및 소개', '사용자 리뷰 및 평가']),
  'tabs/do-related': () => _labels(const ['기본 정보', '보안 설정', '알림 설정']),
  'tabs/dont-unrelated': () => _labels(const ['프로필', '결제', '고객센터']),
  'tabs/placement-expand': () => SizedBox(
    width: 320,
    child: Tabs.labels(labels: const ['전체', '읽지 않음', '중요'], selectedIndex: 0, expand: true, onChanged: (_) {}),
  ),
  'tabs/placement-underline': () => SizedBox(
    width: 240,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tabs.labels(
          labels: const ['개요', '리뷰'],
          selectedIndex: 0,
          variant: CoreTabVariant.underline,
          onChanged: (_) {},
        ),
        const Gap.space16(),
        const Text('선택한 탭의 내용이 여기에 옵니다.').bodyMedium.onSurfaceVariant,
      ],
    ),
  ),
  'tabs/related-tab-pane': () => SizedBox(
    width: 192,
    child: TabPane(
      tabs: const [
        CoreTabItem(label: '일반', content: Text('일반 설정')),
        CoreTabItem(label: '고급', content: Text('고급 설정')),
      ],
      selectedIndex: 0,
      onChanged: (_) {},
    ),
  ),
  'tabs/related-accordion': () => const SizedBox(
    width: 192,
    child: Accordion(
      items: [
        AccordionItem(title: '배송은 얼마나 걸리나요?', content: Text('보통 2~3일 걸려요.'), expanded: true),
        AccordionItem(title: '환불할 수 있나요?', content: Text('30일 안에 요청할 수 있어요.')),
      ],
    ),
  ),
  'tabs/related-navigation-bar': () => SizedBox(
    width: 192,
    child: NavigationBar(
      mode: CoreNavigationBarMode.bar,
      selectedIndex: 0,
      onSelected: (_) {},
      labelMode: CoreNavigationLabelMode.all,
      items: const [
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.house), label: '홈'),
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.search), label: '검색'),
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.user), label: '프로필'),
      ],
    ),
  ),
};

Widget _countBadge(String count) => Badge(
  variant: CoreBadgeVariant.filled,
  form: CoreBadgeForm.count,
  size: CoreComponentSize.xs,
  child: Text(count),
);

Widget _labels(List<String> labels) => Tabs.labels(labels: labels, selectedIndex: 0, onChanged: (_) {});

/// 상태 장면 — 변형마다 선택됨 · 기본 · 비활성 탭과, 선택된 탭이 비활성인 바.
Widget _tabsStates() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (final (index, variant) in CoreTabVariant.values.indexed) ...[
      if (index > 0) const Gap.space24(),
      Text(variant.name).labelSmall.onSurfaceVariant,
      const Gap.space8(),
      docsFlutterDemoRow([
        Tabs(
          variant: variant,
          tabs: const [
            CoreTabItem(label: '선택됨'),
            CoreTabItem(label: '기본'),
            CoreTabItem(label: '비활성', enabled: false),
          ],
          selectedIndex: 0,
          onChanged: (_) {},
        ),
        Tabs(
          variant: variant,
          tabs: const [
            CoreTabItem(label: '선택됨 · 비활성', enabled: false),
            CoreTabItem(label: '기본'),
          ],
          selectedIndex: 0,
          onChanged: (_) {},
        ),
      ]),
    ],
  ],
);

/// 속성으로 그리는 탭 바 — 선택과 닫힌 탭을 기억한다.
///
/// 속성: `variant` · `size` · `expand` · `scrollable` 은 위젯 속성 그대로,
/// `selectedIndex` 는 처음 선택, `badge` 는 첫 탭의 배지 숫자, `onClose` 는
/// 모든 탭에 닫기 버튼, `disabled` 는 비활성으로 둘 탭의 인덱스.
class _TabsPreview extends StatefulWidget {
  const _TabsPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_TabsPreview> createState() => _TabsPreviewState();
}

class _TabsPreviewState extends State<_TabsPreview> {
  late List<int> _open;
  late int _index;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant _TabsPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameProps(oldWidget.props, widget.props)) _reset();
  }

  void _reset() {
    _open = [for (var i = 0; i < kTabsPreviewLabels.length; i++) i];
    _index = (int.tryParse(widget.props['selectedIndex'] ?? '') ?? 0).clamp(0, _open.length - 1);
  }

  void _handleClose(int position) {
    setState(() {
      _open.removeAt(position);
      if (_open.isEmpty) {
        // 마지막 탭을 닫으면 처음 상태로 돌아간다 — 미리보기가 비지 않게.
        _reset();
      } else if (position < _index || _index == _open.length) {
        _index = (_index - 1).clamp(0, _open.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final badge = props['badge'];
    final closable = previewFlag(props, 'onClose');
    final disabled = int.tryParse(props['disabled'] ?? '');
    return Tabs(
      tabs: [
        for (final (position, original) in _open.indexed)
          CoreTabItem(
            label: kTabsPreviewLabels[original],
            badge: original == 0 && badge != null ? _countBadge(badge) : null,
            enabled: original != disabled,
            onClose: closable ? () => _handleClose(position) : null,
          ),
      ],
      selectedIndex: _index,
      variant: previewEnum(CoreTabVariant.values, props['variant'], CoreTabVariant.defaultVariant),
      size: previewEnum(CoreTabsSize.values, props['size'], CoreTabsSize.defaultSize),
      expand: previewFlag(props, 'expand'),
      scrollable: previewFlag(props, 'scrollable'),
      onChanged: (index) => setState(() => _index = index),
    );
  }
}

bool _sameProps(Map<String, String> a, Map<String, String> b) =>
    a.length == b.length && a.entries.every((entry) => b[entry.key] == entry.value);
