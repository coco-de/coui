/// ThemeController 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · `<SizeSpec>` · 플레이그라운드가,
/// 장면은 `<Preview demo="theme-controller/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`theme_controller_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'theme_controller_page.dart';

/// 속성 → Component.
///
/// 선택은 눌러야 바뀌므로 빌더가 고른 이름을 기억한다. 서버에서 그리는 블록에서는
/// 처음 선택만 보이고, 브라우저에서 깨어나는 플레이그라운드에서는 원을 눌러 바꿀 수 있다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _ThemeControllerPreview(props: props);

/// 장면 이름(`theme-controller/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 세 번째를 고른다 — 구조 번호(팔레트는 첫 원, 버튼은 고른 원)가 겹치지 않게.
  'theme-controller/anatomy': () => ThemeController(
    selectedTheme: themeControllerPreviewPalettes.last.$1,
    onThemeChanged: (_) {},
    themes: themeControllerPreviewOptions(const {}),
  ),
  'theme-controller/palette': () => ThemeController(
    onThemeChanged: (_) {},
    themes: themeControllerPaletteThemes(),
  ),
  'theme-controller/states': _themeControllerStates,
  'theme-controller/locked': () => ThemeController(
    selectedTheme: themeControllerPreviewPalettes.first.$1,
    onThemeChanged: (_) {},
    themes: themeControllerPreviewOptions(const {'locked': themeControllerLockedName}),
  ),
  'theme-controller/long-name': () => ThemeController(
    selectedTheme: themeControllerPreviewPalettes.first.$1,
    onThemeChanged: (_) {},
    themes: [
      themeControllerOption(
        themeControllerPreviewPalettes.first.$1,
        themeControllerPreviewPalettes.first.$2.take(2).toList(),
      ),
      themeControllerOption(themeControllerLongName, const [(76, 29, 149), (45, 212, 191)]),
      themeControllerOption(
        themeControllerPreviewPalettes.last.$1,
        themeControllerPreviewPalettes.last.$2.take(2).toList(),
      ),
    ],
  ),
  // `selectedTheme` 이 어느 `name` 과도 같지 않다 — 아무 원도 고른 모양이 아니다.
  'theme-controller/dont-mismatch': () => ThemeController(
    selectedTheme: 'ocean',
    onThemeChanged: (_) {},
    themes: themeControllerPreviewOptions(const {'count': '2'}),
  ),
  'theme-controller/dont-light-dark': () => ThemeController(
    selectedTheme: themeControllerLightDarkThemes.first.name,
    onThemeChanged: (_) {},
    themes: themeControllerLightDarkThemes,
  ),
};

/// 상태 장면 — 기본 · 선택 · 비활성 · 비활성 선택. hover · 눌림 · 포커스는
/// 브라우저가 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _themeControllerStates() => div(
  classes: 'docs-demo-field-states',
  styles: Styles(raw: {'grid-template-columns': 'repeat(${themeControllerStateColumns.length}, max-content)'}),
  [
    for (final (title, _, _) in themeControllerStateColumns) span([Text(title).labelSmall.onSurfaceVariant]),
    for (final (_, selected, enabled) in themeControllerStateColumns) _stateCell(selected: selected, enabled: enabled),
  ],
);

Component _stateCell({required bool selected, required bool enabled}) {
  final (name, palette) = themeControllerPreviewPalettes.first;
  return ThemeController(
    selectedTheme: selected ? name : null,
    enabled: enabled,
    onThemeChanged: (_) {},
    themes: [themeControllerOption(name, palette.take(2).toList())],
  );
}

/// 속성으로 그리는 테마 선택기 — 눌러 고른 이름을 기억한다.
///
/// 속성: `size` · `enabled` 는 컴포넌트 속성 그대로, `selected` 는 처음 고른 이름,
/// `colors` · `count` · `locked` 는 [themeControllerPreviewOptions] 가 읽는다.
class _ThemeControllerPreview extends StatefulComponent {
  const _ThemeControllerPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_ThemeControllerPreview> createState() => _ThemeControllerPreviewState();
}

class _ThemeControllerPreviewState extends State<_ThemeControllerPreview> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = _initialSelected();
  }

  @override
  void didUpdateComponent(covariant _ThemeControllerPreview oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.props['selected'] != component.props['selected']) _selected = _initialSelected();
  }

  String _initialSelected() => component.props['selected'] ?? themeControllerPreviewPalettes.first.$1;

  void _handleThemeChanged(String name) => setState(() => _selected = name);

  @override
  Component build(BuildContext context) {
    final props = component.props;
    return ThemeController(
      selectedTheme: _selected,
      onThemeChanged: _handleThemeChanged,
      size: previewEnum(CoreThemeControllerSize.values, props['size'], CoreThemeControllerSize.defaultSize),
      enabled: previewFlag(props, 'enabled', fallback: true),
      themes: themeControllerPreviewOptions(props),
    );
  }
}
