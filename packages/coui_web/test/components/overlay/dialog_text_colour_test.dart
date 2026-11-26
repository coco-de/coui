// Dialog title / body colours come from the Core typography defaults, and
// the panel foreground is only what the rest of the panel inherits.
//
// Each text slot emits its own default's colour class (`defaultTitleStyle`,
// `defaultContentStyle`), and the panel carries the foreground class
// (`defaultsByVariant.foregroundColor`) that the leading / trailing slots
// inherit. The Flutter twin paints the same three from the same three
// fields; this pins the Web half so both are held from both ends.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

late ResolvedDialog _seen;

class _Capture extends StatelessComponent {
  const _Capture({this.dialogStyle});

  final CoreDialogStyle? dialogStyle;

  @override
  Component build(BuildContext context) {
    _seen = resolveDialog(context, dialogStyle: dialogStyle);
    return const Component.text('x');
  }
}

Future<ResolvedDialog> _resolve(
  ComponentTester tester, {
  CoreDialogStyle? dialogStyle,
}) async {
  pumpWithTheme(tester, _Capture(dialogStyle: dialogStyle));
  await tester.pump();
  return _seen;
}

String _textClass(CoreColor color) => 'text-${color.tailwindColor}';

void main() {
  group('Dialog text colours come from the Core defaults', () {
    testComponents('body emits the defaultContentStyle colour class', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      final classes = resolved.content.className.split(' ');

      expect(
        classes,
        contains(_textClass(CoreDialogStyle.defaultContentStyle.color!)),
      );
      expect(
        classes,
        isNot(
          contains(_textClass(const CoreColor.token(CoreColors.onSurface))),
        ),
      );
    });

    testComponents('title emits the defaultTitleStyle colour class', (
      tester,
    ) async {
      final resolved = await _resolve(tester);

      expect(
        resolved.titleSlot.className.split(' '),
        contains(_textClass(CoreDialogStyle.defaultTitleStyle.color!)),
      );
    });

    testComponents('the panel carries the foreground the slots inherit', (
      tester,
    ) async {
      final resolved = await _resolve(tester);

      expect(
        resolved.panel.className.split(' '),
        contains(_textClass(CoreDialogStyle.defaultsByVariant.foregroundColor)),
      );
    });

    testComponents('a contentStyle token colour override wins', (
      tester,
    ) async {
      const override = CoreColor.token(CoreColors.error);
      final resolved = await _resolve(
        tester,
        dialogStyle: const CoreDialogStyle(
          contentStyle: CoreTextStyle(color: override),
        ),
      );
      final classes = resolved.content.className.split(' ');

      expect(classes, contains(_textClass(override)));
      expect(
        classes,
        isNot(contains(_textClass(CoreDialogStyle.defaultContentStyle.color!))),
      );
    });
  });
}
