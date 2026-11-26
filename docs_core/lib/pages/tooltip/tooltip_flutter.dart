/// Tooltip 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="tooltip/...">` 가 읽는다. 같은 이름의 Web 파일(`tooltip_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대의 말풍선은 그림이다. `Tooltip` 은 포인터를 올려야 열리고, 말풍선은
/// 루트 `Overlay` 에 올라가 트리거에 붙는다 — 열린 말풍선을 그 자리에 그리는
/// 공개 경로가 없다. 그래서 그림은 `Tooltip` 이 쓰는 `resolveTooltip` 이 낸
/// 값(테마 · 서페이스 스타일 포함)으로 말풍선을 그리고, 위치만 트리거 옆의
/// `Row` · `Column` 으로 잡는다. 꼬리를 그리는 위젯은 공개되지 않아 같은
/// 모양으로 다시 그린다. 실제 `Tooltip` 은 플레이그라운드의 "올려 보기" 버튼이
/// 연다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'tooltip_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _tooltip;

/// 장면 이름(`tooltip/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
  'tooltip/do-visible-text': () => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: CoreSpace.space240),
    child: TextField(label: page.demoFieldLabel, description: page.demoRule),
  ),
  'tooltip/dont-hidden-rule': () => _TooltipPicture(
    message: page.demoRule,
    trigger: _iconTrigger(LucideIcons.info, page.demoRuleName),
  ),
  'tooltip/dont-interactive': () => _TooltipPicture(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space8,
      children: [
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

Widget _tooltip(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _opener(props, label);
  return _propPicture(props, label);
}

/// 속성으로 고른 말풍선 그림.
Widget _propPicture(Map<String, String> props, String? label) => _TooltipPicture(
  message: page.demoMessageOf(props, label),
  position: page.demoPositionOf(props),
  style: page.demoStyleOf(props),
  trigger: _textTrigger(),
);

/// 플레이그라운드의 미리보기 — 말풍선 그림 아래의 버튼이 같은 속성의 실제
/// `Tooltip` 으로 감싸져 있다. 포인터를 올리면 열린다.
Widget _opener(Map<String, String> props, String? label) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    _propPicture(props, label),
    const Gap(gapStyle: CoreGapStyle(size: page.demoOpenerGap)),
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

Widget _textTrigger() => Button(
  variant: CoreButtonVariant.outline,
  onPressed: () {},
  child: const Text(page.demoTrigger),
);

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

/// 아이콘과 두 줄 글 — 아이콘 색은 직접 주고, 글은 말풍선의 글자 스타일을
/// 이어받도록 글자 역할을 정하는 체인(`.bodySmall` 류)을 쓰지 않는다.
Widget _richContent() => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    const Icon(LucideIcons.keyboard, iconStyle: page.demoBubbleIconStyle),
    const Gap.space8(),
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(page.demoRichTitle).semiBold,
        const Text(page.demoRichShortcut),
      ],
    ),
  ],
);

/// 말풍선 그림 — `resolveTooltip` 이 낸 값으로 `Tooltip` 과 같은 순서로 쌓는다
/// (바탕 · 라벨 글자 → 폭 상한 → 꼬리 → 서페이스 재질). 트리거와의 거리는 낸
/// 값의 `gap` 이다.
class _TooltipPicture extends StatelessWidget {
  const _TooltipPicture({
    required this.trigger,
    this.message = page.demoMessage,
    this.content,
    this.position = CoreTooltipPosition.top,
    this.style,
  });

  final Widget trigger;
  final String message;
  final Widget? content;
  final CoreTooltipPosition position;
  final CoreTooltipStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTooltip(context, tooltipStyle: style);
    final opacity = resolved.surfaceOpacity;
    final fill = opacity == null ? resolved.backgroundColor : resolved.backgroundColor.withValues(alpha: opacity);
    Widget bubble = Container(
      padding: resolved.padding,
      decoration: BoxDecoration(color: fill, borderRadius: resolved.borderRadius),
      child: DefaultTextStyle.merge(style: resolved.labelTextStyle, child: content ?? Text(message)),
    );
    final maxWidth = resolved.panelMaxWidth;
    if (maxWidth != null) {
      bubble = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: bubble,
      );
    }
    if (resolved.tailWidth > 0 && resolved.tailHeight > 0) {
      bubble = Stacks(
        clipBehavior: CoreClipBehavior.none,
        children: [
          bubble,
          Position.fill(
            child: _TailPicture(
              position: position,
              color: fill,
              base: resolved.tailWidth,
              protrusion: resolved.tailHeight,
            ),
          ),
        ],
      );
    }
    final blur = resolved.surfaceBlur;
    if ((blur != null && blur > 0) || resolved.surfaceSheen != null) {
      bubble = SurfaceBlur(
        borderRadius: resolved.borderRadius,
        surfaceBlur: blur,
        surfaceSaturation: resolved.surfaceSaturation,
        surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
        surfaceSheen: resolved.surfaceSheen,
        refraction: Theme.of(context).surfaceRefraction,
        child: bubble,
      );
    }
    final vertical = position == CoreTooltipPosition.top || position == CoreTooltipPosition.bottom;
    final bubbleFirst = position == CoreTooltipPosition.top || position == CoreTooltipPosition.left;
    final children = bubbleFirst ? [bubble, trigger] : [trigger, bubble];
    return vertical
        ? Column(mainAxisSize: MainAxisSize.min, spacing: resolved.gap, children: children)
        : Row(mainAxisSize: MainAxisSize.min, spacing: resolved.gap, children: children);
  }
}

/// 말풍선에서 트리거 쪽 변의 가운데에 삼각형을 놓는다.
class _TailPicture extends StatelessWidget {
  const _TailPicture({required this.position, required this.color, required this.base, required this.protrusion});

  final CoreTooltipPosition position;
  final Color color;
  final double base;
  final double protrusion;

  @override
  Widget build(BuildContext context) {
    final vertical = position == CoreTooltipPosition.top || position == CoreTooltipPosition.bottom;
    final (alignment, offset) = switch (position) {
      CoreTooltipPosition.top => (Alignment.bottomCenter, Offset(0, protrusion)),
      CoreTooltipPosition.bottom => (Alignment.topCenter, Offset(0, -protrusion)),
      CoreTooltipPosition.left => (Alignment.centerRight, Offset(protrusion, 0)),
      CoreTooltipPosition.right => (Alignment.centerLeft, Offset(-protrusion, 0)),
    };
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: CustomPaint(
          size: vertical ? Size(base, protrusion) : Size(protrusion, base),
          painter: _TailPainter(position: position, color: color),
        ),
      ),
    );
  }
}

/// 밑변이 말풍선에 닿고 끝이 트리거를 가리키는 삼각형.
class _TailPainter extends CustomPainter {
  const _TailPainter({required this.position, required this.color});

  final CoreTooltipPosition position;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final points = switch (position) {
      CoreTooltipPosition.top => [Offset.zero, Offset(size.width, 0), Offset(size.width / 2, size.height)],
      CoreTooltipPosition.bottom => [
        Offset(size.width / 2, 0),
        Offset(size.width, size.height),
        Offset(0, size.height),
      ],
      CoreTooltipPosition.left => [Offset.zero, Offset(size.width, size.height / 2), Offset(0, size.height)],
      CoreTooltipPosition.right => [
        Offset(size.width, 0),
        Offset(size.width, size.height),
        Offset(0, size.height / 2),
      ],
    };
    canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.position != position || oldDelegate.color != color;
}
