// EPIC-004 (#3597) child #3613 — WebLifecycleProbe.
//
// Proves `web_lifecycle_probe.dart` against the real `Dialog` (portalled
// through `OverlayHost`, the same host `CoUIWeb` installs at the app
// root) — not a hand-rolled stand-in.
//
// #3644 — the original version of this file drove the open→close
// transition with two `tester.pumpComponent(...)` calls, which never
// reaches `State.didUpdateComponent` (see `web_lifecycle_probe.dart`'s
// doc comment) and made the core assertion pass identically whether or
// not #3621's exit-window fix was even present in this lineage — the
// defect this file exists to lock down was invisible to it. This version
// drives the *same* `Dialog` instance through the transition via
// `ExitWindowHost`, a child rebuild that does reach `didUpdateComponent`.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog.dart';
import 'package:coui_web/src/overlay/overlay_host.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'web_lifecycle_probe.dart';

/// Finds the dialog panel — the element carrying `role="dialog"` — so
/// [expectExitAnimation] has a single element to read the rendered
/// `animation` property off of.
final Finder _panel = find.byComponentPredicate(
  (c) => c is DomComponent && c.attributes?['role'] == 'dialog',
);

void main() {
  /// Builds an [ExitWindowHost]-driven `Dialog`, portalled through
  /// `OverlayHost` — the real mount path (`_schedulePortalSync`/
  /// `OverlayPortal.of(context)`) rather than the SSR/test inline
  /// fallback `_DialogState.build` falls back to when no portal host is
  /// in the ancestor chain.
  Component buildHost(void Function(ExitWindowHostState state) onState) =>
      Theme.defaults(
        child: OverlayHost(
          child: ExitWindowHost(
            onState: onState,
            builder: (open) => Dialog(
              title: const Component.text('Title'),
              content: const Component.text('Body'),
              open: open,
            ),
          ),
        ),
      );

  group('WebLifecycleProbe — Dialog 퇴장 (#3613, corrected #3644)', () {
    testComponents(
      '양성 대조군 — 진입 상태에서는 패널 콘텐츠가 실제로 존재한다',
      (tester) async {
        tester.pumpComponent(buildHost((_) {}));
        await tester.pump();

        expect(find.text('Body'), findsOneComponent);
      },
    );

    // Regression lock for #3621 — Web Dialog used to unmount the moment
    // its open flag went false, with no exit transition at all. This is
    // structurally the same assertion as the one at lines 106-166 of
    // dialog_test.dart, made via the same child-rebuild shape. It is
    // duplicated here on purpose, not for redundancy's own sake: the
    // design-parity pipeline's JSON report only aggregates results from
    // this directory (packages/coui_web/test/parity), so a failure over
    // in dialog_test.dart never surfaces in that report. This probe
    // needs its own copy of the assertion to register as parity
    // coverage at all.
    testComponents(
      '퇴장 애니메이션이 실제로 존재한다 — 닫힘 트리거를 반영한 리빌드 '
      '직후에도 패널 콘텐츠가 남아 있다',
      (tester) async {
        late ExitWindowHostState host;
        tester.pumpComponent(buildHost((state) => host = state));
        await tester.pump();
        expect(find.text('Body'), findsOneComponent);

        host.setOpen(false);
        await tester.pump();
        expect(
          survivesImmediatelyAfterCloseTrigger(find.text('Body')),
          isTrue,
          reason:
              'the panel should still be in the tree right after the '
              'close-triggering rebuild — it has an exit transition to '
              'play. A `false` here means the exit-window deferral '
              '(#3621) is gone from this lineage.',
        );
      },
    );

    // #3644's genuinely new coverage — everything above restates what
    // `dialog_test.dart` already locks down structurally (see that
    // test's comment for why it is still worth restating here). DOM
    // survival alone cannot distinguish "the correct exit transition is
    // playing" from "the wrong one is" or "the right one at the wrong
    // speed" — both would still leave the panel in the tree. This reads
    // the rendered `animation` value itself.
    testComponents(
      '퇴장 애니메이션이 exit 키프레임 이름과 duration 토큰을 그대로 반영한다',
      (tester) async {
        late ExitWindowHostState host;
        tester.pumpComponent(buildHost((state) => host = state));
        await tester.pump();

        host.setOpen(false);
        await tester.pump();

        expectExitAnimation(
          _panel,
          exitKeyframeName: 'co-dialog-panel-exit',
          expectedDuration: CoreDialogStyle.defaultTransitionDuration,
        );
      },
    );
  });
}
