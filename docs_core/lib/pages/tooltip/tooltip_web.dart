/// Tooltip 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="tooltip/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`tooltip_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대의 말풍선은 그림이다. `Tooltip` 은 포인터를 올려야 열리고, 말풍선은
/// 오버레이 호스트의 툴팁 층에 올라가 트리거에 붙는다 — 열린 말풍선을 그
/// 자리에 그리는 공개 경로가 없다. 그래서 그림은 `Tooltip` 이 쓰는
/// `resolveTooltip`(테마 · 서페이스 스타일 포함)으로 말풍선과 꼬리를 그리고,
/// 위치만 트리거 옆의 flex 상자로 잡는다. 실제 `Tooltip` 은 플레이그라운드의
/// "올려 보기" 버튼이 연다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'tooltip_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _tooltip;

/// 장면 이름(`tooltip/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'tooltip/anatomy': () => _TooltipPicture(trigger: _textTrigger(), style: page.demoTailStyle),
  'tooltip/tail': () => _TooltipPicture(
    position: CoreTooltipPosition.bottom,
    style: page.demoTailStyle,
    trigger: _textTrigger(),
  ),
  'tooltip/long': () => _TooltipPicture(
    message: page.demoLongMessage,
    style: const CoreTooltipStyle(panelMaxWidth: page.demoMaxWidth),
    trigger: _iconTrigger(LucideIcons.info, page.demoImageHelpName),
  ),
  'tooltip/rich': () => _TooltipPicture(
    content: _richContent(),
    trigger: _iconTrigger(LucideIcons.undo2, page.demoRichTitle),
  ),
  'tooltip/do-icon-name': () => _TooltipPicture(trigger: _iconTrigger(LucideIcons.link, page.demoMessage)),
  'tooltip/dont-repeat': () => _TooltipPicture(
    message: page.demoSave,
    trigger: Button(onPressed: () {}, child: const Text(page.demoSave)),
  ),
  'tooltip/do-short': () => _TooltipPicture(
    message: page.demoShortMessage,
    trigger: _iconTrigger(LucideIcons.undo2, page.demoRichTitle),
  ),
  'tooltip/dont-long': () => _TooltipPicture(
    message: page.demoTooLongMessage,
    style: const CoreTooltipStyle(panelMaxWidth: CoreSpace.space192),
    trigger: _iconTrigger(LucideIcons.undo2, page.demoRichTitle),
  ),
  'tooltip/do-visible-text': () => div(
    styles: Styles(raw: {'width': 'min(100%, ${pinnedLengthCss(CoreSpace.space240)})'}),
    [const TextField(label: page.demoFieldLabel, description: page.demoRule)],
  ),
  'tooltip/dont-hidden-rule': () => _TooltipPicture(
    message: page.demoRule,
    trigger: _iconTrigger(LucideIcons.info, page.demoRuleName),
  ),
  'tooltip/dont-interactive': () => _TooltipPicture(
    content: div(
      styles: Styles(
        raw: {
          'display': 'flex',
          'flex-direction': 'column',
          'align-items': 'center',
          'gap': spaceCss(CoreSpace.space8),
        },
      ),
      [
        const Text(page.demoBubbleQuestion),
        Button(
          variant: CoreButtonVariant.secondary,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Text(page.demoBubbleAction),
        ),
      ],
    ),
    trigger: _iconTrigger(LucideIcons.trash2, page.demoBubbleAction),
  ),
};

Component _tooltip(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _opener(props, label);
  return _propPicture(props, label);
}

/// 속성으로 고른 말풍선 그림.
Component _propPicture(Map<String, String> props, String? label) => _TooltipPicture(
  message: page.demoMessageOf(props, label),
  position: page.demoPositionOf(props),
  style: page.demoStyleOf(props),
  trigger: _textTrigger(),
);

/// 플레이그라운드의 미리보기 — 말풍선 그림 아래의 버튼이 같은 속성의 실제
/// `Tooltip` 으로 감싸져 있다. 포인터를 올리면 열린다.
Component _opener(Map<String, String> props, String? label) => div(
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
    _propPicture(props, label),
    Tooltip(
      message: page.demoMessageOf(props, label),
      position: page.demoPositionOf(props),
      waitDuration: page.demoWaitOf(props),
      tooltipStyle: page.demoStyleOf(props),
      child: Button(
        variant: CoreButtonVariant.outline,
        size: CoreComponentSize.sm,
        onPressed: () {},
        child: const Text(page.demoOpener),
      ),
    ),
  ],
);

Component _textTrigger() => Button(
  variant: CoreButtonVariant.outline,
  onPressed: () {},
  child: const Text(page.demoTrigger),
);

/// 글자 없는 아이콘 버튼 — 이름을 `aria-label` 로 준다.
Component _iconTrigger(IconName icon, String name) => Button(
  variant: CoreButtonVariant.outline,
  shape: CoreButtonShape.square,
  attributes: {'aria-label': name},
  onPressed: () {},
  child: Icon(icon),
);

/// 아이콘과 두 줄 글 — 아이콘 색은 직접 주고, 글은 말풍선의 글자 스타일을 이어받는다.
Component _richContent() => div(
  styles: Styles(raw: {'display': 'flex', 'align-items': 'center', 'gap': spaceCss(CoreSpace.space8)}),
  [
    const Icon(LucideIcons.keyboard, iconStyle: page.demoBubbleIconStyle),
    div(styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column'}), [
      const Text(page.demoRichTitle).semiBold,
      const Text(page.demoRichShortcut),
    ]),
  ],
);

/// 말풍선 그림 — 말풍선 · 꼬리의 모양은 `resolveTooltip` 이 낸 값, 트리거와의
/// 거리는 `placementOffset` 이다. 부분마다 `data-docs-part` 를 달아 구조 블록이
/// 번호를 붙인다.
class _TooltipPicture extends StatelessComponent {
  const _TooltipPicture({
    required this.trigger,
    this.message = page.demoMessage,
    this.content,
    this.position = CoreTooltipPosition.top,
    this.style,
  });

  final Component trigger;
  final String message;
  final Component? content;
  final CoreTooltipPosition position;
  final CoreTooltipStyle? style;

  @override
  Component build(BuildContext context) {
    final resolved = resolveTooltip(
      context,
      didEnter: true,
      activeDurationMs: CoreTooltipContract.defaultOpenAnimationDuration.inMilliseconds,
      placement: switch (position) {
        CoreTooltipPosition.top => CorePopoverPlacement.top,
        CoreTooltipPosition.bottom => CorePopoverPlacement.bottom,
        CoreTooltipPosition.left => CorePopoverPlacement.left,
        CoreTooltipPosition.right => CorePopoverPlacement.right,
      },
      tooltipStyle: style,
    );
    final bubble = div(
      attributes: const {'data-docs-part': 'bubble'},
      classes: resolved.bubble.className,
      styles: resolved.bubble.inlineStyles,
      [
        span(
          attributes: const {'data-docs-part': 'label'},
          styles: resolved.label?.inlineStyles,
          [content ?? Text(message)],
        ),
        if (resolved.tail case final tail?)
          div(
            attributes: const {'data-docs-part': 'tail'},
            classes: tail.className,
            styles: tail.inlineStyles,
            const [],
          ),
      ],
    );
    final target = div(attributes: const {'data-docs-part': 'trigger'}, [trigger]);
    final vertical = position == CoreTooltipPosition.top || position == CoreTooltipPosition.bottom;
    final bubbleFirst = position == CoreTooltipPosition.top || position == CoreTooltipPosition.left;
    final offset =
        style?.placementOffset ??
        context.theme.coreComponentTheme?.tooltip?.style?.placementOffset ??
        CoreTooltipStyle.defaultPlacementOffset;
    return div(
      styles: Styles(
        raw: {
          'display': 'inline-flex',
          'flex-direction': vertical ? 'column' : 'row',
          'align-items': 'center',
          'gap': pinnedLengthCss(offset),
        },
      ),
      bubbleFirst ? [bubble, target] : [target, bubble],
    );
  }
}
