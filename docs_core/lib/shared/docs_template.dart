/// 문서 페이지 템플릿 — 컴포넌트 페이지의 기존 구성 · v2 구성과 Blocks
/// 페이지의 구성.
///
/// v2 는 Figma 의 컴포넌트 페이지 템플릿(CoUI website, `04 Components`)을
/// 따르는 구성이다. 페이지는 frontmatter `template: v2` 로 고른다. Blocks
/// 페이지(`content/blocks`)는 Figma 의 `05 Blocks` 를 따르는 블록 구성
/// 하나뿐이라 고를 것이 없다. 사이트의 레이아웃 · 문서 계약 테스트가 이
/// 파일을 함께 읽는다 — 섹션 목록이 두 곳에 있으면 한쪽만 바뀌는 날
/// 테스트가 다른 구성을 강제한다.
///
/// 순수 Dart 다(사이트와 네이티브 문서 앱이 함께 읽는다).
library;

/// v2 템플릿을 고르는 frontmatter 값.
const String kDocsTemplateV2 = 'v2';

/// v2 페이지의 H2 섹션 — 이 순서로 놓인다.
///
/// 컴포넌트에 해당하는 것만 넣는다(크기 · 형태 · 상태 · 배치 등은 그
/// 축이 있는 컴포넌트만). 목록에 없는 섹션(링크 버튼처럼 그 컴포넌트에만
/// 있는 것)은 순서 검사에서 빠진다.
const List<String> kDocsV2Sections = [
  '플레이그라운드',
  '구조',
  'Variant',
  '크기',
  '형태',
  '상태',
  '사용 가이드',
  '배치',
  '테마와 스타일',
  '접근성',
  '플랫폼 차이',
  'API',
  '관련 컴포넌트',
];

/// v2 페이지가 반드시 갖는 섹션.
///
/// 기존 구성이 요구하던 것(Live Preview · Props · 동작 스펙 · 플랫폼 차이 ·
/// 사용 가이드라인 · 접근성)의 v2 자리다. 동작 스펙은 v2 에서 상태 · 링크
/// 같은 축별 섹션으로 나뉘므로 하나의 필수 섹션이 아니다.
const List<String> kDocsV2RequiredSections = ['플레이그라운드', '사용 가이드', '접근성', '플랫폼 차이', 'API'];

/// v2 의 접근성 섹션 이름 — 다섯 축(역할 · 키보드 · 스크린 리더 · 포커스
/// 관리 · 알려진 제약)은 기존 구성과 같은 `###` 라벨로 이 아래에 둔다.
const String kDocsV2AccessibilitySection = '접근성';

/// v2 의 사용 가이드 섹션 이름.
const String kDocsV2UsageSection = '사용 가이드';

/// 마크다운 원문의 frontmatter 가 v2 템플릿을 고르는가.
bool docsUsesTemplateV2(String markdown) {
  final match = RegExp(r'^---\n(.*?)\n---', dotAll: true).firstMatch(markdown);
  if (match == null) return false;
  return RegExp('^template:\\s*$kDocsTemplateV2\\s*\$', multiLine: true).hasMatch(match.group(1)!);
}

/// Blocks 페이지의 H2 섹션 — 이 순서로 놓인다.
///
/// Figma 의 `05 Blocks` 페이지(Hero · Footer)를 따른다. 블록에 해당하는 것만
/// 넣는다(구조 · 등장 애니메이션 · 사용 가이드는 그것이 있는 블록만). 목록에
/// 없는 섹션은 순서 검사에서 빠진다.
const List<String> kDocsBlockSections = [
  '구조',
  '레이아웃',
  '기본 사용법',
  '속성',
  '스타일',
  '등장 애니메이션',
  '접근성',
  '사용 가이드',
  '플랫폼 차이',
];

/// Blocks 페이지가 반드시 갖는 섹션.
///
/// 플랫폼 차이는 시안에 없지만 필수다 — 블록은 Web 과 Flutter 가 함께
/// 그리므로, 그 자리가 없으면 두 플랫폼의 차이가 페이지에서 통째로 빠진다.
const List<String> kDocsBlockRequiredSections = ['레이아웃', '기본 사용법', '속성', '접근성', '플랫폼 차이'];
