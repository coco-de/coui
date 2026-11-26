import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('the default hero centres the copy and does not mount media', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const Hero(
        media: Text('Media'),
        child: Text('Copy'),
      ),
    );

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Media'), findsNothing);
    expect(find.byType(Row), findsNothing);
  });

  testWidgets('a wide split trails media beside the copy', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpTestApp(
      tester,
      const MediaQuery(
        data: MediaQueryData(size: Size(1200, 800)),
        child: Hero(
          layout: CoreHeroLayout.split,
          media: Text('Media'),
          child: Text('Copy'),
        ),
      ),
    );

    expect(find.byType(Row), findsOneWidget);
    final copy = tester.getTopLeft(find.text('Copy'));
    final media = tester.getTopLeft(find.text('Media'));
    expect(media.dx, greaterThan(copy.dx));
  });

  testWidgets('a narrow split stacks media under the copy', (tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpTestApp(
      tester,
      const MediaQuery(
        data: MediaQueryData(size: Size(500, 800)),
        child: Hero(
          layout: CoreHeroLayout.split,
          media: Text('Media'),
          child: Text('Copy'),
        ),
      ),
    );

    expect(find.byType(Column), findsWidgets);
    final copy = tester.getTopLeft(find.text('Copy'));
    final media = tester.getTopLeft(find.text('Media'));
    expect(media.dy, greaterThan(copy.dy));
    expect(find.byType(Row), findsNothing);
  });

  test('imageUrl stays the background on both layouts', () {
    const center = Hero(
      imageUrl: 'https://example.com/bg.jpg',
      child: Text('Copy'),
    );
    const split = Hero(
      layout: CoreHeroLayout.split,
      imageUrl: 'https://example.com/bg.jpg',
      media: Text('Media'),
      child: Text('Copy'),
    );
    expect(center.imageUrl, split.imageUrl);
    expect(split.media, isNotNull);
  });
}
