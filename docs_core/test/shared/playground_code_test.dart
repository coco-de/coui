import 'package:docs_core/shared/playground_spec.dart';
import 'package:test/test.dart';

/// 플레이그라운드 코드가 플랫폼마다 맞는 코드를 내는가.
///
/// 레이아웃 부품은 둘레의 코드가 플랫폼마다 다르다(Flutter 는 `Row` ·
/// `Column`, Web 은 flex `div`). 한 스니펫에 둘을 이어 적으면 복사한 코드가
/// 어느 쪽에서도 그대로 컴파일되지 않는다 — 그래서 그런 페이지는 `webCode` 를
/// 따로 둔다. 여기서는 그 나눔이 레지스트리의 모든 페이지에서 지켜지는지 본다.
void main() {
  final pages = kDocsPlaygrounds.keys.toList()..sort();

  test('레지스트리의 페이지를 돈다', () => expect(pages, containsAll(['button', 'gap'])));

  for (final page in pages) {
    final spec = kDocsPlaygrounds[page]!;
    test('$page — Flutter 코드는 code, Web 코드는 webCode 가 있을 때만 다르다', () {
      final flutter = spec.codeFor(DocsCodePlatform.flutter, spec.initial, spec.label);
      final web = spec.codeFor(DocsCodePlatform.web, spec.initial, spec.label);
      expect(flutter, spec.code(spec.initial, spec.label));
      if (spec.codeDiffersByPlatform) {
        expect(web, spec.webCode!(spec.initial, spec.label));
        expect(web, isNot(flutter), reason: 'webCode 를 두었는데 같은 코드다 — 두지 않는다');
      } else {
        expect(web, flutter);
      }
    });
  }

  test('Gap — 부모가 Flutter 는 Row · Column, Web 은 flex div 다', () {
    final spec = kDocsPlaygrounds['gap']!;
    for (final direction in ['row', 'column']) {
      final props = {...spec.initial, 'direction': direction};
      final flutter = spec.codeFor(DocsCodePlatform.flutter, props, spec.label);
      final web = spec.codeFor(DocsCodePlatform.web, props, spec.label);
      expect(flutter, startsWith(direction == 'row' ? 'Row(' : 'Column('));
      expect(flutter, isNot(contains('div(')));
      expect(web, startsWith('div('));
      expect(web, contains(direction == 'row' ? 'flex-row' : 'flex-col'));
      expect(web, isNot(contains('Row(')));
      expect(web, isNot(contains('Column(')));
    }
  });
}
