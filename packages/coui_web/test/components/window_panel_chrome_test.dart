// What a bare `WindowPanel` draws when nothing is stated: the 12 corner, the
// `md` step of the shadow scale, a title bar padded 12 on its sides with no
// divider under it.
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/window_panel/window_panel_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

ResolvedWindowPanel _resolve(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return resolveWindowPanel(context);
}

void main() {
  group('WindowPanel default chrome', () {
    testComponents('the frame corner is 12', (tester) async {
      final inline = _resolve(tester).root.inlineStyles!.properties;

      expect(
        inline['border-radius'],
        const CoreBorderRadius.all(12).toValue(),
      );
    });

    testComponents('the frame casts the md step and its rim', (tester) async {
      final inline = _resolve(tester).root.inlineStyles!.properties;
      final shadow = inline['box-shadow']!;

      // The step's own variable — an extra alpha over the base colour would
      // have been a different, literal stack.
      expect(shadow, 'var(--shadow-md), $kSurfaceRimVar');
    });

    testComponents('the title bar pads its sides by 12', (tester) async {
      final inline = _resolve(tester).titleBar.inlineStyles!.properties;

      expect(
        inline['padding'],
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12).toValue(),
      );
    });

    testComponents('the title bar draws no divider under itself', (
      tester,
    ) async {
      final titleBar = _resolve(tester).titleBar;
      final classes = titleBar.className.split(' ');
      final inline = titleBar.inlineStyles!.properties;

      expect(classes.where((cls) => cls.startsWith('border')), isEmpty);
      expect(inline.keys.where((key) => key.startsWith('border-')), [
        'border-radius',
      ]);
    });
  });

  group('WindowPanel control glyph colour', () {
    testComponents('the close × rests on the surface-variant tone, not error', (
      tester,
    ) async {
      // The style the panel forwards to the close `Button` — the glyph is the
      // button's child, so this foreground is what paints it.
      final resolved = _resolve(tester);

      expect(
        resolved.closeButtonStyle.foregroundColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        resolved.closeButtonStyle.foregroundColor,
        resolved.controlButtonStyle.foregroundColor,
      );
    });

    testComponents('the close button keeps its error emphasis on hover', (
      tester,
    ) async {
      final style = _resolve(tester).closeButtonStyle;

      expect(
        style.hoverBackgroundColor,
        const CoreColor.token(CoreColors.error),
      );
      expect(
        style.hoverForegroundColor,
        const CoreColor.token(CoreColors.onError),
      );
    });
  });
}
