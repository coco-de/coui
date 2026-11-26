import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child, {required double textScale}) =>
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: material.Scaffold(
          body: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: Align(alignment: Alignment.topLeft, child: child),
            ),
          ),
        ),
      ),
    );

void main() {
  // The disc is a fixed size and the initials only mark a name written beside
  // it, so the OS text scale does not reach them. Grown with it, two letters
  // outgrew the disc at 1.5× — md 29.7 × 21 became 40 × 40 (wrapped onto two
  // lines and cut off), xl 47 × 34 became 64 × 64.
  group('Avatar initials ignore the OS text scale', () {
    for (final size in [CoreComponentSize.md, CoreComponentSize.xl]) {
      testWidgets('${size.name}: one line, the same box at 1.0 / 1.5 / 2.0', (
        tester,
      ) async {
        final boxes = <double, Size>{};
        late Size disc;
        for (final textScale in [1.0, 1.5, 2.0]) {
          await tester.pumpWidget(
            _buildApp(
              Avatar(initials: 'AB', size: size),
              textScale: textScale,
            ),
          );
          disc = tester.getSize(find.byType(Avatar));
          boxes[textScale] = tester.getSize(find.text('AB'));
        }
        expect(boxes[1.5], boxes[1.0]);
        expect(boxes[2.0], boxes[1.0]);
        // One line of the role's text, inside the disc.
        expect(boxes[1.0]!.width, lessThan(disc.width));
        expect(boxes[1.0]!.height, lessThan(disc.height));
      });
    }

    testWidgets('the disc itself does not follow the text scale either', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const Avatar(initials: 'AB'), textScale: 1),
      );
      final resting = tester.getSize(find.byType(Avatar));
      await tester.pumpWidget(
        _buildApp(const Avatar(initials: 'AB'), textScale: 2),
      );
      expect(tester.getSize(find.byType(Avatar)), resting);
    });
  });
}
