import 'package:coui_web/coui_web.dart' show CoreCommandItem;
import 'package:docs_core/shared/docs_search_index.dart';
import 'package:docs_core/shared/guide_catalog.dart';
import 'package:test/test.dart';

void main() {
  final items = buildDocsSearchIndex().expand((group) => group.items).toList();
  List<DocsSearchItem> search(String query) => items
      .where(
        (item) =>
            CoreCommandItem<Object>(value: item.value, label: item.label, keywords: item.keywords).matchesQuery(query),
      )
      .toList();

  test('Korean names resolve through Command keywords', () {
    expect(search('버튼').map((item) => item.value), contains('button'));
    expect(search('달력').map((item) => item.value), contains('calendar'));
    expect(search('파일 업로드').map((item) => item.value), contains('file-input'));
    expect(search('BUTTON').map((item) => item.value), contains('button'));
  });

  test('guides are searchable and retain their own routes', () {
    expect(search('테마').map((item) => docsSearchPath(item.value)), contains('/guides/theming'));
    // 설치는 빠른 시작에 합쳐졌다 — 옛 이름으로 찾아도 그 페이지가 나온다.
    expect(search('설치').map((item) => docsSearchPath(item.value)), contains('/getting-started'));
    for (final guide in kDocsGuides) {
      expect(items.map((item) => item.value), contains(guide.path));
      expect(docsSearchPath(guide.path), guide.path);
    }
    expect(docsSearchPath('button'), '/components/button');
    expect(docsSearchPath('hero'), '/blocks/hero');
  });

  test('result identifiers are unique across all catalogs', () {
    expect(items.map((item) => item.value).toSet(), hasLength(items.length));
  });
}
