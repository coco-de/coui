// A panel that states a width band takes its content's width inside it.
//
// Flutter's popup is a `ConstrainedBox(min, max)` around its content, so a
// standalone menu is as wide as its rows want, held between 240 and 280. The
// Web panel is a block-level flex box: with no width of its own it filled
// whatever it sat in, up to the band's top — 280 in a wide page where
// Flutter drew 240. A panel with no ceiling states no band to land in and
// keeps filling, which an anchored panel sized by its host needs.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

Future<void> _withContext(
  ComponentTester tester,
  void Function(BuildContext context) body,
) async {
  late BuildContext captured;
  tester.pumpComponent(
    Theme.defaults(
      child: Builder(
        builder: (context) {
          captured = context;
          return const div([]);
        },
      ),
    ),
  );
  body(captured);
}

Set<String> _classes(String className) =>
    className.split(' ').where((c) => c.isNotEmpty).toSet();

void main() {
  group('Popup width', () {
    testComponents('a panel with a finite band hugs its content', (
      tester,
    ) async {
      await _withContext(tester, (context) {
        final root = resolvePopup(
          context,
          direction: CoreAxis.vertical,
          popupStyle: const CorePopupStyle(minWidth: 240, maxWidth: 280),
        ).root;

        expect(_classes(root.className), contains('w-fit'));
        // The band itself is unchanged.
        expect(root.inlineStyles!.properties['min-width'], '${240 / 16}rem');
        expect(root.inlineStyles!.properties['max-width'], '${280 / 16}rem');
      });
    });

    testComponents('a panel with no ceiling keeps filling', (tester) async {
      await _withContext(tester, (context) {
        final root = resolvePopup(context, direction: CoreAxis.vertical).root;

        expect(CorePopupStyle.defaultMaxWidth.isFinite, isFalse);
        expect(_classes(root.className), isNot(contains('w-fit')));
        expect(root.inlineStyles!.properties.containsKey('max-width'), isFalse);
      });
    });

    testComponents('the standalone menu is a banded panel, so it hugs', (
      tester,
    ) async {
      await _withContext(tester, (context) {
        const band = CoreMenuStyle.defaultPopupStyle;
        final root = resolvePopup(
          context,
          direction: CoreAxis.vertical,
          popupStyle: band,
        ).root;

        expect(band.minWidth, CoreLayout.layout240);
        expect(band.maxWidth, CoreLayout.layout280);
        expect(_classes(root.className), contains('w-fit'));
      });
    });
  });
}
