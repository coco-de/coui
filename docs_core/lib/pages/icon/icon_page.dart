/// Icon 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `icon_web.dart` · `icon_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 셋이다: `icon`(Lucide 의 kebab-case 이름), `size`(`CoreIconSize` 의
/// 숫자), `color`(색 토큰 이름, `inherit` 은 색을 주지 않는다). 두 플랫폼
/// 빌더와 코드가 같은 뜻으로 읽도록 해석은 이 파일 한 곳에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/icon.md`.
const String slug = 'icon';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// Icon 의 크기는 크기 단계(`CoreComponentSize`)가 아니라 숫자라서
/// `defaultsBySize` 가 없다. 페이지는 [iconSizeSteps] 를 장면으로 보인다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 플레이그라운드에서 고르는 아이콘 — 속성 값 → 아이콘. 모두 패키지에 번들된
/// 아이콘이라 두 플랫폼이 네트워크 없이 그린다.
const Map<String, IconName> iconPreviewGlyphs = {
  'house': LucideIcons.house,
  'heart': LucideIcons.heart,
  'search': LucideIcons.search,
  'star': LucideIcons.star,
  'bell': LucideIcons.bell,
  'triangle-alert': LucideIcons.triangleAlert,
};

/// `CoreIconSize` 의 값 — 작은 값부터. 플레이그라운드의 크기 선택지와
/// `icon/sizes` 장면이 함께 읽는다.
const List<double> iconSizeSteps = [
  CoreIconSize.size10,
  CoreIconSize.size12,
  CoreIconSize.size14,
  CoreIconSize.size16,
  CoreIconSize.size18,
  CoreIconSize.size20,
  CoreIconSize.size24,
  CoreIconSize.size28,
  CoreIconSize.size32,
  CoreIconSize.size48,
];

/// 플레이그라운드와 `icon/colors` 장면에서 고르는 색 — 이름은 `CoreColors` 의
/// 멤버 이름과 같아, 코드에 그대로 적는다. 선택지끼리 눈에 띄게 달라야 해서,
/// 기본 팔레트에서 글자색과 거의 같은 `primary` · `tertiary` 는 넣지 않는다.
const Map<String, CoreColorToken> iconPreviewColors = {
  'onSurfaceVariant': CoreColors.onSurfaceVariant,
  'info': CoreColors.info,
  'success': CoreColors.success,
  'warning': CoreColors.warning,
  'error': CoreColors.error,
};

/// 색을 주지 않는 선택지의 속성 값.
const String iconPreviewInheritColor = 'inherit';

/// 값이 정해지는 순서의 단계 — 뒤로 갈수록 우선한다. 두 플랫폼 장면이 함께 읽는다.
const List<String> iconThemeOrder = [
  '아무 값도 없을 때',
  '가장 가까운 IconTheme',
  '앱 테마 CoreIconTheme',
  '아이콘의 iconStyle',
];

/// 속성의 `icon` 이름 — 없거나 모르는 값은 `house`.
String iconPreviewName(Map<String, String> props) {
  final name = props['icon'];
  return name != null && iconPreviewGlyphs.containsKey(name) ? name : 'house';
}

/// 속성의 `icon` → 아이콘.
IconName iconPreviewGlyph(Map<String, String> props) => iconPreviewGlyphs[iconPreviewName(props)]!;

/// 속성의 `size` → 크기. `CoreIconSize` 의 값이 아니면 `null` — 크기를 주지 않는다.
double? iconPreviewSize(Map<String, String> props) {
  final size = double.tryParse(props['size'] ?? '');
  return size != null && iconSizeSteps.contains(size) ? size : null;
}

/// 속성의 `color` → 색. `inherit` 이나 모르는 값은 `null` — 색을 주지 않는다.
CoreColor? iconPreviewColor(Map<String, String> props) {
  final token = iconPreviewColors[props['color']];
  return token == null ? null : CoreColor.token(token);
}

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: const {'icon': 'house', 'size': '32', 'color': iconPreviewInheritColor},
  controls: [
    DocsPlaygroundChoice(label: 'icon', prop: 'icon', options: [...iconPreviewGlyphs.keys]),
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: [for (final size in iconSizeSteps) '${size.toInt()}']),
    DocsPlaygroundChoice(label: 'color', prop: 'color', options: [iconPreviewInheritColor, ...iconPreviewColors.keys]),
  ],
  code: _iconCode,
);

/// 속성 → 코드. 주지 않은 크기 · 색은 적지 않는다.
String _iconCode(Map<String, String> props, String? label) {
  final glyph = 'LucideIcons.${docsIconIdentifier(iconPreviewName(props))}';
  final size = iconPreviewSize(props);
  final color = props['color'];
  final fields = [
    if (size != null) 'size: CoreIconSize.size${size.toInt()},',
    if (iconPreviewColors.containsKey(color)) 'color: CoreColor.token(CoreColors.$color),',
  ];
  if (fields.isEmpty) return 'Icon($glyph)';
  return 'Icon(\n  $glyph,\n  iconStyle: CoreIconStyle(\n${fields.map((f) => '    $f').join('\n')}\n  ),\n)';
}
