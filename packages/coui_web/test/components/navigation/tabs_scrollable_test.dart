import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

void main() {
  for (final variant in CoreTabVariant.values) {
    testServer('$variant scrolls full labels without flex compression', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: Tabs(
            id: 'translations',
            tabs: [
              const CoreTabItem<Component>(
                label: 'Kontoeinstellungen und Datenschutz',
              ),
              CoreTabItem<Component>(
                label: '계정 및 개인정보 보호 설정',
                onClose: () {},
              ),
            ],
            selectedIndex: 1,
            onChanged: (_) {},
            variant: variant,
            expand: true,
            scrollable: true,
          ),
        ),
      );
      final document = (await tester.request('/')).document!;
      final root = document.querySelector('[role="tablist"]')!;
      final scroller = root.querySelector('[data-coui-tabs-scroll]')!;
      expect(root.attributes['style'], isNot(contains('overflow-x: auto')));
      expect(scroller.attributes['style'], contains('overflow-x: auto'));
      expect(scroller.querySelectorAll('[role="tab"]').length, 2);
      expect(root.attributes['style'], contains('max-width: 100%'));
      final tabs = document.querySelectorAll('[role="tab"]');
      expect(tabs.first.text, contains('Kontoeinstellungen und Datenschutz'));
      expect(tabs.last.text, contains('계정 및 개인정보 보호 설정'));
      expect(tabs.first.attributes['style'], contains('flex-shrink: 0'));
      expect(tabs.last.parent!.attributes['style'], contains('flex-shrink: 0'));
      expect(tabs.first.attributes['class'], isNot(contains('flex-1')));
      expect(tabs.map((tab) => tab.attributes['tabindex']), ['-1', '0']);
      expect(tabs.last.attributes['aria-selected'], 'true');
      expect(
        tabs.first.children.first.attributes['style'],
        contains('min-height:'),
      );
    });
  }

  test('scrollable is opt-in and copyWith preserves it', () {
    final tabs = Tabs.labels(labels: const ['Account'], selectedIndex: 0);
    expect(tabs.scrollable, isFalse);
    expect(tabs.copyWith(scrollable: true).primary.scrollable, isTrue);
  });
}
