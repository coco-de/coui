// The host that fades a panel is correct on its own, whatever mounts it.
//
// The popover engine and the dialog route each rebuild their panel on every
// frame of their animation, so a host that read the progress only when its
// parent rebuilt it would look right under both. A third host need not: a
// panel handed to a transition that rebuilds nothing is built once and then
// only moves. These tests mount the host the way such a parent would — built
// once, an animation moving under it — and read what it does.
//
// What the surface then draws at each progress is held against the shared
// table by `popover_glass_fade_test.dart`; what this holds is the hand-off:
// the progress reaches the surface, the claim moves the opacity off the
// panel, and a panel nobody claims is faded as a whole.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/surface_fade.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const Duration _kRun = Duration(milliseconds: 1000);

const w.Key _plain = w.ValueKey('plain');

const w.Widget _glassPanel = Popup(
  children: [w.SizedBox(width: 120, height: 60)],
);

/// A host over [child], driven by a controller nothing else listens to.
///
/// The host is built once: nothing here rebuilds it again, so what it
/// publishes after that is what it heard from the animation itself.
Future<w.AnimationController> _mount(
  WidgetTester tester,
  w.Widget child, {
  CoreSurfaceStyleId style = CoreSurfaceStyleId.liquidGlass,
}) async {
  final controller = w.AnimationController(vsync: tester, duration: _kRun);
  await pumpTestApp(
    tester,
    SurfaceFadeHost(animation: controller, child: child),
    surfaceStyle: style,
  );

  return controller;
}

/// Takes the tree down and then the controller, inside the test: a ticker that
/// is still running when the body ends is a leak the harness reports.
Future<void> _end(WidgetTester tester, w.AnimationController controller) async {
  await tester.pumpWidget(const w.SizedBox());
  controller.dispose();
}

/// The host's own fade: the nearest `RenderAnimatedOpacity` above [of].
RenderAnimatedOpacity _fadeAbove(WidgetTester tester, Finder of) {
  RenderAnimatedOpacity? found;
  tester.element(of).visitAncestorElements((element) {
    final render = element is RenderObjectElement ? element.renderObject : null;
    if (render is RenderAnimatedOpacity) {
      found = render;

      return false;
    }

    return true;
  });

  return found!;
}

List<RenderSurfaceFadeBox> _fadeBoxes(WidgetTester tester) => [
  for (final element in find.byType(SurfaceFadeBox).evaluate())
    element.renderObject! as RenderSurfaceFadeBox,
];

void main() {
  group('a host over a glass panel', () {
    testWidgets('hands the surface the progress of an animation nothing else '
        'rebuilds for', (tester) async {
      final controller = await _mount(tester, _glassPanel);
      controller.forward();
      await tester.pump();
      expect(_fadeBoxes(tester).single.progress, 0);

      await tester.pump(const Duration(milliseconds: 250));
      expect(_fadeBoxes(tester).single.progress, closeTo(0.25, 1e-9));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_fadeBoxes(tester).single.progress, closeTo(0.75, 1e-9));

      await _end(tester, controller);
    });

    testWidgets('takes its own opacity off the panel once a surface claims '
        'the fade, and keeps it nothing while the animation is', (
      tester,
    ) async {
      final controller = await _mount(tester, _glassPanel);
      final panel = find.byType(Popup);

      // At nothing the panel is not painted, claimed or not.
      expect(_fadeAbove(tester, panel).opacity.value, 0);

      controller.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        _fadeAbove(tester, panel).opacity.value,
        1,
        reason: 'the surface fades itself, so the host does not',
      );

      await _end(tester, controller);
    });
  });

  group('a host over a panel nobody claims', () {
    testWidgets('fades it as a whole by its own opacity', (tester) async {
      final controller = await _mount(
        tester,
        const w.SizedBox(key: _plain, width: 120, height: 60),
      );
      final panel = find.byKey(_plain);
      controller.forward();
      await tester.pump();

      var elapsed = Duration.zero;
      for (final level in [0.25, 0.5, 0.75]) {
        final next = Duration(milliseconds: (level * 1000).round());
        await tester.pump(next - elapsed);
        elapsed = next;

        expect(
          _fadeAbove(tester, panel).opacity.value,
          closeTo(level, 1e-9),
          reason: 'level $level',
        );
      }
      expect(find.byType(SurfaceFadeBox), findsNothing);

      await _end(tester, controller);
    });

    testWidgets('a surface that draws no pass leaves the fade to the host', (
      tester,
    ) async {
      final controller = await _mount(
        tester,
        _glassPanel,
        style: CoreSurfaceStyleId.defaultStyle,
      );
      controller.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(BackdropFilter), findsNothing);
      expect(
        _fadeAbove(tester, find.byType(Popup)).opacity.value,
        closeTo(0.5, 1e-9),
      );

      await _end(tester, controller);
    });
  });

  group('a host that is given another animation', () {
    testWidgets('follows the new one, and lets the old one go', (tester) async {
      final first = w.AnimationController(vsync: tester, duration: _kRun);
      final second = w.AnimationController(vsync: tester, duration: _kRun);
      final current = ValueNotifier<w.Animation<double>>(first);
      // The host stays where it is; what changes is the animation it is given.
      await pumpTestApp(
        tester,
        w.ValueListenableBuilder<w.Animation<double>>(
          valueListenable: current,
          builder: (_, animation, _) =>
              SurfaceFadeHost(animation: animation, child: _glassPanel),
        ),
        surfaceStyle: CoreSurfaceStyleId.liquidGlass,
      );

      first.value = 0.25;
      await tester.pump();
      expect(_fadeBoxes(tester).single.progress, closeTo(0.25, 1e-9));

      current.value = second;
      second.value = 0.75;
      await tester.pump();
      expect(_fadeBoxes(tester).single.progress, closeTo(0.75, 1e-9));

      // The one it let go of moves nothing.
      first.value = 0.1;
      await tester.pump();
      expect(_fadeBoxes(tester).single.progress, closeTo(0.75, 1e-9));

      await tester.pumpWidget(const w.SizedBox());
      current.dispose();
      first.dispose();
      second.dispose();
    });

    testWidgets('fades a panel nobody claims by the new one', (tester) async {
      final first = w.AnimationController(vsync: tester, duration: _kRun);
      final second = w.AnimationController(vsync: tester, duration: _kRun);
      final current = ValueNotifier<w.Animation<double>>(first);
      await pumpTestApp(
        tester,
        w.ValueListenableBuilder<w.Animation<double>>(
          valueListenable: current,
          builder: (_, animation, _) => SurfaceFadeHost(
            animation: animation,
            child: const w.SizedBox(key: _plain, width: 120, height: 60),
          ),
        ),
        surfaceStyle: CoreSurfaceStyleId.liquidGlass,
      );
      final panel = find.byKey(_plain);

      first.value = 0.25;
      await tester.pump();
      expect(_fadeAbove(tester, panel).opacity.value, closeTo(0.25, 1e-9));

      current.value = second;
      second.value = 0.6;
      await tester.pump();
      expect(_fadeAbove(tester, panel).opacity.value, closeTo(0.6, 1e-9));

      // The opacity on the panel is the new animation's, not the old one's.
      first.value = 0.1;
      await tester.pump();
      expect(_fadeAbove(tester, panel).opacity.value, closeTo(0.6, 1e-9));

      await tester.pumpWidget(const w.SizedBox());
      current.dispose();
      first.dispose();
      second.dispose();
    });
  });
}
