import 'package:coui_core/coui_core.dart';
import 'package:docs_core/shared/playground_spec.dart';
import 'package:docs_core/shared/preview_props.dart';
import 'package:docs_core/shared/size_spec.dart';
import 'package:test/test.dart';

// 크기 표는 Core 의 크기 행을 읽어 만든다. 아래 숫자는 손으로 적은 기대값 —
// 표와 크기 행이 함께 틀어지는 경우(읽는 필드를 잘못 고른 경우)도 잡으려고
// 숫자로 고정한다. 크기 행을 바꾸는 PR 은 이 숫자도 같이 바꾼다.
void main() {
  group('docsSizeSpecFor', () {
    test('button rows read height · padding · icon · label role · radius', () {
      final spec = docsSizeSpecFor('button')!;
      expect(spec.columns, ['size', '높이 · 좌우 여백', '아이콘', '라벨 · 모서리']);
      expect([for (final row in spec.rows) row.size], CoreComponentSize.values);
      expect(
        {for (final row in spec.rows) row.size.name: row.cells},
        {
          'xs': ['24 · 8', '12', '12 Medium · 6'],
          'sm': ['32 · 12', '14', '13 Medium · 8'],
          'md': ['40 · 16', '16', '14 Medium · 10'],
          'lg': ['48 · 20', '18', '16 Medium · 12'],
          'xl': ['56 · 24', '20', '16 Medium · 14'],
          'xl2': ['64 · 28', '24', '16 Medium · 16'],
        },
      );
    });

    test('text-field rows read min height · padding · value text', () {
      final spec = docsSizeSpecFor('text-field')!;
      expect(
        {for (final row in spec.rows) row.size.name: row.cells},
        {
          'sm': ['32 · 10', '14', 'sm'],
          'md': ['40 · 12', '14', 'md'],
          'lg': ['48 · 14', '14', 'lg'],
          'xl': ['56 · 16', '15', 'xl'],
          'xl2': ['64 · 20', '15', 'xl2'],
        },
      );
    });

    test('TextField playground offers the same size options as the size table', () {
      final size = kDocsPlaygrounds['text-field']!.controls.whereType<DocsPlaygroundChoice>().singleWhere(
        (choice) => choice.prop == 'size',
      );
      expect(size.options, docsSizeSpecFor('text-field')!.rows.map((row) => row.size.name));
    });

    // 위 숫자 검사는 기준 페이지 둘만 손으로 적는다. 아래는 레지스트리의
    // 모든 페이지에 걸리는 모양 검사다 — 새 페이지가 열을 하나 빠뜨리거나
    // 크기를 두 번 적어도 표는 에러 없이 그려지므로 여기서 잡는다.
    for (final component in kDocsSizeSpecComponents.toList()..sort()) {
      test('$component — 크기마다 한 행, 열마다 한 칸', () {
        final spec = docsSizeSpecFor(component)!;
        expect(spec.columns.first, 'size');
        expect(spec.rows, isNotEmpty);
        final sizes = [for (final row in spec.rows) row.size];
        expect(sizes.toSet(), hasLength(sizes.length), reason: '같은 크기가 두 번');
        expect(sizes, [...sizes]..sort((a, b) => a.index.compareTo(b.index)), reason: '작은 크기부터');
        for (final row in spec.rows) {
          expect(row.cells, hasLength(spec.columns.length - 1), reason: row.size.name);
          expect(row.cells.where((cell) => cell.trim().isEmpty), isEmpty, reason: row.size.name);
        }
      });

      test('$component — 플레이그라운드의 크기 선택지가 크기 표의 행과 같다', () {
        final choice = kDocsPlaygrounds[component]?.controls.whereType<DocsPlaygroundChoice>().where(
          (choice) => choice.prop == 'size',
        );
        if (choice == null || choice.isEmpty) return;
        expect(choice.single.options, docsSizeSpecFor(component)!.rows.map((row) => row.size.name));
      });
    }

    test('every listed component has a spec, and only those', () {
      for (final component in kDocsSizeSpecComponents) {
        expect(docsSizeSpecFor(component), isNotNull, reason: component);
      }
      expect(docsSizeSpecFor('avatar'), isNull);
    });
  });

  group('parsePreviewProps', () {
    test('splits on ; and the first =', () {
      expect(parsePreviewProps('variant=outline; size=md;placeholder=a=b;'), {
        'variant': 'outline',
        'size': 'md',
        'placeholder': 'a=b',
      });
    });

    test('a bare key reads as true, empty pieces are dropped', () {
      expect(parsePreviewProps('expanded;;=x'), {'expanded': 'true'});
      expect(parsePreviewProps(null), isEmpty);
    });

    test('unknown enum names fall back instead of throwing', () {
      expect(previewEnum(CoreComponentSize.values, 'huge', CoreComponentSize.md), CoreComponentSize.md);
      expect(previewEnum(CoreComponentSize.values, 'xl2', CoreComponentSize.md), CoreComponentSize.xl2);
      expect(previewFlag({'enabled': 'false'}, 'enabled', fallback: true), isFalse);
      expect(previewFlag({}, 'enabled', fallback: true), isTrue);
    });
  });
}
