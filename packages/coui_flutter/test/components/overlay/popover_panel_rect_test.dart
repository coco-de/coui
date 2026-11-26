import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Report = ({Rect rect, SchedulerPhase phase});

const ValueKey<String> _kPanelKey = ValueKey('panel');

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
            child: SizedBox(key: widget.anchorKey, width: 100, height: 40),
          ),
        ),
      ),
    ),
  );
}

void main() {
  PopoverEntryHandle<void> open(
    GlobalKey anchorKey,
    List<_Report> reports, {
    Alignment alignment = Alignment.topCenter,
    Alignment anchorAlignment = Alignment.bottomCenter,
  }) => const PopoverOverlayHandler().show<void>(
    context: anchorKey.currentContext!,
    alignment: alignment,
    anchorAlignment: anchorAlignment,
    modal: false,
    onPanelRect: (rect) => reports.add((
      rect: rect,
      phase: SchedulerBinding.instance.schedulerPhase,
    )),
    builder: (_) => const SizedBox(key: _kPanelKey, width: 120, height: 60),
  );

  testWidgets('the engine reports the panel box after the frame, the box it '
      'settled on', (tester) async {
    final anchorKey = GlobalKey();
    final top = ValueNotifier<double>(100);
    addTearDown(top.dispose);
    final reports = <_Report>[];

    await tester.pumpWidget(_Harness(anchorKey: anchorKey, top: top));
    final handle = open(anchorKey, reports);
    await tester.pump();
    await tester.pump();

    expect(reports, hasLength(1));
    expect(
      reports.single.phase,
      SchedulerPhase.postFrameCallbacks,
      reason:
          'a report from inside layout would let a listener call '
          'setState during the frame',
    );
    expect(reports.single.rect.size, const Size(120, 60));

    // Once the open animation has finished the panel is where it was said to
    // be: the report is the box the panel was laid out in, not a box that
    // moves with the animation.
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getRect(find.byKey(_kPanelKey)), reports.single.rect);

    handle.dismissImmediately();
    await tester.pump();
  });

  testWidgets('the box is the one collision handling settled on', (
    tester,
  ) async {
    final anchorKey = GlobalKey();
    final top = ValueNotifier<double>(0);
    addTearDown(top.dispose);
    final reports = <_Report>[];

    await tester.pumpWidget(_Harness(anchorKey: anchorKey, top: top));
    // Above the trigger, against the top edge: nothing fits there, so the
    // engine puts the panel below it, and that is what is reported.
    final handle = open(
      anchorKey,
      reports,
      alignment: Alignment.bottomCenter,
      anchorAlignment: Alignment.topCenter,
    );
    await tester.pump();
    await tester.pump();

    final anchor = tester.getRect(find.byKey(anchorKey));
    expect(reports, hasLength(1));
    expect(
      reports.single.rect.top,
      greaterThanOrEqualTo(anchor.bottom),
      reason: 'flipped below the trigger',
    );

    handle.dismissImmediately();
    await tester.pump();
  });

  testWidgets('a panel that moves is reported again, and one that does not '
      'is not', (tester) async {
    final anchorKey = GlobalKey();
    final top = ValueNotifier<double>(100);
    addTearDown(top.dispose);
    final reports = <_Report>[];

    await tester.pumpWidget(_Harness(anchorKey: anchorKey, top: top));
    final handle = open(anchorKey, reports);
    await tester.pump();
    await tester.pump();
    expect(reports, hasLength(1));

    // `follow` lays the panel out every frame; nothing moved, nothing to say.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(
      reports,
      hasLength(1),
      reason: 'the same box is not a change a listener could draw from',
    );

    top.value = 220;
    await tester.pump();
    await tester.pump();
    expect(reports, hasLength(2));
    expect(reports.last.rect.top - reports.first.rect.top, closeTo(120, 0.01));
    expect(reports.last.phase, SchedulerPhase.postFrameCallbacks);

    handle.dismissImmediately();
    await tester.pump();
  });

  testWidgets('a panel nobody listens to is laid out as it always was', (
    tester,
  ) async {
    final anchorKey = GlobalKey();
    final top = ValueNotifier<double>(100);
    addTearDown(top.dispose);

    await tester.pumpWidget(_Harness(anchorKey: anchorKey, top: top));
    final handle = const PopoverOverlayHandler().show<void>(
      context: anchorKey.currentContext!,
      alignment: Alignment.topCenter,
      anchorAlignment: Alignment.bottomCenter,
      modal: false,
      builder: (_) => const SizedBox(key: _kPanelKey, width: 120, height: 60),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final anchor = tester.getRect(find.byKey(anchorKey));
    final panel = tester.getRect(find.byKey(_kPanelKey));
    expect(panel.size, const Size(120, 60));
    expect(panel.top, closeTo(anchor.bottom, 0.5));
    expect(tester.takeException(), isNull);

    handle.dismissImmediately();
    await tester.pump();
  });
}
