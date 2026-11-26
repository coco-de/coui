// The frost and the body shade are two terms a glass surface lays over its
// backdrop pass. On the Web they are SVG filters in the surface's own
// `backdrop-filter` list, reached through two custom properties, and this
// file is what the stylesheet says about them: where each filter document
// lives, which rule names which, what the list looks like, and what takes
// them away.
//
// A stylesheet is read by a browser that matches selectors and substitutes
// custom properties, so every assertion here can pass while the glass draws
// nothing. The browser half of this file is
// `tool/parity/test/web/surface_finish_probe_test.dart`; this one is the text.

import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

const CoreSurfaceStyleId _glass = CoreSurfaceStyleId.liquidGlass;

/// The two custom properties the filter lists read.
const String _frost = kWebSurfaceFrostVar;
const String _shade = kWebSurfaceShadeVar;

/// A tuning that states both terms, a share per mode on the frost and a
/// shade in the dark palette only — the shape the shipped preset has.
const CoreSurfaceTuning _both = CoreSurfaceTuning(
  surfaceBlur: 0.6,
  surfaceFrostBlur: 14,
  surfaceFrostOpacity: 0.73,
  surfaceFrostOpacityInDarkMode: 0.85,
  surfaceBodyShadeInDarkMode: 0.28,
);

String _sheet(CoreSurfaceTuning? tuning) => ThemeConfig.from(
  CouiColorPresets.source,
  surfaceTunings: tuning == null ? const {} : {_glass: tuning},
).surfaceStyleVariableBlocks;

/// The body of the rule written under exactly [selector], or null.
///
/// Anchored to the end of the rule before it: the selector of the light rule
/// is the tail of every dark one.
String? _body(String css, String selector, {bool inMedia = false}) {
  final escaped = RegExp.escape(selector);
  final pattern = inMedia
      ? RegExp(
          r'@media \(prefers-color-scheme:dark\)\{'
          '$escaped'
          r'\{([^}]*)\}\}',
        )
      : RegExp('(?:^|\\})$escaped\\{([^}]*)\\}');

  return pattern.firstMatch(css)?.group(1);
}

/// The selectors one surface rule is written under, for a functional surface
/// of the document's own style and for one that carries its own style class.
class _Forms {
  const _Forms({
    required this.base,
    required this.darkAttribute,
    required this.darkMedia,
    required this.darkScope,
    required this.lightScope,
  });

  factory _Forms.global() {
    const target = '.$kWebSurfaceMarker.$kWebSurfaceRoleFunctional';

    return _Forms(
      base: '[data-coui-style="${_glass.name}"] $target',
      darkAttribute:
          '[data-theme="dark"][data-coui-style="${_glass.name}"] $target',
      darkMedia:
          ':root:not([data-theme="light"]) '
          '[data-coui-style="${_glass.name}"] $target',
      darkScope:
          '[data-coui-style="${_glass.name}"] [data-theme="dark"]:not(:root) '
          '$target',
      lightScope:
          '[data-coui-style="${_glass.name}"] [data-theme="light"]:not(:root) '
          '$target',
    );
  }

  factory _Forms.local() {
    const scope =
        '.$kWebLocalSurfaceMarker.$kWebSurfaceRoleFunctional'
        '.coui-material-liquidGlass';

    return const _Forms(
      base: scope,
      darkAttribute: '[data-theme="dark"] $scope',
      darkMedia: ':root:not([data-theme="light"]) $scope',
      darkScope: '[data-theme="dark"]:not(:root) $scope',
      lightScope: '[data-theme="light"]:not(:root) $scope',
    );
  }

  final String base;
  final String darkAttribute;
  final String darkMedia;
  final String darkScope;
  final String lightScope;

  List<String> get dark => [darkAttribute, darkMedia, darkScope];

  String? lightBody(String css) => _body(css, base);

  String? darkBody(String css, String selector) =>
      _body(css, selector, inMedia: selector == darkMedia);
}

/// The `backdrop-filter` list a rule body states.
String _list(String body) {
  final match = RegExp('backdrop-filter:([^;]*);').firstMatch(body);
  expect(match, isNotNull, reason: 'no backdrop-filter in: $body');

  return match!.group(1)!;
}

/// What the rule body sets [property] to, or null.
String? _declared(String body, String property) => RegExp(
  '(?:^|;)${RegExp.escape(property)}:([^;]*);',
).firstMatch(body)?.group(1);

/// The SVG document inside a `url("data:image/svg+xml,…#f")`.
String _document(String url) {
  final match = RegExp(
    r'url\("data:image/svg\+xml,([^"#]*)#f"\)',
  ).firstMatch(url);
  expect(match, isNotNull, reason: url);

  return Uri.decodeComponent(match!.group(1)!);
}

/// The `:root` rule that defines the filter documents, as a name → url map.
Map<String, String> _definitions(String css) {
  final rule = RegExp(
    r':root\{(--coui-surface-(?:frost|shade)-[^}]*)\}',
  ).allMatches(css).map((m) => m.group(1)!).join(';');
  final out = <String, String>{};
  for (final entry in RegExp(
    r'(--coui-surface-(?:frost|shade)-[A-Za-z]+-(?:light|dark)):(url\("[^"]*"\))',
  ).allMatches(rule)) {
    out[entry.group(1)!] = entry.group(2)!;
  }

  return out;
}

void main() {
  group('a sheet that states neither term', () {
    final untuned = _sheet(null);

    test('names neither custom property and carries no filter document', () {
      expect(untuned, isNot(contains(_frost)));
      expect(untuned, isNot(contains(_shade)));
      expect(untuned, isNot(contains('data:image/svg')));
      expect(untuned, isNot(contains('prefers-contrast:more),(forced-colors')));
      expect(untuned, isNot(contains(kWebSvgBackdropAttribute)));
    });

    test('is also what a tuning that states other terms ships', () {
      final other = _sheet(
        const CoreSurfaceTuning(surfaceBlur: 0.6, surfaceSaturation: 2),
      );

      expect(other, isNot(contains(_frost)));
      expect(other, isNot(contains(_shade)));
      expect(other, isNot(contains('data:image/svg')));
    });

    test('and a shade of zero is the shade of nothing', () {
      final zero = _sheet(
        const CoreSurfaceTuning(surfaceBlur: 0.6, surfaceBodyShade: 0),
      );

      expect(zero, isNot(contains(_shade)));
      expect(zero, isNot(contains('data:image/svg')));
    });
  });

  group('the filter documents', () {
    final sheet = _sheet(_both);
    final defs = _definitions(sheet);

    test('are defined once each, on :root, not in the rules that use them', () {
      expect(
        defs.keys,
        unorderedEquals([
          '$_frost-liquidGlass-light',
          '$_frost-liquidGlass-dark',
          '$_shade-liquidGlass-dark',
        ]),
      );
      // The point of defining them once: the sheet restates a surface for
      // every role, depth, palette and scope, and a document is hundreds of
      // characters.
      expect(
        RegExp('data:image/svg').allMatches(sheet).length,
        defs.length,
        reason: 'a document spelled in a rule other than its definition',
      );
    });

    test('carry the numbers the tuning states, one per mode', () {
      String stdDeviation(String doc) =>
          RegExp('stdDeviation="([0-9.]+)"').firstMatch(doc)!.group(1)!;
      String k2(String doc) =>
          RegExp('k2="([0-9.]+)"').firstMatch(doc)!.group(1)!;

      final light = _document(defs['$_frost-liquidGlass-light']!);
      final dark = _document(defs['$_frost-liquidGlass-dark']!);
      expect(stdDeviation(light), '14');
      expect(stdDeviation(dark), '14');
      expect(k2(light), '0.73');
      expect(k2(dark), '0.85');

      final shade = _document(defs['$_shade-liquidGlass-dark']!);
      expect(shade, contains('amplitude="-0.28"'));
      expect(shade, contains('exponent="2"'));
      expect(shade, contains('offset="1"'));
    });

    test('are percent-encoded so no stray quote reaches the injection', () {
      // The sheet is injected as an unescaped single-quoted string; one
      // quote in a data URL takes the whole injection down.
      expect(sheet, isNot(contains("'")));
      for (final url in defs.values) {
        expect(url, startsWith('url("data:image/svg+xml,'));
        expect(url, endsWith('#f")'));
        expect(url.substring(5, url.length - 2), isNot(contains('"')));
      }
    });

    test('are written once per distinct document, not once per mode', () {
      final equal = _sheet(
        const CoreSurfaceTuning(
          surfaceBlur: 0.6,
          surfaceFrostBlur: 10,
          surfaceFrostOpacity: 0.5,
          surfaceBodyShade: 0.2,
        ),
      );

      expect(_definitions(equal).keys, [
        '$_frost-liquidGlass-light',
        '$_shade-liquidGlass-light',
      ]);
      // And a mode that draws the same document does not restate a name.
      expect(equal, isNot(contains('-liquidGlass-dark')));
    });
  });

  group('the filter list', () {
    final sheet = _sheet(_both);

    for (final entry in {
      'a surface of the document style': _Forms.global(),
      'a surface that carries its own style': _Forms.local(),
    }.entries) {
      final forms = entry.value;

      test('puts the frost first and the shade last — ${entry.key}', () {
        final selectors = [forms.base, ...forms.dark, forms.lightScope];
        for (final selector in selectors) {
          final body = selector == forms.darkMedia
              ? forms.darkBody(sheet, selector)
              : _body(sheet, selector);
          expect(body, isNotNull, reason: selector);
          final list = _list(body!);

          expect(list, startsWith('var($_frost,) blur('), reason: selector);
          expect(list, endsWith(' var($_shade,)'), reason: selector);
          // The terms that were already in the list keep their order between
          // the two new ones: the chroma lift, then the dimming.
          expect(
            list.indexOf('saturate('),
            lessThan(list.indexOf('brightness(')),
            reason: selector,
          );
        }
      });

      test('names each mode its own definition — ${entry.key}', () {
        final light = forms.lightBody(sheet)!;
        expect(
          _declared(light, _frost),
          'var($_frost-liquidGlass-light)',
        );
        // The light shade is none: `initial` is the empty fallback the list
        // answers with.
        expect(_declared(light, _shade), 'initial');

        for (final selector in forms.dark) {
          final body = forms.darkBody(sheet, selector)!;
          expect(
            _declared(body, _frost),
            'var($_frost-liquidGlass-dark)',
            reason: selector,
          );
          expect(
            _declared(body, _shade),
            'var($_shade-liquidGlass-dark)',
            reason: selector,
          );
        }
        // A light scope inside a dark page must not read the dark document.
        final scope = _body(sheet, forms.lightScope)!;
        expect(_declared(scope, _frost), 'var($_frost-liquidGlass-light)');
        expect(_declared(scope, _shade), 'initial');
      });
    }

    test('states only the term the tuning states', () {
      final frostOnly = _sheet(
        const CoreSurfaceTuning(
          surfaceBlur: 0.6,
          surfaceFrostBlur: 10,
          surfaceFrostOpacity: 0.5,
        ),
      );
      final shadeOnly = _sheet(
        const CoreSurfaceTuning(surfaceBlur: 0.6, surfaceBodyShade: 0.3),
      );
      final forms = _Forms.global();

      final onlyFrost = _list(forms.lightBody(frostOnly)!);
      expect(onlyFrost, contains('var($_frost,)'));
      expect(onlyFrost, isNot(contains(_shade)));
      expect(frostOnly, isNot(contains(_shade)));

      final onlyShade = _list(forms.lightBody(shadeOnly)!);
      expect(onlyShade, contains('var($_shade,)'));
      expect(onlyShade, isNot(contains(_frost)));
      expect(shadeOnly, isNot(contains(_frost)));
    });

    test('is not restated per mode when no term differs by mode', () {
      final flat = _sheet(
        const CoreSurfaceTuning(
          surfaceBlur: 0.6,
          surfaceFrostBlur: 10,
          surfaceFrostOpacity: 0.5,
        ),
      );
      final forms = _Forms.global();

      // The dimming differs by mode, so a dark rule exists; what it must not
      // do is restate a custom property whose value is the light one.
      final dark = forms.darkBody(flat, forms.darkAttribute);
      expect(dark, isNotNull);
      expect(_declared(dark!, _frost), isNull);
      expect(_declared(dark, _shade), isNull);
    });

    test('rides the pass: a surface with no blur has no list to put it in', () {
      final noBlur = _sheet(
        const CoreSurfaceTuning(surfaceFrostBlur: 10, surfaceFrostOpacity: 0.5),
      );
      // The glass preset always draws a pass, so this asserts the other
      // direction: no rule on the glass has the term without a blur.
      for (final match in RegExp(r'\{([^{}]*)\}').allMatches(noBlur)) {
        final body = match.group(1)!;
        if (body.contains('var($_frost,)')) {
          expect(body, contains('blur('));
        }
      }
    });

    test('is not on a nested surface, which draws no pass', () {
      for (final match in RegExp(r'\{([^{}]*)\}').allMatches(sheet)) {
        final body = match.group(1)!;
        if (body.contains('backdrop-filter:none')) {
          expect(body, isNot(contains(_frost)));
          expect(body, isNot(contains(_shade)));
        }
      }
    });
  });

  group('what takes the terms away', () {
    final sheet = _sheet(_both);

    test('more contrast and forced colours blank both properties', () {
      const rule = [
        '@media (prefers-contrast:more),(forced-colors:active){',
        ':where(.$kWebSurfaceMarker,.$kWebLocalSurfaceMarker){',
        '$_frost:initial !important;$_shade:initial !important;}}',
      ];

      final text = rule.join();
      expect(sheet, contains(text));
      expect(
        RegExp(RegExp.escape(text)).allMatches(sheet).length,
        1,
        reason: 'one rule for the whole sheet, not one per palette',
      );
    });

    test('is not restated by anything that could outrank it', () {
      // `!important` in an author rule outranks every normal declaration; an
      // important declaration with another value would be the only thing that
      // could take that back. The three there are — the accessibility rule
      // and the two routes of the one for a browser that draws no SVG filter
      // in a backdrop list — and every one of them blanks the property.
      final important = RegExp(
        '${RegExp.escape(_frost)}:([^;]*) !important',
      ).allMatches(sheet);

      expect(important.map((m) => m.group(1)), [
        'initial',
        'initial',
        'initial',
      ]);
    });

    group('in a browser that draws no SVG filter named in a backdrop list', () {
      const marked = ':where(.$kWebSurfaceMarker,.$kWebLocalSurfaceMarker)';

      /// The route that applies from the first paint: a feature query that
      /// only WebKit answers.
      const query =
          '@supports (-apple-pay-button-style:black) '
          'or (font:-apple-system-body)';

      /// The route that applies once the browser build has said which browser
      /// it is in.
      const scope =
          ':root[$kWebSvgBackdropAttribute="$kWebSvgBackdropOff"] $marked';

      String firstPaint(String body) => '$query{$marked{$body}}';
      String attribute(String body) => '$scope{$body}';

      const both = '$_frost:initial !important;$_shade:initial !important;';

      /// How many rules are open at [index]: zero for a rule of the sheet.
      int depthAt(String css, int index) {
        var depth = 0;
        for (var i = 0; i < index; i++) {
          if (css[i] == '{') depth++;
          if (css[i] == '}') depth--;
        }

        return depth;
      }

      test('both properties are blanked from the first paint, with no script '
          'involved', () {
        final rule = firstPaint(both);

        expect(sheet, contains(rule));
        expect(
          RegExp(RegExp.escape(rule)).allMatches(sheet).length,
          1,
          reason: 'one rule for the whole sheet, not one per palette',
        );
      });

      test('both properties are blanked under the attribute the browser build '
          'writes', () {
        final rule = attribute(both);

        expect(sheet, contains(rule));
        expect(
          RegExp(RegExp.escape(rule)).allMatches(sheet).length,
          1,
          reason: 'one rule for the whole sheet, not one per palette',
        );
      });

      test('neither rule is behind a media query: the browser decides, not '
          'the user', () {
        // The accessibility rule is a media query and these are not: each one
        // is a rule of the sheet and not in one.
        expect(depthAt(sheet, sheet.indexOf(firstPaint(both))), 0);
        expect(depthAt(sheet, sheet.indexOf(attribute(both))), 0);
      });

      test('every feature the first-paint query names belongs to Apple', () {
        // A standard feature that Blink gets one day would take the two terms
        // from the browser that draws them. Apple's own carry the vendor
        // prefix, in the property or in the value. Read from the sheet, so it
        // judges what ships and not this file's copy of it.
        //
        // The clip a surface that clips its own content moves to its border box
        // asks its own question (`overflow-clip-margin`), about a feature that
        // is Blink's to have — it is not the first-paint query this judges.
        final queries = RegExp(r'@supports ([^{]*)\{')
            .allMatches(sheet)
            .map((m) => m.group(1)!)
            .where((query) => !query.contains('overflow-clip-margin'))
            .toList();
        expect(queries, hasLength(1));

        final conditions = RegExp(
          r'\(([^)]*)\)',
        ).allMatches(queries.single).map((m) => m.group(1)!).toList();
        expect(conditions, isNotEmpty);
        for (final condition in conditions) {
          expect(condition, contains('-apple-'));
        }
      });

      test('states only the term the sheet states', () {
        final frostOnly = _sheet(
          const CoreSurfaceTuning(
            surfaceBlur: 0.6,
            surfaceFrostBlur: 10,
            surfaceFrostOpacity: 0.5,
          ),
        );
        final shadeOnly = _sheet(
          const CoreSurfaceTuning(surfaceBlur: 0.6, surfaceBodyShade: 0.3),
        );

        for (final route in [firstPaint, attribute]) {
          expect(frostOnly, contains(route('$_frost:initial !important;')));
          expect(shadeOnly, contains(route('$_shade:initial !important;')));
        }
      });
    });

    test('reduced transparency removes the whole list', () {
      // The terms are inside the list, so the rule that drops the list
      // drops them; no rule of their own is needed.
      expect(
        sheet,
        contains('@media (prefers-reduced-transparency:reduce)'),
      );
      expect(sheet, contains('backdrop-filter:none !important;'));
    });
  });
}
