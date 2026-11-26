/// ContextMenu 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="context-menu/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`context_menu_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대의 열린 패널은 그림이다. `ContextMenu` 의 패널은 열리면 오버레이
/// 호스트의 메뉴 층에 올라가고, 패널을 제자리에 그리는 공개 경로가 없다. 대신
/// 패널이 안에 그리는 것 — `Menu` 하나 — 을 `ContextMenu` 가 넘기는 것과 같은
/// 스타일(`CoreContextMenuStyle.defaultMenuStyle`)로 제자리에 그린다. 미리보기
/// 상자는 `ContextMenu` 처럼 `Popup` 에 담아 `defaultPreviewGap` 만큼 메뉴 위에
/// 놓고, 들어 올림 그림은 `CoreContextMenuStyle` 의 기본값(크기 · 그림자 ·
/// 모서리 · 덮개)으로 그린다. 실제 `ContextMenu` 는 플레이그라운드의 그림 아래
/// 영역이다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'context_menu_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _contextMenu;

/// 장면 이름(`context-menu/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'context-menu/anatomy': () => _picture(page.demoAnatomyItems<Component>()),
  'context-menu/preview': () => _openPanel(
    page.demoItems<Component>(const {}),
    preview: const Text(page.demoPreviewText),
  ),
  'context-menu/lift': () => _liftPicture(page.demoItems<Component>(const {})),
  'context-menu/do-visible-path': () => _pathPicture(withButton: true),
  'context-menu/dont-only-path': () => _pathPicture(withButton: false),
  'context-menu/do-critical-last': () => _panel(page.demoCriticalLastItems<Component>()),
  'context-menu/dont-critical-middle': () => _panel(page.demoCriticalMiddleItems<Component>()),
};

Component _contextMenu(Map<String, String> props, String? label) {
  final target = label ?? page.demoTargetLabel;
  if (previewFlag(props, 'opener')) return _ContextMenuOpener(props: props, target: target);
  return _picture(
    page.demoItems<Component>(props),
    target: target,
    preview: _previewOf(props),
    open: page.demoEnabled(props),
  );
}

Component? _previewOf(Map<String, String> props) =>
    previewFlag(props, 'preview') ? const Text(page.demoPreviewText) : null;

/// 메뉴를 여는 영역 — 코드 상자의 `child` 와 같다.
Component _target(String text) => OutlinedContainer(
  containerStyle: const CoreOutlinedContainerStyle(padding: CoreEdgeInsets.all(CoreSpace.space24)),
  child: Text(text),
);

/// 열린 패널 — `ContextMenu` 가 패널에 그리는 `Menu`.
Component _panel(List<CoreMenuItem<Component>> items) => div(
  attributes: const {'data-docs-part': 'panel'},
  [Menu(items: items, menuStyle: CoreContextMenuStyle.defaultMenuStyle)],
);

/// 세로로 쌓은 묶음 — 내용 폭만 차지한다.
Component _column(List<Component> children, {required String gap}) => div(
  styles: Styles(
    raw: {'display': 'inline-flex', 'flex-direction': 'column', 'align-items': 'flex-start', 'gap': gap},
  ),
  children,
);

/// 열린 메뉴 — [preview] 가 있으면 `ContextMenu` 처럼 `Popup` 에 담아 메뉴 위에
/// 둔다.
Component _openPanel(List<CoreMenuItem<Component>> items, {Component? preview}) => _column(
  [
    if (preview != null)
      div(
        attributes: const {'data-docs-part': 'preview'},
        [
          Popup(attributes: const {'role': 'presentation'}, children: [preview]),
        ],
      ),
    _panel(items),
  ],
  gap: pinnedLengthCss(CoreContextMenuContract.defaultPreviewGap),
);

/// 여는 영역과 열린 메뉴의 그림. [open] 이 false 면 닫힌 모습(영역만)이다.
Component _picture(
  List<CoreMenuItem<Component>> items, {
  String target = page.demoTargetLabel,
  Component? preview,
  bool open = true,
}) => _column(
  [
    div(attributes: const {'data-docs-part': 'child'}, [_target(target)]),
    if (open) _openPanel(items, preview: preview),
  ],
  gap: spaceCss(CoreSpace.space12),
);

/// 완전히 들어 올린 모습의 그림 — 덮개 위에서 `child` 가 커지고 그림자를 드리운다.
///
/// 실제 덮개는 화면 전체를 덮지만 그림은 이 상자만 덮는다.
Component _liftPicture(List<CoreMenuItem<Component>> items) => div(
  styles: Styles(
    raw: {
      'display': 'inline-flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': spaceCss(CoreSpace.space16),
      'padding': spaceCss(CoreSpace.space24),
      'border-radius': const CoreBorderRadius.all(CoreRadius.radius16).toValue(),
      'background-color': const CoreColor.token(
        CoreColors.scrim,
      ).scaleAlpha(CoreContextMenuStyle.defaultLiftDimOpacity).toValue(),
    },
  ),
  [
    div(
      styles: Styles(
        raw: {
          'border-radius': CoreContextMenuStyle.defaultLiftRadius.toValue(),
          'box-shadow': emitShadow(CoreContextMenuStyle.defaultLiftCast, base: kShadowVariableBase),
          'transform': 'scale(${CoreContextMenuStyle.defaultLiftScale})',
        },
      ),
      [_target(page.demoTargetLabel)],
    ),
    _panel(items),
  ],
);

/// "여는 길" 카드 — 파일 한 줄과 그 줄의 메뉴. [withButton] 이면 같은 행동을 여는
/// 버튼이 줄에 보인다.
Component _pathPicture({required bool withButton}) => _column(
  [
    OutlinedContainer(
      containerStyle: const CoreOutlinedContainerStyle(padding: CoreEdgeInsets.all(CoreSpace.space16)),
      child: div(
        styles: Styles(raw: {'display': 'flex', 'align-items': 'center', 'gap': spaceCss(CoreSpace.space12)}),
        [
          const Text(page.demoFileName),
          if (withButton)
            Button(
              variant: CoreButtonVariant.outline,
              size: CoreComponentSize.sm,
              onPressed: () {},
              child: const Text(page.demoVisibleAction),
            ),
        ],
      ),
    ),
    _panel(page.demoPathItems<Component>()),
  ],
  gap: spaceCss(CoreSpace.space12),
);

/// 플레이그라운드의 미리보기 — 열린 메뉴의 그림 아래에, 같은 속성의 실제
/// `ContextMenu` 로 감싼 영역을 둔다. 우클릭하거나(터치는 길게 눌러) 연다.
/// `enabled: false` 면 열리지 않으므로 그림을 두지 않는다.
class _ContextMenuOpener extends StatelessComponent {
  const _ContextMenuOpener({required this.props, required this.target});

  final Map<String, String> props;
  final String target;

  @override
  Component build(BuildContext context) {
    final enabled = page.demoEnabled(props);
    final items = page.demoItems<Component>(props);
    return div(
      styles: Styles(
        raw: {
          'display': 'flex',
          'flex-direction': 'column',
          'align-items': 'center',
          'gap': spaceCss(page.demoOpenerGap),
          'width': '100%',
        },
      ),
      [
        if (enabled) _openPanel(items, preview: _previewOf(props)),
        ContextMenu(
          key: ValueKey(page.demoPreviewKey(props)),
          enabled: enabled,
          liftChild: previewFlag(props, 'liftChild'),
          glideToSelect: previewFlag(props, 'glideToSelect'),
          haptics: previewFlag(props, 'haptics'),
          preview: _previewOf(props),
          items: items,
          child: _target(target),
        ),
      ],
    );
  }
}
