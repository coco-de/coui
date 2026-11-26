/// FAB 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="fab/...">` 가 읽는다. 같은 이름의 Flutter 파일(`fab_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'fab_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _fab;

/// 장면 이름(`fab/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'fab/anatomy': _openMenu,
  'fab/menu': _openMenu,
  'fab/sizes-extended': () => docsWebDemoRow([for (final size in CoreFabSize.values) _extended(size)]),
  'fab/states': _states,
  'fab/do-single': _plus,
  'fab/dont-two': () => docsWebDemoRow([
    _plus(),
    Fab(trigger: const Icon(LucideIcons.pencil), onPressed: () {}),
  ]),
  'fab/do-extended': () => _extended(CoreFabSize.regular),
  'fab/dont-disabled': () => const Fab(trigger: Icon(LucideIcons.plus)),
  'fab/do-confirm': () => Button(
    variant: CoreButtonVariant.destructive,
    onPressed: () {},
    child: const Text('모두 삭제'),
  ),
  'fab/dont-destructive': () => Fab(
    trigger: const Icon(LucideIcons.x),
    label: const Text('모두 삭제'),
    onPressed: () {},
  ),
  'fab/placement-corner': () => _phone(_plus()),
  'fab/placement-menu': () => _phone(_openMenu()),
  'fab/a11y-name': () => div(classes: 'docs-demo-caption', [
    Fab(trigger: const Icon(LucideIcons.plus), tooltip: fabPreviewTooltip, onPressed: () {}),
    div([
      code([Component.text('aria-label="$fabPreviewTooltip"')]),
      const Text('아이콘만 있는 FAB 은 웹에서 tooltip 이 이름이 됩니다.').bodySmall.onSurfaceVariant,
    ]),
  ]),
};

Component _fab(Map<String, String> props, String? label) {
  final form = props['form'] ?? 'circle';
  final menu = form == 'menu';
  return Fab(
    // 형태가 바뀌면 다시 만든다 — 메뉴의 열림 상태가 다른 형태로 넘어가지 않게.
    key: ValueKey('fab-$form'),
    trigger: const Icon(LucideIcons.plus),
    label: form == 'extended' ? Text(label ?? fabPreviewLabel) : null,
    size: fabPreviewSize(props['size']),
    expandDirection: previewEnum(
      CoreFabExpandDirection.values,
      props['expandDirection'],
      CoreFabExpandDirection.defaultDirection,
    ),
    tooltip: props['tooltip'],
    onPressed: menu ? null : () {},
    actions: menu
        ? [
            for (final action in fabPreviewActions)
              FabAction(icon: Icon(action.icon), label: Text(action.label), onPressed: () {}),
          ]
        : null,
  );
}

Component _plus() => Fab(trigger: const Icon(LucideIcons.plus), onPressed: () {});

Component _extended(CoreFabSize size) => Fab(
  trigger: const Icon(LucideIcons.plus),
  label: const Text(fabPreviewLabel),
  size: size,
  onPressed: () {},
);

/// 열린 메뉴의 그림. 실제 Fab 은 메뉴를 오버레이 층에 열어 문서 상자 안에
/// 그릴 수 없다. 판과 행은 킷의 `Popup` · `MenuItem` 이고, 값은 Fab 의
/// 기본값을 읽는다.
Component _openMenu() => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'flex-end',
      'gap': spaceCss(CoreFabStyle.defaultSpacing),
    },
  ),
  [
    Popup(
      popupStyle: CoreFabStyle.defaultPopupStyle,
      children: [for (final action in fabPreviewActions) _menuRow(action)],
    ),
    div(
      attributes: const {'data-docs-part': 'fab'},
      styles: Styles(raw: {'display': 'flex'}),
      [
        Fab(trigger: const Icon(LucideIcons.x), onPressed: () {}),
      ],
    ),
  ],
);

Component _menuRow(FabPreviewAction action) => MenuItem(
  label: div(classes: WebLayout.truncate, [Text(action.label)]),
  size: CoreFabContract.actionItemSize,
  leading: Icon(action.icon),
  menuItemStyle: CoreFabStyle.defaultActionItemStyle,
  onPressed: () {},
);

/// 상태 장면. Hover 는 그때의 채움을, Pressed 는 그때의 채움과 크기를 고정해
/// 그리고, Focus 는 링을 켠 `FocusOutline` 으로 감싼다 — 브라우저는 포인터나
/// 키보드 없이 이 상태를 켤 수 없다.
Component _states() {
  Component cell(String caption) => div(
    styles: Styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'center', 'gap': spaceCss(CoreSpace.space8)},
    ),
    [
      switch (caption) {
        'Hover' => _filled(CoreColors.primaryHover),
        'Pressed' => div(
          styles: Styles(
            raw: {'display': 'inline-flex', 'transform': 'scale(${CoreButtonStyle.defaultPressedScale})'},
          ),
          [_filled(CoreColors.primaryPressed)],
        ),
        'Focus' => FocusOutline(
          focused: true,
          focusOutlineStyle: _focusRing,
          css: Styles(raw: {'display': 'inline-flex'}),
          child: _plus(),
        ),
        '비활성' => const Fab(trigger: Icon(LucideIcons.plus)),
        '열림' => Fab(trigger: const Icon(LucideIcons.x), onPressed: () {}),
        _ => _plus(),
      },
      Text(caption).labelSmall.onSurfaceVariant,
    ],
  );
  return div(
    styles: Styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'justify-content': 'center', 'gap': spaceCss(CoreSpace.space24)},
    ),
    [for (final caption in fabStateCaptions) cell(caption)],
  );
}

const CoreFocusOutlineStyle _focusRing = CoreFocusOutlineStyle(
  borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
  offsetColor: CoreFocusRing.opaqueOffsetColor,
);

Component _filled(CoreColorToken token) => Fab(
  trigger: const Icon(LucideIcons.plus),
  onPressed: () {},
  fabStyle: CoreFabStyle(
    buttonStyle: CoreButtonStyle(backgroundColor: CoreColor.token(token), disableHoverEffect: true),
  ),
);

/// 휴대폰 화면의 아래쪽 — 본문 줄과 끝 모서리의 [corner].
Component _phone(Component corner) => div(classes: 'docs-demo-phone', [
  div(classes: 'docs-demo-phone-lines', [
    for (final width in ['70%', '100%']) span(styles: Styles(raw: {'width': width}), []),
  ]),
  div(styles: Styles(raw: {'display': 'flex', 'justify-content': 'flex-end'}), [corner]),
]);
