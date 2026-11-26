/// Popover 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="popover/...">` 가 읽는다. 같은 이름의 Web 파일(`popover_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 열린 패널은 그림이다. `Popover` 의 패널은 앱의 오버레이에 올라가고, 닫힌
/// 상태로 시작한다 — 패널을 트리거 옆 제자리에 그리는 공개 경로가 없다. 그래서
/// 그림은 패널 상자인 실제 `Popup` 에 `CorePopoverStyle.defaultPanelStyle` 을
/// 넘겨 그리고, 트리거와의 간격은 `CorePopoverStyle.defaultPlacementOffset`
/// 을 쓴다. `CorePopoverTheme` · 화면 가장자리 처리 · 전환은 그림에 없다. 실제
/// `Popover` 는 플레이그라운드의 아래 트리거가 연다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'popover_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _popover;

/// 장면 이름(`popover/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'popover/anatomy': () => _PopoverPicture(content: _content()),
  'popover/constraints': _constraints,
  'popover/do-focused': () => _PopoverPicture(triggerLabel: '정렬', content: _focusedContent()),
  'popover/dont-long-form': () => _PopoverPicture(triggerLabel: '계정 정보 입력', content: _longForm()),
};

Widget _popover(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _PopoverOpener(props: props, label: label);
  return _propPicture(props, label);
}

/// 속성으로 고른 그림. 좁은 카드에서 왼쪽 · 오른쪽 배치가 넘치지 않게 줄인다.
Widget _propPicture(Map<String, String> props, String? label) => FittedBox(
  fit: BoxFit.scaleDown,
  child: _PopoverPicture(
    placement: page.demoPlacementOf(props),
    triggerLabel: label ?? page.demoTrigger,
    content: _content(),
  ),
);

/// 트리거와 열린 패널의 그림 — `placement` 가 가리키는 쪽에 패널을 놓고, 같은
/// 자리(시작 · 가운데 · 끝)로 트리거와 맞춘다.
class _PopoverPicture extends StatelessWidget {
  const _PopoverPicture({
    required this.content,
    this.placement = CorePopoverPlacement.bottom,
    this.triggerLabel = page.demoTrigger,
  });

  final Widget content;
  final CorePopoverPlacement placement;
  final String triggerLabel;

  @override
  Widget build(BuildContext context) {
    final trigger = Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(triggerLabel));
    final panel = _panel(content);
    final children = placement.isTop || placement.isLeft ? <Widget>[panel, trigger] : <Widget>[trigger, panel];
    final cross = _crossAlign(placement);

    if (placement.isTop || placement.isBottom) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: cross,
        spacing: CorePopoverStyle.defaultPlacementOffset,
        children: children,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      spacing: CorePopoverStyle.defaultPlacementOffset,
      children: children,
    );
  }
}

CrossAxisAlignment _crossAlign(CorePopoverPlacement placement) => switch (placement) {
  CorePopoverPlacement.topStart ||
  CorePopoverPlacement.bottomStart ||
  CorePopoverPlacement.leftStart ||
  CorePopoverPlacement.rightStart => CrossAxisAlignment.start,
  CorePopoverPlacement.topEnd ||
  CorePopoverPlacement.bottomEnd ||
  CorePopoverPlacement.leftEnd ||
  CorePopoverPlacement.rightEnd => CrossAxisAlignment.end,
  CorePopoverPlacement.top ||
  CorePopoverPlacement.bottom ||
  CorePopoverPlacement.left ||
  CorePopoverPlacement.right => CrossAxisAlignment.center,
};

/// 패널 상자 — `Popover` 가 패널에 쓰는 것과 같은 `Popup` 과 기본 스타일.
Widget _panel(Widget content) => Popup(popupStyle: CorePopoverStyle.defaultPanelStyle, children: [content]);

Widget _content([String body = page.demoBody]) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space4,
  children: [const Text(page.demoTitle).labelLarge, Text(body).bodySmall.onSurfaceVariant],
);

/// 폭 제약 장면 — 폭이 같은 트리거 아래에 제약마다 짧은 패널과 긴 패널을
/// 놓는다.
Widget _constraints() => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space24,
  children: [
    for (final constraint in page.demoConstraints)
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CorePopoverStyle.defaultPlacementOffset,
        children: [
          SizedBox(
            width: page.demoAnchorWidth,
            child: Button(
              variant: CoreButtonVariant.outline,
              expanded: true,
              onPressed: () {},
              child: Text(constraint.name),
            ),
          ),
          for (final body in const [page.demoShortBody, page.demoLongBody])
            _constrained(constraint, _panel(_content(body))),
        ],
      ),
  ],
);

Widget _constrained(CorePopoverConstraint constraint, Widget panel) => switch (constraint) {
  CorePopoverConstraint.anchorFixedSize => SizedBox(width: page.demoAnchorWidth, child: panel),
  CorePopoverConstraint.anchorMaxSize => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: page.demoAnchorWidth),
    child: panel,
  ),
  CorePopoverConstraint.anchorMinSize => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: page.demoAnchorWidth),
    child: panel,
  ),
  CorePopoverConstraint.flexible || CorePopoverConstraint.intrinsic => panel,
};

// 패널(`Popup`)은 내용의 폭을 먼저 묻는다 — 폭을 정한 `SizedBox` 가 그 답이라,
// 안의 입력창은 폭 질의를 받지 않는다.
Widget _focusedContent() => SizedBox(
  width: page.demoAnchorWidth,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space12,
    children: [
      const Text('정렬 순서').labelLarge,
      const Text('목록에 보일 순서를 고릅니다.').bodySmall.onSurfaceVariant,
      Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('최신순 적용')),
    ],
  ),
);

Widget _longForm() => SizedBox(
  width: page.demoAnchorWidth,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CoreSpace.space12,
    children: [
      for (final label in const ['이름', '이메일', '전화번호']) TextField(label: label),
    ],
  ),
);

/// 플레이그라운드의 미리보기 — 그림 아래에 같은 속성의 실제 `Popover` 를 둔다.
///
/// 그림과 실제 패널의 내용은 코드 상자와 같은 본문 한 줄이다. 컨트롤러는 늘
/// 붙이고, `manual` 이면 트리거 버튼이 `toggle` 을 부른다.
class _PopoverOpener extends StatefulWidget {
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
  Widget build(BuildContext context) {
    final props = widget.props;
    final openTrigger = page.demoOpenTriggerOf(props);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _PopoverPicture(
            placement: page.demoPlacementOf(props),
            triggerLabel: widget.label ?? page.demoTrigger,
            content: const Text(page.demoBody),
          ),
        ),
        const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
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
