import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show ServerTester, testServer;

/// The Web twin of the Flutter `app_bar_actions_axis_test`: a bar whose
/// actions stand in a column beside the content keeps only the actions
/// that may not leave its row, and a column handed the same lists draws
/// the rest — read back off the server markup.
Component _host(Component child, {CoreSurfaceStyleId? surfaceStyle}) => CoUIWeb(
  theme: .coui,
  child: surfaceStyle == null
      ? child
      : SurfaceStyleScope(surfaceStyle: surfaceStyle, child: child),
);

Component _icon(IconName icon, String name) => Button(
  variant: .ghost,
  shape: .square,
  onPressed: () {},
  attributes: {'aria-label': name},
  child: Icon(icon),
);

Component _edit() => BarAction(
  axisBehavior: .horizontalOnly,
  child: Button(
    variant: .ghost,
    onPressed: () {},
    attributes: const {'aria-label': 'Edit'},
    child: const Text('Edit'),
  ),
);

List<Component> _leading() => [_icon(LucideIcons.chevronLeft, 'Back')];

List<Component> _trailing() => [_icon(LucideIcons.share, 'Share'), _edit()];

AppBar _bar({
  CoreAxis actionsAxis = CoreAppBarContract.defaultActionsAxis,
  List<Component>? leading,
  List<Component>? trailing,
}) => AppBar(
  id: 'bar',
  title: const Text('Inbox'),
  actionsAxis: actionsAxis,
  leading: leading ?? _leading(),
  trailing: trailing ?? _trailing(),
);

/// The names of the buttons under [selector], in document order.
Future<List<String?>> _buttons(
  ServerTester tester,
  Component child, {
  required String selector,
  CoreSurfaceStyleId? surfaceStyle,
}) async {
  tester.pumpComponent(_host(child, surfaceStyle: surfaceStyle));
  final document = (await tester.request('/')).document!;
  return [
    for (final button in document.querySelectorAll('$selector button'))
      button.attributes['aria-label'],
  ];
}

void main() {
  testServer('a bar draws every action in its own row by default', (
    tester,
  ) async {
    expect(
      await _buttons(tester, _bar(), selector: '#bar'),
      ['Back', 'Share', 'Edit'],
    );
  });

  for (final surfaceStyle in [null, CoreSurfaceStyleId.liquidGlass]) {
    final name = surfaceStyle?.name ?? 'opaque';

    testServer('with its actions in a column the bar keeps the '
        'horizontal-only action alone ($name)', (tester) async {
      tester.pumpComponent(
        _host(_bar(actionsAxis: .vertical), surfaceStyle: surfaceStyle),
      );
      final document = (await tester.request('/')).document!;
      final bar = document.querySelector('#bar')!;

      expect(
        [
          for (final button in bar.querySelectorAll('button'))
            button.attributes['aria-label'],
        ],
        ['Edit'],
      );
      // The moved back button leaves no empty cluster behind it.
      expect(bar.querySelector('[data-coui-app-bar-leading]'), isNull);
      expect(bar.querySelector('[data-coui-app-bar-trailing]'), isNotNull);
      expect(bar.text, contains('Inbox'));
    });

    testServer('the column draws the rest: each action exactly once '
        '($name)', (tester) async {
      final leading = _leading();
      final trailing = _trailing();
      tester.pumpComponent(
        _host(
          div([
            _bar(
              actionsAxis: .vertical,
              leading: leading,
              trailing: trailing,
            ),
            div(id: 'strip', [
              ToolbarGroup(
                ariaLabel: 'Page actions',
                direction: .vertical,
                children: [...leading, ...trailing],
              ),
            ]),
          ]),
          surfaceStyle: surfaceStyle,
        ),
      );
      final document = (await tester.request('/')).document!;
      List<String?> names(String selector) => [
        for (final button in document.querySelectorAll('$selector button'))
          button.attributes['aria-label'],
      ];

      expect(names('#bar'), ['Edit']);
      expect(names('#strip'), ['Back', 'Share']);
      expect(document.querySelectorAll('button'), hasLength(3));
    });
  }

  testServer('a bar whose actions all moved keeps neither cluster', (
    tester,
  ) async {
    tester.pumpComponent(
      _host(
        _bar(
          actionsAxis: .vertical,
          trailing: [_icon(LucideIcons.share, 'Share')],
        ),
      ),
    );
    final document = (await tester.request('/')).document!;
    final bar = document.querySelector('#bar')!;

    expect(bar.querySelector('button'), isNull);
    expect(bar.querySelector('[data-coui-app-bar-leading]'), isNull);
    expect(bar.querySelector('[data-coui-app-bar-trailing]'), isNull);
  });

  testServer('a kept group keeps its own capsule under glass', (tester) async {
    tester.pumpComponent(
      _host(
        _bar(
          actionsAxis: .vertical,
          trailing: [
            _icon(LucideIcons.share, 'Share'),
            BarAction(
              axisBehavior: .horizontalOnly,
              child: ToolbarGroup(ariaLabel: 'Editing', children: [_edit()]),
            ),
          ],
        ),
        surfaceStyle: .liquidGlass,
      ),
    );
    final document = (await tester.request('/')).document!;
    final bar = document.querySelector('#bar')!;

    // The marked group is one capsule of its own — not a capsule the bar
    // wrapped around a capsule.
    final groups = bar.querySelectorAll('[role="group"]');
    expect(groups, hasLength(1));
    expect(groups.single.attributes['aria-label'], 'Editing');
    expect(bar.querySelector('[data-coui-app-bar-actions]'), isNull);
    expect(
      [
        for (final button in bar.querySelectorAll('button'))
          button.attributes['aria-label'],
      ],
      ['Edit'],
    );
  });

  test('a copy keeps where the actions stand', () {
    final bar = _bar(actionsAxis: .vertical).copyWith(classes: 'w-full');

    expect(bar.actionsAxis, CoreAxis.vertical);
    expect(
      _bar().copyWith(actionsAxis: .vertical).actionsAxis,
      CoreAxis.vertical,
    );
  });
}
