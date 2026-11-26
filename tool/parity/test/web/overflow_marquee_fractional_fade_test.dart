import 'package:coui_web/coui_web.dart';
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/web/ssr_render.dart';

Future<String> _renderMarquee(CoreAxis axis, double? portion) async {
  return await renderComponentBodyHtml(
    CoUIWeb(
      theme: .coui,
      enableThemeAnimation: false,
      child: OverflowMarquee(
        id: 'public-marquee',
        direction: axis,
        overflowMarqueeStyle: portion == null
            ? null
            : CoreOverflowMarqueeStyle(fadePortion: portion),
        child: div(
          const [],
          styles: Styles(
            raw: {
              'width': axis == .horizontal ? '720px' : '80px',
              'height': axis == .horizontal ? '80px' : '720px',
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final axis in CoreAxis.values) {
    for (final portion in [12.5, .5, 12.0, 24.0]) {
      test('public SSR ${axis.name} retains fadePortion $portion', () async {
        final body = await _renderMarquee(axis, portion);
        final document = html.parse(body);
        final root = document.getElementById('public-marquee')!;
        final style = root.querySelector('style')!.text;
        final expected = portion == portion.truncateToDouble()
            ? '${portion.toInt()}px'
            : '${portion}px';
        final match = RegExp(' black ([0-9.]+)px,').firstMatch(style);
        final actualLength = match == null
            ? null
            : double.parse(match.group(1)!);
        expect(root.querySelector('.co-om-track'), isNotNull);
        expect(style, contains(expected));
        expect(actualLength, portion);
      });
    }
    test('public SSR ${axis.name} keeps the no-override default', () async {
      final body = await _renderMarquee(axis, null);
      final root = html.parse(body).getElementById('public-marquee')!;
      final style = root.querySelector('style')!.text;
      expect(
        double.parse(
          RegExp(' black ([0-9.]+)px,').firstMatch(style)!.group(1)!,
        ),
        CoreOverflowMarqueeStyle.defaultFadePortion,
      );
    });
    test('public SSR ${axis.name} keeps zero fade disabled', () async {
      final body = await _renderMarquee(axis, 0);
      final root = html.parse(body).getElementById('public-marquee')!;
      expect(root.querySelector('style')!.text, isNot(contains('mask-image')));
    });
  }
}
