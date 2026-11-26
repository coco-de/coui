/// HoverCard 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="hover-card/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`hover_card_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대의 카드는 그림이다. `HoverCard` 의 카드는 열리면 루트 `Overlay` 에
/// 올라가 트리거에 붙는다 — 열린 카드를 그 자리에 그리는 공개 경로가 없다.
/// 그래서 그림은 `HoverCard` 가 여는 카드와 같은 `Popup` 에 `resolveHoverCard`
/// 가 낸 `panelStyle`(테마 포함)을 넘겨 그리고, 위치만 트리거 옆의 `Row` ·
/// `Column` 으로 잡는다. 실제 `HoverCard` 는 플레이그라운드의 "올려 보기"
/// 버튼이 연다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'hover_card_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _hoverCard;

/// 장면 이름(`hover-card/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'hover-card/anatomy': () => _HoverCardPicture(trigger: _trigger(page.demoTrigger), content: _body(page.demoBody)),
  'hover-card/profile': () => _HoverCardPicture(trigger: _trigger(page.demoMention), content: _profile()),
  'hover-card/placements': () => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: CoreSpace.space32,
    runSpacing: CoreSpace.space32,
    children: [
      for (final placement in page.demoSides)
        _HoverCardPicture(placement: placement, trigger: _trigger(placement.name), content: _body(page.demoSideBody)),
    ],
  ),
  'hover-card/dont-only-action': () => _HoverCardPicture(
    trigger: _iconTrigger(LucideIcons.settings, page.demoSettingsName),
    content: Button(
      variant: CoreButtonVariant.destructive,
      size: CoreComponentSize.sm,
      onPressed: () {},
      child: const Text(page.demoOnlyAction),
    ),
  ),
  'hover-card/link-preview': () => _HoverCardPicture(trigger: _trigger(page.demoLinkTitle), content: _linkPreview()),
  'hover-card/dont-form': () => _HoverCardPicture(trigger: _trigger(page.demoFormTrigger), content: _form()),
};

Widget _hoverCard(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _opener(props, label);
  return _propPicture(props, label);
}

/// 속성으로 고른 카드 그림.
Widget _propPicture(Map<String, String> props, String? label) => _HoverCardPicture(
  placement: page.demoPlacementOf(props),
  trigger: _trigger(label ?? page.demoTrigger),
  content: _body(page.demoBodyOf(props)),
);

/// 플레이그라운드의 미리보기 — 카드 그림 아래의 버튼이 같은 속성의 실제
/// `HoverCard` 로 감싸져 있다. 포인터를 올리면 열린다.
Widget _opener(Map<String, String> props, String? label) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    _propPicture(props, label),
    const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
    HoverCard(
      placement: page.demoPlacementOf(props),
      openDelay: page.demoOpenDelayOf(props),
      trigger: Button(
        variant: CoreButtonVariant.outline,
        size: CoreComponentSize.sm,
        onPressed: () {},
        child: const Text(page.demoOpener),
      ),
      content: _body(page.demoBodyOf(props)),
    ),
  ],
);

Widget _trigger(String label) => Button(variant: CoreButtonVariant.ghost, onPressed: () {}, child: Text(label));

/// 글자 없는 아이콘 버튼 — 이름을 `Semantics` 로 준다.
Widget _iconTrigger(IconName icon, String name) => Semantics(
  label: name,
  child: Button(
    variant: CoreButtonVariant.outline,
    shape: CoreButtonShape.square,
    onPressed: () {},
    child: Icon(icon),
  ),
);

Widget _body(String text) => Text(text).bodySmall.onSurface;

/// 세로로 쌓는 카드 내용.
Widget _column(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space8,
  children: children,
);

Widget _profile() => _column([
  const Avatar(initials: page.demoProfileInitials),
  const Text(page.demoProfileName).titleSmall.onSurface,
  const Text(page.demoProfileRole).bodySmall.onSurfaceVariant,
  const Text(page.demoProfileStats).labelSmall.onSurfaceVariant,
]);

Widget _linkPreview() => _column([
  const Text(page.demoLinkTitle).titleSmall.onSurface,
  const Text(page.demoLinkSummary).bodySmall.onSurfaceVariant,
]);

/// 카드는 내용의 폭을 미리 재어 폭을 정하므로 입력창의 폭을 여기서 정한다.
Widget _form() => SizedBox(
  width: CoreSpace.space192,
  child: _column([
    TextField(label: page.demoFormLabel),
    Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text(page.demoFormSave)),
  ]),
);

/// 카드 그림 — `HoverCard` 가 여는 카드와 같은 `Popup` 이고, 트리거와의 거리는
/// `resolveHoverCard` 가 낸 `panelOffset` 의 길이다.
class _HoverCardPicture extends StatelessWidget {
  const _HoverCardPicture({
    required this.trigger,
    required this.content,
    this.placement = CorePopoverPlacement.bottom,
  });

  final Widget trigger;
  final Widget content;
  final CorePopoverPlacement placement;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveHoverCard(context, placement: placement);
    final panel = Popup(popupStyle: resolved.panelStyle, children: [content]);
    final gap = resolved.panelOffset.distance;
    final children = page.demoPanelFirst(placement) ? [panel, trigger] : [trigger, panel];
    return page.demoIsVertical(placement)
        ? Column(mainAxisSize: MainAxisSize.min, spacing: gap, children: children)
        : Row(mainAxisSize: MainAxisSize.min, spacing: gap, children: children);
  }
}
