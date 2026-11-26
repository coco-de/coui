import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _headerKey = ValueKey<String>('header');
const _bodyKey = ValueKey<String>('body');
const _footerKey = ValueKey<String>('footer');

void main() {
  group('Card spacing', () {
    testWidgets('content sits 24 from the sides and 20 from the top', (
      tester,
    ) async {
      late double scaling;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            scaling = Theme.of(context).scaling;
            return const Card(
              header: Text('Header', key: _headerKey),
              body: Text('Body', key: _bodyKey),
            );
          },
        ),
      );

      final card = tester.getRect(find.byType(Card));
      final header = tester.getRect(find.byKey(_headerKey));
      // The default variant (filled) draws no border, so the padding is the
      // whole inset.
      expect(
        header.left - card.left,
        moreOrLessEquals(CoreSpace.space24 * scaling, epsilon: 0.01),
      );
      expect(
        header.top - card.top,
        moreOrLessEquals(CoreSpace.space20 * scaling, epsilon: 0.01),
      );
    });

    testWidgets('an outlined card adds its 1px border to the inset', (
      tester,
    ) async {
      late double scaling;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            scaling = Theme.of(context).scaling;
            return const Card(
              variant: .outlined,
              header: Text('Header', key: _headerKey),
              body: Text('Body', key: _bodyKey),
            );
          },
        ),
      );

      final card = tester.getRect(find.byType(Card));
      final header = tester.getRect(find.byKey(_headerKey));
      expect(
        header.left - card.left,
        moreOrLessEquals((CoreSpace.space24 + 1) * scaling, epsilon: 0.01),
      );
      expect(
        header.top - card.top,
        moreOrLessEquals((CoreSpace.space20 + 1) * scaling, epsilon: 0.01),
      );
    });

    testWidgets('header to body is 8 and body to footer is 12', (
      tester,
    ) async {
      late double scaling;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            scaling = Theme.of(context).scaling;
            return const Card(
              header: Text('Header', key: _headerKey),
              body: Text('Body', key: _bodyKey),
              footer: Text('Footer', key: _footerKey),
            );
          },
        ),
      );

      final header = tester.getRect(find.byKey(_headerKey));
      final body = tester.getRect(find.byKey(_bodyKey));
      final footer = tester.getRect(find.byKey(_footerKey));

      expect(
        body.top - header.bottom,
        moreOrLessEquals(CoreSpace.space8 * scaling, epsilon: 0.01),
      );
      expect(
        footer.top - body.bottom,
        moreOrLessEquals(CoreSpace.space12 * scaling, epsilon: 0.01),
      );
    });
  });
}
