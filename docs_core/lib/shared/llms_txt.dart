/// `llms.txt` — AI 소비자를 위한 문서 사이트 색인. **사이트 구조에서 파생**한다.
///
/// 형식은 llmstxt.org 규약을 따른다: H1 이름 · 인용 요약 · 짧은 산문 ·
/// `## 섹션` 마다 `- [이름](url): 설명` 링크 목록. 섹션은 사이트의 탭이고
/// ([kDocsNavTabs]), 그 아래 링크는 탭의 페이지다 — 손으로 관리하는 또 하나의
/// 목록을 만들지 않는다. 사이드바 · 그리드 · 검색이 같은 구조에서 파생되는
/// 것과 같은 이유다: 사본은 언젠가 한 곳만 빠뜨린다.
///
/// 컴포넌트 탭만 카테고리마다 섹션 하나로 편다(`## Components: Form`) —
/// 백 몇십 개가 한 섹션에 놓이면 색인이 색인 구실을 못 한다.
///
/// **언어는 영문이다.** 문서 사이트 본문은 한국어가 primary 지만 AI 소비
/// 표면은 영문으로 낸다(`process/docs-site.md` "언어 정책"). 그래서 구조의
/// 사람용 문자열이 아니라 영문 전용 필드([DocsNavPage.englishLabel] ·
/// [DocsNavPage.englishDescription])를 읽는다.
///
/// **범위는 색인이다** — 링크와 한 줄 요약. 페이지 본문을 이어 붙인
/// `llms-full.txt` 는 만들지 않는다: 본문은 한국어라 영문 AI 표면 정책과
/// 맞지 않는다.
///
/// 순수 Dart 다(jaspr · Flutter import 없음). 생성기
/// `tool/gen_llms_txt.dart` 가 이 함수의 결과를 `docs_site/web/llms.txt` 에
/// 쓰고, `test/registry/llms_txt_sync_test.dart` 가 커밋된 파일이 이 함수의
/// 결과와 같은지 게이트한다.
library;

import 'component_catalog.dart';
import 'docs_navigation.dart';

/// 문서 사이트의 공개 origin — 배포 워크플로가 GitHub Pages 에 싣는 CNAME 과
/// 같은 호스트다. `llms.txt` 의 링크는 절대 URL 이어야 한다(AI 소비자는
/// 파일을 사이트 밖에서 읽는다).
const String kDocsSiteOrigin = 'https://coui.cocode.im';

/// `llms.txt` 전체 본문을 만든다. 같은 카탈로그면 항상 같은 바이트를 낸다.
String renderLlmsTxt() {
  final buffer = StringBuffer()
    ..writeln('# CoUI')
    ..writeln()
    ..writeln(
      '> CoUI is a cross-platform UI component library for Dart: the same '
      'components, with the same named-properties API and the same design '
      'tokens, render on Flutter (mobile/desktop) and on the web via Jaspr.',
    )
    ..writeln()
    ..writeln(
      '- Packages: `coui_flutter` (Flutter widgets), `coui_web` (Jaspr '
      'components), `coui_core` (platform-neutral contracts, styles and '
      'design tokens shared by both).',
    )
    ..writeln(
      '- Import one barrel per platform: '
      '`package:coui_flutter/coui_flutter.dart` or '
      '`package:coui_web/coui_web.dart`.',
    )
    ..writeln(
      '- Visual overrides go through a single `xxxStyle: CoreXxxStyle?` '
      'parameter per component; semantic choices such as `variant` and '
      '`size` are plain parameters.',
    )
    ..writeln(
      '- The linked documentation pages are written in Korean; component '
      'names, parameters and code samples are English.',
    )
    ..writeln();

  for (final tab in kDocsNavTabs) {
    if (tab.id == _componentsTabId) {
      _writeComponents(buffer, tab);
      continue;
    }

    buffer
      ..writeln('## ${tab.label}')
      ..writeln();
    for (final page in tab.pages) {
      buffer.writeln(_link(page.englishLabel, page.path, page.englishDescription));
    }
    buffer.writeln();
  }

  buffer
    ..writeln('## Optional')
    ..writeln()
    ..writeln(
      _link(
        'Source code',
        'https://github.com/coco-de/coui',
        'Repository with all three packages',
      ),
    );

  return buffer.toString();
}

/// 컴포넌트 탭의 id — 이 탭만 카테고리마다 섹션으로 편다.
const String _componentsTabId = 'components';

/// 컴포넌트 탭을 쓴다 — 전체 보기 한 줄, 그다음 카테고리마다 섹션 하나.
void _writeComponents(StringBuffer buffer, DocsNavTab tab) {
  buffer
    ..writeln('## ${tab.label}')
    ..writeln()
    ..writeln(
      _link(
        kDocsComponentsOverviewPage.englishLabel,
        kDocsComponentsOverviewPage.path,
        kDocsComponentsOverviewPage.englishDescription,
      ),
    )
    ..writeln();

  for (final group in kDocsComponentGroups) {
    buffer
      ..writeln('## ${tab.label}: ${group.title}')
      ..writeln();
    final groupDescription = group.description;
    if (groupDescription != null) {
      buffer
        ..writeln(groupDescription)
        ..writeln();
    }
    for (final entry in group.items) {
      buffer.writeln(
        _link(
          entry.name,
          '/components/${entry.slug}',
          _componentNote(entry),
        ),
      );
    }
    buffer.writeln();
  }
}

String _componentNote(DocsComponentEntry entry) {
  final status = entry.deprecation;
  if (status == null) return entry.llmsSummary;
  final replacement = status.replacementName;
  final suffix = replacement == null
      ? 'deprecated since ${status.since}'
      : 'deprecated since ${status.since}, use $replacement';
  return '${entry.llmsSummary} ($suffix)';
}

String _link(String title, String pathOrUrl, String? note) {
  final url = pathOrUrl.startsWith('http') ? pathOrUrl : '$kDocsSiteOrigin$pathOrUrl';
  return note == null ? '- [$title]($url)' : '- [$title]($url): $note';
}
