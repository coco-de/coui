import 'package:docs_app/src/content/docs_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseDocsPage', () {
    test('frontmatter 를 파싱하고 본문과 분리한다', () {
      final page = parseDocsPage(
        path: '/components/badge',
        source: '''
---
title: Badge
description: 배지 컴포넌트
category: display
platforms: [flutter, web]
related: [avatar, icon, chip]
tags: [indicator, count, status]
---

# Badge

본문.
''',
      );

      expect(page.title, 'Badge');
      expect(page.description, '배지 컴포넌트');
      expect(page.category, 'display');
      expect(page.platforms, ['flutter', 'web']);
      expect(page.related, ['avatar', 'icon', 'chip']);
      expect(page.tags, ['indicator', 'count', 'status']);
      expect(page.body.trim(), startsWith('# Badge'));
      expect(page.body, isNot(contains('title: Badge')));
    });

    test('frontmatter 가 없으면 전체가 본문이다', () {
      final page = parseDocsPage(path: '/x', source: '# 제목\n\n본문.');
      expect(page.title, isNull);
      expect(page.body, '# 제목\n\n본문.');
    });

    test('깨진 frontmatter 에서 죽지 않고 저하된다', () {
      // 페이지 하나의 오타로 앱 전체가 죽으면 안 된다.
      final page = parseDocsPage(
        path: '/x',
        source: '---\n: : 깨짐 : :\n---\n\n본문.',
      );
      expect(page.title, isNull);
      expect(page.body.trim(), '본문.');
    });

    test('닫히지 않은 frontmatter 는 본문으로 취급한다', () {
      final page = parseDocsPage(path: '/x', source: '---\ntitle: X\n\n본문.');
      expect(page.body, contains('본문.'));
    });
  });
}
