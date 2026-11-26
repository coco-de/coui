import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../parity/parity_fonts.dart';

void main() {
  setUpAll(() async {
    await loadParityFonts();
    final data = IconifyJson.fromJson(
      jsonDecode(
            File(
              '../../tool/parity/vendor/iconify/lucide-1.2.121.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    for (final icon in const [
      LucideIcons.chevronLeft,
      LucideIcons.chevronRight,
      LucideIcons.lock,
      LucideIcons.rotateCw,
      LucideIcons.share,
      LucideIcons.plus,
    ]) {
      IconResolver.instance.register(icon.id, data.resolve(icon.name)!);
    }
  });

  tearDownAll(IconResolver.instance.clearMemoryCache);

  for (final dark in [false, true]) {
    testWidgets('380×200 ${dark ? 'dark' : 'light'} window paints all glyphs '
        'and overlays its full content surface', (tester) async {
      const captureKey = ValueKey('browser capture');
      await pumpTestApp(
        tester,
        const RepaintBoundary(
          key: captureKey,
          child: SizedBox(
            width: 380,
            height: 200,
            child: MockupBrowser(child: Center(child: Text('Content'))),
          ),
        ),
        theme: ThemeData.fromCore(
          dark ? CoreThemePresets.dark : CoreThemePresets.light,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SvgPicture), findsNWidgets(6));
      final window = tester.getRect(find.byType(MockupBrowser));
      expect(window.size, const Size(380, 200));
      final resolved = resolveMockupBrowser(
        tester.element(find.byType(MockupBrowser)),
      );
      final content = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(MockupBrowser),
              matching: find.byType(Container),
            ),
          )
          .singleWhere(
            (box) =>
                box.child is Padding &&
                box.clipBehavior == Clip.antiAlias &&
                (box.decoration as BoxDecoration?)?.color ==
                    resolved.contentBackgroundColor,
          );
      expect(tester.getRect(find.byWidget(content)), window);
      final blur = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      expect(blur.filter, ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20));
      expect(tester.getRect(find.byType(BackdropFilter)).top, window.top);
      expect(tester.getSize(find.byType(BackdropFilter)).height, 44);

      // Optional review evidence uses the same engine frame as the assertions.
      final captureDir = Platform.environment['MOCKUP_BROWSER_CAPTURE_DIR'];
      if (captureDir != null) {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(captureKey),
          );
          final frame = await boundary.toImage();
          final png = await frame.toByteData(format: ui.ImageByteFormat.png);
          Directory(captureDir).createSync(recursive: true);
          File(
            '$captureDir/flutter-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytesSync(png!.buffer.asUint8List());
          frame.dispose();
        });
      }
    });
  }

  testWidgets('the final window outline lets child taps through', (
    tester,
  ) async {
    var taps = 0;
    await pumpTestApp(
      tester,
      SizedBox(
        width: 380,
        height: 200,
        child: MockupBrowser(
          child: GestureDetector(
            onTap: () => taps += 1,
            behavior: .opaque,
            child: const Center(child: Text('Tap content')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tap content'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
