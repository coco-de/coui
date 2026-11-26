// 가운데 제목은 클러스터 사이 공간이 아니라 바 전체의 가운데에 놓인다 — 재질과
// 단일행 변형에 관계없이.
//
// 단일행 바가 세 칸 grid(leading · 제목 · trailing)가 되고, 양옆 칸이 둘 중
// 넓은 클러스터의 폭(`--coui-app-bar-side`)으로 같아 제목이 바의 가운데에 선다.
// 그 변수는 브라우저에서 측정기가 쓴다 — 쓰기 전(서버 첫 화면)에는 각 칸이 자기
// `max-content` 로 떨어진다. 이 파일은 그 구조(클래스 · inline 선언)를
// 렌더된 DOM 으로 본다. 브라우저가 그 grid 를 실제로 어디에 그리는지는
// `tool/parity/test/web/app_bar_center_title_probe_test.dart` 가 Chrome 에서 잰다.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kColumns =
    'minmax(var(--coui-app-bar-side, max-content), 1fr) '
    'minmax(0, max-content) '
    'minmax(var(--coui-app-bar-side, max-content), 1fr)';

/// 측정기의 숨은 앵커 — `hidden` 이라 grid 칸이 되지 않는다.
Finder _sideAnchor() => find.byComponentPredicate(
  (c) =>
      c is DomComponent &&
      c.tag == 'span' &&
      (c.id?.startsWith('co-app-bar-side-') ?? false),
);

/// 클래스 목록에 [cls] 를 포함한 `<div>` (whole-class 비교).
Finder _divWithClass(String cls) => find.byComponentPredicate(
  (c) => c is div && (c.classes?.split(' ').contains(cls) ?? false),
);

/// [attribute] 마커를 단 `<div>`.
Finder _marked(String attribute) => find.byComponentPredicate(
  (c) => c is div && (c.attributes?.containsKey(attribute) ?? false),
);

div _single(Finder finder) => finder.evaluate().single.component as div;

List<String> _classes(div d) => d.classes?.split(' ') ?? const [];

String? _style(div d, String property) => d.styles?.properties[property];

/// 바 루트 — 변형의 높이 class 를 가진 `<div>`.
div _root(String heightClass) => _single(_divWithClass(heightClass));

/// 제목 wrapper — 제목 typography role class 를 가진 `<div>`.
div _titleWrapper(String roleClass) => _single(_divWithClass(roleClass));

AppBar _bar({
  CoreAppBarVariant variant = .standard,
  bool centerTitle = true,
  bool trailingExpanded = false,
  CoreAppBarStyle? appBarStyle,
  Component? child,
}) => AppBar(
  variant: variant,
  centerTitle: centerTitle,
  trailingExpanded: trailingExpanded,
  appBarStyle: appBarStyle,
  leading: const [Text('Back')],
  trailing: const [Text('Search'), Text('More')],
  title: child == null ? const Text('Title') : null,
  child: child,
);

void main() {
  group('centerTitle — 세 칸 grid', () {
    for (final (variant, heightClass, roleClass) in [
      (CoreAppBarVariant.standard, 'h-size64', 'text-title-medium'),
      (CoreAppBarVariant.compact, 'h-size56', 'text-title-medium'),
      (CoreAppBarVariant.dense, 'h-size48', 'text-label-large'),
    ]) {
      for (final surfaceStyle in [
        CoreSurfaceStyleId.defaultId,
        CoreSurfaceStyleId.liquidGlass,
      ]) {
        testComponents('${variant.name} · ${surfaceStyle.name}', (
          tester,
        ) async {
          pumpWithTheme(
            tester,
            _bar(
              variant: variant,
              appBarStyle: CoreAppBarStyle(surfaceStyle: surfaceStyle),
            ),
          );
          await tester.pump();

          final root = _root(heightClass);
          expect(_classes(root), containsAll(['grid', 'items-center']));
          expect(_classes(root), isNot(contains('flex-row')));
          expect(_style(root, 'grid-template-columns'), _kColumns);

          final leading = _single(_marked('data-coui-app-bar-leading'));
          expect(_style(leading, 'grid-column'), '1');
          expect(_style(leading, 'justify-self'), 'start');

          final title = _titleWrapper(roleClass);
          expect(_style(title, 'grid-column'), '2');
          expect(_classes(title), isNot(contains('flex-1')));
          // 절대 위치 · 측정한 max-width 로 가운데에 세우지 않는다.
          expect(_style(title, 'position'), isNull);
          expect(_style(title, 'max-width'), isNull);

          final trailing = _single(_marked('data-coui-app-bar-trailing'));
          expect(_style(trailing, 'grid-column'), '3');
          expect(_style(trailing, 'justify-self'), 'end');
          expect(_style(trailing, 'margin-inline-start'), isNull);

          // 양옆 칸을 같게 하는 측정기의 앵커 — 숨겨져 grid 칸이 아니다.
          final anchor =
              _sideAnchor().evaluate().single.component as DomComponent;
          expect(anchor.attributes, containsPair('hidden', ''));

          // 제목은 한 줄 — 대칭 폭에 들어가지 않으면 말줄임.
          expect(
            _classes(_single(_divWithClass('truncate'))),
            containsAll(['max-w-full', 'truncate']),
          );
        });
      }
    }

    testComponents('custom child 는 제목 줄로 감싸지 않는다', (tester) async {
      pumpWithTheme(
        tester,
        _bar(child: const Text('Custom')),
      );
      await tester.pump();

      expect(_classes(_root('h-size64')), contains('grid'));
      expect(_divWithClass('truncate'), findsNothing);
      // The custom child is centred on the same symmetric sides.
      expect(_sideAnchor(), findsOneComponent);
    });
  });

  group('가운데 맞출 자리가 없으면 flex 행 그대로', () {
    void expectFlexRow(div root) {
      expect(
        _classes(root),
        containsAll(['flex', 'flex-row', 'items-center']),
      );
      expect(_classes(root), isNot(contains('grid')));
      expect(_style(root, 'grid-template-columns'), isNull);
      expect(_divWithClass('truncate'), findsNothing);
      expect(_sideAnchor(), findsNothing);
    }

    testComponents('centerTitle: false', (tester) async {
      pumpWithTheme(tester, _bar(centerTitle: false));
      await tester.pump();

      expectFlexRow(_root('h-size64'));
      expect(_classes(_titleWrapper('text-title-medium')), contains('flex-1'));
    });

    testComponents('trailingExpanded — trailing 이 남는 폭을 가진다', (tester) async {
      pumpWithTheme(tester, _bar(trailingExpanded: true));
      await tester.pump();

      expectFlexRow(_root('h-size64'));
      expect(
        _classes(_single(_marked('data-coui-app-bar-trailing'))),
        containsAll(['flex-1', 'justify-end']),
      );
    });

    testComponents('medium 은 자기 2행 그대로', (tester) async {
      pumpWithTheme(tester, _bar(variant: .medium));
      await tester.pump();

      final root = _root('h-size112');
      expect(_classes(root), containsAll(['flex', 'flex-col']));
      expect(_style(root, 'grid-template-columns'), isNull);
      expect(_divWithClass('truncate'), findsNothing);
      expect(_sideAnchor(), findsNothing);
    });
  });
}
