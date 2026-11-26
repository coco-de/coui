/// 본문의 `#조각` 링크와 `>` 가 든 속성값 — 네이티브 앱의 해석.
library;

import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/page/docs_page_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveDocsLinkTarget', () {
    const from = '/components/card';

    test('#조각 만 있는 링크는 지금 페이지에 머문다', () {
      expect(
        resolveDocsLinkTarget('#알려진-제약', from: from),
        '/components/card#알려진-제약',
      );
    });

    test('그 밖의 링크는 전과 같이 푼다', () {
      expect(
        resolveDocsLinkTarget('/components/button#api', from: from),
        '/components/button#api',
      );
      expect(
        resolveDocsLinkTarget('./button.md', from: from),
        '/components/button',
      );
      expect(
        resolveDocsLinkTarget('guides/theme', from: from),
        '/guides/theme',
      );
    });
  });

  group('속성값의 >', () {
    test('따옴표 안의 > 는 태그를 닫지 않는다', () {
      final tag = parseDocsTag(
        '<AnatomyItem selector="[role=radio] > span" />',
      );
      expect(tag?.attributes['selector'], '[role=radio] > span');
      expect(tag?.innerMarkdown, isNull);
    });

    test('짝이 있는 태그와 작은따옴표 값에서도 같다', () {
      final tag = parseDocsTag(
        "<AnatomyItem selector='.a > .b'>\n설명\n</AnatomyItem>",
      );
      expect(tag?.attributes['selector'], '.a > .b');
      expect(tag?.innerMarkdown, '설명');
    });

    test('같은 줄 뒤에 글이 붙은 줄은 여전히 태그가 아니다', () {
      expect(findDocsTags('<Widget> 는 "따옴표" > 를 담은 산문'), isEmpty);
    });
  });
}
