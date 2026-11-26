import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Report = ({bool horizontal, bool vertical, SchedulerPhase phase});

/// A trigger whose distance from the top edge the test moves while a
/// `follow` overlay tracks it.
class _Harness extends StatefulWidget {
  const _Harness({required this.anchorKey, required this.top});

  final GlobalKey anchorKey;
  final ValueNotifier<double> top;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  @override
  Widget build(BuildContext context) => material.MaterialApp(
    home: Theme(
      data: const ThemeData(),
      child: ValueListenableBuilder(
        valueListenable: widget.top,
        builder: (_, top, _) => Padding(
          padding: EdgeInsets.only(top: top),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              key: widget.anchorKey,
              width: 100,
              height: 40,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the engine reports a flip after the frame, and only when '
      'it changes', (tester) async {
    final anchorKey = GlobalKey();
    final top = ValueNotifier<double>(0);
    addTearDown(top.dispose);
    final reports = <_Report>[];

    await tester.pumpWidget(_Harness(anchorKey: anchorKey, top: top));

    // Above the trigger — against the top edge that cannot fit, so the
    // engine flips it below.
    final handle = const PopoverOverlayHandler().show<void>(
      context: anchorKey.currentContext!,
      alignment: Alignment.bottomCenter,
      modal: false,
      onFlipResolved:
          ({required invertedHorizontally, required invertedVertically}) {
            reports.add((
              horizontal: invertedHorizontally,
              vertical: invertedVertically,
              phase: SchedulerBinding.instance.schedulerPhase,
            ));
          },
      builder: (_) => const SizedBox(width: 120, height: 60),
    );
    await tester.pump();
    await tester.pump();

    expect(reports, hasLength(1));
    expect(reports.single.vertical, isTrue);
    expect(reports.single.horizontal, isFalse);
    expect(
      reports.single.phase,
      SchedulerPhase.postFrameCallbacks,
      reason:
          'a report from inside layout would let a listener call '
          'setState during the frame',
    );

    // `follow` re-lays the panel out every frame. Moving the trigger
    // without leaving the flipping zone must stay silent.
    for (final y in [4.0, 8.0, 12.0]) {
      top.value = y;
      await tester.pump();
      await tester.pump();
    }
    expect(
      reports,
      hasLength(1),
      reason:
          'the panel moved but did not flip — nothing changed that a '
          'listener could draw from',
    );

    // Room above now — the flip is undone, and that is a change.
    top.value = 300;
    await tester.pump();
    await tester.pump();
    expect(reports, hasLength(2));
    expect(reports.last.vertical, isFalse);
    expect(reports.last.phase, SchedulerPhase.postFrameCallbacks);

    handle.dismissImmediately();
    await tester.pump();
  });
}
