// #3777 — dialog shadow existed only on Web, hardcoded to `var(--shadow-lg)`
// (the popover/tooltip rung) with zero Core declaration behind it. This
// reads back that the panel's `box-shadow` now resolves through
// `CoreDialogStyle.panelBoxShadow` / `defaultPanelBoxShadow` and lands on
// the canonical Modal/Dialog rung (`shadow-xl`), not the value that used
// to be there by accident.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

ResolvedDialog? _seen;

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
  return _seen!;
}

void main() {
  group('panel box-shadow resolves through CoreDialogStyle (#3777)', () {
    testComponents('unconfigured panel emits the shadow-xl rung', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      final boxShadow = resolved.panel.inlineStyles!.properties['box-shadow'];

      expect(boxShadow, isNotNull);
      expect(boxShadow, contains('var(--shadow-xl)'));
      // The regression this test exists to catch: the panel used to be
      // hardcoded to the popover/tooltip rung with no Core field behind
      // it at all.
      expect(boxShadow, isNot(contains('var(--shadow-lg)')));
    });

    testComponents('a per-instance override reaches the panel', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        dialogStyle: const CoreDialogStyle(panelBoxShadow: CoreShadow.xl2),
      );
      final boxShadow = resolved.panel.inlineStyles!.properties['box-shadow'];

      expect(boxShadow, contains('var(--shadow-2xl)'));
    });

    testComponents('a raw (non-scale) override falls back to a literal', (
      tester,
    ) async {
      const rawLayer = (
        offsetX: 0.0,
        offsetY: 3.0,
        blurRadius: 6.0,
        spreadRadius: -1.0,
        opacity: 0.2,
        inset: false,
      );
      final resolved = await _resolve(
        tester,
        dialogStyle: const CoreDialogStyle(panelBoxShadow: [rawLayer]),
      );
      final boxShadow = resolved.panel.inlineStyles!.properties['box-shadow'];

      // Off-scale stacks are not one of the named rungs, so they emit a
      // literal rather than a `var(--shadow-*)` reference (same
      // class-vs-inline rule every other token category follows).
      expect(boxShadow, isNotNull);
      expect(boxShadow, isNot(contains('var(--shadow-')));
    });
  });
}
