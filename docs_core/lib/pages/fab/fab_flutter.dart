/// FAB 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="fab/...">` 가 읽는다. 같은 이름의 Web 파일(`fab_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'fab_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _fab;

/// 장면 이름(`fab/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'fab/anatomy': _openMenu,
  'fab/menu': _openMenu,
  'fab/sizes-extended': () => docsFlutterDemoRow([for (final size in CoreFabSize.values) _extended(size)]),
  'fab/states': _states,
  'fab/do-single': _plus,
  'fab/dont-two': () => docsFlutterDemoRow([
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
  'fab/a11y-name': () => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space8,
    children: [
      // Flutter 의 tooltip 은 라벨이 아니라서 이름은 Semantics 로 붙인다.
      MergeSemantics(
        child: Semantics(
          label: fabPreviewTooltip,
          child: Fab(trigger: const Icon(LucideIcons.plus), onPressed: () {}),
        ),
      ),
      const Text("Semantics(label: '$fabPreviewTooltip')").bodySmall.onSurfaceVariant,
    ],
  ),
};

Widget _fab(Map<String, String> props, String? label) {
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

Widget _plus() => Fab(trigger: const Icon(LucideIcons.plus), onPressed: () {});

Widget _extended(CoreFabSize size) => Fab(
  trigger: const Icon(LucideIcons.plus),
  label: const Text(fabPreviewLabel),
  size: size,
  onPressed: () {},
);

/// 열린 메뉴의 그림 — Web 과 같은 구성. 판과 행은 킷의 `Popup` · `MenuItem`
/// 이고, 값은 Fab 의 기본값을 읽는다.
Widget _openMenu() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.end,
  spacing: CoreFabStyle.defaultSpacing,
  children: [
    Popup(
      popupStyle: CoreFabStyle.defaultPopupStyle,
      children: [for (final action in fabPreviewActions) _menuRow(action)],
    ),
    Fab(trigger: const Icon(LucideIcons.x), onPressed: () {}),
  ],
);

Widget _menuRow(FabPreviewAction action) => MenuItem(
  label: DefaultTextStyle.merge(
    softWrap: false,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    child: Text(action.label),
  ),
  size: CoreFabContract.actionItemSize,
  leading: Icon(action.icon),
  menuItemStyle: CoreFabStyle.defaultActionItemStyle,
  onPressed: () {},
);

/// 상태 장면 — Web 과 같은 여섯 칸. Flutter 의 `Button` 은 누르는 동안 채움을
/// 바꾸지 않으므로 Pressed 칸은 크기만 줄인다.
Widget _states() {
  Widget cell(String caption) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space8,
    children: [
      switch (caption) {
        'Hover' => _filled(CoreColors.primaryHover),
        'Pressed' => Transform.scale(scale: CoreButtonStyle.defaultPressedScale, child: _plus()),
        'Focus' => FocusOutline(focused: true, focusOutlineStyle: _focusRing, child: _plus()),
        '비활성' => const Fab(trigger: Icon(LucideIcons.plus)),
        '열림' => Fab(trigger: const Icon(LucideIcons.x), onPressed: () {}),
        _ => _plus(),
      },
      Text(caption).labelSmall.onSurfaceVariant,
    ],
  );
  return Wrap(
    alignment: WrapAlignment.center,
    spacing: CoreSpace.space24,
    runSpacing: CoreSpace.space24,
    children: [for (final caption in fabStateCaptions) cell(caption)],
  );
}

const CoreFocusOutlineStyle _focusRing = CoreFocusOutlineStyle(
  borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
  offsetColor: CoreFocusRing.opaqueOffsetColor,
);

Widget _filled(CoreColorToken token) => Fab(
  trigger: const Icon(LucideIcons.plus),
  onPressed: () {},
  fabStyle: CoreFabStyle(
    buttonStyle: CoreButtonStyle(backgroundColor: CoreColor.token(token), disableHoverEffect: true),
  ),
);

/// 휴대폰 화면의 아래쪽 — 본문 줄과 끝 모서리의 [corner].
Widget _phone(Widget corner) => Builder(
  builder: (context) {
    final scheme = Theme.of(context).colorScheme;
    Color tone(CoreColorToken token) => scheme.resolve(CoreColor.token(token)).toValue();
    return SizedBox(
      width: 220,
      height: 280,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone(CoreColors.surface),
          border: Border.all(color: tone(CoreColors.outlineVariant)),
          borderRadius: BorderRadius.circular(CoreRadius.radius24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CoreSpace.space16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: CoreSpace.space8,
                children: [
                  for (final width in const [130.0, 186.0])
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: tone(CoreColors.surfaceContainerHigh),
                        borderRadius: BorderRadius.circular(CoreRadius.radius9999),
                      ),
                      child: SizedBox(width: width, height: CoreSpace.space8),
                    ),
                ],
              ),
              Align(alignment: AlignmentDirectional.centerEnd, child: corner),
            ],
          ),
        ),
      ),
    );
  },
);
