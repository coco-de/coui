import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show ServerTester, testServer;

/// A navigation bar that floats is the whole footer: the Flutter twin lays
/// that bar over the body with no section around it
/// (`floatingFooter && footers.single is NavigationBar`), so the section the
/// Web twin keeps for it paints no face. With a face it is an opaque band
/// across the bottom of the body — the floating glass capsule then sits on
/// the band rather than over the content, and a bar drawn compact shrinks
/// away from a strip that stays.
void main() {
  Component host(Component child) => CoUIWeb(theme: .coui, child: child);

  const bar = NavigationBar(
    id: 'nav',
    items: [
      CoreNavigationBarItem.destination(label: 'Home'),
      CoreNavigationBarItem.destination(label: 'Search'),
    ],
  );

  /// The classes and inline style of the section holding the footer whose
  /// first element carries [id].
  Future<({List<String> classes, String style})> section(
    ServerTester tester,
    Component scaffold,
    String id,
  ) async {
    tester.pumpComponent(host(scaffold));
    final document = (await tester.request('/')).document!;
    final parent = document.querySelector('#$id')!.parent!;

    return (
      classes: parent.classes.toList(),
      style: parent.attributes['style'] ?? '',
    );
  }

  bool paintsFace(({List<String> classes, String style}) section) =>
      section.classes.any((name) => name.startsWith('bg-')) ||
      section.style.contains('background');

  testServer('a floating navigation bar is the whole footer', (tester) async {
    final footer = await section(
      tester,
      const Scaffold(
        floatingFooter: true,
        footers: [bar],
        child: div([]),
      ),
      'nav',
    );

    expect(footer.classes, contains('sticky'));
    expect(paintsFace(footer), isFalse);
  });

  testServer('a stated footer face does not come back under it', (
    tester,
  ) async {
    // The Flutter twin draws the bar alone there, whatever the scaffold's
    // footer face says.
    final footer = await section(
      tester,
      const Scaffold(
        floatingFooter: true,
        footers: [bar],
        scaffoldStyle: CoreScaffoldStyle(
          footerBackgroundColor: CoreColor.token(CoreColors.primary),
        ),
        child: div([]),
      ),
      'nav',
    );

    expect(paintsFace(footer), isFalse);
  });

  testServer('a docked navigation bar keeps the footer face', (tester) async {
    final footer = await section(
      tester,
      const Scaffold(footers: [bar], child: div([])),
      'nav',
    );

    expect(paintsFace(footer), isTrue);
  });

  testServer('a floating footer of anything else keeps its face', (
    tester,
  ) async {
    final other = await section(
      tester,
      const Scaffold(
        floatingFooter: true,
        footers: [div([], id: 'other')],
        child: div([]),
      ),
      'other',
    );
    expect(paintsFace(other), isTrue);

    // Two footers are a section, even when one is a bar.
    final two = await section(
      tester,
      const Scaffold(
        floatingFooter: true,
        footers: [
          bar,
          div([], id: 'second'),
        ],
        child: div([]),
      ),
      'nav',
    );
    expect(paintsFace(two), isTrue);
  });
}
