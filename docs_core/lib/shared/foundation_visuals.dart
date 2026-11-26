/// 파운데이션 페이지의 `<FoundationVisual kind="…" />` 가 보여 주는 값.
///
/// 문서 사이트는 이 값을 그림으로, 네이티브 문서 앱은 같은 값을 표로 그린다.
/// 두 표면이 이 목록 하나를 읽어야 한쪽만 고친 글이나 숫자가 다른 쪽에서
/// 옛 값으로 남지 않는다. 숫자는 손으로 적지 않고 `coui_core` 토큰에서 읽고,
/// 여기 적힌 글은 그림 안에 들어가는 이름표와 한 줄 설명뿐이다.
///
/// 순수 Dart 다 — jaspr 도 Flutter 도 import 하지 않는다.
library;

import 'package:coui_core/coui_core.dart';

import '../icon_data/bootstrap_names.dart';
import '../icon_data/hero_names.dart';
import '../icon_data/lucide_names.dart';
import '../icon_data/radix_names.dart';

/// `<FoundationVisual kind>` 가 받는 값.
enum FoundationVisualKind {
  /// 디자인 토큰 개요의 파운데이션 목록.
  topics('topics'),

  /// 색상 원칙 세 가지.
  colorPrinciples('color-principles'),

  /// 15단계 뉴트럴.
  neutral('neutral'),

  /// 상태 색 네 사다리.
  status('status'),

  /// 분류 색.
  category('category'),

  /// Semantic 색 토큰의 라이트 · 다크 값.
  semantic('semantic'),

  /// 브랜드 색을 primary 자리에 넣는 예.
  brand('brand'),

  /// 본문 서체와 코드 서체.
  fonts('fonts'),

  /// 22개 글자 역할.
  typography('typography'),

  /// 아이콘 세트 네 가지.
  iconSets('icon-sets'),

  /// 간격 사다리의 대표 단계.
  spacing('spacing'),

  /// 반경 역할 다섯 단.
  radii('radii'),

  /// 그림자 단계.
  shadows('shadows'),

  /// 상태 투명도.
  opacity('opacity'),

  /// 포커스 링.
  focusRing('focus-ring'),

  /// 지속 시간 alias.
  duration('duration'),

  /// 이징 alias.
  easing('easing'),

  /// Web z-index 단계.
  layers('layers');

  const FoundationVisualKind(this.attribute);

  /// 마크다운에 적는 `kind` 속성 값.
  final String attribute;

  /// [value] 에 맞는 종류. 모르는 값이면 `null`.
  static FoundationVisualKind? parse(String? value) {
    for (final kind in values) {
      if (kind.attribute == value) return kind;
    }
    return null;
  }
}

// ── 개요 ──────────────────────────────────────────────────────────

/// 파운데이션 페이지 경로 → 개요 목록에 붙는 한 줄 설명.
///
/// 목록의 순서와 이름은 내비게이션(`docs_navigation.dart`)의 Foundations 탭이
/// 정한다. 여기에는 설명만 있다.
const Map<String, String> kFoundationTopicDescriptions = {
  '/guides/colors': 'Neutral, 상태 색, 분류 색',
  '/guides/typography': '역할 22개, Pretendard와 Geist Mono',
  '/guides/icons': '아이콘 세트 4종과 Icon 컴포넌트',
  '/guides/layout': '간격 사다리와 레이아웃 컴포넌트',
  '/guides/shape': '반경 역할과 선 굵기',
  '/guides/effect': '그림자, 투명도, 포커스 링',
  '/guides/animation': '지속 시간과 이징',
  '/guides/layering': 'Web z-index 12단계',
};

// ── 색상 ──────────────────────────────────────────────────────────

/// 색상 원칙 — 번호 · 제목 · 설명.
const List<({String number, String title, String description})> kColorPrinciples = [
  (number: '01', title: '뉴트럴이 기본', description: '화면 대부분을 15단계 뉴트럴로 만듭니다.'),
  (number: '02', title: '색은 의미에만', description: '상태를 알리거나 항목을 구분할 때만 색을 씁니다.'),
  (number: '03', title: '대비 기준', description: '글자는 4.5:1, UI 요소는 3:1 이상을 지킵니다.'),
];

/// 뉴트럴 15단계 — 단계 번호 → 색.
Map<int, CoreColor> get foundationNeutralSteps => CouiColorPresets.palette.neutral.steps;

/// 상태 색 사다리 — 이름 · 쓰는 곳 · 단계.
List<({String label, String description, Map<int, CoreColor> steps})> get foundationStatusRamps {
  const palette = CouiColorPresets.palette;
  return [
    (label: 'Error', description: '실패, 입력 오류', steps: palette.error.steps),
    (label: 'Success', description: '완료, 정상 처리', steps: palette.success.steps),
    (label: 'Warning', description: '주의, 되돌릴 수 없는 작업', steps: palette.warning.steps),
    (label: 'Info', description: '안내, 새 소식', steps: palette.info.steps),
  ];
}

/// 상태 색 사다리에서 굵게 보이는 단계 — 라이트 모드가 쓰는 값.
const List<int> kStatusKeySteps = [100, 600, 700];

/// 상태 색 사다리 아래의 설명.
const String kStatusRampNote = '굵은 단계가 라이트 모드의 주요 값입니다. 100은 컨테이너, 600은 채움, 700은 컨테이너 위 글자이고, 아이콘은 500을 씁니다.';

/// 분류 색 표의 두 열 이름.
const ({String container, String onContainer}) kCategoryColumns = (
  container: '컨테이너',
  onContainer: '컨테이너 위 글자',
);

/// 분류 색 표 아래의 설명.
const String kCategoryDotNote = '점은 채움(category-{색}) 색으로, 차트 계열이나 상태가 아닌 표시 점에 씁니다.';

/// 분류 색 토큰 이름의 형식 — 제목 · 이름.
const ({String title, String names}) kCategoryNaming = (
  title: '토큰 이름',
  names: 'category-{색} · on-category-{색} · category-{색}-container · on-category-{색}-container · category-{색}-outline',
);

/// 분류 색 하나의 이름 — `red` → `Red`.
String foundationCategoryName(CoreCategoryColor hue) => '${hue.name[0].toUpperCase()}${hue.name.substring(1)}';

/// 분류 색 하나의 라이트 모드 값 — 컨테이너 · 컨테이너 위 글자 · 채움(점).
({CoreColor container, CoreColor onContainer, CoreColor fill}) foundationCategoryTones(CoreCategoryColor hue) => (
  container: CoreCategoryPalette.tone(hue, .lightContainer),
  onContainer: CoreCategoryPalette.tone(hue, .lightOnContainer),
  fill: CoreCategoryPalette.tone(hue, .lightFill),
);

/// Semantic 표의 열 이름.
const List<String> kSemanticColumns = ['토큰', '라이트', '다크', '용도'];

/// Semantic 표의 행 — 토큰 · 용도. 값은 기본 테마의 두 스킴에서 읽는다.
const List<({CoreColorToken token, String role})> kSemanticRoles = [
  (token: CoreColors.onSurface, role: '본문, 제목'),
  (token: CoreColors.onSurfaceVariant, role: '설명, 보조 글자'),
  (token: CoreColors.onSurfaceSubtle, role: '라벨, 메타 정보'),
  (token: CoreColors.surface, role: '페이지 배경'),
  (token: CoreColors.surfaceContainer, role: '섹션, 타일 배경'),
  (token: CoreColors.surfaceRaised, role: '선택된 세그먼트, 탭'),
  (token: CoreColors.outlineSubtle, role: '떠 있는 패널 테두리'),
  (token: CoreColors.primary, role: '주 버튼 (neutral/900)'),
  (token: CoreColors.error, role: '오류 상태 채움'),
  (token: CoreColors.success, role: '성공 상태 채움'),
  (token: CoreColors.warning, role: '경고 상태 채움'),
  (token: CoreColors.info, role: '정보 상태 채움'),
];

/// 브랜드 예제 코드의 이름표.
const String kBrandThemeTitle = 'theme.dart';

/// 브랜드 색 하나로 테마를 만드는 코드.
///
/// 색 소스가 primary 와 함께 onPrimary · hover · pressed · container 색을
/// 만든다. primary 하나만 덮어쓰면 hover · pressed 색이 기본 뉴트럴로 남는다.
const String kBrandThemeSource = '''final brand = CoreBrandSchemeSource
    .fromColor(CoreColor(0xFF2F6BFF));

CoUIApp(
  theme: ThemeData.fromCore(
    CoreThemePresets.light.copyWith(
      colorScheme: brand.light(),
    ),
  ),
)''';

/// 브랜드 예제의 버튼 — 이름과 브랜드 색. 색이 없으면 기본 테마다.
const List<({String label, CoreColor? brandColor})> kBrandSamples = [
  (label: '기본', brandColor: null),
  (label: '고객사 B', brandColor: CoreColor(0xFF2F6BFF)),
  (label: '고객사 C', brandColor: CoreColor(0xFFF67B0C)),
];

/// 브랜드 예제 버튼 하나의 채움과 글자색 — 그 색 소스가 라이트 모드에서
/// 만드는 primary · onPrimary.
({CoreColor primary, CoreColor onPrimary}) foundationBrandColors(CoreColor? brandColor) {
  final scheme = brandColor == null
      ? CoreThemePresets.lightColorScheme
      : CoreBrandSchemeSource.fromColor(brandColor).light().resolved(.light);
  // 스킴의 색은 토큰 이름(`primary`)을 함께 들고 있어, 그대로 넘기면 Web 이
  // 페이지 테마의 `primary` 로 칠한다. 이 견본은 그 브랜드의 값을 보여 주는
  // 것이므로 값만 남긴다.
  return (primary: CoreColor(scheme.primary.argb), onPrimary: CoreColor(scheme.onPrimary.argb));
}

// ── 타이포그래피 ──────────────────────────────────────────────────

/// 두 서체 — 견본 · 이름 · 쓰는 역할 · 고정폭인지.
const List<({String sample, String name, String roles, bool mono})> kFoundationFonts = [
  (sample: '가나다 Aa 123', name: 'Pretendard', roles: 'display, headline, title, body, label', mono: false),
  (sample: 'const a = 0;', name: 'Geist Mono', roles: 'code 역할 3종 (400)', mono: true),
];

/// 스케일 표의 열 이름.
const List<String> kTypographyColumns = ['역할', '크기 / 행간 / 굵기', '예시'];

/// 스케일 표의 행 — 역할 이름(kebab) · 스타일. `CoreTextStyles.values` 순서다.
List<({String name, CoreTextStyle style})> get foundationTypeRoles => [
  for (final role in CoreTextStyles.values) (name: role.name, style: role.read(CoreTypography.coui)),
];

/// `label-xl2` → `Label XL2` — 표에 보이는 역할 이름.
String foundationRoleName(String kebab) => kebab
    .split('-')
    .map((part) {
      if (part.length <= 2 || part == 'xl2') return part.toUpperCase();
      return '${part[0].toUpperCase()}${part.substring(1)}';
    })
    .join(' ');

/// 역할의 크기 · 행간 · 굵기 — `52 / 1.4 / 700`, 고정 줄 상자면 `11 / 21px / 400`.
String foundationTypeMeta(CoreTextStyle style) {
  final lineHeight = style.lineHeightPx == null
      ? foundationNumber(style.lineHeight)
      : '${foundationNumber(style.lineHeightPx)}px';
  return '${foundationNumber(style.fontSize)} / $lineHeight / ${foundationNumber(style.fontWeight)}';
}

/// 역할의 예시 문장 — 역할 무리(display · headline · title · code · 나머지)마다 하나.
String foundationTypeSpecimen(String kebab) => switch (kebab.split('-').first) {
  'display' => '크로스 플랫폼 UI',
  'headline' => '크로스 플랫폼 UI 컴포넌트',
  'title' => '크로스 플랫폼 UI 컴포넌트 라이브러리',
  'code' => 'final value = 0;',
  _ => 'CoUI는 크로스 플랫폼 UI 컴포넌트 라이브러리입니다.',
};

/// 정수면 소수점 없이, 아니면 그대로. 값이 없으면 `—`.
String foundationNumber(num? number) => number == null
    ? '—'
    : number == number.roundToDouble()
    ? number.toInt().toString()
    : number.toString();

// ── 아이콘 ────────────────────────────────────────────────────────

/// 아이콘 세트 — 이름 · 아이콘 수 · 덧붙임. 수는 카탈로그 목록에서 센다.
List<({String label, int count, String? note})> get foundationIconSets => [
  (label: 'Lucide', count: lucideNames.length, note: 'CoUI 컴포넌트 기본'),
  (label: 'Bootstrap', count: bootstrapNames.length, note: null),
  (label: 'Radix', count: radixNames.length, note: null),
  (label: 'HeroIcons', count: heroNames.length, note: null),
];

/// `1695` → `1,695`.
String foundationCount(int count) =>
    count.toString().replaceAllMapped(RegExp(r'\d(?=(\d{3})+$)'), (match) => '${match[0]},');

// ── 레이아웃 · 모양 · 효과 ────────────────────────────────────────

/// 간격 사다리의 대표 단계 — 토큰 · px.
const List<({String token, double value})> kFoundationSpacing = [
  (token: 'space4', value: CoreSpace.space4),
  (token: 'space8', value: CoreSpace.space8),
  (token: 'space12', value: CoreSpace.space12),
  (token: 'space16', value: CoreSpace.space16),
  (token: 'space24', value: CoreSpace.space24),
  (token: 'space32', value: CoreSpace.space32),
  (token: 'space48', value: CoreSpace.space48),
  (token: 'space64', value: CoreSpace.space64),
];

/// 반경 역할 — 역할 · px.
const List<({String role, double radius})> kFoundationRadii = [
  (role: 'part', radius: CoreRadiusRole.part),
  (role: 'control', radius: CoreRadiusRole.control),
  (role: 'panel', radius: CoreRadiusRole.panel),
  (role: 'surface', radius: CoreRadiusRole.surface),
  (role: 'modal', radius: CoreRadiusRole.modal),
];

/// 그림자 견본 — 토큰 · 레이어.
const List<({String token, List<CoreShadowLayer> layers})> kFoundationShadows = [
  (token: 'xs', layers: CoreShadow.xs),
  (token: 'sm', layers: CoreShadow.sm),
  (token: 'md', layers: CoreShadow.md),
  (token: 'lg', layers: CoreShadow.lg),
  (token: 'xl', layers: CoreShadow.xl),
];

/// 상태 투명도 견본 — 상태 · 값. 첫 칸은 겹침이 없는 기본 상태다.
const List<({String state, double opacity})> kFoundationOpacity = [
  (state: '기본', opacity: 0),
  (state: 'hover', opacity: CoreOpacity.hover),
  (state: 'focus', opacity: CoreOpacity.focus),
  (state: 'pressed', opacity: CoreOpacity.pressed),
  (state: 'disabled', opacity: CoreOpacity.disabled),
];

/// 상태 투명도 견본의 이름표 — `hover 3%`. 기본 상태는 이름만.
String foundationOpacityLabel(({String state, double opacity}) sample) =>
    sample.opacity == 0 ? sample.state : '${sample.state} ${(sample.opacity * 100).round()}%';

/// 포커스 링 견본의 버튼 글자.
const String kFocusRingSampleLabel = '저장하기';

/// 포커스 링 견본 아래의 값 — `ringWidth 2 · ringOffset 2`.
String get foundationFocusRingCaption =>
    'ringWidth ${foundationNumber(CoreFocusRing.ringWidth)} · ringOffset ${foundationNumber(CoreFocusRing.ringOffset)}';

// ── 모션 · 레이어 ─────────────────────────────────────────────────

/// 지속 시간 alias — 이름 · ms.
const List<({String alias, int milliseconds})> kFoundationDurations = [
  (alias: 'instant', milliseconds: CoreDuration.instant),
  (alias: 'fast', milliseconds: CoreDuration.fast),
  (alias: 'normal', milliseconds: CoreDuration.normal),
  (alias: 'moderate', milliseconds: CoreDuration.moderate),
  (alias: 'slow', milliseconds: CoreDuration.slow),
];

/// 이징 alias — 이름 · 곡선 · 곡선의 이름과 쓰임.
const List<({String alias, CoreCubicBezier curve, String description})> kFoundationEasings = [
  (alias: 'move', curve: CoreEasing.move, description: 'ease-in-out · 화면 안 상태 전환'),
  (alias: 'enter', curve: CoreEasing.enter, description: 'ease-out · 등장'),
  (alias: 'exit', curve: CoreEasing.exit, description: 'ease-in · 퇴장'),
  (alias: 'feedback', curve: CoreEasing.feedback, description: 'ease-out-back · 약한 오버슈트'),
];

/// 곡선의 cubic-bezier 값 — `0.42, 0, 0.58, 1`.
String foundationCubicBezier(CoreCubicBezier curve) =>
    [curve.x1, curve.y1, curve.x2, curve.y2].map(foundationNumber).join(', ');

/// 레이어 견본 — 아래에서 위로 쌓이는 순서의 토큰 · 이름.
const List<({String token, String label})> kFoundationLayers = [
  (token: 'z0', label: '기본 콘텐츠'),
  (token: 'z20', label: '헤더'),
  (token: 'z40', label: '스크림'),
  (token: 'z50', label: '모달'),
  (token: 'z70', label: '툴팁'),
  (token: 'z80', label: '토스트'),
];
