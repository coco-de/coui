/// 랜딩이 보여 주는 값 — 전부 살아 있는 출처에서 읽는다.
///
/// 랜딩은 숫자와 이름을 많이 말한다: 컴포넌트 수, 카테고리별 개수, 토큰
/// 이름, 변형 이름, 글자 크기. 손으로 적으면 전부 지금은 맞고, 카탈로그나
/// 계약이 바뀌는 날 조용히 거짓이 된다. 그래서 이 파일은 값을 적지 않고
/// 카탈로그 · `coui_core` 계약 · 패키지 CHANGELOG 에서 **읽는 방법**만
/// 적는다. 뷰는 여기서 받은 것을 그리기만 한다.
library;

import 'package:coui_core/coui_core.dart';
import 'package:docs_core/markdown/changelog.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_core/shared/guide_catalog.dart';

// ── 컴포넌트 수 ───────────────────────────────────────────────────

/// 랜딩이 수를 내림하는 단위.
const int _kFigureStep = 10;

/// 카탈로그의 컴포넌트 수.
int get siteComponentTotal => kDocsComponentGroups.fold(0, (sum, group) => sum + group.items.length);

/// 랜딩이 말하는 컴포넌트 수 — 십 단위로 내린 값.
///
/// "160+" 로 읽히는 숫자다. 내림이라 컴포넌트가 하나 늘어도 문장이 틀리지
/// 않고, 열 개가 늘면 숫자가 따라 오른다.
int get siteComponentFloor => (siteComponentTotal ~/ _kFigureStep) * _kFigureStep;

// ── 경로 ──────────────────────────────────────────────────────────

/// 가이드 경로를 카탈로그에서 찾는다.
///
/// 경로를 문자열로 적으면 가이드가 옮겨지거나 지워져도 링크는 그대로
/// 남는다. 카탈로그에 없는 slug 는 여기서 던진다 — 죽은 링크가 조용히
/// 나가는 것보다 빌드가 멈추는 편이 낫다.
String siteGuidePath(String slug) {
  for (final guide in kDocsGuides) {
    if (guide.slug == slug) return guide.path;
  }
  throw StateError('가이드 카탈로그에 `$slug` 가 없다');
}

/// 컴포넌트 문서 경로와 표시 이름을 카탈로그에서 찾는다.
DocsComponentEntry siteComponent(String slug) {
  for (final group in kDocsComponentGroups) {
    for (final item in group.items) {
      if (item.slug == slug) return item;
    }
  }
  throw StateError('컴포넌트 카탈로그에 `$slug` 가 없다');
}

// ── 진입 카드 ─────────────────────────────────────────────────────

/// "어디서부터 시작할까요?" 의 카드 하나.
class SiteEntryPoint {
  /// 진입 카드를 만든다.
  const SiteEntryPoint({
    required this.title,
    required this.description,
    required this.action,
    required this.href,
  });

  /// 섹션 이름.
  final String title;

  /// 그 섹션이 담는 것.
  final String description;

  /// 이동 문구.
  final String action;

  /// 목적지.
  final String href;
}

/// 진입 카드 — 읽는 순서대로.
List<SiteEntryPoint> get siteEntryPoints => [
  const SiteEntryPoint(
    title: 'Getting Started',
    description: '설치부터 첫 화면까지, Flutter와 Jaspr Web 각각의 경로로 안내합니다.',
    action: '빠른 시작 보기',
    href: '/getting-started',
  ),
  const SiteEntryPoint(
    title: 'Foundations',
    description: '색상, 타이포그래피, 모양처럼 모든 컴포넌트가 함께 쓰는 기초 값을 정리했습니다.',
    action: '토큰 살펴보기',
    href: '/tokens/overview',
  ),
  SiteEntryPoint(
    title: 'Components',
    description: '$siteComponentFloor개 이상 컴포넌트의 사용법과 두 플랫폼 코드를 한곳에서 봅니다.',
    action: '전체 보기',
    href: '/components-overview',
  ),
  SiteEntryPoint(
    title: 'Resources',
    description: 'Figma 라이브러리, AI · MCP 연결, 설계 문서 기준, Changelog를 모았습니다.',
    action: '리소스 보기',
    href: siteGuidePath('figma-library'),
  ),
];

// ── 코드 타일 ─────────────────────────────────────────────────────

/// 코드 타일의 한 플랫폼.
class SiteCodeSample {
  /// 플랫폼 하나의 코드를 만든다.
  const SiteCodeSample({required this.id, required this.label, required this.package});

  /// 탭과 패널의 DOM id 에 쓰는 이름.
  final String id;

  /// 탭에 적는 이름.
  final String label;

  /// 그 플랫폼의 패키지 — 두 코드가 갈리는 유일한 자리다.
  final String package;

  /// 첫 줄 — import.
  String get importLine => "import 'package:$package/$package.dart';";
}

/// 코드 타일의 두 플랫폼 — 첫 항목이 처음 보이는 탭이다.
const List<SiteCodeSample> kSiteCodeSamples = [
  SiteCodeSample(id: 'flutter', label: 'Flutter', package: 'coui_flutter'),
  SiteCodeSample(id: 'jaspr', label: 'Jaspr', package: 'coui_web'),
];

/// 두 플랫폼이 글자 그대로 함께 쓰는 호출.
///
/// 변형 이름은 enum 에서 읽는다 — 멤버 이름이 바뀌면 이 견본이 컴파일
/// 되지 않는 코드를 보여 주는 대신 여기서 빌드가 멈춘다.
List<String> get siteCodeCall => [
  'Button(',
  '  variant: CoreButtonVariant.${CoreButtonVariant.primary.name},',
  '  onPressed: save,',
  "  child: Text('저장하기'),",
  ')',
];

// ── 타이포그래피 타일 ─────────────────────────────────────────────

/// 타이포그래피 타일의 한 줄 — 견본의 이름과, 그 견본을 그리는 역할.
///
/// 견본은 역할 하나로 그린다. 그래서 크기 · 굵기 · 줄 높이 · 자간이 그
/// 역할의 것이고, 옆에 적는 숫자([size])도 그 역할의 크기다 — 그린 글자와
/// 적은 숫자가 갈리지 않는다. 좁은 타일에 네 줄이 사다리로 읽히도록
/// 이름(Display · Title …)보다 한 단 작은 역할로 그린다.
class SiteTypeSample {
  /// 견본 한 줄을 만든다.
  const SiteTypeSample({required this.label, required this.role});

  /// 줄에 적는 이름.
  final String label;

  /// 견본을 그리는 역할.
  final CoreTextStyleToken role;

  /// 그 역할의 글자 크기(px) — 스케일에서 읽는다.
  int get size => (role.read(CoreTypography.coui).fontSize ?? 0).round();
}

/// 타이포그래피 타일의 견본 — 큰 역할부터.
const List<SiteTypeSample> kSiteTypeSamples = [
  SiteTypeSample(label: 'Display', role: CoreTextStyles.headlineLarge),
  SiteTypeSample(label: 'Title', role: CoreTextStyles.headlineSmall),
  SiteTypeSample(label: 'Body', role: CoreTextStyles.titleSmall),
  SiteTypeSample(label: 'Label', role: CoreTextStyles.labelSmall),
];

// ── 색상 타일 ─────────────────────────────────────────────────────

/// 색상 타일이 보여 주는 neutral 단계 — 밝은 쪽부터.
const List<int> kSiteNeutralSteps = [150, 300, 500, 700, 850];

/// CoUI neutral 램프의 단계 → 색.
Map<int, CoreColor> get siteNeutralRamp => CouiColorPresets.palette.neutral.steps;

// ── Figma 라이브러리 · MCP 타일 ───────────────────────────────────

/// 레이어 목록의 한 줄 — 컴포넌트 하나와 그 변형 속성 하나.
///
/// Figma 라이브러리의 세트 이름과 변형 속성은 코드 계약에서 생성된다.
/// 그래서 이름은 카탈로그에서, 속성 값은 `coui_core` 의 enum 에서, 토큰은
/// 그 변형의 기본 스타일에서 읽는다 — 셋 다 여기 적힌 문자열이 아니다.
class SiteLayer {
  /// 레이어 한 줄을 만든다.
  const SiteLayer({
    required this.slug,
    required this.property,
    required this.value,
    required this.token,
  });

  /// 카탈로그 slug.
  final String slug;

  /// 변형 속성 이름 (`variant` · `size` · `tone`).
  final String property;

  /// 그 속성의 값 — enum 멤버 이름.
  final String value;

  /// 그 변형의 채움이 읽는 색 토큰 이름.
  final String token;

  /// 컴포넌트 이름 — 카탈로그가 정한다.
  String get name => siteComponent(slug).name;

  /// 컴포넌트 문서.
  String get href => '/components/$slug';

  /// Figma 가 변형을 적는 방식 — `Variant=primary`.
  String get figmaProperty => '${property[0].toUpperCase()}${property.substring(1)}=$value';
}

String _tokenName(CoreColor color) {
  final token = color.token;
  if (token == null) throw StateError('토큰이 없는 색은 이름을 댈 수 없다');
  return token.name;
}

/// 레이어 목록 — 목록의 첫 줄이 처음 선택된 줄이다.
List<SiteLayer> get siteLayers {
  final button = CoreButtonStyle.defaultsByVariant[CoreButtonVariant.primary];
  final textField = CoreTextFieldStyle.defaultsByVariant[CoreTextFieldVariant.filled];
  final toggle = CoreToggleStyle.defaultsByVariant[CoreToggleVariant.defaultVariant];
  final badge = CoreBadgeStyle.defaultsByTone[CoreBadgeTone.success];
  final buttonFill = button?.backgroundColor;
  if (buttonFill == null || textField == null || toggle == null || badge == null) {
    throw StateError('레이어 목록이 읽는 변형의 기본 스타일이 없다');
  }

  return [
    SiteLayer(
      slug: 'button',
      property: 'variant',
      value: CoreButtonVariant.primary.name,
      token: _tokenName(buttonFill),
    ),
    SiteLayer(
      slug: 'text-field',
      property: 'variant',
      value: CoreTextFieldVariant.filled.name,
      token: _tokenName(textField.backgroundColor),
    ),
    SiteLayer(
      slug: 'toggle',
      property: 'size',
      value: CoreComponentSize.md.name,
      token: _tokenName(toggle.activeTrack),
    ),
    SiteLayer(
      slug: 'badge',
      property: 'tone',
      value: CoreBadgeTone.success.name,
      token: _tokenName(badge.tonalBackgroundColor),
    ),
  ];
}

// ── 최근 업데이트 ─────────────────────────────────────────────────

/// 릴리스 한 건이 어떤 종류의 변경인가.
enum SiteUpdateKind {
  /// 새 기능이 있다.
  feature('Feature'),

  /// 수정만 있다.
  fix('Fix'),

  /// 그 밖 — 리팩터링 · 문서 · 성능.
  update('Update');

  const SiteUpdateKind(this.label);

  /// 배지에 적는 이름.
  final String label;
}

/// "최근 업데이트" 의 한 줄.
class SiteUpdate {
  /// 업데이트 한 줄을 만든다.
  const SiteUpdate({
    required this.version,
    required this.kind,
    required this.summary,
    required this.date,
  });

  /// 버전 — `v0.183.0`.
  final String version;

  /// 변경의 종류.
  final SiteUpdateKind kind;

  /// 그 릴리스의 첫 항목.
  final String summary;

  /// 릴리스 날짜 — `11.12`.
  final String date;
}

/// release-please 가 쓰는 섹션 제목 (`release-please-config.json`).
const String _kFeatureSection = '기능';
const String _kFixSection = '버그 수정';

/// 항목 끝에 붙는 이슈 · 커밋 참조와 `closes` 꼬리.
final RegExp _trailingReferences = RegExp(r'(\s*\((#\d+|[0-9a-f]{7,})\)|,?\s*closes\s+#\d+)+\s*$');

/// 항목 안의 굵게 표시.
final RegExp _bold = RegExp(r'\*\*([^*]+)\*\*');

/// 항목 안의 인라인 코드 표시.
final RegExp _inlineCode = RegExp('`([^`]*)`');

/// 한 릴리스에서 랜딩에 올릴 한 줄을 고른다.
///
/// 기능이 있으면 기능, 없으면 수정, 그것도 없으면 처음 나오는 섹션의 첫
/// 항목이다. 항목이 하나도 없는 릴리스는 올리지 않는다(`null`).
SiteUpdate? siteUpdateOf(ChangelogEntry entry) {
  final (kind, bullets) = switch (entry.sections) {
    {_kFeatureSection: final features} when features.isNotEmpty => (SiteUpdateKind.feature, features),
    {_kFixSection: final fixes} when fixes.isNotEmpty => (SiteUpdateKind.fix, fixes),
    final sections => (
      SiteUpdateKind.update,
      sections.values.firstWhere((bullets) => bullets.isNotEmpty, orElse: () => const <String>[]),
    ),
  };
  if (bullets.isEmpty) return null;

  final summary = stripChangelogNoise(bullets.first)
      .replaceAll(_trailingReferences, '')
      .replaceAllMapped(_bold, (match) => match.group(1) ?? '')
      .replaceAllMapped(_inlineCode, (match) => match.group(1) ?? '')
      .trim();

  // `2026-11-12` → `11.12`. 형식이 다르면 적힌 그대로 둔다.
  final parts = entry.date.split('-');
  final date = parts.length == 3 ? '${parts[1]}.${parts[2]}' : entry.date;

  return SiteUpdate(version: 'v${entry.version}', kind: kind, summary: summary, date: date);
}

/// CHANGELOG 원문에서 최근 [count] 건을 뽑는다.
List<SiteUpdate> siteUpdatesFrom(String changelogSource, {required int count}) => [
  // 항목 없는 릴리스를 건너뛰어도 [count] 건이 차도록 넉넉히 읽는다.
  for (final entry in parseChangelogEntries(changelogSource, limit: count * 3)) ?siteUpdateOf(entry),
].take(count).toList();
