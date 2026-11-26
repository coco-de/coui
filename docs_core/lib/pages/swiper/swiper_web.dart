/// Swiper 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="swiper/...">` 가 읽는다. 같은 이름의 Flutter 파일(`swiper_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 열린 패널은 그림이다. `Swiper` 의 패널은 `openDrawer` 가 오버레이 호스트로
/// 올려 화면을 덮고, 웹의 `Drawer` 위젯은 혼자서는 아무것도 그리지 않는다. 처음
/// 그릴 때의 `open: true` 도 패널을 열지 않는다. 그래서 그림은 작은 화면 상자
/// 안에 `Drawer` 가 패널에 쓰는 것과 같은 모양(`resolveDrawer`)을 놓는다.
/// `Swiper` 가 `variant` 에 따라 주는 `CoreSwiperStyle.defaultsByVariant` 를
/// 넘기므로 `CoreDrawerTheme` 과 서페이스 스타일은 그림에 닿고, `CoreSwiperTheme`
/// 과 전환은 그림에 없다. 실제 `Swiper` 는 플레이그라운드의 그림 아래에 있다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'swiper_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _swiper;

/// 장면 이름(`swiper/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'swiper/anatomy': () => _anatomyInset(const _SwiperPicture()),
  'swiper/do-button': () => _closedSwiper(openButton: true),
  'swiper/dont-gesture-only': () => _closedSwiper(openButton: false),
  'swiper/do-close': () => const _SwiperPicture(position: CoreSwiperPosition.bottom),
  'swiper/dont-no-close': () => const _SwiperPicture(position: CoreSwiperPosition.bottom, close: false),
};

/// 구조 장면의 상자 — 위 여백은 맨 위 부품에 붙는 번호가 무대 윗선에 걸치지 않게
/// 하고, 폭은 좁은 화면에서 왼쪽 번호의 자리를 남기고 줄어든다.
Component _anatomyInset(Component picture) => div(
  styles: Styles(
    raw: {
      'width': 'min(${pinnedLengthCss(page.demoScreenWidth)}, calc(100vw - ${pinnedLengthCss(CoreSpace.space128)}))',
      'padding-top': spaceCss(CoreSpace.space12),
    },
  ),
  [picture],
);

Component _swiper(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _SwiperOpener(props: props);
  return _propPicture(props);
}

/// 속성으로 고른 열린 상태의 그림. [height] 는 플레이그라운드만 낮춘다.
Component _propPicture(Map<String, String> props, {double height = page.demoScreenHeight}) => _SwiperPicture(
  position: page.demoPositionOf(props),
  variant: page.demoVariantOf(props),
  showDragHandle: page.demoShowDragHandleOf(props),
  height: height,
);

/// 닫힌 실제 `Swiper` — `child` 만 보인다.
Component _closedSwiper({required bool openButton}) => Swiper(
  overlayContent: _menu(null),
  child: _swipeArea(CoreSwiperPosition.defaultPosition, onOpen: openButton ? () {} : null),
);

/// 패널의 내용 — 플레이그라운드 코드의 `overlayContent` 와 같다. [onClose] 가
/// 없으면 닫기 버튼을 뺀다.
Component _menu(void Function()? onClose) => div(
  classes: 'flex flex-col items-start gap-${CoreSpace.scale.space8}',
  [
    const Text(page.demoFirstItem),
    const Text(page.demoSecondItem),
    if (onClose != null)
      Button(
        variant: CoreButtonVariant.outline,
        size: CoreComponentSize.sm,
        onPressed: onClose,
        child: const Text(page.demoClose),
      ),
  ],
);

/// 감싼 영역 — 플레이그라운드 코드의 `child` 와 같다. [onOpen] 이 없으면 여는
/// 버튼을 뺀다. `select-none` 은 마우스로 밀 때 글자가 선택되지 않게 한다.
Component _swipeArea(CoreSwiperPosition position, {void Function()? onOpen}) => Card(
  variant: CoreCardVariant.outlined,
  classes: 'select-none',
  css: Styles(raw: {'width': pinnedLengthCss(page.demoAreaWidth), 'max-width': '100%'}),
  child: div(
    classes: 'flex flex-col items-center gap-${CoreSpace.scale.space12}',
    [
      Text(page.demoHint(position)).bodySmall,
      if (onOpen != null) Button(size: CoreComponentSize.sm, onPressed: onOpen, child: const Text(page.demoOpen)),
    ],
  ),
);

/// 열린 상태의 그림 — 작은 화면 상자에 뒤 화면, 배경막, 패널을 차례로 쌓는다.
/// `drawer` variant 는 뒤 화면을 줄인다. 부분마다 `data-docs-part` 를 달아 구조
/// 블록이 번호를 붙인다.
class _SwiperPicture extends StatelessComponent {
  const _SwiperPicture({
    this.position = CoreSwiperPosition.defaultPosition,
    this.variant = CoreSwiperVariant.defaultVariant,
    this.showDragHandle = true,
    this.close = true,
    this.height = page.demoScreenHeight,
  });

  final CoreSwiperPosition position;
  final CoreSwiperVariant variant;
  final bool showDragHandle;
  final bool close;
  final double height;

  @override
  Component build(BuildContext context) {
    final side = page.demoSideOf(position);
    final style = page.demoPictureStyle(variant);
    final drawer = resolveDrawer(context, side: side, open: true, dragDelta: 0, draggable: false, drawerStyle: style);
    final zoom = variant == CoreSwiperVariant.drawer;
    final scale = zoom ? style.backdropScale ?? CoreDrawerStyle.defaultBackdropScale : 1;
    final corner = zoom
        ? style.backdropCornerRadius ?? CoreDrawerStyle.defaultBackdropCornerRadius
        : CoreBorderRadius.zero;
    // 뒤 화면의 감싼 영역은 패널의 반대쪽에 둔다.
    final (justify, align) = switch (side) {
      CoreDrawerSide.left => ('flex-end', 'center'),
      CoreDrawerSide.right => ('flex-start', 'center'),
      CoreDrawerSide.top => ('center', 'flex-end'),
      CoreDrawerSide.bottom => ('center', 'flex-start'),
    };

    final handle = showDragHandle
        ? div(
            attributes: const {'aria-hidden': 'true'},
            classes: drawer.handle.className,
            styles: drawer.handle.inlineStyles,
            [
              div(
                attributes: const {'data-docs-part': 'handle'},
                classes: drawer.handlePill.className,
                styles: drawer.handlePill.inlineStyles,
                const [],
              ),
            ],
          )
        : null;
    final content = div(
      classes: drawer.content.className,
      styles: drawer.content.inlineStyles,
      [
        div(
          attributes: const {'data-docs-part': 'overlayContent'},
          [_menu(close ? () {} : null)],
        ),
      ],
    );
    final sidePanel = side == CoreDrawerSide.left || side == CoreDrawerSide.right;
    final panel = div(
      attributes: const {'data-docs-part': 'panel'},
      classes: drawer.panel.className,
      styles: drawer.panel.inlineStyles,
      sidePanel && handle != null
          ? [
              div(classes: drawer.sideRow.className, [
                if (side == CoreDrawerSide.right) handle,
                div(classes: drawer.sideBody.className, [content]),
                if (side == CoreDrawerSide.left) handle,
              ]),
            ]
          : [
              if (side == CoreDrawerSide.bottom) ?handle,
              content,
              if (side == CoreDrawerSide.top) ?handle,
            ],
    );

    return div(
      attributes: const {'data-docs-part': 'screen'},
      styles: Styles(
        raw: {
          'position': 'relative',
          'isolation': 'isolate',
          'overflow': 'hidden',
          'width': pinnedLengthCss(page.demoScreenWidth),
          'max-width': '100%',
          'height': pinnedLengthCss(height),
          'border-radius': const CoreBorderRadius.all(CoreRadius.radius12).toValue(),
          'background-color': const CoreColor.token(CoreColors.surfaceContainerHighest).toValue(),
        },
      ),
      [
        // 뒤 화면 — `drawer` variant 는 이 층 전체를 줄인다. 구조의 `child` 는
        // 그 안의 감싼 영역만 가리킨다.
        div(
          styles: Styles(
            raw: {
              'position': 'absolute',
              'inset': '0',
              'display': 'flex',
              'justify-content': justify,
              'align-items': align,
              'padding': spaceCss(CoreSpace.space16),
              'background-color': const CoreColor.token(CoreColors.surface).toValue(),
              'transform': 'scale($scale)',
              'border-radius': corner.toValue(),
            },
          ),
          [
            div(
              attributes: const {'data-docs-part': 'child'},
              styles: const Styles(raw: {'min-width': '0', 'max-width': '100%'}),
              [_swipeArea(position, onOpen: () {})],
            ),
          ],
        ),
        div(
          attributes: const {'data-docs-part': 'barrier'},
          classes: drawer.barrier.className,
          styles: drawer.barrier.inlineStyles,
          const [],
        ),
        panel,
      ],
    );
  }
}

/// 플레이그라운드의 미리보기 — 열린 상태의 그림 아래에 같은 속성의 실제
/// `Swiper` 를 둔다. 아래 영역을 밀거나 여는 버튼을 누르면 패널이 열린다.
///
/// `open` 은 `onOpenChanged` 로 맞춘다 — 사용자가 닫은 뒤에도 버튼이 다시 열 수
/// 있다.
class _SwiperOpener extends StatefulComponent {
  const _SwiperOpener({required this.props});

  final Map<String, String> props;

  @override
  State<_SwiperOpener> createState() => _SwiperOpenerState();
}

class _SwiperOpenerState extends State<_SwiperOpener> {
  bool _open = false;

  void _handleOpenChanged(bool open) => setState(() => _open = open);

  @override
  Component build(BuildContext context) {
    final props = component.props;
    final position = page.demoPositionOf(props);
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
        _propPicture(props, height: page.demoPlaygroundScreenHeight),
        Swiper(
          position: position,
          variant: page.demoVariantOf(props),
          showDragHandle: page.demoShowDragHandleOf(props),
          enabled: page.demoEnabledOf(props),
          barrierDismissible: page.demoBarrierDismissibleOf(props),
          open: _open,
          onOpenChanged: _handleOpenChanged,
          overlayContent: _menu(() => _handleOpenChanged(false)),
          child: _swipeArea(position, onOpen: () => _handleOpenChanged(true)),
        ),
      ],
    );
  }
}
