import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const ValueKey<String> _kCardKey = ValueKey('card-under-test');
const ValueKey<String> _kContentKey = ValueKey('card-content');
const _kDirectional = CoreEdgeInsets.directional(
  start: 11,
  top: 3,
  end: 7,
  bottom: 5,
);

void main() {
  final cases = [
    (
      name: 'directional input follows ambient direction',
      input: _kDirectional,
      scaling: 1.0,
      ltr: const EdgeInsets.fromLTRB(11, 3, 7, 5),
      rtl: const EdgeInsets.fromLTRB(7, 3, 11, 5),
    ),
    (
      name: 'physical asymmetric input keeps physical sides',
      input: const CoreEdgeInsets.fromLTRB(11, 3, 7, 5),
      scaling: 1.0,
      ltr: const EdgeInsets.fromLTRB(11, 3, 7, 5),
      rtl: const EdgeInsets.fromLTRB(11, 3, 7, 5),
    ),
    (
      name: 'default padding remains symmetric and unchanged',
      input: null,
      scaling: 1.0,
      ltr: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      rtl: const EdgeInsets.fromLTRB(24, 20, 24, 20),
    ),
    (
      name: 'directional padding scales exactly once',
      input: _kDirectional,
      scaling: 1.5,
      ltr: const EdgeInsets.fromLTRB(16.5, 4.5, 10.5, 7.5),
      rtl: const EdgeInsets.fromLTRB(10.5, 4.5, 16.5, 7.5),
    ),
  ];

  for (final slots in [false, true]) {
    for (final row in cases) {
      testWidgets('${slots ? 'slots' : 'child'}: ${row.name}', (tester) async {
        const content = SizedBox(
          key: _kContentKey,
          width: double.infinity,
          height: 10,
        );
        final style = CoreCardStyle(
          padding: row.input,
          borderWidth: 0,
          sizing: .fixed,
          width: 100,
          height: 10 + row.ltr.top + row.ltr.bottom,
        );
        final card = slots
            ? Card(key: _kCardKey, cardStyle: style, body: content)
            : Card(key: _kCardKey, cardStyle: style, child: content);

        // Reuse the same authored public Card while only inherited reading
        // direction changes. No observer, resolver replay or private State.
        for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
          await pumpTestApp(
            tester,
            card,
            theme: const ThemeData().copyWith(scaling: () => row.scaling),
            textDirection: direction,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byKey(_kCardKey), findsOneWidget);
          expect(find.byKey(_kContentKey), findsOneWidget);
          final frame = tester.getRect(find.byKey(_kCardKey));
          final child = tester.getRect(find.byKey(_kContentKey));
          final expected = direction == TextDirection.ltr ? row.ltr : row.rtl;
          expect(child.left - frame.left, closeTo(expected.left, 0.001));
          expect(child.top - frame.top, closeTo(expected.top, 0.001));
          expect(frame.right - child.right, closeTo(expected.right, 0.001));
          expect(frame.bottom - child.bottom, closeTo(expected.bottom, 0.001));
        }
      });
    }
  }
}
