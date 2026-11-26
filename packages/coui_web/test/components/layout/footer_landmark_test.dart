import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

List<CoreFooterNavData<Component>> _sections() => [
  CoreFooterNavData(title: 'Product', children: [text('Pricing')]),
];

void main() {
  group('the footer is a landmark', () {
    // What this locks: the root element was hardcoded to `<div>` while
    // `build` already read a `tag` field, and the component set an
    // `aria-label` on it. An `aria-label` on an element with no role
    // creates no landmark — screen-reader landmark navigation listed
    // nothing, so the label described a region that did not exist.
    //
    // `HeroSection` sets `role="region"` and `NavigationBar` emits a
    // real `<nav>`, so the omission read as an oversight, not a policy.
    testComponents('renders a real <footer> by default', (tester) async {
      pumpWithTheme(tester, Footer(sections: _sections()));

      expect(find.tag('footer'), findsOneComponent);
    });

    testComponents('keeps its accessible name', (tester) async {
      pumpWithTheme(tester, Footer(sections: _sections()));

      final root =
          find.tag('footer').evaluate().first.component as DomComponent;
      // A page can carry several landmarks; unnamed ones read back as a
      // row of bare role names and tell a user nothing about which is
      // which.
      expect(root.attributes?['aria-label'], isNotNull);
    });

    testComponents('can step down to a div when nested', (tester) async {
      // A `<footer>` inside another `<footer>` is not a second landmark,
      // so the element has to stay overridable.
      pumpWithTheme(tester, Footer(sections: _sections(), tag: 'div'));

      expect(find.tag('footer'), findsNothing);
    });
  });
}
