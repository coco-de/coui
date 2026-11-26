@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/shared/block_catalog.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_core/shared/docs_navigation.dart';
import 'package:docs_core/shared/guide_catalog.dart';
import 'package:test/test.dart';

/// 사이트 구조(`kDocsNavTabs`)가 스스로 모순되지 않는지, 그리고 콘텐츠와
/// 어긋나지 않는지 본다.
///
/// 헤더의 탭, 탭마다 다른 사이드바, 이전 · 다음 페이저, 검색 인덱스,
/// `llms.txt`, 네이티브 앱의 사이드바가 전부 이 구조 하나를 읽는다. 그래서
/// 여기의 구멍은 한 표면이 아니라 여섯 표면에 같은 모양으로 나타난다.
void main() {
  final pages = [for (final location in kDocsNavLocations) location.page];

  /// 구조의 경로 → 그 페이지의 마크다운 파일.
  File contentOf(String path) {
    final direct = File('content$path.md');
    return direct.existsSync() ? direct : File('content$path/index.md');
  }

  group('구조', () {
    test('탭은 다섯이고 id 가 서로 다르다', () {
      expect(kDocsNavTabs.map((tab) => tab.label), [
        'Getting Started',
        'Foundations',
        'Components',
        'Blocks',
        'Resources',
      ]);
      expect(kDocsNavTabs.map((tab) => tab.id).toSet(), hasLength(kDocsNavTabs.length));
    });

    test('한 페이지는 한 자리에만 있다', () {
      // 두 탭에 걸친 페이지는 어느 사이드바를 그릴지, 페이저의 앞뒤가
      // 무엇인지 답이 둘이 된다.
      final paths = pages.map((page) => page.path).toList();
      expect(paths.toSet(), hasLength(paths.length));
    });

    test('탭의 주소는 그 탭의 첫 페이지다', () {
      for (final tab in kDocsNavTabs) {
        expect(tab.path, tab.groups.first.pages.first.path, reason: tab.id);
        expect(tab.pages, isNotEmpty, reason: tab.id);
      }
    });

    test('모든 묶음에 이름과 페이지가 있다', () {
      for (final tab in kDocsNavTabs) {
        for (final group in tab.groups) {
          expect(group.title, isNotEmpty, reason: tab.id);
          expect(group.pages, isNotEmpty, reason: '${tab.id} / ${group.title}');
        }
      }
    });
  });

  group('카탈로그와의 대응', () {
    test('모든 가이드가 구조에 한 번 있다', () {
      for (final guide in kDocsGuides) {
        expect(pages.where((page) => page.path == guide.path), hasLength(1), reason: guide.slug);
      }
    });

    test('모든 컴포넌트와 블록이 구조에 한 번 있다', () {
      for (final entry in kDocsComponentEntries) {
        expect(pages.where((page) => page.path == '/components/${entry.slug}'), hasLength(1), reason: entry.slug);
      }
      for (final block in kDocsBlocks) {
        expect(pages.where((page) => page.path == block.path), hasLength(1), reason: block.slug);
      }
    });

    test('컴포넌트의 폐기 표시가 카탈로그에서 온다', () {
      for (final entry in kDocsComponentEntries) {
        final page = pages.singleWhere((page) => page.path == '/components/${entry.slug}');
        expect(page.deprecated, entry.isDeprecated, reason: entry.slug);
      }
    });
  });

  group('콘텐츠와의 대응', () {
    test('구조의 모든 페이지에 마크다운이 있다', () {
      final missing = [
        for (final page in pages)
          if (!contentOf(page.path).existsSync()) page.path,
      ];

      expect(missing, isEmpty, reason: '사이드바의 링크가 없는 페이지를 가리킨다');
    });

    test('사이드바의 이름이 그 페이지의 제목이다', () {
      // 가이드 · 최상위 페이지의 이름은 손으로 적는다. 사이드바에서 누른
      // 이름과 도착한 페이지의 제목이 다르면 잘못 온 것으로 읽힌다.
      // 컴포넌트와 블록은 카탈로그의 이름을 쓰므로 여기서 보지 않는다.
      final catalogued = {
        for (final entry in kDocsComponentEntries) '/components/${entry.slug}',
        for (final block in kDocsBlocks) block.path,
        // 한 탭의 "전체 보기" — 사이드바의 이름은 자리를, 제목은 내용을 말한다.
        kDocsComponentsOverviewPage.path,
        kDocsBlocksOverviewPage.path,
      };
      final title = RegExp(r'^title:\s*(.+)$', multiLine: true);

      for (final page in pages.where((page) => !catalogued.contains(page.path))) {
        final found = title.firstMatch(contentOf(page.path).readAsStringSync())?.group(1)?.trim();

        expect(found, startsWith(page.label), reason: '${page.path} 의 제목이 사이드바의 이름과 다르다');
      }
    });

    test('옮겨진 주소는 구조 안의 페이지로 간다', () {
      for (final moved in kDocsMovedPaths.entries) {
        expect(docsNavLocate(moved.key), isNull, reason: '${moved.key} 는 옛 주소인데 구조에 남아 있다');
        expect(docsNavLocate(moved.value), isNotNull, reason: '${moved.key} 가 없는 페이지로 간다');
        expect(contentOf(moved.key).existsSync(), isFalse, reason: '${moved.key} 의 마크다운이 남아 있다');
      }
    });
  });

  group('자리 찾기', () {
    test('페이저의 앞뒤가 읽는 순서를 따르고 탭을 건너 이어진다', () {
      expect(kDocsNavLocations.first.previous, isNull);
      expect(kDocsNavLocations.last.next, isNull);

      for (final (index, location) in kDocsNavLocations.indexed.skip(1)) {
        expect(location.previous, same(kDocsNavLocations[index - 1].page));
        expect(kDocsNavLocations[index - 1].next, same(location.page));
      }

      // 탭의 끝에서 다음 탭의 첫 페이지로.
      final lastOfFirstTab = docsNavLocate(kDocsNavTabs.first.pages.last.path)!;
      expect(lastOfFirstTab.next?.path, kDocsNavTabs[1].path);
    });

    test('끝의 빗금이 붙은 주소도 같은 자리다', () {
      expect(docsNavLocate('/guides/theming/')?.page.path, '/guides/theming');
    });

    test('구조에 없는 주소는 같은 디렉터리의 탭을 고른다', () {
      expect(docsNavLocate('/components/not-a-component'), isNull);
      expect(docsNavTabFor('/components/not-a-component').id, 'components');
      expect(docsNavTabFor('/nowhere').id, kDocsNavTabs.first.id);
    });

    test('경로 표시는 탭에서 시작한다', () {
      expect(docsNavLocate('/overview')!.trail.first, 'Getting Started');
    });
  });
}
