// Pins where shipped `coui_web` components fetch their static assets from.
//
// Two components pulled assets from a public CDN with no way to change the
// origin — every consumer inherited the third-party request, including
// builds under a strict CSP or with no network. The defaults must stay
// where they were (existing consumers see no change), and an override has
// to actually reach the emitted URL.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// Every flag box's `background-image` URL in the rendered tree.
List<String> _flagImages() => find
    .byComponentPredicate(
      (c) =>
          c is DomComponent &&
          (c.styles?.properties['background-image']?.startsWith('url(') ??
              false),
    )
    .evaluate()
    .map(
      (e) =>
          (e.component as DomComponent).styles!.properties['background-image']!,
    )
    .toList();

void main() {
  group('PhoneInput flag source', () {
    testComponents('defaults to the public flag-icons CDN', (tester) async {
      pumpWithTheme(tester, const PhoneInput());

      final flags = _flagImages();
      expect(flags, isNotEmpty);
      expect(
        flags.first,
        startsWith('url(${CouiAssetSourceScope.defaultFlagIconsBaseUrl}/'),
      );
      expect(
        CouiAssetSourceScope.defaultFlagIconsBaseUrl,
        'https://cdn.jsdelivr.net/gh/lipis/flag-icons@7.2.3/flags/4x3',
        reason: 'the default origin must not move under existing consumers',
      );
    });

    testComponents('an ancestor scope moves it to a mirror', (tester) async {
      pumpWithTheme(
        tester,
        const CouiAssetSourceScope(
          flagIconsBaseUrl: '/assets/flags',
          child: PhoneInput(),
        ),
      );

      final flags = _flagImages();
      expect(flags, isNotEmpty);
      expect(flags, everyElement(startsWith('url(/assets/flags/')));
      expect(flags, everyElement(endsWith('.svg)')));
    });
  });

  group('iconScript source', () {
    List<String> sources(Component scripts) => (scripts as Fragment).children
        .cast<DomComponent>()
        .map((entry) => entry.attributes!['src']!)
        .toList();

    test('defaults to the pinned jsDelivr build', () {
      expect(
        sources(iconScript()),
        [
          'https://cdn.jsdelivr.net/npm/iconify-icon@2.1.0/dist/iconify-icon.min.js',
          'packages/coui_web/iconify_stroke.js',
        ],
      );
    });

    test('a caller-supplied src wins over the version', () {
      expect(
        sources(
          iconScript(
            version: '9.9.9',
            src: '/vendor/iconify-icon.js',
            normalizerSrc: '/vendor/coui-iconify-stroke.js',
          ),
        ),
        ['/vendor/iconify-icon.js', '/vendor/coui-iconify-stroke.js'],
      );
    });
  });
}
