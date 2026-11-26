/// NavigationBarItem 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="navigation-bar-item/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`navigation_bar_item_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 항목은 hover · 포커스 · 눌림 색을 바의 바탕색에 섞으므로, 미리보기는 항목을
/// 그 색의 판(`navigationBarItemFace`) 위에 놓는다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'navigation_bar_item_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _navigationBarItem;

/// 장면 이름(`navigation-bar-item/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'navigation-bar-item/anatomy': () => _panel(
    CoreNavigationBarItemContract.defaultMode,
    NavigationBarItem(
      icon: const Icon(LucideIcons.inbox),
      label: navigationBarItemPreviewLabel,
      badge: _countBadge(navigationBarItemPreviewCount),
      selected: true,
      onPressed: () {},
    ),
  ),
  'navigation-bar-item/label-positions': _labelPositions,
  'navigation-bar-item/long-label': () => _column(CoreNavigationBarItemContract.defaultMode, [
    for (final overflow in const [CoreNavigationOverflow.ellipsis, CoreNavigationOverflow.clip])
      NavigationBarItem(
        icon: const Icon(LucideIcons.inbox),
        label: navigationBarItemLongLabel,
        badge: _countBadge(navigationBarItemLongCount),
        overflow: overflow,
        onPressed: () {},
      ),
  ]),
  'navigation-bar-item/states': _states,
  'navigation-bar-item/do-one-selected': () => _choices(const {0}),
  'navigation-bar-item/dont-two-selected': () => _choices(const {0, 2}),
  'navigation-bar-item/column': () => _column(CoreNavigationBarItemContract.defaultMode, [
    for (final (index, (label, icon, enabled)) in navigationBarItemListRows.indexed)
      NavigationBarItem(
        icon: Icon(icon),
        label: label,
        badge: index == 0 ? _countBadge(navigationBarItemPreviewCount) : null,
        showDot: index == 1,
        selected: index == 0,
        enabled: enabled,
        onPressed: () {},
      ),
  ]),
  'navigation-bar-item/rail-column': () => _column(
    CoreNavigationBarMode.rail,
    [
      for (final (index, (label, icon, _)) in navigationBarItemListRows.take(3).indexed)
        NavigationBarItem(
          mode: CoreNavigationBarMode.rail,
          icon: Icon(icon),
          label: label,
          badge: index == 0 ? _countBadge(navigationBarItemPreviewCount) : null,
          showDot: index == 1,
          selected: index == 0,
          onPressed: () {},
        ),
    ],
    gap: CoreSpace.space8,
  ),
};

Widget _navigationBarItem(Map<String, String> props, String? label) {
  final mode = navigationBarItemMode(props);
  final count = props['badge'];
  final indicator = props['indicator'];
  final labelMode = props['labelMode'];
  return _panel(
    mode,
    NavigationBarItem(
      mode: mode,
      icon: const Icon(LucideIcons.inbox),
      label: label ?? navigationBarItemPreviewLabel,
      badge: count == null ? null : _countBadge(count),
      showDot: previewFlag(props, 'showDot'),
      indicator: indicator == null
          ? null
          : previewEnum(CoreNavigationSelectionIndicator.values, indicator, mode.defaultIndicator),
      selectionMark: previewEnum(
        CoreNavigationSelectionMark.values,
        props['selectionMark'],
        CoreNavigationSelectionMark.defaultSelectionMark,
      ),
      labelMode: labelMode == null
          ? null
          : previewEnum(CoreNavigationLabelMode.values, labelMode, mode.defaultLabelMode),
      selected: previewFlag(props, 'selected'),
      enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
      onPressed: () {},
    ),
  );
}

/// 상태 면을 섞는 바탕색의 판. 항목은 판의 폭을 채운다.
Widget _panel(CoreNavigationBarMode mode, Widget child, {double? width}) => SizedBox(
  width: width ?? navigationBarItemPreviewWidth(mode),
  child: Builder(
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.resolve(navigationBarItemFace(mode)).toValue(),
        borderRadius: BorderRadius.circular(CoreRadiusRole.panel),
      ),
      child: Padding(padding: const EdgeInsets.all(CoreSpace.space8), child: child),
    ),
  ),
);

/// [_panel] 안에 항목을 세로로 쌓는다.
Widget _column(
  CoreNavigationBarMode mode,
  List<Widget> children, {
  double? width,
  double gap = CoreSpace.space2,
}) => _panel(
  mode,
  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: gap,
    children: children,
  ),
  width: width,
);

Widget _countBadge(String count) => Badge(
  form: CoreBadgeForm.count,
  tone: CoreBadgeTone.info,
  variant: CoreBadgeVariant.filled,
  size: CoreComponentSize.xs,
  child: Text(count),
);

/// 이름 자리 넷 — Web 과 같은 레일 목적지를 자리만 바꿔 놓는다.
Widget _labelPositions() => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space16,
  runSpacing: CoreSpace.space16,
  children: [
    for (final position in CoreNavigationLabelPosition.values)
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space4,
        children: [
          _panel(
            CoreNavigationBarMode.rail,
            NavigationBarItem(
              mode: CoreNavigationBarMode.rail,
              labelPosition: position,
              icon: const Icon(LucideIcons.settings),
              label: navigationBarItemShortLabel,
              selected: true,
              onPressed: () {},
            ),
            width: CoreSize.size112,
          ),
          Text(position.name).labelSmall.onSurfaceVariant,
        ],
      ),
  ],
);

/// 상태 장면 — Web 과 같은 네 상태를 사이드바 줄과 바 목적지로 놓는다.
Widget _states() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space12,
  children: [
    for (final (name, selected, enabled) in navigationBarItemStateRows)
      Wrap(
        spacing: CoreSpace.space12,
        runSpacing: CoreSpace.space8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: CoreSize.size96, child: Text(name).labelSmall.onSurfaceVariant),
          for (final mode in const [CoreNavigationBarItemContract.defaultMode, CoreNavigationBarMode.bar])
            _panel(
              mode,
              NavigationBarItem(
                mode: mode,
                icon: const Icon(LucideIcons.inbox),
                label: navigationBarItemPreviewLabel,
                selected: selected,
                enabled: enabled,
                onPressed: () {},
              ),
              width: mode.isSidebar ? CoreLayout.layout160 : null,
            ),
        ],
      ),
  ],
);

/// 사용 가이드 장면 — [selected] 에 든 순서의 줄을 선택해 그린다.
Widget _choices(Set<int> selected) => _column(CoreNavigationBarItemContract.defaultMode, [
  for (final (index, (label, icon, _)) in navigationBarItemListRows.take(3).indexed)
    NavigationBarItem(icon: Icon(icon), label: label, selected: selected.contains(index), onPressed: () {}),
]);
