import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/search/docs_search.dart';
import 'package:docs_core/shared/docs_search_index.dart';
import 'package:flutter_test/flutter_test.dart';

/// 검색 팔레트가 입력한 검색어로 목록을 거르는지 본다.
///
/// `Command` 는 제어형이라 검색어 상태를 호출자가 들고 `query` 로 다시
/// 넘겨야 한다. 그 배선이 빠지면 입력창에는 글자가 보이는데 목록은 전부
/// 그대로 남는다 — 렌더도 예외도 정상이라 목록을 세어 봐야만 드러난다.
void main() {
  Future<void> openSearch(
    WidgetTester tester, {
    List<String>? navigated,
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late BuildContext opener;
    await tester.pumpWidget(
      CoUIApp(
        home: Builder(
          builder: (context) {
            opener = context;
            return const SizedBox.shrink();
          },
        ),
        scaling: .desktop,
        theme: ThemeData.fromCore(CoreThemePresets.previewLight),
      ),
    );
    await tester.pump();

    final _ = showDocsSearch(
      opener,
      onNavigate: (path) => navigated?.add(path),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('검색어를 입력하기 전에는 첫 그룹의 항목이 보인다', (tester) async {
    await openSearch(tester);

    expect(find.byType(Command), findsOneWidget);
    // 첫 그룹은 사이트 구조의 첫 탭이다 — 이름을 여기 적지 않고 인덱스에서
    // 읽는다. 적어 두면 페이지 이름을 바꾼 날 팔레트는 멀쩡한데 이 테스트만
    // 깨진다.
    expect(
      find.text(buildDocsSearchIndex().first.items.first.label),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('검색어가 목록을 거른다', (tester) async {
    await openSearch(tester);

    await tester.enterText(find.byType(EditableText), 'focus');
    await tester.pumpAndSettle();

    // 일치하지 않는 항목은 사라진다 — 배선이 빠지면 여기서 그대로 남는다.
    expect(find.text('Button'), findsNothing);
    // 라벨에 검색어가 든 항목은 남는다.
    expect(find.text('FocusOutline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('걸러진 항목을 고르면 그 문서로 이동한다', (tester) async {
    final navigated = <String>[];
    await openSearch(tester, navigated: navigated);

    await tester.enterText(find.byType(EditableText), 'focusoutline');
    await tester.pumpAndSettle();
    await tester.tap(find.text('FocusOutline'));
    await tester.pumpAndSettle();

    expect(navigated, ['/components/focus-outline']);
    expect(find.byType(Command), findsNothing);
  });
  testWidgets('Korean aliases filter and navigate to component docs', (
    tester,
  ) async {
    final navigated = <String>[];
    await openSearch(tester, navigated: navigated);
    await tester.enterText(find.byType(EditableText), '버튼');
    await tester.pumpAndSettle();
    expect(find.text('Button'), findsOneWidget);
    await tester.tap(find.text('Button'));
    await tester.pumpAndSettle();
    expect(navigated, ['/components/button']);
  });

  testWidgets('guide results navigate outside the component namespace', (
    tester,
  ) async {
    final navigated = <String>[];
    await openSearch(tester, navigated: navigated);
    await tester.enterText(find.byType(EditableText), 'theming');
    await tester.pumpAndSettle();
    await tester.tap(find.text('테마'));
    await tester.pumpAndSettle();
    expect(navigated, ['/guides/theming']);
  });
}
