/// Drawer 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="drawer/...">` 가 읽는다. 같은 이름의 Web 파일(`drawer_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대의 패널은 그림이다. 열린 서랍은 내비게이터에 라우트를 올리므로 네이티브
/// 문서 앱에서는 앱 전체를 덮는다. 그래서 그림은 실제 `Drawer` 를 라우트 없이
/// 작은 화면 상자 안에 놓고, 누르거나 초점을 받지 못하게 막는다 — 닫기 버튼은
/// 라우트 밖에서 누르면 루트 내비게이터의 맨 위 라우트를 닫기 때문이다. 어두운
/// 막의 색과 옆 서랍의 폭은 `resolveDrawer` 가 낸 값이다. 열고 닫기 · 끌기는
/// 그림에 없다. 실제 서랍은 플레이그라운드의 "열어 보기"가 연다.
library;

import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'drawer_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _drawer;

/// 장면 이름(`drawer/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'drawer/anatomy': () => _DrawerPicture(
    side: CoreDrawerSide.bottom,
    title: page.demoTitle,
    description: page.demoDescription,
    showDragHandle: true,
    content: const Text(page.demoContent),
    footer: _footer(_noop, _noop),
    height: page.demoAnatomyHeight,
  ),
  'drawer/footer': () => _DrawerPicture(
    side: CoreDrawerSide.right,
    title: '프로필',
    description: '다른 사람에게 보이는 모습을 바꿔요.',
    content: TextField(label: '이름'),
    footer: _footer(_noop, _noop, apply: '저장', cancelVariant: CoreButtonVariant.secondary),
    height: page.demoSceneHeight,
  ),
  'drawer/sheet': () => _DrawerPicture(
    side: CoreDrawerSide.bottom,
    title: '통화 선택',
    description: '받으실 통화를 선택해 주세요',
    showDragHandle: true,
    showCloseButton: false,
    drawerStyle: const CoreDrawerStyle(
      panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius28),
      dividerStyle: CoreDividerStyle(thickness: CoreStrokeWidth.stroke0),
    ),
    content: _lines(page.demoCurrencies),
    height: page.demoSceneHeight,
  ),
  'drawer/rubber-band': () => _DrawerPicture(
    side: CoreDrawerSide.bottom,
    showDragHandle: true,
    showCloseButton: false,
    content: _rubberBandContent(),
    height: page.demoSceneHeight,
  ),
  'drawer/do-complex': () => _DrawerPicture(
    side: CoreDrawerSide.right,
    title: '필터',
    content: _column([TextField(label: '최저 가격'), const Text('판매 중인 상품만 보여 줍니다.')]),
    footer: _footer(_noop, _noop),
    height: page.demoCardHeight,
  ),
  'drawer/dont-confirm': () => const _DrawerPicture(
    side: CoreDrawerSide.bottom,
    content: Text('정말 삭제하시겠어요?'),
    height: page.demoCardHeight,
  ),
  'drawer/do-title': () => _DrawerPicture(
    side: CoreDrawerSide.right,
    title: '알림 설정',
    content: _lines(const ['새 글', '댓글', '팔로우']),
    height: page.demoCardHeight,
  ),
  'drawer/dont-no-name': () => _DrawerPicture(
    side: CoreDrawerSide.right,
    content: _lines(const ['새 글', '댓글', '팔로우']),
    height: page.demoCardHeight,
  ),
};

Widget _drawer(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _DrawerOpener(props: props, label: label);
  return _propPicture(props, label);
}

/// 속성으로 고른 패널 그림.
Widget _propPicture(Map<String, String> props, String? label) => _DrawerPicture(
  side: page.demoSideOf(props),
  title: label ?? page.demoTitle,
  description: props['description'],
  showDragHandle: page.demoShowsHandle(props),
  showCloseButton: page.demoShowsClose(props),
  content: const Text(page.demoContent),
  footer: page.demoHasFooter(props) ? _footer(_noop, _noop) : null,
);

void _noop() {}

/// 하단 영역의 버튼 줄 — 플레이그라운드의 Flutter 코드와 같은 모양이다.
Widget _footer(
  VoidCallback onCancel,
  VoidCallback onApply, {
  String apply = page.demoApply,
  CoreButtonVariant cancelVariant = CoreButtonVariant.outline,
}) => Row(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space8,
  children: [
    Button(variant: cancelVariant, onPressed: onCancel, child: const Text(page.demoCancel)),
    Button(onPressed: onApply, child: Text(apply)),
  ],
);

Widget _column(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space12,
  children: children,
);

Widget _lines(List<String> lines) => _column([for (final line in lines) Text(line)]);

/// 고무줄 장면의 본문 — 취소 · 제목 · 완료 줄과 시간 목록.
Widget _rubberBandContent() => _column([
  Row(
    children: [
      Button(variant: CoreButtonVariant.ghost, onPressed: _noop, child: const Text('취소')),
      Expanded(child: Center(child: const Text('알림 시간').titleMedium)),
      Button(onPressed: _noop, child: const Text('완료')),
    ],
  ),
  for (final time in page.demoTimes) Text(time),
]);

/// 패널 그림 — 작은 화면 상자에 어두운 막을 칠하고, 실제 `Drawer` 를 붙는
/// 가장자리에 놓는다.
///
/// 옆 서랍의 폭은 상자보다 48 좁은 폭을 넘지 않는다. 무대가 상자보다 좁으면
/// 상자 전체를 줄여 그린다.
class _DrawerPicture extends StatelessWidget {
  const _DrawerPicture({
    required this.side,
    required this.content,
    this.title,
    this.description,
    this.footer,
    this.showDragHandle = CoreDrawerContract.defaultShowDragHandle,
    this.showCloseButton = CoreDrawerContract.defaultShowCloseButton,
    this.drawerStyle,
    this.height = page.demoFrameHeight,
  });

  final CoreDrawerSide side;
  final Widget content;
  final String? title;
  final String? description;
  final Widget? footer;
  final bool showDragHandle;
  final bool showCloseButton;
  final CoreDrawerStyle? drawerStyle;
  final double height;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveDrawer(context, side: side, drawerStyle: drawerStyle);
    final screenFill = Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.surface)).toValue();
    final isSidePanel = side == CoreDrawerSide.left || side == CoreDrawerSide.right;
    final alignment = switch (side) {
      CoreDrawerSide.left => Alignment.centerLeft,
      CoreDrawerSide.right => Alignment.centerRight,
      CoreDrawerSide.top => Alignment.topCenter,
      CoreDrawerSide.bottom => Alignment.bottomCenter,
    };

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(CoreRadiusRole.surface)),
        child: SizedBox(
          width: page.demoFrameWidth,
          height: height,
          child: IgnorePointer(
            child: ExcludeFocus(
              child: ColoredBox(
                color: screenFill,
                child: ColoredBox(
                  color: resolved.barrierColor,
                  child: Align(
                    alignment: alignment,
                    child: SizedBox(
                      width: isSidePanel
                          ? math.min(resolved.panelWidth, page.demoFrameWidth - CoreSpace.space48)
                          : page.demoFrameWidth,
                      height: isSidePanel ? height : null,
                      child: Drawer(
                        side: side,
                        title: title,
                        description: description,
                        showDragHandle: showDragHandle,
                        showCloseButton: showCloseButton,
                        drawerStyle: drawerStyle,
                        content: content,
                        footer: footer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 플레이그라운드의 미리보기 — 패널 그림 아래의 버튼이 같은 속성의 실제
/// 서랍을 연다.
///
/// 열린 서랍은 루트 내비게이터에 라우트를 올린다 — 사이트의 임베드에서는
/// 임베드 안을, 네이티브 문서 앱에서는 앱 전체를 덮는다. 코드 상자의 Flutter
/// 코드와 같은 속성으로 연다.
class _DrawerOpener extends StatelessWidget {
  const _DrawerOpener({required this.props, required this.label});

  final Map<String, String> props;
  final String? label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _propPicture(props, label),
      const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
      Button(
        variant: CoreButtonVariant.outline,
        onPressed: () => _open(context),
        child: const Text(page.demoOpener),
      ),
    ],
  );

  void _open(BuildContext context) {
    openDrawer<void>(
      context: context,
      side: page.demoSideOf(props),
      rubberBand: page.demoRubberBand(props),
      builder: (drawerContext) {
        void close() => closeDrawer<void>(drawerContext);
        return Drawer(
          title: label ?? page.demoTitle,
          description: props['description'],
          showDragHandle: page.demoShowsHandle(props),
          showCloseButton: page.demoShowsClose(props),
          content: const Text(page.demoContent),
          footer: page.demoHasFooter(props) ? _footer(close, close) : null,
        );
      },
    );
  }
}
