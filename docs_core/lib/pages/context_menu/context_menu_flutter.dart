/// ContextMenu 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="context-menu/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`context_menu_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대의 열린 패널은 그림이다. `ContextMenu` 의 패널은 열리면 앱의
/// `Overlay` 에 올라가고, 패널을 제자리에 그리는 공개 경로가 없다. 대신 패널이
/// 안에 그리는 것 — `Menu` 하나 — 을 `ContextMenu` 가 넘기는 것과 같은 스타일
/// (`CoreContextMenuStyle.defaultMenuStyle`)로 제자리에 그린다. 미리보기 상자는
/// `ContextMenu` 처럼 `Popup` 에 담아 `defaultPreviewGap` 만큼 메뉴 위에 놓고,
/// 들어 올림 그림은 `CoreContextMenuStyle` 의 기본값(크기 · 그림자 · 모서리 ·
/// 덮개)을 `resolveContextMenu` 에 넘겨 그린다. 색과 서페이스 스타일은 테마를
/// 따른다. 실제 `ContextMenu` 는 플레이그라운드의 그림 아래 영역이다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'context_menu_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _contextMenu;

/// 장면 이름(`context-menu/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'context-menu/anatomy': () => _picture(page.demoAnatomyItems<Widget>()),
  'context-menu/preview': () => _openPanel(
    page.demoItems<Widget>(const {}),
    preview: const Text(page.demoPreviewText),
  ),
  'context-menu/lift': () => _LiftPicture(items: page.demoItems<Widget>(const {})),
  'context-menu/do-visible-path': () => _pathPicture(withButton: true),
  'context-menu/dont-only-path': () => _pathPicture(withButton: false),
  'context-menu/do-critical-last': () => _panel(page.demoCriticalLastItems<Widget>()),
  'context-menu/dont-critical-middle': () => _panel(page.demoCriticalMiddleItems<Widget>()),
};

Widget _contextMenu(Map<String, String> props, String? label) {
  final target = label ?? page.demoTargetLabel;
  if (previewFlag(props, 'opener')) return _ContextMenuOpener(props: props, target: target);
  return _picture(
    page.demoItems<Widget>(props),
    target: target,
    preview: _previewOf(props),
    open: page.demoEnabled(props),
  );
}

Widget? _previewOf(Map<String, String> props) =>
    previewFlag(props, 'preview') ? const Text(page.demoPreviewText) : null;

/// 메뉴를 여는 영역 — 코드 상자의 `child` 와 같다.
Widget _target(String text) => OutlinedContainer(
  containerStyle: const CoreOutlinedContainerStyle(padding: CoreEdgeInsets.all(CoreSpace.space24)),
  child: Text(text),
);

/// 열린 패널 — `ContextMenu` 가 패널에 그리는 `Menu`.
Widget _panel(List<CoreMenuItem<Widget>> items) => Menu(items: items, menuStyle: CoreContextMenuStyle.defaultMenuStyle);

/// 열린 메뉴 — [preview] 가 있으면 `ContextMenu` 처럼 `Popup` 에 담아 메뉴 위에
/// 둔다.
Widget _openPanel(List<CoreMenuItem<Widget>> items, {Widget? preview}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreContextMenuContract.defaultPreviewGap,
  children: [
    if (preview != null) Popup(children: [preview]),
    _panel(items),
  ],
);

/// 여는 영역과 열린 메뉴의 그림. [open] 이 false 면 닫힌 모습(영역만)이다.
Widget _picture(
  List<CoreMenuItem<Widget>> items, {
  String target = page.demoTargetLabel,
  Widget? preview,
  bool open = true,
}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space12,
  children: [
    _target(target),
    if (open) _openPanel(items, preview: preview),
  ],
);

/// "여는 길" 카드 — 파일 한 줄과 그 줄의 메뉴. [withButton] 이면 같은 행동을 여는
/// 버튼이 줄에 보인다.
Widget _pathPicture({required bool withButton}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space12,
  children: [
    OutlinedContainer(
      containerStyle: const CoreOutlinedContainerStyle(padding: CoreEdgeInsets.all(CoreSpace.space16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space12,
        children: [
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
    _panel(page.demoPathItems<Widget>()),
  ],
);

/// 완전히 들어 올린 모습의 그림 — 덮개 위에서 `child` 가 커지고 그림자를 드리운다.
///
/// 실제 덮개는 화면 전체를 덮지만 그림은 이 상자만 덮는다.
class _LiftPicture extends StatelessWidget {
  const _LiftPicture({required this.items});

  final List<CoreMenuItem<Widget>> items;

  @override
  Widget build(BuildContext context) {
    // Web 그림처럼 Core 기본값으로 그린다. 인스턴스에 준 값은 테마의 `contextMenu`
    // 값보다 우선한다.
    final menu = resolveContextMenu(
      context,
      contextMenuStyle: const CoreContextMenuStyle(
        liftScale: CoreContextMenuStyle.defaultLiftScale,
        liftDimOpacity: CoreContextMenuStyle.defaultLiftDimOpacity,
        liftCast: CoreContextMenuStyle.defaultLiftCast,
        liftRadius: CoreContextMenuStyle.defaultLiftRadius,
      ),
    );
    final lift = resolveContextMenuLift(context, menu: menu, progress: 1);
    return DecoratedBox(
      decoration: BoxDecoration(color: lift.dimColor, borderRadius: BorderRadius.circular(CoreRadius.radius16)),
      child: Padding(
        padding: const EdgeInsets.all(CoreSpace.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CoreSpace.space16,
          children: [
            Transform.scale(
              scale: lift.scale,
              child: InjectedCast(
                shadows: lift.shadows,
                borderRadius: lift.borderRadius,
                child: _target(page.demoTargetLabel),
              ),
            ),
            _panel(items),
          ],
        ),
      ),
    );
  }
}

/// 플레이그라운드의 미리보기 — 열린 메뉴의 그림 아래에, 같은 속성의 실제
/// `ContextMenu` 로 감싼 영역을 둔다. 우클릭하거나(모바일은 길게 눌러) 연다.
/// `enabled: false` 면 열리지 않으므로 그림을 두지 않는다.
class _ContextMenuOpener extends StatelessWidget {
  const _ContextMenuOpener({required this.props, required this.target});

  final Map<String, String> props;
  final String target;

  @override
  Widget build(BuildContext context) {
    final enabled = page.demoEnabled(props);
    final items = page.demoItems<Widget>(props);
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: page.demoOpenerGap,
      children: [
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
