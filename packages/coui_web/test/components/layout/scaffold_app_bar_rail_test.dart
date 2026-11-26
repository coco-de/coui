import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

Component _screen({
  bool adaptive = true,
  CoreEdgeInsets? insets,
  bool grouped = false,
}) => CoUIWeb(
  theme: .coui,
  child: Scaffold(
    adaptiveAppBarActions: adaptive,
    appBarControlInsets: insets,
    headers: [
      AppBar(
        id: 'bar',
        title: const Text('Inbox'),
        appBarStyle: const CoreAppBarStyle(surfaceStyle: .liquidGlass),
        leading: [_icon('Back', LucideIcons.chevronLeft)],
        trailing: [
          if (grouped)
            ToolbarGroup(ariaLabel: 'Actions', children: _actions())
          else
            ..._actions(),
        ],
      ),
    ],
    child: const Text('Body'),
  ),
);
Component _icon(String name, IconName icon) => Button(
  variant: .ghost,
  shape: .square,
  attributes: {'aria-label': name},
  onPressed: () {},
  child: Icon(icon),
);
List<Component> _actions() => [
  _icon('Share', LucideIcons.share),
  BarAction(
    axisBehavior: .horizontalOnly,
    child: Button(variant: .ghost, onPressed: () {}, child: const Text('Edit')),
  ),
];

void main() {
  for (final grouped in [false, true]) {
    testServer('right-strip actions render once; mixed group=$grouped', (
      tester,
    ) async {
      tester.pumpComponent(
        _screen(
          insets: const CoreEdgeInsets.only(right: 84, bottom: 34),
          grouped: grouped,
        ),
      );
      final doc = (await tester.request('/')).document!;
      final rail = doc.querySelector('[data-coui-app-bar-rail]')!;
      expect(
        rail
            .querySelectorAll('button')
            .map((e) => e.attributes['aria-label'])
            .toList(),
        ['Back', 'Share'],
      );
      expect(doc.querySelector('#bar')!.text, contains('Edit'));
      expect(doc.querySelector('#bar')!.querySelectorAll('button').length, 1);
      expect(doc.querySelectorAll('button').length, 3);
      expect(rail.attributes['style'], matches(r'right: 24(?:\.0)?px'));
      expect(rail.attributes['style'], matches(r'top: 160(?:\.0)?px'));
    });
  }
  testServer('left-strip actions use the physical left edge', (tester) async {
    tester.pumpComponent(
      _screen(insets: const CoreEdgeInsets.only(left: 84, bottom: 34)),
    );
    final doc = (await tester.request('/')).document!;
    final rail = doc.querySelector('[data-coui-app-bar-rail]')!;
    expect(rail.attributes['style'], matches(r'left: 24(?:\.0)?px'));
    expect(rail.attributes['style'], matches(r'top: 160(?:\.0)?px'));
    expect(rail.querySelectorAll('button').length, 2);
    expect(doc.querySelector('#bar')!.querySelectorAll('button').length, 1);
  });

  testServer('SSR without measured insets keeps controls in the header', (
    tester,
  ) async {
    tester.pumpComponent(_screen());
    final doc = (await tester.request('/')).document!;
    expect(doc.querySelector('[data-coui-app-bar-rail]'), isNull);
    expect(doc.querySelector('#bar')!.querySelectorAll('button').length, 3);
  });
  testServer('existing scaffold opt-out preserves header actions', (
    tester,
  ) async {
    tester.pumpComponent(
      _screen(adaptive: false, insets: const CoreEdgeInsets.only(right: 84)),
    );
    final doc = (await tester.request('/')).document!;
    expect(doc.querySelector('[data-coui-app-bar-rail]'), isNull);
    expect(doc.querySelector('#bar')!.querySelectorAll('button').length, 3);
  });
}
