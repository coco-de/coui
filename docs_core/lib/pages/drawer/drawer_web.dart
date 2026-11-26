/// Drawer 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="drawer/...">` 가 읽는다. 같은 이름의 Flutter 파일(`drawer_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대의 패널은 그림이다. Web 의 `Drawer` 는 트리에 놓으면 아무것도 그리지
/// 않고, `openDrawer` 가 오버레이 호스트에 올릴 때만 그려진다. 그래서 그림은
/// 열린 서랍이 쓰는 `resolveDrawer` 의 겉모습(Core 기본값 · `CoreDrawerTheme` ·
/// 테마, 서페이스 스타일의 표시 클래스까지)을 작은 화면 상자 안에 놓고, 안의
/// 버튼 · 간격 · 글자는 킷의 것을 쓴다. 그림은 `inert` 라 누르거나 초점을 받지
/// 못하고(Flutter 그림과 같다), 열고 닫기 · 끌기도 없다. 실제 서랍은
/// 플레이그라운드의 "열어 보기"가 연다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'drawer_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _drawer;

/// 장면 이름(`drawer/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 블록은 장면을 상자 하나에 더 담고, 그 상자의 폭은 내용이 정한다. 그림의
  // 막과 패널은 겹쳐 놓은 것이라 폭을 만들지 않아, 이 장면만 폭을 정해 준다.
  'drawer/anatomy': () => div(
    styles: Styles(
      raw: {
        'width': 'min(${pinnedLengthCss(page.demoFrameWidth)}, calc(100vw - ${pinnedLengthCss(CoreSpace.space128)}))',
        // 막 위에 붙는 번호가 무대 윗선에 걸치지 않게 한다.
        'padding-top': spaceCss(CoreSpace.space12),
      },
    ),
    [
      _DrawerPicture(
        side: CoreDrawerSide.bottom,
        title: page.demoTitle,
        description: page.demoDescription,
        showDragHandle: true,
        content: const Text(page.demoContent),
        footer: _footer(_noop, _noop),
        height: page.demoAnatomyHeight,
      ),
    ],
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
  'drawer/dont-confirm': () => _DrawerPicture(
    side: CoreDrawerSide.bottom,
    content: const Text('정말 삭제하시겠어요?'),
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

Component _drawer(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _DrawerOpener(props: props, label: label);
  return _propPicture(props, label);
}

/// 속성으로 고른 패널 그림.
Component _propPicture(Map<String, String> props, String? label) => _DrawerPicture(
  side: page.demoSideOf(props),
  title: label ?? page.demoTitle,
  description: props['description'],
  showDragHandle: page.demoShowsHandle(props),
  showCloseButton: page.demoShowsClose(props),
  content: const Text(page.demoContent),
  footer: page.demoHasFooter(props) ? _footer(_noop, _noop) : null,
);

void _noop() {}

/// 하단 영역의 버튼 줄 — 플레이그라운드의 Web 코드와 같은 모양이다.
Component _footer(
  void Function() onCancel,
  void Function() onApply, {
  String apply = page.demoApply,
  CoreButtonVariant cancelVariant = CoreButtonVariant.outline,
}) => div(
  styles: Styles(raw: {'display': 'flex', 'gap': spaceCss(CoreSpace.space8)}),
  [
    Button(variant: cancelVariant, onPressed: onCancel, child: const Text(page.demoCancel)),
    Button(onPressed: onApply, child: Text(apply)),
  ],
);

Component _column(List<Component> children) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space12)}),
  children,
);

Component _lines(List<String> lines) => _column([for (final line in lines) Text(line)]);

/// 고무줄 장면의 본문 — 취소 · 제목 · 완료 줄과 시간 목록.
Component _rubberBandContent() => _column([
  div(styles: Styles(raw: {'display': 'flex', 'align-items': 'center'}), [
    Button(variant: CoreButtonVariant.ghost, onPressed: _noop, child: const Text('취소')),
    div(styles: Styles(raw: {'flex': '1', 'text-align': 'center'}), [const Text('알림 시간').titleMedium]),
    Button(onPressed: _noop, child: const Text('완료')),
  ]),
  for (final time in page.demoTimes) Text(time),
]);

/// 패널 그림 — 작은 화면 상자 안에 어두운 막과 패널을 놓는다.
///
/// 구성은 열린 서랍과 같다: 하단 시트는 손잡이가 머리 줄 위에, 상단 시트는
/// 본문 아래에, 옆 서랍은 안쪽 변에 세로로 놓인다. 옆 서랍의 폭은 상자가
/// 좁으면 상자보다 48 좁게 줄인다. 상자는 따로 쌓임 문맥을 만들어, 안의
/// `z-50` 이 문서의 머리 줄 위로 올라오지 않게 한다. 부분마다
/// `data-docs-part` 를 달아 구조 블록이 번호를 붙인다.
class _DrawerPicture extends StatelessComponent {
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
  final Component content;
  final String? title;
  final String? description;
  final Component? footer;
  final bool showDragHandle;
  final bool showCloseButton;
  final CoreDrawerStyle? drawerStyle;
  final double height;

  @override
  Component build(BuildContext context) {
    final resolved = resolveDrawer(
      context,
      side: side,
      open: true,
      dragDelta: 0,
      draggable: false,
      drawerStyle: drawerStyle,
    );
    final isSidePanel = side == CoreDrawerSide.left || side == CoreDrawerSide.right;
    final handle = showDragHandle ? _handle(resolved) : null;
    final header = _header(resolved);
    final footer = this.footer;
    final body = <Component>[
      ?header,
      _slot('content', resolved.content, [content]),
      if (footer != null) _slot('footer', resolved.footer, [footer]),
    ];
    final children = handle != null && isSidePanel
        ? <Component>[
            div(classes: resolved.sideRow.className, [
              if (side == CoreDrawerSide.right) handle,
              div(classes: resolved.sideBody.className, body),
              if (side == CoreDrawerSide.left) handle,
            ]),
          ]
        : <Component>[
            if (handle != null && side == CoreDrawerSide.bottom) handle,
            ...body,
            if (handle != null && side == CoreDrawerSide.top) handle,
          ];

    return div(
      styles: Styles(
        raw: {
          'position': 'relative',
          'isolation': 'isolate',
          'overflow': 'hidden',
          'width': 'min(100%, ${pinnedLengthCss(page.demoFrameWidth)})',
          'height': pinnedLengthCss(height),
          'border-radius': pinnedLengthCss(CoreRadiusRole.surface),
          'background-color': const CoreColor.token(CoreColors.surface).toValue(),
        },
      ),
      attributes: const {'inert': ''},
      [
        div(
          const [],
          classes: resolved.barrier.className,
          styles: resolved.barrier.inlineStyles,
          attributes: const {'data-docs-part': 'scrim'},
        ),
        div(
          classes: resolved.panel.className,
          styles: Styles(
            raw: {
              ...?resolved.panel.inlineStyles?.properties,
              if (isSidePanel) 'max-width': 'calc(100% - ${pinnedLengthCss(CoreSpace.space48)})',
            },
          ),
          attributes: const {'data-docs-part': 'panel'},
          children,
        ),
      ],
    );
  }

  Component _slot(String part, WebElementChrome chrome, List<Component> children) => div(
    classes: chrome.className,
    styles: chrome.inlineStyles,
    attributes: {'data-docs-part': part},
    children,
  );

  Component _handle(ResolvedDrawer resolved) => div(
    classes: resolved.handle.className,
    styles: resolved.handle.inlineStyles,
    attributes: const {'aria-hidden': 'true', 'data-docs-part': 'handle'},
    [div(const [], classes: resolved.handlePill.className, styles: resolved.handlePill.inlineStyles)],
  );

  /// 머리 줄 — 제목도 설명도 없으면 그리지 않는다(닫기 버튼도 함께 빠진다).
  Component? _header(ResolvedDrawer resolved) {
    final title = this.title;
    final description = this.description;
    if (title == null && description == null) return null;

    return _slot('header', resolved.header, [
      div(
        classes: resolved.titleWrap.className,
        styles: resolved.titleWrap.inlineStyles,
        attributes: const {'data-docs-part': 'title'},
        [
          if (description == null)
            Text(title!).titleMedium
          else
            div(classes: resolved.heading.className, styles: resolved.heading.inlineStyles, [
              if (title != null) ...[Text(title).titleMedium, Gap(gapStyle: resolved.titleDescriptionGapStyle)],
              div(classes: resolved.description.className, styles: resolved.description.inlineStyles, [
                Text(description),
              ]),
            ]),
        ],
      ),
      if (showCloseButton)
        Button(
          variant: CoreButtonVariant.plain,
          size: CoreComponentSize.sm,
          shape: CoreButtonShape.square,
          buttonStyle: resolved.closeButtonStyle,
          attributes: const {'aria-label': '닫기', 'data-docs-part': 'close'},
          onPressed: _noop,
          child: Icon(LucideIcons.x, iconStyle: resolved.closeButtonStyle.leadingIconStyle),
        ),
    ]);
  }
}

/// 플레이그라운드의 미리보기 — 패널 그림 아래의 버튼이 같은 속성의 실제
/// 서랍을 연다.
///
/// 열린 서랍은 플레이그라운드의 오버레이 호스트에 올라가 페이지를 덮는다.
/// 코드 상자의 Web 코드와 같은 속성으로 연다.
class _DrawerOpener extends StatelessComponent {
  const _DrawerOpener({required this.props, required this.label});

  final Map<String, String> props;
  final String? label;

  @override
  Component build(BuildContext context) => div(
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
      builder: (close) => Drawer(
        title: label ?? page.demoTitle,
        description: props['description'],
        showDragHandle: page.demoShowsHandle(props),
        showCloseButton: page.demoShowsClose(props),
        rubberBand: page.demoRubberBand(props),
        content: const Text(page.demoContent),
        footer: page.demoHasFooter(props) ? _footer(close, close) : null,
      ),
    );
  }
}
