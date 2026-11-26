import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

Map<String, String> _styles() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .singleWhere((c) => c.id == 'frame')
    .styles!
    .properties;

List<double> _percentages(String value) => value
    .split(' ')
    .map((part) => double.parse(part.replaceAll('%', '')))
    .toList();

void main() {
  group('flat clip policy and inherited style', () {
    for (final (flat, nested, expected) in const [
      (CoreClipBehavior.none, CoreClipBehavior.hardEdge, 'visible'),
      (CoreClipBehavior.antiAlias, CoreClipBehavior.none, 'hidden'),
      (
        CoreClipBehavior.antiAliasWithSaveLayer,
        CoreClipBehavior.none,
        'hidden',
      ),
      (CoreClipBehavior.hardEdge, CoreClipBehavior.none, 'visible'),
      (CoreClipBehavior.none, CoreClipBehavior.none, 'visible'),
      (CoreClipBehavior.hardEdge, CoreClipBehavior.hardEdge, 'hidden'),
    ]) {
      testComponents('${flat.name} over ${nested.name}', (tester) async {
        pumpWithTheme(
          tester,
          Frame(
            id: 'frame',
            clipBehavior: flat,
            frameStyle: CoreFrameStyle(clipBehavior: nested),
          ),
        );

        expect(_styles()['overflow'], expected);
      });
    }

    testComponents('omitted flat policy keeps the style fallback', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Frame(
          id: 'frame',
          frameStyle: CoreFrameStyle(clipBehavior: .none),
        ),
      );

      expect(_styles()['overflow'], 'visible');
    });

    testComponents('instance style still overrides the theme fallback', (
      tester,
    ) async {
      tester.pumpComponent(
        Theme(
          data: ThemeData.coui.copyWith(
            coreComponentTheme: const CoreComponentTheme(
              frame: CoreFrameTheme(style: CoreFrameStyle(clipBehavior: .none)),
            ),
          ),
          child: const Frame(
            id: 'frame',
            frameStyle: CoreFrameStyle(clipBehavior: .hardEdge),
          ),
        ),
      );

      expect(_styles()['overflow'], 'hidden');
    });

    testComponents('explicit nondefault policy overrides a theme policy', (
      tester,
    ) async {
      tester.pumpComponent(
        Theme(
          data: ThemeData.coui.copyWith(
            coreComponentTheme: const CoreComponentTheme(
              frame: CoreFrameTheme(
                style: CoreFrameStyle(clipBehavior: .hardEdge),
              ),
            ),
          ),
          child: const Frame(id: 'frame', clipBehavior: .none),
        ),
      );

      expect(_styles()['overflow'], 'visible');
    });
  });

  group('normalized raw alignment coordinates', () {
    for (final (alignment, expected) in const [
      (CoreAlignment.topStart, [0.0, 0.0]),
      (CoreAlignment.center, [50.0, 50.0]),
      (CoreAlignment.bottomEnd, [100.0, 100.0]),
      (CoreAlignment(.125, -.375), [56.25, 31.25]),
      (CoreAlignment(-.17, .23), [41.5, 61.5]),
      (CoreAlignment(.001, -.003), [50.05, 49.85]),
      // Outside the documented domain, retain the existing clamp.
      (CoreAlignment(-2, 3), [0.0, 100.0]),
    ]) {
      testComponents('$alignment reaches both origin and image position', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          Frame(
            id: 'frame',
            transformAlignment: alignment,
            backgroundImage: CoreImageSource.network(
              'https://example.invalid/image.png',
              alignment: alignment,
            ),
          ),
        );

        for (final property in ['transform-origin', 'background-position']) {
          final actual = _percentages(_styles()[property]!);
          expect(actual[0], closeTo(expected[0], 1e-12), reason: property);
          expect(actual[1], closeTo(expected[1], 1e-12), reason: property);
        }
      });
    }

    testComponents('named anchors retain their existing CSS spelling', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Frame(id: 'frame', transformAlignment: CoreAlignment.center),
      );

      expect(_styles()['transform-origin'], '50% 50%');
    });
  });

  testComponents('caller CSS remains the final override', (tester) async {
    pumpWithTheme(
      tester,
      const Frame(
        id: 'frame',
        clipBehavior: .none,
        frameStyle: CoreFrameStyle(clipBehavior: .hardEdge),
        transformAlignment: CoreAlignment(.125, -.375),
        backgroundImage: CoreImageSource.network(
          'https://example.invalid/image.png',
          alignment: CoreAlignment(.125, -.375),
        ),
        css: Styles(
          raw: {
            'overflow': 'clip',
            'transform-origin': '13.25% 72.75%',
            'background-position': '18.75% 63.125%',
          },
        ),
      ),
    );

    expect(_styles()['overflow'], 'clip');
    expect(_styles()['transform-origin'], '13.25% 72.75%');
    expect(_styles()['background-position'], '18.75% 63.125%');
  });
}
