// #3859 — `probeRootTextStyle` (#3852) had zero committed tests: every
// improvement that PR reported was unverified by anything that would
// actually fail if the algorithm regressed. The two committed tests that
// *do* exist under `tool/parity/test/` (`css_value_parsers_test.dart`,
// `entry_loader_test.dart`) cover an unrelated box-shadow parser and loader
// isolation — they pass identically whether this function's root-attribution
// fix is present or reverted to the pre-#3852 "first `Text` found anywhere
// under root" implementation.
//
// This file exercises `probeRootTextStyle` directly against small,
// hand-built widget trees shaped like the two cases `root_text_probe.dart`'s
// own top comment documents having measured against real components
// (`dialog`, `card`) — not by re-running the full manifest capture harness
// (`flutter_capture_matrix_test.dart`), which needs a `PARITY_MANIFEST` and
// pulls in `docs_core`'s whole registry. Calling the function under test
// directly, with a deliberately-constructed tree *shape*, is what makes
// each case below a controlled, deterministic proof of *this* algorithm's
// behavior — see `flutter_capture_matrix_overlay_pinning_test.dart`
// (sibling file) for the separate concern of whether the real capture
// harness feeds this function an accurate tree in the first place.
//
// #3909 — `probeRootTextStyle` stopped comparing candidate render-box size/
// position against `rootSize` (a tolerance that degenerated the moment
// root's own true size could coincide with a foreign sub-component's, which
// `flutter_capture_matrix_overlay_pinning_test.dart`'s second case proved
// happens for real) and now walks the element tree structurally instead
// (`root_scoped_walk.dart`). The two cases below still exercise exactly the
// shapes their names describe; only the *why* they resolve correctly
// changed, not what they assert.
//
// Every case here was verified to actually catch a regression: reverting
// `probeRootTextStyle`'s body to the pre-#3852 implementation (`find
// .descendant(of: rootFinder, matching: find.byType(Text))`, first RichText
// found, no foreign-chrome filtering — restorable via `git show
// f8da15a25^:packages/coui_flutter/test/parity/root_text_probe.dart`'s
// absence, i.e. the diff at
// f8da15a25~1..f8da15a25 in `flutter_capture_matrix_test.dart`) makes the
// `dialog 형태`/`card 형태` cases below fail — the exact numbers from that
// run are in this PR's description, not repeated here since they'd rot the
// moment either test's fixture colors change.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'root_text_probe.dart';

void main() {
  testWidgets(
    'positioned visible text wins over invisible layers and graphics',
    (
      tester,
    ) async {
      final rootKey = GlobalKey();
      const invisible = AlwaysStoppedAnimation<double>(0);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: KeyedSubtree(
                key: rootKey,
                child: const Stack(
                  children: [
                    Positioned.fill(
                      child: FadeTransition(
                        opacity: invisible,
                        child: DefaultTextStyle(
                          style: TextStyle(color: Colors.red, fontSize: 14),
                          child: Text('Hidden slide'),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: [
                          DefaultTextStyle(
                            style: TextStyle(color: Colors.blue, fontSize: 20),
                            child: SizedBox(width: 10, height: 10),
                          ),
                          DefaultTextStyle(
                            style: TextStyle(color: Colors.green, fontSize: 14),
                            child: Text('Live'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final actual = probeRootTextStyle(
        tester,
        rootFinder: find.byKey(rootKey),
      );
      expect(actual?.color, Colors.green);
      expect(actual?.fontSize, 14);
    },
  );

  for (final measureVisible in [false, true]) {
    testWidgets(
      'Stack reads painted text, measurement visible=$measureVisible',
      (
        tester,
      ) async {
        final rootKey = GlobalKey();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: KeyedSubtree(
                  key: rootKey,
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: measureVisible ? 1 : 0,
                        child: const DefaultTextStyle(
                          style: TextStyle(color: Colors.red, fontSize: 14),
                          child: Center(child: Text('Measure')),
                        ),
                      ),
                      const Positioned.fill(
                        child: DefaultTextStyle(
                          style: TextStyle(color: Colors.green, fontSize: 14),
                          child: Center(child: Text('Visible')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final actual = probeRootTextStyle(
          tester,
          rootFinder: find.byKey(rootKey),
        );
        expect(actual?.color, measureVisible ? Colors.red : Colors.green);
      },
    );
  }

  for (final state in [
    (value: 'typed', hintVisible: false, expected: Colors.green),
    (value: '', hintVisible: true, expected: Colors.red),
    (value: '', hintVisible: false, expected: null),
  ]) {
    testWidgets('reads the painted input text: $state', (tester) async {
      final rootKey = GlobalKey();
      final controller = TextEditingController(text: state.value);
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 60,
              child: KeyedSubtree(
                key: rootKey,
                child: Row(
                  children: [
                    Visibility(
                      visible: state.hintVisible,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: const SizedBox(
                        width: 100,
                        height: 40,
                        child: DefaultTextStyle(
                          style: TextStyle(color: Colors.red, fontSize: 14),
                          child: Text('Hint'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 40,
                      child: EditableText(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                        ),
                        cursorColor: Colors.green,
                        backgroundCursorColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final actual = probeRootTextStyle(
        tester,
        rootFinder: find.byKey(rootKey),
      );
      expect(actual?.color, state.expected);
    });
  }

  testWidgets(
    'dialog 형태 — 먼저 그려지는 trigger 라벨이 아니라 root 자신의 bounds 와 '
    '일치하는 dialog 자신의 스타일을 고른다',
    (tester) async {
      // Mirrors the real `dialog` manifest entry's documented shape
      // (`root_text_probe.dart`'s top comment, case 1): a small trigger
      // whose own `DefaultTextStyle.merge` sits ABOVE its own chrome
      // Container (matching `button.dart`'s `styledContent` — the merge is
      // the *parent* of the decorated box, not its child), stacked with a
      // dialog surface that — unlike the real `dialog` example where the
      // closed `Dialog` paints nothing at all — is genuinely open here and
      // is what root's own bounds actually track. The trigger is declared
      // FIRST (both trees put the trigger before the dialog — this is what
      // let the pre-#3852 "first Text in tree order" implementation read
      // the trigger's own label instead of anything belonging to the
      // dialog).
      const triggerStyle = TextStyle(
        color: Color(0xFF0F2248), // onPrimary-shaped — dark, on a filled button
        fontSize: 14,
      );
      const dialogStyle = TextStyle(
        color: Color(
          0xFFFCFCFD,
        ), // onSurface-shaped — near-white, on a dark surface
        fontSize: 16,
      );
      final rootKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: KeyedSubtree(
              key: rootKey,
              // A `SizedBox` fixes root's own bounds to exactly the
              // dialog surface's box (see below) — this is what a real
              // capture's `rootRenderObject`/`rootSize` represents: root's
              // *own*, already-measured geometry, not something this test
              // has to reverse-engineer from Column/Stack sizing rules.
              child: SizedBox(
                width: 300,
                height: 150,
                child: Stack(
                  children: [
                    // Trigger — visited FIRST in tree order (Stack lays out
                    // its `children` list in the order given), much
                    // smaller than root, positioned away from root's own
                    // origin. Neither its size nor its position falls
                    // within `_kChromeLayerToleranceInPx` (16px) of root's
                    // (300x150 at origin (0,0)) on any edge.
                    Positioned(
                      left: 4,
                      top: 4,
                      child: DefaultTextStyle.merge(
                        style: triggerStyle,
                        child: Container(
                          width: 90,
                          height: 32,
                          color: const Color(0xFF3355FF),
                          alignment: Alignment.center,
                          child: const Text('Open Dialog'),
                        ),
                      ),
                    ),
                    // Dialog surface — non-positioned, so it fills the
                    // `SizedBox` exactly (0px diff from root's own bounds
                    // on every edge): this is root's own chrome.
                    DefaultTextStyle.merge(
                      style: dialogStyle,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF1B1B22),
                        ),
                        child: Center(child: Text('Dialog content')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rootFinder = find.byKey(rootKey);

      final result = probeRootTextStyle(tester, rootFinder: rootFinder);

      expect(result, isNotNull);
      expect(
        result!.color,
        dialogStyle.color,
        reason:
            'root_text_probe 가 trigger 의 onPrimary 대신 dialog 자신의 색을 '
            '골라야 한다 — #3852 이 고치려던 "unrelated sibling" 케이스.',
      );
      expect(result.fontSize, dialogStyle.fontSize);
    },
  );

  testWidgets(
    'card 형태 — 더 깊은 header 오버라이드가 아니라 root 자신이 선언한 '
    'DefaultTextStyle 을 고른다',
    (tester) async {
      // Mirrors `root_text_probe.dart`'s top comment case 2: root (a
      // Card-shaped surface) wraps its whole subtree in
      // `DefaultTextStyle.merge(bodyStyle)` — root's OWN declared value —
      // but a `header` slot re-wraps that in a second, more-specific
      // `DefaultTextStyle.merge(headerStyle)` deeper inside. The header's
      // own `Text` is visited before the plain body `Text`, so the
      // pre-#3852 "first Text found, fully resolved" implementation
      // resolved THROUGH both merges and read the header's semibold/18px
      // override instead of root's own 400/16px.
      const bodyStyle = TextStyle(
        color: Color(0xFF18191B),
        fontWeight: FontWeight.w400,
        fontSize: 16,
      );
      const headerStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 18);
      final rootKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyedSubtree(
            key: rootKey,
            // Root's own chrome declares bodyStyle directly on itself —
            // this `DefaultTextStyle.merge` is the very first candidate
            // `probeRootTextStyle` encounters under root.
            child: DefaultTextStyle.merge(
              style: bodyStyle,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header slot — a deeper, more-specific override.
                      DefaultTextStyle.merge(
                        style: headerStyle,
                        child: const Text('Card Title'),
                      ),
                      const SizedBox(height: 8),
                      const Text('Card body copy'), // inherits bodyStyle
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rootFinder = find.byKey(rootKey);

      final result = probeRootTextStyle(tester, rootFinder: rootFinder);

      expect(result, isNotNull);
      expect(
        result!.fontWeight,
        bodyStyle.fontWeight,
        reason:
            'root_text_probe 가 header 의 semibold 오버라이드가 아니라 root '
            '자신의 bodyStyle(400) 을 골라야 한다 — #3852 이 고치려던 "deeper '
            'override" 케이스.',
      );
      expect(result.fontSize, bodyStyle.fontSize);
      expect(result.color, bodyStyle.color);
    },
  );

  testWidgets(
    'bare Text 분기 — 로컬 DefaultTextStyle 이 전혀 없으면 단일-경로로 도달한 '
    'ambient 스타일을 그대로 반환한다',
    (tester) async {
      // `probeRootTextStyle`'s own doc comment: when no `DefaultTextStyle`
      // widget stands between root and a bare `Text`, that `Text`'s own
      // fully-resolved style already *is* the ambient value at root's
      // position. #3909's structural walk reaches this `Text` the same way
      // it reaches everything else — a chain of single-child steps
      // (`SizedBox` → `Align` → `Text`, none of them branching) — so
      // nothing here needs to be sized/positioned unusually to prove the
      // point (the pre-#3909 version needed the `Text` deliberately
      // off-`rootSize` to prove its bounds-check was skipped for this
      // branch; the new algorithm has no bounds-check to skip).
      const ambientStyle = TextStyle(
        color: Color(0xFF18191B),
        fontSize: 20,
        fontWeight: FontWeight.w500,
      );
      final rootKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: ambientStyle,
            child: Align(
              alignment: Alignment.topLeft,
              child: KeyedSubtree(
                key: rootKey,
                child: const SizedBox(
                  width: 300,
                  height: 150,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    // No `DefaultTextStyle.merge` anywhere in this subtree
                    // — this `Text` resolves purely from the ambient ancestor.
                    child: Text('bare'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rootFinder = find.byKey(rootKey);

      final result = probeRootTextStyle(tester, rootFinder: rootFinder);

      expect(result, isNotNull);
      expect(result!.color, ambientStyle.color);
      expect(result.fontSize, ambientStyle.fontSize);
      expect(result.fontWeight, ambientStyle.fontWeight);
    },
  );

  testWidgets(
    '아무 후보도 없으면 null — 비교 대상이 없다는 뜻이지 조작된 불일치가 아니다',
    (tester) async {
      final rootKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyedSubtree(
            key: rootKey,
            // No `DefaultTextStyle`/`Text` anywhere under root at all.
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rootFinder = find.byKey(rootKey);

      final result = probeRootTextStyle(tester, rootFinder: rootFinder);

      expect(result, isNull);
    },
  );
}
