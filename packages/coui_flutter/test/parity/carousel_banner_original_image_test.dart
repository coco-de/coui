import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/svg_picture_string.dart';
import '../helpers/test_app.dart';

class _NoHttp extends HttpOverrides {
  int requests = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    requests++;
    throw StateError('The carousel banner preview must not request HTTP');
  }
}

/// The docs preview's original image glyph is a bundled icon, so it paints
/// from the first frame with no network and no disk cache.
void main() {
  for (final (variant, dark) in const [
    ('default', false),
    ('md', false),
    ('default', true),
    ('md', true),
  ]) {
    testWidgets(
      '$variant/${dark ? 'dark' : 'light'}: original image demo paints from the bundle, offline',
      (tester) async {
        final resolver = IconResolver.instance..clearMemoryCache();
        final previousHttp = HttpOverrides.current;
        final noHttp = _NoHttp();
        HttpOverrides.global = noHttp;
        addTearDown(() => HttpOverrides.global = previousHttp);
        final diskPath = resolver.cacheDir;
        final directory = Directory.systemTemp.createTempSync(
          'coui-icon-cold-',
        );
        resolver.cacheDir = '${directory.path}/never-created';
        addTearDown(() {
          resolver.cacheDir = diskPath;
          directory.deleteSync(recursive: true);
        });
        {
          // Clearing the memory cache leaves the bundle: this is the glyph the
          // preview draws, in the data the bundle carries.
          final data = resolver.get('lucide:image');
          expect(data, isNotNull);
          expect(data!.body, contains('<rect'));
          expect(data.body, contains('stroke-width="2"'));
          const boundaryKey = ValueKey('original-preview');
          await tester.pumpWidget(
            buildTestApp(
              Center(
                child: SizedBox(
                  width: 361,
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: kFlutterPreviewRegistry['carousel-banner']!(
                      variant == 'default' ? null : variant,
                    ),
                  ),
                ),
              ),
              theme: ThemeData.fromCore(
                dark ? CoreThemePresets.dark : CoreThemePresets.light,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final icon = find.byWidgetPredicate(
            (w) => w is Icon && w.icon.id == 'lucide:image',
          );
          expect(icon, findsOneWidget);
          final svg = find.descendant(
            of: icon,
            matching: find.byType(SvgPicture),
          );
          expect(tester.getSize(svg), const Size.square(24));
          final cell = find.ancestor(
            of: icon,
            matching: find.byType(ClipRRect),
          );
          expect(
            tester.getSize(cell),
            Size.square(variant == 'default' ? 56 : 72),
          );
          expect(tester.getCenter(icon), tester.getCenter(cell));
          final element = tester.element(icon);
          final ink = Theme.of(element).colorScheme
              .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
              .toValue();
          expect(
            tester.widget<SvgPicture>(svg).colorFilter,
            ColorFilter.mode(ink, .srcIn),
          );
          expect(strokeWidthsIn(svgStringOf(tester, icon)), ['1.5']);

          final bounds = tester.getRect(icon);
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(boundaryKey),
          );
          final origin = tester.getTopLeft(find.byKey(boundaryKey));
          final frame = await tester.runAsync(boundary.toImage);
          final rgba = await tester.runAsync(() => frame!.toByteData());
          final bytes = rgba!.buffer.asUint8List();
          var inkPixels = 0;
          for (var y = 0; y < 24; y++) {
            for (var x = 0; x < 24; x++) {
              final offset =
                  (((bounds.top - origin.dy).round() + y) * frame!.width +
                      (bounds.left - origin.dx).round() +
                      x) *
                  4;
              if ((bytes[offset] - (ink.r * 255).round()).abs() <= 2 &&
                  (bytes[offset + 1] - (ink.g * 255).round()).abs() <= 2 &&
                  (bytes[offset + 2] - (ink.b * 255).round()).abs() <= 2 &&
                  bytes[offset + 3] == 255) {
                inkPixels++;
              }
            }
          }
          expect(
            inkPixels,
            greaterThan(12),
            reason: 'actual glyph pixels, not a 24px transparent placeholder',
          );
          if (Platform.environment['COUI_CAROUSEL_PAINTED_EVIDENCE']
              case final String path) {
            final png = await tester.runAsync(
              () => frame!.toByteData(format: .png),
            );
            final target = Directory(path)..createSync(recursive: true);
            File(
              '${target.path}/$variant-${dark ? 'dark' : 'light'}.flutter.png',
            ).writeAsBytesSync(png!.buffer.asUint8List());
          }
          frame!.dispose();
          expect(noHttp.requests, 0);
          expect(Directory(resolver.cacheDir).existsSync(), isFalse);
        }
      },
    );
  }
}
