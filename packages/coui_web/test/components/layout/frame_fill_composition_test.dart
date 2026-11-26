import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _color = CoreColor(0xFF224466);
const _image = CoreImageSource.network(
  'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22/%3E',
  fit: CoreImageFit.contain,
  alignment: CoreAlignment(.125, -.375),
);
const _gradient = CoreGradient(
  type: CoreGradientType.linear,
  colors: [CoreColor(0xFF00FF00), CoreColor.transparent],
);

Map<String, String> _styles() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .singleWhere((c) => c.id == 'frame')
    .styles!
    .properties;

void main() {
  group('the existing Native fill policy', () {
    testComponents('an unfilled Frame adds no background', (tester) async {
      pumpWithTheme(tester, const Frame(id: 'frame'));

      expect(_styles().containsKey('background-color'), isFalse);
      expect(_styles().containsKey('background-image'), isFalse);
    });

    testComponents('color-only is unchanged', (tester) async {
      pumpWithTheme(
        tester,
        const Frame(id: 'frame', backgroundColor: _color),
      );

      expect(_styles()['background-color'], _color.toValue());
      expect(_styles().containsKey('background-image'), isFalse);
    });

    testComponents('image-only adds no invented color', (tester) async {
      pumpWithTheme(
        tester,
        const Frame(id: 'frame', backgroundImage: _image),
      );

      expect(_styles()['background-image'], 'url("${_image.url}")');
      expect(_styles().containsKey('background-color'), isFalse);
      expect(_styles()['background-size'], 'contain');
      expect(_styles()['background-position'], '56.25% 31.25%');
      expect(_styles()['background-repeat'], 'no-repeat');
    });

    testComponents('image preserves the authored lower solid color', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Frame(
          id: 'frame',
          backgroundImage: _image,
          backgroundColor: _color,
        ),
      );

      expect(_styles()['background-image'], 'url("${_image.url}")');
      expect(_styles()['background-color'], _color.toValue());
    });

    testComponents('a theme color is also retained below the image', (
      tester,
    ) async {
      tester.pumpComponent(
        Theme(
          data: ThemeData.coui.copyWith(
            coreComponentTheme: const CoreComponentTheme(
              frame: CoreFrameTheme(
                style: CoreFrameStyle(backgroundColor: _color),
              ),
            ),
          ),
          child: const Frame(id: 'frame', backgroundImage: _image),
        ),
      );

      expect(_styles()['background-color'], _color.toValue());
    });

    for (final color in [null, _color]) {
      testComponents(
        'gradient-only keeps the existing solid exclusion: $color',
        (
          tester,
        ) async {
          pumpWithTheme(
            tester,
            Frame(id: 'frame', gradient: _gradient, backgroundColor: color),
          );

          expect(_styles()['background-image'], _gradient.toValue());
          expect(_styles().containsKey('background-color'), isFalse);
          expect(_styles().containsKey('background-size'), isFalse);
          expect(_styles().containsKey('background-position'), isFalse);
          expect(_styles().containsKey('background-repeat'), isFalse);
        },
      );

      testComponents(
        'image is above gradient, not above a new third fill: $color',
        (
          tester,
        ) async {
          pumpWithTheme(
            tester,
            Frame(
              id: 'frame',
              backgroundImage: _image,
              gradient: _gradient,
              backgroundColor: color,
            ),
          );

          // Both values contain internal commas. Neither may be split apart
          // while composing the two independent CSS image layers.
          expect(
            _styles()['background-image'],
            'url("${_image.url}"), ${_gradient.toValue()}',
          );
          expect(_styles().containsKey('background-color'), isFalse);
          expect(_styles()['background-size'], 'contain, auto');
          expect(_styles()['background-position'], '56.25% 31.25%, 0% 0%');
          expect(_styles()['background-repeat'], 'no-repeat, repeat');
        },
      );
    }
  });

  group('image placement belongs only to the front layer', () {
    for (final (fit, expected) in const [
      (CoreImageFit.cover, 'cover'),
      (CoreImageFit.contain, 'contain'),
      (CoreImageFit.fill, '100% 100%'),
      (CoreImageFit.none, 'auto'),
      // Preserve the existing Web mapping; this does not claim that
      // contain implements Native scaleDown for every intrinsic size.
      (CoreImageFit.scaleDown, 'contain'),
    ]) {
      testComponents('${fit.name} does not resize the lower gradient', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          Frame(
            id: 'frame',
            backgroundImage: CoreImageSource.network(_image.url, fit: fit),
            gradient: _gradient,
          ),
        );

        expect(_styles()['background-size'], '$expected, auto');
        expect(_styles()['background-repeat'], 'no-repeat, repeat');
      });
    }
  });

  testComponents('caller background longhands remain the final authority', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const Frame(
        id: 'frame',
        backgroundImage: _image,
        gradient: _gradient,
        css: Styles(
          raw: {
            'background-image': 'none',
            'background-color': '#123456',
            'background-size': '12px 13px',
            'background-position': '18.75% 63.125%',
            'background-repeat': 'repeat-x',
          },
        ),
      ),
    );

    expect(_styles()['background-image'], 'none');
    expect(_styles()['background-color'], '#123456');
    expect(_styles()['background-size'], '12px 13px');
    expect(_styles()['background-position'], '18.75% 63.125%');
    expect(_styles()['background-repeat'], 'repeat-x');
  });

  testComponents('caller background shorthand remains intact', (tester) async {
    const background = 'url("caller.png") 25% 75% / 10px 20px repeat #123456';
    pumpWithTheme(
      tester,
      const Frame(
        id: 'frame',
        backgroundImage: _image,
        gradient: _gradient,
        css: Styles(raw: {'background': background}),
      ),
    );

    expect(_styles()['background'], background);
  });
}
