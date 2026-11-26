// AppBar 흡수 (#4564) — 바가 자기 chrome 을 소유한다.
//
// standard/compact/dense 는 단일행, medium 은 48px 상단행 + 하단 정렬
// 대형 타이틀의 2행 구조. divider / elevated 플래그와 `appBarStyle` 의
// spacing / actionSpacing 도달, dense 행이 스스로 적는 면 · 간격 ·
// 제목을 렌더된 DOM 으로 검증한다.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// 클래스 목록에 [cls] 를 포함한 `<div>` 를 찾는다 (whole-class 비교).
Finder _divWithClass(String cls) => find.byComponentPredicate(
  (c) => c is div && (c.classes?.split(' ').contains(cls) ?? false),
);

/// [classes] 를 **모두** 가진 `<div>` 를 찾는다 (whole-class 비교).
///
/// 단일 class 로는 특정할 수 없는 element 가 있다 — 바 padding 과 단일행
/// title padding 이 둘 다 `space8` 이라 `pl-space8` 은 루트와 title wrapper
/// 양쪽에 나온다. 어느 쪽에 붙었는지가 이 축의 전부이므로, title 을
/// 식별하는 typography class 와 함께 본다.
Finder _divWithClasses(List<String> classes) => find.byComponentPredicate((c) {
  if (c is! div) return false;
  final present = c.classes?.split(' ').toSet() ?? const <String>{};
  return classes.every(present.contains);
});

/// inline style 에 [property] 가 [value] 로 박힌 `<div>` 를 찾는다.
Finder _divWithStyle(String property, String value) =>
    find.byComponentPredicate(
      (c) => c is div && c.styles?.properties[property] == value,
    );

void main() {
  group('AppBar — 렌더', () {
    testComponents('standard 는 단일행 + h-size64 + divider 기본', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const AppBar(title: Text('Dashboard')),
      );
      await tester.pump();

      // 기본 높이는 variant 테이블의 size 토큰 class 로 나간다.
      expect(_divWithClass('h-size64'), findsOneComponent);
      // divider 기본 on — border-b + 기본 토큰 색 class.
      expect(_divWithClass('border-b'), findsOneComponent);
      expect(_divWithClass('border-b-outline-variant'), findsOneComponent);
      // 타이틀 typography role class 가 wrapper 에 붙는다.
      expect(_divWithClass('text-title-medium'), findsOneComponent);
      // 타이틀 **자신의** inset — 이 축의 정답이 Web 이라서 여기 그물이
      // 없으면 Web 이 titlePadding emit 을 잃어도 조용하다 (Flutter 는
      // 이 값을 medium 분기에서만 읽다가 단일행 제목이 8px 왼쪽으로
      // 어긋난 채 출하됐다). typography class 로 title wrapper 를 특정한다
      // — `pl-space8` 만 보면 같은 값을 쓰는 루트 padding 도 걸린다.
      expect(
        _divWithClasses(['text-title-medium', 'pl-space8', 'pr-space8']),
        findsOneComponent,
      );
      // medium 전용 top row 는 렌더되지 않는다.
      expect(_divWithClass('h-size48'), findsNothing);
    });

    testComponents('compact 는 h-size56, showDivider:false 는 border-b 0', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const AppBar(
          variant: .compact,
          showDivider: false,
          title: Text('Dense'),
        ),
      );
      await tester.pump();

      expect(_divWithClass('h-size56'), findsOneComponent);
      expect(_divWithClass('border-b'), findsNothing);
    });

    testComponents('medium 은 2행 — h-size112 루트 + h-size48 top row', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const AppBar(
          variant: .medium,
          title: Text('Large title'),
          trailing: [div([])],
        ),
      );
      await tester.pump();

      expect(_divWithClass('h-size112'), findsOneComponent);
      expect(_divWithClass('h-size48'), findsOneComponent);
      // 대형 타이틀은 하단 정렬 + titleLarge role.
      expect(_divWithClass('justify-end'), findsOneComponent);
      expect(_divWithClass('text-title-large'), findsOneComponent);
    });

    testComponents('elevated 는 box-shadow 프리셋 변수로 나간다', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const AppBar(elevated: true, title: Text('Cast')),
      );
      await tester.pump();

      // 기본 CoreShadow.sm 스택은 `var(--shadow-sm)` 프리셋 변수로
      // 라우팅된다 (서페이스 스타일이 굽힐 수 있는 간접층).
      expect(
        _divWithStyle(
          'box-shadow',
          'var(--shadow-sm), var(--coui-surface-rim)',
        ),
        findsOneComponent,
      );
    });

    testComponents(
      'appBarStyle 의 spacing / actionSpacing 이 각 클러스터에 도달한다',
      (tester) async {
        pumpWithTheme(
          tester,
          const AppBar(
            title: Text('Spacing'),
            trailing: [div([])],
            appBarStyle: CoreAppBarStyle(
              spacing: CoreSpace.space16,
              actionSpacing: CoreSpace.space12,
            ),
          ),
        );
        await tester.pump();

        // spacing → leading / centre / trailing 사이.
        expect(
          _divWithStyle('gap', 'var(--coui-space-16)'),
          findsOneComponent,
        );
        // actionSpacing → 트레일링 클러스터 안쪽 gap.
        expect(
          _divWithStyle('gap', 'var(--coui-space-12)'),
          findsOneComponent,
        );
      },
    );
  });

  // dense — 데스크톱 제목 바. 이 행만 면 · 클러스터 간격 · 제목 굵기를
  // 스스로 적는다. resolver 가 공용 기본값(surface · 4 / 4 · 역할의 굵기)을
  // 계속 읽으면 여기서 실패한다.
  group('AppBar — dense', () {
    testComponents('h-size48 + 바 inset 16 + chrome 층 면', (tester) async {
      pumpWithTheme(
        tester,
        const AppBar(variant: .dense, title: Text('Workspace')),
      );
      await tester.pump();

      expect(
        _divWithClasses([
          'h-size48',
          'pl-space16',
          'pr-space16',
          'bg-surface-container-low',
        ]),
        findsOneComponent,
      );
      expect(_divWithClass('bg-surface'), findsNothing);
      // 재질 규칙이 다시 진술하는 채움도 같은 면을 가리킨다.
      expect(
        _divWithStyle(
          '--coui-surface-rgb',
          'var(--coui-surface-container-low)',
        ),
        findsOneComponent,
      );
    });

    testComponents('나머지 변형은 surface 면 그대로', (tester) async {
      pumpWithTheme(
        tester,
        const AppBar(variant: .compact, title: Text('Title')),
      );
      await tester.pump();

      expect(_divWithClass('bg-surface'), findsOneComponent);
      expect(_divWithClass('bg-surface-container-low'), findsNothing);
    });

    testComponents('클러스터 사이 14, 행동 사이 8', (tester) async {
      pumpWithTheme(
        tester,
        const AppBar(
          variant: .dense,
          title: Text('Workspace'),
          trailing: [div([]), div([])],
        ),
      );
      await tester.pump();

      expect(_divWithStyle('gap', 'var(--coui-space-14)'), findsOneComponent);
      expect(_divWithStyle('gap', 'var(--coui-space-8)'), findsOneComponent);
      // 공용 기본 4 는 어디에도 남지 않는다.
      expect(_divWithStyle('gap', 'var(--coui-space-4)'), findsNothing);
    });

    testComponents('제목은 labelLarge 역할 + semibold, inset 0', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const AppBar(variant: .dense, title: Text('Workspace')),
      );
      await tester.pump();

      // 역할과 토큰 색은 class, 역할 위에 얹은 굵기만 inline 으로 나간다.
      expect(
        _divWithClasses([
          'text-label-large',
          'text-on-surface',
          'pl-space0',
          'pr-space0',
        ]),
        findsOneComponent,
      );
      expect(_divWithStyle('font-weight', '600'), findsOneComponent);
    });
  });

  // prominent — 탭 첫 화면의 한 줄 큰 제목. compact 와 같은 56 높이에
  // headlineSmall 제목이고, 제목이 바 가장자리에서 20 에서 시작한다
  // (바 padding 4 + 제목 inset 16). 단일행 분기를 공유하므로 여기서는
  // 이 변형 자신의 값만 본다.
  group('AppBar — prominent', () {
    testComponents('h-size56 + 바 inset 4 + surface 면, 단일행', (tester) async {
      pumpWithTheme(
        tester,
        const AppBar(variant: .prominent, title: Text('지도')),
      );
      await tester.pump();

      expect(
        _divWithClasses([
          'h-size56',
          'pl-space4',
          'pr-space4',
          'bg-surface',
        ]),
        findsOneComponent,
      );
      // 2행(medium) 전용 element 는 나오지 않는다.
      expect(_divWithClass('h-size48'), findsNothing);
      expect(_divWithClass('h-size112'), findsNothing);
      expect(_divWithClass('justify-end'), findsNothing);
      expect(_divWithClass('bg-surface-container-low'), findsNothing);
    });

    testComponents('제목은 headlineSmall 역할 그대로 + inset 16', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const AppBar(variant: .prominent, title: Text('지도')),
      );
      await tester.pump();

      expect(
        _divWithClasses([
          'text-headline-small',
          'text-on-surface',
          'pl-space16',
          'pr-space16',
        ]),
        findsOneComponent,
      );
      // 역할이 크기 · 굵기 · 행간 · 자간을 통째로 들고 오므로, 역할 위에
      // 얹은 inline 값이 나오면 제목이 타입 스케일 밖으로 나간 것이다.
      final overlay = find.byComponentPredicate((c) {
        if (c is! div) return false;
        final props = c.styles?.properties ?? const <String, String>{};
        return props.containsKey('font-size') ||
            props.containsKey('font-weight') ||
            props.containsKey('line-height') ||
            props.containsKey('letter-spacing');
      });
      expect(overlay, findsNothing);
    });

    testComponents('다른 변형의 제목 역할은 그대로', (tester) async {
      pumpWithTheme(
        tester,
        const AppBar(variant: .compact, title: Text('Title')),
      );
      await tester.pump();

      expect(_divWithClass('text-title-medium'), findsOneComponent);
      expect(_divWithClass('text-headline-small'), findsNothing);
    });
  });
}
