// The scope row's selected chip, read from the SSR markup. The Flutter twin
// asserts the same emphasis against the rendered widgets
// (`coui_flutter/test/components/control/command_test.dart`).

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

const List<CoreCommandGroup<Component>> _groups = [
  CoreCommandGroup(
    scope: 'actions',
    items: [CoreCommandItem(value: 'a', label: 'Alpha')],
  ),
];
const List<CoreCommandScope> _scopes = [
  CoreCommandScope(value: 'actions', label: 'Actions'),
];

void main() {
  testServer('the selected scope chip is the primary-container tint, not the '
      'solid primary fill', (tester) async {
    tester.pumpComponent(
      CoUIWeb(
        theme: .coui,
        child: Command(groups: _groups, scopes: _scopes, onSelect: (_) {}),
      ),
    );
    final body = (await tester.request('/')).document!.body!;
    final chips = body.querySelectorAll('[aria-pressed]');
    // The automatic All chip and the one scope.
    expect(chips.length, 2);

    // The chip's root carries the press state; its `.co-chip-body` child
    // carries the chrome.
    final selected = chips
        .singleWhere((c) => c.attributes['aria-pressed'] == 'true')
        .querySelector('.co-chip-body')!;
    expect(selected.text, contains('All'));
    final classes = selected.attributes['class'] ?? '';
    expect(classes, contains('bg-primary-container'));
    expect(classes, contains('text-on-primary-container'));
    // The solid fill and its on-ink are the loud register — not asked for.
    expect(RegExp(r'(^|\s)bg-primary(\s|$)').hasMatch(classes), isFalse);
    expect(RegExp(r'(^|\s)text-on-primary(\s|$)').hasMatch(classes), isFalse);

    final resting = chips
        .singleWhere((c) => c.attributes['aria-pressed'] == 'false')
        .querySelector('.co-chip-body')!;
    expect(resting.text, contains('Actions'));
    expect(resting.attributes['class'] ?? '', isNot(contains('primary')));
  });
}
