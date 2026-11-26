/// Breadcrumb 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="breadcrumb/...">` ·
/// `<Anatomy>` · `<Card demo>` 가 읽는다. 같은 이름의 Web 파일
/// (`breadcrumb_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'breadcrumb_page.dart';

/// 속성 → Widget.
///
/// 항목을 누르면 `onItemTap` 이 받은 번호를 경로 아래에 적는다 — Web 빌더와
/// 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _BreadcrumbPreview(props: props);

/// 장면 이름(`breadcrumb/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'breadcrumb/anatomy': () => _trail(kBreadcrumbAnatomyLabels),
  'breadcrumb/states': _states,
  'breadcrumb/separator': _separators,
  'breadcrumb/overflow': () => SizedBox(
    width: kBreadcrumbOverflowWidth,
    child: _trail(kBreadcrumbLongLabels),
  ),
  'breadcrumb/do-current': () => _trail(kBreadcrumbDoCurrentLabels),
  'breadcrumb/dont-missing-current': () => _trail(kBreadcrumbDontMissingCurrentLabels),
  'breadcrumb/do-deep': () => _trail(kBreadcrumbDoDeepLabels),
  'breadcrumb/dont-two-levels': () => _trail(kBreadcrumbDontTwoLevelLabels),
  'breadcrumb/related-tabs': () => SizedBox(
    width: 192,
    child: Tabs.labels(labels: kBreadcrumbRelatedTabLabels, selectedIndex: 0, onChanged: (_) {}),
  ),
  'breadcrumb/related-navigation-bar': () => SizedBox(
    width: 192,
    child: NavigationBar(
      mode: CoreNavigationBarMode.bar,
      selectedIndex: 0,
      onSelected: (_) {},
      labelMode: CoreNavigationLabelMode.all,
      items: const [
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.house), label: '홈'),
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.search), label: '검색'),
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.settings), label: '설정'),
      ],
    ),
  ),
  'breadcrumb/related-link': () => const Link(href: '/components/link', child: Text('주문 목록으로 돌아가기')),
};

/// 라벨만으로 그리는 누를 수 있는 경로.
Widget _trail(List<String> labels) => Breadcrumb(items: breadcrumbItems(labels), onItemTap: (_) {});

/// 상태 장면 — 활성 · 비활성 · 표시 전용.
Widget _states() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (final (index, row) in kBreadcrumbStateRows.indexed) ...[
      if (index > 0) const Gap.space16(),
      Text(row.caption).codeSm.onSurfaceVariant,
      const Gap.space4(),
      Breadcrumb(
        items: breadcrumbItems(kBreadcrumbStateLabels),
        onItemTap: row.hasHandler ? (_) {} : null,
        enabled: row.enabled,
      ),
    ],
  ],
);

/// 구분자 장면 — 기본값과 덮어쓴 값.
Widget _separators() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (final (index, row) in kBreadcrumbSeparatorRows.indexed) ...[
      if (index > 0) const Gap.space16(),
      Text(row.caption).codeSm.onSurfaceVariant,
      const Gap.space4(),
      Breadcrumb(items: breadcrumbItems(kBreadcrumbStateLabels), onItemTap: (_) {}, breadcrumbStyle: row.style),
    ],
  ],
);

/// 속성으로 그리는 탐색 경로 — 마지막에 누른 항목의 번호를 기억한다.
///
/// 속성: `depth` 는 항목 수, `separatorSize` · `gap` 은 구분자의 크기와 양옆
/// 간격, `enabled=false` 는 비활성.
class _BreadcrumbPreview extends StatefulWidget {
  const _BreadcrumbPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_BreadcrumbPreview> createState() => _BreadcrumbPreviewState();
}

class _BreadcrumbPreviewState extends State<_BreadcrumbPreview> {
  int? _tapped;

  @override
  void didUpdateWidget(covariant _BreadcrumbPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameProps(oldWidget.props, widget.props)) _tapped = null;
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final tapped = _tapped;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Breadcrumb(
          items: breadcrumbPreviewItems(props),
          onItemTap: (index) => setState(() => _tapped = index),
          enabled: previewFlag(props, 'enabled', fallback: true) ? null : false,
          breadcrumbStyle: breadcrumbPreviewStyle(props),
        ),
        if (tapped != null) ...[
          const Gap.space8(),
          Text('onItemTap($tapped)').codeSm.onSurfaceVariant,
        ],
      ],
    );
  }
}

bool _sameProps(Map<String, String> a, Map<String, String> b) =>
    a.length == b.length && a.entries.every((entry) => b[entry.key] == entry.value);
