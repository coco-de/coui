import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('Hover', () {
    testWidgets('renders child widget', (tester) async {
      await pumpTestApp(
        tester,
        Hover(
          onHover: (_) {},
          child: const Text('Hover Target'),
        ),
      );

      expect(find.text('Hover Target'), findsOneWidget);
    });
  });

  group('Hover', () {
    testWidgets('renders child widget', (tester) async {
      await pumpTestApp(
        tester,
        const Hover(child: Text('Co Hover Me')),
      );

      expect(find.text('Co Hover Me'), findsOneWidget);
    });

    testWidgets('fires onEnter/onExit immediately on pointer transitions', (
      tester,
    ) async {
      var entered = false;
      var exited = false;
      await pumpTestApp(
        tester,
        Hover(
          onEnter: () => entered = true,
          onExit: () => exited = true,
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final gesture = await tester.createGesture(kind: .mouse);
      await gesture.addPointer(location: .zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byType(Hover)));
      await tester.pump();
      expect(entered, isTrue);

      await gesture.moveTo(.zero);
      await tester.pump();
      expect(exited, isTrue);
    });

    testWidgets('scaleUp effect renders an AnimatedScale wrapper', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Hover(
          effect: .scaleUp,
          child: SizedBox(width: 100, height: 100),
        ),
      );

      expect(find.byType(AnimatedScale), findsOneWidget);
    });

    testWidgets('shadow effect resolves a hovered box-shadow stack', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Hover(
          effect: .shadow,
          child: SizedBox(width: 100, height: 100),
        ),
      );

      // The drop-shadow effect composes one blurred/tinted child silhouette
      // per resolved shadow layer, each faded in/out by its own
      // AnimatedOpacity (never unmounted — see `_DropShadow`'s doc comment
      // in hover.dart for why an AnimatedContainer boxShadow null↔list lerp
      // was replaced: it scaled blur from zero, a hard-edged flash, instead
      // of a clean fade).
      List<double> currentShadowOpacities() => tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .map((w) => w.opacity)
          .toList();

      // Idle: shadow layers exist but are fully transparent.
      final idleOpacities = currentShadowOpacities();
      expect(idleOpacities, isNotEmpty);
      expect(idleOpacities, everyElement(0.0));

      final gesture = await tester.createGesture(kind: .mouse);
      await gesture.addPointer(location: .zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(Hover)));
      await tester.pump();

      // Hovered: every shadow layer fades to fully opaque.
      final hoveredOpacities = currentShadowOpacities();
      expect(hoveredOpacities, isNotEmpty);
      expect(hoveredOpacities, everyElement(1.0));
    });

    testWidgets('onHover fires true after waitDuration', (tester) async {
      bool? reported;
      await pumpTestApp(
        tester,
        Hover(
          onHover: (value) => reported = value,
          waitDuration: const Duration(milliseconds: 50),
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final gesture = await tester.createGesture(kind: .mouse);
      await gesture.addPointer(location: .zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(Hover)));
      await tester.pump();

      expect(reported, isNull);
      await tester.pump(const Duration(milliseconds: 60));
      expect(reported, isTrue);
    });
  });
}
