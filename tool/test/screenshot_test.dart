import 'package:test/test.dart';

import '../screenshot_target.dart';

void main() {
  group('screenshotUrl', () {
    test('a component slug keeps the /components/<slug> shape', () {
      expect(
        screenshotUrl(
          (component: 'button', path: null),
          baseUrl: 'http://localhost:8080',
        ),
        'http://localhost:8080/components/button',
      );
    });

    test('a site path is appended to the base as-is', () {
      expect(
        screenshotUrl(
          (component: null, path: '/'),
          baseUrl: 'http://localhost:8080',
        ),
        'http://localhost:8080/',
      );
      expect(
        screenshotUrl(
          (component: null, path: '/components-overview'),
          baseUrl: 'http://localhost:8080',
        ),
        'http://localhost:8080/components-overview',
      );
    });

    test('a trailing slash on the base does not double up', () {
      expect(
        screenshotUrl(
          (component: null, path: '/components-overview'),
          baseUrl: 'http://localhost:8080/',
        ),
        'http://localhost:8080/components-overview',
      );
      expect(
        screenshotUrl(
          (component: 'button', path: null),
          baseUrl: 'http://localhost:8080/',
        ),
        'http://localhost:8080/components/button',
      );
    });
  });

  group('screenshotPageProblem', () {
    test('a slug alone and a rooted path alone are both capturable', () {
      expect(screenshotPageProblem((component: 'button', path: null)), isNull);
      expect(screenshotPageProblem((component: null, path: '/')), isNull);
    });
  });

  group('validateScreenshotPage', () {
    test('rejects naming neither a component nor a path', () {
      expect(
        () => validateScreenshotPage((component: null, path: null)),
        throwsArgumentError,
      );
    });

    test('rejects naming both', () {
      expect(
        () => validateScreenshotPage((component: 'button', path: '/')),
        throwsArgumentError,
      );
    });

    test('rejects a path without the leading slash', () {
      // `components-overview` reads as a component slug in a workflow
      // file; it must not quietly resolve to the same page as
      // `/components-overview`.
      expect(
        () => validateScreenshotPage(
          (component: null, path: 'components-overview'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('screenshotLabel', () {
    test('a component is named by its slug', () {
      expect(
        screenshotLabel((component: 'date-picker', path: null)),
        'date-picker',
      );
    });

    test('the site root is named index', () {
      expect(screenshotLabel((component: null, path: '/')), 'index');
    });

    test('path segments fold to dashes', () {
      expect(
        screenshotLabel((component: null, path: '/components-overview')),
        'components-overview',
      );
      expect(
        screenshotLabel((component: null, path: '/guides/theming/')),
        'guides-theming',
      );
    });

    test('characters that are unsafe in a filename are replaced', () {
      expect(
        screenshotLabel((component: null, path: '/components-overview#forms')),
        'components-overview-forms',
      );
    });
  });

  group('screenshotOutPath', () {
    test('default path without a style keeps the old shape', () {
      expect(
        screenshotOutPath(label: 'button', theme: 'dark'),
        '/tmp/button-dark.png',
      );
    });

    test('default path with a style inserts it before the theme', () {
      expect(
        screenshotOutPath(
          label: 'index',
          theme: 'light',
          surfaceStyle: 'neoBrutalism',
        ),
        '/tmp/index-neoBrutalism-light.png',
      );
    });

    test('a template substitutes {label}, {theme} and {style}', () {
      expect(
        screenshotOutPath(
          label: 'components-overview',
          theme: 'dark',
          surfaceStyle: 'liquidGlass',
          template: '/out/landing/{label}-{style}-{theme}.png',
        ),
        '/out/landing/components-overview-liquidGlass-dark.png',
      );
    });

    test('{style} reads `default` when no style is set', () {
      expect(
        screenshotOutPath(
          label: 'index',
          theme: 'light',
          template: '/out/index-{style}-{theme}.png',
        ),
        '/out/index-default-light.png',
      );
    });
  });
}
