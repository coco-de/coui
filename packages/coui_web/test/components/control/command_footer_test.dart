// The palette footer's key hints, read from the SSR markup. The Flutter twin
// asserts the same copy against the rendered widget
// (`coui_flutter/test/components/control/command_test.dart`).

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

const List<CoreCommandGroup<Component>> _groups = [
  CoreCommandGroup(
    items: [CoreCommandItem(value: 'a', label: 'Alpha')],
  ),
];

void main() {
  testServer('the arrow pair is labelled once, for moving either way', (
    tester,
  ) async {
    tester.pumpComponent(
      CoUIWeb(
        theme: .coui,
        child: Command(
          groups: _groups,
          presentation: .dialog,
          onSelect: (_) {},
        ),
      ),
    );
    final text = (await tester.request('/')).document!.body!.text;

    expect(RegExp('Navigate').allMatches(text).length, 1);
    expect(text, isNot(contains('Move Up')));
    expect(text, isNot(contains('Move Down')));
  });
}
