/// NavigationBarItem 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="navigation-bar-item/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`navigation_bar_item_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 항목은 hover · 포커스 · 눌림 색을 바의 바탕색에 섞으므로, 미리보기는 항목을
/// 그 색의 판(`navigationBarItemFace`) 위에 놓는다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'navigation_bar_item_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _navigationBarItem;

/// 장면 이름(`navigation-bar-item/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 블록이 배지에 번호를 붙일 수 있게 배지를 `data-docs-part` 로 감싼다.
  'navigation-bar-item/anatomy': () => _panel(
    CoreNavigationBarItemContract.defaultMode,
    NavigationBarItem(
      icon: const Icon(LucideIcons.inbox),
      label: navigationBarItemPreviewLabel,
      badge: span(
        attributes: const {'data-docs-part': 'badge'},
        styles: Styles(raw: {'display': 'flex'}),
        [_countBadge(navigationBarItemPreviewCount)],
      ),
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

Component _navigationBarItem(Map<String, String> props, String? label) {
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
Component _panel(CoreNavigationBarMode mode, Component child, {double? width}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'box-sizing': 'border-box',
      'width': pinnedLengthCss(width ?? navigationBarItemPreviewWidth(mode)),
      'max-width': '100%',
      'padding': spaceCss(CoreSpace.space8),
      'border-radius': CoreBorderRadius.all(CoreRadiusRole.panel).toValue(),
      'background-color': navigationBarItemFace(mode).toValue(),
    },
  ),
  [child],
);

/// [_panel] 안에 항목을 세로로 쌓는다.
Component _column(
  CoreNavigationBarMode mode,
  List<Component> children, {
  double? width,
  double gap = CoreSpace.space2,
}) => _panel(
  mode,
  div(
    styles: Styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(gap), 'width': '100%', 'min-width': '0'},
    ),
    children,
  ),
  width: width,
);

Component _countBadge(String count) => Badge(
  form: CoreBadgeForm.count,
  tone: CoreBadgeTone.info,
  variant: CoreBadgeVariant.filled,
  size: CoreComponentSize.xs,
  child: Text(count),
);

/// 이름 자리 넷 — 같은 레일 목적지를 자리만 바꿔 놓는다.
Component _labelPositions() => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'gap': spaceCss(CoreSpace.space16),
    },
  ),
  [
    for (final position in CoreNavigationLabelPosition.values)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'align-items': 'center',
            'gap': spaceCss(CoreSpace.space4),
          },
        ),
        [
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
          span([Text(position.name).labelSmall.onSurfaceVariant]),
        ],
      ),
  ],
);

/// 상태 장면 — 상태마다 사이드바 줄(`fill`)과 바 목적지(`color`)를 나란히 놓는다.
/// hover · 포커스 · 눌림은 포인터나 키보드 없이 켤 수 없어 표로 대신한다.
Component _states() => div(
  styles: Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space12), 'max-width': '100%'},
  ),
  [
    for (final (name, selected, enabled) in navigationBarItemStateRows)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-wrap': 'wrap',
            'align-items': 'center',
            'gap': spaceCss(CoreSpace.space12),
          },
        ),
        [
          div(styles: Styles(raw: {'width': pinnedLengthCss(CoreSize.size96)}), [
            Text(name).labelSmall.onSurfaceVariant,
          ]),
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
Component _choices(Set<int> selected) => _column(CoreNavigationBarItemContract.defaultMode, [
  for (final (index, (label, icon, _)) in navigationBarItemListRows.take(3).indexed)
    NavigationBarItem(icon: Icon(icon), label: label, selected: selected.contains(index), onPressed: () {}),
]);
