/// ThemeController 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · `<SizeSpec>` · 플레이그라운드가,
/// 장면은 `<Preview demo="theme-controller/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`theme_controller_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'theme_controller_page.dart';

/// 속성 → Widget.
///
/// 선택은 눌러야 바뀌므로 빌더가 고른 이름을 기억한다 — Web 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _ThemeControllerPreview(props: props);

/// 장면 이름(`theme-controller/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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

/// 상태 장면 — Web 과 같은 네 상태.
Widget _themeControllerStates() => Wrap(
  spacing: CoreSpace.space16,
  runSpacing: CoreSpace.space12,
  children: [
    for (final (title, selected, enabled) in themeControllerStateColumns)
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space8,
        children: [
          Text(title).labelSmall.onSurfaceVariant,
          _stateCell(selected: selected, enabled: enabled),
        ],
      ),
  ],
);

Widget _stateCell({required bool selected, required bool enabled}) {
  final (name, palette) = themeControllerPreviewPalettes.first;
  return ThemeController(
    selectedTheme: selected ? name : null,
    enabled: enabled,
    onThemeChanged: (_) {},
    themes: [themeControllerOption(name, palette.take(2).toList())],
  );
}

/// 속성으로 그리는 테마 선택기 — 눌러 고른 이름을 기억한다. 속성은 Web 과 같다.
class _ThemeControllerPreview extends StatefulWidget {
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
  void didUpdateWidget(covariant _ThemeControllerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.props['selected'] != widget.props['selected']) _selected = _initialSelected();
  }

  String _initialSelected() => widget.props['selected'] ?? themeControllerPreviewPalettes.first.$1;

  void _handleThemeChanged(String name) => setState(() => _selected = name);

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    return ThemeController(
      selectedTheme: _selected,
      onThemeChanged: _handleThemeChanged,
      size: previewEnum(CoreThemeControllerSize.values, props['size'], CoreThemeControllerSize.defaultSize),
      enabled: previewFlag(props, 'enabled', fallback: true),
      themes: themeControllerPreviewOptions(props),
    );
  }
}
