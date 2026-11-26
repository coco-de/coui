/// CommandSearch 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<SizeSpec>` · 플레이그라운드가, 장면은
/// `<Preview demo="command-search/...">` · `<Card demo>` · `<Anatomy demo>` 가
/// 읽는다. 같은 이름의 Web 파일(`command_search_web.dart`)과 컴포넌트 · 속성 ·
/// 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'command_search_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _commandSearch;

/// 장면 이름(`command-search/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
    TextField(readOnly: true, hintText: page.kCommandSearchShortHint),
  ),
};

Widget _commandSearch(Map<String, String> props, String? label) {
  final shortcut = props['shortcut'];
  final trigger = _sized(
    page.commandSearchPreviewWidth(props),
    CommandSearch(
      size: page.commandSearchPreviewSize(props),
      hint: props['hint'],
      leading: docsFlutterIcon(props['leading']),
      shortcut: shortcut == null ? null : Kbd(keys: [shortcut]),
      enabled: previewFlag(props, 'enabled', fallback: true),
      onPressed: () {},
    ),
  );
  return page.commandSearchPreviewOnSurface(props) ? _backdrop(CoreColors.surface, trigger) : trigger;
}

/// 폭을 정한 상자 — 좁은 칸에서는 부모의 폭까지만 쓴다.
Widget _sized(double width, Widget child) => SizedBox(width: width, child: child);

/// 트리거를 놓는 바탕 면.
Widget _backdrop(CoreColorToken token, Widget child) => Builder(
  builder: (context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.resolve(CoreColor.token(token)).toValue(),
      borderRadius: const BorderRadius.all(Radius.circular(CoreRadiusRole.panel)),
    ),
    child: Padding(padding: const EdgeInsets.all(CoreSpace.space16), child: child),
  ),
);

Widget _cardTrigger({CoreCommandSize size = CoreCommandSize.defaultSize}) => _sized(
  page.kCommandSearchCardWidth,
  CommandSearch(
    size: size,
    hint: page.kCommandSearchShortHint,
    shortcut: const Kbd(keys: [page.kCommandSearchKeys]),
    onPressed: () {},
  ),
);

/// 기본 안내 글 · 검색 아이콘과, 둘을 바꾼 트리거.
Widget _contentScene() => _backdrop(
  CoreColors.surface,
  _sized(
    page.kCommandSearchWidth,
    Column(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space12,
      children: [
        CommandSearch(
          shortcut: const Kbd(keys: [page.kCommandSearchKeys]),
          onPressed: () {},
        ),
        CommandSearch(
          hint: page.kCommandSearchCustomHint,
          leading: const Icon(LucideIcons.calendar),
          onPressed: () {},
        ),
      ],
    ),
  ),
);

/// 상태 격자 — Web 과 같은 두 칸.
Widget _statesScene() => docsFlutterDemoRow([
  _stateCell('기본', enabled: true),
  _stateCell('비활성', enabled: false),
]);

Widget _stateCell(String name, {required bool enabled}) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space8,
  children: [
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
Widget _appBarScene() => _sized(
  page.kCommandSearchBarWidth,
  AppBar(
    leading: [
      Button(
        variant: CoreButtonVariant.ghost,
        shape: CoreButtonShape.square,
        onPressed: () {},
        child: const Icon(LucideIcons.menu),
      ),
    ],
    child: CommandSearch(
      shortcut: const Kbd(keys: [page.kCommandSearchKeys]),
      onPressed: () {},
    ),
  ),
);
