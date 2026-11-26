// Web: TextField, TextArea and Toggle log, once and only where asserts are
// on, that `xs` is retiring — the twin of
// `coui_flutter/test/components/form/retiring_size_notice_test.dart`.
//
// Driven through the real components, because the resolvers are what call
// `noticeRetiringSize`; a Core-only test would pass with the call missing.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  late List<String> said;

  setUp(() {
    said = [];
    debugRetiringSizeNoticeSink = (message) => said = [...said, message];
    debugResetRetiringSizeNotices();
  });

  tearDown(() {
    debugRetiringSizeNoticeSink = null;
    debugResetRetiringSizeNotices();
  });

  final components = <String, Component Function(CoreComponentSize)>{
    'TextField': (size) => TextField(size: size),
    'TextArea': (size) => TextArea(size: size),
    'Toggle': (size) => Toggle(onChanged: (_) {}, size: size),
  };

  for (final MapEntry(key: name, value: build) in components.entries) {
    group(name, () {
      testComponents('xs logs the notice once, naming sm and the release', (
        tester,
      ) async {
        pumpWithTheme(tester, build(CoreComponentSize.xs));
        // A second build of the same component says nothing new.
        pumpWithTheme(
          tester,
          Component.fragment([
            build(CoreComponentSize.xs),
            build(CoreComponentSize.xs),
          ]),
        );

        expect(said, hasLength(1));
        expect(said.single, contains(name));
        expect(said.single, contains('`xs`'));
        expect(said.single, contains('`sm`'));
        expect(said.single, contains('coui_core 0.153 at the earliest'));
        // Toggle already draws `sm`; the fields still draw their own `xs`.
        // Each must be told what actually changes for it.
        expect(
          said.single,
          name == 'Toggle'
              ? contains('already renders as `sm`')
              : isNot(contains('already renders')),
        );
      });

      testComponents('a size that is staying says nothing', (tester) async {
        for (final size in CoreComponentSize.values) {
          if (size == CoreComponentSize.xs) continue;
          pumpWithTheme(tester, build(size));
        }

        expect(said, isEmpty);
      });
    });
  }
}
