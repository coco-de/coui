// The drawer's backdrop has no zoom-out unless a style asks for it: the page
// behind keeps its size and square corners and only the scrim dims it. The
// zoom-out (95 %, rounded) is the opt-in effect the swiper's `drawer` variant
// states.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

ResolvedDrawerBackdropRuntime _resolve(
  ComponentTester tester, {
  CoreDrawerStyle? style,
}) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return resolveDrawerBackdropRuntime(context, drawerStyle: style);
}

void main() {
  group('drawer backdrop', () {
    testComponents('does not zoom out by default', (tester) async {
      final runtime = _resolve(tester);
      expect(runtime.scale, 1.0);
      expect(runtime.cornerRadiusTopLeftPx, 0);
      expect(runtime.cornerRadiusBottomRightPx, 0);
    });

    testComponents('zooms out when a style states the effect', (tester) async {
      final runtime = _resolve(
        tester,
        style: const CoreDrawerStyle(
          backdropScale: CoreDrawerStyle.zoomBackdropScale,
          backdropCornerRadius: CoreDrawerStyle.zoomBackdropCornerRadius,
        ),
      );
      expect(runtime.scale, 0.95);
      expect(runtime.cornerRadiusTopLeftPx, 24);
    });

    testComponents('the swiper drawer variant carries the zoom-out', (
      tester,
    ) async {
      final style = CoreSwiperStyle.defaultsByVariant[CoreSwiperVariant.drawer];
      final runtime = _resolve(tester, style: style);
      expect(runtime.scale, 0.95);
    });
  });
}
