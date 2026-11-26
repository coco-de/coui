import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  test('copyWith keeps layout and media', () {
    const media = Text('Media');
    const hero = Hero(
      layout: CoreHeroLayout.split,
      media: media,
      child: Text('Copy'),
    );

    expect(hero.copyWith().layout, CoreHeroLayout.split);
    expect(hero.copyWith().media, same(media));
    expect(const Hero(child: Text('Copy')).layout, isNull);
  });

  testComponents('the default hero does not render media', (tester) async {
    pumpWithTheme(
      tester,
      const Hero(
        media: Text('Media'),
        child: Text('Copy'),
      ),
    );

    expect(find.text('Copy'), findsOneComponent);
    expect(find.text('Media'), findsNothing);
  });

  testComponents('split stacks copy above media at the test viewport', (
    tester,
  ) async {
    // The VM stub reports a viewport width of 0, which is below the
    // tablet threshold, so the pair stacks. The row classes are the
    // same resolver's other branch — asserted below.
    pumpWithTheme(
      tester,
      const Hero(
        layout: CoreHeroLayout.split,
        media: Text('Media'),
        child: Text('Copy'),
      ),
    );

    expect(find.text('Copy'), findsOneComponent);
    expect(find.text('Media'), findsOneComponent);
    final classes = find
        .byType(DomComponent)
        .evaluate()
        .map((e) => (e.component as DomComponent).classes ?? '')
        .join(' ');
    expect(classes, contains('flex-col'));
    expect(classes, isNot(contains('flex-row')));
  });
}
