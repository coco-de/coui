/// HoverCard 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="hover-card/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`hover_card_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대의 카드는 그림이다. `HoverCard` 의 카드는 열리면 오버레이 호스트의
/// 팝오버 층에 올라가 트리거에 붙는다 — 열린 카드를 그 자리에 그리는 공개
/// 경로가 없다. 그래서 그림은 `HoverCard` 가 쓰는 `resolveHoverCard` 가 낸
/// 판의 모양(`Popup` 의 모양 — 테마 · 서페이스 스타일 포함)으로 카드를 그리고,
/// 위치만 트리거 옆의 flex 상자로 잡는다. 실제 `HoverCard` 는 플레이그라운드의
/// "올려 보기" 버튼이 연다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'hover_card_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _hoverCard;

/// 장면 이름(`hover-card/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'hover-card/anatomy': () => _HoverCardPicture(
    trigger: _trigger(page.demoTrigger),
    content: div(attributes: const {'data-docs-part': 'content'}, [_body(page.demoBody)]),
  ),
  'hover-card/profile': () => _HoverCardPicture(trigger: _trigger(page.demoMention), content: _profile()),
  'hover-card/placements': () => div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'align-items': 'center',
        'justify-content': 'center',
        'gap': spaceCss(CoreSpace.space32),
      },
    ),
    [
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

Component _hoverCard(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _opener(props, label);
  return _propPicture(props, label);
}

/// 속성으로 고른 카드 그림.
Component _propPicture(Map<String, String> props, String? label) => _HoverCardPicture(
  placement: page.demoPlacementOf(props),
  trigger: _trigger(label ?? page.demoTrigger),
  content: _body(page.demoBodyOf(props)),
);

/// 플레이그라운드의 미리보기 — 카드 그림 아래의 버튼이 같은 속성의 실제
/// `HoverCard` 로 감싸져 있다. 포인터를 올리면 열린다.
Component _opener(Map<String, String> props, String? label) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': spaceCss(CoreSpace.space16),
      'width': '100%',
    },
  ),
  [
    _propPicture(props, label),
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

Component _trigger(String label) => Button(variant: CoreButtonVariant.ghost, onPressed: () {}, child: Text(label));

/// 글자 없는 아이콘 버튼 — 이름을 `aria-label` 로 준다.
Component _iconTrigger(IconName icon, String name) => Button(
  variant: CoreButtonVariant.outline,
  shape: CoreButtonShape.square,
  attributes: {'aria-label': name},
  onPressed: () {},
  child: Icon(icon),
);

Component _body(String text) => Text(text).bodySmall.onSurface;

/// 세로로 쌓는 카드 내용.
Component _column(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'flex-start',
      'gap': spaceCss(CoreSpace.space8),
    },
  ),
  children,
);

Component _profile() => _column([
  Avatar(initials: page.demoProfileInitials),
  const Text(page.demoProfileName).titleSmall.onSurface,
  const Text(page.demoProfileRole).bodySmall.onSurfaceVariant,
  const Text(page.demoProfileStats).labelSmall.onSurfaceVariant,
]);

Component _linkPreview() => _column([
  const Text(page.demoLinkTitle).titleSmall.onSurface,
  const Text(page.demoLinkSummary).bodySmall.onSurfaceVariant,
]);

Component _form() => div(
  styles: Styles(raw: {'width': pinnedLengthCss(CoreSpace.space192)}),
  [
    _column([
      const TextField(label: page.demoFormLabel),
      Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text(page.demoFormSave)),
    ]),
  ],
);

/// 카드 그림 — 판의 모양은 `resolveHoverCard` 가 낸 것(`HoverCard` 가 여는
/// 카드와 같은 `Popup` 모양), 트리거와의 거리는 `placementOffset` 이다. 부분마다
/// `data-docs-part` 를 달아 구조 블록이 번호를 붙인다.
class _HoverCardPicture extends StatelessComponent {
  const _HoverCardPicture({
    required this.trigger,
    required this.content,
    this.placement = CorePopoverPlacement.bottom,
  });

  final Component trigger;
  final Component content;
  final CorePopoverPlacement placement;

  @override
  Component build(BuildContext context) {
    final resolved = resolveHoverCard(context: context);
    final offset =
        context.theme.coreComponentTheme?.hoverCard?.style?.placementOffset ??
        CoreHoverCardStyle.defaultPlacementOffset;
    final panel = div(classes: resolved.motion.className, [
      div(
        attributes: const {'data-docs-part': 'panel'},
        classes: resolved.bubble.className,
        styles: resolved.bubble.inlineStyles,
        [content],
      ),
    ]);
    final target = div(
      attributes: const {'data-docs-part': 'trigger'},
      classes: resolved.trigger.className,
      [trigger],
    );
    final panelFirst = page.demoPanelFirst(placement);
    return div(
      styles: Styles(
        raw: {
          'display': 'inline-flex',
          'flex-direction': page.demoIsVertical(placement) ? 'column' : 'row',
          'align-items': 'center',
          'gap': pinnedLengthCss(offset),
        },
      ),
      panelFirst ? [panel, target] : [target, panel],
    );
  }
}
