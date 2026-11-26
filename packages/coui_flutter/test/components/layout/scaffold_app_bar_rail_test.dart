import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const ValueKey<String> _back = ValueKey('back');
const ValueKey<String> _share = ValueKey('share');
const ValueKey<String> _body = ValueKey('body');

Widget _screen({
  Key? scaffoldKey,
  bool adaptive = true,
  CoreEdgeInsets insets = const CoreEdgeInsets.only(right: 84, bottom: 34),
  bool grouped = false,
  VoidCallback? onBack,
}) => Scaffold(
  key: scaffoldKey,
  adaptiveAppBarActions: adaptive,
  appBarControlInsets: insets,
  headers: [
    AppBar(
      title: const Text('Inbox'),
      centerTitle: true,
      appBarStyle: const CoreAppBarStyle(surfaceStyle: .liquidGlass),
      leading: [
        Button(
          key: _back,
          variant: .ghost,
          shape: .square,
          onPressed: onBack ?? () {},
          child: const Icon(LucideIcons.chevronLeft),
        ),
      ],
      trailing: [
        if (grouped)
          ToolbarGroup(ariaLabel: 'Actions', children: _actions())
        else
          ..._actions(),
      ],
    ),
  ],
  child: const SizedBox.expand(key: _body),
);

List<Widget> _actions() => [
  Button(
    key: _share,
    variant: .ghost,
    shape: .square,
    onPressed: () {},
    child: const Icon(LucideIcons.share),
  ),
  BarAction(
    axisBehavior: .horizontalOnly,
    child: Button(variant: .ghost, onPressed: () {}, child: const Text('Edit')),
  ),
];

void main() {
  for (final width in [466.0, 951.0]) {
    for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets(
        'Duo $width $direction puts actions in the physical right strip',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 669));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          var taps = 0;
          await pumpTestApp(
            tester,
            _screen(onBack: () => taps++),
            textDirection: direction,
          );
          expect(find.byKey(_back), findsOneWidget);
          expect(find.byKey(_share), findsOneWidget);
          final back = tester.getRect(find.byKey(_back));
          final share = tester.getRect(find.byKey(_share));
          expect(back.center.dx, closeTo(width - 48, 0.1));
          expect(share.center.dx, closeTo(back.center.dx, 0.1));
          expect(back.top, greaterThanOrEqualTo(160));
          expect(share.top, greaterThan(back.bottom));
          expect(
            tester.getRect(find.byKey(_body)).right,
            closeTo(width - 84, 0.1),
          );
          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text('Edit'),
            ),
            findsOneWidget,
          );
          expect(
            tester.getCenter(find.text('Inbox')).dx,
            closeTo((width - 84) / 2, 0.1),
          );
          await tester.tap(find.byKey(_back));
          expect(taps, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('a nested scaffold automatically uses the reserved rail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(951, 669));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var taps = 0;
    await pumpTestApp(
      tester,
      NavigationPanePadding(
        viewPadding: const EdgeInsets.only(right: 84, bottom: 34),
        child: Padding(
          padding: const EdgeInsets.only(left: 467, right: 84),
          child: Scaffold(
            headers: [
              AppBar(
                title: const Text('Details'),
                leading: [
                  Button(
                    key: _back,
                    onPressed: () => taps++,
                    child: const Icon(LucideIcons.chevronLeft),
                  ),
                ],
              ),
            ],
            child: const SizedBox.expand(key: _body),
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byKey(_body)).right, 867);
    expect(tester.getCenter(find.byKey(_back)).dx, closeTo(903, 0.1));
    await tester.tap(find.byKey(_back));
    expect(taps, 1);
  });

  testWidgets('a plain rail leaves a 44-point action target', (tester) async {
    await pumpTestApp(
      tester,
      const Scaffold(
        adaptiveAppBarActions: true,
        appBarControlInsets: CoreEdgeInsets.only(right: 84, bottom: 34),
        headers: [
          AppBar(leading: [SizedBox.square(key: _back, dimension: 48)]),
        ],
        child: SizedBox.expand(),
      ),
    );
    expect(tester.getSize(find.byKey(_back)).width, 44);
  });

  testWidgets('rail material can use the glass navigation capsule', (
    tester,
  ) async {
    var taps = 0;
    await pumpTestApp(
      tester,
      Scaffold(
        adaptiveAppBarActions: true,
        appBarControlInsets: const CoreEdgeInsets.only(right: 84, bottom: 34),
        scaffoldStyle: const CoreScaffoldStyle(
          appBarRailPopupStyle: CorePopupStyle(surfaceStyle: .liquidGlass),
        ),
        headers: [
          AppBar(
            leading: [
              Button(
                key: _back,
                variant: .ghost,
                shape: .square,
                onPressed: () => taps++,
                child: const Icon(LucideIcons.chevronLeft),
              ),
            ],
          ),
        ],
        child: const SizedBox.expand(),
      ),
    );
    final group = tester.widget<ToolbarGroup>(find.byType(ToolbarGroup));
    expect(group.popupStyle?.surfaceStyle, CoreSurfaceStyleId.liquidGlass);
    expect(tester.getSize(find.byKey(_back)), const Size(48, 48));
    await tester.tap(find.byKey(_back));
    expect(taps, 1);
  });

  testWidgets('a left strip keeps controls below the status indicators', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      _screen(insets: const CoreEdgeInsets.only(left: 84, bottom: 34)),
    );
    final back = tester.getRect(find.byKey(_back));
    final share = tester.getRect(find.byKey(_share));
    expect(back.center.dx, closeTo(48, 0.1));
    expect(back.top, greaterThanOrEqualTo(160));
    expect(share.center.dx, closeTo(48, 0.1));
    expect(share.top, greaterThan(back.bottom));
    expect(tester.getRect(find.byKey(_body)).left, 84);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing device pose retains the body element', (tester) async {
    await pumpTestApp(tester, _screen(insets: CoreEdgeInsets.zero));
    final content = tester.element(find.byKey(_body));

    await pumpTestApp(tester, _screen());
    expect(tester.element(find.byKey(_body)), same(content));

    await pumpTestApp(tester, _screen(insets: CoreEdgeInsets.zero));
    expect(tester.element(find.byKey(_body)), same(content));
  });

  testWidgets('a scaffold GlobalKey is not copied into its internal layout', (
    tester,
  ) async {
    final key = GlobalKey();
    await pumpTestApp(tester, _screen(scaffoldKey: key));
    expect(find.byKey(key), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mixed groups retain text actions exactly once in the header', (
    tester,
  ) async {
    await pumpTestApp(tester, _screen(grouped: true));
    expect(find.text('Edit'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Edit')),
      findsOneWidget,
    );
    expect(find.byKey(_share), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opt-out and ordinary phone insets keep actions horizontal', (
    tester,
  ) async {
    for (final screen in [
      _screen(adaptive: false),
      _screen(insets: CoreEdgeInsets.zero),
      _screen(insets: const CoreEdgeInsets.only(top: 59, bottom: 34)),
      _screen(insets: const CoreEdgeInsets.symmetric(horizontal: 44)),
    ]) {
      await pumpTestApp(tester, screen);
      expect(
        tester.getCenter(find.byKey(_back)).dy,
        closeTo(tester.getCenter(find.byKey(_share)).dy, 0.1),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('short viewport keeps every action reachable in the header', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(466, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpTestApp(tester, _screen());
    expect(
      tester.getCenter(find.byKey(_back)).dy,
      closeTo(tester.getCenter(find.byKey(_share)).dy, 0.1),
    );
    expect(find.text('Edit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
