// Component tests for the Web `CarouselBanner`.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/carousel_banner/carousel_banner.dart';
import 'package:coui_web/src/components/display/carousel_banner/carousel_banner_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

/// A Lucide glyph the bundle does not carry, so it draws through the Iconify
/// adapter whose element holds the size.
const _unbundled = IconName('lucide', 'a-arrow-down');

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

void main() {
  group('CarouselBanner', () {
    testComponents('renders the title and the supporting line', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const CarouselBanner(
          title: Component.text('New this week'),
          description: Component.text('Three titles just landed'),
        ),
      );

      expect(find.text('New this week'), findsOneComponent);
      expect(find.text('Three titles just landed'), findsOneComponent);
    });

    testComponents('a tappable strip composes Clickable', (tester) async {
      // Which is what carries `role="button"`, the tab stop and keyboard
      // activation — a hand-rolled click handler would look right with a
      // mouse and be unreachable without one.
      pumpWithTheme(
        tester,
        CarouselBanner(onTap: () {}, title: const Component.text('Tap me')),
      );

      expect(find.byType(Clickable), findsOneComponent);
    });

    testComponents('no tap handler means no clickable wrapper', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const CarouselBanner(title: Component.text('Static')),
      );

      expect(find.byType(Clickable), findsNothing);
    });

    testComponents('the text column can wrap — min-w-0 on the flex child', (
      tester,
    ) async {
      // Without it the row holds open at its longest word instead of
      // wrapping; Flutter gets the same from `Expanded`.
      final resolved = resolveCarouselBanner(_themedContext(tester));

      expect(resolved.text.className, contains('min-w-0'));
      expect(resolved.text.className, contains('flex-1'));
    });

    testComponents('the thumbnail is square and clips what a caller puts in', (
      tester,
    ) async {
      final resolved = resolveCarouselBanner(
        _themedContext(tester),
        size: CoreCarouselBannerSize.md,
      );
      final raw = resolved.thumbnail.inlineStyles!.properties;

      expect(raw['width'], raw['height']);
      expect(raw['overflow'], 'hidden');
    });

    testComponents('the thumbnail centres what a caller puts in', (
      tester,
    ) async {
      // Flex-centred like the canvas's thumbnail frame, so a child smaller
      // than the square sits in the middle and not at its top-left corner.
      final cls = resolveCarouselBanner(_themedContext(tester)).thumbnail;

      expect(cls.className, contains('flex'));
      expect(cls.className, contains('items-center'));
      expect(cls.className, contains('justify-center'));
    });

    testComponents('an Icon in the thumbnail draws at the row icon size', (
      tester,
    ) async {
      // The slot says so through an ambient `IconTheme`, so the glyph is the
      // row's icon size (24 at both sizes) centred in the square — not the
      // square's own side, and not the app-root ambient. The Flutter twin
      // centres the same glyph at the same size.
      for (final size in CoreCarouselBannerSize.values) {
        final row = CoreCarouselBannerStyle.defaultsBySize[size]!;
        const side = 24.0;
        expect(side, lessThan(row.thumbnailSize!), reason: '${size.name} row');

        // The icon has to stay outside the bundle: this reads the size off
        // the `<iconify-icon>` element, and a bundled glyph is inline SVG.
        expect(CoreBundledIcons.icons, isNot(contains(_unbundled.id)));
        pumpWithTheme(
          tester,
          CarouselBanner(
            size: size,
            thumbnail: const Icon(_unbundled),
            title: const Component.text('t'),
          ),
        );

        // `lucide:a-arrow-down` is outside the bundle, so it is the
        // `<iconify-icon>` element that carries the size.
        final glyph =
            find.tag('iconify-icon').evaluate().single.component
                as DomComponent;
        expect(
          glyph.styles?.properties['width'],
          '${side / kRemDivisor}rem',
          reason: '${size.name} glyph width',
        );
        expect(
          glyph.styles?.properties['height'],
          '${side / kRemDivisor}rem',
          reason: '${size.name} glyph height',
        );
        // The variant tone, so the glyph recedes against the placeholder.
        expect(
          glyph.classes,
          contains('text-on-surface-variant'),
          reason: '${size.name} glyph colour',
        );
      }
    });

    testComponents(
      'the icon style the slot hands over is the row, not a side',
      (
        tester,
      ) async {
        final context = _themedContext(tester);
        for (final size in CoreCarouselBannerSize.values) {
          final row = CoreCarouselBannerStyle.defaultsBySize[size]!;
          final resolved = resolveCarouselBanner(context, size: size);

          expect(
            resolved.thumbnailIconStyle,
            row.thumbnailIconStyle,
            reason: size.name,
          );
          expect(
            resolved.thumbnailIconStyle.color,
            CoreCarouselBannerStyle.defaultThumbnailIconColor,
            reason: size.name,
          );
        }
      },
    );

    testComponents('each size emits its own row, not one flattened set', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final sm = resolveCarouselBanner(context);
      final md = resolveCarouselBanner(
        context,
        size: CoreCarouselBannerSize.md,
      );

      expect(
        sm.thumbnail.inlineStyles!.properties['width'],
        isNot(md.thumbnail.inlineStyles!.properties['width']),
      );
      expect(sm.title.className, isNot(md.title.className));
    });
  });
}
