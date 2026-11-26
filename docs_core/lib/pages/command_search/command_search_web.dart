/// CommandSearch 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<SizeSpec>` · 플레이그라운드가, 장면은
/// `<Preview demo="command-search/...">` · `<Card demo>` · `<Anatomy demo>` 가
/// 읽는다. 같은 이름의 Flutter 파일(`command_search_flutter.dart`)과 컴포넌트 ·
/// 속성 · 장면 이름이 같아야 한다.
///
/// 트리거는 제자리에 그려지므로 무대의 트리거는 모두 실제 `CommandSearch` 다.
/// 면이 `surfaceContainer` 이고 테두리가 없어 같은 색의 면에서는 상자가 보이지
/// 않는다. 상자를 보여야 하는 장면은 `surface` 면 위에 놓는다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'command_search_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _commandSearch;

/// 장면 이름(`command-search/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'command-search/anatomy': () => _backdrop(
    CoreColors.surface,
    _sized(
      page.kCommandSearchAnatomyWidth,
      CommandSearch(
        shortcut: const Kbd(keys: [page.kCommandSearchKeys]),
        onPressed: () {},
      ),
    ),
  ),
  'command-search/content': _contentScene,
  'command-search/states': _statesScene,
  'command-search/narrow': () => _backdrop(
    CoreColors.surface,
    _sized(
      page.kCommandSearchNarrowWidth,
      CommandSearch(
        hint: page.kCommandSearchLongHint,
        shortcut: const Kbd(keys: [page.kCommandSearchKeys]),
        onPressed: () {},
      ),
    ),
  ),
  'command-search/in-app-bar': _appBarScene,
  'command-search/do-on-surface': () => _backdrop(CoreColors.surface, _cardTrigger()),
  'command-search/dont-on-container': () => _backdrop(CoreColors.surfaceContainer, _cardTrigger()),
  'command-search/do-same-size': () => _backdrop(
    CoreColors.surface,
    _cardTrigger(size: CoreCommandSize.sm),
  ),
  'command-search/dont-readonly-field': () => _sized(
    page.kCommandSearchCardWidth,
    const TextField(readOnly: true, hintText: page.kCommandSearchShortHint),
  ),
};

Component _commandSearch(Map<String, String> props, String? label) {
  final shortcut = props['shortcut'];
  final trigger = _sized(
    page.commandSearchPreviewWidth(props),
    CommandSearch(
      size: page.commandSearchPreviewSize(props),
      hint: props['hint'],
      leading: docsWebIcon(props['leading']),
      shortcut: shortcut == null ? null : Kbd(keys: [shortcut]),
      enabled: previewFlag(props, 'enabled', fallback: true),
      onPressed: () {},
    ),
  );
  return page.commandSearchPreviewOnSurface(props) ? _backdrop(CoreColors.surface, trigger) : trigger;
}

/// 폭을 정한 상자 — 좁은 칸에서는 칸의 폭까지만 쓴다.
Component _sized(double width, Component child) => div(
  styles: Styles(raw: {'width': pinnedLengthCss(width), 'max-width': '100%'}),
  [child],
);

/// 트리거를 놓는 바탕 면.
Component _backdrop(CoreColorToken token, Component child) => div(
  styles: Styles(
    raw: {
      'box-sizing': 'border-box',
      'min-width': '0',
      'max-width': '100%',
      'padding': spaceCss(CoreSpace.space16),
      'border-radius': const CoreBorderRadius.all(CoreRadiusRole.panel).toValue(),
      'background-color': CoreColor.token(token).toValue(),
    },
  ),
  [child],
);

Component _cardTrigger({CoreCommandSize size = CoreCommandSize.defaultSize}) => _sized(
  page.kCommandSearchCardWidth,
  CommandSearch(
    size: size,
    hint: page.kCommandSearchShortHint,
    shortcut: const Kbd(keys: [page.kCommandSearchKeys]),
    onPressed: () {},
  ),
);

/// 기본 안내 글 · 검색 아이콘과, 둘을 바꾼 트리거.
Component _contentScene() => _backdrop(
  CoreColors.surface,
  _sized(
    page.kCommandSearchWidth,
    div(
      styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space12)}),
      [
        CommandSearch(
          shortcut: const Kbd(keys: [page.kCommandSearchKeys]),
          onPressed: () {},
        ),
        CommandSearch(
          hint: page.kCommandSearchCustomHint,
          leading: Icon(LucideIcons.calendar),
          onPressed: () {},
        ),
      ],
    ),
  ),
);

/// 기본과 비활성 — hover · 포커스 · 눌림은 정지 화면에서 켤 수 없어 표의
/// 설명으로 대신한다.
Component _statesScene() => docsWebDemoRow([
  _stateCell('기본', enabled: true),
  _stateCell('비활성', enabled: false),
]);

Component _stateCell(String name, {required bool enabled}) => div(
  styles: Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'center', 'gap': spaceCss(CoreSpace.space8)},
  ),
  [
    _backdrop(
      CoreColors.surface,
      _sized(
        page.kCommandSearchCardWidth,
        CommandSearch(
          hint: page.kCommandSearchShortHint,
          shortcut: const Kbd(keys: [page.kCommandSearchKeys]),
          enabled: enabled,
          onPressed: () {},
        ),
      ),
    ),
    Text(name).labelSmall.onSurfaceVariant,
  ],
);

/// 앱 바의 `child` 자리에 놓은 트리거.
Component _appBarScene() => _sized(
  page.kCommandSearchBarWidth,
  AppBar(
    leading: [
      Button(
        variant: CoreButtonVariant.ghost,
        shape: CoreButtonShape.square,
        onPressed: () {},
        attributes: const {'aria-label': page.kCommandSearchMenuName},
        child: Icon(LucideIcons.menu),
      ),
    ],
    child: CommandSearch(
      shortcut: const Kbd(keys: [page.kCommandSearchKeys]),
      onPressed: () {},
    ),
  ),
);
