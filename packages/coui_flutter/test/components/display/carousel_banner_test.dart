// Widget tests for the Flutter `CarouselBanner`.

import 'dart:convert';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../test/fixtures/carousel_banner_images.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Material(
      child: Center(child: SizedBox(width: 361, child: child)),
    ),
  ),
);

void main() {
  group('CarouselBanner', () {
    testWidgets('renders the title and the supporting line', (tester) async {
      await tester.pumpWidget(
        _app(
          const CarouselBanner(
            title: Text('New this week'),
            description: Text('Three titles just landed'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('New this week'), findsOneWidget);
      expect(find.text('Three titles just landed'), findsOneWidget);
    });

    testWidgets('a null description drops the line, not the strip', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const CarouselBanner(title: Text('Only a title'))),
      );
      await tester.pump();

      expect(find.text('Only a title'), findsOneWidget);
      expect(find.byType(CarouselBanner), findsOneWidget);
    });

    testWidgets('the thumbnail sets the height — inset + side + inset', (
      tester,
    ) async {
      // The one number a caller can predict about this strip, and the
      // reason the description can be dropped without the band resizing.
      for (final (size, height) in const [
        (CoreCarouselBannerSize.sm, 88.0),
        (CoreCarouselBannerSize.md, 112.0),
      ]) {
        await tester.pumpWidget(
          _app(
            CarouselBanner(
              size: size,
              thumbnail: const SizedBox.shrink(),
              title: const Text('Title'),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.getSize(find.byType(CarouselBanner)).height,
          height,
          reason: '$size',
        );
      }
    });

    testWidgets('dropping the description does not change the height', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const CarouselBanner(
            thumbnail: SizedBox.shrink(),
            title: Text('Title'),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(CarouselBanner)).height, 88.0);
    });

    testWidgets('an Icon is centred at the row icon size, not stretched', (
      tester,
    ) async {
      // The square's tight constraints used to stretch a placeholder glyph
      // to the whole side (56 / 72). The slot's rule is that an icon is a
      // mark: centred at the icon size the row states (24 at both sizes).
      for (final size in CoreCarouselBannerSize.values) {
        final row = CoreCarouselBannerStyle.defaultsBySize[size]!;
        await tester.pumpWidget(
          _app(
            CarouselBanner(
              size: size,
              thumbnail: const Icon(LucideIcons.check),
              title: const Text('Title'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // A bundled glyph must paint; measuring the unbundled image icon's
        // loading placeholder would not establish a rendered icon size.
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(tester.getSize(find.byType(SvgPicture)), const Size.square(24));
        final icon = find.byType(Icon);
        expect(
          tester.getSize(icon),
          const Size.square(24),
          reason: '$size icon box',
        );
        final box = find.byType(SizedBox).evaluate().where((e) {
          final w = e.widget as SizedBox;
          return w.width == row.thumbnailSize && w.height == row.thumbnailSize;
        });
        expect(box, isNotEmpty, reason: '$size thumbnail square');
        expect(
          tester.getCenter(icon),
          tester.getCenter(find.byWidget(box.first.widget)),
          reason: '$size icon is centred in the square',
        );
      }
    });

    testWidgets('real images fill the thumbnail box and honour caller fit', (
      tester,
    ) async {
      for (final size in CoreCarouselBannerSize.values) {
        final side = size == CoreCarouselBannerSize.sm ? 56.0 : 72.0;
        for (final fixture in kCarouselBannerImages) {
          final picture = Image.memory(base64Decode(fixture.png));
          await tester.pumpWidget(
            _app(CarouselBanner(size: size, thumbnail: picture)),
          );
          await tester.runAsync(
            () => precacheImage(
              picture.image,
              tester.element(find.byType(Image)),
            ),
          );
          await tester.pumpAndSettle();
          final raw = tester.widget<RawImage>(find.byType(RawImage));
          expect(raw.image!.width, fixture.width);
          expect(raw.image!.height, fixture.height);
          expect(tester.getSize(find.byType(Image)), Size.square(side));
          expect(tester.getSize(find.byType(RawImage)), Size.square(side));

          // Pixel filling is a caller choice: test an actual decoded image
          // with explicit fit, rather than calling a coloured box an image.
          const boundaryKey = ValueKey('picture');
          await tester.pumpWidget(
            _app(
              CarouselBanner(
                size: size,
                thumbnail: RepaintBoundary(
                  key: boundaryKey,
                  child: Image(image: picture.image, fit: BoxFit.fill),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(boundaryKey),
          );
          final rgba = await tester.runAsync(() async {
            final image = await boundary.toImage();
            try {
              return await image.toByteData();
            } finally {
              image.dispose();
            }
          });
          final pixels = rgba!.buffer.asUint8List();
          for (final (fraction, colour) in const [
            (0.1, [255, 0, 0, 255]),
            (0.9, [0, 0, 255, 255]),
          ]) {
            final offset =
                ((side ~/ 2) * side.toInt() + (side * fraction).floor()) * 4;
            expect(
              pixels.sublist(offset, offset + 4),
              colour,
              reason: '${size.name}/${fixture.name} pixels at $fraction',
            );
          }
        }
      }
    });

    testWidgets('a thumbnail Icon keeps its explicit size and colour', (
      tester,
    ) async {
      for (final size in CoreCarouselBannerSize.values) {
        const icon = Icon(
          LucideIcons.check,
          iconStyle: CoreIconStyle(size: 20, color: CoreColor(0xFFFF0000)),
        );
        await tester.pumpWidget(
          _app(CarouselBanner(size: size, thumbnail: icon)),
        );
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byWidget(icon)), const Size.square(20));
        final resolved = resolveIcon(
          tester.element(find.byWidget(icon)),
          icon: icon.icon,
          data: CoreBundledIcons.icons[icon.icon.id],
          widgetStyle: icon.iconStyle,
        );
        expect(resolved.color, const Color(0xFFFF0000));
        final clip = find.ancestor(
          of: find.byWidget(icon),
          matching: find.byType(ClipRRect),
        );
        expect(tester.getCenter(find.byWidget(icon)), tester.getCenter(clip));
      }
    });

    testWidgets('the icon theme the slot hands over carries size and tone', (
      tester,
    ) async {
      late BuildContext captured;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      for (final size in CoreCarouselBannerSize.values) {
        final row = CoreCarouselBannerStyle.defaultsBySize[size]!;
        final resolved = resolveCarouselBanner(captured, size: size);

        // The token size: `Icon` multiplies its own box by the scaling, and
        // the stroke rule reads the size before that.
        expect(
          resolved.thumbnailIconTheme.size,
          row.thumbnailIconStyle!.size,
          reason: '$size',
        );
        expect(
          resolved.thumbnailIconTheme.color,
          Theme.of(captured).colorScheme.onSurfaceVariant.toValue(),
          reason: '$size',
        );
      }
    });

    testWidgets('a tappable strip is reachable by keyboard, not just mouse', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          CarouselBanner(
            onTap: () => taps++,
            title: const Text('Tap me'),
          ),
        ),
      );
      await tester.pump();

      // The composed `Clickable` is what carries focus and activation; a
      // hand-rolled gesture detector would look right with a mouse and be
      // unreachable without one.
      expect(find.byType(Clickable), findsOneWidget);
      await tester.tap(find.byType(CarouselBanner));
      expect(taps, 1);
    });

    testWidgets('no tap handler means no clickable wrapper', (tester) async {
      await tester.pumpWidget(
        _app(const CarouselBanner(title: Text('Static'))),
      );
      await tester.pump();

      expect(find.byType(Clickable), findsNothing);
    });
  });
}
