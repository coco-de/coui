import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show ServerTester, testServer;

/// The Web twin of the Flutter `toolbar_group_direction_test`: the group's
/// controls run along a row or down a column, read back off the server
/// markup. What the browser lays the column out as is the Chrome probe's.
Component _host(Component child, {CoreSurfaceStyleId? surfaceStyle}) => CoUIWeb(
  theme: .coui,
  child: surfaceStyle == null
      ? child
      : SurfaceStyleScope(surfaceStyle: surfaceStyle, child: child),
);

Component _action(IconName icon, String name) => Button(
  variant: .ghost,
  shape: .square,
  onPressed: () {},
  attributes: {'aria-label': name},
  child: Icon(icon),
);

ToolbarGroup _group({
  CoreAxis direction = CoreToolbarGroupContract.defaultDirection,
  CorePopupStyle? popupStyle,
  List<Component>? children,
}) => ToolbarGroup(
  ariaLabel: 'Page actions',
  direction: direction,
  popupStyle: popupStyle,
  children:
      children ??
      [
        _action(LucideIcons.chevronLeft, 'Back'),
        _action(LucideIcons.share, 'Share'),
      ],
);

/// `rem` length of [px], as the surface writes a seat.
String _rem(double px) => '${px / kRemDivisor}rem';

void main() {
  for (final direction in CoreAxis.values) {
    testServer('the glass seat follows the $direction', (tester) async {
      tester.pumpComponent(
        _host(_group(direction: direction), surfaceStyle: .liquidGlass),
      );
      final document = (await tester.request('/')).document!;
      final group = document.querySelector('[role="group"]')!;
      final seat = _rem(
        CoreToolbarGroupContract.glassActionMinSizeFor(direction),
      );

      expect(group.attributes['aria-label'], 'Page actions');
      expect(
        group.classes,
        contains(direction == .vertical ? 'flex-col' : 'flex-row'),
      );
      expect(
        group.classes,
        isNot(contains(direction == .vertical ? 'flex-row' : 'flex-col')),
      );
      // One capsule carries the material; each control sits in a seat of
      // the direction's size.
      expect(group.classes, contains('coui-material-liquidGlass'));
      final seats = group.children;
      expect(seats, hasLength(2));
      for (final child in seats) {
        final style = child.attributes['style']!;
        expect(style, contains('min-width: $seat'));
        expect(style, contains('min-height: $seat'));
        // The button fills its seat.
        final button = child.querySelector('[aria-label]')!;
        expect(button.attributes['style'], contains('height: $seat'));
        expect(button.attributes['style'], contains('min-width: $seat'));
      }
    });
  }

  test('a column seat is 48 and a row seat 44', () {
    // Spelled as lengths, so the markup above cannot agree with a wrong
    // constant.
    expect(
      _rem(CoreToolbarGroupContract.glassActionMinSizeFor(.vertical)),
      '3.0rem',
    );
    expect(
      _rem(CoreToolbarGroupContract.glassActionMinSizeFor(.horizontal)),
      '2.75rem',
    );
  });

  group('the glyph', () {
    /// The size each glyph in the group is drawn at, as the icon writes it.
    Future<List<String>> glyphs(
      ServerTester tester,
      Component group, {
      CoreSurfaceStyleId? surfaceStyle,
    }) async {
      tester.pumpComponent(_host(group, surfaceStyle: surfaceStyle));
      final document = (await tester.request('/')).document!;
      return [
        for (final icon in document.querySelectorAll('[data-icon]'))
          RegExp(
            'width: ([0-9.]+rem)',
          ).firstMatch(icon.attributes['style']!)!.group(1)!,
      ];
    }

    testServer("a glass column draws the glass rail's 24", (tester) async {
      final sizes = await glyphs(
        tester,
        _group(direction: .vertical),
        surfaceStyle: .liquidGlass,
      );

      expect(sizes, [_rem(24), _rem(24)]);
      expect(
        _rem(CoreNavigationBarStyle.defaultIconStyle.size!),
        _rem(24),
      );
    });

    testServer('a button with a label beside its glyph takes it too', (
      tester,
    ) async {
      final sizes = await glyphs(
        tester,
        _group(
          direction: .vertical,
          children: [
            Button(
              variant: .ghost,
              onPressed: () {},
              leading: const Icon(LucideIcons.share),
              child: const Text('Share'),
            ),
          ],
        ),
        surfaceStyle: .liquidGlass,
      );

      expect(sizes, [_rem(24)]);
    });

    final own = _rem(
      CoreButtonStyle.iconSizeFor(
        size: .md,
        iconShaped: true,
        iconShapeOverride: null,
        leadingOverride: null,
        trailingOverride: null,
      ),
    );

    testServer("a glass row keeps the button's own", (tester) async {
      final sizes = await glyphs(tester, _group(), surfaceStyle: .liquidGlass);

      expect(own, isNot(_rem(24)));
      expect(sizes, [own, own]);
    });

    testServer("an opaque column keeps the button's own", (tester) async {
      final sizes = await glyphs(tester, _group(direction: .vertical));

      expect(sizes, [own, own]);
    });
  });

  group('the controls a column draws', () {
    Component edit() => BarAction(
      axisBehavior: .horizontalOnly,
      child: Button(
        variant: .ghost,
        onPressed: () {},
        attributes: const {'aria-label': 'Edit'},
        child: const Text('Edit'),
      ),
    );

    List<Component> actions() => [
      _action(LucideIcons.chevronLeft, 'Back'),
      edit(),
      ToolbarGroup(
        ariaLabel: 'Share and more',
        children: [
          _action(LucideIcons.share, 'Share'),
          _action(LucideIcons.ellipsis, 'More'),
        ],
      ),
    ];

    for (final surfaceStyle in [null, CoreSurfaceStyleId.liquidGlass]) {
      testServer(
        'leave out a horizontal-only action and take a group in '
        '(${surfaceStyle?.name ?? 'opaque'})',
        (tester) async {
          tester.pumpComponent(
            _host(
              _group(direction: .vertical, children: actions()),
              surfaceStyle: surfaceStyle,
            ),
          );
          final document = (await tester.request('/')).document!;

          // One capsule: the group among the children gave it its controls.
          final groups = document.querySelectorAll('[role="group"]');
          expect(groups, hasLength(1));
          expect(groups.single.attributes['aria-label'], 'Page actions');
          expect(
            [
              for (final button in document.querySelectorAll('button'))
                button.attributes['aria-label'],
            ],
            ['Back', 'Share', 'More'],
          );
          // Each is a child of the column itself — a seat under glass.
          expect(groups.single.children, hasLength(3));
        },
      );
    }

    testServer('a row draws every one, the group in its own capsule', (
      tester,
    ) async {
      tester.pumpComponent(_host(_group(children: actions())));
      final document = (await tester.request('/')).document!;

      expect(document.querySelectorAll('[role="group"]'), hasLength(2));
      expect(
        [
          for (final button in document.querySelectorAll('button'))
            button.attributes['aria-label'],
        ],
        ['Back', 'Edit', 'Share', 'More'],
      );
    });

    testServer('a column of horizontal-only actions draws nothing', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          _group(direction: .vertical, children: [edit()]),
          surfaceStyle: .liquidGlass,
        ),
      );
      final document = (await tester.request('/')).document!;

      expect(document.querySelector('[role="group"]'), isNull);
      expect(document.querySelector('button'), isNull);
    });

    testServer('a marker adds no element of its own', (tester) async {
      tester.pumpComponent(_host(div(id: 'host', [edit()])));
      final document = (await tester.request('/')).document!;
      final host = document.querySelector('#host')!;

      expect(host.children, hasLength(1));
      expect(host.children.single.localName, 'button');
    });
  });

  testServer('a material stated on the group alone takes the column seats', (
    tester,
  ) async {
    tester.pumpComponent(
      _host(
        _group(
          direction: .vertical,
          popupStyle: const CorePopupStyle(surfaceStyle: .liquidGlass),
        ),
      ),
    );
    final document = (await tester.request('/')).document!;
    final group = document.querySelector('[role="group"]')!;

    expect(group.classes, contains('flex-col'));
    expect(
      group.children.first.attributes['style'],
      contains('min-width: ${_rem(48)}'),
    );
  });

  testServer('the opaque column keeps its padding and its controls’ size', (
    tester,
  ) async {
    tester.pumpComponent(_host(_group(direction: .vertical)));
    final document = (await tester.request('/')).document!;
    final group = document.querySelector('[role="group"]')!;

    expect(group.classes, contains('flex-col'));
    expect(group.classes, isNot(contains('coui-material-liquidGlass')));
    // No seats: the controls are the capsule's own children.
    expect(group.children, hasLength(2));
    for (final child in group.children) {
      expect(child.attributes['aria-label'], isNotNull);
    }
    // The capsule's own padding, measured from its outer edge (the panel
    // takes its border out of it).
    final inset = spaceCss(
      CoreToolbarGroupContract.defaultPopupStyle.padding!.top,
    );
    expect(group.attributes['style'], contains('padding: calc($inset - '));
  });

  testServer('an empty column draws nothing', (tester) async {
    tester.pumpComponent(
      _host(
        _group(direction: .vertical, children: const []),
        surfaceStyle: .liquidGlass,
      ),
    );
    final document = (await tester.request('/')).document!;

    expect(document.querySelector('[role="group"]'), isNull);
  });
}
