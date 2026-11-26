// Pins ChipInput's paste behaviour on Flutter.
//
// The `pasteSplitter == null` case is the one that matters most, and it
// is the one the obvious implementation gets wrong.
//
// `Action.overridable` does not fall through. Once `EditableText` finds
// an ancestor override for `PasteTextIntent` that is enabled, that
// override *replaces* the built-in `_PasteSelectionAction` — it is not
// consulted first and then deferred to. So the natural shape, "always
// install the override, return early when there is no splitter", does not
// leave ordinary pasting intact: it inserts nothing, and paste silently
// stops working for every caller who never asked for splitting.
//
// The fix is to build the `Actions` wrapper only when a splitter exists.
// `default paste is left alone` fails against the early-return shape,
// which is why it is written against the widget tree rather than against
// a clipboard round-trip: it asserts the override is *absent*, which is
// the actual invariant.

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

/// Whether ChipInput installed its own `PasteTextIntent` override.
///
/// Matched on `CallbackAction<PasteTextIntent>` specifically:
/// `EditableText` registers the same intent internally with its own
/// private action, so a `containsKey` check finds a paste override in
/// every build and can never fail.
bool _hasPasteOverride(WidgetTester tester) => tester
    .widgetList<Actions>(find.byType(Actions))
    .any((a) => a.actions[PasteTextIntent] is CallbackAction<PasteTextIntent>);

/// Drives the paste intent the way a keyboard shortcut would.
Future<void> _invokePaste(WidgetTester tester) async {
  final context = tester.element(find.byType(EditableText));
  Actions.invoke(
    context,
    const PasteTextIntent(SelectionChangedCause.keyboard),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Stands in for the system clipboard.
  void primeClipboard(WidgetTester tester, String? text) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.getData') {
          return text == null ? null : <String, dynamic>{'text': text};
        }

        return null;
      },
    );
  }

  group('ChipInput paste', () {
    testWidgets('default paste is left alone when no splitter is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(ChipInput(chips: const ['x'], onChanged: (_) {})),
      );

      expect(
        _hasPasteOverride(tester),
        isFalse,
        reason:
            'an installed override replaces the default outright, so '
            'installing one here would break ordinary pasting',
      );
    });

    testWidgets('a splitter installs the override', (tester) async {
      await tester.pumpWidget(
        _app(
          ChipInput(
            chips: const [],
            onChanged: (_) {},
            pasteSplitter: CoreChipInputContract.splitOn(','),
          ),
        ),
      );

      expect(_hasPasteOverride(tester), isTrue);
    });

    testWidgets('a separated paste becomes several chips', (tester) async {
      List<String>? received;
      primeClipboard(tester, 'a,b,c');

      await tester.pumpWidget(
        _app(
          ChipInput(
            chips: const [],
            onChanged: (next) => received = next,
            pasteSplitter: CoreChipInputContract.splitOn(','),
          ),
        ),
      );

      await _invokePaste(tester);

      expect(received, equals(['a', 'b', 'c']));
    });

    testWidgets('maxChips caps a pasted batch', (tester) async {
      List<String>? received;
      primeClipboard(tester, 'a,b,c');

      await tester.pumpWidget(
        _app(
          ChipInput(
            chips: const ['x'],
            maxChips: 3,
            onChanged: (next) => received = next,
            pasteSplitter: CoreChipInputContract.splitOn(','),
          ),
        ),
      );

      await _invokePaste(tester);

      expect(received, equals(['x', 'a', 'b']));
    });

    // A field already at `maxChips` renders no entry input at all, so
    // there is nothing to paste into and no case to write. The cap is
    // covered above, where the field is still present.

    testWidgets('a paste of only separators reports nothing', (tester) async {
      var notified = false;
      primeClipboard(tester, ' , , ');

      await tester.pumpWidget(
        _app(
          ChipInput(
            chips: const ['x'],
            onChanged: (_) => notified = true,
            pasteSplitter: CoreChipInputContract.splitOn(','),
          ),
        ),
      );

      await _invokePaste(tester);

      expect(notified, isFalse);
    });

    testWidgets('an empty clipboard reports nothing', (tester) async {
      var notified = false;
      primeClipboard(tester, null);

      await tester.pumpWidget(
        _app(
          ChipInput(
            chips: const [],
            onChanged: (_) => notified = true,
            pasteSplitter: CoreChipInputContract.splitOn(','),
          ),
        ),
      );

      await _invokePaste(tester);

      expect(notified, isFalse);
    });
  });
}
