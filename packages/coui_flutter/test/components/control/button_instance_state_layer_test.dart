import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The hover and pressed wash a `plain` button wears when the surface it
/// sits on pins its label colour — a banner or toast action.
///
/// Read back from the resolver's decoration for each widget-state set,
/// which is what `Button` paints: a ramp wired into the style but never
/// reaching the fill would leave hover unchanged, and these tests would
/// see exactly that.
class _Capture extends StatelessWidget {
  const _Capture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);

    return const SizedBox.shrink();
  }
}

const Set<WidgetState> _kRest = {};
const Set<WidgetState> _kHover = {WidgetState.hovered};
const Set<WidgetState> _kPressed = {WidgetState.pressed};
const Set<WidgetState> _kFocus = {WidgetState.focused};

void main() {
  late BuildContext context;
  late ColorScheme scheme;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        home: _Capture((c) => context = c),
      ),
    );
    scheme = Theme.of(context).colorScheme;
  }

  Color fill(CoreButtonStyle? style, Set<WidgetState> states) {
    final r = resolveButton(
      context,
      variant: .plain,
      size: .md,
      shape: .rectangle,
      buttonStyle: style,
    );

    return (r.decoration.resolve(states) as BoxDecoration).color!;
  }

  Color wash(CoreColor ink, double weight) => Color.alphaBlend(
    scheme.resolve(ink).toValue().withValues(alpha: weight),
    const Color(0x00000000),
  );

  group('Button instance stateLayer', () {
    testWidgets('plain without a ramp keeps hover and pressed clear', (
      tester,
    ) async {
      await pump(tester);

      expect(fill(null, _kRest).a, 0);
      expect(fill(null, _kHover).a, 0);
      expect(fill(null, _kPressed).a, 0);
    });

    testWidgets('the ramp washes the instance label colour', (tester) async {
      await pump(tester);
      const ink = CoreColor.token(CoreColors.onInfo);
      const style = CoreButtonStyle(
        foregroundColor: ink,
        hoverForegroundColor: ink,
        stateLayer: CoreStateLayer.subtle,
      );

      expect(fill(style, _kRest).a, 0);
      expect(fill(style, _kHover), wash(ink, CoreOpacity.hover));
      expect(fill(style, _kPressed), wash(ink, CoreOpacity.pressed));
      // Focus is the ring, not a wash.
      expect(fill(style, _kFocus).a, 0);
    });
  });

  group('Banner and Toast actions show hover', () {
    for (final emphasis in CoreBannerEmphasis.values) {
      for (final variant in CoreBannerVariant.values) {
        testWidgets('banner ${emphasis.name} ${variant.name}', (tester) async {
          await pump(tester);
          final banner = resolveBanner(
            context,
            variant: variant,
            emphasis: emphasis,
          );

          for (final style in [
            banner.actionButtonStyle,
            banner.closeButtonStyle,
          ]) {
            expect(style.stateLayer, CoreStateLayer.subtle);
            final ink = style.foregroundColor!;
            expect(fill(style, _kHover), wash(ink, CoreOpacity.hover));
            expect(fill(style, _kPressed), wash(ink, CoreOpacity.pressed));
          }
        });
      }
    }

    for (final variant in CoreToastVariant.values) {
      testWidgets('toast ${variant.name} action', (tester) async {
        await pump(tester);
        final toast = resolveToast(
          context,
          variant: variant,
          dismissible: true,
        );
        final style = toast.actionButtonStyle;

        expect(style.stateLayer, CoreStateLayer.subtle);
        final ink = style.foregroundColor!;
        expect(fill(style, _kHover), wash(ink, CoreOpacity.hover));
        expect(fill(style, _kPressed), wash(ink, CoreOpacity.pressed));
      });
    }
  });
}
