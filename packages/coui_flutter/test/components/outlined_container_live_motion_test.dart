import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('live reduced motion settles chrome and preserves child focus', (
    tester,
  ) async {
    var reduced = false;
    var expanded = false;
    late StateSetter update;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final content = Focus(
      focusNode: focus,
      child: StatefulBuilder(
        builder: (_, _) => const SizedBox(height: 20),
      ),
    );
    await pumpTestApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: OutlinedContainer(
              containerStyle: CoreOutlinedContainerStyle(
                width: expanded ? 180 : 100,
                padding: CoreEdgeInsets.all(expanded ? 16 : 0),
                duration: const Duration(milliseconds: 400),
                backgroundColor: expanded
                    ? const CoreColor(0xFF0000FF)
                    : const CoreColor(0xFFFF0000),
              ),
              child: content,
            ),
          );
        },
      ),
      surfaceStyle: .liquidGlass,
    );
    final probe = find.descendant(
      of: find.byType(OutlinedContainer),
      matching: find.byType(StatefulBuilder),
    );
    final contentState = tester.state(probe);
    final blurState = tester.state(find.byType(SurfaceBlur));
    focus.requestFocus();
    await tester.pump();
    update(() => expanded = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getSize(find.byType(OutlinedContainer)).width, lessThan(180));
    expect(tester.hasRunningAnimations, isTrue);

    update(() => reduced = true);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.getSize(find.byType(OutlinedContainer)).width, 180);
    expect(identical(tester.state(probe), contentState), isTrue);
    expect(
      identical(tester.state(find.byType(SurfaceBlur)), blurState),
      isTrue,
    );
    expect(focus.hasFocus, isTrue);
    final chrome = find
        .descendant(
          of: find.byType(OutlinedContainer),
          matching: find.byType(AnimatedContainer),
        )
        .first;
    final target = tester.widget<AnimatedContainer>(chrome).decoration;
    final painted = tester
        .widget<DecoratedBox>(
          find
              .descendant(of: chrome, matching: find.byType(DecoratedBox))
              .first,
        )
        .decoration;
    expect(painted, target);

    update(() => reduced = false);
    await tester.pump();
    expect(identical(tester.state(probe), contentState), isTrue);
    expect(focus.hasFocus, isTrue);
    update(() => expanded = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pressed glass chip stops all motion when preference changes', (
    tester,
  ) async {
    var reduced = false;
    late StateSetter update;
    await pumpTestApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: Chip(label: 'Action', onTap: () {}),
          );
        },
      ),
      surfaceStyle: .liquidGlass,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Action')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    update(() => reduced = true);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
