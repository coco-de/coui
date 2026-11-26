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

void main() {
  testComponents('widget style overrides project border preservation', (
    tester,
  ) async {
    late BuildContext context;
    tester.pumpComponent(
      Theme(
        data: ThemeData.coui.copyWith(
          coreComponentTheme: const CoreComponentTheme(
            outlinedContainer: CoreOutlinedContainerTheme(
              style: CoreOutlinedContainerStyle(
                borderColor: CoreColor.transparent,
                borderWidth: 2,
                preserveTransparentBorder: true,
              ),
            ),
          ),
        ),
        child: _ContextCapture((value) => context = value),
      ),
    );
    final inherited = resolveOutlinedContainer(context: context);
    final overridden = resolveOutlinedContainer(
      context: context,
      containerStyle: const CoreOutlinedContainerStyle(
        preserveTransparentBorder: false,
      ),
    );
    expect(
      inherited.root.inlineStyles!.properties['border-width'],
      'var(--coui-stroke-width-2)',
    );
    expect(
      overridden.root.inlineStyles!.properties['border-width'],
      'var(--coui-stroke-width-0)',
    );
  });

  for (final preserve in [false, true]) {
    testComponents('opaque none has no inset with preserve=$preserve', (
      tester,
    ) async {
      late BuildContext context;
      pumpWithTheme(tester, _ContextCapture((value) => context = value));
      final resolved = resolveOutlinedContainer(
        context: context,
        containerStyle: CoreOutlinedContainerStyle(
          borderStyle: .none,
          borderColor: const CoreColor(0xffff0000),
          borderWidth: 2,
          preserveTransparentBorder: preserve,
        ),
      );
      expect(
        resolved.root.inlineStyles!.properties['border-width'],
        'var(--coui-stroke-width-0)',
      );
    });
  }

  for (final style in CoreOutlinedContainerBorderStyle.values) {
    for (final preserve in [false, true]) {
      testComponents('transparent $style layout, preserve=$preserve', (
        tester,
      ) async {
        late BuildContext context;
        pumpWithTheme(tester, _ContextCapture((value) => context = value));
        final resolved = resolveOutlinedContainer(
          context: context,
          containerStyle: CoreOutlinedContainerStyle(
            borderColor: CoreColor.transparent,
            borderWidth: 2,
            borderStyle: style,
            preserveTransparentBorder: preserve,
          ),
        );
        final patterned =
            style == CoreOutlinedContainerBorderStyle.dashed ||
            style == CoreOutlinedContainerBorderStyle.dotted;
        final root = resolved.root.inlineStyles!.properties;
        final inset =
            preserve && style != CoreOutlinedContainerBorderStyle.none;
        if (!patterned || preserve) {
          expect(
            root['border-width'],
            'var(--coui-stroke-width-${inset ? 2 : 0})',
          );
        } else {
          expect(root.containsKey('border-width'), isFalse);
        }
        if (patterned && preserve) {
          expect(root['border-style'], 'solid');
          expect(root['border-color'], 'transparent');
          expect(
            resolved.dashRect!.inlineStyles!.properties['stroke-width'],
            'var(--coui-stroke-width-2)',
          );
        }
      });
    }
  }

  for (final style in [
    CoreOutlinedContainerBorderStyle.dashed,
    CoreOutlinedContainerBorderStyle.dotted,
  ]) {
    testComponents('$style reserves the same width for clear and opaque', (
      tester,
    ) async {
      late BuildContext context;
      pumpWithTheme(tester, _ContextCapture((value) => context = value));
      for (final color in [
        CoreColor.transparent,
        const CoreColor(0xffff0000),
      ]) {
        final resolved = resolveOutlinedContainer(
          context: context,
          containerStyle: CoreOutlinedContainerStyle(
            borderColor: color,
            borderWidth: 2,
            borderStyle: style,
            preserveTransparentBorder: true,
          ),
        );
        expect(
          resolved.root.inlineStyles!.properties['border-width'],
          'var(--coui-stroke-width-2)',
        );
        expect(
          resolved.root.inlineStyles!.properties['border-color'],
          'transparent',
        );
        expect(
          resolved.dashRect!.inlineStyles!.properties['stroke-width'],
          'var(--coui-stroke-width-2)',
        );
      }
    });
  }

  testComponents('transparent border reserves width only when requested', (
    tester,
  ) async {
    late BuildContext context;
    pumpWithTheme(tester, _ContextCapture((value) => context = value));
    final normal = resolveOutlinedContainer(
      context: context,
      containerStyle: const CoreOutlinedContainerStyle(
        borderColor: CoreColor.transparent,
        borderWidth: 1,
      ),
    );
    final preserved = resolveOutlinedContainer(
      context: context,
      containerStyle: const CoreOutlinedContainerStyle(
        borderColor: CoreColor.transparent,
        borderWidth: 1,
        preserveTransparentBorder: true,
      ),
    );
    expect(normal, isA<ResolvedOutlinedContainer>());
    expect(
      normal.root.inlineStyles!.properties['border-width'],
      'var(--coui-stroke-width-0)',
    );
    expect(
      preserved.root.inlineStyles!.properties['border-width'],
      'var(--coui-stroke-width-1)',
    );
  });
}
