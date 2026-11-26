// #3909 — `findChromeNode` had zero committed tests: its structural rewrite
// (`root_scoped_walk.dart`'s [findRootScoped] replacing the old
// geometric-size-match rule) was only exercised indirectly, through
// `flutter_capture_matrix_test.dart`'s full manifest run. This file
// exercises it directly against small, hand-built trees shaped like the two
// cases `root_scoped_walk.dart`'s own top comment documents (a real,
// nonzero-everywhere multi-child branch vs. one with a zero-size sibling)
// — mirroring `root_text_probe_test.dart`'s own structure for the sibling
// probe that shares this same underlying primitive.
//
// Real `Alert`/`Card`-shaped components wrap their *whole* subtree in
// chrome before any branch (`OutlinedContainer`/`DecoratedBox` first, the
// Row/Column with icon+content slots nested *inside* it) — chrome then
// sits on the single-child path regardless of this file's branching rule,
// which is exactly why the pre-#3909 "never branch" version never showed a
// visible regression for `findChromeNode` specifically across a full T1
// manifest run (only `probeRootTextStyle`, which needs to reach *past*
// that same branch to find the text nested inside it, did). The first case
// below instead puts root's own branch point first (an icon beside a
// chrome-bearing content panel) — the shape that actually needs
// [findChromeNode] to recurse past a branch — so this file's own coverage
// doesn't silently depend on that same accident of "chrome happens to
// always be found before any branch" holding for every future component.
//
// Every case here was verified to actually catch a regression: reverting
// this file's `findChromeNode` call to walk a "never branch, full stop, no
// zero-sibling exception" version of `findRootScoped` (this file's own
// #3909 predecessor) makes the first case below fail.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chrome_node_probe.dart';

void main() {
  testWidgets(
    'icon + chrome-panel row 형태 — root 자신이 곧바로 여러 자식으로 '
    'branch 하고, chrome 은 그 중 한 branch 안에 있다 (모든 형제가 뭔가를 '
    '그리므로 branching 이 안전하다)',
    (tester) async {
      // Unlike `card.dart`/`alert.dart` (both wrap their *whole* subtree
      // in chrome before any branch, so chrome sits on the single-child
      // path regardless of this file's branching rule), this fixture puts
      // root's own `Row` branch point *first* — mirroring a leading-icon
      // component whose chrome panel is only one of several direct
      // children, the shape that actually needs [findChromeNode] to
      // recurse *past* a branch to find it. Every sibling renders
      // *something* (none is `Size.zero`), which is what should make this
      // branch safe to search.
      final rootKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: KeyedSubtree(
              key: rootKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon-shaped leaf sibling — non-zero size, not a chrome
                  // candidate itself.
                  const SizedBox(width: 20, height: 20),
                  const SizedBox(width: 8), // Gap-shaped leaf sibling.
                  Expanded(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0F0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Heads up'),
                            const Text('Something happened.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = findChromeNode(
        tester,
        rootFinder: find.byKey(rootKey),
      );

      expect(result, isNotNull);
      expect(
        result!.decoration?.color,
        const Color(0xFFFFF0F0),
        reason:
            'findChromeNode 가 root 자신의 chrome 을 Row branch 너머로 찾아야 '
            '한다 — icon+chrome-panel row 케이스 (#3909).',
      );
    },
  );

  testWidgets(
    'trigger + closed-overlay 형태 — 형제 중 하나가 아무것도 그리지 않으면 '
    'branch 전체를 거부한다 (foreign 컴포넌트의 chrome 을 잘못 고르지 않음)',
    (tester) async {
      // Mirrors `dialog.dart`'s real shape: root is a bare `Column` with
      // no chrome of its own, wrapping a trigger with its own decorated
      // chrome plus a "closed overlay" sibling that renders `Size.zero`
      // (`SizedBox.shrink()` — exactly what a closed `Dialog` returns).
      final rootKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: KeyedSubtree(
              key: rootKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xFF3355FF)),
                    child: const SizedBox(
                      width: 90,
                      height: 32,
                      child: Text('Open Dialog'),
                    ),
                  ),
                  const SizedBox.shrink(), // Closed overlay — zero size.
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = findChromeNode(
        tester,
        rootFinder: find.byKey(rootKey),
      );

      expect(
        result,
        isNull,
        reason:
            'findChromeNode 가 trigger 의 DecoratedBox 를 root 자신의 chrome인 '
            '것처럼 잘못 반환했다 — dialog 형태 컴포지션에서 재현되면 안 되는 '
            '회귀다 (#3909, #3859).',
      );
    },
  );

  testWidgets(
    '단일 경로 — branching 없이 바로 도달하는 chrome 은 그대로 찾는다',
    (tester) async {
      final rootKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyedSubtree(
            key: rootKey,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFF18191B)),
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = findChromeNode(
        tester,
        rootFinder: find.byKey(rootKey),
      );

      expect(result, isNotNull);
      expect(result!.decoration?.color, const Color(0xFF18191B));
    },
  );

  testWidgets(
    '반복 아이템 형태 — 형제 여럿이 각자 자기 chrome 을 갖고 있으면 '
    '"item zero" 를 추측하지 않고 branch 전체를 거부한다 (#3904)',
    (tester) async {
      // Mirrors `theme_controller.dart`'s real shape: root is a bare
      // `Wrap`/`Row` with no chrome of its own, wrapping N structurally
      // identical, independent sub-components (`_ThemeSwatch`) — each one
      // reachable only by descending into its own subtree, each one
      // carrying its own real `DecoratedBox`. Before #3904's fix,
      // [findChromeNode] picked whichever sibling's subtree it reached
      // first ("item zero"), attributing that swatch's own
      // selected/unselected chrome to root — a *confidently wrong*
      // comparison (root's true identity has no chrome of its own at
      // all), not an honest "couldn't find one". Every sibling here
      // independently leads to a real `DecoratedBox` (not a `Size.zero`
      // leaf, so [findRootScoped]'s zero-sibling refusal doesn't already
      // cover this), so this is exactly the ambiguity this fix closes.
      final rootKey = GlobalKey();

      Widget swatch(Color color) => Semantics(
        button: true,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color),
          child: const SizedBox(width: 24, height: 24),
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: KeyedSubtree(
              key: rootKey,
              child: Wrap(
                children: [
                  swatch(const Color(0xFF3355FF)),
                  swatch(const Color(0xFFFF5533)),
                  swatch(const Color(0xFF33FF55)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = findChromeNode(
        tester,
        rootFinder: find.byKey(rootKey),
      );

      expect(
        result,
        isNull,
        reason:
            'findChromeNode 가 반복되는 첫 swatch 자신의 chrome 을 root 의 '
            '것인 것처럼 잘못 반환했다 — theme-controller 형태 컴포지션에서 '
            '재현되면 안 되는 회귀다 (#3904).',
      );
    },
  );

  testWidgets(
    '반복되는 위젯 타입이라도 후보를 딱 하나만 내면(나머지는 leaf) 그 '
    '하나는 그대로 찾는다 — 타입 반복 자체가 아니라 도달 가능한 후보 수가 '
    '기준이다 (#3904)',
    (tester) async {
      // `checkbox.dart`'s real shape has two `SizedBox`-shaped *leaf*
      // siblings (an icon-shaped placeholder and a gap) next to the real
      // chrome-bearing square — sharing a widget *type* for unrelated
      // reasons, neither leading to a candidate. A widget-type-repetition
      // heuristic would refuse this branch (a real regression #3904's own
      // before/after `compare_reports.dart` run caught: `checkbox`/
      // `radio-group`/`text-field` all lost their previously-correct
      // `borderRadiusPx`/`paddingPx` match). Counting *reachable
      // candidates* instead — here, exactly one — keeps this branch
      // resolvable.
      final rootKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: KeyedSubtree(
              key: rootKey,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 16, height: 16), // leaf, no chrome.
                  const SizedBox(width: 8), // leaf, no chrome.
                  DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xFF18191B)),
                    child: const SizedBox(width: 20, height: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = findChromeNode(
        tester,
        rootFinder: find.byKey(rootKey),
      );

      expect(result, isNotNull);
      expect(result!.decoration?.color, const Color(0xFF18191B));
    },
  );
}
