/// Swiper 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="swiper/...">` 가 읽는다. 같은 이름의 Web 파일(`swiper_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 열린 패널은 그림이다. `Swiper` 의 패널은 `openDrawer` 가 라우트로 올려 —
/// 네이티브 문서 앱에서는 앱 전체를 덮는다 — 그 자리에 열 수 없고, 처음 그릴
/// 때의 `open: true` 는 패널을 열지 않는다. 그래서 그림은 작은 화면 상자 안에
/// 패널 위젯인 실제 `Drawer` 를 놓는다. `Drawer` 에는 `Swiper` 가 `variant` 에
/// 따라 주는 `CoreSwiperStyle.defaultsByVariant` 를 넘기고, 배경막 색과 뒤
/// 화면의 축소는 `resolveDrawer` 가 낸 값을 쓴다. `CoreSwiperTheme` 은 그림에
/// 닿지 않는다. 실제 `Swiper` 는 플레이그라운드의 그림 아래에 있다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'swiper_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _swiper;

/// 장면 이름(`swiper/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'swiper/anatomy': () => const _SwiperPicture(),
  'swiper/do-button': () => _closedSwiper(openButton: true),
  'swiper/dont-gesture-only': () => _closedSwiper(openButton: false),
  'swiper/do-close': () => const _SwiperPicture(position: CoreSwiperPosition.bottom),
  'swiper/dont-no-close': () => const _SwiperPicture(position: CoreSwiperPosition.bottom, close: false),
};

Widget _swiper(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _SwiperOpener(props: props);
  return _propPicture(props);
}

/// 속성으로 고른 열린 상태의 그림. [height] 는 플레이그라운드만 낮춘다.
Widget _propPicture(Map<String, String> props, {double height = page.demoScreenHeight}) => _SwiperPicture(
  position: page.demoPositionOf(props),
  variant: page.demoVariantOf(props),
  showDragHandle: page.demoShowDragHandleOf(props),
  height: height,
);

/// 닫힌 실제 `Swiper` — `child` 만 보인다.
Widget _closedSwiper({required bool openButton}) => Swiper(
  overlayContent: _menu(null),
  child: _swipeArea(CoreSwiperPosition.defaultPosition, onOpen: openButton ? () {} : null),
);

/// 패널의 내용 — 플레이그라운드 코드의 `overlayContent` 와 같다. [onClose] 가
/// 없으면 닫기 버튼을 뺀다.
Widget _menu(VoidCallback? onClose) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space8,
  children: [
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
/// 버튼을 뺀다.
Widget _swipeArea(CoreSwiperPosition position, {VoidCallback? onOpen}) => SizedBox(
  width: page.demoAreaWidth,
  child: Card(
    variant: CoreCardVariant.outlined,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space12,
      children: [
        Text(page.demoHint(position)).bodySmall,
        if (onOpen != null) Button(size: CoreComponentSize.sm, onPressed: onOpen, child: const Text(page.demoOpen)),
      ],
    ),
  ),
);

/// 열린 상태의 그림 — 작은 화면 상자에 뒤 화면, 배경막, 실제 `Drawer` 패널을
/// 차례로 쌓는다. `drawer` variant 는 뒤 화면을 줄인다.
class _SwiperPicture extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final side = page.demoSideOf(position);
    final style = page.demoPictureStyle(variant);
    final drawer = resolveDrawer(context, side: side, drawerStyle: style);
    final zoom = variant == CoreSwiperVariant.drawer;
    final sidePanel = side == CoreDrawerSide.left || side == CoreDrawerSide.right;
    final dock = switch (side) {
      CoreDrawerSide.left => Alignment.centerLeft,
      CoreDrawerSide.right => Alignment.centerRight,
      CoreDrawerSide.top => Alignment.topCenter,
      CoreDrawerSide.bottom => Alignment.bottomCenter,
    };

    return SizedBox(
      width: page.demoScreenWidth,
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(CoreRadius.radius12)),
        child: Stacks(
          children: [
            Position.fill(
              child: ColoredBox(
                color: theme.colorScheme.resolve(const CoreColor.token(CoreColors.surfaceContainerHighest)).toValue(),
              ),
            ),
            Position.fill(
              child: Transform.scale(
                scale: zoom ? drawer.backdropScale : 1,
                child: ClipRRect(
                  borderRadius: zoom ? drawer.backdropCornerRadius : BorderRadius.zero,
                  child: ColoredBox(
                    color: theme.colorScheme.resolve(const CoreColor.token(CoreColors.surface)).toValue(),
                    child: Padding(
                      padding: const EdgeInsets.all(CoreSpace.space16),
                      child: Align(
                        alignment: Alignment(-dock.x, -dock.y),
                        child: _swipeArea(position, onOpen: () {}),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Position.fill(child: ColoredBox(color: drawer.barrierColor)),
            Align(
              alignment: dock,
              child: SizedBox(
                width: sidePanel ? drawer.panelWidth : double.infinity,
                height: sidePanel ? double.infinity : null,
                child: Drawer(
                  side: side,
                  showDragHandle: showDragHandle,
                  drawerStyle: style,
                  content: _menu(close ? () {} : null),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 플레이그라운드의 미리보기 — 열린 상태의 그림 아래에 같은 속성의 실제
/// `Swiper` 를 둔다. 아래 영역을 밀거나 여는 버튼을 누르면 패널이 열린다.
///
/// `open` 은 `onOpenChanged` 로 맞춘다 — 사용자가 닫은 뒤에도 버튼이 다시 열 수
/// 있다.
class _SwiperOpener extends StatefulWidget {
  const _SwiperOpener({required this.props});

  final Map<String, String> props;

  @override
  State<_SwiperOpener> createState() => _SwiperOpenerState();
}

class _SwiperOpenerState extends State<_SwiperOpener> {
  bool _open = false;

  void _handleOpenChanged(bool open) => setState(() => _open = open);

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final position = page.demoPositionOf(props);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _propPicture(props, height: page.demoPlaygroundScreenHeight),
        const Gap(gapStyle: CoreGapStyle(size: page.demoOpenerGap)),
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
