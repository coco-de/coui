// The Dialog panel's layout defaults and the two gaps its stack carries,
// read back from what the Web resolver emits and what the widget renders.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
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

/// The sizes of every `Gap` the rendered Dialog stack carries, in DOM order.
List<double?> _gapSizes(ComponentTester tester) => [
  for (final element in find.byType(Gap).evaluate())
    (element.component as Gap).gapStyle?.size,
];

void main() {
  group('Dialog panel layout defaults', () {
    testComponents('the panel pads 24 above and on both sides, 20 below', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      final padding = resolved.panel.inlineStyles!.properties['padding']!;

      expect(
        padding,
        const CoreEdgeInsets.only(
          top: CoreSpace.space24,
          left: CoreSpace.space24,
          right: CoreSpace.space24,
          bottom: CoreSpace.space20,
        ).toValue(),
      );
      expect(padding, contains('var(--coui-space-20)'));
      expect(padding, contains('var(--coui-space-24)'));
    });

    testComponents('the panel stops at the 560 layout width', (tester) async {
      final resolved = await _resolve(tester);

      expect(
        resolved.panel.inlineStyles!.properties['max-width'],
        '${CoreLayout.layout560 / kRemDivisor}rem',
      );
      expect(CoreLayout.layout560, 560);
    });

    testComponents('the panel holds 280 but never past the route room', (
      tester,
    ) async {
      final resolved = await _resolve(tester);

      expect(
        resolved.panel.inlineStyles!.properties['min-width'],
        'min(${CoreLayout.layout280 / kRemDivisor}rem, '
        'calc(100% - 2 * ${spaceCss(CoreDialogStyle.defaultRoutePadding)}))',
      );
    });

    testComponents('the panel fills a phone less the route room', (
      tester,
    ) async {
      final resolved = await _resolve(tester);

      expect(
        resolved.panel.inlineStyles!.properties['width'],
        'calc(100% - 2 * ${spaceCss(CoreDialogStyle.defaultRoutePadding)})',
      );
    });

    testComponents('the head-to-body gap is 14 and the actions gap is 20', (
      tester,
    ) async {
      final resolved = await _resolve(tester);

      expect(resolved.sectionGapStyle.size, CoreSpace.space14);
      expect(resolved.actionsGapStyle.size, CoreSpace.space20);
    });

    testComponents('a stated actionsGapStyle reaches the resolved slot only', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        dialogStyle: const CoreDialogStyle(
          actionsGapStyle: CoreGapStyle(size: CoreSpace.space32),
        ),
      );

      expect(resolved.actionsGapStyle.size, CoreSpace.space32);
      expect(resolved.sectionGapStyle.size, CoreSpace.space14);
    });
  });

  group('Dialog stack gaps, as rendered', () {
    testComponents('content takes the section gap and actions the actions '
        'gap', (tester) async {
      pumpWithTheme(
        tester,
        const Dialog(
          title: Component.text('Title'),
          content: Component.text('Body'),
          actions: [Component.text('OK')],
        ),
      );
      await tester.pump();

      expect(_gapSizes(tester), [CoreSpace.space14, CoreSpace.space20]);
    });

    testComponents('without content the actions gap is the only one', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Dialog(
          title: Component.text('Title'),
          actions: [Component.text('OK')],
        ),
      );
      await tester.pump();

      expect(_gapSizes(tester), [CoreSpace.space20]);
    });

    testComponents('a stated actionsGapStyle sizes the gap above the actions', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Dialog(
          title: Component.text('Title'),
          content: Component.text('Body'),
          actions: [Component.text('OK')],
          dialogStyle: CoreDialogStyle(
            actionsGapStyle: CoreGapStyle(size: CoreSpace.space32),
          ),
        ),
      );
      await tester.pump();

      expect(_gapSizes(tester), [CoreSpace.space14, CoreSpace.space32]);
    });
  });
}
