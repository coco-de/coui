import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('modal settles live chrome without losing content or focus', (
    tester,
  ) async {
    var reduced = false;
    var selected = false;
    late StateSetter update;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final content = Focus(
      focusNode: focus,
      child: StatefulBuilder(
        builder: (_, _) => const SizedBox(width: 100, height: 40),
      ),
    );
    await pumpTestApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: ModalContainer(
              filled: true,
              fillColor: selected
                  ? const Color(0xFF0000FF)
                  : const Color(0xFFFF0000),
              duration: const Duration(milliseconds: 400),
              child: content,
            ),
          );
        },
      ),
      surfaceStyle: .liquidGlass,
    );
    final probe = find.descendant(
      of: find.byType(ModalContainer),
      matching: find.byType(StatefulBuilder),
    );
    final contentState = tester.state(probe);
    final blurState = tester.state(find.byType(SurfaceBlur));
    final chrome = find.descendant(
      of: find.byType(ModalContainer),
      matching: find.byType(AnimatedContainer),
    );
    Decoration? target() => tester.widget<AnimatedContainer>(chrome).decoration;
    Decoration painted() => tester
        .widget<DecoratedBox>(
          find
              .descendant(of: chrome, matching: find.byType(DecoratedBox))
              .first,
        )
        .decoration;

    focus.requestFocus();
    await tester.pump();
    update(() => selected = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.hasRunningAnimations, isTrue);
    expect(painted(), isNot(target()));

    update(() => reduced = true);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(painted(), target());
    expect(identical(tester.state(probe), contentState), isTrue);
    expect(
      identical(tester.state(find.byType(SurfaceBlur)), blurState),
      isTrue,
    );
    expect(focus.hasFocus, isTrue);

    update(() => reduced = false);
    await tester.pump();
    expect(identical(tester.state(probe), contentState), isTrue);
    expect(focus.hasFocus, isTrue);
    update(() => selected = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
