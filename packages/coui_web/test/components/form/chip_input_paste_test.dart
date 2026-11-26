// Guards the Web ChipInput's paste wiring.
//
// The component bound only `keydown` on its entry input, so pasted text
// landed in the buffer and waited for an Enter the user still had to
// press — there was no paste listener anywhere in `form/chip_input/`.
//
// What this file can and cannot reach:
//
//   Firing the handler needs a real `web.ClipboardEvent` carrying
//   `clipboardData`. These tests run on the VM, where `package:web` is a
//   stub, so the dispatch itself cannot be driven here. The split-and-cap
//   behaviour is pinned in `coui_core`'s `chip_input_paste_test.dart`,
//   which both platforms call into, and the end-to-end path is pinned on
//   the Flutter twin.
//
//   What is reachable is whether the listener is *attached*, and only
//   when a splitter was supplied — the two facts the bug and its
//   guardrail are about. An always-attached handler would cancel the
//   browser's default paste for every caller, including the ones who
//   never asked for splitting.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kPasteEvent = 'paste';

/// Every event name bound anywhere in the rendered tree.
///
/// Scanned rather than read off the `<input>` because `TextField` gives
/// the input element a curated handler map and routes caller-supplied
/// handlers to its root, where they still see the input's events by
/// bubbling — the same path ChipInput's existing Enter handler takes.
Set<String> _boundEvents() {
  final names = <String>{};
  for (final tag in const ['div', 'input']) {
    for (final element in find.tag(tag).evaluate()) {
      final dom = element.component as DomComponent;
      names.addAll((dom.events ?? const {}).keys);
    }
  }

  return names;
}

void main() {
  group('ChipInput paste wiring', () {
    testComponents('no splitter binds no paste listener', (tester) async {
      pumpWithTheme(tester, ChipInput(chips: const ['x'], onChanged: (_) {}));

      expect(
        _boundEvents(),
        isNot(contains(_kPasteEvent)),
        reason:
            'the handler cancels the default paste, so attaching it '
            'unconditionally would break ordinary pasting',
      );
    });

    testComponents('a splitter binds the paste listener', (tester) async {
      pumpWithTheme(
        tester,
        ChipInput(
          chips: const [],
          onChanged: (_) {},
          pasteSplitter: CoreChipInputContract.splitOn(','),
        ),
      );

      expect(_boundEvents(), contains(_kPasteEvent));
    });

    testComponents('the splitter survives copyWith', (tester) async {
      final input = ChipInput(
        chips: const [],
        onChanged: (_) {},
        pasteSplitter: CoreChipInputContract.splitOn(','),
      ).copyWith(chips: const ['x']);

      pumpWithTheme(tester, input);

      expect(input.chips, equals(['x']));
      expect(input.pasteSplitter, isNotNull);
      expect(
        input.pasteSplitter!('a,b'),
        equals(['a', 'b']),
        reason: 'the copy must carry the caller\'s splitter, not a stub',
      );
      expect(_boundEvents(), contains(_kPasteEvent));
    });
  });
}
