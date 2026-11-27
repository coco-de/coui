/// Window 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="window/...">` 가
/// 읽는다. 같은 이름의 Flutter 파일(`window_flutter.dart`)과 컴포넌트 · 속성 ·
/// 장면 이름이 같아야 한다.
///
/// 장면은 서버에서 그린 채로 남을 수 있어, 처음부터 최대화하거나 스냅한 창을
/// 두지 않는다. 그 창의 크기는 브라우저에서 창 매니저를 잰 뒤에야 정해진다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'window_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _window;

/// 장면 이름(`window/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'window/anatomy': () => _host(
    height: page.anatomyHeight,
    windows: [
      Window(
        bounds: page.anatomyBounds,
        title: const Text(page.anatomyTitle),
        actions: _saveButton(),
        content: _body(page.anatomyBody),
      ),
    ],
  ),
  'window/states': () => _host(
    height: page.statesHeight,
    windows: [
      Window(
        bounds: page.statesFrontBounds,
        title: const Text(page.statesFrontTitle),
        content: _body(page.statesFrontBody),
      ),
      Window(
        bounds: page.statesBackBounds,
        title: const Text(page.statesBackTitle),
        content: _body(page.statesBackBody),
      ),
      Window(
        bounds: page.statesMinimizedBounds,
        minimized: true,
        title: const Text(page.statesMinimizedTitle),
        content: _body(page.statesMinimizedBody),
      ),
    ],
  ),
  'window/layers': () => _host(
    height: page.layersHeight,
    windows: [
      Window(
        bounds: page.layersFirstBounds,
        title: const Text(page.layersFirstTitle),
        content: _body(page.layersFirstBody),
      ),
      Window(
        bounds: page.layersPinnedBounds,
        alwaysOnTop: true,
        title: const Text(page.layersPinnedTitle),
        content: _body(page.layersPinnedBody),
      ),
    ],
  ),
  'window/do-extra-action': () => _host(
    height: page.actionsHeight,
    windows: [
      Window(
        bounds: page.actionsBounds,
        title: const Text(page.actionsTitle),
        actions: _saveButton(),
        content: _body(page.extraActionBody),
      ),
    ],
  ),
  'window/dont-window-actions': () => _host(
    height: page.actionsHeight,
    windows: [
      Window(
        bounds: page.actionsBounds,
        maximizable: false,
        title: const Text(page.actionsTitle),
        actions: const WindowActions(),
        content: _body(page.windowActionsBody),
      ),
    ],
  ),
  'window/do-move-buttons': () => const _MoveButtons(),
};

/// 플레이그라운드.
Component _window(Map<String, String> props, String? label) => _Playground(props: props);

class _Playground extends StatefulComponent {
  const _Playground({required this.props});

  final Map<String, String> props;

  @override
  State<_Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<_Playground> {
  /// "창 다시 놓기" 를 누른 횟수. 바뀌면 창 매니저를 새로 만든다.
  int _round = 0;

  @override
  Component build(BuildContext context) {
    final props = component.props;
    return _column(page.playgroundWidth, [
      _host(
        navigatorKey: ValueKey('${page.demoSignature(props)}-$_round'),
        width: page.playgroundWidth,
        height: page.playgroundHeight,
        windows: [
          _playgroundWindow(props, page.playgroundFrontBounds, page.playgroundFrontTitle, page.playgroundFrontBody),
          _playgroundWindow(props, page.playgroundBackBounds, page.playgroundBackTitle, page.playgroundBackBody),
        ],
      ),
      _outlineButton(page.resetLabel, () => setState(() => _round += 1)),
    ]);
  }
}

Window _playgroundWindow(Map<String, String> props, CoreWindowRect bounds, String title, String body) => Window(
  bounds: bounds,
  constraints: page.playgroundConstraints,
  draggable: page.demoFlag(props, 'draggable'),
  resizable: page.demoFlag(props, 'resizable'),
  maximizable: page.demoFlag(props, 'maximizable'),
  minimizable: page.demoFlag(props, 'minimizable'),
  closable: page.demoFlag(props, 'closable'),
  title: Text(title),
  content: _body(body),
);

/// 컨트롤러로 창을 옮기는 버튼을 창 매니저 밖에 둔 장면.
class _MoveButtons extends StatefulComponent {
  const _MoveButtons();

  @override
  State<_MoveButtons> createState() => _MoveButtonsState();
}

class _MoveButtonsState extends State<_MoveButtons> {
  final CoreWindowController _controller = CoreWindowController(bounds: page.moveBounds);

  void _moveTo(double left) {
    final bounds = _controller.bounds;
    _controller.bounds = CoreWindowRect.fromLTWH(left, bounds.top, bounds.width, bounds.height);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) => _column(page.sceneWidth, [
    _host(
      height: page.moveHeight,
      windows: [
        Window.controlled(
          controller: _controller,
          title: const Text(page.moveTitle),
          content: _body(page.moveBody),
        ),
      ],
    ),
    docsWebDemoRow([
      _outlineButton(page.moveLeftLabel, () => _moveTo(page.moveLeft)),
      _outlineButton(page.moveRightLabel, () => _moveTo(page.moveRight)),
    ]),
  ]);
}

/// 폭과 높이를 정한 창 매니저. 테두리로 매니저의 범위를 보인다. 창의 위치와
/// 크기는 CSS px 라, 매니저의 크기만 rem 으로 둔다.
Component _host({
  required double height,
  required List<Window> windows,
  double width = page.sceneWidth,
  Key? navigatorKey,
}) => div(
  styles: Styles(
    raw: {'width': pinnedLengthCss(width), 'max-width': '100%', 'height': pinnedLengthCss(height)},
  ),
  [
    OutlinedContainer(
      css: const Styles(raw: {'height': '100%'}),
      child: WindowNavigator(key: navigatorKey, showTopSnapBar: false, initialWindows: windows),
    ),
  ],
);

/// 창 매니저와 버튼을 위아래로 놓는다.
Component _column(double width, List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': spaceCss(CoreSpace.space8),
      'width': pinnedLengthCss(width),
      'max-width': '100%',
    },
  ),
  children,
);

/// 창 본문의 글자 — Web 의 본문은 왼쪽 위부터 놓인다.
Component _body(String text) => Text(text);

Component _saveButton() => Button(
  variant: CoreButtonVariant.ghost,
  size: CoreComponentSize.xs,
  onPressed: () {},
  child: const Text(page.saveLabel),
);

Component _outlineButton(String text, void Function() onPressed) => Button(
  variant: CoreButtonVariant.outline,
  size: CoreComponentSize.sm,
  onPressed: onPressed,
  child: Text(text),
);
