// TextField, TextArea and Toggle log, once and only where asserts are on,
// that `xs` is retiring — and keep rendering exactly as before.
//
// The resolvers are what call `noticeRetiringSize`, so this drives the real
// widgets rather than the Core function: a resolver that forgot the call
// would pass a Core-only test.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

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

  final components = <String, Widget Function(CoreComponentSize)>{
    'TextField': (size) =>
        TextField(controller: TextEditingController(), size: size),
    'TextArea': (size) =>
        TextArea(controller: TextEditingController(), size: size),
    'Toggle': (size) => Toggle(onChanged: (_) {}, value: false, size: size),
  };

  for (final MapEntry(key: name, value: build) in components.entries) {
    group(name, () {
      testWidgets('xs logs the notice once, naming sm and the release', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(build(CoreComponentSize.xs)));
        await tester.pump();
        // A second build of the same field says nothing new.
        await tester.pumpWidget(
          _buildApp(
            material.Column(
              children: [
                build(CoreComponentSize.xs),
                build(CoreComponentSize.xs),
              ],
            ),
          ),
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
        expect(tester.takeException(), isNull);
      });

      testWidgets('a size that is staying says nothing', (tester) async {
        for (final size in CoreComponentSize.values) {
          if (size == CoreComponentSize.xs) continue;
          await tester.pumpWidget(_buildApp(build(size)));
        }

        expect(said, isEmpty);
      });
    });
  }
}
