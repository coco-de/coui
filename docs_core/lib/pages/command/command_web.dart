/// Command 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · `<SizeSpec>` · 플레이그라운드가,
/// 장면은 `<Preview demo="command/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`command_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// `Command` 는 놓인 자리에 그려지므로 무대의 팔레트는 실제 컴포넌트다. 페이지가
/// 열릴 때 포커스를 가져가지 않게 모든 무대는 `autofocus` 를 끈다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'command_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _command;

/// 장면 이름(`command/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'command/anatomy': () => _still(const {
    'presentation': 'dialog',
    'scopes': 'true',
    'icons': 'true',
    'dismiss': 'true',
  }),
  'command/items': () => _framed(
    Command(autofocus: false, onSelect: (_) {}, groups: page.commandItemsSceneGroups<Component>(_glyph)),
  ),
  'command/keywords': () => _still(const {'icons': 'true', 'query': page.commandKeywordQuery}),
  'command/scopes': () => _still(const {'scopes': 'true', 'icons': 'true'}, scope: page.commandScopesSceneValue),
  'command/empty': () => _still(const {'query': page.commandEmptyQuery}),
  'command/do-grouped': () => _still(const {'icons': 'true'}),
  'command/dont-flat': () => _framed(
    Command(autofocus: false, onSelect: (_) {}, groups: page.commandFlatSceneGroups<Component>()),
  ),
  'command/long-list': () => _framed(
    Command(autofocus: false, onSelect: (_) {}, groups: page.commandLongListSceneGroups<Component>()),
  ),
  'command/do-empty-action': () => _framed(
    Command(
      query: page.commandEmptyQuery,
      autofocus: false,
      onSelect: (_) {},
      emptyIcon: const Icon(LucideIcons.search),
      emptyAction: Button(
        variant: CoreButtonVariant.plain,
        size: CoreComponentSize.sm,
        onPressed: () {},
        child: const Text(page.commandEmptyActionLabel),
      ),
      groups: page.commandPreviewGroups<Component>(page.CommandPreviewOptions.from(const {}), _glyph),
    ),
  ),
};

Component _command(Map<String, String> props, String? label) {
  final options = page.CommandPreviewOptions.from(props);
  if (previewFlag(props, 'opener')) return _CommandPlayground(options: options);
  return _frame(options, _palette(options, query: options.query));
}

/// 속성으로 고른 정지 팔레트.
Component _still(Map<String, String> props, {String? scope}) {
  final options = page.CommandPreviewOptions.from(props);
  return _frame(options, _palette(options, query: options.query, scope: scope));
}

/// 기본 속성의 틀.
Component _framed(Component child) => _frame(page.CommandPreviewOptions.from(const {}), child);

/// 팔레트를 놓는 틀 — 폭을 정하고, `fullscreen` 은 화면 대신 쓰는 높이를 준다.
/// `inline` 팔레트는 240보다 좁아지지 않으므로 더 좁은 칸에서는 옆으로
/// 스크롤한다.
Component _frame(page.CommandPreviewOptions options, Component child) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'width': pinnedLengthCss(options.width),
      'max-width': '100%',
      if (options.presentation == CoreCommandPresentation.fullscreen)
        'height': pinnedLengthCss(page.commandPreviewScreenHeight),
      if (options.presentation == CoreCommandPresentation.inline) 'overflow-x': 'auto',
    },
  ),
  [child],
);

Component _glyph(IconName icon) => Icon(icon);

Command _palette(
  page.CommandPreviewOptions options, {
  required String query,
  String? scope,
  bool autofocus = false,
  void Function(String)? onQueryChanged,
  void Function(String?)? onScopeChanged,
  void Function(String)? onSelect,
  void Function()? onDismiss,
}) => Command(
  presentation: options.presentation,
  size: options.size,
  scopes: options.scopes ? page.commandPreviewScopes : const [],
  scope: options.scopes ? scope : null,
  query: query,
  autofocus: autofocus,
  showFooter: options.showFooter,
  onQueryChanged: onQueryChanged,
  onScopeChanged: onScopeChanged,
  onSelect: onSelect ?? (_) {},
  onDismiss: options.dismiss ? (onDismiss ?? () {}) : null,
  groups: page.commandPreviewGroups<Component>(options, _glyph),
);

/// 검색어와 범위를 들고 있는 팔레트 — 입력하면 걸러진다.
class _LivePalette extends StatefulComponent {
  const _LivePalette({required this.options, this.autofocus = false, this.onClose});

  final page.CommandPreviewOptions options;
  final bool autofocus;

  /// 팔레트를 담은 대화상자를 닫는다 — 대화상자 안에서만 준다.
  final void Function()? onClose;

  @override
  State<_LivePalette> createState() => _LivePaletteState();
}

class _LivePaletteState extends State<_LivePalette> {
  late String _query = component.options.query;
  String? _scope;

  void _setQuery(String query) => setState(() => _query = query);

  void _setScope(String? scope) => setState(() => _scope = scope);

  @override
  Component build(BuildContext context) {
    final onClose = component.onClose;
    return _palette(
      component.options,
      query: _query,
      scope: _scope,
      autofocus: component.autofocus,
      onQueryChanged: _setQuery,
      onScopeChanged: _setScope,
      onSelect: onClose == null ? null : (_) => onClose(),
      onDismiss: onClose,
    );
  }
}

/// 플레이그라운드의 미리보기 — 입력에 따라 걸러지는 팔레트. `presentation` 이
/// dialog 면 아래의 버튼이 같은 속성의 팔레트를 실제 `Dialog` 안에 연다.
/// 스크림 · Escape · 항목 선택이 닫는다.
class _CommandPlayground extends StatefulComponent {
  const _CommandPlayground({required this.options});

  final page.CommandPreviewOptions options;

  @override
  State<_CommandPlayground> createState() => _CommandPlaygroundState();
}

class _CommandPlaygroundState extends State<_CommandPlayground> {
  bool _open = false;

  void _setOpen(bool open) => setState(() => _open = open);

  @override
  Component build(BuildContext context) {
    final options = component.options;
    final palette = _frame(options, _LivePalette(options: options));
    if (options.presentation != CoreCommandPresentation.dialog) return palette;
    void close() => _setOpen(false);
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
        palette,
        Button(
          variant: CoreButtonVariant.outline,
          size: CoreComponentSize.sm,
          onPressed: () => _setOpen(true),
          child: const Text(page.commandPreviewOpener),
        ),
        Dialog(
          open: _open,
          onClose: close,
          content: _LivePalette(options: options, autofocus: true, onClose: close),
          dialogStyle: page.commandPreviewDialogStyle,
        ),
      ],
    );
  }
}
