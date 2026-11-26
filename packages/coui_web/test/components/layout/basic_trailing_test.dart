import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

List<String?> _texts() => find
    .byType(Text)
    .evaluate()
    .map((e) => (e.component as Text).data)
    .toList();

void main() {
  group('Basic redesign props', () {
    testComponents('showSubtitle false hides the subtitle', (tester) async {
      pumpWithTheme(
        tester,
        const Basic(
          title: Text('Title'),
          subtitle: Text('Subtitle'),
          showSubtitle: false,
        ),
      );
      expect(_texts(), ['Title']);
    });

    testComponents('subtitle shows by default', (tester) async {
      pumpWithTheme(
        tester,
        const Basic(title: Text('Title'), subtitle: Text('Subtitle')),
      );
      expect(_texts(), ['Title', 'Subtitle']);
    });

    testComponents('trailingText renders before the chevron', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Basic(
          title: Text('Title'),
          trailingText: Text('Value'),
          showTrailingIcon: true,
        ),
      );
      expect(_texts(), ['Title', 'Value']);
      expect(find.byType(Icon).evaluate(), hasLength(1));
    });

    testComponents(
      'the chevron is on by default, can be turned off, and yields to trailing',
      (
        tester,
      ) async {
        pumpWithTheme(tester, const Basic(title: Text('Title')));
        expect(find.byType(Icon).evaluate(), hasLength(1));

        pumpWithTheme(
          tester,
          const Basic(title: Text('Title'), showTrailingIcon: false),
        );
        expect(find.byType(Icon).evaluate(), isEmpty);

        pumpWithTheme(
          tester,
          const Basic(
            title: Text('Title'),
            trailing: Text('Custom'),
            showTrailingIcon: true,
          ),
        );
        expect(find.byType(Icon).evaluate(), isEmpty);
        expect(_texts(), ['Title', 'Custom']);
      },
    );
  });
}
