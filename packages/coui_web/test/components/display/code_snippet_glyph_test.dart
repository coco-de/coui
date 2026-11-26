// The getter names and token names are the fixture data — naming each one
// would hide the pair the assertion is about.

/// The colour the copy glyph is drawn in, read off the rendered markup.
///
/// `defaultCopyIconStyle` states no colour, so the glyph's `<svg>` emits no
/// colour of its own and takes its colour from the cascade: the glyph strokes
/// with `currentColor`, which is the copy `<button>`'s own `color` —
/// `text-on-surface-variant` at rest, `hover:text-on-surface` on hover,
/// `disabled:text-disabled-content` when disabled. A colour class on the
/// `<svg>` itself outranks the inherited one, which is what a solid role face
/// relies on: the resolver states the face's ink on the glyph
/// (`CoreCodeSnippetStyle.inkOnFace`), so it keeps that ink through hover.
///
/// No browser runs here, so the cascade is modelled from the emitted names:
/// the glyph's own colour class if it has one, otherwise the button's class
/// for the state, each resolved against the scheme of the mode.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kSnippet = CodeSnippet(code: 'x', mode: 'dart');

/// The four shipped schemes `--coui-*` holds in each mode.
final _kModes = <String, CoreColorScheme>{
  'Light': CouiColorPresets.source.light().resolved(.light),
  'Dark': CouiColorPresets.source.dark().resolved(.dark),
  'HCLight': CouiColorPresets.source.highContrastLight().resolved(.light),
  'HCDark': CouiColorPresets.source.highContrastDark().resolved(.dark),
};

/// The face token and the ink each solid-face getter states.
final _kSolidFaces =
    <
      String,
      ({
        CodeSnippet Function(CodeSnippet) get,
        CoreColorToken face,
        CoreColorToken ink,
      })
    >{
      'primary': (
        get: (snippet) => snippet.primary,
        face: CoreColors.primary,
        ink: CoreColors.onPrimary,
      ),
      'secondary': (
        get: (snippet) => snippet.secondary,
        face: CoreColors.secondary,
        ink: CoreColors.onSecondary,
      ),
      'tertiary': (
        get: (snippet) => snippet.tertiary,
        face: CoreColors.tertiary,
        ink: CoreColors.onTertiary,
      ),
      'error': (
        get: (snippet) => snippet.error,
        face: CoreColors.error,
        ink: CoreColors.onError,
      ),
      'success': (
        get: (snippet) => snippet.success,
        face: CoreColors.success,
        ink: CoreColors.onSuccess,
      ),
      'warning': (
        get: (snippet) => snippet.warning,
        face: CoreColors.warning,
        ink: CoreColors.onWarning,
      ),
      'info': (
        get: (snippet) => snippet.info,
        face: CoreColors.info,
        ink: CoreColors.onInfo,
      ),
      'outline': (
        get: (snippet) => snippet.outline,
        face: CoreColors.outline,
        ink: CoreColors.surface,
      ),
    };

/// Faces whose glyph follows the button: the default face, the surface-tone
/// getters, and every other tone the role colours are certified on.
final _kFollowingFaces = <String, ({CodeSnippet snippet, CoreColorToken face})>{
  'default face (surfaceContainerLow)': (
    snippet: _kSnippet,
    face: CoreColors.surfaceContainerLow,
  ),
  '.surface': (snippet: _kSnippet.surface, face: CoreColors.surface),
  '.surfaceContainer': (
    snippet: _kSnippet.surfaceContainer,
    face: CoreColors.surfaceContainer,
  ),
  for (final tone in CoreSyntaxFaces.tones)
    'tone ${tone.name}': (
      snippet: _kSnippet.withStyle(
        CoreCodeSnippetStyle(backgroundColor: CoreColor.token(tone)),
      ),
      face: tone,
    ),
};

/// Every token a glyph can end up in, by the CSS name the class carries.
final Map<String, CoreColorToken> _kTokensByName = {
  for (final token in <CoreColorToken>[
    CoreColors.onSurface,
    CoreColors.onSurfaceVariant,
    CoreColors.disabledContent,
    CoreColors.onPrimary,
    CoreColors.onSecondary,
    CoreColors.onTertiary,
    CoreColors.onError,
    CoreColors.onSuccess,
    CoreColors.onWarning,
    CoreColors.onInfo,
    CoreColors.surface,
  ])
    token.name: token,
};

/// The token the colour class `<variant>text-X` in [classes] names, or `null`
/// when there is none. [variant] is `''` for the base class and `'hover:'`
/// or `'disabled:'` for a state's.
CoreColorToken? _tokenOf(String classes, {String variant = ''}) {
  final prefix = '${variant}text-';
  final tokens = [
    for (final name in classes.split(' '))
      if (name.startsWith(prefix) &&
          _kTokensByName[name.substring(prefix.length)] != null)
        _kTokensByName[name.substring(prefix.length)]!,
  ];
  expect(tokens.length, lessThanOrEqualTo(1), reason: '$variant in $classes');
  return tokens.firstOrNull;
}

/// The `<button>` and `<svg>` the snippet rendered, and every element between
/// them (outermost first, the button included).
({DomComponent button, DomComponent glyph, List<DomComponent> between})
_copyAffordance(ComponentTester tester) {
  final buttonElement = find.tag('button').evaluate().single;
  final glyphElement = find.tag('svg').evaluate().single;
  final between = <DomComponent>[];
  var found = false;
  void visit(Element element) {
    if (identical(element, glyphElement)) {
      found = true;
      return;
    }
    final component = element.component;
    if (component is DomComponent) between.add(component);
    element.visitChildren((child) {
      if (!found) visit(child);
    });
    if (!found && component is DomComponent) between.removeLast();
  }

  visit(buttonElement);
  expect(found, isTrue, reason: 'the glyph sits inside the copy button');
  return (
    button: buttonElement.component as DomComponent,
    glyph: glyphElement.component as DomComponent,
    between: between,
  );
}

double _ratio(CoreColor a, CoreColor b) => CoreContrast.ratio(a, b);

void _pump(ComponentTester tester, CodeSnippet snippet) =>
    pumpWithTheme(tester, snippet);

void main() {
  group('copy glyph — follows the copy button on an admitted face', () {
    for (final MapEntry(key: faceName, value: face)
        in _kFollowingFaces.entries) {
      testComponents('$faceName — the glyph emits no colour of its own', (
        tester,
      ) async {
        _pump(tester, face.snippet);
        final parts = _copyAffordance(tester);

        // The glyph states nothing: no colour class, no inline colour, so the
        // stroke (`currentColor`) takes the colour it inherits.
        expect(_tokenOf(parts.glyph.classes ?? ''), isNull);
        expect(parts.glyph.styles?.properties, isNot(contains('color')));
        // Nothing between the button and the glyph recolours it either.
        for (final element in parts.between) {
          expect(
            _tokenOf(element.classes ?? ''),
            element == parts.button ? isNotNull : isNull,
            reason: '<${element.tag}> between the button and the glyph',
          );
          if (element != parts.button) {
            expect(element.styles?.properties, isNot(contains('color')));
          }
        }

        // What the button hands down, state by state.
        final classes = parts.button.classes!;
        expect(_tokenOf(classes), CoreColors.onSurfaceVariant);
        expect(
          _tokenOf(classes, variant: 'hover:'),
          CoreColors.onSurface,
          reason: 'hover',
        );
        expect(
          _tokenOf(classes, variant: 'disabled:'),
          CoreColors.disabledContent,
          reason: 'disabled',
        );
      });

      for (final MapEntry(key: modeName, value: scheme) in _kModes.entries) {
        testComponents('$faceName — rest and hover read 4.5:1 — $modeName', (
          tester,
        ) async {
          _pump(tester, face.snippet);
          final classes = _copyAffordance(tester).button.classes!;
          final faceColour = face.face.read(scheme)!;
          final rest = _tokenOf(classes)!.read(scheme)!;
          final hovered = _tokenOf(classes, variant: 'hover:')!.read(scheme)!;
          expect(_ratio(rest, faceColour), greaterThanOrEqualTo(4.5));
          expect(_ratio(hovered, faceColour), greaterThanOrEqualTo(4.5));
          expect(hovered, isNot(rest), reason: 'hover changes the glyph');
        });
      }
    }

    testComponents('the glyph is a currentColor stroke, so it inherits', (
      tester,
    ) async {
      // The inheritance the markup above relies on: the bundled copy glyph
      // strokes with `currentColor` and fixes no colour of its own.
      final glyph = CoreBundledIcons.icons['lucide:copy']!.body;
      expect(glyph, contains('stroke="currentColor"'));
      expect(glyph, isNot(contains('#')));
      expect(glyph, isNot(contains('rgb')));
    });
  });

  group('copy glyph — a solid face pins the glyph to its ink', () {
    for (final MapEntry(key: name, value: pair) in _kSolidFaces.entries) {
      testComponents('.$name — the glyph states the ink as its own class', (
        tester,
      ) async {
        _pump(tester, pair.get(_kSnippet));
        final parts = _copyAffordance(tester);
        // A colour class on the element beats the one it would inherit, in
        // every state — the button's hover class does not reach it.
        expect(_tokenOf(parts.glyph.classes ?? ''), pair.ink);
        expect(
          _tokenOf(parts.glyph.classes ?? '', variant: 'hover:'),
          isNull,
          reason: 'the glyph has no hover colour of its own to change to',
        );
      });

      for (final MapEntry(key: modeName, value: scheme) in _kModes.entries) {
        testComponents('.$name — the ink reads 4.5:1 on its face — $modeName', (
          tester,
        ) async {
          _pump(tester, pair.get(_kSnippet));
          final own = _tokenOf(_copyAffordance(tester).glyph.classes ?? '')!;
          expect(
            _ratio(own.read(scheme)!, pair.face.read(scheme)!),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    }
  });

  group('copy glyph — the face the chain ends on decides', () {
    // A solid getter followed by a surface-tone getter leaves the glyph on
    // the button again; a tone followed by a solid one, or a solid face stated
    // without a getter, pins it to the face's ink.
    final ends = <String, ({CodeSnippet snippet, CoreColorToken? ink})>{
      '.primary.surface': (snippet: _kSnippet.primary.surface, ink: null),
      '.error.surfaceContainer': (
        snippet: _kSnippet.error.surfaceContainer,
        ink: null,
      ),
      '.outline.transparent': (
        snippet: _kSnippet.outline.transparent,
        ink: null,
      ),
      '.surface.primary': (
        snippet: _kSnippet.surface.primary,
        ink: CoreColors.onPrimary,
      ),
      '.success.warning': (
        snippet: _kSnippet.success.warning,
        ink: CoreColors.onWarning,
      ),
      'withStyle(backgroundColor: tertiary)': (
        snippet: _kSnippet.withStyle(
          const CoreCodeSnippetStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
          ),
        ),
        ink: CoreColors.onTertiary,
      ),
    };
    for (final MapEntry(key: chain, value: end) in ends.entries) {
      testComponents(
        end.ink == null
            ? '$chain — the glyph follows the button again'
            : '$chain — the glyph states the face ink as its own class',
        (tester) async {
          _pump(tester, end.snippet);
          final parts = _copyAffordance(tester);
          final own = _tokenOf(parts.glyph.classes ?? '');
          expect(own, end.ink);
          expect(parts.glyph.styles?.properties, isNot(contains('color')));
          expect(
            _tokenOf(parts.glyph.classes ?? '', variant: 'hover:'),
            isNull,
          );
          if (end.ink == null) {
            expect(
              _tokenOf(parts.button.classes!),
              CoreColors.onSurfaceVariant,
            );
            expect(
              _tokenOf(parts.button.classes!, variant: 'hover:'),
              CoreColors.onSurface,
            );
          }
        },
      );
    }
  });
}
