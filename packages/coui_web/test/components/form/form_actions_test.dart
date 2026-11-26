// Form's `showActions` / `primaryAction` / `secondaryAction` slots
// (Web twin of `packages/coui_flutter/test/components/form/form_test.dart`'s
// "Form actions row" group) — the default-rendered Submit/Cancel buttons
// never wire to `onSubmit` (2026-09-11 결정: 완전 수동), and the default
// rendering only appears when `showActions` is true.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('Form actions row', () {
    testComponents('showActions defaults to false — no actions render', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Form(children: const [Text('Form content')]),
      );

      expect(find.text('Submit'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testComponents(
      'showActions renders the default Submit / Cancel buttons',
      (tester) async {
        pumpWithTheme(
          tester,
          Form(showActions: true, children: const [Text('Form content')]),
        );

        expect(find.text('Submit'), findsOneComponent);
        expect(find.text('Cancel'), findsOneComponent);
      },
    );

    testComponents(
      'a custom primaryAction replaces the default Submit button outright',
      (tester) async {
        pumpWithTheme(
          tester,
          Form(
            showActions: true,
            primaryAction: const Text('Save changes'),
            children: const [Text('Form content')],
          ),
        );

        expect(find.text('Save changes'), findsOneComponent);
        expect(find.text('Submit'), findsNothing);
        // secondaryAction still renders its own default.
        expect(find.text('Cancel'), findsOneComponent);
      },
    );

    testComponents(
      'showSecondaryAction: false hides the Cancel button, Submit stays',
      (tester) async {
        pumpWithTheme(
          tester,
          Form(
            showActions: true,
            showSecondaryAction: false,
            children: const [Text('Form content')],
          ),
        );

        expect(find.text('Submit'), findsOneComponent);
        expect(find.text('Cancel'), findsNothing);
      },
    );

    testComponents(
      'pressing the default primaryAction does NOT call onSubmit — the '
      'two are fully independent by design',
      (tester) async {
        var submitCount = 0;
        pumpWithTheme(
          tester,
          Form(
            showActions: true,
            onSubmit: () => submitCount++,
            children: const [Text('Form content')],
          ),
        );

        await tester.click(
          find
              .ancestor(of: find.text('Submit'), matching: find.tag('button'))
              .first,
        );

        expect(submitCount, 0);
      },
    );
  });
}
