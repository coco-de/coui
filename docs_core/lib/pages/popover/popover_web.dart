/// Popover 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="popover/...">` 가 읽는다. 같은 이름의 Flutter 파일(`popover_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 열린 패널은 그림이다. `Popover` 의 패널은 오버레이 호스트로 올라가고, 닫힌
/// 상태로 시작한다 — 패널을 트리거 옆 제자리에 그리는 공개 경로가 없다. 그래서
/// 그림은 패널 상자인 실제 `Popup` 에 `CorePopoverStyle.defaultPanelStyle` 을
/// 넘겨 그리고, 트리거와의 간격은 `CorePopoverStyle.defaultPlacementOffset`
/// 을 쓴다. `CorePopoverTheme` · 화면 가장자리 처리 · 전환은 그림에 없다. 실제
/// `Popover` 는 플레이그라운드의 아래 트리거가 연다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'popover_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _popover;

/// 장면 이름(`popover/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'popover/anatomy': () => _picture(content: _content()),
  'popover/constraints': _constraints,
  'popover/do-focused': () => _picture(triggerLabel: '정렬', content: _focusedContent()),
  'popover/dont-long-form': () => _picture(triggerLabel: '계정 정보 입력', content: _longForm()),
};

Component _popover(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _PopoverOpener(props: props, label: label);
  return _propPicture(props, label);
}

/// 속성으로 고른 그림.
Component _propPicture(Map<String, String> props, String? label) => _picture(
  placement: page.demoPlacementOf(props),
  triggerLabel: label ?? page.demoTrigger,
  content: _content(),
);

/// 트리거와 열린 패널의 그림 — `placement` 가 가리키는 쪽에 패널을 놓고, 같은
/// 자리(시작 · 가운데 · 끝)로 트리거와 맞춘다. 부분마다 `data-docs-part` 를 달아
/// 구조 블록이 번호를 붙인다.
Component _picture({
  required Component content,
  CorePopoverPlacement placement = CorePopoverPlacement.bottom,
  String triggerLabel = page.demoTrigger,
}) {
  final trigger = div(
    attributes: const {'data-docs-part': 'trigger'},
    styles: Styles(raw: {'display': 'inline-flex'}),
    [Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(triggerLabel))],
  );
  final panel = _panel(content);
  final panelFirst = placement.isTop || placement.isLeft;
  return div(
    styles: Styles(
      raw: {
        'display': 'inline-flex',
        'flex-direction': placement.isTop || placement.isBottom ? 'column' : 'row',
        'align-items': _crossAlign(placement),
        'gap': pinnedLengthCss(CorePopoverStyle.defaultPlacementOffset),
      },
    ),
    panelFirst ? [panel, trigger] : [trigger, panel],
  );
}

String _crossAlign(CorePopoverPlacement placement) => switch (placement) {
  CorePopoverPlacement.topStart ||
  CorePopoverPlacement.bottomStart ||
  CorePopoverPlacement.leftStart ||
  CorePopoverPlacement.rightStart => 'flex-start',
  CorePopoverPlacement.topEnd ||
  CorePopoverPlacement.bottomEnd ||
  CorePopoverPlacement.leftEnd ||
  CorePopoverPlacement.rightEnd => 'flex-end',
  CorePopoverPlacement.top ||
  CorePopoverPlacement.bottom ||
  CorePopoverPlacement.left ||
  CorePopoverPlacement.right => 'center',
};

/// 패널 상자 — `Popover` 가 패널에 쓰는 것과 같은 `Popup` 과 기본 스타일. `Popup` 의
/// 기본 `role="menu"` 는 그림에 맞지 않아 뺀다.
Component _panel(Component content) => Popup(
  popupStyle: CorePopoverStyle.defaultPanelStyle,
  attributes: const {'role': 'presentation', 'data-docs-part': 'panel'},
  children: [content],
);

Component _content({String body = page.demoBody}) => div(
  attributes: const {'data-docs-part': 'content'},
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space4)}),
  [Text(page.demoTitle).labelLarge, Text(body).bodySmall.onSurfaceVariant],
);

/// 폭 제약 장면 — 폭이 같은 트리거 아래에 제약마다 짧은 패널과 긴 패널을
/// 놓는다.
Component _constraints() {
  final anchor = pinnedLengthCss(page.demoAnchorWidth);
  return div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'justify-content': 'center',
        'align-items': 'flex-start',
        'gap': spaceCss(CoreSpace.space24),
      },
    ),
    [
      for (final constraint in page.demoConstraints)
        div(
          styles: Styles(
            raw: {
              'display': 'flex',
              'flex-direction': 'column',
              'align-items': 'flex-start',
              'gap': pinnedLengthCss(CorePopoverStyle.defaultPlacementOffset),
            },
          ),
          [
            div(styles: Styles(raw: {'width': anchor}), [
              Button(
                variant: CoreButtonVariant.outline,
                expanded: true,
                onPressed: () {},
                child: Text(constraint.name),
              ),
            ]),
            for (final body in const [page.demoShortBody, page.demoLongBody])
              div(styles: Styles(raw: _constraintStyles(constraint, anchor)), [
                _panel(_content(body: body)),
              ]),
          ],
        ),
    ],
  );
}

Map<String, String> _constraintStyles(CorePopoverConstraint constraint, String anchor) => switch (constraint) {
  CorePopoverConstraint.anchorFixedSize => {'width': anchor},
  CorePopoverConstraint.anchorMaxSize => {'max-width': anchor},
  CorePopoverConstraint.anchorMinSize => {'min-width': anchor},
  CorePopoverConstraint.flexible || CorePopoverConstraint.intrinsic => <String, String>{},
};

Component _focusedContent() => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'flex-start',
      'gap': spaceCss(CoreSpace.space12),
      'width': pinnedLengthCss(page.demoAnchorWidth),
    },
  ),
  [
    Text('정렬 순서').labelLarge,
    Text('목록에 보일 순서를 고릅니다.').bodySmall.onSurfaceVariant,
    Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('최신순 적용')),
  ],
);

Component _longForm() => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': spaceCss(CoreSpace.space12),
      'width': pinnedLengthCss(page.demoAnchorWidth),
    },
  ),
  [
    for (final label in const ['이름', '이메일', '전화번호']) TextField(label: label),
  ],
);

/// 플레이그라운드의 미리보기 — 그림 아래에 같은 속성의 실제 `Popover` 를 둔다.
///
/// 그림과 실제 패널의 내용은 코드 상자와 같은 본문 한 줄이다. 컨트롤러는 늘
/// 붙이고, `manual` 이면 트리거 버튼이 `toggle` 을 부른다.
class _PopoverOpener extends StatefulComponent {
  const _PopoverOpener({required this.props, required this.label});

  final Map<String, String> props;
  final String? label;

  @override
  State<_PopoverOpener> createState() => _PopoverOpenerState();
}

class _PopoverOpenerState extends State<_PopoverOpener> {
  final _controller = PopoverController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final props = component.props;
    final openTrigger = page.demoOpenTriggerOf(props);
    return div(
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
        _picture(
          placement: page.demoPlacementOf(props),
          triggerLabel: component.label ?? page.demoTrigger,
          content: const Text(page.demoBody),
        ),
        Popover(
          controller: _controller,
          placement: page.demoPlacementOf(props),
          openTrigger: openTrigger,
          modal: page.demoModalOf(props),
          trigger: Button(
            variant: CoreButtonVariant.outline,
            size: CoreComponentSize.sm,
            onPressed: openTrigger == CorePopoverTrigger.manual ? _controller.toggle : () {},
            child: Text(page.demoOpenerLabel(openTrigger)),
          ),
          content: const Text(page.demoBody),
        ),
      ],
    );
  }
}
